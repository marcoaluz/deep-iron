extends SceneTree
## Bloco 35: Arsenal + desgaste. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var dur_log: Array = []
var hits_before := 0.0


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


func guard() -> Node:
	return get_nodes_in_group("ipezinhos")[0]


func eng() -> Node:
	return get_nodes_in_group("ipezinhos")[1]


func free_spot(near: Vector2) -> Vector2:
	var placer = g("house_placer")
	placer._collect_blockers()
	for r in range(1, 16):
		for a in range(16):
			var p: Vector2 = near + Vector2.RIGHT.rotated(a * TAU / 16.0) * (60.0 + r * 28.0)
			if placer.check_spot(p) == "":
				return p
	return Vector2.INF


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 1500.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	var def = g("defense")
	var gd := guard()
	if step < 6 and dn:
		dn.time = 20.0  # dia
	if step == 0 and t > 2.0:
		print("== guarda novo e Arsenal")
		var eco = main.get_node("Economy")
		eco.credits = 999999
		var arm = g("armazens")
		for k in arm.stock:
			arm.stock[k] = 9000.0
		arm.wood_stored = 9000.0
		arm._recount()
		gd.guard_base_hp = 99999.0  # o teste é da arma, não de machucar
		gd.combat_skill = 1.0
		gd.set_job("guarda")
		check(gd.weapon == "porrete" and gd.weapon_durability == def.weapon_max_durability("porrete"), "virou guarda: porrete de casa (%s)" % gd.weapon_label())
		check(gd._hand_item() == gd.PORRETE, "na mão: porrete")
		check(def.weapon_block_reason("lanca") == "precisa do Arsenal", "forjar sem Arsenal: '%s'" % def.weapon_block_reason("lanca"))
		check(def.build_arsenal(), "Arsenal abre o posicionador (jogador escolhe o lugar)")
		check(g("house_placer").active, "posicionador ativo")
		g("house_placer").cancel()
		var spot := free_spot(g("village_hub").global_position)
		var c0: float = eco.credits
		check(def._confirm_arsenal(spot), "Arsenal encomendado em %s" % spot)
		check(eco.credits == c0 - def.arsenal_credits, "cobrou %d cr" % def.arsenal_credits)
		check(def.arsenal() == null and def.arsenal_block_reason().begins_with("em obra"), "ainda é canteiro: %s" % def.arsenal_block_reason())
		set_meta("spot", spot)
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 4.0:
		var cant = g("canteiros")
		check(cant != null and cant.obra_progress() == 0.0, "sem engenheiro: canteiro parado")
		eng().set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 2
		t_mark = t
	elif step == 2:
		if def.arsenal() != null:
			Engine.time_scale = 1.0
			var a = def.arsenal()
			check(a.global_position.distance_to(get_meta("spot")) < 1.0, "Arsenal pronto no lugar escolhido")
			var map: RID = gd._agent.get_navigation_map()
			var path: PackedVector2Array = NavigationServer2D.map_get_path(map, gd.global_position, a.get_slot_position(0), true)
			check(path.size() > 0 and path[path.size() - 1].distance_to(a.get_slot_position(0)) < 20.0, "navegação chega no Arsenal")
			eng().set_job("ocioso")
			check(def.start_forge("lanca"), "forja da lança encomendada")
			step = 3
			t_mark = t
		elif t - t_mark > 300.0:
			check(false, "Arsenal não ficou pronto")
			step = 99
	elif step == 3 and t - t_mark > 4.0:
		check(def.forge_progress() == 0.0, "sem engenheiro a forja não anda (%d%%)" % roundi(def.forge_progress() * 100))
		print("  arsenal: ", def.arsenal()._label.text.replace("\n", " | "))
		eng().set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 4
		t_mark = t
	elif step == 4:
		if def.rack_count("lanca") > 0 or gd.weapon == "lanca":
			check(def.weapons.has("lanca"), "lança forjada (receita conhecida)")
			step = 5
			t_mark = t
		elif t - t_mark > 300.0:
			check(false, "lança não ficou pronta (%s)" % def.forge_title())
			step = 99
	elif step == 5:
		# de dia, o guarda com porrete vai buscar a lança
		if gd.weapon == "lanca":
			Engine.time_scale = 1.0
			check(def.rack_count("lanca") == 0, "pegou a lança do cavalete (%s)" % gd.weapon_label())
			check(gd._hand_item() == gd.LANCA, "na mão: lança")
			check(def.broken_total() == 0, "porrete usado não vai pra pilha de conserto")
			# prepara a noite: durabilidade baixa + uma besta no cavalete
			gd.weapon_durability = 3.0
			step = 6
			t_mark = t
		elif t - t_mark > 200.0:
			check(false, "guarda não foi buscar a lança (%s)" % gd.get_state_label())
			step = 99
	elif step == 6:
		print("== invasão")
		eng().set_job("ocioso")
		dn.time = dn.day_duration + 5.0  # noite
		def.start_invasion()
		def.rack["besta"] = 1  # de noite, armado, ele NAO sai do posto pra trocar
		Engine.time_scale = 4.0
		step = 7
		t_mark = t
	elif step == 7:
		dn.time = dn.day_duration + 5.0
		if dur_log.is_empty() or dur_log[-1] != gd.weapon_durability:
			dur_log.append(gd.weapon_durability)
		if gd.weapon == "" and gd.broken_weapon == "lanca":
			print("  durabilidade: ", dur_log)
			check(dur_log.size() >= 4 and dur_log[0] == 3.0, "cada golpe gastou 1 (3 -> 0)")
			check(gd._hand_item() == null and gd._broken_icon.visible, "quebrou: mãos vazias + ícone de arma quebrada")
			var hud = main.get_node("HUD")
			hud._refresh()
			check(hud._unarmed_label.visible, "HUD avisa: %s" % hud._unarmed_label.text)
			step = 8
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "a lança não quebrou (dur %s, estado %s)" % [gd.weapon_durability, gd.get_state_label()])
			step = 99
	elif step == 8:
		dn.time = dn.day_duration + 5.0
		if gd.weapon != "":
			print("  depois do Arsenal: ", gd.weapon_label(), "  estado: ", gd.get_state_label())
			check(gd.weapon == "besta" and gd.weapon_durability == def.weapon_max_durability("besta"), "pegou a besta do cavalete, inteira")
			check(def.broken_count("lanca") == 1, "a lança quebrada ficou na pilha de conserto")
			check(gd._hand_item() == gd.BESTA, "na mão: besta")
			step = 9
			t_mark = t
		elif gd.get_state() == "rearming" and not has_meta("saw_rearm"):
			set_meta("saw_rearm", true)
			print("  ", gd.display_name, ": ", gd.get_state_label(), " (de noite, no meio da invasão)")
		elif t - t_mark > 300.0:
			check(false, "guarda desarmado não re-equipou (%s)" % gd.get_state_label())
			step = 99
	elif step == 9:
		Engine.time_scale = 1.0
		def.end_invasion()
		dn.time = 20.0
		print("== conserto")
		var eco = main.get_node("Economy")
		var c0: float = eco.credits
		var rc: Vector3i = def.repair_cost("lanca")
		check(rc.x < def.weapon_cost("lanca").x, "consertar é mais barato (%s vs %s)" % [rc, def.weapon_cost("lanca")])
		check(def.start_repair("lanca"), "conserto encomendado")
		check(eco.credits == c0 - rc.x and def.broken_count("lanca") == 0, "cobrou %d cr e tirou da pilha" % rc.x)
		check(absf(float(def.queue[0].total) - def.weapon_time[1] * def.repair_time_mult) < 0.01, "leva metade do tempo (%.0fs)" % float(def.queue[0].total))
		check(def.start_forge("besta"), "forja da besta na fila também")
		gd.weapon_durability = 20.0
		var sm = root.get_node("SaveManager")
		set_meta("before", [gd.weapon, gd.weapon_durability, def.rack.duplicate(), def.broken.duplicate(), def.queue.size(), def.forge_title()])
		check(sm.save_game("teste"), "salvou")
		gd.weapon = "porrete"
		gd.weapon_durability = 1.0
		def.rack = {}
		def.queue = []
		sm.load_game()
		step = 10
		t_mark = t
	elif step == 10 and t - t_mark > 2.0:
		gd = guard()
		var now := [gd.weapon, gd.weapon_durability, def.rack.duplicate(), def.broken.duplicate(), def.queue.size(), def.forge_title()]
		print("  antes:  ", get_meta("before"))
		print("  depois: ", now)
		check(str(now) == str(get_meta("before")), "save/load: arma, durabilidade, cavalete, pilha e fila iguais")
		check(def.arsenal() != null and def.arsenal().global_position.distance_to(get_meta("spot")) < 1.0, "save/load: Arsenal no mesmo lugar")
		# save antigo (versão 3): guarda sem arma salva, forja andando sozinha
		print("== save antigo")
		var f := FileAccess.open("user://savegame.json", FileAccess.READ)
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		f.close()
		data["save_version"] = 3
		data["defense"] = {"weapons": ["porrete", "lanca"], "forging": "besta", "forge_left": 12.0, "wave": 2, "warned_day": -1, "start_day": 1}
		for wd in data["workers"]:
			for k in ["weapon", "weapon_durability", "broken_weapon", "got_porrete"]:
				wd.erase(k)
		var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(data))
		fw.close()
		def.arsenal().queue_free()
		root.get_node("SaveManager").load_game()
		step = 11
		t_mark = t
	elif step == 11 and t - t_mark > 2.0:
		gd = guard()
		print("  guarda: ", gd.weapon_label(), "  fila: ", def.forge_title(), " left ", def.queue[0].left if not def.queue.is_empty() else -1)
		check(gd.weapon == "lanca" and gd.weapon_durability == def.weapon_max_durability("lanca"), "save antigo: guarda com a melhor arma que tinha, inteira")
		check(def.queue.size() == 1 and def.queue[0].id == "besta" and absf(float(def.queue[0].left) - 12.0) < 0.01, "save antigo: forja em andamento virou encomenda na fila")
		check(eng().job != "guarda" and eng().weapon == "", "não-guarda continua sem arma")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
