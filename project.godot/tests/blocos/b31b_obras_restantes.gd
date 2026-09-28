extends SceneTree
## Bloco 31b. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var snap := {}


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
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade (sem deixar o mundo velho)


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func free_spot(near: Vector2) -> Vector2:
	var placer = g("house_placer")
	placer._collect_blockers()
	for r in range(1, 16):
		for a in range(16):
			var p: Vector2 = near + Vector2.RIGHT.rotated(a * TAU / 16.0) * (60.0 + r * 28.0)
			if placer.check_spot(p) == "":
				return p
	return Vector2.INF


## As 6 obras do 31b que existem agora (nome -> nó que responde a interface de obra).
func obras31b() -> Dictionary:
	var d := {}
	var hub = g("village_hub")
	if hub.pending_upgrade == "expandir":
		d["expandir"] = hub
	for c in get_nodes_in_group("canteiros"):
		d[c.kind] = c
	var esc = g("escudos")
	if esc and esc.obra_pending():
		d["escudo"] = esc
	var dig = g("escavadeira")
	if dig.building_reactor != "":
		d["reator"] = dig
	return d


func progress_text() -> String:
	var parts: Array[String] = []
	var o := obras31b()
	for k in o:
		parts.append("%s %d%%" % [k, roundi(o[k].obra_progress() * 100)])
	return "  ".join(parts)


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 1500.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 2.0:
		var eco = main.get_node("Economy")
		var hub = g("village_hub")
		var arm = g("armazens")
		eco.credits = 999999
		for k in arm.stock:
			arm.stock[k] = 9000.0
		arm.wood_stored = 9000.0
		arm.lifetime_stored = 999999.0
		arm._recount()
		g("finds").rare_parts = 99
		hub.level = 4  # lab (2) e escudo (4) liberados; expandir 4 -> 5
		print("== encomendas das 6 obras, sem engenheiro")
		var c0: float = eco.credits
		check(hub.level_up(), "expandir a vila encomendado")
		check(hub.level == 4, "nível da vila ainda NÃO subiu")
		OS.delay_msec(15)
		check(g("morale")._confirm_taverna(free_spot(hub.global_position)), "taverna encomendada")
		OS.delay_msec(15)
		check(g("research")._confirm_lab(free_spot(hub.global_position)), "laboratório encomendado")
		OS.delay_msec(15)
		check(g("defense")._confirm_campo(free_spot(hub.global_position)), "campo de treino encomendado")
		OS.delay_msec(15)
		var sun = g("sun")
		var esc = sun.spawn_shield(free_spot(hub.global_position))
		check(esc.start_stage("fundacao"), "etapa do escudo encomendada")
		OS.delay_msec(15)
		var dig = g("escavadeira")
		for id in dig.PART_IDS:
			dig.installed[id] = true
		dig._complete()
		check(dig.build_reactor("diesel"), "reator encomendado")
		check(not dig.built_reactors.has("diesel"), "reator ainda NÃO existe")
		check(eco.credits < c0, "cobrou tudo na encomenda (%d -> %d cr)" % [c0, eco.credits])
		check(g("tavernas") == null and g("laboratorios") == null and g("campos") == null, "nenhum prédio apareceu ainda (só canteiros)")
		check(g("morale").taverna_block_reason().begins_with("em obra"), "taverna bloqueada: '%s'" % g("morale").taverna_block_reason())
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 6.0:
		var o := obras31b()
		print("  6 s sem engenheiro: ", progress_text())
		check(o.size() == 6, "as 6 obras pendentes (%d)" % o.size())
		var moved := false
		for k in o:
			if o[k].obra_progress() > 0.0:
				moved = true
		check(not moved, "nada andou sem engenheiro")
		var hud = main.get_node("HUD")
		hud._refresh()
		print("  HUD: ", hud._obras_label.text.replace("\n", " | "))
		check("esperando engenheiro" in hud._obras_label.text, "HUD mostra esperando engenheiro")
		var lab_c = null
		for c in get_nodes_in_group("canteiros"):
			if c.kind == "laboratorio":
				lab_c = c
		check(lab_c != null and "esperando engenheiro" in lab_c._label.text, "canteiro mostra: %s" % (lab_c._label.text.replace("\n", " ") if lab_c else "?"))
		get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
		step = 2
		t_mark = t
	elif step == 2:
		var hub = g("village_hub")
		var eng = get_nodes_in_group("ipezinhos")[0]
		if eng._obra_on_site and hub.obra_progress() > 0.05:
			print("  ", eng.get_state_label(), "  |  ", progress_text())
			check(eng._obra == hub, "fila: a mais antiga (expandir) primeiro")
			var others := 0.0
			var o := obras31b()
			for k in o:
				if k != "expandir":
					others += o[k].obra_progress()
			check(others == 0.0, "um de cada vez: só a expansão andou")
			snap = {"expandir": hub.obra_progress()}
			eng.set_job("ocioso")
			step = 3
			t_mark = t
		elif t - t_mark > 120.0:
			check(false, "engenheiro não começou (%s)" % eng.get_state_label())
			step = 9
	elif step == 3 and t - t_mark > 4.0:
		var hub = g("village_hub")
		check(absf(hub.obra_progress() - snap.expandir) < 0.001, "tirou o engenheiro: pausou em %d%%" % roundi(hub.obra_progress() * 100))
		var sm = root.get_node("SaveManager")
		set_meta("before", progress_text())
		check(sm.save_game("teste"), "salvou com as 6 obras pendentes")
		sm.load_game()
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 2.5:
		print("  antes:  ", get_meta("before"))
		print("  depois: ", progress_text())
		var o := obras31b()
		check(o.size() == 6 and progress_text() == get_meta("before"), "as 6 obras e o progresso voltaram iguais do save")
		for w in get_nodes_in_group("ipezinhos"):
			w.set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 5
		t_mark = t
	elif step == 5:
		# vigia engenheiro "preso": indo pra obra há muito tempo sem sair do lugar
		for w in get_nodes_in_group("ipezinhos"):
			if w.get_state() == "building" and not w._obra_on_site and w._obra != null:
				var key := "walk_%s" % w.name
				var last: Array = get_meta(key) if has_meta(key) else [w.global_position, t]
				if w.global_position.distance_to(last[0]) > 12.0:
					set_meta(key, [w.global_position, t])
				elif t - last[1] > 30.0:
					check(false, "%s preso a caminho de %s há 30 s em %s" % [w.display_name, w._obra.obra_title(), w.global_position.round()])
					set_meta(key, [w.global_position, t + 9999.0])
				else:
					set_meta(key, last)
		var lab_c = null
		for c in get_nodes_in_group("canteiros"):
			if c.kind == "laboratorio":
				lab_c = c
		var lab_ok: bool = lab_c == null or lab_c.obra_progress() > 0.3
		if g("tavernas") != null and Canteiro_count("taverna") == 0 and lab_ok:
			Engine.time_scale = 1.0
			check(true, "taverna ficou pronta: o canteiro virou prédio (%s)" % g("tavernas").name)
			check(g("morale").build_or_upgrade_taverna(), "ampliação da taverna encomendada")
			check(Canteiro_count("taverna_up") == 1 and g("tavernas").level == 1, "ampliação em obra; taverna ainda nível 1")
			step = 9
		elif t - t_mark > 500.0:
			Engine.time_scale = 1.0
			check(false, "taverna não ficou pronta: %s" % progress_text())
			for w in get_nodes_in_group("ipezinhos"):
				var ob = w._obra
				print("    %s job=%s estado=%s | %s | pos %s alvo %s movendo=%s | obra em %s" % [w.display_name, w.job, w.get_state(), w.get_state_label(),
					w.global_position.round(), w._target.round(), w._moving,
					ob.obra_position(w).round() if ob else "-"])
			step = 9
	if step == 9:
		print("  estado final: ", progress_text())
		for w in get_nodes_in_group("ipezinhos"):
			print("    %s job=%s | %s | pos %s alvo %s movendo=%s" % [w.display_name, w.job, w.get_state_label(), w.global_position.round(), w._target.round(), w._moving])
			if w._moving:
				var map: RID = w._agent.get_navigation_map()
				var cp: Vector2 = NavigationServer2D.map_get_closest_point(map, w._target)
				var path: PackedVector2Array = NavigationServer2D.map_get_path(map, w.global_position, w._target, true)
				print("      alvo mais perto andável %s (dist %d)  caminho %d pontos, termina em %s  fim_nav=%s  preso_etapa=%d t=%.1f" % [cp.round(), cp.distance_to(w._target), path.size(), path[path.size()-1].round() if path.size() > 0 else "-", w._agent.is_navigation_finished(), w._stuck_stage, w._stuck_time])
				print("      próximo ponto do agente: %s  vel %s  desvio=%s ghost=%.1f  vel_efetiva=%.1f" % [w._agent.get_next_path_position().round(), w.velocity.round(), w._agent.avoidance_enabled, w._ghost_left, w._get_effective_speed()])
		print("\nFALHAS: %d" % fails)
		return true
	return false


func Canteiro_count(kind: String) -> int:
	return get_nodes_in_group("canteiros").filter(func(c): return c.kind == kind).size()
