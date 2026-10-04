extends SceneTree
## Bloco 73 (não é teste): os bonecos andando de perto, quadro a quadro, pra ver se o pé fica no chão.
## Com janela e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_andar.gd -- <pasta de saída> [fps]
## Grava <pasta>/q_000.png... (um recorte em volta dos bonecos, a cada quadro, por 4 s; o GIF é montado
## à parte). fps = o limite da tela (60 por padrão; 144 testa a suavização).
const PATH := "user://savegame.json"
const ZOOM := 2.0
const RECORTE := Vector2i(960, 560)
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var quadros: Array[Image] = []
var ws: Array = []
var alvos := {}
var centro := Vector2.ZERO


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_andar")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(args[1]) if args.size() > 1 else 60
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _prepara() -> void:
	var hud = g("hud")
	if hud:
		hud.visible = false
	var hub: Vector2 = g("village_hub").global_position
	centro = hub + Vector2(110, 30)
	ws = main.get_tree().get_nodes_in_group("ipezinhos")
	var jobs := ["minerador", "lenhador", "minerador"]
	var genders := ["menino", "menino", "menina"]
	# cada um vai e volta num eixo do chão (SE/NO, NE/SO) e um na diagonal
	var rotas := [[Vector2(-80, -10), Vector2(80, -10)], [Vector2(10, -60), Vector2(10, 70)], [Vector2(-60, 50), Vector2(60, -50)]]
	for i in ws.size():
		var w = ws[i]
		w.gender = genders[i % 3]
		w.set_job(jobs[i % 3])
		w.manual_override_time = 999.0
		w.global_position = centro + rotas[i % 3][0]
		alvos[w] = [centro + rotas[i % 3][0], centro + rotas[i % 3][1], 1]
		w.move_to(alvos[w][1])
	var cam = main.get_node("Camera2D")
	var v = main.get_node("IsoView")
	cam.bounds = Rect2()
	cam.zoom = Vector2(ZOOM, ZOOM)
	cam._target_zoom = ZOOM
	cam.position = v.to_screen(centro)
	cam._target_pos = cam.position


func _process(delta: float) -> bool:
	t += delta
	if step == 0:
		if t > 4.0:
			_prepara()
			step = 1
			t = 0.0
		return false
	for w in ws:  # chegou: volta
		var a: Array = alvos[w]
		if w.global_position.distance_to(a[a[2]]) < 12.0:
			a[2] = 1 - a[2]
			w.move_to(a[a[2]])
	if step == 1:
		if t > 1.5:
			step = 2
			t = 0.0
		return false
	var img := root.get_texture().get_image()
	var c := img.get_size() / 2
	quadros.append(img.get_region(Rect2i(c - RECORTE / 2, RECORTE)))
	if t > 4.0:
		for k in quadros.size():
			quadros[k].save_png(out_dir.path_join("q_%03d.png" % k))
		print("ok ", quadros.size(), " quadros em ", out_dir)
		return true
	return false
