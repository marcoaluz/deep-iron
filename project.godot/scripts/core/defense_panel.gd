extends PanelContainer
## Janela de Defesa (tecla G, ou clique numa barricada / no campo de treino):
## próxima invasão, portões (ampliar/consertar), guardas, campo de treino e armas.

var _hud: CanvasLayer
var _def: Node
var _status: Label
var _gate_rows: Dictionary = {}  # gate_id -> {label, up, fix}
var _guards_label: Label
var _campo_button: Button
var _weapon_rows: Dictionary = {}  # id -> {status, button}
var _forge_bar: ProgressBar


func setup(hud: CanvasLayer, def: Node, _economy: Node) -> void:
	_hud = hud
	_def = def
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(500, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("DEFESA", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_status = _hud._label("", 14, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("MURO (as criaturas precisam derrubar pra entrar)", 12, _hud.COLOR_DIM))
	for id in ["tunel", "poco"]:
		var l: Label = _hud._label("", 12, _hud.COLOR_TEXT)
		vbox.add_child(l)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var up: Button = _hud._button("")
		up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		up.add_theme_font_size_override("font_size", 12)
		up.pressed.connect(func():
			Audio.click()
			var g: Node = _def.gate(id)
			if g:
				g.upgrade()
			refresh())
		row.add_child(up)
		var fix: Button = _hud._button("")
		fix.add_theme_font_size_override("font_size", 12)
		fix.custom_minimum_size.x = 150
		fix.pressed.connect(func():
			Audio.click()
			var g: Node = _def.gate(id)
			if g:
				g.repair()
			refresh())
		row.add_child(fix)
		_gate_rows[id] = {"label": l, "up": up, "fix": fix}

	vbox.add_child(HSeparator.new())
	_guards_label = _hud._label("", 12, _hud.COLOR_TEXT)
	_guards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_guards_label)
	_campo_button = _hud._button("")
	_campo_button.pressed.connect(func():
		Audio.click()
		_def.build_campo()
		refresh())
	vbox.add_child(_campo_button)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("ARMAS (todos os guardas usam a melhor que já foi forjada)", 12, _hud.COLOR_DIM))
	_forge_bar = _hud._bar(_hud.COLOR_TITLE)
	_forge_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_forge_bar.max_value = 1.0
	vbox.add_child(_forge_bar)
	for id in _def.WEAPON_IDS:
		if id == "porrete":
			continue
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var i: int = _def.WEAPON_IDS.find(id)
		info.tooltip_text = _def.WEAPON_DESCRIPTIONS[id]
		info.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(_hud._label("%s — dano %d%s" % [_def.WEAPON_NAMES[id], roundi(_def.weapon_damage[i]),
			(", de longe" if _def.weapon_range[i] > 40.0 else (", forte contra Ferrugentos" if _def.weapon_vs_ferrugento[i] > 1.0 else ""))], 13, _hud.COLOR_TEXT))
		var status: Label = _hud._label("", 11, _hud.COLOR_DIM)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(status)
		var b: Button = _hud._button("Forjar")
		b.custom_minimum_size.x = 110
		b.pressed.connect(func():
			Audio.click()
			_def.start_forge(id)
			refresh())
		row.add_child(b)
		_weapon_rows[id] = {"status": status, "button": b}


func refresh() -> void:
	if not visible:
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	if _def.invasion_active:
		_status.text = "INVASÃO EM ANDAMENTO (onda %d): %d criaturas, %d já dentro da vila, %d derrubadas." % [
			_def.wave, _def.creatures().size(), _def.creatures_inside(), _def.killed_tonight]
		_status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD)
	else:
		var nd: int = _def.next_invasion_day()
		var today: bool = dn != null and nd == dn.day and not dn.is_night()
		_status.text = ("Próxima invasão: HOJE À NOITE!" if today else "Próxima invasão: noite do dia %d" % nd) \
			+ ("  •  Ferrugentos também (o nível 2 está aberto)" if _def.level2_open() else "")
		_status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD if today else _hud.COLOR_TEXT)

	for id in _gate_rows:
		var row: Dictionary = _gate_rows[id]
		var g: Node = _def.gate(id)
		if g == null:
			continue
		var name_lvl: String = g.LEVEL_NAMES[g.level]
		var hp_txt := "" if g.level == 0 else "  •  vida %d/%d" % [roundi(g.hp), roundi(g.max_hp())]
		if id == "poco" and not _def.level2_open():
			hp_txt += "  (Ferrugentos só depois do nível 2)"
		row.label.text = "%s: %s%s" % [g.display_name, name_lvl, hp_txt]
		var up_reason: String = g.upgrade_block_reason()
		if up_reason == "nível máximo":
			row.up.text = "Máximo"
		elif up_reason == "":
			var c: Vector3i = g.upgrade_costs[g.level + 1]
			row.up.text = "Construir %s (%s)" % [g.LEVEL_NAMES[g.level + 1].split(" ")[0].to_lower(), _cost_text(c, g.upgrade_ore[g.level + 1])]
		else:
			row.up.text = "Ampliar: " + up_reason
		row.up.disabled = up_reason != ""
		var fix_reason: String = g.repair_block_reason()
		row.fix.visible = g.level > 0
		row.fix.text = "Consertar (%d madeira)" % g.repair_cost() if fix_reason == "" else ("Inteiro" if fix_reason == "inteiro" else "Consertar: " + fix_reason)
		row.fix.disabled = fix_reason != ""

	var gs: Array = _def.guards()
	var ready_n := gs.filter(func(w): return w.combat_skill >= 1.0).size()
	_guards_label.text = "Guardas: %d (%d treinados)  •  arma: %s  •  selecione ipezinhos e aperte X pra torná-los guardas. De dia treinam no campo; à noite vão pros portões." % [
		gs.size(), ready_n, _def.WEAPON_NAMES[_def.best_weapon()]]
	var campo_reason: String = _def.campo_block_reason()
	_campo_button.text = "Campo de treino construído" if campo_reason == "construído" else (
		"Construir campo de treino — escolher lugar (%d cr + %d madeira)" % [_def.campo_credits, _def.campo_wood] if campo_reason == "" else "Campo de treino: " + campo_reason)
	_campo_button.disabled = campo_reason != ""

	_forge_bar.visible = _def.forging != ""
	_forge_bar.value = _def.forge_progress()
	for id in _weapon_rows:
		var row: Dictionary = _weapon_rows[id]
		var reason: String = _def.weapon_block_reason(id)
		var i: int = _def.WEAPON_IDS.find(id)
		var cost := _cost_text(_def.weapon_costs[i], _def.weapon_ore[i])
		row.status.text = {"pronta": "PRONTA", "forjando": "forjando %d%%" % roundi(_def.forge_progress() * 100.0)}.get(reason, cost + ("" if reason == "" else "  (" + reason + ")"))
		row.button.text = "Pronta" if reason == "pronta" else "Forjar"
		row.button.disabled = reason != ""


func _cost_text(c: Vector3i, ore: String) -> String:
	var bits: Array[String] = []
	if c.x > 0:
		bits.append("%d cr" % c.x)
	if c.y > 0:
		bits.append("%d %s" % [c.y, ore if ore != "" else "minério"])
	if c.z > 0:
		bits.append("%d madeira" % c.z)
	return " + ".join(bits)


func button_text() -> String:
	if _def.invasion_active:
		return "INVASÃO! (G)"
	var dn := get_tree().get_first_node_in_group("day_night")
	var nd: int = _def.next_invasion_day()
	if dn and nd == dn.day:
		return "Defesa: HOJE (G)"
	return "Defesa: dia %d (G)" % nd


func has_available_action() -> bool:
	var dn := get_tree().get_first_node_in_group("day_night")
	return _def.invasion_active or (dn != null and _def.next_invasion_day() == dn.day)
