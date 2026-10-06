extends SceneTree
## Bloco 90 (não é teste): a decoração do jogador à noite (tochas e lampiões acesos, bancos, mesa, flores).
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco90.gd -- <pasta de saída>
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
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b90")
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
	if step == 0 and t > 4.0:
		var hub = get_first_node_in_group("village_hub")
		var dm = get_first_node_in_group("decoracoes_mgr")
		var eco = get_first_node_in_group("economy")
		eco.credits = 9999.0
		var arm = get_first_node_in_group("armazens")
		arm.stock["ferro"] = 999.0
		arm.wood_stored = 999.0
		arm._recount()
		var placer = get_first_node_in_group("house_placer")
		var base: Vector2 = hub.global_position + Vector2(150, 110)
		var plano := [["lampiao", Vector2(0, 0)], ["banco", Vector2(30, 10)], ["lampiao", Vector2(80, 0)], ["mesa", Vector2(40, 50)],
			["tocha", Vector2(-20, 60)], ["tocha", Vector2(100, 60)], ["canteiro_flores", Vector2(-30, 25)], ["canteiro_flores", Vector2(110, 25)],
			["bandeira", Vector2(50, -20)], ["cerca", Vector2(40, 95)]]
		for pl in plano:
			var pg = load("res://scripts/core/decor.gd").pegada(pl[0])
			placer.begin(Callable(), load(load("res://scripts/core/decor.gd").info(pl[0]).textura), 1, "x", {"footprint": Rect2(-pg * 0.5, pg)})
			placer._collect_blockers()
			var q := Vector2.INF
			for r in range(0, 120, 6):
				for a in range(12):
					var c: Vector2 = (base + pl[1] + Vector2.RIGHT.rotated(a * TAU / 12.0) * r).round()
					if q == Vector2.INF and placer.check_spot(c) == "":
						q = c
			placer.cancel()
			if q != Vector2.INF:
				dm.colocar(pl[0], q)
		dn.time = dn.day_duration + 60.0
		dn.snap_lighting()
		get_first_node_in_group("hud").visible = false
		var cam = main.get_node("Camera2D")
		var iso = main.get_node("IsoView")
		cam.bounds = Rect2()
		cam.zoom = Vector2(2.2, 2.2)
		cam._target_zoom = 2.2
		cam.position = iso.to_screen(base + Vector2(40, 30)) + Vector2(0, -20)
		cam._target_pos = cam.position
		step = 1
		t = 0.0
	elif step == 1 and t > 2.5:
		root.get_texture().get_image().save_png(out_dir.path_join("decoracao_noite.png"))
		print("ok")
		return true
	if dn and step >= 1:
		dn.time = dn.day_duration + 60.0
	return false
