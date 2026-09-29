extends SceneTree
## Bloco 48: janela 1280×720, tela cheia (F11 / Alt+Enter) e paradas de zoom nítidas.
## RODAR SÓ COM APPDATA ISOLADO (grava settings.cfg).
const Settings := preload("res://scripts/core/settings.gd")
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var signals := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.set_meta("screen_scale", 1.5)  # headless abre 64×64: finge uma tela 1080p (×1,5)
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func key(code: Key, alt := false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = code
	ev.alt_pressed = alt
	return ev


func whole(x: float) -> bool:
	return absf(x - roundf(x)) < 0.0001 and roundf(x) >= 1.0


## Ponto do mundo que está embaixo de um ponto da tela.
func world_under(cam: Camera2D, screen: Vector2) -> Vector2:
	return cam.position + (screen - cam.get_viewport_rect().size * 0.5) / cam.zoom.x


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 90.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var cam: Camera2D = main.get_node("Camera2D")
	if step == 0 and t > 1.5:
		step = 98
		print("== janela")
		var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
		var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
		check(w == 1280 and h == 720, "resolução base %dx%d" % [w, h])
		check(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items"
			and ProjectSettings.get_setting("display/window/stretch/aspect") == "expand", "stretch continua canvas_items / expand")
		check(root.content_scale_size == Vector2i(1280, 720), "janela usa a base 1280×720 (%s)" % root.content_scale_size)
		print("  janela headless: %s  escala usada %.2f (fingindo 1080p)" % [root.size, cam.screen_scale()])

		print("== tela cheia: F11 / Alt+Enter, escolha lembrada")
		var wm = root.get_node_or_null("WindowManager")
		check(wm != null, "autoload WindowManager")
		wm.fullscreen_changed.connect(func(_on): signals += 1)
		var panel: VBoxContainer = load("res://scripts/ui/settings_panel.gd").new()
		root.add_child(panel)
		check(panel._fullscreen != null and not panel._fullscreen.button_pressed, "configurações: caixinha 'Tela cheia' (desligada)")
		wm._input(key(KEY_F11))
		check(wm.is_fullscreen() and Settings.get_value("video", "fullscreen", false) == true, "F11 liga e grava no settings.cfg")
		check(panel._fullscreen.button_pressed, "a caixinha acompanha o F11")
		wm._input(key(KEY_F11))
		check(not wm.is_fullscreen() and Settings.get_value("video", "fullscreen", true) == false, "F11 de novo desliga e grava")
		wm._input(key(KEY_ENTER, true))
		check(wm.is_fullscreen(), "Alt+Enter liga")
		wm._input(key(KEY_KP_ENTER, true))
		check(not wm.is_fullscreen(), "Alt+Enter (teclado numérico) desliga")
		wm._input(key(KEY_ENTER))
		check(not wm.is_fullscreen(), "Enter sozinho não mexe")
		check(signals == 4, "sinal de troca a cada alternância (%d)" % signals)
		panel._fullscreen.button_pressed = true
		check(Settings.get_value("video", "fullscreen", false) == true, "clicar na caixinha também grava")
		panel.queue_free()
		wm.set_fullscreen(false)

		print("== paradas de zoom nítidas")
		for sc in [1.0, 1.5, 2.0, 3.0]:
			var stops: Array[float] = cam.zoom_stops(sc)
			var px: Array = stops.map(func(z): return snappedf(cam.art_pixel_screen(z, sc), 0.01))
			print("  escala %.1f (%s): zoom %s -> px de arte na tela %s" % [sc, {1.0: "720p", 1.5: "1080p", 2.0: "1440p", 3.0: "4K"}[sc],
				str(stops.map(func(z): return snappedf(z, 0.001))), str(px)])
			var ok := not stops.is_empty()
			for i in stops.size():
				ok = ok and whole(cam.art_pixel_screen(stops[i], sc)) and stops[i] >= cam.zoom_min - 0.0001 and stops[i] <= cam.zoom_max + 0.0001
				if i > 0:
					ok = ok and absf(cam.art_pixel_screen(stops[i], sc) - cam.art_pixel_screen(stops[i - 1], sc) - 1.0) < 0.0001
			check(ok, "escala %.1f: toda parada = pixel de arte inteiro (1 px a mais por parada)" % sc)
		check(cam.zoom_stops(3.0).size() > cam.zoom_stops(1.5).size(), "4K tem paradas mais finas que 1080p")
		check(whole(cam.art_pixel_screen(cam.zoom.x)) and is_equal_approx(cam.zoom.x, cam._target_zoom),
			"zoom inicial %.3f já é nítido (%.2f px por px de arte)" % [cam.zoom.x, cam.art_pixel_screen(cam.zoom.x)])

		print("== roda do mouse: parada em parada, suave, na direção do cursor")
		cam.follow_target = null
		cam.focus_on(Vector2(0, -40))
		cam.position = Vector2(0, -40)
		cam._target_pos = cam.position
		set_meta("z0", cam._target_zoom)
		var p: Vector2 = cam.get_viewport_rect().size * 0.5 + Vector2(180, 90)
		set_meta("p", p)
		set_meta("w0", world_under(cam, p))
		cam._zoom_by(cam.zoom_step, p)
		check(cam._target_zoom > get_meta("z0") and whole(cam.art_pixel_screen(cam._target_zoom)),
			"um clique pra dentro: %.3f -> %.3f (próxima parada)" % [get_meta("z0"), cam._target_zoom])
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 0.05:
		check(cam.zoom.x > get_meta("z0") and cam.zoom.x < cam._target_zoom, "o zoom anda suave (no meio do caminho: %.3f)" % cam.zoom.x)
		step = 2
		t_mark = t
	elif step == 2 and t - t_mark > 1.5:
		step = 98
		check(is_equal_approx(cam.zoom.x, cam._target_zoom) and whole(cam.art_pixel_screen(cam.zoom.x)),
			"assentou na parada (%.4f = %.3f px por px de arte)" % [cam.zoom.x, cam.art_pixel_screen(cam.zoom.x)])
		var drift: float = world_under(cam, get_meta("p")).distance_to(get_meta("w0"))
		check(drift < 3.0, "o ponto embaixo do cursor ficou parado (desvio %.1f px)" % drift)
		var z: float = cam._target_zoom
		cam._zoom_by(1.0 / cam.zoom_step, get_meta("p"))
		cam._zoom_by(1.0 / cam.zoom_step, get_meta("p"))
		var stops: Array[float] = cam.zoom_stops()
		var i := stops.find(z)
		check(i >= 2 and is_equal_approx(cam._target_zoom, stops[i - 2]), "dois cliques pra fora: duas paradas pra trás (%.3f)" % cam._target_zoom)
		for k in 30:
			cam._zoom_by(cam.zoom_step, get_meta("p"))
		check(is_equal_approx(cam._target_zoom, stops[-1]) and cam._target_zoom <= cam.zoom_max, "não passa do zoom máximo (%.2f)" % cam._target_zoom)
		for k in 30:
			cam._zoom_by(1.0 / cam.zoom_step, get_meta("p"))
		check(is_equal_approx(cam._target_zoom, stops[0]) and cam._target_zoom >= cam.zoom_min, "nem do mínimo (%.2f)" % cam._target_zoom)
		cam.set_target_zoom(1.3)
		check(whole(cam.art_pixel_screen(cam._target_zoom)), "zoom pedido de fora (save antigo 1,3) assenta numa parada: %.3f" % cam._target_zoom)
		cam.crisp_zoom = false
		var before: float = cam._target_zoom
		cam._zoom_by(cam.zoom_step, get_meta("p"))
		check(is_equal_approx(cam._target_zoom, before * cam.zoom_step), "crisp_zoom desligado: zoom livre como antes")
		cam.crisp_zoom = true

		print("== nada de sprite/prédio mudou de tamanho")
		var env = get_first_node_in_group("environment")
		var w = get_first_node_in_group("ipezinhos")
		var casa = get_first_node_in_group("casas")
		check(env.pixel_scale == 2.0 and w._body.scale == Vector2(2, 2) and casa.get_node("Visual").scale == Vector2(2, 2),
			"escala 2 no chão, no ipezinho e na casa (como antes)")
		check(cam.art_pixel_world == env.pixel_scale, "a câmera usa a mesma densidade de arte do mapa")

		print("== save/load guarda o zoom nítido")
		cam.set_target_zoom(2.0)
		cam.zoom = Vector2.ONE * cam._target_zoom
		set_meta("zs", cam._target_zoom)
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 2.5:
		check(is_equal_approx(cam._target_zoom, get_meta("zs")) and whole(cam.art_pixel_screen(cam._target_zoom)),
			"depois do load: mesmo zoom nítido (%.3f)" % cam._target_zoom)
		step = 99
	if step == 98:
		check(false, "o passo 0 parou no meio (erro de script)")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
