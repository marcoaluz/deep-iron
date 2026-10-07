extends SceneTree
## Bloco 37: fundação + raio das casas. RODAR SÓ COM APPDATA ISOLADO.
## (Bloco 74: no mapa da maquete v3 o armazém é o da mina — a fundação escolhe só o Centro da Vila.)
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	root.add_child(main)  # founding_on_new_game fica ligado: partida nova de verdade
	current_scene = main  # load_game troca a cena de verdade


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func placer() -> Node:
	return g("house_placer")


## Primeiro ponto válido num anel em volta de `c` (entre r0 e r1).
func spot_near(c: Vector2, r0: float, r1: float) -> Vector2:
	var p = placer()
	var r := r0
	while r <= r1:
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
		r += 14.0
	return Vector2.INF


func obras_done() -> bool:
	return get_nodes_in_group("obras").filter(func(o): return o.obra_pending()).is_empty()


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 1200.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	if step == 0 and t > 2.5:
		print("== fundação")
		check(get_nodes_in_group("casas").is_empty(), "partida nova: nenhuma casa pronta")
		check(get_nodes_in_group("comedouros").is_empty(), "partida nova: nenhum comedouro")
		check(not hub.founded and not hub.visible, "Centro da Vila esperando lugar")
		check(placer().active, "posicionador aberto pro Centro da Vila")
		placer().cancel()
		check(placer().active, "fundação não cancela com Esc/botão direito")
		var env = g("environment")
		var c: Vector2 = env.walkable_rect().get_center()
		var pos := spot_near(c, 0.0, 200.0)
		check(pos != Vector2.INF, "achou lugar livre perto do meio da mina: %s" % pos)
		placer().move_to(pos)
		check(placer().try_confirm(), "Centro da Vila posicionado")
		set_meta("hub", pos)
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 0.3:
		check(hub.global_position == get_meta("hub") and hub.visible, "Centro da Vila no lugar escolhido (%s)" % hub.global_position)
		var arm = g("armazens")
		var env = g("environment")
		check(g("founding").step == "done" and not placer().active, "Bloco 74: não pede o Armazém (ele é o da mina)")
		check(env.surface_area(arm.global_position) == "mina", "o armazém continua na frente da mina (%s)" % arm.global_position)
		set_meta("arm", arm.global_position)
		step = 2
		t_mark = t
	elif step == 2 and t - t_mark > 0.3:
		var eco = main.get_node("Economy")
		var arm = g("armazens")
		check(hub.founded and not placer().active, "vila fundada")
		check(arm.global_position == get_meta("arm"), "Armazém no lugar escolhido")
		print("  pacote inicial: %d cr, %d ferro, %d madeira" % [eco.credits, arm.stock["ferro"], arm.wood_stored])
		var need_cr: int = hub.starter_house_cost.x * 3 + hub.comedouro_cost.x
		var need_fe: int = hub.starter_house_cost.y * 3 + hub.comedouro_cost.y
		var need_wd: int = hub.starter_house_cost.z * 3 + hub.comedouro_cost.z
		check(eco.credits >= need_cr and arm.stock["ferro"] >= need_fe and arm.wood_stored >= need_wd, "dá pra 3 casas + 1 comedouro (%d cr, %d ferro, %d madeira)" % [need_cr, need_fe, need_wd])
		check(hub.starter_houses_left == 3, "3 casas iniciais")
		# Prompt 29 (decisão do Marco): sem raio — casa em qualquer lugar da pedreira; a floresta
		# (além da paliçada) não pode. Antes: só até house_radius() do Centro.
		print("== casas em qualquer lugar da pedreira")
		check(hub.build_starter_house(), "escolher lugar da casa")
		check(hub.house_radius() == 0.0 and placer()._radius == 0.0, "sem raio do Centro")
		var forest := Vector2(-560, -500)  # (Bloco 74: a floresta é a faixa do oeste)
		placer().move_to(forest)
		print("  na floresta: '%s'" % placer()._reason)
		check("floresta" in placer()._reason, "na floresta (além da paliçada): inválido")
		check(not placer().try_confirm() and get_nodes_in_group("casas").is_empty(), "clique na floresta não constrói")
		var far_q := spot_near(Vector2(420, 300), 0.0, 300.0)  # fundo da pedreira, longe do Centro
		placer().move_to(far_q)
		check(placer()._reason == "" and far_q.distance_to(hub.global_position) > 400.0, "longe do Centro, no fundo da pedreira: pode (%s, a %d px)" % [far_q, far_q.distance_to(hub.global_position)])
		var houses: Array = []
		for i in 3:
			if i > 0:
				hub.build_starter_house()
			var q := spot_near(hub.global_position, 110.0, 600.0)
			placer().move_to(q)
			check(placer().try_confirm(), "casa inicial %d em %s (a %d px do Centro)" % [i + 1, q, q.distance_to(hub.global_position)])
			houses.append(q)
		check(hub.starter_houses_left == 0 and get_nodes_in_group("casas").size() == 3, "3 casas encomendadas")
		check(get_nodes_in_group("casas").all(func(c): return c.starter_house and c.obra_pending()), "casas iniciais em obra")
		check(hub.build_comedouro(), "escolher lugar do comedouro")
		var cq := spot_near(arm.global_position, 110.0, 400.0)
		placer().move_to(cq)
		check(placer().try_confirm(), "comedouro encomendado em %s" % cq)
		set_meta("com", cq)
		set_meta("max0", eco.max_workers)
		get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
		get_nodes_in_group("ipezinhos")[1].set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 3
		t_mark = t
	elif step == 3:
		if obras_done() and get_nodes_in_group("comedouros").size() == 1:
			Engine.time_scale = 1.0
			var eco = main.get_node("Economy")
			check(get_nodes_in_group("casas").all(func(c): return c.built), "3 casas prontas")
			check(eco.max_workers == get_meta("max0"), "casas iniciais não mexem no limite (%d)" % eco.max_workers)
			var com = g("comedouros")
			check(com.global_position == get_meta("com") and com.food_stock > 0.0, "comedouro pronto no lugar, com comida (%d)" % com.food_stock)
			print("== raio desligado em qualquer estágio")
			hub.level = 2
			check(hub.house_radius() == 0.0, "estágio 2: continua sem raio")
			hub.level = 1
			var sm = root.get_node("SaveManager")
			set_meta("snap", [hub.global_position, g("armazens").global_position, com.global_position, get_nodes_in_group("casas").size(), hub.starter_houses_left])
			check(sm.save_game("teste"), "salvou")
			sm.load_game()
			step = 4
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "obras não terminaram")
			step = 99
	elif step == 4 and t - t_mark > 2.0:
		var snap: Array = get_meta("snap")
		print("  depois do load: hubs=%d  casas=%d  comedouros=%d" % [get_nodes_in_group("village_hub").size(), get_nodes_in_group("casas").size(), get_nodes_in_group("comedouros").size()])
		check(get_nodes_in_group("village_hub").size() == 1, "(teste) só um mundo depois do load")
		check(hub.global_position == snap[0] and g("armazens").global_position == snap[1], "save/load: Centro e Armazém onde foram fundados")
		check(get_nodes_in_group("comedouros").size() == 1 and g("comedouros").global_position == snap[2], "save/load: comedouro construído no lugar")
		check(get_nodes_in_group("casas").size() == 3 and get_nodes_in_group("casas").all(func(c): return c.placed_by_player and c.starter_house and c.built), "save/load: as 3 casas iniciais (e nenhuma da cena)")
		check(hub.founded and hub.starter_houses_left == 0 and not placer().active, "save/load: fundada, sem refazer a fundação")
		# save ANTIGO (sem layout) + uma casa posicionada longe (fora do raio novo)
		print("== save antigo")
		var f := FileAccess.open("user://savegame.json", FileAccess.READ)
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		f.close()
		data.erase("layout")
		data["village"].erase("founded")
		data["village"].erase("starter_houses_left")
		data["placed_houses"] = [{"name": "CasaNova9", "position": [520.0, 330.0]}]
		data["casas"] = {"CasaNova9": {"built": true}}
		data["comedouros"] = {}
		var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(data))
		fw.close()
		root.get_node("SaveManager").load_game()
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 2.0:
		var names: Array = get_nodes_in_group("casas").map(func(c): return String(c.name))
		print("  casas: ", names, "  Centro em ", hub.global_position)
		check(names.has("Casa") and names.has("Casa2") and names.has("Casa3"), "save antigo: as casas da cena continuam")
		check(names.has("CasaNova9"), "save antigo: casa posicionada longe (fora do raio) continua")
		var far = main.get_node("World/CasaNova9")
		check(far.built and far.beds_total() == 4 and far.global_position.distance_to(hub.global_position) > 400.0, "ela funciona (4 camas) mesmo a %d px do Centro" % far.global_position.distance_to(hub.global_position))
		check(hub.global_position == Vector2(40, -190) and get_nodes_in_group("comedouros").size() == 1, "save antigo: Centro e comedouro no layout da cena")  # Bloco 74: o Centro na praça da vila
		check(hub.founded and not placer().active, "save antigo: não pede fundação")
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 6
		t_mark = t
	elif step == 6 and t - t_mark > 2.0:
		var names: Array = get_nodes_in_group("casas").map(func(c): return String(c.name))
		check(names.has("Casa") and names.has("Casa3") and names.has("CasaNova9"), "salvou de novo e carregou: casas da cena não somem (%s)" % str(names))
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
