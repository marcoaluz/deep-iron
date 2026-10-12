extends SceneTree
## Bloco 137 (não é teste): TELEMETRIA de uma noite — quantos guardas de vigia estão no posto x jantando/na roda ao longo
## da hora social, e onde está o padre (dentro da igreja, na roda, comendo). Sem janela, APPDATA isolado:
##   <Godot>.exe --headless --path . -s res://tests/telemetria_bloco137.gd -- <pasta de saída>
## Grava noite_guardas.csv (uma linha a cada amostra) e resumo.txt.
var main: Node
var out_dir := ""
var _linhas: Array = ["hora,de_vigia,no_posto,jantando_ou_roda,a_caminho,padre_estado,padre_dentro"]
var _min_posto := 999
var _min_posto_assumido := 999  # (depois que o 1º de vigia chegou ao posto: a troca de turno do fim da tarde fica de fora)
var _assumiu := false
var _amostras := 0
var _social_amostras := 0
var _padre_roda := 0
var _padre_dentro_expediente := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://telemetria137")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	_roda()


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _roda() -> void:
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	await _frames(8)
	var eco := g("economy")
	eco.credits = 9999.0
	for i in 8:
		eco.novo_ipezinho("menina" if i % 2 == 0 else "menino")
	await _frames(4)
	var hub: Node2D = g("village_hub")
	var cal := g("calendario")
	var dn := g("day_night")
	var sched := g("schedule")
	hub.level = maxi(int(hub.level), int(cal.padre_estagio))
	if cal.igreja() == null:
		hub.spawn_igreja(hub.global_position + Vector2(320, 220))
	var pd: Node2D = cal.chega_padre()
	pd._heal()
	var gente: Array = get_nodes_in_group("ipezinhos").filter(func(x): return not x.e_crianca() and not x.is_priest())
	var guardas: Array = gente.slice(0, 6)
	for x in guardas:
		x.set_job("guarda", false)
	for x in gente.slice(6):
		x.set_job("minerador", false)
	if dn.e_domingo():
		dn.day += 1
	# a tarde (o padre no expediente) e depois a noite inteira até dormir
	dn.time = dn.tempo_da_hora(15.0)
	pd.global_position = cal.igreja().altar_pos()
	Engine.time_scale = 4.0
	var fim: float = fposmod(dn.hora_dormir + 0.5, 24.0)
	var passou_meia_noite := false
	var h_ant: float = dn.hora()
	while true:
		await create_timer(0.5, true, false, true).timeout
		var h: float = dn.hora()
		if h < h_ant:
			passou_meia_noite = true
		h_ant = h
		_amostra(h, guardas, pd, sched, dn)
		if (passou_meia_noite or dn.hora_dormir > 12.0) and sched._entre(h, fim, fposmod(fim + 1.0, 24.0)):
			break
		if _amostras > 4000:
			break
	Engine.time_scale = 1.0
	var f := FileAccess.open(out_dir.path_join("noite_guardas.csv"), FileAccess.WRITE)
	f.store_string("\n".join(_linhas) + "\n")
	f.close()
	var r := "Bloco 137 — uma noite com 6 guardas (vigília de %d%%) e o padre\n" % roundi(sched.vigilia_fracao * 100.0)
	r += "amostras: %d (%d na hora social)\n" % [_amostras, _social_amostras]
	r += "menor número de guardas de vigia NO POSTO durante a hora social: %d (contando a chegada do trabalho do dia)\n" % _min_posto
	r += "menor número NO POSTO depois que a vigia assumiu (o revezamento da janta): %d\n" % _min_posto_assumido
	r += "amostras com o padre na roda/janta (hora social): %d de %d\n" % [_padre_roda, _social_amostras]
	r += "amostras com o padre DENTRO da igreja no expediente: %d\n" % _padre_dentro_expediente
	var f2 := FileAccess.open(out_dir.path_join("resumo.txt"), FileAccess.WRITE)
	f2.store_string(r)
	f2.close()
	print(r)
	quit()


func _amostra(h: float, guardas: Array, pd: Node, sched: Node, dn: Node) -> void:
	_amostras += 1
	var vig: Array = guardas.filter(func(x): return sched.de_vigia(x))
	var posto := 0
	var social := 0
	var caminho := 0
	for x in vig:
		var st: String = x.get_state()
		if st == "guard":
			if x.has_method("_guard_target") or true:
				posto += 1
		elif st in ["social", "eating"]:
			social += 1
		else:
			caminho += 1
	var e_social: bool = sched.periodo_geral(h) == "social"
	if e_social:
		_social_amostras += 1
		_min_posto = mini(_min_posto, posto)
		if posto > 0:
			_assumiu = true
		if _assumiu:
			_min_posto_assumido = mini(_min_posto_assumido, posto)
		if String(pd.get_state()) in ["social", "eating"]:
			_padre_roda += 1
	elif sched.periodo_geral(h) == "trabalho" and pd._inside:
		_padre_dentro_expediente += 1
	_linhas.append("%.2f,%d,%d,%d,%d,%s,%s" % [h, vig.size(), posto, social, caminho, pd.get_state(), str(pd._inside)])
