extends SceneTree
## Bloco 72: a mina como a referência — os andares UM EMBAIXO DO OUTRO, debaixo da vila, em forma de
## caverna, ligados por um poço de elevador reto (e a escada em espiral ao lado). Confere: cada andar na
## vista debaixo da vila (não no canto do mapa), as gaiolas de todos na mesma vertical da torre do
## elevador da superfície, todo conteúdo dentro do chão da caverna, a navegação pelo contorno (rocha não
## anda), a ida e volta lógica <-> vista, e a terra/poço/espiral montados. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const Niveis := preload("res://scripts/core/niveis.gd")
var main: Node
var t := 0.0
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


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if t > 4.0:
		_lugar()
		_poco()
		_cavernas()
		_navegacao()
		_vista()
		print("FALHAS: %d" % fails)
		return true
	return false


func _lugar() -> void:
	print("== a coluna debaixo da vila")
	var env = g("environment")
	var iso = main.get_node("IsoView")
	var vila_x: float = iso.to_screen(g("village_hub").global_position).x
	var esc_x: float = iso.to_screen(g("escavadeira").global_position).x
	var elev_x: float = iso.to_screen(g("elevador").global_position).x
	var leste_x: float = iso.to_screen(Vector2(env.leste_x() + 400.0, 0)).x
	for lv in iso._levels:
		var c: float = Rect2(lv.sprite.position, lv.sprite.texture.get_size()).get_center().x
		check(c > esc_x - 900.0 and c < elev_x + 300.0 and c < leste_x, "%s debaixo da vila (centro na tela %.0f; vila %.0f, elevador %.0f)" % [lv.nome, c, vila_x, elev_x])
		check(float(lv.k) < 1.0, "%s mais compacto (escala %.2f)" % [lv.nome, lv.k])
	var ys := []
	for lv in iso._levels:
		ys.append(lv.sprite.position.y)
	var ordem := true
	for i in range(1, ys.size()):
		ordem = ordem and ys[i] > ys[i - 1]
	check(ordem, "um embaixo do outro (S2, S3, S4, S5 descendo na tela)")


func _poco() -> void:
	print("== o poço do elevador")
	var iso = main.get_node("IsoView")
	var topo: float = iso.to_screen(g("elevador").global_position).x
	var xs := [iso.to_screen(g("elevador").bottom_position).x]
	for grupo in ["elevador_abismo", "elevador_s4", "elevador_s5"]:
		var e = g(grupo)
		if e:
			xs.append(iso.to_screen(e.bottom_position).x)
	var alinhado := true
	for x in xs:
		alinhado = alinhado and absf(x - topo) < 6.0
	check(xs.size() == 4 and alinhado, "as 4 gaiolas na vertical da torre da vila (%s; torre %.0f)" % [str(xs.map(func(x): return roundi(x))), topo])
	var nomes := []
	for c in iso._terrain_node.get_children():
		nomes.append(String(c.name))
	check(nomes.has("Poco") and nomes.has("Espiral") and nomes.has("TerraColuna") and nomes.has("TerraFaixa"), "poço, espiral e a terra da coluna montados")


func _cavernas() -> void:
	print("== cavernas")
	var env = g("environment")
	var fora := []
	var total := 0
	for grupo in ["minerios", "zonas_perigo", "pocas_perigo", "nivel_deco"]:
		for n in main.get_tree().get_nodes_in_group(grupo):
			var p: Vector2 = (n as Node2D).global_position
			if env.level_of(p).is_empty():
				continue
			total += 1
			if not env.dentro_da_caverna(p):
				fora.append(String(n.name))
	for grupo in ["elevador", "elevadores"]:
		for e in main.get_tree().get_nodes_in_group(grupo):
			for p in [e.bottom_position, (e as Node2D).global_position]:
				if not env.level_of(p).is_empty():
					total += 1
					if not env.dentro_da_caverna(p):
						fora.append(String(e.name))
	check(total > 40 and fora.is_empty(), "todo o conteúdo dos andares no chão da caverna (%d; fora: %s)" % [total, str(fora)])
	for nome in ["nivel2", "abismo", "s4", "s5"]:
		var a: Dictionary = env.andares.andares[nome]
		var r := Rect2(a.rect[0], a.rect[1], a.rect[2], a.rect[3])
		var pol: PackedVector2Array = env.contorno_do_andar(r)
		var area := 0.0
		for i in pol.size():
			area += pol[i].x * pol[(i + 1) % pol.size()].y - pol[(i + 1) % pol.size()].x * pol[i].y
		var k := absf(area) * 0.5 / r.get_area()
		check(pol.size() >= 24 and k > 0.45 and k < 0.92, "%s: caverna (contorno %d pontos, %.0f%% do retângulo: nem quadrado nem pequena)" % [nome, pol.size(), k * 100.0])
		check(not env.dentro_da_caverna(r.position + Vector2(8, 8)), "%s: o canto do retângulo é rocha" % nome)


func _navegacao() -> void:
	print("== navegação")
	var env = g("environment")
	var map: RID = main.get_world_2d().navigation_map
	var r: Rect2 = env.deep_rect
	var canto := r.position + Vector2(10, 10)
	var q := NavigationServer2D.map_get_closest_point(map, canto)
	check(q.distance_to(canto) > 30.0 and env.dentro_da_caverna(q), "clique na rocha leva pro chão da caverna (%s -> %s)" % [str(canto), str(q.round())])
	var vila: Vector2 = g("village_hub").global_position + Vector2(0, 80)
	var alvo: Vector2 = Niveis.por_id("S2").rect.get_center()
	var cam := NavigationServer2D.map_get_path(map, vila, alvo, true)
	check(not cam.is_empty() and cam[cam.size() - 1].distance_to(alvo) < 30.0, "da vila até o meio do S2 pelo elevador")


func _vista() -> void:
	print("== lógica <-> vista")
	var env = g("environment")
	var ok := true
	for p in [Vector2(100, 1000), Vector2(-200, 1700), Vector2(50, 2400), Vector2(-100, 2950)]:
		var lv: Dictionary = env.level_of(p)
		var volta: Vector2 = env.logic_from_view(env.view_ground(p), float(lv.z_chao))
		ok = ok and volta.distance_to(p) < 0.5
	check(ok, "ida e volta lógica -> vista -> lógica em todos os andares")
