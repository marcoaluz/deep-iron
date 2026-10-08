extends SceneTree
## Bloco 94: a CADEIA DE PRODUÇÃO fechada. Carpintaria (obra em etapas, arte do PixelLab) + CARPINTEIRO /
## CARPINTEIRA (madeira -> tábuas; tábuas + pregos -> cama de tábua; só por ordem; pausa sem insumo); a cama
## trocada na casa (o carpinteiro monta, +ânimo); pregos/ferragens na casa 3, na barricada 3 e na ferrovia
## (antes da fornalha viram ferro); aço na picareta de aço, na lança de prata e nas bobinas; couro nas botas
## (a neve atrasa quem anda sem) e na mochila (+carga do minerador); save e save antigo.
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
	load("res://scripts/props/armazem.gd").limite_desligado = true  # Bloco 97: o limite do armazém não é o assunto deste teste


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func finish_canteiro(kind: String) -> bool:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			c.obra_work(c.left + 1.0)
			return true
	return false


func menu_card(menu, tab: String, name: String) -> Dictionary:
	menu.visible = true
	menu._show_tab(menu.TAB_NAMES.find(tab))
	menu.refresh()
	for c in menu._cards:
		if c.def.name == name:
			return c
	return {}


func zera(arm) -> void:
	for o in arm.stock:
		arm.stock[o] = 0.0
	arm.itens.clear()
	arm.wood_stored = 0.0
	arm.leather_stored = 0.0
	arm._recount()


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 2400.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(9.0)  # sempre de manhã, horário de trabalho
	for w in ws():
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	var eco = g("economy")
	var arm = g("armazens")
	if step == 0 and t > 2.0:
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		print("== a arte (PixelLab): carpintaria em etapas, carpinteiro e carpinteira, retratos, ícones")
		var IsoArt = load("res://scripts/iso/iso_art.gd")
		var est: Dictionary = IsoArt.entry("carpintaria").get("estados", {})
		check(est.has("obra_1") and est.has("obra_2") and est.has("obra_3") and est.has("pronto"), "predios.json: obra 1 -> 2 -> 3 -> pronto")
		check(IsoArt.KIND_OF_SCENE.get("carpintaria") == "carpintaria" and IsoArt.KIND_OF_CANTEIRO.get("carpintaria") == "carpintaria", "vista iso: cena e canteiro da carpintaria")
		var Bon = load("res://scripts/iso/iso_bonecos.gd")
		var par: Array = Bon.data().get("funcoes", {}).get("carpinteiro", [])
		check(par == ["carpinteiro", "carpinteira", "serrar"], "bonecos.json: carpinteiro/carpinteira, trabalho 'serrar'")
		for pasta in ["carpinteiro", "carpinteira"]:
			var anims: Dictionary = Bon.data().pastas.get(pasta, {}).get("anims", {})
			var ok := true
			for an in ["caminhada", "comer", "ferido", "deitar", "mancar_esq", "serrar"]:
				for d in ["SE", "NE", "SO", "NO"]:
					ok = ok and anims.get(an, {}).has(d)
			check(ok, "%s: as 6 animações nas 4 direções" % pasta)
			var cas: Dictionary = Bon.data().pastas.get("casaco_" + pasta, {}).get("anims", {})
			check(cas.has("caminhada") and cas.has("serrar"), "%s: casaco de inverno (caminhada e serrar)" % pasta)
			var nexp := 0
			for e in ["neutro", "contente", "cansado", "bravo", "ferido"]:
				for tom in ["clara", "parda", "negra"]:
					if ResourceLoader.exists("res://assets/game/ui/retratos/%s/%s__%s.png" % [pasta, e, tom]):
						nexp += 1
			check(nexp == 15, "%s: retrato com as 5 expressões x 3 peles (%d)" % [pasta, nexp])
		var Ic = load("res://scripts/ui/icones.gd")
		check(Ic.tex("carpinteiro") != null and Ic.predio("carpintaria") != null, "ícone da barra e cartão do CONSTRUIR")
		for it in ["it_tabua", "it_cama_boa", "it_mochila", "it_botas", "it_picareta_de_aco"]:
			check(Ic.tex(it) != null, "ícone %s" % it)
		print("== construir a carpintaria")
		eco.credits = 9000.0
		zera(arm)
		arm.stock["ferro"] = 400.0
		arm.wood_stored = 300.0
		arm._recount()
		hub.level = 1
		check("estágio" in hub.carpintaria_block_reason(), "estágio 1: ainda não libera ('%s')" % hub.carpintaria_block_reason())
		hub.level = 2
		var hud = g("hud")
		check(not menu_card(hud._build_menu, "Produção", "Carpintaria").is_empty(), "menu: aba Produção com a Carpintaria")
		hud._build_menu.visible = false
		check(hub.carpintaria_block_reason() == "", "estágio 2: libera")
		var c0: float = eco.credits
		check(hub.build_carpintaria(), "escolher lugar")
		var q := spot_near(arm.global_position + Vector2(-120, 60))
		g("house_placer").cancel()
		check(q.is_finite() and hub._confirm_carpintaria(q), "carpintaria encomendada (canteiro) em %s" % q)
		check(eco.credits == c0 - hub.carpintaria_credits, "gastou %d cr" % hub.carpintaria_credits)
		var cant: Node = null
		for c in get_nodes_in_group("canteiros"):
			if c.kind == "carpintaria":
				cant = c
		check(cant != null and IsoArt.kind_of(cant) == "carpintaria", "o canteiro desenha a obra da carpintaria")
		check(finish_canteiro("carpintaria") and get_nodes_in_group("carpintarias").size() == 1, "o engenheiro ergueu a carpintaria")
		var cp = g("carpintarias")
		check(not cp.is_in_group("fornalhas") and cp.panel_id == "carpintaria", "é carpintaria, não fornalha")
		print("== carpinteiro e carpinteira")
		var homem: Node = null
		var mulher: Node = null
		for w in ws():
			if w.gender == "menino" and homem == null:
				homem = w
			elif w.gender == "menina" and mulher == null:
				mulher = w
		# o gênero dos ipezinhos do começo é sorteado: sem um dos dois, força num ipezinho diferente
		if homem == null:
			homem = ws()[0] if ws()[0] != mulher else ws()[1]
			homem.gender = "menino"
		if mulher == null:
			mulher = ws()[1] if ws()[1] != homem else ws()[0]
			mulher.gender = "menina"
		mulher.set_job("carpinteiro")
		check(mulher.is_carpenter() and mulher.outfit() == "carpinteiro", "mulher vira carpinteira (roupa própria)")
		var folders: Array = Bon.folders(mulher)
		check(folders.has("carpinteira"), "a vista iso usa a arte da carpinteira (%s)" % str(folders))
		mulher.set_job("ocioso")
		homem.set_job("carpinteiro")
		check(homem.is_carpenter() and Bon.folders(homem).has("carpinteiro"), "homem vira carpinteiro")
		check(Bon.work_anim(homem) == "serrar", "o trabalho dele é serrar")
		arm.wood_stored = 30.0
		arm._recount()
		set_meta("cp", cp)
		set_meta("carp", homem)
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 30.0:
		var cp = get_meta("cp")
		var carp = get_meta("carp")
		check(eco.quantidade("madeira") == 30.0 and eco.quantidade("tabua") == 0.0, "sem ordem o carpinteiro não pega nada")
		print("== ordem: 2 levas de tábuas (3 madeira -> 4 tábuas)")
		check(cp.encomendar("tabua", 2), "encomendou 2 levas de tábuas")
		check(eco.quantidade("madeira") == 30.0, "encomendar não gasta nada")
		step = 2
		t_mark = t
	elif step == 2:
		var cp = get_meta("cp")
		var carp = get_meta("carp")
		if not cp.fila.tem_trabalho() and carp.barras_mao.is_empty():
			check(eco.quantidade("tabua") == 8.0, "fez 8 tábuas e levou pro armazém (%d)" % eco.quantidade("tabua"))
			check(eco.quantidade("madeira") == 24.0, "gastou 2 x 3 madeira")
			print("== cama de tábua: pausa sem pregos")
			check(cp.encomendar("cama_boa", 1), "encomendou 1 cama de tábua")
			check("prego" in cp.falta(), "sem pregos: PAUSADA ('%s')" % cp.falta())
			check("PAUSADA" in cp.status_text(), "a placa mostra a pausa")
			step = 3
			t_mark = t
		elif t - t_mark > 900.0:
			check(false, "a ordem de tábuas não terminou (%s, %s)" % [carp.get_state(), cp.status_text()])
			step = 99
	elif step == 3 and t - t_mark > 15.0:
		var cp = get_meta("cp")
		check(eco.quantidade("tabua") == 8.0, "pausada: nada gasto")
		eco.add_item("prego", 8.0)
		cp._acorda_fundidores()
		step = 4
		t_mark = t
	elif step == 4:
		var cp = get_meta("cp")
		var carp = get_meta("carp")
		if not cp.fila.tem_trabalho() and carp.barras_mao.is_empty():
			check(eco.quantidade("cama_boa") == 1.0 and eco.quantidade("tabua") == 2.0 and eco.quantidade("prego") == 0.0,
				"chegaram os pregos: 1 cama de tábua (6 tábuas + 8 pregos)")
			print("== trocar a cama de uma casa")
			var casa: Node = null
			for c in get_nodes_in_group("casas"):
				if c.built and not c.residents().is_empty():
					casa = c
					break
			var dono: Node = null
			for w in casa.residents():
				if w._home_slot == 0:
					dono = w
			check(casa.motivo_cama_boa() == "", "pode trocar a cama")
			check(casa.pedir_cama_boa() and eco.quantidade("cama_boa") == 0.0 and casa.camas_pedidas == 1, "a cama sai do armazém e espera o carpinteiro")
			set_meta("casa", casa)
			set_meta("dono", dono)
			step = 5
			t_mark = t
		elif t - t_mark > 900.0:
			check(false, "a cama não ficou pronta (%s, %s)" % [carp.get_state(), cp.status_text()])
			step = 99
	elif step == 5:
		var casa = get_meta("casa")
		if casa.camas_boas == 1:
			check(casa.camas_pedidas == 0 and casa.cama_boa(0), "o carpinteiro montou a cama (cama 0 é de tábua)")
			var dono = get_meta("dono")
			if dono:
				var tem: bool = dono.happiness_factors().any(func(f): return f[0] == "cama de tábua" and f[1] == casa.conforto_cama_boa)
				check(tem, "quem dorme nela ganha +%d de ânimo" % roundi(casa.conforto_cama_boa))
			Engine.time_scale = 1.0
			step = 6
		elif t - t_mark > 600.0:
			check(false, "a cama não foi montada (%s)" % get_meta("carp").get_state())
			step = 6
		elif get_meta("carp").get_state() == "montando_cama" and not has_meta("viu_montar"):
			set_meta("viu_montar", true)
			check(true, "o carpinteiro vai montar a cama")
	elif step == 6:
		print("== custos: antes da fornalha, peças viram ferro")
		hub.level = 1
		var bar = g("barricadas")
		bar.level = 2
		var ef: Dictionary = eco.itens_efetivos(bar.upgrade_item_cost())
		check(ef.itens.is_empty() and ef.minerio == ceilf(12 * eco.ferro_por_prego + 4 * eco.ferro_por_ferragem), "barricada 3 antes da fornalha: só ferro (+%d)" % ef.minerio)
		check(not ("prego" in eco.custo_metal_texto(500, 170, "ferro", 30, bar.upgrade_item_cost())), "o texto não pede pregos antes da fornalha")
		print("== com a fornalha: pregos e ferragens")
		hub.level = 3
		zera(arm)
		eco.credits = 9000.0
		check("pregos" in bar.upgrade_block_reason() and "ferragens" in bar.upgrade_block_reason(), "barricada 3 pede pregos e ferragens ('%s')" % bar.upgrade_block_reason())
		eco.add_item("barra_ferro", 85.0)
		eco.add_item("prego", 12.0)
		eco.add_item("ferragem", 4.0)
		arm.wood_stored = 30.0
		arm._recount()
		# Bloco 96: subir a barricada é obra de engenheiro: o material fica reservado e o nível sobe no fim da obra
		check(bar.upgrade() and eco.livre("prego") == 0.0 and eco.livre("ferragem") == 0.0 and eco.livre("barra_ferro") == 0.0,
			"barricada 3 paga: 85 barras + 12 pregos + 4 ferragens")
		for k in bar._obra.necessario:
			bar._obra.entregar(k, float(bar._obra.necessario[k]))
			eco.tira(k, float(bar._obra.necessario[k]))  # (o engenheiro levou)
		bar.obra_work(999.0)
		check(bar.level == 3, "barricada nível 3 depois da obra")
		var casa = get_meta("casa")
		casa.level = 2
		casa._apply_level_beds()
		check("pregos" in casa.upgrade_cost_text() and "ferragens" in casa.upgrade_cost_text(), "casa nível 3: %s" % casa.upgrade_cost_text())
		check("ferro" in casa.upgrade_cost_text() and "70 ferro" in casa.upgrade_cost_text(), "casa nível 3: o ferro baixou pra 70")
		var ft: String = hub.ferrovia_cost_text()
		check(hub.ferrovia_proximo() == "" or ("pregos" in ft and "ferrage" in ft and "barras de ferro" in ft), "ferrovia: barras + pregos + ferragens ('%s')" % ft)
		check(hub.ferrovia_pecas("S2") == {"prego": 30, "ferragem": 2} and hub.ferrovia_pecas("S5") == {"prego": 48, "ferragem": 5}, "ferrovia: S2 30 pregos + 2 ferragens; S5 48 + 5")
		print("== aço: picareta de aço, lança de prata, bobinas")
		var ofi = g("oficina")
		check(ofi.TOOL_NAMES["picareta_aco"] == "Picareta temperada" and ofi.tool_ore_type("picareta_aco") == "ferro", "a picareta do cobre continua de ferro (Picareta temperada)")
		hub.level = 2
		check("estágio" in ofi.tool_block_reason("picareta_de_aco") or "nível 3" in ofi.tool_block_reason("picareta_de_aco"), "picareta de aço só no estágio 3 ('%s')" % ofi.tool_block_reason("picareta_de_aco"))
		hub.level = 3
		check("aço" in ofi.tool_block_reason("picareta_de_aco"), "picareta de aço pede aço ('%s')" % ofi.tool_block_reason("picareta_de_aco"))
		check("12 aço" in ofi.tool_cost_text("picareta_de_aco"), "custo: %s" % ofi.tool_cost_text("picareta_de_aco"))
		ofi.crafted["picareta_de_aco"] = true
		check(is_equal_approx(ofi.mult_mineracao(), ofi.picareta_aco_mult), "com ela: x%.2f minério por golpe" % ofi.mult_mineracao())
		ofi.crafted["picareta_de_aco"] = false
		var def = g("defense")
		check(def.weapon_item_cost("lanca_prata") == {"aco": 6} and def.weapon_item_cost("lanca_prata", true) == {"aco": 3}, "lança de prata: 6 aço (conserto 3)")
		check("aço" in eco.custo_metal_texto(600, 48, "prata", 20, def.weapon_item_cost("lanca_prata")) and "24 barras de prata" in eco.custo_metal_texto(600, 48, "prata", 20, def.weapon_item_cost("lanca_prata")),
			"lança de prata: 24 barras de prata + 6 aço")
		var esc = g("escudos")
		if esc == null:  # (o escudo só aparece mais tarde no jogo: um avulso pra conferir o custo)
			esc = load("res://scenes/props/escudo.tscn").instantiate()
			esc.position = hub.global_position + Vector2(400, 300)
			hub.get_parent().add_child(esc)
		if esc:
			check("20 aço" in esc.stage_cost_text("bobinas") and "110 cobre" in esc.stage_cost_text("bobinas"), "bobinas: %s" % esc.stage_cost_text("bobinas"))
		print("== couro: botas e mochila")
		var eq = g("equipment")
		check(eq.TYPES.has("botas") and eq.itens_extra("botas") == {"prego": eq.botas_pregos}, "botas: couro + pregos")
		check("pregos" in eq.cost_text(eq.cost("botas"), "botas"), "custo das botas: %s" % eq.cost_text(eq.cost("botas"), "botas"))
		var w: Node = get_meta("dono") if get_meta("dono") else ws()[0]
		w.wearing.erase("botas")
		w._inside = false
		w.global_position = hub.global_position + Vector2(0, 90)
		dn.day = 1 + 3 * g("sun").days_per_season  # inverno
		var cold: bool = eq.is_cold_at(w.global_position)
		check(cold, "inverno na superfície")
		check(is_equal_approx(w._neve_mult(), eq.neve_speed_mult), "sem botas, na neve: anda a %d%%" % roundi(w._neve_mult() * 100.0))
		w.wearing["botas"] = eq.botas_durability
		check(w._neve_mult() == 1.0, "com botas: ritmo de sempre")
		w.wearing.erase("botas")
		dn.day = 1
		check(w._neve_mult() == 1.0, "fora do inverno a neve não atrasa")
		var rm: Array = ofi.receitas_ferreiro.filter(func(r): return r.id == "mochila")
		check(not rm.is_empty() and rm[0].insumos.has("couro"), "mochila: receita do ferreiro com couro")
		var min_ = ws()[0]
		min_.set_job("minerador")
		min_.tem_mochila = false
		var c16: float = min_.capacidade_carga()
		eco.add_item("mochila", 1.0)
		min_.pega_mochila(arm)
		check(min_.tem_mochila and eco.quantidade("mochila") == 0.0 and min_.capacidade_carga() == c16 + min_.mochila_carga,
			"minerador pegou a mochila: carga %d -> %d" % [c16, min_.capacidade_carga()])
		set_meta("min", min_)
		print("== save e save antigo")
		var cp = get_meta("cp")
		cp.encomendar("tabua", 3)
		eq.pool["botas"] = [100.0]
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		check(data.village.carpintarias.size() == 1 and data.village.carpintarias[0].fila.size() == 1, "save: carpintaria com a fila")
		set_meta("pos", cp.global_position)
		set_meta("casa_nome", String(casa.name))
		root.get_node("SaveManager").load_game()
		step = 7
		t_mark = t
	elif step == 7 and t - t_mark > 2.0:
		var cps := get_nodes_in_group("carpintarias")
		check(cps.size() == 1 and cps[0].global_position == get_meta("pos") and cps[0].fila.fila.size() == 1, "load: carpintaria no lugar com a ordem")
		var casa: Node = null
		for c in get_nodes_in_group("casas"):
			if String(c.name) == get_meta("casa_nome"):
				casa = c
		check(casa != null and casa.camas_boas == 1, "load: a cama de tábua continua na casa")
		var mins := ws().filter(func(w): return w.tem_mochila)
		check(mins.size() == 1, "load: o minerador continua com a mochila")
		check(g("equipment").pool.get("botas", []).size() == 1, "load: as botas no vestiário")
		print("== save antigo (sem as chaves novas)")
		var c2 = casa
		c2.load_save_data({"built": true, "level": 1})
		check(c2.camas_boas == 0 and c2.camas_pedidas == 0, "casa de save antigo: nenhuma cama de tábua")
		var w0: Node = ws()[0]
		var d0: Dictionary = w0.get_save_data()
		d0.erase("mochila")
		w0.load_save_data(d0)
		check(not w0.tem_mochila, "ipezinho de save antigo: sem mochila")
		var eq2 = g("equipment")
		eq2.load_save_data({"pool": {"casaco": [100.0]}, "broken": {}})
		check(eq2.available("botas") == 0 and eq2.available("casaco") == 1, "vestiário de save antigo: sem botas")
		step = 99
	if step == 99:
		Engine.time_scale = 1.0
		print("\nFALHAS: %d" % fails)
		return true
	return false
