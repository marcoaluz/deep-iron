extends SceneTree
## Bloco 86: ORDENS DE PRODUÇÃO (production_queue.gd) + FORNALHA + FUNDIDOR. Nada sem ordem; quantidade do
## jogador; insumo gasto só quando a unidade começa; pausa sem insumo (nada mais é gasto); cancelar devolve;
## fila com máximo; estágio da vila; custo só minério e créditos; save. RODAR SÓ COM APPDATA ISOLADO.
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


func finish_canteiro(kind: String) -> bool:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			c.obra_work(c.left + 1.0)
			return true
	return false


func estoque(eco, item: String) -> float:
	return eco.quantidade(item)


func menu_card(menu, tab: String, name: String) -> Dictionary:
	menu.visible = true
	menu._show_tab(menu.TAB_NAMES.find(tab))
	menu.refresh()
	for c in menu._cards:
		if c.def.name == name:
			return c
	return {}


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
		dn.time = dn.tempo_da_hora(9.0)  # sempre de manhã, horário de trabalho
	for w in ws():
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	var eco = g("economy")
	var arm = g("armazens")
	if step == 0 and t > 2.0:
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		print("== construir a fornalha")
		eco.credits = 5000.0
		for o in arm.stock:
			arm.stock[o] = 0.0
		arm.stock["ferro"] = 300.0
		arm.wood_stored = 0.0
		arm._recount()
		hub.level = 1
		check("estágio" in hub.fornalha_block_reason(), "estágio 1: a fornalha ainda não libera ('%s')" % hub.fornalha_block_reason())
		var hud = g("hud")
		check(not menu_card(hud._build_menu, "Produção", "Fornalha").is_empty(), "menu: aba Produção com a Fornalha")
		hud._build_menu.visible = false
		hub.level = 2
		check(hub.fornalha_block_reason() == "", "estágio 2: libera, mesmo SEM madeira (custo só minério e créditos)")
		var c0: float = eco.credits
		var f0: float = arm.stock["ferro"]
		check(hub.build_fornalha(), "escolher lugar")
		var q := spot_near(hub.global_position + Vector2(160, 80))
		g("house_placer").cancel()
		check(q.is_finite() and hub._confirm_fornalha(q), "fornalha encomendada (canteiro) em %s" % q)
		# Bloco 96: o ferro fica reservado no armazém (o engenheiro leva): o livre cai
		check(eco.credits == c0 - hub.fornalha_credits and is_equal_approx(eco.livre("ferro"), f0 - hub.fornalha_ore), "gastou %d cr + %d ferro" % [hub.fornalha_credits, hub.fornalha_ore])
		check(finish_canteiro("fornalha") and get_nodes_in_group("fornalhas").size() == 1, "o engenheiro ergueu a fornalha")
		var f = g("fornalhas")
		print("== sem ordem: nada")
		var fund = ws()[0]
		fund.set_job("fundidor")
		check(fund.is_smelter() and fund.outfit() == "fundidor", "função Fundidor (roupa provisória)")
		arm.stock["ferro"] = 20.0
		arm.stock["carvao"] = 10.0
		arm._recount()
		set_meta("f", f)
		set_meta("fund", fund)
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 30.0:
		var f = get_meta("f")
		var fund = get_meta("fund")
		check(estoque(eco, "ferro") == 20.0 and estoque(eco, "carvao") == 10.0 and fund.barras_mao.is_empty(), "sem ordem o fundidor não pega nada (ferro 20, carvão 10)")
		check(fund.get_state() == "idle" and not f._acesa, "fundidor parado, fornalha apagada (%s)" % fund.get_state())
		print("== ordem: 3 barras de ferro")
		check(f.encomendar("barra_ferro", 3), "encomendou 3 barras de ferro")
		check(estoque(eco, "ferro") == 20.0, "encomendar não gasta nada (cada unidade paga quando começa)")
		step = 2
		t_mark = t
	elif step == 2:
		var f = get_meta("f")
		if not f.fila.tem_trabalho() and get_meta("fund").barras_mao.is_empty():
			Engine.time_scale = 1.0
			print("  barras %d; ferro %d; carvão %d" % [estoque(eco, "barra_ferro"), estoque(eco, "ferro"), estoque(eco, "carvao")])
			check(estoque(eco, "barra_ferro") == 3.0, "fez EXATAMENTE 3 barras e levou pro armazém")
			check(estoque(eco, "ferro") == 14.0 and estoque(eco, "carvao") == 7.0, "gastou 3 x (2 ferro + 1 carvão)")
			set_meta("ferro_fim", estoque(eco, "ferro"))
			Engine.time_scale = 4.0
			step = 3
			t_mark = t
		elif t - t_mark > 1200.0:
			Engine.time_scale = 1.0
			check(false, "a ordem não terminou (%s, %s)" % [get_meta("fund").get_state(), f.status_text()])
			step = 99
	elif step == 3 and t - t_mark > 20.0:
		var f = get_meta("f")
		check(estoque(eco, "ferro") == get_meta("ferro_fim") and get_meta("fund").get_state() == "idle", "terminada a ordem, ele para (nada mais gasto)")
		print("== pausa sem insumo")
		arm.stock["cobre"] = 2.0
		arm.stock["carvao"] = 0.0
		arm._recount()
		f.encomendar("barra_cobre", 5)
		check(f.falta() != "" and "carvão" in f.falta(), "sem carvão: PAUSADA ('%s')" % f.falta())
		check("PAUSADA" in f.status_text(), "a placa mostra a pausa")
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 20.0:
		var f = get_meta("f")
		check(estoque(eco, "cobre") == 2.0 and f.fila.comecadas() == 0, "pausada: nada foi gasto (cobre 2)")
		print("== cancelar devolve")
		f.cancelar(0)
		check(not f.fila.tem_trabalho(), "cancelou a ordem")
		arm.stock["prata"] = 8.0
		arm._recount()
		f.encomendar("barra_prata", 4)
		var n: int = f.fila.comecar_unidades(2, eco)
		check(n == 2 and estoque(eco, "prata") == 4.0, "2 unidades começadas pagaram 4 prata")
		f.cancelar(0)
		check(estoque(eco, "prata") == 8.0, "cancelar devolveu a prata das começadas")
		print("== limites")
		check("estágio 3" in f.motivo_encomenda("aco", 1), "aço só no estágio 3 (Fundição)")
		hub.level = 3
		check(f.motivo_encomenda("aco", 1) == "", "estágio 3: aço libera")
		for i in f.max_fila:
			f.encomendar("barra_ferro", 1)
		check("fila cheia" in f.motivo_encomenda("barra_ferro", 1), "fila com máximo (%d)" % f.max_fila)
		print("== janela")
		var hud = g("hud")
		hud.open_panel("fornalha")
		var p = hud._panels["fornalha"]
		p.focus(f)
		p.refresh()
		check(p._linhas.size() == f.receitas.size(), "uma linha por receita (%d)" % p._linhas.size())
		var q0: int = p._qtd["barra_cobre"]
		check(p._fila_box.get_child_count() == f.max_fila, "a fila aparece na janela")
		print("== save")
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		check(data.village.fornalhas.size() == 1 and data.village.fornalhas[0].fila.size() == f.max_fila, "save: fornalha com a fila")
		set_meta("pos", f.global_position)
		root.get_node("SaveManager").load_game()
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 2.0:
		var fs := get_nodes_in_group("fornalhas")
		check(fs.size() == 1 and fs[0].global_position == get_meta("pos") and fs[0].fila.fila.size() == fs[0].max_fila, "load: fornalha no lugar com as ordens")
		step = 99
	if step == 99:
		Engine.time_scale = 1.0
		print("\nFALHAS: %d" % fails)
		return true
	return false
