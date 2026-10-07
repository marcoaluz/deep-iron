extends SceneTree
## Bloco 93 (não é teste): fotos do cemitério no jogo — a evolução da obra (estacas, postes, cerca, pronto), vazio,
## o padre levando um corpo e o cemitério com os túmulos (nome e dia).
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco93.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var cem: Node2D
var padre: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b93")
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


func camera(centro: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var iso = main.get_node("IsoView")
	cam.bounds = Rect2()
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = iso.to_screen(centro)
	cam._target_pos = cam.position


func foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome))


func _process(delta: float) -> bool:
	t += delta
	var dn = g("day_night")
	var hub = g("village_hub")
	if dn and step >= 1:
		dn.time = dn.tempo_da_hora(10.0)
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
		hub.level = 2
		g("calendario").padre_chegou = true
		var q := Rect2()
		for r in range(240, 700, 24):  # (longe do Centro: o prédio alto taparia a vista)
			for a in range(16):
				var c: Vector2 = hub.global_position + Vector2.RIGHT.rotated(a * TAU / 16.0) * r
				var tq := Rect2(c - Vector2(84, 60), Vector2(168, 120))
				if not q.has_area() and hub.motivo_cemiterio(tq) == "":
					q = tq
		hub._confirm_cemiterio(q)
		cem = hub.cemiterios()[0]
		dn.time = dn.tempo_da_hora(10.0)
		dn.snap_lighting()
		g("hud").visible = false
		camera(cem.rect.get_center() + Vector2(0, -10), 2.0)
		step = 1
		t = 0.0
	elif step == 1 and t > 1.5:
		foto("obra_1_estacas.png")
		cem.obra_work(cem.total * 0.45)
		step = 2
		t = 0.0
	elif step == 2 and t > 1.0:
		foto("obra_2_postes.png")
		cem.obra_work(cem.total * 0.3)
		step = 3
		t = 0.0
	elif step == 3 and t > 1.0:
		foto("obra_3_cerca.png")
		cem.obra_work(cem.total)
		step = 4
		t = 0.0
	elif step == 4 and t > 1.0:
		foto("pronto_vazio.png")
		# o padre levando um corpo (congelado no meio do caminho)
		var ws: Array = get_nodes_in_group("ipezinhos")
		padre = ws[0]
		padre.gender = "menino"
		padre.set_job("padre")
		padre.carregando_corpo = {"nome": "Beto", "dia": 4, "estacao": "Primavera", "causa": ""}
		padre.global_position = Vector2(cem.rect.end.x - 20.0, cem.rect.end.y + 40.0)  # (na frente, longe da Oficina)
		padre.velocity = Vector2(-30, -10)
		padre.set_process(false)
		padre.set_physics_process(false)
		var corpo: Node2D = g("calendario").CORPO.new()
		corpo.monta({"nome": "Lia", "dia": 5})
		corpo.position = cem.portao_pos() + Vector2(70, 60)
		hub.get_parent().add_child(corpo)
		camera(Vector2(cem.rect.end.x - 20.0, cem.rect.end.y + 30.0), 3.0)
		step = 5
		t = 0.0
	elif step == 5 and t > 1.5:
		foto("padre_levando.png")
		# o cemitério depois de algumas mortes: cruzes e lápides com o nome e o dia
		var nomes := ["Beto", "Lia", "Quim", "Mel", "Rosa", "Tião", "Dora", "Zeca"]
		for i in nomes.size():
			cem.enterra({"nome": nomes[i], "dia": 3 + i * 2, "estacao": ["Primavera", "Verão"][i / 5], "causa": ""})
		camera(cem.rect.get_center() + Vector2(0, -10), 2.4)
		step = 6
		t = 0.0
	elif step == 6 and t > 1.5:
		foto("com_tumulos.png")
		g("hud").visible = true
		g("hud").toggle_build_menu()
		var bm = g("build_menu")
		if bm and bm.has_method("show_tab"):
			bm.show_tab("Culto")
		step = 7
		t = 0.0
	elif step == 7 and t > 1.0:
		foto("menu_culto.png")
		print("ok")
		return true
	return false
