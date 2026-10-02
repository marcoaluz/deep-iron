extends Node
## Defesa da vila (nó Defense, grupo "defense"): muro, armas, campo de treino,
## postos dos guardas e as INVASÕES NOTURNAS.
##
## Invasões: a primeira na noite do dia first_invasion_day (contado a partir do dia em
## que a defesa começou nesta partida: jogo novo = dia 1; save de antes = o dia em que
## carregou, pra ninguém ser pego de surpresa), depois a cada
## invasion_every noites, cada onda mais forte. Um aviso aparece no fim da tarde.
##   - Lumívoros nascem na clareira e descem pelo túnel (barricada "tunel").
##   - Ferrugentos sobem pelo poço do elevador (barricada "poco") — só depois que
##     o nível 2 abre (a escavação acordou eles).
## Ao amanhecer os que sobraram vão embora (creature.gd -> leave_at_dawn).
##
## ARSENAL + DESGASTE (Bloco 35):
##   - O Arsenal é um prédio que o jogador posiciona (como a taverna) e o engenheiro ergue.
##     As armas são forjadas LÁ, numa fila de encomendas que só anda com engenheiro
##     trabalhando no Arsenal (interface de obra). Arma pronta vai pro cavalete (rack).
##   - Cada guarda tem a SUA arma (ipezinho.weapon) com durabilidade: cada golpe numa
##     invasão gasta 1 (weapon_durability). Zerou, quebra: o guarda fica desarmado (soco,
##     unarmed_damage) até ir ao Arsenal. Lá ele deixa a quebrada e pega a melhor do
##     cavalete; cavalete vazio = um porrete (de graça, sempre tem). Sem Arsenal, fica no soco.
##   - Decisão: FORJAR x CONSERTAR. Forjar faz uma arma nova do zero (custo cheio). A arma
##     quebrada vai pra pilha "para consertar"; consertar custa repair_cost_mult do custo
##     (créditos, minério e madeira) e repair_time_mult do tempo, e volta pro cavalete.
##     Porrete não se conserta (é de graça). De dia, guarda com arma pior troca por uma
##     melhor do cavalete e a dele, usada, vai pra pilha de conserto.
##   - `weapons` = armas que a vila JÁ SABE fazer (forjou pelo menos uma vez): libera a
##     próxima da lista. O primeiro porrete de cada guarda vem de casa.
##
## GUARDA CAÍDO + BRECHA (Bloco 36):
##   - Guarda que perde a luta cai GRAVE no lugar e não anda (ipezinho.downed). Só o MÉDICO
##     resgata: vai até ele (acorda/sai do plantão pra isso), carrega nas costas e entrega
##     na enfermaria. No chão o relógio de "sem cuidado" corre (downed_untreated_time) e,
##     zerado, ele morre; nas costas do médico o relógio pausa.
##   - Enquanto ele está caído, o portão dele (downed_gate) tem uma BRECHA: o primeiro
##     invasor daquele portão que chegar num armazém leva raid_ore_percent do minério
##     guardado e raid_credit_percent dos créditos. Uma vez por portão por invasão. (O roubo
##     de sempre do Ferrugento — steal_amount por golpe — continua igual, à parte.)

signal invasion_started(wave: int)
signal invasion_ended(killed: int)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const LUMIVORO := preload("res://scenes/creatures/lumivoro.tscn")
const FERRUGENTO := preload("res://scenes/creatures/ferrugento.tscn")
const CAMPO_SCENE := preload("res://scenes/props/campo_treino.tscn")
const CAMPO_TEXTURE := preload("res://assets/game/campo_treino.png")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const ARSENAL_SCENE := preload("res://scenes/props/arsenal.tscn")
const ARSENAL_TEXTURE := preload("res://assets/game/arsenal.png")
const WEAPON_IDS := ["porrete", "lanca", "besta", "lanca_prata"]
const WEAPON_NAMES := {
	"porrete": "Porrete",
	"lanca": "Lança de ferro",
	"besta": "Besta de cobre",
	"lanca_prata": "Lança de prata",
}
const WEAPON_DESCRIPTIONS := {
	"porrete": "Um pedaço de pau. Melhor que nada.",
	"lanca": "Ponta de ferro num cabo comprido.",
	"besta": "Atira de longe: o guarda acerta antes de apanhar.",
	"lanca_prata": "A prata corta a ferrugem: dano extra contra Ferrugentos.",
}

@export_group("Armas (na ordem de WEAPON_IDS)")
@export var weapon_damage: Array[float] = [3.0, 6.0, 7.0, 11.0]
@export var weapon_range: Array[float] = [18.0, 18.0, 110.0, 18.0]
## Multiplicador do dano contra Ferrugentos.
@export var weapon_vs_ferrugento: Array[float] = [1.0, 1.0, 1.0, 1.6]
## x = créditos, y = minério, z = madeira.
@export var weapon_costs: Array[Vector3i] = [Vector3i.ZERO, Vector3i(150, 40, 20), Vector3i(350, 40, 40), Vector3i(600, 60, 20)]
@export var weapon_ore: Array[String] = ["", "ferro", "cobre", "prata"]
## Segundos de ENGENHEIRO no Arsenal pra forjar cada arma (Bloco 35: só anda com engenheiro).
@export var weapon_time: Array[float] = [0.0, 40.0, 60.0, 80.0]
## Bloco 35: golpes que cada arma aguenta antes de quebrar (cada ataque numa invasão gasta 1).
@export var weapon_durability: Array[int] = [30, 45, 55, 70]
## Consertar custa essa fração do custo de forjar (créditos, minério e madeira)...
@export_range(0.1, 1.0) var repair_cost_mult: float = 0.4
## ...e essa fração do tempo de forja.
@export_range(0.1, 1.0) var repair_time_mult: float = 0.5
## Desarmado (a arma quebrou): luta no soco.
@export var unarmed_damage: float = 1.5
@export var unarmed_range: float = 16.0

@export_group("Brecha na defesa (Bloco 36)")
## Guarda caído abre brecha no portão dele: o primeiro invasor dali que chega no armazém
## leva essa fração do MINÉRIO guardado (de cada tipo)...
@export_range(0.0, 1.0) var raid_ore_percent: float = 0.12
## ...e essa fração dos CRÉDITOS. (Uma vez por portão por invasão.)
@export_range(0.0, 1.0) var raid_credit_percent: float = 0.12

@export_group("Arsenal (Bloco 35)")
@export var arsenal_credits: int = 150
## Pedra (minério de ferro) e madeira pra erguer o Arsenal.
@export var arsenal_ore: int = 40
@export var arsenal_wood: int = 60
## Segundos de engenheiro pra erguer o Arsenal.
@export var arsenal_build_time: float = 40.0
## Máximo de encomendas na fila da forja.
@export var forge_queue_max: int = 4

@export_group("Campo de treino")
@export var campo_credits: int = 120
@export var campo_wood: int = 50
## Bloco 31b: segundos de engenheiro pra erguer o campo de treino.
@export var campo_build_time: float = 30.0

@export_group("Invasões")
@export var first_invasion_day: int = 3
@export var invasion_every: int = 2
@export var lumi_base: int = 2
@export var lumi_per_wave: int = 1
@export var lumi_max: int = 10
@export var ferr_per_wave: int = 1
@export var ferr_max: int = 6
## Vida das criaturas cresce essa fração por onda.
@export var hp_growth: float = 0.15
## Aviso quando faltar isso (s) pro anoitecer numa noite de invasão.
@export var warn_before: float = 40.0
## As criaturas vão chegando ao longo desses segundos do começo da noite.
@export var spawn_spread: float = 20.0
## Prompt 17: a partir dessa onda, 1 a cada `strong_every` criaturas vem na forma FORTE (Lumívoro
## bruto, Ferrugento carregador), com mais vida e dano. 0 = nunca.
@export var strong_from_wave: int = 4
@export var strong_every: int = 3
@export var strong_hp_mult: float = 1.6
@export var strong_damage_mult: float = 1.3

@export_group("Tiers e chefe (Bloco 62)")
## Tier da onda = 1 + onda / tier_every_waves + pesquisas feitas / tier_research_step.
@export var tier_every_waves: int = 3
@export var tier_research_step: int = 4
## Por tier acima do 1: vida extra e o forte vem mais vezes (strong_every - 1 por tier, mínimo 2).
@export var tier_hp_bonus: float = 0.12
## A partir deste tier, os fortes viram ELITE (ancião/blindado): mais vida e dano.
@export var elite_from_tier: int = 3
@export var elite_hp_mult: float = 1.35
@export var elite_damage_mult: float = 1.2
## O CHEFE (Matriarca dos Lumívoros): uma vez por estação, a partir desta estação da partida
## (0 = 1ª primavera, 1 = 1º verão...), na 1ª invasão dela.
@export var boss_from_season: int = 1
@export var boss_hp_mult: float = 10.0
@export var boss_damage_mult: float = 2.0
## Grito: a cada tantos segundos chama mais Lumívoros perto dela (até boss_call_max no total).
@export var boss_call_every: float = 9.0
@export var boss_call_count: int = 2
@export var boss_call_max: int = 8
## Golpe dela num guarda armado gasta a arma (pontos de durabilidade a mais).
@export var boss_weapon_corrode: float = 4.0
## Recompensa: solarita, peças raras e pontos na pesquisa em andamento.
@export var boss_reward_solarita: int = 40
@export var boss_reward_parts: int = 2
@export var boss_reward_research: float = 80.0

## Armas que a vila já sabe fazer (forjou pelo menos uma vez; o porrete já vem).
var weapons: Array = ["porrete"]
## Bloco 35: armas prontas no cavalete do Arsenal e quebradas esperando conserto (id -> qtd).
var rack: Dictionary = {}
var broken: Dictionary = {}
## Fila da forja: [{what: "forjar"/"consertar", id, left, total, ordered_at}]. A primeira é
## a que o engenheiro está fazendo.
var queue: Array = []
var wave: int = 0
## Dia em que a defesa começou nesta partida (-1 = ainda não sabe).
var start_day: int = -1
var invasion_active: bool = false
var killed_tonight: int = 0
## Prompt 17: criaturas nascidas nesta noite (pra escolher a forma forte).
var _spawned: int = 0
var _warned_day: int = -1
var _spawn_queue: Array = []  # [{kind, at}]
## Bloco 36: portões que já foram saqueados nesta invasão (brecha rouba uma vez só).
var _raided_gates: Array = []
var _night_time: float = 0.0
var _sound_timer := 0.0
## Bloco 62: chefe por estação da partida: {"<n>": "veio" | "derrotado" | "fugiu"}.
var bosses := {}
var _boss: Node = null
var _boss_called := 0
var _boss_call_t := 0.0
## O que aconteceu com a última onda (telemetria): {onda, tier, total, derrubadas, chefe}.
var last_result := {}


func _ready() -> void:
	add_to_group("defense")
	_connect_cycle.call_deferred()


func _connect_cycle() -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn:
		dn.phase_changed.connect(_on_phase_changed)


# ------------------------------------------------------------ consultas
func _dn() -> Node:
	return get_tree().get_first_node_in_group("day_night")


func gate(id: String) -> Node2D:
	for g in get_tree().get_nodes_in_group("barricadas"):
		if g.gate_id == id:
			return g
	return null


func campo() -> Node:
	return get_tree().get_first_node_in_group("campos")


## Bloco 47: todos os campos de treino (cada um tem as suas vagas; guarda treina no mais perto livre).
func campos() -> Array:
	return get_tree().get_nodes_in_group("campos")


func campo_cost() -> Vector3i:
	var base := Vector3i(campo_credits, 0, campo_wood)
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.scaled_cost(base, campos().size()) if eco else base


func campo_cost_text() -> String:
	var c := campo_cost()
	return "%d cr + %d madeira" % [c.x, c.z]


func level2_open() -> bool:
	var shaft := get_tree().get_first_node_in_group("elevador")
	return shaft != null and shaft.unlocked


func first_day() -> int:
	return maxi(start_day, 1) + first_invasion_day - 1


func is_invasion_night(day: int) -> bool:
	var first := first_day()
	return day >= first and (day - first) % maxi(invasion_every, 1) == 0


func next_invasion_day() -> int:
	var dn := _dn()
	var d: int = dn.day if dn else 1
	if dn and dn.is_night():
		d += 1  # a de hoje já começou (ou não era hoje)
	while not is_invasion_night(d):
		d += 1
	return d


func creatures() -> Array:
	return get_tree().get_nodes_in_group("criaturas").filter(func(c): return c.is_alive())


## Tem criatura dentro da vila (já passou a barricada)? Pro medo no ânimo.
func creatures_inside() -> int:
	return creatures().filter(func(c): return c.inside).size()


func guards() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.is_guard())


## A melhor arma que a vila já sabe forjar.
func best_weapon() -> String:
	var best := "porrete"
	for id in WEAPON_IDS:
		if weapons.has(id):
			best = id
	return best


## Dano de um golpe com essa arma ("" = desarmado, no soco).
func weapon_damage_vs(target: Node, weapon_id: String = "") -> float:
	var i := WEAPON_IDS.find(weapon_id)
	var dmg: float = weapon_damage[i] if i >= 0 else unarmed_damage
	if i >= 0 and target != null and target.get("kind") == "ferrugento":
		dmg *= weapon_vs_ferrugento[i]
	var res := get_tree().get_first_node_in_group("research")
	if res:
		dmg *= res.guard_damage_mult()  # holofotes
	return dmg


func weapon_reach(weapon_id: String = "") -> float:
	var i := WEAPON_IDS.find(weapon_id)
	return weapon_range[i] if i >= 0 else unarmed_range


func weapon_max_durability(weapon_id: String) -> float:
	var i := WEAPON_IDS.find(weapon_id)
	return float(weapon_durability[i]) if i >= 0 and i < weapon_durability.size() else 0.0


## Guardas sem arma nenhuma.
func unarmed_guards() -> Array:
	return guards().filter(func(w): return w.weapon == "")


# ------------------------------------------------------------ brecha (Bloco 36)
## Quem está caído em combate esperando o médico.
func downed_guards() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.get("downed"))


func nearest_gate_id(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	for g in get_tree().get_nodes_in_group("barricadas"):
		var d := pos.distance_to(g.global_position)
		if d < best_d:
			best_d = d
			best = g.gate_id
	return best


func gate_label(id: String) -> String:
	return {"tunel": "portão da floresta", "poco": "portão do poço"}.get(id, "portão")


## O portão está aberto pra saque? (guarda dele caído, numa invasão, e ainda não saquearam)
func breached(gate_id: String) -> bool:
	if not invasion_active or gate_id == "" or _raided_gates.has(gate_id):
		return false
	return downed_guards().any(func(w): return w.downed_gate == gate_id)


## Invasor que passou pela brecha chegou no armazém: leva uma parte do minério e dos créditos.
func raid(creature: Node, armazem: Node) -> void:
	var gid: String = creature.get("gate_id") if creature.get("gate_id") != null else ""
	if not breached(gid):
		return
	_raided_gates.append(gid)
	var ore_taken := 0.0
	for ore in armazem.stock.keys():
		var amount: float = floorf(float(armazem.stock[ore]) * raid_ore_percent)
		if amount >= 1.0:
			ore_taken += armazem.take(amount, ore)
	var eco := get_tree().get_first_node_in_group("economy")
	var cr_taken := 0
	if eco:
		cr_taken = floori(eco.credits * raid_credit_percent)
		if cr_taken > 0:
			eco.credits -= cr_taken
			eco.credits_changed.emit(eco.credits)
	if ore_taken > 0.0 and creature.get("looted") != null:
		creature.looted = true  # Prompt 17: sai com a carga (caçamba cheia)
	armazem.show_popup("ROUBO: -%d minério  -%d cr" % [roundi(ore_taken), cr_taken], Color(1.0, 0.35, 0.3))
	Audio.alarm()
	var who: Array = downed_guards().filter(func(w): return w.downed_gate == gid).map(func(w): return w.display_name)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("ROUBO NO ARMAZÉM!",
			"Com %s caído, os invasores entraram pela brecha do %s e levaram %d de minério e %d créditos." % [
				", ".join(who) if not who.is_empty() else "o guarda", gate_label(gid), roundi(ore_taken), cr_taken])


## Posto de cada guarda: metade no túnel, metade no poço (se o nível 2 abriu).
func guard_post(worker: Node) -> Vector2:
	var list := guards()
	var i := maxi(list.find(worker), 0)
	var gates: Array = []
	var t := gate("tunel")
	if t:
		gates.append(t)
	var p := gate("poco")
	if p and level2_open():
		gates.append(p)
	var base: Vector2
	if gates.is_empty():
		var hub := get_tree().get_first_node_in_group("village_hub")
		base = hub.global_position + Vector2(0, 60) if hub else Vector2.ZERO
	else:
		base = gates[i % gates.size()].global_position + Vector2(0, 30)
	var slot := i / maxi(gates.size(), 1)
	return base + Vector2(-24.0 + 16.0 * (slot % 4), 10.0 * floorf(slot / 4.0))


# ------------------------------------------------------------ armas / Arsenal (Bloco 35)
func arsenal() -> Node:
	return get_tree().get_first_node_in_group("arsenais")


## Bloco 47: todos os Arsenais. O cavalete, a pilha de conserto e a fila da forja são UM só
## (ficam aqui no Defense): engenheiro em qualquer Arsenal anda com a mesma fila, e o guarda
## pega/devolve arma no Arsenal mais perto dele. Mais Arsenal = mais perto e mais vagas.
func arsenais() -> Array:
	return get_tree().get_nodes_in_group("arsenais")


func arsenal_cost() -> Vector3i:
	var base := Vector3i(arsenal_credits, arsenal_ore, arsenal_wood)
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.scaled_cost(base, arsenais().size()) if eco else base


func arsenal_cost_text() -> String:
	var c := arsenal_cost()
	return "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]


func rack_count(id: String) -> int:
	return int(rack.get(id, 0))


func broken_count(id: String) -> int:
	return int(broken.get(id, 0))


func rack_total() -> int:
	var n := 0
	for id in rack:
		n += int(rack[id])
	return n


func broken_total() -> int:
	var n := 0
	for id in broken:
		n += int(broken[id])
	return n


## Melhor arma do cavalete que é MELHOR que `than` ("" = qualquer). "" se não tem.
func better_in_rack(than: String) -> String:
	var best := ""
	for i in range(WEAPON_IDS.find(than) + 1, WEAPON_IDS.size()):
		if rack_count(WEAPON_IDS[i]) > 0:
			best = WEAPON_IDS[i]
	return best


## O guarda chegou no Arsenal: deixa a quebrada (e a usada, se trocar) e pega a melhor.
func swap_weapon(worker: Node) -> void:
	if worker.broken_weapon != "":
		if worker.broken_weapon != "porrete":  # porrete quebrado vai pro fogo
			broken[worker.broken_weapon] = broken_count(worker.broken_weapon) + 1
		worker.broken_weapon = ""
	var cur: String = worker.weapon
	var best := better_in_rack(cur)
	if best != "":
		_take_from(rack, best)
		if cur != "" and cur != "porrete":
			# a dele volta: inteira pro cavalete, usada pra pilha de conserto
			var full: bool = worker.weapon_durability >= weapon_max_durability(cur) - 0.01
			var pile: Dictionary = rack if full else broken
			pile[cur] = int(pile.get(cur, 0)) + 1
		worker.equip(best)
	elif cur == "":
		worker.equip("porrete")  # cavalete vazio: porrete, que sempre tem
	_arsenal_refresh()


func _take_from(pile: Dictionary, id: String) -> void:
	pile[id] = int(pile.get(id, 0)) - 1
	if pile[id] <= 0:
		pile.erase(id)


func weapon_cost(id: String) -> Vector3i:
	return weapon_costs[WEAPON_IDS.find(id)]


func repair_cost(id: String) -> Vector3i:
	var c := weapon_cost(id)
	return Vector3i(ceili(c.x * repair_cost_mult), ceili(c.y * repair_cost_mult), ceili(c.z * repair_cost_mult))


## "" se pode encomendar a forja; senão o motivo.
func weapon_block_reason(id: String) -> String:
	if id == "porrete":
		return "de graça no Arsenal"
	if arsenal() == null:
		return "precisa do Arsenal"
	if queue.size() >= forge_queue_max:
		return "fila da forja cheia"
	var i := WEAPON_IDS.find(id)
	var prev: String = WEAPON_IDS[i - 1] if i > 0 else ""
	if prev != "" and not weapons.has(prev):
		return "precisa forjar antes: %s" % WEAPON_NAMES[prev]
	var c := weapon_costs[i]
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(c.x, c.y, weapon_ore[i], c.z) if eco else "sem recursos"


func repair_block_reason(id: String) -> String:
	if arsenal() == null:
		return "precisa do Arsenal"
	if broken_count(id) <= 0:
		return "nenhuma quebrada"
	if queue.size() >= forge_queue_max:
		return "fila da forja cheia"
	var c := repair_cost(id)
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(c.x, c.y, weapon_ore[WEAPON_IDS.find(id)], c.z) if eco else "sem recursos"


## Paga e põe na fila da forja (só anda com engenheiro no Arsenal).
func start_forge(id: String) -> bool:
	if weapon_block_reason(id) != "":
		Audio.error()
		return false
	var i := WEAPON_IDS.find(id)
	var c := weapon_costs[i]
	if not get_tree().get_first_node_in_group("economy").spend(c.x, c.y, weapon_ore[i], c.z):
		return false
	_enqueue("forjar", id, weapon_time[i])
	return true


## Paga o conserto (mais barato) e põe na fila; a quebrada sai da pilha e vai pra bigorna.
func start_repair(id: String) -> bool:
	if repair_block_reason(id) != "":
		Audio.error()
		return false
	var c := repair_cost(id)
	if not get_tree().get_first_node_in_group("economy").spend(c.x, c.y, weapon_ore[WEAPON_IDS.find(id)], c.z):
		return false
	_take_from(broken, id)
	_enqueue("consertar", id, weapon_time[WEAPON_IDS.find(id)] * repair_time_mult)
	return true


func _enqueue(what: String, id: String, seconds: float) -> void:
	var t := maxf(seconds, 1.0)
	queue.append({"what": what, "id": id, "left": t, "total": t, "ordered_at": Time.get_unix_time_from_system()})
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s: %s — na fila do Arsenal, precisa de engenheiro (tecla 4)." % [
			"Forjar" if what == "forjar" else "Consertar", WEAPON_NAMES[id]], Color(1.0, 0.8, 0.45))
	_arsenal_refresh()


## "Forjar: Lança de ferro" da encomenda da vez.
func forge_title() -> String:
	if queue.is_empty():
		return ""
	var o: Dictionary = queue[0]
	return "%s: %s" % ["Forjar" if o.what == "forjar" else "Consertar", WEAPON_NAMES.get(o.id, "?")]


func forge_progress() -> float:
	if queue.is_empty():
		return 0.0
	var o: Dictionary = queue[0]
	return clampf(1.0 - float(o.left) / float(o.total), 0.0, 1.0) if float(o.total) > 0.0 else 1.0


func forge_ordered_at() -> float:
	return float(queue[0].ordered_at) if not queue.is_empty() else 0.0


## O engenheiro trabalhou `seconds` no Arsenal: só assim a forja anda.
func forge_work(seconds: float) -> void:
	if queue.is_empty():
		return
	var o: Dictionary = queue[0]
	o.left = float(o.left) - seconds
	if o.left > 0.0:
		return
	queue.pop_front()
	var id: String = o.id
	rack[id] = rack_count(id) + 1
	var first := not weapons.has(id)
	if first:
		weapons.append(id)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s %s! Está no cavalete do Arsenal: os guardas vêm buscar." % [
			WEAPON_NAMES[id], "forjada" if o.what == "forjar" else "consertada"], Color(0.55, 1.0, 0.5))
	var ars := arsenal()
	Audio.forge(ars.global_position if ars else Vector2.ZERO)
	# guardas com arma pior (ou sem nenhuma) já decidem ir buscar
	for w in guards():
		if w.weapon == "" or better_in_rack(w.weapon) != "":
			w.wake_decision()
	_arsenal_refresh()


func _arsenal_refresh() -> void:
	for ars in arsenais():
		if ars.has_method("refresh"):
			ars.refresh()


# ------------------------------------------------------------ construir o Arsenal
func arsenal_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "arsenal")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := get_tree().get_first_node_in_group("economy")
	var cost := arsenal_cost()
	return eco.missing_text(cost.x, cost.y, "ferro", cost.z) if eco else "sem recursos"


func build_arsenal() -> bool:
	if arsenal_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_arsenal, ARSENAL_TEXTURE, 4, "o Arsenal")
	return true


func _confirm_arsenal(pos: Vector2) -> bool:
	if arsenal_block_reason() != "":
		Audio.error()
		return false
	var cost := arsenal_cost()
	if not get_tree().get_first_node_in_group("economy").spend(cost.x, cost.y, "ferro", cost.z):
		return false
	Canteiro.order(get_tree(), "arsenal", pos, arsenal_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Arsenal encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_arsenal(pos: Vector2) -> Node2D:
	var a: Node2D = ARSENAL_SCENE.instantiate()
	var n := arsenais().size()
	a.name = "Arsenal" if n == 0 else "Arsenal%d" % (n + 1)
	a.position = pos
	get_tree().get_first_node_in_group("village_hub").get_parent().add_child(a)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return a


# ------------------------------------------------------------ campo de treino
func campo_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "campo")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := get_tree().get_first_node_in_group("economy")
	var cost := campo_cost()
	return eco.missing_text(cost.x, 0, "", cost.z) if eco else "sem recursos"


func build_campo() -> bool:
	if campo_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_campo, CAMPO_TEXTURE, 1, "o campo de treino")
	return true


func _confirm_campo(pos: Vector2) -> bool:
	if campo_block_reason() != "":
		Audio.error()
		return false
	var cost := campo_cost()
	if not get_tree().get_first_node_in_group("economy").spend(cost.x, 0, "", cost.z):
		return false
	Canteiro.order(get_tree(), "campo", pos, campo_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Campo de treino encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


## Bloco 31b: o canteiro terminou (chamado por canteiro.gd).
func finish_build(kind: String, pos: Vector2) -> void:
	if kind == "arsenal":
		var a := spawn_arsenal(pos)
		a.pop_in()
		Audio.recruit()
		var h := get_tree().get_first_node_in_group("hud")
		if h:
			h.show_toast("Arsenal pronto! Forje armas aqui (G: Defesa); guarda desarmado vem buscar.", Color(0.55, 1.0, 0.5))
		for w in guards():
			w.wake_decision()
		return
	if kind != "campo":
		return
	var c := spawn_campo(pos)
	c.pop_in()
	Audio.recruit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Campo de treino pronto! Os guardas treinam aqui de dia (tecla X faz guarda).", Color(0.55, 1.0, 0.5))


func spawn_campo(pos: Vector2) -> Node2D:
	var c: Node2D = CAMPO_SCENE.instantiate()
	var n := campos().size()
	c.name = "CampoTreino" if n == 0 else "CampoTreino%d" % (n + 1)
	c.position = pos
	get_tree().get_first_node_in_group("village_hub").get_parent().add_child(c)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return c


# ------------------------------------------------------------ invasões
func _process(delta: float) -> void:
	# (Bloco 35: a forja não anda mais sozinha — só com engenheiro no Arsenal, forge_work)
	var dn := _dn()
	if dn == null:
		return
	if start_day < 0 and not SaveManager.pending_load:
		start_day = dn.day  # jogo novo (dia 1) ou save de antes da defesa
	# aviso no fim da tarde
	if not dn.is_night() and is_invasion_night(dn.day) and _warned_day != dn.day \
			and dn.time_left_in_phase() <= warn_time():
		_warned_day = dn.day
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			var ferr := " e os Ferrugentos se mexem no poço" if level2_open() else ""
			var radio := "O rádio pegou o chiado deles bem antes: " if _has_radio() else ""
			hud.show_banner("VEM AÍ UMA INVASÃO",
				"%sOs Lumívoros se juntam na clareira%s. Esta noite eles atacam — guardas nos portões! (G: Defesa)" % [radio, ferr])
		Audio.alarm()
	# criaturas chegando aos poucos
	if invasion_active:
		_night_time += delta
		while not _spawn_queue.is_empty() and _spawn_queue[0].at <= _night_time:
			var k: String = _spawn_queue.pop_front().kind
			if k == "chefe":
				_spawn_boss()
			else:
				_spawn(k)
		_boss_tick(delta)


## Bloco 60: com o rádio, o aviso vem antes.
func _has_radio() -> bool:
	var res := get_tree().get_first_node_in_group("research")
	return res != null and res.has("radio")


func warn_time() -> float:
	var res := get_tree().get_first_node_in_group("research")
	return warn_before + (res.radio_warning_bonus if _has_radio() else 0.0)


func _on_phase_changed(night: bool) -> void:
	var dn := _dn()
	if night and dn and is_invasion_night(dn.day) and not invasion_active:
		start_invasion()
	elif not night and invasion_active:
		end_invasion()


# ------------------------------------------------------------ tiers e chefe (Bloco 62)
func tier() -> int:
	var res := get_tree().get_first_node_in_group("research")
	var pesq: int = (res.done as Array).size() if res else 0
	return 1 + int(wave / maxi(tier_every_waves, 1)) + int(pesq / maxi(tier_research_step, 1))


func _season_number() -> int:
	var dn := _dn()
	var sun := get_tree().get_first_node_in_group("sun")
	var per: int = sun.days_per_season if sun else 4
	return int((maxi(dn.day if dn else 1, 1) - 1) / maxi(per, 1))


## Esta invasão traz o chefe? (uma vez por estação, a partir de boss_from_season)
func boss_due() -> bool:
	var n := _season_number()
	return n >= boss_from_season and not bosses.has(str(n))


func boss_alive() -> bool:
	return _boss != null and is_instance_valid(_boss) and _boss.is_alive()


func _spawn_boss() -> void:
	var c := _spawn("lumivoro")
	if c == null:
		return
	c.make_boss(boss_hp_mult, boss_damage_mult)
	c.weapon_corrode = boss_weapon_corrode
	_boss = c
	_boss_called = 0
	_boss_call_t = boss_call_every
	bosses[str(_season_number())] = "veio"
	c.died.connect(_on_boss_died)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("A MATRIARCA DOS LUMÍVOROS!", "A rainha deles veio junto. Ela grita chamando mais Lumívoros e o golpe dela corrói as armas. Derrube-a antes do amanhecer.")
	Audio.screech(c.global_position)
	var diary := get_tree().get_first_node_in_group("diary")
	if diary and diary.has_method("unlock"):
		diary.unlock("matriarca")


func _on_boss_died(killed: bool) -> void:
	var key := str(_season_number())
	if not killed:
		return
	bosses[key] = "derrotado"
	var arm := get_tree().get_first_node_in_group("armazens")
	if arm:
		arm.add_ore(float(boss_reward_solarita), "solarita")
	var finds := get_tree().get_first_node_in_group("finds")
	if finds:
		finds.rare_parts += boss_reward_parts
	var res := get_tree().get_first_node_in_group("research")
	if res and res.current != "":
		res.progress += boss_reward_research
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("A MATRIARCA CAIU!", "Dos cristais dela: +%d solarita, +%d peças raras%s." % [
			boss_reward_solarita, boss_reward_parts, (" e a pesquisa avançou") if res and res.current != "" else ""])
	Audio.fanfare()


func _boss_tick(delta: float) -> void:
	if not boss_alive() or not _boss.inside:
		return
	_boss_call_t -= delta
	if _boss_call_t > 0.0 or _boss_called >= boss_call_max:
		return
	_boss_call_t = boss_call_every
	for i in mini(boss_call_count, boss_call_max - _boss_called):
		var c := _spawn("lumivoro")
		if c:
			c.global_position = _boss.global_position + Vector2(randf_range(-30, 30), randf_range(-20, 20))
			c.inside = true
			_boss_called += 1
	Audio.screech(_boss.global_position)
	_boss.shout()


func start_invasion() -> void:
	wave += 1
	invasion_active = true
	_raided_gates = []
	killed_tonight = 0
	_night_time = 0.0
	_spawn_queue = []
	_spawned = 0
	var lumi := mini(lumi_base + lumi_per_wave * (wave - 1), lumi_max)
	var ferr := mini(ferr_per_wave * maxi(wave - 1, 1), ferr_max) if level2_open() else 0
	for i in lumi:
		_spawn_queue.append({"kind": "lumivoro", "at": randf_range(0.0, spawn_spread)})
	for i in ferr:
		_spawn_queue.append({"kind": "ferrugento", "at": randf_range(2.0, spawn_spread)})
	var chefe := boss_due()
	if chefe:
		_spawn_queue.append({"kind": "chefe", "at": spawn_spread * 0.6})
	_spawn_queue.sort_custom(func(a, b): return a.at < b.at)
	last_result = {"onda": wave, "tier": tier(), "total": lumi + ferr + (1 if chefe else 0), "derrubadas": 0, "chefe": "veio" if chefe else ""}
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("INVASÃO! (onda %d, tier %d)" % [wave, tier()], "%d Lumívoros%s. Aguentem até o amanhecer." % [
			lumi, (" e %d Ferrugentos" % ferr) if ferr > 0 else ""])
	Audio.alarm()
	invasion_started.emit(wave)


func _spawn(kind: String) -> Node2D:
	var env := get_tree().get_first_node_in_group("environment")
	var world := get_tree().get_first_node_in_group("village_hub").get_parent()
	var c: Node2D = (LUMIVORO if kind == "lumivoro" else FERRUGENTO).instantiate()
	var pos: Vector2
	var g: Node2D
	if kind == "lumivoro":
		var r: Rect2 = env.clearing_rect.grow(-60.0) if env else Rect2(-200, -850, 400, 300)
		pos = Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y - 60.0))
		g = gate("tunel")
	else:
		var shaft := get_tree().get_first_node_in_group("elevador")
		pos = shaft.global_position + Vector2(randf_range(-10, 10), -4) if shaft else Vector2.ZERO
		g = gate("poco")
	if env:
		pos = NavigationServer2D.map_get_closest_point(world.get_world_2d().navigation_map, pos)
	c.position = pos
	c.gate_id = "tunel" if kind == "lumivoro" else "poco"  # Bloco 36: de que portão ele vem
	world.add_child(c)
	var tr := tier()
	c.setup(g, (1.0 + hp_growth * (wave - 1)) * (1.0 + tier_hp_bonus * (tr - 1)))
	_spawned += 1
	var every := maxi(strong_every - (tr - 1), 2) if strong_every > 0 else 0
	if every > 0 and wave >= strong_from_wave and _spawned % every == 0:
		c.make_strong(strong_hp_mult, strong_damage_mult)
		if tr >= elite_from_tier:
			c.make_elite(elite_hp_mult, elite_damage_mult)  # Bloco 62: ancião / blindado
	var res := get_tree().get_first_node_in_group("research")
	if res and kind == "lumivoro":
		c.speed *= res.lumivoro_speed_mult()  # holofotes
	c.died.connect(func(killed: bool):
		if killed:
			killed_tonight += 1)
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		diary.unlock("lumivoros" if kind == "lumivoro" else "ferrugentos")
	return c


func end_invasion() -> void:
	invasion_active = false
	_spawn_queue = []
	var left := creatures()
	if boss_alive():
		bosses[str(_season_number())] = "fugiu"  # amanheceu com ela de pé: só volta na próxima estação
	if not last_result.is_empty():
		last_result.derrubadas = killed_tonight
		if last_result.chefe != "":
			last_result.chefe = bosses.get(str(_season_number()), last_result.chefe)
	_boss = null
	for c in left:
		c.leave_at_dawn()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Amanheceu: %d criatura%s derrubada%s esta noite%s." % [
			killed_tonight, "s" if killed_tonight != 1 else "", "s" if killed_tonight != 1 else "",
			(", o resto fugiu") if not left.is_empty() else ""], Color(1.0, 0.85, 0.45))
	invasion_ended.emit(killed_tonight)


# ------------------------------------------------------------ save/load (SaveManager)
## As criaturas não vão pro save: carregar no meio da noite encerra a invasão.
func get_save_data() -> Dictionary:
	var d := {
		"weapons": weapons.duplicate(),
		"rack": rack.duplicate(),
		"broken": broken.duplicate(),
		"queue": queue.duplicate(true),
		"wave": wave,
		"warned_day": _warned_day,
		"start_day": start_day,
		"bosses": bosses.duplicate(),  # Bloco 62
		"last_result": last_result.duplicate(),
	}
	# Bloco 47: listas (antes: "campo" e "arsenal" com um só)
	d["campos"] = campos().map(func(c): return SaveUtil.vec2_to_array(c.global_position))
	d["arsenais"] = arsenais().map(func(a): return SaveUtil.vec2_to_array(a.global_position))
	return d


func load_save_data(d: Dictionary) -> void:
	weapons = ["porrete"]
	for id in SaveUtil.array(d, "weapons"):
		if id is String and id in WEAPON_IDS and not weapons.has(id):
			weapons.append(id)
	# Bloco 35 (save antigo: o SaveManager já passou a forja em andamento pra fila)
	rack = _load_pile(SaveUtil.dict(d, "rack"))
	broken = _load_pile(SaveUtil.dict(d, "broken"))
	queue = []
	for o in SaveUtil.array(d, "queue"):
		if typeof(o) != TYPE_DICTIONARY:
			continue
		var id := SaveUtil.text(o, "id", "")
		var what := SaveUtil.text(o, "what", "forjar")
		if id not in WEAPON_IDS or id == "porrete" or what not in ["forjar", "consertar"]:
			continue
		var i := WEAPON_IDS.find(id)
		var full_t: float = weapon_time[i] * (repair_time_mult if what == "consertar" else 1.0)
		var total := maxf(SaveUtil.num(o, "total", full_t), 1.0)
		queue.append({"what": what, "id": id, "total": total,
			"left": clampf(SaveUtil.num(o, "left", total), 0.0, total),
			"ordered_at": SaveUtil.num(o, "ordered_at", 0.0)})
	wave = maxi(SaveUtil.integer(d, "wave", 0), 0)
	_warned_day = SaveUtil.integer(d, "warned_day", -1)
	start_day = SaveUtil.integer(d, "start_day", -1)
	bosses = {}
	var b := SaveUtil.dict(d, "bosses")  # Bloco 62 (save antigo: nenhum chefe ainda)
	for k in b:
		if String(b[k]) in ["veio", "derrotado", "fugiu"]:
			bosses[str(k)] = String(b[k]) if String(b[k]) != "veio" else "fugiu"  # carregou no meio da noite: conta como fugiu
	last_result = SaveUtil.dict(d, "last_result")
	_boss = null
	invasion_active = false
	if campos().is_empty():
		for pos in SaveUtil.positions(d, "campos", "campo"):  # Bloco 47 (save antigo: um só)
			spawn_campo(pos)
	if arsenais().is_empty():
		for pos in SaveUtil.positions(d, "arsenais", "arsenal"):
			spawn_arsenal(pos)
	_arsenal_refresh()


func _load_pile(src: Dictionary) -> Dictionary:
	var out := {}
	for id in src:
		if id in WEAPON_IDS and id != "porrete":
			var n := maxi(int(SaveUtil.num(src, id, 0.0)), 0)
			if n > 0:
				out[id] = n
	return out
