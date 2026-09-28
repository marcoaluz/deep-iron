extends PanelContainer
## Bloco 46: MENU DE CONSTRUÇÃO estilo Frostpunk (botão CONSTRUIR na barra de baixo ou
## barra de espaço). Abas por categoria; cada aba mostra os prédios como cartões com
## desenho, custo e o motivo quando não dá. Clicar em "Construir" chama o MESMO fluxo que
## já existia (escolher lugar + engenheiro) — o menu só junta tudo num lugar.
##
## Os limites de hoje continuam: o que só pode ter um (Arsenal, Laboratório, Taverna,
## Vestiário, Coletor…) mostra "um por vila"; o que pode ter vários (casas, comedouros,
## parques) mostra "pode ter vários". Itens do futuro aparecem como "em breve".

const TAB_NAMES := ["Moradia", "Alimentação", "Saúde", "Lazer", "Pesquisa", "Defesa e equipamento", "Coleta automática", "Vila"]

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


# ------------------------------------------------------------ o que tem em cada aba
## Cada item: name, tex, frames, desc, many (pode ter vários?), soon (em breve), cost(), reason(),
## act(), e opcional label (texto do botão) e "open" (abre uma janela em vez de construir).
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
			out.append({"name": "Casa nível 2 e 3", "tex": "casa", "frames": 3, "soon": true, "desc": "Casas maiores (mais camas)."})
			out.append({"name": "Escola", "tex": "", "soon": true, "desc": "Pra quando a vila tiver crianças."})
		"Alimentação":
			if hub:
				out.append({"name": "Comedouro", "tex": "comedouro", "frames": 3, "many": true,
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
					"act": func(): hub.buy_upgrade("enfermaria"), "label": "Ampliar"})
			out.append({"name": "Nova enfermaria", "tex": "enfermaria", "frames": 2, "soon": true, "desc": "Mais de uma enfermaria na vila."})
		"Lazer":
			if mor:
				out.append({"name": "Taverna", "tex": "taverna", "frames": 2,
					"desc": "Quem está triste vai lá se animar. Depois dá pra ampliar.",
					"cost": func(): return _taverna_cost(mor),
					"reason": func(): return mor.taverna_block_reason(),
					"act": func(): mor.build_or_upgrade_taverna(),
					"label_fn": func(): return "Construir" if mor.taverna() == null else "Ampliar"})
				out.append({"name": "Parque", "tex": "parque", "frames": 1, "many": true,
					"desc": "Ânimo aos pouquinhos pra quem passa perto.",
					"cost": func(): return "%d cr + %d %s + %d madeira" % [mor.park_credits, mor.park_ore, mor.park_ore_type, mor.park_wood],
					"reason": func(): return mor.park_block_reason(),
					"act": func(): mor.build_park()})
		"Pesquisa":
			if res:
				out.append({"name": "Laboratório", "tex": "laboratorio", "frames": 2,
					"desc": "Pesquisadores (tecla Z) geram pontos pra árvore de pesquisa.",
					"cost": func(): return "%d cr + %d ferro + %d madeira" % [res.lab_credits, res.lab_iron, res.lab_wood],
					"reason": func(): return "" if res.lab_block_reason() == "" else res.lab_block_reason(),
					"act": func(): res.build_lab()})
		"Defesa e equipamento":
			if def:
				out.append({"name": "Arsenal", "tex": "arsenal", "frames": 4,
					"desc": "Forja e conserta as armas dos guardas.",
					"cost": func(): return "%d cr + %d ferro + %d madeira" % [def.arsenal_credits, def.arsenal_ore, def.arsenal_wood],
					"reason": func(): return def.arsenal_block_reason(),
					"act": func(): def.build_arsenal()})
				out.append({"name": "Campo de treino", "tex": "campo_treino", "frames": 1,
					"desc": "Guardas treinam de dia e lutam melhor.",
					"cost": func(): return "%d cr + %d madeira" % [def.campo_credits, def.campo_wood],
					"reason": func(): return def.campo_block_reason(),
					"act": func(): def.build_campo()})
			if eq:
				out.append({"name": "Vestiário", "tex": "vestiario", "frames": 1,
					"desc": "Guarda casacos e trajes (a Oficina faz).",
					"cost": func(): return "%d cr + %d ferro + %d madeira" % [eq.vestiario_credits, eq.vestiario_ore, eq.vestiario_wood],
					"reason": func(): return eq.vestiario_block_reason(),
					"act": func(): eq.build_vestiario()})
			out.append({"name": "Oficina (forja)", "tex": "oficina", "frames": 2, "open": "oficina",
				"desc": "Ferramentas e equipamento. Já vem com a vila.",
				"cost": func(): return "",
				"reason": func(): return "",
				"act": func(): _hud.open_panel("oficina"), "label": "Abrir"})
		"Coleta automática":
			if hub:
				out.append({"name": "Coletor de madeira", "tex": "coletor_madeira", "frames": 2,
					"desc": "Serraria na clareira: um lenhador opera e ela faz madeira sozinha.",
					"cost": func(): return hub.coletor_cost_text(),
					"reason": func(): return hub.coletor_block_reason(),
					"act": func(): hub.build_coletor()})
			out.append({"name": "Coletor de minério", "tex": "", "soon": true, "desc": "Máquina que minera sozinha com um operador."})
		"Vila":
			if hub:
				out.append({"name": "Expandir a vila", "tex": "centro_vila", "frames": 5,
					"desc": "Próximo estágio (o Centro da Vila é um só). Abre galerias e aumenta o raio das casas.",
					"cost": func(): return ("%d cr" % hub.next_level_cost()) if hub.level < hub.max_level() else "",
					"reason": func(): return _expand_reason(hub),
					"act": func(): hub.level_up(), "label": "Expandir"})
				out.append({"name": "Trilhas batidas", "tex": "", "desc": "Todo mundo anda mais rápido.",
					"cost": func(): return _upgrade_cost_text(hub, "trilhas"),
					"reason": func(): return hub.upgrade_block_reason("trilhas"),
					"act": func(): hub.buy_upgrade("trilhas"), "label": "Melhorar"})
			if sun:
				out.append({"name": "Escudo solar", "tex": "escudo", "frames": 5,
					"desc": "O projeto final: protege a vila do sol pra sempre.",
					"cost": func(): return "pago por etapa, no gerador",
					"reason": func(): return sun.shield_block_reason(),
					"act": func(): sun.place_shield()})
	return out


func _taverna_cost(mor: Node) -> String:
	if mor.taverna() == null:
		return "%d cr + %d madeira" % [mor.taverna_credits, mor.taverna_wood]
	return "%d cr + %d madeira + %d %s" % [mor.taverna_up_credits, mor.taverna_up_wood, mor.taverna_up_ore, mor.taverna_up_ore_type]


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
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
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
	var name_l: Label = _hud._label(d.name, 14, _hud.COLOR_TEXT)
	v.add_child(name_l)
	var tag := "em breve" if d.get("soon", false) else ("pode ter vários" if d.get("many", false) else ("" if d.has("open") else "um por vila"))
	if tag != "":
		v.add_child(_hud._label(tag, 11, _hud.COLOR_DIM))
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
	return {"def": d, "status": status, "button": btn, "cost": cost}


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
		var ok := reason == ""
		c.status.text = "" if ok else reason
		c.button.disabled = not ok
		if d.has("label_fn"):
			c.button.text = d.label_fn.call()
