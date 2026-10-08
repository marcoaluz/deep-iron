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
var _streams := {}  # nome -> AudioStream (sons novos, carregados no _ready)
const NOVOS := {
	"build": ["build_hit_0", "build_hit_1", "build_hit_2"], "build_done": ["build_done"],
	"harvest": ["harvest_0", "harvest_1", "harvest_2"], "equip": ["equip"], "party": ["party"],
	"ui_open": ["ui_open"], "ui_close": ["ui_close"], "place": ["place"], "creature_down": ["creature_down"],
	"drill": ["drill"], "music_danger": ["music_danger"], "rain_loop": ["rain_loop"],
	"surface_day_loop": ["surface_day_loop"], "surface_night_loop": ["surface_night_loop"], "deep_loop": ["deep_loop"],
}


const Settings := preload("res://scripts/core/settings.gd")


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
	for k in NOVOS:
		var arr: Array[AudioStream] = []
		for nome in NOVOS[k]:
			var path := "res://assets/audio/%s.wav" % nome
			if ResourceLoader.exists(path):
				arr.append(load(path))
		_streams[k] = arr
	_setup_limiter()

	_music_player = _make_loop_player(music, &"Music")
	_danger_player = _make_loop_player(_first("music_danger"), &"Music")
	_ambience_player = _make_loop_player(ambience, &"Ambience")
	_amb = {"mina": _ambience_player, "dia": _make_loop_player(_first("surface_day_loop"), &"Ambience"),
		"noite": _make_loop_player(_first("surface_night_loop"), &"Ambience"), "fundo": _make_loop_player(_first("deep_loop"), &"Ambience")}
	_rain_player = _make_loop_player(_first("rain_loop"), &"Ambience")
	if music_enabled and _music_player.stream:
		_fade_in(_music_player)
	if _ambience_player.stream:
		_fade_in(_ambience_player, ambience_db.get("mina", 0.0))


func _process(delta: float) -> void:
	_step_tokens = minf(_step_tokens + max_steps_per_second * delta, max_steps_per_second)
	_ctx_timer -= delta
	if _ctx_timer <= 0.0:
		_ctx_timer = 0.5
		_update_context()


# ------------------------------------------------------------ Bloco 55: contexto (ambiência e música)
## Onde a câmera está olhando decide a ambiência: clareira (dia/noite, + chuva por cima), mina, ou o
## fundo (nível 2/abismo). Invasão acontecendo troca a música pra de perigo (e volta depois).
func _update_context() -> void:
	var tree := get_tree()
	var env := tree.get_first_node_in_group("environment")
	var cam := get_viewport().get_camera_2d()
	var ctx := "mina"
	var rain := false
	if env and cam:
		var ground: Vector2 = cam.ground_center() if cam.has_method("ground_center") else cam.get_screen_center_position()
		if env.has_method("level_at") and env.level_at(ground) >= 2:
			ctx = "fundo"
		elif env.has_method("open_sky_rect") and env.open_sky_rect().has_point(ground) and env.surface_area(ground) != "mina":
			# Bloco 74: céu aberto na floresta e na vila; na área da mina (montanha, armazém) o som da mina
			var dn := tree.get_first_node_in_group("day_night")
			ctx = "noite" if dn and dn.has_method("is_night") and dn.is_night() else "dia"
			var w := tree.get_first_node_in_group("weather")
			rain = w != null and w.has_method("level") and w.level("rain") > 0.3
	set_ambience(ctx, rain)
	var d := tree.get_first_node_in_group("defense")
	set_danger(d != null and bool(d.get("invasion_active")))


func set_ambience(ctx: String, rain: bool = false) -> void:
	if not _amb.has(ctx):
		ctx = "mina"
	if ctx != ambience_now:
		ambience_now = ctx
		for k in _amb:
			_xfade(_amb[k], k == ctx, ambience_db.get(k, 0.0), ambience_crossfade)
	if rain != _raining:
		_raining = rain
		_xfade(_rain_player, rain, rain_db, ambience_crossfade)


func set_danger(on: bool) -> void:
	if on == _danger:
		return
	_danger = on
	if not music_enabled:
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


func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func toggle_music() -> void:
	music_enabled = not music_enabled
	if music_enabled:
		_fade_in(_danger_player if _danger else _music_player)
	else:
		_music_player.stop()
		_danger_player.stop()
	save_settings()


## Volumes e música vêm de user://settings.cfg (o Inspector só dá o padrão da 1ª vez).
func _load_settings() -> void:
	master_volume = Settings.get_value("audio", "master_volume", master_volume)
	music_volume = Settings.get_value("audio", "music_volume", music_volume)
	ambience_volume = Settings.get_value("audio", "ambience_volume", ambience_volume)
	sfx_volume = Settings.get_value("audio", "sfx_volume", sfx_volume)
	music_enabled = Settings.get_value("audio", "music_enabled", music_enabled)


func save_settings() -> void:
	for key in ["master_volume", "music_volume", "ambience_volume", "sfx_volume", "music_enabled"]:
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
	play_at(&"pick", pick_sounds, pos, pick_db)


func step(pos: Vector2) -> void:
	if _step_tokens < 1.0:
		return
	_step_tokens -= 1.0
	play_at(&"step", step_sounds, pos, step_db, 0.12)


func deposit(pos: Vector2) -> void:
	play_at(&"deposit", deposit_sounds, pos, deposit_db)


func eat(pos: Vector2) -> void:
	play_at(&"eat", eat_sounds, pos, eat_db)


func hurt(pos: Vector2) -> void:
	if hurt_sound:
		play_at(&"hurt", [hurt_sound], pos, hurt_db)


func heal(pos: Vector2) -> void:
	if heal_sound:
		play_at(&"heal", [heal_sound], pos, heal_db, 0.0)


func forge(pos: Vector2) -> void:
	if forge_sound:
		play_at(&"forge", [forge_sound], pos, forge_db, 0.12)


func chop(pos: Vector2) -> void:
	play_at(&"chop", chop_sounds, pos, chop_db)


func elevator(pos: Vector2) -> void:
	if elevator_sound:
		play_at(&"elevator", [elevator_sound], pos, elevator_db, 0.05)


func branch(pos: Vector2) -> void:
	if branch_sound:
		play_at(&"branch", [branch_sound], pos, branch_db)


func fanfare() -> void:
	play_ui(fanfare_sound, fanfare_db)


func toll() -> void:
	play_ui(toll_sound, toll_db)


func cheers(pos: Vector2) -> void:
	if cheers_sound:
		play_at(&"cheers", [cheers_sound], pos, cheers_db)


func find(pos: Vector2) -> void:
	if find_sound:
		play_at(&"find", [find_sound], pos, find_db, 0.02)


func robot(pos: Vector2) -> void:
	if robot_sound:
		play_at(&"robot", [robot_sound], pos, robot_db, 0.0)


func boom(pos: Vector2) -> void:
	if boom_sound:
		play_at(&"boom", [boom_sound], pos, boom_db, 0.05)


func alarm() -> void:
	play_ui(alarm_sound, alarm_db)


func solar() -> void:
	play_ui(solar_sound, solar_db)


func screech(pos: Vector2) -> void:
	if screech_sound:
		play_at(&"screech", [screech_sound], pos, screech_db, 0.12)


func clank(pos: Vector2) -> void:
	if clank_sound:
		play_at(&"clank", [clank_sound], pos, clank_db, 0.1)


func hit(pos: Vector2) -> void:
	if hit_sound:
		play_at(&"hit", [hit_sound], pos, hit_db, 0.12)


func gate_break(pos: Vector2) -> void:
	if gate_break_sound:
		play_at(&"gate_break", [gate_break_sound], pos, gate_break_db, 0.05)


func protest(pos: Vector2) -> void:
	if protest_sound:
		play_at(&"protest", [protest_sound], pos, protest_db, 0.03)


# ------------------------------------------------------------ Bloco 55: eventos que não tinham som
func build_hit(pos: Vector2) -> void:
	play_at(&"build", _streams.get("build", [] as Array[AudioStream]), pos, build_db, 0.1)


func build_done(pos: Vector2) -> void:
	play_at(&"build_done", _streams.get("build_done", [] as Array[AudioStream]), pos, build_done_db, 0.02)


func harvest(pos: Vector2) -> void:
	play_at(&"harvest", _streams.get("harvest", [] as Array[AudioStream]), pos, harvest_db)


func equip(pos: Vector2) -> void:
	play_at(&"equip", _streams.get("equip", [] as Array[AudioStream]), pos, equip_db)


func party() -> void:
	play_ui(_first("party"), party_db)


func place_sound() -> void:
	play_ui(_first("place"), place_db)


func creature_down(pos: Vector2) -> void:
	play_at(&"creature_down", _streams.get("creature_down", [] as Array[AudioStream]), pos, creature_down_db)


func drill(pos: Vector2) -> void:
	play_at(&"drill", _streams.get("drill", [] as Array[AudioStream]), pos, drill_db, 0.06)


func ui_open() -> void:
	play_ui(_first("ui_open"), ui_panel_db)


func ui_close() -> void:
	play_ui(_first("ui_close"), ui_panel_db)


func sell() -> void:
	play_ui(sell_sound)


func recruit() -> void:
	play_ui(recruit_sound)


## Bloco 101: migrantes chegando no portão.
func migrantes(pos: Vector2) -> void:
	if migrantes_sound:
		play_at(&"migrantes", [migrantes_sound], pos, ui_db)


func click() -> void:
	play_ui(click_sound, ui_db - 6.0)


func error() -> void:
	play_ui(error_sound)


func play_at(key: StringName, streams: Array[AudioStream], pos: Vector2, volume_db: float, pitch_var: float = -1.0) -> void:
	if streams.is_empty() or _pool.is_empty():
		return
	var cam := get_viewport().get_camera_2d()
	if cam and cam.get_screen_center_position().distance_to(pos) > sfx_max_distance:
		return
	# Bloco 55: no máximo max_same_voice do mesmo som tocando (o resto não entra)
	var iguais := 0
	for v in _pool:
		if v.playing and v.get_meta("key", &"") == key:
			iguais += 1
	if iguais >= max_same_voice:
		return
	var p := _take_voice()
	p.set_meta("key", key)
	p.stream = streams[_pick_index(key, streams.size())]
	p.global_position = pos
	p.volume_db = volume_db
	var pv := pitch_variation if pitch_var < 0.0 else pitch_var
	p.pitch_scale = randf_range(1.0 - pv, 1.0 + pv)
	p.play()


func play_ui(stream: AudioStream, volume_db: float = NAN) -> void:
	if stream == null:
		return
	var u := _ui_pool[_next_ui]
	for i in _ui_pool.size():  # uma livre, se tiver (senão a mais antiga)
		var c := _ui_pool[(_next_ui + i) % _ui_pool.size()]
		if not c.playing:
			u = c
			break
	_next_ui = (_ui_pool.find(u) + 1) % _ui_pool.size()
	u.stream = stream
	u.volume_db = ui_db if is_nan(volume_db) else volume_db
	u.play()


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
