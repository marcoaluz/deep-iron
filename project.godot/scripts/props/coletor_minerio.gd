extends "res://scripts/props/station.gd"
## Coletor de minério (grupo "coletores_minerio") — Bloco 57: broca a vapor em cima de uma jazida.
##
## Um MINERADOR designado (janela do coletor) fica operando: com ele no posto, a máquina tira
## ore_per_sec da jazida mais perto (ou a escolhida) e manda direto pro armazém mais perto, do tipo
## da jazida. Para sem operador, sem jazida no alcance, ou com a jazida esgotada (volta sozinha quando
## ela regenera). A jazida é a mesma dos mineradores manuais: os dois dividem o que ela tem.
## Construída pelo engenheiro (canteiro "coletor_minerio", dono: Centro da Vila), perto de uma jazida
## liberada. Pode ter vários (custo cresce), cada um com o seu operador.

@export_group("Coleta (Bloco 57)")
## Minério por segundo com o operador no posto (antes da zanga/ânimo dele).
@export var ore_per_sec: float = 0.5
## Até onde a broca alcança uma jazida (px da lógica).
@export var reach: float = 230.0

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "coletor_minerio"
var kind := "minerio"
## O minerador designado (null = sem operador).
var operator: Node = null
## Minério produzido desde que foi construída (todos os tipos).
var total_produced: float = 0.0
## Jazida escolhida (posição; INF = a mais perto). Vai no save pela posição.
var chosen_pos := Vector2.INF
var _acc := 0.0
var _producing := false
var _sound_timer := 0.0
var _why := ""

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $StatusLabel
@onready var _smoke: CPUParticles2D = $Smoke


func _ready() -> void:
	super()
	add_to_group("coletores_minerio")
	add_to_group("clickable")
	refresh()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-50, -76), Vector2(100, 80)).has_point(p)


func decor_clear_rect() -> Rect2:
	return Rect2(global_position + Vector2(-52, -78), Vector2(104, 84))


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_miner")


## Só o operador designado usa a vaga.
func accepts_worker(worker: Node) -> bool:
	return worker == operator


func is_usable() -> bool:
	return operator != null


func has_operator() -> bool:
	if operator != null and not is_instance_valid(operator):
		operator = null
	return operator != null


## Designa um minerador pra operar (substitui o anterior; ele sai de outra máquina se estava).
func designate(worker: Node) -> bool:
	if worker == null or not worker.is_miner():
		return false
	if has_operator() and operator != worker:
		release()
	for other in get_tree().get_nodes_in_group("coletores_minerio"):
		if other != self and other.operator == worker:
			other.release()
	operator = worker
	worker.wake_decision()
	refresh()
	return true


func release() -> void:
	var w := operator
	operator = null
	_producing = false
	if w != null and is_instance_valid(w):
		release_slot(w)
		w.wake_decision()
	refresh()


## Jazidas que a broca alcança (liberadas, fora do entulho), da mais perto pra mais longe.
func jazidas_no_alcance() -> Array:
	var out := []
	for j in get_tree().get_nodes_in_group("minerios"):
		if not j.is_unlocked() or j.is_sealed():
			continue
		if j.global_position.distance_to(global_position) <= reach:
			out.append(j)
	out.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	return out


## A jazida que ela está tirando (a escolhida, se ainda dá; senão a mais perto com minério).
func jazida() -> Node:
	var lista := jazidas_no_alcance()
	if chosen_pos != Vector2.INF:
		for j in lista:
			if j.global_position.distance_to(chosen_pos) < 4.0:
				return j
	for j in lista:
		if j.has_ore() and not j.is_depleted():
			return j
	return lista[0] if not lista.is_empty() else null


## Troca pra próxima jazida no alcance (botão da janela).
func choose_next() -> void:
	var lista := jazidas_no_alcance()
	if lista.is_empty():
		return
	var atual := jazida()
	var i := lista.find(atual)
	chosen_pos = lista[(i + 1) % lista.size()].global_position
	refresh()


func _process(delta: float) -> void:
	has_operator()
	_producing = false
	_why = ""
	var j := jazida()
	if not has_operator():
		_why = "sem operador (designe um minerador)"
	elif j == null:
		_why = "nenhuma jazida no alcance"
	elif j.is_depleted() or not j.has_ore():
		_why = "jazida esgotada (volta quando regenerar)"
	else:
		for body in _working_bodies():
			if body == operator and body.get_state() == "operating_ore":
				_producing = true
				body.operate_tick()
				_acc += ore_per_sec * body.work_mult() * delta
		if not _producing:
			_why = "%s: %s" % [operator.display_name, operator.get_state_label()]
	while _producing and _acc >= 1.0:
		_acc -= 1.0
		var got: float = j.extract(1.0)
		if got <= 0.0:
			break
		total_produced += got
		_deliver(got, j.tipo_extraido())  # Bloco 102
	if _producing:
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = 0.95 * randf_range(0.85, 1.15)
			Audio.drill(global_position)
	_visual.frame = 1 if _producing else 0
	_smoke.emitting = _producing
	if Engine.get_process_frames() % 15 == 0:
		refresh()


func _deliver(amount: float, ore: String) -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	var best: Node2D = eco.armazem_com_espaco(global_position, amount) if eco else null  # Bloco 97: só onde cabe
	_sem_espaco = best == null
	if best:
		best.add_ore(amount, ore)


## Texto da placa (e da janela).
## Bloco 97: o armazém estava cheio na última entrega (a máquina para de mandar).
var _sem_espaco := false


func status_text() -> String:
	if has_operator() and _sem_espaco:
		return "parado — armazém cheio (venda, gaste ou amplie o armazém)"
	if _producing and has_operator():
		var j := jazida()
		return "produzindo %.1f %s/s (%s)" % [ore_per_sec * operator.work_mult(), j.nome_visivel().to_lower() if j else "?", operator.display_name]
	return "parado — " + (_why if _why != "" else "sem operador (designe um minerador)")


func refresh() -> void:
	if not is_inside_tree():
		return
	_label.text = "Coletor de minério\n%s\ntotal: %d" % [status_text(), int(total_produced)]
	_label.modulate = Color(0.75, 1.0, 0.6) if _producing else Color(0.9, 0.86, 0.8)


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
