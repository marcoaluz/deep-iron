extends SceneTree
## Bloco 107 (não é teste): fotos — a estufa de vidro, a carvoaria e o curtume prontos e em obra (os 3 estágios), o agricultor
## colhendo na horta, o lenhador carvoejando e o caçador curtindo, a janela da cozinha (cardápio). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco107.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var hub: Node
var obs := {}


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco107")
	DirAccess.make_dir_recursive_absolute(out_dir)
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
	load("res://scripts/core/defense.gd").moradores_desligados = true
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
	return main.get_tree().get_first_node_in_group(n)


func _salva(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("tela: ", nome)


func _foca(pos: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var alvo: Vector2 = main.get_node("IsoView").to_screen(pos)
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = alvo
	cam._target_pos = alvo


func _spot(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 600, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return c


func _obra_parte(f: float) -> void:
	for c in main.get_tree().get_nodes_in_group("canteiros"):
		var site = preload("res://scripts/core/obra_site.gd").de(c)
		if site:
			for k in site.necessario:
				site.entregar(k, 9999.0)
		c.left = c.total * (1.0 - f)


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		print("TIMEOUT")
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(10.0)
	var eco = g("economy")
	var arm = g("armazens")
	var hud = g("hud")
	var sun = g("sun")
	if sun:
		sun.wave_today = false
	for w in main.get_tree().get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if passo == 0 and t > 4.0:
		passo = 1
		hub = g("village_hub")
		var cal = g("calendario")
		if cal:
			cal.padre_estagio = 9  # (sem o banner "um padre chegou" na foto)
		hub.level = 2
		eco.credits = 9999.0
		arm.stock["ferro"] = 800.0
		arm.wood_stored = 900.0
		arm.raw_stored = 80.0
		arm.leather_stored = 20.0
		arm._recount()
		eco.add_item("barra_ferro", 300.0)
		eco.add_item("prego", 200.0)
		load("res://scripts/props/armazem.gd").limite_desligado = true
		var mig = g("migrantes")
		if mig:
			mig.proximo = 1.0e9
		hud.close_panels()
		while main.get_tree().get_nodes_in_group("ipezinhos").size() < 8:
			eco.novo_ipezinho()
		# as 3 estruturas na frente do Centro, em obra
		var base: Vector2 = hub.global_position
		var centro := _spot(base + Vector2(0, 250))
		obs["estufa"] = _spot(centro + Vector2(-170, 0))
		obs["carvoaria"] = _spot(centro + Vector2(10, 30))
		obs["curtume"] = _spot(centro + Vector2(170, 0))
		for k in ["estufa", "carvoaria", "curtume"]:
			hub._obra107_confirma(k, obs[k])
		t_mark = t
	elif passo >= 11 and passo <= 13 and t - t_mark > 1.0:
		# obra 1 -> 2 -> 3: uma foto com cada parte do trabalho feita
		_salva("obras_%d" % [20, 55, 85][passo - 11])
		passo += 1
		t_mark = t
		if passo <= 13:
			_obra_parte([0.2, 0.55, 0.85][passo - 11])
		if passo == 14:
			for c in main.get_tree().get_nodes_in_group("canteiros"):
				c.obra_work(c.total + 1.0)
			passo = 2
	elif passo == 1 and t - t_mark > 1.5:
		passo = 10
	elif passo == 10:
		_obra_parte(0.2)
		_foca(obs["carvoaria"] + Vector2(0, -30), 1.5)
		passo = 11
		t_mark = t
	elif passo == 11 and false:
		pass
	elif passo == 2 and t - t_mark > 1.5:
		_foca(obs["carvoaria"] + Vector2(0, -30), 1.5)
		passo = 3
		t_mark = t
	elif passo == 3 and t - t_mark > 1.0:
		_salva("prontas")
		# o pessoal trabalhando: agricultor na estufa, lenhador na carvoaria, caçador no curtume
		var w: Array = main.get_tree().get_nodes_in_group("ipezinhos")
		w[0].set_job("agricultor")
		w[1].set_job("lenhador")
		w[2].set_job("caçador")
		w[3].set_job("agricultor")
		w[3].gender = "menina"
		var carv = hub.carvoarias()[0]
		var curt = hub.curtumes()[0]
		carv.encomendar("carvao_vegetal", 6)
		curt.encomendar("couro_curtido", 4)
		Engine.time_scale = 4.0
		passo = 4
		t_mark = t
	elif passo == 4 and t - t_mark > 28.0:
		Engine.time_scale = 1.0
		var w2: Array = main.get_tree().get_nodes_in_group("ipezinhos")
		print("estados: ", w2.slice(0, 4).map(func(x): return x.job + "/" + x.get_state()))
		var alvo: Node = null
		for x in w2:
			if x.get_state() == "carvoejando":
				alvo = x
		if alvo:
			_foca(alvo.global_position, 3.0)
		else:
			_foca(obs["carvoaria"], 2.0)
		passo = 5
		t_mark = t
	elif passo == 5 and t - t_mark > 1.2:
		_salva("lenhador_carvoejando")
		var alvo2: Node = null
		for x in main.get_tree().get_nodes_in_group("ipezinhos"):
			if x.get_state() == "curtindo":
				alvo2 = x
		_foca(alvo2.global_position if alvo2 else obs["curtume"], 3.0)
		passo = 6
		t_mark = t
	elif passo == 6 and t - t_mark > 1.2:
		_salva("cacador_curtindo")
		var alvo3: Node = null
		for x in main.get_tree().get_nodes_in_group("ipezinhos"):
			if x.get_state() == "foraging":
				alvo3 = x
		_foca(alvo3.global_position if alvo3 else hub.global_position, 3.0)
		passo = 7
		t_mark = t
	elif passo == 7 and t - t_mark > 1.2:
		_salva("agricultor_colhendo")
		hud.open_panel("cozinha", g("comedouros"))
		passo = 8
		t_mark = t
	elif passo == 8 and t - t_mark > 1.0:
		_salva("cozinha_cardapio")
		hud.close_panels()
		hud.toggle_build_menu()
		hud._build_menu._show_tab(hud._build_menu.TAB_NAMES.find("Alimentação"))
		passo = 9
		t_mark = t
	elif passo == 9 and t - t_mark > 1.0:
		_salva("menu_alimentacao")
		print("FIM")
		return true
	return false
