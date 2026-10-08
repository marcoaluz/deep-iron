extends SceneTree
## Bloco 101: MIGRANTES E POPULAÇÃO INICIAL. (A) Acabou o "Recrutar" (a tecla R, os botões, o custo, a ajuda). (B) A
## partida nova começa com 10 (5 homens e 5 mulheres, sem função) e os recursos da Fundação dão pras 3 casas e a cozinha;
## a cozinha começa com 240 de comida (cabe 300). (C) A capacidade da vila são as camas. (D) Migrantes: um grupo vem pela
## floresta e espera do lado de fora do portão, com o alerta e o cartão (retrato, nome, sexo, condição, função desejada —
## nunca padre); Aceitar com cama (entra, sem função; ferido vai pra enfermaria), sem cama (desabilitado: "falta cama"),
## Recusar, o prazo, o ataque à noite. (E) A frequência pela atratividade e a rede de segurança; o satélite chama
## migrantes. (F) Save e save antigo. RODAR SÓ COM APPDATA ISOLADO.
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
	if Time.get_ticks_msec() - _t0 > 300000:
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
	var eco = g("economy")
	var hud = g("hud")
	var hub = g("village_hub")
	var mig = g("migrantes")
	var gate = g("barricadas")
	mig.proximo = 1.0e9  # (o relógio de verdade não atrapalha: os grupos aqui são chamados à mão)

	print("== A) acabou o 'Recrutar'")
	check(not eco.has_method("recruit") and not eco.has_method("recruit_cost") and not eco.has_method("recruit_block_reason"), "a economia não compra ipezinho")
	check(Teclas.acao(KEY_R) != "recrutar" and not Teclas.PADRAO.has("recrutar"), "a tecla R não recruta mais (a ação saiu)")
	check(hud.get("_recruit_button") == null and hud._panels.hub.get("_recruit_button") == null, "sem botão de recrutar (HUD e Centro da Vila)")
	check(not FileAccess.get_file_as_string("res://scripts/core/hud.gd").contains("recrutar\" % ["), "a ajuda de atalhos não fala mais em recrutar")

	print("== B) a partida nova: 10 ipezinhos, 5 e 5, sem função; a Fundação dá pras casas e a cozinha")
	var fund = g("founding")
	check(fund != null and fund.populacao_inicial == 10, "a Fundação começa com 10")
	fund.completa_populacao()
	var ws := get_nodes_in_group("ipezinhos")
	var homens := ws.filter(func(w): return w.gender == "menino").size()
	check(ws.size() == 10, "10 ipezinhos (%d)" % ws.size())
	check(homens == 5 and ws.size() - homens == 5 or (homens > 5 and get_nodes_in_group("ipezinhos").size() == 10), "5 homens e 5 mulheres (%d / %d; os da cena já vêm sorteados)" % [homens, ws.size() - homens])
	check(ws.all(func(w): return w.job == "ocioso"), "todos sem função")
	var nomes := {}
	for w in ws:
		nomes[w.display_name] = true
	check(nomes.size() >= 8, "nomes sorteados (%d diferentes)" % nomes.size())
	var casa_c: Vector3i = hub.starter_house_cost
	var coz: Vector3i = hub.comedouro_cost
	check(hub.founding_credits >= 3 * casa_c.x + coz.x and hub.founding_ore >= 3 * casa_c.y + coz.y and hub.founding_wood >= 3 * casa_c.z + coz.z,
		"os recursos da Fundação pagam as 3 casas e a cozinha (%d cr, %d ferro, %d madeira)" % [hub.founding_credits, hub.founding_ore, hub.founding_wood])
	var camas_ini: int = hub.starter_houses * load("res://scenes/props/casa.tscn").instantiate().beds_by_level[0]
	check(camas_ini >= 10, "as 3 casas iniciais dão %d camas (cabem os 10)" % camas_ini)
	var comed: Node = load("res://scenes/props/comedouro.tscn").instantiate()
	check(comed.start_food == 240.0 and comed.food_capacity == 300.0, "a cozinha começa com 240 de comida e cabe 300")
	comed.free()

	print("== C) a capacidade da vila são as camas")
	hud._refresh()
	check(hud._workers_count_label.text == "%d / %d camas" % [eco.worker_count(), eco.worker_count() + eco.free_beds()], "o HUD: '%s'" % hud._workers_count_label.text)
	# camas livres pro resto do teste
	for c in get_nodes_in_group("casas"):
		c.built = true
	while eco.free_beds() < 4:
		var casa_nova: Node2D = load("res://scenes/props/casa.tscn").instantiate()
		casa_nova.placed_by_player = true
		hub.get_parent().add_child(casa_nova)
		casa_nova.global_position = hub.global_position + Vector2(300 + randf() * 80, 200)
	check(eco.free_beds() >= 4, "camas livres pra receber migrantes (%d)" % eco.free_beds())

	print("== D) um grupo chega e espera no portão")
	Engine.time_scale = 3.0
	var grupo: Array = mig.chama_grupo(3)
	check(grupo.size() == 3 and mig.esperando.size() == 3, "3 migrantes chamados")
	var vis: Array = grupo.map(func(e): return e.w)
	check(vis.all(func(w): return w.visitante and w.is_in_group("migrantes_gente") and not w.is_in_group("ipezinhos")), "são visitantes: fora do grupo da vila (não comem, não contam)")
	check(eco.worker_count() == 10, "a população não mudou (%d)" % eco.worker_count())
	var chegaram := await _ate(func(): return vis.all(func(w): return is_instance_valid(w) and w.global_position.distance_to(gate.global_position) < 90.0), 60.0)
	check(chegaram and vis.all(func(w): return gate.lado_de(w.global_position) == -1), "andaram pela floresta até o portão e esperam do lado de fora")
	hud._refresh()
	check(hud._alertas.ativos().has("migrantes"), "o alerta 'migrantes' na coluna")
	var jan = hud._panels.migrantes
	check(jan.visible, "a janela 'Migrantes' abriu sozinha")
	jan.refresh()
	check(jan._lista.get_child_count() == 3, "um cartão por migrante (%d)" % jan._lista.get_child_count())
	check(mig.esperando.all(func(e): return e.funcao != "padre" and e.condicao in mig.CONDICOES), "cada um tem condição e uma função desejada (nunca padre)")
	var c0: Control = jan._lista.get_child(0)
	var textos: Array = []
	for n in c0.find_children("*", "Label", true, false):
		textos.append(n.text)
	var junto := " | ".join(textos)
	check(("homem" in junto or "mulher" in junto) and "Condição:" in junto and "Gostaria de ser:" in junto and c0.find_children("*", "TextureRect", true, false).size() >= 1,
		"o cartão: retrato, nome, sexo, condição e função ('%s')" % junto.left(120))

	print("== D2) aceitar com cama: entra, sem função; o ferido vai pra enfermaria")
	mig.esperando[0].condicao = "ferido"
	mig.esperando[1].condicao = "saudavel"
	var ferido: Node = mig.esperando[0].w
	var sao: Node = mig.esperando[1].w
	check(mig.motivo_aceitar(ferido) == "" and mig.aceita(ferido), "aceitou o ferido (tinha cama)")
	check(ferido.is_in_group("ipezinhos") and not ferido.visitante and ferido.job == "ocioso" and ferido.injured, "virou morador, sem função, ferido")
	check(mig.aceita(sao) and sao.is_in_group("ipezinhos") and eco.worker_count() == 12, "aceitou o outro (agora são %d)" % eco.worker_count())
	var entrou := await _ate(func(): return gate.lado_de(sao.global_position) == 1, 60.0)
	check(entrou, "o aceito passou pelo portão pra dentro da vila")
	var foi := await _ate(func(): return ferido.get_state() == "infirmary", 20.0)
	check(foi, "o ferido aceito vai pra enfermaria (%s)" % ferido.get_state())

	print("== D3) sem cama: o botão fica desabilitado com a dica 'falta cama'")
	var terceiro: Node = mig.esperando[0].w
	var guard := 0
	while eco.free_beds() > 0 and guard < 30:
		eco.novo_ipezinho()
		guard += 1
	check(mig.motivo_aceitar(terceiro) == "falta cama" and not mig.aceita(terceiro), "sem cama: não aceita ('%s')" % mig.motivo_aceitar(terceiro))
	hud.open_panel("migrantes")
	jan.refresh()
	await process_frame  # (os cartões velhos saem no fim do quadro)
	var bt: Button = jan._lista.get_child(0).find_child("Aceitar", true, false)
	check(bt != null and bt.disabled and bt.tooltip_text == "falta cama", "o botão Aceitar desabilitado com a dica 'falta cama'")
	print("== D4) recusar e o prazo")
	mig.recusa(terceiro)
	check(mig.esperando.is_empty() and is_instance_valid(terceiro), "recusado: sai da espera e volta pra floresta")
	var g2: Array = mig.chama_grupo(1)
	g2[0].prazo = 1.5
	var expirou := await _ate(func(): return mig.esperando.is_empty(), 10.0)
	check(expirou, "sem resposta no prazo: foi embora")

	print("== D5) à noite, esperando, pode ser atacado")
	var g3: Array = mig.chama_grupo(1)
	var alvo: Dictionary = g3[0]
	alvo.condicao = "saudavel"
	var dn = g("day_night")
	dn._pula_para(dn.tempo_da_hora(22.0))
	var bicho: Node2D = load("res://scenes/creatures/lumivoro.tscn").instantiate()
	hub.get_parent().add_child(bicho)
	bicho.global_position = gate.global_position + Vector2(-400, 0)
	bicho.set_process(false)
	mig.risco_ataque_hora = 1.0
	mig._hora_t = 999.0
	mig._confere(0.0)
	check(alvo.condicao == "ferido", "atacado de noite no portão: ferido")
	mig._hora_t = 999.0
	var w_alvo: Node = alvo.w
	mig._confere(0.0)
	check(not mig.esperando.has(alvo), "atacado de novo (já ferido): não resistiu")
	bicho.queue_free()
	mig.risco_ataque_hora = 0.08
	dn._pula_para(dn.tempo_da_hora(10.0))

	print("== E) a frequência: atratividade e rede de segurança; o satélite")
	hub.level = 1
	for c in get_nodes_in_group("comedouros"):
		c.food_stock = 0.0
	var i_ruim: float = mig.intervalo()
	hub.level = 5
	for c in get_nodes_in_group("comedouros"):
		c.food_stock = c.food_capacity
	var i_bom: float = mig.intervalo()
	check(mig.atratividade() > 0.0 and mig.atratividade() <= 1.0 and i_bom < i_ruim, "vila mais atraente = grupos mais seguidos (%.1f dias contra %.1f)" % [i_bom / dn.cycle_length(), i_ruim / dn.cycle_length()])
	check(i_bom >= mig.intervalo_min_dias * dn.cycle_length() - 0.1, "com intervalo mínimo (%.1f dia)" % mig.intervalo_min_dias)
	check(mig.partes_atratividade().size() == 6, "conta estágio, comida, ânimo, camas, beleza e missões")
	# a rede de segurança: a vila quase vazia chama ajuda logo
	var todos := get_nodes_in_group("ipezinhos")
	for k in range(todos.size() - 2):
		todos[k].remove_from_group("ipezinhos")  # (de mentira: só pra contar menos de 4)
	mig.esperando.clear()
	mig.socorro_dias = 0.02  # (meio dia de jogo no jogo; aqui, pra não esperar)
	mig.proximo = 50.0 * dn.cycle_length()
	await _espera(0.2)
	var socorro := await _ate(func(): return not mig.esperando.is_empty(), 25.0)
	check(socorro and mig.esperando.size() >= 2, "com menos de %d ipezinhos chega ajuda logo (%d vieram)" % [mig.socorro_abaixo_de, mig.esperando.size()])
	for k in range(todos.size() - 2):
		if is_instance_valid(todos[k]):
			todos[k].add_to_group("ipezinhos")
	for e in mig.esperando.duplicate():
		mig.recusa(e.w)
	mig.proximo = 1.0e9
	# o padre nunca vem
	var funcoes := {}
	for k in 60:
		funcoes[mig.FUNCOES[randi() % mig.FUNCOES.size()]] = true
	check(not mig.FUNCOES.has("padre") and not funcoes.has("padre"), "o migrante nunca vem como padre")
	# o satélite
	var res = g("research")
	if not res.done.has("satelite"):
		res.done.append("satelite")
	res._on_day_started(res.satellite_days())
	check(not mig.esperando.is_empty(), "o satélite chamou um grupo de migrantes (%d)" % mig.esperando.size())
	Engine.time_scale = 1.0

	print("== F) save e save antigo")
	var nomes_esp: Array = mig.esperando.map(func(e): return e.w.display_name)
	var d: Dictionary = mig.get_save_data()
	mig.load_save_data(d)
	await process_frame
	await process_frame
	check(mig.esperando.size() == nomes_esp.size() and mig.esperando.map(func(e): return e.w.display_name) == nomes_esp, "salvou e carregou quem espera no portão (%s)" % [nomes_esp])
	check(mig.esperando.all(func(e): return e.w.visitante and not e.w.is_in_group("ipezinhos")), "voltam como visitantes")
	mig.load_save_data({})
	check(mig.esperando.is_empty() and mig.proximo > 0.0, "save antigo (sem a chave): ninguém esperando, o primeiro grupo no prazo normal")
	var ec := {"credits": 500.0, "recruited_count": 4, "max_workers": 16}
	eco.load_save_data(ec)
	check(is_equal_approx(eco.credits, 500.0), "a economia do save antigo (com recruited_count e max_workers) carrega")

	print("\nFALHAS: %d" % fails)
	quit()
