extends Node2D
## Robô antigo (grupo "robos"): um Ferrugento desligado, achado no fundo da mina.
##
## Ciclo: "found" (caído onde acharam) -> um ipezinho é mandado buscar e carrega
## ("carried", devagar, inclusive pelo elevador) -> "base" (largado ao lado da
## Oficina) -> "repairing" (peças raras + créditos + ferro + tempo) -> "active":
## o GUARDA FERRUGENTO. De dia fica de guarda no Centro da Vila; à noite patrulha
## as casas. Com ele ativo, a vila fica mais tranquila (+ânimo, no morale.gd).
## (As invasões dos próximos blocos vão usar ele como defensor.)
## Bloco 96: o conserto é uma OBRA de engenheiro: o ferro vai nas costas dele (ObraSite) e o tempo só anda com ele
## trabalhando (antes andava sozinho). Save antigo consertando: material todo entregue, falta o engenheiro.

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96
var _obra := ObraSite.new()

@export_group("Conserto")
@export var repair_parts: int = 6
@export var repair_credits: int = 400
@export var repair_ore: int = 60
@export var repair_time: float = 90.0

@export_group("Guarda")
@export var patrol_speed: float = 42.0
## Posto de dia, em relação ao Centro da Vila.
@export var post_offset: Vector2 = Vector2(78, 46)
## Felicidade somada no alvo de todos com o guarda ativo.
@export var guard_bonus: float = 5.0
## Luta: vida, dano, ritmo e distância em que vê as criaturas. Zerou a vida: desliga até de manhã.
@export var robot_max_hp: float = 80.0
@export var robot_damage: float = 9.0
@export var robot_attack_interval: float = 1.2
@export var robot_aggro: float = 220.0

var panel_id := "robo"
## "found", "carried", "base", "repairing" ou "active".
var state := "found"
## Quem foi mandado buscar / está carregando.
var carrier: Node2D = null
var repair_left := 0.0
var pending_save_data: Dictionary = {}

var _patrol_i := 0
var _anim := 0.0
var _sound_timer := 0.0
var _was_night := false
var robot_hp: float = -1.0
var stunned := false
var _foe: Node2D = null
var _attack_cd := 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _eye: PointLight2D = $EyeLight
@onready var _label: Label = $StatusLabel
@onready var _agent: NavigationAgent2D = $Agent


func _ready() -> void:
	add_to_group("robos")
	add_to_group("clickable")
	_eye.add_to_group("cullable_lights")
	if not pending_save_data.is_empty():
		load_save_data(pending_save_data)
		pending_save_data = {}
	_update_visual()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-20, -44), Vector2(40, 48)).has_point(p)


# ------------------------------------------------------------ transporte
## O ipezinho pergunta: ainda preciso de você?
func needs_carrier(worker: Node) -> bool:
	return state in ["found", "carried"] and carrier == worker


## Manda o ipezinho livre mais perto (não machucado, fora de greve) buscar.
func request_carrier() -> Node:
	if state != "found":
		return null
	var morale := get_tree().get_first_node_in_group("morale")
	if morale and morale.on_strike:
		return null
	var best: Node2D = null
	var best_d := INF
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.injured or w.get("holding_robot") != null:
			continue
		var d: float = w.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = w
	if best:
		carrier = best
		best.assign_robot(self)
	return best


func attach(worker: Node2D) -> void:
	carrier = worker
	state = "carried"
	_update_visual()


## Largou no caminho (anoiteceu, machucou, greve...): fica ali até ele voltar.
func detach() -> void:
	if state == "carried":
		state = "found"
	_update_visual()


func drop_point() -> Vector2:
	var ofi := get_tree().get_first_node_in_group("oficina")
	var p: Vector2 = ofi.global_position + Vector2(-72, 36) if ofi else global_position
	return NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, p)


func deliver() -> void:
	state = "base"
	carrier = null
	global_position = drop_point()
	Audio.deposit(global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("O robô chegou na Oficina. Clique nele pra consertar.", Color(0.5, 1.0, 0.95))
	_update_visual()


# ------------------------------------------------------------ conserto
func repair_block_reason() -> String:
	if state != "base":
		return "precisa estar na Oficina"
	var finds := get_tree().get_first_node_in_group("finds")
	var eco := get_tree().get_first_node_in_group("economy")
	var parts: Array[String] = []
	if finds and finds.rare_parts < repair_parts:
		parts.append("%d peças raras" % (repair_parts - finds.rare_parts))
	if eco:
		var m: String = eco.missing_text(repair_credits, repair_ore, "ferro", 0, "ferro")
		if m != "":
			parts.append(m.trim_prefix("falta "))
	return "falta " + " + ".join(parts) if not parts.is_empty() else ""


func start_repair() -> bool:
	if repair_block_reason() != "":
		Audio.error()
		return false
	var finds := get_tree().get_first_node_in_group("finds")
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(repair_credits, repair_ore, "ferro"):
		return false
	finds.spend_parts(repair_parts)
	state = "repairing"
	repair_left = repair_time
	_obra.start()  # Bloco 96: o ferro fica reservado; o engenheiro leva e conserta
	add_to_group("obras")
	_update_visual()
	return true


func _activate() -> void:
	state = "active"
	repair_left = 0.0
	remove_from_group("obras")
	Audio.robot(global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("GUARDA FERRUGENTO ATIVO!",
			"O robô antigo acordou do nosso lado. De dia vigia o Centro da Vila; à noite patrulha as casas.")
	_update_visual()


# ------------------------------------------------------------ tempo
func _process(delta: float) -> void:
	match state:
		"carried":
			if carrier == null or not is_instance_valid(carrier) or carrier.get("holding_robot") != self:
				if carrier != null and not is_instance_valid(carrier):
					carrier = null  # quem carregava sumiu (morreu): precisa mandar outro
				detach()
			else:
				global_position = carrier.global_position + Vector2(-9.0 * carrier.get("_facing"), -3.0)
		"found":
			if carrier != null and not is_instance_valid(carrier):
				carrier = null
		"repairing":
			if _obra.has_engineer():  # Bloco 96: só anda com o engenheiro (obra_work)
				_sound_timer -= delta
				if _sound_timer <= 0.0:
					_sound_timer = 0.9 * randf_range(0.8, 1.2)
					Audio.forge(global_position)
				_visual.frame = 0 if fmod(repair_left, 1.0) > 0.15 else 1  # "pisca" enquanto conserta
		"active":
			_guard(delta)
	_update_label()


func _is_night() -> bool:
	var dn := get_tree().get_first_node_in_group("day_night")
	return dn != null and dn.is_night()


func _patrol_points() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for g in ["casas", "enfermarias", "tavernas", "village_hub"]:
		for n in get_tree().get_nodes_in_group(g):
			pts.append(n.global_position + Vector2(0, 30))
	return pts


func can_fight() -> bool:
	return state == "active" and not stunned


## Criatura bateu no robô.
func take_hit(amount: float, attacker: Node2D) -> void:
	if not can_fight():
		return
	if robot_hp < 0.0:
		robot_hp = robot_max_hp
	robot_hp -= amount
	_foe = attacker
	_visual.modulate = Color(2.0, 0.6, 0.6)
	create_tween().tween_property(_visual, "modulate", Color.WHITE, 0.2)
	if robot_hp <= 0.0:
		stunned = true
		_eye.enabled = false
		_visual.frame = 0
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("O Guarda Ferrugento caiu! Volta a funcionar de manhã.", Color(1.0, 0.6, 0.45))


## Vê criatura por perto: vai lá e bate. true = está lutando (não patrulha).
func _fight(delta: float) -> bool:
	_attack_cd -= delta
	if _foe != null and (not is_instance_valid(_foe) or not _foe.is_alive()):
		_foe = null
	if _foe == null:
		var best_d := robot_aggro
		for c in get_tree().get_nodes_in_group("criaturas"):
			if c.is_alive() and global_position.distance_to(c.global_position) < best_d:
				best_d = global_position.distance_to(c.global_position)
				_foe = c
	if _foe == null:
		return false
	var d := global_position.distance_to(_foe.global_position)
	if d > 22.0:
		if _agent.target_position.distance_to(_foe.global_position) > 8.0:
			_agent.target_position = _foe.global_position
		var next := _agent.get_next_path_position()
		var step := (next - global_position).limit_length(patrol_speed * 1.3 * delta)
		global_position += step
		if absf(step.x) > 0.01:
			_visual.flip_h = step.x < 0.0
		_anim += delta * 8.0
		_visual.frame = 1 + (int(_anim) % 2)
	elif _attack_cd <= 0.0:
		_attack_cd = robot_attack_interval
		_foe.take_hit(robot_damage, self)
		Audio.hit(global_position)
		_visual.position.x = 3.0 * (1.0 if _foe.global_position.x > global_position.x else -1.0)
		create_tween().tween_property(_visual, "position:x", 0.0, 0.15)
	return true


func _guard(delta: float) -> void:
	var night := _is_night()
	if stunned:
		if night:
			return
		stunned = false  # amanheceu: religa
		robot_hp = robot_max_hp
	if robot_hp < 0.0 or not night:
		robot_hp = robot_max_hp
	if _fight(delta):
		return
	_eye.enabled = true
	_eye.energy = 0.9 if night else 0.35
	if night != _was_night:
		_was_night = night
		_agent.target_position = global_position  # recalcula o destino
	var dest: Vector2
	if night:
		var pts := _patrol_points()
		if pts.is_empty():
			return
		_patrol_i %= pts.size()
		dest = pts[_patrol_i]
		if global_position.distance_to(dest) < 10.0:
			_patrol_i = (_patrol_i + 1) % pts.size()
			dest = pts[_patrol_i]
	else:
		var hub := get_tree().get_first_node_in_group("village_hub")
		dest = hub.global_position + post_offset if hub else global_position
	if _agent.target_position.distance_to(dest) > 1.0:
		_agent.target_position = dest
	var moving := false
	if global_position.distance_to(dest) > 4.0 and not _agent.is_navigation_finished():
		var next := _agent.get_next_path_position()
		var step := (next - global_position).limit_length(patrol_speed * delta)
		global_position += step
		moving = step.length() > 0.01
		if absf(step.x) > 0.01:
			_visual.flip_h = step.x < 0.0
	_anim += delta * (6.0 if moving else 0.0)
	_visual.frame = 1 + (int(_anim) % 2) if moving else 1


# ------------------------------------------------------------ visual
func _update_visual() -> void:
	_visual.frame = 1 if state == "active" else 0
	_visual.rotation = 0.0
	_eye.enabled = state == "active"
	_update_label()


func _update_label() -> void:
	match state:
		"found":
			_label.text = "Robô antigo" + ("\n(indo buscar)" if carrier != null else "\nclique pra buscar")
			_label.modulate = Color(0.6, 0.95, 0.9)
		"carried":
			_label.text = ""
		"base":
			_label.text = "Robô antigo\nprecisa de conserto"
			_label.modulate = Color(1.0, 0.8, 0.5)
		"repairing":
			_label.text = "Consertando  %d%%" % roundi((1.0 - repair_left / repair_time) * 100.0)
			_label.modulate = Color(1.0, 0.8, 0.5)
		"active":
			_label.text = "Guarda"
			_label.modulate = Color(0.55, 1.0, 0.95)


# ------------------------------------------------------------ save/load (via finds.gd)
func obra_pending() -> bool:
	return state == "repairing"


func obra_title() -> String:
	return "Consertar o robô"


func obra_progress() -> float:
	return clampf(1.0 - repair_left / repair_time, 0.0, 1.0) if state == "repairing" and repair_time > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return global_position + Vector2(0, 28) + _obra.offset_for(worker)


## Bloco 96: o engenheiro trabalhou `seconds` no conserto.
func obra_work(seconds: float) -> void:
	if state != "repairing":
		return
	repair_left -= seconds
	if repair_left <= 0.0:
		_activate()


## Cancelado: volta a esperar na Oficina; as peças raras voltam (créditos e ferro: ObraSite.cancelar).
func obra_cancelar() -> void:
	state = "base"
	repair_left = 0.0
	remove_from_group("obras")
	var finds := get_tree().get_first_node_in_group("finds")
	if finds:
		finds.rare_parts += repair_parts
	_update_visual()


# ------------------------------------------------------------ obra (Bloco 96: conserto por engenheiro, com material)
func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


func get_save_data() -> Dictionary:
	return {"state": state, "position": SaveUtil.vec2_to_array(global_position), "repair_left": repair_left,
		"obra": _obra.get_save_data()}


## Quem estava sendo carregado volta pro chão (é só mandar buscar de novo).
func load_save_data(d: Dictionary) -> void:
	var s := SaveUtil.text(d, "state", "found")
	state = s if s in ["found", "base", "repairing", "active"] else "found"
	global_position = SaveUtil.vec2(d, "position", global_position)
	repair_left = clampf(SaveUtil.num(d, "repair_left", repair_time), 0.0, repair_time) if state == "repairing" else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))  # Bloco 96 (save antigo: sem material = tudo entregue)
	if state == "repairing":
		add_to_group("obras")
	elif is_in_group("obras"):
		remove_from_group("obras")
	carrier = null
