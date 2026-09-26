extends Node
## Economia do protótipo: vender minério armazenado por créditos e recrutar ipezinhos.
## Fica no nó "Economy" da cena principal (grupo "economy") — ajuste os números no Inspector.

signal credits_changed(credits: float)

const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
signal ore_sold(amount: float, earned: float)
signal worker_recruited(worker: Node2D, cost: int)

@export_group("Venda")
## Créditos por unidade de ferro.
@export var ore_price: float = 2.0
## Créditos por unidade de cobre.
@export var copper_price: float = 4.0
## Créditos por unidade de carvão.
@export var coal_price: float = 3.0
@export var starting_credits: float = 0.0
## Vende sozinho o que estiver no armazém a cada auto_sell_interval segundos.
@export var auto_sell: bool = false
@export var auto_sell_interval: float = 4.0

@export_group("Recrutamento")
@export var worker_scene: PackedScene
@export var recruit_base_cost: float = 150.0
## Multiplica o custo a cada ipezinho recrutado (1.5 = +50%).
@export var recruit_cost_growth: float = 1.5
## Limite inicial; a melhoria "Moradias" do Centro da Vila aumenta.
@export var max_workers: int = 8
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
## Minério guardado nos armazéns: de um tipo, ou de todos com ore_type = "".
func stored_ore(ore_type: String = "") -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		if ore_type == "":
			total += a.total_stored
		else:
			total += a.stock.get(ore_type, 0.0)
	return total


func price_of(ore_type: String) -> float:
	match ore_type:
		"cobre":
			return copper_price
		"carvao":
			return coal_price
	return ore_price


func sale_value() -> int:
	var value := 0.0
	for t in Ores.TYPES:
		value += floorf(stored_ore(t)) * price_of(t)
	return int(value)


func sell_all() -> float:
	var sold := 0.0
	var earned := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		var taken: Dictionary = a.take_all()
		var value := 0.0
		for t in taken:
			sold += taken[t]
			value += taken[t] * price_of(t)
		if value > 0.0:
			a.show_popup("+%d cr" % int(value), Color(0.55, 1.0, 0.5))
		earned += value
	if sold <= 0.0:
		return 0.0
	_add_credits(earned)
	total_earned += earned
	ore_sold.emit(sold, earned)
	Audio.sell()
	return earned


# ------------------------------------------------------------ gastos (Centro da Vila)
## ore_type = "" aceita qualquer minério (custos genéricos do Centro da Vila e da escavadeira).
func can_afford(cost_credits: float, cost_ore: float, ore_type: String = "") -> bool:
	return credits >= cost_credits and stored_ore(ore_type) >= cost_ore


## Paga em créditos + minério do armazém. Retorna false (e não gasta nada) se não der.
## Com ore_type = "", gasta primeiro o minério mais barato.
func spend(cost_credits: float, cost_ore: float, ore_type: String = "") -> bool:
	if not can_afford(cost_credits, cost_ore, ore_type):
		Audio.error()
		return false
	if cost_credits > 0.0:
		_add_credits(-cost_credits)
	var types: Array = [ore_type]
	if ore_type == "":
		types = Ores.TYPES.duplicate()
		types.sort_custom(func(a, b): return price_of(a) < price_of(b))
	var left := cost_ore
	for t in types:
		for a in get_tree().get_nodes_in_group("armazens"):
			if left <= 0.0:
				break
			left -= a.take(left, t)
	return true


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


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {
		"credits": credits,
		"recruited_count": recruited_count,
		"total_earned": total_earned,
		"max_workers": max_workers,
		"auto_sell": auto_sell,
	}


func load_save_data(d: Dictionary) -> void:
	credits = maxf(SaveUtil.num(d, "credits", credits), 0.0)
	recruited_count = maxi(SaveUtil.integer(d, "recruited_count", recruited_count), 0)
	total_earned = SaveUtil.num(d, "total_earned", total_earned)
	max_workers = maxi(SaveUtil.integer(d, "max_workers", max_workers), 1)
	auto_sell = SaveUtil.boolean(d, "auto_sell", auto_sell)
	credits_changed.emit(credits)
