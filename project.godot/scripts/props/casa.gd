extends "res://scripts/props/station.gd"
## Casa da vila. Cada slot é uma cama FIXA: o ipezinho reivindica uma cama
## quando nasce (claim_bed) e só a devolve quando sai do jogo.
##
## À noite o ipezinho vai até a porta (posição da cama dele) e "entra": some do
## mapa até amanhecer. Com alguém dentro, a janela acende e sai fumaça da chaminé.

var _inside: Array[Node] = []

@onready var _visual: Sprite2D = $Visual
@onready var _window_light: PointLight2D = $WindowLight
@onready var _smoke: CPUParticles2D = $Smoke
@onready var _sleep_label: Label = $SleepLabel


func _ready() -> void:
	super()
	add_to_group("casas")
	_window_light.add_to_group("cullable_lights")
	_update_visual()


## Reserva uma cama permanente. Retorna o índice ou -1 se a casa estiver cheia.
func claim_bed(worker: Node2D) -> int:
	return reserve_slot(worker)


func beds_total() -> int:
	return slot_count


func beds_taken() -> int:
	return occupied_slot_count()


## Chamado pelo ipezinho ao entrar/sair de casa.
func set_inside(worker: Node, inside: bool) -> void:
	if inside and not _inside.has(worker):
		_inside.append(worker)
	elif not inside:
		_inside.erase(worker)
	_update_visual()


func sleeping_count() -> int:
	_inside = _inside.filter(func(w): return is_instance_valid(w))
	return _inside.size()


func _update_visual() -> void:
	var occupied := sleeping_count() > 0
	_visual.frame = 1 if occupied else 0  # quadro 1 = janelas acesas
	_window_light.enabled = occupied
	_smoke.emitting = occupied
	_sleep_label.visible = occupied
	if occupied:
		_sleep_label.text = "Zz  %d" % sleeping_count()
