extends Camera2D

const ZOOM_MIN    := Vector2(0.25, 0.25)
const ZOOM_MAX    := Vector2(2.5,  2.5)
const ZOOM_STEP   := 0.12
const PAN_SPEED   := 500.0

var _panning      := false
var _pan_origin   := Vector2.ZERO
var _cam_origin   := Vector2.ZERO

func _ready() -> void:
	zoom = Vector2(0.8, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom = (zoom + Vector2(ZOOM_STEP, ZOOM_STEP)).clamp(ZOOM_MIN, ZOOM_MAX)
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom = (zoom - Vector2(ZOOM_STEP, ZOOM_STEP)).clamp(ZOOM_MIN, ZOOM_MAX)
			MOUSE_BUTTON_MIDDLE:
				_panning      = event.pressed
				_pan_origin   = event.position
				_cam_origin   = position

	if event is InputEventMouseMotion and _panning:
		position = _cam_origin - (event.position - _pan_origin) / zoom

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	if dir != Vector2.ZERO:
		position += dir * PAN_SPEED * delta / zoom.x
