extends PanelContainer
## Janela do Canteiro da Escavadeira: progresso da montagem e fabricação das peças.
## Criada pelo HUD (setup) e montada por código; usa os helpers de estilo do HUD.
## Abre clicando no canteiro, pela tecla E ou pelo botão no painel do HUD.
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _dig: Node
var _economy: Node
var _progress_label: Label
var _progress_bar: ProgressBar
var _fab_label: Label
var _fab_bar: ProgressBar
var _done_label: Label
var _rows: Dictionary = {}  # id -> {panel, status, button}
var _parts_box: VBoxContainer
var _intro: Label
var _reactor_box: VBoxContainer
var _drill_label: Label
var _drill_button: Button
var _finds_label: Label
var _reactor_rows: Dictionary = {}  # id -> {status, button}


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
	var title: Label = _hud._label("ESCAVADEIRA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
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
		+ "a Estrutura vem primeiro. O custo é pago ao começar a fabricar.", Tipo.DETALHE, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_intro = intro

	_progress_label = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	vbox.add_child(_progress_label)
	_progress_bar = _hud._bar(_hud.COLOR_TITLE)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_progress_bar)

	_fab_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	vbox.add_child(_fab_label)
	_fab_bar = _hud._bar(_hud.COLOR_CARGO)
	_fab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fab_bar.custom_minimum_size.y = 6
	vbox.add_child(_fab_bar)

	_done_label = _hud._label("PRONTA! A descida pro nível 2 está aberta ao lado dela.", Tipo.CORPO, _hud.COLOR_TITLE)
	_done_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_done_label)

	_parts_box = VBoxContainer.new()
	_parts_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_parts_box)
	_parts_box.add_child(HSeparator.new())
	_parts_box.add_child(_hud._label("PEÇAS", Tipo.DETALHE, _hud.COLOR_DIM))
	for id in _dig.PART_IDS:
		_rows[id] = _make_part_row(_parts_box, id)

	# pronta: reatores (Bloco 19)
	_reactor_box = VBoxContainer.new()
	_reactor_box.add_theme_constant_override("separation", 5)
	vbox.add_child(_reactor_box)
	_reactor_box.add_child(HSeparator.new())
	var drill_row := HBoxContainer.new()
	_reactor_box.add_child(drill_row)
	_drill_label = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	_drill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drill_row.add_child(_drill_label)
	_drill_button = _hud._button("Desligar")
	_drill_button.pressed.connect(func():
		Audio.click()
		_dig.toggle_drill()
		refresh())
	drill_row.add_child(_drill_button)
	_finds_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_finds_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reactor_box.add_child(_finds_label)
	_reactor_box.add_child(_hud._label("REATORES  (um por vez; a broca manda minério direto pro armazém)", Tipo.DETALHE, _hud.COLOR_DIM))
	for id in _dig.REACTOR_IDS:
		_reactor_rows[id] = _make_reactor_row(_reactor_box, id)


func _make_part_row(parent: VBoxContainer, id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var name_label: Label = _hud._label(_dig.PART_NAMES[id], Tipo.TITULO, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var status: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	top.add_child(status)

	var desc: Label = _hud._label(_dig.PART_DESCRIPTIONS[id], Tipo.DETALHE, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	v.add_child(bottom)
	var cost: Vector3i = _dig.part_cost(id)
	var cost_label: Label = _hud._label(_texto_peca(id), Tipo.DETALHE, _hud.COLOR_TEXT)
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cost_label)
	var button: Button = _hud._button("Fabricar")
	button.custom_minimum_size.x = 150
	button.pressed.connect(func():
		Audio.click()
		_dig.start_part(id)
		refresh())
	bottom.add_child(button)
	return {"status": status, "button": button, "cost": cost_label}


## Bloco 87: o custo da peça (o metal em barra a partir do estágio da fornalha).
func _texto_peca(id: String) -> String:
	var cost: Vector3i = _dig.part_cost(id)
	var metal: String = _economy.custo_metal_texto(cost.x, cost.y, "") if _economy else "%d cr + %d minério" % [cost.x, cost.y]
	return "%s  •  %ds  •  vila nível %d" % [metal, cost.z, _dig.part_stage(id)]


func _make_reactor_row(parent: VBoxContainer, id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var name_label: Label = _hud._label("%s  —  %.2f/s" % [_dig.REACTOR_NAMES[id], _dig.reactor_rate(id)], Tipo.CORPO, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var button: Button = _hud._button("")
	button.custom_minimum_size.x = 120
	button.pressed.connect(func():
		Audio.click()
		if _dig.built_reactors.has(id):
			_dig.install_reactor(id)
		else:
			_dig.build_reactor(id)
		refresh())
	top.add_child(button)
	var desc: Label = _hud._label(_dig.REACTOR_DESCRIPTIONS[id], Tipo.DETALHE, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	var status: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(status)
	return {"status": status, "button": button}


func _refresh_reactors() -> void:
	_drill_label.text = "%s: %s" % [_dig.REACTOR_NAMES.get(_dig.reactor, "?"), _dig.drill_status()]
	_drill_label.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK if _dig.reactor_active() else _hud.COLOR_HUNGER_BAD)
	_drill_button.text = "Desligar" if _dig.drill_on else "Ligar"
	var finds := get_tree().get_first_node_in_group("finds")
	if finds:
		var got: Array[String] = []
		for item in finds.ITEM_IDS:
			if finds.has_item(item):
				got.append(finds.ITEM_NAMES[item])
		_finds_label.text = "Peças raras: %d   •   Achados: %s" % [finds.rare_parts, ", ".join(got) if not got.is_empty() else "nenhum ainda (procure no nível 2)"]
	for id in _reactor_rows:
		var row: Dictionary = _reactor_rows[id]
		var reason: String = _dig.reactor_block_reason(id)
		var status: Label = row.status
		var button: Button = row.button
		var cost: Vector3i = _dig.reactor_cost(id)
		var bits: Array[String] = []
		if cost.z > 0:
			bits.append("%d peças raras" % cost.z)
		if cost.x > 0:
			bits.append("%d cr" % cost.x)
		if cost.y > 0:
			bits.append(_economy.metal_texto(cost.y, "ferro") if _economy else "%d ferro" % cost.y)  # Bloco 87
		var cost_text := "vem com a escavadeira" if id == "vapor" else " + ".join(bits)
		match reason:
			"instalado":
				status.text = "INSTALADO"
				status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK)
				button.text = "Instalado"
				button.disabled = true
			"construído":
				status.text = "construído — dá pra trocar"
				status.add_theme_color_override("font_color", _hud.COLOR_TEXT)
				button.text = "Instalar"
				button.disabled = _dig.outage_left > 0.0
			"":
				status.text = cost_text
				status.add_theme_color_override("font_color", _hud.COLOR_TEXT)
				button.text = "Construir"
				button.disabled = false
			_:
				# falta o achado: só isso importa; senão mostra custo + o que falta
				status.text = reason + " (nível 2)" if reason.begins_with("precisa achar") else "%s  (%s)" % [cost_text, reason]
				status.add_theme_color_override("font_color", _hud.COLOR_DIM)
				button.text = "Construir"
				button.disabled = true


func refresh() -> void:
	if not visible or _dig == null:
		return
	_parts_box.visible = not _dig.complete
	_reactor_box.visible = _dig.complete
	# pronta: some o que era do projeto (a janela não cabe na tela com os reatores)
	_intro.visible = not _dig.complete
	_progress_label.visible = not _dig.complete
	_progress_bar.visible = not _dig.complete
	if _dig.complete:
		_refresh_reactors()
	var n: int = _dig.installed_count()
	var total: int = _dig.PART_IDS.size()
	_progress_label.text = "Peças instaladas: %d / %d" % [n, total]
	_progress_bar.max_value = total
	_progress_bar.value = n

	var fab: String = _dig.fabricating
	_fab_label.visible = fab != ""
	_fab_bar.visible = fab != ""
	if fab != "":
		if _dig.obra_workers().is_empty():
			_fab_label.text = "%s: esperando engenheiro (tecla 4)  —  %ds de trabalho" % [_dig.PART_NAMES[fab], ceili(_dig.fab_left)]
		else:
			_fab_label.text = "Montando: %s  —  faltam %ds" % [_dig.PART_NAMES[fab], ceili(_dig.fab_left)]
		_fab_bar.max_value = 1.0
		_fab_bar.value = _dig.fab_progress()
	_done_label.visible = _dig.complete

	for id in _rows:
		var row: Dictionary = _rows[id]
		if row.has("cost"):
			row.cost.text = _texto_peca(id)  # Bloco 87
		var reason: String = _dig.part_block_reason(id)
		var status: Label = row.status
		var button: Button = row.button
		match reason:
			"instalada":
				status.text = "instalada"
				status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK)
				button.text = "Instalada"
			"fabricando":
				status.text = ("montando %d%%" if not _dig.obra_workers().is_empty() else "esperando engenheiro %d%%") % roundi(_dig.fab_progress() * 100.0)
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
		if _dig.reactor_active():
			return "Escavadeira %.2f/s (E)" % _dig.reactor_rate()
		return "Escavadeira: %s (E)" % ("PANE" if _dig.outage_left > 0.0 else ("SEM CARVÃO" if _dig.no_fuel else "desligada"))
	if _dig.fabricating != "":
		return "Escavadeira %d%%%s (E)" % [roundi(_dig.fab_progress() * 100.0), "" if not _dig.obra_workers().is_empty() else " sem eng."]
	return "Escavadeira %d/5 (E)" % _dig.installed_count()


func has_available_action() -> bool:
	if _dig.complete:
		for id in _dig.REACTOR_IDS:
			if _dig.reactor_block_reason(id) == "":
				return true
		return not _dig.reactor_active() and _dig.drill_on
	for id in _dig.PART_IDS:
		if _dig.part_block_reason(id) == "":
			return true
	return false
