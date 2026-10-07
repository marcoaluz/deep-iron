extends PanelContainer
## Janela da Enfermaria: leitos, pacientes, quem está esperando (com o relógio
## de "sem cuidado" correndo), ampliar (melhoria do Centro da Vila) e o memorial.
## Abre clicando na enfermaria, pela tecla I ou pelo botão no painel do HUD.
## Bloco 47: pode ter enfermarias extras. A janela mostra a CLICADA (tecla/botão: a principal);
## o memorial é sempre o da principal; o botão do HUD soma todas.
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _inf: Node
var _main_inf: Node  # a principal (memorial)
var _economy: Node
var _title: Label
var _new_button: Button
var _beds_label: Label
var _list: VBoxContainer
var _upgrade_button: Button
var _memorial: VBoxContainer


func setup(hud: CanvasLayer, inf: Node, economy: Node) -> void:
	_hud = hud
	_inf = inf
	_main_inf = inf
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
	_title = _hud._label("ENFERMARIA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)

	var intro: Label = _hud._label(
		"Machucado só se cura aqui, deitado num leito. Sem leito, o tempo corre: "
		+ "leve piora pra grave, grave pode morrer.", Tipo.DETALHE, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_beds_label = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	vbox.add_child(_beds_label)
	_upgrade_button = _hud._button("")
	_upgrade_button.pressed.connect(func():
		Audio.click()
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub:
			hub.buy_upgrade("enfermaria")
		refresh())
	vbox.add_child(_upgrade_button)
	_new_button = _hud._button("")
	_new_button.pressed.connect(func():
		Audio.click()
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub:
			hub.build_enfermaria()
		refresh())
	vbox.add_child(_new_button)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("PACIENTES E ESPERA", Tipo.DETALHE, _hud.COLOR_DIM))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	vbox.add_child(_list)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("MEMORIAL", Tipo.DETALHE, _hud.COLOR_DIM))
	_memorial = VBoxContainer.new()
	vbox.add_child(_memorial)


## Bloco 47: o HUD avisa qual enfermaria foi clicada (null = a principal).
func focus(node: Node) -> void:
	_inf = node if node != null and node.is_in_group("enfermarias") else _main_inf


func _wards() -> Array:
	return get_tree().get_nodes_in_group("enfermarias")


func refresh() -> void:
	if not visible or _inf == null:
		return
	if not is_instance_valid(_inf) or not _inf.is_inside_tree():
		_inf = _main_inf
	var hub := get_tree().get_first_node_in_group("village_hub")
	var wards := _wards()
	_title.text = "ENFERMARIA" if wards.size() <= 1 else "ENFERMARIA %d de %d%s" % [wards.find(_inf) + 1, wards.size(), " (extra)" if _inf.extra else " (principal)"]
	_beds_label.text = "Leitos ocupados: %d / %d   •   cura no leito: leve %ds, grave %ds" % [
		_inf.patients().size(), _inf.beds_total(), roundi(_inf.heal_time("leve")), roundi(_inf.heal_time("grave"))]
	if wards.size() > 1:
		var p := 0
		var b := 0
		for w in wards:
			p += w.patients().size()
			b += w.beds_total()
		_beds_label.text += "\nNa vila: %d enfermarias, %d / %d leitos (a ampliação vale pra todas)." % [wards.size(), p, b]
	if hub:
		var n_extra: int = hub.extra_enfermarias().size()
		var new_reason: String = hub.enfermaria_block_reason()
		var what := "Construir outra enfermaria" + (" (tem %d extra%s)" % [n_extra, "s" if n_extra > 1 else ""] if n_extra > 0 else "")
		_new_button.text = ("%s — escolher lugar  (%s)" % [what, hub.enfermaria_cost_text()]) if new_reason == "" else "%s: %s" % [what, new_reason]
		_new_button.disabled = new_reason != ""
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
			_name(w), w.injury_severity, ceili(w._recovery_left)], Tipo.CORPO, _hud.COLOR_HUNGER_OK))
	var no_bed: Array = _inf.without_bed()
	for w in _inf.waiting():
		any = true
		var color: Color = _hud.COLOR_HUNGER_BAD if no_bed.has(w) or w.injury_severity == "grave" else _hud.COLOR_HUNGER_LOW
		_list.add_child(_hud._label("! %s — %s" % [_name(w), w.get_state_label()], Tipo.CORPO, color))
	if not any:
		_list.add_child(_hud._label("ninguém machucado", Tipo.DETALHE, _hud.COLOR_DIM))

	for c in _memorial.get_children():
		c.queue_free()
	if _main_inf.memorial.is_empty():
		_memorial.add_child(_hud._label("ninguém morreu (ainda)", Tipo.DETALHE, _hud.COLOR_DIM))
	for e in _main_inf.memorial:
		_memorial.add_child(_hud._label("† %s — dia %d — acidente %s (%s)" % [
			str(e.get("name", "?")), int(e.get("day", 1)), str(e.get("severity", "?")), str(e.get("cause", "?"))], Tipo.DETALHE, _hud.COLOR_DIM))


func _name(w: Node) -> String:
	var n = w.get("display_name")
	return n if n is String and n != "" else String(w.name)


func button_text() -> String:
	# Bloco 47: soma todas as enfermarias
	var waiting_n := 0
	var p := 0
	var b := 0
	for w in _wards():
		waiting_n += w.without_bed().size()
		p += w.patients().size()
		b += w.beds_total()
	var t := "Enfermaria%s %d/%d" % ["s" if _wards().size() > 1 else "", p, b]
	if waiting_n > 0:
		t += " +%d fora!" % waiting_n
	return t + " (I)"


## Destaca o botão quando tem gente sem leito (ou a ampliação cabe no bolso).
func has_available_action() -> bool:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return _wards().any(func(w): return not w.without_bed().is_empty()) or (hub != null and hub.upgrade_block_reason("enfermaria") == "")
