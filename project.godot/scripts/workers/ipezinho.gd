extends CharacterBody2D

const SPEED := 120.0
const HUNGER_MAX      := 100.0
const HUNGER_DECAY    := 1.5   # quanto perde por segundo (100 → 0 em ~67s, ajustamos depois)
const CARGO_CAPACITY := 20.0

@onready var _hunger_label: Label = $HungerLabel
@onready var _cargo_label: Label = $CargoLabel

var _target  : Vector2 = Vector2.ZERO
var _moving  : bool    = false
var hunger   : float   = HUNGER_MAX
var carrying: float = 0.0

func _ready() -> void:
	_target = global_position
	_update_hunger_label()

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

func _process(delta: float) -> void:
	hunger = max(hunger - HUNGER_DECAY * delta, 0.0)
	_update_hunger_label()
	if hunger <= 0.0:
		_on_starving()

func _update_hunger_label() -> void:
	_hunger_label.text = str(int(hunger))

#Comida
func _on_starving() -> void:
	_hunger_label.modulate = Color.RED
func feed(amount: float) -> void:
	hunger = min(hunger + amount, HUNGER_MAX)
	_hunger_label.modulate = Color.WHITE
#
#Cargo

func mine(amount: float) -> float:
	var space := CARGO_CAPACITY - carrying
	var taken: float = min(amount, space)
	carrying += taken
	_update_cargo_label()
	return taken

func deposit(amount: float) -> float:
	var given: float = min(amount, carrying)
	carrying -= given
	_update_cargo_label()
	return given

func _update_cargo_label() -> void:
	_cargo_label.text = "Carga: %d" % int(carrying)
