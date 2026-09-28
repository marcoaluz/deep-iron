extends Node2D
## Gerador do ESCUDO SOLAR (grupo "escudos"): o projeto final. O jogador escolhe o lugar
## (janela do Sol, tecla Y) e constrói 4 etapas, uma por vez (paga ao começar, leva tempo):
## Fundação -> Bobinas -> Núcleo de solarita -> Emissor. Com a última: VITÓRIA (sun.gd).
## Bloco 31b: cada etapa paga vira OBRA — só anda com um engenheiro trabalhando aqui.

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const STAGE_IDS := ["fundacao", "bobinas", "nucleo", "emissor"]
const STAGE_NAMES := {
	"fundacao": "Fundação",
	"bobinas": "Bobinas de cobre",
	"nucleo": "Núcleo de solarita",
	"emissor": "Emissor do escudo",
}

@export_group("Etapas (na ordem de STAGE_IDS)")
## x = créditos, y = minério, z = segundos de obra.
@export var stage_costs: Array[Vector3i] = [
	Vector3i(600, 200, 60),
	Vector3i(900, 150, 80),
	Vector3i(1200, 150, 100),
	Vector3i(2000, 100, 120),
]
@export var stage_ore: Array[String] = ["ferro", "cobre", "solarita", "prata"]
## Extras: madeira (fundação), prata (bobinas), peças raras (núcleo), solarita (emissor).
@export var stage_wood: Array[int] = [100, 0, 0, 0]
@export var bobinas_silver: int = 80
@export var nucleo_parts: int = 15
@export var emissor_solarita: int = 100

var panel_id := "sol"
var built: int = 0  # etapas prontas
var building: String = ""
var build_left: float = 0.0
var _sound_timer := 0.0
var _obra := ObraSite.new()

@onready var _visual: Sprite2D = $Visual
@onready var _glow: PointLight2D = $Glow
@onready var _label: Label = $StatusLabel


func _ready() -> void:
	add_to_group("escudos")
	add_to_group("obras")
	add_to_group("clickable")
	_glow.add_to_group("cullable_lights")
	_update_visual()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-32, -76), Vector2(64, 80)).has_point(p)


## Navegação contorna a base (environment.gd, NAV_EXTRA_GROUPS).
func get_obstacle_outline() -> PackedVector2Array:
	var c := global_position + Vector2(0, -8)
	return PackedVector2Array([c + Vector2(-26, -6), c + Vector2(26, -6), c + Vector2(26, 6), c + Vector2(-26, 6)])


func complete() -> bool:
	return built >= STAGE_IDS.size()


func next_stage() -> String:
	return STAGE_IDS[built] if not complete() else ""


func stage_block_reason(id: String) -> String:
	var i := STAGE_IDS.find(id)
	if i < built:
		return "pronta"
	if building == id:
		return "construindo"
	if building != "":
		return "obra ocupada"
	if i > built:
		return "precisa: %s" % STAGE_NAMES[STAGE_IDS[built]]
	var c := stage_costs[i]
	var eco := get_tree().get_first_node_in_group("economy")
	var parts: Array[String] = []
	if eco:
		var m: String = eco.missing_text(c.x, c.y, stage_ore[i], stage_wood[i])
		if m != "":
			parts.append(m.trim_prefix("falta "))
		if id == "bobinas" and eco.stored_ore("prata") < bobinas_silver:
			parts.append("%d prata" % ceili(bobinas_silver - eco.stored_ore("prata")))
		if id == "emissor" and eco.stored_ore("solarita") < emissor_solarita:
			parts.append("%d solarita" % ceili(emissor_solarita - eco.stored_ore("solarita")))
	var finds := get_tree().get_first_node_in_group("finds")
	if id == "nucleo" and finds and finds.rare_parts < nucleo_parts:
		parts.append("%d peças raras" % (nucleo_parts - finds.rare_parts))
	return "falta " + ", ".join(parts) if not parts.is_empty() else ""


func stage_cost_text(id: String) -> String:
	var i := STAGE_IDS.find(id)
	var c := stage_costs[i]
	var bits: Array[String] = ["%d cr" % c.x, "%d %s" % [c.y, stage_ore[i]]]
	if stage_wood[i] > 0:
		bits.append("%d madeira" % stage_wood[i])
	if id == "bobinas":
		bits.append("%d prata" % bobinas_silver)
	if id == "nucleo":
		bits.append("%d peças raras" % nucleo_parts)
	if id == "emissor":
		bits.append("%d solarita" % emissor_solarita)
	return " + ".join(bits) + "  •  %ds" % c.z


func start_stage(id: String) -> bool:
	if stage_block_reason(id) != "":
		Audio.error()
		return false
	var i := STAGE_IDS.find(id)
	var c := stage_costs[i]
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(c.x, c.y, stage_ore[i], stage_wood[i]):
		return false
	if id == "bobinas":
		eco.spend(0, bobinas_silver, "prata")
	if id == "emissor":
		eco.spend(0, emissor_solarita, "solarita")
	if id == "nucleo":
		get_tree().get_first_node_in_group("finds").spend_parts(nucleo_parts)
	building = id
	build_left = float(c.z)
	_obra.start()
	_update_visual()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Etapa encomendada: %s — precisa de engenheiro (tecla 4)." % STAGE_NAMES[id], Color(1.0, 0.8, 0.45))
	return true


# ------------------------------------------------------------ obra (Bloco 31b)
func obra_pending() -> bool:
	return building != ""


func obra_title() -> String:
	return "Escudo: %s" % STAGE_NAMES.get(building, "etapa")


func obra_progress() -> float:
	return build_progress()


func obra_position(worker: Node) -> Vector2:
	return global_position + Vector2(0, 30) + _obra.offset_for(worker)


## O engenheiro trabalhou `seconds` aqui: só assim a etapa anda.
func obra_work(seconds: float) -> void:
	if building == "":
		return
	build_left -= seconds
	if build_left <= 0.0:
		_finish_stage()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


func _finish_stage() -> void:
	built += 1
	building = ""
	build_left = 0.0
	pop_in()
	_update_visual()
	if complete():
		var sun := get_tree().get_first_node_in_group("sun")
		if sun:
			sun.win()


func build_progress() -> float:
	if building == "":
		return 0.0
	var total := float(stage_costs[STAGE_IDS.find(building)].z)
	return clampf(1.0 - build_left / total, 0.0, 1.0)


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.3)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if building == "":
		if complete():
			_glow.energy = 0.9 + 0.3 * sin(Time.get_ticks_msec() * 0.003)
		return
	# a etapa só anda com engenheiro (obra_work); aqui só o som e o texto
	if _obra.has_engineer():
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = 0.8 * randf_range(0.8, 1.2)
			Audio.forge(global_position)
	_update_label()


func _update_visual() -> void:
	_visual.frame = clampi(built, 0, 4)
	_glow.enabled = built >= 3
	_glow.color = Color(0.55, 0.85, 1.0) if complete() else Color(1.0, 0.6, 0.3)
	_update_label()


func _update_label() -> void:
	if complete():
		_label.text = "ESCUDO SOLAR\nativo"
		_label.modulate = Color(0.6, 0.9, 1.0)
	elif building != "":
		_label.text = "Gerador do escudo\n%s  %s" % [STAGE_NAMES[building], _obra.status(build_progress())]
		_label.modulate = Color(1.0, 0.8, 0.5) if _obra.has_engineer() else Color(1.0, 0.62, 0.3)
	else:
		_label.text = "Gerador do escudo\n%d/4 etapas" % built
		_label.modulate = Color(0.9, 0.85, 0.75)


# ------------------------------------------------------------ save/load (via sun.gd)
func get_save_data() -> Dictionary:
	return {"position": SaveUtil.vec2_to_array(global_position), "built": built, "building": building, "build_left": build_left,
		"obra": _obra.get_save_data()}


func load_save_data(d: Dictionary) -> void:
	built = clampi(SaveUtil.integer(d, "built", 0), 0, STAGE_IDS.size())
	building = SaveUtil.text(d, "building", "")
	if building not in STAGE_IDS or STAGE_IDS.find(building) != built:
		building = ""
	build_left = maxf(SaveUtil.num(d, "build_left", 0.0), 0.0) if building != "" else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	_update_visual()
