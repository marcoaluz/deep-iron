extends SceneTree
## Bloco 107: AGRICULTOR, ESTUFA, CARVOARIA, CURTUME e CARDÁPIO. (A) Itens novos e os compartimentos deles; a Fornalha gasta o
## carvão vegetal ANTES do mineral. (B) Horta e estufa construídas DENTRO da vila (estágio, custo, obra por etapas com
## material, o máximo); a estufa rende mais no inverno e menos no verão que a horta aberta. (C) O agricultor colhe; com
## agricultor o caçador só caça, sem ele o caçador colhe (fallback); o cuidado (a horta aberta regenera mais). (D) A
## carvoaria (um lenhador opera, por ordem, nada automático) e o curtume (um caçador opera). (E) Com curtume, botas,
## mochila e trajes pedem couro curtido (sem curtume, cru; casaco sempre cru). (F) O cardápio: ensopado (porção, fome,
## ânimo) e a ordem de ração (vira item, a cozinha volta ao prato; a expedição gasta a ração pronta primeiro). (G) A tecla,
## a barra, o save e o save antigo (a horta da clareira só sai com a chave nova). RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const Items := preload("res://scripts/core/items.gd")
const ProductionQueue := preload("res://scripts/core/production_queue.gd")
var main: Node
var t := 0.0
var fails := 0
var rodando := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
	load("res://scripts/core/defense.gd").moradores_desligados = true
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


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func espera(cond: Callable, max_s: float) -> bool:
	var t0 := t
	while not cond.call():
		if t - t0 > max_s:
			return false
		await process_frame
	return true


func anda(s: float) -> void:
	var t0 := t
	while t - t0 < s:
		await process_frame


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


## Termina a obra de um canteiro entregando o material todo (a obra só anda com o material entregue, Bloco 96).
func termina(kind: String) -> bool:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			var site = ObraSite.de(c)
			if site:
				for k in site.necessario:
					site.entregar(k, 9999.0)
			c.obra_work(c.left + 1.0)
			return true
	return false


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 900.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		Engine.time_scale = 1.0
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(9.0)
	for w in ws():
		w.hunger = w.hunger_max
	var sun = g("sun")
	if sun:
		sun.wave_today = false
	if not rodando and t > 2.0:
		rodando = true
		roda()
	return false


func roda() -> void:
	var eco = g("economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	var hud = g("hud")
	var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
	g("sun").season_wave_chance = nunca
	load("res://scripts/props/armazem.gd").limite_desligado = true  # (o assunto aqui não é o limite do armazém)
	while ws().size() < 8:
		eco.novo_ipezinho()
	await process_frame
	var w: Array = ws()
	eco.credits = 9999.0
	arm.stock["ferro"] = 500.0
	arm.stock["carvao"] = 0.0
	arm.wood_stored = 900.0
	arm.raw_stored = 100.0
	arm._recount()
	eco.add_item("prego", 200.0)
	eco.add_item("barra_ferro", 300.0)  # (do estágio da fornalha em diante o ferro dos custos vira barra)

	print("== A) itens novos e a Fornalha gastando o carvão vegetal primeiro")
	check(Items.compartimento("carvao_vegetal") == "madeira" and Items.compartimento("couro_curtido") == "manufaturados" and Items.compartimento("racao") == "alimentos",
		"compartimentos: carvão vegetal -> madeira, couro curtido -> manufaturados, ração -> alimentos")
	check(Items.onde("carvao_vegetal") == "itens" and Items.ITENS["carvao_vegetal"].preco == 0.0 and Items.ITENS["couro_curtido"].preco == 0.0, "não vendem (insumo)")
	var fila := ProductionQueue.new([{"id": "barra", "nome": "Barra", "insumos": {"ferro": 2, "carvao": 1}, "produto": {"barra_ferro": 1}, "segundos": 1.0, "estagio": 0}], 4)
	eco.add_item("carvao_vegetal", 2.0)
	arm.stock["carvao"] = 5.0
	arm._recount()
	fila.encomendar("barra", 3, 1)
	check(fila.falta_para(eco) == "", "carvão vegetal + mineral cobrem a ordem")
	fila.comecar_unidades(3, eco)
	check(is_equal_approx(eco.quantidade("carvao_vegetal"), 0.0) and is_equal_approx(eco.quantidade("carvao"), 4.0), "gastou o vegetal (2) ANTES do mineral (1): sobrou %d mineral" % int(eco.quantidade("carvao")))

	await process_frame  # (o recibo de uma encomenda vale só no quadro do pagamento: a fila de teste acima não vaza pra obra)
	print("== B) a horta e a estufa: construídas DENTRO da vila, em obra por etapas, com material")
	check(hub.level >= 1 and hub.horta_block_reason().begins_with("em obra") == false, "horta: estágio 1 já libera (%s)" % hub.horta_block_reason())
	hub.level = 1
	check(hub.estufa_block_reason().begins_with("precisa da vila no estágio"), "estufa: precisa do estágio 2 ('%s')" % hub.estufa_block_reason())
	hub.level = 2
	check(hub.estufa_block_reason() == "" and hub.carvoaria_block_reason() == "" and hub.curtume_block_reason() == "", "no estágio 2 as três liberam")
	var antes_h: int = hub.hortas().size()
	var c0: float = eco.credits
	var custo_h: int = hub.obra107_cost("horta").x
	var pos_h := spot_near(hub.global_position + Vector2(-120, 60))
	check(hub._obra107_confirma("horta", pos_h), "encomendou uma horta")
	var cant = null
	for c in get_nodes_in_group("canteiros"):
		if c.kind == "horta":
			cant = c
	check(cant != null and ObraSite.de(cant) != null and ObraSite.de(cant).tem_material() and is_equal_approx(c0 - eco.credits, float(custo_h)), "obra com a lista de material; créditos cobrados (%d)" % int(c0 - eco.credits))
	check(hub.horta_block_reason().begins_with("em obra"), "uma por vez na obra")
	check(termina("horta") and hub.hortas().size() == antes_h + 1, "o engenheiro ergueu a horta (agora %d)" % hub.hortas().size())
	var horta_nova = hub.hortas()[hub.hortas().size() - 1]
	check(horta_nova.is_in_group("coleta_comida") and not horta_nova.estufa, "a horta nova é do grupo de coleta de comida")
	var p_est := spot_near(hub.global_position + Vector2(120, 60))
	var c1: float = eco.credits
	check(hub._obra107_confirma("estufa", p_est), "encomendou a estufa")
	check(c1 - eco.credits == hub.estufa_credits, "estufa: %d cr cobrados (%s)" % [int(c1 - eco.credits), hub.estufa_cost_text()])
	check(termina("estufa") and hub.estufas().size() == 1, "a estufa ergueu")
	var estufa = hub.estufas()[hub.estufas().size() - 1] if not hub.estufas().is_empty() else horta_nova
	check(estufa.estufa and estufa.is_in_group("coleta_comida") and estufa.is_in_group("estufas"), "a estufa também é fonte de comida")
	check(hub.estufa_block_reason() == "" and hub.estufas().size() < hub.estufa_max, "cabe uma segunda estufa (máx. %d)" % hub.estufa_max)
	check(hub.obra107_cost("estufa").x > hub.estufa_credits - 1 and hub.obra107_cost("horta").x > hub.horta_credits, "as próximas custam mais")
	# as estações: a estufa rende mais no inverno e menos no calor que a horta aberta
	check(sun_ok(), "estufa: inverno > horta aberta; verão e primavera < horta aberta")

	print("== C) o agricultor colhe; o caçador só caça com agricultor (e colhe sem ele); o cuidado")
	var agri = w[0]
	var cacador = w[1]
	cacador.set_job("caçador")
	check(not cacador._agricultor_na_vila(), "sem agricultor: o caçador colhe a horta")
	var escolheu := await espera(func(): return cacador.get_state() in ["foraging", "hunting"], 30.0)
	check(escolheu, "o caçador trabalha (%s)" % cacador.get_state())
	agri.set_job("agricultor")
	check(agri.is_farmer() and agri.outfit() == "agricultor", "função agricultor (roupa 'agricultor')")
	cacador._agri_na_vila_t = -10.0
	cacador.wake_decision()
	await anda(2.0)
	check(cacador._agricultor_na_vila() and cacador.get_state() != "foraging", "com agricultor o caçador não colhe mais (%s)" % cacador.get_state())
	var colheu := await espera(func(): return agri.get_state() == "foraging" and agri.raw_carrying > 0.0, 90.0)
	check(colheu, "o agricultor colhe (carrega %.1f)" % agri.raw_carrying)
	var h_c = horta_nova
	h_c._agri_t = -10.0
	var r_com: float = h_c.regen_por_segundo()
	agri.set_job("ocioso")
	h_c._agri_t = -10.0
	var r_sem: float = h_c.regen_por_segundo()
	check(r_sem > 0.0 and absf(r_com / r_sem - h_c.cuidado_mult) < 0.01, "o cuidado: a horta aberta regenera x%.2f com agricultor (%.3f contra %.3f /s)" % [r_com / maxf(r_sem, 0.001), r_com, r_sem])
	check(estufa.regen_por_segundo() > 0.0 and is_equal_approx(estufa.regen_por_segundo(), estufa.regen_rate * g("sun").estufa_mult()), "a estufa não leva o cuidado (leva a estação dela)")
	cacador._agri_na_vila_t = -10.0
	check(not cacador._agricultor_na_vila(), "tirou o agricultor: o caçador volta a poder colher")
	cacador.set_job("ocioso")

	print("== D) a carvoaria (lenhador) e o curtume (caçador): obra, ordem, operador")
	check(hub._obra107_confirma("carvoaria", spot_near(hub.global_position + Vector2(-200, -20))) and termina("carvoaria") and hub.carvoarias().size() == 1, "carvoaria erguida")
	check(hub._obra107_confirma("curtume", spot_near(hub.global_position + Vector2(200, -20))) and termina("curtume") and hub.curtumes().size() == 1, "curtume erguido")
	var carv = hub.carvoarias()[0]
	var curt = hub.curtumes()[0]
	var lenh = w[2]
	var lenh2 = w[3]
	lenh.set_job("lenhador")
	lenh2.set_job("lenhador")
	await anda(2.0)
	check(carv.fila.tem_trabalho() == false and lenh.get_state() != "carvoejando", "sem ordem a carvoaria não faz nada (nada automático)")
	var m0: float = eco.quantidade("madeira")
	check(carv.encomendar("carvao_vegetal", 3), "encomendou 3 carvões vegetais")
	check(is_equal_approx(eco.quantidade("madeira"), m0), "encomendar não gasta (cada unidade paga quando começa)")
	var fez := await espera(func(): return _conta_operadores([lenh, lenh2]) and eco.quantidade("carvao_vegetal") >= 3.0, 200.0)
	check(fez, "o lenhador carvoejou e levou pro armazém (%d carvões)" % int(eco.quantidade("carvao_vegetal")))
	check(float(carv.produzido.get("carvao_vegetal", 0.0)) >= 3.0 and absf(float(carv.produzido.get("carvao_vegetal", 0.0)) - eco.quantidade("carvao_vegetal")) < 0.01, "a telemetria conta o que foi feito (produzido %s, no armazém %.1f)" % [str(carv.produzido), eco.quantidade("carvao_vegetal")])
	check(operaram_max <= 1, "um lenhador por vez opera (no máximo %d ao mesmo tempo)" % operaram_max)
	lenh.set_job("ocioso")
	lenh2.set_job("ocioso")
	# o curtume
	var cac = w[4]
	cac.set_job("caçador")
	arm.leather_stored = 6.0
	arm._recount()
	check(curt.encomendar("couro_curtido", 2), "encomendou 2 couros curtidos")
	var curtiu := await espera(func(): return eco.quantidade("couro_curtido") >= 2.0, 200.0)
	check(curtiu, "o caçador curtiu e levou pro armazém (%d)" % int(eco.quantidade("couro_curtido")))
	check(is_equal_approx(arm.leather_stored, 4.0), "gastou 1 couro cru por curtido (sobrou %d)" % int(arm.leather_stored))
	cac.set_job("ocioso")

	print("== E) com curtume, botas, mochila e trajes pedem couro curtido")
	var eqp = g("equipment")
	check(eqp.couro_de("botas") == "couro_curtido" and eqp.couro_de("gas") == "couro_curtido" and eqp.couro_de("casaco") == "couro", "botas e trajes curtido; casaco cru")
	check(ProductionQueue.usa_curtido(), "a fila de produção sabe que há curtume")
	var fo = ProductionQueue.new([{"id": "mochila", "nome": "Mochila", "insumos": {"couro": 3, "prego": 2}, "produto": {"mochila": 1}, "segundos": 1.0, "estagio": 0, "curtido": true}], 4)
	check(fo.receita("mochila").insumos.has("couro_curtido") and not fo.receita("mochila").insumos.has("couro"), "a mochila pede couro curtido")
	var ofi = g("oficina")
	check(ofi.fila_ferreiro.receita("mochila").insumos.has("couro_curtido"), "a receita real da Oficina também")
	check(eqp.cost_text(eqp.cost("botas"), "botas").contains("curtido"), "o custo diz 'couro curtido'")
	# tira o curtume: volta ao cru
	var curt_save: Node = curt
	curt.remove_from_group("curtumes")
	check(eqp.couro_de("botas") == "couro" and not ProductionQueue.usa_curtido() and ofi.fila_ferreiro.receita("mochila").insumos.has("couro"), "sem curtume: cru, como antes")
	curt_save.add_to_group("curtumes")

	print("== F) o cardápio e a ração")
	var coz = g("comedouros")
	check(coz.prato == "comum" and is_equal_approx(coz._porcao(), 8.0) and is_equal_approx(coz._fome_da_porcao(), 45.0), "refeição comum: porção 8, fome 45")
	check(coz.set_prato("ensopado") and is_equal_approx(coz._porcao(), 12.0) and is_equal_approx(coz._fome_da_porcao(), 45.0 * 1.25), "ensopado: porção 12, fome %.0f" % coz._fome_da_porcao())
	check(not coz.set_prato("sopa"), "prato que não existe é recusado")
	var comilao = w[5]
	comilao.hunger = 10.0
	coz.food_stock = 100.0
	var f_ant: float = coz.food_stock
	comilao.animo_prato = 0.0
	comilao.global_position = coz.global_position + Vector2(0, 30)
	comilao._servido = false
	comilao._ai_state = "eating"
	comilao._refeicao_alvo = "almoco"
	var serviu := await espera(func(): return comilao.animo_prato > 0.0, 20.0)
	check(serviu or f_ant - coz.food_stock >= 11.9, "serviu o ensopado (comida gasta: %.1f, ânimo %.1f)" % [f_ant - coz.food_stock, comilao.animo_prato])
	check(comilao.happiness_factors().any(func(f): return String(f[0]).contains("ensopado")) or comilao.animo_prato <= 0.0, "o ânimo do ensopado entra na lista de motivos")
	coz.set_prato("comum")
	# a ração
	coz.food_stock = 200.0
	check(coz.motivo_racao(0) != "" and coz.motivo_racao(coz.racao_max_pedido + 1) != "", "a quantidade da ração é conferida")
	check(coz.pede_racao(2) and coz.racao_pedida == 2, "pediu 2 rações")
	check(coz._fazendo_racao() and coz._mult_preparo() > 3.0, "com comida de reserva, a cozinha faz ração (preparo x%.1f)" % coz._mult_preparo())
	var cozinheiro = w[6]
	cozinheiro.set_job("cozinheiro")
	arm.raw_stored = 100.0
	arm._recount()
	var racoes0: float = eco.quantidade("racao")
	var feita := await espera(func(): return eco.quantidade("racao") >= racoes0 + 2.0, 300.0)
	check(feita and coz.racao_pedida == 0, "o cozinheiro fez as 2 rações (itens no armazém: %d)" % int(eco.quantidade("racao")))
	check(coz.prato == "comum" and not coz._fazendo_racao() and is_equal_approx(coz._mult_preparo(), 1.0), "a cozinha voltou sozinha ao prato de antes")
	cozinheiro.set_job("ocioso")
	var ex = g("expedicoes")
	check(ex.racoes_prontas() >= 2.0 and ex.racoes_a_gastar(2, 1.0) == 2, "a expedição vê as rações prontas (2 pessoas, 1 dia = 2 rações)")
	check(is_equal_approx(ex.comida_a_tirar(2, 1.0), 0.0), "e não pede comida da cozinha por elas (%.0f)" % ex.comida_a_tirar(2, 1.0))
	check(ex.comida_a_tirar(2, 3.0) > 0.0 and ex.comida_a_tirar(2, 3.0) < ex.racao_total(2, 3.0), "o que as rações não cobrem sai da cozinha (%.0f de %.0f)" % [ex.comida_a_tirar(2, 3.0), ex.racao_total(2, 3.0)])
	hud.open_panel("cozinha", coz)
	var cp = hud._panels["cozinha"]
	cp.refresh()
	check(cp.visible and cp._btn_comum.disabled and not cp._btn_ensopado.disabled, "a janela da cozinha abre (prato atual marcado)")
	hud.close_panels()

	print("== G) tecla, barra, save e save antigo")
	check(Teclas.acao(KEY_MINUS) == "agricultor", "tecla física '-' = agricultor")
	var usadas := {}
	var conflito := ""
	for a in Teclas.PADRAO:
		for k in Teclas.PADRAO[a]:
			if usadas.has(k) and usadas[k] != a:
				conflito = "%s x %s" % [usadas[k], a]
			usadas[k] = a
	check(conflito == "", "nenhuma tecla padrão repetida (%s)" % conflito)
	check(hud._job_buttons.has("agricultor") and hud.GRUPOS_FUNCOES[0][1].has("agricultor"), "o botão na barra, em PRODUÇÃO")
	var tel := load("res://scripts/core/telemetria.gd")
	check((tel.COLUNAS as Array).has("estufas") and (tel.COLUNAS as Array).has("carvao_vegetal_feito") and (tel.COLUNAS as Array).has("prato"), "a telemetria tem as colunas novas")
	w[0].set_job("agricultor")
	coz.set_prato("ensopado")
	coz.pede_racao(3)
	horta_nova.total_colhido = 77.0
	var d: Dictionary = hub.get_save_data()
	check(d.has("hortas") and (d.hortas as Array).size() >= 2 and d.has("carvoarias") and d.has("curtumes"), "o Centro da Vila salva as estruturas (hortas %d)" % (d.hortas as Array).size())
	var antes_e: int = hub.estufas().size()
	var antes_ho: int = hub.hortas().size()
	hub.load_save_data(d)
	await process_frame
	check(hub.estufas().size() == antes_e and hub.hortas().size() == antes_ho and hub.carvoarias().size() == 1 and hub.curtumes().size() == 1, "carregou: as mesmas estruturas (hortas %d, estufas %d)" % [hub.hortas().size(), hub.estufas().size()])
	var cd: Dictionary = coz.get_save_data()
	coz.prato = "comum"
	coz.racao_pedida = 0
	coz.load_save_data(cd)
	check(coz.prato == "ensopado" and coz.racao_pedida == 3, "o cardápio volta (ensopado, 3 rações)")
	var velho: Dictionary = d.duplicate(true)
	velho.erase("hortas")
	velho.erase("carvoarias")
	velho.erase("curtumes")
	hub.load_save_data(velho)
	await process_frame
	check(hub.carvoarias().is_empty() and hub.curtumes().is_empty(), "save antigo: nenhuma carvoaria nem curtume")
	check(hub.hortas().size() + hub.estufas().size() == antes_ho + antes_e, "save antigo (sem a chave 'hortas'): as hortas da cena continuam (nada some)")
	var cv: Dictionary = {"food_stock": 50.0}
	coz.load_save_data(cv)
	check(coz.prato == "comum" and coz.racao_pedida == 0, "save antigo da cozinha: refeição comum, sem ração")
	var com_chave: Dictionary = d.duplicate(true)
	com_chave["hortas"] = []
	hub.load_save_data(com_chave)
	await process_frame
	check(hub.hortas().is_empty() and hub.estufas().is_empty(), "save COM a chave e vazio: a horta da clareira sai (a vila é do jogador)")

	Engine.time_scale = 1.0
	print("\nFALHAS: %d" % fails)
	quit()


var operaram_max := 0


## Anota quantos dos dois lenhadores operam a carvoaria ao mesmo tempo (o máximo visto). Sempre false: só vigia.
func _conta_operadores(lista: Array) -> bool:
	var n := 0
	for l in lista:
		if l.get_state() in ["carvoejando", "buscando_insumo"]:
			n += 1
	operaram_max = maxi(operaram_max, n)
	return true


## A estufa rende menos que a horta aberta na primavera e no verão e mais no inverno (os @export do sol).
func sun_ok() -> bool:
	var s = g("sun")
	return s.season_estufa_mult[3] > s.season_garden_mult[3] and s.season_estufa_mult[0] * 0.30 < s.season_garden_mult[0] * 0.35 \
		and s.season_estufa_mult[1] * 0.30 < s.season_garden_mult[1] * 0.35
