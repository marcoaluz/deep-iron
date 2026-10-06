extends SceneTree
## Bloco 88 (não é teste): a missa de domingo na igreja, com o padre.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco88.gd -- <pasta de saída>
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
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b88")
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
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 4.0:
		var hub = get_first_node_in_group("village_hub")
		var cal = get_first_node_in_group("calendario")
		hub.level = 2
		cal._process(0.0)
		while get_nodes_in_group("ipezinhos").size() < 9:
			get_first_node_in_group("economy").recruit_free()
		var p = get_first_node_in_group("house_placer")
		hub.build_igreja()
		p._collect_blockers()
		var q := Vector2.INF
		for r in range(0, 400, 12):
			for a in range(24):
				var c: Vector2 = (hub.global_position + Vector2(-150, 140) + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
				if q == Vector2.INF and p.check_spot(c) == "":
					q = c
		p.cancel()
		hub.spawn_igreja(q)
		dn.day = 7
		dn._pula_para(dn.tempo_da_hora(8.95))
		get_first_node_in_group("hud").visible = false
		Engine.time_scale = 5.0
		step = 1
		t = 0.0
	elif step == 1 and dn.hora() >= 10.2:
		Engine.time_scale = 1.0
		var ig = get_first_node_in_group("igrejas")
		var cam = main.get_node("Camera2D")
		var iso = main.get_node("IsoView")
		cam.bounds = Rect2()
		cam.zoom = Vector2(2.0, 2.0)
		cam._target_zoom = 2.0
		cam.position = iso.to_screen(ig.global_position + Vector2(0, 40)) + Vector2(0, -40)
		cam._target_pos = cam.position
		step = 2
		t = 0.0
	elif step == 2 and t > 2.0:
		root.get_texture().get_image().save_png(out_dir.path_join("missa_domingo.png"))
		print("ok")
		return true
	return false
