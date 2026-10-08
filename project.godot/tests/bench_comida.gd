extends SceneTree
## Bloco 101 (não é teste): MEDE a comida dos primeiros dias com 10 ipezinhos (a população inicial nova). Cada dia
## imprime: a comida pronta no comedouro, a matéria-prima no armazém, a fome média e as refeições perdidas.
##   <Godot>.exe --headless --path . -s res://tests/bench_comida.gd -- <cenario> [dias]    (APPDATA isolado)
## Cenários: "sem_funcao" (os 10 parados: o pior caso), "1coz2cac" (1 cozinheiro, 2 caçadores, o resto parado),
## "1coz3cac" (1 cozinheiro, 3 caçadores).
const ACELERA := 8.0
var main: Node
var t := 0.0
var fase := 0
var cenario := "1coz2cac"
var dias := 3
var dia_ant := 0
var perdidas_ant := 0
var propostas := {}
var _entregue := 0.0
var _comida_ant := -1.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	var args := OS.get_cmdline_user_args()
	cenario = args[0] if args.size() > 0 else cenario
	dias = int(args[1]) if args.size() > 1 else dias
	for a in args.slice(2):  # propostas, sem mexer no jogo: comida=240 horta=0.5 (regeneração/s) capacidade=300
		var kv := String(a).split("=")
		if kv.size() == 2:
			propostas[kv[0]] = float(kv[1])
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(n: String) -> Node:
	return get_first_node_in_group(n)


func _comida() -> float:
	var s := 0.0
	for c in get_nodes_in_group("comedouros"):
		s += float(c.food_stock)
	return s


func _perdidas() -> int:
	var n := 0
	for w in get_nodes_in_group("ipezinhos"):
		n += int(w.get("refeicoes_perdidas")) if w.get("refeicoes_perdidas") != null else 0
	return n


func _linha(rotulo: String) -> void:
	var ws := get_nodes_in_group("ipezinhos")
	var fome := 0.0
	for w in ws:
		fome += float(w.hunger)
	var arm = g("armazens")
	print("  %s  comida pronta %5.1f | matéria-prima %5.1f | fome média %5.1f | refeições perdidas (acumulado) %d | %d ipezinhos" % [
		rotulo, _comida(), float(arm.raw_stored), fome / maxf(ws.size(), 1), _perdidas(), ws.size()])
	var hortas := get_nodes_in_group("coleta_comida").map(func(h): return int(h.food_remaining) if h.get("food_remaining") != null else -1)
	var est := {}
	for w in ws:
		if w.job != "ocioso":
			var k: String = "%s:%s" % [w.job, w.get_state()]
			est[k] = est.get(k, 0) + 1
	print("      hortas %s | %s | entregue na cozinha hoje %.0f" % [hortas, est, _entregue])
	_entregue = 0.0


func _process(delta: float) -> bool:
	t += delta
	var dn = g("day_night")
	if fase == 0 and t > 3.0:
		fase = 1
		var eco = g("economy")
		eco.max_workers = 99
		while get_nodes_in_group("ipezinhos").size() < 10:
			if eco.recruit_free() == null:
				break
		for c in get_nodes_in_group("comedouros"):
			if propostas.has("capacidade"):
				c.food_capacity = propostas.capacidade
			if propostas.has("comida"):
				c.food_stock = minf(propostas.comida, c.food_capacity)
		for h in get_nodes_in_group("coleta_comida"):
			if propostas.has("horta") and h.get("regen_rate") != null:
				h.regen_rate = propostas.horta
		if not propostas.is_empty():
			print("PROPOSTA (só nesta medição): %s" % propostas)
		var ws := get_nodes_in_group("ipezinhos")
		var jobs: Array = []
		match cenario:
			"1coz2cac":
				jobs = ["cozinheiro", "caçador", "caçador"]
			"1coz3cac":
				jobs = ["cozinheiro", "caçador", "caçador", "caçador"]
		for i in ws.size():
			ws[i].set_job(jobs[i] if i < jobs.size() else "ocioso")
		var def = g("defense")
		if def:
			def.first_invasion_day = 999
		print("cenário %s, %d ipezinhos, comida inicial %.0f (capacidade %.0f), porção %.0f x 3 refeições" % [
			cenario, ws.size(), _comida(), get_nodes_in_group("comedouros")[0].food_capacity, g("schedule").porcao if g("schedule") else -1])
		dia_ant = dn.day
		Engine.time_scale = ACELERA
		_linha("dia %d 05:00" % dn.day)
		return false
	if fase == 1:  # quanto entrou na cozinha (subidas do estoque)
		var c := _comida()
		if _comida_ant >= 0.0 and c > _comida_ant:
			_entregue += c - _comida_ant
		_comida_ant = c
	if fase == 1 and Engine.get_process_frames() % 600 == 0 and OS.get_environment("BENCH_DEBUG") != "":
		_linha("    %s" % dn.hora_texto())
	if fase == 1 and dn.day != dia_ant:
		dia_ant = dn.day
		_linha("dia %d 05:00" % dn.day)
		if dn.day > dias:
			Engine.time_scale = 1.0
			return true
	if Time.get_ticks_msec() > 900000:  # (tempo real: o delta vem acelerado)
		print("TIMEOUT")
		return true
	return false
