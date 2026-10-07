extends SceneTree
## Bloco 95: LAYOUT V2 da interface (seção 27 do guia) + a escala tipográfica. A barra de cima sem "Vender"/"auto"
## (foram pro Armazém) e com a hora no meio; a aba fina da esquerda (Tab abre a lista; os parados e os com
## problema primeiro); a coluna de ALERTAS (ícone + número; clicar leva ao lugar); a barra de funções agrupada
## (só as liberadas, nome na dica); o cartão do selecionado acima da barra; os rótulos do mapa só com o nome (o
## resto com o mouse/janela aberta); a gaveta das obras com o martelo cinza esperando engenheiro; a pilha de
## avisos; a escala 90/100/125%; o espaço do rastreador de missões; os BALÕES DE MOTIVO (e o liga/desliga);
## nenhum tamanho de letra solto no código. RODAR SÓ COM APPDATA ISOLADO.
const Tipo := preload("res://scripts/ui/tipografia.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
var Ipe: GDScript  # (load na hora: o preload pedia o autoload Audio antes de existir)
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var _alvo: Node = null


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
	preload("res://scripts/core/settings.gd").set_value("video", "ui_scale", 1.0)  # (o autoload ainda não está na árvore)
	root.size = Vector2i(1280, 720)  # a tela lógica do jogo
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP  # (headless: a janela é quadrada; assim a área é 1280x720)
	main = load("res://scenes/game/main.tscn").instantiate()
	Ipe = load("res://scripts/workers/ipezinho.gd")
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


func tecla(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = k
	main._unhandled_input(ev)


## O espelho (iso) de um nó e o rótulo espelhado dele (sincroniza na hora: sem janela, as coisas paradas só se
## copiam quando entram na tela).
func rotulo_espelhado(n: Node) -> Label:
	var iso := g("iso_view")
	if iso == null:
		return null
	for bb in iso.find_children("BB_*", "", true, false):
		if bb.get("src") == n:
			bb._sync_props()
			for pr in bb._pairs:
				if pr[0] is Label and String(pr[0].name) == "NameLabel":
					return pr[1]
	return null


## Nenhum tamanho de letra solto no código (a escala do tipografia.gd vale pra tudo).
func numeros_soltos() -> Array[String]:
	var out: Array[String] = []
	var re_fs := RegEx.create_from_string('font_size",\\s*\\d')
	var re_lb := RegEx.create_from_string('_label\\([^\\n]*?,\\s*\\d+\\s*,\\s*(COLOR|_hud|Color|hud|UiSkin)')
	var re_px := RegEx.create_from_string('usa_fonte\\([^\\n]*,\\s*\\d+\\)')
	var re_ds := RegEx.create_from_string('draw_string\\([^\\n]*,\\s*-?\\d+,\\s*\\d+\\s*[,)]')
	var pastas := ["res://scripts"]
	while not pastas.is_empty():
		var d: String = pastas.pop_back()
		for sub in DirAccess.get_directories_at(d):
			pastas.append(d.path_join(sub))
		for f in DirAccess.get_files_at(d):
			if not f.ends_with(".gd") or f == "tipografia.gd":
				continue
			var p := d.path_join(f)
			var txt := FileAccess.get_file_as_string(p)
			for re in [re_fs, re_lb, re_px, re_ds]:
				var m: RegExMatch = re.search(txt)
				if m:
					out.append("%s: %s" % [p.get_file(), m.get_string().left(60)])
	return out


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 200.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var hud = main.get_node_or_null("HUD")
	if step == 0 and t > 3.0:
		step = 1
		t_mark = t
		print("== A) barra de cima: hora no meio, sem Vender/auto (foram pro Armazém)")
		hud._refresh()
		var vis: Vector2 = root.get_visible_rect().size
		check(hud.get("_sell_button") == null and hud.get("_auto_sell_check") == null, "barra de cima sem 'Vender' e 'auto'")
		var arm = hud._panels.get("armazem")
		check(arm != null and arm.get("_auto_check") is CheckBox, "o 'auto' está na janela do Armazém")
		var rc: Rect2 = hud._clock_box.get_global_rect()
		check(absf(rc.get_center().x - vis.x * 0.5) < 160.0, "a hora fica no meio da barra (centro %d de %d)" % [rc.get_center().x, vis.x])
		check(hud._phase_label.get_theme_font_size("font_size") >= Tipo.PIXEL_2, "a hora é grande (%d px)" % hud._phase_label.get_theme_font_size("font_size"))
		check(hud._phase_label.text.contains(":"), "mostra hh:mm ('%s')" % hud._phase_label.text)
		var row: Control = hud._chips.credits.box.get_parent()
		check(row.get_combined_minimum_size().x <= vis.x, "a barra de cima cabe na largura (%d de %d)" % [row.get_combined_minimum_size().x, vis.x])
		check(hud._menu_janelas != null, "menu 'Janelas' na barra de cima (no lugar da coluna de construções)")
		hud._monta_menu_janelas()
		check(hud._menu_janelas.get_popup().item_count >= 5, "o menu lista as janelas (%d itens)" % hud._menu_janelas.get_popup().item_count)

		print("== B) aba fina + lista (Tab), parados e com problema primeiro")
		check(Teclas.acao(KEY_TAB) == "pessoas" and Teclas.acao(KEY_PERIOD) == "proximo", "Tab = pessoas; '.' = próximo ipezinho")
		check(hud._tira != null and hud._tira.get_global_rect().size.x <= hud.TIRA_W + 2.0, "aba fina à esquerda (%d px)" % hud._tira.get_global_rect().size.x)
		check(not hud._left_panel.visible, "a lista começa fechada (mais mapa)")
		tecla(KEY_TAB)
		check(hud._left_panel.visible, "Tab abre a lista")
		var w: Array = ws()
		w[0].set_job("minerador")
		w[1].hurt("mina", "leve")
		hud._refresh()
		var prios: Array = []
		for c in hud._rows_box.get_children():
			for k in hud._rows:
				if hud._rows[k].panel == c:
					prios.append(hud.prioridade_na_lista(k))
		var ordenada := true
		for i in range(1, prios.size()):
			if prios[i] < prios[i - 1]:
				ordenada = false
		check(ordenada and prios.size() == w.size(), "ordem da lista: parados, com problema, o resto %s" % str(prios))
		tecla(KEY_TAB)
		check(not hud._left_panel.visible, "Tab de novo fecha")
		hud._abre_gaveta(true)
		check(hud._left_panel.visible and hud._gaveta_por_mouse, "passar o mouse na aba abre a lista")
		hud._fecha_gavetas()

		print("== C) coluna de ALERTAS (ícone + número; clicar leva ao lugar)")
		for c in get_nodes_in_group("comedouros"):
			c.food_stock = 0.0
		hud._refresh()
		var ativos: Array = hud._alertas.ativos()
		print("  alertas: ", ativos)
		check(ativos.has("sem_comida"), "sem comida aparece")
		check(ativos.has("ferido"), "ferido aparece")
		check(ativos.has("ociosos"), "parados aparecem")
		var cam = main.get_node("Camera2D")
		var antes: Vector2 = cam._target_pos if "_target_pos" in cam else cam.position
		_alvo = hud._alertas.vai("ferido")
		check(_alvo == w[1], "clicar no alerta de ferido vai até ele (e seleciona)")
		var depois: Vector2 = cam._target_pos if "_target_pos" in cam else cam.position
		check(antes != depois or antes.distance_to(w[1].global_position) < 1.0, "a câmera foi pro lugar")
		var tip: String = hud._alertas._botoes["sem_comida"].button.tooltip_text
		check(tip.contains("porç"), "a dica conta o detalhe ('%s')" % tip.replace("\n", " | ").left(70))
		check(hud.get("_buildings_box") == null, "a coluna de construções saiu")

		print("== D) barra de funções agrupada (só as liberadas; nome na dica)")
		check(hud._grupos.has("PRODUÇÃO") and hud._grupos.has("SERVIÇO") and hud._grupos.has("DEFESA"), "grupos Produção | Serviço | Defesa")
		var mb: Button = hud._job_buttons["minerador"].button
		check(mb.visible and mb.tooltip_text.begins_with("Minerador") and mb.tooltip_text.contains("tecla 1"), "botão só com ícone; o nome e a tecla na dica")
		check(not mb.get_children().any(func(c): return c is HBoxContainer and c.get_children().any(func(l): return l is Label and l.text == "Minerador")), "sem o nome escrito no botão")
		var padre_lib: bool = hud.funcao_liberada("padre")
		check(hud._job_buttons["padre"].button.visible == padre_lib, "padre só aparece liberado (agora: %s)" % padre_lib)
		var fund_lib: bool = hud.funcao_liberada("fundidor")
		check(hud._job_buttons["fundidor"].button.visible == fund_lib, "fundidor só aparece com a fornalha (agora: %s)" % fund_lib)
		if not fund_lib:
			w[2].set_job("fundidor")
			hud._refresh()
			check(hud._job_buttons["fundidor"].button.visible, "quem já tem a função mostra o botão")
			w[2].set_job("ocioso")

		print("== E) cartão do selecionado acima da barra, à esquerda")
		main.select(w[0])
		hud._refresh()
		var card: Control = hud._portrait_card
		check(card.visible and hud._portrait_doing.text == w[0].get_state_label(), "retrato + o que está fazendo ('%s')" % hud._portrait_doing.text)
		var cr: Rect2 = card.get_global_rect()
		var orr: Rect2 = hud._order_bar.get_global_rect()
		check(cr.end.y <= orr.position.y + 1.0, "fica acima da barra (%d <= %d), não cobre o Construir" % [cr.end.y, orr.position.y])
		check(cr.position.x < root.get_visible_rect().size.x * 0.5, "à esquerda")
		main.select(null)
		hud._refresh()
		check(not card.visible, "sem seleção: some")

		print("== F) rótulos do mapa só com o nome (detalhes ao passar o mouse)")
		var coz: Node = g("comedouros")
		var rot := rotulo_espelhado(coz)
		var iso = g("iso_view")
		check(rot != null, "rótulo da cozinha espelhado")
		if rot:
			check(not rot.text.contains("\n") and rot.text == "Cozinha", "só o nome: '%s'" % rot.text.replace("\n", " | "))
			check(rot.get_theme_font_size("font_size") == Tipo.MAPA, "letra menor no mapa (%d)" % rot.get_theme_font_size("font_size"))
			iso.foco = coz  # (o mesmo caminho do mouse em cima: o hover o cursor do HUD limpa sem janela)
		step = 2
		t_mark = t
		return false
	if step == 2 and t - t_mark > 0.6:
		step = 3
		var coz: Node = g("comedouros")
		var rot := rotulo_espelhado(coz)
		var iso = g("iso_view")
		if rot:
			check(rot.text.contains("\n"), "com o mouse em cima: o texto inteiro ('%s')" % rot.text.replace("\n", " | "))
		iso.foco = null

		print("== G) obras: barrinha + martelo cinza esperando engenheiro")
		var eco = g("economy")
		eco.credits = 9999.0
		var arm = g("armazens")
		for k in ["ferro", "cobre", "carvao"]:
			arm.stock[k] = 5000.0
		arm.wood_stored = 5000.0
		arm.total_stored = arm.stock.values().reduce(func(x, y): return x + y, 0.0)  # (só recalcula quando chega carga)
		var hub = g("village_hub")
		print("  trilhas: '%s'" % hub.upgrade_block_reason("trilhas"))
		hub.buy_upgrade("trilhas")
		var obras := get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending())
		check(not obras.is_empty(), "uma obra encomendada (%d)" % obras.size())
		hud.toggle_obras()
		hud._refresh()
		var linha: Control = hud._obras_box.get_child(0) if hud._obras_box.get_child_count() > 0 else null
		var martelo: TextureRect = linha.find_child("Martelo", true, false) if linha else null
		check(martelo != null and martelo.modulate.r < 0.6, "martelo cinza = esperando engenheiro")
		var barra: ProgressBar = linha.find_child("Barra", true, false) if linha else null
		check(barra != null, "barrinha de progresso na gaveta das obras")
		check(hud._alertas.ativos().has("obra_parada"), "alerta de obra parada")
		check(hud._tira_obras.get_node("Num").text != "", "número de obras na aba fina ('%s')" % hud._tira_obras.get_node("Num").text)
		hud._fecha_gavetas()

		print("== H) avisos em pilha num canto, com ícone")
		for i in 6:
			hud.show_toast("Aviso %d: sem comida na cozinha" % i, hud.COLOR_HUNGER_BAD)
		var av: Control = hud._avisos
		check(av.get_child_count() <= av.maximo, "no máximo %d na tela (%d)" % [av.maximo, av.get_child_count()])
		var ultimo: Control = av.get_child(av.get_child_count() - 1)
		check(ultimo.find_children("*", "TextureRect", true, false).size() > 0, "o aviso tem ícone")
		var ar: Rect2 = av.get_global_rect()
		check(ar.end.x > root.get_visible_rect().size.x * 0.75, "no canto direito")
		hud.show_toast("Clique pra ir", hud.COLOR_TITLE, g("comedouros"))
		var com_alvo: Control = av.get_child(av.get_child_count() - 1)
		check(com_alvo.mouse_filter == Control.MOUSE_FILTER_STOP, "aviso com lugar: clicável")

		print("== I) escala 90 / 100 / 125% e o espaço das missões")
		var wm = root.get_node("WindowManager")
		check(wm.UI_SCALES == [0.9, 1.0, 1.25], "3 opções de escala")
		check(is_equal_approx(wm.opcao_de_escala(0.8), 0.9) and is_equal_approx(wm.opcao_de_escala(1.5), 1.25) and is_equal_approx(wm.opcao_de_escala(1.1), 1.0), "valor antigo vai pra opção mais perto")
		wm.set_ui_scale(1.25)
		check(is_equal_approx(wm.applied_ui_scale(), 1.25) and is_equal_approx(root.content_scale_factor, 1.25), "125% cabe em 1280x720 (%s)" % str(root.content_scale_factor))
		wm.set_ui_scale(1.0)
		var ms: Control = hud._missoes
		check(ms != null and not ms.visible and ms.custom_minimum_size.x >= 240.0, "rastreador de missões reservado (escondido)")
		ms.mostra("Cap. 2  Fogo e ferro", [["10 barras de ferro", false], ["igreja", true]])
		check(ms.visible, "o rastreador aparece quando o sistema de missões pedir")
		ms.esconde()

		print("== J) tipografia: escala única, sem número solto")
		var tema: Theme = UiSkin.theme()
		check(tema != null and tema.default_font_size == Tipo.CORPO, "tema com o corpo em %d px" % Tipo.CORPO)
		check(Tipo.CORPO >= 12 and Tipo.DETALHE >= 12 and Tipo.DICA >= 12, "nada da interface abaixo de 12 px")
		check(hud._order_bar.theme == tema, "o tema chega no HUD (CanvasLayer)")
		var soltos := numeros_soltos()
		for s in soltos.slice(0, 6):
			print("    solto: ", s)
		check(soltos.is_empty(), "nenhum tamanho de letra solto no código (%d)" % soltos.size())

		print("== K) balões de motivo")
		var w: Array = ws()
		var parado: Node = null
		for x in w:
			if x.has_no_job() and not x.injured:
				parado = x
		_alvo = parado
		Ipe.baloes_motivo = true
		check(parado != null and parado.motivo_parado() == "sem_trabalho", "sem função parado: 'sem trabalho'")
		step = 4
		t_mark = t
		return false
	if step == 4 and t - t_mark > 3.0:
		step = 5
		var p: Node = _alvo
		check(p.motivo_no_balao() == "sem_trabalho", "o balão aparece depois de um tempo parado ('%s')" % p.motivo_no_balao())
		var bal: Sprite2D = p.get_node_or_null("BalaoMotivo")
		check(bal != null and bal.visible and bal.get_node("Icone").texture != null, "balão com o ícone")
		p.hunger = 1.0
		check(p.motivo_parado() == "sem_comida", "com fome e a cozinha vazia: 'sem comida'")
		p.hunger = p.hunger_max
		var guarda: Node = ws()[2]
		guarda.set_job("guarda")
		guarda.weapon = ""
		var def = g("defense")
		check(def.arsenal() != null or guarda.motivo_parado() == "sem_ferramenta", "guarda sem arma e sem Arsenal: 'sem ferramenta' ('%s', arsenal: %s)" % [guarda.motivo_parado(), def.arsenal()])
		var m: Node = ws()[0]
		m._moving = true
		m._stuck_stage = 1
		check(m.motivo_parado() == "caminho_bloqueado", "preso andando: 'caminho bloqueado'")
		m._stuck_stage = 0
		m._moving = false
		Ipe.baloes_motivo = false
		step = 6
		t_mark = t
		return false
	if step == 6 and t - t_mark > 1.2:
		step = 7
		check(_alvo.motivo_no_balao() == "", "desligado nas configurações: some")
		Ipe.baloes_motivo = true
		var nomes: Dictionary = Ipe.MOTIVO_ICONE
		var faltam: Array = nomes.values().filter(func(n): return preload("res://scripts/ui/icones.gd").tex(n) == null)
		check(nomes.size() == 5 and faltam.is_empty(), "os 5 motivos têm ícone (faltam: %s)" % str(faltam))
		print("\nFALHAS: %d" % fails)
		return true
	return false
