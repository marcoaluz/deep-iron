extends "res://scripts/props/station.gd"

signal stored_changed(total: float)

@export var DEPOSIT_RATE: float = 10.0
## Quantidade armazenada para cada estágio da pilha de minério (1, 2, 3).
@export var pile_thresholds: Array[float] = [1.0, 60.0, 200.0]
## Intervalo entre os textos flutuantes "+N".
@export var popup_interval: float = 0.8

var total_stored: float = 0.0
var _pending_popup: float = 0.0
var _popup_timer: float = 0.0

@onready var _label: Label = $AmountLabel
@onready var _visual: Sprite2D = $Visual
@onready var _pile: Sprite2D = $OrePile


func _ready() -> void:
	super()
	add_to_group("armazens")
	_update_label()


func _accepts(body: Node2D) -> bool:
	return body.has_method("deposit")


func _process(delta: float) -> void:
	var received := 0.0
	for body in _working_bodies():
		received += body.deposit(DEPOSIT_RATE * delta)
	if received > 0.0:
		total_stored += received
		_pending_popup += received
		_update_label()
		stored_changed.emit(total_stored)

	_popup_timer -= delta
	var finished_batch := _popup_timer <= 0.0 and _pending_popup >= 1.0 and received <= 0.0
	if finished_batch or _pending_popup >= 20.0:
		_spawn_popup(int(_pending_popup))
		_pending_popup -= int(_pending_popup)
		_popup_timer = popup_interval


func _update_label() -> void:
	_label.text = "Minério: %d" % int(total_stored)
	var stage := 0
	for t in pile_thresholds:
		if total_stored >= t:
			stage += 1
	_pile.frame = clampi(stage, 0, _pile.hframes - 1)


func _spawn_popup(amount: int) -> void:
	var popup := Label.new()
	popup.text = "+%d" % amount
	popup.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.position = Vector2(-12, -76)
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 26.0, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.chain().tween_callback(popup.queue_free)
	# "pulinho" do prédio
	var bump := create_tween()
	bump.tween_property(_visual, "scale", Vector2(2.1, 1.9), 0.08)
	bump.tween_property(_visual, "scale", Vector2(2, 2), 0.12)
