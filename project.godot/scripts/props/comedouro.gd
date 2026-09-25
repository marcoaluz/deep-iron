extends "res://scripts/props/station.gd"

@export var FEED_RATE: float = 12.0  # quanto restaura de fome por segundo


func _ready() -> void:
	super()
	add_to_group("comedouros")


func _accepts(body: Node2D) -> bool:
	return body.has_method("feed")


func _process(delta: float) -> void:
	for body in _working_bodies():
		body.feed(FEED_RATE * delta)
