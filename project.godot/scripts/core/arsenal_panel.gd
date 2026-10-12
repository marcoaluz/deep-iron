extends PanelContainer
## Bloco 128: a janela do ARSENAL (clique nele). Só o que ele faz: a FORJA (fila, barra), o CAVALETE (o que tem pronto e o
## que espera conserto), as armas (forjar e consertar) e os guardas desarmados. Antes o Arsenal e o campo de treino abriam a
## janela da Defesa; agora a Defesa (G) é só a visão geral. Construir outro Arsenal é no menu CONSTRUIR, nunca aqui.
## Interface das janelas do HUD: setup(hud, alvo, economia), refresh(), focus(no), button_text(), has_available_action().
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _def: Node
var _focus: Node = null
var _title: Label
var _info: Label
var _status_forja: Label
var _forge_bar: ProgressBar
var _cavalete: Label
var _desarmados: Label
var _weapon_rows: Dictionary = {}  # id -> {status, button, fix}


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
	_title = _hud._label("ARSENAL", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_info = _hud._label("Forja e conserta as armas dos guardas. Arma se gasta na luta: quebrou, o guarda vem aqui buscar outra. "
		+ "O ferreiro (tecla 7) trabalha na forja, por encomenda.", Tipo.DETALHE, _hud.COLOR_DIM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_info)
	_desarmados = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_desarmados.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_desarmados)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("CAVALETE", Tipo.DETALHE, _hud.COLOR_DIM))
	_cavalete = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_cavalete.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_cavalete)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("FORJA", Tipo.DETALHE, _hud.COLOR_DIM))
	_status_forja = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_status_forja.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_forja)
	_forge_bar = _hud._bar(_hud.COLOR_TITLE)
	_forge_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_forge_bar.max_value = 1.0
	vbox.add_child(_forge_bar)
	vbox.add_child(_hud._label("ARMAS", Tipo.DETALHE, _hud.COLOR_DIM))
	for id in _def.WEAPON_IDS:
		if id == "porrete":
			continue
		var row := HBoxContainer.new()
		row.name = "Arma_" + id
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


## O HUD avisa qual Arsenal foi clicado (null = abriu pelo menu: o principal).
func focus(node: Node) -> void:
	_focus = node if node != null and node.is_in_group("arsenais") else null


func _atual() -> Node:
	if _focus != null and is_instance_valid(_focus) and _focus.is_inside_tree():
		return _focus
	return _def.arsenal()


func refresh() -> void:
	if not visible:
		return
	var todos: Array = _def.arsenais()
	var ars: Node = _atual()
	if todos.size() <= 1 or ars == null:
		_title.text = "ARSENAL"
	else:
		_title.text = "ARSENAL %d de %d — %s" % [todos.find(ars) + 1, todos.size(), "forja" if ars == _def.arsenal() else "posto de armas"]
	var unarmed: Array = _def.unarmed_guards()
	_desarmados.text = "Guardas desarmados: %d%s" % [unarmed.size(), "" if unarmed.is_empty() else "  (" + ", ".join(PackedStringArray(unarmed.map(func(w): return String(w.display_name)))) + ")"]
	_desarmados.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD if not unarmed.is_empty() else _hud.COLOR_TEXT)
	if ars == null:
		_cavalete.text = "Sem Arsenal: não dá pra forjar nem trocar arma quebrada (o guarda luta no soco). Construa em CONSTRUIR > Defesa e equipamento."
	else:
		var bits: Array[String] = []
		for id in _def.WEAPON_IDS:
			if _def.rack_count(id) > 0:
				bits.append("%d %s" % [_def.rack_count(id), _def.WEAPON_NAMES[id].to_lower()])
		_cavalete.text = "No cavalete: %s  •  pra consertar: %d  •  porrete sempre tem (de graça)." % [
			", ".join(bits) if not bits.is_empty() else "vazio", _def.broken_total()]
	var vazia: bool = _def.queue.is_empty()
	_forge_bar.visible = not vazia
	_forge_bar.value = _def.forge_progress()
	if vazia:
		_status_forja.text = "Parada: sem encomenda. Escolha uma arma abaixo (a ordem é sua; o ferreiro só anda com encomenda)."
	else:
		var eng: bool = ars != null and not ars.obra_workers().is_empty()
		_status_forja.text = "Na forja: %s — %d%%%s%s" % [_def.forge_title(), roundi(_def.forge_progress() * 100.0),
			"" if eng else "  (esperando o ferreiro — tecla 7)" if ars != null else "  (construa o Arsenal)",
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
	if not _def.queue.is_empty():
		return "Arsenal: forjando %d%%" % roundi(_def.forge_progress() * 100.0)
	var un: int = _def.unarmed_guards().size()
	return "Arsenal" + ("  •  %d desarmado%s" % [un, "s" if un > 1 else ""] if un > 0 else "")


func is_available() -> bool:
	return _def.arsenal() != null  # (sem Arsenal construído a janela não aparece no menu "Janelas")


func has_available_action() -> bool:
	return _def.arsenal() != null and not _def.unarmed_guards().is_empty() and _def.queue.is_empty()
