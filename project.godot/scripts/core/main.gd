extends Node2D

signal selection_changed(unit: Node2D)

const SELECT_RADIUS := 22.0
const MARKER_TIME := 0.6

var selected: Node2D = null

var _marker_pos := Vector2.ZERO
var _marker_timer := 0.0

@onready var _camera: Camera2D = $Camera2D
@onready var _environment: Node2D = $World/Environment


func _ready() -> void:
	_camera.bounds = _environment.map_rect


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos := get_global_mouse_position()
			var clicked_unit := _find_ipezinho_at(click_pos)
			if clicked_unit:
				select(clicked_unit)
			elif selected:
				var target := click_pos.clamp(_environment.map_rect.position, _environment.map_rect.end)
				selected.move_to(target)
				_marker_pos = target
				_marker_timer = MARKER_TIME
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			select(null)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_TAB:
				_select_next()
			KEY_F:
				if selected:
					_camera.follow_target = null if _camera.follow_target == selected else selected
			KEY_ESCAPE:
				select(null)


func _find_ipezinho_at(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := SELECT_RADIUS
	for ip in get_tree().get_nodes_in_group("ipezinhos"):
		# o clique conta a partir do meio do corpo (a origem fica no pé)
		var d: float = (ip.global_position + Vector2(0, -14)).distance_to(pos)
		if d <= best_dist:
			best_dist = d
			best = ip
	return best


func select(unit: Node2D) -> void:
	if selected and is_instance_valid(selected):
		selected.set_selected(false)
	if unit == null and _camera.follow_target == selected:
		_camera.follow_target = null
	selected = unit
	if selected:
		selected.set_selected(true)
	selection_changed.emit(selected)


func _select_next() -> void:
	var workers := get_tree().get_nodes_in_group("ipezinhos")
	if workers.is_empty():
		return
	var i := workers.find(selected)
	var next: Node2D = workers[(i + 1) % workers.size()]
	select(next)
	_camera.focus_on(next.global_position)


func _process(delta: float) -> void:
	if _marker_timer > 0.0:
		_marker_timer -= delta
		queue_redraw()


func _draw() -> void:
	if _marker_timer <= 0.0:
		return
	var t := _marker_timer / MARKER_TIME
	draw_set_transform(_marker_pos, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, lerpf(18.0, 6.0, t), 0.0, TAU, 24, Color(1.0, 0.84, 0.25, t), 2.0)
