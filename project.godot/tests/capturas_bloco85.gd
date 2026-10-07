extends SceneTree
## Bloco 85 (não é teste): a hora social na praça — rodas de conversa com balão.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco85.gd -- <pasta de saída>
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
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b85")
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
		w.refeicoes_hoje["jantar"] = true
	if step == 0 and t > 4.0:
		while get_nodes_in_group("ipezinhos").size() < 8:
			get_first_node_in_group("economy").recruit_free()
		for w in get_nodes_in_group("ipezinhos"):
			w.set_job("minerador")
		var sched = get_first_node_in_group("schedule")
		sched.conversa_min = 60.0
		sched.conversa_max = 90.0
		dn.ir_para_hora(18.6)
		# só a praça: todo mundo junto pra foto
		for s in get_nodes_in_group("social_spots"):
			if s.tipo != "praca":
				s.remove_from_group("social_spots")
		var hud = get_first_node_in_group("hud")
		hud.visible = false
		Engine.time_scale = 3.0
		step = 1
		t = 0.0
	elif step == 1 and t > 45.0:
		Engine.time_scale = 1.0
		var praca = null
		for s in get_nodes_in_group("social_spots"):
			praca = s
		var cam = main.get_node("Camera2D")
		var iso = main.get_node("IsoView")
		cam.bounds = Rect2()
		cam.zoom = Vector2(2.6, 2.6)
		cam._target_zoom = 2.6
		cam.position = iso.to_screen(praca.centro()) + Vector2(0, -20)
		cam._target_pos = cam.position
		step = 2
		t = 0.0
	elif step == 2 and t > 2.5:
		root.get_texture().get_image().save_png(out_dir.path_join("hora_social_praca.png"))
		print("ok")
		return true
	return false
