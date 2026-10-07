extends SceneTree
## Bloco 51: TESTE DE ESTRESSE do engenheiro depois de carregar o save. 50 ciclos de: deixar o jogo
## andar um pouco (tempo acelerado, engenheiros em estados diferentes: parado, indo, construindo),
## salvar, carregar e conferir que cada engenheiro com obra pendente, em até 25 s de jogo, chegou
## (está construindo) ou está se aproximando (a distância até a obra caiu). Pega o "engenheiro preso a
## caminho" visto no b31b. RODAR SÓ COM APPDATA ISOLADO.
const CICLOS := 50
const PRAZO := 25.0  # s de jogo pra retomar depois de carregar
const PATH := "user://savegame.json"
var main: Node
var step := 0
var ciclo := 0
var fails := 0
var t := 0.0  # s REAIS (o tempo do jogo para ao carregar: Engine.time_scale = 0)
var t_mark := 0.0
var t0 := 0
var dist0 := {}
var presos := 0
var vigias := 0


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
	t0 = Time.get_ticks_msec()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func free_spot(near: Vector2) -> Vector2:
	var placer = g("house_placer")
	placer._collect_blockers()
	for r in range(1, 16):
		for a in range(16):
			var p: Vector2 = near + Vector2.RIGHT.rotated(a * TAU / 16.0) * (60.0 + r * 28.0)
			if placer.check_spot(p) == "":
				return p
	return Vector2.INF


func engenheiros() -> Array:
	return get_nodes_in_group("ipezinhos").filter(func(w): return w.job == "engenheiro")


func pendentes() -> int:
	var n := 0
	for o in get_nodes_in_group("obras"):
		if o.has_method("obra_pending") and o.obra_pending():
			n += 1
	return n


func _process(_delta: float) -> bool:
	t = (Time.get_ticks_msec() - t0) / 1000.0
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 900.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no ciclo %d\nFALHAS: %d" % [ciclo, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_monta()
				step = 1
				t_mark = t
		1:  # deixa andar um pouco (cada ciclo um tempo: pega estados diferentes)
			if t - t_mark > 0.3 + float(ciclo % 7) * 0.4:
				Engine.time_scale = 1.0
				root.get_node("SaveManager").save_game("estresse")
				Engine.time_scale = 0.0
				root.get_node("SaveManager").load_game()
				step = 2
				t_mark = t
		2:  # carregou: guarda a distância de cada engenheiro até a obra dele
			if t - t_mark > 1.0 and main != null and main.is_inside_tree():
				Engine.time_scale = 4.0
				dist0.clear()
				step = 3
				t_mark = t
		3:
			if t - t_mark < 0.3:
				return false
			if dist0.is_empty():
				for w in engenheiros():
					dist0[w.name] = _dist(w)
			var prazo_ok := (t - t_mark) * 4.0 > PRAZO
			var todos := true
			for w in engenheiros():
				if not _retomou(w):
					todos = false
			if todos or prazo_ok:
				if not todos:
					presos += 1
					for w in engenheiros():
						if not _retomou(w):
							print("    ciclo %d: %s parado: estado %s, obra %s, dist %.0f (era %.0f), pos %s alvo %s movendo=%s" % [
								ciclo, w.display_name, w.get_state(), w._obra.obra_title() if w._obra else "-", _dist(w), dist0.get(w.name, -1.0),
								w.global_position.round(), w._target.round(), w._moving])
				ciclo += 1
				if ciclo >= CICLOS or pendentes() == 0:
					Engine.time_scale = 1.0
					check(presos == 0, "%d ciclos de salvar/carregar: todo engenheiro retomou a obra (presos: %d)" % [ciclo, presos])
					check(ciclo >= 20, "ciclos suficientes antes das obras acabarem (%d)" % ciclo)
					_vigia_forcado()
					print("FALHAS: %d" % fails)
					return true
				step = 1
				t_mark = t
	return false


func _dist(w) -> float:
	if w._obra == null or not is_instance_valid(w._obra):
		return -1.0
	return w.global_position.distance_to(w._obra_goal())


## Retomou: sem obra pendente pra ele, já construindo, ou mais perto do que estava ao carregar.
func _retomou(w) -> bool:
	if pendentes() == 0:
		return true
	if w.get_state() == "building" and w._obra_on_site:
		return true
	var d0: float = dist0.get(w.name, -1.0)
	var d := _dist(w)
	if d < 0.0:
		return w.get_state() != "building"  # sem obra escolhida ainda: só conta se não ficou "indo pra nada"
	return d0 > 0.0 and d < d0 - 20.0


## Muitas obras longas (sobra trabalho pros 50 ciclos) e todo mundo engenheiro.
func _monta() -> void:
	var eco = g("economy")
	eco.credits = 99999
	var arm = g("armazens")
	for ore in ["ferro", "cobre", "carvao", "prata", "solarita"]:
		arm.stock[ore] = 9999.0
	arm.wood_stored = 9999.0
	var hub = g("village_hub")
	g("morale")._confirm_taverna(free_spot(hub.global_position))
	g("research")._confirm_lab(free_spot(hub.global_position))
	g("defense")._confirm_campo(free_spot(hub.global_position))
	for c in get_nodes_in_group("canteiros"):
		c.total = 4000.0  # obras longas: o estresse precisa de obra pendente o tempo todo
		c.left = 4000.0
	for w in get_nodes_in_group("ipezinhos"):
		w.set_job("engenheiro")
	print("== %d obras, %d engenheiros, %d ciclos" % [pendentes(), engenheiros().size(), CICLOS])


## O vigia age quando o engenheiro fica "a caminho" sem se aproximar: força a situação (sem progresso
## por mais que obra_watchdog_time) e confere que ele escolheu outro ponto de acesso ou foi puxado.
func _vigia_forcado() -> void:
	var w = engenheiros()[0]
	var site: Node = null
	for o in get_nodes_in_group("obras"):
		if o.has_method("obra_pending") and o.obra_pending():
			site = o
	if site == null:
		check(false, "vigia forçado: sem obra pendente pra testar")
		return
	w._obra_stop()
	w._obra = site
	w._ai_state = "building"
	var pos0: Vector2 = w.global_position
	w._obra_watch_best = 0.0  # "não se aproximou" desde o começo
	w._obra_watchdog_tick(w.obra_watchdog_time + 1.0, 9999.0)
	check(w._obra_alt != Vector2.INF or w.global_position != pos0,
		"vigia forçado age (ponto de acesso %s, posição %s -> %s)" % [w._obra_alt, pos0.round(), w.global_position.round()])
	w._obra_watch_best = INF
	w._obra_watch_t = 0.0
	w._obra_watchdog_tick(1.0, 500.0)
	check(w._obra_watch_t == 0.0 and w._obra_watch_best == 500.0, "vigia não age enquanto ele se aproxima")
