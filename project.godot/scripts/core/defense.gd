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
## Os guardas (ipezinho com a função "guarda") usam a melhor arma forjada aqui.

signal invasion_started(wave: int)
signal invasion_ended(killed: int)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const LUMIVORO := preload("res://scenes/creatures/lumivoro.tscn")
const FERRUGENTO := preload("res://scenes/creatures/ferrugento.tscn")
const CAMPO_SCENE := preload("res://scenes/props/campo_treino.tscn")
const CAMPO_TEXTURE := preload("res://assets/game/campo_treino.png")
const Canteiro := preload("res://scripts/props/canteiro.gd")
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
@export var weapon_time: Array[float] = [0.0, 40.0, 60.0, 80.0]

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

## Armas já forjadas (o porrete já vem).
var weapons: Array = ["porrete"]
var forging: String = ""
var forge_left: float = 0.0
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


func best_weapon() -> String:
	var best := "porrete"
	for id in WEAPON_IDS:
		if weapons.has(id):
			best = id
	return best


func weapon_damage_vs(target: Node) -> float:
	var i := WEAPON_IDS.find(best_weapon())
	var dmg: float = weapon_damage[i]
	if target != null and target.get("kind") == "ferrugento":
		dmg *= weapon_vs_ferrugento[i]
	var res := get_tree().get_first_node_in_group("research")
	if res:
		dmg *= res.guard_damage_mult()  # holofotes
	return dmg


func weapon_reach() -> float:
	return weapon_range[WEAPON_IDS.find(best_weapon())]


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


# ------------------------------------------------------------ armas
func weapon_block_reason(id: String) -> String:
	if weapons.has(id):
		return "pronta"
	if forging == id:
		return "forjando"
	if forging != "":
		return "forja ocupada"
	var i := WEAPON_IDS.find(id)
	var prev: String = WEAPON_IDS[i - 1] if i > 0 else ""
	if prev != "" and not weapons.has(prev):
		return "precisa: %s" % WEAPON_NAMES[prev]
	var c := weapon_costs[i]
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(c.x, c.y, weapon_ore[i], c.z) if eco else "sem recursos"


func start_forge(id: String) -> bool:
	if weapon_block_reason(id) != "":
		Audio.error()
		return false
	var i := WEAPON_IDS.find(id)
	var c := weapon_costs[i]
	if not get_tree().get_first_node_in_group("economy").spend(c.x, c.y, weapon_ore[i], c.z):
		return false
	forging = id
	forge_left = weapon_time[i]
	return true


func forge_progress() -> float:
	if forging == "":
		return 0.0
	var total: float = weapon_time[WEAPON_IDS.find(forging)]
	return clampf(1.0 - forge_left / total, 0.0, 1.0) if total > 0.0 else 1.0


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
	if forging != "":
		forge_left -= delta
		if forge_left <= 0.0:
			weapons.append(forging)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud:
				hud.show_toast("Arma nova: %s! Todos os guardas já usam." % WEAPON_NAMES[forging], Color(0.55, 1.0, 0.5))
			var ofi := get_tree().get_first_node_in_group("oficina")
			Audio.forge(ofi.global_position if ofi else Vector2.ZERO)
			forging = ""
			forge_left = 0.0
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
		"forging": forging,
		"forge_left": forge_left,
		"wave": wave,
		"warned_day": _warned_day,
		"start_day": start_day,
	}
	var c := campo()
	if c:
		d["campo"] = SaveUtil.vec2_to_array(c.global_position)
	return d


func load_save_data(d: Dictionary) -> void:
	weapons = ["porrete"]
	for id in SaveUtil.array(d, "weapons"):
		if id is String and id in WEAPON_IDS and not weapons.has(id):
			weapons.append(id)
	forging = SaveUtil.text(d, "forging", "")
	if forging not in WEAPON_IDS or weapons.has(forging):
		forging = ""
	forge_left = maxf(SaveUtil.num(d, "forge_left", 0.0), 0.0) if forging != "" else 0.0
	wave = maxi(SaveUtil.integer(d, "wave", 0), 0)
	_warned_day = SaveUtil.integer(d, "warned_day", -1)
	start_day = SaveUtil.integer(d, "start_day", -1)
	invasion_active = false
	if d.has("campo") and campo() == null:
		var pos := SaveUtil.vec2(d, "campo", Vector2.INF)
		if pos != Vector2.INF:
			spawn_campo(pos)
