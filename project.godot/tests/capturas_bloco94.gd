extends SceneTree
## Bloco 94 (não é teste): fotos da arte do PixelLab no jogo — a carpintaria nas 3 etapas de obra e pronta, o
## carpinteiro e a carpinteira serrando (de roupa e de casaco), a janela da carpintaria, a da casa com as camas
## de tábua e a barra de funções com o Carpinteiro.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco94.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var gente: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b94")
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


func g(n: String) -> Node:
	return get_first_node_in_group(n)


func livre(c: Vector2, raio := 400) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, raio, 10):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func canteiro(kind: String) -> Node:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			return c
	return null


func camera(centro: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var iso = main.get_node("IsoView")
	cam.bounds = Rect2()
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = iso.to_screen(centro)
	cam._target_pos = cam.position


func congela(w: Node, pos: Vector2, genero: String, casaco: bool) -> void:
	w.gender = genero
	w.set_job("carpinteiro")
	w.global_position = pos
	w.velocity = Vector2.ZERO
	w._work_timer = 5.0
	if casaco:
		w.wearing["casaco"] = 100.0
	else:
		w.wearing.erase("casaco")
	w.set_process(false)
	w.set_physics_process(false)


func foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome))


func _process(delta: float) -> bool:
	t += delta
	var dn = g("day_night")
	var hub = g("village_hub")
	if step == 0 and t > 4.0:
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		var eco = g("economy")
		eco.credits = 99999.0
		var arm = g("armazens")
		arm.stock["ferro"] = 999.0
		arm.wood_stored = 999.0
		arm._recount()
		hub.level = 3
		var q := livre(hub.global_position + Vector2(-60, 200))
		hub.build_carpintaria()
		g("house_placer").cancel()
		hub._confirm_carpintaria(q)
		set_meta("q", q)
		dn.time = dn.tempo_da_hora(10.0)
		dn.snap_lighting()
		g("hud").visible = false
		camera(q + Vector2(0, -30), 2.4)
		set_meta("etapa", 0)
		step = 1
		t = 0.0
	elif step == 1 and t > 1.5:
		# a obra nas 3 etapas (o engenheiro avança: 0-33 / 33-66 / 66-100%)
		var e: int = get_meta("etapa")
		var c := canteiro("carpintaria")
		c.obra_work(c.total * 0.2 if e == 0 else c.total * 0.33)
		step = 2
		t = 0.0
	elif step == 2 and t > 1.5:
		var e: int = get_meta("etapa")
		foto("carpintaria_obra_%d.png" % (e + 1))
		if e < 2:
			set_meta("etapa", e + 1)
			step = 1
		else:
			var c := canteiro("carpintaria")
			c.obra_work(c.left + 1.0)
			step = 3
		t = 0.0
	elif step == 3 and t > 1.5:
		foto("carpintaria_pronta.png")
		var q: Vector2 = get_meta("q")
		var ws: Array = get_nodes_in_group("ipezinhos")
		var eco = g("economy")
		while ws.size() < 4:
			eco.credits = 99999.0
			eco.recruit()
			ws = get_nodes_in_group("ipezinhos")
		var plano := [["menino", q + Vector2(-40, 62), false], ["menina", q + Vector2(10, 74), false],
			["menino", q + Vector2(60, 66), true], ["menina", q + Vector2(100, 56), true]]
		for i in plano.size():
			congela(ws[i], plano[i][1], plano[i][0], plano[i][2])
		gente = ws.slice(0, 4)
		camera(q + Vector2(30, 10), 2.6)
		step = 4
		t = 0.0
	elif step == 4 and t > 2.0:
		foto("carpinteiros_serrando.png")
		camera(get_meta("q") + Vector2(20, 50), 4.0)
		step = 5
		t = 0.0
	elif step == 5 and t > 1.5:
		foto("carpinteiros_perto.png")
		# a janela da carpintaria com ordens e a da casa com as camas de tábua
		g("hud").visible = true
		var cp = g("carpintarias")
		var eco = g("economy")
		eco.add_item("prego", 4.0)
		cp.encomendar("tabua", 5)
		cp.encomendar("cama_boa", 2)
		g("hud").open_panel("carpintaria", cp)
		step = 6
		t = 0.0
	elif step == 6 and t > 1.5:
		foto("janela_carpintaria.png")
		var hud = g("hud")
		hud._panels["carpintaria"].visible = false
		var casa: Node = null
		for c in get_nodes_in_group("casas"):
			if c.built:
				casa = c
				break
		casa.camas_boas = 2
		casa.camas_pedidas = 1
		g("economy").add_item("cama_boa", 1.0)
		hud.open_panel("casa", casa)
		step = 7
		t = 0.0
	elif step == 7 and t > 1.5:
		foto("janela_casa_camas.png")
		g("hud")._panels["casa"].visible = false
		main.select(gente[0])
		step = 8
		t = 0.0
	elif step == 8 and t > 1.5:
		foto("barra_carpinteiro.png")
		print("ok")
		return true
	if step >= 4:
		for w in gente:
			w._work_timer = 5.0
	return false
