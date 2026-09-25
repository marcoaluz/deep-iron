extends Camera2D
## Câmera RTS: zoom suave na direção do cursor, pan com botão do meio / setas / WASD,
## pan pela borda da tela (opcional), limites no mapa e seguir o ipezinho selecionado (F).

@export_group("Zoom")
@export var zoom_min: float = 0.6
@export var zoom_max: float = 3.0
@export var start_zoom: float = 1.3
## Multiplicador por "clique" da roda do mouse.
@export var zoom_step: float = 1.15
@export var zoom_smoothing: float = 12.0

@export_group("Pan")
@export var pan_speed: float = 650.0
@export var pan_smoothing: float = 10.0
@export var edge_scroll: bool = false
@export var edge_margin: float = 10.0

@export_group("Limites")
## Área onde o centro da câmera pode ficar (normalmente o mapa). Tamanho zero = sem limite.
@export var bounds: Rect2 = Rect2()
@export var bounds_margin: float = 80.0

var follow_target: Node2D = null

var _target_zoom: float = 1.0
var _target_pos: Vector2
var _zoom_anchor_screen: Vector2
var _panning := false
var _pan_origin := Vector2.ZERO
var _cam_origin := Vector2.ZERO


func _ready() -> void:
	_target_zoom = start_zoom
	zoom = Vector2.ONE * start_zoom
	_target_pos = position
	make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_by(zoom_step, event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_by(1.0 / zoom_step, event.position)
			MOUSE_BUTTON_MIDDLE:
				_panning = event.pressed
				_pan_origin = event.position
				_cam_origin = position
				follow_target = null
	elif event is InputEventMouseMotion and _panning:
		position = _clamp_to_bounds(_cam_origin - (event.position - _pan_origin) / zoom.x)
		_target_pos = position
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_HOME:
				_target_pos = bounds.get_center() if bounds.has_area() else Vector2.ZERO
				follow_target = null


func _zoom_by(factor: float, screen_pos: Vector2) -> void:
	_target_zoom = clampf(_target_zoom * factor, zoom_min, zoom_max)
	_zoom_anchor_screen = screen_pos


func _process(delta: float) -> void:
	# --- zoom suave mantendo o ponto sob o cursor parado
	if not is_equal_approx(zoom.x, _target_zoom):
		var screen_offset := _zoom_anchor_screen - get_viewport_rect().size * 0.5
		if follow_target != null:
			screen_offset = Vector2.ZERO  # seguindo alguém: zoom no centro
		var anchor_world := position + screen_offset / zoom.x
		var z := lerpf(zoom.x, _target_zoom, 1.0 - exp(-zoom_smoothing * delta))
		if absf(z - _target_zoom) < 0.001:
			z = _target_zoom
		zoom = Vector2(z, z)
		var new_pos := anchor_world - screen_offset / z
		_target_pos += new_pos - position
		position = new_pos

	# --- pan por teclado / borda
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D): dir.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):  dir.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):    dir.y -= 1.0
	if edge_scroll and not _panning:
		var mouse := get_viewport().get_mouse_position()
		var size := get_viewport_rect().size
		if mouse.x < edge_margin: dir.x -= 1.0
		elif mouse.x > size.x - edge_margin: dir.x += 1.0
		if mouse.y < edge_margin: dir.y -= 1.0
		elif mouse.y > size.y - edge_margin: dir.y += 1.0
	if dir != Vector2.ZERO:
		follow_target = null
		_target_pos += dir.normalized() * pan_speed * delta / zoom.x

	# --- seguir alvo
	if follow_target != null:
		if is_instance_valid(follow_target):
			_target_pos = follow_target.global_position + Vector2(0, -16)
		else:
			follow_target = null

	_target_pos = _clamp_to_bounds(_target_pos)
	if not _panning:
		position = position.lerp(_target_pos, 1.0 - exp(-pan_smoothing * delta))


func _clamp_to_bounds(p: Vector2) -> Vector2:
	if not bounds.has_area():
		return p
	var r := bounds.grow(bounds_margin)
	return p.clamp(r.position, r.end)


func focus_on(world_pos: Vector2) -> void:
	_target_pos = _clamp_to_bounds(world_pos)
