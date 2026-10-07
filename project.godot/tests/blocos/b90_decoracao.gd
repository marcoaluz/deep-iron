extends SceneTree
## Bloco 90: DECORAÇÃO construída pelo jogador — catálogo (decor.gd), aba Decoração (e Produção/Culto no menu),
## pôr várias em sequência sem engenheiro, remover com reembolso, tochas/lampiões acendendo com o torch_level,
## Lumívoro atraído pela luz (e apagando ela), banco/mesa como ponto social, beleza perto de casa com teto,
## navegação só das peças grandes com rebuild agrupado, tochas da seed intocadas, save próprio.
## RODAR SÓ COM APPDATA ISOLADO.
const Decor := preload("res://scripts/core/decor.gd")
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var rebuilds := 0


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


## Um lugar livre pra uma peça `id` (o posicionador diz, com a pegada dela).
func livre_para(id: String, perto: Vector2) -> Vector2:
	var placer = g("house_placer")
	var pg := Decor.pegada(id)
	placer.begin(Callable(), load(Decor.info(id).textura), 1, "teste", {"footprint": Rect2(-pg * 0.5, pg)})
	var q := livre(placer, perto)
	placer.cancel()
	return q


## Um lugar livre com a pegada que o posicionador está usando agora.
func livre(placer, perto: Vector2) -> Vector2:
	placer._collect_blockers()
	for r in range(0, 300, 10):
		for a in range(16):
			var q: Vector2 = (perto + Vector2.RIGHT.rotated(a * TAU / 16.0) * r).round()
			if placer.check_spot(q) == "":
				return q
	return Vector2.INF


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 300.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dm = g("decoracoes_mgr")
	var dn = g("day_night")
	var eco = g("economy")
	var env = g("environment")
	var hub = g("village_hub")
	var placer = g("house_placer")
	if step == 0 and t > 2.0:
		print("== catálogo e menu")
		var ids := ["tocha", "lampiao", "banco", "mesa", "cerca", "canteiro_flores", "bandeira"]
		check(ids.all(func(i): return Decor.existe(i)), "as 7 peças no catálogo")
		check(ids.all(func(i): var d: Dictionary = Decor.info(i); return d.has("nome") and load(d.textura) != null and d.has("pegada") and d.has("custo") and d.has("luz") and d.has("assentos") and d.has("beleza")),
			"cada uma com nome, textura (provisória), pegada, custo, luz, assentos e beleza")
		var menu = g("hud")._build_menu
		check(menu.TAB_NAMES.has("Decoração") and menu.TAB_NAMES.has("Produção") and menu.TAB_NAMES.has("Culto"), "menu: abas Decoração, Produção e Culto")
		check(not menu_card(menu, "Decoração", "Lampião").is_empty() and not menu_card(menu, "Decoração", "Remover decoração").is_empty(), "aba Decoração com as peças e o Remover")
		menu.visible = false
		env.navigation_region.navigation_polygon_changed.connect(func(): rebuilds += 1)
		var tochas_seed := get_nodes_in_group("tochas").size()
		set_meta("tochas_seed", tochas_seed)
		print("== pôr várias em sequência (sem engenheiro)")
		eco.credits = 9999.0
		var arm = g("armazens")
		arm.stock["ferro"] = 999.0
		arm.wood_stored = 999.0
		arm._recount()
		var nav0 = env.navigation_region.navigation_polygon
		var c0: float = eco.credits
		check(dm.comecar("tocha") and placer.active, "pôr tocha: posicionador aberto")
		var base: Vector2 = hub.global_position + Vector2(170, 90)
		var p1 := livre(placer, base)
		placer.move_to(p1)
		check(placer.try_confirm() and placer.active, "1ª tocha posta e o modo continua (repeat)")
		var p2 := livre(placer, base + Vector2(40, 0))
		placer.move_to(p2)
		check(placer.try_confirm() and placer.active, "2ª tocha em sequência")
		placer.cancel()
		check(get_nodes_in_group("decoracoes").size() == 2 and get_nodes_in_group("canteiros").is_empty(), "2 tochas prontas na hora (sem canteiro)")
		check(is_equal_approx(c0 - eco.credits, 2 * Decor.custo("tocha").x), "pagou 2 x %s" % dm.custo_texto("tocha"))
		check(env.navigation_region.navigation_polygon == nav0 and not dm.nav_pendente(), "tochas (pequenas) não mexem na navegação")
		print("== luz")
		var tocha = get_nodes_in_group("decoracoes")[0]
		check(tocha.is_in_group("decor_luzes") and tocha.get_node("Luz").is_in_group("cullable_lights"), "tocha tem luz (cullable_lights)")
		dn.time = 20.0
		dn.snap_lighting()
		dm._luz_t = 0.0
		dm._process(0.0)
		check(not tocha.acesa(), "de dia: apagada")
		dn.time = dn.day_duration + 40.0
		dn.snap_lighting()
		dm._luz_t = 0.0
		dm._process(0.0)
		check(tocha.acesa(), "de noite: acesa (torch_level %.2f)" % dn.torch_level())
		print("== Lumívoro atraído pela luz")
		for w in get_nodes_in_group("ipezinhos"):
			w.global_position = hub.global_position + Vector2(-600, -300)
		var lumi = load("res://scenes/creatures/lumivoro.tscn").instantiate()
		lumi.position = tocha.global_position + Vector2(50, 30)
		hub.get_parent().add_child(lumi)
		var alvo = lumi._pick_target()
		check(alvo != null and alvo.is_in_group("decor_luzes"), "o Lumívoro vai numa tocha acesa (foi em %s)" % (alvo.name if alvo else "nada"))
		lumi.atracao_luz = 0.0001
		var sem = lumi._pick_target()
		check(sem == null or not sem.is_in_group("decor_luzes"), "com atracao_luz quase zero, não")
		lumi.atracao_luz = 2.0
		alvo.take_hit(5.0, lumi)
		check(not alvo.acesa() and lumi._pick_target() != alvo, "ele apaga a tocha (e procura outra luz)")
		tocha = alvo
		lumi.queue_free()
		dn.time = 20.0
		dn.snap_lighting()
		dm._luz_t = 0.0
		dm._process(0.0)
		check(not tocha.apagada, "amanheceu: a luz comida volta")
		print("== banco e mesa: ponto social; peça grande na navegação (agrupado)")
		var pb := livre_para("banco", base + Vector2(0, 60))
		var banco = dm.colocar("banco", pb)
		check(banco != null and banco.get_node_or_null("PontoSocial") != null and banco.get_node("PontoSocial").tipo == "banco" and banco.get_node("PontoSocial").vagas() == 2,
			"banco vira ponto social com 2 lugares")
		rebuilds = 0
		for k in 3:
			dm.colocar("mesa", livre_para("mesa", base + Vector2(-80 - 50 * k, 100)))
		check(dm.nav_pendente() and rebuilds == 0, "3 mesas: navegação esperando (agrupada)")
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 1.5:
		check(not dm.nav_pendente() and rebuilds == 1, "um rebuild só pras 3 mesas (%d)" % rebuilds)
		print("== beleza perto de casa")
		var casa: Node = null
		var morador: Node = null
		for w in get_nodes_in_group("ipezinhos"):
			if w.has_home():
				casa = w._home
				morador = w
		check(casa != null, "tem casa com morador")
		if casa:
			var antes: float = dm.beleza_da_casa(casa)
			var pf := livre_para("canteiro_flores", casa.global_position + Vector2(60, 60))
			dm.colocar("canteiro_flores", pf)
			var depois: float = dm.beleza_da_casa(casa)
			check(depois > antes and morador.happiness_factors().any(func(f): return f[0] == "casa enfeitada"), "canteiro perto: fator 'casa enfeitada' (%.1f -> %.1f)" % [antes, depois])
			for k in 8:
				var q := livre_para("canteiro_flores", casa.global_position + Vector2(-70 + k * 10, 70))
				dm.colocar("canteiro_flores", q)
			check(is_equal_approx(dm.beleza_da_casa(casa), dm.beleza_teto), "com muita decoração: no teto (%.1f)" % dm.beleza_da_casa(casa))
		print("== remover (reembolso)")
		var peca = get_nodes_in_group("decoracoes")[0]
		var cr0: float = eco.credits
		var c := Decor.custo(peca.id)
		check(dm.remover(peca), "removeu")
		check(is_equal_approx(eco.credits - cr0, floorf(c.x * dm.reembolso)), "devolveu %d%% dos créditos" % roundi(dm.reembolso * 100.0))
		check(get_nodes_in_group("tochas").size() == get_meta("tochas_seed"), "as tochas da seed do mapa não mudaram")
		print("== save")
		var n: int = dm.pecas().size()
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		check(data.has("decoracoes") and data.decoracoes.pecas.size() == n and data.decoracoes.pecas[0].size() == 3, "save: lista própria [id, x, y] (%d)" % n)
		set_meta("n", n)
		root.get_node("SaveManager").load_game()
		step = 2
		t_mark = t
	elif step == 2 and t - t_mark > 2.0:
		check(dm.pecas().size() == get_meta("n"), "load: a decoração voltou (%d)" % dm.pecas().size())
		dm.load_save_data({})
		check(dm.pecas().is_empty(), "save antigo: sem decoração")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
