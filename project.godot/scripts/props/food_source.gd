extends "res://scripts/props/station.gd"
## Ponto de coleta de comida: horta de cogumelos de caverna (grupo "coleta_comida").
##
## Funciona como uma jazida, só que de comida: tem uma quantidade, esgota com a
## colheita, fica um tempo "colhida" e regenera sozinha. Só o COZINHEIRO colhe
## (via harvest()); ele leva a comida pro comedouro.

const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Colheita")
## Comida colhida por segundo por cozinheiro.
@export var HARVEST_RATE: float = 3.0
## Comida total quando a horta está cheia.
@export var food_total: float = 150.0
## Comida que volta a crescer por segundo (0 = não regenera).
@export var regen_rate: float = 0.35
## Segundos "colhida" depois de esgotar, antes de começar a regenerar.
@export var depleted_cooldown: float = 25.0
## Abaixo disso a horta não atrai cozinheiros novos.
@export var min_food_to_harvest: float = 5.0

var food_remaining: float = 0.0
var _cooldown: float = 0.0
var _hit_time: float = 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel


func _ready() -> void:
	super()
	add_to_group("coleta_comida")
	food_remaining = food_total
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("harvest")


func is_usable() -> bool:
	return _cooldown <= 0.0 and food_remaining >= minf(min_food_to_harvest, food_total)


func has_food() -> bool:
	return food_remaining > 0.0 and _cooldown <= 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	elif regen_rate > 0.0 and food_remaining < food_total:
		food_remaining = minf(food_remaining + regen_rate * delta, food_total)

	var harvesting := false
	if food_remaining > 0.0 and _cooldown <= 0.0:
		for body in _working_bodies():
			var taken: float = body.harvest(minf(HARVEST_RATE * delta, food_remaining))
			if taken > 0.0:
				harvesting = true
			food_remaining -= taken
			if food_remaining <= 0.0:
				food_remaining = 0.0
				_cooldown = depleted_cooldown
				break
	_hit_time = _hit_time + delta if harvesting else 0.0
	_update_visual()


func _update_visual() -> void:
	var ratio := food_remaining / food_total if food_total > 0.0 else 0.0
	# quadro 0 = cheia, 1 = pela metade, 2 = colhida
	_visual.frame = 2 if ratio < 0.15 else (1 if ratio < 0.6 else 0)
	_visual.position.x = sin(_hit_time * 30.0) * 0.8 if _hit_time > 0.0 else 0.0
	if _cooldown > 0.0:
		_label.text = "colhida (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.6, 0.45)
	else:
		_label.text = "Horta  %d" % int(food_remaining)
		_label.modulate = Color(0.85, 0.95, 0.75, 0.9)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"food_remaining": food_remaining, "cooldown": _cooldown}


func load_save_data(d: Dictionary) -> void:
	food_remaining = clampf(SaveUtil.num(d, "food_remaining", food_remaining), 0.0, food_total)
	_cooldown = maxf(SaveUtil.num(d, "cooldown", 0.0), 0.0)
	_update_visual()
