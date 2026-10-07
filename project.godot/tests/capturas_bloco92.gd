extends SceneTree
## Bloco 92 (não é teste): fotos da arte do PixelLab no jogo — a fornalha e a igreja (obra e prontas), os 5 bonecos
## novos trabalhando na frente delas, a decoração de noite e a barra de funções com o Padre.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco92.gd -- <pasta de saída>
const Decor := preload("res://scripts/core/decor.gd")
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var gente: Array = []
var base := Vector2.ZERO


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b92")
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


func congela(w: Node, pos: Vector2, job: String, genero: String, trabalhando: bool) -> void:
	w.gender = genero
	w.set_job(job)
	w.global_position = pos
	w.velocity = Vector2.ZERO
	w._work_timer = 5.0 if trabalhando else 0.0
	w.set_process(false)
	w.set_physics_process(false)


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
		var cal = g("calendario")
		cal.padre_chegou = true
		# a fornalha e a igreja em obra (os desenhos da evolução)
		base = hub.global_position + Vector2(-60, 200)
		hub.build_fornalha()
		var qf := livre(base)
		g("house_placer").cancel()
		hub._confirm_fornalha(qf)
		hub.build_igreja()
		var qi := livre(base + Vector2(190, 0))
		g("house_placer").cancel()
		hub._confirm_igreja(qi)
		set_meta("qf", qf)
		set_meta("qi", qi)
		canteiro("fornalha").obra_work(canteiro("fornalha").left * 0.45)
		canteiro("igreja").obra_work(canteiro("igreja").left * 0.7)
		dn.time = dn.tempo_da_hora(10.0)
		dn.snap_lighting()
		g("hud").visible = false
		camera((qf + qi) * 0.5 + Vector2(0, -40), 1.6)
		step = 1
		t = 0.0
	elif step == 1 and t > 2.0:
		root.get_texture().get_image().save_png(out_dir.path_join("predios_em_obra.png"))
		for k in ["fornalha", "igreja"]:
			var c := canteiro(k)
			c.obra_work(c.left + 1.0)
		step = 2
		t = 0.0
	elif step == 2 and t > 1.5:
		# os 5 bonecos novos na frente, trabalhando (fundidor/a, ferreiro/a, o padre pregando)
		var qf: Vector2 = get_meta("qf")
		var qi: Vector2 = get_meta("qi")
		var ws: Array = get_nodes_in_group("ipezinhos")
		var eco = g("economy")
		while ws.size() < 5:
			eco.credits = 99999.0
			eco.recruit()
			ws = get_nodes_in_group("ipezinhos")
		var plano := [["fundidor", "menino", qf + Vector2(-30, 40)], ["fundidor", "menina", qf + Vector2(10, 52)],
			["ferreiro", "menino", qf + Vector2(60, 50)], ["ferreiro", "menina", qf + Vector2(95, 60)],
			["padre", "menino", qi + Vector2(0, 50)]]
		for i in plano.size():
			congela(ws[i], plano[i][2], plano[i][0], plano[i][1], true)
		gente = ws.slice(0, 5)
		camera((qf + qi) * 0.5 + Vector2(0, -20), 1.7)
		step = 3
		t = 0.0
	elif step == 3 and t > 2.0:
		root.get_texture().get_image().save_png(out_dir.path_join("predios_e_oficios.png"))
		camera(get_meta("qf") + Vector2(40, 40), 3.2)
		step = 4
		t = 0.0
	elif step == 4 and t > 1.5:
		root.get_texture().get_image().save_png(out_dir.path_join("oficios_perto.png"))
		# a decoração de noite
		var dm = g("decoracoes_mgr")
		var placer = g("house_placer")
		var b2: Vector2 = hub.global_position + Vector2(170, 90)
		var plano := [["lampiao", Vector2(0, 0)], ["banco", Vector2(30, 10)], ["lampiao", Vector2(80, 0)], ["mesa", Vector2(40, 50)],
			["tocha", Vector2(-20, 60)], ["tocha", Vector2(100, 60)], ["canteiro_flores", Vector2(-30, 25)], ["canteiro_flores", Vector2(110, 25)],
			["bandeira", Vector2(50, -20)], ["cerca", Vector2(40, 95)]]
		for pl in plano:
			var pg := Decor.pegada(pl[0])
			placer.begin(Callable(), load(Decor.info(pl[0]).textura), 1, "x", {"footprint": Rect2(-pg * 0.5, pg)})
			placer._collect_blockers()
			var q := Vector2.INF
			for r in range(0, 120, 6):
				for a in range(12):
					var c: Vector2 = (b2 + pl[1] + Vector2.RIGHT.rotated(a * TAU / 12.0) * r).round()
					if q == Vector2.INF and placer.check_spot(c) == "":
						q = c
			placer.cancel()
			if q != Vector2.INF:
				dm.colocar(pl[0], q)
		set_meta("b2", b2)
		dn.time = dn.day_duration + 60.0
		dn.snap_lighting()
		camera(b2 + Vector2(40, 30), 2.2)
		step = 5
		t = 0.0
	elif step == 5 and t > 2.5:
		root.get_texture().get_image().save_png(out_dir.path_join("decoracao_noite.png"))
		dn.time = dn.tempo_da_hora(11.0)
		dn.snap_lighting()
		step = 6
		t = 0.0
	elif step == 6 and t > 1.5:
		root.get_texture().get_image().save_png(out_dir.path_join("decoracao_dia.png"))
		# a barra de funções com o Padre (HUD de volta), o padre selecionado
		g("hud").visible = true
		main.select(gente[4])
		camera(get_meta("qi") + Vector2(0, 20), 2.0)
		step = 7
		t = 0.0
	elif step == 7 and t > 1.5:
		root.get_texture().get_image().save_png(out_dir.path_join("barra_padre.png"))
		print("ok")
		return true
	if step >= 3 and step < 5:
		for w in gente:
			w._work_timer = 5.0
	if step == 5:
		dn.time = dn.day_duration + 60.0
	return false
