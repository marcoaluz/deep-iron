extends SceneTree
## Bloco 32: visual da Escavadeira. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var alphas: Array[float] = []
const OS_ := preload("res://scripts/core/obra_site.gd")


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


func vis(dig) -> String:
	var parts: Array[String] = []
	for id in dig.PART_IDS:
		var l: Sprite2D = dig._layers[id]
		if l.visible:
			parts.append("%s(a=%.2f)" % [id, l.modulate.a])
	if dig._reactor_layer.visible:
		parts.append("reator[%s]" % dig.REACTOR_IDS[dig._reactor_layer.frame])
	if dig._reactor_new.visible:
		parts.append("novo[%s a=%.2f]" % [dig.REACTOR_IDS[dig._reactor_new.frame], dig._reactor_new.modulate.a])
	return " ".join(parts) if not parts.is_empty() else "(só a plataforma)"


func only_visible(dig, ids: Array) -> bool:
	for id in dig.PART_IDS:
		if dig._layers[id].visible != ids.has(id):
			return false
	return true


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 900.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	var dig = g("escavadeira")
	if step == 0 and t > 2.0:
		print("== partida nova: ", vis(dig))
		check(dig.get_node("Base").visible, "plataforma (Base) aparece")
		check(only_visible(dig, []), "nenhuma peça aparece")
		check(not dig._reactor_layer.visible and not dig._reactor_new.visible, "nenhum reator aparece")
		var eco = main.get_node("Economy")
		eco.credits = 999999
		var arm = g("armazens")
		for k in arm.stock:
			arm.stock[k] = 9000.0
		arm._recount()
		g("village_hub").level = 4
		check(dig.start_part("estrutura"), "estrutura encomendada")
		print("  encomendada: ", vis(dig))
		check(only_visible(dig, ["estrutura"]), "só a estrutura aparece (fantasma)")
		check(absf(dig._layers.estrutura.modulate.a - 0.18) < 0.01, "fantasma bem fraco sem engenheiro (a=%.2f)" % dig._layers.estrutura.modulate.a)
		get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1:
		if dig.fabricating == "estrutura" and dig._obra.has_engineer():
			var a: float = dig._layers.estrutura.modulate.a
			if alphas.is_empty() or a > alphas[-1] + 0.1:
				alphas.append(a)
				print("  montando: %d%%  %s" % [roundi(dig.fab_progress() * 100), vis(dig)])
			if alphas.size() == 2 and a == alphas[1]:
				var c: Color = dig._layers.estrutura.modulate
				check(c.is_equal_approx(OS_.ghost_color(dig.fab_progress())), "cor = do canteiro")
		if dig.installed.estrutura:
			Engine.time_scale = 1.0
			print("  instalada: ", vis(dig))
			check(alphas.size() >= 3, "fantasma ficou nítido aos poucos (%s)" % str(alphas.map(func(x): return snappedf(x, 0.01))))
			check(dig._layers.estrutura.modulate == Color.WHITE, "estrutura sólida")
			check(only_visible(dig, ["estrutura"]), "só a estrutura (as outras não aparecem)")
			check(dig.start_part("broca"), "broca encomendada (fora de ordem)")
			step = 2
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "estrutura não ficou pronta")
			step = 9
	elif step == 2 and t - t_mark > 1.0:
		print("  broca em obra: ", vis(dig))
		check(only_visible(dig, ["estrutura", "broca"]), "estrutura + fantasma da broca")
		# pausa: tira o engenheiro -> o fantasma para onde está
		var a0: float = dig._layers.broca.modulate.a
		get_nodes_in_group("ipezinhos")[0].set_job("ocioso")
		set_meta("a0", a0)
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 3.0:
		var a1: float = dig._layers.broca.modulate.a
		check(absf(a1 - OS_.ghost_color(dig.fab_progress()).a) < 0.001, "pausado: fantasma parado no progresso (a=%.2f)" % a1)
		# salva no meio da broca e carrega
		var sm = root.get_node("SaveManager")
		set_meta("before", vis(dig))
		check(sm.save_game("teste"), "salvou com a broca pela metade")
		sm.load_game()
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 2.0:
		print("  antes:  ", get_meta("before"))
		print("  depois: ", vis(dig))
		check(vis(dig) == get_meta("before"), "save/load: mesmo visual")
		# completa direto (a lógica de tempo não é deste bloco)
		dig.fab_left = 0.0
		dig.obra_work(0.1)
		for id in ["motor", "hidraulica", "cabine"]:
			dig.start_part(id)
			dig.obra_work(999.0)
		print("  pronta: ", vis(dig))
		check(dig.complete, "escavadeira pronta")
		check(only_visible(dig, dig.PART_IDS), "as 5 peças sólidas")
		check(dig._reactor_layer.visible and dig._reactor_layer.frame == 0, "caldeira a vapor aparece embaixo do convés")
		g("finds").rare_parts = 99
		check(dig.build_reactor("diesel"), "reator diesel encomendado")
		print("  diesel em obra: ", vis(dig))
		check(dig._reactor_new.visible and dig._reactor_new.frame == 1, "fantasma do diesel ao lado da plataforma")
		check(dig._reactor_layer.frame == 0, "caldeira continua instalada enquanto isso")
		dig.obra_work(20.0)
		dig._process(0.0)
		print("  diesel 50%: ", vis(dig))
		check(absf(dig._reactor_new.modulate.a - (0.18 + 0.6 * 0.5)) < 0.02, "fantasma do diesel ~metade nítido")
		dig.obra_work(999.0)
		print("  diesel pronto: ", vis(dig))
		check(not dig._reactor_new.visible and dig._reactor_layer.frame == 1, "diesel entrou no lugar da caldeira")
		check(dig.install_reactor("vapor"), "trocou de volta pra caldeira")
		check(dig._reactor_layer.frame == 0, "visual voltou pra caldeira")
		dig.install_reactor("diesel")
		dig.toggle_drill()
		check(dig._reactor_layer.modulate == dig.REACTOR_IDLE_COLOR, "desligada: reator escuro")
		dig.toggle_drill()
		set_meta("before", vis(dig))
		root.get_node("SaveManager").save_game("teste")
		root.get_node("SaveManager").load_game()
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 2.0:
		print("  depois do load: ", vis(dig))
		check(vis(dig) == get_meta("before") and dig._reactor_layer.frame == 1, "save/load: pronta com diesel")
		step = 9
	if step == 9:
		print("\nFALHAS: %d" % fails)
		return true
	return false
