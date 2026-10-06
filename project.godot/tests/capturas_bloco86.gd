extends SceneTree
## Bloco 86 (não é teste): a fornalha funcionando (fundidor) e a janela com receitas e fila.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco86.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b86")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _process(delta: float) -> bool:
	t += delta
	var dn = get_first_node_in_group("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(10.0)
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 4.0:
		var hub = get_first_node_in_group("village_hub")
		hub.level = 2
		var p = get_first_node_in_group("house_placer")
		hub.build_fornalha()
		p._collect_blockers()
		var q := Vector2.INF
		for r in range(0, 400, 12):
			for a in range(24):
				var c: Vector2 = (hub.global_position + Vector2(-60, 120) + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
				if q == Vector2.INF and p.check_spot(c) == "":
					q = c
		p.cancel()
		var f = hub.spawn_fornalha(q)
		var arm = get_first_node_in_group("armazens")
		arm.stock["ferro"] = 80.0
		arm.stock["carvao"] = 40.0
		arm._recount()
		f.encomendar("barra_ferro", 10)
		f.encomendar("barra_cobre", 4)
		get_nodes_in_group("ipezinhos")[0].set_job("fundidor")
		set_meta("f", f)
		get_first_node_in_group("hud").visible = false
		Engine.time_scale = 4.0
		step = 1
		t = 0.0
	elif step == 1 and (get_meta("f")._acesa or t > 120.0):
		Engine.time_scale = 1.0
		var f = get_meta("f")
		var cam = main.get_node("Camera2D")
		var iso = main.get_node("IsoView")
		cam.bounds = Rect2()
		cam.zoom = Vector2(2.4, 2.4)
		cam._target_zoom = 2.4
		cam.position = iso.to_screen(f.global_position) + Vector2(0, -30)
		cam._target_pos = cam.position
		step = 2
		t = 0.0
	elif step == 2 and t > 1.5:
		root.get_texture().get_image().save_png(out_dir.path_join("fornalha_acesa.png"))
		var hud = get_first_node_in_group("hud")
		hud.visible = true
		hud.open_panel("fornalha", get_meta("f"))
		step = 3
		t = 0.0
	elif step == 3 and t > 1.0:
		root.get_texture().get_image().save_png(out_dir.path_join("janela_fornalha.png"))
		print("ok")
		return true
	return false
