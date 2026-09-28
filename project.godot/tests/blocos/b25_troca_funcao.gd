extends SceneTree
## Troca de função carregando minério: tem que ir armazenar antes. (Rodar com APPDATA isolado.)
var main: Node
var t := 0.0
var step := 0
var w: Node2D
var switched_at := 0.0
var seen_storing := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade


func _process(_delta: float) -> bool:
	t += _delta
	if t > 150.0:
		print("TIMEOUT")
		return true
	if step == 0 and t > 3.0:
		w = get_nodes_in_group("ipezinhos")[0]
		w.set_job("minerador")
		step = 1
	elif step == 1 and w.get_state() == "mining" and w.carrying >= 4.0:
		# está na jazida (longe do armazém) com carga parcial: vira lenhador
		print("minerando com carga %.1f — troca pra lenhador" % w.carrying)
		w.set_job("lenhador")
		switched_at = t
		step = 2
	elif step == 2:
		if w.get_state() == "storing":
			seen_storing = true
		if t - switched_at > 0.5 and step == 2:
			print("0,5 s depois: estado=%s carga=%.1f -> %s" % [w.get_state_label(), w.carrying,
				"OK (indo entregar)" if seen_storing else "FALHOU"])
			step = 3
	elif step == 3 and w.carrying <= 0.0:
		print("entregou (%.0f s depois). agora: %s" % [t - switched_at, w.get_state_label()])
		step = 4
	elif step == 4 and w.get_state() in ["chopping", "idle", "home"]:
		print("depois da entrega foi pra: %s  -> OK" % w.get_state_label())
		return true
	return false
