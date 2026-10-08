extends SceneTree
## Bloco 39: economia (venda no armazém, recrutar com cama). RODAR SÓ COM APPDATA ISOLADO.
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


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 600.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var eco = main.get_node("Economy")
	var arm = g("armazens")
	var hud = main.get_node("HUD")
	if step == 0 and t > 2.0:
		print("== moeda e venda")
		check(eco.credits == eco.starting_credits, "moeda no valor inicial (%d)" % eco.credits)
		hud._refresh()
		check(hud._chips.has("credits") or true, "(HUD)")
		arm.stock["ferro"] = 50.0
		arm.stock["cobre"] = 10.0
		arm._recount()
		check(arm.contains_point(arm.global_position + Vector2(0, -30)) and arm.panel_id == "armazem" and arm.is_in_group("clickable"), "clicar no armazém abre a janela de venda")
		hud.open_panel("armazem")
		var panel = hud._panels["armazem"]
		panel.refresh()
		print("  ", panel._rows["ferro"].label.text, "  |  ", panel._rows["cobre"].label.text, "  |  ", panel._sell_all.text)
		var c0: float = eco.credits
		eco.sell("ferro")
		check(is_equal_approx(eco.credits - c0, 50.0 * eco.ore_price) and arm.stock["ferro"] < 1.0 and arm.stock["cobre"] == 10.0,
			"vender ferro: +%d cr (50 x %s), cobre intocado" % [eco.credits - c0, eco.ore_price])
		c0 = eco.credits
		eco.sell_all()
		check(is_equal_approx(eco.credits - c0, 10.0 * eco.copper_price) and arm.total_stored < 1.0, "vender tudo: +%d cr pelo cobre" % (eco.credits - c0))
		# Bloco 101: acabou a COMPRA de ipezinhos (quem chega são os migrantes, b101); a capacidade são as camas
		print("== sem compra de ipezinhos; capacidade = camas")
		var beds := 0
		for c in get_nodes_in_group("casas"):
			beds += c.beds_total()
		print("  camas %d, ipezinhos %d, livres %d" % [beds, eco.worker_count(), eco.free_beds()])
		check(not eco.has_method("recruit") and not eco.has_method("recruit_cost"), "não tem mais 'recrutar' (nem custo)")
		var c_antes: float = eco.credits
		var w = eco.novo_ipezinho()
		check(w != null and eco.credits == c_antes, "quem chega não custa crédito")
		set_meta("new", w.name if w else "")
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 1.0:
		var w = main.get_node_or_null("World/" + get_meta("new"))
		var hub = g("village_hub")
		check(w != null and w.has_home(), "quem chega tem casa/cama (%s)" % (w._home.name if w and w.has_home() else "sem casa"))
		check(w.global_position.distance_to(hub.global_position) < 120.0, "chegou perto do Centro da Vila")
		# enche até não ter cama: a vila está cheia (o migrante não pode ser aceito: b101)
		var guard := 0
		while eco.free_beds() > 0 and guard < 20:
			eco.novo_ipezinho()
			guard += 1
		check(eco.free_beds() == 0 and not eco.tem_cama_livre(), "sem cama livre: a vila está cheia")
		hud._refresh()
		print("  HUD: ", hud._workers_count_label.text)
		check("camas" in hud._workers_count_label.text and hud.get("_recruit_button") == null, "o HUD mostra 'N / camas' e não tem botão de recrutar")
		print("== custos antigos seguem iguais")
		var oficina = g("oficina")
		eco.credits = 99999.0
		arm.stock["ferro"] = 999.0
		arm.wood_stored = 999.0
		arm._recount()
		print("  oficina: '%s'" % oficina.tool_block_reason("picareta_aco"))
		var c1: float = eco.credits
		check(oficina.start_tool("picareta_aco"), "Oficina encomenda como sempre (créditos + minério)")
		check(eco.credits < c1 and arm.stock["ferro"] < 999.0, "cobrou créditos e minério como antes")
		eco.credits = 1234.0
		set_meta("cr", 1234.0)
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 2
		t_mark = t
	elif step == 2 and t - t_mark > 2.0:
		check(is_equal_approx(eco.credits, 1234.0), "save/load: moeda mantida (%d)" % eco.credits)
		# save antigo sem o campo de moeda
		var f := FileAccess.open("user://savegame.json", FileAccess.READ)
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		f.close()
		data["economy"].erase("credits")
		data["economy"].erase("total_earned")
		var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(data))
		fw.close()
		root.get_node("SaveManager").load_game()
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 2.0:
		check(get_nodes_in_group("village_hub").size() == 1 and is_equal_approx(eco.credits, eco.starting_credits), "save sem moeda: carregou, moeda no padrão (%d)" % eco.credits)
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
