extends Node
## Bloco 121: a MÚSICA DINÂMICA (Prompt 7, guia seção 23). Filho do autoload Audio (audio_manager.gd).
##
## Cada ESTAÇÃO tem 3 faixas do mesmo BPM e do mesmo tom (data/audio/musica.json, geradas no Bloco 120; as 4 estações foram medidas como SINCRONIZADAS,
## docs/audio/SINCRONIA_MUSICA.md), tocadas juntas num AudioStreamSynchronized: o PAD (arquivo `<estacao>_noite`: drones, a base que nunca para), a MELODIA
## (`<estacao>_dia`: violão e sanfona, de dia) e a PERCUSSÃO (`<estacao>_perigo`: entra com a invasão). O jogo só mexe no volume de cada camada:
##   dia: melodia + pad baixo | noite: pad alto, sem melodia | perigo: entra a percussão e a melodia cede | fundo da mina: mais drone, menos melodia.
## As estações e os temas (menu, vitória, derrota) são CLIPES de um AudioStreamInteractive; trocar de clipe é um crossfade. Os WAV não têm BPM, então o
## Godot não sabe achar o "próximo compasso": esta classe conta os compassos (todas as faixas têm o mesmo tamanho e começam juntas) e só pede a troca na
## virada do compasso; e, sem BPM no stream, o Godot conta 1 batida = 1 s, então `crossfade_s` vai direto em `fade_beats`.
## FALLBACK: sem as 3 faixas de nenhuma estação (ou desligada nas Configurações), `ativa()` é falso e o jogo toca as 2 músicas de antes (jogo e perigo), como no Bloco 117.

const Slots := preload("res://scripts/core/audio_slots.gd")
const ESTACOES := ["primavera", "verao", "outono", "inverno"]
## Temas (clipes 4, 5 e 6 do Interactive): arquivos `tema_menu`, `tema_vitoria`, `tema_derrota`.
const TEMAS := ["menu", "vitoria", "derrota"]
## Dentro do Synchronized: 0 = pad (arquivo "noite"), 1 = melodia ("dia"), 2 = percussão ("perigo").
const L_PAD := 0
const L_MELODIA := 1
const L_PERCUSSAO := 2
const SUFIXO := ["noite", "dia", "perigo"]
const MUDO_DB := -60.0

@export_group("Camadas (dB)")
## Melodia (violão e sanfona) de dia.
@export var melodia_dia_db: float = -3.0
## Melodia de noite: mudo (de noite quem canta é o pad).
@export var melodia_noite_db: float = -60.0
## Somado à melodia no fundo da mina (S2 a S5): menos melodia.
@export var melodia_fundo_db: float = -14.0
## Somado à melodia no perigo: ela cede à percussão.
@export var melodia_perigo_db: float = -8.0
## Pad (drones) de dia: a base, baixa.
@export var pad_dia_db: float = -9.0
## Pad de noite: sobe e assume.
@export var pad_noite_db: float = -2.0
## Somado ao pad no fundo da mina: mais drone.
@export var pad_fundo_db: float = 3.0
## Percussão com a invasão em andamento (fora dela, mudo).
@export var percussao_perigo_db: float = -3.0
@export_group("Tempo")
## Segundos que uma camada leva pra subir ou descer (a velocidade é 60 dB nesse tempo).
@export var camada_fade_s: float = 2.5
## Duração do crossfade entre clipes (estação nova, tema). O stream WAV não tem BPM: o Godot conta 1 batida = 1 s.
@export var crossfade_s: float = 3.0
## BPM e batidas por compasso das faixas (data/audio/musica.json): o compasso dura 60 / bpm * batidas.
@export var bpm: float = 80.0
@export var batidas_por_compasso: int = 4
## Quanto dura o tema de vitória ou de derrota antes de a música do jogo voltar (s).
@export var tema_fim_segundos: float = 60.0
## Fade de entrada e de saída de tudo (s).
@export var fade_geral_s: float = 2.0

## Os testes ligam a música dinâmica mesmo em headless (sem tela não há quem ouça: fica desligada).
static var forcar := false

var _sets: Array[AudioStreamSynchronized] = []  # um por estação (null = incompleta)
var _temas: Array[AudioStream] = []  # menu, vitoria, derrota (null = sem arquivo)
var _interativo: AudioStreamInteractive
var _player: AudioStreamPlayer
var _pb: AudioStreamPlaybackInteractive
var _carregada := false
var _clip := -1  # o clipe tocando agora (0..3 estação, 4..6 tema)
var _inicio_ms := 0  # quando o clipe atual começou (o relógio dos compassos)
var _troca_clip := -1
var _troca_em_ms := -1
var _estacao := 0
var _noite := false
var _perigo := false
var _fundo := false
var _jogando := false
var _menu := false
var _tema := ""  # vitoria ou derrota tocando
var _tema_ate_ms := 0
var _db: Array[float] = [MUDO_DB, MUDO_DB, MUDO_DB]  # o volume de cada camada agora (dB)
var _tw: Tween
## Os testes mandam no relógio (ms); -1 = o relógio de verdade.
var relogio_ms := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _agora() -> int:
	return relogio_ms if relogio_ms >= 0 else Time.get_ticks_msec()


## Duração de um compasso (s).
func compasso_s() -> float:
	return 60.0 / maxf(bpm, 1.0) * float(batidas_por_compasso)


# ------------------------------------------------------------ carregar
## Monta as estações e os temas com o que existe nos arquivos. Devolve se há pelo menos uma estação completa.
func carrega() -> bool:
	_sets.clear()
	_temas.clear()
	for i in ESTACOES.size():
		var sy := AudioStreamSynchronized.new()
		sy.stream_count = 3
		var ok := true
		for l in 3:
			var arr := Slots.streams("musica/%s_%s" % [ESTACOES[i], SUFIXO[l]])
			if arr.is_empty():
				ok = false
				break
			Slots.forca_loop(arr[0])
			sy.set_sync_stream(l, arr[0])
		_sets.append(sy if ok else null)
	for nome in TEMAS:
		var arr := Slots.streams("musica/tema_" + nome)
		if arr.is_empty():
			_temas.append(null)
			continue
		if nome == "menu":
			Slots.forca_loop(arr[0])
		_temas.append(arr[0])
	_carregada = true
	if _sets.all(func(s): return s == null):
		_interativo = null
		return false
	_monta()
	return true


func _monta() -> void:
	_interativo = AudioStreamInteractive.new()
	var n := ESTACOES.size() + TEMAS.size()
	_interativo.clip_count = n
	for i in ESTACOES.size():
		_interativo.set_clip_name(i, ESTACOES[i])
		_interativo.set_clip_stream(i, _sets[i])
	for j in TEMAS.size():
		_interativo.set_clip_name(ESTACOES.size() + j, "tema_" + TEMAS[j])
		_interativo.set_clip_stream(ESTACOES.size() + j, _temas[j])
	for a in n:
		for b in n:
			if a == b:
				continue
			# estação -> estação continua do mesmo ponto (as faixas têm o mesmo tamanho e o mesmo BPM); tema entra e sai do começo
			var para := AudioStreamInteractive.TRANSITION_TO_TIME_SAME_POSITION if (a < ESTACOES.size() and b < ESTACOES.size()) else AudioStreamInteractive.TRANSITION_TO_TIME_START
			_interativo.add_transition(a, b, AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE, para, AudioStreamInteractive.FADE_CROSS, crossfade_s)


func _garante() -> bool:
	if not _carregada:
		carrega()
	return _interativo != null


## Há música dinâmica a tocar? (ligada nas Configurações, música ligada, não é headless, e ao menos uma estação completa.)
func ativa() -> bool:
	var a := get_parent()
	if a == null or not bool(a.get("musica_dinamica")) or not bool(a.get("music_enabled")):
		return false
	if DisplayServer.get_name() == "headless" and not forcar:
		return false
	return _garante()


func tem_estacao(i: int) -> bool:
	_garante()
	return i >= 0 and i < _sets.size() and _sets[i] != null


func tem_tema(nome: String) -> bool:
	_garante()
	var i := TEMAS.find(nome)
	return i >= 0 and i < _temas.size() and _temas[i] != null


## Qual estação toca: a pedida, ou (se ela estiver incompleta) a completa mais perto dela.
func estacao_que_toca(i: int) -> int:
	for passo in ESTACOES.size():
		var k := (i + passo) % ESTACOES.size()
		if tem_estacao(k):
			return k
	return -1


# ------------------------------------------------------------ entradas (o Audio chama a cada 0,5 s)
## O estado do jogo: estação (0 a 3), noite, perigo (invasão), fundo (andares S2 a S5) e se há partida.
func atualiza(estacao: int, noite: bool, perigo: bool, fundo: bool, jogando: bool) -> void:
	_estacao = clampi(estacao, 0, ESTACOES.size() - 1)
	_noite = noite
	_perigo = perigo
	_fundo = fundo
	_jogando = jogando
	_decide()


## O menu inicial pede (ou solta) o tema do menu.
func menu(on: bool) -> void:
	_menu = on
	_decide()


## Vitória ou derrota: o tema entra (crossfade) e, passados `tema_fim_segundos`, a música do jogo volta.
func toca_tema(nome: String) -> bool:
	if not ativa() or not (nome in ["vitoria", "derrota"]) or not tem_tema(nome):
		return false
	_tema = nome
	_tema_ate_ms = _agora() + int(tema_fim_segundos * 1000.0)
	_decide()
	return true


## O clipe que deveria tocar agora (-1 = nada).
func clipe_desejado() -> int:
	if _tema != "":
		return ESTACOES.size() + TEMAS.find(_tema)
	if _menu and tem_tema("menu"):
		return ESTACOES.size() + TEMAS.find("menu")
	if _jogando:
		return estacao_que_toca(_estacao)
	return -1


func _decide() -> void:
	if not ativa():
		if _player != null and _player.playing:
			_para()
		return
	var d := clipe_desejado()
	if d < 0:
		if _player != null and _player.playing:
			_para()
		return
	if _player == null or not _player.playing:
		_inicia(d)
		return
	if d != _clip and _troca_clip != d:
		var entre_estacoes := d < ESTACOES.size() and _clip >= 0 and _clip < ESTACOES.size()
		_troca_clip = d
		# entre estações a troca espera a virada do compasso; tema e volta do tema entram na hora
		_troca_em_ms = _proximo_compasso_ms() if entre_estacoes else _agora()
		_processa_troca()


# ------------------------------------------------------------ tocar, parar, trocar
func _inicia(clip: int) -> void:
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.bus = &"Music"
		add_child(_player)
	_interativo.set_initial_clip(clip)
	_player.stream = _interativo
	_player.volume_db = -40.0
	_player.play()
	_pb = _player.get_stream_playback() as AudioStreamPlaybackInteractive
	_clip = clip
	_troca_clip = -1
	_troca_em_ms = -1
	_inicio_ms = _agora()
	for l in 3:  # as camadas já nascem no volume certo (sem a subida do zero)
		_db[l] = _alvo_db(l)
	_aplica_volumes()
	_fade_geral(0.0)


func _para() -> void:
	_troca_clip = -1
	_clip = -1
	_fade_geral(-40.0, true)


func _fade_geral(db: float, parar: bool = false) -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(_player, "volume_db", db, fade_geral_s)
	if parar:
		_tw.tween_callback(func():
			if _player != null and _clip < 0:
				_player.stop())


## Quando cai o próximo compasso (ms do relógio), a partir do começo do clipe e do tamanho dele.
func _proximo_compasso_ms() -> int:
	var c := compasso_s()
	var passou := float(_agora() - _inicio_ms) / 1000.0
	var proximo := ceilf(passou / c) * c
	if proximo - passou < 0.15:  # quase em cima da virada: espera a seguinte
		proximo += c
	return _inicio_ms + int(proximo * 1000.0)


func _processa_troca() -> void:
	if _troca_clip < 0 or _agora() < _troca_em_ms:
		return
	if _pb == null or _player == null or not _player.playing:
		return
	var vindo_de_estacao := _clip >= 0 and _clip < ESTACOES.size()
	var vai_pra_estacao := _troca_clip < ESTACOES.size()
	if _clip < 0:  # estava parando (fade-out): volta a subir
		_fade_geral(0.0)
	_pb.switch_to_clip(_troca_clip)
	if not (vindo_de_estacao and vai_pra_estacao):
		_inicio_ms = _agora()  # tema entra e sai do começo: o relógio dos compassos recomeça
	_clip = _troca_clip
	_troca_clip = -1
	_troca_em_ms = -1


# ------------------------------------------------------------ volumes das camadas
## O volume (dB) que a camada `l` deve ter agora, pelo estado do jogo e pelo mix das Configurações.
func _alvo_db(l: int) -> float:
	var db := MUDO_DB
	match l:
		L_PAD:
			db = (pad_noite_db if _noite else pad_dia_db) + (pad_fundo_db if _fundo else 0.0) + _mix_db("mix_pad")
		L_MELODIA:
			db = (melodia_noite_db if _noite else melodia_dia_db)
			if db > MUDO_DB:
				db += (melodia_fundo_db if _fundo else 0.0) + (melodia_perigo_db if _perigo else 0.0) + _mix_db("mix_melodia")
		L_PERCUSSAO:
			db = (percussao_perigo_db + _mix_db("mix_percussao")) if _perigo else MUDO_DB
	return maxf(db, MUDO_DB)


## O slider das Configurações (0 a 1) em dB (0 = mudo).
func _mix_db(variavel: String) -> float:
	var a := get_parent()
	var v := float(a.get(variavel)) if a != null and a.get(variavel) != null else 1.0
	return linear_to_db(maxf(v, 0.001))


func alvo_db(l: int) -> float:
	return _alvo_db(l)


func db_atual(l: int) -> float:
	return _db[l]


func _aplica_volumes() -> void:
	for sy in _sets:
		if sy == null:
			continue
		for l in 3:
			sy.set_sync_stream_volume(l, _db[l])


func _process(delta: float) -> void:
	if _interativo == null or _player == null or not _player.playing:
		return
	if _tema != "" and _agora() >= _tema_ate_ms:
		_tema = ""
		_decide()
	_processa_troca()
	var passo := 60.0 / maxf(camada_fade_s, 0.05) * delta  # dB por quadro
	var mudou := false
	for l in 3:
		var alvo := _alvo_db(l)
		if not is_equal_approx(_db[l], alvo):
			_db[l] = move_toward(_db[l], alvo, passo)
			mudou = true
	if mudou:
		_aplica_volumes()


## O que está tocando (pro teste): {clipe, estacao, tema, db: [pad, melodia, percussao], tocando}.
func estado() -> Dictionary:
	return {"clipe": _clip, "tema": _tema, "menu": _menu, "troca": _troca_clip, "troca_em_ms": _troca_em_ms, "inicio_ms": _inicio_ms,
		"tocando": _player != null and _player.playing, "db": _db.duplicate()}


func clipe_atual() -> int:
	return _pb.get_current_clip_index() if _pb != null and _player != null and _player.playing else -1
