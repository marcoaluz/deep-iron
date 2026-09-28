extends "res://scripts/props/station.gd"
## Comedouro com ESTOQUE de comida (food_stock).
##
## - Quem vem comer só come se houver estoque; cada unidade de comida repõe
##   hunger_per_food de fome. Sem estoque, ninguém come (quem está com fome segue
##   trabalhando, faminto e lento, até alguém repor).
## - Bloco 27: o cozinheiro (estado "cooking") chega com matéria-prima do armazém e
##   PREPARA aqui: a leva leva um tempo (prep_time_per_raw no ipezinho) e só no fim
##   vira comida pronta no estoque.
## - "delivering" ainda descarrega comida pronta (cesta de saves antigos).
## - O sprite mostra cheio / pela metade / vazio.

const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Ritmo")
## Fome restaurada por segundo por ipezinho comendo.
@export var FEED_RATE: float = 12.0
## Quanta fome cada unidade de comida repõe (5 -> uma refeição de 30 a 95 gasta ~13 de comida).
@export var hunger_per_food: float = 5.0
## Comida descarregada por segundo pelo cozinheiro.
@export var DELIVER_RATE: float = 8.0

@export_group("Estoque")
## Máximo de comida guardada.
@export var food_capacity: float = 120.0
## Comida no começo de um jogo novo.
@export var start_food: float = 60.0

@export_group("Som")
## Intervalo entre os sons de mastigar enquanto alguém come.
@export var eat_sound_interval: float = 0.9

var food_stock: float = 0.0
var _sound_timer: float = 0.0
var _was_empty: bool = false
## Algum cozinheiro preparando uma leva aqui agora (a placa mostra "preparando...").
var is_cooking: bool = false

@onready var _visual: Sprite2D = $Visual
@onready var _name_label: Label = $NameLabel


func _ready() -> void:
	super()
	add_to_group("comedouros")
	food_stock = clampf(start_food, 0.0, food_capacity)
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("feed")


## Quem vem comer precisa de estoque; o cozinheiro precisa de espaço pra descarregar.
func accepts_worker(worker: Node) -> bool:
	if worker.has_method("get_state") and worker.get_state() in ["delivering", "cooking"]:
		return food_stock < food_capacity - 0.5
	return food_stock > 0.0


func has_food() -> bool:
	return food_stock > 0.0


func space_left() -> float:
	return maxf(food_capacity - food_stock, 0.0)


func _process(delta: float) -> void:
	var eating := false
	var cooking := false
	for body in _working_bodies():
		if body.has_method("deliver_food") and body.get_state() == "delivering":
			food_stock += body.deliver_food(minf(DELIVER_RATE * delta, space_left()))
			continue
		if body.has_method("cook_tick") and body.get_state() == "cooking":
			food_stock += body.cook_tick(delta, space_left())  # 0 até a leva ficar pronta
			cooking = true
			continue
		if food_stock <= 0.0 or body.hunger >= body.hunger_max:
			continue
		var wanted := minf(FEED_RATE * delta, body.hunger_max - body.hunger)
		var cost := minf(wanted / hunger_per_food, food_stock)
		food_stock -= cost
		body.feed(cost * hunger_per_food)
		eating = true
	food_stock = clampf(food_stock, 0.0, food_capacity)
	is_cooking = cooking
	_sound_timer -= delta
	if eating and _sound_timer <= 0.0:
		_sound_timer = eat_sound_interval * randf_range(0.8, 1.2)
		Audio.eat(global_position)
	_update_visual()


func _update_visual() -> void:
	var ratio := food_stock / food_capacity if food_capacity > 0.0 else 0.0
	# quadro 0 = cheio, 1 = pela metade, 2 = vazio
	_visual.frame = 2 if food_stock <= 0.0 else (1 if ratio < 0.5 else 0)
	var empty := food_stock <= 0.0
	_name_label.text = "Comedouro\n%s" % ("SEM COMIDA" if empty else "%d / %d" % [int(food_stock), int(food_capacity)])
	if is_cooking:
		_name_label.text += "\npreparando..."
	_name_label.modulate = Color(1.0, 0.45, 0.4) if empty else (Color(1.0, 0.8, 0.45) if ratio < 0.25 else Color.WHITE)
	if empty and not _was_empty:
		var pop := create_tween()
		_name_label.scale = Vector2(1.2, 1.2)
		pop.tween_property(_name_label, "scale", Vector2.ONE, 0.3)
	_was_empty = empty


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"food_stock": food_stock}


func load_save_data(d: Dictionary) -> void:
	food_stock = clampf(SaveUtil.num(d, "food_stock", food_stock), 0.0, food_capacity)
	_update_visual()
