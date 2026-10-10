extends SceneTree
## Bloco 108: POLÍTICAS DA VILA. (A) O padrão é o jogo de antes (todo multiplicador 1,0, nenhum ânimo, porção 8/45). (B) Acesso:
## libera no Vilarejo; a tecla F6 sem conflito; a janela no menu. (C) Jornada: produção/acidente/ânimo só em quem produz (os
## essenciais ficam de fora); a espera de 1 dia; voltar ao padrão é imediato com a vila insatisfeita. (D) Ração: a porção e a
## fome na mesma proporção, o teto com o ensopado, a fraqueza depois de N dias e a recuperação; o teto da penalidade de ânimo.
## (E) Segurança: a vigilância cobra por guarda ao anoitecer (sem créditos não vale), todos de vigia, o saque da brecha e o
## roubo pela metade, o portão protegido; o treinamento precisa de campo, sobe o teto a 125% (dano/vida pela fórmula de
## sempre) e o excesso cai devagar fora dele. (F) Migração: fechada para o relógio (a rede de segurança e o satélite valem;
## quem espera fica), seletiva espera cama, intervalo e prazo maiores. (G) Save, save antigo e a telemetria. (H) A janela.
## RODAR SÓ COM APPDATA ISOLADO.
const Teclas := preload("res://scripts/core/teclas.gd")
const Modificadores := preload("res://scripts/core/modificadores.gd")
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


func anda(s: float) -> void:
	var t0 := t
	while t - t0 < s:
		await process_frame


func perto(a: float, b: float, eps: float = 0.001) -> bool:
	return absf(a - b) <= eps


func soma(f: Array) -> float:
	var s := 0.0
	for x in f:
		s += float(x[1])
	return s


func _process(delta: float) -> bool:
	t += delta
	if t > 240.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
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
	var hub = g("village_hub")
	var hud = g("hud")
	var pol = g("politicas")
	var coz = g("comedouros")
	var migr = g("migrantes")
	var def = g("defense")
	var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
	g("sun").season_wave_chance = nunca
	def.first_invasion_day = 999
	while ws().size() < 8:
		eco.novo_ipezinho()
	await process_frame
	var w: Array = ws()
	w[0].set_job("minerador")
	w[1].set_job("cozinheiro")
	w[2].set_job("guarda")
	w[3].set_job("guarda")
	w[4].set_job("lenhador")
	await process_frame
	var mineiro: Node = w[0]
	var cozinheiro: Node = w[1]
	var guarda: Node = w[2]
	for x in ws():
		x.tracos = ["valente"]  # (Bloco 110: um traço que não mexe na reação às políticas — aqui o assunto é a política)

	print("-- (A) o padrão é o jogo de antes")
	check(pol != null and pol.is_in_group("modificadores"), "o nó Politicas existe e está no grupo dos modificadores")
	check(pol.e_padrao() and pol.resumo() == "jornada=normal racao=normal seguranca=padrao migracao=aberta", "tudo no padrão (%s)" % pol.resumo())
	var tudo_um := true
	for k in ["producao", "acidente", "porcao", "fome_refeicao", "migracao_intervalo", "treino", "roubo"]:
		for quem in [null, mineiro, cozinheiro, guarda]:
			if not perto(Modificadores.mult(self, k, quem), 1.0):
				tudo_um = false
	check(tudo_um, "todo multiplicador vale 1,0 no padrão")
	check(ws().all(func(x): return pol.fatores_animo(x).is_empty()), "nenhum motivo de ânimo no padrão")
	check(perto(coz._porcao(), 8.0) and perto(coz._fome_da_porcao(), 45.0), "porção 8 enchendo 45 (como antes)")
	check(perto(pol.teto_treino(), 1.0), "teto do treino 100%")
	var W = load("res://scripts/workers/ipezinho.gd")
	check([W.ROLE_COOK, W.ROLE_DOCTOR, W.ROLE_GUARD, W.ROLE_PRIEST].all(func(r): return r in pol.funcoes_essenciais), "os essenciais batem com os ROLE_* do ipezinho")

	print("-- (B) acesso")
	hub.level = 1
	check(not pol.liberada() and pol.motivo_bloqueio("jornada", "estendida").begins_with("libera no estágio Vilarejo"), "no Acampamento: trancada (%s)" % pol.motivo_bloqueio("jornada", "estendida"))
	check(hud._panels.has("politicas") and not hud._panels["politicas"].is_available(), "a janela existe e fica fora do menu antes do Vilarejo")
	check(hub.stage_unlocks_text(2).contains("Políticas da Vila"), "o Centro da Vila diz que o Vilarejo libera a janela")
	hub.level = 2
	check(pol.liberada() and hud._panels["politicas"].is_available(), "no Vilarejo: liberada")
	check(Teclas.acao(KEY_F6) == "painel_politicas" and hud.TECLA_JANELA.get("politicas") == "painel_politicas", "F6 = Políticas da Vila (e no menu Janelas)")
	var usadas := {}
	var conflito := ""
	for a in Teclas.PADRAO:
		for k in Teclas.PADRAO[a]:
			if usadas.has(k) and usadas[k] != a:
				conflito = "%s x %s" % [usadas[k], a]
			usadas[k] = a
	check(conflito == "" and not KEY_F6 in Teclas.RESERVADAS, "nenhuma tecla padrão repetida (%s)" % conflito)
	check(Teclas.NOMES.any(func(n): return n[0] == "painel_politicas"), "dá pra trocar a tecla nas Configurações")

	print("-- (C) jornada")
	var wm_min: float = mineiro.work_mult()
	var wm_coz: float = cozinheiro.work_mult()
	eco.credits = 1000.0
	check(pol.escolhe("jornada", "estendida"), "escolheu a jornada estendida")
	check(perto(mineiro.work_mult(), wm_min * 1.15), "mineiro rende x1,15 (%.3f -> %.3f)" % [wm_min, mineiro.work_mult()])
	check(perto(cozinheiro.work_mult(), wm_coz), "o cozinheiro (essencial) não muda")
	check(perto(Modificadores.mult(self, "acidente", mineiro), 1.30) and perto(Modificadores.mult(self, "acidente", cozinheiro), 1.0), "acidente x1,30 só em quem produz")
	check(perto(soma(pol.fatores_animo(mineiro)), -8.0) and pol.fatores_animo(cozinheiro).is_empty() and pol.fatores_animo(guarda).is_empty(), "ânimo -8 só em quem produz")
	check(mineiro.happiness_factors().any(func(f): return f[0] == "jornada estendida"), "o motivo aparece no ânimo do ipezinho (happiness_factors)")
	check(not pol.escolhe("jornada", "reduzida") and pol.motivo_bloqueio("jornada", "reduzida").begins_with("pode trocar daqui a"), "espera de 1 dia pra trocar de novo (%s)" % pol.motivo_bloqueio("jornada", "reduzida"))
	check(perto(float(pol.espera["jornada"]), g("day_night").cycle_length()), "a espera é 1 dia de jogo")
	check(pol.motivo_bloqueio("racao", "reduzida") == "", "a espera é por política (a ração está livre)")
	for x in ws():
		x.happiness = 20.0
	check(pol.vila_em_apuro() and pol.motivo_bloqueio("jornada", "normal") == "" and pol.motivo_bloqueio("jornada", "reduzida") != "", "vila insatisfeita: VOLTAR ao padrão é imediato; outra opção, não")
	check(pol.escolhe("jornada", "normal") and pol.opcao("jornada") == "normal", "voltou ao normal na hora")
	for x in ws():
		x.happiness = 70.0
	pol.espera["jornada"] = 0.0
	check(pol.escolhe("jornada", "reduzida") and perto(mineiro.work_mult(), wm_min * 0.85) and perto(soma(pol.fatores_animo(mineiro)), 5.0), "reduzida: x0,85 e +5")
	check(not pol.motivo_bloqueio("jornada", "reduzida").is_empty(), "a opção ativa não se escolhe de novo")
	pol.forca("jornada", "normal")

	print("-- (D) ração")
	pol.forca("racao", "reduzida")
	check(perto(coz._porcao(), 6.0) and perto(coz._fome_da_porcao(), 33.75), "reduzida: porção 6 enchendo 33,75 (a mesma proporção: não cria comida)")
	check(perto(soma(pol.fatores_animo(cozinheiro)), -6.0) and perto(soma(pol.fatores_animo(guarda)), -6.0), "ânimo -6 de todos")
	coz.set_prato("ensopado")
	check(perto(coz._porcao(), 9.0) and perto(coz._fome_da_porcao(), 45.0 * 1.25 * 0.75), "ensopado x reduzida: porção 9, fome 42,2")
	var guarda_porcao: float = pol.racao_reduzida_porcao
	pol.racao_reduzida_porcao = 3.0  # (uma "farta" exagerada, só pra ver o teto)
	check(perto(coz._porcao(), 12.0), "o teto: nunca mais que o ensopado (x1,5 = 12)")
	pol.racao_reduzida_porcao = guarda_porcao
	coz.set_prato("comum")
	pol.forca("jornada", "estendida")
	check(perto(soma(pol.fatores_animo(mineiro)), -12.0), "estendida (-8) + reduzida (-6) = -14 vira o teto -12 (%.1f)" % soma(pol.fatores_animo(mineiro)))
	check(perto(pol.animo_previsto("jornada", "normal") - pol.animo_previsto("jornada", "estendida"), 0.0, 99.0), "ânimo previsto calcula")
	pol.forca("jornada", "normal")
	check(not pol.fraqueza_ativa(), "sem fraqueza no começo")
	for i in pol.fraqueza_dias:
		pol._amanheceu(i)
	check(pol.fraqueza_ativa() and perto(Modificadores.mult(self, "producao", mineiro), 0.9) and perto(Modificadores.mult(self, "acidente", mineiro), 1.25), "3 dias seguidos: FRAQUEZA (x0,9 e acidente x1,25)")
	check(perto(Modificadores.mult(self, "producao", cozinheiro), 1.0), "a fraqueza não mexe nos essenciais (a cozinha não para)")
	pol.forca("racao", "normal")
	check(pol.fraqueza_ativa() and pol.fraqueza_recupera == 2, "voltou ao normal: a fraqueza ainda dura 2 dias")
	pol._amanheceu(0)
	pol._amanheceu(0)
	check(not pol.fraqueza_ativa() and perto(Modificadores.mult(self, "producao", mineiro), 1.0), "recuperou depois de 2 dias")
	pol.forca("racao", "reduzida")
	pol._amanheceu(0)
	pol.forca("racao", "normal")
	check(not pol.fraqueza_ativa() and pol.racao_dias == 0, "1 dia de reduzida não deixa fraqueza")
	coz.food_stock = 0.0
	check(Modificadores.mult(self, "porcao") <= 1.0, "a ração nunca aumenta a porção (sem comida, ninguém come)")
	coz.food_stock = 200.0

	print("-- (E) segurança")
	pol.forca("seguranca", "vigilancia")
	check(not pol.vigilancia_ativa(), "de dia ainda não pagou (cobra ao anoitecer)")
	eco.credits = 100.0
	var custo: int = pol.custo_vigilancia()
	pol._marco("anoitecer")
	check(custo == 10 and perto(eco.credits, 90.0) and pol.vigilancia_ativa(), "anoitecer: cobrou 5 cr x 2 guardas (%d cr; sobrou %d)" % [custo, int(eco.credits)])
	var sch = g("schedule")
	check(sch.de_vigia(guarda) and sch.de_vigia(w[3]), "todos os guardas de vigia (fim do rodízio)")
	check(perto(Modificadores.mult(self, "roubo"), 0.5) and migr._portao_vigiado(), "roubo/saque x0,5 e o portão protegido")
	# o saque da brecha pela metade
	var arm = g("armazens")
	arm.stock["ferro"] = 100.0
	arm._recount()
	eco.credits = 1000.0
	guarda.downed = true
	guarda.downed_gate = "tunel"
	var sc := GDScript.new()
	sc.source_code = "extends Node\nvar gate_id := \"tunel\"\nvar looted := false\n"
	sc.reload()
	var falsa: Node = sc.new()
	root.add_child(falsa)
	def.invasion_active = true  # (a brecha só abre numa invasão)
	def.raid(falsa, arm)
	def.invasion_active = false
	check(perto(float(arm.stock["ferro"]), 94.0) and perto(eco.credits, 940.0), "brecha com o armazém vigiado: levou 6 de 100 de ferro e 60 de 1000 cr (metade de 12%%) — ficou %d / %d" % [int(arm.stock["ferro"]), int(eco.credits)])
	guarda.downed = false
	guarda.downed_gate = ""
	def._raided_gates.clear()
	falsa.queue_free()
	pol._amanheceu(0)
	check(not pol.vigilancia_ativa(), "amanheceu: a próxima noite cobra de novo")
	eco.credits = 3.0
	pol._marco("anoitecer")
	check(not pol.vigilancia_ativa() and perto(eco.credits, 3.0), "sem créditos: a noite vale o padrão (não cobrou, sem dívida)")
	pol.forca("seguranca", "padrao")
	check(pol.motivo_bloqueio("seguranca", "treinamento").contains("campo de treino") or not get_nodes_in_group("campos").is_empty(), "treinamento sem campo: bloqueado")
	if get_nodes_in_group("campos").is_empty():
		def.spawn_campo(hub.global_position + Vector2(160, 60))
		await process_frame
	pol.forca("seguranca", "treinamento")
	check(pol.treinamento_ativo() and perto(pol.teto_treino(), 1.25) and perto(Modificadores.mult(self, "treino"), 1.5), "treinamento: teto 125%, treino x1,5")
	guarda.combat_skill = 1.0
	guarda.train(0.5)
	check(perto(guarda.combat_skill, 1.25), "treinou até 125%% (%.3f)" % guarda.combat_skill)
	check(perto(guarda.guard_max_hp(), 55.0) and perto(lerpf(guarda.untrained_damage_mult, 1.0, guarda.combat_skill), 1.125), "vida 55 e dano x1,125 (a fórmula de sempre)")
	check(perto(soma(pol.fatores_animo(guarda)), -6.0) and pol.fatores_animo(mineiro).is_empty(), "ânimo -6 só nos guardas")
	pol.forca("seguranca", "padrao")
	for i in 5:
		pol._process(1.0)
	check(guarda.combat_skill < 1.25 and guarda.combat_skill > 1.2, "fora do treinamento cai devagar (%.3f)" % guarda.combat_skill)
	guarda.combat_skill = 1.001
	pol._process(1.0)
	check(perto(guarda.combat_skill, 1.0), "...e para em 100%")
	guarda.combat_skill = 0.4
	guarda.train(2.0)
	check(perto(guarda.combat_skill, 1.0), "no padrão o treino continua parando em 100%")

	print("-- (F) migração")
	migr.esperando.clear()
	var i_aberta: float = migr.intervalo()
	pol.forca("migracao", "seletiva")
	check(perto(migr.intervalo(), i_aberta * 1.5, 0.5), "seletiva: intervalo x1,5")
	var camas: int = eco.free_beds()
	migr.proximo = 0.0
	await anda(0.5)
	if camas <= 0:
		check(migr.esperando.is_empty(), "seletiva sem cama livre (%d): ninguém vem" % camas)
	else:
		check(migr.esperando.size() <= camas, "seletiva: o grupo cabe nas camas (%d <= %d)" % [migr.esperando.size(), camas])
	var chegou: Array = migr.chama_grupo(1, "")
	check(not chegou.is_empty() and perto(float(chegou[0].prazo), migr.prazo_dias * g("day_night").cycle_length() * 2.0, 1.0), "seletiva: prazo no portão x2")
	var esperando_antes: int = migr.esperando.size()
	pol.forca("migracao", "fechada")
	check(migr.esperando.size() == esperando_antes, "fechar não manda embora quem espera (o cartão segue até o prazo)")
	for e in migr.esperando.duplicate():
		migr.recusa(e.w)
	await process_frame
	migr.proximo = 2.0
	await anda(3.0)
	check(migr.esperando.is_empty() and migr.proximo > 1.5, "fechada: o relógio do próximo grupo parou (%.1f s)" % migr.proximo)
	var sat: Array = migr.chama_grupo(1, "satelite")
	check(not sat.is_empty(), "fechada: o satélite (ordem do jogador) chama mesmo assim")
	for e in migr.esperando.duplicate():
		migr.recusa(e.w)
	await process_frame
	var socorro_antes: int = migr.socorro_abaixo_de
	migr.socorro_abaixo_de = 99
	migr.proximo = 0.5  # (com socorro o relógio anda mesmo fechada; sem, ficaria parado como acima)
	await anda(1.5)
	check(not migr.esperando.is_empty(), "fechada: a rede de segurança chega mesmo assim")
	migr.socorro_abaixo_de = socorro_antes
	for e in migr.esperando.duplicate():
		migr.recusa(e.w)
	pol.forca("migracao", "aberta")

	print("-- (F2) greve: as políticas que tiram ânimo caem sozinhas")
	pol.forca("jornada", "estendida")
	pol.forca("racao", "reduzida")
	pol.forca("migracao", "fechada")
	pol.espera["jornada"] = 500.0
	g("morale").strike_started.emit()
	check(pol.opcao("jornada") == "normal" and pol.opcao("racao") == "normal" and pol.opcao("migracao") == "fechada", "a greve derrubou a estendida e a reduzida (a migração, que não tira ânimo, ficou)")
	check(perto(float(pol.espera["jornada"]), 0.0), "sem espera pra escolher de novo depois da greve")
	pol.forca("migracao", "aberta")

	print("-- (G) save, save antigo e telemetria")
	pol.forca("jornada", "estendida")
	pol.forca("racao", "reduzida")
	pol.forca("seguranca", "vigilancia")
	pol.forca("migracao", "seletiva")
	pol.espera["racao"] = 123.0
	pol.racao_dias = 2
	pol.trocas = 7
	var d: Dictionary = JSON.parse_string(JSON.stringify(pol.get_save_data()))
	var sm = root.get_node("SaveManager")
	check(sm._collect().has("politicas"), "o SaveManager leva a chave 'politicas'")
	for p in pol.POLITICAS:
		pol.forca(p, pol.PADRAO[p])
	pol.load_save_data(d)
	check(pol.resumo() == "jornada=estendida racao=reduzida seguranca=vigilancia migracao=seletiva" and perto(pol.espera["racao"], 123.0) and pol.racao_dias == 2 and pol.trocas == 7, "carregou igual (%s)" % pol.resumo())
	pol.load_save_data({})
	check(pol.e_padrao() and perto(pol.espera["racao"], 0.0) and pol.racao_dias == 0 and not pol.fraqueza_ativa(), "save antigo (sem a chave): tudo no padrão, sem espera")
	pol.load_save_data({"ativa": {"racao": "farta", "jornada": 3}})
	check(pol.e_padrao(), "valor estranho no save vira o padrão")
	var wd: Dictionary = guarda.get_save_data() if guarda.has_method("get_save_data") else {}
	if not wd.is_empty():
		wd["combat_skill"] = 1.2
		guarda.load_save_data(wd)
		check(perto(guarda.combat_skill, 1.2), "o save do guarda aceita habilidade acima de 100%")
		guarda.combat_skill = 1.0
	var tel := load("res://scripts/core/telemetria.gd")
	check((tel.COLUNAS as Array).has("pol_jornada") and (tel.COLUNAS as Array).has("comida_servida_dia") and (tel.COLUNAS as Array).has("acidentes_dia"), "a telemetria tem as colunas novas")
	var telem = g("telemetria")
	if telem:
		telem.registra()
		var f := FileAccess.open(telem.arquivo, FileAccess.READ)
		var ultima := ""
		while f and not f.eof_reached():
			var l := f.get_line()
			if l != "":
				ultima = l
		check(ultima.split(",").size() == (tel.COLUNAS as Array).size(), "a linha da telemetria tem uma coluna por nome (%d x %d)" % [ultima.split(",").size(), (tel.COLUNAS as Array).size()])
	else:
		print("  (sem telemetria nesta build: a linha não foi conferida)")

	print("-- (H) a janela")
	for p in pol.POLITICAS:
		pol.forca(p, pol.PADRAO[p])
		pol.espera[p] = 0.0
	hud.open_panel("politicas")
	var pn = hud._panels["politicas"]
	await process_frame
	check(pn.visible and not pn._det_box.visible, "abre sem detalhe")
	pn._seleciona("jornada", "estendida")
	check(pn._det_box.visible and pn._det_custa.text.contains("Ânimo") and pn._det_ganha.text.contains("+15%") and not pn._btn_confirma.disabled, "clicar numa opção mostra ganha/custa e Confirmar")
	pn._confirma()
	check(pol.opcao("jornada") == "estendida" and not pn._det_box.visible, "confirmou: a política vale e o detalhe fecha")
	pn._seleciona("jornada", "reduzida")
	check(pn._btn_confirma.disabled and pn._btn_confirma.text.begins_with("Não dá:"), "na espera: o botão diz o porquê (%s)" % pn._btn_confirma.text)
	pn._seleciona("racao", "reduzida")
	check(pn._det_custa.text.contains("3 dias seguidos") and pn._det_custa.text.contains("2 dias depois") and not pn._det_custa.text.contains(".0 dias"), "os dias aparecem inteiros (%s)" % pn._det_custa.text)
	pn._seleciona("seguranca", "treinamento")
	check(pn._det_restricao.text.contains("campo de treino"), "a restrição aparece")
	check(pn.button_text().contains("estendida"), "o menu Janelas mostra o que mudou (%s)" % pn.button_text())
	hud.close_panels()

	Engine.time_scale = 1.0
	print("\nFALHAS: %d" % fails)
	quit()
