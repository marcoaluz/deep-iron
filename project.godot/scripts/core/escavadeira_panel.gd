extends PanelContainer
## Janela do Canteiro da Escavadeira: progresso da montagem e fabricação das peças.
## Criada pelo HUD (setup) e montada por código; usa os helpers de estilo do HUD.
## Abre clicando no canteiro, pela tecla E ou pelo botão no painel do HUD.

var _hud: CanvasLayer
var _dig: Node
var _economy: Node
var _progress_label: Label
var _progress_bar: ProgressBar
var _fab_label: Label
var _fab_bar: ProgressBar
var _done_label: Label
var _rows: Dictionary = {}  # id -> {panel, status, button}


func setup(hud: CanvasLayer, dig: Node, economy: Node) -> void:
	_hud = hud
	_dig = dig
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(480, 0)
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
	var title: Label = _hud._label("ESCAVADEIRA", 20, _hud.COLOR_TITLE)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	title.add_theme_constant_override("outline_size", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.tooltip_text = "Fechar (Esc / E)"
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)

	var intro: Label = _hud._label(
		"Projeto de fim de jogo: fabrique as 5 peças aqui no canteiro. Uma por vez; "
		+ "a Estrutura vem primeiro. O custo é pago ao começar a fabricar.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)

	_progress_label = _hud._label("", 14, _hud.COLOR_TEXT)
	vbox.add_child(_progress_label)
	_progress_bar = _hud._bar(_hud.COLOR_TITLE)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_progress_bar)

	_fab_label = _hud._label("", 12, _hud.COLOR_DIM)
	vbox.add_child(_fab_label)
	_fab_bar = _hud._bar(_hud.COLOR_CARGO)
	_fab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fab_bar.custom_minimum_size.y = 6
	vbox.add_child(_fab_bar)

	_done_label = _hud._label("A escavadeira está PRONTA! A descida pro NÍVEL 2 abriu ao lado dela.", 14, _hud.COLOR_TITLE)
	_done_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_done_label)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("PEÇAS", 12, _hud.COLOR_DIM))
	for id in _dig.PART_IDS:
		_rows[id] = _make_part_row(vbox, id)


func _make_part_row(parent: VBoxContainer, id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var name_label: Label = _hud._label(_dig.PART_NAMES[id], 14, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var status: Label = _hud._label("", 12, _hud.COLOR_DIM)
	top.add_child(status)

	var desc: Label = _hud._label(_dig.PART_DESCRIPTIONS[id], 12, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	v.add_child(bottom)
	var cost: Vector3i = _dig.part_cost(id)
	var cost_label: Label = _hud._label("%d cr + %d minério  •  %ds  •  vila nível %d" % [cost.x, cost.y, cost.z, _dig.part_stage(id)], 12, _hud.COLOR_TEXT)
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cost_label)
	var button: Button = _hud._button("Fabricar")
	button.custom_minimum_size.x = 150
	button.pressed.connect(func():
		Audio.click()
		_dig.start_part(id)
		refresh())
	bottom.add_child(button)
	return {"status": status, "button": button}


func refresh() -> void:
	if not visible or _dig == null:
		return
	var n: int = _dig.installed_count()
	var total: int = _dig.PART_IDS.size()
	_progress_label.text = "Peças instaladas: %d / %d" % [n, total]
	_progress_bar.max_value = total
	_progress_bar.value = n

	var fab: String = _dig.fabricating
	_fab_label.visible = fab != ""
	_fab_bar.visible = fab != ""
	if fab != "":
		_fab_label.text = "Fabricando: %s  —  faltam %ds" % [_dig.PART_NAMES[fab], ceili(_dig.fab_left)]
		_fab_bar.max_value = 1.0
		_fab_bar.value = _dig.fab_progress()
	_done_label.visible = _dig.complete

	for id in _rows:
		var row: Dictionary = _rows[id]
		var reason: String = _dig.part_block_reason(id)
		var status: Label = row.status
		var button: Button = row.button
		match reason:
			"instalada":
				status.text = "instalada"
				status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK)
				button.text = "Instalada"
			"fabricando":
				status.text = "fabricando %d%%" % roundi(_dig.fab_progress() * 100.0)
				status.add_theme_color_override("font_color", _hud.COLOR_TITLE)
				button.text = "Fabricando..."
			"":
				status.text = "disponível"
				status.add_theme_color_override("font_color", _hud.COLOR_TEXT)
				button.text = "Fabricar"
			_:
				status.text = reason
				status.add_theme_color_override("font_color", _hud.COLOR_DIM)
				button.text = "Fabricar"
		button.disabled = reason != ""


func button_text() -> String:
	if _dig.complete:
		return "Escavadeira — PRONTA  (E)"
	if _dig.fabricating != "":
		return "Escavadeira — %s %d%%  (E)" % [_dig.PART_NAMES[_dig.fabricating], roundi(_dig.fab_progress() * 100.0)]
	return "Escavadeira — %d/5 peças  (E)" % _dig.installed_count()


func has_available_action() -> bool:
	for id in _dig.PART_IDS:
		if _dig.part_block_reason(id) == "":
			return true
	return false
