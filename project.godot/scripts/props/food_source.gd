extends "res://scripts/props/station.gd"
## Ponto de coleta de comida: horta de cogumelos de caverna (grupo "coleta_comida").
##
## Funciona como uma jazida, só que de comida: tem uma quantidade, esgota com a
## colheita, fica um tempo "colhida" e regenera sozinha.
## Bloco 27: dá matéria-prima CRUA (fruta). Só o CAÇADOR colhe (via harvest()) e leva
## pro armazém; o cozinheiro busca lá e prepara no comedouro.
## Bloco 34: a horta fica NA CLAREIRA (main.tscn), junto das árvores e das tocas — os três
## pontos de coleta "de fora". Dentro da mina só fica o preparo (comedouro). A posição
## não vai no save: um save antigo carrega com a horta já no lugar novo.

const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Estufa e cuidado (Bloco 107)")
## Esta é uma ESTUFA (horta coberta): a estação conta pelo `sun.season_estufa_mult` (no inverno rende mais que a horta
## aberta) em vez de `season_garden_mult`.
@export var estufa := false
## Com um AGRICULTOR na vila a horta aberta regenera x isto (ele cuida). A estufa já nasce pro agricultor: não conta.
@export var cuidado_mult: float = 1.25

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
## Bloco 107: tudo que já foi colhido aqui (a telemetria soma; vai pro save).
var total_colhido := 0.0
var _cooldown: float = 0.0
var _hit_time: float = 0.0
var _sound_cd := 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel


func _ready() -> void:
	super()
	add_to_group("coleta_comida")
	add_to_group("estufas" if estufa else "hortas")  # Bloco 107
	food_remaining = food_total
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("harvest")


func is_usable() -> bool:
	return _cooldown <= 0.0 and food_remaining >= minf(min_food_to_harvest, food_total)


func has_food() -> bool:
	return food_remaining > 0.0 and _cooldown <= 0.0


## Bloco 107: quanto a horta (ou a estufa) cresce por segundo agora: a regeneração x a estação (a estufa tem a dela: no
## inverno rende mais que a horta aberta) x o cuidado do agricultor (só a horta aberta).
func regen_por_segundo() -> float:
	var sun := get_tree().get_first_node_in_group("sun")
	var season: float = (sun.estufa_mult() if estufa else sun.garden_mult()) if sun else 1.0  # inverno quase para a horta
	if not estufa and _tem_agricultor():
		season *= cuidado_mult
	return regen_rate * season


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	elif regen_rate > 0.0 and food_remaining < food_total:
		food_remaining = minf(food_remaining + regen_por_segundo() * delta, food_total)

	var harvesting := false
	if food_remaining > 0.0 and _cooldown <= 0.0:
		for body in _working_bodies():
			var taken: float = body.harvest(minf(HARVEST_RATE * delta, food_remaining))
			if taken > 0.0:
				harvesting = true
			food_remaining -= taken
			total_colhido += taken  # Bloco 107
			if food_remaining <= 0.0:
				food_remaining = 0.0
				_cooldown = depleted_cooldown
				break
	_hit_time = _hit_time + delta if harvesting else 0.0
	if harvesting:  # Bloco 55: farfalhar da colheita
		_sound_cd -= delta
		if _sound_cd <= 0.0:
			_sound_cd = randf_range(0.7, 1.1)
			Audio.harvest(global_position)
	_update_visual()


## Bloco 107: tem um agricultor trabalhando na vila? (olha a cada segundo, não a cada quadro)
var _agri_t := 0.0
var _agri := false


func _tem_agricultor() -> bool:
	var agora := Time.get_ticks_msec() / 1000.0
	if agora - _agri_t > 1.0:
		_agri_t = agora
		_agri = get_tree().get_nodes_in_group("ipezinhos").any(func(w): return w.has_method("is_farmer") and w.is_farmer() and not w.injured)
	return _agri


func _update_visual() -> void:
	var ratio := food_remaining / food_total if food_total > 0.0 else 0.0
	# quadro 0 = cheia, 1 = pela metade, 2 = colhida
	_visual.frame = 2 if ratio < 0.15 else (1 if ratio < 0.6 else 0)
	_visual.position.x = sin(_hit_time * 30.0) * 0.8 if _hit_time > 0.0 else 0.0
	if _cooldown > 0.0:
		_label.text = "colhida (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.6, 0.45)
	else:
		_label.text = "%s  %d" % ["Estufa" if estufa else "Horta", int(food_remaining)]
		_label.modulate = Color(0.85, 0.95, 0.75, 0.9)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"food_remaining": food_remaining, "cooldown": _cooldown, "total_colhido": total_colhido}  # Bloco 107


func load_save_data(d: Dictionary) -> void:
	food_remaining = clampf(SaveUtil.num(d, "food_remaining", food_remaining), 0.0, food_total)
	_cooldown = maxf(SaveUtil.num(d, "cooldown", 0.0), 0.0)
	total_colhido = maxf(SaveUtil.num(d, "total_colhido", 0.0), 0.0)  # Bloco 107 (save antigo: zero)
	_update_visual()
