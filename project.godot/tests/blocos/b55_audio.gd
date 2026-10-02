extends SceneTree
## Bloco 55: passe de áudio. Buses + limitador no Master, sliders mexendo nos buses, todo evento com
## som (sem lacuna), música de perigo na invasão (e volta), ambiência pelo lugar da câmera (mina,
## clareira de dia/noite, chuva por cima, fundo), limite de vozes do mesmo som, e 15 ipezinhos
## trabalhando sem passar do teto. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var audio: Node
var t := 0.0
var step := 0
var t_mark := 0.0
var fails := 0
var peak := -200.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	audio = root.get_node("Audio")


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 80.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_buses()
				_eventos()
				_vozes()
				_ambiencia()
				g("defense").start_invasion()
				audio._update_context()
				step = 1
				t_mark = t
		1:
			if t - t_mark > audio.music_crossfade + 0.6:
				check(audio.is_danger() and audio._danger_player.playing and audio._danger_player.volume_db > -3.0, "invasão: música de perigo subiu (%.1f dB)" % audio._danger_player.volume_db)
				check(audio._music_player.volume_db < -30.0 or not audio._music_player.playing, "a calma desceu")
				var d = g("defense")
				for c in main.get_tree().get_nodes_in_group("criaturas"):
					c.queue_free()
				d.invasion_active = false
				audio._update_context()
				step = 2
				t_mark = t
		2:
			if t - t_mark > audio.music_crossfade + 0.6:
				check(not audio.is_danger() and audio._music_player.playing and audio._music_player.volume_db > -3.0, "invasão acabou: volta a calma (%.1f dB)" % audio._music_player.volume_db)
				check(not audio._danger_player.playing, "a de perigo parou")
				_trabalho()
				step = 3
				t_mark = t
		3:
			var idx := AudioServer.get_bus_index(&"Master")
			peak = maxf(peak, maxf(AudioServer.get_bus_peak_volume_left_db(idx, 0), AudioServer.get_bus_peak_volume_right_db(idx, 0)))
			if t - t_mark > 10.0:
				check(peak <= audio.limiter_ceiling_db + 0.3, "15 ipezinhos trabalhando: pico do Master %.1f dB (teto %.1f)" % [peak, audio.limiter_ceiling_db])
				Engine.time_scale = 1.0
				print("FALHAS: %d" % fails)
				return true
	return false


func _buses() -> void:
	print("== buses e mixer")
	for b in ["Master", "Music", "Ambience", "SFX"]:
		check(AudioServer.get_bus_index(b) >= 0, "bus %s" % b)
	var m := AudioServer.get_bus_index(&"Master")
	var lim: AudioEffect = null
	for i in AudioServer.get_bus_effect_count(m):
		if AudioServer.get_bus_effect(m, i) is AudioEffectHardLimiter:
			lim = AudioServer.get_bus_effect(m, i)
	check(lim != null and lim.ceiling_db <= 0.0, "limitador no Master (teto %s dB)" % (str(lim.ceiling_db) if lim else "-"))
	var sfx0: float = audio.sfx_volume
	audio.sfx_volume = 0.5
	audio.apply_volumes()
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"SFX")) - linear_to_db(0.5)) < 0.1, "slider de efeitos mexe no bus SFX")
	audio.music_volume = 0.2
	audio.apply_volumes()
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")) - linear_to_db(0.2)) < 0.1, "slider de música mexe no bus Music")
	audio.sfx_volume = sfx0
	audio.music_volume = 0.35
	audio.apply_volumes()


## Tabela evento -> som: todo som que o jogo chama existe (nenhum vazio).
func _eventos() -> void:
	print("== eventos com som")
	var falta := []
	for k in ["pick_sounds", "step_sounds", "deposit_sounds", "eat_sounds", "chop_sounds"]:
		if (audio.get(k) as Array).is_empty():
			falta.append(k)
	for k in ["sell_sound", "recruit_sound", "click_sound", "error_sound", "hurt_sound", "heal_sound", "forge_sound",
			"fanfare_sound", "elevator_sound", "branch_sound", "toll_sound", "cheers_sound", "protest_sound", "find_sound",
			"robot_sound", "boom_sound", "alarm_sound", "screech_sound", "clank_sound", "hit_sound", "gate_break_sound", "solar_sound"]:
		if audio.get(k) == null:
			falta.append(k)
	for k in audio.NOVOS:
		if (audio._streams.get(k, []) as Array).is_empty():
			falta.append(k)
	check(falta.is_empty(), "todos os sons carregados (%d novos)%s" % [audio.NOVOS.size(), (" — faltam: %s" % str(falta)) if not falta.is_empty() else ""])
	for f in ["build_hit", "build_done", "harvest", "equip", "creature_down", "drill"]:
		check(audio.has_method(f), "Audio.%s()" % f)
	for f in ["party", "place_sound", "ui_open", "ui_close"]:
		check(audio.has_method(f), "Audio.%s()" % f)
	# a fanfarra não é mais cortada por um clique (4 vozes de interface)
	audio.fanfare()
	audio.click()
	var tocando: int = audio._ui_pool.filter(func(u): return u.playing).size()
	check(tocando >= 2, "fanfarra + clique tocam juntos (%d vozes de interface)" % tocando)


func _vozes() -> void:
	print("== limite de vozes")
	var cam := main.get_viewport().get_camera_2d()
	var pos: Vector2 = cam.get_screen_center_position()
	for i in 20:
		audio.play_at(&"pick", audio.pick_sounds, pos, -10.0)
	var n := 0
	for v in audio._pool:
		if v.playing and v.get_meta("key", &"") == &"pick":
			n += 1
	check(n <= audio.max_same_voice and n >= 1, "20 picaretas no mesmo quadro: %d tocando (máximo %d)" % [n, audio.max_same_voice])
	for v in audio._pool:
		v.stop()


func _ambiencia() -> void:
	print("== ambiência pelo lugar")
	var env = g("environment")
	var cam = main.get_node("Camera2D")
	var dn = g("day_night")
	var w = g("weather")
	cam.focus_on(g("village_hub").global_position)
	cam.position = cam._target_pos
	cam.force_update_scroll()
	audio._update_context()
	check(audio.ambience_now == "mina", "câmera na vila (mina): %s" % audio.ambience_now)
	var clareira: Vector2 = (env.clearing_rect as Rect2).get_center()
	cam.focus_on(clareira)
	cam.position = cam._target_pos
	cam.force_update_scroll()
	dn.time = 10.0
	dn._process(0.0)
	audio._update_context()
	check(audio.ambience_now == "dia", "clareira de dia: %s (chão %s)" % [audio.ambience_now, cam.ground_center().round()])
	dn.time = dn.day_duration + 5.0
	dn._process(0.0)
	audio._update_context()
	check(audio.ambience_now == "noite", "clareira de noite: %s" % audio.ambience_now)
	w.forcar_chuva = true
	w.snap()
	audio._update_context()
	check(audio._raining and audio._rain_player.playing, "chuva por cima")
	w.forcar_chuva = false
	w.snap()
	audio._update_context()
	check(not audio._raining, "parou de chover")
	if env.deep_rect.has_area():
		cam.focus_on(env.deep_rect.get_center())
		cam.position = cam._target_pos
		cam.force_update_scroll()
		audio._update_context()
		check(audio.ambience_now == "fundo", "nível 2: %s" % audio.ambience_now)
	dn.time = 10.0
	dn._process(0.0)
	cam.focus_on(g("village_hub").global_position)
	cam.position = cam._target_pos
	cam.force_update_scroll()
	audio._update_context()


func _trabalho() -> void:
	print("== 15 ipezinhos trabalhando")
	var eco = g("economy")
	eco.max_workers = 30
	while main.get_tree().get_nodes_in_group("ipezinhos").size() < 15:
		if eco.recruit_free() == null:
			break
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	for i in ws.size():
		ws[i].set_job(["minerador", "lenhador", "minerador", "cozinheiro"][i % 4])
	var cam = main.get_node("Camera2D")
	cam.focus_on(g("village_hub").global_position)
	Engine.time_scale = 3.0
	print("    %d ipezinhos" % ws.size())
