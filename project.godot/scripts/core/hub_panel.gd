extends PanelContainer
## Janela do Centro da Vila: progresso, expandir a vila e comprar melhorias.
## Criada pelo HUD (setup) e montada por código; usa os helpers de estilo do HUD.
## Abre clicando no prédio, pela tecla U ou pelo botão no painel do HUD.
const Tipo := preload("res://scripts/ui/tipografia.gd")

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
var _starter_button: Button  # Bloco 37: casas iniciais
var _comedouro_button: Button
var _radius_label: Label
var _coletor_button: Button  # Bloco 45


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
	var title: Label = _hud._label("CENTRO DA VILA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
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

	_stage_label = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	vbox.add_child(_stage_label)
	_stats_label = _hud._label("", Tipo.CORPO, _hud.COLOR_DIM)
	vbox.add_child(_stats_label)

	vbox.add_child(HSeparator.new())
	_next_title = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	vbox.add_child(_next_title)
	_next_bar = _hud._bar(_hud.COLOR_TITLE)
	_next_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_next_bar)
	_next_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_next_label)
	_level_button = _hud._button("")
	_level_button.pressed.connect(func():
		Audio.click()
		_hub.level_up()
		refresh())
	vbox.add_child(_level_button)

	# Bloco 37: construções da vila (casas iniciais da fundação e comedouro)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("CONSTRUIR (o engenheiro ergue)", Tipo.DETALHE, _hud.COLOR_DIM))
	_radius_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_radius_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_radius_label)
	_starter_button = _hud._button("")
	_starter_button.pressed.connect(func():
		Audio.click()
		_hub.build_starter_house()
		refresh())
	vbox.add_child(_starter_button)
	_comedouro_button = _hud._button("")
	_comedouro_button.pressed.connect(func():
		Audio.click()
		_hub.build_comedouro()
		refresh())
	vbox.add_child(_comedouro_button)
	_coletor_button = _hud._button("")
	_coletor_button.pressed.connect(func():
		Audio.click()
		_hub.build_coletor()
		refresh())
	vbox.add_child(_coletor_button)

	vbox.add_child(HSeparator.new())
	var up_header := HBoxContainer.new()
	vbox.add_child(up_header)
	var up_title: Label = _hud._label("MELHORIAS", Tipo.DETALHE, _hud.COLOR_DIM)
	up_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_header.add_child(up_title)
	up_header.add_child(_hud._label("cada uma vai até o nível da vila", Tipo.DETALHE, _hud.COLOR_DIM))

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
	var name_label: Label = _hud._label(_hub.UPGRADE_NAMES[id], Tipo.TITULO, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var level_label: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TITLE)
	top.add_child(level_label)

	var desc: Label = _hud._label(_hub.upgrade_description(id), Tipo.DETALHE, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	v.add_child(bottom)
	var effect: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
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
	_stats_label.text = "População: %d ipezinhos   •   camas: %d / %d (cabe quem tem cama: os migrantes chegam no portão)\nMinério coletado (total): %d   •   créditos ganhos (total): %d" % [
		workers, taken, beds, int(_hub.lifetime_ore()), int(_economy.total_earned)]

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
		_next_label.text = "%d / %d minério coletado no total\nLibera: %s" % [int(have), need, _hub.stage_unlocks_text(lvl + 1)]
		var cost: int = _hub.next_level_cost()
		if _hub.pending_upgrade == "expandir":
			_level_button.text = "Expandindo: %s" % _hub.obra_status().split(": ", true, 1)[-1]
		elif _hub.pending_upgrade != "":
			_level_button.text = "Expandir vila  (espere a obra atual terminar)"
		elif have < need:
			_level_button.text = "Expandir vila  (falta minério coletado)"
		else:
			_level_button.text = "Expandir vila  (%d cr)" % cost
		_level_button.disabled = not _hub.can_level_up()

	# Bloco 37
	var r: float = _hub.house_radius()
	_radius_label.text = ("Casas só em volta do Centro da Vila: até %d px (cresce %d a cada estágio)." % [roundi(r), roundi(_hub.house_radius_per_stage)]) \
		if r > 0.0 else "Casas em qualquer lugar livre da mina."
	_starter_button.visible = _hub.starter_houses_left > 0
	var sr: String = _hub.starter_block_reason()
	_starter_button.text = ("Casa inicial (%d restante%s) — escolher lugar  (%s)" % [_hub.starter_houses_left, "s" if _hub.starter_houses_left > 1 else "", _hub.starter_cost_text()]) \
		if sr == "" else "Casa inicial: " + sr
	_starter_button.disabled = sr != ""
	var cr: String = _hub.comedouro_block_reason()
	_comedouro_button.text = ("Cozinha — escolher lugar  (%s)" % _hub.comedouro_cost_text()) if cr == "" else "Cozinha: " + cr
	_comedouro_button.disabled = cr != ""
	var colr: String = _hub.coletor_block_reason()
	_coletor_button.text = ("Outro coletor de madeira — escolher lugar na clareira  (%s)" % _hub.coletor_cost_text()) if colr == "" \
		else "Outro coletor de madeira: " + colr
	_coletor_button.disabled = colr != ""
	_coletor_button.visible = _hub.coletor_restaurado()  # Bloco 81: o primeiro é a ruína da floresta

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
		if reason == "em obra":
			button.text = "Em obra: %s" % _hub.obra_status().split(": ", true, 1)[-1]
		elif reason == "outra melhoria em obra":
			button.text = "Espere a obra atual terminar"
		elif cur >= mx:
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
	if _hub.obra_pending():
		return "Vila: obra %d%%%s (U)" % [roundi(_hub.obra_progress() * 100.0), "" if not _hub.obra_workers().is_empty() else " sem eng."]
	return "Vila: %s (U)" % _hub.stage_name()


func has_available_action() -> bool:
	if _hub.can_level_up():
		return true
	# Bloco 37: casa inicial da fundação ainda por construir (guia o começo da partida)
	if _hub.starter_houses_left > 0 and _hub.starter_block_reason() == "":
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
