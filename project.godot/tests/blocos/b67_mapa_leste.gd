extends SceneTree
## Bloco 67: mapa ampliado pro leste. Área nova ~2x a antiga (total ~3x), trancada (sem caminho,
## ninguém escolhe estação de lá), conteúdo com nome fixo (jazidas, árvores, toca), desbravar pelo
## Centro da Vila (estágio, custo, obra do engenheiro), depois caminho e construção lá, câmera
## cobre o leste, save/load (aberto + estado das jazidas novas) e save antigo = trancado.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var alvo := Vector2(1800, 150)
var ore_salvo := -1.0


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
	return current_scene.get_tree().get_first_node_in_group(grupo)


func _caminho_chega(de: Vector2, ate: Vector2) -> bool:
	var map: RID = main.get_world_2d().navigation_map
	var p := NavigationServer2D.map_get_path(map, de, ate, true)
	return not p.is_empty() and p[p.size() - 1].distance_to(ate) < 30.0


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 150.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_trancado()
				_desbrava()
				step = 1
		1:
			if g("environment").leste_aberto:
				Engine.time_scale = 1.0
				step = 2
				t_mark = t
		2:
			if t - t_mark > 1.0:  # (a malha nova sincroniza no quadro seguinte)
				_aberto()
				root.get_node("SaveManager").save_game("teste")
				step = 3
				t_mark = t
		3:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 4
				t_mark = t
		4:
			if t - t_mark > 3.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _trancado() -> void:
	print("== área nova")
	var env = g("environment")
	check(env.has_leste(), "o mapa tem leste")
	# o mapa de antes do Bloco 67 ia até x=760 (Bloco 74: o leste trancado agora começa depois da mina)
	var velho := Rect2(env.iso_ground_rect().position, Vector2(760.0 - env.iso_ground_rect().position.x, env.iso_ground_rect().size.y))
	var razao: float = env.iso_ground_rect().get_area() / velho.get_area()
	var lr: Rect2 = env.leste_rect()
	check(razao >= 2.5, "área total %.1fx a de antes" % razao)
	check(not env.leste_aberto and env.trancado(alvo), "começa trancado")
	var hub = g("village_hub")
	check(not _caminho_chega(hub.global_position + Vector2(0, 60), alvo), "sem caminho até o leste")
	check(main.get_node("World").has_node("JazidaLeste1") and main.get_node("World").has_node("TocaLeste"), "conteúdo novo com nome fixo (jazidas, toca)")
	var arvs: int = main.get_tree().get_nodes_in_group("arvores").filter(func(a): return a.name.begins_with("ArvoreLeste")).size()
	check(arvs >= 8, "árvores no leste (%d)" % arvs)
	var cam = main.get_node("Camera2D")
	check(cam.bounds.encloses(Rect2(lr.position + Vector2(10, 10), lr.size - Vector2(20, 20))), "câmera cobre o leste")
	# ninguém escolhe estação do leste trancado
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w.set_job("minerador")
	for m in main.get_tree().get_nodes_in_group("minerios"):
		if not m.name.begins_with("JazidaLeste"):
			m.ore_remaining = 0.0
			m._cooldown = 999.0
	var st: Node = w._find_best_station("minerios")
	check(st == null or not st.name.begins_with("JazidaLeste"), "minerador não escolhe jazida do leste trancado (%s)" % (st.name if st else "nenhuma"))
	for m in main.get_tree().get_nodes_in_group("minerios"):
		if not m.name.begins_with("JazidaLeste"):
			m._cooldown = 0.0
			m.ore_remaining = m.ore_total
	var placer = g("house_placer")
	placer._collect_blockers()
	check(placer.check_spot(alvo) != "", "não constrói no leste trancado (%s)" % placer.check_spot(alvo))
	main.get_node("World/JazidaLeste2").ore_remaining = 77.0


func _desbrava() -> void:
	print("== desbravar")
	var hub = g("village_hub")
	hub.level = 1
	check("estágio" in hub.leste_block_reason(), "precisa da vila crescer (%s)" % hub.leste_block_reason())
	hub.level = 2
	var eco = g("economy")
	eco.credits = 5000
	var arm = g("armazens")
	arm.stock["ferro"] = 500.0
	arm.wood_stored = 500.0
	arm._recount()
	check(hub.leste_block_reason() == "", "com estágio e recursos: liberado")
	check(hub.desbravar_leste(), "encomendado")
	var cant: Node = null
	for c in main.get_tree().get_nodes_in_group("canteiros"):
		if c.kind == "desbravar":
			cant = c
	check(cant != null, "obra do engenheiro na fronteira")
	check(hub.leste_block_reason().begins_with("em obra"), "uma vez: %s" % hub.leste_block_reason())
	if cant:
		cant.total = 3.0
		cant.left = 3.0
	main.get_tree().get_nodes_in_group("ipezinhos")[1].set_job("engenheiro")
	Engine.time_scale = 3.0


func _aberto() -> void:
	print("== aberto")
	var env = g("environment")
	var hub = g("village_hub")
	check(env.leste_aberto and not env.trancado(alvo), "o leste abriu")
	check(_caminho_chega(hub.global_position + Vector2(0, 60), alvo), "agora tem caminho até o leste")
	check(env.walkable_rect().has_point(alvo), "a área de construir inclui o leste")
	var placer = g("house_placer")
	placer._collect_blockers()
	var ok := false
	for dx in range(0, 400, 40):
		if placer.check_spot(alvo + Vector2(dx, 0)) == "":
			ok = true
			break
	check(ok, "dá pra construir no leste")
	check(hub.leste_block_reason() == "já desbravado", "não desbrava de novo")
	var j = main.get_node("World/JazidaLeste2")
	j.regen_rate = 0.0
	j.ore_remaining = 77.0
	ore_salvo = j.ore_remaining


func _carregado() -> void:
	print("== depois de carregar")
	var env = g("environment")
	check(env.leste_aberto, "o leste continua aberto")
	var j = main.get_node_or_null("World/JazidaLeste2")
	check(j != null and absf(j.ore_remaining - ore_salvo) < 2.0, "estado da jazida nova voltou pelo nome (%.0f, salvo %.0f)" % [j.ore_remaining if j else -1.0, ore_salvo])
	var hub = g("village_hub")
	var d: Dictionary = hub.get_save_data()
	d.erase("leste_aberto")
	env.set_leste_aberto(false)
	hub.load_save_data(d)
	check(not env.leste_aberto, "save antigo (sem leste): trancado")
