extends SceneTree
## Bloco 41: Parque. RODAR SÓ COM APPDATA ISOLADO.
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


## Congela dois ipezinhos (um no raio do parque, outro longe) só com o parque mexendo no ânimo.
func freeze(w, pos: Vector2) -> void:
	w.auto_mode = false
	w._moving = false
	w.global_position = pos
	w.happiness_drift = 0.0
	w.happiness = 40.0


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
	var mor = g("morale")
	var eco = main.get_node("Economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	if step == 0 and t > 2.0:
		print("== construir")
		set_meta("tav", [mor.taverna_credits, mor.taverna_wood, mor.taverna_bonus.duplicate(), mor.taverna_build_time])
		eco.credits = 1000.0
		arm.stock["ferro"] = 200.0
		arm.wood_stored = 200.0
		arm._recount()
		var hud = main.get_node("HUD")
		hud.open_panel("moral")
		hud._panels["moral"].refresh()
		print("  botão: ", hud._panels["moral"]._park_button.text)
		check("Construir parque" in hud._panels["moral"]._park_button.text and "100 cr" in hud._panels["moral"]._park_button.text, "parque aparece como construção, com custo")
		check(mor.build_park(), "escolher lugar do parque")
		var placer = g("house_placer")
		# (Prompt 29: o raio das casas está desligado — parque em qualquer lugar da pedreira também)
		check(placer._radius == hub.house_radius() and (placer._radius == 0.0 or placer._radius_center == hub.global_position), "segue o raio das casas (%d px do Centro; 0 = sem raio)" % placer._radius)
		var q := spot_near(hub.global_position, 110.0, maxf(hub.house_radius(), 400.0) - 5.0)  # (Prompt 29: sem raio)
		placer.move_to(q)
		var c0: float = eco.credits
		var f0: float = arm.stock["ferro"]
		var w0: float = arm.wood_stored
		check(placer.try_confirm(), "parque encomendado em %s" % q)
		# Bloco 96: ferro e madeira ficam reservados no armazém (o engenheiro leva): o livre cai
		check(eco.credits == c0 - mor.park_credits and is_equal_approx(eco.livre("ferro"), f0 - mor.park_ore) and is_equal_approx(eco.livre("madeira"), w0 - mor.park_wood),
			"gastou %d cr + %d ferro + %d madeira" % [mor.park_credits, mor.park_ore, mor.park_wood])
		check(mor.parks().is_empty() and g("canteiros") != null, "ainda é canteiro")
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
		if not mor.parks().is_empty():
			Engine.time_scale = 1.0
			var p = mor.parks()[0]
			check(p.global_position == get_meta("pos"), "engenheiro ergueu o parque no lugar")
			print("== ânimo passivo")
			var ws := get_nodes_in_group("ipezinhos")
			freeze(ws[1], p.global_position + Vector2(40, 10))
			freeze(ws[2], p.global_position + Vector2(mor.park_radius + 200.0, 0))
			step = 25
		elif t - t_mark > 300.0:
			check(false, "parque não ficou pronto")
			step = 99
	elif step == 25:
		# (Prompt 29) um quadro depois: o quadro em que o parque nasce é longo (refaz a navegação)
		# e ainda corria a 8×; a medição começa limpa daqui
		for w in get_nodes_in_group("ipezinhos").slice(1, 3):
			w.happiness = 40.0
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 4.0:
		var ws := get_nodes_in_group("ipezinhos")
		var near: float = ws[1].happiness
		var far: float = ws[2].happiness
		print("  perto: 40 -> %.2f   longe: 40 -> %.2f   (%.1f s, taxa %.2f/s)" % [near, far, t - t_mark, mor.park_rate])
		check(near > 41.0 and absf(near - (40.0 + mor.park_rate * (t - t_mark))) < 0.3, "perto do parque ganha ânimo na taxa")
		check(far == 40.0, "fora do raio não ganha")
		mor.park_cap = 41.0
		ws[1].happiness = 40.9
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 2.0:
		var ws := get_nodes_in_group("ipezinhos")
		check(ws[1].happiness <= 41.0 + 0.001, "respeita o teto (%.2f <= %.0f)" % [ws[1].happiness, mor.park_cap])
		mor.park_cap = 100.0
		var tav: Array = get_meta("tav")
		check(tav[0] == mor.taverna_credits and tav[1] == mor.taverna_wood and str(tav[2]) == str(mor.taverna_bonus) and tav[3] == mor.taverna_build_time, "taverna continua igual")
		check(mor.taverna_block_reason() == "", "taverna segue construível como antes")
		# segundo parque + save/load
		# (Prompt 29) o lugar sai do posicionador DO PARQUE aberto (pegada do desenho novo e os
		# bloqueios de agora, com o 1º parque); antes usava a pegada e os bloqueios que tinham ficado
		var plc = g("house_placer")
		plc.begin(func(_q): return false, mor.PARQUE_TEXTURE, 1, "o parque", {})
		var q2 := spot_near(hub.global_position + Vector2(0, 0), 150.0, maxf(hub.house_radius(), 400.0) - 5.0)
		plc.cancel()
		var p2 = mor.spawn_park(q2)
		set_meta("both", [mor.parks()[0].global_position, p2.global_position])
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 2.0:
		var ps: Array = mor.parks().map(func(p): return p.global_position)
		var both: Array = get_meta("both")
		print("  parques depois do load: ", ps)
		check(ps.size() == 2 and ps.has(both[0]) and ps.has(both[1]), "save/load: os 2 parques no lugar")
		var w = get_nodes_in_group("ipezinhos")[1]
		freeze(w, both[1] + Vector2(20, 20))
		step = 6
		t_mark = t
	elif step == 6 and t - t_mark > 3.0:
		var w = get_nodes_in_group("ipezinhos")[1]
		check(w.happiness > 40.8, "save/load: continua alegrando (40 -> %.2f)" % w.happiness)
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
