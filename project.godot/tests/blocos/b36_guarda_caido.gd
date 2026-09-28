extends SceneTree
## Bloco 36: guarda caído + roubo pela brecha. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var ore0 := 0.0
var cr0 := 0.0
var fall_pos := Vector2.ZERO
var care_mark := 0.0


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


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func find(nm: String) -> Node:
	for w in ws():
		if w.display_name == nm:
			return w
	return null


func arm_ore() -> float:
	var a = g("armazens")
	var s := 0.0
	for k in a.stock:
		s += a.stock[k]
	return s


func kill_all() -> void:
	for c in get_nodes_in_group("criaturas"):
		if c.is_alive():
			c.die(false)


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 1500.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	var def = g("defense")
	for w in ws():
		w.hunger = w.hunger_max
	if dn and step >= 1:
		dn.time = dn.day_duration + 5.0  # noite o tempo todo
	if step == 0 and t > 2.0:
		print("== guarda perde a luta")
		var gd = ws()[0]
		set_meta("guard", gd.display_name)
		gd.set_job("guarda")
		gd.combat_skill = 1.0
		gd.guard_base_hp = 1.0  # cai no primeiro golpe
		gd.guard_hp_per_skill = 0.0
		for w in ws().slice(1):
			w.set_job("minerador")
		var arm = g("armazens")
		arm.stock["ferro"] = 400.0
		arm.stock["cobre"] = 100.0
		arm._recount()
		main.get_node("Economy").credits = 1000.0
		ore0 = arm_ore()
		cr0 = main.get_node("Economy").credits
		dn.time = dn.day_duration + 5.0
		def.start_invasion()
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1:
		var gd = find(get_meta("guard"))
		if gd.downed:
			fall_pos = gd.global_position
			print("  %s caiu em %s — %s" % [gd.display_name, fall_pos.round(), gd.get_state_label()])
			check(gd.injured and gd.injury_severity == "grave", "caiu GRAVE")
			check(gd.downed_gate == "tunel", "brecha no portão do túnel")
			check(def.breached("tunel"), "portão do túnel aberto pra saque")
			var hud = main.get_node("HUD")
			hud._refresh()
			check(hud._downed_label.visible and "SEM MÉDICO" in hud._downed_label.text, "HUD: %s" % hud._downed_label.text)
			care_mark = gd._care_left
			step = 2
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "guarda não caiu (%s)" % gd.get_state_label())
			step = 99
	elif step == 2:
		var gd = find(get_meta("guard"))
		if gd.global_position.distance_to(fall_pos) > 2.0:
			check(false, "o caído se mexeu sozinho (%s)" % gd.global_position.round())
			step = 99
			return false
		var eco = main.get_node("Economy")
		if eco.credits < cr0:
			var ore_lost := ore0 - arm_ore()
			var cr_lost: float = cr0 - eco.credits
			print("  ROUBO: -%.0f minério (de %.0f)  -%.0f cr (de %.0f)" % [ore_lost, ore0, cr_lost, cr0])
			check(absf(cr_lost - floorf(cr0 * def.raid_credit_percent)) < 1.0, "levou %d%% dos créditos" % roundi(def.raid_credit_percent * 100))
			check(ore_lost >= floorf(ore0 * def.raid_ore_percent) - 2.0, "levou ~%d%% do minério" % roundi(def.raid_ore_percent * 100))
			check(not def.breached("tunel"), "uma vez só por portão nesta invasão")
			check(gd.global_position.distance_to(fall_pos) < 1.0 and gd.downed and gd._carried_by == null, "ninguém (sem médico) tirou ele de lá")
			check(gd._care_left < care_mark, "relógio correndo no chão (%.0f -> %.0f)" % [care_mark, gd._care_left])
			set_meta("cr_after", eco.credits)
			step = 3
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "não houve roubo (%s)" % gd.get_state_label())
			step = 99
	elif step == 3 and t - t_mark > 20.0:
		var eco = main.get_node("Economy")
		check(eco.credits == get_meta("cr_after"), "não roubou de novo pela mesma brecha")
		kill_all()
		Engine.time_scale = 1.0
		var gd = find(get_meta("guard"))
		set_meta("before", [gd.global_position.round(), gd.injury_severity, snappedf(gd._care_left, 1.0), gd.downed_gate])
		var sm = root.get_node("SaveManager")
		check(sm.save_game("teste"), "salvou com o guarda caído (no meio da invasão)")
		gd.global_position += Vector2(100, 0)
		sm.load_game()
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 1.5:
		kill_all()
		var gd = find(get_meta("guard"))
		var now := [gd.global_position.round(), gd.injury_severity, snappedf(gd._care_left, 1.0), gd.downed_gate]
		print("  antes:  ", get_meta("before"), "\n  depois: ", now, "  ", gd.get_state_label())
		check(gd.downed and now[0] == get_meta("before")[0] and now[1] == "grave" and now[3] == "tunel" and absf(now[2] - get_meta("before")[2]) <= 3.0,
			"save/load: caído no mesmo lugar, grave, relógio e portão iguais")
		Engine.time_scale = 1.0
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 3.0:
		var gd = find(get_meta("guard"))
		check(gd.downed and gd.global_position.round() == get_meta("before")[0], "depois do load continua caído, parado")
		print("== médico designado (de noite)")
		var doc: Node = null
		for w in ws():
			if w != gd:
				doc = w
				break
		set_meta("doc", doc.display_name)
		doc.set_job("médico")
		Engine.time_scale = 4.0
		step = 6
		t_mark = t
	elif step == 6:
		kill_all()
		var gd = find(get_meta("guard"))
		var doc = find(get_meta("doc"))
		if gd._carried_by != null and not has_meta("carry_seen"):
			set_meta("carry_seen", true)
			set_meta("care_carry", gd._care_left)
			print("  ", doc.display_name, ": ", doc.get_state_label(), "   |   ", gd.display_name, ": ", gd.get_state_label())
			check(doc.carrying_patient == gd and gd._carried_by == doc, "o MÉDICO pôs nas costas")
		if has_meta("carry_seen") and gd._carried_by != null:
			if gd.global_position.distance_to(doc.global_position) > 3.0:
				check(false, "carregado não acompanha o médico")
				step = 99
		if not gd.downed:
			print("  entregue: ", gd.get_state_label(), "  em ", gd.global_position.round())
			check(has_meta("carry_seen"), "foi carregado (não andou sozinho)")
			check(absf(gd._care_left - maxf(get_meta("care_carry"), gd.grave_untreated_time)) < 5.0 or gd._admitted, "relógio pausou nas costas do médico")
			check(gd.injured and (gd._admitted or gd.get_state() == "idle" or gd.get_state() == "infirmary"), "chegou na enfermaria (%s)" % gd.get_state_label())
			step = 7
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "médico não resgatou (médico: %s)" % doc.get_state_label())
			step = 99
	elif step == 7 and t - t_mark > 3.0:
		var gd = find(get_meta("guard"))
		check(gd._admitted, "deitou no leito (%s)" % gd.get_state_label())
		print("== sem resgate: morre")
		Engine.time_scale = 1.0
		var other: Node = null
		for w in ws():
			if w.display_name != get_meta("doc") and w != gd:
				other = w
		other.set_job("guarda")
		set_meta("dead", other.display_name)
		find(get_meta("doc")).set_job("minerador")  # sem médico
		other._fall_in_combat("lumivoro")
		other._care_left = 4.0
		step = 8
		t_mark = t
	elif step == 8:
		if find(get_meta("dead")) == null:
			var mem: Array = g("enfermarias").memorial
			check(not mem.is_empty() and mem[-1].name == get_meta("dead"), "sem resgate, o relógio zerou e ele morreu (memorial: %s)" % (mem[-1].name if not mem.is_empty() else "?"))
			step = 99
		elif t - t_mark > 20.0:
			check(false, "caído sem resgate não morreu")
			step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
