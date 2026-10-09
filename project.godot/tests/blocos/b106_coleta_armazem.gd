extends SceneTree
## Bloco 106: COLETA, ARMAZÉM POR COMPARTIMENTO e OCIOSIDADE. (A) Os compartimentos lógicos (alimentos, madeira, minérios e
## barras, manufaturados), a capacidade por nível e a categoria de cada item. (B) Um compartimento cheio não bloqueia os
## outros (o lenhador entrega madeira com o minério cheio); a janela mostra uma barra por compartimento; o alerta diz
## "armazém de X cheio"; nada some (devolução entra mesmo cheio). (C) Ociosidade: o minerador com o minério cheio para de
## minerar, guarda a carga, espera DISPONÍVEL no Centro (estado próprio, balão "armazém cheio") e volta sozinho quando
## abre espaço; o engenheiro com sobra de minério não trava a obra. (D) As máquinas param ANTES de produzir (coletor de
## minério, escavadeira, coletor de madeira). (E) O ritmo novo da mineração (@export na Economia). (F) O vagonete da boca
## começa em RUÍNA: só com mecânico dá pra restaurar; em ruína o ponto não recebe; restaurado funciona sem o mecânico;
## restaurar não liga a mina. (G) Save e save antigo. RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
var Arm: GDScript = null  # (load em tempo de execução: o armazem.gd usa o Audio, que o preload do teste não vê)
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


## Enche o compartimento de minério do armazém até o limite.
func enche_minerio(arm) -> void:
	arm.stock["ferro"] = 0.0
	arm._recount()
	arm.stock["ferro"] = arm.espaco_cat("minerios")
	arm._recount()


func roda() -> void:
	var eco = g("economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	var hud = g("hud")
	var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
	g("sun").season_wave_chance = nunca
	while ws().size() < 6:
		eco.novo_ipezinho()
	await process_frame
	var w: Array = ws()
	Arm = load("res://scripts/props/armazem.gd")

	print("== A) os compartimentos (lógicos, no mesmo armazém)")
	check(Arm.CATEGORIAS == ["alimentos", "madeira", "minerios", "manufaturados"], "4 compartimentos")
	check(arm.nivel == 1 and arm.capacidade_cat("alimentos") == 150.0 and arm.capacidade_cat("madeira") == 350.0
		and arm.capacidade_cat("minerios") == 400.0 and arm.capacidade_cat("manufaturados") == 100.0, "nível 1: 150 / 350 / 400 / 100")
	check(arm.capacidade() == 1000.0 and arm.capacidade_minima_no_nivel(2) == 2500.0, "o total é a soma (1.000); o nível 2 dá 2.500")
	check(Arm.categoria_de("ferro") == "minerios" and Arm.categoria_de("barra_ferro") == "minerios" and Arm.categoria_de("desconhecido") == "minerios"
		and Arm.categoria_de("madeira") == "madeira" and Arm.categoria_de("tabua") == "madeira" and Arm.categoria_de("comida_crua") == "alimentos"
		and Arm.categoria_de("couro") == "manufaturados" and Arm.categoria_de("prego") == "manufaturados", "a categoria de cada item")
	arm.stock["ferro"] = 10.0
	arm.add_item("barra_ferro", 5.0)
	arm.wood_stored = 7.0
	arm.add_item("tabua", 3.0)
	arm.raw_stored = 4.0
	arm.leather_stored = 2.0
	arm.add_item("prego", 6.0)
	arm._recount()
	check(arm.usado_cat("minerios") == 15.0 and arm.usado_cat("madeira") == 10.0 and arm.usado_cat("alimentos") == 4.0
		and arm.usado_cat("manufaturados") == 8.0, "o uso de cada compartimento (15/10/4/8)")
	arm.take_item("barra_ferro", 5.0)
	arm.take_item("tabua", 3.0)
	arm.take_item("prego", 6.0)
	arm.leather_stored = 0.0

	print("== B) um cheio não bloqueia os outros; nada some")
	enche_minerio(arm)
	arm.wood_stored = 0.0
	arm.raw_stored = 0.0
	arm._recount()
	check(arm.cheio_cat("minerios") and not arm.cheio_cat("madeira") and not arm.cheio(), "minério cheio, madeira livre (o armazém não está 'cheio')")
	check(eco.armazem_com_espaco(arm.global_position, 1.0, "minerios") == null and eco.armazem_com_espaco(arm.global_position, 1.0, "madeira") == arm,
		"armazem_com_espaco por compartimento")
	check(eco.categorias_cheias() == ["minerios"], "a economia sabe o compartimento cheio")
	var lenh = w[0]
	lenh.set_job("lenhador")
	lenh.wood_carrying = 6.0
	check(arm.accepts_worker(lenh) or lenh.get_state() != "hauling", "o armazém aceita quem traz madeira")
	var m0: float = arm.usado_cat("madeira")
	Engine.time_scale = 4.0
	var entregou := await espera(func(): return arm.usado_cat("madeira") > m0, 60.0)
	check(entregou, "com o minério cheio, o lenhador entregou madeira (%d)" % int(arm.usado_cat("madeira")))
	await anda(1.0)
	hud._refresh_alertas(ws())
	var dica: String = hud._alertas._botoes["armazem_cheio"].button.tooltip_text
	check(hud._alertas.ativos().has("armazem_cheio") and dica.contains("minérios"), "o alerta: 'armazém de minérios e barras cheio' (%s)" % dica.split("\n")[1].left(50))
	var antes: float = arm.usado_cat("minerios")
	eco.devolve("ferro", 5.0, arm.global_position)
	check(arm.usado_cat("minerios") >= antes + 5.0 - 0.01, "devolução entra mesmo cheio (nada some)")
	hud.open_panel("armazem")
	var pn = hud._panels["armazem"]
	pn.refresh()
	check(pn._cat_linhas.size() == 4 and String(pn._cat_linhas["minerios"].label.text).contains("CHEIO") and not String(pn._cat_linhas["madeira"].label.text).contains("CHEIO"),
		"a janela: uma barra por compartimento ('%s')" % pn._cat_linhas["minerios"].label.text)
	hud.close_panels()

	print("== C) ociosidade: o minerador para, guarda a carga, espera disponível e volta sozinho")
	for p in get_nodes_in_group("pontos_carga"):
		p.parar_por_area(true, "teste")  # (nenhum ponto do vagonete recebe)
	var min_ = w[1]
	min_.set_job("minerador")
	min_.carrying = 6.0
	min_.cargo_type = "ferro"
	min_.wake_decision()
	var esperando := await espera(func(): return min_.get_state() == "esperando_espaco", 20.0)
	check(esperando, "minério cheio: o minerador vai pro estado 'esperando espaço' (%s)" % min_.get_state())
	check(is_equal_approx(min_.carrying, 6.0), "guardou o que carregava (%.0f)" % min_.carrying)
	check(min_.motivo_parado() == "armazem_cheio", "o balão: armazém cheio")
	check(String(min_.get_state_label()).contains("espaço"), "o estado aparece ('%s')" % min_.get_state_label())
	await anda(6.0)
	check(min_.get_state() == "esperando_espaco" and is_equal_approx(min_.carrying, 6.0), "não minera o que não cabe (continua com 6)")
	var eng = w[2]
	eng.set_job("engenheiro")
	eng.carrying = 4.0
	eng.cargo_type = "ferro"
	eng.wake_decision()
	await anda(2.0)
	check(eng.get_state() != "esperando_espaco" and eng.get_state() != "storing", "o engenheiro com sobra de minério não trava (%s)" % eng.get_state())
	arm.stock["ferro"] = 0.0
	arm._recount()  # abre espaço
	var voltou := await espera(func(): return min_.get_state() in ["storing", "mining"], 30.0)
	check(voltou, "abriu espaço: ele volta sozinho (%s)" % min_.get_state())
	eng.carrying = 0.0
	for p in get_nodes_in_group("pontos_carga"):
		p.parar_por_area(false)

	print("== D) as máquinas param ANTES de produzir (nada some)")
	var jaz: Node = null
	for j in get_nodes_in_group("minerios"):
		if j.has_method("is_unlocked") and j.is_unlocked() and j.ore_remaining > 100.0 and j.global_position.y < 1500.0:
			jaz = j
			break
	var cm = load("res://scenes/props/coletor_minerio.tscn").instantiate()
	cm.position = jaz.global_position + Vector2(60, 40)
	hub.get_parent().add_child(cm)
	await process_frame
	var op = w[3]
	op.set_job("minerador")
	cm.designate(op)
	enche_minerio(arm)
	var r0: float = jaz.ore_remaining
	await anda(10.0)
	check(cm._sem_espaco and cm.total_produced == 0.0, "o coletor de minério parado com o minério cheio (produziu %d)" % int(cm.total_produced))
	check(jaz.ore_remaining >= r0 - 0.5 or jaz.ore_remaining >= jaz.ore_total - 0.5, "não tirou da jazida (%.0f -> %.0f)" % [r0, jaz.ore_remaining])
	var esc = g("escavadeira")
	esc.complete = true
	if not esc.built_reactors.has("vapor"):
		esc.built_reactors.append("vapor")
	esc.reactor = "vapor"
	esc.drill_on = true
	arm.stock["carvao"] = 0.0
	arm._recount()
	enche_minerio(arm)
	await anda(5.0)
	check(esc.sem_espaco and esc.total_produced == 0.0 and esc.drill_status().contains("cheio"), "a escavadeira para com o minério cheio ('%s')" % esc.drill_status())
	esc.drill_on = false
	cm.release()
	cm.queue_free()
	arm.stock["ferro"] = 0.0
	arm._recount()

	print("== E) o ritmo da mineração")
	check(eco.ritmo_mineracao > 0.0 and eco.ritmo_mineracao < 0.2, "ritmo_mineracao @export (%.3f)" % eco.ritmo_mineracao)
	var boca = g("bocas_mina")
	check(boca.taxa_dentro <= 5.0, "a galeria de dentro acompanha (taxa_dentro %.1f/h)" % boca.taxa_dentro)
	var j2: Node = jaz
	var antes_m: float = j2.ore_remaining
	var mineiro = w[4]
	mineiro.set_job("minerador")
	await anda(20.0)
	check(true, "(minerou %.1f em 20 s da jazida de teste)" % maxf(antes_m - j2.ore_remaining, 0.0))

	print("== F) o vagonete da boca começa em RUÍNA")
	check(boca.etapa == 0 and not boca.restaurado(), "partida nova: em ruína (etapa 0)")
	check(not boca.is_usable() and not boca.operando(), "em ruína o ponto não recebe e o carrinho não anda")
	check(boca.etapa_block_reason().begins_with("precisa de mecânico"), "sem mecânico: '%s'" % boca.etapa_block_reason())
	check(not boca.pedir_etapa(), "o pedido não passa sem mecânico")
	hud.open_panel("vagonete")
	var vp = hud._panels.get("vagonete")
	if vp:
		vp.refresh()
	check(vp != null and vp._button.disabled and vp._button.text.contains("mecânico"), "a janela: botão desligado com 'precisa de mecânico' (%s)" % (("'%s' desligado=%s visível=%s" % [vp._button.text, vp._button.disabled, vp.visible]) if vp else "sem janela: %s" % str(hud._panels.keys())))
	hud.close_panels()
	var mec = w[5]
	mec.set_job("mecânico")
	eco.credits = 5000.0
	arm.stock["ferro"] = 200.0
	arm.wood_stored = 200.0
	arm._recount()
	check(boca.etapa_block_reason() == "", "com mecânico pode ('%s')" % boca.etapa_block_reason())
	var cr0: float = eco.credits
	check(boca.pedir_etapa() and boca.pago and boca.obra_pending() and boca.oficio_obra() == "mecanico", "etapa 1 paga: obra do mecânico")
	check(mec._obra_e_minha(boca), "o mecânico pega a obra")
	var e1 := await espera(func(): return boca.etapa >= 2 and not boca.pago, 200.0)
	check(e1, "o mecânico fez a etapa 1 (levando a madeira)")
	for i in 2:
		check(boca.pedir_etapa(), "etapa %d paga (%s)" % [boca.etapa, boca.etapa_block_reason()])
		var site = ObraSite.de(boca)
		for k in site.necessario:
			site.entregar(k, 999.0)
		boca.obra_work(999.0)
	check(boca.restaurado() and boca.etapa == boca.ETAPA_PRONTA, "restaurado (as 3 etapas)")
	check(cr0 - eco.credits >= 120.0 + 160.0 - 0.5, "pagou as etapas (%d cr)" % int(cr0 - eco.credits))
	mec.set_job("ocioso")
	await anda(1.0)
	check(boca.is_usable() and boca.restaurado(), "restaurado funciona sem o mecânico")
	check(g("work_areas").areas.is_empty(), "restaurar não criou nem ligou área de mina (o comando é do jogador)")

	print("== G) save e save antigo")
	var d: Dictionary = boca.get_save_data()
	check(d.has("etapa") and int(d.etapa) == boca.ETAPA_PRONTA, "o vagonete salva a etapa")
	boca.etapa = 0
	boca.load_save_data(d)
	check(boca.restaurado(), "carregou restaurado")
	var velho := d.duplicate()
	velho.erase("etapa")
	velho.erase("pago")
	velho.erase("progresso")
	boca.etapa = 0
	boca.load_save_data(velho)
	check(boca.restaurado(), "save antigo (sem a chave): o vagonete que já andava continua andando")
	var ad: Dictionary = arm.get_save_data()
	ad["stock"]["ferro"] = 900.0  # mais que o compartimento (save antigo com 900 de minério)
	arm.load_save_data(ad)
	check(is_equal_approx(arm.stock["ferro"], 900.0) and arm.cheio_cat("minerios"), "save antigo acima do limite: nada some (só não recebe mais minério)")
	check(not arm.cheio_cat("madeira"), "e os outros compartimentos continuam recebendo")
	arm.stock["ferro"] = 50.0
	arm._recount()
	var sm = root.get_node("SaveManager")
	sm.save_game()
	var js = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
	check(js is Dictionary and int(js.village.estacao_mina.get("etapa", -1)) == boca.ETAPA_PRONTA, "o save do jogo leva a etapa do vagonete da boca")

	Engine.time_scale = 1.0
	print("\nFALHAS: %d" % fails)
	quit()
