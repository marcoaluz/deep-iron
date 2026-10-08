extends SceneTree
## Bloco 99 (não é teste): MEDE a produção de minério por hora de jogo com N mineradores, na partida nova (as jazidas
## da pedreira e a boca da mina), com o vagonete da boca LIGADO (com) ou PARADO (sem: tudo na mão até o armazém).
## Imprime: minério que entrou no armazém por hora e o que ficou no caminho (mãos + ponto + carrinho).
##   <Godot>.exe --headless --path . -s res://tests/bench_minerio.gd -- <com|sem> <mineradores> [horas] [pedreira|galerias]
## (APPDATA isolado). "galerias": a vila no estágio 5 (todas as galerias da montanha abertas) e uma ÁREA DE MINA
## na montanha (de x 640 a 1180, y -520 a -120) com os mineradores dela, ligada — o caso em que a boca e o vagonete
## deveriam fazer sentido.
const ACELERA := 8.0
const HORA_INI := 7.25  # depois do café
var main: Node
var t := 0.0
var fase := 0
var com := true
var n_min := 5
var horas := 4.0
var cenario := "pedreira"
var ini := {}
var t_ini := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	var args := OS.get_cmdline_user_args()
	com = args.size() < 1 or args[0] == "com"
	n_min = int(args[1]) if args.size() > 1 else 5
	horas = float(args[2]) if args.size() > 2 else 4.0
	cenario = args[3] if args.size() > 3 else "pedreira"
	load("res://scripts/props/armazem.gd").limite_desligado = true  # (o limite do armazém não é o assunto)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(n: String) -> Node:
	return get_first_node_in_group(n)


func _minerio_armazem() -> float:
	var s := 0.0
	for a in get_nodes_in_group("armazens"):
		for k in a.stock:
			s += float(a.stock[k])
	return s


func _no_caminho() -> float:
	var s := 0.0
	for w in get_nodes_in_group("ipezinhos"):
		s += float(w.carrying)
	for p in get_nodes_in_group("vagonetes").map(func(v): return v.station).filter(func(x): return x != null):
		s += p.buffered()
		for k in p.cart_load:
			s += float(p.cart_load[k])
	return s


func _process(delta: float) -> bool:
	t += delta
	var dn = g("day_night")
	if fase == 0 and t > 3.0:
		fase = 1
		var eco = g("economy")
		while get_nodes_in_group("ipezinhos").size() < n_min:
			if eco.recruit_free() == null:  # (a partida começa com 3: os outros entram de graça pra medir)
				break
		var ws := get_nodes_in_group("ipezinhos")
		var n := 0
		for w in ws:
			if n < n_min and cenario == "pedreira":
				w.set_job("minerador")
				n += 1
			else:
				w.set_job("ocioso")
		if cenario == "galerias":
			g("village_hub").level = 5
			for j in get_nodes_in_group("minerios"):
				if j.has_method("on_unlock_changed"):
					j.on_unlock_changed(false)
			var wa = g("work_areas")
			var a = wa.criar("mina", Rect2(640, -520, 540, 400))
			print("área de mina: ", a != null, " ", wa.motivo_invalido("mina", Rect2(640, -520, 540, 400)))
			if a:
				wa.ativar(a, true)
				print("ipezinhos: %d, disponíveis: %d, mineiros na área: %d" % [ws.size(), wa.disponiveis().size(), wa.definir(a, n_min)])
		var def = g("defense")
		if def:
			def.first_invasion_day = 999  # (sem invasão durante a medição)
		for p in get_nodes_in_group("pontos_carga"):
			if not com:
				p.remove_from_group("pontos_carga")  # sem vagonete: ninguém acha o ponto (a área não religa ele)
				p.parar_por_area(true, "medição: sem vagonete")
		dn._pula_para(dn.tempo_da_hora(HORA_INI))
		Engine.time_scale = ACELERA
		return false
	if fase == 1 and dn.hora() >= HORA_INI + 0.25:
		fase = 2  # 15 min de jogo pra todo mundo chegar no trabalho
		ini = {"arm": _minerio_armazem(), "cam": _no_caminho(), "h": dn.hora()}
		return false
	if fase == 2 and OS.get_environment("BENCH_DEBUG") != "" and Engine.get_process_frames() % 300 == 0:
		var dentro := 0
		for bm in get_nodes_in_group("bocas_mina"):
			dentro += bm.dentro.size()
		var estados := {}
		for w in get_nodes_in_group("ipezinhos"):
			estados[w.get_state()] = estados.get(w.get_state(), 0) + 1
		print("  %s dentro=%d estados=%s mult=%s" % [dn.hora_texto(), dentro, estados, get_nodes_in_group("ipezinhos").map(func(w): return snappedf(w.mult_mineracao(), 0.01))])
	if fase == 2 and dn.hora() >= float(ini.h) + horas:
		var arm := _minerio_armazem() - float(ini.arm)
		var cam := _no_caminho() - float(ini.cam)
		var h: float = dn.hora() - float(ini.h)
		var movido := 0.0
		for v in get_nodes_in_group("vagonetes"):
			if v.station:
				movido += v.station.total_moved
		print("RESULTADO cenário=%s modo=%s mineradores=%d horas=%.2f | armazém +%.1f (%.1f/h) | no caminho %+.1f | minerado %.1f/h | vagonete levou %.1f" % [
			cenario, "com vagonete" if com else "sem vagonete", n_min, h, arm, arm / h, cam, (arm + cam) / h, movido])
		Engine.time_scale = 1.0
		return true
	if t > 600.0:
		print("TIMEOUT")
		return true
	return false
