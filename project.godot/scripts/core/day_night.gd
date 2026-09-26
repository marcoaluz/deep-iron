extends Node
## Ciclo dia/noite = turno de trabalho dos ipezinhos.
##
## Um "dia" completo dura day_duration + night_duration segundos reais.
## De dia eles trabalham; ao anoitecer cada ipezinho larga o que está fazendo e
## vai pra casa; ao amanhecer voltam sozinhos ao trabalho.
##
## A luz ambiente (CanvasModulate) muda aos poucos: nos últimos transition_time
## segundos de cada fase ela passa pelo tom de crepúsculo até chegar na cor da
## próxima fase. As tochas, cristais e lanternas continuam iguais — de noite
## elas é que seguram o mapa.
##
## Fica no nó "DayNight" da cena principal (grupo "day_night").

signal phase_changed(is_night: bool)
signal day_started(day: int)

@export_group("Duração (segundos reais)")
@export var day_duration: float = 180.0
@export var night_duration: float = 60.0
## Duração do entardecer/amanhecer (a luz muda nesse trecho final de cada fase).
@export var transition_time: float = 12.0
## Acelera o relógio (2 = passa 2x mais rápido). Útil pra testar.
@export var time_scale: float = 1.0
## Em que ponto do dia o jogo começa (segundos desde o amanhecer).
@export var start_time: float = 0.0

@export_group("Luz ambiente")
@export var ambient_path: NodePath = ^"../Ambient"
@export var day_color: Color = Color(0.4, 0.42, 0.54)
@export var twilight_color: Color = Color(0.3, 0.24, 0.34)
@export var night_color: Color = Color(0.13, 0.15, 0.28)

var day: int = 1
## Segundos desde o amanhecer do dia atual.
var time: float = 0.0
var _night: bool = false
var _ambient: CanvasModulate


func _ready() -> void:
	add_to_group("day_night")
	_ambient = get_node_or_null(ambient_path) as CanvasModulate
	time = clampf(start_time, 0.0, cycle_length() - 0.01)
	_night = time >= day_duration
	_update_ambient()


func _process(delta: float) -> void:
	time += delta * time_scale
	if time >= cycle_length():
		time -= cycle_length()
		day += 1
	var night_now := time >= day_duration
	if night_now != _night:
		_night = night_now
		_announce_phase()
	_update_ambient()


# ------------------------------------------------------------ consulta
func cycle_length() -> float:
	return day_duration + night_duration


func is_night() -> bool:
	return _night


## Segundos até a próxima virada (anoitecer ou amanhecer).
func time_left_in_phase() -> float:
	return (cycle_length() - time) if _night else (day_duration - time)


## 0..1 de quanto da fase atual já passou.
func phase_progress() -> float:
	if _night:
		return (time - day_duration) / night_duration
	return time / day_duration


## Pula direto pra próxima fase (tecla N, pra testar).
func skip_phase() -> void:
	if _night:
		time = 0.0
		day += 1
		_night = false
	else:
		time = day_duration
		_night = true
	_announce_phase()
	_update_ambient()


# ------------------------------------------------------------ internos
func _announce_phase() -> void:
	if not _night:
		day_started.emit(day)
	phase_changed.emit(_night)
	# avisa os ipezinhos (duck typing, igual às estações)
	for worker in get_tree().get_nodes_in_group("ipezinhos"):
		if worker.has_method("on_phase_changed"):
			worker.on_phase_changed(_night)


func _update_ambient() -> void:
	if _ambient == null:
		return
	var from := night_color if _night else day_color
	var to := day_color if _night else night_color
	var left := time_left_in_phase()
	var c := from
	if left < transition_time and transition_time > 0.0:
		var t := 1.0 - left / transition_time  # 0 -> 1 ao longo da transição
		c = from.lerp(twilight_color, t * 2.0) if t < 0.5 else twilight_color.lerp(to, t * 2.0 - 1.0)
	_ambient.color = c
