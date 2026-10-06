extends SceneTree
## Bloco 89 (não é teste): os três tipos de caminho pintados na vila.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco89.gd -- <pasta de saída>
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
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b89")
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
	if step == 0 and t > 4.0:
		var hub = get_first_node_in_group("village_hub")
		var eco = get_first_node_in_group("economy")
		eco.credits = 9999.0
		var arm = get_first_node_in_group("armazens")
		arm.stock["ferro"] = 999.0
		arm._recount()
		var pl = get_first_node_in_group("caminho_placer")
		var a: Vector2 = hub.global_position + Vector2(-140, 120)
		for k in 3:
			pl.begin(["terra", "cascalho", "pedra"][k])
			pl.pinta_ate(a + Vector2(0, k * 40))
			pl.pinta_ate(a + Vector2(220, k * 40))
			pl.pinta_ate(a + Vector2(220, k * 40 + 20))
			pl.cancel()
		get_first_node_in_group("hud").visible = false
		var cam = main.get_node("Camera2D")
		var iso = main.get_node("IsoView")
		cam.bounds = Rect2()
		cam.zoom = Vector2(1.8, 1.8)
		cam._target_zoom = 1.8
		cam.position = iso.to_screen(a + Vector2(110, 40))
		cam._target_pos = cam.position
		step = 1
		t = 0.0
	elif step == 1 and t > 2.0:
		root.get_texture().get_image().save_png(out_dir.path_join("caminhos.png"))
		print("ok")
		return true
	return false
