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
var _warned_day: int = -1
var _spawn_queue: Array = []  # [{kind, at}]
var _night_time: float = 0.0
var _sound_timer := 0.0


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
	var ars := arsenal()
	if ars and ars.has_method("refresh"):
		ars.refresh()


# ------------------------------------------------------------ construir o Arsenal
func arsenal_block_reason() -> String:
	if arsenal() != null:
		return "construído"
	var c := Canteiro.pending(get_tree(), "arsenal")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(arsenal_credits, arsenal_ore, "ferro", arsenal_wood) if eco else "sem recursos"


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
	if not get_tree().get_first_node_in_group("economy").spend(arsenal_credits, arsenal_ore, "ferro", arsenal_wood):
		return false
	Canteiro.order(get_tree(), "arsenal", pos, arsenal_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Arsenal encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_arsenal(pos: Vector2) -> Node2D:
	var a: Node2D = ARSENAL_SCENE.instantiate()
	a.name = "Arsenal"
	a.position = pos
	get_tree().get_first_node_in_group("village_hub").get_parent().add_child(a)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return a


# ------------------------------------------------------------ campo de treino
func campo_block_reason() -> String:
	if campo() != null:
		return "construído"
	var c := Canteiro.pending(get_tree(), "campo")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(campo_credits, 0, "", campo_wood) if eco else "sem recursos"


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
	if not get_tree().get_first_node_in_group("economy").spend(campo_credits, 0, "", campo_wood):
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
		if arsenal() != null:
			return
		var a := spawn_arsenal(pos)
		a.pop_in()
		Audio.recruit()
		var h := get_tree().get_first_node_in_group("hud")
		if h:
			h.show_toast("Arsenal pronto! Forje armas aqui (G: Defesa); guarda desarmado vem buscar.", Color(0.55, 1.0, 0.5))
		for w in guards():
			w.wake_decision()
		return
	if kind != "campo" or campo() != null:
		return
	var c := spawn_campo(pos)
	c.pop_in()
	Audio.recruit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Campo de treino pronto! Os guardas treinam aqui de dia (tecla X faz guarda).", Color(0.55, 1.0, 0.5))


func spawn_campo(pos: Vector2) -> Node2D:
	var c: Node2D = CAMPO_SCENE.instantiate()
	c.name = "CampoTreino"
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
			and dn.time_left_in_phase() <= warn_before:
		_warned_day = dn.day
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			var ferr := " e os Ferrugentos se mexem no poço" if level2_open() else ""
			hud.show_banner("VEM AÍ UMA INVASÃO",
				"Os Lumívoros se juntam na clareira%s. Esta noite eles atacam — guardas nos portões! (G: Defesa)" % ferr)
		Audio.alarm()
	# criaturas chegando aos poucos
	if invasion_active:
		_night_time += delta
		while not _spawn_queue.is_empty() and _spawn_queue[0].at <= _night_time:
			_spawn(_spawn_queue.pop_front().kind)


func _on_phase_changed(night: bool) -> void:
	var dn := _dn()
	if night and dn and is_invasion_night(dn.day) and not invasion_active:
		start_invasion()
	elif not night and invasion_active:
		end_invasion()


func start_invasion() -> void:
	wave += 1
	invasion_active = true
	killed_tonight = 0
	_night_time = 0.0
	_spawn_queue = []
	var lumi := mini(lumi_base + lumi_per_wave * (wave - 1), lumi_max)
	var ferr := mini(ferr_per_wave * maxi(wave - 1, 1), ferr_max) if level2_open() else 0
	for i in lumi:
		_spawn_queue.append({"kind": "lumivoro", "at": randf_range(0.0, spawn_spread)})
	for i in ferr:
		_spawn_queue.append({"kind": "ferrugento", "at": randf_range(2.0, spawn_spread)})
	_spawn_queue.sort_custom(func(a, b): return a.at < b.at)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("INVASÃO! (onda %d)" % wave, "%d Lumívoros%s. Aguentem até o amanhecer." % [
			lumi, (" e %d Ferrugentos" % ferr) if ferr > 0 else ""])
	Audio.alarm()
	invasion_started.emit(wave)


func _spawn(kind: String) -> void:
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
	world.add_child(c)
	c.setup(g, 1.0 + hp_growth * (wave - 1))
	var res := get_tree().get_first_node_in_group("research")
	if res and kind == "lumivoro":
		c.speed *= res.lumivoro_speed_mult()  # holofotes
	c.died.connect(func(killed: bool):
		if killed:
			killed_tonight += 1)
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		diary.unlock("lumivoros" if kind == "lumivoro" else "ferrugentos")


func end_invasion() -> void:
	invasion_active = false
	_spawn_queue = []
	var left := creatures()
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
	}
	var c := campo()
	if c:
		d["campo"] = SaveUtil.vec2_to_array(c.global_position)
	var a := arsenal()
	if a:
		d["arsenal"] = SaveUtil.vec2_to_array(a.global_position)
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
	invasion_active = false
	if d.has("campo") and campo() == null:
		var pos := SaveUtil.vec2(d, "campo", Vector2.INF)
		if pos != Vector2.INF:
			spawn_campo(pos)
	if d.has("arsenal") and arsenal() == null:
		var apos := SaveUtil.vec2(d, "arsenal", Vector2.INF)
		if apos != Vector2.INF:
			spawn_arsenal(apos)
	_arsenal_refresh()


func _load_pile(src: Dictionary) -> Dictionary:
	var out := {}
	for id in src:
		if id in WEAPON_IDS and id != "porrete":
			var n := maxi(int(SaveUtil.num(src, id, 0.0)), 0)
			if n > 0:
				out[id] = n
	return out
