extends SceneTree
## Bloco 76: o resto da maquete e o andar de todos. Confere: os LOTES LIVRES da vila (4, cada um um lugar
## de casa válido fora da praça e das ruas, o chão limpo, o posicionador encaixando no meio do lote, lote
## com prédio deixa de ser livre), a BOCA DA ESPIRAL posta na superfície, a arte das faixas (o rio de lava
## e os fios de lava no S3, a cortina da cachoeira no S4, as raízes debaixo da floresta) e o andar de todos
## (a gente inteira com caminhada de 8 quadros e passada medida; criaturas, robô e bichos pela distância).
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
	if t > 4.0:
		_lotes()
		_espiral()
		_faixas()
		_andar()
		print("FALHAS: %d" % fails)
		return true
	return false


func _lotes() -> void:
	print("== os lotes livres da vila")
	var env = g("environment")
	var hub = g("village_hub")
	var lotes: Array = env.lotes()
	check(lotes.size() == 4, "4 lotes (%d)" % lotes.size())
	check(env.lotes_livres().size() == 4, "todos livres no começo")
	var placer = g("house_placer")
	placer.begin(func(_p): return false, hub.CASA_TEXTURE, 3, "teste", hub.house_placer_opts())
	for r in lotes:
		var c: Vector2 = r.position - env.LOTE_RECT.position
		check(placer.check_spot(c) == "", "lote em %s: dá pra construir casa (%s)" % [c, placer.check_spot(c)])
		check(absf(c.y - (-40.0)) > 70.0 and absf(c.x - 40.0) > 60.0 and c.distance_to(Vector2(40, -200)) > 150.0,
			"lote em %s fora da praça e das ruas" % c)
		var sujo := 0
		for ch in env.get_children():
			if ch is Node2D and ch.has_meta("iso_prop") and ch.visible and r.has_point(ch.global_position):
				sujo += 1
		check(sujo == 0, "o chão do lote em %s está limpo (%d enfeites)" % [c, sujo])
	var c0: Vector2 = lotes[0].position - env.LOTE_RECT.position
	placer.move_to(c0 + Vector2(22, 14))
	check(placer._pos == c0 and placer.no_lote, "perto do lote o prédio encaixa no meio dele")
	placer.move_to(c0 + Vector2(200, 0))
	check(not placer.no_lote, "longe do lote não encaixa")
	placer.cancel()
	var casa := Node2D.new()
	casa.add_to_group("casas")
	main.get_node("World").add_child(casa)
	casa.global_position = c0
	check(env.lotes_livres().size() == 3 and env.lote_perto(c0) == Vector2.INF, "com uma casa dentro o lote deixa de ser livre")
	casa.remove_from_group("casas")
	casa.queue_free()


func _espiral() -> void:
	print("== a boca da escada em espiral")
	var env = g("environment")
	var achou: Node2D = null
	for ch in env.get_children():
		if ch is Node2D and str(ch.get_meta("iso_prop", "")) == "boca_espiral":
			achou = ch
	check(achou != null, "a casinha da espiral está no mapa")
	if achou:
		var iso = g("iso_view")
		var tela: Vector2 = iso.to_screen(achou.global_position)
		var esp: Dictionary = env.andares.get("espiral", {})
		check(not esp.is_empty() and absf(tela.x - (esp.tela[0] + 300.0)) < 40.0, "em cima da espiral da coluna (x da tela %d)" % tela.x)
		check(env.surface_area(achou.global_position) == "mina", "na área da mina, perto do elevador")


func _conta(img: Image, cor: Color, tol: float) -> int:
	var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and absf(c.r - cor.r) < tol and absf(c.g - cor.g) < tol and absf(c.b - cor.b) < tol:
				n += 1
	return n


func _faixas() -> void:
	print("== a arte das faixas")
	var lava := _conta(load("res://assets/game/iso/mapa/andar_abismo.png").get_image(), Color8(255, 196, 70), 0.06)
	check(lava > 400, "S3: o rio e os fios de lava (%d px)" % lava)
	var agua := _conta(load("res://assets/game/iso/mapa/andar_s4.png").get_image(), Color8(200, 230, 255), 0.08)
	check(agua > 150, "S4: a cortina da cachoeira (%d px)" % agua)
	var raiz := _conta(load("res://assets/game/iso/mapa/andar_nivel2.png").get_image(), Color8(76, 55, 35), 0.03)
	var raiz_s5 := _conta(load("res://assets/game/iso/mapa/andar_s5.png").get_image(), Color8(76, 55, 35), 0.03)
	check(raiz > 40 and raiz > raiz_s5 * 3, "S2: raízes da floresta descendo a parede (%d px; S5 %d)" % [raiz, raiz_s5])


func _andar() -> void:
	print("== o andar de todos")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/game/iso/bonecos/bonecos.json"))
	var gente := 0
	var oito := 0
	var com_ciclo := 0
	for pasta in d.pastas:
		var cam: Dictionary = d.pastas[pasta].get("anims", {}).get("caminhada", {})
		if cam.is_empty() or pasta.begins_with("criatura") or pasta == "robo":
			continue
		gente += 1
		if cam.values().all(func(x): return int(x.n) == 8):
			oito += 1
		if cam.values().all(func(x): return x.has("ciclo")):
			com_ciclo += 1
	check(gente >= 42 and oito == gente, "a gente toda com caminhada de 8 quadros (%d de %d)" % [oito, gente])
	check(com_ciclo == gente, "e a passada medida em cada tira (%d)" % com_ciclo)
	var bichos := 0
	for pasta in d.pastas:
		if pasta.begins_with("criatura") or pasta == "robo":
			var cam: Dictionary = d.pastas[pasta].get("anims", {}).get("caminhada", {})
			if not cam.is_empty() and cam.values().all(func(x): return x.has("ciclo")):
				bichos += 1
	check(bichos >= 6, "criaturas e robô com passada medida (%d)" % bichos)
	var animal := load("res://scripts/creatures/animal.gd")
	check(animal.get_script_constant_map().has("CICLO"), "coelho e javali: passada por bicho (animal.gd CICLO)")
