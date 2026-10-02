extends Node2D
## Plataforma do ABISMO (nível 3, grupo "elevador_abismo"): fica no fundo do nível 2,
## arruinada. O jogador conserta (peças raras + créditos + prata + tempo) e ela vira
## um elevador igual ao do nível 2 (NavigationLink2D, nos dois sentidos).
## Lá embaixo: basalto em brasa, SOLARITA (precisa do Traje de chumbo da Oficina),
## acidentes bem mais comuns e mais graves, e o calor tira o ânimo de quem trabalha lá.

signal opened

const SaveUtil := preload("res://scripts/core/save_util.gd")
const RUIN := preload("res://assets/game/elevador_ruina.png")
const CAGE := preload("res://assets/game/elevador.png")

## Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do abismo).
@export var bottom_position: Vector2 = Vector2(-360, 1500)
@export var link_travel_cost: float = 0.05

@export_group("Conserto")
@export var repair_parts: int = 12
@export var repair_credits: int = 1500
@export var repair_silver: int = 150
@export var repair_time: float = 120.0
## Estágio mínimo da vila pra começar o conserto.
@export var repair_min_stage: int = 4

var panel_id := "abismo"
var unlocked: bool = false

@export_group("Viagem (Bloco 68)")
## Segundos na gaiola por viagem e quantos cabem nela de uma vez (mais gente = espera a próxima).
@export var travel_time: float = 1.6
@export var capacity: int = 4
var _riders: Array = []  # fim da viagem (s do relógio) de quem está na gaiola


## Bloco 68: quanto tempo esse ipezinho fica na gaiola (a viagem + a fila, se lotou).
func ride_wait() -> float:
	var now := Time.get_ticks_msec() / 1000.0
	_riders = _riders.filter(func(t): return t > now)
	var fila := int(_riders.size() / maxi(capacity, 1))
	var espera := travel_time * (1 + fila) / maxf(Engine.time_scale, 0.01)
	_riders.append(now + espera)
	return travel_time * (1 + fila)


## Bloco 68: por que a plataforma ainda está fechada (o nível S3 lê daqui).
func reason_locked() -> String:
	if unlocked:
		return ""
	var r := repair_block_reason()
	return "consertar a plataforma" + ((" (%s)" % r) if r != "" and r != "consertando" else (" (consertando)" if r == "consertando" else ""))
var repairing: bool = false
var repair_left: float = 0.0
var _sound_timer := 0.0

@onready var _top_sprite: Sprite2D = $Top/Sprite
@onready var _top_lamp: PointLight2D = $Top/Lamp
@onready var _top_label: Label = $Top/Label
@onready var _bottom: Node2D = $Bottom
@onready var _bottom_label: Label = $Bottom/Label
@onready var _link: NavigationLink2D = $Link
@onready var _sparks: CPUParticles2D = $Top/Sparks


func _ready() -> void:
	add_to_group("elevador_abismo")
	add_to_group("clickable")
	_top_lamp.add_to_group("cullable_lights")
	_bottom.position = bottom_position - global_position
	_link.start_position = Vector2.ZERO
	_link.end_position = bottom_position - global_position
	_link.bidirectional = true
	_link.travel_cost = link_travel_cost
	_link.enter_cost = 0.0
	_apply(false)


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-26, -64), Vector2(52, 68)).has_point(p)


func level2_open() -> bool:
	var shaft := get_tree().get_first_node_in_group("elevador")
	return shaft != null and shaft.unlocked


## "" = pode consertar; "aberta" / "consertando"; senão o que falta.
func repair_block_reason() -> String:
	if unlocked:
		return "aberta"
	if repairing:
		return "consertando"
	if not level2_open():
		return "o nível 2 ainda está fechado"
	var pq := preload("res://scripts/core/niveis.gd").pesquisa_falta(get_tree(), "S3")  # Bloco 68: o nível pede pesquisa
	if pq != "":
		return pq
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < repair_min_stage:
		return "requer vila nível %d" % repair_min_stage
	var parts: Array[String] = []
	var finds := get_tree().get_first_node_in_group("finds")
	if finds and finds.rare_parts < repair_parts:
		parts.append("%d peças raras" % (repair_parts - finds.rare_parts))
	var eco := get_tree().get_first_node_in_group("economy")
	if eco:
		var m: String = eco.missing_text(repair_credits, repair_silver, "prata")
		if m != "":
			parts.append(m.trim_prefix("falta "))
	return "falta " + ", ".join(parts) if not parts.is_empty() else ""


func start_repair() -> bool:
	if repair_block_reason() != "":
		Audio.error()
		return false
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(repair_credits, repair_silver, "prata"):
		return false
	get_tree().get_first_node_in_group("finds").spend_parts(repair_parts)
	repairing = true
	repair_left = repair_time
	_apply(false)
	return true


func repair_progress() -> float:
	return clampf(1.0 - repair_left / repair_time, 0.0, 1.0) if repairing else (1.0 if unlocked else 0.0)


func _process(delta: float) -> void:
	if not repairing:
		return
	repair_left -= delta
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = 0.8 * randf_range(0.8, 1.2)
		Audio.forge(global_position)
	_top_label.text = "Consertando a plataforma  %d%%" % roundi(repair_progress() * 100.0)
	if repair_left <= 0.0:
		repairing = false
		unlocked = true
		_apply(true)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_banner("O ABISMO ABRIU!",
				"A plataforma desce pro nível 3. Lá tem SOLARITA (precisa do Traje de chumbo), mas o calor e os acidentes são brutais.")
		Audio.fanfare()
		opened.emit()


func _apply(animate: bool) -> void:
	_top_sprite.texture = CAGE if unlocked else RUIN
	_top_lamp.enabled = unlocked
	_link.enabled = unlocked
	_sparks.emitting = repairing
	if unlocked:
		_top_label.text = "descida pro ABISMO (nível 3)"
		_top_label.modulate = Color(1.0, 0.65, 0.4)
	elif not repairing:
		_top_label.text = "Plataforma arruinada\nclique pra consertar"
		_top_label.modulate = Color(0.8, 0.75, 0.7)
	_bottom_label.text = "Nível 3 — o ABISMO" if unlocked else "Nível 3 — sem acesso (a plataforma lá em cima está arruinada)"
	_bottom_label.modulate = Color(1.0, 0.6, 0.4, 0.95) if unlocked else Color(1, 0.55, 0.45, 0.8)
	if animate:
		_top_sprite.scale = Vector2(2.6, 1.4)
		create_tween().tween_property(_top_sprite, "scale", Vector2(2, 2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Audio.forge(global_position)
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed(animate)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"unlocked": unlocked, "repairing": repairing, "repair_left": repair_left}


func load_save_data(d: Dictionary) -> void:
	unlocked = SaveUtil.boolean(d, "unlocked", false)
	repairing = SaveUtil.boolean(d, "repairing", false) and not unlocked
	repair_left = clampf(SaveUtil.num(d, "repair_left", repair_time), 0.0, repair_time) if repairing else 0.0
	_apply(false)
