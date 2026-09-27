extends "res://scripts/props/station.gd"
## Laboratório (grupo "laboratorios"): onde os PESQUISADORES geram pontos pra pesquisa
## em andamento (research.gd). Posicionado pelo jogador (tecla Q).
## Sem pesquisa escolhida ele fica "fechado" e os pesquisadores voltam a trabalhar.

var panel_id := "lab"

@onready var _visual: Sprite2D = $Visual
@onready var _glow: PointLight2D = $Glow
@onready var _label: Label = $StatusLabel
@onready var _dish: Sprite2D = $Dish


func _ready() -> void:
	super()
	add_to_group("laboratorios")
	add_to_group("clickable")
	_glow.add_to_group("cullable_lights")


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-34, -60), Vector2(68, 64)).has_point(p)


func _research() -> Node:
	return get_tree().get_first_node_in_group("research")


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_researcher")


## Só vale vir pra cá com pesquisa em andamento.
func is_usable() -> bool:
	var r := _research()
	return r != null and r.current != ""


func show_satellite(on: bool) -> void:
	_dish.visible = on


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var r := _research()
	var n := 0
	for body in _working_bodies():
		if body.get_state() == "research":
			n += 1
	if r and n > 0:
		r.add_points(r.points_per_researcher * n * delta)
	var active: bool = r != null and r.current != "" and n > 0
	_visual.frame = 1 if active else 0
	_glow.enabled = active
	if r == null or r.current == "":
		_label.text = "Laboratório\n(sem pesquisa — Q)"
	else:
		_label.text = "Laboratório\n%s %d%%%s" % [r.TECHS[r.current].name, roundi(r.current_progress() * 100.0),
			"" if n > 0 else " (sem pesquisador)"]
