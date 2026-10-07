extends SceneTree
## Bloco 89: CAMINHOS pintados (terra batida, cascalho, pedra) — pintar/apagar arrastando com custo por célula,
## bônus de velocidade por tipo (Trilhas batidas aumenta o bônus, não acelera mais todo mundo), sem mexer na
## navegação, prédio por cima apaga o trecho, o passeio da hora social segue o caminho, save compacto.
## RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func menu_card(menu, tab: String, name: String) -> Dictionary:
	menu.visible = true
	menu._show_tab(menu.TAB_NAMES.find(tab))
	menu.refresh()
	for c in menu._cards:
		if c.def.name == name:
			return c
	return {}


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 300.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var cam = g("caminhos")
	var pl = g("caminho_placer")
	var hub = g("village_hub")
	var eco = g("economy")
	var env = g("environment")
	if step == 0 and t > 2.0:
		print("== pintar")
		check(cam != null and pl != null and cam.celulas.is_empty(), "sistema de caminhos e a ferramenta no jogo")
		var hud = g("hud")
		check(not menu_card(hud._build_menu, "Vila", "Caminho: cascalho").is_empty() and not menu_card(hud._build_menu, "Vila", "Apagar caminhos").is_empty(),
			"menu CONSTRUIR (aba Vila): caminhos e apagar")
		hud._build_menu.visible = false
		eco.credits = 1000.0
		var arm = g("armazens")
		arm.stock["ferro"] = 500.0
		arm._recount()
		var nav0 = env.navigation_region.navigation_polygon
		var a: Vector2 = hub.global_position + Vector2(-60, 150)
		var b: Vector2 = a + Vector2(200, 0)
		pl.begin("terra")
		var c0: float = eco.credits
		var n: int = pl.pinta_ate(a)
		n += pl.pinta_ate(b)
		print("  %d células de terra; créditos %d -> %d" % [n, c0, eco.credits])
		check(n >= 9 and cam.celulas.size() == n, "arrastar pinta as células da linha sem pular (%d)" % n)
		check(is_equal_approx(c0 - eco.credits, n * cam.custo("terra").x), "custo por célula (%s cada)" % cam.custo_texto("terra"))
		check(env.navigation_region.navigation_polygon == nav0, "pintar não refaz a navegação")
		pl.cancel()
		print("== velocidade")
		var w = get_nodes_in_group("ipezinhos")[0]
		w.global_position = cam.centro_de(cam.celula_de(a + Vector2(40, 0)))
		var v_terra: float = w._speed_bonus()
		w.global_position = a + Vector2(0, -200)
		var v_fora: float = w._speed_bonus()
		check(is_equal_approx(v_terra, 1.0 + cam.bonus["terra"]) and is_equal_approx(v_fora, 1.0), "no caminho de terra: x%.2f; fora: x%.2f" % [v_terra, v_fora])
		hub.upgrades.trilhas = 2
		w.global_position = cam.centro_de(cam.celula_de(a + Vector2(40, 0)))
		var v_trilhas: float = w._speed_bonus()
		check(v_trilhas > v_terra and is_equal_approx(hub.speed_mult(), 1.0), "Trilhas nível 2 aumenta o bônus do caminho (x%.2f) e não acelera mais todo mundo" % v_trilhas)
		hub.upgrades.trilhas = 0
		print("== cascalho e pedra")
		var f0: float = arm.stock["ferro"]
		pl.begin("pedra")
		var np: int = pl.pinta_ate(a + Vector2(0, 40))
		np += pl.pinta_ate(a + Vector2(60, 40))
		pl.cancel()
		check(np >= 3 and arm.stock["ferro"] == f0 - np * cam.custo("pedra").y and cam.tipo_em(a + Vector2(10, 40)) == "pedra", "pedra custa ferro (%d células)" % np)
		w.global_position = cam.centro_de(cam.celula_de(a + Vector2(10, 40)))
		check(is_equal_approx(w._speed_bonus(), 1.0 + cam.bonus["pedra"]) and cam.bonus["pedra"] > cam.bonus["terra"], "pedra é a mais rápida (x%.2f)" % w._speed_bonus())
		print("== apagar")
		var c1: float = eco.credits
		var total0: int = cam.celulas.size()
		pl.begin("apagar")
		var na: int = pl.pinta_ate(a + Vector2(0, 40))
		na += pl.pinta_ate(a + Vector2(60, 40))
		pl.cancel()
		check(na == np and cam.celulas.size() == total0 - np and eco.credits == c1, "apagou o trecho de pedra (sem devolução)")
		print("== prédio por cima apaga o trecho")
		var antes: int = cam.celulas.size()
		var pq = g("morale").spawn_park(a + Vector2(100, 0))
		var depois: int = cam.celulas.size()
		print("  parque em cima: %d -> %d células" % [antes, depois])
		check(depois < antes and cam.tipo_em(a + Vector2(100, 0)) == "", "o parque apagou o trecho embaixo dele")
		check(not cam.pintar(cam.celula_de(a + Vector2(100, 0)), "terra"), "não dá pra pintar embaixo de prédio")
		print("== o passeio segue o caminho")
		cam.celulas.clear()
		var spot = get_nodes_in_group("social_spots").filter(func(s): return s.tipo == "refeitorio")[0]
		var origem: Vector2 = spot.centro() + Vector2(260, 60)
		pl.begin("cascalho")
		pl.pinta_ate(origem)
		pl.pinta_ate(origem + Vector2(-130, -20))
		pl.pinta_ate(spot.centro() + Vector2(0, 10))
		pl.cancel()
		var rota: PackedVector2Array = cam.rota(origem, spot.centro())
		check(rota.size() >= 3 and rota.size() > 0 and Array(rota).all(func(q): return cam.tipo_em(q) == "cascalho"), "rota pelos caminhos: %d pontos em cima do cascalho" % rota.size())
		var w2 = get_nodes_in_group("ipezinhos")[1]
		w2.global_position = origem
		for s in get_nodes_in_group("social_spots"):
			if s != spot:
				s.remove_from_group("social_spots")
		w2._ai_state = "social"
		w2._spot = null
		w2._social_vai()
		var no_caminho := Array(w2._passeio).filter(func(q): return cam.tipo_em(q) == "cascalho").size()
		check(w2._spot == spot and no_caminho >= 2, "o passeio usa os pontos do caminho (%d de %d)" % [no_caminho, w2._passeio.size()])
		print("== save compacto")
		var n_cel: int = cam.celulas.size()
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		check(data.has("caminhos") and data.caminhos.cascalho.size() == n_cel and data.caminhos.terra.is_empty() and data.caminhos.cascalho[0] is Array,
			"save: lista de células por tipo (%d de cascalho)" % data.caminhos.cascalho.size())
		set_meta("n", n_cel)
		cam.celulas.clear()
		root.get_node("SaveManager").load_game()
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 2.0:
		check(cam.celulas.size() == get_meta("n"), "load: os caminhos voltaram (%d)" % cam.celulas.size())
		var d: Dictionary = cam.get_save_data()
		d.erase("cascalho")
		cam.load_save_data({})
		check(cam.celulas.is_empty(), "save antigo: sem caminhos")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
