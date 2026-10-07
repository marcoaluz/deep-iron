extends SceneTree
## Bloco 69 (não é teste): a atmosfera de cada nível — S1 (poeira), S2 (névoa verde, gás, cristais
## verdes) e S3 (lava, brasas, cristais vermelhos) — com e sem "reduzir efeitos", atmosfera desligada
## e uma foto de longe (as lajes empilhadas embaixo da superfície). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_atmosfera.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const Settings := preload("res://scripts/core/settings.gd")
const Efeitos := preload("res://scripts/core/efeitos.gd")
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var _prox := 4.0
## [nome da foto, ponto da lógica (Vector2.INF = centro do nível), parada do zoom, preparo]
var _fotos := []


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
	var iso = main.get_tree().get_first_node_in_group("iso_view")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(parada, 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.bounds = Rect2()  # as lajes de baixo ficam fora do limite da superfície
	cam.position = iso.to_screen(alvo)
	cam._target_pos = cam.position


func _prepara() -> void:
	var env = main.get_tree().get_first_node_in_group("environment")
	var hud = main.get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = false
	var vila: Vector2 = main.get_tree().get_first_node_in_group("village_hub").global_position
	_fotos = [
		["s1_vila", vila + Vector2(0, 60), 2, func(): pass],
		["s2", env.deep_rect.get_center(), 2, func(): pass],
		["s3", env.abyss_rect.get_center(), 2, func(): pass],
		["s3_reduzido", env.abyss_rect.get_center(), 2, func(): Efeitos.set_reduzidos(true, main.get_tree())],
		["s2_sem_atmosfera", env.deep_rect.get_center(), 2, func():
			Efeitos.set_reduzidos(false, main.get_tree())
			Settings.set_value("video", "atmosfera", 0.0)
			main.get_tree().call_group("efeitos", "efeitos_mudaram")],
		["longe", (vila + env.deep_rect.get_center()) * 0.5, 0, func():
			Settings.set_value("video", "atmosfera", 1.0)
			main.get_tree().call_group("efeitos", "efeitos_mudaram")],
	]


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		return true
	if t < _prox:
		return false
	if step == 0:
		_prepara()
	var i := step / 2
	if i >= _fotos.size():
		print("fotos em ", out_dir)
		return true
	var f: Array = _fotos[i]
	if step % 2 == 0:
		(f[3] as Callable).call()
		_mira(f[1], f[2])
		_prox = t + 2.5
	else:
		root.get_texture().get_image().save_png(out_dir.path_join(f[0] + ".png"))
		_prox = t + 0.2
	step += 1
	return false
