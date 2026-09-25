extends Node
## Economia do protótipo: vender minério armazenado por créditos e recrutar ipezinhos.
## Fica no nó "Economy" da cena principal (grupo "economy") — ajuste os números no Inspector.

signal credits_changed(credits: float)
signal ore_sold(amount: float, earned: float)
signal worker_recruited(worker: Node2D, cost: int)

@export_group("Venda")
## Créditos por unidade de minério.
@export var ore_price: float = 2.0
@export var starting_credits: float = 0.0
## Vende sozinho o que estiver no armazém a cada auto_sell_interval segundos.
@export var auto_sell: bool = false
@export var auto_sell_interval: float = 4.0

@export_group("Recrutamento")
@export var worker_scene: PackedScene
@export var recruit_base_cost: float = 120.0
## Multiplica o custo a cada ipezinho recrutado (1.5 = +50%).
@export var recruit_cost_growth: float = 1.5
@export var max_workers: int = 24
## Nó onde os novos ipezinhos são criados (precisa ser o nó com y-sort).
@export var spawn_parent: NodePath = ^"../World"

var credits: float = 0.0
var recruited_count: int = 0
var total_earned: float = 0.0
var _auto_timer: float = 0.0


func _ready() -> void:
	add_to_group("economy")
	credits = starting_credits


func _process(delta: float) -> void:
	if not auto_sell:
		return
	_auto_timer -= delta
	if _auto_timer <= 0.0:
		_auto_timer = auto_sell_interval
		if stored_ore() >= 1.0:
			sell_all()


# ------------------------------------------------------------ venda
func stored_ore() -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.total_stored
	return total


func sale_value() -> int:
	return int(floorf(stored_ore()) * ore_price)


func sell_all() -> float:
	var sold := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		var amount: float = a.take_all()
		if amount <= 0.0:
			continue
		sold += amount
		a.show_popup("+%d cr" % int(amount * ore_price), Color(0.55, 1.0, 0.5))
	if sold <= 0.0:
		return 0.0
	var earned := sold * ore_price
	_add_credits(earned)
	total_earned += earned
	ore_sold.emit(sold, earned)
	Audio.sell()
	return earned


func _add_credits(amount: float) -> void:
	credits += amount
	credits_changed.emit(credits)


# ------------------------------------------------------------ recrutamento
func worker_count() -> int:
	return get_tree().get_nodes_in_group("ipezinhos").size()


func recruit_cost() -> int:
	return int(round(recruit_base_cost * pow(recruit_cost_growth, recruited_count)))


func can_recruit() -> bool:
	return worker_scene != null and credits >= recruit_cost() and worker_count() < max_workers


func recruit() -> Node2D:
	if not can_recruit():
		Audio.error()
		return null
	var cost := recruit_cost()
	var parent := get_node_or_null(spawn_parent)
	if parent == null:
		push_warning("Economy: spawn_parent não encontrado")
		return null

	var worker := worker_scene.instantiate() as Node2D
	worker.name = _next_worker_name()
	worker.position = _spawn_position()
	parent.add_child(worker)

	_add_credits(-cost)
	recruited_count += 1
	worker_recruited.emit(worker, cost)
	Audio.recruit()
	return worker


func _spawn_position() -> Vector2:
	var armazem: Node2D = get_tree().get_first_node_in_group("armazens")
	var base := armazem.global_position if armazem else Vector2.ZERO
	return base + Vector2(randf_range(-50.0, 50.0), randf_range(70.0, 95.0))


func _next_worker_name() -> String:
	var n := worker_count() + 1
	var parent := get_node_or_null(spawn_parent)
	while parent and parent.has_node("Ipezinho%d" % n):
		n += 1
	return "Ipezinho%d" % n
