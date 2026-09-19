extends Area2D

@export var MINE_RATE: float = 4.0
@export var ore_total: float = 200.0

var ore_remaining: float = ore_total

@onready var _label: Label = $AmountLabel
var _mining_bodies: Array[Node2D] = []

func _ready() -> void:
	add_to_group("minerios")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_label()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("mine"):
		_mining_bodies.append(body)

func _on_body_exited(body: Node2D) -> void:
	_mining_bodies.erase(body)

func _process(delta: float) -> void:
	if ore_remaining <= 0.0:
		return
	for body in _mining_bodies:
		var amount :float = min(MINE_RATE * delta, ore_remaining)
		var taken: float = body.mine(amount)
		ore_remaining -= taken
		_update_label()
		if ore_remaining <= 0.0:
			modulate = Color(0.4, 0.4, 0.4)
			break

func _update_label() -> void:
	_label.text = str(int(ore_remaining))
