extends SceneTree
## Bloco 27: caçador + cozinheiro que prepara. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var hunter: Node2D
var cook: Node2D
var eco: Node
var arm: Node
var com: Node
var oficina: Node
var last_prep := 0.0
var food_before_batch := -1.0
var saw_prep_hold := false
var fruit_trip := 0.0
var meat_trip := 0.0
var stocking_seen_raw := 0.0
var t_mark := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true  # Bloco 102: o teste é de antes do catálogo (tudo conhecido)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	for f in ["user://savegame.json"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 400.0:
		print("TIMEOUT no passo %d" % step)
		print("\nFALHAS: %d" % (fails + 1))
		return true
	var dn = get_first_node_in_group("day_night")
	if dn:
		dn.time = 20.0  # dia eterno durante o teste
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max  # ninguém para pra comer (isola o teste da comida)
	if step == 0 and t > 1.5:
		eco = main.get_node("Economy")
		arm = get_first_node_in_group("armazens")
		com = get_first_node_in_group("comedouros")
		oficina = get_first_node_in_group("oficina")
		var ws := get_nodes_in_group("ipezinhos")
		hunter = ws[0]
		cook = ws[1]
		hunter.set_job("caçador")
		cook.set_job("cozinheiro")
		print("== caçador: %s  cozinheiro: %s" % [hunter.display_name, cook.display_name])
		check(not oficina.has_tool("arco"), "começa sem arco e flecha")
		var toca = get_first_node_in_group("caca")
		check(toca != null and not toca.is_usable(), "toca não é usável sem arco")
		step = 1
	elif step == 1:
		# 1) sem arco: colhe fruta, nunca caça
		if hunter.get_state() == "hunting":
			check(false, "caçou SEM arco")
		if cook.get_state() == "idle" and t < 8.0 and arm.raw_stored <= 0.0:
			if t_mark == 0.0:
				t_mark = t
				check(cook.get_state_label() == "esperando matéria-prima", "cozinheiro sem matéria-prima espera: '%s'" % cook.get_state_label())
		if hunter.get_state() == "stocking" and stocking_seen_raw == 0.0:
			stocking_seen_raw = hunter.raw_carrying
			fruit_trip = hunter.raw_carrying
			print("  viagem de fruta: %.1f de matéria-prima (%s)" % [fruit_trip, hunter.get_state_label()])
		if arm.raw_stored > 0.5:
			check(fruit_trip > 0.0, "caçador colheu fruta e o estoque de matéria-prima subiu (%.1f)" % arm.raw_stored)
			step = 2
	elif step == 2:
		# 2) cozinheiro busca, prepara, e só no fim a comida pronta sobe
		if cook.get_state() == "cooking" and cook._prep_left > 0.0:
			if food_before_batch < 0.0:
				food_before_batch = com.food_stock
				print("  preparando: leva de %.1f, %s" % [cook.raw_carrying, cook.get_state_label()])
			if com.food_stock > food_before_batch + 0.01:
				check(false, "comida pronta subiu ANTES da leva terminar")
			saw_prep_hold = true
		elif saw_prep_hold and cook._prep_left <= 0.0:
			check(com.food_stock > food_before_batch, "leva pronta: comida %.1f -> %.1f" % [food_before_batch, com.food_stock])
			# 3) arco e flecha
			oficina.crafted["arco"] = true
			for w in get_nodes_in_group("ipezinhos"):
				w.on_tool_crafted("arco")
			# (Bloco 43) Bloco 29: o arco só vai na mão caçando; fora disso, a cesta de coleta
			check(hunter._hand_item() == (hunter.BOW if hunter.get_state() == "hunting" else hunter.FORAGE_BASKET),
				"caçador com arco (na mão só caçando)")
			stocking_seen_raw = 0.0
			step = 3
	elif step == 3:
		if hunter.get_state() == "hunting" and t_mark >= 0.0:
			print("  caçando: %s" % hunter.get_state_label())
			t_mark = -1.0
		if hunter.get_state() == "stocking" and stocking_seen_raw == 0.0 and t_mark < 0.0:
			meat_trip = hunter.raw_carrying
			stocking_seen_raw = meat_trip
			check(meat_trip > fruit_trip, "viagem de caça rende mais: %.1f x fruta %.1f" % [meat_trip, fruit_trip])
			step = 4
	elif step == 4 and hunter.get_state() != "stocking":
		# 4) save/load de verdade (pasta isolada)
		var toca = get_first_node_in_group("caca")
		# (Bloco 43) matéria-prima TOTAL (armazém + mochilas): o jogo segue rodando depois do
		# load e o cozinheiro pode pegar um pouco do armazém antes da conferência
		var raw_total: float = arm.raw_stored
		for w in get_nodes_in_group("ipezinhos"):
			raw_total += w.raw_carrying
		var want := {"raw": arm.raw_stored, "raw_total": raw_total, "game": toca.game_remaining}
		var sm = root.get_node("SaveManager")
		check(sm.save_game("teste"), "salvou (raw %.1f, toca %.1f, arco)" % [want.raw, want.game])
		set_meta("want", want)
		sm.load_game()
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 0.8:
		var want: Dictionary = get_meta("want")
		var arm2 = get_first_node_in_group("armazens")
		var of2 = get_first_node_in_group("oficina")
		var toca2 = get_first_node_in_group("caca")
		var total2: float = arm2.raw_stored
		for w in get_nodes_in_group("ipezinhos"):
			total2 += w.raw_carrying
		check(absf(arm2.raw_stored - want.raw) < 1.0 or absf(total2 - want.raw_total) < 1.0,
			"matéria-prima voltou (armazém %.1f, total %.1f de %.1f)" % [arm2.raw_stored, total2, want.raw_total])
		check(absf(toca2.game_remaining - want.game) < 1.0, "toca voltou no mesmo estado (%.1f)" % toca2.game_remaining)
		check(of2.has_tool("arco"), "arco e flecha continua desbloqueado")
		var jobs := get_nodes_in_group("ipezinhos").map(func(w): return w.job)
		check(jobs.has("caçador") and jobs.has("cozinheiro"), "funções voltaram: %s" % [jobs])
		print("\nFALHAS: %d" % fails)
		return true
	return false
