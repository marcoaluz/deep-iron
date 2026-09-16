extends Area2D

@export var DEPOSIT_RATE :float = 10.0
var total_stored: float = 0.0

@onready var _label: Label = $AmountLabel
var _depositing_bodies: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_label()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("deposit"):
		_depositing_bodies.append(body)

func _on_body_exited(body: Node2D) -> void:
	_depositing_bodies.erase(body)

func _process(delta: float) -> void:
	for body in _depositing_bodies:
		var amount: float = body.deposit(DEPOSIT_RATE * delta)
		total_stored += amount
		_update_label()

func _update_label() -> void:
	_label.text = "Minério: %d" % int(total_stored)
