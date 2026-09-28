extends "res://scripts/props/station.gd"
## Oficina de ferramentas (grupo "oficina").
##
## Fabrica ferramentas novas gastando créditos + minério de um tipo específico.
## Cada ferramenta libera um tipo de minério que antes não dava pra minerar:
##   Picareta de aço temperado  -> cobre   (custa ferro)
##   Lampião de segurança       -> carvão  (custa cobre: o carvão vem depois do cobre)
##   Arco e flecha (Bloco 27)   -> caça de animais pro caçador (não libera minério)
## Uma ferramenta por vez; o custo é pago ao começar e ela fica pronta depois de
## alguns segundos na forja. As jazidas consultam is_ore_unlocked() e são avisadas
## (on_unlock_changed) quando algo muda; os ipezinhos, via on_tool_crafted().

signal tool_started(id: String)
signal tool_crafted(id: String)

const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const TOOL_IDS := ["picareta_aco", "lampiao", "broca", "traje", "arco"]
const TOOL_NAMES := {
	"picareta_aco": "Picareta de aço temperado",
	"lampiao": "Lampião de segurança",
	"broca": "Broca manual",
	"traje": "Traje de chumbo",
	"arco": "Arco e flecha",
}
const TOOL_DESCRIPTIONS := {
	"picareta_aco": "Aço duro o bastante pra quebrar os veios de cobre.",
	"lampiao": "Avisa do gás dos veios de carvão. Sem ele, ninguém entra lá.",
	"broca": "Fura a rocha dura do nível 2, onde a prata se esconde.",
	"traje": "Protege do calor e da energia da solarita, lá no abismo (nível 3).",
	"arco": "Deixa o caçador caçar os coelhos das tocas da clareira: rende mais que fruta por viagem.",
}
## O que libera cada ferramenta que NÃO é de minério (texto do painel e do aviso de pronta).
const TOOL_UNLOCK_LABELS := {"arco": "caça de animais"}
## Tipo de minério que cada ferramenta libera (as que liberam outra coisa ficam de fora).
const TOOL_UNLOCKS := {
	"picareta_aco": "cobre",
	"lampiao": "carvao",
	"broca": "prata",
	"traje": "solarita",
}

@export_group("Ferramentas (na ordem de TOOL_IDS)")
## x = créditos, y = quantidade de minério, z = segundos na forja.
@export var tool_costs: Array[Vector3i] = [
	Vector3i(310, 150, 30),  # picareta de aço
	Vector3i(560, 125, 45),  # lampião
	Vector3i(800, 150, 60),  # broca manual
	Vector3i(1400, 120, 75),  # traje de chumbo
	Vector3i(180, 40, 25),  # arco e flecha (Bloco 27)
]
## Tipo do minério gasto em cada ferramenta.
@export var tool_ore_types: Array[String] = ["ferro", "cobre", "carvao", "prata", "ferro"]
## Madeira gasta em cada ferramenta (cabo/estrutura) — referência: 1 madeira pra 5 minério.
@export var tool_wood_costs: Array[int] = [30, 25, 40, 30, 35]
## Estágio mínimo da vila (Centro da Vila) pra fabricar cada ferramenta.
@export var tool_min_stage: Array[int] = [1, 2, 4, 4, 1]

@export_group("Efeitos")
@export var forge_sound_interval: float = 0.7
@export var idle_forge_energy: float = 0.45
@export var active_forge_energy: float = 1.1

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "oficina"
var crafted: Dictionary = {}
var crafting: String = ""
var craft_left: float = 0.0

var _sound_timer: float = 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _sparks: CPUParticles2D = $Sparks
@onready var _forge_light: PointLight2D = $ForgeLight
@onready var _label: Label = $NameLabel


func _ready() -> void:
	super()
	add_to_group("oficina")
	add_to_group("clickable")
	_forge_light.add_to_group("cullable_lights")
	for id in TOOL_IDS:
		crafted[id] = false
	_update_visual()


func _process(delta: float) -> void:
	if crafting == "":
		return
	craft_left -= delta
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = forge_sound_interval * randf_range(0.8, 1.2)
		Audio.forge(global_position)
	# forja tremeluzindo enquanto trabalha
	_forge_light.energy = active_forge_energy * (1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.12)
	if craft_left <= 0.0:
		_finish(crafting)
	else:
		_update_label()


## Área clicável (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-42, -70), Vector2(84, 74)).has_point(p)


# ------------------------------------------------------------ consulta
func has_tool(id: String) -> bool:
	return crafted.get(id, false)


## Ferro está sempre liberado; os outros dependem da ferramenta.
func is_ore_unlocked(ore_type: String) -> bool:
	var tool := tool_for_ore(ore_type)
	return tool == "" or has_tool(tool)


## Ferramenta que libera o minério ("" = não precisa de nenhuma).
func tool_for_ore(ore_type: String) -> String:
	for id in TOOL_UNLOCKS:
		if TOOL_UNLOCKS[id] == ore_type:
			return id
	return ""


## Texto do que a ferramenta libera ("Cobre", "caça de animais"...).
func unlock_label(id: String) -> String:
	if TOOL_UNLOCKS.has(id):
		return Ores.display_name(TOOL_UNLOCKS[id])
	return TOOL_UNLOCK_LABELS.get(id, "?")


func tool_cost(id: String) -> Vector3i:
	return tool_costs[TOOL_IDS.find(id)]


func tool_ore_type(id: String) -> String:
	return tool_ore_types[TOOL_IDS.find(id)]


func tool_wood(id: String) -> int:
	var i := TOOL_IDS.find(id)
	return tool_wood_costs[i] if i < tool_wood_costs.size() else 0


func tool_stage(id: String) -> int:
	return tool_min_stage[TOOL_IDS.find(id)]


func craft_progress() -> float:
	if crafting == "":
		return 0.0
	var total := float(tool_cost(crafting).z)
	return clampf(1.0 - craft_left / total, 0.0, 1.0) if total > 0.0 else 1.0


## "" se dá pra fabricar agora; senão o motivo.
func tool_block_reason(id: String) -> String:
	if has_tool(id):
		return "pronta"
	if crafting == id:
		return "fabricando"
	if crafting != "":
		return "forja ocupada"
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < tool_stage(id):
		return "requer vila nível %d" % tool_stage(id)
	var cost := tool_cost(id)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return "sem recursos"
	var missing: String = eco.missing_text(cost.x, cost.y, tool_ore_type(id), tool_wood(id))
	if missing != "":
		return missing
	return ""


# ------------------------------------------------------------ ações
func start_tool(id: String) -> bool:
	if tool_block_reason(id) != "":
		Audio.error()
		return false
	var cost := tool_cost(id)
	if not get_tree().get_first_node_in_group("economy").spend(cost.x, cost.y, tool_ore_type(id), tool_wood(id)):
		return false
	crafting = id
	craft_left = float(cost.z)
	_sound_timer = 0.0
	_update_visual()
	_popup("Forjando: %s" % TOOL_NAMES[id], Color(1.0, 0.8, 0.45))
	tool_started.emit(id)
	return true


func _finish(id: String) -> void:
	crafted[id] = true
	crafting = ""
	craft_left = 0.0
	_update_visual()
	Audio.recruit()
	_popup("%s pronta! %s liberado" % [TOOL_NAMES[id], unlock_label(id)], Color(0.55, 1.0, 0.5))
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed()
	for worker in get_tree().get_nodes_in_group("ipezinhos"):
		if worker.has_method("on_tool_crafted"):
			worker.on_tool_crafted(id)
	tool_crafted.emit(id)


# ------------------------------------------------------------ visual
func _update_visual() -> void:
	var active := crafting != ""
	_visual.frame = 1 if active else 0
	_sparks.emitting = active
	_forge_light.energy = active_forge_energy if active else idle_forge_energy
	_update_label()


func _update_label() -> void:
	if crafting != "":
		_label.text = "Oficina\n%s  %d%%" % [TOOL_NAMES[crafting], roundi(craft_progress() * 100.0)]
		_label.modulate = Color(1.0, 0.8, 0.5)
	else:
		_label.text = "Oficina"
		_label.modulate = Color(0.9, 0.86, 0.8)


func _popup(text: String, color: Color) -> void:
	var stacked := get_children().filter(func(c): return c.has_meta("popup")).size()
	var popup := Label.new()
	popup.set_meta("popup", true)
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", 14)
	popup.position = Vector2(-130, -110 - stacked * 20)
	popup.size = Vector2(260, 20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 1.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(1.2)
	tween.chain().tween_callback(popup.queue_free)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"crafted": crafted.duplicate(), "crafting": crafting, "craft_left": craft_left}


func load_save_data(d: Dictionary) -> void:
	var saved := SaveUtil.dict(d, "crafted")
	for id in TOOL_IDS:
		crafted[id] = SaveUtil.boolean(saved, id, false)
	crafting = SaveUtil.text(d, "crafting", "")
	if crafting not in TOOL_IDS or has_tool(crafting):
		crafting = ""
	craft_left = maxf(SaveUtil.num(d, "craft_left", 0.0), 0.0) if crafting != "" else 0.0
	_update_visual()
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed(false)
	for worker in get_tree().get_nodes_in_group("ipezinhos"):
		for id in TOOL_IDS:
			if has_tool(id) and worker.has_method("on_tool_crafted"):
				worker.on_tool_crafted(id)
