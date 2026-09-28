extends SceneTree
## Bloco 40: clima visual por estação. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var mech0 := []


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


func day_of(season: int) -> int:
	return 1 + season * g("sun").days_per_season


func levels(w) -> String:
	return "folhas %.2f  neve %.2f  chuva %.2f  pólen %.2f  geada %.2f" % [w.level("leaves"), w.level("snow"), w.level("rain"), w.level("pollen"), w.level("frost")]


func mech(sun) -> Array:
	var out := []
	for s in 4:
		out.append([sun.season_hunger_mult[s], sun.season_garden_mult[s], sun.season_day_mult[s], sun.season_night_mult[s], sun.season_wave_chance[s]])
	return out


## Um dia SECO da estação (sem pancada de chuva).
func dry_day(w, season: int) -> int:
	var d := day_of(season)
	for i in g("sun").days_per_season:
		if w.rain_window(d + i).x < 0.0:
			return d + i
	return d


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 300.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var w = g("weather")
	var dn = g("day_night")
	var sun = g("sun")
	if step == 0 and t > 2.0:
		mech0 = mech(sun)
		check(w != null and w.z_index > 0, "clima existe, desenhado por cima do mundo")
		check(not w.has_method("_input") and not w.has_method("_unhandled_input"), "clima não recebe clique")
		print("== outono")
		dn.day = dry_day(w, 2)
		w.snap()
		print("  ", sun.season_name(), ": ", levels(w))
		check(w.level("leaves") == 1.0 and w.level("snow") == 0.0 and w._fx.leaves.node.emitting, "outono: folhas caindo")
		print("== inverno")
		dn.day = day_of(3)
		w.snap()
		print("  ", sun.season_name(), ": ", levels(w))
		check(w.level("snow") == 1.0 and w.level("leaves") == 0.0 and w.level("frost") == 1.0, "inverno: neve + geada")
		check(w._fx.snow.node.amount > w._fx.leaves.node.amount * 3, "neve bem mais densa que folhas (%d x %d)" % [w._fx.snow.node.amount, w._fx.leaves.node.amount])
		check(w._fx.snow.node.texture != w._fx.leaves.node.texture, "desenho diferente das folhas")
		print("== verão")
		dn.day = dry_day(w, 1)
		w.snap()
		print("  ", sun.season_name(), ": ", levels(w))
		check(w.level("pollen") == 1.0 and w.level("leaves") == 0.0 and w.level("snow") == 0.0, "verão: só pólen de leve (%d partículas)" % w._fx.pollen.node.amount)
		print("== chuva")
		var rd := -1
		for d in range(day_of(0), day_of(0) + 40):
			if sun.season_index(d) == 0 and w.rain_window(d).x >= 0.0:
				rd = d
				break
		check(rd > 0, "achou um dia de primavera com chuva (dia %d)" % rd)
		var win: Vector2 = w.rain_window(rd)
		check(win == w.rain_window(rd), "a chuva do dia é sempre a mesma (%.2f..%.2f do ciclo)" % [win.x, win.y])
		dn.day = rd
		dn.time = (win.x + win.y) * 0.5 * dn.cycle_length()
		w.snap()
		print("  ", sun.season_name(), " dia %d: " % rd, levels(w))
		check(w.is_raining() and w.level("rain") == 1.0, "pancada de chuva no meio da janela")
		dn.time = (win.y + 0.02) * dn.cycle_length()
		check(not w.is_raining(), "depois da janela, parou de chover")
		print("== troca suave: outono -> inverno")
		dn.day = dry_day(w, 2)
		dn.time = 5.0
		w.snap()
		dn.day = day_of(3)
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 1.5:
		print("  1,5 s depois: ", levels(w))
		check(w.level("leaves") > 0.5 and w.level("leaves") < 1.0 and w.level("snow") > 0.0 and w.level("snow") < 0.5, "misturando: folhas somem, neve chega (sem corte)")
		step = 2
		t_mark = t
	elif step == 2 and t - t_mark > 10.0:
		print("  10 s depois: ", levels(w))
		check(w.level("leaves") == 0.0 and w.level("snow") == 1.0, "terminou a troca: só neve")
		check(str(mech(sun)) == str(mech0), "nenhum número de mecânica de estação mudou")
		dn.day = day_of(3)
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 0.6:
		print("  0,6 s depois do load: ", sun.season_name(), " — ", levels(w))
		check(sun.season_index() == 3 and w.level("snow") == 1.0 and w.level("frost") == 1.0, "save/load: neve na hora (sem esperar o fade)")
		check(w._fx.snow.node.emitting, "partículas já caindo")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
