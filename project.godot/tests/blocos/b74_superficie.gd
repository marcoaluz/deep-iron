extends SceneTree
## Bloco 74: a superfície da maquete v3 aprovada pelo Marco (docs/arte/bloco72/maquete/superficie_v3_legenda.jpg)
## — FLORESTA | VILA | MINA, de oeste pra leste. Confere: as áreas do mapa (a floresta a oeste da paliçada de
## norte a sul, a vila, a mina, o leste trancado depois dela), o que fica em cada área (árvores e tocas na
## floresta; Centro, casas e prédios na vila, SEM jazida; todas as jazidas, as galerias e o armazém na mina),
## carvão à esquerda da boca e cobre à direita, o ÚNICO portão (paliçada bloqueia, o portão passa, o caminho
## da floresta pra vila passa por ele), a montanha em degraus (6, 12, 18) com as escadas chegando nas
## galerias, o vagonete fixo da boca até a porta do armazém (o minerador entrega, o vagonete leva), o portão
## de lado com os guardas do lado da vila, as criaturas saindo da floresta, o clima na superfície toda,
## construir (floresta e montanha não) e o save do mapa antigo (casa que caiu na floresta vai pra vila).
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var t_mark := 0.0
var fails := 0
var est: Node
var arm: Node
var antes := 0.0


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
	return main.get_tree().get_first_node_in_group(grupo)


func gs(grupo: String) -> Array:
	return main.get_tree().get_nodes_in_group(grupo)


func env() -> Node:
	return g("environment")


func _caminho(de: Vector2, ate: Vector2) -> PackedVector2Array:
	return NavigationServer2D.map_get_path(main.get_world_2d().navigation_map, de, ate, true)


func _chega(de: Vector2, ate: Vector2, folga := 30.0) -> bool:
	var p := _caminho(de, ate)
	return not p.is_empty() and p[p.size() - 1].distance_to(ate) < folga


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 4.0:
				_areas()
				_conteudo()
				_palicada()
				_montanha()
				_vagonete_monta()
				_portao_guardas()
				_clima_criaturas()
				_construir()
				_save_antigo()
				step = 1
				t_mark = t
		1:
			if t - t_mark > 14.0:
				_vagonete_levou()
				print("FALHAS: %d" % fails)
				return true
	return false


func _areas() -> void:
	print("== as três áreas (maquete v3)")
	var e := env()
	check(e.vertical_palisade(), "paliçada de norte a sul (mapa.json: palicada x=%s, portão em y=%s)" % [e.palisade_x, e.gate_y])
	var a: Dictionary = e.areas
	check(a.has("floresta") and a.has("vila") and a.has("mina"), "áreas floresta | vila | mina (%s)" % [a.keys()])
	if not (a.has("floresta") and a.has("vila") and a.has("mina")):
		return
	check(float(a.floresta[1]) == e.palisade_x and float(a.vila[0]) == e.palisade_x, "a paliçada separa a floresta da vila")
	check(float(a.vila[0]) < float(a.vila[1]) and float(a.vila[1]) <= float(a.mina[0]) + 0.01, "de oeste pra leste: floresta, vila, mina")
	check(absf(e.leste_x() - float(a.mina[1])) < 1.0, "o leste trancado começa onde a mina acaba (x=%d)" % e.leste_x())
	var cr: Rect2 = e.clearing_rect
	check(cr.end.x <= e.palisade_x + 0.5 and cr.size.y > 1200.0, "a floresta das criaturas é a faixa do oeste (%s)" % cr)
	var vila_w: float = float(a.vila[1]) - float(a.vila[0])
	check(vila_w >= 800.0, "vila larga pra construir: %d px de largura x %d de fundo" % [vila_w, e.iso_ground_rect().size.y])
	var gr: Rect2 = e.iso_ground_rect()
	var vila_degraus := {}
	for x in range(int(a.vila[0]) + 20, int(a.vila[1]) - 20, 40):
		for y in range(int(gr.position.y) + 20, int(gr.end.y) - 20, 40):
			vila_degraus[int(e.tile_level(e.tile_at(Vector2(x, y))))] = true
	check(vila_degraus.keys() == [0], "a vila é plana, sem terraços (degraus achados: %s)" % [vila_degraus.keys()])


func _conteudo() -> void:
	print("== o que fica em cada área")
	var e := env()
	var na := func(n: Node) -> String: return e.surface_area((n as Node2D).global_position)
	var arv := gs("arvores").filter(func(n): return not n.is_in_group("leste_conteudo"))
	check(not arv.is_empty() and arv.all(func(n): return na.call(n) == "floresta"), "as %d árvores que dão madeira estão na floresta" % arv.size())
	var tocas := gs("caca").filter(func(n): return not n.is_in_group("leste_conteudo"))
	check(not tocas.is_empty() and tocas.all(func(n): return na.call(n) == "floresta"), "as tocas estão na floresta (%d)" % tocas.size())
	check(na.call(g("village_hub")) == "vila", "o Centro da Vila na vila")
	check(gs("casas").all(func(n): return na.call(n) == "vila"), "as casas na vila")
	for grupo in ["oficina", "enfermarias", "comedouros", "escavadeira"]:
		var ns := gs(grupo)
		check(ns.all(func(n): return na.call(n) == "vila"), "%s na vila" % grupo)
	var jaz := gs("minerios").filter(func(n): return e.level_of(n.global_position).is_empty() and not n.is_in_group("leste_conteudo"))
	var fora := jaz.filter(func(n): return na.call(n) != "mina").map(func(n): return String(n.name))
	check(jaz.size() >= 14 and fora.is_empty(), "todas as %d jazidas da superfície na mina, nenhuma na vila %s" % [jaz.size(), fora])
	var tipos := {}
	for j in jaz:
		tipos[j.ore_type] = true
	check(tipos.has("carvao") and tipos.has("cobre") and tipos.has("ferro"), "na montanha: carvão, cobre e ferro (o ferro é o minério de base) %s" % [tipos.keys()])
	var gal := jaz.filter(func(n): return n.gallery_name != "")
	check(gal.size() == 4, "as 4 galerias na mina (%s)" % [gal.map(func(n): return n.gallery_name)])
	arm = g("armazens")
	check(arm != null and na.call(arm) == "mina", "o armazém é da mina")
	var bocas: Array = e.bocas_da_mina()
	check(bocas.size() == 5, "5 bocas na montanha (a principal + as das 4 galerias)")
	if bocas.is_empty():
		return
	var boca: Vector2 = bocas[0]
	check(arm.global_position.distance_to(boca) < 300.0 and arm.global_position.y > boca.y, "o armazém logo na frente da boca principal (%d px)" % arm.global_position.distance_to(boca))
	var pe := jaz.filter(func(n): return n.gallery_name == "" and n.global_position.y < boca.y + 120.0)
	var carvao := pe.filter(func(n): return n.ore_type == "carvao")
	var cobre := pe.filter(func(n): return n.ore_type == "cobre")
	check(not carvao.is_empty() and carvao.all(func(n): return n.global_position.x < boca.x), "carvão no pé da montanha, à esquerda da boca")
	check(not cobre.is_empty() and cobre.all(func(n): return n.global_position.x > boca.x), "cobre no pé da montanha, à direita da boca")
	for gn in gal:  # cada galeria na frente de uma boca
		var perto: float = bocas.map(func(b): return (b as Vector2).distance_to(gn.global_position)).min()
		check(perto < 40.0, "galeria %s na frente da boca dela (%d px)" % [gn.gallery_name, perto])


func _palicada() -> void:
	print("== a paliçada e o único portão")
	var e := env()
	var gate: Node2D = g("defense").gate("tunel")
	check(gate != null and absf(gate.global_position.x - e.palisade_x) < 2.0 and absf(gate.global_position.y - e.gate_y) < 2.0,
		"o portão da floresta na abertura da paliçada")
	check(e.on_palisade(Vector2(e.palisade_x, e.gate_y - 300.0)) and not e.on_palisade(Vector2(e.palisade_x, e.gate_y)), "fora do portão é paliçada; no portão, passa")
	var de := Vector2(e.palisade_x - 220.0, e.gate_y - 500.0)
	var ate := Vector2(e.palisade_x + 220.0, e.gate_y - 500.0)
	var p := _caminho(de, ate)
	var pelo_portao := false
	for q in p:
		if absf(q.x - e.palisade_x) < 30.0 and absf(q.y - e.gate_y) < e.gate_half_width + 10.0:
			pelo_portao = true
	check(_chega(de, ate) and pelo_portao, "da floresta pra vila o caminho passa pelo portão (%d pontos)" % p.size())


func _montanha() -> void:
	print("== a montanha em degraus")
	var e := env()
	var bocas: Array = e.bocas_da_mina()
	var alturas := {}
	for gn in gs("minerios").filter(func(n): return n.gallery_name != ""):
		alturas[gn.gallery_name] = int(e.tile_level(e.tile_at(gn.global_position)))
	check(alturas.values().has(0) and alturas.values().has(6) and alturas.values().has(12), "galerias no pé (0), no 1º degrau (6) e no 2º (12): %s" % [alturas])
	var topo := Vector2(980, -800)
	check(int(e.tile_level(e.tile_at(topo))) == 18, "o alto da montanha: 18 degraus")
	var vila: Vector2 = g("village_hub").global_position + Vector2(0, 80)
	for gn in gs("minerios").filter(func(n): return n.gallery_name != ""):
		check(_chega(vila, gn.global_position, 40.0), "da vila até a galeria %s (pelas escadas)" % gn.gallery_name)
	check(e.spot_ok(topo, 8.0, true), "o alto dos degraus anda (não é mais o paredão do mapa antigo)")


func _vagonete_monta() -> void:
	print("== o vagonete da boca até o armazém")
	var e := env()
	est = g("ponto_carga_fixo")
	check(est != null and est.is_in_group("pontos_carga"), "o ponto de carga fixo da mina")
	if est == null:
		return
	var boca: Vector2 = (e.bocas_da_mina() as Array)[0]
	check(est.global_position.distance_to(boca) < 50.0, "na frente da boca principal")
	check(not g("village_hub").vagonetes().has(est), "fora da lista dos que o jogador constrói (custo e save à parte)")
	var r: Node = est.rail
	check(r != null and r.points.size() == 3, "o trilho: da boca, reto pro sul e vira pra porta")
	if r == null or r.points.size() < 3:
		return
	check(absf(r.points[0].y - boca.y) < 8.0 and absf(r.points[0].x - r.points[1].x) < 0.5 and env().height_at(r.points[0]) == 0.0,
		"sai do batente da boca (no chão, não em cima da montanha) e desce reto")
	check(r.points[2].distance_to(arm.global_position + Vector2(0, 30)) < 1.0, "termina na porta do armazém")
	# carga esperando: o vagonete sai sozinho e descarrega no armazém
	antes = float(arm.stock.get("cobre", 0.0))
	est.stock = {"cobre": 30.0}
	est._wait_t = 0.0
	Engine.time_scale = 4.0


func _vagonete_levou() -> void:
	Engine.time_scale = 1.0
	if est == null:
		return
	var depois := float(arm.stock.get("cobre", 0.0))
	check(depois >= antes + 24.0, "o vagonete levou o cobre até o armazém (%d -> %d, levou %d no total)" % [antes, depois, est.total_moved])


func _portao_guardas() -> void:
	print("== o portão de lado e os guardas do lado da vila")
	var gate: Node2D = g("defense").gate("tunel")
	check(gate.get("vertical") == true and gate.inside_dir() == Vector2.RIGHT, "portão numa paliçada de norte a sul: a vila fica a leste")
	var l: Array = preload("res://scripts/iso/iso_art.gd").layers(gate)
	check(not l.is_empty() and l[0].get("flip", false), "a arte do portão vem virada de lado")
	var w = gs("ipezinhos")[0]
	w.set_job("guarda")
	var post: Vector2 = g("defense").guard_post(w)
	check(post.x > gate.global_position.x + 10.0, "o posto do guarda fica do lado da vila (%s)" % post)


func _clima_criaturas() -> void:
	print("== criaturas da floresta, clima na superfície toda")
	var e := env()
	var d = g("defense")
	var c: Node2D = d._spawn("lumivoro")
	check(c.global_position.x < e.palisade_x, "o lumívoro nasce na floresta (x=%d)" % c.global_position.x)
	c.queue_free()
	var w = g("weather")
	if w:
		check(w._rect == e.open_sky_rect() and w._rect.has_point(g("armazens").global_position) and w._rect.has_point(g("village_hub").global_position),
			"o clima cobre floresta, vila e mina (%s)" % w._rect)


func _construir() -> void:
	print("== onde constrói")
	var e := env()
	var fp := Rect2(-560, -400, 60, 40)
	check(e.in_forest(fp), "na floresta não (é mata)")
	var monte := Rect2(950, -780, 60, 40)
	check(e.footprint_reason(monte) != "", "na montanha não: '%s'" % e.footprint_reason(monte))
	var vila := Rect2(260, -820, 60, 40)
	check(e.footprint_reason(vila) == "" and not e.in_forest(vila), "no norte da vila (espaço novo): pode")


func _save_antigo() -> void:
	print("== save do mapa antigo")
	var e := env()
	var hub = g("village_hub")
	var casa: Node2D = hub.spawn_house(Vector2(-560, -380), "CasaDoMapaAntigo", false)
	check(casa != null and casa.global_position.x < e.palisade_x, "uma casa do mapa antigo, onde hoje é floresta")
	e.migrated.clear()
	e.migrate_positions()
	check(casa.global_position.x > e.palisade_x and e.surface_area(casa.global_position) == "vila",
		"ao carregar ela vai pro lugar livre da vila mais perto (%s)" % casa.global_position.round())
	check(e.migrated.any(func(m): return m.nome == "CasaDoMapaAntigo"), "fica anotado em migrated")
