extends SceneTree
## Bloco 78: os MARCOS de cada andar (maquete v4 aprovada, docs/NovoLayout): a vila de mineração nas galerias
## (cabanas e bocas de túnel desenhadas na faixa), a caverna de cristais no S2 (mais cristais e poças d'água
## deitadas), o fóssil gigante no S3 (com luz, bloqueando a passagem), a fonte termal no S4 (bicas com vapor
## na vista) e a cidade subterrânea no S5 (torre, casas, lampiões de cristal acesos). Confere que cada marco
## está no mapa, dentro do chão da caverna, longe das jazidas e com o caminho das jazidas ainda aberto.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var fails := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if t > 5.0:
		_marcos()
		_vida()
		_galerias()
		_caminho()
		print("FALHAS: %d" % fails)
		return true
	return false


func _todos(prop: String) -> Array:
	var env = g("environment")
	return env.get_children().filter(func(c): return c is Node2D and str(c.get_meta("iso_prop", "")) == prop and c.visible)


func _marcos() -> void:
	print("== os marcos de cada andar")
	var env = g("environment")
	var esperado := {"fossil_gigante": ["abismo", 1], "bica_vapor": ["s4", 3], "lampiao_cristal": ["s5", 4], "torre_0": ["s5", 1]}
	for prop in esperado:
		var ns := _todos(prop)
		check(ns.size() >= int(esperado[prop][1]), "%s: %d no mapa" % [prop, ns.size()])
		for n in ns:
			var lv: Dictionary = env.level_of(n.global_position)
			check(not lv.is_empty() and lv.nome == esperado[prop][0], "%s em %s no andar %s" % [prop, n.global_position, lv.get("nome", "?")])
			check(env.dentro_da_caverna(n.global_position), "%s dentro do chão da caverna" % prop)
	var cristais := 0
	for c in env.get_children():
		if c is Node2D and str(c.get_meta("iso_prop", "")).begins_with("cristal_") and not env.level_of(c.global_position).is_empty() \
				and env.level_of(c.global_position).nome == "nivel2":
			cristais += 1
	check(cristais >= 12, "S2: caverna de cristais (%d cristais)" % cristais)
	var s2 = preload("res://scripts/core/niveis.gd").todos().filter(func(n): return n.id == "S2")[0]
	check(s2.decalques.any(func(d): return str(d[0]).begins_with("poca_agua")), "S2: poças d'água deitadas no chão")
	# longe das jazidas (não tampa minério)
	var perto := 0
	for prop in ["fossil_gigante", "bica_vapor", "lampiao_cristal", "torre_0"]:
		for n in _todos(prop):
			for j in get_nodes_in_group("minerios"):
				if n.global_position.distance_to(j.global_position) < 40.0:
					perto += 1
	check(perto == 0, "nenhum marco em cima de jazida (%d)" % perto)


func _vida() -> void:
	print("== o que dá vida aos marcos")
	var f: Array = _todos("fossil_gigante")
	check(not f.is_empty() and f[0].get_node_or_null("LuzMarco") != null, "o fóssil tem a luz da lava")
	var l: Array = _todos("lampiao_cristal")
	check(not l.is_empty() and l.all(func(x): return x.get_node_or_null("LuzMarco") != null), "os lampiões de cristal acendem")
	var iso = g("iso_view")
	var vapores := 0
	for p in iso._poca_fx:
		if is_instance_valid(p) and String(p.name).begins_with("VaporBica_"):
			vapores += 1
	check(vapores == _todos("bica_vapor").size(), "cada bica solta vapor na vista (%d)" % vapores)
	var env = g("environment")
	var bloqueia := false
	if not f.is_empty():
		var c: Vector2 = f[0].global_position
		for o in env.decoration_obstacles():
			if Geometry2D.is_point_in_polygon(c + Vector2(30, -4), o):
				bloqueia = true
	check(bloqueia, "o fóssil (grande) bloqueia a passagem")


func _galerias() -> void:
	print("== a vila de mineração nas galerias (desenhada na faixa)")
	var img: Image = load("res://assets/game/iso/mapa/galerias.png").get_image()
	var cab: Image = load("res://assets/game/iso/props/cabana_mina.png").get_image()
	# a cabana tem o telhado de zinco: conta pixels da cor dele na faixa
	var alvo := cab.get_pixel(cab.get_width() / 2, 6)
	var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and absf(c.r - alvo.r) < 0.02 and absf(c.g - alvo.g) < 0.02 and absf(c.b - alvo.b) < 0.02:
				n += 1
	check(n > 20, "as cabanas de mineiro estão na faixa das galerias (%d px do telhado)" % n)


func _caminho() -> void:
	print("== o caminho até as jazidas continua aberto")
	var nav_map: RID = g("environment").navigation_region.get_navigation_map()
	var ruins := 0
	for nome in ["abismo", "s4", "s5"]:
		var env = g("environment")
		var a: Dictionary = env.andares.andares[nome]
		var gaiola := Vector2(a.gaiola[0], a.gaiola[1])
		for j in get_nodes_in_group("minerios"):
			var lv: Dictionary = env.level_of(j.global_position)
			if lv.is_empty() or lv.nome != nome:
				continue
			var path := NavigationServer2D.map_get_path(nav_map, gaiola, j.global_position, true)
			if path.is_empty() or path[path.size() - 1].distance_to(j.global_position) > 60.0:
				ruins += 1
				print("    sem caminho: ", j.name, " ", j.global_position)
	check(ruins == 0, "da gaiola até cada jazida do S3, S4 e S5 (%d sem caminho)" % ruins)
