extends SceneTree
## Bloco 28. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var hunter: Node2D
var tocas: Array
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
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func hud() -> Node:
	return main.get_node("HUD")


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 300.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = get_first_node_in_group("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 1.5:
		var ws := get_nodes_in_group("ipezinhos")
		print("== A) outfit por função")
		var want := {"caçador": "cacador", "guarda": "guarda", "pesquisador": "pesquisador",
			"minerador": "ipezinho_", "cozinheiro": "cozinheiro", "lenhador": "lenhador", "ocioso": "civil"}
		var w = ws[2]
		for job in want:
			w.set_job(job)
			var f: String = w._body.texture.resource_path.get_file()
			var ok := f.begins_with("ipezinho_%s_" % want[job]) if job != "minerador" else (f.count("_") == 1)
			check(ok, "%-11s -> %s" % [job, f])
		w.set_job("ocioso")

		print("== B) HUD em blocos")
		var texts := root.find_children("*", "Label", true, false).map(func(l): return l.text)
		# (Bloco 43) HUD estilo Frostpunk: as seções agora são estas duas colunas
		# (Bloco 95) a coluna de construções virou a de alertas (só ícones); as gavetas da aba fina têm título
		for sec in ["FORÇA DE TRABALHO", "OBRAS"]:
			check(texts.has(sec), "seção '%s'" % sec)
		hunter = ws[0]
		hunter.set_job("caçador")
		ws[1].set_job("guarda")
		hud()._refresh()
		var h = hud()
		# (Bloco 43) a contagem por função fica na barra de funções (vazio = nenhum)
		check(h._job_buttons["caçador"].count.text == "1", "contagem: '%s'" % h._job_buttons["caçador"].count.text)
		check(h._job_buttons["guarda"].count.text == "1", "contagem: '%s'" % h._job_buttons["guarda"].count.text)
		check(h._job_buttons["minerador"].count.text == "", "contagem: '%s'" % h._job_buttons["minerador"].count.text)
		check(h._no_job_label.text.begins_with("SEM FUNÇÃO: 1"), "destaque: '%s'" % h._no_job_label.text)
		h.set_collapsed(true, false)
		check(not h._rows_scroll.visible and h._no_job_label.visible and h._job_buttons["guarda"].count.text == "1",
			"recolher esconde botões/lista mas mantém a contagem")
		h.set_collapsed(false, false)
		check(h._rows_scroll.visible, "abrir mostra a lista de novo")

		print("== C) caçador: fallback e volta pra caça")
		var of = get_first_node_in_group("oficina")
		of.crafted["arco"] = true
		for x in ws:
			x.on_tool_crafted("arco")
		tocas = get_nodes_in_group("caca")
		for tc in tocas:  # todas as tocas esgotadas
			tc.game_remaining = 0.0
			tc._cooldown = 9999.0
		step = 1
		t_mark = t
	elif step == 1:
		if hunter.get_state() == "hunting":
			check(false, "caçou com as tocas esgotadas")
			step = 9
		if hunter.get_state() == "foraging" and hunter._raw_units > 1.0:
			check(true, "tocas esgotadas: foi colher fruta (%s, mochila %.1f)" % [hunter.get_state_label(), hunter._raw_units])
			for tc in tocas:  # uma toca regenera
				tc._cooldown = 0.0
				tc.game_remaining = tc.game_total
			step = 2
			t_mark = t
	elif step == 2:
		if hunter.get_state() == "hunting":
			check(true, "toca regenerou: largou a fruta e voltou a caçar em %.1f s (mochila %.1f, sem descarregar antes)" % [t - t_mark, hunter._raw_units])
			var sm = root.get_node("SaveManager")
			check(sm.save_game("teste"), "salvou")
			sm.load_game()
			step = 3
			t_mark = t
		elif t - t_mark > 15.0:
			check(false, "não voltou a caçar em 15 s (estado %s)" % hunter.get_state_label())
			step = 9
	elif step == 3 and t - t_mark > 2.0:
		var jobs := {}
		for w in get_nodes_in_group("ipezinhos"):
			jobs[w.job] = w._body.texture.resource_path.get_file()
		check(jobs.has("caçador") and jobs["caçador"].begins_with("ipezinho_cacador_"), "depois de carregar: caçador com outfit certo (%s)" % jobs.get("caçador"))
		check(jobs.has("guarda") and jobs["guarda"].begins_with("ipezinho_guarda_"), "depois de carregar: guarda com outfit certo (%s)" % jobs.get("guarda"))
		step = 9
	if step == 9:
		print("\nFALHAS: %d" % fails)
		return true
	return false
