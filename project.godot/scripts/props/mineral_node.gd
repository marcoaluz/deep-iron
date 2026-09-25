extends "res://scripts/props/station.gd"
## Jazida de minério. Esgota com a mineração e regenera aos poucos.

signal depleted
signal replenished

@export_group("Mineração")
@export var MINE_RATE: float = 4.0
@export var ore_total: float = 200.0
## Minério regenerado por segundo (0 = não regenera).
@export var regen_rate: float = 0.6
## Segundos "morta" depois de esgotar, antes de começar a regenerar.
@export var depleted_cooldown: float = 20.0
## Abaixo disso a jazida não atrai novos ipezinhos (quem já está minerando continua).
@export var min_ore_to_mine: float = 15.0

@export_group("Visual")
## Variantes de sprite sorteadas no _ready (vazio = mantém a textura da cena).
@export var textures: Array[Texture2D] = []
@export var min_visual_scale: float = 0.6

var ore_remaining: float = 0.0
var _cooldown: float = 0.0
var _hit_time: float = 0.0
var _base_scale: Vector2

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel
@onready var _chips: CPUParticles2D = $Chips


func _ready() -> void:
	super()
	add_to_group("minerios")
	ore_remaining = ore_total
	if not textures.is_empty():
		_visual.texture = textures[randi() % textures.size()]
		_visual.flip_h = randf() < 0.5
	_base_scale = _visual.scale
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("mine")


func is_usable() -> bool:
	return _cooldown <= 0.0 and ore_remaining >= minf(min_ore_to_mine, ore_total)


func has_ore() -> bool:
	return ore_remaining > 0.0


func is_depleted() -> bool:
	return _cooldown > 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown <= 0.0:
			replenished.emit()
	elif regen_rate > 0.0 and ore_remaining < ore_total:
		ore_remaining = minf(ore_remaining + regen_rate * delta, ore_total)

	var mined_any := false
	if ore_remaining > 0.0:
		for body in _working_bodies():
			var amount: float = minf(MINE_RATE * delta, ore_remaining)
			var taken: float = body.mine(amount)
			if taken > 0.0:
				mined_any = true
			ore_remaining -= taken
			if ore_remaining <= 0.0:
				ore_remaining = 0.0
				_cooldown = depleted_cooldown
				depleted.emit()
				break

	_hit_time = _hit_time + delta if mined_any else 0.0
	_chips.emitting = mined_any
	_update_visual()


func _update_visual() -> void:
	var ratio := ore_remaining / ore_total if ore_total > 0.0 else 0.0
	var s := lerpf(min_visual_scale, 1.0, sqrt(ratio))
	_visual.scale = _base_scale * s
	# tremidinha enquanto alguém bate com a picareta
	_visual.position.x = sin(_hit_time * 40.0) * 1.0 if _hit_time > 0.0 else 0.0
	if _cooldown > 0.0:
		_visual.modulate = Color(0.45, 0.45, 0.5)
		_label.text = "esgotado (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.55, 0.45)
	else:
		_visual.modulate = Color.WHITE
		_label.text = str(int(ore_remaining))
		_label.modulate = Color(1, 1, 1, 0.9) if is_usable() else Color(1, 0.8, 0.4)
