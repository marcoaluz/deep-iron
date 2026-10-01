extends Node2D
## Vestiário (grupo "vestiarios") — Bloco 44: o lugar físico do equipamento do Bloco 42.
## Os casacos e trajes (equipment.gd) ficam guardados AQUI: sem Vestiário construído,
## ninguém pega casaco nem traje e a Oficina não faz equipamento (tem onde guardar não).
## O jogador escolhe o lugar e o engenheiro ergue (canteiro "vestiario"). Clicar abre a
## janela da Oficina, onde está a seção de equipamento. Um só por vila.

const IsoArt := preload("res://scripts/iso/iso_art.gd")

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "oficina"

@onready var _label: Label = $StatusLabel


func _ready() -> void:
	add_to_group("vestiarios")
	add_to_group("clickable")
	$Light.add_to_group("cullable_lights")
	refresh()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-42, -68), Vector2(84, 72)).has_point(p)


func get_obstacle_outline() -> PackedVector2Array:
	var art := IsoArt.base_rect(self)
	if art.has_area():
		return IsoArt.outline(art)  # Prompt 29: a pegada do desenho novo
	var c := global_position + Vector2(-8, -8)
	return PackedVector2Array([c + Vector2(-28, -8), c + Vector2(28, -8), c + Vector2(28, 6), c + Vector2(-28, 6)])


func decor_clear_rect() -> Rect2:
	var art := IsoArt.base_rect(self)
	return Rect2(global_position + Vector2(-44, -70), Vector2(88, 76)).merge(art) if art.has_area() else Rect2(global_position + Vector2(-44, -70), Vector2(88, 76))


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 20 == 0:
		refresh()


func refresh() -> void:
	var eq := get_tree().get_first_node_in_group("equipment") if is_inside_tree() else null
	if eq == null:
		_label.text = "Vestiário"
		return
	var suits := 0
	for t in eq.SUITS:
		suits += eq.available(t)
	_label.text = "Vestiário\ncasacos %d  •  trajes %d" % [eq.available("casaco"), suits]


func pop_in() -> void:
	var v: Sprite2D = $Visual
	v.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(v, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
