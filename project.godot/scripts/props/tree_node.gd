extends "res://scripts/props/station.gd"
## Árvore da clareira (grupo "arvores"): dá madeira pro LENHADOR.
##
## Funciona como uma jazida: tem uma quantidade, esgota com o corte (vira toco),
## fica um tempo parada e regenera (cresce de novo) aos poucos.

const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Corte")
## Madeira cortada por segundo por lenhador.
@export var CHOP_RATE: float = 1.5
## Madeira total da árvore crescida.
@export var wood_total: float = 40.0
## Madeira que volta a crescer por segundo (0 = não regenera).
@export var regen_rate: float = 0.15
## Segundos como toco depois de esgotar, antes de começar a crescer de novo.
@export var depleted_cooldown: float = 45.0
## Abaixo disso a árvore não atrai lenhadores novos.
@export var min_wood_to_chop: float = 4.0
## Intervalo entre as machadadas (som).
@export var chop_sound_interval: float = 0.55

var wood_remaining: float = 0.0
var _cooldown: float = 0.0
var _hit_time: float = 0.0
var _sound_timer: float = 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel
@onready var _chips: CPUParticles2D = $Chips


func _ready() -> void:
	super()
	add_to_group("arvores")
	wood_remaining = wood_total
	_visual.flip_h = randf() < 0.5
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("chop")


func is_usable() -> bool:
	return _cooldown <= 0.0 and wood_remaining >= minf(min_wood_to_chop, wood_total)


func has_wood() -> bool:
	return wood_remaining > 0.0 and _cooldown <= 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	elif regen_rate > 0.0 and wood_remaining < wood_total:
		wood_remaining = minf(wood_remaining + regen_rate * delta, wood_total)

	var chopping := false
	if wood_remaining > 0.0 and _cooldown <= 0.0:
		for body in _working_bodies():
			var taken: float = body.chop(minf(CHOP_RATE * delta, wood_remaining))
			if taken > 0.0:
				chopping = true
			wood_remaining -= taken
			if wood_remaining <= 0.0:
				wood_remaining = 0.0
				_cooldown = depleted_cooldown
				break
	_hit_time = _hit_time + delta if chopping else 0.0
	_chips.emitting = chopping
	_sound_timer -= delta
	if chopping and _sound_timer <= 0.0:
		_sound_timer = chop_sound_interval * randf_range(0.85, 1.15)
		Audio.step(global_position)  # "toc" seco de madeira (reaproveita o som de passo)
	_update_visual()


func _update_visual() -> void:
	var ratio := wood_remaining / wood_total if wood_total > 0.0 else 0.0
	# quadro 0 = árvore cheia, 1 = metade dos galhos, 2 = toco
	_visual.frame = 2 if (ratio < 0.15 or _cooldown > 0.0) else (1 if ratio < 0.6 else 0)
	_visual.position.x = sin(_hit_time * 35.0) * 0.8 if _hit_time > 0.0 else 0.0
	if _cooldown > 0.0:
		_label.text = "toco (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.6, 0.45)
	else:
		_label.text = "%d" % int(wood_remaining)
		_label.modulate = Color(0.9, 0.8, 0.65, 0.85)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"wood_remaining": wood_remaining, "cooldown": _cooldown}


func load_save_data(d: Dictionary) -> void:
	wood_remaining = clampf(SaveUtil.num(d, "wood_remaining", wood_remaining), 0.0, wood_total)
	_cooldown = maxf(SaveUtil.num(d, "cooldown", 0.0), 0.0)
	_update_visual()
