extends SceneTree
## Teste do Bloco 25 (não grava nada em user://).
var main: Node
var t := 0.0
var step := 0
var w1: Node2D
var w2: Node2D


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	# NUNCA gravar no save real do jogador durante o teste
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade


func workers() -> Array:
	return get_nodes_in_group("ipezinhos")


func dump(tag: String) -> void:
	var hub = get_first_node_in_group("village_hub")
	for w in workers():
		print("  [%s] %s job=%s estado=%s carga=%d dist_centro=%d" % [tag, w.display_name, w.job, w.get_state_label(),
			int(w.carrying), int(w.global_position.distance_to(hub.global_position)) if hub else -1])


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	var dn = get_first_node_in_group("day_night")
	if t > 170.0:
		print("TIMEOUT do teste"); return true
	if dn and dn.has_method("is_night") and dn.is_night() and step < 9 and int(t * 10) % 50 == 0:
		print("AVISO: anoiteceu em t=%.0f (teste pode ficar distorcido)" % t)
	if step == 0 and t > 10.0:
		step = 1
		print("== 1) partida nova, 10 s depois: todos ociosos, ninguém minerando")
		dump("novo")
		var bad := workers().filter(func(w): return w.job != "ocioso" or w.get_state() == "mining" or w.carrying > 0)
		print("  RESULTADO: ", "OK" if bad.is_empty() else "FALHOU %d" % bad.size())
		# 2) designa minerador pro primeiro
		w1 = workers()[0]
		w2 = workers()[1]
		main.select(w1)
		main.toggle_miner()
		print("== 2) %s virou minerador" % w1.display_name)
	elif step == 1 and t > 35.0:
		step = 2
		dump("minerador")
		print("  RESULTADO: ", "OK" if w1.job == "minerador" and (w1.carrying > 0 or w1.get_state() in ["mining", "storing"]) else "FALHOU")
		# força carga na mão e troca pra lenhador: tem que entregar primeiro
		w1.carrying = 6.0
		main.select(w1)
		main.toggle_lumber()
		print("== 3) %s com carga 6 virou lenhador" % w1.display_name)
	elif step == 2 and t > 37.5:
		step = 3
		# (Bloco 43) se já estava no armazém, em 2,5 s ela entrega e vai cortar: também vale
		print("  estado logo após trocar: ", w1.get_state_label(), " -> ", "OK (vai entregar / já entregou)" if w1.get_state() == "storing" or w1.carrying <= 0.0 else "FALHOU")
		# 4) tirar a função
		main.select(w1)
		main.clear_job()
		print("== 4) tirou a função de %s" % w1.display_name)
	elif step == 3 and t > 60.0:
		step = 4
		dump("sem função")
		print("  RESULTADO: ", "OK" if w1.job == "ocioso" and w1.carrying <= 0.0 else "FALHOU (carga %.1f)" % w1.carrying)
		# 5) toggle: lenhador de novo e toggle de novo = volta a ocioso
		main.select(w2)
		main.toggle_lumber()
		var a: String = w2.job
		main.toggle_lumber()
		print("== 5) toggle L duas vezes: %s -> %s  %s" % [a, w2.job, "OK" if a == "lenhador" and w2.job == "ocioso" else "FALHOU"])
		# 6) round-trip do save por ipezinho
		w2.set_job("guarda")
		var data: Dictionary = w2.get_save_data()
		var clone = main.get_node("Economy").worker_scene.instantiate()
		clone.pending_save_data = data
		clone.name = "Clone"
		main.get_node("World").add_child(clone)
		print("== 6) save/load do ipezinho: job salvo=%s carregado=%s  %s" % [data.get("job"), clone.job,
			"OK" if clone.job == "guarda" else "FALHOU"])
		clone.queue_free()
		# 7) migração de save antigo (versão 2, só "role")
		var old := {"save_version": 2, "workers": [
			{"name": "A", "role": ""}, {"name": "B", "role": "cozinheiro"}, {"name": "C"},
			{"name": "D", "role": "lenhador"}, {"name": "E", "role": "guarda"}]}
		var migrated: Dictionary = root.get_node("SaveManager")._migrate(old)
		var jobs: Array = migrated.workers.map(func(wd): return wd.get("job"))
		print("== 7) migração v2 -> v3: ", jobs, "  ",
			"OK" if jobs == ["minerador", "cozinheiro", "minerador", "lenhador", "guarda"] else "FALHOU")
		# 8) fallback: dados antigos sem migração caindo direto no load_save_data
		var c2 = main.get_node("Economy").worker_scene.instantiate()
		c2.pending_save_data = {"role": ""}
		c2.name = "Clone2"
		main.get_node("World").add_child(c2)
		print("== 8) load direto de dado antigo (role \"\"): job=%s  %s" % [c2.job, "OK" if c2.job == "minerador" else "FALHOU"])
		c2.queue_free()
		# 9) recrutado nasce ocioso
		var eco = main.get_node("Economy")
		eco.credits = 99999
		var r = eco.recruit()
		print("== 9) recrutado: job=%s  %s" % [r.job, "OK" if r.job == "ocioso" else "FALHOU"])
		step = 9
		return true
	return false
