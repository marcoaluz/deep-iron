extends SceneTree
## Bloco 109 (não é teste): cronometra as partes da decisão da IA (pra achar o que pesa). APPDATA isolado.
##   <Godot>.exe --headless --path . -s res://tests/perf_ia.gd
var main: Node
var t := 0.0
var feito := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
	load("res://scripts/core/defense.gd").moradores_desligados = true
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _mede(nome: String, n: int, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	for i in n:
		f.call()
	var us := float(Time.get_ticks_usec() - t0) / n
	print("  %-40s %8.1f us/chamada" % [nome, us])


func _process(delta: float) -> bool:
	t += delta
	if t < 3.0 or feito:
		return false
	feito = true
	var eco = get_first_node_in_group("economy")
	eco.max_workers = 99
	while get_nodes_in_group("ipezinhos").size() < 12:
		eco.recruit_free()
	var w: Node = get_nodes_in_group("ipezinhos")[0]
	w.set_job("minerador")
	var env = get_first_node_in_group("environment")
	var jaz = get_nodes_in_group("minerios")
	print("jazidas: %d, árvores: %d" % [jaz.size(), get_nodes_in_group("arvores").size()])
	var j0: Node = jaz[0]
	_mede("_find_best_station(minerios)", 200, func(): w._find_best_station("minerios"))
	_mede("_find_best_station(arvores)", 200, func(): w._find_best_station("arvores"))
	_mede("_custo_estacao(jazida)", 2000, func(): w._custo_estacao(j0, "minerios"))
	_mede("_falta_no_armazem", 2000, func(): w._falta_no_armazem(j0, "minerios"))
	_mede("_perigo_em", 2000, func(): w._perigo_em(j0))
	_mede("env.danger_mult_at", 2000, func(): env.danger_mult_at(j0.global_position))
	_mede("_criatura_perto", 2000, func(): w._criatura_perto(j0.global_position, 160.0))
	_mede("eco.quantidade(ferro)", 2000, func(): eco.quantidade("ferro"))
	_mede("_choose_state (minerador)", 200, func(): w._choose_state())
	w.set_job("engenheiro")
	_mede("_choose_state (engenheiro, secundária)", 200, func(): w._choose_state())
	_mede("_has_usable_station(arvores)", 200, func(): w._has_usable_station("arvores"))
	_mede("work_mult", 5000, func(): w.work_mult())
	quit()
	return true
