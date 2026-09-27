extends PanelContainer
## Janela da Plataforma do Abismo (clique na plataforma no fundo do nível 2, ou no
## botão do HUD, que aparece quando o nível 2 abre): consertar e abrir o nível 3.

var _hud: CanvasLayer
var _shaft: Node
var _status: Label
var _desc: Label
var _bar: ProgressBar
var _button: Button


func setup(hud: CanvasLayer, shaft: Node, _economy: Node) -> void:
	_hud = hud
	_shaft = shaft
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(440, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("O ABISMO (NÍVEL 3)", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var lore: Label = _hud._label(
		"No fundo do nível 2 tem uma plataforma velha, arruinada, que desce ainda mais. "
		+ "Lá embaixo a rocha guardou o calor da explosão solar: a SOLARITA.", 12, _hud.COLOR_DIM)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lore)
	_status = _hud._label("", 15, _hud.COLOR_TEXT)
	vbox.add_child(_status)
	_desc = _hud._label("", 12, _hud.COLOR_DIM)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_desc)
	_bar = _hud._bar(_hud.COLOR_TITLE)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.max_value = 1.0
	vbox.add_child(_bar)
	_button = _hud._button("")
	_button.pressed.connect(func():
		Audio.click()
		_shaft.start_repair()
		refresh())
	vbox.add_child(_button)


func refresh() -> void:
	if not visible:
		return
	var reason: String = _shaft.repair_block_reason()
	_bar.visible = _shaft.repairing
	_bar.value = _shaft.repair_progress()
	_button.visible = not _shaft.unlocked and not _shaft.repairing
	if _shaft.unlocked:
		_status.text = "Aberto: a plataforma desce pro nível 3"
		_desc.text = "Solarita: vale muito (e vai ser importante contra a radiação). Precisa do Traje de chumbo (Oficina). " \
			+ "Acidentes lá são 4x mais comuns e mais graves, e o calor tira o ânimo de quem trabalha no abismo."
	elif _shaft.repairing:
		_status.text = "Consertando... faltam %ds" % ceili(_shaft.repair_left)
		_desc.text = "A gaiola, as correntes e a polia estão sendo trocadas."
	else:
		_status.text = "Plataforma arruinada"
		_desc.text = "Conserto: %d peças raras + %d cr + %d prata, %ds de trabalho (vila nível %d)." % [
			_shaft.repair_parts, _shaft.repair_credits, _shaft.repair_silver, roundi(_shaft.repair_time), _shaft.repair_min_stage]
		_button.text = "Consertar a plataforma" if reason == "" else "Consertar: " + reason
		_button.disabled = reason != ""


func is_available() -> bool:
	return _shaft.level2_open()


func button_text() -> String:
	if _shaft.unlocked:
		return "Abismo aberto"
	if _shaft.repairing:
		return "Abismo %d%%" % roundi(_shaft.repair_progress() * 100.0)
	return "Abismo: consertar"


func has_available_action() -> bool:
	return _shaft.repair_block_reason() == ""
