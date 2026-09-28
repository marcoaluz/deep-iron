extends "res://scripts/props/station.gd"
## Toca de caça na clareira (grupo "caca") — Bloco 27.
##
## Funciona como a horta, só que de caça: tem uma quantidade, esgota, fica um tempo
## vazia e regenera — bem mais devagar que a horta, pra não ser sempre a escolha óbvia.
## Só o CAÇADOR com ARCO E FLECHA (Oficina) caça aqui. Cada unidade de caça vale
## meat_raw_value de matéria-prima (fruta vale 1), então rende mais por viagem.

const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Caça")
## Unidades de caça por segundo por caçador.
@export var HUNT_RATE: float = 1.0
## Caça total quando a toca está cheia.
@export var game_total: float = 20.0
## Caça que volta por segundo (a horta volta 0.35/s: aqui é bem mais lento).
@export var regen_rate: float = 0.04
## Segundos vazia depois de esgotar, antes de começar a regenerar.
@export var depleted_cooldown: float = 90.0
## Abaixo disso a toca não atrai caçadores novos.
@export var min_game_to_hunt: float = 4.0
## Matéria-prima que cada unidade de caça rende (uma unidade de fruta rende 1).
@export var meat_raw_value: float = 2.5
## Ferramenta da Oficina exigida pra caçar aqui.
@export var required_tool: String = "arco"

var game_remaining: float = 0.0
var _cooldown: float = 0.0
var _hit_time: float = 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel


func _ready() -> void:
	super()
	add_to_group("caca")
	game_remaining = game_total
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("hunt")


## O caçador já tem arco e flecha (a Oficina fabricou)?
func bow_ready() -> bool:
	var oficina := get_tree().get_first_node_in_group("oficina")
	return oficina != null and oficina.has_tool(required_tool)


func is_usable() -> bool:
	return bow_ready() and _cooldown <= 0.0 and game_remaining >= minf(min_game_to_hunt, game_total)


func accepts_worker(_worker: Node) -> bool:
	return bow_ready()


func has_game() -> bool:
	return game_remaining > 0.0 and _cooldown <= 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	elif regen_rate > 0.0 and game_remaining < game_total:
		game_remaining = minf(game_remaining + regen_rate * delta, game_total)

	var hunting := false
	if game_remaining > 0.0 and _cooldown <= 0.0 and bow_ready():
		for body in _working_bodies():
			var taken: float = body.hunt(minf(HUNT_RATE * delta, game_remaining), meat_raw_value)
			if taken > 0.0:
				hunting = true
			game_remaining -= taken
			if game_remaining <= 0.0:
				game_remaining = 0.0
				_cooldown = depleted_cooldown
				break
	_hit_time = _hit_time + delta if hunting else 0.0
	_update_visual()


func _update_visual() -> void:
	var ratio := game_remaining / game_total if game_total > 0.0 else 0.0
	# quadro 0 = coelho do lado de fora, 1 = só as orelhas, 2 = vazia
	_visual.frame = 2 if (_cooldown > 0.0 or ratio < 0.15) else (1 if ratio < 0.6 else 0)
	_visual.position.x = sin(_hit_time * 30.0) * 0.8 if _hit_time > 0.0 else 0.0
	if not bow_ready():
		_label.text = "Toca\n(precisa de arco)"
		_label.modulate = Color(0.85, 0.8, 0.75, 0.75)
	elif _cooldown > 0.0:
		_label.text = "toca vazia (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.6, 0.45)
	else:
		_label.text = "Toca  %d" % int(game_remaining)
		_label.modulate = Color(0.95, 0.85, 0.7, 0.9)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"game_remaining": game_remaining, "cooldown": _cooldown}


func load_save_data(d: Dictionary) -> void:
	game_remaining = clampf(SaveUtil.num(d, "game_remaining", game_remaining), 0.0, game_total)
	_cooldown = maxf(SaveUtil.num(d, "cooldown", 0.0), 0.0)
	_update_visual()
