extends "res://scripts/props/station.gd"
## Coletor de madeira (grupo "coletores") — Bloco 45: serraria a vapor na CLAREIRA.
##
## Um LENHADOR designado (janela do coletor) vai até a máquina e fica operando: enquanto ele
## está no posto, a máquina produz wood_per_sec de madeira e manda direto pro armazém mais
## perto (como a Escavadeira faz com o minério). Sem operador ela para — nada quebra. O
## lenhador manual (cortar árvore e levar) continua existindo em paralelo.
## De noite o operador vai pra casa como todo lenhador (turno extra: continua).
## Construída pelo engenheiro (canteiro "coletor", dono: Centro da Vila); uma por vila.

## Madeira por segundo com o operador no posto (antes da zanga/ânimo dele).
@export var wood_per_sec: float = 0.6

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "coletor"
## O lenhador designado (null = sem operador).
var operator: Node = null
## Madeira produzida desde que foi construída.
var total_produced: float = 0.0
var _acc := 0.0
var _producing := false
var _sound_timer := 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $StatusLabel
@onready var _smoke: CPUParticles2D = $Smoke


func _ready() -> void:
	super()
	add_to_group("coletores")
	add_to_group("clickable")
	refresh()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-50, -76), Vector2(100, 80)).has_point(p)


func decor_clear_rect() -> Rect2:
	return Rect2(global_position + Vector2(-52, -78), Vector2(104, 84))


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_lumber")


## Só o operador designado usa a vaga.
func accepts_worker(worker: Node) -> bool:
	return worker == operator


func is_usable() -> bool:
	return operator != null


func has_operator() -> bool:
	if operator != null and not is_instance_valid(operator):
		operator = null
	return operator != null


## Designa um lenhador pra operar (substitui o anterior).
func designate(worker: Node) -> bool:
	if worker == null or not worker.is_lumber():
		return false
	if has_operator() and operator != worker:
		release()
	operator = worker
	worker.wake_decision()
	refresh()
	return true


## Tira o operador (a máquina para).
func release() -> void:
	var w := operator
	operator = null
	if w != null and is_instance_valid(w):
		release_slot(w)
		w.wake_decision()
	refresh()


func _process(delta: float) -> void:
	has_operator()
	_producing = false
	for body in _working_bodies():
		if body == operator and body.get_state() == "operating":
			_producing = true
			body.operate_tick()
			_acc += wood_per_sec * body.work_mult() * delta
	while _acc >= 1.0:
		_acc -= 1.0
		total_produced += 1.0
		_deliver(1.0)
	if _producing:
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = 1.1 * randf_range(0.8, 1.2)
			Audio.chop(global_position)
	_visual.frame = 1 if _producing else 0
	_smoke.emitting = _producing
	if Engine.get_process_frames() % 15 == 0:
		refresh()


func _deliver(amount: float) -> void:
	var best: Node2D = null
	var best_d := INF
	for a in get_tree().get_nodes_in_group("armazens"):
		var d := global_position.distance_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	if best:
		best.wood_stored += amount
		best._recount()


## Texto da placa (e da janela).
func status_text() -> String:
	if not has_operator():
		return "parado — sem operador (designe um lenhador)"
	if _producing:
		return "produzindo %.1f madeira/s (%s)" % [wood_per_sec * operator.work_mult(), operator.display_name]
	return "parado — %s: %s" % [operator.display_name, operator.get_state_label()]


func refresh() -> void:
	if not is_inside_tree():
		return
	_label.text = "Coletor de madeira\n%s\ntotal: %d" % [status_text(), int(total_produced)]
	_label.modulate = Color(0.75, 1.0, 0.6) if _producing else Color(0.9, 0.86, 0.8)


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
