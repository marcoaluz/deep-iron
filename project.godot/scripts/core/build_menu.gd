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

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const TAB_NAMES := ["Moradia", "Alimentação", "Saúde", "Lazer", "Pesquisa", "Defesa e equipamento", "Coleta automática", "Produção", "Vila"]

var _hud: CanvasLayer
var _tabs_row: HBoxContainer
var _cards_box: HBoxContainer
var _tab := 0
var _tab_buttons: Array[Button] = []
var _cards: Array = []  # [{def, root, status, button, cost}]


func setup(hud: CanvasLayer) -> void:
	_hud = hud
	_build()
	visible = false


func _g(group: String) -> Node:
	return get_tree().get_first_node_in_group(group)


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -126.0  # logo acima da barra de funções
	custom_minimum_size = Vector2(860, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title: Label = _hud._label("CONSTRUIR", 18, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_hud._label("escolha o prédio → escolha o lugar → o engenheiro (tecla 4) ergue", 12, _hud.COLOR_DIM))
	var close: Button = _hud._button("X")
	close.tooltip_text = "Fechar (Esc / espaço)"
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	head.add_child(close)
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 4)
	v.add_child(_tabs_row)
	for i in TAB_NAMES.size():
		var b: Button = _hud._button(TAB_NAMES[i])
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 12)
		if UiSkin.ok():
			UiSkin.aplica_aba(b)  # Prompt 20: aba de couro (a escolhida clara)
		b.pressed.connect(func():
			Audio.click()
			_show_tab(i))
		_tabs_row.add_child(b)
		_tab_buttons.append(b)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 196)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_cards_box)


func toggle() -> void:
	visible = not visible
	if visible:
		move_to_front()  # por cima dos painéis do lado (força de trabalho)
		_show_tab(_tab)


func _show_tab(i: int) -> void:
	_tab = i
	for k in _tab_buttons.size():
		_tab_buttons[k].set_pressed_no_signal(k == i)
	for c in _cards_box.get_children():
		c.queue_free()
	_cards.clear()
	for d in _defs(TAB_NAMES[i]):
		_cards.append(_make_card(d))
	refresh()
	_encolhe.call_deferred()


## Prompt 20: o painel só cresce sozinho (texto quebrando no 1º quadro o deixava enorme): volta pro
## tamanho do conteúdo, preso em cima da barra de funções.
func _encolhe() -> void:
	reset_size()
	offset_left = -size.x * 0.5
	offset_right = size.x * 0.5
	offset_top = -126.0 - size.y
	offset_bottom = -126.0


# ------------------------------------------------------------ o que tem em cada aba
## Cada item: name, tex, frames, desc, many (pode ter vários?), soon (em breve), cost(), reason(),
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
				out.append({"name": "Casa inicial", "tex": "casa", "frames": 3, "many": true,
					"desc": "Casa da fundação (4 camas). Não gasta nível de Moradias.",
					"cost": func(): return hub.starter_cost_text(),
					"reason": func(): return hub.starter_block_reason(),
					"act": func(): hub.build_starter_house()})
			if hub:
				out.append({"name": "Casa (Moradias)", "tex": "casa", "frames": 3, "many": true,
					"desc": "+%d no limite de ipezinhos e 4 camas. Só em volta do Centro da Vila." % hub.workers_per_moradia,
					"cost": func(): return _upgrade_cost_text(hub, "moradias"),
					"reason": func(): return hub.upgrade_block_reason("moradias"),
					"act": func(): hub.buy_upgrade("moradias")})
			out.append({"name": "Casa nível 2 e 3", "tex": "casa", "frames": 3, "many": true, "open": "casa", "label": "Ampliar uma casa",
				"desc": "Mais camas e conforto (ânimo de quem mora). Nível 2 pede a vila no estágio 2; nível 3, estágio 3 e a pesquisa de Medicina. Ou clique numa casa.",
				"cost": func(): return _casa_cost_text(),
				"reason": func(): return _casa_reason(),
				"act": func(): _hud.open_panel("casa")})
			out.append({"name": "Escola", "tex": "", "soon": true, "desc": "Pra quando a vila tiver crianças."})
		"Alimentação":
			if hub:
				out.append({"name": "Cozinha", "tex": "comedouro", "frames": 3, "many": true,
					"desc": "Onde a vila come. O cozinheiro enche.",
					"cost": func(): return hub.comedouro_cost_text(),
					"reason": func(): return hub.comedouro_block_reason(),
					"act": func(): hub.build_comedouro()})
		"Saúde":
			if hub:
				out.append({"name": "Ampliar Enfermaria", "tex": "enfermaria", "frames": 2,
					"desc": "+1 leito e cura mais rápida. (A enfermaria vem com a vila.)",
					"cost": func(): return _upgrade_cost_text(hub, "enfermaria"),
					"reason": func(): return hub.upgrade_block_reason("enfermaria"),
					"act": func(): hub.buy_upgrade("enfermaria"), "label": "Ampliar", "tag": "melhoria (vale pra todas)"})
				out.append({"name": "Nova enfermaria", "tex": "enfermaria", "frames": 2, "many": true, "scales": true,
					"desc": "Mais leitos em outro lugar. O médico vai pra que precisa; o memorial fica na principal.",
					"count": func(): return _count("enfermarias"),
					"cost": func(): return hub.enfermaria_cost_text(),
					"reason": func(): return hub.enfermaria_block_reason(),
					"act": func(): hub.build_enfermaria()})
		"Lazer":
			if mor:
				out.append({"name": "Taverna", "tex": "taverna", "frames": 2, "many": true, "scales": true,
					"desc": "Quem está triste vai lá se animar. Mais tavernas = mais lugares (o ânimo não soma).",
					"count": func(): return _count("tavernas"),
					"cost": func(): return mor.taverna_cost_text(),
					"reason": func(): return mor.taverna_build_reason(),
					"act": func(): mor.build_taverna()})
				out.append({"name": "Ampliar taverna", "tex": "taverna", "frames": 2, "tag": "melhoria",
					"desc": "+2 lugares e diversão mais rápida (a primeira taverna que ainda não está no máximo).",
					"cost": func(): return mor.taverna_up_cost_text(),
					"reason": func(): return mor.taverna_upgrade_reason(),
					"act": func(): mor.upgrade_taverna(), "label": "Ampliar"})
				out.append({"name": "Parque", "tex": "parque", "frames": 1, "many": true,
					"desc": "Ânimo aos pouquinhos pra quem passa perto.",
					"cost": func(): return "%d cr + %d %s + %d madeira" % [mor.park_credits, mor.park_ore, mor.park_ore_type, mor.park_wood],
					"reason": func(): return mor.park_block_reason(),
					"act": func(): mor.build_park()})
		"Pesquisa":
			if res:
				out.append({"name": "Laboratório", "tex": "laboratorio", "frames": 2, "many": true, "scales": true,
					"desc": "Pesquisadores (tecla Z) geram pontos. Todos os laboratórios somam na MESMA pesquisa.",
					"count": func(): return _count("laboratorios"),
					"cost": func(): return res.lab_cost_text(),
					"reason": func(): return res.lab_block_reason(),
					"act": func(): res.build_lab()})
		"Defesa e equipamento":
			if def:
				out.append({"name": "Arsenal", "tex": "arsenal", "frames": 4, "many": true, "scales": true,
					"desc": "Forja e conserta as armas. O 1º forja; os outros são postos de armas (guarda troca no mais perto).",
					"count": func(): return _count("arsenais"),
					"cost": func(): return def.arsenal_cost_text(),
					"reason": func(): return def.arsenal_block_reason(),
					"act": func(): def.build_arsenal()})
				out.append({"name": "Campo de treino", "tex": "campo_treino", "frames": 1, "many": true, "scales": true,
					"desc": "Guardas treinam de dia e lutam melhor. Mais campos = mais guardas treinando juntos.",
					"count": func(): return _count("campos"),
					"cost": func(): return def.campo_cost_text(),
					"reason": func(): return def.campo_block_reason(),
					"act": func(): def.build_campo()})
			var fundo := _g("fundo")
			if fundo:
				out.append({"name": "Ventilador (nível 2)", "tex": "ventilador", "frames": 1, "many": true,
					"desc": "Lá embaixo, no S2: em volta dele a máscara de gás gasta metade e o ácido das poças queima mais devagar. Afina a névoa verde.",
					"count": func(): return _count("ventiladores"),
					"cost": func(): return fundo.ventilador_cost_text(),
					"reason": func(): return fundo.ventilador_block_reason(),
					"act": func(): fundo.build_ventilador()})
			if eq:
				out.append({"name": "Vestiário", "tex": "vestiario", "frames": 1,
					"desc": "Guarda casacos e trajes (a Oficina faz). Um só: o estoque é da vila toda.",
					"cost": func(): return "%d cr + %d ferro + %d madeira" % [eq.vestiario_credits, eq.vestiario_ore, eq.vestiario_wood],
					"reason": func(): return eq.vestiario_block_reason(),
					"act": func(): eq.build_vestiario()})
			var ofi := _g("oficina")
			if ofi and ofi.has_method("is_built") and not ofi.is_built() and hub:
				out.append({"name": "Oficina (forja)", "tex": "oficina", "frames": 2, "tag": "uma só",
					"desc": "Ferramentas (liberam minérios novos) e equipamento. O engenheiro ergue.",
					"cost": func(): return hub.oficina_cost_text(),
					"reason": func(): return hub.oficina_block_reason(),
					"act": func(): hub.build_oficina()})
			else:
				out.append({"name": "Oficina (forja)", "tex": "oficina", "frames": 2, "open": "oficina", "tag": "construída (uma só)",
					"desc": "Ferramentas e equipamento.",
					"cost": func(): return "",
					"reason": func(): return "",
					"act": func(): _hud.open_panel("oficina"), "label": "Abrir"})
		"Coleta automática":
			if hub and hub.coletor_restaurado():  # Bloco 81: o primeiro é a ruína da floresta; extras só depois dela
				out.append({"name": "Coletor de madeira", "tex": "coletor_madeira", "frames": 2, "many": true, "scales": true,
					"desc": "Serraria na clareira: um lenhador opera e ela faz madeira sozinha. Cada uma tem o seu operador.",
					"count": func(): return _count("coletores"),
					"cost": func(): return hub.coletor_cost_text(),
					"reason": func(): return hub.coletor_block_reason(),
					"act": func(): hub.build_coletor()})
			if hub:
				out.append({"name": "Trilho e vagonete", "tex": "", "many": true, "scales": true,
					"desc": "Ponto de carga perto das jazidas e um trilho até o armazém: os mineradores entregam ali e o vagonete leva sozinho. O trilho gasta; quebrado, o engenheiro conserta.",
					"count": func(): return _count("pontos_carga"),
					"cost": func(): return hub.vagonete_cost_text(),
					"reason": func(): return hub.vagonete_block_reason(),
					"act": func(): hub.build_vagonete()})
				var prox: String = hub.ferrovia_proximo()  # Bloco 79
				out.append({"name": "Ferrovia de carga" + (" (%s)" % prox if prox != "" else ""), "tex": "", "many": true, "scales": true,
					"desc": "Uma estação no andar (a ponta leste, perto do poço): os mineradores de lá entregam nela e o carrinho SOBE pelo cavalete até o armazém. Um andar de cada vez, de cima pra baixo; o trilho gasta e o engenheiro conserta.",
					"count": func(): return _count("ferrovias"),
					"cost": func(): return hub.ferrovia_cost_text(),
					"reason": func(): return hub.ferrovia_block_reason(),
					"act": func(): hub.build_ferrovia()})
				out.append({"name": "Coletor de minério", "tex": "coletor_minerio", "frames": 2, "many": true, "scales": true,
					"desc": "Broca a vapor perto de uma jazida: um minerador opera e ela manda minério do tipo da jazida pro armazém. Cada uma tem o seu operador.",
					"count": func(): return _count("coletores_minerio"),
					"cost": func(): return hub.coletor_minerio_cost_text(),
					"reason": func(): return hub.coletor_minerio_block_reason(),
					"act": func(): hub.build_coletor_minerio()})
		"Produção":  # Bloco 86: o que transforma (fornalha; o ferreiro no Bloco 87)
			if hub:
				out.append({"name": "Fornalha", "tex": "fornalha", "frames": 2, "many": true, "scales": true,
					"desc": "Funde minério em barra (ferro, cobre, prata, lingote solar; aço no estágio 3) — só por ordem, com quantidade. Opera: o FUNDIDOR.",
					"count": func(): return _count("fornalhas"),
					"cost": func(): return hub.fornalha_cost_text(),
					"reason": func(): return hub.fornalha_block_reason(),
					"act": func(): hub.build_fornalha()})
		"Vila":
			if hub:
				out.append({"name": "Expandir a vila", "tex": "centro_vila", "frames": 5,
					"desc": "Próximo estágio (o Centro da Vila é um só). Abre galerias e aumenta o raio das casas.",
					"cost": func(): return ("%d cr" % hub.next_level_cost()) if hub.level < hub.max_level() else "",
					"reason": func(): return _expand_reason(hub),
					"act": func(): hub.level_up(), "label": "Expandir", "tag": "Centro da Vila: um só"})
				out.append({"name": "Desbravar o leste", "tex": "", "tag": "uma vez",
					"desc": "Abre a área nova do mapa: floresta, encosta rochosa e outra pedreira com mais jazidas. O engenheiro abre caminho na fronteira.",
					"cost": func(): return hub.leste_cost_text() if hub.leste_block_reason() != "já desbravado" else "",
					"reason": func(): return hub.leste_block_reason(),
					"act": func(): hub.desbravar_leste(), "label": "Desbravar"})
				out.append({"name": "Trilhas batidas", "tex": "", "desc": "Todo mundo anda mais rápido.",
					"cost": func(): return _upgrade_cost_text(hub, "trilhas"),
					"reason": func(): return hub.upgrade_block_reason("trilhas"),
					"act": func(): hub.buy_upgrade("trilhas"), "label": "Melhorar", "tag": "melhoria"})
			if sun:
				out.append({"name": "Escudo solar", "tex": "escudo", "frames": 5,
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
func _icon(name: String, frames: int) -> Texture2D:
	var novo := Icones.predio(name) if name != "" else null
	if novo != null:
		return novo  # Prompt 21: render reduzido do prédio pronto (arte nova)
	if name == "" or not ResourceLoader.exists("res://assets/game/%s.png" % name):
		return null
	var tex: Texture2D = load("res://assets/game/%s.png" % name)
	var a := AtlasTexture.new()
	a.atlas = tex
	var w := tex.get_width() / maxi(frames, 1)
	a.region = Rect2(0, 0, w, tex.get_height())
	return a


func _make_card(d: Dictionary) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.cartao("breve" if d.get("soon", false) else "") if UiSkin.ok() else _hud._row_style(false))
	panel.custom_minimum_size = Vector2(190, 186)
	_cards_box.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	var icon := TextureRect.new()
	icon.texture = _icon(d.get("tex", ""), d.get("frames", 1))
	icon.custom_minimum_size = Vector2(0, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if d.get("soon", false):
		icon.modulate = Color(1, 1, 1, 0.35)
	v.add_child(icon)
	var lock := TextureRect.new()  # Prompt 20: cadeado no canto do cartão trancado
	lock.texture = UiSkin.tex("cadeado")
	lock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.anchor_left = 1.0
	lock.anchor_right = 1.0
	lock.offset_left = -30.0
	lock.offset_bottom = 38.0
	lock.visible = false
	icon.add_child(lock)  # (filho do desenho: o cartão é um container e esticaria o cadeado)
	var name_l: Label = _hud._label(d.name, 14, _hud.COLOR_TEXT)
	v.add_child(name_l)
	var tag: Label = _hud._label(_tag_text(d), 11, _hud.COLOR_DIM)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = 176
	tag.visible = tag.text != ""
	v.add_child(tag)
	var desc: Label = _hud._label(d.get("desc", ""), 11, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 176
	v.add_child(desc)
	var cost: Label = _hud._label("", 11, _hud.COLOR_TITLE)
	cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost.custom_minimum_size.x = 176
	v.add_child(cost)
	var status: Label = _hud._label("", 11, _hud.COLOR_HUNGER_BAD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 176
	v.add_child(status)
	var btn: Button = _hud._button(d.get("label", "Construir"))
	btn.add_theme_font_size_override("font_size", 12)
	v.add_child(btn)
	if d.get("soon", false):
		btn.text = "Em breve"
		btn.disabled = true
	else:
		btn.pressed.connect(func():
			Audio.click()
			if not d.has("open"):
				visible = false  # o posicionador assume
			d.act.call()
			if visible:
				refresh())
	return {"def": d, "status": status, "button": btn, "cost": cost, "tag": tag, "panel": panel, "lock": lock, "locked": null}


func refresh() -> void:
	if not visible:
		return
	for c in _cards:
		var d: Dictionary = c.def
		if d.get("soon", false):
			c.status.text = ""
			c.cost.text = ""
			continue
		var reason: String = d.reason.call()
		c.cost.text = d.cost.call()
		c.tag.text = _tag_text(d)  # Bloco 47: "tem N" muda quando constrói
		var ok := reason == ""
		c.status.text = "" if ok else reason
		c.button.disabled = not ok
		if UiSkin.ok() and c.locked != (not ok):  # Prompt 20: trancado = cartão escuro + cadeado
			c.locked = not ok
			c.panel.add_theme_stylebox_override("panel", UiSkin.cartao("bloq" if not ok else ""))
			c.lock.visible = not ok
		if d.has("label_fn"):
			c.button.text = d.label_fn.call()
