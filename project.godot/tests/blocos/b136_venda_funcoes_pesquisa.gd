extends SceneTree
## Bloco 136: TRÊS JANELAS NOVAS. RODAR SÓ COM APPDATA ISOLADO.
##   (1) VENDER NO ARMAZÉM: o "Vender…" (e o botão da categoria) abre a caixa de venda; nada vende sem Confirmar; a
##       quantidade (−/+/máx/digitar) mostra o valor; Vender tudo; Cancelar e Esc não vendem; o aviso do "auto";
##   (2) FUNÇÕES: o botão da função sem ninguém selecionado abre a lista de quem tem e de quem não tem; dar, tirar e
##       trocar (menu com ✓/✗) sem selecionar no mapa; a contagem do botão muda na hora; com seleção, segue dando;
##   (3) PESQUISADOR: a ficha mostra o que pesquisa agora (%, tempo), a fila e o que dá pra mandar estudar (o corpo da
##       criatura "pronta para estudar"); nada começa sozinho; fila e cancelar (devolve); ao concluir, o "por que veio";
##       o save da fila (e o save antigo sem ela).
var fails := 0
var main: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	load("res://scripts/props/armazem.gd").limite_desligado = true  # (o teste enche o armazém pra vender)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
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


func _roda() -> void:
	await _frames(2)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	await _frames(8)
	var eco := g("economy")
	eco.credits = 9999.0
	for i in 6:
		eco.novo_ipezinho("menina" if i % 2 == 0 else "menino")
	await _frames(4)
	await _venda()
	await _funcoes()
	await _pesquisa()
	print("FALHAS: %d" % fails)
	quit()


# ------------------------------------------------------------ (1) a caixa de venda
func _venda() -> void:
	print("== (1) vender no armazém: a caixa de venda")
	var hud := g("hud")
	var eco := g("economy")
	var arm: Node2D = get_nodes_in_group("armazens")[0]
	eco.auto_sell = false
	arm.stock["ferro"] = 30.0
	arm._recount()
	eco.add_item("barra_cobre", 4.0, arm.global_position)
	hud.open_panel("armazem")
	var p = hud._panels["armazem"]
	p.refresh()
	await _frames(2)
	var cx: Control = p._caixa
	var c0: float = eco.credits
	var tem: int = int(floorf(eco.quantidade("ferro")))
	p._rows["ferro"].button.pressed.emit()
	await _frames(2)
	check(cx.visible and cx.id == "ferro" and eco.credits == c0 and int(floorf(eco.quantidade("ferro"))) == tem,
		"\"Vender…\" abre a caixa e NÃO vende (créditos e ferro iguais)")
	check(String(cx._titulo.text) == "Ferro" and ("tem %d" % tem) in String(cx._info.text) and "cr cada" in String(cx._info.text) and cx._icone.texture != null,
		"\"Você está vendendo: [ícone] Ferro — tem %d, X cr cada\" (%s)" % [tem, cx._info.text])
	check(cx.qtd == tem and ("%d" % tem) in String(cx._tudo.text) and ("+%d cr" % int(tem * eco.price_of("ferro"))) in String(cx._tudo.text),
		"começa em tudo; o \"Vender tudo\" mostra o total (%s)" % cx._tudo.text)
	cx._campo.value = 5
	check(cx.qtd == 5 and ("= %d cr" % int(5 * eco.price_of("ferro"))) in String(cx._total.text), "digitar 5: o valor em créditos (%s)" % cx._total.text)
	cx._define(cx.qtd - 1)
	check(cx.qtd == 4, "o − tira um")
	cx._max.pressed.emit()
	check(cx.qtd == tem, "o \"máx\" volta pra tudo")
	cx._define(9999)
	check(cx.qtd == tem, "não passa do que tem")
	cx._cancelar.pressed.emit()
	check(not cx.visible and eco.credits == c0 and int(floorf(eco.quantidade("ferro"))) == tem, "Cancelar fecha sem vender")
	p._rows["ferro"].button.pressed.emit()
	check(hud.fecha_janela_de_cima() and not cx.visible and p.visible and eco.credits == c0, "Esc fecha a caixa (e só ela: o armazém fica aberto), sem vender")
	p._rows["ferro"].button.pressed.emit()
	cx._define(10)
	var ganho: float = cx.confirmar()
	check(is_equal_approx(ganho, 10.0 * eco.price_of("ferro")) and int(floorf(eco.quantidade("ferro"))) == tem - 10 and not cx.visible,
		"Confirmar vende só os 10 escolhidos (+%d cr)" % ganho)
	p._rows["ferro"].button.pressed.emit()
	ganho = cx.vender_tudo()
	check(ganho > 0.0 and eco.quantidade("ferro") < 1.0, "Vender tudo vende o resto (+%d cr)" % ganho)
	check(p._rows["madeira"].button == null, "madeira continua sem \"Vender…\" (só o que o jogo deixa vender)")
	check(not cx.abre_item("madeira") and not cx.visible, "a caixa nem abre pra madeira")
	c0 = eco.credits
	p._secoes["metal"].button.pressed.emit()
	await _frames(1)
	check(cx.visible and cx.categoria == "metal" and eco.credits == c0 and "+" in String(cx._confirmar.text),
		"o botão da categoria também pede confirmação (%s)" % cx._confirmar.text)
	ganho = cx.confirmar()
	check(ganho > 0.0 and eco.quantidade("barra_cobre") < 1.0, "confirmou: a categoria vendida (+%d cr)" % ganho)
	eco.auto_sell = true
	arm.stock["ferro"] = 8.0
	arm._recount()
	p._rows["ferro"].button.pressed.emit()
	check(cx._nota.visible and "sozinho" in String(cx._nota.text), "com \"Vender sozinho (auto)\" ligado, a caixa avisa (%s)" % cx._nota.text)
	cx.cancelar()
	eco.auto_sell = false
	check(cx.is_in_group("janela_modal"), "a caixa é modal pra roda do mouse (sem zoom no mapa)")
	hud.close_panels()


# ------------------------------------------------------------ (2) a janela da função
func _funcoes() -> void:
	print("== (2) funções: a lista de quem tem e de quem não tem")
	var hud := g("hud")
	main.selection.clear()
	var gente: Array = get_nodes_in_group("ipezinhos").filter(func(w): return not w.e_crianca())
	for w in gente:
		w.set_job(w.ROLE_IDLE, false)
	gente[0].set_job("minerador", false)
	main.toggle_miner()
	await _frames(2)
	var p = hud._panels["funcoes"]
	check(p.visible and p.job == "minerador", "sem ninguém selecionado, o botão Minerador abre a janela da função")
	check(p.com_funcao().size() == 1 and p.sem_funcao().size() == gente.size() - 1,
		"a lista: %d com a função, %d sem" % [p.com_funcao().size(), p.sem_funcao().size()])
	var linha: Dictionary = p._linhas[gente[0]]
	check(linha.retrato.texture != null and "Ânimo" in String(linha.linha.text) and String(linha.nome.text).begins_with(hud._worker_name(gente[0])),
		"cada linha: retrato, nome, ânimo e o que está fazendo (%s)" % linha.linha.text)
	var alvo: Node = gente[1]
	p._linhas[alvo].acao.pressed.emit()
	await _frames(1)
	check(alvo.job == "minerador" and String(hud._job_buttons["minerador"].count.text) == "2",
		"\"Dar: Minerador\" a quem não tem: a contagem do botão vira 2 na hora")
	p._linhas[alvo].acao.pressed.emit()
	await _frames(1)
	check(alvo.job == alvo.ROLE_IDLE and String(hud._job_buttons["minerador"].count.text) == "1", "\"Tirar\": volta a 1")
	var mb: MenuButton = p._linhas[alvo].trocar
	p._monta_menu(mb, alvo)
	var pm := mb.get_popup()
	var tem_marca := false
	for i in pm.item_count:
		var t := pm.get_item_text(i)
		if t.begins_with("✓") or t.begins_with("✗"):
			tem_marca = true
	check(tem_marca and pm.item_count >= 4, "o \"Trocar ▾\" lista as funções com ✓/✗ (%d itens)" % pm.item_count)
	var idx_lenhador := -1
	for i in hud.ORDER_JOBS.size():
		if hud.ORDER_JOBS[i][0] == "lenhador":
			idx_lenhador = i
	pm.id_pressed.emit(idx_lenhador)
	await _frames(1)
	check(alvo.job == "lenhador", "escolher Lenhador no menu troca a função")
	var mulher: Node = null
	for w in gente:
		if String(w.gender) == "menina":
			mulher = w
	if mulher:
		var antes := String(mulher.job)
		check(not p.da(mulher, "padre") and String(mulher.job) == antes, "a regra do padre vale aqui também (mulher não vira padre)")
	p.mostra("lenhador")
	check(p.job == "lenhador" and p.com_funcao().has(alvo), "o seletor troca a função mostrada (lenhador: %d)" % p.com_funcao().size())
	main.selection.assign([gente[2]])
	main.toggle_miner()
	check(gente[2].job == "minerador", "com alguém selecionado, o botão segue dando a função (como antes)")
	main.selection.clear()
	hud.close_panels()


# ------------------------------------------------------------ (3) o pesquisador
func _pesquisa() -> void:
	print("== (3) o pesquisador: ficha, fila, nada sozinho")
	var hud := g("hud")
	var eco := g("economy")
	var res := g("research")
	var cat := g("catalogo")
	var hub: Node2D = g("village_hub")
	eco.credits = 5000.0
	var arm: Node2D = get_nodes_in_group("armazens")[0]
	for o in ["ferro", "cobre", "carvao", "prata"]:
		arm.stock[o] = 300.0
	arm._recount()
	eco.add_item("madeira", 300.0, arm.global_position)
	if res.labs().is_empty():
		res.spawn_lab(hub.global_position + Vector2(260, 120))
	await _frames(3)
	var w: Node = get_nodes_in_group("ipezinhos").filter(func(x): return not x.e_crianca())[3]
	w.set_job("pesquisador", false)
	# o catálogo: o carvão foi avistado e não é estudado; sem ordem, ninguém sai
	check(cat.estado("carvao") == cat.AVISTADO and not cat.tem_alvo(w), "carvão avistado e SEM ordem: a pesquisadora não sai sozinha")
	check(cat.estudaveis().has("carvao") and "pronta para estudar" in cat.situacao("carvao") and "h" in cat.tempo_texto("carvao"),
		"a lista do que dá pra estudar: %s — %s" % [cat.situacao("carvao"), cat.tempo_texto("carvao")])
	check(cat.pede_estudo("carvao") and cat.fila_estudo == ["carvao"] and cat.tem_alvo(w), "Pesquisar: entra na fila e ela tem alvo")
	check(not cat.pede_estudo("carvao") and cat.motivo_estudo("carvao") == "já está na fila", "não entra duas vezes")
	check(cat.cancela_estudo("carvao") and cat.fila_estudo.is_empty() and not cat.tem_alvo(w), "Cancelar tira da fila (e ela não vai)")
	# a criatura: o corpo no chão = pronta pra estudar
	cat.avista("lumivoro", false)
	check(cat.motivo_estudo("lumivoro") == "precisa de um corpo (abata um)", "Lumívoro avistado sem corpo: \"precisa de um corpo\"")
	var corpo: Node2D = load("res://scripts/props/corpo_criatura.gd").new()
	corpo.kind = "lumivoro"
	corpo.especie = "lumivoro"
	var pz: Array = cat.prazo_corpo()
	corpo.prazo_dia = int(pz[0])
	corpo.prazo_t = float(pz[1])
	main.get_node("World").add_child(corpo)
	corpo.global_position = hub.global_position + Vector2(120, 160)
	await _frames(2)
	check(corpo.is_in_group("corpos_criatura") and cat.situacao("lumivoro").begins_with("pronta para estudar: o corpo some em"),
		"o corpo no chão: \"%s — %s\"" % [cat.nome("lumivoro"), cat.situacao("lumivoro")])
	# o laboratório: pede, fila, cancela (devolve)
	cat.estuda("carvao", null)  # (os Explosivos esperam o estudo do carvão: Bloco 102)
	var c0: float = eco.credits
	check(res.pede("carrinhos") and res.current == "carrinhos" and eco.credits == c0 - 150.0, "Pesquisar com o laboratório livre: começa já (pagou 150 cr)")
	check(res.pede("medicina") and res.fila == ["medicina"] and res.current == "carrinhos", "a segunda entra na FILA (não paga ainda)")
	check(res.motivo_pedido("explosivos") == "" and res.pede("explosivos") and res.fila.size() == 2, "a que precisa da atual também pode entrar na fila")
	check(res.motivo_pedido("escoramento").begins_with("caminho fechado"), "o caminho que a fila já escolheu fica fechado (%s)" % res.motivo_pedido("escoramento"))
	res.add_points(10.0)
	var tr: float = res.tempo_restante()
	check(tr > 0.0, "tempo que falta: %s s (INF = ninguém no laboratório)" % str(tr))
	var ferro0: float = eco.quantidade("ferro")
	c0 = eco.credits
	check(res.cancela("carrinhos") and res.current == "" and eco.credits == c0 + 150.0 and is_equal_approx(eco.quantidade("ferro"), ferro0 + 100.0),
		"cancelar a de agora DEVOLVE o custo (150 cr e 100 ferro)")
	check(not res.fila.has("explosivos") and res.fila == ["medicina"], "cancelou o requisito: a que dependia dele sai da fila")
	res._tenta_fila(10.0)
	check(res.current == "medicina" and res.fila.is_empty(), "a próxima da fila começou sozinha (pagou na hora)")
	res.pede("radio")
	res.add_points(99999.0)
	res._tenta_fila(10.0)
	check(res.has("medicina") and res.current == "radio", "acabou a de agora: a da fila entra")
	# a ficha do pesquisador
	hud.open_panel("ficha", w)
	await _frames(2)
	var f = hud._panels["ficha"]
	var est = f._estudos
	check(est.visible and "Rádio" in String(est._agora.text) or "radio" in String(est._agora.text).to_lower(), "a ficha do pesquisador mostra a pesquisa de agora (%s)" % String(est._agora.text).replace("\n", " / "))
	check(est._barra.visible, "com a barra de progresso")
	var botoes: Array = est.find_children("Pesquisar_*", "Button", true, false)
	var tem_lumi := botoes.any(func(b): return b.name == "Pesquisar_lumivoro" and not b.disabled)
	check(tem_lumi, "o corpo do Lumívoro aparece como pesquisa disponível (botão Pesquisar ativo)")
	check(botoes.any(func(b): return String(b.name).begins_with("Pesquisar_") and b.name != "Pesquisar_lumivoro" and b.name != "Pesquisar_carvao"),
		"e as pesquisas do laboratório, com custo e tempo (%d botões)" % botoes.size())
	var outro: Node = get_nodes_in_group("ipezinhos").filter(func(x): return not x.e_crianca() and x != w)[0]
	outro.set_job("minerador", false)
	hud.open_panel("ficha", outro)
	await _frames(1)
	check(not f._estudos.visible, "na ficha de quem não é pesquisador, a seção não aparece")
	hud.close_panels()
	# ao concluir: o "por que veio" no cartão
	cat.pede_estudo("lumivoro")
	cat.estuda("lumivoro", w)
	await _frames(2)
	var achou := false
	for l in hud.find_children("*", "Label", true, false):
		if "Por que veio:" in String((l as Label).text):
			achou = true
	check(achou and cat.estudado("lumivoro") and not cat.fila_estudo.has("lumivoro"), "ao concluir: o cartão traz o \"Por que veio\" e sai da fila")
	# o save da fila
	res.pede("estudo_solar")
	cat.avista("cobre", false)
	cat.pede_estudo("cobre")
	var dr: Dictionary = JSON.parse_string(JSON.stringify(res.get_save_data()))
	var dc: Dictionary = JSON.parse_string(JSON.stringify(cat.get_save_data()))
	res.fila = []
	cat.fila_estudo = []
	res.load_save_data(dr)
	cat.load_save_data(dc)
	check(res.fila.has("estudo_solar") and cat.fila_estudo.has("cobre"), "save: as duas filas voltam (%s / %s)" % [res.fila, cat.fila_estudo])
	dr.erase("fila")
	dc.erase("fila_estudo")
	res.load_save_data(dr)
	cat.load_save_data(dc)
	check(res.fila.is_empty() and cat.fila_estudo.is_empty(), "save antigo (sem as chaves): filas vazias, carrega")
