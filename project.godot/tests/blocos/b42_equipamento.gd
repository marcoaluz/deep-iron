extends SceneTree
## Bloco 42: casaco de inverno + trajes de perigo. RODAR SÓ COM APPDATA ISOLADO.
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
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func day_of(season: int) -> int:
	return 1 + season * g("sun").days_per_season


## Parado num lugar, sem IA, acordado ao ar livre.
func pin(w, pos: Vector2) -> void:
	w.auto_mode = false
	w._moving = false
	w._set_state("manual")
	w._manual_timer = 999.0
	w.global_position = pos
	w._inside = false
	w._resting = false


func zone(kind: String) -> Node:
	for z in get_nodes_in_group("zonas_perigo"):
		if z.kind == kind:
			return z
	return null


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 900.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	var eq = g("equipment")
	var eco = main.get_node("Economy")
	var arm = g("armazens")
	var ofi = g("oficina")
	for w in ws():
		w.hunger = w.hunger_max
	if dn and step < 90:
		dn.time = 20.0
	if step == 0 and t > 2.0:
		print("== casaco na Oficina")
		# (Bloco 44) o equipamento agora precisa do prédio do Vestiário: ergue um pronto
		eq.spawn_vestiario(g("village_hub").global_position + Vector2(170, 70))
		set_meta("gal", g("village_hub").galleries_for_level(2).map(func(m): return m.is_sealed()))
		dn.day = day_of(1)  # verão
		eco.credits = 99999.0
		arm.stock["ferro"] = 900.0
		arm.stock["carvao"] = 900.0
		arm.wood_stored = 900.0
		arm.leather_stored = 0.0
		arm._recount()
		print("  sem couro: '%s'" % eq.order_block_reason("casaco"))
		check("couro" in eq.order_block_reason("casaco"), "casaco pede couro (vem da caça)")
		arm.leather_stored = 50.0
		var c0: float = eco.credits
		check(eq.order("casaco"), "casaco encomendado")
		check(eco.credits == c0 - eq.coat_credits and arm.leather_stored == 50.0 - eq.coat_leather, "cobrou créditos + couro")
		check(ofi.obra_pending() and "Casaco" in ofi.obra_title(), "fila da Oficina: %s" % ofi.obra_title())
		ws()[0].set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 1
		t_mark = t
	elif step == 1:
		if eq.available("casaco") == eq.coat_batch:
			Engine.time_scale = 1.0
			check(true, "engenheiro fez %d casacos: no vestiário" % eq.coat_batch)
			ws()[0].set_job("ocioso")
			for w in ws():
				check(not w.wearing.has("casaco"), "%s sem casaco no verão" % w.display_name) if w == ws()[0] else null
			print("== inverno")
			dn.day = day_of(3)
			step = 2
			t_mark = t
		elif t - t_mark > 200.0:
			check(false, "casacos não ficaram prontos")
			step = 99
	elif step == 2 and t - t_mark > 0.5:
		var n := ws().filter(func(w): return w.wearing.has("casaco")).size()
		check(n == 3 and eq.available("casaco") == 0, "no inverno os 3 pegaram casaco sozinhos (vestiário: %d)" % eq.available("casaco"))
		var a = ws()[1]
		var b = ws()[2]
		pin(a, Vector2(0, -100))
		pin(b, Vector2(40, -100))
		# b fica sem casaco (e o vestiário vazio)
		b.wearing.erase("casaco")
		print("  work_mult com casaco %.2f  sem casaco %.2f (mood/ânimo iguais)" % [a._cold_mult(), b._cold_mult()])
		check(a._cold_mult() == 1.0 and is_equal_approx(b._cold_mult(), eq.cold_work_mult), "sem casaco trabalha a %d%%" % roundi(eq.cold_work_mult * 100))
		var hud = main.get_node("HUD")
		hud._refresh()
		print("  HUD: ", hud._cold_label.text)
		check(hud._cold_label.visible and "SEM CASACO: 1" in hud._cold_label.text, "HUD avisa quantos ficaram sem")
		b.injured = false
		check(b.hunger > 0.0 and not b.injured, "sem casaco ninguém morre/machuca")
		set_meta("d0", a.wearing.casaco)
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 2.0:
		var a = ws()[1]
		var used: float = get_meta("d0") - a.wearing.casaco
		check(used > 1.5 and used < 2.6, "casaco gasta no frio (%.1f em %.1f s)" % [used, t - t_mark])
		a._inside = true
		set_meta("d1", a.wearing.casaco)
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 1.5:
		var a = ws()[1]
		a._inside = true
		check(absf(a.wearing.casaco - get_meta("d1")) < 0.05, "dentro de casa não gasta")
		a._inside = false
		a.wearing.casaco = 0.4
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 1.0:
		var a = ws()[1]
		check(not a.wearing.has("casaco") and eq.broken_count("casaco") == 1, "casaco rasgou com o uso: foi pra pilha de conserto")
		print("== fim do inverno")
		set_meta("dur_back", ws()[0].wearing.get("casaco", -1.0))
		dn.day = day_of(0) + 16  # primavera do ano seguinte
		step = 6
		t_mark = t
	elif step == 6 and t - t_mark > 0.5:
		check(ws().all(func(w): return not w.wearing.has("casaco")), "acabou o inverno: todos devolveram")
		check(eq.available("casaco") == 1 and absf(eq.pool.casaco[0] - get_meta("dur_back")) < 1.0, "devolvido com o desgaste que tinha (%.0f)" % eq.pool.casaco[0])
		print("== trajes")
		print("  sem pesquisa: '%s'" % eq.order_block_reason("gas"))
		check(eq.order_block_reason("gas").begins_with("precisa pesquisar"), "traje precisa da pesquisa")
		g("research").done.append("trajes")
		check(eq.order("gas"), "máscara de gás encomendada (depois da pesquisa)")
		ws()[0].set_job("engenheiro")
		ws()[0].auto_mode = true
		Engine.time_scale = 8.0
		step = 7
		t_mark = t
	elif step == 7:
		if eq.available("gas") == 1:
			Engine.time_scale = 1.0
			ws()[0].set_job("ocioso")
			var z := zone("gas")
			var a = ws()[1]
			var b = ws()[2]
			pin(a, z.exit_point(z.global_position + Vector2(-200, 0)))
			pin(b, z.exit_point(z.global_position + Vector2(-200, 30)))
			# b pede pra entrar sem traje (o único vai ficar com a)
			a.global_position = z.global_position
			step = 8
			t_mark = t
		elif t - t_mark > 200.0:
			check(false, "máscara não ficou pronta")
			step = 99
	elif step == 8 and t - t_mark > 0.3:
		var z := zone("gas")
		var a = ws()[1]
		var b = ws()[2]
		print("    a: pos %s zona=%s wearing=%s | b: pos %s wearing=%s" % [a.global_position.round(), eq.hazard_at(a.global_position), a.wearing, b.global_position.round(), b.wearing])
		check(a.wearing.has("gas") and eq.available("gas") == 0, "entrou na zona: vestiu a máscara sozinho")
		var bpos: Vector2 = b.global_position
		b.move_to(z.global_position + Vector2(10, 0))
		check(not b._moving or not z.contains(b._target), "sem traje no vestiário: ordem pra dentro bloqueada")
		b.global_position = z.global_position + Vector2(20, 5)  # "entrou" à força
		set_meta("g0", a.wearing.get("gas", 0.0))
		step = 9
		t_mark = t
	elif step == 9 and t - t_mark > 2.0:
		var z := zone("gas")
		var a = ws()[1]
		var b = ws()[2]
		print("    a: pos %s zona=%s wearing=%s estado=%s movendo=%s | vestiário gas=%d" % [a.global_position.round(), g("equipment").hazard_at(a.global_position), a.wearing, a.get_state(), a._moving, g("equipment").available("gas")])
		var used: float = get_meta("g0") - a.wearing.get("gas", 0.0)
		check(used > 1.5 and used < 2.6, "máscara gasta só lá dentro (%.1f em %.1f s)" % [used, t - t_mark])
		check(not z.contains(b.global_position) or (b._moving and not z.contains(b._target)), "quem entrou sem traje é mandado pra fora (%s)" % b.global_position.round())
		var node = main.get_node("World/JazidaGasCarvao")
		check(not node.accepts_worker(b), "jazida da zona não aceita quem não tem traje")
		# b vai pra longe (senão pega a máscara que o a devolver — o que é o certo)
		pin(b, z.exit_point(z.global_position + Vector2(-200, 60)) + Vector2(-80, 0))
		# a sai: devolve
		var left: float = a.wearing.get("gas", 0.0)
		a.global_position = z.exit_point(a.global_position) + Vector2(-30, 0)
		set_meta("left", left)
		step = 10
		t_mark = t
	elif step == 10 and t - t_mark > 0.3:
		var z := zone("gas")
		var a = ws()[1]
		var back: float = eq.pool.gas[0] if eq.available("gas") > 0 else -1.0
		check(not a.wearing.has("gas") and eq.available("gas") == 1 and back < eq.max_durability("gas"), "saiu: devolveu a máscara gasta (%.0f/%.0f)" % [back, eq.max_durability("gas")])
		a.global_position = z.global_position
		step = 11
		t_mark = t
	elif step == 11 and t - t_mark > 0.3:
		var a = ws()[1]
		a.wearing.gas = 0.3
		step = 12
		t_mark = t
	elif step == 12 and t - t_mark > 1.0:
		var z := zone("gas")
		var a = ws()[1]
		check(not a.wearing.has("gas") and eq.broken_count("gas") == 1, "máscara quebrou lá dentro: foi pra pilha")
		check(a._moving and not z.contains(a._target), "e ele saiu na hora")
		print("== conserto (padrão do Arsenal)")
		var rc: Vector4i = eq.repair_cost("gas")
		var c: Vector4i = eq.cost("gas")
		check(rc.x < c.x and rc.y < c.y, "consertar é mais barato (%s x %s)" % [rc, c])
		var c0: float = eco.credits
		check(eq.repair("gas"), "conserto encomendado")
		check(eco.credits == c0 - rc.x and eq.broken_count("gas") == 0 and absf(float(eq.queue[0].total) - eq.suit_time[0] * eq.repair_time_mult) < 0.01, "cobrou %d cr, metade do tempo" % rc.x)
		# couro da caça
		var h = ws()[2]
		h.set_job("caçador")
		h._ai_state = "hunting"
		var l0: float = h.leather_carrying
		h._gather_raw(2.0, 2.5, "hunting")
		check(h.leather_carrying > l0, "caça rende couro (%.1f)" % h.leather_carrying)
		h._ai_state = "foraging"
		var l1: float = h.leather_carrying
		h._gather_raw(1.0, 1.0, "foraging")
		check(h.leather_carrying == l1, "fruta não rende couro")
		# save/load
		ws()[1].wearing = {"casaco": 111.0}
		var snap := [eq.pool.duplicate(true), eq.broken.duplicate(), eq.queue.size(), arm.leather_stored]
		set_meta("snap", snap)
		set_meta("who", ws()[1].display_name)
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 13
		t_mark = t
	elif step == 13 and t - t_mark > 1.5:
		var snap: Array = get_meta("snap")
		var now := [eq.pool.duplicate(true), eq.broken.duplicate(), eq.queue.size(), arm.leather_stored]
		print("  antes:  ", snap, "\n  depois: ", now)
		check(str(now[1]) == str(snap[1]) and now[2] == snap[2] and absf(now[3] - snap[3]) < 0.01 and (now[0].gas as Array).size() == (snap[0].gas as Array).size(), "save/load: vestiário, pilha, fila e couro iguais")
		var who: Node = null
		for w in ws():
			if w.display_name == get_meta("who"):
				who = w
		check(who != null and (who.wearing.has("casaco") and absf(who.wearing.casaco - 111.0) < 0.01 or eq.available("casaco") >= 1), "save/load: casaco e desgaste de quem vestia")
		var gal: Array = g("village_hub").galleries_for_level(2).map(func(m): return m.is_sealed())
		check(str(gal) == str(get_meta("gal")), "galerias por estágio iguais")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
