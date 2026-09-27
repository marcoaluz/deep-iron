extends PanelContainer
## Janela da Enfermaria: leitos, pacientes, quem está esperando (com o relógio
## de "sem cuidado" correndo), ampliar (melhoria do Centro da Vila) e o memorial.
## Abre clicando na enfermaria, pela tecla I ou pelo botão no painel do HUD.

var _hud: CanvasLayer
var _inf: Node
var _economy: Node
var _beds_label: Label
var _list: VBoxContainer
var _upgrade_button: Button
var _memorial: VBoxContainer


func setup(hud: CanvasLayer, inf: Node, economy: Node) -> void:
	_hud = hud
	_inf = inf
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
	var title: Label = _hud._label("ENFERMARIA", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)

	var intro: Label = _hud._label(
		"Machucado só se cura aqui, deitado num leito. Sem leito, o tempo corre: "
		+ "leve piora pra grave, grave pode morrer.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_beds_label = _hud._label("", 14, _hud.COLOR_TEXT)
	vbox.add_child(_beds_label)
	_upgrade_button = _hud._button("")
	_upgrade_button.pressed.connect(func():
		Audio.click()
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub:
			hub.buy_upgrade("enfermaria")
		refresh())
	vbox.add_child(_upgrade_button)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("PACIENTES E ESPERA", 12, _hud.COLOR_DIM))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	vbox.add_child(_list)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("MEMORIAL", 12, _hud.COLOR_DIM))
	_memorial = VBoxContainer.new()
	vbox.add_child(_memorial)


func refresh() -> void:
	if not visible or _inf == null:
		return
	var hub := get_tree().get_first_node_in_group("village_hub")
	_beds_label.text = "Leitos ocupados: %d / %d   •   cura no leito: leve %ds, grave %ds" % [
		_inf.patients().size(), _inf.beds_total(), roundi(_inf.heal_time("leve")), roundi(_inf.heal_time("grave"))]
	if hub:
		var reason: String = hub.upgrade_block_reason("enfermaria")
		var cost: Vector2i = hub.upgrade_cost("enfermaria")
		if reason == "":
			_upgrade_button.text = "Ampliar: +%d leito  (%d cr + %d minério)" % [_inf.beds_per_level, cost.x, cost.y]
		elif reason == "nível máximo":
			_upgrade_button.text = "Enfermaria no tamanho máximo"
		else:
			_upgrade_button.text = "Ampliar: " + reason
		_upgrade_button.disabled = reason != ""

	for c in _list.get_children():
		c.queue_free()
	var any := false
	for w in _inf.patients():
		any = true
		_list.add_child(_hud._label("✚ %s — %s — cura em %ds" % [
			_name(w), w.injury_severity, ceili(w._recovery_left)], 13, _hud.COLOR_HUNGER_OK))
	var no_bed: Array = _inf.without_bed()
	for w in _inf.waiting():
		any = true
		var color: Color = _hud.COLOR_HUNGER_BAD if no_bed.has(w) or w.injury_severity == "grave" else _hud.COLOR_HUNGER_LOW
		_list.add_child(_hud._label("! %s — %s" % [_name(w), w.get_state_label()], 13, color))
	if not any:
		_list.add_child(_hud._label("ninguém machucado", 12, _hud.COLOR_DIM))

	for c in _memorial.get_children():
		c.queue_free()
	if _inf.memorial.is_empty():
		_memorial.add_child(_hud._label("ninguém morreu (ainda)", 12, _hud.COLOR_DIM))
	for e in _inf.memorial:
		_memorial.add_child(_hud._label("† %s — dia %d — acidente %s (%s)" % [
			str(e.get("name", "?")), int(e.get("day", 1)), str(e.get("severity", "?")), str(e.get("cause", "?"))], 12, _hud.COLOR_DIM))


func _name(w: Node) -> String:
	var n = w.get("display_name")
	return n if n is String and n != "" else String(w.name)


func button_text() -> String:
	var waiting_n: int = _inf.without_bed().size()
	var t := "Enfermaria %d/%d" % [_inf.patients().size(), _inf.beds_total()]
	if waiting_n > 0:
		t += " +%d fora!" % waiting_n
	return t + " (I)"


## Destaca o botão quando tem gente sem leito (ou a ampliação cabe no bolso).
func has_available_action() -> bool:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return not _inf.without_bed().is_empty() or (hub != null and hub.upgrade_block_reason("enfermaria") == "")
