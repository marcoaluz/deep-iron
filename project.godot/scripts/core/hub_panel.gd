extends PanelContainer
## Janela do Centro da Vila: progresso, expandir a vila e comprar melhorias.
## Criada pelo HUD (setup) e montada por código; usa os helpers de estilo do HUD.
## Abre clicando no prédio, pela tecla U ou pelo botão no painel do HUD.

var _hud: CanvasLayer
var _hub: Node
var _economy: Node
var _stage_label: Label
var _stats_label: Label
var _next_title: Label
var _next_bar: ProgressBar
var _next_label: Label
var _level_button: Button
var _rows: Dictionary = {}  # id -> {level, effect, button}


func setup(hud: CanvasLayer, hub: Node, economy: Node) -> void:
	_hud = hud
	_hub = hub
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(460, 0)
	# centralizado na tela, crescendo pros dois lados
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
	var title: Label = _hud._label("CENTRO DA VILA", 20, _hud.COLOR_TITLE)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	title.add_theme_constant_override("outline_size", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.tooltip_text = "Fechar (Esc / U)"
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)

	_stage_label = _hud._label("", 15, _hud.COLOR_TEXT)
	vbox.add_child(_stage_label)
	_stats_label = _hud._label("", 13, _hud.COLOR_DIM)
	vbox.add_child(_stats_label)

	vbox.add_child(HSeparator.new())
	_next_title = _hud._label("", 12, _hud.COLOR_DIM)
	vbox.add_child(_next_title)
	_next_bar = _hud._bar(_hud.COLOR_TITLE)
	_next_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_next_bar)
	_next_label = _hud._label("", 12, _hud.COLOR_DIM)
	vbox.add_child(_next_label)
	_level_button = _hud._button("")
	_level_button.pressed.connect(func():
		Audio.click()
		_hub.level_up()
		refresh())
	vbox.add_child(_level_button)

	vbox.add_child(HSeparator.new())
	var up_header := HBoxContainer.new()
	vbox.add_child(up_header)
	var up_title: Label = _hud._label("MELHORIAS", 12, _hud.COLOR_DIM)
	up_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_header.add_child(up_title)
	up_header.add_child(_hud._label("cada uma vai até o nível da vila", 11, _hud.COLOR_DIM))

	for id in _hub.UPGRADE_IDS:
		_rows[id] = _make_upgrade_row(vbox, id)


func _make_upgrade_row(parent: VBoxContainer, id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var name_label: Label = _hud._label(_hub.UPGRADE_NAMES[id], 14, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var level_label: Label = _hud._label("", 12, _hud.COLOR_TITLE)
	top.add_child(level_label)

	var desc: Label = _hud._label(_hub.upgrade_description(id), 12, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	v.add_child(bottom)
	var effect: Label = _hud._label("", 12, _hud.COLOR_TEXT)
	effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(effect)
	var button: Button = _hud._button("")
	button.custom_minimum_size.x = 190
	button.pressed.connect(func():
		Audio.click()
		_hub.buy_upgrade(id)
		refresh())
	bottom.add_child(button)
	return {"level": level_label, "effect": effect, "button": button}


func refresh() -> void:
	if not visible or _hub == null:
		return
	var lvl: int = _hub.level
	_stage_label.text = "%s  —  estágio %d de %d" % [_hub.stage_name(), lvl, _hub.max_level()]

	var workers := get_tree().get_nodes_in_group("ipezinhos").size()
	var beds := 0
	var taken := 0
	for casa in get_tree().get_nodes_in_group("casas"):
		beds += casa.beds_total()
		taken += casa.beds_taken()
	_stats_label.text = "População: %d / %d ipezinhos   •   camas: %d / %d\nMinério coletado (total): %d   •   créditos ganhos (total): %d" % [
		workers, _economy.max_workers, taken, beds, int(_hub.lifetime_ore()), int(_economy.total_earned)]

	if lvl >= _hub.max_level():
		_next_title.text = "A VILA ESTÁ NO ESTÁGIO MÁXIMO"
		_next_bar.max_value = 1.0
		_next_bar.value = 1.0
		_next_label.text = ""
		_level_button.text = "Estágio máximo"
		_level_button.disabled = true
	else:
		var need: int = _hub.next_level_ore()
		var have: float = _hub.lifetime_ore()
		_next_title.text = "PRÓXIMO ESTÁGIO: %s" % _hub.stage_name(lvl + 1).to_upper()
		_next_bar.max_value = need
		_next_bar.value = minf(have, need)
		_next_label.text = "%d / %d minério coletado no total" % [int(have), need]
		var cost: int = _hub.next_level_cost()
		if have < need:
			_level_button.text = "Expandir vila  (falta minério coletado)"
		else:
			_level_button.text = "Expandir vila  (%d cr)" % cost
		_level_button.disabled = not _hub.can_level_up()

	for id in _rows:
		var row: Dictionary = _rows[id]
		var cur: int = _hub.upgrades[id]
		var mx: int = _hub.upgrade_max(id)
		row.level.text = "nível %d / %d" % [cur, mx]
		var effect: String = _hub.upgrade_effect_text(id, cur)
		if cur < mx:
			effect += "  →  " + _hub.upgrade_effect_text(id, cur + 1)
		row.effect.text = effect
		var reason: String = _hub.upgrade_block_reason(id)
		var button: Button = row.button
		if cur >= mx:
			button.text = "Nível máximo"
		elif reason.begins_with("requer"):
			button.text = "Requer vila nível %d" % (cur + 1)
		else:
			var verb := "Construir casa" if id == "moradias" else "Melhorar"
			button.text = "%s  (%s)" % [verb, _cost_text(id)]
			if reason.begins_with("falta"):
				button.text = reason.substr(0, 1).to_upper() + reason.substr(1)
			button.tooltip_text = "Custo: " + _cost_text(id)
		button.disabled = reason != ""


func button_text() -> String:
	return "Vila: %s (U)" % _hub.stage_name()


func has_available_action() -> bool:
	if _hub.can_level_up():
		return true
	for id in _hub.UPGRADE_IDS:
		if _hub.upgrade_block_reason(id) == "":
			return true
	return false


## Custo completo do próximo nível (créditos + minério/pedra + madeira).
func _cost_text(id: String) -> String:
	var t := cost_text(_hub.upgrade_cost(id))
	if id == "moradias":
		var cost: Vector2i = _hub.upgrade_cost(id)
		t = "%d cr" % cost.x
		if cost.y > 0:
			t += " + %d %s" % [cost.y, _hub.upgrade_ore_label(id)]
	var wood: int = _hub.upgrade_wood(id)
	if wood > 0:
		t += " + %d madeira" % wood
	return t


static func cost_text(cost: Vector2i) -> String:
	var t := "%d cr" % cost.x
	if cost.y > 0:
		t += " + %d minério" % cost.y
	return t
