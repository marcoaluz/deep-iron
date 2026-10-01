extends SceneTree
## Bloco 32: visual da Escavadeira. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var alphas: Array[int] = []  # Prompt 28: os estágios de obra vistos (era a nitidez do fantasma)
const OS_ := preload("res://scripts/core/obra_site.gd")
const OE := preload("res://scripts/core/obra_estagio.gd")


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
			parts.append("%s(obra %d)" % [id, OE.shown(l)])
	if dig._reactor_layer.visible:
		parts.append("reator[%s]" % dig.REACTOR_IDS[dig._reactor_layer.frame])
	if dig._reactor_new.visible:
		parts.append("novo[%s obra %d]" % [dig.REACTOR_IDS[dig._reactor_new.frame], OE.shown(dig._reactor_new)])
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
		check(only_visible(dig, ["estrutura"]), "só a estrutura aparece (em obra)")
		check(OE.shown(dig._layers.estrutura) == 1, "sem engenheiro: obra no estágio 1, a fundação (%d)" % OE.shown(dig._layers.estrutura))
		get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1:
		if dig.fabricating == "estrutura" and dig._obra.has_engineer():
			var a: int = OE.shown(dig._layers.estrutura)
			if alphas.is_empty() or a > alphas[-1]:
				alphas.append(a)
				print("  montando: %d%%  %s" % [roundi(dig.fab_progress() * 100), vis(dig)])
				check(a == OE.stage(dig.fab_progress()), "estágio = o do progresso (mesma regra do canteiro)")
		if dig.installed.estrutura:
			Engine.time_scale = 1.0
			print("  instalada: ", vis(dig))
			check(alphas == [1, 2, 3], "subiu pelos 3 estágios de obra (%s)" % str(alphas))
			check(dig._layers.estrutura.modulate == Color.WHITE and OE.shown(dig._layers.estrutura) == 0, "estrutura pronta, sem corte de obra")
			check(only_visible(dig, ["estrutura"]), "só a estrutura (as outras não aparecem)")
			check(dig.start_part("broca"), "broca encomendada (fora de ordem)")
			step = 2
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "estrutura não ficou pronta")
			step = 9
	elif step == 2 and t - t_mark > 1.0:
		print("  broca em obra: ", vis(dig))
		check(only_visible(dig, ["estrutura", "broca"]), "estrutura + broca em obra")
		# pausa: tira o engenheiro -> a obra para onde está
		var a0: int = OE.shown(dig._layers.broca)
		get_nodes_in_group("ipezinhos")[0].set_job("ocioso")
		set_meta("a0", a0)
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 3.0:
		var a1: int = OE.shown(dig._layers.broca)
		check(a1 == OE.stage(dig.fab_progress()) and a1 == get_meta("a0"), "pausado: obra parada no estágio do progresso (%d)" % a1)
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
		check(dig._reactor_new.visible and dig._reactor_new.frame == 1, "obra do diesel ao lado da plataforma")
		check(dig._reactor_layer.frame == 0, "caldeira continua instalada enquanto isso")
		dig.obra_work(20.0)
		dig._process(0.0)
		print("  diesel 50%: ", vis(dig))
		check(OE.shown(dig._reactor_new) == 2, "diesel na metade: estágio 2 (%d)" % OE.shown(dig._reactor_new))
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
