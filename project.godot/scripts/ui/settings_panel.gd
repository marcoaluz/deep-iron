extends VBoxContainer
## Tela de configurações (volumes, música, tela cheia, dicas do HUD). Usada no menu de pausa
## e na tela inicial. Cada mudança já vale na hora e fica salva em settings.cfg.

signal back_pressed

const Settings := preload("res://scripts/core/settings.gd")
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)

var _fullscreen: CheckBox


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	custom_minimum_size = Vector2(360, 0)
	var title := _label("CONFIGURAÇÕES", 22, COLOR_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	_slider("Volume geral", "master_volume")
	_slider("Música", "music_volume")
	_slider("Ambiente da caverna", "ambience_volume")
	_slider("Efeitos", "sfx_volume")

	var music := CheckBox.new()
	music.text = "Música ligada  (M)"
	music.button_pressed = Audio.music_enabled
	music.toggled.connect(func(on: bool):
		if on != Audio.music_enabled:
			Audio.toggle_music())
	add_child(music)

	# Bloco 48: tela cheia (F11 / Alt+Enter também alternam; a escolha fica salva)
	_fullscreen = CheckBox.new()
	_fullscreen.text = "Tela cheia  (F11 / Alt+Enter)"
	_fullscreen.button_pressed = WindowManager.is_fullscreen()
	_fullscreen.toggled.connect(func(on: bool):
		Audio.click()
		WindowManager.set_fullscreen(on))
	add_child(_fullscreen)
	WindowManager.fullscreen_changed.connect(_on_fullscreen_changed)

	var hints := CheckBox.new()
	hints.text = "Mostrar dicas de controle  (H)"
	hints.button_pressed = Settings.get_value("hud", "show_hints", false)
	hints.toggled.connect(func(on: bool):
		Settings.set_value("hud", "show_hints", on)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("set_hints_visible"):
			hud.set_hints_visible(on))
	add_child(hints)

	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(0, 38)
	back.pressed.connect(func():
		Audio.click()
		back_pressed.emit())
	add_child(back)


## F11 com a janela aberta: a caixinha acompanha.
func _on_fullscreen_changed(on: bool) -> void:
	if _fullscreen:
		_fullscreen.set_pressed_no_signal(on)


## Linha "nome  [====slider====]  75%" ligada a uma variável de volume do Audio.
func _slider(text: String, audio_var: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var name_label := _label(text, 14, COLOR_TEXT)
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = roundf(float(Audio.get(audio_var)) * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := _label("%d%%" % slider.value, 13, COLOR_TEXT)
	value_label.custom_minimum_size.x = 44
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float):
		value_label.text = "%d%%" % v
		Audio.set(audio_var, v / 100.0)
		Audio.apply_volumes()
		Audio.save_settings())
	slider.drag_ended.connect(func(_changed: bool): Audio.click())


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
