extends Node
## Ciclo dia/noite = turno de trabalho dos ipezinhos.
##
## Bloco 83: RELÓGIO DE 24 HORAS. Um dia inteiro (24 h de jogo) dura `duracao_dia_real` segundos reais
## (padrão 540 s = 9 min: 1 hora de jogo = 22,5 s). Os MARCOS são horas (@export): amanhecer 05:00, fim do
## expediente 18:00, anoitecer 18:30, dormir 21:30 — e o sinal marco(nome) avisa quando o relógio passa
## por cada um. Semana de 7 dias (o 7º é domingo); semana() conta as semanas desde o começo.
## O "dia" do jogo vira no AMANHECER, como sempre foi: 01:00 ainda é a noite do mesmo dia.
##
## A API de antes continua (o resto do jogo e os testes usam):
##   time               segundos REAIS desde o amanhecer do dia atual
##   day                o dia (1, 2, ...)
##   is_night()         do anoitecer ao amanhecer (é quando todo mundo vai pra casa)
##   day_duration       segundos do amanhecer ao anoitecer — agora CALCULADO pelos marcos (só leitura)
##   night_duration     segundos do anoitecer ao amanhecer (só leitura)
##   cycle_length(), time_left_in_phase(), phase_progress(), darkness(), torch_level(), skip_phase()
##   sinais phase_changed(is_night) e day_started(day)
## Novos: hora(), hora_texto() "hh:mm", dia_semana() 1..7, nome_dia(), semana(), e_domingo(),
## segundos_ate_hora(h), tempo_da_hora(h); pular_dia() (o botão "Pular dia": acelera com a simulação
## rodando de verdade até o próximo amanhecer e para sozinho em invasão, onda solar, ferido grave, morte
## ou greve); e, pros testes, ir_para_hora(h) e avancar(segundos).
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
## Bloco 83: o relógio passou por um marco ("amanhecer", "fim_expediente", "anoitecer", "dormir").
signal marco(nome: String)
## Bloco 83: o "Pular dia" acabou (motivo: "amanheceu", "invasão", "onda solar", "ferido grave"...).
signal pulo_terminou(motivo: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const DIAS := ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]
const DIAS_CURTOS := ["SEG", "TER", "QUA", "QUI", "SEX", "SÁB", "DOM"]
## Versão do relógio no save (sem ela: o ciclo antigo de 180 s de dia + 60 s de noite).
const RELOGIO_VERSAO := 24

@export_group("Relógio de 24 horas (Bloco 83)")
## Segundos REAIS de um dia inteiro (24 h de jogo). 540 = 9 minutos; 1 hora de jogo = 22,5 s.
@export var duracao_dia_real: float = 540.0
## Hora em que amanhece (o turno começa, o dia do jogo vira). 5.0 = 05:00.
@export_range(0.0, 24.0, 0.25) var hora_amanhecer: float = 5.0
## Hora do fim do expediente (a agenda manda voltar e largar a carga). 18.0 = 18:00.
@export_range(0.0, 24.0, 0.25) var hora_fim_expediente: float = 18.0
## Hora em que anoitece (is_night: todo mundo pra casa). 18.5 = 18:30.
@export_range(0.0, 24.0, 0.25) var hora_anoitecer: float = 18.5
## Hora de dormir (a hora social acaba). 21.5 = 21:30.
@export_range(0.0, 24.0, 0.25) var hora_dormir: float = 21.5
## Acelera o relógio (2 = passa 2x mais rápido). Útil pra testar.
@export var time_scale: float = 1.0
## Em que ponto do dia o jogo começa (segundos desde o amanhecer).
@export var start_time: float = 0.0

@export_group("Pular dia (Bloco 83)")
## Velocidade do jogo enquanto pula o dia (Engine.time_scale): a simulação roda de verdade, só mais rápida.
@export var pular_velocidade: float = 8.0

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

@export_group("Estações (Prompt 19)")
## A luz ambiente de cada estação multiplica a do horário: primavera neutra, verão quente e
## claro, outono dourado, inverno frio e azulado. As noites de inverno ficam um pouco mais escuras.
@export var season_tints: Array[Color] = [Color(1, 1, 1), Color(1.04, 1.0, 0.92), Color(1.02, 0.95, 0.86), Color(0.9, 0.95, 1.06)]
@export var winter_night_darker: float = 0.88

@export_group("Tochas")
## Escuridão (0 = dia, 1 = noite) em que as tochas começam a acender...
@export_range(0.0, 1.0) var torch_on_at: float = 0.25
## ...e em que ficam totalmente acesas.
@export_range(0.0, 1.0) var torch_full_at: float = 0.6

var day: int = 1
## Segundos desde o amanhecer do dia atual.
var time: float = 0.0
## Segundos REAIS do amanhecer ao anoitecer (pelos marcos). Só leitura.
var day_duration: float:
	get:
		return _horas_entre(hora_amanhecer, hora_anoitecer) * segundos_por_hora()
## Segundos REAIS do anoitecer ao amanhecer. Só leitura.
var night_duration: float:
	get:
		return maxf(duracao_dia_real - day_duration, 0.01)
## Bloco 83: pulando o dia agora?
var pulando := false
var _night: bool = false
var _ambient: CanvasModulate
var _darkness: float = 0.0  # mostrada agora (persegue o alvo com light_fade_speed)
var _pulo_ate_dia := 0
var _pulo_vel_antes := 1.0
var _pulo_retrato := {}


func _ready() -> void:
	add_to_group("day_night")
	_ambient = get_node_or_null(ambient_path) as CanvasModulate
	time = clampf(start_time, 0.0, cycle_length() - 0.01)
	_night = time >= day_duration
	snap_lighting()


func _process(delta: float) -> void:
	var antes := time
	time += delta * time_scale
	var virou := false
	if time >= cycle_length():
		time -= cycle_length()
		day += 1
		virou = true
	_marcos(antes, time, virou)
	var night_now := time >= day_duration
	if night_now != _night:
		_night = night_now
		_announce_phase()
	# persegue o valor certo sem cortes (acelera junto com time_scale pra não ficar pra trás)
	_darkness = move_toward(_darkness, target_darkness(), light_fade_speed * delta * maxf(time_scale, 1.0))
	_update_ambient()
	if pulando:
		_confere_pulo()


# ------------------------------------------------------------ consulta
func cycle_length() -> float:
	return maxf(duracao_dia_real, 1.0)


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
	var dd := day_duration
	var nd := night_duration
	var dusk_from := dd - clampf(dusk_starts_before, 0.0, dd)
	var dusk_to := dd + clampf(dusk_ends_after, 0.01, nd)
	var dawn_from := -clampf(dawn_starts_before, 0.0, nd)
	var dawn_to := clampf(dawn_ends_after, 0.01, dd)
	if time < dawn_to:
		return 1.0 - smoothstep(dawn_from, dawn_to, time)  # comecinho do dia: ainda clareando
	if time >= cycle + dawn_from:
		return 1.0 - smoothstep(dawn_from, dawn_to, time - cycle)  # fim da noite: já clareando
	return smoothstep(dusk_from, dusk_to, time)


# ------------------------------------------------------------ relógio de 24 h (Bloco 83)
## Segundos reais de uma hora de jogo (22,5 com o padrão).
func segundos_por_hora() -> float:
	return cycle_length() / 24.0


## Hora agora (0..24, com fração: 14.5 = 14:30).
func hora() -> float:
	return fposmod(hora_amanhecer + time / segundos_por_hora(), 24.0)


## "hh:mm" (de agora, ou de uma hora dada).
func hora_texto(h: float = -1.0) -> String:
	var minutos := int(floorf((hora() if h < 0.0 else fposmod(h, 24.0)) * 60.0 + 0.0001))
	return "%02d:%02d" % [(minutos / 60) % 24, minutos % 60]


## Dia da semana do dia do jogo: 1 = segunda ... 7 = domingo.
func dia_semana(d: int = -1) -> int:
	return (maxi(day if d < 0 else d, 1) - 1) % 7 + 1


func nome_dia(curto := false, d: int = -1) -> String:
	return (DIAS_CURTOS if curto else DIAS)[dia_semana(d) - 1]


## Semana do jogo (1 = a primeira).
func semana(d: int = -1) -> int:
	return (maxi(day if d < 0 else d, 1) - 1) / 7 + 1


func e_domingo(d: int = -1) -> bool:
	return dia_semana(d) == 7


## Segundos (desde o amanhecer) em que o relógio marca a hora h.
func tempo_da_hora(h: float) -> float:
	return _horas_entre(hora_amanhecer, h) * segundos_por_hora()


## Segundos reais até o relógio marcar a hora h (a próxima vez; 0 = é agora).
func segundos_ate_hora(h: float) -> float:
	return _horas_entre(hora(), h) * segundos_por_hora()


## A hora agora está entre a e b (a até b, passando da meia-noite se b < a)?
func entre_horas(a: float, b: float) -> bool:
	return _horas_entre(a, hora()) < _horas_entre(a, b)


func _horas_entre(a: float, b: float) -> float:
	return fposmod(b - a, 24.0)


## Marcos de hoje: [nome, hora] na ordem do dia.
func marcos() -> Array:
	return [["amanhecer", hora_amanhecer], ["fim_expediente", hora_fim_expediente], ["anoitecer", hora_anoitecer],
		["dormir", hora_dormir]]


## O próximo marco a partir de agora: [nome, hora].
func proximo_marco() -> Array:
	var melhor: Array = []
	var menor := INF
	for m in marcos():
		var falta := _horas_entre(hora(), m[1])
		if falta > 0.0001 and falta < menor:
			menor = falta
			melhor = m
	return melhor


## Avisa os marcos que o relógio passou entre `antes` e `agora` (na ordem em que aconteceram).
func _marcos(antes: float, agora: float, virou: bool) -> void:
	var passados: Array = []
	for m in marcos():
		var tm := tempo_da_hora(m[1])
		var passou := (tm > antes or tm <= agora) if virou else (antes < tm and tm <= agora)
		if passou:
			passados.append([fposmod(tm - antes, cycle_length()), m[0]])
	passados.sort_custom(func(a, b): return a[0] < b[0])
	for p in passados:
		marco.emit(p[1])


## Pros testes: o relógio vai direto pra hora h (do dia de agora; se já passou e `seguinte`, do dia
## seguinte), virando a fase e os marcos do jeito certo.
func ir_para_hora(h: float, seguinte := false) -> void:
	var alvo := tempo_da_hora(h)
	if seguinte and alvo <= time:
		avancar(cycle_length() - time + alvo)
	elif alvo >= time:
		avancar(alvo - time)
	else:
		_pula_para(alvo)


## Pros testes: avança o relógio `segundos` reais de uma vez (passa pelos marcos, vira o dia, anuncia a
## fase). A simulação do resto NÃO roda junto (pra isso, Engine.time_scale ou pular_dia()).
func avancar(segundos: float) -> void:
	var resto := maxf(segundos, 0.0)
	while resto > 0.0:
		var limite := cycle_length() - time  # um passo não atravessa o anoitecer nem a virada do dia
		if time < day_duration:
			limite = minf(limite, day_duration - time)
		var passo := minf(resto, limite)
		var antes := time
		time += passo
		resto -= passo
		var virou := false
		if time >= cycle_length() - 0.00001:
			time = 0.0
			day += 1
			virou = true
		_marcos(antes, time, virou)
		var night_now := time >= day_duration
		if night_now != _night or virou:
			_night = night_now
			_announce_phase()
	snap_lighting()


func _pula_para(alvo: float) -> void:
	time = clampf(alvo, 0.0, cycle_length() - 0.01)
	var night_now := time >= day_duration
	if night_now != _night:
		_night = night_now
		_announce_phase()
	snap_lighting()


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


# ------------------------------------------------------------ pular dia (Bloco 83)
## Acelera o jogo (pular_velocidade) com a simulação rodando de verdade até o próximo amanhecer.
## Para sozinho se começar uma invasão, tocar o alarme ou chegar uma onda solar, alguém se ferir grave,
## alguém morrer ou começar uma greve. false = já estava pulando.
func pular_dia() -> bool:
	if pulando:
		return false
	pulando = true
	_pulo_ate_dia = day + 1
	_pulo_vel_antes = Engine.time_scale if Engine.time_scale > 0.0 else 1.0
	_pulo_retrato = _retrato()
	Engine.time_scale = pular_velocidade
	return true


## Para o pulo (motivo "" = o jogador mexeu na velocidade: não mexe de novo nela).
func parar_pulo(motivo: String = "") -> void:
	if not pulando:
		return
	pulando = false
	if motivo != "":
		Engine.time_scale = minf(_pulo_vel_antes, pular_velocidade)
	var hud := get_tree().get_first_node_in_group("hud") if is_inside_tree() else null
	if hud and hud.has_method("_mark_speed"):
		hud._mark_speed()
	if hud and motivo != "" and motivo != "amanheceu":
		hud.show_toast("Pular dia parou: %s." % motivo, Color(1.0, 0.75, 0.4))
	pulo_terminou.emit(motivo)


## O que faz o pulo parar, agora: invasão, onda/alarme, feridos graves, ipezinhos, greve.
func _retrato() -> Dictionary:
	var tree := get_tree()
	var def := tree.get_first_node_in_group("defense")
	var sun := tree.get_first_node_in_group("sun")
	var mor := tree.get_first_node_in_group("morale")
	var ws := tree.get_nodes_in_group("ipezinhos")
	return {
		"invasao": def != null and def.invasion_active,
		"onda": sun != null and (sun.wave_active() or sun.warned),
		"graves": ws.filter(func(w): return w.get("injured") and w.get("injury_severity") == "grave").size(),
		"vivos": ws.size(),
		"greve": mor != null and mor.on_strike,
	}


func _confere_pulo() -> void:
	if day >= _pulo_ate_dia:
		parar_pulo("amanheceu")
		return
	var r := _retrato()
	var antes := _pulo_retrato
	if r.invasao and not antes.invasao:
		parar_pulo("começou a invasão")
	elif r.onda and not antes.onda:
		parar_pulo("onda solar a caminho")
	elif r.vivos < antes.vivos:
		parar_pulo("um ipezinho morreu")
	elif r.graves > antes.graves:
		parar_pulo("alguém se feriu grave")
	elif r.greve and not antes.greve:
		parar_pulo("começou uma greve")
	else:
		_pulo_retrato = r  # (a onda que acabou, o ferido que sarou: valem os próximos)


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
	var c := day_color.lerp(twilight, k * 2.0) if k < 0.5 else twilight.lerp(night_color, k * 2.0 - 1.0)
	# Prompt 19: tom da estação (o Sun conta as estações; sem ele, neutro)
	var s := season_index()
	if s >= 0 and s < season_tints.size():
		var t := season_tints[s]
		if s == 3:
			t = t * lerpf(1.0, winter_night_darker, k)
		c = Color(c.r * t.r, c.g * t.g, c.b * t.b, c.a)
	_ambient.color = c


## Estação agora (0 primavera, 1 verão, 2 outono, 3 inverno; -1 = sem o Sun).
func season_index() -> int:
	var sun := get_tree().get_first_node_in_group("sun") if is_inside_tree() else null
	return sun.season_index(day) if sun and sun.has_method("season_index") else -1


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"day": day, "time": time, "relogio": RELOGIO_VERSAO}


## Save antigo (sem "relogio"): o ciclo era 180 s de dia + 60 s de noite — converte proporcional
## (a mesma fração do dia ou da noite).
func load_save_data(d: Dictionary) -> void:
	day = maxi(SaveUtil.integer(d, "day", day), 1)
	var t := SaveUtil.num(d, "time", time)
	if SaveUtil.integer(d, "relogio", 0) < RELOGIO_VERSAO:
		const DIA_ANTIGO := 180.0
		const NOITE_ANTIGA := 60.0
		t = t / DIA_ANTIGO * day_duration if t < DIA_ANTIGO else day_duration + (t - DIA_ANTIGO) / NOITE_ANTIGA * night_duration
	time = clampf(t, 0.0, cycle_length() - 0.01)
	_night = time >= day_duration  # sem anunciar: os ipezinhos decidem sozinhos no próximo tick
	if pulando:
		parar_pulo("")
	snap_lighting()
