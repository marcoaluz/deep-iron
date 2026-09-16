extends Node2D

const SELECT_RADIUS := 24.0

var _selected: Node2D = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos := get_global_mouse_position()
		var clicked_unit := _find_ipezinho_at(click_pos)
		if clicked_unit:
			_select(clicked_unit)
		elif _selected:
			_selected.move_to(click_pos)

func _find_ipezinho_at(pos: Vector2) -> Node2D:
	for ip in get_tree().get_nodes_in_group("ipezinhos"):
		if ip.global_position.distance_to(pos) <= SELECT_RADIUS:
			return ip
	return null

func _select(unit: Node2D) -> void:
	if _selected and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = unit
	_selected.set_selected(true)
