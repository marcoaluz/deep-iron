extends SceneTree
## Bloco 69 (não é teste): a atmosfera de cada nível — S2 (névoa verde, gás, cristais verdes) e S3
## (lava, brasas, cristais vermelhos) — com e sem "reduzir efeitos". Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_atmosfera.gd -- <pasta de saída>
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
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_atmosfera")
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


func _mira(alvo: Vector2, parada: int) -> void:
	var cam = main.get_node("Camera2D")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(parada, 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(alvo)


func _process(delta: float) -> bool:
	t += delta
	if t > 50.0:
		return true
	var env = main.get_tree().get_first_node_in_group("environment")
	match step:
		0:
			if t > 4.0:
				_mira(Vector2(300, 1050), 2)
				step = 1
		1:
			if t > 7.0:
				root.get_texture().get_image().save_png(out_dir.path_join("s2.png"))
				_mira(Vector2(200, 1700), 2)
				var cam = main.get_node("Camera2D")
				var iso = main.get_tree().get_first_node_in_group("iso_view")
				cam.bounds = Rect2()
				cam.position = iso.to_screen(Vector2(200, 1700))
				cam._target_pos = cam.position
				step = 2
		2:
			if t > 10.0:
				root.get_texture().get_image().save_png(out_dir.path_join("s3.png"))
				preload("res://scripts/core/efeitos.gd").set_reduzidos(true, main.get_tree())
				step = 3
		3:
			if t > 12.0:
				root.get_texture().get_image().save_png(out_dir.path_join("s3_reduzido.png"))
				preload("res://scripts/core/efeitos.gd").set_reduzidos(false, main.get_tree())
				print("fotos em ", out_dir)
				return true
	return false
