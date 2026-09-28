extends SceneTree
## Bloco 44: Vestiário como prédio físico. RODAR SÓ COM APPDATA ISOLADO.
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


func spot_near(c: Vector2, r0: float, r1: float) -> Vector2:
	var p = g("house_placer")
	var r := r0
	while r <= r1:
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
		r += 14.0
	return Vector2.INF


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 600.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	var eq = g("equipment")
	var eco = main.get_node("Economy")
	var arm = g("armazens")
	if step == 0 and t > 2.0:
		print("== Passo 0: quem já é prédio")
		check(g("oficina") != null and g("oficina").is_in_group("clickable") and g("oficina").panel_id == "oficina", "Oficina já é prédio clicável (janela da Oficina)")
		check(g("defense").has_method("build_arsenal") and g("research").has_method("build_lab"), "Arsenal e Laboratório já são construíveis")
		check(eq.vestiario() == null, "partida nova: sem Vestiário")
		print("== sem Vestiário: bloqueado com aviso")
		eco.credits = 99999.0
		arm.stock["ferro"] = 900.0
		arm.wood_stored = 900.0
		arm.leather_stored = 50.0
		arm._recount()
		print("  fazer casaco: '%s'" % eq.order_block_reason("casaco"))
		check(eq.order_block_reason("casaco").begins_with("precisa do Vestiário"), "fazer casaco bloqueado sem Vestiário")
		check(not eq.order("casaco") and eq.queue.is_empty(), "encomenda não entra (sem crash)")
		eq.pool.casaco = [240.0]
		check(eq.take("casaco") < 0.0 and eq.available("casaco") == 1, "sem Vestiário ninguém pega casaco (o guardado continua contado)")
		var w = get_nodes_in_group("ipezinhos")[1]
		check(not w.can_enter_hazard("gas"), "zona de perigo fechada sem Vestiário")
		print("== construir")
		var hud = main.get_node("HUD")
		hud.open_panel("oficina")
		hud._panels["oficina"].refresh()
		var btn: String = hud._panels["oficina"]._vest_button.text
		print("  botão: ", btn)
		check(hud._panels["oficina"]._vest_button.visible and "120 cr" in btn, "Vestiário aparece como construção com custo")
		check(eq.build_vestiario(), "escolher lugar")
		var q := spot_near(g("village_hub").global_position, 120.0, 400.0)
		var placer = g("house_placer")
		placer.move_to(q)
		var c0: float = eco.credits
		var f0: float = arm.stock["ferro"]
		var w0: float = arm.wood_stored
		check(placer.try_confirm(), "Vestiário encomendado em %s" % q)
		check(eco.credits == c0 - eq.vestiario_credits and arm.stock["ferro"] == f0 - eq.vestiario_ore and arm.wood_stored == w0 - eq.vestiario_wood,
			"gastou %d cr + %d ferro + %d madeira" % [eq.vestiario_credits, eq.vestiario_ore, eq.vestiario_wood])
		check(eq.vestiario() == null and g("canteiros") != null, "ainda é canteiro")
		set_meta("pos", q)
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 3.0:
		check(g("canteiros").obra_progress() == 0.0, "sem engenheiro não anda")
		get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 2
		t_mark = t
	elif step == 2:
		if eq.vestiario() != null:
			Engine.time_scale = 1.0
			var v = eq.vestiario()
			check(v.global_position == get_meta("pos"), "engenheiro ergueu o Vestiário no lugar")
			check(v.is_in_group("clickable") and v.panel_id == "oficina" and v.contains_point(v.global_position + Vector2(0, -30)), "clicar nele abre a janela da Oficina")
			var hud = main.get_node("HUD")
			hud.open_panel(v.panel_id)
			check(hud._panels["oficina"].visible, "janela da Oficina abriu")
			check(eq.order_block_reason("casaco") == "", "com Vestiário: fazer casaco liberado")
			check(eq.take("casaco") > 0.0, "com Vestiário: pega o casaco que estava guardado")
			get_nodes_in_group("ipezinhos")[0].set_job("ocioso")
			root.get_node("SaveManager").save_game("teste")
			root.get_node("SaveManager").load_game()
			step = 3
			t_mark = t
		elif t - t_mark > 300.0:
			check(false, "Vestiário não ficou pronto")
			step = 99
	elif step == 3 and t - t_mark > 1.5:
		var v = eq.vestiario()
		check(v != null and v.global_position == get_meta("pos") and get_nodes_in_group("vestiarios").size() == 1, "save/load: Vestiário no mesmo lugar (um só)")
		check(eq.order_block_reason("casaco") == "", "save/load: continua funcionando")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
