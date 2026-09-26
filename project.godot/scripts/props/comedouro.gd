extends "res://scripts/props/station.gd"

@export_group("Ritmo")
@export var FEED_RATE: float = 12.0  # quanto restaura de fome por segundo
@export_group("Som")
## Intervalo entre os sons de mastigar enquanto alguém come.
@export var eat_sound_interval: float = 0.9

var _sound_timer: float = 0.0


func _ready() -> void:
	super()
	add_to_group("comedouros")


func _accepts(body: Node2D) -> bool:
	return body.has_method("feed")


func _process(delta: float) -> void:
	var eating := false
	for body in _working_bodies():
		if body.hunger < body.hunger_max:
			eating = true
		body.feed(FEED_RATE * delta)
	_sound_timer -= delta
	if eating and _sound_timer <= 0.0:
		_sound_timer = eat_sound_interval * randf_range(0.8, 1.2)
		Audio.eat(global_position)
