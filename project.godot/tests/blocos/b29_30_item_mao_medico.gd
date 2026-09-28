extends SceneTree
## Blocos 29 (item na mão) e 30 (médico). RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var doc: Node2D
var pat: Node2D
var ward: Node
var t_mark := 0.0
var rec_mark := 0.0
var rate_passive := 0.0


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


func held(w) -> String:
	w._update_animation(0.016)
	if not w._tool.visible:
		return "(nada)"
	return w._tool.texture.resource_path.get_file()


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 400.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = get_first_node_in_group("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 1.5:
		var ws := get_nodes_in_group("ipezinhos")
		var w = ws[2]
		print("== Bloco 29: item na mão (troca no mesmo quadro)")
		# (Bloco 43) Bloco 35: guarda novo começa com o porrete (antes: lança)
		var expect := {"minerador": "pickaxe.png", "lenhador": "axe.png", "guarda": "porrete.png",
			"cozinheiro": "food_basket.png", "pesquisador": "(nada)", "ocioso": "(nada)",
			"médico": "(nada)", "caçador": "forage_basket.png"}
		for job in expect:
			w.set_job(job)
			var h := held(w)
			check(h == expect[job], "%-11s -> %s" % [job, h])
		var of = get_first_node_in_group("oficina")
		of.crafted["arco"] = true
		for x in ws:
			x.on_tool_crafted("arco")
		w._ai_state = "hunting"
		check(held(w) == "bow.png", "caçador com arco CAÇANDO -> %s" % held(w))
		w._ai_state = "foraging"
		check(held(w) == "forage_basket.png", "caçador com arco COLHENDO FRUTA -> %s" % held(w))
		w._ai_state = "mining"
		w.set_job("pesquisador")
		check(held(w) == "pickaxe.png", "pesquisador sem laboratório minerando -> %s" % held(w))
		w.set_job("ocioso")

		print("== Bloco 30: médico")
		ward = get_first_node_in_group("enfermarias")
		check(ward != null, "cena tem enfermaria")
		pat = ws[0]
		doc = ws[1]
		pat.hurt("mina", "grave")
		step = 1
	elif step == 1 and pat._admitted:
		# internado SEM médico: mede a cura passiva
		if rec_mark == 0.0:
			rec_mark = pat._recovery_left
			t_mark = t
		elif t - t_mark >= 3.0:
			rate_passive = (rec_mark - pat._recovery_left) / (t - t_mark)
			print("  sem médico: cura %.2f s de leito por segundo (%s)" % [rate_passive, ward._label.text.replace("\n", " | ")])
			check(absf(rate_passive - 1.0) < 0.1, "sem médico a cura é a passiva de sempre")
			doc.set_job("médico")
			step = 2
			t_mark = t
	elif step == 1 and t > 120.0:
		check(false, "paciente não foi internado em 120 s (estado %s)" % pat.get_state_label())
		step = 9
	elif step == 2:
		if doc._on_duty != null:
			# (Bloco 43) _inside é o que some com ele do mapa (o desenho some no quadro seguinte)
			check(doc._inside, "médico entrou na enfermaria (sumiu do mapa): %s" % doc.get_state_label())
			check(doc._body.texture.resource_path.get_file().begins_with("ipezinho_medico_"), "outfit de médico (%s)" % doc._body.texture.resource_path.get_file())
			rec_mark = pat._recovery_left
			t_mark = t
			step = 3
		elif t - t_mark > 60.0:
			check(false, "médico não chegou em 60 s (%s)" % doc.get_state_label())
			step = 9
	elif step == 3 and t - t_mark >= 3.0:
		var rate: float = (rec_mark - pat._recovery_left) / (t - t_mark)
		print("  com médico: cura %.2f s de leito por segundo (%s)" % [rate, ward._label.text.replace("\n", " | ")])
		check(rate > rate_passive * 2.0, "cura bem mais rápida com médico (%.2f x %.2f)" % [rate, rate_passive])
		check(ward.waiting_clock_mult() < 1.0, "quem espera leito piora mais devagar (relógio x%.2f)" % ward.waiting_clock_mult())
		doc.set_job("ocioso")
		check(ward.doctors().is_empty() and ward.heal_rate() == 1.0, "tirou a função: bônus parou NA HORA (taxa %.1f)" % ward.heal_rate())
		doc.set_job("médico")
		hud_check()
		step = 4
		t_mark = t
	elif step == 4 and doc._on_duty != null:
		var sm = root.get_node("SaveManager")
		check(sm.save_game("teste"), "salvou com médico de plantão")
		sm.load_game()
		step = 5
		t_mark = t
	elif step == 4 and t - t_mark > 60.0:
		check(false, "médico não voltou ao plantão")
		step = 9
	elif step == 5 and t - t_mark > 12.0:
		var docs := get_nodes_in_group("ipezinhos").filter(func(w): return w.job == "médico")
		check(docs.size() == 1, "depois de carregar: 1 médico")
		if docs.size() == 1:
			check(docs[0]._on_duty != null or docs[0].get_state() == "doctor", "médico voltou pro plantão sozinho (%s)" % docs[0].get_state_label())
		step = 9
	if step == 9:
		print("\nFALHAS: %d" % fails)
		return true
	return false


func hud_check() -> void:
	var h = main.get_node("HUD")
	h._refresh()
	# (Bloco 43) HUD Frostpunk: contagem na barra de funções
	check(h._job_buttons.has("médico") and h._job_buttons["médico"].count.text == "1", "HUD contagem de médicos: '%s'" % (h._job_buttons["médico"].count.text if h._job_buttons.has("médico") else "?"))
