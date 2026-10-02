extends SceneTree
## Prompt 18: EFEITOS na vista iso (iso_fx.gd). Partículas com textura de pixel por papel;
## festa (bandeirinhas, fogos), greve (barril em chamas, placas, placa na mão), satélite
## (antena), explosivos, onda solar (tela), escudo (domo), cova do cemitério, cesto na mão,
## clima com textura nova e neblina, gotas na mina, ar tremendo no calor, marcadores.
## RODAR SÓ COM APPDATA ISOLADO.
const IsoFx := preload("res://scripts/iso/iso_fx.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const B := preload("res://scripts/iso/iso_bonecos.gd")
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var fails := 0


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


func iso() -> Node:
	return main.get_node("IsoView")


func fx() -> Node:
	return iso()._fx


func node(g: String) -> Node:
	return main.get_tree().get_first_node_in_group(g)


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		node("day_night").time_scale = 0.0
		_dados()
		_particulas()
		_liga_eventos()
		t = 3.0
	elif step == 1 and t > 4.8:
		step = 2
		_confere_eventos()
		_bonecos()
		_desliga_eventos()
		t = 4.8
	elif step == 2 and t > 5.6:
		_confere_desligados()
		print("FALHAS: %d" % fails)
		return true
	return false


func _dados() -> void:
	print("== texturas")
	var falta := []
	for n in ["faisca", "brasa", "lasca", "serragem", "poeira", "poeira_p", "fumaca", "vapor", "nuvem_gas", "radiacao", "gota",
			"pedra", "chuva", "neve", "polen", "folha", "neblina", "fogos", "confete_0", "brilho_achado", "anel_selecao",
			"marcador_destino", "obra_ok", "obra_x"]:
		if IsoFx.tex(n) == null:
			falta.append(n)
	check(falta.is_empty(), "texturas de partícula e marcadores %s" % [falta])
	var ok := true
	for a in ["chama_p", "chama_g", "barril_fogo", "bandeirinhas"]:
		if IsoFx.frames(a).size() != 8 or IsoFx.fx_layer(a).peg.size() != 4:
			ok = false
	check(ok, "4 efeitos animados (8 quadros, com caixa)")


func _particula(n: Node, nome: String) -> CPUParticles2D:
	var bb = iso().billboard_of(n)
	if bb == null:
		return null
	for pr in bb._pairs:
		if pr[1] is CPUParticles2D and (nome == "" or String(pr[0].name) == nome):
			return pr[1]
	return null


func _particulas() -> void:
	print("== partículas copiadas com textura")
	var arv := node("arvores")
	var chips := _particula(arv, "Chips") if arv else null
	check(chips != null and chips.texture == IsoFx.tex("serragem"), "árvore: serragem")
	var casa := node("casas")
	var fum := _particula(casa, "Smoke") if casa else null
	check(fum != null and fum.texture == IsoFx.tex("fumaca"), "casa: fumaça da chaminé")
	var gas: Node = null
	for z in main.get_tree().get_nodes_in_group("zonas_perigo"):
		if z.kind == "gas":
			gas = z
	var pg := _particula(gas, "") if gas else null
	check(pg != null and pg.texture == IsoFx.tex("nuvem_gas"), "zona de gás: nuvem verde")
	if fum:
		check(is_equal_approx(fum.scale_amount_max * iso().S, 1.0) or is_equal_approx(fum.scale_amount_max * iso().S, 2.0), "tamanho em pixel inteiro (1 px da textura = 1 ou 2 px de arte)")


func _liga_eventos() -> void:
	var m := node("morale")
	m.festa_left = 120.0
	m.strike_end_at = 101.0  # (o ânimo da vila está bom: sem isso o Morale encerraria a greve)
	m.strike_ultimatum = 9999.0
	m._start_strike()
	var lab: Node2D = load("res://scenes/props/laboratorio.tscn").instantiate()
	lab.position = Vector2(420, -260)
	main.get_node("World").add_child(lab)
	var res := node("research")
	res.done.append("satelite")
	res.done.append("explosivos")
	var sun := node("sun")
	sun.wave_left = 20.0
	var dn := node("day_night")
	dn.time = 215.0  # noite: fogos
	dn.snap_lighting()


func _confere_eventos() -> void:
	print("== grandes eventos")
	check(fx()._bandeiras.size() == 3, "festa: 3 varais de bandeirinhas")
	var fogos := fx().get_children().filter(func(c): return c is CPUParticles2D and c.texture == IsoFx.tex("fogos"))
	check(not fogos.is_empty(), "festa à noite: fogos (%d)" % fogos.size())
	var barril: Node = null
	var placas := 0
	for n in main.get_node("World").get_children():
		if n.get_meta("iso_fx", "") == "barril_fogo":
			barril = n
		if n.get_meta("iso_prop", "") == "placa_greve":
			placas += 1
	check(barril != null and placas == 2, "greve: barril em chamas e 2 placas perto do Centro")
	var bbb = iso().billboard_of(barril) if barril else null
	check(bbb != null and bbb._art != null and bbb._art.get_child_count() > 0, "barril desenhado com o fogo animado")
	var labs: int = main.get_tree().get_nodes_in_group("laboratorios").size()
	check(labs > 0 and fx()._antenas.size() == labs, "satélite: antena do lado de cada laboratório (%d)" % labs)
	check(fx()._explosivos != null, "explosivos: caixote perto do poço da mina")
	check(fx()._wave_layer.visible and fx()._wave_k > 0.5, "onda solar: a tela esquenta (k %.2f)" % fx()._wave_k)
	var sky = iso()._sky
	if sky and not sky._wx_pairs.is_empty():
		check(sky._wx_pairs.rain[1].texture == IsoFx.tex("chuva") and sky._wx_pairs.snow[1].texture == IsoFx.tex("neve"), "clima: chuva e neve com a textura nova")
		check(sky._fog.size() > 0, "neblina pronta")
	var calor: int = main.get_tree().get_nodes_in_group("zonas_perigo").filter(func(z): return z.kind == "calor").size()
	var tremor: int = iso()._terrain_node.get_children().filter(func(c): return String(c.name).begins_with("Calor_")).size()
	check(tremor == calor, "ar tremendo em cada fenda de calor (%d)" % tremor)
	print("== cova e escudo")
	var enf := node("enfermarias")
	enf._spawn_grave(enf.global_position + Vector2(80, 10), "Teste")
	var g := main.get_tree().get_nodes_in_group("graves")
	var lay: Array = IsoArt.prop_layers(g[g.size() - 1]) if not g.is_empty() else []
	check(not lay.is_empty() and lay[0].tex.resource_path.ends_with("cova.png"), "cova do cemitério com a arte nova")
	var sun := node("sun")
	var hub := node("village_hub") as Node2D
	sun.spawn_shield(hub.global_position + Vector2(200, 120))
	sun.won = true
	sun.wave_left = 0.0


func _bonecos() -> void:
	print("== na mão")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w._ai_state = "strike"
	w.auto_mode = false
	w._inside = false
	w._resting = false
	w.downed = false
	w.injured = false
	w._work_timer = 0.0
	w.velocity = Vector2.ZERO
	var p: Dictionary = B.pose(w, 0, 0.0)
	check(p.has("item") and p.item.tex.resource_path.ends_with("placa_greve.png"), "greve: placa erguida na mão")
	w._ai_state = "idle"
	w.set_job("caçador")
	w._ai_state = "foraging"
	var p2: Dictionary = B.pose(w, 0, 0.0)
	check(p2.has("item") and p2.item.tex.resource_path.ends_with("cesto.png"), "caçador sem arco: cesto de coleta na mão")


func _desliga_eventos() -> void:
	var m := node("morale")
	m.festa_left = 0.0
	m._end_strike()


func _confere_desligados() -> void:
	print("== acabou")
	check(fx()._domo.visible, "escudo ativo: domo sobre a vila")
	check(fx()._bandeiras.is_empty(), "fim da festa: bandeirinhas recolhidas")
	var resto := main.get_node("World").get_children().filter(func(n): return n.get_meta("iso_fx", "") == "barril_fogo" and not n.is_queued_for_deletion())
	check(resto.is_empty(), "fim da greve: barril e placas recolhidos")
