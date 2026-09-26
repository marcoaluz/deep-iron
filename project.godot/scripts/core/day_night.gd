extends Node
## Ciclo dia/noite = turno de trabalho dos ipezinhos.
##
## Um "dia" completo dura day_duration + night_duration segundos reais.
## De dia eles trabalham; ao anoitecer cada ipezinho larga o que está fazendo e
## vai pra casa; ao amanhecer voltam sozinhos ao trabalho.
##
## Iluminação: a partir de `time` sai uma "escuridão" contínua (0 = dia pleno,
## 1 = noite plena). O escurecer começa um pouco ANTES de anoitecer e termina um
## pouco depois (idem pro clarear), então a luz muda aos poucos enquanto a lógica
## de turno (dormir/acordar) continua virando no mesmo instante de sempre.
## Com ela:
##   - a luz ambiente (CanvasModulate "Ambient") vai de day_color -> dusk_color
##     -> night_color à noite, e night_color -> dawn_color -> day_color de manhã;
##   - as tochas (grupo "tochas", montadas pelo Environment) usam torch_level():
##     apagadas de dia, acendendo com fade quando escurece.
## Cristais, janelas e lanternas dos ipezinhos continuam sempre acesos.
##
## Fica no nó "DayNight" da cena principal (grupo "day_night").

signal phase_changed(is_night: bool)
signal day_started(day: int)

const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Duração (segundos reais)")
@export var day_duration: float = 180.0
@export var night_duration: float = 60.0
## Acelera o relógio (2 = passa 2x mais rápido). Útil pra testar.
@export var time_scale: float = 1.0
## Em que ponto do dia o jogo começa (segundos desde o amanhecer).
@export var start_time: float = 0.0

@export_group("Horários da luz (segundos em volta da virada)")
## Começa a escurecer esses segundos ANTES de anoitecer (os ipezinhos ainda trabalham).
@export var dusk_starts_before: float = 25.0
## Termina de escurecer esses segundos DEPOIS de anoitecer.
@export var dusk_ends_after: float = 8.0
## Começa a clarear esses segundos ANTES de amanhecer.
@export var dawn_starts_before: float = 8.0
## Termina de clarear esses segundos DEPOIS de amanhecer.
@export var dawn_ends_after: float = 20.0
## Mudança brusca (tecla N, pular fase) vira um fade: quanto da escuridão muda por segundo.
@export var light_fade_speed: float = 0.5

@export_group("Cores do ambiente")
@export var ambient_path: NodePath = ^"../Ambient"
## Dia: luz quente do sol entrando pela boca da mina (valores > 1 clareiam além do normal).
@export var day_color: Color = Color(0.78, 0.72, 0.56)
## Meio do entardecer (quente, alaranjado/roxo).
@export var dusk_color: Color = Color(0.52, 0.34, 0.34)
## Noite: bem mais escura que antes; tochas, cristais e lanternas seguram o mapa.
@export var night_color: Color = Color(0.07, 0.08, 0.18)
## Meio do amanhecer (mais frio que o entardecer).
@export var dawn_color: Color = Color(0.42, 0.4, 0.5)

@export_group("Tochas")
## Escuridão (0 = dia, 1 = noite) em que as tochas começam a acender...
@export_range(0.0, 1.0) var torch_on_at: float = 0.25
## ...e em que ficam totalmente acesas.
@export_range(0.0, 1.0) var torch_full_at: float = 0.6

var day: int = 1
## Segundos desde o amanhecer do dia atual.
var time: float = 0.0
var _night: bool = false
var _ambient: CanvasModulate
var _darkness: float = 0.0  # mostrada agora (persegue o alvo com light_fade_speed)


func _ready() -> void:
	add_to_group("day_night")
	_ambient = get_node_or_null(ambient_path) as CanvasModulate
	time = clampf(start_time, 0.0, cycle_length() - 0.01)
	_night = time >= day_duration
	snap_lighting()


func _process(delta: float) -> void:
	time += delta * time_scale
	if time >= cycle_length():
		time -= cycle_length()
		day += 1
	var night_now := time >= day_duration
	if night_now != _night:
		_night = night_now
		_announce_phase()
	# persegue o valor certo sem cortes (acelera junto com time_scale pra não ficar pra trás)
	_darkness = move_toward(_darkness, target_darkness(), light_fade_speed * delta * maxf(time_scale, 1.0))
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


## Escuridão mostrada agora: 0 = dia pleno, 1 = noite plena.
func darkness() -> float:
	return _darkness


## Quanto as tochas devem estar acesas agora (0 = apagadas, 1 = acesas).
func torch_level() -> float:
	return smoothstep(torch_on_at, maxf(torch_full_at, torch_on_at + 0.01), _darkness)


## Escuridão "certa" pro horário atual (sem o fade de mudança brusca).
func target_darkness() -> float:
	var cycle := cycle_length()
	var dusk_from := day_duration - clampf(dusk_starts_before, 0.0, day_duration)
	var dusk_to := day_duration + clampf(dusk_ends_after, 0.01, night_duration)
	var dawn_from := -clampf(dawn_starts_before, 0.0, night_duration)
	var dawn_to := clampf(dawn_ends_after, 0.01, day_duration)
	if time < dawn_to:
		return 1.0 - smoothstep(dawn_from, dawn_to, time)  # comecinho do dia: ainda clareando
	if time >= cycle + dawn_from:
		return 1.0 - smoothstep(dawn_from, dawn_to, time - cycle)  # fim da noite: já clareando
	return smoothstep(dusk_from, dusk_to, time)


## Põe a luz direto no valor certo (ao começar e ao carregar save: sem fade).
func snap_lighting() -> void:
	_darkness = target_darkness()
	_update_ambient()


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
	# de manhã (fim da noite / começo do dia) usa o tom de amanhecer; no resto, o de entardecer
	var morning := time < day_duration * 0.5 or time >= cycle_length() - dawn_starts_before
	var twilight := dawn_color if morning else dusk_color
	var k := _darkness
	_ambient.color = day_color.lerp(twilight, k * 2.0) if k < 0.5 else twilight.lerp(night_color, k * 2.0 - 1.0)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"day": day, "time": time}


func load_save_data(d: Dictionary) -> void:
	day = maxi(SaveUtil.integer(d, "day", day), 1)
	time = clampf(SaveUtil.num(d, "time", time), 0.0, cycle_length() - 0.01)
	_night = time >= day_duration  # sem anunciar: os ipezinhos decidem sozinhos no próximo tick
	snap_lighting()
