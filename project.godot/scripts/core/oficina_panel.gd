extends PanelContainer
## Janela da Oficina: fabricar ferramentas que liberam minérios novos.
## Criada pelo HUD (setup) e montada por código; usa os helpers de estilo do HUD.
## Abre clicando na oficina, pela tecla O ou pelo botão no painel do HUD.

const Ores := preload("res://scripts/core/ores.gd")

var _hud: CanvasLayer
var _oficina: Node
var _economy: Node
var _craft_label: Label
var _craft_bar: ProgressBar
var _rows: Dictionary = {}  # id -> {status, button}
var _eq_rows: Dictionary = {}  # Bloco 42: tipo -> {status, make, fix}
var _eq_queue: Label


func setup(hud: CanvasLayer, oficina: Node, economy: Node) -> void:
	_hud = hud
	_oficina = oficina
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(460, 0)
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
	var title: Label = _hud._label("OFICINA", 20, _hud.COLOR_TITLE)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	title.add_theme_constant_override("outline_size", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.tooltip_text = "Fechar (Esc / O)"
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)

	var intro: Label = _hud._label(
		"Ferramentas novas liberam minérios que antes não dava pra minerar. "
		+ "Uma por vez na forja; o custo é pago ao começar.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)

	_craft_label = _hud._label("", 12, _hud.COLOR_DIM)
	vbox.add_child(_craft_label)
	_craft_bar = _hud._bar(_hud.COLOR_CARGO)
	_craft_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_craft_bar.custom_minimum_size.y = 6
	vbox.add_child(_craft_bar)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("FERRAMENTAS", 12, _hud.COLOR_DIM))
	for id in _oficina.TOOL_IDS:
		_rows[id] = _make_tool_row(vbox, id)
	# Bloco 42: equipamento (vestiário da vila)
	var eq := get_tree().get_first_node_in_group("equipment") if _oficina.is_inside_tree() else null
	if eq:
		vbox.add_child(HSeparator.new())
		var hint: Label = _hud._label("EQUIPAMENTO — o vestiário da vila: cada um pega e devolve sozinho. Casaco no inverno; traje na zona de perigo.", 12, _hud.COLOR_DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(hint)
		_eq_queue = _hud._label("", 12, _hud.COLOR_TEXT)
		_eq_queue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(_eq_queue)
		for id in eq.TYPES:
			var row := HBoxContainer.new()
			vbox.add_child(row)
			var st: Label = _hud._label("", 12, _hud.COLOR_TEXT)
			st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(st)
			var btns := VBoxContainer.new()
			row.add_child(btns)
			var make: Button = _hud._button("")
			make.add_theme_font_size_override("font_size", 11)
			make.custom_minimum_size.x = 190
			make.pressed.connect(func():
				Audio.click()
				eq.order(id)
				refresh())
			btns.add_child(make)
			var fix: Button = _hud._button("")
			fix.add_theme_font_size_override("font_size", 11)
			fix.pressed.connect(func():
				Audio.click()
				eq.repair(id)
				refresh())
			btns.add_child(fix)
			_eq_rows[id] = {"status": st, "make": make, "fix": fix}


func _make_tool_row(parent: VBoxContainer, id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var name_label: Label = _hud._label(_oficina.TOOL_NAMES[id], 14, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var status: Label = _hud._label("", 12, _hud.COLOR_DIM)
	top.add_child(status)

	var ore: String = _oficina.TOOL_UNLOCKS.get(id, "")
	var unlock: Label = _hud._label("Libera: %s" % _oficina.unlock_label(id), 12, Ores.UI_COLORS.get(ore, _hud.COLOR_TEXT))
	v.add_child(unlock)
	var desc: Label = _hud._label(_oficina.TOOL_DESCRIPTIONS[id], 12, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	v.add_child(bottom)
	var cost: Vector3i = _oficina.tool_cost(id)
	var cost_label: Label = _hud._label("%d cr + %d %s + %d madeira  •  %ds  •  vila nível %d" % [
		cost.x, cost.y, Ores.display_name(_oficina.tool_ore_type(id)).to_lower(), _oficina.tool_wood(id), cost.z, _oficina.tool_stage(id)],
		12, _hud.COLOR_TEXT)
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cost_label)
	var button: Button = _hud._button("Fabricar")
	button.custom_minimum_size.x = 140
	button.pressed.connect(func():
		Audio.click()
		_oficina.start_tool(id)
		refresh())
	bottom.add_child(button)
	return {"status": status, "button": button}


func refresh() -> void:
	if not visible or _oficina == null:
		return
	var busy: String = _oficina.crafting
	_craft_label.visible = busy != ""
	_craft_bar.visible = busy != ""
	if busy != "":
		if _oficina.obra_workers().is_empty():
			_craft_label.text = "%s: esperando engenheiro (tecla 4)  —  %ds de trabalho" % [_oficina.TOOL_NAMES[busy], ceili(_oficina.craft_left)]
		else:
			_craft_label.text = "Forjando: %s  —  faltam %ds" % [_oficina.TOOL_NAMES[busy], ceili(_oficina.craft_left)]
		_craft_bar.max_value = 1.0
		_craft_bar.value = _oficina.craft_progress()

	for id in _rows:
		var row: Dictionary = _rows[id]
		var reason: String = _oficina.tool_block_reason(id)
		var status: Label = row.status
		var button: Button = row.button
		match reason:
			"pronta":
				status.text = "pronta"
				status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK)
				button.text = "Pronta"
			"fabricando":
				status.text = ("forjando %d%%" if not _oficina.obra_workers().is_empty() else "esperando engenheiro %d%%") % roundi(_oficina.craft_progress() * 100.0)
				status.add_theme_color_override("font_color", _hud.COLOR_TITLE)
				button.text = "Forjando..."
			"":
				status.text = "disponível"
				status.add_theme_color_override("font_color", _hud.COLOR_TEXT)
				button.text = "Fabricar"
			_:
				status.text = reason
				status.add_theme_color_override("font_color", _hud.COLOR_DIM)
				button.text = "Fabricar"
		button.disabled = reason != ""
	_refresh_equipment()


func _refresh_equipment() -> void:
	var eq := get_tree().get_first_node_in_group("equipment")
	if eq == null or _eq_queue == null:
		return
	_eq_queue.visible = eq.pending()
	if eq.pending():
		var eng: bool = not _oficina.obra_workers().is_empty()
		_eq_queue.text = "Fila: %s — %d%%%s%s" % [eq.title(), roundi(eq.progress() * 100.0),
			"" if eng else "  (esperando engenheiro — tecla 4)", "  •  +%d na fila" % (eq.queue.size() - 1) if eq.queue.size() > 1 else ""]
	for id in _eq_rows:
		var row: Dictionary = _eq_rows[id]
		var extra := ""
		if id == "casaco":
			extra = "  •  faz %d por vez; sem casaco no inverno trabalha a %d%%" % [eq.coat_batch, roundi(eq.cold_work_mult * 100.0)]
		else:
			extra = "  •  pra entrar no %s" % eq.ZONE_NAMES[id].to_lower()
		row.status.text = "%s: %d no vestiário, %d em uso, %d quebrado%s%s" % [eq.NAMES[id], eq.available(id), eq.in_use(id), eq.broken_count(id),
			"s" if eq.broken_count(id) != 1 else "", extra]
		var r: String = eq.order_block_reason(id)
		row.make.text = ("Fazer  (%s)" % eq.cost_text(eq.cost(id), id)) if r == "" else (r.substr(0, 1).to_upper() + r.substr(1))
		row.make.disabled = r != ""
		var fr: String = eq.repair_block_reason(id)
		row.fix.visible = eq.broken_count(id) > 0
		row.fix.text = ("Consertar  (%s)" % eq.cost_text(eq.repair_cost(id), id)) if fr == "" else "Consertar: " + fr
		row.fix.disabled = fr != ""


func button_text() -> String:
	if _oficina.crafting != "":
		return "Oficina %d%%%s (O)" % [roundi(_oficina.craft_progress() * 100.0), "" if not _oficina.obra_workers().is_empty() else " sem eng."]
	var done := 0
	for id in _oficina.TOOL_IDS:
		if _oficina.has_tool(id):
			done += 1
	return "Oficina %d/%d (O)" % [done, _oficina.TOOL_IDS.size()]


func has_available_action() -> bool:
	for id in _oficina.TOOL_IDS:
		if _oficina.tool_block_reason(id) == "":
			return true
	return false
