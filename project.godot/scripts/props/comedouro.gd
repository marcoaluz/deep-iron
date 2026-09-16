extends Area2D

const FEED_RATE := 25.0  # quanto restaura de fome por segundo

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

var _feeding_bodies: Array[Node2D] = []

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("feed"):
		_feeding_bodies.append(body)

func _on_body_exited(body: Node2D) -> void:
	_feeding_bodies.erase(body)

func _process(delta: float) -> void:
	for body in _feeding_bodies:
		body.feed(FEED_RATE * delta)
