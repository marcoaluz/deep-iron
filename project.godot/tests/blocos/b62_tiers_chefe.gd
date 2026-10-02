extends SceneTree
## Bloco 62: tiers das ondas (onda e pesquisas), elite, e o chefe (Matriarca): vem uma vez por
## estação a partir da configurada, grita e chama Lumívoros, corrói a arma do guarda, pode ser
## derrubada (recompensa) ou fugir ao amanhecer; persiste no save; telemetria registra; sem
## softlock com todos os guardas caídos. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var chefe: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return current_scene.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 120.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_tiers()
				_chefe_vem()
				step = 1
				t_mark = t
		1:
			chefe = null
			for c in main.get_tree().get_nodes_in_group("chefes"):
				chefe = c
			if chefe != null:
				_chefe_luta()
				step = 2
				t_mark = t
			elif t - t_mark > 30.0:
				check(false, "a Matriarca nasceu na invasão")
				step = 2
		2:
			if t - t_mark > 12.0:
				_grito_e_morte()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 2.0:
				_fuga_e_save()
				step = 4
				t_mark = t
		4:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 5
				t_mark = t
		5:
			if t - t_mark > 3.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _tiers() -> void:
	print("== tiers")
	var d = g("defense")
	var res = g("research")
	d.wave = 0
	var t1: int = d.tier()
	d.wave = d.tier_every_waves * 2
	var t2: int = d.tier()
	check(t1 == 1 and t2 == 3, "tier sobe com a onda (%d -> %d)" % [t1, t2])
	for id in res.ORDER.slice(0, d.tier_research_step):
		res._finish(id)
	check(d.tier() == t2 + 1, "e com as pesquisas feitas (%d)" % d.tier())
	# elite: o forte nas ondas de tier alto
	var c: Node2D = d._spawn("lumivoro")
	c.make_strong(d.strong_hp_mult, d.strong_damage_mult)
	var hp_forte: float = c.max_hp
	c.make_elite(d.elite_hp_mult, d.elite_damage_mult)
	check(c.elite and c.max_hp > hp_forte, "elite: mais vida (%.0f -> %.0f)" % [hp_forte, c.max_hp])
	c.queue_free()
	d.wave = 0


func _chefe_vem() -> void:
	print("== chefe")
	var d = g("defense")
	var dn = g("day_night")
	var sun = g("sun")
	dn.day = 1
	check(not d.boss_due(), "1ª primavera: sem chefe")
	dn.day = sun.days_per_season * d.boss_from_season + 1
	check(d.boss_due(), "estação %d: chefe devido" % d.boss_from_season)
	d.spawn_spread = 1.0
	d.start_invasion()
	check(d.last_result.chefe == "veio" and d.last_result.tier >= 1, "onda registra o chefe e o tier (%s)" % str(d.last_result))
	Engine.time_scale = 2.0


func _chefe_luta() -> void:
	var d = g("defense")
	check(chefe.variant == "chefe" and chefe.max_hp >= 18.0 * d.boss_hp_mult * 0.99, "a Matriarca: vida %.0f" % chefe.max_hp)
	check(not d.boss_due(), "uma por estação: não vem de novo")
	chefe.inside = true
	chefe._gate = null
	d._boss_call_t = 0.0


func _grito_e_morte() -> void:
	var d = g("defense")
	Engine.time_scale = 1.0
	check(d._boss_called >= d.boss_call_count, "grito chamou Lumívoros (%d)" % d._boss_called)
	# golpe num guarda armado corrói a arma
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w.set_job("guarda")
	w.equip("lanca")
	var dur0: float = w.weapon_durability
	chefe._attack(w)
	check(w.weapon == "" or w.weapon_durability <= dur0 - d.boss_weapon_corrode + 0.01, "golpe dela corrói a arma (%.0f -> %.0f)" % [dur0, w.weapon_durability])
	# derrubar: recompensa
	var arm = g("armazens")
	var sol0: float = arm.stock.get("solarita", 0.0)
	var finds = g("finds")
	var p0: int = finds.rare_parts if finds else 0
	chefe.take_hit(chefe.hp + 1.0, w)
	check(d.bosses.get(str(d._season_number()), "") == "derrotado", "derrotada (registro da estação)")
	check(arm.stock.get("solarita", 0.0) >= sol0 + d.boss_reward_solarita - 0.01, "recompensa: +%d solarita" % d.boss_reward_solarita)
	check(finds == null or finds.rare_parts == p0 + d.boss_reward_parts, "+%d peças raras" % d.boss_reward_parts)


func _fuga_e_save() -> void:
	print("== fuga, guardas caídos e save")
	var d = g("defense")
	var dn = g("day_night")
	var sun = g("sun")
	# próxima estação: vem de novo e foge ao amanhecer
	dn.day = sun.days_per_season * (d.boss_from_season + 1) + 1
	check(d.boss_due(), "estação seguinte: chefe de novo")
	d.end_invasion()
	for c in main.get_tree().get_nodes_in_group("criaturas"):
		c.queue_free()
	d.start_invasion()
	d._night_time = 999.0
	d._process(0.1)
	var tem := false
	for c in main.get_tree().get_nodes_in_group("chefes"):
		if c.is_alive():
			tem = true
	check(tem, "nasceu de novo")
	# todos os guardas caídos: a noite acaba igual (sem softlock)
	for w in main.get_tree().get_nodes_in_group("ipezinhos"):
		if w.is_guard():
			w.take_hit(999.0, null)
	d.end_invasion()
	check(not d.invasion_active, "amanhecer encerra mesmo com os guardas caídos")
	check(d.bosses.get(str(d._season_number()), "") == "fugiu", "amanheceu com ela de pé: fugiu")
	check(d.last_result.chefe == "fugiu", "telemetria/onda: chefe fugiu")
	var tel = main.get_tree().get_first_node_in_group("telemetria")
	if tel:
		check(tel.COLUNAS.has("chefe") and tel.COLUNAS.has("tier"), "telemetria tem tier e chefe")
	root.get_node("SaveManager").save_game("teste")


func _carregado() -> void:
	print("== depois de carregar")
	var d = g("defense")
	var sun = g("sun")
	var s1 := str(d.boss_from_season)
	var s2 := str(d.boss_from_season + 1)
	check(d.bosses.get(s1, "") == "derrotado" and d.bosses.get(s2, "") == "fugiu", "save guarda os chefes (%s)" % str(d.bosses))
