extends SceneTree
## Bloco 60: dinamite (pesquisa Explosivos) e rádio. Sem a pesquisa: bloqueado com motivo; fazer
## dinamite gasta cr + carvão; clicar no entulho abre a janela da galeria; um ipezinho leva a carga,
## explode, a galeria abre e a dinamite é gasta; acidente pelo risco; rádio adianta o aviso de
## invasão e acelera o satélite; save/load (dinamite e galeria explodida). RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var gal: Node
var gal_nome := ""


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
	if t > 120.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_dinamite()
				step = 1
				t_mark = t
		1:
			if not gal.is_sealed():
				Engine.time_scale = 1.0
				_abriu()
				_radio()
				root.get_node("SaveManager").save_game("teste")
				step = 2
				t_mark = t
			elif t - t_mark > 70.0:
				check(false, "a galeria abriu (%s)" % str(g("research")._blast))
				step = 2
		2:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 3.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _lacradas() -> Array:
	return main.get_tree().get_nodes_in_group("minerios").filter(func(m): return m.is_sealed())


func _dinamite() -> void:
	print("== dinamite")
	var res = g("research")
	var ls := _lacradas()
	check(not ls.is_empty(), "há galeria lacrada (%d)" % ls.size())
	if ls.is_empty():
		return
	gal = ls[0]
	gal_nome = gal.name
	check(gal.is_in_group("clickable") and gal.panel_id == "galeria", "entulho clicável")
	check("Explosivos" in res.craft_dynamite_reason() and "Explosivos" in res.blast_reason(gal), "sem a pesquisa: bloqueado (%s)" % res.blast_reason(gal))
	var hud = g("hud")
	hud.open_panel_for(gal)
	var pn = hud._panels["galeria"]
	check(pn.visible and pn._galeria == gal and pn._explodir.disabled, "clique abre a janela da galeria, explodir travado")
	res._finish("explosivos")
	var eco = g("economy")
	eco.credits = 1000
	var arm = g("armazens")
	arm.stock["carvao"] = 100.0
	arm._recount()
	var c0: float = eco.credits
	check(res.craft_dynamite() and res.dynamite == 1, "fez 1 dinamite")
	check(eco.credits == c0 - res.dynamite_credits, "cobrou %d cr (e carvão)" % res.dynamite_credits)
	pn.refresh()
	check(not pn._explodir.disabled, "agora dá pra explodir")
	res.dynamite_risk_miner = 0.0
	res.dynamite_risk_untrained = 0.0
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	ws[0].set_job("minerador")
	pn._explodir.pressed.emit()
	check(res.blast_in_progress() and res.dynamite == 0, "explosão encomendada: a dinamite saiu do paiol")
	check(res._blast.quem.is_miner(), "quem leva é o minerador")
	Engine.time_scale = 3.0


func _abriu() -> void:
	print("== abriu")
	var res = g("research")
	check(gal.blasted and not gal.is_sealed(), "galeria %s aberta pela dinamite" % gal.gallery_name)
	check(not gal.is_in_group("clickable"), "entulho não é mais clicável")
	check(not res.blast_in_progress(), "trabalho terminou")
	# acidente: risco 100% com quem não é minerador
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[2]
	w.set_job("lenhador")
	res.dynamite_risk_untrained = 1.0
	var outra: Node = null
	for m in _lacradas():
		outra = m
	if outra:
		res._explode(outra, w)
	else:
		var m0 = main.get_tree().get_nodes_in_group("minerios")[0]
		m0.blasted = false
		res._explode(m0, w)
	check(w.injured, "sem treino (risco 100%%): %s se machucou" % w.display_name)
	res.dynamite = 2


func _radio() -> void:
	print("== rádio")
	var res = g("research")
	var d = g("defense")
	var dn = g("day_night")
	var base: float = d.warn_time()
	var dia: int = dn.day
	while not d.is_invasion_night(dia):
		dia += 1
	dn.day = dia
	dn.time = dn.day_duration - (d.warn_before + 30.0)
	dn._process(0.0)
	d._warned_day = -1
	d._process(0.0)
	check(d._warned_day != dia, "sem rádio: ainda não avisou (faltando %.0f s, aviso a %.0f s)" % [dn.time_left_in_phase(), base])
	res._finish("radio")
	check(d.warn_time() == base + res.radio_warning_bonus, "rádio: aviso %.0f s antes (era %.0f)" % [d.warn_time(), base])
	d._process(0.0)
	check(d._warned_day == dia, "com rádio: avisou mais cedo")
	check(res.satellite_days() == res.radio_satellite_every_days and res.satellite_days() < res.satellite_every_days, "satélite: colono a cada %d dia(s) com o rádio" % res.satellite_days())
	dn.time = 10.0
	dn._process(0.0)


func _carregado() -> void:
	print("== depois de carregar")
	var res = g("research")
	check(res.dynamite == 2, "dinamite no paiol voltou (%d)" % res.dynamite)
	var m: Node = null
	for x in main.get_tree().get_nodes_in_group("minerios"):
		if x.name == gal_nome:
			m = x
	check(m != null and m.blasted and not m.is_sealed(), "galeria explodida continua aberta")
