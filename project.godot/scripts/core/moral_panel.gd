extends PanelContainer
## Janela de Bem-estar (tecla B, botão no HUD ou clique na taverna): ânimo da vila,
## o que está incomodando/ajudando, greve e ultimato, festa e taverna.

var _hud: CanvasLayer
var _morale: Node
var _economy: Node
var _avg_label: Label
var _avg_bar: ProgressBar
var _dist_label: Label
var _strike_label: Label
var _causes: VBoxContainer
var _festa_button: Button
var _taverna_label: Label
var _taverna_button: Button
var _park_label: Label  # Bloco 41
var _park_button: Button


func setup(hud: CanvasLayer, morale: Node, economy: Node) -> void:
	_hud = hud
	_morale = morale
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
	var title: Label = _hud._label("BEM-ESTAR", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)

	var intro: Label = _hud._label(
		"Ânimo baixo derruba a produção. Se a média ficar muito baixa, eles entram em GREVE; "
		+ "se a greve durar demais, eles te expulsam da vila.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)
	_avg_label = _hud._label("", 15, _hud.COLOR_TEXT)
	row.add_child(_avg_label)
	_avg_bar = _hud._bar(_hud.COLOR_HUNGER_OK)
	_avg_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_avg_bar.custom_minimum_size.y = 12
	row.add_child(_avg_bar)
	_dist_label = _hud._label("", 12, _hud.COLOR_DIM)
	vbox.add_child(_dist_label)
	_strike_label = _hud._label("", 14, _hud.COLOR_HUNGER_BAD)
	_strike_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_strike_label)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("O QUE PESA NO ÂNIMO", 12, _hud.COLOR_DIM))
	_causes = VBoxContainer.new()
	_causes.add_theme_constant_override("separation", 1)
	vbox.add_child(_causes)

	vbox.add_child(HSeparator.new())
	_festa_button = _hud._button("")
	_festa_button.pressed.connect(func():
		Audio.click()
		_morale.throw_festa()
		refresh())
	vbox.add_child(_festa_button)
	_taverna_label = _hud._label("", 12, _hud.COLOR_DIM)
	_taverna_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_taverna_label)
	_taverna_button = _hud._button("")
	_taverna_button.pressed.connect(func():
		Audio.click()
		_morale.build_or_upgrade_taverna()
		refresh())
	vbox.add_child(_taverna_button)
	_park_label = _hud._label("", 12, _hud.COLOR_DIM)
	_park_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_park_label)
	_park_button = _hud._button("")
	_park_button.pressed.connect(func():
		Audio.click()
		_morale.build_park()
		refresh())
	vbox.add_child(_park_button)


func _color_for(h: float) -> Color:
	if h >= 75.0:
		return _hud.COLOR_HUNGER_OK
	if h >= 40.0:
		return _hud.COLOR_TEXT
	if h >= 25.0:
		return _hud.COLOR_HUNGER_LOW
	return _hud.COLOR_HUNGER_BAD


func refresh() -> void:
	if not visible or _morale == null:
		return
	var ws: Array = _morale.workers()
	var avg: float = _morale.average()
	if avg < 0.0:
		_avg_label.text = "Ânimo: —"
		_avg_bar.value = 0
	else:
		_avg_label.text = "Ânimo da vila: %d — %s" % [roundi(avg), _morale.mood_word(avg)]
		_avg_label.add_theme_color_override("font_color", _color_for(avg))
		_avg_bar.value = avg
		(_avg_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = _color_for(avg)
	var counts := [0, 0, 0, 0]
	for w in ws:
		counts[w.happiness_level()] += 1
	_dist_label.text = "revoltados %d  •  tristes %d  •  contentes %d  •  felizes %d" % counts

	if _morale.on_strike:
		var left := ceili(_morale.strike_left)
		_strike_label.text = "EM GREVE! Precisa chegar a %d de ânimo. Expulsão em %d:%02d." % [
			roundi(_morale.strike_end_at), left / 60, left % 60]
	elif _morale.below_time > 0.0:
		var left := ceili(_morale.strike_grace - _morale.below_time)
		_strike_label.text = "Revoltados! Se o ânimo não passar de %d, a greve começa em %d:%02d." % [
			roundi(_morale.strike_below), left / 60, left % 60]
	else:
		_strike_label.text = ""
	_strike_label.visible = _strike_label.text != ""

	# junta os motivos de todos: "com fome  -10  (3 ipezinhos)"
	var agg := {}
	var order: Array = []
	for w in ws:
		for f in w.happiness_factors():
			var key: String = f[0]
			if not agg.has(key):
				agg[key] = [f[1], 0]
				order.append(key)
			agg[key][1] += 1
	order.sort_custom(func(a, b): return agg[a][0] < agg[b][0])
	for c in _causes.get_children():
		c.queue_free()
	for key in order:
		var v: float = agg[key][0]
		var n: int = agg[key][1]
		var who := "todos" if n == ws.size() and ws.size() > 1 else "%d ipezinho%s" % [n, "s" if n > 1 else ""]
		var color: Color = _hud.COLOR_HUNGER_BAD if v < 0.0 else _hud.COLOR_HUNGER_OK
		_causes.add_child(_hud._label("%s %d  —  %s  (%s)" % ["+" if v >= 0.0 else "", roundi(v), key, who], 12, color))
	if order.is_empty():
		_causes.add_child(_hud._label("—", 12, _hud.COLOR_DIM))

	var festa_reason: String = _morale.festa_block_reason()
	if festa_reason == "":
		_festa_button.text = "Dar uma festa: +%d de ânimo  (%d cr + %d comida)" % [
			roundi(_morale.festa_boost), _morale.festa_credits, roundi(_morale.festa_food)]
	else:
		_festa_button.text = "Festa: " + festa_reason
	_festa_button.disabled = festa_reason != ""

	var tav: Node = _morale.taverna()
	var tav_reason: String = _morale.taverna_block_reason()
	if tav == null:
		_taverna_label.text = "Sem taverna. Com ela, quem está triste vai lá se animar (e todo mundo fica +%d)." % roundi(_morale.taverna_bonus[0])
		_taverna_button.text = ("Construir taverna — escolher lugar  (%d cr + %d madeira)" % [_morale.taverna_credits, _morale.taverna_wood]) if tav_reason == "" else "Construir taverna: " + tav_reason
	else:
		_taverna_label.text = "Taverna nível %d: %d lugares, %d na taverna agora." % [tav.level, tav.slot_count, tav.guests().size()]
		if tav_reason == "nível máximo":
			_taverna_button.text = "Taverna no tamanho máximo"
		elif tav_reason == "":
			_taverna_button.text = "Ampliar taverna: +2 lugares  (%d cr + %d madeira + %d %s)" % [
				_morale.taverna_up_credits, _morale.taverna_up_wood, _morale.taverna_up_ore, _morale.taverna_up_ore_type]
		else:
			_taverna_button.text = "Ampliar taverna: " + tav_reason
	_taverna_button.disabled = tav_reason != ""
	var n: int = _morale.parks().size()
	_park_label.text = "Parques: %d. Quem passa perto (até %d px) ganha ânimo aos pouquinhos, sem precisar ir lá." % [n, roundi(_morale.park_radius)]
	var pr: String = _morale.park_block_reason()
	_park_button.text = ("Construir parque — escolher lugar  (%d cr + %d %s + %d madeira)" % [_morale.park_credits, _morale.park_ore, _morale.park_ore_type, _morale.park_wood]) \
		if pr == "" else "Construir parque: " + pr
	_park_button.disabled = pr != ""


func button_text() -> String:
	if _morale.on_strike:
		var left := ceili(_morale.strike_left)
		return "GREVE! %d:%02d (B)" % [left / 60, left % 60]
	var avg: float = _morale.average()
	if avg < 0.0:
		return "Bem-estar (B)"
	return "Ânimo %d (B)" % roundi(avg)


func has_available_action() -> bool:
	return _morale.on_strike or _morale.below_time > 0.0 \
		or (_morale.average() < 50.0 and _morale.festa_block_reason() == "")
