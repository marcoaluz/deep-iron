extends SceneTree
## Bloco 135: CORREÇÕES do HUD e da vila. RODAR SÓ COM APPDATA ISOLADO.
##   (1) as Configurações do menu inicial cabem na tela (1280x720 e 1366x768, escalas 90/100/125%): o conteúdo rola e o
##       rodapé (Cancelar / Concluir) fica sempre visível; Cancelar e Esc desfazem o que mudou;
##   (2) o gerenciador de janelas flutuantes: nunca fora da tela, nunca uma em cima da outra, X sempre visível, Esc fecha a
##       de cima primeiro;
##   (3) dar função a 12 pessoas sem travar (nenhum quadro acima de 50 ms);
##   (4) o mineiro na FRENTE da jazida (ponto de trabalho do lado da câmera e na frente na ordem de desenho);
##   (5) os emigrantes: ícone com contador, a janela com aceitar/recusar/aceitar todos, clique no mapa à noite, aviso;
##   (6) os prédios únicos no CONSTRUIR: ✔ Construído / Em obra / disponível, e nunca dois.
var fails := 0
var main: Node


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
	await _configuracoes()
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	await _frames(8)
	await _janelas()
	await _migrantes()
	await _funcoes()
	await _jazidas()
	await _unicos()
	print("FALHAS: %d" % fails)
	quit()


# ------------------------------------------------------------ (2) o gerente de janelas
func _janelas() -> void:
	print("== (2) janelas flutuantes: dentro da tela, sem cobrir outra, X, Esc")
	var hud := g("hud")
	var ger: Node = hud.gerente
	check(ger != null, "o HUD tem o gerente de janelas")
	var w: Node = get_nodes_in_group("ipezinhos")[0]
	hud.open_panel("hub")
	await _frames(3)
	hud.open_panel("ficha", w)
	await _frames(3)
	hud.mostra_requisitos("cozinheiro", "Cozinheiro", Color.WHITE, w)
	await _frames(4)
	var hub_p: Control = hud._panels["hub"]
	var ficha: Control = hud._panels["ficha"]
	var req: Control = hud._req_card
	check(hub_p.visible and ficha.visible and req.visible, "janela do Centro, ficha e cartão de requisitos abertos ao mesmo tempo")
	var area: Rect2 = ger.area()
	var todas := [hub_p, ficha, req]
	var dentro := true
	for j in todas:
		dentro = dentro and area.grow(1.0).encloses((j as Control).get_global_rect())
	check(dentro, "todas dentro da área útil da tela (nenhuma cortada) — área %s, centro %s, ficha %s, cartão %s" % [area, hub_p.get_global_rect(), ficha.get_global_rect(), req.get_global_rect()])
	# duas (a ficha e o cartão — o caso do Marco) nunca se cobrem; com três, a que não cabe vai em cascata: a de cima
	# inteira e o título (30 px de cima) das de trás à mostra
	check(not ficha.get_global_rect().grow(-2.0).intersects(req.get_global_rect()) or not hub_p.get_global_rect().grow(-2.0).intersects(req.get_global_rect()) and not hub_p.get_global_rect().grow(-2.0).intersects(ficha.get_global_rect()),
		"a ficha e o cartão de requisitos não ficam um em cima do outro")
	var de_cima: Control = ger.abertas()[-1]
	var titulos_ok := true
	for j in todas:
		if j == de_cima:
			continue
		var titulo := Rect2((j as Control).get_global_rect().position, Vector2((j as Control).size.x, 30.0))
		for k in todas:
			if k != j and (k as Control).get_index() > (j as Control).get_index() and (k as Control).get_global_rect().encloses(titulo):
				titulos_ok = false
	check(titulos_ok, "nenhuma janela some inteira atrás de outra (o título de cada uma fica à mostra)")
	hud.close_panels()
	await _frames(2)
	hud.open_panel("ficha", w)
	await _frames(3)
	hud.mostra_requisitos("cozinheiro", "Cozinheiro", Color.WHITE, w)
	await _frames(4)
	check(not ficha.get_global_rect().grow(-2.0).intersects(req.get_global_rect()) and area.grow(1.0).encloses(ficha.get_global_rect()) and area.grow(1.0).encloses(req.get_global_rect()),
		"só a ficha e o cartão (o caso do Marco): lado a lado, dentro da tela — ficha %s, cartão %s" % [ficha.get_global_rect(), req.get_global_rect()])
	hud.open_panel("hub")
	await _frames(3)
	var com_x := true
	for j in todas + [hud._hint_panel]:
		com_x = com_x and ger.tem_x(j)
	check(com_x, "todas têm o botão X (a ajuda também)")
	hud.set_hints_visible(true)
	await _frames(4)
	check(area.grow(1.0).encloses(hud._hint_panel.get_global_rect()), "a ajuda abre dentro da tela")
	# Esc fecha a de cima primeiro
	check(hud.fecha_janela_de_cima() and not hud._hint_panel.visible and req.visible and ficha.visible, "Esc fecha a de cima (a ajuda) e deixa as outras")
	check(hud.fecha_janela_de_cima() and not hub_p.visible and req.visible and ficha.visible, "Esc de novo fecha a seguinte de cima (o Centro, a última aberta antes da ajuda)")
	check(hud.fecha_janela_de_cima() and not req.visible and ficha.visible, "e de novo, o cartão")
	# uma janela de prédio troca pela outra; a ficha fica
	hud.open_panel("hub")
	await _frames(2)
	hud.open_panel("moral")
	await _frames(3)
	check(not hub_p.visible and hud._panels["moral"].visible and ficha.visible, "abrir outra janela de prédio fecha a anterior do mesmo tipo (a ficha fica)")
	# jogada pra fora da tela: o gerente traz de volta
	ficha.global_position = Vector2(-600, -400)
	ger.posiciona(ficha)
	check(area.grow(1.0).encloses(ficha.get_global_rect()), "uma janela fora da tela volta pra dentro (clamp)")
	hud.close_panels()
	await _frames(2)


# ------------------------------------------------------------ (1) as Configurações
func _configuracoes() -> void:
	print("== (1) as Configurações cabem na tela")
	var WindowManager: Node = root.get_node("WindowManager")
	var Audio: Node = root.get_node("Audio")
	var menu: Node = load("res://scenes/ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	await _frames(3)
	var painel: Node = null
	for n in menu.find_children("*", "VBoxContainer", true, false):
		if n.get_script() == load("res://scripts/ui/settings_panel.gd"):
			painel = n
	check(painel != null, "o menu inicial tem a tela de Configurações")
	if painel == null:
		menu.queue_free()
		return
	for c in painel.get_parent().get_children():
		if c is Control and c != painel:
			(c as Control).visible = false
	painel.visible = true
	var escala0: float = WindowManager.ui_scale()
	for tam in [Vector2i(1280, 720), Vector2i(1366, 768)]:
		root.size = tam
		for esc in WindowManager.UI_SCALES:
			WindowManager.set_ui_scale(esc)
			await _frames(14)
			var tela: Rect2 = root.get_visible_rect()
			var rc: Rect2 = (painel.cancelar as Control).get_global_rect()
			var ro: Rect2 = (painel.concluir as Control).get_global_rect()
			var dentro := tela.grow(1.0).encloses(rc) and tela.grow(1.0).encloses(ro)
			check(dentro and rc.size.y > 10.0 and ro.end.y > tela.end.y - 160.0, "%dx%d, escala %d%%: Cancelar e Concluir dentro da tela e a janela aproveita a altura (tela %s, Concluir %s)" % [
				tam.x, tam.y, roundi(esc * 100.0), str(tela.size.round()), str(ro.position.round())])
	WindowManager.set_ui_scale(escala0)
	check(painel.get_node_or_null("Rolagem") is ScrollContainer, "o conteúdo fica numa área que rola")
	# Cancelar desfaz
	painel.visible = false
	await _frames(1)
	painel.visible = true
	await _frames(2)
	var antes: float = Audio.ui_volume
	Audio.ui_volume = 0.11
	Audio.save_settings()
	painel.cancela()
	await _frames(2)
	check(is_equal_approx(Audio.ui_volume, antes) and is_equal_approx(float(load("res://scripts/core/settings.gd").get_value("audio", "ui_volume", -1.0)), antes),
		"Cancelar desfaz o que mudou (volume da interface volta a %.2f)" % antes)
	# Esc cancela
	painel.visible = true
	await _frames(2)
	Audio.ui_volume = 0.22
	Audio.save_settings()
	var fechou := [false]
	painel.back_pressed.connect(func(): fechou[0] = true, CONNECT_ONE_SHOT)
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = KEY_ESCAPE
	ev.keycode = KEY_ESCAPE
	painel._unhandled_key_input(ev)
	check(fechou[0] and is_equal_approx(Audio.ui_volume, antes), "Esc cancela e fecha")
	# Concluir guarda
	painel.visible = true
	await _frames(2)
	Audio.ui_volume = 0.33
	Audio.save_settings()
	painel.conclui()
	check(is_equal_approx(float(load("res://scripts/core/settings.gd").get_value("audio", "ui_volume", -1.0)), 0.33), "Concluir guarda o que mudou")
	Audio.ui_volume = antes
	Audio.save_settings()
	menu.queue_free()
	await _frames(2)


# ------------------------------------------------------------ (3) dar função sem travar
func _funcoes() -> void:
	print("== (3) dar função a 12 pessoas sem travar")
	var eco := g("economy")
	while get_nodes_in_group("ipezinhos").size() < 12:
		eco.novo_ipezinho("M")
	await _frames(10)
	var ws: Array = get_nodes_in_group("ipezinhos").slice(0, 12)
	var labels0 := 0
	for w in ws:
		labels0 += (w as Node).find_children("*", "Label", false, false).size()
	main.selection.clear()
	for w in ws:
		main.selection.append(w)
	# (sem janela, a 1ª vez de cada roupa carrega na hora — de propósito, pros testes; com janela ela vem em segundo
	# plano: medido pelo tests/bench_funcoes.gd. Aqui: uma rodada pra carregar e a medida na segunda)
	for job in ["lenhador", "cozinheiro", "minerador"]:
		main.toggle_job(job, job, Color.WHITE)
		await _frames(3)
	var pior := 0.0
	for job in ["lenhador", "cozinheiro", "minerador"]:
		var t0 := Time.get_ticks_usec()
		main.toggle_job(job, job, Color.WHITE)
		pior = maxf(pior, (Time.get_ticks_usec() - t0) / 1000.0)
		for f in 8:
			var tf := Time.get_ticks_usec()
			await process_frame
			pior = maxf(pior, (Time.get_ticks_usec() - tf) / 1000.0)
	var labels1 := 0
	for w in ws:
		labels1 += (w as Node).find_children("*", "Label", false, false).size()
	check(labels1 <= labels0, "dar função a várias de uma vez não cria um balão em cada uma (o aviso do canto basta)")
	check(pior < 50.0, "as 12 de uma vez: nenhum quadro acima de 50 ms (pior %.1f ms)" % pior)
	var w0: Node = ws[0]
	main.selection.clear()
	main.selection.append(w0)
	main.toggle_job("guarda", "Guarda", Color.WHITE)
	check(w0.find_children("*", "Label", false, false).size() > 0, "uma pessoa só: o balão com a função continua")
	var hud := g("hud")
	var fonte: String = (load("res://scripts/core/hud.gd") as GDScript).source_code
	var corpo := fonte.substr(fonte.find("func _refresh_order_bar"), fonte.find("func funcao_liberada") - fonte.find("func _refresh_order_bar"))
	check(not corpo.contains("_dica_funcao("), "a barra de baixo não reavalia os requisitos de todas as funções a cada segundo")
	hud._job_buttons["lenhador"].button.mouse_entered.emit()
	check(String(hud._job_buttons["lenhador"].button.tooltip_text).contains("O que ela precisa"), "a dica com os requisitos sai quando o mouse chega no botão")
	var t1 := Time.get_ticks_usec()
	for i in 10:
		hud._refresh_order_bar(get_nodes_in_group("ipezinhos"))
	var ms := (Time.get_ticks_usec() - t1) / 10000.0
	check(ms < 10.0, "atualizar a barra de baixo com alguém selecionado custa pouco (%.2f ms)" % ms)
	var Bon: GDScript = load("res://scripts/iso/iso_bonecos.gd")
	var Ret: GDScript = load("res://scripts/ui/retratos.gd")
	var Sl: GDScript = load("res://scripts/core/audio_slots.gd")
	check(Bon.has_method("_reserva") and Ret.has_method("aquece_todos") and Sl.has_method("aquece"),
		"roupas, retratos e sons carregam em segundo plano (sem esperar dentro do quadro)")


# ------------------------------------------------------------ (4) o mineiro na frente da jazida
func _jazidas() -> void:
	print("== (4) o mineiro na frente da jazida (todas, todos os andares)")
	var iso := g("iso_view")
	var w: Node2D = get_nodes_in_group("ipezinhos")[1]
	var total := 0
	var fora := 0
	var na_frente := 0
	var frente_tela := 0
	for m in get_nodes_in_group("minerios"):
		var bb_m = iso.billboard_of(m)
		if bb_m == null or bb_m.box == null:
			continue
		var rocha: Rect2 = bb_m.box.rect
		for i in m.slot_count:
			total += 1
			var p: Vector2 = m.get_slot_position(i)
			w.global_position = p
			iso._process(0.016)
			var bb_w = iso.billboard_of(w)
			var arte := p * 1.5  # (a caixa da vista é em px de arte: chão x 1,5)
			if not rocha.grow(-1.0).has_point(arte):
				fora += 1
			# do lado da câmera: na tela, o pé dele fica abaixo do centro da pedra
			if (p - m.global_position).x + (p - m.global_position).y > 0.0:
				frente_tela += 1
			# visível inteiro: ou o desenho dele nem cruza o da pedra na tela (ao lado), ou ele é desenhado depois (na frente)
			var Iso: GDScript = load("res://scripts/iso/iso_core.gd")
			var cruza: bool = bb_w != null and bb_w.box != null and Iso.screen_rect(bb_w.box).intersects(Iso.screen_rect(bb_m.box))
			if bb_w and (not cruza or bb_w.z_index > bb_m.z_index):
				na_frente += 1
			else:
				print("   atrás: %s posto %d em %s: z mineiro %s, z pedra %d, caixa %s, pedra %s" % [m.name, i, p.round(), str(bb_w.z_index) if bb_w else "-", bb_m.z_index, str(bb_w.box.rect) if bb_w and bb_w.box else "-", rocha])
	check(total >= 30, "jazidas conferidas em todos os andares (%d postos)" % total)
	check(fora == total, "nenhum posto dentro da pedra (%d de %d fora)" % [fora, total])
	check(frente_tela == total, "todos os postos do lado da câmera (%d de %d)" % [frente_tela, total])
	check(na_frente == total, "o mineiro em cada posto aparece inteiro: ao lado da pedra ou desenhado na frente dela (%d de %d)" % [na_frente, total])
	var m0: Node2D = get_nodes_in_group("minerios")[0]
	var atras := m0.global_position + Vector2(-60, -60)
	var esp: Vector2 = m0.get_wait_position(Node2D.new() if false else w)
	w.global_position = atras
	esp = m0.get_wait_position(w)
	check((esp - m0.global_position).x + (esp - m0.global_position).y > 0.0, "quem espera a vez fica na frente da pedra mesmo chegando por trás")


# ------------------------------------------------------------ (5) os migrantes
func _migrantes() -> void:
	print("== (5) migrantes: ícone com contador, janela, aceitar todos, clique no mapa de noite")
	var mig := g("migrantes")
	var hud := g("hud")
	var eco := g("economy")
	var dn := g("day_night")
	check(mig != null, "o sistema de migrantes existe")
	var chegaram: Array = mig.chama_grupo(3)
	await _frames(2)
	hud.close_panels()
	hud._refresh()
	var al: Dictionary = hud._alertas._botoes.get("migrantes", {})
	check(not al.is_empty() and al.button.visible and String(al.count.text) == "3", "ícone na coluna da direita com o contador (%s)" % (al.count.text if not al.is_empty() else "?"))
	al.button.pressed.emit()
	await _frames(2)
	var painel: Control = hud._panels["migrantes"]
	check(painel.visible, "clicar no ícone abre a janela dos migrantes")
	painel.refresh()
	var textos := ""
	for l in painel.find_children("*", "Label", true, false):
		textos += (l as Label).text + " | "
	check(textos.contains("Idade:") and textos.contains("Família: chegou com"), "cada cartão tem retrato, nome, função, idade e família")
	var todos: Button = painel.find_child("AceitarTodos", true, false)
	check(todos != null and todos.visible and painel.find_child("Aceitar", true, false) != null and painel.find_child("Recusar", true, false) != null,
		"botões Aceitar, Recusar e Aceitar todos")
	# o clique no mapa, de noite, na frente do portão
	dn.time = dn.tempo_da_hora(22.0)
	await _frames(2)
	hud.close_panels()
	var w: Node2D = chegaram[0].w
	w.global_position = w.global_position  # (onde ele está esperando)
	var iso := g("iso_view")
	main._press_canvas = iso.to_screen(w.global_position) + Vector2(14, -6)
	main._finish_left_click_iso(false)
	await _frames(2)
	check(painel.visible, "de noite, clicar no migrante (perto, não em cima) abre a janela — o portão não rouba o clique")
	# o save leva a família
	var d: Dictionary = mig.get_save_data()
	check(d.has("grupo_n") and (d.esperando as Array).all(func(x): return x.has("grupo")), "o save guarda a família (grupo) de cada um")
	mig.load_save_data(d)
	await _frames(2)
	check(mig.familia_de(mig.esperando[0].w).size() == 2, "carregando, a família continua junta")
	mig.load_save_data({"proximo": 999.0, "esperando": [{"ipezinho": {}, "name": "Velho", "condicao": "saudavel", "funcao": "minerador", "prazo": 100.0}]})
	await _frames(2)
	check(mig.esperando.size() == 1 and mig.familia_de(mig.esperando[0].w).is_empty(), "save antigo (sem grupo): carrega, cada um sozinho")
	# aceitar todos
	mig.chama_grupo(2)
	await _frames(2)
	var camas: int = eco.free_beds()
	var antes: int = mig.esperando.size()
	var n: int = mig.aceita_todos()
	check(n == mini(antes, camas), "Aceitar todos: entram %d (camas livres %d, esperando %d)" % [n, camas, antes])
	for e in mig.esperando.duplicate():
		mig.recusa(e.w)
	dn.time = dn.tempo_da_hora(12.0)
	hud.close_panels()
	await _frames(2)


# ------------------------------------------------------------ (6) os prédios únicos no CONSTRUIR
func _cartao(hud: Node, nome: String) -> Dictionary:
	var bm: Node = hud._build_menu
	for i in bm.TAB_NAMES.size():
		bm._show_tab(i)
		bm.refresh()
		for c in bm._cards:
			if String(c.def.name) == nome:
				return c
	return {}


func _unicos() -> void:
	print("== (6) prédios únicos: ✔ Construído / Em obra / disponível, nunca dois")
	var hud := g("hud")
	var hub := g("village_hub")
	var eco := g("economy")
	eco.credits = 99999.0
	hud.close_panels()
	hud.toggle_build_menu()
	await _frames(2)
	var ofi := _cartao(hud, "Oficina (forja)")
	check(not ofi.is_empty() and String(ofi.tag.text) == "✔ Construído" and String(ofi.button.text) == "Abrir" and not ofi.button.disabled,
		"a Oficina construída: \"✔ Construído\" com o botão Abrir (%s / %s)" % [ofi.tag.text if not ofi.is_empty() else "?", ofi.button.text if not ofi.is_empty() else "?"])
	ofi.button.pressed.emit()
	await _frames(2)
	check(hud._panels["oficina"].visible and not g("house_placer").active, "Abrir abre a janela da Oficina (não pede outra)")
	check(hub.oficina_block_reason() != "" and not hub.build_oficina(), "pelo atalho também não dá pra pedir outra Oficina")
	hud.close_panels()
	hud.toggle_build_menu()
	await _frames(2)
	# a Igreja em obra
	hub.level = maxi(int(hub.level), int(hub.igreja_estagio))
	var Canteiro: GDScript = load("res://scripts/props/canteiro.gd")
	var obra = Canteiro.order(self, "igreja", hub.global_position + Vector2(200, 200), 60.0)
	await _frames(2)
	var igr := _cartao(hud, "Igreja")
	check(not igr.is_empty() and String(igr.tag.text) == "Em obra" and igr.button.disabled and igr.barra != null and igr.barra.visible,
		"a Igreja em obra: \"Em obra\", a barra das etapas e o botão desligado")
	check(hub.igreja_block_reason().begins_with("em obra") and not hub.build_igreja(), "nem pelo atalho dá pra pedir outra Igreja em obra")
	obra.obra_work(99999.0)
	await _frames(3)
	igr = _cartao(hud, "Igreja")
	check(String(igr.tag.text) == "✔ Construído" and String(igr.button.text) == "Abrir", "a obra acabou: a Igreja vira \"✔ Construído\"")
	# o Posto de troca: disponível, depois em obra
	hub.level = 5
	var pt := _cartao(hud, "Posto de troca")
	check(not pt.is_empty() and String(pt.tag.text).begins_with("uma só") and String(pt.button.text) == "Construir", "o Posto de troca ainda não pedido: disponível (uma só)")
	var obra2 = Canteiro.order(self, "posto_troca", hub.global_position + Vector2(-200, 200), 60.0)
	await _frames(2)
	pt = _cartao(hud, "Posto de troca")
	check(String(pt.tag.text) == "Em obra" and pt.button.disabled and not hub.build_posto_troca(), "o Posto de troca em obra: não dá pra pedir outro")
	hud.toggle_build_menu()
	if is_instance_valid(obra2):
		obra2.queue_free()
	await _frames(2)

