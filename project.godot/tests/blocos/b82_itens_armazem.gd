extends SceneTree
## Bloco 82: catálogo de itens (items.gd), itens processados guardados FORA do stock de minério (dicionário
## `itens` de cada armazém), Economia somando/guardando/tirando/vendendo, janela do armazém em grade por
## categoria (zero esmaecido, vender por tipo e por categoria) e save (com e sem a chave nova).
## RODAR SÓ COM APPDATA ISOLADO.
const Items := preload("res://scripts/core/items.gd")
const Ores := preload("res://scripts/core/ores.gd")
const Icones := preload("res://scripts/ui/icones.gd")
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


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 200.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var eco = g("economy")
	var arms: Array = get_nodes_in_group("armazens")
	if step == 0 and t > 2.0:
		print("== catálogo")
		var cats := {}
		var sem_icone := []
		for id in Items.ITENS:
			var it: Dictionary = Items.ITENS[id]
			cats[it.cat] = true
			if not (it.has("nome") and it.has("icone") and it.has("preco") and it.has("onde") and Items.CATEGORIAS.has(it.cat)):
				check(false, "item %s completo" % id)
			var tex: Texture2D = Icones.tex(Items.icone(id))
			if tex == null:
				sem_icone.append(id)
		check(Ores.TYPES.all(func(o): return Items.categoria(o) == "minerio" and Items.onde(o) == "stock"), "todos os minérios no catálogo (minério, no stock)")
		check(["barra_ferro", "barra_cobre", "aco", "barra_prata", "lingote_solar", "prego"].all(func(i): return Items.onde(i) == "itens"),
			"itens novos (barras, aço, lingote, prego) como processados")
		check(Items.categoria("madeira") == "madeira" and Items.categoria("comida_crua") == "comida" and Items.categoria("couro") == "pecas"
			and Items.categoria("pecas_raras") == "pecas" and Items.categoria("aco") == "metal", "madeira, comida crua, couro e peças raras nas categorias")
		check(["minerio", "metal", "madeira", "comida", "pecas"].all(func(c): return cats.has(c)), "categorias usadas: %s" % [cats.keys()])
		check(sem_icone.is_empty(), "todo item tem ícone (faltando: %s)" % [sem_icone])
		print("== guardar fora do stock, em vários armazéns")
		var a1: Node2D = arms[0]
		var a2: Node2D = load("res://scenes/props/armazem.tscn").instantiate()
		a2.name = "ArmazemTeste"
		a2.position = a1.global_position + Vector2(260, 140)
		a1.get_parent().add_child(a2)
		set_meta("a2", a2)
		for a in [a1, a2]:
			for o in a.stock:
				a.stock[o] = 0.0
			a._recount()
		a1.stock["ferro"] = 40.0
		a1._recount()
		var minerio0: float = eco.stored_ore("")
		check(eco.add_item("barra_ferro", 6.0, a1.global_position) and eco.add_item("barra_ferro", 4.0, a2.global_position + Vector2(5, 5)),
			"guardou 6 + 4 barras de ferro (no armazém mais perto)")
		check(a1.item_count("barra_ferro") == 6.0 and a2.item_count("barra_ferro") == 4.0, "cada armazém com a sua parte (6 e 4)")
		check(eco.quantidade("barra_ferro") == 10.0, "a vila soma 10 barras")
		check(eco.stored_ore("") == minerio0 and a1.total_stored == 40.0, "barra NÃO conta como minério (pilha, marcos e custos intactos)")
		check(not eco.add_item("ferro", 5.0), "minério não entra pelo add_item (vai pelo stock)")
		check(eco.take_item("barra_ferro", 7.0) == 7.0 and eco.quantidade("barra_ferro") == 3.0, "tirou 7 dos dois armazéns, sobram 3")
		eco.add_item("barra_ferro", 7.0)
		eco.add_item("barra_cobre", 5.0)
		eco.add_item("prego", 30.0)
		a1.wood_stored = 25.0
		a1.raw_stored = 12.0
		a1.leather_stored = 4.0
		g("finds").rare_parts = 3
		check(eco.quantidade("madeira") == 25.0 and eco.quantidade("comida_crua") == 12.0 and eco.quantidade("couro") == 4.0
			and eco.quantidade("pecas_raras") == 3.0 and eco.quantidade("ferro") == 40.0, "quantidade() lê madeira, comida crua, couro, peças raras e minério")
		print("== janela do armazém")
		var hud = g("hud")
		hud.open_panel("armazem")
		var p = hud._panels["armazem"]
		p.refresh()
		check(Items.ITENS.keys().all(func(i): return p._rows.has(i)), "uma célula por item do catálogo")
		check(p._secoes.has("minerio") and p._secoes.has("metal") and p._secoes.has("pecas") and not p._secoes.has("equipamento"),
			"seções por categoria (equipamento só quando houver item)")
		var cf: Dictionary = p._rows["barra_ferro"]
		var cz: Dictionary = p._rows["aco"]
		check(cf.label.text == "10" and cf.cell.modulate.a == 1.0 and not cf.button.disabled, "barra de ferro: 10, nítida, botão Vender ativo")
		check(cz.label.text == "0" and cz.cell.modulate.a < 0.5 and cz.button.disabled, "aço: 0, esmaecido, Vender desligado")
		check(p._rows["madeira"].button == null and "não se vende" in p._rows["madeira"].price.text, "madeira: sem Vender ('não se vende')")
		check(p._rows["barra_ferro"].name.text == "Barra de ferro" and p._rows["ferro"].cell.get_child(0) != null, "célula com ícone, nome e quantidade")
		check(p._sell_all == p._secoes["minerio"].button and "80" in p._sell_all.text, "minério: 'Vender tudo' (+80 cr) no título ('%s')" % p._sell_all.text)
		print("  metal: ", p._secoes["metal"].button.text)
		print("== vender")
		var c0: float = eco.credits
		cf.button.pressed.emit()
		check(p._sel_id == "barra_ferro" and p._sel_qtd == 10, "'Vender…' seleciona o item na barra de venda (quantidade = tudo: %d)" % p._sel_qtd)
		p._sel_qtd = 4
		p.vender_selecionado()
		check(is_equal_approx(eco.credits - c0, 4.0 * Items.preco_base("barra_ferro")) and eco.quantidade("barra_ferro") == 6.0,
			"escolheu 4: vendeu 4 barras (+%d cr), ficaram 6" % (eco.credits - c0))
		check(eco.sell("ferro", 15.0) == 15.0 * eco.ore_price and eco.quantidade("ferro") == 25.0, "Economy.sell(minério, 15) vende só 15")
		g("armazens").stock["ferro"] = 40.0
		g("armazens")._recount()
		c0 = eco.credits
		p._sel_tudo.pressed.emit()
		p.vender_selecionado()
		var ganho: float = eco.credits - c0
		check(is_equal_approx(ganho, 6.0 * Items.preco_base("barra_ferro")) and eco.quantidade("barra_ferro") == 0.0 and eco.quantidade("ferro") == 40.0,
			"'Tudo': vendeu as 6 que restavam (+%d cr), minério intocado" % ganho)
		check(cf.cell.modulate.a < 0.5, "depois de vender, a célula esmaece")
		eco.precos_itens = {"barra_cobre": 20.0}
		check(eco.price_of("barra_cobre") == 20.0, "preço de um item trocado na Economia (precos_itens)")
		c0 = eco.credits
		eco.sell_all()
		check(eco.credits - c0 == 80.0 and eco.quantidade("barra_cobre") == 5.0 and eco.quantidade("prego") == 30.0, "'Vender tudo' continua sendo só o minério (+80 cr)")
		c0 = eco.credits
		p._secoes["metal"].button.pressed.emit()
		check(eco.credits - c0 == 100.0 and eco.quantidade("barra_cobre") == 0.0 and eco.quantidade("prego") == 30.0, "vender a categoria metal: +100 cr, prego fica")
		check(eco.sell("madeira") == 0.0 and eco.quantidade("madeira") == 25.0, "madeira não se vende")
		eco.precos_itens = {}
		print("== save")
		eco.add_item("aco", 3.0, a1.global_position)
		eco.add_item("lingote_solar", 2.0, a1.global_position)
		set_meta("pregos", eco.quantidade("prego"))
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		var sv: Dictionary = data.armazens.get(String(a1.name), {})
		check(sv.has("itens") and int(sv.itens.get("aco", 0)) == 3 and int(sv.itens.get("lingote_solar", 0)) == 2, "save: 'itens' no armazém (%s)" % [sv.get("itens")])
		set_meta("data", data)
		for a in arms:
			a.itens.clear()
		root.get_node("SaveManager").load_game()
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 2.0:
		var a1: Node2D = arms[0]
		check(a1.item_count("aco") == 3.0 and a1.item_count("lingote_solar") == 2.0, "load: aço e lingote de volta no armazém")
		print("== save antigo (sem 'itens')")
		var data: Dictionary = get_meta("data")
		for k in data.armazens:
			data.armazens[k].erase("itens")
		var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(data))
		fw.close()
		root.get_node("SaveManager").load_game()
		step = 2
		t_mark = t
	elif step == 2 and t - t_mark > 2.0:
		var vazio := true
		for a in get_nodes_in_group("armazens"):
			if not a.itens.is_empty():
				vazio = false
		check(vazio and eco.quantidade("aco") == 0.0, "save antigo: armazéns sem itens processados, sem erro")
		check(eco.stored_ore("ferro") >= 0.0 and get_nodes_in_group("armazens").size() >= 1, "save antigo: minério de sempre carregou")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
