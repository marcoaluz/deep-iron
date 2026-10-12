extends SceneTree
## Bloco 128: TRÊS CORREÇÕES DE INTERFACE. RODAR SÓ COM APPDATA ISOLADO.
##   (A) cada prédio abre a SUA janela (Arsenal, Campo de treino, Taverna) e a da Defesa (G) é a visão geral; nenhuma janela de
##       prédio tem "escolher lugar" (construir é só no menu CONSTRUIR, e cada item tem cartão com imagem); o muro/portão
##       (melhoria) também está no CONSTRUIR;
##   (B) a roda do mouse sobre qualquer janela/menu da interface não dá zoom no mapa (e sobre o mapa dá);
##   (C) os REQUISITOS DA FUNÇÃO: lista em dados (data/funcoes), cartão ✓/✗ ao dar a função, o cartão do selecionado, a dica do
##       botão, o texto do balão (motivo_texto) e a fala do capataz do primeiro dia.
var main: Node
var hud: Node
var def: Node
var fails := 0
const Req := preload("res://scripts/core/requisitos_funcao.gd")


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
	load("res://scripts/core/defense.gd").moradores_desligados = true
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Todos os textos dos botões de uma janela (recursivo).
func _botoes(n: Node, out: Array = []) -> Array:
	if n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_botoes(c, out)
	return out


func _poe(cena: String, pos: Vector2) -> Node:
	var no: Node2D = load(cena).instantiate()
	g("village_hub").get_parent().add_child(no)
	no.global_position = pos
	return no


func _roda() -> void:
	await _frames(5)
	hud = g("hud")
	def = g("defense")
	g("eventos").ligado = false
	g("pedidos").ligado = false
	var hub := g("village_hub")
	var menu = hud._build_menu

	print("== (A) cada prédio abre a SUA janela")
	var ars := _poe("res://scenes/props/arsenal.tscn", hub.global_position + Vector2(-200, -90))
	var campo := _poe("res://scenes/props/campo_treino.tscn", hub.global_position + Vector2(-260, 90))
	var tav := _poe("res://scenes/props/taverna.tscn", hub.global_position + Vector2(130, -170))
	await _frames(3)
	check(ars.panel_id == "arsenal" and campo.panel_id == "campo" and tav.panel_id == "taverna", "panel_id: arsenal / campo / taverna (não mais defesa/defesa/moral)")
	var gate := g("barricadas")
	check(String(gate.panel_id) == "defesa", "o portão segue abrindo a janela da Defesa (visão geral)")
	for id in ["arsenal", "campo", "taverna", "defesa", "moral"]:
		check(hud._panels.has(id), "janela '%s' registrada" % id)
	hud.open_panel_for(ars)
	check(hud._panels["arsenal"].visible and not hud._panels["defesa"].visible, "clicar no Arsenal abre a janela do Arsenal")
	hud.open_panel_for(campo)
	check(hud._panels["campo"].visible and not hud._panels["defesa"].visible and not hud._panels["arsenal"].visible, "clicar no campo abre a janela do campo")
	hud.open_panel_for(tav)
	check(hud._panels["taverna"].visible and not hud._panels["moral"].visible, "clicar na taverna abre a janela da taverna (não a de Bem-estar)")
	hud.open_panel_for(gate)
	check(hud._panels["defesa"].visible, "clicar no portão abre a Defesa")
	var pd = hud._panels["defesa"]
	check(pd.get("_weapon_rows") == null and pd.get("_campo_button") == null and pd.get("_arsenal_button") == null,
		"a Defesa não tem mais forja, armas nem botões de construir")
	pd.refresh()
	check(pd._links.visible and pd._arsenal_link.visible and pd._campo_link.visible, "a Defesa só aponta (atalhos) pro Arsenal e pro campo")

	print("== o Arsenal: forja, cavalete e armas")
	var gs: Array = get_nodes_in_group("ipezinhos")
	hud.open_panel("arsenal", ars)
	var pa = hud._panels["arsenal"]
	pa.refresh()
	check(pa._weapon_rows.size() >= 2 and not pa._weapon_rows.has("porrete"), "o Arsenal lista as armas pra forjar (menos o porrete)")
	check(pa._cavalete.text.find("cavalete") >= 0 or pa._cavalete.text.find("Cavalete") >= 0, "mostra o cavalete (%s)" % pa._cavalete.text)
	check(pa._status_forja.text != "", "mostra a forja")

	print("== o Campo de treino: guardas em treino e %% de treino")
	var g1: Node = gs[0]
	var g2: Node = gs[1]
	g1.set_job("guarda")
	g2.set_job("guarda")
	g1.combat_skill = 0.5
	g2.combat_skill = 0.0
	hud.open_panel("campo", campo)
	var pc = hud._panels["campo"]
	pc.refresh()
	var linhas_guardas: Array = []
	for c in pc._lista.get_children():
		if c is Label:
			linhas_guardas.append((c as Label).text)
	check(linhas_guardas.size() == def.guards().size() and linhas_guardas.size() >= 2, "uma linha por guarda (%d)" % linhas_guardas.size())
	check(linhas_guardas.any(func(t): return "50% de treino" in t), "mostra a % de treino do guarda (%s)" % str(linhas_guardas))
	check(pc._resumo.text.find("treinando") >= 0, "resumo: quantos treinando (%s)" % pc._resumo.text)

	print("== a Taverna: frequentadores e ânimo")
	hud.open_panel("taverna", tav)
	var pt = hud._panels["taverna"]
	tav.set_inside(g1, true)
	pt.refresh()
	var freq: Array = pt._lista.get_children().filter(func(c): return c is Label and (c as Label).text.find("ânimo") >= 0)
	check(freq.size() == 1, "lista o frequentador com o ânimo (%d linha)" % freq.size())
	check(pt._resumo.text.find("1 de") >= 0 and pt._bonus.text.find("Ânimo da vila") >= 0, "resumo: lugares ocupados e ânimo da vila")
	tav.set_inside(g1, false)

	print("== nenhuma janela de prédio escolhe lugar (construir é só no CONSTRUIR)")
	hud.close_panels()
	var ruins := 0
	for id in hud._panels.keys():
		hud.open_panel(id)
		hud._panels[id].refresh()
		for t in _botoes(hud._panels[id]):
			if "escolher lugar" in t.to_lower() or "escolher o lugar" in t.to_lower() or "marcar o lugar" in t.to_lower():
				ruins += 1
				print("    ", id, ": ", t)
	hud.close_panels()
	check(ruins == 0, "nenhum botão 'escolher lugar' nas janelas (%d achados)" % ruins)
	for id in ["hub", "enfermaria", "lab", "oficina", "calendario", "moral", "sun", "coletor", "coletor_minerio"]:
		if not hud._panels.has(id):
			continue
		var pn = hud._panels[id]
		check(not _botoes(pn).any(func(t): return String(t).begins_with("Construir ") and "(" in String(t) and " cr" in String(t)),
			"janela '%s' não tem botão de construir com custo" % id)

	print("== o CONSTRUIR tem cartão (com imagem) pra tudo que antes só se construía por janela")
	var por_nome := {}
	for tab in menu.TAB_NAMES:
		for d in menu._defs(tab):
			por_nome[String(d.name)] = d
	var fx = hub.coletor_fixo()
	if fx and not fx.restaurado():
		fx.restaura_tudo()
		por_nome.clear()
		for tab in menu.TAB_NAMES:
			for d in menu._defs(tab):
				por_nome[String(d.name)] = d
	var esperados := ["Casa (Moradias)", "Cozinha", "Horta", "Estufa", "Nova enfermaria", "Taverna", "Ampliar taverna", "Parque", "Laboratório",
		"Arsenal", "Campo de treino", "Vestiário", "Muro e portão", "Fornalha", "Carpintaria", "Carvoaria", "Curtume", "Coletor de minério",
		"Coletor de madeira", "Armazém novo", "Escudo solar", "Cemitério", "Escola"]
	for nome in esperados:
		var d: Dictionary = por_nome.get(nome, {})
		var tem_img: bool = not d.is_empty() and ResourceLoader.exists(String(d.get("img", "")))
		check(not d.is_empty() and tem_img, "cartão '%s' no CONSTRUIR, com imagem" % nome)
	check(por_nome.has("Igreja") and por_nome.has("Oficina (forja)"), "Igreja e Oficina também têm cartão")
	var cm: Dictionary = por_nome.get("Muro e portão", {})
	check(not cm.is_empty() and String(cm.reason.call()) == String(gate.upgrade_block_reason()), "o cartão do muro/portão usa o motivo do próprio portão ('%s')" % (cm.reason.call() if not cm.is_empty() else "-"))
	hud.abre_construir("Defesa e equipamento")
	check(menu.visible and menu.TAB_NAMES[menu._tab] == "Defesa e equipamento", "abre_construir(aba): o menu abre na aba pedida")
	hud.close_panels()

	print("== (B) a roda do mouse não dá zoom sobre a interface")
	var cam = main.get_node("Camera2D")
	cam.crisp_zoom = false  # (zoom livre: em headless as paradas nítidas não deixam o zoom andar nem dos lados)
	cam.zoom_max = 40.0
	cam._target_zoom = 5.0
	var vis := root.get_visible_rect().size
	hud.close_panels()
	await _frames(2)
	var livre := Vector2(vis.x * 0.5, vis.y * 0.42)
	await _mouse(livre)
	var z0: float = cam._target_zoom
	_roda_mouse(livre, true)
	await _frames(2)
	check(not is_equal_approx(cam._target_zoom, z0), "sobre o mapa a roda dá zoom (%.2f -> %.2f)" % [z0, cam._target_zoom])
	cam._target_zoom = z0
	var ids_roda := ["armazem", "defesa", "arsenal", "campo", "taverna", "moral", "catalogo", "lab", "hub", "enfermaria", "oficina", "missoes"]
	var testados := 0
	for id in ids_roda:
		if not hud._panels.has(id):
			continue
		hud.open_panel(id)
		await _frames(3)
		var p: Control = hud._panels[id]
		var onde := p.get_global_rect().get_center()
		await _mouse(onde)
		var antes: float = cam._target_zoom
		_roda_mouse(onde, true)
		_roda_mouse(onde, false)
		await _frames(2)
		testados += 1
		check(is_equal_approx(cam._target_zoom, antes), "roda sobre a janela '%s' não muda o zoom (%.2f)" % [id, cam._target_zoom])
		hud.close_panels()
	check(testados >= 8, "testou %d janelas" % testados)
	# o menu CONSTRUIR
	hud.toggle_build_menu()
	await _frames(3)
	var onde_m: Vector2 = menu.get_global_rect().get_center()
	await _mouse(onde_m)
	var antes_m: float = cam._target_zoom
	_roda_mouse(onde_m, true)
	_roda_mouse(onde_m, false)
	await _frames(2)
	check(is_equal_approx(cam._target_zoom, antes_m), "roda sobre o CONSTRUIR não muda o zoom")
	hud.close_panels()
	# a gaveta de pessoas
	hud._abre_gaveta(false)
	await _frames(3)
	await _frames(4)
	var rg: Rect2 = hud._left_panel.get_global_rect()  # (a altura muda quando a lista monta: um ponto perto do topo)
	var onde_g := Vector2(rg.position.x + 40.0, rg.position.y + 24.0)
	await _mouse(onde_g)
	var antes_g: float = cam._target_zoom
	_roda_mouse(onde_g, true)
	await _frames(2)
	check(is_equal_approx(cam._target_zoom, antes_g), "roda sobre a lista de pessoas não muda o zoom")
	hud.close_panels()
	# uma janela modal aberta (mesmo com o mouse no mapa)
	await _mouse(livre)
	var modal := CanvasLayer.new()
	modal.add_to_group("janela_modal")
	root.add_child(modal)
	check(cam.roda_e_da_interface(), "com uma janela modal aberta, a roda é da interface")
	var antes_modal: float = cam._target_zoom
	_roda_mouse(livre, true)
	await _frames(2)
	check(is_equal_approx(cam._target_zoom, antes_modal), "com modal aberta a roda não dá zoom no mapa")
	modal.queue_free()
	await _frames(2)
	check(not cam.roda_e_da_interface(), "fechada a modal, a roda volta ao mapa")

	print("== (C) requisitos da função")
	Req.carrega(true)
	var funcoes := ["minerador", "lenhador", "caçador", "agricultor", "cozinheiro", "fundidor", "ferreiro", "carpinteiro", "engenheiro",
		"carregador", "mecânico", "médico", "pesquisador", "padre", "batedor", "guarda"]
	var sem_texto: Array[String] = []
	for f in funcoes:
		if not Req.tem(f) or Req.resumo(f) == "":
			sem_texto.append(f + " (função/resumo)")
			continue
		for rid in Req.ids(f):
			if Req.texto(f, rid + ".ok") == "" or Req.texto(f, rid + ".falta") == "":
				sem_texto.append("%s.%s" % [f, rid])
	check(sem_texto.is_empty(), "as 16 funções têm requisitos e textos ok/falta em dados (%s)" % str(sem_texto))
	for f in hud.ORDER_JOBS:
		check(Req.tem(String(f[0])), "ORDER_JOBS '%s' tem requisitos" % f[0])
	var travou: Array[String] = []
	for f in funcoes:
		var av1 := Req.avalia(self, f, null)
		var av2 := Req.avalia(self, f, gs[2])
		if av1.itens.is_empty() or av2.itens.is_empty() or Req.linhas(av1).is_empty():
			travou.append(f)
	check(travou.is_empty(), "avalia() devolve a lista (com e sem ipezinho) pra todas (%s)" % str(travou))

	print("  -- o caçador do relato: sem arco, sem toca estudada e sem horta")
	var ofi := g("oficina")
	ofi.crafted["arco"] = false
	for n in get_nodes_in_group("coleta_comida"):
		n.remove_from_group("coleta_comida")
	for n in get_nodes_in_group("caca"):
		n.remove_from_group("caca")
	var cac: Node = gs[gs.size() - 1]
	cac.set_job("caçador")
	cac._ai_state = "idle"
	var av := Req.avalia(self, "caçador", cac)
	var txt := "\n".join(Req.linhas(av))
	print(txt)
	check(not av.pode, "sem arco, sem toca e sem horta: o caçador NÃO tem trabalho")
	check("✗ Falta o arco: a Oficina faz" in txt, "✗ Falta o arco: a Oficina faz")
	check(txt.find("✗ Nenhuma toca na clareira") >= 0 or txt.find("✗ Nenhuma toca estudada: o pesquisador precisa catalogar") >= 0, "✗ toca (estudada) falta")
	check("✗ Construa a horta: CONSTRUIR > Alimentação" in txt, "✗ Construa a horta: CONSTRUIR > Alimentação")
	check(String(av.primeiro).begins_with("Falta o arco"), "o motivo específico é o primeiro que falta (%s)" % av.primeiro)
	ofi.crafted["arco"] = true
	var av_ok := Req.avalia(self, "caçador", cac)
	check("✓ Tem arco" in "\n".join(Req.linhas(av_ok)), "com o arco fabricado o ✗ vira ✓")
	ofi.crafted["arco"] = false

	print("  -- o cartão ao dar a função")
	main.selection.clear()
	main.selection.append(cac)
	cac.set_job("ocioso")
	main.toggle_hunter()
	await _frames(2)
	var carta = hud._req_card
	check(carta.visible and carta.job == "caçador", "dar a função abre o cartão de requisitos")
	var lt: Array = carta.linhas_texto()
	check(lt.size() == 3 and String(lt[0]).begins_with("✗"), "o cartão lista os 3 requisitos com ✓/✗ (%s)" % str(lt))
	check(carta.situacao().find("Sem trabalho") >= 0, "e diz que está sem trabalho")
	ofi.crafted["arco"] = true
	carta._t_confere = 9.0
	carta._process(0.1)
	check(String(carta.linhas_texto()[0]).begins_with("✓"), "o cartão confere de novo: resolveu o arco, o ✗ vira ✓")
	ofi.crafted["arco"] = false
	carta.visible = false
	main.toggle_miner()
	check(hud._req_card.visible and hud._req_card.job == "minerador", "outra função: o cartão dela")
	hud._req_card.visible = false

	print("  -- o cartão do selecionado e a dica do botão")
	cac.set_job("caçador")
	main.selection.clear()
	main.selection.append(cac)
	hud._update_portrait([cac])
	check(hud._portrait_req.visible and hud._portrait_req.text.find("✗") >= 0, "o cartão do selecionado mostra os ✗ (%s)" % hud._portrait_req.text.replace("\n", " | "))
	hud._job_buttons["caçador"].button.mouse_entered.emit()  # (Bloco 135: a dica é montada quando o mouse chega no botão)
	var tip: String = hud._job_buttons["caçador"].button.tooltip_text
	check(tip.find("O que ela precisa") >= 0 and tip.find("✗ Falta o arco") >= 0, "a dica do botão do caçador lista os requisitos")

	print("  -- o texto do balão (motivo_parado)")
	var dn := g("day_night")
	dn.time = 40.0  # de dia
	cac._ai_state = "idle"
	var motivo := String(cac.motivo_texto())
	print("  motivo_parado=", cac.motivo_parado(), " texto=", motivo)
	check(motivo != "" and motivo != "Sem função: dê uma na barra de baixo", "o texto do balão não é o genérico (%s)" % motivo)
	check(motivo.find("arco") >= 0 or motivo.find("toca") >= 0 or motivo.find("horta") >= 0, "ele diz o que falta (arco/toca/horta)")
	# o balão com o texto, aparecendo quando selecionado
	cac.set_selected(true)
	cac.sem_baloes = false
	cac.baloes_motivo = true
	cac._baloes_lido = true
	for i in 8:  # (o balão espera 2 s parado pelo mesmo motivo; a conferência é a cada meio segundo)
		cac._motivo_cd = 0.0
		cac._motivo_tick(0.5)
	var bal := cac.get_node_or_null("BalaoMotivo")
	check(bal != null and bal.get_node_or_null("Texto") != null, "o balão de motivo tem o texto")
	cac.set_selected(false)

	print("  -- o capataz do primeiro dia")
	var guia := g("guia")
	if guia:
		var dica: String = guia._dica_requisito(["caçador"])
		check(dica.begins_with("Atenção, caçador sem trabalho.") and dica.find("arco") >= 0, "o guia diz o que falta ao caçador (%s)" % dica)
		cac.set_job("ocioso")
		check(guia._dica_requisito(["caçador"]) == "", "sem ninguém na função, o guia não fala")
	else:
		check(false, "nó do guia")

	print("  -- o fundidor: Fornalha pronta e nenhuma ordem")
	var forn := _poe("res://scenes/props/fornalha.tscn", hub.global_position + Vector2(200, 120))
	await _frames(2)
	var av_f := Req.avalia(self, "fundidor", null)
	var txt_f := "
".join(Req.linhas(av_f))
	check("✓ A Fornalha está pronta" in txt_f and "✗ Nenhuma ordem: clique na Fornalha e encomende" in txt_f, "fundidor: Fornalha ✓, sem ordem ✗ (%s)" % txt_f.replace("
", " | "))
	check(not av_f.pode, "fundidor sem ordem não tem trabalho")
	forn.queue_free()
	var av_m := Req.avalia(self, "minerador", gs[0])
	check(av_m.itens.size() == 2 and String(av_m.itens[0].texto).find("jazida") >= 0, "minerador: jazida e espaço no armazém (%s)" % str(Req.linhas(av_m)))

	print("  -- os demais (um por função: falta e passa)")
	# engenheiro sem obra; fundidor sem fornalha ordenada; médico com a enfermaria
	check(not Req.avalia(self, "engenheiro", null).pode or not get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending()).is_empty(),
		"engenheiro: sem obra pendente não tem trabalho")
	var av_med := Req.avalia(self, "médico", null)
	check(av_med.pode == not get_nodes_in_group("enfermarias").is_empty(), "médico: pode se tem enfermaria")
	var av_g := Req.avalia(self, "guarda", null)
	check(av_g.itens.size() == 3, "guarda: muro, Arsenal e campo")
	var av_p := Req.avalia(self, "padre", null)
	check(String(av_p.itens[0].texto).begins_with("Construa a Igreja") == (get_nodes_in_group("igrejas").is_empty()), "padre: a igreja")

	Engine.time_scale = 1.0
	print("FALHAS: %d" % fails)
	quit()


## Põe o mouse (motion) num ponto (coordenadas da tela do jogo) e deixa a interface processar. Em headless a janela é 64x64
## e o jogo é esticado: o evento entra em pixels da JANELA (a tela do jogo vezes a transformação final).
func _mouse(p: Vector2) -> void:
	var q: Vector2 = root.get_final_transform() * p
	var ev := InputEventMouseMotion.new()
	ev.position = q
	ev.global_position = q
	Input.parse_input_event(ev)
	await process_frame
	await process_frame


func _roda_mouse(p: Vector2, pra_cima: bool) -> void:
	var q: Vector2 = root.get_final_transform() * p
	var ev := InputEventMouseButton.new()
	ev.position = q
	ev.global_position = q
	ev.button_index = MOUSE_BUTTON_WHEEL_UP if pra_cima else MOUSE_BUTTON_WHEEL_DOWN
	ev.pressed = true
	Input.parse_input_event(ev)
	var solta := InputEventMouseButton.new()
	solta.position = q
	solta.global_position = q
	solta.button_index = ev.button_index
	solta.pressed = false
	Input.parse_input_event(solta)
