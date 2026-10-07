extends SceneTree
## Bloco 77 (não é teste): as áreas de trabalho no jogo — a área de madeira na floresta, a de alimentos e a
## mina com o carrinho, com os rótulos no mapa e a janela TRABALHADORES aberta; e a área sendo marcada.
## Com janela e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco77.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var wa: Node
var madeira = null
var comida = null
var mina = null


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_b77")
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


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _foca(p: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()
	cam.focus_on(p)
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom


func _foto(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_jpg(out_dir.path_join(nome + ".jpg"), 0.9)
	print("foto ", nome)


func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t > 4.0:
				_monta()
				step = 1
				t = 0.0
		1:
			if t > 14.0:  # os trabalhadores chegaram nas áreas
				Engine.time_scale = 1.0
				var hud = g("hud")
				hud.close_panels()
				_foca(madeira.centro() + Vector2(120, 0), 1.0)
				step = 2
				t = 0.0
		2:
			if t > 1.0:
				_foto("01_areas_floresta")
				var hud = g("hud")
				hud.open_panel("trabalho")
				hud._panels["trabalho"].focus_area(madeira)
				step = 3
				t = 0.0
		3:
			if t > 1.0:
				_foto("02_janela_trabalhadores")
				g("hud").close_panels()
				_foca(mina.centro(), 1.0)
				step = 4
				t = 0.0
		4:
			if t > 1.0:
				_foto("03_mina_operando")
				var placer = g("area_placer")
				placer.begin("madeira")
				var c: Vector2 = madeira.centro() + Vector2(-60, 320)
				placer.arrastando = true
				placer.drag(c, c + Vector2(260, 180))
				_foca(c + Vector2(130, 60), 1.0)
				step = 5
				t = 0.0
		5:
			if t > 1.0:
				_foto("04_marcando_area")
				print("ok")
				return true
	return false


func _monta() -> void:
	wa = g("work_areas")
	var eco = g("economy")
	eco.max_workers = 30
	while get_nodes_in_group("ipezinhos").size() < 12:
		if eco.recruit_free() == null:
			break
	for w in get_nodes_in_group("ipezinhos"):
		w.set_job("ocioso")
		w.overtime = true
	var trees: Array = get_nodes_in_group("arvores").filter(func(x): return x.is_usable())
	var c: Vector2 = trees[0].global_position
	madeira = wa.criar("madeira", Rect2(c - Vector2(210, 210), Vector2(420, 420)))
	wa.definir(madeira, 5)
	var fs: Array = get_nodes_in_group("coleta_comida")
	var cf: Vector2 = fs[0].global_position
	comida = wa.criar("comida", Rect2(cf - Vector2(110, 110), Vector2(220, 220)))
	wa.definir(comida, 3)
	var cart: Node = null
	for st in get_nodes_in_group("pontos_carga"):
		if st.get("rota_fixa"):
			cart = st
	var r := Rect2(cart.global_position, Vector2.ZERO)
	for j in get_nodes_in_group("minerios"):
		if j.is_usable() and j.global_position.distance_to(cart.global_position) < 500.0:
			r = r.expand(j.global_position)
	mina = wa.criar("mina", r.grow(30.0))
	wa.definir(mina, 2)
	wa.ativar(mina, true)
	Engine.time_scale = 4.0
