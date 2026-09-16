extends CharacterBody2D

const SPEED := 120.0

var _target  : Vector2 = Vector2.ZERO
var _moving  : bool    = false

func _ready() -> void:
	_target = global_position

func move_to(pos: Vector2) -> void:
	_target  = pos
	_moving  = true

func _physics_process(_delta: float) -> void:
	if not _moving:
		return

	var dir := _target - global_position
	if dir.length() < 4.0:
		velocity = Vector2.ZERO
		global_position = _target
		_moving = false
		return

	velocity = dir.normalized() * SPEED
	move_and_slide()
