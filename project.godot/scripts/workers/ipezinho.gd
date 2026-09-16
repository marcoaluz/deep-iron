extends CharacterBody2D

@export var speed: float = 120.0
@export var hunger_max: float = 100.0
@export var hunger_decay: float = 0.7
@export var cargo_capacity: float = 20.0
@export var loaded_speed_penalty: float = 0.35  # 0.35 = até 35% mais lento com carga cheia

@onready var _hunger_label: Label = $HungerLabel
@onready var _cargo_label: Label = $CargoLabel

var _target  : Vector2 = Vector2.ZERO
var _moving  : bool    = false
var hunger   : float   = 100.0
var carrying : float   = 0.0

func _ready() -> void:
	add_to_group("ipezinhos")
	_target = global_position
	hunger = hunger_max
	_update_hunger_label()
	_update_cargo_label()

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
	velocity = dir.normalized() * _get_effective_speed()
	move_and_slide()

func _get_effective_speed() -> float:
	var load_ratio := carrying / cargo_capacity
	var penalty := 1.0 - (load_ratio * loaded_speed_penalty)
	return speed * penalty

func _process(delta: float) -> void:
	hunger = max(hunger - hunger_decay * delta, 0.0)
	_update_hunger_label()
	if hunger <= 0.0:
		_on_starving()

func _update_hunger_label() -> void:
	_hunger_label.text = str(int(hunger))

func _on_starving() -> void:
	_hunger_label.modulate = Color.RED

func feed(amount: float) -> void:
	hunger = min(hunger + amount, hunger_max)
	_hunger_label.modulate = Color.WHITE

func mine(amount: float) -> float:
	var space := cargo_capacity - carrying
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

func set_selected(is_selected: bool) -> void:
	modulate = Color(1.4, 1.4, 1.4) if is_selected else Color.WHITE
