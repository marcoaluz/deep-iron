extends SceneTree
## Bloco 104: ROBÔ ANTIGO, BATEDOR E EXPEDIÇÕES. (A) A cadeia do robô no lugar da sorte: o corpo do Ferrugento estudado ->
## o sinal (o Rádio; a Antena da Oficina) de noite -> as 3 escutas (a pesquisadora) -> a fábrica soterrada revelada.
## (B) O batedor: a função (tecla K), bate o mato, rastreia a toca (nascem mais), avista de longe. (C) A janela (tecla ;):
## as regiões (revelada / "?" / trancada), a equipe, o risco com as partes. (D) A expedição: a ração paga, a equipe sai do
## mundo (fora do grupo da vila: não come, não defende), a decisão do caminho, a volta com o relatório, os achados, o
## diário; a exploração revela a região. (E) O robô achado na fábrica (no fluxo de sempre). (F) Ferimento e morte (sem
## corpo). (G) Uma por vez e o Posto. (H) Sinais, missões, telemetria. (I) Save (quem está fora) e save antigo.
## RODAR SÓ COM APPDATA ISOLADO.
const Teclas := preload("res://scripts/core/teclas.gd")
var main: Node
var fails := 0
var _t0 := 0


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
	_t0 = Time.get_ticks_msec()
	_roda()


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - _t0 > 400000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		Engine.time_scale = 1.0
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func _espera(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += root.get_process_delta_time()


func _ate(cond: Callable, s: float) -> bool:
	var t := 0.0
	while t < s:
		if cond.call():
			return true
		await process_frame
		t += root.get_process_delta_time()
	return cond.call()


func _roda() -> void:
	for i in 12:
		await process_frame
	await _espera(2.0)
	var ex = g("expedicoes")
	var cat = g("catalogo")
	var eco = g("economy")
	var hud = g("hud")
	var res = g("research")
	var of = g("oficina")
	var dn = g("day_night")
	var finds = g("finds")
	var mig = g("migrantes")
	if mig:
		mig.proximo = 1.0e9
	load("res://scripts/core/defense.gd").moradores_desligados = true
	while get_nodes_in_group("ipezinhos").size() < 7:
		eco.novo_ipezinho()
	await process_frame
	var gente: Array = get_nodes_in_group("ipezinhos")
	for id in ["cobre", "carvao", "coelho"]:
		cat.estuda(id, null)
	check(ex != null and ex.regioes().size() >= 7, "as expedições na cena com as regiões dos dados (%d)" % (ex.regioes().size() if ex else 0))
	check(Teclas.acao(KEY_K) == "batedor" and Teclas.acao(KEY_SEMICOLON) == "painel_expedicoes", "K = batedor, ; = Expedições")

	print("== A) a cadeia do robô")
	check(ex.cadeia == 0 and not ex.sorte_robo, "partida nova: sem sorte pro robô, a cadeia no começo")
	check(of.tool_block_reason("antena").contains("Ferrugento"), "a Antena só depois da pista (%s)" % of.tool_block_reason("antena"))
	cat.avista("ferrugento", false)
	cat.estuda("ferrugento", null)
	check(ex.cadeia == 1 and g("diary").has_page("robo_origem"), "o corpo do Ferrugento estudado: a pista da fábrica (diário)")
	check(not ex.tem_receptor(), "sem o Rádio e sem a Antena, ninguém capta o sinal")
	of.crafted["antena"] = true
	check(ex.tem_receptor(), "a Antena improvisada capta (pra quem escolheu a Hidroponia)")
	dn.time = dn.tempo_da_hora(23.0)
	var sinal := await _ate(func(): return ex.cadeia == 2, 4.0)
	check(sinal and g("diary").has_page("robo_sinal"), "de noite, o sinal no rádio (diário)")
	check(ex.ESCUTAS.all(func(x): return cat.estado(x) == cat.AVISTADO), "as 3 escutas pra pesquisadora")
	dn.time = dn.tempo_da_hora(9.0)
	var loc := [false]
	ex.robo_localizado.connect(func(): loc[0] = true)
	var pq: Node = gente[0]
	pq.set_job("pesquisador")
	cat.segundos_estudo = 2.0
	Engine.time_scale = 4.0
	var tri := await _ate(func(): return ex.cadeia == 4, 150.0)
	Engine.time_scale = 1.0
	check(tri, "a pesquisadora fez as 3 escutas (cadeia %d)" % ex.cadeia)
	check(ex.reveladas.has("fabrica") and loc[0] and g("diary").has_page("robo_regiao"), "a fábrica soterrada revelada (sinal robo_localizado)")
	pq.set_job("ocioso")

	print("== B) o batedor")
	var bat: Node = gente[1]
	bat.set_job("batedor")
	check(bat.is_scout() and bat.outfit() == "batedor", "a função batedor com a roupa própria")
	bat.wake_decision()
	var bateu := await _ate(func(): return bat.get_state() == "batendo", 10.0)
	check(bateu, "de dia ele bate o mato (%s)" % bat.get_state())
	var coelho: Node = null
	for t in get_nodes_in_group("caca"):
		if t.animal == "coelho":
			coelho = t
	coelho.rastreia()
	check(coelho.rastreada() and is_equal_approx(coelho._mult_rastreada(), ex.toca_rastreada_mult), "a toca rastreada: nascem mais bichos hoje (x%.1f)" % coelho._mult_rastreada())
	var javali: Node = null
	for t in get_nodes_in_group("caca"):
		if t.animal == "javali":
			javali = t
	bat.auto_mode = false
	bat.global_position = javali.global_position + Vector2(300, 0)
	var viu := await _ate(func(): return cat.estado("javali") != cat.DESCONHECIDO, 4.0)
	check(viu, "o batedor avista de longe (300 px da toca do javali)")
	bat.auto_mode = true

	print("== C) a janela e o risco")
	hud.open_panel("expedicoes")
	var pn = hud._panels.get("expedicoes")
	check(pn != null and pn.visible, "a janela das Expedições abre")
	pn.escolhe("floresta")
	await process_frame
	check(String(pn._marcas["floresta"].text).begins_with("A floresta"), "a floresta revelada pelo nome")
	check(String(pn._marcas["estrada"].text) == "?", "a estrada velha escondida: '?'")
	check(String(pn._marcas["ruinas_leste"].text) == "?" and pn._marcas["ruinas_leste"].tooltip_text.contains("leste"), "as ruínas do leste trancadas (o leste fechado: ? apagado com o motivo)")
	var guarda: Node = gente[2]
	guarda.set_job("guarda")
	guarda.equip("lanca")
	var med: Node = gente[3]
	med.set_job("médico")
	check(ex.motivo("floresta", [guarda, med], true, false, 1).contains("batedor"), "sem batedor não sai")
	var equipe: Array = [bat, guarda]
	var rk: Dictionary = ex.risco("floresta", equipe, true, false)
	check(absf(float(rk.total) - 0.08 * ex.mult_guarda * ex.mult_batedor) < 0.001 and rk.partes.size() == 3, "o risco: perigo x escolta x batedor (%.3f, %d partes)" % [rk.total, rk.partes.size()])
	var rk2: Dictionary = ex.risco("fabrica", equipe, false, true)
	check(rk2.partes.any(func(p): return String(p[0]).begins_with("sem traje") or String(p[0]).contains("antirradiação")) and rk2.partes.any(func(p): return String(p[0]) == "sem ração"), "sem traje e sem ração aparecem no risco")
	pn.define_equipe(equipe)
	await process_frame
	check(pn._det.find_child("Risco", true, false) != null and pn._det.find_child("Partir", true, false) != null, "a janela mostra o risco e o botão Partir")

	print("== D) a expedição")
	dn.time = dn.tempo_da_hora(9.0)
	var com0: float = ex.comida_na_cozinha()
	check(ex.motivo("floresta", equipe, true, false, 1) == "", "pode sair (%s)" % ex.motivo("floresta", equipe, true, false, 1))
	var saiu := [""]
	ex.expedicao_saiu.connect(func(r): saiu[0] = r)
	check(ex.parte("floresta", equipe, true, false, 1), "partiu")
	check(ex.comida_na_cozinha() < com0 - 1.0 and saiu[0] == "floresta", "a ração saiu da cozinha (%d -> %d) e o sinal" % [int(com0), int(ex.comida_na_cozinha())])
	Engine.time_scale = 4.0
	var fora := await _ate(func(): return equipe.all(func(w): return w.fora), 60.0)
	Engine.time_scale = 1.0
	check(fora, "a equipe andou até a saída e saiu do mundo")
	check(not bat.is_in_group("ipezinhos") and not bat.visible and not g("defense").guards().has(guarda), "fora: não está no grupo da vila e não defende")
	var fome0: float = bat.hunger
	await _espera(1.0)
	check(is_equal_approx(bat.hunger, fome0), "fora: não come (a fome parada)")
	check(ex.motivo("estrada", [gente[4], gente[5]], false, false, 1).contains("expedição"), "uma expedição por vez")
	var e: Dictionary = ex.em_curso[0]
	e.decorrido = float(e.decisoes[0].quando) + 0.1
	await process_frame
	await process_frame
	check(e.decisoes[0].mostrada and hud._confirma != null and hud._confirma.visible, "a decisão do caminho apareceu (%s)" % e.decisoes[0].evento)
	hud._confirma.confirmed.emit()
	hud._confirma.hide()
	check(String(e.decisoes[0].escolha) == "a", "escolheu a opção A")
	e.risco = 0.0
	e.volta_dia = dn.day
	e.volta_t = 0.0
	e.extra_t = 0.0
	var volta := [{}]
	ex.expedicao_voltou.connect(func(_r, rr): volta[0] = rr)
	var voltou := await _ate(func(): return not volta[0].is_empty(), 5.0)
	check(voltou and bat.is_in_group("ipezinhos") and bat.visible and not bat.fora, "voltou: de novo na vila")
	check(ex.relatorios.size() == 1 and String(ex.relatorios[0].texto).contains("Acharam"), "o relatório: %s" % (String(ex.relatorios[0].texto).replace("\n", " / ") if not ex.relatorios.is_empty() else "?"))
	check(g("diary").has_page("expedicao_%d" % int(e.n)), "o relatório no diário")
	check(ex.voltou_de.has("floresta") and ex.total_voltaram == 1, "a volta contada")

	print("== E) o robô na fábrica")
	var ex_eq: Array = [bat, gente[4]]
	gente[4].set_job("guarda")
	gente[4].equip("lanca")
	dn.time = dn.tempo_da_hora(9.0)
	check(ex.parte("fabrica", ex_eq, false, false, 2), "a expedição pra fábrica soterrada (%s)" % ex.motivo("fabrica", ex_eq, false, false, 2))
	var ef: Dictionary = ex.em_curso[0]
	for w in ex_eq:
		w.sai_do_mundo()
	ef.fase = "fora"
	for d in ef.decisoes:
		d.escolha = "b"
		d.mostrada = true
	ef.risco = 0.0
	ef.volta_dia = dn.day
	ef.volta_t = 0.0
	var achou := await _ate(func(): return finds.robot_found, 5.0)
	await process_frame
	var robo: Node = g("robos")
	check(achou and robo != null and robo.state == "found" and ex.cadeia == 5, "achou o robô: ele chega desligado, no fluxo de sempre (%s)" % (robo.state if robo else "?"))

	print("== F) ferimento e morte")
	dn.time = dn.tempo_da_hora(9.0)
	var vit: Node = gente[5]
	vit.set_job("guarda")
	vit.equip("lanca")
	var nome_vit: String = vit.display_name
	check(ex.parte("floresta", [bat, vit], true, false, 1), "outra expedição")
	var em: Dictionary = ex.em_curso[0]
	for w in [bat, vit]:
		w.sai_do_mundo()
	em.fase = "fora"
	for d in em.decisoes:
		d.escolha = "b"
		d.mostrada = true
	em.risco = 0.95
	ex.chance_grave = 1.0
	ex.morte_sem_medico = 1.0
	em.volta_dia = dn.day
	em.volta_t = 0.0
	var vf := [{}]
	ex.expedicao_voltou.connect(func(_r, rr): vf[0] = rr)
	var v2 := await _ate(func(): return not vf[0].is_empty(), 5.0)
	check(v2 and (vf[0].mortos.size() + vf[0].feridos.size()) >= 1, "o risco alto feriu/matou (mortos %s, feridos %s)" % [vf[0].get("mortos", []), vf[0].get("feridos", [])])
	await process_frame
	check(get_nodes_in_group("corpos").all(func(c): return c.nome != nome_vit), "quem morreu longe não deixa corpo")
	ex.chance_grave = 0.3
	ex.morte_sem_medico = 0.3

	print("== G) o Posto de expedição")
	var hub = g("village_hub")
	check(ex.max_agora() == 1, "sem o Posto: 1 expedição")
	hub.upgrades["posto"] = 1
	check(ex.max_agora() == 2, "com o Posto: 2")
	check(hub.UPGRADE_IDS.has("posto") and hub.upgrade_description("posto") != "", "o Posto é uma melhoria do Centro")
	hub.upgrades["posto"] = 0

	print("== H) sinais, missões, telemetria")
	var ms = g("missoes")
	check(ms.valor_do_objetivo(["expedicao", "", 1]) >= 2.0 and ms.valor_do_objetivo(["expedicao", "floresta", 1]) == 1.0, "objetivo 'expedicao'")
	check(ms.valor_do_objetivo(["regiao", "fabrica", 1]) == 1.0, "objetivo 'regiao'")
	var tel := load("res://scripts/core/telemetria.gd")
	check((tel.COLUNAS as Array).has("expedicoes_fora") and (tel.COLUNAS as Array).has("achados_expedicao"), "a telemetria tem as colunas das expedições")

	print("== I) save e save antigo")
	dn.time = dn.tempo_da_hora(9.0)
	var novo1: Node = eco.novo_ipezinho()
	var novo2: Node = eco.novo_ipezinho()
	await process_frame
	novo1.set_job("batedor")
	novo2.set_job("guarda")
	novo2.equip("lanca")
	var bat2: Node = novo1
	var g2: Node = novo2
	check(ex.parte("floresta", [bat2, g2], false, false, 1), "uma expedição pra salvar no meio")
	for w in [bat2, g2]:
		w.sai_do_mundo()
	ex.em_curso[0].fase = "fora"
	var d: Dictionary = ex.get_save_data()
	check(d.em_curso.size() == 1 and (d.em_curso[0].saves as Array).size() == 2, "o save leva quem está fora (o save de cada um)")
	var nomes_fora: Array = [String(bat2.display_name), String(g2.display_name)]
	ex.load_save_data(d)
	await process_frame
	await process_frame
	await process_frame
	var recriados: Array = ex.em_curso[0].membros if not ex.em_curso.is_empty() else []
	check(recriados.size() == 2 and recriados.all(func(w): return is_instance_valid(w) and w.fora and not w.is_in_group("ipezinhos")), "carregou: os dois de novo fora do mundo")
	check(recriados.map(func(w): return String(w.display_name)) == nomes_fora, "os mesmos (%s)" % [nomes_fora])
	ex.load_save_data({})
	finds.robot_found = false
	ex.depois_de_carregar(false)
	check(ex.sorte_robo and ex.em_curso.is_empty() and ex.reveladas.has("floresta"), "save antigo sem robô: a sorte continua como reserva; a floresta revelada")
	finds.robot_found = true
	ex.depois_de_carregar(false)
	check(ex.cadeia == 5 and not ex.sorte_robo, "save antigo com o robô: a cadeia cumprida")
	var sm = root.get_node("SaveManager")
	sm.save_game()
	var js = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
	check(js is Dictionary and js.has("expedicoes"), "o save do jogo tem a chave 'expedicoes'")

	print("\nFALHAS: %d" % fails)
	quit()
