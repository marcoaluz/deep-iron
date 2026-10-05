extends SceneTree
## Bloco 79: a FERROVIA DE CARGA (maquete v4 aprovada). Confere: o lugar da estação em cada andar (ponta leste,
## no chão da caverna, longe da gaiola e das jazidas, com caminho da gaiola até ela), a construção (um andar
## de cada vez, de cima pra baixo; andar fechado não; o canteiro vira a estação do andar certo), o mineiro do
## andar escolhendo a estação em vez do armazém lá em cima, o carrinho subindo pelo cavalete (some do chão,
## aparece na vista iso entre os postes) e a carga chegando no armazém, o trilho gastando (obra do engenheiro),
## as áreas de mina (Bloco 77) parando a estação, e o save.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var est: Node = null
var ferro0 := 0.0
var viu_subindo := false
var viu_tela := false
var salvo := {}


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
	return get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		Engine.time_scale = 1.0
		print("TIMEOUT (passo %d)\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 5.0:
				_lugares()
				_construir()
				step = 1
				t_mark = t
		1:  # o canteiro: o engenheiro termina (aqui: termina na mão)
			if t - t_mark > 0.5:
				_canteiro_vira_estacao()
				step = 10
				t_mark = t
		10:  # (o trilho da estação é montado no quadro seguinte)
			if t - t_mark > 0.5:
				_mineiro_escolhe()
				_carga()
				Engine.time_scale = 6.0
				step = 2
				t_mark = t
		2:  # o carrinho sobe, descarrega e volta
			var iso = g("iso_view")
			if est.progresso_subida() >= 0.0:
				viu_subindo = true
				var p: Vector2 = iso.ferrovia_carrinho(est)
				var px: Vector2 = iso.ferrovia_postes()
				if p != Vector2.INF and p.x >= px.x - 70.0 and p.x <= px.y + 70.0:
					viu_tela = true
			if est.total_moved > 0.0 or t - t_mark > 60.0:
				Engine.time_scale = 1.0
				_chegou()
				_gasta()
				_area_para()
				_salva()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 4
				t_mark = t
		4:
			if t - t_mark > 5.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _nivel(id: String) -> Resource:
	return preload("res://scripts/core/niveis.gd").por_id(id)


func _lugares() -> void:
	print("== o lugar da estação em cada andar")
	var env = g("environment")
	var nav_map: RID = env.navigation_region.get_navigation_map()
	for id in ["S2", "S3", "S4", "S5"]:
		var n := _nivel(id)
		var p: Vector2 = env.ponto_ferrovia(n)
		check(p != Vector2.INF, "%s: lugar achado %s" % [id, p])
		if p == Vector2.INF:
			continue
		var r: Rect2 = env.rect_do_nivel(n)
		check(r.has_point(p) and env.dentro_da_caverna(p), "%s: no chão da caverna do andar" % id)
		check(p.x > r.get_center().x, "%s: na metade leste (perto do poço e do cavalete)" % id)
		var perto := get_nodes_in_group("minerios").filter(func(j): return j.global_position.distance_to(p) < 60.0).size()
		check(perto == 0, "%s: longe das jazidas" % id)
		var info: Dictionary = env.andares.andares[{"S2": "nivel2", "S3": "abismo", "S4": "s4", "S5": "s5"}[id]]
		var gaiola := Vector2(info.gaiola[0], info.gaiola[1])
		var path := NavigationServer2D.map_get_path(nav_map, gaiola, p, true)
		check(not path.is_empty() and path[path.size() - 1].distance_to(p) < 40.0, "%s: caminho da gaiola até a estação" % id)


func _construir() -> void:
	print("== construir (um andar de cada vez, de cima pra baixo)")
	var hub = g("village_hub")
	var eco = g("economy")
	eco.credits = 99999
	var arm = g("armazens")
	arm.stock["ferro"] = 999.0
	arm.wood_stored = 999.0
	arm._recount()
	check(hub.ferrovia_proximo() == "S2", "o primeiro é o S2")
	var why: String = hub.ferrovia_block_reason()
	check(why.begins_with("S2 fechado"), "andar fechado não constrói (%s)" % why)
	var sh = g("elevador")
	sh.unlocked = true  # abre o S2 (a escavadeira pronta)
	if sh.has_method("sync_state"):
		sh.sync_state()
	why = hub.ferrovia_block_reason()
	check(why == "", "S2 aberto: pode (%s)" % why)
	var cr0: float = eco.credits
	check(hub.build_ferrovia(), "encomendou a estação do S2")
	check(eco.credits < cr0, "pagou (%d créditos)" % int(cr0 - eco.credits))
	var c = preload("res://scripts/props/canteiro.gd").pending(main.get_tree(), "ferrovia")
	check(c != null, "canteiro da ferrovia esperando engenheiro")
	check(hub.ferrovia_block_reason().begins_with("em obra"), "não encomenda outra com uma em obra")


func _canteiro_vira_estacao() -> void:
	var hub = g("village_hub")
	var c = preload("res://scripts/props/canteiro.gd").pending(main.get_tree(), "ferrovia")
	if c:
		c.obra_work(9999.0)  # (o engenheiro terminou)
	est = hub.ferrovia_de("S2")
	check(est != null and est.ferrovia == "S2", "o canteiro virou a estação do S2")
	check(est != null and est.is_in_group("pontos_carga") and not hub.vagonetes().has(est), "é ponto de carga, mas não conta como vagonete comum")
	check(hub.ferrovia_proximo() == "S3", "o próximo é o S3")
	check(est.subida() > 400.0, "a subida pelo cavalete: %d" % int(est.subida()))


func _mineiro_escolhe() -> void:
	print("== o mineiro do S2 entrega na estação, não no armazém lá em cima")
	var w = get_nodes_in_group("ipezinhos")[0]
	var env = g("environment")
	w.global_position = est.global_position + Vector2(-120, 10)
	w.set_job("minerador")
	w.carrying = w.cargo_capacity
	var pc: Node2D = w._find_best_station("pontos_carga")
	var arm: Node2D = w._find_best_station("armazens")
	check(pc == est, "a estação do andar é o ponto de carga escolhido")
	check(arm == null or w.global_position.distance_to(pc.global_position) < w.global_position.distance_to(arm.global_position),
		"mais perto que o armazém (vai nela)")
	w.carrying = 0.0


func _carga() -> void:
	print("== o carrinho sobe pelo cavalete")
	var arm = g("armazens")
	ferro0 = float(arm.stock.get("prata", 0.0))
	est.stock["prata"] = 40.0
	est._wait_t = 99.0


func _chegou() -> void:
	var arm = g("armazens")
	check(viu_subindo, "o carrinho entrou na subida")
	check(viu_tela, "na vista iso ele aparece no cavalete (entre os postes)")
	check(est.total_moved > 0.0, "levou carga até o armazém (%d)" % int(est.total_moved))
	check(float(arm.stock.get("prata", 0.0)) > ferro0, "a prata chegou no armazém (%d)" % int(float(arm.stock.get("prata", 0.0)) - ferro0))


func _gasta() -> void:
	print("== o trilho gasta")
	est.rail_left = 0
	check(est.is_broken() and est.obra_pending(), "quebrado: vira obra do engenheiro")
	est.obra_work(9999.0)
	check(not est.is_broken(), "consertado")


func _area_para() -> void:
	print("== área de mina (Bloco 77) parando a estação")
	var wa = g("work_areas")
	var a = wa.criar("mina", Rect2(est.global_position - Vector2(120, 60), Vector2(240, 120)))
	check(a != null, "área de mina em volta da estação")
	wa._sincroniza_carrinhos()
	check(est.parado_por_area(), "mina desligada: a estação para")
	wa.apagar(a)
	wa._sincroniza_carrinhos()
	check(not est.parado_por_area(), "sem a área: volta a andar")


func _salva() -> void:
	est.stock["prata"] = 12.0
	salvo = {"pos": est.global_position, "total": est.total_moved}
	root.get_node("SaveManager").save_game("teste")


func _carregado() -> void:
	print("== depois de carregar")
	var hub = g("village_hub")
	var e2 = hub.ferrovia_de("S2")
	check(e2 != null and e2.global_position == salvo.pos, "a estação do S2 voltou no lugar")
	check(e2 != null and absf(e2.total_moved - salvo.total) < 0.5 and float(e2.stock.get("prata", 0.0)) >= 11.0, "com o total e a carga")
	check(get_nodes_in_group("ferrovias").size() == 1, "uma estação só (não duplicou)")
	check(hub.ferrovia_proximo() == "S3", "o próximo continua o S3")
