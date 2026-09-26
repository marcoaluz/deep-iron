extends "res://scripts/props/station.gd"
## Jazida de minério. Esgota com a mineração e regenera aos poucos.
##
## ore_type diz o que ela dá (ferro, cobre, carvão). Tipos que precisam de
## ferramenta ficam BLOQUEADOS (escuros, com cadeado, ninguém minera) até a
## Oficina fabricar a ferramenta certa.

const Ores := preload("res://scripts/core/ores.gd")

signal depleted
signal replenished

@export_group("Mineração")
## Tipo de minério desta jazida: "ferro", "cobre" ou "carvao".
@export_enum("ferro", "cobre", "carvao") var ore_type: String = "ferro"
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
var _unlocked: bool = true

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel
@onready var _chips: CPUParticles2D = $Chips
@onready var _padlock: Sprite2D = $Padlock


func _ready() -> void:
	super()
	add_to_group("minerios")
	ore_remaining = ore_total
	if not textures.is_empty():
		_visual.texture = textures[randi() % textures.size()]
		_visual.flip_h = randf() < 0.5
	_base_scale = _visual.scale
	_chips.color = Ores.CHIP_COLORS.get(ore_type, _chips.color)
	on_unlock_changed.call_deferred()  # a Oficina pode entrar na árvore depois
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("mine")


func is_usable() -> bool:
	return _unlocked and _cooldown <= 0.0 and ore_remaining >= minf(min_ore_to_mine, ore_total)


func is_unlocked() -> bool:
	return _unlocked


## Ipezinho só vem pra cá de mãos vazias ou já carregando o mesmo tipo.
func accepts_worker(worker: Node) -> bool:
	return worker.carrying <= 0.0 or worker.cargo_type == ore_type


## Quanto este minério vale em relação ao ferro (os ipezinhos preferem os mais valiosos).
func get_value_weight() -> float:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return 1.0
	return eco.price_of(ore_type) / maxf(eco.price_of("ferro"), 0.01)


## Chamado pela Oficina quando uma ferramenta fica pronta.
func on_unlock_changed() -> void:
	var oficina := get_tree().get_first_node_in_group("oficina")
	var was := _unlocked
	# sem Oficina no mapa, nada fica bloqueado
	_unlocked = oficina == null or oficina.is_ore_unlocked(ore_type)
	if _unlocked and not was:
		var pop := create_tween()
		_visual.scale = _base_scale * 1.25
		pop.tween_property(_visual, "scale", _base_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_update_visual()


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
	if ore_remaining > 0.0 and _unlocked:
		for body in _working_bodies():
			var amount: float = minf(MINE_RATE * delta, ore_remaining)
			var taken: float = body.mine(amount, ore_type)
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
	_padlock.visible = not _unlocked
	if not _unlocked:
		_visual.modulate = Color(0.42, 0.42, 0.5)
		var oficina := get_tree().get_first_node_in_group("oficina")
		var tool: String = oficina.tool_for_ore(ore_type) if oficina else ""
		_label.text = "%s: precisa de\n%s" % [Ores.display_name(ore_type), oficina.TOOL_NAMES[tool] if tool != "" else "?"]
		_label.modulate = Color(0.75, 0.75, 0.85, 0.8)
		_padlock.position.y = -16.0 + sin(Time.get_ticks_msec() * 0.003) * 1.5
	elif _cooldown > 0.0:
		_visual.modulate = Color(0.45, 0.45, 0.5)
		_label.text = "esgotado (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.55, 0.45)
	else:
		_visual.modulate = Color.WHITE
		_label.text = str(int(ore_remaining))
		_label.modulate = Color(1, 1, 1, 0.9) if is_usable() else Color(1, 0.8, 0.4)
