extends PanelContainer
## Janela do Sol (tecla Y, ou clique no gerador do escudo): estação, previsão das
## ondas solares e a obra do escudo (a vitória).

var _hud: CanvasLayer
var _sun: Node
var _season: Label
var _forecast: Label
var _place_button: Button
var _stage_rows: Dictionary = {}  # id -> {status, button}
var _bar: ProgressBar
var _stages_box: VBoxContainer


func setup(hud: CanvasLayer, sun: Node, _economy: Node) -> void:
	_hud = hud
	_sun = sun
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
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("O SOL", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_season = _hud._label("", 14, _hud.COLOR_TEXT)
	_season.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_season)
	_forecast = _hud._label("", 13, _hud.COLOR_TEXT)
	_forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_forecast)
	var info: Label = _hud._label(
		"Nas ondas solares, quem está na mina ou na clareira fora de casa acumula radiação e se "
		+ "machuca. No nível 2 e no abismo a rocha protege. O sol piora a cada dia: só o escudo resolve.",
		11, _hud.COLOR_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("ESCUDO SOLAR (vitória)", 13, _hud.COLOR_TITLE))
	_place_button = _hud._button("")
	_place_button.pressed.connect(func():
		Audio.click()
		_sun.place_shield()
		refresh())
	vbox.add_child(_place_button)
	_bar = _hud._bar(_hud.COLOR_TITLE)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.max_value = 1.0
	vbox.add_child(_bar)
	_stages_box = VBoxContainer.new()
	_stages_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_stages_box)
	var escudo_script := preload("res://scripts/props/escudo.gd")
	for id in escudo_script.STAGE_IDS:
		var row := HBoxContainer.new()
		_stages_box.add_child(row)
		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_box)
		info_box.add_child(_hud._label(escudo_script.STAGE_NAMES[id], 13, _hud.COLOR_TEXT))
		var status: Label = _hud._label("", 11, _hud.COLOR_DIM)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_box.add_child(status)
		var b: Button = _hud._button("Construir")
		b.custom_minimum_size.x = 110
		b.pressed.connect(func():
			Audio.click()
			var s: Node = _sun.shield()
			if s:
				s.start_stage(id)
			refresh())
		row.add_child(b)
		_stage_rows[id] = {"status": status, "button": b}


func refresh() -> void:
	if not visible:
		return
	_season.text = "%s — dia %d de %d da estação" % [_sun.season_name(), _sun.day_in_season(), _sun.days_per_season]
	_forecast.text = _sun.forecast_text()
	_forecast.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD if _sun.wave_active() or _sun.time_to_wave() >= 0.0 and _sun.warned else _hud.COLOR_TEXT)
	var s: Node = _sun.shield()
	var reason: String = _sun.shield_block_reason()
	_place_button.visible = s == null
	_place_button.text = "Marcar o lugar do gerador do escudo" if reason == "" else "Gerador do escudo: " + reason
	_place_button.disabled = reason != ""
	_stages_box.visible = s != null
	_bar.visible = s != null and s.building != ""
	if s == null:
		return
	_bar.value = s.build_progress()
	for id in _stage_rows:
		var row: Dictionary = _stage_rows[id]
		var r: String = s.stage_block_reason(id)
		var status: Label = row.status
		var b: Button = row.button
		match r:
			"pronta":
				status.text = "PRONTA"
				status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK)
			"construindo":
				status.text = "construindo %d%%" % roundi(s.build_progress() * 100.0)
				status.add_theme_color_override("font_color", _hud.COLOR_TITLE)
			"":
				status.text = s.stage_cost_text(id)
				status.add_theme_color_override("font_color", _hud.COLOR_TEXT)
			_:
				status.text = s.stage_cost_text(id) + "  (" + r + ")"
				status.add_theme_color_override("font_color", _hud.COLOR_DIM)
		b.visible = r not in ["pronta", "construindo"]
		b.disabled = r != ""


func button_text() -> String:
	if _sun.won:
		return "Escudo ativo (Y)"
	if _sun.wave_active():
		return "ONDA SOLAR! (Y)"
	return "%s (Y)" % _sun.season_name()


func has_available_action() -> bool:
	if _sun.wave_active() or (_sun.warned and _sun.time_to_wave() >= 0.0):
		return true
	var s: Node = _sun.shield()
	if s == null:
		return _sun.shield_block_reason() == ""
	return s.next_stage() != "" and s.stage_block_reason(s.next_stage()) == ""
