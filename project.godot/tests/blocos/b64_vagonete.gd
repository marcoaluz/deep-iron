extends SceneTree
## Bloco 64: trilho e vagonete. Construir perto das jazidas (longe do armazém), canteiro do
## engenheiro, trilho até o armazém, minerador entrega no ponto de carga, vagonete leva sozinho pro
## armazém, trilho quebra (vagonete para, ponto cheio não aceita: mineradores voltam pro armazém),
## engenheiro conserta, save/load. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var est: Node
var ferro0 := 0.0


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
	load("res://scripts/props/armazem.gd").limite_desligado = true  # Bloco 97: o limite do armazém não é o assunto deste teste


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
	if t > 150.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_constroi()
				step = 1
		1:
			var ps: Array = _construidos()
			if not ps.is_empty() and ps[0].rail != null:
				est = ps[0]
				Engine.time_scale = 1.0
				_trilho()
				step = 2
				t_mark = t
		2:
			if est.total_moved >= est.cart_capacity - 0.1:
				_levou()
				step = 3
				t_mark = t
			elif t - t_mark > 50.0:
				check(false, "vagonete levou a carga (%s, d=%.0f de %.0f)" % [est.cart_state, est.cart_d, est._len])
				step = 3
				t_mark = t
		3:
			if est.is_broken():
				_quebrou()
				step = 4
				t_mark = t
			elif t - t_mark > 50.0:
				check(false, "trilho quebrou depois da última viagem")
				step = 4
		4:
			if not est.is_broken():
				Engine.time_scale = 1.0
				check(est.rail_left == est.rail_trips and not est.rail.broken, "engenheiro consertou o trilho")
				root.get_node("SaveManager").save_game("teste")
				step = 5
				t_mark = t
			elif t - t_mark > 50.0:
				check(false, "engenheiro consertou")
				step = 5
				t_mark = t
		5:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 6
				t_mark = t
		6:
			if t - t_mark > 3.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _constroi() -> void:
	print("== construir")
	var hub = g("village_hub")
	var eco = g("economy")
	eco.credits = 5000
	var arm = g("armazens")
	arm.stock["ferro"] = 500.0
	arm.wood_stored = 500.0
	arm._recount()
	check(hub.vagonete_spot_reason(arm.global_position + Vector2(40, 0)) != "", "perto do armazém: não pode")
	check(hub.build_vagonete(), "abre o posicionador")
	var placer = g("house_placer")
	placer._collect_blockers()
	var lugar := Vector2.INF
	for j in main.get_tree().get_nodes_in_group("minerios"):
		if not j.is_unlocked() or j.is_sealed() or j.global_position.distance_to(arm.global_position) < 260.0:
			continue
		for r in range(2, 8):
			for a in 16:
				var p: Vector2 = j.global_position + Vector2.RIGHT.rotated(a * TAU / 16.0) * (r * 22.0)
				placer.move_to(p)
				if placer._reason == "":
					lugar = p
					break
			if lugar != Vector2.INF:
				break
		if lugar != Vector2.INF:
			break
	check(lugar != Vector2.INF and placer.try_confirm(), "encomendado em %s" % lugar)
	var cant: Node = null
	for c in main.get_tree().get_nodes_in_group("canteiros"):
		if c.kind == "vagonete":
			cant = c
	check(cant != null, "canteiro do engenheiro")
	if cant:
		cant.total = 3.0
		cant.left = 3.0
	main.get_tree().get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
	Engine.time_scale = 3.0


func _trilho() -> void:
	print("== trilho e entrega")
	check(est.rail.points.size() >= 2 and est._len > 100.0, "trilho até o armazém (%d pontos, %.0f px)" % [est.rail.points.size(), est._len])
	check(est.rail.points[est.rail.points.size() - 1].distance_to(est.armazem().global_position) < 80.0, "termina no armazém")
	# minerador perto do ponto de carga, com carga: escolhe o ponto, não o armazém
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[1]
	w.set_job("minerador")
	w.global_position = est.global_position + Vector2(40, 30)
	w.carrying = w.cargo_capacity
	w.cargo_type = "ferro"
	w._set_state("idle")
	w._decision_timer = 0.0
	w._decide_next_action()
	check(w._station == est, "minerador perto entrega no ponto de carga (estação: %s)" % (w._station.name if w._station else "-"))
	ferro0 = g("armazens").stock.get("ferro", 0.0)
	est.stock["ferro"] = est.stock.get("ferro", 0.0) + est.cart_capacity
	Engine.time_scale = 3.0


func _levou() -> void:
	check(g("armazens").stock.get("ferro", 0.0) >= ferro0 + est.cart_capacity - 0.5, "o armazém recebeu a carga do vagonete")
	est.rail_left = 1  # a próxima volta quebra
	est.stock["ferro"] = est.stock.get("ferro", 0.0) + est.cart_capacity


func _quebrou() -> void:
	print("== quebrou")
	check(est.rail.broken and est.obra_pending(), "trilho quebrado vira obra do engenheiro")
	est.stock["ferro"] = est.buffer_capacity
	check(not est.is_usable(), "quebrado e cheio: o ponto não aceita (mineradores vão pro armazém)")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[1]
	w.global_position = est.global_position + Vector2(40, 30)
	w.carrying = w.cargo_capacity
	w._set_state("idle")
	w._decide_next_action()
	check(w._station != est, "minerador foi pro armazém (sem travar)")
	est.stock = {}
	Engine.time_scale = 3.0


## Os pontos de carga que o jogador construiu (Bloco 74: fora o fixo da boca da mina).
func _construidos() -> Array:
	return main.get_tree().get_nodes_in_group("pontos_carga").filter(func(p): return not p.is_in_group("ponto_carga_fixo"))


func _carregado() -> void:
	print("== depois de carregar")
	var ps: Array = _construidos()
	check(ps.size() == 1, "ponto de carga voltou")
	if ps.is_empty():
		return
	var e = ps[0]
	check(e.total_moved >= e.cart_capacity - 0.1, "total levado voltou (%.0f)" % e.total_moved)
	check(e.rail != null and e.rail.points.size() >= 2, "trilho refeito")
	var fixos: int = main.get_tree().get_nodes_in_group("ponto_carga_fixo").size()  # (Bloco 74: o da mina tem o dele)
	check(main.get_tree().get_nodes_in_group("trilhos").size() == 1 + fixos and main.get_tree().get_nodes_in_group("vagonetes").size() == 1 + fixos, "um trilho e um vagonete (sem duplicar)")
