extends SceneTree
## Bloco 34: horta na clareira. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var states: Array[String] = []
var left_clearing := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true  # Bloco 102: o teste é de antes do catálogo (tudo conhecido)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade (sem deixar o mundo velho)


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func hunter() -> Node:
	return get_nodes_in_group("ipezinhos")[0]


func nav_ok(from: Vector2, to: Vector2) -> float:
	var map: RID = hunter()._agent.get_navigation_map()
	var path: PackedVector2Array = NavigationServer2D.map_get_path(map, from, to, true)
	return path[path.size() - 1].distance_to(to) if path.size() > 0 else INF


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 900.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	var env = g("environment")
	var horta = main.get_node("World/Horta")
	var arm = g("armazens")
	var h := hunter()
	if step == 0 and t > 2.0:
		print("== horta na clareira em ", horta.global_position)
		check(env.clearing_rect.has_point(horta.global_position), "horta dentro da clareira")
		check(horta.global_position.distance_to(g("comedouros").global_position) > 600.0, "longe do comedouro (%d px)" % horta.global_position.distance_to(g("comedouros").global_position))
		var near_tree := INF
		for a in get_nodes_in_group("arvores"):
			near_tree = minf(near_tree, horta.global_position.distance_to(a.global_position))
		var near_toca := INF
		for c in get_nodes_in_group("caca"):
			near_toca = minf(near_toca, horta.global_position.distance_to(c.global_position))
		check(near_tree >= 80.0 and near_tree <= 200.0 and near_toca >= 80.0, "perto mas não colada: árvore a %d px, toca a %d px" % [near_tree, near_toca])
		var d := nav_ok(arm.global_position + Vector2(0, 40), horta.global_position + Vector2(0, 20))
		check(d < 30.0, "navegação: armazém -> horta chega (sobra %.1f px)" % d)
		for n in ["GaleriaOeste", "GaleriaSudeste", "GaleriaNorte", "GaleriaNordeste"]:
			var gp: Vector2 = main.get_node("World/" + n).global_position
			var dg := nav_ok(arm.global_position + Vector2(0, 40), gp + Vector2(0, 26))
			check(dg < 30.0, "navegação: armazém -> %s chega (sobra %.1f px)" % [n, dg])
		check(g("oficina").has_tool("arco") == false, "partida nova: sem arco")
		h.set_job("caçador")
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1:
		if h.get_state() == "foraging" and h._station == horta and env.clearing_rect.has_point(h.global_position):
			print("  sem arco: ", h.get_state_label(), " em ", h.global_position.round())
			check(true, "caçador sem arco atravessou o túnel e está colhendo fruta na clareira")
			step = 2
			t_mark = t
		elif t - t_mark > 150.0:
			check(false, "caçador sem arco não chegou na horta (%s em %s)" % [h.get_state_label(), h.global_position.round()])
			step = 2
	elif step == 2:
		if arm.raw_stored > 0.5:
			print("  entregou %.1f de matéria-prima no armazém" % arm.raw_stored)
			check(true, "voltou pra mina só pra entregar")
			g("oficina").crafted["arco"] = true
			step = 3
			t_mark = t
		elif t - t_mark > 200.0:
			check(false, "caçador não entregou (%s)" % h.get_state_label())
			step = 3
	elif step == 3:
		if h.get_state() == "hunting" and h._raw_units > 0.5 and h._raw_units < h.hunter_carry - 3.0:
			print("  com arco: ", h.get_state_label(), " mochila %.1f/%d" % [h._raw_units, h.hunter_carry])
			check(g("caca") != null and env.clearing_rect.has_point(h.global_position), "caçando na toca da clareira")
			for c in get_nodes_in_group("caca"):
				c.game_remaining = 0.0
				c._cooldown = 300.0
			states.clear()
			step = 4
			t_mark = t
		elif t - t_mark > 200.0:
			check(false, "caçador com arco não foi caçar (%s)" % h.get_state_label())
			step = 5
	elif step == 4:
		var s: String = h.get_state()
		if states.is_empty() or states[-1] != s:
			states.append(s)
		if not env.clearing_rect.grow(10.0).has_point(h.global_position) and s != "stocking":
			left_clearing = true
		if s == "foraging" and h._station == horta and h._work_timer > 0.0:
			print("  tocas esgotadas -> estados: ", " > ".join(states))
			check(not states.has("stocking"), "não voltou pra mina entre caçar e colher")
			check(not left_clearing, "ficou na clareira o tempo todo")
			check(h._raw_units > 0.5, "mochila da caça continua (%.1f)" % h._raw_units)
			step = 5
			t_mark = t
		elif t - t_mark > 120.0:
			check(false, "não passou pra fruta: %s" % " > ".join(states))
			step = 5
	elif step == 5:
		Engine.time_scale = 1.0
		h.set_job("ocioso")
		horta.food_remaining = 77.5
		horta._cooldown = 0.0
		var sm = root.get_node("SaveManager")
		check(sm.save_game("teste"), "salvou")
		horta.food_remaining = 3.0
		sm.load_game()
		step = 6
		t_mark = t
	elif step == 6 and t - t_mark > 2.0:
		var horta2 = main.get_node("World/Horta")
		print("  depois do load: horta %.1f em %s" % [horta2.food_remaining, horta2.global_position])
		check(absf(horta2.food_remaining - 77.5) < 1.0, "save/load: comida da horta preservada")
		check(env.clearing_rect.has_point(horta2.global_position), "save/load: horta continua na clareira")
		step = 9
	if step == 9:
		print("\nFALHAS: %d" % fails)
		return true
	return false
