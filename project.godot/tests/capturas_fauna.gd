extends SceneTree
## Bloco 61 (não é teste): foto da clareira com as tocas e os bichos (coelhos e javalis), na vista
## iso, zoom de jogo e de perto. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_fauna.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var shots := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_fauna")
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
	if t > 40.0:
		return true
	var tocas: Array = main.get_tree().get_nodes_in_group("caca")
	if tocas.size() < 2:
		return false
	var meio: Vector2 = (tocas[0].global_position + tocas[1].global_position) * 0.5
	if shots == 0 and t > 4.0:
		_mira(meio, 2)
		shots = 1
	elif shots == 1 and t > 6.0:
		root.get_texture().get_image().save_png(out_dir.path_join("clareira.png"))
		_mira(tocas[1].global_position, 4)
		shots = 2
	elif shots == 2 and t > 8.0:
		root.get_texture().get_image().save_png(out_dir.path_join("javalis.png"))
		_mira(tocas[0].global_position, 4)
		shots = 3
	elif shots == 3 and t > 10.0:
		root.get_texture().get_image().save_png(out_dir.path_join("coelhos.png"))
		print("fotos em ", out_dir)
		return true
	return false
