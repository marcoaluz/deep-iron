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
@export var click_sound: AudioStream
@export var error_sound: AudioStream
@export var hurt_sound: AudioStream
@export var heal_sound: AudioStream
@export var forge_sound: AudioStream
@export var fanfare_sound: AudioStream

@export_group("Mixagem dos efeitos (dB)")
@export var pick_db: float = -7.0
@export var step_db: float = -22.0
@export var deposit_db: float = -9.0
@export var eat_db: float = -11.0
@export var hurt_db: float = -4.0
@export var heal_db: float = -8.0
@export var forge_db: float = -10.0
@export var fanfare_db: float = -4.0
@export var ui_db: float = -6.0
## Variação aleatória de pitch (0.08 = ±8%), pra não soar repetitivo.
@export var pitch_variation: float = 0.08

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	apply_volumes()

	for i in max_voices:
		var p := AudioStreamPlayer2D.new()
		p.bus = &"SFX"
		p.max_distance = sfx_max_distance
		p.attenuation = 1.2
		add_child(p)
		_pool.append(p)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = &"SFX"
	add_child(_ui_player)

	_music_player = _make_loop_player(music, &"Music")
	_ambience_player = _make_loop_player(ambience, &"Ambience")
	if music_enabled and _music_player.stream:
		_fade_in(_music_player)
	if _ambience_player.stream:
		_fade_in(_ambience_player)


func _process(delta: float) -> void:
	_step_tokens = minf(_step_tokens + max_steps_per_second * delta, max_steps_per_second)


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
		_fade_in(_music_player)
	else:
		_music_player.stop()


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


func _fade_in(p: AudioStreamPlayer) -> void:
	if p.stream == null:
		return
	p.volume_db = -40.0
	p.play()
	create_tween().tween_property(p, "volume_db", 0.0, fade_in_time)


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


func fanfare() -> void:
	play_ui(fanfare_sound, fanfare_db)


func sell() -> void:
	play_ui(sell_sound)


func recruit() -> void:
	play_ui(recruit_sound)


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
	var p := _take_voice()
	p.stream = streams[_pick_index(key, streams.size())]
	p.global_position = pos
	p.volume_db = volume_db
	var pv := pitch_variation if pitch_var < 0.0 else pitch_var
	p.pitch_scale = randf_range(1.0 - pv, 1.0 + pv)
	p.play()


func play_ui(stream: AudioStream, volume_db: float = NAN) -> void:
	if stream == null:
		return
	_ui_player.stream = stream
	_ui_player.volume_db = ui_db if is_nan(volume_db) else volume_db
	_ui_player.play()


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
