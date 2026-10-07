extends PanelContainer
## Janela do Laboratório (tecla Q, ou clique no laboratório): a árvore de pesquisa.
## Cada ramo em uma coluna; os pares do 2º nível são escolhas (pesquisar um tranca o outro).

const Icones := preload("res://scripts/ui/icones.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const BRANCHES := [["Mina", ["carrinhos", "explosivos", "escoramento", "trajes", "ventilacao", "bombas"]],
	["Vila", ["medicina", "radio", "hidroponia"]],
	["Sol", ["estudo_solar", "satelite", "holofotes", "escudo"]]]

var _hud: CanvasLayer
var _res: Node
var _status: Label
var _bar: ProgressBar
var _lab_button: Button
var _cards: Dictionary = {}  # id -> {status, button, panel}


func setup(hud: CanvasLayer, res: Node, _economy: Node) -> void:
	_hud = hud
	_res = res
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(920, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("LABORATÓRIO — PESQUISA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_status = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)
	_bar = _hud._bar(_hud.COLOR_HUNGER_OK)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.max_value = 1.0
	vbox.add_child(_bar)
	_lab_button = _hud._button("")
	_lab_button.pressed.connect(func():
		Audio.click()
		_res.build_lab()
		refresh())
	vbox.add_child(_lab_button)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	vbox.add_child(cols)
	for b in BRANCHES:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.custom_minimum_size.x = 295
		cols.add_child(col)
		col.add_child(_hud._label("RAMO: %s" % b[0].to_upper(), Tipo.DETALHE, _hud.COLOR_DIM))
		for id in b[1]:
			_cards[id] = _make_card(col, id)


func _make_card(parent: VBoxContainer, id: String) -> Dictionary:
	var t: Dictionary = _res.TECHS[id]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var ic := Icones.tex("pq_" + id)
	if ic:  # Prompt 21: o ícone da tecnologia
		var tr := TextureRect.new()
		tr.texture = ic
		tr.custom_minimum_size = Vector2(32, 32)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(tr)
	var excl: String = "  (escolha)" if t.excl != "" else ""
	var name_label: Label = _hud._label(t.name + excl, Tipo.CORPO, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var button: Button = _hud._button("Pesquisar")
	button.add_theme_font_size_override("font_size", Tipo.DETALHE)
	button.pressed.connect(func():
		Audio.click()
		_res.start(id)
		refresh())
	top.add_child(button)
	var desc: Label = _hud._label(t.desc, Tipo.DETALHE, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 280
	v.add_child(desc)
	var status: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 280
	v.add_child(status)
	return {"status": status, "button": button, "panel": panel}


func refresh() -> void:
	if not visible:
		return
	var n: int = _res.researchers().size()
	var lab: Node = _res.lab()
	var lab_reason: String = _res.lab_block_reason()
	# Bloco 47: pode ter vários (somam na mesma pesquisa; o próximo custa mais)
	var n_labs: int = _res.labs().size()
	var lab_what := "laboratório" if lab == null else "outro laboratório (tem %d: mais vagas pra pesquisador)" % n_labs
	_lab_button.text = ("Construir %s — escolher lugar (%s)" % [lab_what, _res.lab_cost_text()]) \
		if lab_reason == "" else "Laboratório: " + lab_reason
	_lab_button.disabled = lab_reason != ""
	if _res.current != "":
		_status.text = "Pesquisando: %s — %d%%  •  %d pesquisador%s (tecla Z faz pesquisador)" % [
			_res.TECHS[_res.current].name, roundi(_res.current_progress() * 100.0), n, "es" if n != 1 else ""]
	else:
		_status.text = "Nenhuma pesquisa em andamento. %d pesquisador%s (tecla Z). Pesquisadores só trabalham no laboratório de dia." % [n, "es" if n != 1 else ""]
	_bar.visible = _res.current != ""
	_bar.value = _res.current_progress()
	for id in _cards:
		var card: Dictionary = _cards[id]
		var t: Dictionary = _res.TECHS[id]
		var reason: String = _res.block_reason(id)
		var c: Vector3i = t.cost
		var bits: Array[String] = ["%d pontos" % t.points]
		if c.x > 0:
			bits.append("%d cr" % c.x)
		if c.y > 0:
			bits.append("%d %s" % [c.y, t.ore])
		if c.z > 0:
			bits.append("%d madeira" % c.z)
		var status: Label = card.status
		var button: Button = card.button
		match reason:
			"pesquisado":
				status.text = "PESQUISADO"
				status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK)
			"pesquisando":
				status.text = "pesquisando %d%%" % roundi(_res.current_progress() * 100.0)
				status.add_theme_color_override("font_color", _hud.COLOR_TITLE)
			"":
				status.text = " + ".join(bits)
				status.add_theme_color_override("font_color", _hud.COLOR_TEXT)
			_:
				status.text = " + ".join(bits) + "  (" + reason + ")" if not reason.begins_with("caminho fechado") else reason
				status.add_theme_color_override("font_color", _hud.COLOR_DIM)
		button.visible = reason not in ["pesquisado", "pesquisando"] and not reason.begins_with("caminho fechado")
		button.disabled = reason != ""
		(card.panel as PanelContainer).modulate = Color(1, 1, 1, 0.5) if reason.begins_with("caminho fechado") else Color.WHITE


func button_text() -> String:
	if _res.current != "":
		return "Pesquisa %d%% (Q)" % roundi(_res.current_progress() * 100.0)
	return "Laboratório (Q)" if _res.lab() else "Pesquisa (Q)"


func has_available_action() -> bool:
	if _res.lab() == null:
		return _res.lab_block_reason() == ""
	if _res.current != "":
		return false
	for id in _res.ORDER:
		if _res.block_reason(id) == "":
			return true
	return false
