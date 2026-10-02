extends SceneTree
## Bloco 67 (não é teste): o mapa ampliado. Foto de longe (vila + leste com névoa), depois o leste
## desbravado (de longe e de perto na pedreira nova). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_leste.gd -- <pasta de saída>
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
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_leste")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_size(Vector2i(1600, 900))
	root.size = Vector2i(1600, 900)
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


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		return true
	var env = main.get_tree().get_first_node_in_group("environment")
	match step:
		0:
			if t > 4.0:
				_mira(Vector2(1300, -200), 0)
				step = 1
		1:
			if t > 6.0:
				_foto("longe_trancado")
				_mira(Vector2(900, 100), 2)
				step = 2
		2:
			if t > 8.0:
				_foto("fronteira_trancada")
				env.set_leste_aberto(true)
				step = 3
		3:
			if t > 11.0:
				_mira(Vector2(1300, -200), 0)
				step = 4
		4:
			if t > 13.0:
				_foto("longe_aberto")
				_mira(Vector2(1800, 150), 3)
				step = 5
		5:
			if t > 15.0:
				_foto("pedreira_leste")
				_mira(Vector2(1600, -750), 3)
				step = 6
		6:
			if t > 17.0:
				_foto("floresta_leste")
				print("fotos em ", out_dir)
				return true
	return false
