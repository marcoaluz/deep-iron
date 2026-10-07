extends SceneTree
## Bloco 87: o FERREIRO (Oficina e Arsenal; o engenheiro só nas obras de construção) — ferramentas, a forja
## do Arsenal (fabricar x consertar, desgaste), pregos e ferragens por ordem (production_queue) — e a
## MIGRAÇÃO dos custos em minério pra barras a partir do estágio da fornalha (armas, barricadas, peças da
## Escavadeira, reatores, coletores, laboratório); os prédios iniciais seguem no minério bruto.
## RODAR SÓ COM APPDATA ISOLADO.
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


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func enche(eco, arm) -> void:
	eco.credits = 99999.0
	for o in arm.stock:
		arm.stock[o] = 2000.0
	arm.wood_stored = 2000.0
	arm._recount()


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 2000.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(9.0)
	for w in ws():
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	var eco = g("economy")
	var arm = g("armazens")
	var of = g("oficina")
	var def = g("defense")
	if step == 0 and t > 2.0:
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		print("== migração: estágio 1 = minério bruto")
		enche(eco, arm)
		hub.level = 1
		check(eco.metal(40, "ferro") == ["ferro", 40.0] and not eco.pede_barras(), "antes da fornalha: 40 ferro continua 40 ferro")
		check("barra" not in hub.coletor_cost_text() and "barra" not in g("research").lab_cost_text(), "custos ainda em minério ('%s')" % g("research").lab_cost_text())
		print("== a partir do estágio da fornalha: barras")
		hub.level = hub.fornalha_estagio
		check(eco.pede_barras() and eco.metal(40, "ferro") == ["barra_ferro", 20.0] and eco.metal(60, "prata") == ["barra_prata", 30.0] and eco.metal(35, "cobre") == ["barra_cobre", 18.0],
			"1 barra = %s minérios (40 ferro -> 20 barras; 35 cobre -> 18)" % eco.minerios_por_barra)
		var tabela := {
			"laboratório": g("research").lab_cost_text(),
			"coletor de madeira": hub.coletor_cost_text(),
			"coletor de minério": hub.coletor_minerio_cost_text(),
			"lança de ferro": eco.custo_metal_texto(def.weapon_costs[1].x, def.weapon_costs[1].y, def.weapon_ore[1], def.weapon_costs[1].z),
			"reator (fusão)": eco.metal_texto(g("escavadeira").reactor_cost("fusao").y if g("escavadeira") else 0, "ferro"),
		}
		print("  ", tabela)
		check(tabela.values().all(func(v): return v == "" or "barra" in v), "laboratório, coletores, armas e reatores pedem barras")
		check("barra" not in hub.comedouro_cost_text() and "barra" not in hub.fornalha_cost_text() and "barra" not in hub.starter_cost_text(),
			"prédios iniciais (casa, cozinha, fornalha) seguem no minério bruto")
		for o in arm.stock:
			arm.stock[o] = 2000.0
		arm.itens.clear()
		arm._recount()
		var cl: Vector3i = def.weapon_costs[1]
		var falta_l: String = eco.metal_falta(cl.x, cl.y, def.weapon_ore[1], cl.z)
		check("barras de ferro" in falta_l, "sem barra a lança não sai ('%s')" % falta_l)
		print("== o ferreiro e a Oficina")
		var eng = ws()[0]
		var fer = ws()[1]
		eng.set_job("engenheiro")
		check(of != null and of.get("oficio") == "ferreiro", "a obra da Oficina é do ferreiro")
		check(of.start_tool("picareta_aco"), "encomendou a picareta de aço na Oficina")
		set_meta("eng", eng)
		set_meta("fer", fer)
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 40.0:
		var eng = get_meta("eng")
		check(of.craft_progress() == 0.0 and eng._obra != of, "o engenheiro NÃO forja (Oficina parada: %d%%)" % roundi(of.craft_progress() * 100.0))
		check("esperando ferreiro" in of._label.text or "ferreiro" in of._obra.status(0.0), "a Oficina mostra 'esperando ferreiro'")
		var fer = get_meta("fer")
		fer.set_job("ferreiro")
		check(fer.is_smith() and fer.outfit() == "ferreiro", "função Ferreiro (roupa provisória)")
		step = 2
		t_mark = t
	elif step == 2:
		if of.has_tool("picareta_aco"):
			check(true, "o ferreiro forjou a picareta de aço")
			print("== pregos e ferragens: só por ordem")
			for o in arm.stock:
				arm.stock[o] = 0.0
			arm.itens.clear()
			arm.itens["barra_ferro"] = 2.0
			arm._recount()
			check(of.encomendar("prego", 2), "encomendou 2 x pregos (6 cada)")
			check(eco.quantidade("barra_ferro") == 2.0, "encomendar não gasta")
			step = 3
			t_mark = t
		elif t - t_mark > 600.0:
			check(false, "o ferreiro não forjou (%s)" % get_meta("fer").get_state_label())
			step = 99
	elif step == 3:
		if not of.fila_ferreiro.tem_trabalho():
			check(eco.quantidade("prego") == 12.0 and eco.quantidade("barra_ferro") == 0.0, "fez exatamente 12 pregos com 2 barras (%d pregos)" % eco.quantidade("prego"))
			of.encomendar("ferragem", 1)
			check(of.falta_encomenda() != "" and "barras de ferro" in of.falta_encomenda(), "ferragem sem barra: PAUSADA ('%s')" % of.falta_encomenda())
			check(eco.quantidade("prego") == 12.0, "pausada não gasta os pregos")
			of.cancelar(0)
			print("== a forja do Arsenal com o ferreiro (fabricar x consertar)")
			enche(eco, arm)
			arm.itens["barra_ferro"] = 200.0
			var q := spot_near(hub.global_position + Vector2(-150, 120))
			var ars = def.spawn_arsenal(q)
			check(ars != null and ars.get("oficio") == "ferreiro", "o Arsenal é obra do ferreiro")
			var b0: float = eco.quantidade("barra_ferro")
			check(def.start_forge("lanca"), "forjar lança")
			check(eco.quantidade("barra_ferro") == b0 - ceilf(def.weapon_costs[1].y / eco.minerios_por_barra), "pagou em barras (%d)" % (b0 - eco.quantidade("barra_ferro")))
			def.broken["lanca"] = 1
			check(def.start_repair("lanca"), "consertar uma lança quebrada")
			set_meta("rack0", def.rack_count("lanca"))
			step = 4
			t_mark = t
		elif t - t_mark > 600.0:
			check(false, "os pregos não ficaram prontos (%s)" % of.fila_ferreiro.texto_ordem(0))
			step = 99
	elif step == 4:
		if def.queue.is_empty():
			check(def.rack_count("lanca") == get_meta("rack0") + 2, "fabricou uma e consertou outra: 2 lanças a mais no cavalete")
			print("== barricada, escavadeira, coletor, laboratório em barra")
			var bar = g("barricadas")
			if bar.level < 2:
				bar.level = 1
			var c3: Vector3i = bar.upgrade_costs[bar.level + 1]
			var b1: float = eco.quantidade("barra_ferro")
			var ok_bar: bool = bar.upgrade_block_reason() == "" and bar.upgrade()
			print("  barricada: %s; barras %d -> %d" % [ok_bar, b1, eco.quantidade("barra_ferro")])
			check(not ok_bar or eco.quantidade("barra_ferro") == b1 - ceilf(c3.y / eco.minerios_por_barra), "ampliar a barricada paga em barras")
			arm.itens.clear()
			arm._recount()
			var falta_col: String = hub.coletor_minerio_block_reason()
			check("barras de ferro" in falta_col, "coletor de minério sem barra: '%s'" % falta_col)
			print("== save")
			of.encomendar("prego", 3)
			root.get_node("SaveManager").save_game("teste")
			root.get_node("SaveManager").load_game()
			step = 5
			t_mark = t
		elif t - t_mark > 900.0:
			check(false, "a forja não terminou (%s)" % def.forge_title())
			step = 99
	elif step == 5 and t - t_mark > 2.0:
		var of2 = g("oficina")
		check(of2.fila_ferreiro.fila.size() == 1 and of2.fila_ferreiro.texto_ordem(0).begins_with("Pregos"), "load: a encomenda de pregos voltou")
		step = 99
	if step == 99:
		Engine.time_scale = 1.0
		print("\nFALHAS: %d" % fails)
		return true
	return false
