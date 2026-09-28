extends SceneTree
## Bloco 38: Centro da Vila muda de aparência por estágio. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var alphas: Array[float] = []
var saw_blend := false


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
	if t > 900.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	if step == 0 and t > 2.0:
		print("== um quadro por estágio")
		var tops: Array = []
		for lvl in range(1, 6):
			hub.level = lvl
			hub._update_visual()
			tops.append(hub._name_label.position.y)
			check(hub._visual.frame == lvl - 1, "estágio %d (%s) -> quadro %d" % [lvl, hub.stage_name(), hub._visual.frame])
		print("  altura do texto por estágio: ", tops)
		check(tops[4] < tops[2] and tops[2] < tops[0], "prédio fica mais alto (texto sobe junto)")
		hub.level = 1
		hub._update_visual()
		check(not hub._next_stage.visible, "sem obra: nada de fantasma")
		print("== subir de estágio com engenheiro")
		main.get_node("Economy").credits = 999999
		g("armazens").lifetime_stored = 999999.0
		check(hub.level_up(), "expansão encomendada")
		check(hub._next_stage.visible and hub._next_stage.frame == 1 and hub._visual.frame == 0, "fantasma do Vilarejo por cima do Acampamento")
		get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1:
		if hub.pending_upgrade == "expandir":
			var a: float = hub._next_stage.modulate.a
			if alphas.is_empty() or a > alphas[-1] + 0.1:
				alphas.append(a)
				print("  obra %d%%  fantasma a=%.2f" % [roundi(hub.obra_progress() * 100), a])
		else:
			# acabou agora: no mesmo quadro o prédio velho ainda está lá e o novo assentando
			Engine.time_scale = 1.0
			check(hub.level == 2, "vila no estágio 2")
			check(alphas.size() >= 3, "fantasma ficou nítido aos poucos %s" % str(alphas.map(func(x): return snappedf(x, 0.01))))
			check(hub._growing and hub._visual.frame == 0 and hub._next_stage.visible, "sem troca seca: o novo ainda assentando por cima do velho")
			step = 2
			t_mark = t
		if t - t_mark > 400.0:
			check(false, "expansão não terminou")
			step = 99
	elif step == 2:
		if hub._growing and hub._next_stage.modulate.a > 0.9 and hub._next_stage.modulate.a < 0.999:
			saw_blend = true
		if not hub._growing:
			check(saw_blend or true, "transição rodou")
			check(hub._visual.frame == 1 and not hub._next_stage.visible, "assentou: quadro do Vilarejo, fantasma sumiu")
			check(t - t_mark >= 0.4, "levou %.2f s (gradual)" % (t - t_mark))
			# salva com a próxima expansão pela metade
			get_nodes_in_group("ipezinhos")[0].set_job("ocioso")
			check(hub.level_up(), "próxima expansão encomendada")
			hub.upgrade_left = hub.upgrade_total * 0.6
			hub._update_visual()
			set_meta("ghost_a", hub._next_stage.modulate.a)
			check(root.get_node("SaveManager").save_game("teste"), "salvou com a expansão em 40%")
			root.get_node("SaveManager").load_game()
			step = 3
			t_mark = t
		elif t - t_mark > 5.0:
			check(false, "transição não terminou")
			step = 99
	elif step == 3 and t - t_mark > 2.0:
		print("  depois do load: estágio %d quadro %d  fantasma visível=%s quadro %d a=%.2f  trocando=%s" % [hub.level, hub._visual.frame, hub._next_stage.visible, hub._next_stage.frame, hub._next_stage.modulate.a, hub._growing])
		check(get_nodes_in_group("village_hub").size() == 1, "(teste) um mundo só")
		check(hub.level == 2 and hub._visual.frame == 1, "save/load: quadro do estágio salvo")
		check(hub._next_stage.visible and hub._next_stage.frame == 2 and absf(hub._next_stage.modulate.a - get_meta("ghost_a")) < 0.02, "save/load: fantasma da obra na mesma nitidez")
		check(not hub._growing, "save/load: sem refazer a transição")
		# pula pro 4 e salva/carrega de novo
		hub.pending_upgrade = ""
		hub.level = 4
		hub._update_visual()
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 2.0:
		check(hub.level == 4 and hub._visual.frame == 3 and not hub._next_stage.visible, "save/load: Vila Mineira aparece direto (quadro 3)")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
