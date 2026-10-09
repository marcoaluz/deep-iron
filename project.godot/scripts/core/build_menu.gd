extends PanelContainer
## Bloco 46: MENU DE CONSTRUÇÃO estilo Frostpunk (botão CONSTRUIR na barra de baixo ou
## barra de espaço). Abas por categoria; cada aba mostra os prédios como cartões com
## desenho, custo e o motivo quando não dá. Clicar em "Construir" chama o MESMO fluxo que
## já existia (escolher lugar + engenheiro) — o menu só junta tudo num lugar.
##
## Bloco 47: o que pode ter vários mostra "pode ter vários • tem N" e, se o próximo custa
## mais (Economy.extra_building_cost_growth), o custo do cartão já é o do PRÓXIMO. O que
## continua único (Vestiário, Oficina, Centro da Vila, Escudo) mostra "um por vila";
## melhorias mostram "melhoria". Itens do futuro aparecem como "em breve".
##
## Bloco 95 (layout v2, partes B e D): a janela tem TAMANHO E LUGAR FIXOS (iguais em todas as abas, centrada
## entre a barra de cima e a de baixo, em px lógicos: cresce junto com a escala da interface). Os cartões têm
## um tamanho só, numa GRADE que quebra em linhas e rola só na vertical. O cartão tem estrutura fixa: imagem
## (sempre do mesmo tamanho e moldura), nome, etiqueta, descrição curta (o texto inteiro na dica), custo numa
## linha, requisito noutra (cadeado + motivo) e o botão no rodapé. Abas de largura igual em duas linhas.
## Esc fecha, ←/→ trocam de aba, a última aba fica lembrada (configurações). Todo cartão tem imagem (campo
## "img"); sem ela aparece um "?" e o teste b95b avisa.

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Settings := preload("res://scripts/core/settings.gd")
const TAB_NAMES := ["Moradia", "Alimentação", "Saúde", "Lazer", "Pesquisa", "Defesa e equipamento", "Coleta automática", "Produção", "Culto", "Decoração", "Vila"]
## Nome curto na aba (o inteiro vai na dica): a aba tem largura fixa.
const TAB_CURTO := {"Defesa e equipamento": "Defesa e equip."}
const DIR_PREDIOS := "res://assets/game/ui/icones/predios/"
const DIR_CARTOES := "res://assets/game/ui/icones/cartoes/"

## Tamanho MÁXIMO da janela (px lógicos). Ela usa o que couber entre a barra de cima e a de baixo (a 125% em
## 1280x720 a área é 1024x576), igual em todas as abas: só muda com a escala da interface ou a janela do jogo.
@export var janela_tamanho := Vector2(872, 560)
## Folga mínima entre a janela e as barras / as bordas (px lógicos).
@export var janela_folga := 8.0
## Tamanho de cada cartão (px lógicos). A altura cresce até caber a estrutura fixa na fonte de agora (_altura_cartao):
## todo cartão fica com a MESMA altura, e o botão no mesmo lugar.
@export var cartao_tamanho := Vector2(196, 238)
## Cartões por linha da grade.
@export var colunas := 4
## Abas por linha (11 abas = 2 linhas).
@export var abas_por_linha := 6
## Linhas da descrição no cartão (o resto vai na dica).
@export var desc_linhas := 3
## Área da imagem no topo do cartão (px lógicos; a imagem é 96x64 e fica 1:1 no meio).
@export var imagem_area := Vector2(180, 70)

var _hud: CanvasLayer
var _tabs_grid: GridContainer
var _cards_box: GridContainer
var _scroll: ScrollContainer
var _tab := 0
var _tab_buttons: Array[Button] = []
var _cards: Array = []  # [{def, root, status, button, cost, tag, panel, lock, img, locked}]
var _estilo_moldura: StyleBox


func setup(hud: CanvasLayer) -> void:
	_hud = hud
	add_to_group("menu_construir")
	_tab = clampi(int(Settings.get_value("hud", "construir_aba", 0)), 0, TAB_NAMES.size() - 1)
	_build()
	visible = false


func _g(group: String) -> Node:
	return get_tree().get_first_node_in_group(group)


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	# tamanho e lugar fixos: centrada na tela, um pouco acima do meio (entre as barras de cima e de baixo)
	set_anchors_preset(Control.PRESET_CENTER)
	_posiciona()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	var title: Label = _hud._label("CONSTRUIR", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	head.add_child(title)
	var instr: Label = _hud._label("Escolha o prédio e o lugar; o engenheiro (tecla 4) ergue.", Tipo.CORPO, _hud.COLOR_DIM)
	instr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	instr.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	instr.clip_text = true
	head.add_child(instr)
	var ajuda: Button = _hud._button("?")
	ajuda.custom_minimum_size = Vector2(28, 28)
	ajuda.tooltip_text = ("Escolha o prédio → escolha o lugar no mapa → um ENGENHEIRO (tecla 4) vai até lá e ergue.\n"
		+ "Decoração e caminhos são na hora, sem engenheiro.\n"
		+ "Cartão escuro com cadeado: ainda não dá (o motivo está embaixo). Custo com ⚠: falta recurso.\n"
		+ "←/→ trocam de aba  •  Esc fecha  •  a última aba fica lembrada.")
	head.add_child(ajuda)
	var close: Button = _hud._button("X")
	close.custom_minimum_size = Vector2(28, 28)
	close.tooltip_text = "Fechar (Esc / espaço)"
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	head.add_child(close)
	_tabs_grid = GridContainer.new()
	_tabs_grid.columns = abas_por_linha
	_tabs_grid.add_theme_constant_override("h_separation", 4)
	_tabs_grid.add_theme_constant_override("v_separation", 4)
	v.add_child(_tabs_grid)
	var larg_aba := floorf((tamanho().x - 32.0 - 4.0 * (abas_por_linha - 1)) / abas_por_linha)
	for i in TAB_NAMES.size():
		var nome: String = TAB_NAMES[i]
		var b: Button = _hud._button(TAB_CURTO.get(nome, nome))
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(larg_aba, 26)
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.tooltip_text = nome
		b.add_theme_font_size_override("font_size", Tipo.CORPO)
		if UiSkin.ok():
			UiSkin.aplica_aba(b)  # Prompt 20: aba de couro (a escolhida clara)
		b.add_theme_color_override("font_pressed_color", _hud.COLOR_TITLE)  # Bloco 95: a ativa bem destacada
		b.add_theme_color_override("font_hover_pressed_color", _hud.COLOR_TITLE)
		b.pressed.connect(func():
			Audio.click()
			_show_tab(i))
		_tabs_grid.add_child(b)
		_tab_buttons.append(b)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # Bloco 95: só na vertical
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_scroll)
	var centro := CenterContainer.new()  # a grade fica no meio da área (sobra igual dos dois lados)
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(centro)
	_cards_box = GridContainer.new()
	_cards_box.columns = colunas
	_cards_box.add_theme_constant_override("h_separation", 8)
	_cards_box.add_theme_constant_override("v_separation", 8)
	centro.add_child(_cards_box)
	var m := StyleBoxFlat.new()  # a moldura da imagem: fundo escuro e aro de ferro, igual em todo cartão
	m.bg_color = Color(0.07, 0.055, 0.045, 0.95)
	m.border_color = Color(0.36, 0.28, 0.2)
	m.set_border_width_all(1)
	m.set_content_margin_all(2)
	_estilo_moldura = m


## O tamanho da janela (Bloco 95): o máximo que cabe entre as barras, nunca maior que janela_tamanho. Não
## depende da aba (só da área lógica da tela, que muda com a escala da interface).
func tamanho() -> Vector2:
	var vis := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var topo: float = _hud.TOP_BAR_H if _hud else 40.0
	var base: float = _base_barra()
	var lado: float = (_hud.TIRA_W + _hud.SIDE_MARGIN * 2.0) if _hud else 50.0  # a aba fina e os alertas ficam de fora
	return Vector2(minf(janela_tamanho.x, vis.x - 2.0 * lado), minf(janela_tamanho.y, vis.y - topo - base - 2.0 * janela_folga)).floor()


## Altura reservada embaixo (a barra de funções e a margem). Antes de a barra se montar, a altura que ela terá.
func _base_barra() -> float:
	if _hud and _hud.get("_order_bar") and _hud._order_bar.size.y > 1.0:
		return _hud._order_bar.size.y + _hud.SIDE_MARGIN
	return 82.0


## Tamanho e lugar fixos (Bloco 95): o mesmo retângulo em todas as abas, centrado entre as duas barras.
func _posiciona() -> void:
	var vis := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var tam := tamanho()
	var topo: float = _hud.TOP_BAR_H if _hud else 40.0
	var meio_y := (topo + (vis.y - _base_barra())) * 0.5 - vis.y * 0.5  # o meio entre as duas barras, relativo ao centro
	custom_minimum_size = tam
	offset_left = -floorf(tam.x * 0.5)
	offset_right = offset_left + tam.x
	offset_top = floorf(meio_y - tam.y * 0.5)
	offset_bottom = offset_top + tam.y
	size = tam


func toggle() -> void:
	visible = not visible
	if visible:
		move_to_front()  # por cima dos painéis do lado (força de trabalho)
		_posiciona()
		_show_tab(_tab)


func _show_tab(i: int) -> void:
	_tab = clampi(i, 0, TAB_NAMES.size() - 1)
	Settings.set_value("hud", "construir_aba", _tab)
	for k in _tab_buttons.size():
		_tab_buttons[k].set_pressed_no_signal(k == _tab)
	for c in _cards_box.get_children():
		_cards_box.remove_child(c)
		c.queue_free()
	_cards.clear()
	for d in _defs(TAB_NAMES[_tab]):
		_cards.append(_make_card(d))
	_scroll.scroll_vertical = 0
	refresh()
	_posiciona()


## ←/→ trocam de aba com a janela aberta (a câmera não usa as setas enquanto isso: camera_controller).
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	var k: Key = event.physical_keycode
	if k == KEY_LEFT or k == KEY_RIGHT:
		Audio.click()
		_show_tab(posmod(_tab + (1 if k == KEY_RIGHT else -1), TAB_NAMES.size()))
		get_viewport().set_input_as_handled()


func _predio(nome: String) -> String:
	return DIR_PREDIOS + nome + ".png"


func _cartao(nome: String) -> String:
	return DIR_CARTOES + nome + ".png"


# ------------------------------------------------------------ o que tem em cada aba
## Cada item: name, img (a imagem do cartão: _predio(nome) = prédio pronto reduzido, _cartao(nome) = ilustração
## própria do Bloco 95), desc, many (pode ter vários?), soon (em breve), cost(), reason(),
## act(), e opcional label (texto do botão), "open" (abre uma janela em vez de construir),
## tag (etiqueta fixa), count() (quantos já tem) e scales (o próximo custa mais — Bloco 47).
func _defs(tab: String) -> Array:
	var hub := _g("village_hub")
	var mor := _g("morale")
	var res := _g("research")
	var def := _g("defense")
	var eq := _g("equipment")
	var sun := _g("sun")
	var out: Array = []
	match tab:
		"Moradia":
			if hub and hub.starter_houses_left > 0:
				out.append({"name": "Casa inicial", "img": _predio("casa"), "many": true,
					"desc": "Casa da fundação (4 camas). Não gasta nível de Moradias.",
					"cost": func(): return hub.starter_cost_text(),
					"reason": func(): return hub.starter_block_reason(),
					"act": func(): hub.build_starter_house()})
			if hub:
				out.append({"name": "Casa (Moradias)", "img": _predio("casa"), "many": true,
					"desc": "+%d no limite de ipezinhos e 4 camas. Só em volta do Centro da Vila." % hub.workers_per_moradia,
					"cost": func(): return _upgrade_cost_text(hub, "moradias"),
					"reason": func(): return hub.upgrade_block_reason("moradias"),
					"act": func(): hub.buy_upgrade("moradias")})
			out.append({"name": "Casa nível 2 e 3", "img": _predio("casa"), "many": true, "open": "casa", "label": "Ampliar uma casa",
				"desc": "Mais camas e conforto (ânimo de quem mora). Nível 2 pede a vila no estágio 2; nível 3, estágio 3 e a pesquisa de Medicina. Ou clique numa casa.",
				"cost": func(): return _casa_cost_text(),
				"reason": func(): return _casa_reason(),
				"act": func(): _hud.open_panel("casa")})
			out.append({"name": "Escola", "img": _cartao("escola"), "soon": true, "desc": "Pra quando a vila tiver crianças."})
		"Alimentação":
			if hub:
				out.append({"name": "Cozinha", "img": _predio("comedouro"), "many": true,
					"desc": "Onde a vila come. O cozinheiro enche.",
					"cost": func(): return hub.comedouro_cost_text(),
					"reason": func(): return hub.comedouro_block_reason(),
					"act": func(): hub.build_comedouro()})
		"Saúde":
			if hub:
				out.append({"name": "Ampliar Enfermaria", "img": _predio("enfermaria"),
					"desc": "+1 leito e cura mais rápida. (A enfermaria vem com a vila.)",
					"cost": func(): return _upgrade_cost_text(hub, "enfermaria"),
					"reason": func(): return hub.upgrade_block_reason("enfermaria"),
					"act": func(): hub.buy_upgrade("enfermaria"), "label": "Ampliar", "tag": "melhoria (vale pra todas)"})
				out.append({"name": "Nova enfermaria", "img": _predio("enfermaria"), "many": true, "scales": true,
					"desc": "Mais leitos em outro lugar. O médico vai pra que precisa; o memorial fica na principal.",
					"count": func(): return _count("enfermarias"),
					"cost": func(): return hub.enfermaria_cost_text(),
					"reason": func(): return hub.enfermaria_block_reason(),
					"act": func(): hub.build_enfermaria()})
		"Lazer":
			if mor:
				out.append({"name": "Taverna", "img": _predio("taverna"), "many": true, "scales": true,
					"desc": "Quem está triste vai lá se animar. Mais tavernas = mais lugares (o ânimo não soma).",
					"count": func(): return _count("tavernas"),
					"cost": func(): return mor.taverna_cost_text(),
					"reason": func(): return mor.taverna_build_reason(),
					"act": func(): mor.build_taverna()})
				out.append({"name": "Ampliar taverna", "img": _predio("taverna"), "tag": "melhoria",
					"desc": "+2 lugares e diversão mais rápida (a primeira taverna que ainda não está no máximo).",
					"cost": func(): return mor.taverna_up_cost_text(),
					"reason": func(): return mor.taverna_upgrade_reason(),
					"act": func(): mor.upgrade_taverna(), "label": "Ampliar"})
				out.append({"name": "Parque", "img": _predio("parque"), "many": true,
					"desc": "Ânimo aos pouquinhos pra quem passa perto.",
					"cost": func(): return "%d cr + %d %s + %d madeira" % [mor.park_credits, mor.park_ore, mor.park_ore_type, mor.park_wood],
					"reason": func(): return mor.park_block_reason(),
					"act": func(): mor.build_park()})
		"Pesquisa":
			if res:
				out.append({"name": "Laboratório", "img": _predio("laboratorio"), "many": true, "scales": true,
					"desc": "Pesquisadores (tecla Z) geram pontos. Todos os laboratórios somam na MESMA pesquisa.",
					"count": func(): return _count("laboratorios"),
					"cost": func(): return res.lab_cost_text(),
					"reason": func(): return res.lab_block_reason(),
					"act": func(): res.build_lab()})
		"Defesa e equipamento":
			if def:
				out.append({"name": "Arsenal", "img": _predio("arsenal"), "many": true, "scales": true,
					"desc": "Forja e conserta as armas. O 1º forja; os outros são postos de armas (guarda troca no mais perto).",
					"count": func(): return _count("arsenais"),
					"cost": func(): return def.arsenal_cost_text(),
					"reason": func(): return def.arsenal_block_reason(),
					"act": func(): def.build_arsenal()})
				out.append({"name": "Campo de treino", "img": _predio("campo_treino"), "many": true, "scales": true,
					"desc": "Guardas treinam de dia e lutam melhor. Mais campos = mais guardas treinando juntos.",
					"count": func(): return _count("campos"),
					"cost": func(): return def.campo_cost_text(),
					"reason": func(): return def.campo_block_reason(),
					"act": func(): def.build_campo()})
			var fundo := _g("fundo")
			if fundo:
				out.append({"name": "Ventilador (nível 2)", "img": _predio("ventilador"), "many": true,
					"desc": "Lá embaixo, no S2: em volta dele a máscara de gás gasta metade e o ácido das poças queima mais devagar. Afina a névoa verde.",
					"count": func(): return _count("ventiladores"),
					"cost": func(): return fundo.ventilador_cost_text(),
					"reason": func(): return fundo.ventilador_block_reason(),
					"act": func(): fundo.build_ventilador()})
			if eq:
				out.append({"name": "Vestiário", "img": _predio("vestiario"),
					"desc": "Guarda casacos e trajes (a Oficina faz). Um só: o estoque é da vila toda.",
					"cost": func(): return "%d cr + %d ferro + %d madeira" % [eq.vestiario_credits, eq.vestiario_ore, eq.vestiario_wood],
					"reason": func(): return eq.vestiario_block_reason(),
					"act": func(): eq.build_vestiario()})
			var ofi := _g("oficina")
			if ofi and ofi.has_method("is_built") and not ofi.is_built() and hub:
				out.append({"name": "Oficina (forja)", "img": _predio("oficina"), "tag": "uma só",
					"desc": "Ferramentas (liberam minérios novos) e equipamento. O engenheiro ergue.",
					"cost": func(): return hub.oficina_cost_text(),
					"reason": func(): return hub.oficina_block_reason(),
					"act": func(): hub.build_oficina()})
			else:
				out.append({"name": "Oficina (forja)", "img": _predio("oficina"), "open": "oficina", "tag": "construída (uma só)",
					"desc": "Ferramentas e equipamento.",
					"cost": func(): return "",
					"reason": func(): return "",
					"act": func(): _hud.open_panel("oficina"), "label": "Abrir"})
		"Coleta automática":
			if hub and hub.coletor_restaurado():  # Bloco 81: o primeiro é a ruína da floresta; extras só depois dela
				out.append({"name": "Coletor de madeira", "img": _predio("coletor_madeira"), "many": true, "scales": true,
					"desc": "Serraria na clareira: um lenhador opera e ela faz madeira sozinha. Cada uma tem o seu operador.",
					"count": func(): return _count("coletores"),
					"cost": func(): return hub.coletor_cost_text(),
					"reason": func(): return hub.coletor_block_reason(),
					"act": func(): hub.build_coletor()})
			if hub:
				out.append({"name": "Trilho e vagonete", "img": _cartao("vagonete"), "many": true, "scales": true,
					"desc": "Ponto de carga perto das jazidas e um trilho até o armazém: os mineradores entregam ali e o vagonete leva sozinho. O trilho gasta; quebrado, o engenheiro conserta.",
					"count": func(): return _count("pontos_carga"),
					"cost": func(): return hub.vagonete_cost_text(),
					"reason": func(): return hub.vagonete_block_reason(),
					"act": func(): hub.build_vagonete()})
				var prox: String = hub.ferrovia_proximo()  # Bloco 79
				out.append({"name": "Ferrovia de carga" + (" (%s)" % prox if prox != "" else ""), "img": _cartao("ferrovia"), "many": true, "scales": true,
					"desc": "Uma estação no andar (a ponta leste, perto do poço): os mineradores de lá entregam nela e o carrinho SOBE pelo cavalete até o armazém. Um andar de cada vez, de cima pra baixo; o trilho gasta e o engenheiro conserta.",
					"count": func(): return _count("ferrovias"),
					"cost": func(): return hub.ferrovia_cost_text(),
					"reason": func(): return hub.ferrovia_block_reason(),
					"act": func(): hub.build_ferrovia()})
				out.append({"name": "Coletor de minério", "img": _predio("coletor_minerio"), "many": true, "scales": true,
					"desc": "Broca a vapor perto de uma jazida: um minerador opera e ela manda minério do tipo da jazida pro armazém. Cada uma tem o seu operador.",
					"count": func(): return _count("coletores_minerio"),
					"cost": func(): return hub.coletor_minerio_cost_text(),
					"reason": func(): return hub.coletor_minerio_block_reason(),
					"act": func(): hub.build_coletor_minerio()})
		"Produção":  # Bloco 86: o que transforma (fornalha; o ferreiro no Bloco 87)
			if hub:
				out.append({"name": "Fornalha", "img": _predio("fornalha"), "many": true, "scales": true,
					"desc": "Funde minério em barra (ferro, cobre, prata, lingote solar; aço no estágio 3) — só por ordem, com quantidade. Opera: o FUNDIDOR.",
					"count": func(): return _count("fornalhas"),
					"cost": func(): return hub.fornalha_cost_text(),
					"reason": func(): return hub.fornalha_block_reason(),
					"act": func(): hub.build_fornalha()})
				out.append({"name": "Carpintaria", "img": _predio("carpintaria"), "many": true, "scales": true,  # Bloco 94
					"desc": "Madeira vira tábuas; tábuas e pregos viram camas de tábua (mais ânimo pra quem dorme nelas) — só por ordem, com quantidade. Opera: o CARPINTEIRO.",
					"count": func(): return _count("carpintarias"),
					"cost": func(): return hub.carpintaria_cost_text(),
					"reason": func(): return hub.carpintaria_block_reason(),
					"act": func(): hub.build_carpintaria()})
		"Decoração":  # Bloco 90: peças instantâneas (sem engenheiro), várias em sequência
			var dm := _g("decoracoes_mgr")
			if dm:
				for did in dm.Catalogo.CATALOGO:
					var info: Dictionary = dm.Catalogo.info(did)
					var extra: Array[String] = []
					if dm.Catalogo.tem_luz(did):
						extra.append("luz à noite (atrai Lumívoros)")
					if int(info.assentos) > 0:
						extra.append("%d lugares (hora social)" % int(info.assentos))
					extra.append("beleza %s" % str(info.beleza))
					out.append({"name": info.nome, "img": _cartao("decor_" + did), "many": true,
						"desc": "Instantâneo, sem engenheiro; ponha várias seguidas (Esc termina). " + ", ".join(extra) + ".",
						"cost": func(): return dm.custo_texto(did),
						"reason": func(): return dm.motivo(did),
						"act": func(): dm.comecar(did), "label": "Pôr"})
				out.append({"name": "Remover decoração", "img": _cartao("remover_decor"), "many": true,
					"desc": "Clique numa peça pra tirar (devolve %d%% do custo)." % roundi(dm.reembolso * 100.0),
					"cost": func(): return "",
					"reason": func(): return "",
					"act": func(): dm.comecar_remover(), "label": "Remover"})
		"Culto":  # Bloco 88: a igreja (missa, funeral, aconselhamento)
			if hub:  # Bloco 93: o cemitério (o jogador arrasta o tamanho; pode ter mais de um)
				out.append({"name": "Cemitério", "img": _predio("cemiterio"), "many": true,
					"tag": "%d construído%s" % [hub.cemiterios().size(), "" if hub.cemiterios().size() == 1 else "s"] if not hub.cemiterios().is_empty() else "você escolhe o tamanho",
					"desc": "Arraste no mapa o tamanho. Começa vazio: o padre traz quem se for e enterra (cruz ou lápide com o nome e o dia). Com a pesquisa Ritos fúnebres, o padre faz o funeral aqui e o ânimo sobe um pouco.",
					"cost": func(): return "por tamanho (%d cr + %d por vaga; ferro e madeira por trecho de cerca)" % [hub.cemiterio_credits_base, hub.cemiterio_credits_por_vaga],
					"reason": func(): return hub.cemiterio_block_reason(),
					"act": func(): hub.build_cemiterio(), "label": "Marcar"})
			if hub and hub.igreja() == null:
				out.append({"name": "Igreja", "img": _predio("igreja"), "tag": "uma só",
					"desc": "Missa no domingo (todos vão), funeral pra quem se for (alivia o luto) e o padre aconselha quem anda zangado. Também é ponto da hora social.",
					"cost": func(): return hub.igreja_cost_text(),
					"reason": func(): return hub.igreja_block_reason(),
					"act": func(): hub.build_igreja()})
			elif hub:
				out.append({"name": "Igreja", "img": _predio("igreja"), "open": "calendario", "tag": "construída (uma só)",
					"desc": "O calendário: missa, funerais, domingo à tarde e os festivais.",
					"cost": func(): return "",
					"reason": func(): return "",
					"act": func(): _hud.open_panel("calendario"), "label": "Abrir"})
		"Vila":
			var cam := _g("caminhos")
			if cam:  # Bloco 89: pintar caminhos (arrastar)
				for tp in ["terra", "cascalho", "pedra"]:
					out.append({"name": "Caminho: %s" % cam.NOMES[tp].to_lower(), "img": _cartao("cam_" + tp), "many": true,
						"desc": "Pinte arrastando no mapa (%s por célula). Quem anda nele fica %d%% mais rápido; as Trilhas aumentam isso. Não bloqueia ninguém." % [
							cam.custo_texto(tp), roundi(float(cam.bonus[tp]) * 100.0)],
						"cost": func(): return "%s / célula" % cam.custo_texto(tp),
						"reason": func(): return cam.motivo_pintar(tp),
						"act": func(): _g("caminho_placer").begin(tp), "label": "Pintar"})
				out.append({"name": "Apagar caminhos", "img": _cartao("apagar_caminho"), "many": true,
					"desc": "Arraste no mapa pra apagar caminho (não devolve o que custou).",
					"cost": func(): return "",
					"reason": func(): return "",
					"act": func(): _g("caminho_placer").begin("apagar"), "label": "Apagar"})
			if hub:
				# Bloco 97: o armazém novo (construção) e a ampliação (até o nível 3)
				out.append({"name": "Armazém novo", "img": _predio("armazem"), "many": true, "scales": true,
					"desc": "Mais espaço pra guardar (o armazém tem limite) e mais perto de onde se trabalha: quem trabalha perto entrega nele e o engenheiro busca material nele. Você escolhe o lugar.",
					"count": func(): return hub.armazens_novos().size(),
					"cost": func(): return hub.armazem_cost_text(),
					"reason": func(): return hub.armazem_block_reason(),
					"act": func(): hub.build_armazem()})
				out.append({"name": "Ampliar armazém", "img": _cartao("armazem_ampliar"), "tag": "melhoria (nível 2 e 3)",
					"desc": "Cabe mais: nível 1 = 400, nível 2 = 1000, nível 3 = 2000 (tudo junto). Amplia o armazém de menor nível; é obra de engenheiro com material.",
					"cost": func(): return _armazem_alvo().ampliar_custo_texto() if _armazem_alvo() else "",
					"reason": func(): return _armazem_alvo().ampliar_motivo() if _armazem_alvo() else "todos no nível máximo",
					"act": func(): _armazem_alvo().ampliar(), "label": "Ampliar"})
				out.append({"name": "Expandir a vila", "img": _predio("centro_vila"),
					"desc": "Próximo estágio (o Centro da Vila é um só). Abre galerias e aumenta o raio das casas.",
					"cost": func(): return ("%d cr" % hub.next_level_cost()) if hub.level < hub.max_level() else "",
					"reason": func(): return _expand_reason(hub),
					"act": func(): hub.level_up(), "label": "Expandir", "tag": "Centro da Vila: um só"})
				out.append({"name": "Desbravar o leste", "img": _cartao("desbravar"), "tag": "uma vez",
					"desc": "Abre a área nova do mapa: floresta, encosta rochosa e outra pedreira com mais jazidas. O engenheiro abre caminho na fronteira.",
					"cost": func(): return hub.leste_cost_text() if hub.leste_block_reason() != "já desbravado" else "",
					"reason": func(): return hub.leste_block_reason(),
					"act": func(): hub.desbravar_leste(), "label": "Desbravar"})
				out.append({"name": "Trilhas batidas", "img": _cartao("trilhas"), "desc": "Todo mundo anda mais rápido.",
					"cost": func(): return _upgrade_cost_text(hub, "trilhas"),
					"reason": func(): return hub.upgrade_block_reason("trilhas"),
					"act": func(): hub.buy_upgrade("trilhas"), "label": "Melhorar", "tag": "melhoria"})
				out.append({"name": "Posto de expedição", "img": _cartao("posto_expedicao"), "desc": "Duas expedições ao mesmo tempo (janela ;).",
					"cost": func(): return _upgrade_cost_text(hub, "posto"),
					"reason": func(): return hub.upgrade_block_reason("posto"),
					"act": func(): hub.buy_upgrade("posto"), "label": "Construir", "tag": "melhoria"})  # Bloco 104
			if sun:
				out.append({"name": "Escudo solar", "img": _predio("escudo"),
					"desc": "O projeto final: protege a vila do sol pra sempre.",
					"cost": func(): return "pago por etapa, no gerador",
					"reason": func(): return sun.shield_block_reason(),
					"act": func(): sun.place_shield()})
	return out


func _count(group: String) -> int:
	return get_tree().get_nodes_in_group(group).size()


## Etiqueta do cartão (Bloco 47: "pode ter vários • tem 2 • o próximo custa +50%").
func _tag_text(d: Dictionary) -> String:
	if d.get("soon", false):
		return "em breve"
	if d.has("tag"):
		return d.tag
	if not d.get("many", false):
		return "" if d.has("open") else "um por vila"
	var t := "pode ter vários"
	if d.has("count"):
		t += " • tem %d" % d.count.call()
	var eco := _g("economy")
	if d.get("scales", false) and eco and eco.extra_building_cost_growth != 1.0:
		t += " • o próximo custa %+d%%" % roundi((eco.extra_building_cost_growth - 1.0) * 100.0)
	return t


## Bloco 97: o armazém que o cartão amplia (o de menor nível que ainda sobe).
func _armazem_alvo() -> Node:
	var melhor: Node = null
	for a in get_tree().get_nodes_in_group("armazens"):
		if not a.has_method("ampliar") or a.nivel >= a.nivel_maximo():
			continue
		if melhor == null or a.nivel < melhor.nivel:
			melhor = a
	return melhor


## Bloco 56: a casa que o cartão amplia (a de menor nível que ainda sobe).
func _casa_alvo() -> Node:
	var melhor: Node = null
	for c in get_tree().get_nodes_in_group("casas"):
		if not c.built or not c.has_method("max_level") or c.level >= c.max_level() or c.upgrade_pending():
			continue
		if melhor == null or c.level < melhor.level:
			melhor = c
	return melhor


func _casa_cost_text() -> String:
	var c := _casa_alvo()
	return ("próxima: nível %d — %s" % [c.level + 1, c.upgrade_cost_text()]) if c else ""


func _casa_reason() -> String:
	var c := _casa_alvo()
	if c == null:
		return "nenhuma casa pra ampliar"
	return c.upgrade_block_reason()


func _expand_reason(hub: Node) -> String:
	if hub.can_level_up():
		return ""
	if hub.level >= hub.max_level():
		return "estágio máximo"
	if hub.pending_upgrade != "":
		return "obra em andamento"
	return "falta minério coletado ou créditos"


func _upgrade_cost_text(hub: Node, id: String) -> String:
	var c: Vector2i = hub.upgrade_cost(id)
	if c.x < 0:
		return ""
	var t := "%d cr" % c.x
	if c.y > 0:
		t += " + %d %s" % [c.y, hub.upgrade_ore_label(id)]
	var w: int = hub.upgrade_wood(id)
	if w > 0:
		t += " + %d madeira" % w
	return t


# ------------------------------------------------------------ cartões
## Imagem do cartão: o campo "img" do item (Bloco 95). Sem ela: null (o cartão mostra o "?").
func _imagem(d: Dictionary) -> Texture2D:
	var p: String = d.get("img", "")
	return load(p) if p != "" and ResourceLoader.exists(p) else null


## (Prompt 21) O desenho reduzido do prédio pelo nome — mantido pra quem ainda pede assim.
func _icon(name: String, frames: int) -> Texture2D:
	var novo := Icones.predio(name) if name != "" else null
	if novo != null:
		return novo
	if name == "" or not ResourceLoader.exists("res://assets/game/%s.png" % name):
		return null
	var tex: Texture2D = load("res://assets/game/%s.png" % name)
	var a := AtlasTexture.new()
	a.atlas = tex
	var w := tex.get_width() / maxi(frames, 1)
	a.region = Rect2(0, 0, w, tex.get_height())
	return a


## Uma linha fixa do cartão: ícone pequeno + texto (custo, requisito). Ocupa a altura mesmo vazia: o botão
## fica no mesmo lugar em todos os cartões.
func _linha(icone: String, cor: Color, linhas := 1) -> Dictionary:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := TextureRect.new()
	ic.texture = Icones.tex(icone, true) if icone != "" else null
	ic.custom_minimum_size = Vector2(16, 16)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	var l: Label = _hud._label("", Tipo.DETALHE, cor)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if linhas > 1 else TextServer.AUTOWRAP_OFF
	l.max_lines_visible = linhas
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = linhas == 1
	l.custom_minimum_size = Vector2(1, _altura_linhas(Tipo.DETALHE, linhas))
	h.add_child(l)
	return {"box": h, "icone": ic, "label": l}


## Altura de n linhas de texto (com o espaço entre linhas que o Label soma quando quebra).
func _altura_linhas(tam: int, n: int) -> float:
	var f: Font = get_theme_default_font() if get_theme_default_font() else ThemeDB.fallback_font
	var entre := float(get_theme_constant("line_spacing", "Label"))
	return ceilf(f.get_height(tam)) * n + entre * maxi(n - 1, 0)


## A altura que a estrutura fixa do cartão pede (imagem, nome, etiqueta, descrição, custo, requisito, botão),
## mais a moldura: a mesma pra todos (nenhum cartão cresce sozinho por causa do texto).
func _altura_cartao() -> float:
	var sb: StyleBox = UiSkin.cartao("") if UiSkin.ok() else _hud._row_style(false)
	var h := imagem_area.y + 4.0  # (a moldura da imagem)
	h += _altura_linhas(Tipo.TITULO, 1) + _altura_linhas(Tipo.DETALHE, 1 + desc_linhas)
	h += maxf(_altura_linhas(Tipo.DETALHE, 1), 16.0) + maxf(_altura_linhas(Tipo.DETALHE, 2), 16.0)
	h += 26.0 + 3.0 * 6.0 + sb.get_minimum_size().y + 4.0  # botão, separações, moldura e folga
	return maxf(cartao_tamanho.y, ceilf(h))


func _make_card(d: Dictionary) -> Dictionary:
	var soon: bool = d.get("soon", false)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.cartao("breve" if soon else "") if UiSkin.ok() else _hud._row_style(false))
	panel.custom_minimum_size = Vector2(cartao_tamanho.x, _altura_cartao())
	panel.size = panel.custom_minimum_size
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_PASS  # pra ter dica (o texto inteiro)
	panel.tooltip_text = "%s\n%s" % [d.name, d.get("desc", "")]
	_cards_box.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	# 1) a imagem: área fixa com fundo e moldura (a imagem 96x64 fica 1:1, no meio)
	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", _estilo_moldura)
	moldura.custom_minimum_size = imagem_area
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(moldura)
	var tex := _imagem(d)
	var img := TextureRect.new()
	img.texture = tex
	img.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(img)
	if tex == null:  # Bloco 95: placeholder claro (o teste b95b lista quem está sem imagem)
		var q: Label = _hud._label("?  sem imagem", Tipo.CORPO, Color(1.0, 0.6, 0.3))
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		moldura.add_child(q)
	var lock := TextureRect.new()  # Prompt 20: cadeado no canto da imagem do cartão trancado
	lock.texture = UiSkin.tex("cadeado")
	lock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lock.offset_left = -30.0
	lock.offset_top = 2.0
	lock.offset_bottom = 38.0
	lock.offset_right = -2.0
	lock.visible = false
	img.add_child(lock)  # (filho do desenho: a moldura é um container e esticaria o cadeado)
	# 2) nome (1 linha) e 3) etiqueta (1 linha)
	var name_l: Label = _hud._label(d.name, Tipo.TITULO, _hud.COLOR_TEXT)
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.clip_text = true
	v.add_child(name_l)
	var tag: Label = _hud._label(_tag_text(d), Tipo.DETALHE, _hud.COLOR_DIM)
	tag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tag.clip_text = true
	tag.custom_minimum_size.y = _altura_linhas(Tipo.DETALHE, 1)
	v.add_child(tag)
	# 4) descrição curta (até desc_linhas; o texto inteiro na dica do cartão)
	var desc: Label = _hud._label(d.get("desc", ""), Tipo.DETALHE, Color(0.78, 0.74, 0.68))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.max_lines_visible = desc_linhas
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.custom_minimum_size = Vector2(1, _altura_linhas(Tipo.DETALHE, desc_linhas))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	# 5) custo e 6) requisito: cada um na sua linha, com ícone (não depende só da cor)
	var cost := _linha("creditos", _hud.COLOR_TITLE)
	v.add_child(cost.box)
	var req := _linha("", Color(1.0, 0.86, 0.6), 2)
	v.add_child(req.box)
	# 7) o botão no rodapé (último da coluna: sempre no mesmo lugar, o cartão tem altura fixa)
	var btn: Button = _hud._button(d.get("label", "Construir"))
	btn.add_theme_font_size_override("font_size", Tipo.CORPO)
	btn.custom_minimum_size.y = 26
	v.add_child(btn)
	if soon:
		btn.text = "Em breve"
		btn.disabled = true
		img.modulate = Color(0.45, 0.42, 0.4)
	else:
		btn.pressed.connect(func():
			Audio.click()
			if not d.has("open"):
				visible = false  # o posicionador assume
			d.act.call()
			if visible:
				refresh())
	return {"def": d, "status": req.label, "req": req, "button": btn, "cost": cost.label, "custo": cost, "tag": tag,
		"panel": panel, "lock": lock, "img": img, "locked": null, "estado": ""}


## Estado do cartão (Bloco 95): "" = dá pra construir; "falta" = sem recurso (o custo que falta em destaque,
## a imagem normal); "bloq" = trancado por estágio/pesquisa/obra (cinza, imagem escura, cadeado + motivo).
func _estado(reason: String) -> String:
	if reason == "":
		return ""
	return "falta" if reason.begins_with("falta") else "bloq"


func refresh() -> void:
	if not visible:
		return
	for c in _cards:
		var d: Dictionary = c.def
		if d.get("soon", false):
			c.status.text = ""
			c.cost.text = ""
			c.req.icone.visible = false
			c.custo.icone.visible = false
			continue
		var reason: String = d.reason.call()
		var custo_txt: String = d.cost.call()
		if c.cost.text != custo_txt:
			c.cost.text = custo_txt
		c.custo.icone.visible = custo_txt != ""
		c.cost.tooltip_text = custo_txt
		c.tag.text = _tag_text(d)  # Bloco 47: "tem N" muda quando constrói
		var est := _estado(reason)
		c.status.text = reason
		c.button.disabled = est != ""
		if c.estado != est:
			c.estado = est
			c.req.icone.visible = est != ""
			c.req.icone.texture = UiSkin.tex("cadeado") if est == "bloq" else Icones.tex("p_alerta")
			c.status.add_theme_color_override("font_color", Color(0.86, 0.82, 0.76) if est == "bloq" else Color(1.0, 0.86, 0.5))
			c.cost.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5) if est == "falta" else _hud.COLOR_TITLE)
			c.img.modulate = Color(0.38, 0.36, 0.35) if est == "bloq" else Color.WHITE  # trancado: imagem escura
			if UiSkin.ok():  # Prompt 20: trancado = cartão escuro + cadeado
				c.panel.add_theme_stylebox_override("panel", UiSkin.cartao("bloq" if est == "bloq" else ""))
			c.lock.visible = est == "bloq"
			c.locked = est != ""
		if d.has("label_fn"):
			c.button.text = d.label_fn.call()


## Bloco 95 (teste e capturas): o retângulo da janela e se algum cartão sai da área visível ou da largura.
func diagnostico() -> Dictionary:
	var area := _scroll.get_global_rect()
	var fora: Array[String] = []
	for c in _cards:
		var r: Rect2 = c.panel.get_global_rect()
		if r.position.x < area.position.x - 0.5 or r.end.x > area.end.x + 0.5:
			fora.append(c.def.name)
	var sem_img: Array[String] = []
	for c in _cards:
		if c.img.texture == null:
			sem_img.append(c.def.name)
	return {"rect": get_global_rect(), "area": area, "fora": fora, "sem_imagem": sem_img,
		"rolagem_h": _scroll.get_h_scroll_bar().visible, "conteudo": _cards_box.get_combined_minimum_size()}
