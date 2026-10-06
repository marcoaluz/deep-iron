extends Node2D
## Parque (grupo "parques") — Bloco 41: lazer PASSIVO. Quem está ao ar livre dentro do
## raio (morale.gd: park_radius) ganha ânimo aos pouquinhos (park_rate por segundo, até
## park_cap), sem precisar ir até lá — diferente da taverna, onde o triste vai e fica.
## Quem aplica é o morale.gd (_park_tick): vários parques não somam, vale um só.
## Construído pelo engenheiro (canteiro "parque"), posicionado como as casas (no raio do
## Centro da Vila). Clicar abre a janela de Bem-estar. Pode ter mais de um.

const SocialSpot := preload("res://scripts/props/social_spot.gd")  # Bloco 85
const IsoArt := preload("res://scripts/iso/iso_art.gd")

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "moral"


func _ready() -> void:
	add_to_group("parques")
	add_child(SocialSpot.criar("parque", "Parque", false, 2, 3, Vector2(0, 10), 1.2))  # Bloco 85
	add_to_group("clickable")
	$Light.add_to_group("cullable_lights")
	queue_redraw()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-50, -72), Vector2(100, 76)).has_point(p)


## Só o tronco da árvore grande bloqueia: o resto do parque é de andar por dentro.
func get_obstacle_outline() -> PackedVector2Array:
	var art := IsoArt.base_rect(self)
	if art.has_area():
		return IsoArt.outline(art)  # Prompt 29: a pegada do desenho novo
	var c := global_position + Vector2(-32, -8)
	return PackedVector2Array([c + Vector2(-4, -3), c + Vector2(4, -3), c + Vector2(4, 3), c + Vector2(-4, 3)])


func decor_clear_rect() -> Rect2:
	var art := IsoArt.base_rect(self)
	return Rect2(global_position + Vector2(-50, -72), Vector2(100, 76)).merge(art) if art.has_area() else Rect2(global_position + Vector2(-50, -72), Vector2(100, 76))


func radius() -> float:
	var m := get_tree().get_first_node_in_group("morale") if is_inside_tree() else null
	return m.park_radius if m else 120.0


## Anel tracejado bem fraco mostrando até onde o parque alegra.
func _draw() -> void:
	var r := radius()
	var n := 48
	for i in n:
		if i % 2 == 0:
			draw_arc(Vector2(0, -10), r, TAU * i / n, TAU * (i + 1) / n, 3, Color(0.6, 1.0, 0.55, 0.13), 1.5)


func pop_in() -> void:
	var v: Sprite2D = $Visual
	v.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(v, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
