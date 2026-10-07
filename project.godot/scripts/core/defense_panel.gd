extends PanelContainer
## Janela de Defesa (tecla G, ou clique numa barricada / no campo de treino):
## próxima invasão, portões (ampliar/consertar), guardas, campo de treino e armas.
## Bloco 35: Arsenal (construir, cavalete, fila da forja), forjar/consertar cada arma e a
## arma + durabilidade de cada guarda (desarmado em destaque).
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _def: Node
var _status: Label
var _gate_rows: Dictionary = {}  # gate_id -> {label, up, fix}
var _poco_label: Label
var _guards_label: Label
var _campo_button: Button
var _weapon_rows: Dictionary = {}  # id -> {status, button, fix}
var _forge_bar: ProgressBar
var _arsenal_label: Label
var _arsenal_button: Button
var _forge_label: Label


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
	var title: Label = _hud._label("DEFESA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_status = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("MURO (o que vem da floresta precisa derrubar pra entrar)", Tipo.DETALHE, _hud.COLOR_DIM))
	for id in ["tunel"]:  # Bloco 80: o único portão (o do poço saiu)
		var l: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
		vbox.add_child(l)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var up: Button = _hud._button("")
		up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		up.add_theme_font_size_override("font_size", Tipo.DETALHE)
		up.pressed.connect(func():
			Audio.click()
			var g: Node = _def.gate(id)
			if g:
				g.upgrade()
			refresh())
		row.add_child(up)
		var fix: Button = _hud._button("")
		fix.add_theme_font_size_override("font_size", Tipo.DETALHE)
		fix.custom_minimum_size.x = 150
		fix.pressed.connect(func():
			Audio.click()
			var g: Node = _def.gate(id)
			if g:
				g.repair()
			refresh())
		row.add_child(fix)
		_gate_rows[id] = {"label": l, "up": up, "fix": fix}
	_poco_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)  # Bloco 80: o poço não tem muro
	_poco_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_poco_label)

	vbox.add_child(HSeparator.new())
	_guards_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_guards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_guards_label)
	_campo_button = _hud._button("")
	_campo_button.pressed.connect(func():
		Audio.click()
		_def.build_campo()
		refresh())
	vbox.add_child(_campo_button)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("ARSENAL — armas se gastam na luta; quebrou, o guarda vem aqui buscar outra", Tipo.DETALHE, _hud.COLOR_DIM))
	_arsenal_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_arsenal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_arsenal_label)
	_arsenal_button = _hud._button("")
	_arsenal_button.pressed.connect(func():
		Audio.click()
		_def.build_arsenal()
		refresh())
	vbox.add_child(_arsenal_button)
	_forge_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_forge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_forge_label)
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
		info.add_child(_hud._label("%s — dano %d%s  •  aguenta %d golpes" % [_def.WEAPON_NAMES[id], roundi(_def.weapon_damage[i]),
			(", de longe" if _def.weapon_range[i] > 40.0 else (", forte contra Ferrugentos" if _def.weapon_vs_ferrugento[i] > 1.0 else "")),
			roundi(_def.weapon_max_durability(id))], Tipo.CORPO, _hud.COLOR_TEXT))
		var status: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(status)
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 2)
		row.add_child(buttons)
		var b: Button = _hud._button("Forjar")
		b.custom_minimum_size.x = 150
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.pressed.connect(func():
			Audio.click()
			_def.start_forge(id)
			refresh())
		buttons.add_child(b)
		var fix: Button = _hud._button("Consertar")
		fix.custom_minimum_size.x = 150
		fix.add_theme_font_size_override("font_size", Tipo.DETALHE)
		fix.pressed.connect(func():
			Audio.click()
			_def.start_repair(id)
			refresh())
		buttons.add_child(fix)
		_weapon_rows[id] = {"status": status, "button": b, "fix": fix}


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
		row.label.text = "%s: %s%s" % [g.display_name, name_lvl, hp_txt]
		var up_reason: String = g.upgrade_block_reason()
		if up_reason == "nível máximo":
			row.up.text = "Máximo"
		elif up_reason == "":
			var c: Vector3i = g.upgrade_costs[g.level + 1]
			row.up.text = "Construir %s (%s)" % [g.LEVEL_NAMES[g.level + 1].split(" ")[0].to_lower(), _cost_text(c, g.upgrade_ore[g.level + 1], g.upgrade_item_cost())]
		else:
			row.up.text = "Ampliar: " + up_reason
		row.up.disabled = up_reason != ""
		var fix_reason: String = g.repair_block_reason()
		row.fix.visible = g.level > 0
		row.fix.text = "Consertar (%d madeira)" % g.repair_cost() if fix_reason == "" else ("Inteiro" if fix_reason == "inteiro" else "Consertar: " + fix_reason)
		row.fix.disabled = fix_reason != ""

	_poco_label.text = ("Poço do elevador: SEM MURO — os Ferrugentos (robôs enferrujados) e o que mais vem do fundo "
		+ "saem direto da boca do poço. Metade dos guardas faz posto lá.") if _def.level2_open() \
		else "Poço do elevador: fechado (os Ferrugentos só saem dele depois que o nível 2 abre)."
	var gs: Array = _def.guards()
	var ready_n := gs.filter(func(w): return w.combat_skill >= 1.0).size()
	var unarmed: Array = _def.unarmed_guards()
	var lines: Array[String] = ["Guardas: %d (%d treinados)%s  •  X faz guarda. De dia treinam no campo; à noite vão pro portão (e pro poço, com o nível 2 aberto)." % [
		gs.size(), ready_n, ("  •  %d DESARMADO%s" % [unarmed.size(), "S" if unarmed.size() > 1 else ""]) if not unarmed.is_empty() else ""]]
	for w in gs:
		if w.downed:  # Bloco 36
			lines.append("  • %s: CAÍDO no %s — %s" % [w.display_name, _def.gate_label(w.downed_gate),
				"sendo levado pra enfermaria" if w._carried_by != null else "só o médico resgata (morre em %ds)" % ceili(w._care_left)])
		elif w.weapon == "":
			lines.append("  • %s: DESARMADO — %s" % [w.display_name,
				"indo ao Arsenal" if w.get_state() == "rearming" else ("sem Arsenal, luta no soco" if _def.arsenal() == null else "vai ao Arsenal")])
		else:
			lines.append("  • %s: %s%s" % [w.display_name, w.weapon_label(), "  (gasta!)" if w.weapon_condition() < 0.25 else ""])
	_guards_label.text = "\n".join(lines)
	_guards_label.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD if not unarmed.is_empty() or not _def.downed_guards().is_empty() else _hud.COLOR_TEXT)
	# Bloco 47: pode ter vários (cada um a mais custa mais)
	var campo_reason: String = _def.campo_block_reason()
	var n_campos: int = _def.campos().size()
	var campo_what := "campo de treino" if n_campos == 0 else "outro campo de treino (tem %d)" % n_campos
	_campo_button.text = ("Construir %s — escolher lugar (%s)" % [campo_what, _def.campo_cost_text()]) if campo_reason == "" \
		else "Construir %s: %s" % [campo_what, campo_reason]
	_campo_button.disabled = campo_reason != ""

	# Arsenal
	var ars: Node = _def.arsenal()
	var ars_reason: String = _def.arsenal_block_reason()
	var n_ars: int = _def.arsenais().size()
	var ars_what := "Arsenal" if n_ars == 0 else "outro Arsenal — posto de armas (tem %d)" % n_ars
	_arsenal_button.text = ("Construir %s — escolher lugar (%s)" % [ars_what, _def.arsenal_cost_text()]) \
		if ars_reason == "" else "Construir %s: %s" % [ars_what, ars_reason]
	_arsenal_button.disabled = ars_reason != ""
	if ars == null:
		_arsenal_label.text = "Sem Arsenal: não dá pra forjar nem trocar arma quebrada (o guarda luta no soco)."
	else:
		var bits: Array[String] = []
		for id in _def.WEAPON_IDS:
			if _def.rack_count(id) > 0:
				bits.append("%d %s" % [_def.rack_count(id), _def.WEAPON_NAMES[id].to_lower()])
		_arsenal_label.text = "Cavalete: %s  •  pra consertar: %d  •  porrete sempre tem (de graça)." % [
			", ".join(bits) if not bits.is_empty() else "vazio", _def.broken_total()]
	_forge_bar.visible = not _def.queue.is_empty()
	_forge_bar.value = _def.forge_progress()
	_forge_label.visible = not _def.queue.is_empty()
	if not _def.queue.is_empty():
		var eng: bool = ars != null and not ars.obra_workers().is_empty()
		_forge_label.text = "Na forja: %s — %d%%%s%s" % [_def.forge_title(), roundi(_def.forge_progress() * 100.0),
			"" if eng else "  (esperando engenheiro — tecla 4)" if ars != null else "  (construa o Arsenal)",
			"  •  +%d na fila" % (_def.queue.size() - 1) if _def.queue.size() > 1 else ""]
	for id in _weapon_rows:
		var row: Dictionary = _weapon_rows[id]
		var reason: String = _def.weapon_block_reason(id)
		var fix_reason: String = _def.repair_block_reason(id)
		var i: int = _def.WEAPON_IDS.find(id)
		var st := "no cavalete: %d  •  quebradas: %d" % [_def.rack_count(id), _def.broken_count(id)]
		if reason != "" and not reason.begins_with("falta"):
			st += "  (" + reason + ")"
		row.status.text = st
		row.button.text = ("Forjar  (%s)" % _cost_text(_def.weapon_costs[i], _def.weapon_ore[i], _def.weapon_item_cost(id))) if not reason.begins_with("falta") else reason.substr(0, 1).to_upper() + reason.substr(1)
		row.button.disabled = reason != ""
		row.fix.text = "Consertar  (%s)" % _cost_text(_def.repair_cost(id), _def.weapon_ore[i], _def.weapon_item_cost(id, true)) if fix_reason == "" or fix_reason.begins_with("fila") \
			else ("Consertar: " + fix_reason)
		row.fix.disabled = fix_reason != ""


## Bloco 87: o metal sai em barra a partir do estágio da fornalha (Economy.custo_metal_texto).
func _cost_text(c: Vector3i, ore: String, itens: Dictionary = {}) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco:
		return eco.custo_metal_texto(c.x, c.y, ore, c.z, itens)  # Bloco 94: + itens (o aço, os pregos)
	var bits: Array[String] = []
	if c.x > 0:
		bits.append("%d cr" % c.x)
	if c.y > 0:
		bits.append("%d %s" % [c.y, ore if ore != "" else "minério"])
	if c.z > 0:
		bits.append("%d madeira" % c.z)
	return " + ".join(bits)


func button_text() -> String:
	var un: int = _def.unarmed_guards().size()
	var tail := "  •  %d desarmado%s" % [un, "s" if un > 1 else ""] if un > 0 else ""
	if _def.invasion_active:
		return "INVASÃO! (G)" + tail
	var dn := get_tree().get_first_node_in_group("day_night")
	var nd: int = _def.next_invasion_day()
	if dn and nd == dn.day:
		return "Defesa: HOJE (G)" + tail
	return "Defesa: dia %d (G)" % nd + tail


func has_available_action() -> bool:
	var dn := get_tree().get_first_node_in_group("day_night")
	return _def.invasion_active or (dn != null and _def.next_invasion_day() == dn.day)
