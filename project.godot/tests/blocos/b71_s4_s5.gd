extends SceneTree
## Bloco 71: S4 (cachoeira e lava) e S5 (lago azul) jogáveis por dados. Área de cada nível (andável,
## nível e perigo de cada ponto), plataformas montadas dos .tres (conserto em cadeia: abismo -> S4 ->
## S5, pesquisa Bombas d'água), caminho até o fundo, jazidas trancadas/abertas, água que molha (a lava
## queima menos), o lago não anda, ânimo do nível, gema azul, corte da mina, vista iso e save/load.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const Niveis := preload("res://scripts/core/niveis.gd")
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var _antes := {}


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


func world() -> Node:
	return g("village_hub").get_parent()


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 120.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 4.0:
				_areas()
				_ligacoes()
				step = 1
				t_mark = t
		1:
			if t - t_mark > 1.0:  # (as ligações abertas entram na navegação no quadro seguinte)
				_caminho()
				_agua_e_lago()
				_animo_e_gema()
				_vista()
				_prepara_save()
				root.get_node("SaveManager").save_game("teste")
				step = 2
				t_mark = t
		2:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 4.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _areas() -> void:
	print("== áreas dos níveis novos")
	var env = g("environment")
	var s4 := Niveis.por_id("S4")
	var s5 := Niveis.por_id("S5")
	check(not s4.em_breve and not s5.em_breve and s4.rect.has_area() and s5.rect.has_area(), "S4 e S5 jogáveis, com área própria")
	check(env.level_at(s4.rect.get_center()) == 4 and env.level_at(s5.rect.get_center()) == 5, "nível de cada ponto: 4 e 5")
	check(env.area_at(s4.rect.get_center()) == "s4" and Niveis.do_ponto(env, s5.rect.get_center()).id == "S5", "área e nível pelos dados")
	check(env.is_deep(s4.rect.get_center()) and is_equal_approx(env.danger_mult_at(s5.rect.get_center()), env.abyss_injury_mult), "fundo: acidente como no abismo")
	check(env.world_rect().encloses(s5.rect), "a câmera alcança o S5")
	check(env.level_at(env.deep_rect.get_center()) == 2 and env.level_at(env.abyss_rect.get_center()) == 3, "nível 2 e abismo como antes")


func _ligacoes() -> void:
	print("== plataformas (dados) e conserto em cadeia")
	var tree := main.get_tree()
	var e4 = g("elevador_s4")
	var e5 = g("elevador_s5")
	check(e4 != null and e5 != null and e4.is_in_group("elevadores") and e5.is_in_group("elevadores"), "plataformas do S4 e do S5 montadas")
	check(e4.global_position.is_equal_approx(Niveis.por_id("S4").ligacao_topo) and e4.bottom_position.is_equal_approx(Niveis.por_id("S4").ligacao_fundo), "topo no abismo, gaiola no S4")
	check(not e4.is_in_group("elevador_abismo") and g("elevador_abismo") != e4, "a do abismo continua única")
	check("plataforma" in Niveis.motivo(tree, Niveis.por_id("S4")), "S4 fechado: %s" % Niveis.motivo(tree, Niveis.por_id("S4")))
	check("fechado" in e4.repair_block_reason(), "sem o abismo aberto não conserta (%s)" % e4.repair_block_reason())
	g("elevador").unlock(false)
	g("elevador_abismo").unlocked = true
	g("elevador_abismo")._apply(false)  # (liga a ligação de navegação, como o conserto faz)
	check("Bombas" in e4.repair_block_reason(), "pede a pesquisa (%s)" % e4.repair_block_reason())
	g("research")._finish("bombas")
	g("village_hub").level = 5
	g("finds").rare_parts = 100
	g("economy").credits = 20000.0
	var arm = g("armazens")
	arm.add_ore(500.0, "solarita")
	arm.add_ore(500.0, "cristal_rubro")
	check(e4.repair_block_reason() == "", "com tudo: pode consertar (%s)" % e4.repair_block_reason())
	check("fechado" in e5.repair_block_reason(), "o S5 espera o S4 (%s)" % e5.repair_block_reason())
	var j4 = world().get_node_or_null("JazidaS4_1")
	check(j4 != null and j4._needs_descent, "jazida do S4 trancada pela descida")
	var sol0: float = arm.stock.solarita
	# Bloco 96: o conserto é obra de engenheiro: a solarita fica reservada (o livre cai) e o tempo anda pelo obra_work
	var eco96 = g("economy")
	check(e4.start_repair() and e4.repairing and eco96.livre("solarita") < sol0, "conserto começou (gasta solarita)")
	e4.repair_left = 0.01
	e4.obra_work(0.05)
	check(e4.unlocked and Niveis.motivo(tree, Niveis.por_id("S4")) == "", "S4 aberto")
	check(g("diary").has_page("nivel_S4"), "página da cachoeira no diário")
	check(not j4._needs_descent, "jazida do S4: a descida abriu (o cristal rubro ainda pede o traje de chumbo)")
	check(e5.repair_block_reason() == "" and e5.start_repair(), "S5: conserto com cristal rubro")
	e5.repair_left = 0.01
	e5.obra_work(0.05)
	check(e5.unlocked and Niveis.liberado(tree, Niveis.por_id("S5")) and world().get_node("JazidaS5_1").is_unlocked(), "S5 aberto, gema liberada")


func _chega(de: Vector2, ate: Vector2) -> bool:
	var map: RID = main.get_world_2d().navigation_map
	var p := NavigationServer2D.map_get_path(map, de, ate, true)
	return not p.is_empty() and p[p.size() - 1].distance_to(ate) < 30.0


func _caminho() -> void:
	print("== caminho até o fundo")
	var vila: Vector2 = g("village_hub").global_position + Vector2(0, 80)
	check(_chega(vila, world().get_node("JazidaS4_1").global_position + Vector2(0, 30)), "da vila até o S4 (4 gaiolas)")
	check(_chega(vila, Niveis.por_id("S5").ligacao_fundo + Vector2(40, 30)), "da vila até o S5")


func _agua_e_lago() -> void:
	print("== água (molha) e lago (não anda)")
	var fundo = g("fundo")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	var agua: Node2D = world().get_node("PocaS4_1")
	check(agua.kind == "agua" and agua.traje() == "", "poça d'água: sem traje")
	w.global_position = agua.global_position
	var v0: float = w.speed * w._speed_bonus()
	w._equip_tick(0.1)
	check(w._na_poca == agua and w._molhado > 0.0 and w._get_effective_speed() < v0, "na água: atrasa e molha (%.0f s)" % w._molhado)
	var lava: Node2D = world().get_node("PocaS4_4")
	w.global_position = lava.global_position
	for i in 26:
		w._equip_tick(0.1)
	check(not w.injured and w._poca_expo < 1.0, "molhado, 2,5 s na lava não queimam (exposição %.2f)" % w._poca_expo)
	var lago: Array = Niveis.por_id("S5").obstaculos[0]
	var r := Rect2(lago[0], lago[1], lago[2], lago[3])
	var q := NavigationServer2D.map_get_closest_point(main.get_world_2d().navigation_map, r.get_center())
	check(not r.grow(-12.0).has_point(q), "o meio do lago não é andável (mais perto: %s)" % str(q))


func _animo_e_gema() -> void:
	print("== ânimo do nível e gema azul")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[1]
	w.global_position = Niveis.por_id("S5").rect.get_center() + Vector2(450, 0)  # (Bloco 75: na faixa, ao lado do lago)
	var f: Array = w.happiness_factors()
	check(f.any(func(x): return x[0] == "a calma do lago azul" and x[1] > 0.0), "no S5: a calma do lago azul")
	w.global_position = Niveis.por_id("S4").rect.get_center()
	f = w.happiness_factors()
	check(f.any(func(x): return x[1] < 0.0 and "cachoeira" in String(x[0])), "no S4: o barulho da cachoeira pesa")
	var eco = g("economy")
	check(eco.price_of("gema_azul") > eco.price_of("cristal_rubro"), "gema azul vale mais que tudo (%.0f)" % eco.price_of("gema_azul"))
	check(world().get_node("JazidaS5_1").ore_type == "gema_azul", "jazidas de gema no S5")


func _vista() -> void:
	print("== vista iso e corte")
	var iso = main.get_node("IsoView")
	var nomes: Array = iso._levels.map(func(lv): return lv.nome)
	check(nomes.has("s4") and nomes.has("s5"), "lajes do S4 e do S5 (%s)" % str(nomes))
	var tem_agua := false
	for lv in iso._levels:
		if lv.nome == "s4":
			tem_agua = lv.sprite.get_node_or_null("Poca_PocaS4_1") != null
	check(tem_agua, "poça d'água desenhada na laje do S4")
	check(iso._atmos.size() == 5, "atmosfera nos 5 níveis")
	var cachoeira := false
	for d in main.get_tree().get_nodes_in_group("nivel_deco"):
		if d.get_meta("iso_fx", "") == "cachoeira":
			cachoeira = iso.billboard_of(d) != null
	check(cachoeira, "a cachoeira (efeito animado dos dados) na vista")
	var c = g("hud")._corte
	c._env = g("environment")
	check(c.ANDARES.size() == 6 and c._onde(Niveis.por_id("S5").rect.get_center())[0] == 5, "corte da mina com S4 e S5")


func _prepara_save() -> void:
	var j = world().get_node("JazidaS5_2")
	j.ore_remaining = 21.0


func _carregado() -> void:
	print("== depois de carregar")
	var e4 = g("elevador_s4")
	var e5 = g("elevador_s5")
	check(e4 != null and e4.unlocked and e5 != null and e5.unlocked, "plataformas abertas voltaram")
	check(main.get_tree().get_nodes_in_group("elevador_s4").size() == 1, "sem plataforma duplicada")
	var j = world().get_node_or_null("JazidaS5_2")
	check(j != null and absf(j.ore_remaining - 21.0) < 2.5, "jazida de gema pelo nome (%.0f)" % (j.ore_remaining if j else -1.0))
	check(j.is_unlocked(), "e aberta")
