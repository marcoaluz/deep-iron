extends SceneTree
## Bloco 91 (não é teste): as criaturas do PixelLab no jogo, lado a lado (Lumívoro, Matriarca, Gosma, Magmante, Ferrugento) com um ipezinho.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco91.gd -- <pasta de saída>
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
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b91")
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


var bichos: Array = []


func _process(delta: float) -> bool:
	t += delta
	if step == 0 and t > 4.0:
		var hub = get_first_node_in_group("village_hub")
		var base: Vector2 = Vector2(-600, 330)  # (a clareira: chão aberto)
		var kinds := ["lumivoro", "chefe", "gosma", "magmante", "ferrugento"]
		for k in kinds.size():
			var kind: String = kinds[k]
			var cena := "lumivoro" if kind == "chefe" else kind
			var c = load("res://scenes/creatures/%s.tscn" % cena).instantiate()
			c.position = base + Vector2(k * 58, (k % 2) * 14)
			hub.get_parent().add_child(c)
			if kind == "chefe":
				c.make_boss(2.0, 1.5)
			c.set_process(false)
			bichos.append(c)
		var w = get_nodes_in_group("ipezinhos")[0]
		w.global_position = base + Vector2(-58, 0)
		w.set_process(false)
		w._inside = false
		w.visible = true
		get_first_node_in_group("hud").visible = false
		var cam = main.get_node("Camera2D")
		var iso = main.get_node("IsoView")
		cam.bounds = Rect2()
		cam.zoom = Vector2(2.4, 2.4)
		cam._target_zoom = 2.4
		cam.position = iso.to_screen(base + Vector2(90, 0)) + Vector2(0, -50)
		cam._target_pos = cam.position
		step = 1
		t = 0.0
	elif step == 1 and t > 2.0:
		root.get_texture().get_image().save_png(out_dir.path_join("criaturas_lado_a_lado.png"))
		print("ok")
		return true
	return false
