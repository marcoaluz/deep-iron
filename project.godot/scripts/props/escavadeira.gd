extends "res://scripts/props/station.gd"
## Canteiro da Escavadeira: projeto de fim de jogo montado peça por peça,
## como uma plataforma de perfuração (grupo "escavadeira").
##
## - 5 peças: Estrutura, Motor, Sistema hidráulico, Cabine e Broca.
## - Cada peça custa créditos + minério do armazém e leva um tempo de fabricação
##   aqui no canteiro (uma peça por vez). Os custos são pagos ao começar.
## - A Estrutura vem primeiro (o resto é montado nela); as outras em qualquer ordem.
## - Cada peça exige um estágio mínimo da vila (Centro da Vila).
## - No mapa, a escavadeira inteira aparece como "projeto" translúcido azulado;
##   cada peça pronta vira sólida. Com as 5, ela liga: a broca gira, a cabine e
##   o giroflex acendem e o sinal `completed` dispara (o HUD mostra a conquista).

signal part_started(id: String)
signal part_installed(id: String)
signal completed

const SaveUtil := preload("res://scripts/core/save_util.gd")
const PART_IDS := ["estrutura", "motor", "hidraulica", "cabine", "broca"]
const PART_NAMES := {
	"estrutura": "Estrutura",
	"motor": "Motor",
	"hidraulica": "Sistema hidráulico",
	"cabine": "Cabine",
	"broca": "Broca",
}
const PART_DESCRIPTIONS := {
	"estrutura": "Torre treliçada e convés de aço. Base de todas as outras peças.",
	"motor": "Motor a diesel que dá força pra broca.",
	"hidraulica": "Cilindros e tanque de óleo que empurram a broca pra baixo.",
	"cabine": "Onde o operador controla a máquina.",
	"broca": "A broca helicoidal gigante. A última peça do projeto.",
}
## "Planta" azulada das peças que ainda não foram feitas (valores > 1 brilham mesmo no escuro).
const GHOST_COLOR := Color(0.75, 1.0, 1.5, 0.4)

@export_group("Peças (na ordem de PART_IDS)")
## Custo de cada peça: x = créditos, y = minério do armazém, z = segundos de fabricação.
@export var part_costs: Array[Vector3i] = [
	Vector3i(500, 190, 45),   # estrutura
	Vector3i(875, 310, 60),   # motor
	Vector3i(750, 375, 50),   # hidráulica
	Vector3i(625, 250, 45),   # cabine
	Vector3i(1500, 625, 90),  # broca
]
## Estágio mínimo da vila pra fabricar cada peça.
@export var part_min_stage: Array[int] = [2, 3, 3, 3, 4]

@export_group("Efeitos")
## Intervalo entre as marteladas enquanto fabrica.
@export var forge_sound_interval: float = 0.8
## Velocidade da animação da broca quando pronta (quadros por segundo).
@export var drill_fps: float = 8.0

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "escavadeira"
var installed: Dictionary = {}
var fabricating: String = ""
var fab_left: float = 0.0
var complete: bool = false

var _sound_timer: float = 0.0
var _anim_time: float = 0.0

@onready var _layers: Dictionary = {
	"estrutura": $Estrutura,
	"hidraulica": $Hidraulica,
	"motor": $Motor,
	"broca": $Broca,
	"cabine": $Cabine,
}
@onready var _sparks: CPUParticles2D = $Sparks
@onready var _dust: CPUParticles2D = $Dust
@onready var _beacon: PointLight2D = $Beacon
@onready var _cab_light: PointLight2D = $CabLight
@onready var _work_light: PointLight2D = $WorkLight
@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("escavadeira")
	add_to_group("clickable")
	for id in PART_IDS:
		installed[id] = false
	for light in [_beacon, _cab_light, _work_light]:
		light.add_to_group("cullable_lights")
	_update_visual()


func _process(delta: float) -> void:
	if fabricating != "":
		fab_left -= delta
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = forge_sound_interval * randf_range(0.8, 1.2)
			Audio.forge(global_position + Vector2(0, -90))
		if fab_left <= 0.0:
			_install(fabricating)
		else:
			# o "projeto" da peça pulsa enquanto é fabricada
			var layer: Sprite2D = _layers[fabricating]
			layer.modulate.a = 0.4 + 0.35 * (sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5)
		_update_label()
	if complete:
		_anim_time += delta
		_layers.broca.frame = int(_anim_time * drill_fps) % 2
		_beacon.energy = 0.9 + 0.6 * absf(sin(_anim_time * 3.0))  # giroflex piscando


## Área clicável (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-80, -192), Vector2(160, 196)).has_point(p)


## Pro ambiente não espalhar pedras/tochas em cima da torre.
func get_clear_center() -> Vector2:
	return global_position + Vector2(0, -90)


func get_clear_radius() -> float:
	return 130.0


# ------------------------------------------------------------ consulta (UI)
func installed_count() -> int:
	var n := 0
	for id in PART_IDS:
		if installed[id]:
			n += 1
	return n


func part_cost(id: String) -> Vector3i:
	return part_costs[PART_IDS.find(id)]


func part_stage(id: String) -> int:
	return part_min_stage[PART_IDS.find(id)]


## 0..1 da peça em fabricação.
func fab_progress() -> float:
	if fabricating == "":
		return 0.0
	var total := float(part_cost(fabricating).z)
	return clampf(1.0 - fab_left / total, 0.0, 1.0) if total > 0.0 else 1.0


## "" se dá pra fabricar agora; senão o motivo.
func part_block_reason(id: String) -> String:
	if installed[id]:
		return "instalada"
	if fabricating == id:
		return "fabricando"
	if fabricating != "":
		return "canteiro ocupado"
	if id != "estrutura" and not installed.estrutura:
		return "precisa da Estrutura"
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < part_stage(id):
		return "requer vila nível %d" % part_stage(id)
	var cost := part_cost(id)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return "sem recursos"
	var missing: String = eco.missing_text(cost.x, cost.y)
	if missing != "":
		return missing
	return ""


# ------------------------------------------------------------ ações
## Paga e começa a fabricar a peça.
func start_part(id: String) -> bool:
	if part_block_reason(id) != "":
		Audio.error()
		return false
	var cost := part_cost(id)
	if not get_tree().get_first_node_in_group("economy").spend(cost.x, cost.y):
		return false
	fabricating = id
	fab_left = float(cost.z)
	_sound_timer = 0.0
	_update_visual()
	_popup("Fabricando: %s" % PART_NAMES[id], Color(1.0, 0.8, 0.45))
	part_started.emit(id)
	return true


func _install(id: String) -> void:
	installed[id] = true
	fabricating = ""
	fab_left = 0.0
	_update_visual()
	var layer: Sprite2D = _layers[id]
	layer.scale = Vector2(2.15, 1.85)
	create_tween().tween_property(layer, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_dust.restart()
	Audio.forge(global_position + Vector2(0, -90))
	_popup("%s instalada!" % PART_NAMES[id], Color(0.55, 1.0, 0.5))
	part_installed.emit(id)
	if installed_count() == PART_IDS.size():
		_complete()


func _complete() -> void:
	complete = true
	_update_visual()
	Audio.fanfare()
	_popup("ESCAVADEIRA PRONTA!", Color(1.0, 0.85, 0.35))
	completed.emit()


# ------------------------------------------------------------ visual
func _update_visual() -> void:
	for id in PART_IDS:
		var layer: Sprite2D = _layers[id]
		layer.modulate = Color.WHITE if installed[id] else GHOST_COLOR
	_layers.cabine.frame = 1 if complete else 0  # janelas acesas + giroflex
	_sparks.emitting = fabricating != ""
	_work_light.enabled = fabricating != ""
	_beacon.enabled = complete
	_cab_light.enabled = complete
	_update_label()


func _update_label() -> void:
	if complete:
		_label.text = "Escavadeira\nPRONTA"
		_label.modulate = Color(1.0, 0.85, 0.4)
	elif fabricating != "":
		_label.text = "Escavadeira  %d/5\n%s  %d%%" % [installed_count(), PART_NAMES[fabricating], roundi(fab_progress() * 100.0)]
		_label.modulate = Color(1.0, 0.8, 0.5)
	else:
		_label.text = "Escavadeira\n%d/5 peças" % installed_count()
		_label.modulate = Color(0.85, 0.85, 0.9)


func _popup(text: String, color: Color) -> void:
	var stacked := get_children().filter(func(c): return c.has_meta("popup")).size()
	var popup := Label.new()
	popup.set_meta("popup", true)
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", 14)
	popup.position = Vector2(-100, -240 - stacked * 20)
	popup.size = Vector2(200, 20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 1.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(1.0)
	tween.chain().tween_callback(popup.queue_free)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"installed": installed.duplicate(), "fabricating": fabricating, "fab_left": fab_left}


## Carregar uma escavadeira pronta NÃO repete a fanfarra nem o banner de conquista.
func load_save_data(d: Dictionary) -> void:
	var saved := SaveUtil.dict(d, "installed")
	for id in PART_IDS:
		installed[id] = SaveUtil.boolean(saved, id, false)
	fabricating = SaveUtil.text(d, "fabricating", "")
	if fabricating not in PART_IDS or installed[fabricating]:
		fabricating = ""
	fab_left = maxf(SaveUtil.num(d, "fab_left", 0.0), 0.0) if fabricating != "" else 0.0
	complete = installed_count() == PART_IDS.size()
	_update_visual()
