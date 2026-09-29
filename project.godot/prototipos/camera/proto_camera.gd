extends Camera2D
## PROTÓTIPO: câmera simples pras duas rotas (roda = zoom no cursor, botão do meio arrasta,
## WASD/setas movem). Igual nas duas, pra comparação ser justa.

var _drag := false
var _drag_from := Vector2.ZERO
var _cam_from := Vector2.ZERO


func _ready() -> void:
	zoom = Vector2.ONE * 1.5
	for a in OS.get_cmdline_user_args():  # (captura) zoom=0.9  cam=x,y
		if a.begins_with("zoom="):
			zoom = Vector2.ONE * float(a.trim_prefix("zoom="))
		elif a.begins_with("cam="):
			var xy := a.trim_prefix("cam=").split(",")
			position = Vector2(float(xy[0]), float(xy[1]))
	make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var before := get_global_mouse_position()
			var z := clampf(zoom.x * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 0.5, 5.0)
			zoom = Vector2(z, z)
			position += before - get_global_mouse_position()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = event.pressed
			_drag_from = event.position
			_cam_from = position
	elif event is InputEventMouseMotion and _drag:
		position = _cam_from - (event.position - _drag_from) / zoom.x


func _process(delta: float) -> void:
	var d := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if Input.is_physical_key_pressed(KEY_A): d.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): d.x += 1.0
	if Input.is_physical_key_pressed(KEY_W): d.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S): d.y += 1.0
	position += d.limit_length(1.0) * 500.0 * delta / zoom.x
