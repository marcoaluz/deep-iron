extends Node
## Autoload "Audio": música, ambiente de caverna e efeitos sonoros.
##
## Ajuste volumes e sons na cena res://scenes/core/audio_manager.tscn (Inspector).
## Os efeitos posicionais usam um pool de AudioStreamPlayer2D, então ficam mais
## baixos longe da câmera e sons fora de alcance nem chegam a tocar.
## Todos os sons vêm de tools/gen_audio.py (sintetizados, sem direitos autorais).

@export_group("Volumes (0 a 1)")
@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var music_volume: float = 0.35
@export_range(0.0, 1.0) var ambience_volume: float = 0.55
@export_range(0.0, 1.0) var sfx_volume: float = 0.8
@export var music_enabled: bool = true
## Segundos de fade-in da música e do ambiente ao iniciar.
@export var fade_in_time: float = 3.0

@export_group("Trilhas")
@export var music: AudioStream
@export var ambience: AudioStream

@export_group("Efeitos")
@export var pick_sounds: Array[AudioStream] = []
@export var step_sounds: Array[AudioStream] = []
@export var deposit_sounds: Array[AudioStream] = []
@export var eat_sounds: Array[AudioStream] = []
@export var sell_sound: AudioStream
@export var recruit_sound: AudioStream
## Bloco 101: a chegada dos migrantes no portão (sem arquivo = mudo; o arquivo vem depois).
@export var migrantes_sound: AudioStream
@export var click_sound: AudioStream
@export var error_sound: AudioStream
@export var hurt_sound: AudioStream
@export var heal_sound: AudioStream
@export var forge_sound: AudioStream
@export var fanfare_sound: AudioStream
@export var chop_sounds: Array[AudioStream] = []
@export var elevator_sound: AudioStream
@export var branch_sound: AudioStream
## Sino fúnebre: um ipezinho morreu.
@export var toll_sound: AudioStream
## Brinde na taverna / batucada da greve.
@export var cheers_sound: AudioStream
@export var protest_sound: AudioStream
## Achado na mina / robô ligando / pane do reator.
@export var find_sound: AudioStream
@export var robot_sound: AudioStream
@export var boom_sound: AudioStream
## Invasão: berrante, Lumívoro, Ferrugento, golpe, barricada quebrando.
@export var alarm_sound: AudioStream
@export var screech_sound: AudioStream
@export var clank_sound: AudioStream
@export var hit_sound: AudioStream
@export var gate_break_sound: AudioStream
## Onda solar chegando.
@export var solar_sound: AudioStream

@export_group("Mixagem dos efeitos (dB)")
@export var pick_db: float = -7.0
@export var step_db: float = -22.0
@export var deposit_db: float = -9.0
@export var eat_db: float = -11.0
@export var hurt_db: float = -4.0
@export var heal_db: float = -8.0
@export var forge_db: float = -10.0
@export var fanfare_db: float = -4.0
@export var chop_db: float = -9.0
@export var elevator_db: float = -8.0
@export var branch_db: float = -5.0
@export var toll_db: float = -5.0
@export var cheers_db: float = -12.0
@export var protest_db: float = -9.0
@export var find_db: float = -8.0
@export var robot_db: float = -6.0
@export var boom_db: float = -2.0
@export var alarm_db: float = -4.0
@export var screech_db: float = -12.0
@export var clank_db: float = -10.0
@export var hit_db: float = -9.0
@export var gate_break_db: float = -4.0
@export var solar_db: float = -3.0
@export var ui_db: float = -6.0
## Variação aleatória de pitch (0.08 = ±8%), pra não soar repetitivo.
@export var pitch_variation: float = 0.08

@export_group("Bloco 55: sons novos, ambiência e música")
@export var build_db: float = -12.0
@export var build_done_db: float = -6.0
@export var harvest_db: float = -12.0
@export var equip_db: float = -10.0
@export var party_db: float = -8.0
@export var place_db: float = -8.0
@export var creature_down_db: float = -8.0
@export var drill_db: float = -14.0
@export var ui_panel_db: float = -14.0
## Quantas vozes do MESMO som ao mesmo tempo (15 mineradores batendo não viram um muro de som).
@export var max_same_voice: int = 4
## Segundos da troca de música (calma <-> perigo) e de ambiência (mina, superfície, fundo).
@export var music_crossfade: float = 2.5
@export var ambience_crossfade: float = 2.0
## Volume de cada ambiência (dB) e da chuva por cima.
@export var ambience_db := {"mina": 0.0, "dia": -4.0, "noite": -5.0, "fundo": -1.0}
@export var rain_db: float = -6.0
## Teto do limitador no Master (dB): nada passa disso, nem com tudo tocando junto.
@export var limiter_ceiling_db: float = -0.5

@export_group("Bloco 114: interface, ducking, voz, passos e prédios")
## Volume do bus UI (0 a 1; o slider "Interface" das Configurações).
@export_range(0.0, 1.0) var ui_volume: float = 0.8
## Voz curta dos ipezinhos ligada (Configurações). Sem arquivo de voz, nada toca.
@export var voz_ligada: bool = true
## Segundos mínimos entre duas vozes (a vila inteira não vira um coro).
@export var voz_intervalo: float = 1.2
## DUCKING: quanto a música abaixa (dB) no alarme, no sino e no aviso grande (banner)...
@export var duck_alarme_db: float = -9.0
@export var duck_sino_db: float = -7.0
@export var duck_aviso_db: float = -6.0
## ...em quantos segundos desce, quanto tempo segura lá embaixo e em quantos volta.
@export var duck_ataque: float = 0.2
@export var duck_segura: float = 2.5
@export var duck_solta: float = 1.2
## Intervalo mínimo entre dois sons de notícia (aviso verde ou vermelho).
@export var noticia_intervalo: float = 0.6
## Tamanho da sala do reverb (eco) que o bus Ambience ganha nos andares com "eco" no slot (0 a 1).
@export_range(0.0, 1.0) var eco_sala: float = 0.85

@export_group("Limites")
@export var max_voices: int = 24
## Máximo de passos tocando por segundo somando todos os ipezinhos.
@export var max_steps_per_second: float = 8.0
## Distância (em pixels do mundo) além da qual efeitos posicionais não tocam.
@export var sfx_max_distance: float = 900.0

var _pool: Array[AudioStreamPlayer2D] = []
var _next_voice := 0
var _ui_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _step_tokens := 0.0
var _last_index := {}  # evita tocar a mesma variação duas vezes seguidas
# Bloco 55
var _ui_pool: Array[AudioStreamPlayer] = []
var _next_ui := 0
var _danger_player: AudioStreamPlayer
var _danger := false
var _amb := {}  # contexto -> AudioStreamPlayer (loop)
var _rain_player: AudioStreamPlayer
var ambience_now := "mina"
var _raining := false
var _ctx_timer := 0.0
# Bloco 114
var _iface_pool: Array[AudioStreamPlayer] = []  # as vozes do bus UI
var _next_iface := 0
var _tema_player: AudioStreamPlayer
var _tema_atual := ""
var _over := {}  # camada (chuva, vento) -> AudioStreamPlayer
var _vento := false
var _onda := false
var _pont_pool: Array[AudioStreamPlayer2D] = []  # os sons soltos (pontuais), no bus Ambience
var _pont_prox := {}  # slot -> (ms) de quando toca o próximo
var _pont_t := 0.0
var _pont_ids: Array[String] = []
var _geiger_ultimo := -100000
var _eco_fx: AudioEffectReverb
var _duck_fx: AudioEffectAmplify
var _duck_db := 0.0  # o quanto a música está abaixada agora (dB, <= 0)
var _duck_alvo := 0.0
var _duck_ate := 0  # (ms) segura o ducking até aqui
var _duck_t := 0  # (ms) da última conta do ducking
var _dia_visto := -1
var _voz_ultima := -100000
var _noticia_ultima := -100000
var predios: Node  # os loops posicionais dos prédios (sons_predios.gd)
var _streams := {}  # nome -> AudioStream (sons novos, carregados no _ready)
const NOVOS := {
	"build": ["build_hit_0", "build_hit_1", "build_hit_2"], "build_done": ["build_done"],
	"harvest": ["harvest_0", "harvest_1", "harvest_2"], "equip": ["equip"], "party": ["party"],
	"ui_open": ["ui_open"], "ui_close": ["ui_close"], "place": ["place"], "creature_down": ["creature_down"],
	"drill": ["drill"], "music_danger": ["music_danger"], "rain_loop": ["rain_loop"],
	"surface_day_loop": ["surface_day_loop"], "surface_night_loop": ["surface_night_loop"], "deep_loop": ["deep_loop"],
}


const Settings := preload("res://scripts/core/settings.gd")
const Slots := preload("res://scripts/core/audio_slots.gd")  # Bloco 114: o catálogo de sons (data/audio/slots.json)
const SonsPredios := preload("res://scripts/core/sons_predios.gd")
## Bloco 114: o contexto da câmera -> o slot da ambiência dele (o andar vem de environment.level_at: 2 = S2... 5 = S5).
const CTX_SLOT := {"mina": "ambiencia/mina", "dia": "ambiencia/floresta_dia", "noite": "ambiencia/floresta_noite",
	"s2": "ambiencia/s2_acido", "s3": "ambiencia/s3_lava", "s4": "ambiencia/s4_cachoeira", "s5": "ambiencia/s5_lago"}
## As camadas por cima da ambiência (ligam e desligam à parte).
const CAMADAS := {"chuva": "ambiencia/chuva", "vento": "ambiencia/vento_inverno", "onda_solar": "ambiencia/onda_solar"}
## Estação do inverno na lista do sun.gd (Primavera, Verão, Outono, Inverno).
const INVERNO := 3
## Perto de uma plataforma, escada ou elevador o passo é de madeira (px do mundo).
const RAIO_MADEIRA := 36.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	apply_volumes()

	for i in max_voices:
		var p := AudioStreamPlayer2D.new()
		p.bus = &"SFX"
		p.max_distance = sfx_max_distance
		p.attenuation = 1.2
		add_child(p)
		_pool.append(p)

	# Bloco 55: 4 vozes de interface (um clique não corta mais a fanfarra)
	for i in 4:
		var u := AudioStreamPlayer.new()
		u.bus = &"SFX"
		add_child(u)
		_ui_pool.append(u)
	_ui_player = _ui_pool[0]
	_garante_buses()
	# Bloco 114: o bus UI tem as 4 vozes dele (os sons de interface não disputam com os efeitos)
	for i in 4:
		var u := AudioStreamPlayer.new()
		u.bus = &"UI"
		add_child(u)
		_iface_pool.append(u)
	Slots.carrega()
	for k in NOVOS:
		var arr: Array[AudioStream] = []
		for nome in NOVOS[k]:
			var path := "res://assets/audio/%s.wav" % nome
			if ResourceLoader.exists(path):
				arr.append(load(path))
		_streams[k] = arr
	_setup_limiter()
	_setup_duck()
	_setup_eco()
	apply_volumes()

	_music_player = _make_loop_player(music, &"Music")
	_danger_player = _make_loop_player(_first("music_danger"), &"Music")
	_ambience_player = _make_loop_player(ambience, &"Ambience")
	for i in 4:  # Bloco 115: os sons soltos pelo contexto (pássaro, trovão, gota...) saem no bus Ambience
		var q := AudioStreamPlayer2D.new()
		q.bus = &"Ambience"
		q.max_distance = sfx_max_distance
		q.attenuation = 1.0
		add_child(q)
		_pont_pool.append(q)
	for id in Slots.todos():
		if String(Slots.slot(id).get("tipo", "")) == "pontual":
			_pont_ids.append(id)
	_amb = {"mina": _ambience_player}
	for ctx in CTX_SLOT:
		if ctx != "mina":
			_amb[ctx] = _make_loop_player(null, &"Ambience")  # (o som entra quando o contexto liga: o arquivo pode chegar depois)
	for k in CAMADAS:
		_over[k] = _make_loop_player(null, &"Ambience")
	_rain_player = _over["chuva"]
	_tema_player = _make_loop_player(null, &"Music")
	predios = SonsPredios.new()
	predios.name = "SonsPredios"
	add_child(predios)
	if music_enabled and _music_player.stream:
		_fade_in(_music_player)
	if _ambience_player.stream:
		_fade_in(_ambience_player, _db_amb("mina"))


func _process(delta: float) -> void:
	_step_tokens = minf(_step_tokens + max_steps_per_second * delta, max_steps_per_second)
	_ctx_timer -= delta
	if _ctx_timer <= 0.0:
		_ctx_timer = 0.5
		_update_context()
	_duck_tick()
	_pontuais_tick(delta)


# ------------------------------------------------------------ Bloco 55: contexto (ambiência e música)
## Onde a câmera está olhando decide a ambiência: clareira (dia/noite, + chuva por cima), mina, ou o
## fundo (nível 2/abismo). Invasão acontecendo troca a música pra de perigo (e volta depois).
func _update_context() -> void:
	var tree := get_tree()
	var env := tree.get_first_node_in_group("environment")
	var cam := get_viewport().get_camera_2d()
	var ctx := "mina"
	var rain := false
	var vento := false
	var onda := false
	if env and cam:
		var ground: Vector2 = cam.ground_center() if cam.has_method("ground_center") else cam.get_screen_center_position()
		var nivel: int = env.level_at(ground) if env.has_method("level_at") else 0
		if nivel >= 2:
			ctx = "s%d" % clampi(nivel, 2, 5)  # Bloco 114: cada andar tem a ambiência dele
		elif env.has_method("open_sky_rect") and env.open_sky_rect().has_point(ground) and env.surface_area(ground) != "mina":
			# Bloco 74: céu aberto na floresta e na vila; na área da mina (montanha, armazém) o som da mina
			var dn := tree.get_first_node_in_group("day_night")
			ctx = "noite" if dn and dn.has_method("is_night") and dn.is_night() else "dia"
			var w := tree.get_first_node_in_group("weather")
			rain = w != null and w.has_method("level") and w.level("rain") > 0.3
			var sol := tree.get_first_node_in_group("sun")
			vento = sol != null and sol.has_method("season_index") and sol.season_index() == INVERNO  # Bloco 114: vento no inverno
	if ctx in ["dia", "noite", "mina"]:  # Bloco 115: a onda solar (a rocha protege os andares fundos: lá não soa)
		var sol2 := tree.get_first_node_in_group("sun")
		onda = sol2 != null and sol2.has_method("wave_active") and sol2.wave_active()
	set_ambience(ctx, rain, vento, onda)
	var d := tree.get_first_node_in_group("defense")
	set_danger(d != null and bool(d.get("invasion_active")))
	# Bloco 114: amanhecer (o dia virou; o 1º dia que o jogo vê não conta, e sem partida zera)
	var dnn := tree.get_first_node_in_group("day_night")
	if dnn == null:
		_dia_visto = -1
	else:
		var dia := int(dnn.day)
		if _dia_visto >= 0 and dia != _dia_visto:
			stinger("amanhecer")
		_dia_visto = dia


func set_ambience(ctx: String, rain: bool = false, vento: bool = false, onda: bool = false) -> void:
	if not _amb.has(ctx):
		ctx = "mina"
	if ctx != ambience_now:
		ambience_now = ctx
		_poe_eco(float(Slots.slot(String(CTX_SLOT.get(ctx, ""))).get("eco", 0.0)))
		for k in _amb:
			if k == ctx:
				_amb_stream(_amb[k], String(CTX_SLOT[k]))
			_xfade(_amb[k], k == ctx, _db_amb(k), ambience_crossfade)
	if rain != _raining:
		_raining = rain
		_camada("chuva", rain)
	if vento != _vento:
		_vento = vento
		_camada("vento", vento)
	if onda != _onda:
		_onda = onda
		_camada("onda_solar", onda)


## Liga ou desliga uma camada por cima da ambiência (chuva, vento do inverno).
func _camada(nome: String, on: bool) -> void:
	var p: AudioStreamPlayer = _over[nome]
	if on:
		_amb_stream(p, String(CAMADAS[nome]))
	_xfade(p, on, _db_slot(String(CAMADAS[nome]), rain_db if nome == "chuva" else 0.0), ambience_crossfade)


## O som do slot no player da ambiência (o arquivo pode ter chegado depois do _ready; sem arquivo vale a reserva).
func _amb_stream(p: AudioStreamPlayer, id: String) -> void:
	var st := _slot_stream(id)
	if st != null and st != p.stream and not p.playing:
		Slots.forca_loop(st)
		p.stream = st


## Volume da ambiência de um contexto: o do slot (data/audio/slots.json), ou o ambience_db antigo.
func _db_amb(ctx: String) -> float:
	return _db_slot(String(CTX_SLOT.get(ctx, "")), float(ambience_db.get(ctx, 0.0)))


func _db_slot(id: String, padrao: float) -> float:
	return float(Slots.slot(id).get("db", padrao))


func set_danger(on: bool) -> void:
	if on == _danger:
		return
	_danger = on
	if not music_enabled or _tema_atual != "":  # Bloco 114: com a abertura/intro tocando, o perigo espera
		return
	_xfade(_danger_player, on, 0.0, music_crossfade)
	_xfade(_music_player, not on, 0.0, music_crossfade)


func is_danger() -> bool:
	return _danger


## Liga (subindo até on_db) ou desliga (descendo e parando) um loop, em `secs`.
func _xfade(p: AudioStreamPlayer, on: bool, on_db: float, secs: float) -> void:
	if p == null or p.stream == null:
		return
	if p.has_meta("_tw"):
		var old: Tween = p.get_meta("_tw")
		if old and old.is_valid():
			old.kill()
	var tw := create_tween()
	p.set_meta("_tw", tw)
	if on:
		if not p.playing:
			p.volume_db = -40.0
			p.play()
		tw.tween_property(p, "volume_db", on_db, secs)
	else:
		tw.tween_property(p, "volume_db", -40.0, secs)
		tw.tween_callback(p.stop)


func _first(k: String) -> AudioStream:
	var arr: Array = _streams.get(k, [])
	return arr[0] if not arr.is_empty() else null


## Limitador no Master: com muita coisa tocando junto, abaixa o pico em vez de estourar.
func _setup_limiter() -> void:
	var idx := AudioServer.get_bus_index(&"Master")
	for i in AudioServer.get_bus_effect_count(idx):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectHardLimiter:
			return
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = limiter_ceiling_db
	AudioServer.add_bus_effect(idx, lim)


# ------------------------------------------------------------ volumes / música
func apply_volumes() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(&"Music", music_volume)
	_set_bus_volume(&"Ambience", ambience_volume)
	_set_bus_volume(&"SFX", sfx_volume)
	_set_bus_volume(&"UI", ui_volume)  # Bloco 114


func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func toggle_music() -> void:
	music_enabled = not music_enabled
	if music_enabled:
		_fade_in(_tema_player if _tema_atual != "" else (_danger_player if _danger else _music_player))
	else:
		_music_player.stop()
		_danger_player.stop()
		_tema_player.stop()
	save_settings()


## Volumes e música vêm de user://settings.cfg (o Inspector só dá o padrão da 1ª vez).
func _load_settings() -> void:
	master_volume = Settings.get_value("audio", "master_volume", master_volume)
	music_volume = Settings.get_value("audio", "music_volume", music_volume)
	ambience_volume = Settings.get_value("audio", "ambience_volume", ambience_volume)
	sfx_volume = Settings.get_value("audio", "sfx_volume", sfx_volume)
	music_enabled = Settings.get_value("audio", "music_enabled", music_enabled)
	ui_volume = Settings.get_value("audio", "ui_volume", ui_volume)  # Bloco 114
	voz_ligada = Settings.get_value("audio", "voz_ligada", voz_ligada)


func save_settings() -> void:
	for key in ["master_volume", "music_volume", "ambience_volume", "sfx_volume", "music_enabled", "ui_volume", "voz_ligada"]:
		Settings.set_value("audio", key, get(key))


func _make_loop_player(stream: AudioStream, bus_name: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus_name
	if stream:
		# garante loop mesmo se o .import do WAV não estiver marcado como loop
		if stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		p.stream = stream
	add_child(p)
	return p


func _fade_in(p: AudioStreamPlayer, to_db: float = 0.0) -> void:
	if p.stream == null:
		return
	p.volume_db = -40.0
	p.play()
	create_tween().tween_property(p, "volume_db", to_db, fade_in_time)


# ------------------------------------------------------------ efeitos
func pick(pos: Vector2) -> void:
	som("sfx/picareta", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func step(pos: Vector2) -> void:
	if _step_tokens < 1.0:
		return
	_step_tokens -= 1.0
	var id := "passos/" + chao_de(pos)  # Bloco 114: o chão decide o som (sem arquivo, o passo de sempre)
	play_at(&"step", _slot_streams(id), pos, _db_slot(id, step_db), 0.12)


func deposit(pos: Vector2) -> void:
	som("sfx/deposito", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func eat(pos: Vector2) -> void:
	som("sfx/comer", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func hurt(pos: Vector2) -> void:
	som("sfx/ferido", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func heal(pos: Vector2) -> void:
	som("sfx/curar", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func forge(pos: Vector2) -> void:
	som("sfx/forja", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func chop(pos: Vector2) -> void:
	som("sfx/machadada", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func elevator(pos: Vector2) -> void:
	som("sfx/elevador", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func branch(pos: Vector2) -> void:
	som("sfx/galho", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func fanfare() -> void:
	som_global("sfx/fanfarra")  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func toll() -> void:
	som_global("sfx/sino_funebre")  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func cheers(pos: Vector2) -> void:
	som("sfx/brinde", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func find(pos: Vector2) -> void:
	som("sfx/achado", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func robot(pos: Vector2) -> void:
	som("sfx/robo", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func boom(pos: Vector2) -> void:
	som("sfx/explosao", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func alarm() -> void:
	som_global("sfx/alarme_invasao")  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func solar() -> void:
	som_global("sfx/solar")  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func screech(pos: Vector2) -> void:
	som("sfx/lumivoro_grito", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func clank(pos: Vector2) -> void:
	som("sfx/ferrugento_golpe", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func hit(pos: Vector2) -> void:
	som("sfx/golpe", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func gate_break(pos: Vector2) -> void:
	som("sfx/portao_quebra", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func protest(pos: Vector2) -> void:
	som("sfx/greve", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


# ------------------------------------------------------------ Bloco 55: eventos que não tinham som
func build_hit(pos: Vector2) -> void:
	som("sfx/martelo", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func build_done(pos: Vector2) -> void:
	som("sfx/obra_pronta", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func harvest(pos: Vector2) -> void:
	som("sfx/colher", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func equip(pos: Vector2) -> void:
	som("sfx/equipar", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func party() -> void:
	som_global("sfx/festa")  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func place_sound() -> void:
	ui("confirmar")


func creature_down(pos: Vector2) -> void:
	som("sfx/criatura_cai", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func drill(pos: Vector2) -> void:
	som("sfx/broca", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func ui_open() -> void:
	ui("abrir_janela")


func ui_close() -> void:
	ui("fechar_janela")


func sell() -> void:
	som_global("sfx/vender")  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


func recruit() -> void:
	som_global("sfx/boas_vindas")  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


## Bloco 101: migrantes chegando no portão.
func migrantes(pos: Vector2) -> void:
	som("sfx/migrantes_chegando", pos)  # Bloco 115: pelo catálogo (sem arquivo, o som de antes)


## Bloco 112: os sons da INTRODUÇÃO por nome ("explosao", "vento", "caravana", "pedreira", "mina", "fogo", "titulo").
## Gancho: toca res://assets/audio/intro/<nome>.ogg (ou .wav) se o arquivo existir; sem ele, fica em silêncio. Os
## arquivos vêm depois — é só pôr na pasta com o nome.
@export var intro_db: float = -6.0  # volume dos sons da introdução (dB)


func intro(nome: String) -> void:
	var id := "intro/" + nome  # Bloco 114: pelo catálogo (data/audio/slots.json)
	play_ui(_slot_stream(id), _db_slot(id, intro_db))


## Bloco 112: quais sons da intro já têm arquivo (pro teste e pro relatório).
func intro_tem(nome: String) -> bool:
	return Slots.tem("intro/" + nome)


func click() -> void:
	ui("clique")


func error() -> void:
	ui("erro")


func play_at(key: StringName, streams: Array[AudioStream], pos: Vector2, volume_db: float, pitch_var: float = -1.0) -> bool:
	if streams.is_empty() or _pool.is_empty():
		return false
	var cam := get_viewport().get_camera_2d()
	if cam and cam.get_screen_center_position().distance_to(pos) > sfx_max_distance:
		return false
	# Bloco 55: no máximo max_same_voice do mesmo som tocando (o resto não entra)
	var iguais := 0
	for v in _pool:
		if v.playing and v.get_meta("key", &"") == key:
			iguais += 1
	if iguais >= max_same_voice:
		return false
	var p := _take_voice()
	p.set_meta("key", key)
	p.stream = streams[_pick_index(key, streams.size())]
	p.global_position = pos
	p.volume_db = volume_db
	var pv := pitch_variation if pitch_var < 0.0 else pitch_var
	p.pitch_scale = randf_range(1.0 - pv, 1.0 + pv)
	p.play()
	return true


func play_ui(stream: AudioStream, volume_db: float = NAN) -> void:
	if stream == null:
		return
	_next_ui = _toca_no_pool(_ui_pool, _next_ui, stream, ui_db if is_nan(volume_db) else volume_db)


## Toca no pool de vozes: uma livre, se tiver (senão a mais antiga). Devolve de onde começa a próxima busca.
func _toca_no_pool(pool: Array[AudioStreamPlayer], inicio: int, stream: AudioStream, db: float) -> int:
	var u := pool[inicio]
	for i in pool.size():  # uma livre, se tiver (senão a mais antiga)
		var c := pool[(inicio + i) % pool.size()]
		if not c.playing:
			u = c
			break
	u.stream = stream
	u.volume_db = db
	u.play()
	return (pool.find(u) + 1) % pool.size()


func _take_voice() -> AudioStreamPlayer2D:
	for i in _pool.size():
		var p := _pool[(_next_voice + i) % _pool.size()]
		if not p.playing:
			_next_voice = (_next_voice + i + 1) % _pool.size()
			return p
	# todas ocupadas: rouba a próxima da fila
	var stolen := _pool[_next_voice]
	_next_voice = (_next_voice + 1) % _pool.size()
	return stolen


func _pick_index(key: StringName, count: int) -> int:
	if count <= 1:
		return 0
	var i := randi() % count
	if _last_index.get(key, -1) == i:
		i = (i + 1 + randi() % (count - 1)) % count
	_last_index[key] = i
	return i


# ------------------------------------------------------------ Bloco 114: o catálogo de sons (slots)
## O primeiro som de um slot: o arquivo (data/audio/slots.json + assets/audio/<id>), senão a reserva (o som antigo); null = mudo.
func _slot_stream(id: String) -> AudioStream:
	var arr := _slot_streams(id)
	return arr[randi() % arr.size()] if not arr.is_empty() else null


func _slot_streams(id: String) -> Array[AudioStream]:
	var arr := Slots.streams(id)
	if not arr.is_empty():
		return arr
	return _reserva(String(Slots.slot(id).get("reserva", "")))


## A reserva de um slot: "prop:<variável do Audio>" (um som ou uma lista) ou "novo:<chave dos sons do Bloco 55>".
func _reserva(r: String) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	if r.begins_with("prop:"):
		var v = get(r.substr(5))
		if v is AudioStream:
			out.append(v)
		elif v is Array:
			for st in v:
				if st is AudioStream:
					out.append(st)
	elif r.begins_with("novo:"):
		for st in _streams.get(r.substr(5), []):
			out.append(st)
	return out


## O bus UI existe mesmo se o layout carregado não tiver (testes, builds antigos).
func _garante_buses() -> void:
	if AudioServer.get_bus_index(&"UI") < 0:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, &"UI")
		AudioServer.set_bus_send(i, &"Master")


# ------------------------------------------------------------ stingers, sino, notícias e interface
## Um stinger por nome (amanhecer, onda_solar, estagio_novo, pesquisa_pronta, morte, vitoria, derrota, missao_cumprida).
## Sem arquivo vale a reserva do slot (o som de antes); o "duck" do slot abaixa a música.
func stinger(nome: String) -> void:
	var id := "stingers/" + nome
	var st := _slot_stream(id)
	if st == null:
		return
	play_ui(st, _db_slot(id, ui_db))
	var d := String(Slots.slot(id).get("duck", ""))
	if d != "":
		duck(d)


## O sino da igreja (tipo "missa" ou "funeral"): posicional; só abaixa a música se deu pra ouvir.
func sino(pos: Vector2, tipo: String = "missa") -> void:
	var id := "predios/sino_" + tipo
	if play_at(&"sino", _slot_streams(id), pos, _db_slot(id, toll_db), 0.02):
		var d := String(Slots.slot(id).get("duck", ""))
		if d != "":
			duck(d)


## Um som de interface pelo nome do slot "ui/<nome>" (abrir_janela, fechar_janela, confirmar, erro, clique, noticia_boa,
## noticia_ruim), no bus UI.
func ui(nome: String) -> void:
	var id := "ui/" + nome
	var st := _slot_stream(id)
	if st == null:
		return
	_next_iface = _toca_no_pool(_iface_pool, _next_iface, st, _db_slot(id, ui_db))


func confirmar() -> void:
	ui("confirmar")


## Notícia boa ou ruim (com um intervalo mínimo entre uma e outra).
func noticia(boa: bool) -> void:
	var agora := Time.get_ticks_msec()
	if agora - _noticia_ultima < int(noticia_intervalo * 1000.0):
		return
	_noticia_ultima = agora
	ui("noticia_boa" if boa else "noticia_ruim")


## O aviso do HUD pela cor: vermelho = notícia ruim, verde = boa; qualquer outra cor (aviso neutro) fica em silêncio.
func noticia_cor(cor: Color) -> void:
	if cor.r > 0.8 and cor.g < 0.6 and cor.b < 0.6:
		noticia(false)
	elif cor.g > 0.8 and cor.r < 0.7 and cor.b < 0.75:
		noticia(true)


# ------------------------------------------------------------ tema (abertura e intro), voz e passos por chão
## A música de um TEMA no lugar da música do jogo: "abertura" (a tela inicial) ou "intro" (a introdução). "" volta pra
## música do jogo. Sem arquivo no slot "musica/<tema>", nada muda.
func tema(nome: String) -> void:
	if nome == _tema_atual:
		return
	if nome != "":
		var id := "musica/" + nome
		var st := _slot_stream(id)
		if st == null or not music_enabled:
			return
		_tema_atual = nome
		if bool(Slots.slot(id).get("loop", false)):
			Slots.forca_loop(st)
		_tema_player.stop()
		_tema_player.stream = st
		_xfade(_tema_player, true, _db_slot(id, 0.0), music_crossfade)
		_xfade(_music_player, false, 0.0, music_crossfade)
		_xfade(_danger_player, false, 0.0, music_crossfade)
	else:
		_tema_atual = ""
		_xfade(_tema_player, false, 0.0, music_crossfade)
		if music_enabled:
			_xfade(_danger_player if _danger else _music_player, true, 0.0, music_crossfade)


func tema_atual() -> String:
	return _tema_atual


## Voz curta de um ipezinho (emoção: ordem, dor, alegria, cansaco; gênero do jogo: "menino" ou "menina"). Desligável nas
## Configurações; sem arquivo, nada toca.
func voz(pos: Vector2, emocao: String, genero: String = "menino") -> void:
	if not voz_ligada:
		return
	var agora := Time.get_ticks_msec()
	if agora - _voz_ultima < int(voz_intervalo * 1000.0):
		return
	var id := "voz/%s_%s" % ["mulher" if genero == "menina" else "homem", emocao]
	var arr := _slot_streams(id)
	if arr.is_empty():
		return
	if play_at(&"voz", arr, pos, _db_slot(id, -14.0), 0.04):
		_voz_ultima = agora


## O tipo de chão debaixo de um ponto: o caminho pintado (terra, cascalho, pedra), a poça (agua), a madeira (perto de
## plataforma, escada ou elevador); senão pelo lugar: andares fundos = pedra, pedreira = cascalho, o resto = terra.
func chao_de(pos: Vector2) -> String:
	var tree := get_tree()
	var cam := tree.get_first_node_in_group("caminhos")
	if cam and cam.has_method("tipo_em"):
		var t := String(cam.tipo_em(pos))
		if t in ["terra", "cascalho", "pedra"]:
			return t
	var fundo := tree.get_first_node_in_group("fundo")
	if fundo and fundo.has_method("poca_at") and fundo.poca_at(pos) != null:
		return "agua"
	for g in ["elevadores", "elevador", "espirais"]:
		for n in tree.get_nodes_in_group(g):
			if n is Node2D and (n as Node2D).global_position.distance_to(pos) <= RAIO_MADEIRA:
				return "madeira"
	var env := tree.get_first_node_in_group("environment")
	if env:
		if env.has_method("level_at") and env.level_at(pos) >= 2:
			return "pedra"
		if env.has_method("surface_area") and String(env.surface_area(pos)) == "mina":
			return "cascalho"
	return "terra"


# ------------------------------------------------------------ ducking e eco
## Limita a música: um AudioEffectAmplify no bus Music (o slider de música continua valendo, o ducking soma).
func _setup_duck() -> void:
	var idx := AudioServer.get_bus_index(&"Music")
	for i in AudioServer.get_bus_effect_count(idx):
		var e := AudioServer.get_bus_effect(idx, i)
		if e is AudioEffectAmplify and e.resource_name == "duck":
			_duck_fx = e
			_duck_t = Time.get_ticks_msec()
			return
	_duck_fx = AudioEffectAmplify.new()
	_duck_fx.resource_name = "duck"
	_duck_fx.volume_db = 0.0
	AudioServer.add_bus_effect(idx, _duck_fx)
	_duck_t = Time.get_ticks_msec()


## DUCKING: a música abaixa (alarme, sino ou aviso grande) e volta sozinha. Dois ao mesmo tempo: vale o mais fundo.
func duck(motivo: String) -> void:
	var db: float = {"alarme": duck_alarme_db, "sino": duck_sino_db, "aviso": duck_aviso_db}.get(motivo, 0.0)
	if db >= 0.0 or _duck_fx == null:
		return
	var agora := Time.get_ticks_msec()
	_duck_alvo = minf(_duck_alvo, db) if agora < _duck_ate else db
	_duck_ate = maxi(_duck_ate, agora + int(duck_segura * 1000.0))


func _duck_tick() -> void:
	if _duck_fx == null:
		return
	var agora := Time.get_ticks_msec()
	var dt := minf(float(agora - _duck_t) / 1000.0, 0.25)
	_duck_t = agora
	if agora >= _duck_ate:
		_duck_alvo = 0.0
	if is_equal_approx(_duck_db, _duck_alvo):
		return
	if _duck_db > _duck_alvo:  # descendo (ataque): rápido
		_duck_db = maxf(_duck_alvo, _duck_db - dt * 10.0 / maxf(duck_ataque, 0.01))
	else:  # voltando (soltura): devagar, sem "bombear"
		_duck_db = minf(_duck_alvo, _duck_db + dt * 10.0 / maxf(duck_solta, 0.01))
	_duck_fx.volume_db = _duck_db


## O quanto a música está abaixada agora (dB; 0 = normal).
func duck_atual() -> float:
	return _duck_db


## O eco do bus Ambience (o S5 liga): um reverb que sobe e desce junto com a troca de ambiência.
func _setup_eco() -> void:
	var idx := AudioServer.get_bus_index(&"Ambience")
	for i in AudioServer.get_bus_effect_count(idx):
		var e := AudioServer.get_bus_effect(idx, i)
		if e is AudioEffectReverb and e.resource_name == "eco":
			_eco_fx = e
			return
	_eco_fx = AudioEffectReverb.new()
	_eco_fx.resource_name = "eco"
	_eco_fx.room_size = eco_sala
	_eco_fx.damping = 0.5
	_eco_fx.dry = 1.0
	_eco_fx.wet = 0.0
	AudioServer.add_bus_effect(idx, _eco_fx)


func _poe_eco(wet: float) -> void:
	if _eco_fx == null:
		return
	if has_meta("_eco_tw"):
		var old: Tween = get_meta("_eco_tw")
		if old and old.is_valid():
			old.kill()
	var tw := create_tween()
	set_meta("_eco_tw", tw)
	tw.tween_property(_eco_fx, "wet", clampf(wet, 0.0, 1.0), ambience_crossfade)


## O quanto de eco o bus Ambience tem agora (0 a 1).
func eco_atual() -> float:
	return _eco_fx.wet if _eco_fx else 0.0


# ------------------------------------------------------------ Bloco 115: todos os sons do jogo pelo catálogo
## Um efeito POSICIONAL pelo slot (sfx/..., animais/..., criaturas/...): volume, variação de tom e a reserva (o som de antes)
## vêm do slot. Devolve se tocou (longe da câmera ou sem som: false).
func som(id: String, pos: Vector2) -> bool:
	var arr := _slot_streams(id)
	if arr.is_empty():
		return false
	var sl := Slots.slot(id)
	return play_at(StringName(id), arr, pos, float(sl.get("db", ui_db)), float(sl.get("pitch", -1.0)))


## Um som SEM posição (conquista, alarme, venda...) pelo slot, nas vozes globais do SFX; o "duck" do slot abaixa a música.
func som_global(id: String) -> void:
	var st := _slot_stream(id)
	if st == null:
		return
	play_ui(st, _db_slot(id, ui_db))
	var d := String(Slots.slot(id).get("duck", ""))
	if d != "":
		duck(d)


## O golpe de uma criatura: cada espécie tem o seu (Lumívoro grita, Ferrugento bate ferro, Gosma, Magmante) e a Matriarca (o
## chefe) o dela; sem arquivo da Matriarca, vale o da espécie dela.
func criatura_golpe(kind: String, variant: String, pos: Vector2) -> void:
	var id: String = {"lumivoro": "sfx/lumivoro_grito", "gosma": "criaturas/gosma_ataque", "magmante": "criaturas/magmante_ataque"}.get(kind, "sfx/ferrugento_golpe")
	if variant == "chefe" and Slots.tem("criaturas/matriarca_ataque"):
		id = "criaturas/matriarca_ataque"
	som(id, pos)


## O portão da paliçada abre ou fecha.
func portao(abre: bool, pos: Vector2) -> void:
	som("sfx/portao_abre" if abre else "sfx/portao_fecha", pos)


## Alguém está sendo irradiado: o contador Geiger (no máximo uma rajada a cada 0,35 s na vila toda).
func radiacao(pos: Vector2) -> void:
	var agora := Time.get_ticks_msec()
	if agora - _geiger_ultimo < 350:
		return
	if som("perigo/geiger", pos):
		_geiger_ultimo = agora


# ------------------------------------------------------------ sons soltos pelo contexto (pássaro, coruja, trovão, gota...)
## Os slots "pontual": cada um toca de vez em quando (intervalo [min, max] s do slot) enquanto o contexto dele vale (dia, noite,
## mina, s2..s5, ou as camadas chuva e vento), num ponto aleatório perto da câmera. Sem arquivo no slot, nada.
func _pontuais_tick(delta: float) -> void:
	_pont_t -= delta
	if _pont_t > 0.0:
		return
	_pont_t = 0.5
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var agora := Time.get_ticks_msec()
	for id in _pont_ids:
		var sl := Slots.slot(id)
		if not _ctx_vale(sl.get("ctx", [])):
			continue
		var arr := Slots.streams(id)
		if arr.is_empty():
			continue
		var inter: Array = sl.get("intervalo", [10, 25])
		if not _pont_prox.has(id):  # a primeira vez só agenda (não toca assim que o contexto liga)
			_pont_prox[id] = agora + int(randf_range(float(inter[0]), float(inter[1])) * 1000.0)
			continue
		if agora < int(_pont_prox[id]):
			continue
		_pont_prox[id] = agora + int(randf_range(float(inter[0]), float(inter[1])) * 1000.0)
		var q := _pont_voz()
		q.stream = arr[_pick_index(StringName(id), arr.size())]
		q.global_position = cam.get_screen_center_position() + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(120.0, 400.0)
		q.volume_db = float(sl.get("db", -12.0))
		q.pitch_scale = randf_range(0.95, 1.05)
		q.play()


func _ctx_vale(lista: Array) -> bool:
	for c in lista:
		match String(c):
			"chuva":
				if _raining:
					return true
			"vento":
				if _vento:
					return true
			_:
				if ambience_now == String(c):
					return true
	return false


func _pont_voz() -> AudioStreamPlayer2D:
	for q in _pont_pool:
		if not q.playing:
			return q
	return _pont_pool[0]
