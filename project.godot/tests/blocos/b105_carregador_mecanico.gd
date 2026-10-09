extends SceneTree
## Bloco 105: CARREGADOR e MECÂNICO. (A) O carregador leva o material da obra e o engenheiro só constrói; a carga
## respeita a capacidade e a reserva (nada prometido a mais). (B) Sem carregador, o engenheiro leva (o fallback). (C) Dois
## carregadores não pegam a mesma entrega. (D) A Fornalha: os insumos "a caminho" só começam na entrega; o fundidor não
## sai; as barras vão pro armazém. (E) A cozinha: o estoque da cozinha e o cozinheiro preparando dali. (F) O desgaste
## (gradual a partir de 40%, quebra em 0) na escavadeira, no coletor, no ventilador (proteção aos poucos e aviso antes de
## falhar) e no robô. (G) O mecânico: o conserto antes da preventiva, a preventiva só com o tempo, o conserto só com
## material (sem material ou sem ninguém, nada é gasto), a cabine. Sem mecânico: o engenheiro conserta só o que quebrou
## e não faz preventiva. (H) A barra, as teclas físicas, o alerta e os balões. (I) As missões e a telemetria. (J) Save e
## save antigo. RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const Desgaste := preload("res://scripts/core/desgaste.gd")
var main: Node
var t := 0.0
var fails := 0
var rodando := false

# vigia (a cada quadro)
var obra: Node = null
var eng: Node = null
var cars: Array = []
var eng_mao := 0.0
var car_mao := 0.0
var car_excesso := 0.0
var sobra_promessa := 0.0
var mesma_entrega := false
var fund: Node = null
var forn: Node = null
var fund_buscou := false
var viu_a_caminho := false
var comecou_antes := false
var cook: Node = null
var cook_buscou := false
var viu_estoque := false
var mec: Node = null
var mec_estados: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true  # (o minério da fornalha já estudado: Bloco 102)
	load("res://scripts/core/defense.gd").moradores_desligados = true  # (Bloco 103: sem moradores no fundo)
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


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func canteiro(kind: String) -> Node:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			return c
	return null


func qtd(d: Dictionary) -> float:
	var n := 0.0
	for k in d:
		n += float(d[k])
	return n


## Espera a condição (segundos de jogo); false = não deu a tempo.
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


func vigia() -> void:
	if is_instance_valid(eng):
		eng_mao = maxf(eng_mao, qtd(eng.material_mao))
	var chaves := {}
	for w in cars:
		if not is_instance_valid(w):
			continue
		var m: float = qtd(w.material_mao) + qtd(w.material_pedido)
		car_mao = maxf(car_mao, m)
		car_excesso = maxf(car_excesso, m - float(w.capacidade_carga()))
		if not w._carga.is_empty():
			var k := String(w._carga.get("chave", ""))
			if chaves.has(k):
				mesma_entrega = true
			chaves[k] = true
	if obra != null and is_instance_valid(obra):
		var site = ObraSite.de(obra)
		if site:
			for k in site.necessario:
				sobra_promessa = maxf(sobra_promessa, site.em_maos(k) + site.pedido(k) - site.falta(k))
	if is_instance_valid(fund) and is_instance_valid(forn):
		if fund.get_state() == "buscando_insumo":
			fund_buscou = true
		if forn.fila.a_caminho() > 0:
			viu_a_caminho = true
			if forn.fila.comecadas() > 0:
				comecou_antes = true
	if is_instance_valid(cook):
		if cook.get_state() == "fetching":
			cook_buscou = true
		var coz = g("comedouros")
		if coz and float(coz.raw_local) > 0.0:
			viu_estoque = true
	if is_instance_valid(mec):
		var st: String = mec.get_state()
		if mec_estados.is_empty() or mec_estados[-1] != st:
			mec_estados.append(st)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 1500.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		Engine.time_scale = 1.0
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(9.0)  # sempre no horário de trabalho
	for w in ws():
		w.hunger = w.hunger_max
	var sun = g("sun")
	if sun:
		sun.wave_today = false
	vigia()
	if not rodando and t > 2.0:
		rodando = true
		roda()
	return false


func roda() -> void:
	var eco = g("economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	var lg = g("logistica")
	var mt = g("manutencao")
	var hud = g("hud")
	var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
	g("sun").season_wave_chance = nunca
	check(lg != null and mt != null, "os nós Logistica e Manutencao na main.tscn")
	while ws().size() < 7:
		eco.novo_ipezinho()
	await process_frame
	var w: Array = ws()

	print("== H) a barra, as teclas físicas e os nomes")
	var jobs: Array = hud.ORDER_JOBS.map(func(e): return e[0])
	check(jobs.has("carregador") and jobs.has("mecânico"), "a barra de funções tem o carregador e o mecânico")
	var servico: Array = []
	for gr in hud.GRUPOS_FUNCOES:
		if gr[0] == "SERVIÇO":
			servico = gr[1]
	check(servico.has("carregador") and servico.has("mecânico"), "os dois no grupo SERVIÇO")
	check(hud._job_buttons.has("carregador") and hud._job_buttons.has("mecânico") and hud._job_buttons["carregador"].button.visible, "os botões existem (e aparecem desde o começo)")
	check(Teclas.acao(KEY_BRACKETRIGHT) == "carregador" and Teclas.acao(KEY_BACKSLASH) == "mecanico", "teclas físicas: BracketRight = carregador, BackSlash = mecânico (no ABNT2: '[' e ']')")
	var usadas := {}
	var conflito := ""
	for a in Teclas.PADRAO:
		for k in Teclas.PADRAO[a]:
			if usadas.has(k) and usadas[k] != a:
				conflito = "%s x %s" % [usadas[k], a]
			usadas[k] = a
	check(conflito == "", "nenhuma tecla padrão repetida (%s)" % conflito)
	check(not Teclas.RESERVADAS.has(KEY_BRACKETRIGHT) and not Teclas.RESERVADAS.has(KEY_BACKSLASH), "as duas não são reservadas (dá pra remapear)")
	check(Teclas.NOMES.any(func(n): return n[0] == "carregador") and Teclas.NOMES.any(func(n): return n[0] == "mecanico"), "aparecem em Configurações > Teclas")
	w[0].set_job("carregador")
	w[1].set_job("mecânico")
	check(w[0].is_carrier() and w[1].is_mechanic(), "as funções novas (%s, %s)" % [w[0].job, w[1].job])
	check(w[1].outfit() == "mecanico" and preload("res://scripts/iso/iso_bonecos.gd").funcao_de(w[1]) in ["mecanico", "engenheiro"], "o mecânico veste a arte dele (provisória: a do engenheiro até a aprovação)")
	w[0].set_job(w[0].ROLE_IDLE)
	w[1].set_job(w[1].ROLE_IDLE)

	print("== F) o desgaste: gradual a partir de 40%, quebra em 0")
	check(Desgaste.eficiencia_de(1.0) == 1.0 and Desgaste.eficiencia_de(0.6) == 1.0, "até 40% de desgaste rende 100%")
	check(Desgaste.eficiencia_de(0.59) < 1.0 and Desgaste.eficiencia_de(0.59) > 0.95, "passou de 40%: começa a cair aos poucos (%.3f)" % Desgaste.eficiencia_de(0.59))
	check(is_equal_approx(Desgaste.eficiencia_de(0.3), 0.75) and Desgaste.eficiencia_de(0.01) > 0.5, "a 70%% de desgaste rende 75%% (%.2f); quase quebrada, perto do mínimo" % Desgaste.eficiencia_de(0.3))
	check(Desgaste.eficiencia_de(0.0) == 0.0, "em 0: quebrada (0)")
	var esc = g("escavadeira")
	check(esc and esc.is_in_group("maquinas") and esc.manut_condicao() == 1.0, "a escavadeira começa nova")
	esc._desgaste.gasta(1.0)
	check(esc._desgaste.quebrada and esc._desgaste.eficiencia() == 0.0, "a escavadeira quebrou e parou (eficiência 0)")
	check(mt.quebras.get("escavadeira", 0) == 1, "a quebra contada (telemetria)")
	check(mt.conserto_de(esc) == null, "sem mecânico nem engenheiro: não abriu conserto (nada gasto)")
	esc._desgaste.restaura()
	# o ventilador: protege menos aos poucos e avisa antes de falhar (as regras do fundo de sempre)
	var fundo = g("fundo")
	var pv := Vector2(-300, 3600)
	var v = fundo.spawn_ventilador(pv)
	await process_frame
	var m_novo: float = fundo.ventilacao_mult(pv)
	var n_novo: float = fundo.nevoa_mult()
	v._desgaste.condicao = 0.3
	var m_gasto: float = fundo.ventilacao_mult(pv)
	check(m_novo < m_gasto and m_gasto < 1.0, "ventilador gasto protege menos, mas ainda protege (%.2f -> %.2f)" % [m_novo, m_gasto])
	check(fundo.nevoa_mult() > n_novo, "a névoa do S2 afina menos (%.2f -> %.2f)" % [n_novo, fundo.nevoa_mult()])
	v._desgaste.gasta(0.1)
	check(mt._avisou.has(v) and not v._desgaste.quebrada, "abaixo de 25%: o aviso de falha ANTES de parar")
	check(mt.com_problema().has(v), "o alerta conta o ventilador falhando")
	v._desgaste.gasta(1.0)
	check(v._desgaste.quebrada and is_equal_approx(fundo.ventilacao_mult(pv), 1.0), "quebrado: não protege (%.2f)" % fundo.ventilacao_mult(pv))
	var hora0: float = v._desgaste.condicao
	v._desgaste.restaura()
	await anda(2.0)
	check(v._desgaste.condicao < 1.0 and v._desgaste.condicao > 0.99, "o ventilador gasta por hora ligado (%.4f)" % v._desgaste.condicao)
	check(hora0 == 0.0, "(quebrado ficou em 0)")
	# o coletor: rende pela eficiência; o robô: cada queda gasta
	var col = g("coletores_madeira") if g("coletores_madeira") else null
	for m in get_nodes_in_group("maquinas"):
		if m.manut_tipo() == "coletor_madeira":
			col = m
	check(col != null, "o coletor de madeira é máquina")
	var robo = load("res://scenes/props/robo.tscn").instantiate()
	robo.position = hub.global_position + Vector2(60, 60)
	hub.get_parent().add_child(robo)
	await process_frame
	robo.state = "active"
	for i in 4:
		preload("res://scripts/core/manutencao.gd").gasta_em(robo, "robo", 1.0)
	check(robo.manut_quebrada(), "o robô quebrou depois de %d quedas" % int(mt.vida.robo))
	robo.queue_free()
	await process_frame

	print("== A) o carregador leva o material da obra; o engenheiro só constrói")
	eco.credits = 5000.0
	arm.wood_stored = 40.0
	arm.stock["ferro"] = 0.0
	arm._recount()
	cars = [w[0]]
	eng = w[1]
	w[0].set_job("carregador")
	w[1].set_job("engenheiro")
	var pos := spot_near(hub.global_position + Vector2(140, 80))
	check(g("morale")._confirm_taverna(pos), "encomendou a taverna (40 madeira)")
	obra = canteiro("taverna")
	Engine.time_scale = 6.0
	var ok: bool = await espera(func(): return obra == null or not is_instance_valid(obra), 260.0)
	check(ok, "a taverna ficou pronta")
	check(car_mao > 0.0, "o carregador levou material (máx. %.1f)" % car_mao)
	check(eng_mao == 0.0, "o engenheiro não carregou nada (máx. %.1f)" % eng_mao)
	check(car_excesso <= 0.01, "a carga nunca passou da capacidade dele (%.1f)" % w[0].capacidade_carga())
	check(sobra_promessa <= 0.01, "nada prometido além do que falta (%.2f)" % sobra_promessa)
	check(lg.entregas >= 1, "entregas contadas: %d" % lg.entregas)

	print("== B) sem carregador, o engenheiro leva (fallback)")
	w[0].set_job(w[0].ROLE_IDLE)
	cars = []
	eng_mao = 0.0
	arm.stock["ferro"] = 20.0
	arm.wood_stored = 25.0
	arm._recount()
	var pos2 := spot_near(hub.global_position + Vector2(-160, 90))
	check(hub._confirm_comedouro(pos2), "encomendou a cozinha (20 ferro + 25 madeira)")
	obra = canteiro("comedouro")
	ok = await espera(func(): return eng_mao > 0.0, 120.0)
	check(ok, "o engenheiro foi buscar o material ele mesmo (%.1f)" % eng_mao)
	check(ObraSite.cancelar(obra), "(cancelou a cozinha: devolve)")
	obra = null

	print("== C) dois carregadores: cada entrega com um só")
	w[0].set_job("carregador")
	w[2].set_job("carregador")
	cars = [w[0], w[2]]
	eng_mao = 0.0
	sobra_promessa = 0.0
	arm.wood_stored = 200.0
	arm.stock["ferro"] = 200.0
	arm._recount()
	var pos3 := spot_near(hub.global_position + Vector2(40, 170))
	check(g("morale")._confirm_park(pos3), "encomendou o parque (%s)" % g("morale").park_block_reason())
	obra = canteiro("parque")
	ok = await espera(func(): return obra == null or not is_instance_valid(obra), 260.0)
	check(ok, "o parque ficou pronto")
	check(not mesma_entrega, "nunca dois carregadores na mesma entrega")
	check(sobra_promessa <= 0.01 and eng_mao == 0.0, "sem promessa duplicada (%.2f); o engenheiro não carregou" % sobra_promessa)
	w[2].set_job(w[2].ROLE_IDLE)
	cars = [w[0]]

	print("== D) a Fornalha: os insumos a caminho, o fundidor fica, as barras vão pro armazém")
	forn = load("res://scenes/props/fornalha.tscn").instantiate()
	forn.position = spot_near(hub.global_position + Vector2(-60, -150))
	hub.get_parent().add_child(forn)
	await process_frame
	fund = w[3]
	fund.set_job("fundidor")
	arm.stock["ferro"] = 20.0
	arm.stock["carvao"] = 10.0
	arm.stock["barra_ferro"] = 0.0
	arm._recount()
	var e0: int = lg.entregas
	check(forn.encomendar("barra_ferro", 2), "encomendou 2 barras de ferro")
	ok = await espera(func(): return eco.quantidade("barra_ferro") >= 2.0, 260.0)
	check(ok, "as 2 barras chegaram ao armazém (%d)" % int(eco.quantidade("barra_ferro")))
	check(viu_a_caminho and not comecou_antes, "os insumos ficaram 'a caminho' e só começaram na entrega")
	check(not fund_buscou, "o fundidor não saiu da fornalha (o carregador buscou e levou)")
	check(is_equal_approx(eco.quantidade("ferro"), 16.0) and is_equal_approx(eco.quantidade("carvao"), 8.0), "gastou só os insumos das 2 (ferro %d, carvão %d)" % [int(eco.quantidade("ferro")), int(eco.quantidade("carvao"))])
	check(lg.entregas >= e0 + 2, "entregas do insumo e das barras (%d)" % (lg.entregas - e0))
	print("  sem minério: o balão 'sem material'")
	arm.stock["ferro"] = 0.0
	arm._recount()
	forn.encomendar("barra_ferro", 1)
	ok = await espera(func(): return w[0].motivo_parado() == "sem_material", 30.0)
	check(ok, "o carregador parado mostra 'sem material' ('%s')" % w[0].motivo_parado())
	check(fund.motivo_parado() == "sem_material", "o fundidor também ('%s')" % fund.motivo_parado())
	check(w[0].MOTIVO_ICONE.has("sem_material") and ResourceLoader.exists("res://assets/game/ui/icones/%s.png" % w[0].MOTIVO_ICONE.sem_material), "o balão tem ícone")
	forn.cancelar(0)
	fund.set_job(fund.ROLE_IDLE)
	fund = null

	print("== E) a cozinha: o carregador enche o estoque; o cozinheiro prepara dali")
	cook = w[4]
	var coz = g("comedouros")
	coz.food_stock = 0.0
	arm.raw_stored = 30.0
	arm._recount()
	cook.set_job("cozinheiro")
	ok = await espera(func(): return coz.food_stock > 0.0, 200.0)
	check(ok, "saiu comida (%.1f)" % coz.food_stock)
	check(viu_estoque, "a cozinha teve estoque próprio (o carregador trouxe)")
	check(not cook_buscou, "o cozinheiro não foi ao armazém")
	cook.set_job(cook.ROLE_IDLE)
	cook = null
	w[0].set_job(w[0].ROLE_IDLE)
	cars = []

	print("== G) o mecânico: conserto antes da preventiva; material só quando dá")
	w[1].set_job(w[1].ROLE_IDLE)  # (sem engenheiro agora)
	mec = w[5]
	mec.set_job("mecânico")
	await anda(1.0)
	check(mec.motivo_parado() in ["sem_trabalho", ""], "sem máquina gasta: sem trabalho ('%s')" % mec.motivo_parado())
	arm.stock["ferro"] = 0.0
	arm._recount()
	var cr0: float = eco.credits
	var w0: float = eco.quantidade("madeira")
	col._desgaste.gasta(1.0)
	check(col.manut_quebrada() and mt.conserto_de(col) == null, "o coletor quebrou; sem ferro: sem obra")
	await anda(mt.conserto_tenta_cada + 1.0)
	check(mt.conserto_de(col) == null and is_equal_approx(eco.credits, cr0) and is_equal_approx(eco.quantidade("madeira"), w0), "sem material completo nada foi gasto (créditos e madeira iguais)")
	check(hud._alertas.ativos().has("maquina"), "o alerta 'Máquina quebrada' na coluna da direita")
	arm.stock["ferro"] = 50.0
	arm.wood_stored = 50.0
	arm._recount()
	var c_custo: Array = mt.custo("coletor_madeira")
	ok = await espera(func(): return mt.conserto_de(col) != null, mt.conserto_tenta_cada * 2.0 + 2.0)
	check(ok, "com material: abriu o conserto")
	esc._desgaste.condicao = 0.5  # gasta (abaixo do limite) com o conserto aberto: o conserto vem primeiro
	mec_estados.clear()
	await anda(mt.conserto_tenta_cada + 1.0)
	check(get_nodes_in_group("consertos_maquina").size() == 1 and is_equal_approx(eco.credits, cr0 - float(c_custo[0])), "pagou UMA vez (%d cr)" % int(cr0 - eco.credits))
	ok = await espera(func(): return not col.manut_quebrada(), 200.0)
	check(ok, "o mecânico consertou o coletor (%s)" % str(mec_estados))
	var i_obra := mec_estados.find("building")
	var i_prev := mec_estados.find("manutencao")
	check(i_obra >= 0 and (i_prev < 0 or i_obra < i_prev), "o conserto veio antes da preventiva %s" % str(mec_estados))
	ok = await espera(func(): return esc.manut_condicao() >= 0.999, 200.0)
	check(ok and mt.preventivas >= 1, "a preventiva da escavadeira (só o tempo dele): condição %.2f" % esc.manut_condicao())
	check(mt.consertos_feitos >= 1, "consertos: %d" % mt.consertos_feitos)
	print("  a cabine do elevador (o conserto do cabo é do mecânico)")
	var ele = g("elevador") if g("elevador") else null
	for m in get_nodes_in_group("maquinas"):
		if m.name == "Elevador":
			ele = m
	ele.unlocked = true
	ele.cabine.quebra()
	check(mt.quebras.get("cabine", 0) >= 1, "a cabine quebrou (contada)")
	arm.stock["ferro"] = 200.0
	arm.wood_stored = 200.0
	arm._recount()
	ok = await espera(func(): return ele.cabine.consertando, 30.0)
	check(ok and ele.oficio_obra() == "mecanico" and mec._obra_e_minha(ele), "o conserto do cabo virou obra do mecânico")
	var cf: int = mt.consertos_feitos
	ok = await espera(func(): return not ele.cabine.quebrada, 300.0)
	check(ok and mt.consertos_feitos == cf + 1, "o mecânico consertou o cabo (consertos %d)" % mt.consertos_feitos)
	ele.unlocked = false
	var est = null
	for m in get_nodes_in_group("maquinas"):
		if m.manut_tipo() == "trilho":
			est = m
	check(est != null and est.oficio_obra() == "mecanico" and mec._obra_e_minha(est) and not w[1]._obra_e_minha(est), "o trilho é do mecânico (com mecânico, o engenheiro não pega)")

	print("== G2) sem mecânico: o engenheiro conserta o que quebrou; preventiva não")
	mec.set_job(mec.ROLE_IDLE)
	mec = null
	var e2 = w[1]
	e2.set_job("engenheiro")
	check(e2._obra_e_minha(est), "sem mecânico, o trilho volta pro engenheiro")
	col._desgaste.gasta(1.0)
	ok = await espera(func(): return mt.conserto_de(col) != null, mt.conserto_tenta_cada * 2.0 + 2.0)
	check(ok and mt.conserto_de(col).oficio == "mecanico" and e2._obra_e_minha(mt.conserto_de(col)), "o conserto abriu e o engenheiro pode pegar")
	ok = await espera(func(): return not col.manut_quebrada(), 200.0)
	check(ok, "o engenheiro consertou o coletor")
	esc._desgaste.condicao = 0.5
	await anda(40.0)
	check(esc.manut_condicao() <= 0.5 + 0.001 and e2.get_state() != "manutencao", "sem mecânico, ninguém faz preventiva (%.2f)" % esc.manut_condicao())
	print("  engenheiro com obra de construção e conserto ao mesmo tempo: a construção primeiro")
	esc._desgaste.restaura()
	arm.wood_stored = 200.0
	arm.stock["ferro"] = 200.0
	arm._recount()
	var pos4 := spot_near(hub.global_position + Vector2(200, -60))
	check(hub._confirm_comedouro(pos4), "encomendou outra cozinha")
	obra = canteiro("comedouro")
	col._desgaste.gasta(1.0)  # (com material e engenheiro: o conserto abre na hora)
	check(mt.conserto_de(col) != null, "o conserto abriu junto")
	await anda(3.0)
	check(e2._obra == obra or e2._material_obra == obra, "o engenheiro pegou a construção, não o conserto")
	ObraSite.cancelar(obra)
	obra = null

	print("== I) missões e telemetria")
	var ms = g("missoes")
	check(ms.valor_do_objetivo(["entregas", "", 1]) == float(lg.entregas) and lg.entregas >= 3, "objetivo 'entregas' (%d)" % lg.entregas)
	check(ms.valor_do_objetivo(["consertos", "", 1]) == float(mt.consertos_feitos) and ms.valor_do_objetivo(["consertos", "preventiva", 1]) == float(mt.preventivas), "objetivo 'consertos' e 'preventiva'")
	var tel := load("res://scripts/core/telemetria.gd")
	check((tel.COLUNAS as Array).has("maquinas_quebradas") and (tel.COLUNAS as Array).has("entregas_carregador"), "a telemetria tem as colunas novas")
	Engine.time_scale = 1.0

	print("== J) save e save antigo")
	w[0].set_job("carregador")
	w[5].set_job("mecânico")
	esc._desgaste.condicao = 0.42
	coz.raw_local = 7.0
	var nomes := {String(w[0].display_name): "carregador", String(w[5].display_name): "mecânico", String(w[1].display_name): "engenheiro"}
	var ent0: int = lg.entregas
	var sm = root.get_node("SaveManager")
	sm.save_game()
	var js = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
	check(js is Dictionary and js.has("logistica") and js.has("manutencao"), "o save tem 'logistica' e 'manutencao'")
	check(sm.load_game(), "carregou")
	ok = await espera(func(): return current_scene != null and current_scene != main and g("manutencao") != null and g("escavadeira") != null, 30.0)
	await anda(1.0)
	main = current_scene
	var jobs_ok := true
	for wk in ws():
		if nomes.has(String(wk.display_name)) and wk.job != nomes[String(wk.display_name)]:
			jobs_ok = false
	check(jobs_ok, "as funções voltaram (carregador, mecânico, engenheiro)")
	check(absf(g("escavadeira").manut_condicao() - 0.42) < 0.01, "o desgaste da escavadeira voltou (%.2f)" % g("escavadeira").manut_condicao())
	check(g("logistica").entregas >= ent0 and g("manutencao").quebras.get("coletor_madeira", 0) >= 2 and g("manutencao").consertos_feitos >= 3, "os contadores voltaram (entregas %d/%d, quebras %s, consertos %d)" % [g("logistica").entregas, ent0, str(g("manutencao").quebras), g("manutencao").consertos_feitos])
	check(absf(float(g("comedouros").raw_local) - 7.0) < 0.01, "o estoque da cozinha voltou")
	# save antigo: sem as chaves novas, os carregadores/mecânicos viram mineradores
	var velho: Dictionary = js.duplicate(true)
	velho.erase("logistica")
	velho.erase("manutencao")
	_tira(velho, ["desgaste", "barras_prontas", "raw_local", "entrega_mao"])
	if velho.has("fundo") and velho.fundo is Dictionary:
		velho.fundo["ventiladores"] = (velho.fundo.get("ventiladores", []) as Array).map(func(p): return [p[0], p[1]])
	for wd in (velho.get("workers", []) as Array):
		if wd is Dictionary and String(wd.get("job", "")) in ["carregador", "mecânico"]:
			wd["job"] = "minerador"
	var f := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(velho))
	f.close()
	check(sm.load_game(), "carregou o save antigo")
	var antes_id: int = main.get_instance_id()
	ok = await espera(func(): return current_scene != null and current_scene.get_instance_id() != antes_id and g("manutencao") != null and g("escavadeira") != null, 30.0)
	await anda(1.0)
	main = current_scene
	var novas := get_nodes_in_group("maquinas").filter(func(m): return m.manut_tipo() in ["escavadeira", "coletor_madeira", "coletor_minerio", "ventilador", "robo"])
	check(not novas.is_empty() and novas.all(func(m): return m.manut_condicao() >= 0.99 and not m.manut_quebrada()), "save antigo: as máquinas novas inteiras (100%%; o ventilador já gastou um segundo): %s" % str(novas.map(func(m): return "%s %.3f" % [m.manut_tipo(), m.manut_condicao()])))
	var eng_ok := ws().any(func(wk): return String(wk.display_name) == String(nomes.keys()[2]) and wk.job == "engenheiro")
	check(eng_ok, "save antigo: as funções de sempre continuam (engenheiro)")
	check(g("logistica").entregas == 0 and g("manutencao").consertos_feitos == 0 and g("comedouros").raw_local == 0.0, "save antigo: nada a caminho, nada contado, cozinha sem estoque")

	print("\nFALHAS: %d" % fails)
	Engine.time_scale = 1.0
	quit()


func _tira(d, chaves: Array) -> void:
	if d is Dictionary:
		for k in chaves:
			d.erase(k)
		for k in d:
			_tira(d[k], chaves)
	elif d is Array:
		for x in d:
			_tira(x, chaves)
