extends SceneTree
## Bloco 31: engenheiro e obras. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var eng: Node2D
var hub: Node
var of: Node
var dig: Node
var casa: Node
var eco: Node
var workers_before := 0
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


func progress() -> Dictionary:
	return {"casa": casa.obra_progress(), "vila": hub.obra_progress(), "oficina": of.obra_progress(), "escav": dig.obra_progress()}


func fmt(p: Dictionary) -> String:
	return "casa %d%%  vila %d%%  oficina %d%%  escavadeira %d%%" % [roundi(p.casa * 100), roundi(p.vila * 100), roundi(p.oficina * 100), roundi(p.escav * 100)]


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 600.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = get_first_node_in_group("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 2.0:
		eco = main.get_node("Economy")
		hub = get_first_node_in_group("village_hub")
		of = get_first_node_in_group("oficina")
		dig = get_first_node_in_group("escavadeira")
		var arm = get_first_node_in_group("armazens")
		eco.credits = 99999
		for k in arm.stock:
			arm.stock[k] = 5000.0
		arm.wood_stored = 5000.0
		arm._recount()
		workers_before = eco.max_workers
		hub.level = 2  # a Escavadeira pede vila nível 2
		print("== encomendas (sem engenheiro)")
		# casa: primeiro lugar livre perto do Centro da Vila
		var placer = get_first_node_in_group("house_placer")
		var spot := Vector2.INF
		for r in range(1, 12):
			for a in range(12):
				var p: Vector2 = hub.global_position + Vector2.RIGHT.rotated(a * TAU / 12.0) * (60.0 + r * 30.0)
				placer._collect_blockers()
				if placer.check_spot(p) == "":
					spot = p
					break
			if spot != Vector2.INF:
				break
		var credits0: float = eco.credits
		check(hub._confirm_house(spot), "casa encomendada em %s" % spot)
		check(eco.credits < credits0, "cobrou ao encomendar (%d -> %d cr)" % [credits0, eco.credits])
		check(eco.max_workers == workers_before, "limite de ipezinhos NÃO subiu ainda (%d)" % eco.max_workers)
		for c in get_nodes_in_group("casas"):
			if c.has_method("obra_pending") and c.obra_pending():
				casa = c
		OS.delay_msec(20)
		check(hub.buy_upgrade("trilhas"), "melhoria Trilhas encomendada")
		check(hub.upgrades.trilhas == 0, "nível da melhoria ainda não subiu")
		OS.delay_msec(20)
		check(of.start_tool("picareta_aco"), "ferramenta encomendada na Oficina: '%s'" % of.tool_block_reason("picareta_aco"))
		OS.delay_msec(20)
		var ok_part: bool = dig.start_part("estrutura")
		check(ok_part, "peça encomendada na Escavadeira ('%s')" % dig.part_block_reason("estrutura"))
		step = 1
		t_mark = t
		snap = progress()
	elif step == 1 and t - t_mark > 8.0:
		var p := progress()
		print("  8 s sem engenheiro: ", fmt(p))
		check(p.casa == 0.0 and p.vila == 0.0 and p.oficina == 0.0 and p.escav == 0.0, "nada andou sem engenheiro")
		check("esperando engenheiro" in casa._sleep_label.text, "casa mostra: %s" % casa._sleep_label.text.replace("\n", " "))
		check("esperando engenheiro" in of._label.text, "oficina mostra: %s" % of._label.text.replace("\n", " "))
		var hud = main.get_node("HUD")
		hud._refresh()
		check(hud._obras_label.visible and "esperando engenheiro" in hud._obras_label.text, "HUD: %s" % hud._obras_label.text.replace("\n", " | "))
		print("== designa 1 engenheiro (fila: a encomenda mais antiga primeiro = casa)")
		eng = get_nodes_in_group("ipezinhos")[0]
		eng.set_job("engenheiro")
		check(eng._body.texture.resource_path.get_file().begins_with("ipezinho_engenheiro_"), "outfit de engenheiro")
		step = 2
		t_mark = t
	elif step == 2:
		if eng._obra_on_site and eng._obra == casa and casa.obra_progress() > 0.15:
			var p := progress()
			print("  ", eng.get_state_label(), "  |  ", fmt(p))
			check(p.vila == 0.0 and p.oficina == 0.0 and p.escav == 0.0, "um de cada vez: só a casa andou")
			check(eng._hand_item() == eng.HAMMER, "martelo na mão")
			snap = p
			eng.set_job("ocioso")
			step = 3
			t_mark = t
		elif t - t_mark > 90.0:
			check(false, "engenheiro não começou a casa em 90 s (%s)" % eng.get_state_label())
			step = 9
	elif step == 3 and t - t_mark > 5.0:
		var p := progress()
		check(absf(p.casa - snap.casa) < 0.001, "tirou o engenheiro: casa PAUSOU em %d%%" % roundi(p.casa * 100))
		check(casa.obra_workers().is_empty(), "ninguém mais na obra")
		# salva no meio, carrega, e confere
		var sm = root.get_node("SaveManager")
		check(sm.save_game("teste"), "salvou com 4 obras pendentes")
		set_meta("p", p)
		sm.load_game()
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 2.0:
		hub = get_first_node_in_group("village_hub")
		of = get_first_node_in_group("oficina")
		dig = get_first_node_in_group("escavadeira")
		eco = main.get_node("Economy") if is_instance_valid(main) else null
		casa = null
		for c in get_nodes_in_group("casas"):
			if c.has_method("obra_pending") and c.obra_pending():
				casa = c
		var before: Dictionary = get_meta("p")
		check(casa != null, "casa em obra voltou do save")
		if casa:
			var p := progress()
			print("  depois de carregar: ", fmt(p))
			check(absf(p.casa - before.casa) < 0.01, "casa voltou com o mesmo progresso (%d%%)" % roundi(p.casa * 100))
			check(hub.pending_upgrade == "trilhas", "melhoria da Vila continua encomendada")
			check(of.crafting == "picareta_aco", "ferramenta continua encomendada")
			check(dig.fabricating == "estrutura", "peça da Escavadeira continua encomendada")
		# engenheiro de novo: termina a casa (acelera o tempo do teste)
		var ws := get_nodes_in_group("ipezinhos")
		eng = ws[0]
		eng.set_job("engenheiro")
		ws[1].set_job("engenheiro")  # 2 engenheiros: cada um pega uma obra diferente
		Engine.time_scale = 4.0
		set_meta("pair_checked", false)
		step = 5
		t_mark = t
	elif step == 5:
		var eco2 = get_first_node_in_group("economy")
		var ws2 := get_nodes_in_group("ipezinhos")
		if not get_meta("pair_checked") and ws2[0]._obra != null and ws2[1]._obra != null:
			set_meta("pair_checked", true)
			check(ws2[0]._obra != ws2[1]._obra, "2 engenheiros: cada um numa obra (%s / %s)" % [ws2[0]._obra.obra_title(), ws2[1]._obra.obra_title()])
		if casa and casa.built:
			Engine.time_scale = 1.0
			check(eco2.max_workers == workers_before + 4, "casa pronta: limite de ipezinhos subiu SÓ AGORA (%d)" % eco2.max_workers)
			var ws := get_nodes_in_group("ipezinhos")
			var sites := [ws[0]._obra, ws[1]._obra]
			print("  engenheiros agora em: %s / %s" % [ws[0].get_state_label(), ws[1].get_state_label()])
			step = 9
		elif t - t_mark > 120.0:
			Engine.time_scale = 1.0
			check(false, "casa não ficou pronta (%s, %d%%)" % [get_nodes_in_group("ipezinhos")[0].get_state_label(), roundi(casa.obra_progress() * 100) if casa else -1])
			step = 9
	if step == 9:
		print("\nFALHAS: %d" % fails)
		return true
	return false
