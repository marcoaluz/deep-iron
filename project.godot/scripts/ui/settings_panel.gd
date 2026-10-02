extends VBoxContainer
## Tela de configurações. Usada no menu de pausa e na tela inicial. Cada mudança já vale na hora e
## fica salva em settings.cfg (e volta ao abrir o jogo).
## Bloco 54: duas colunas — SOM E VÍDEO (volumes, música, tela cheia, escala da interface) e JOGO
## (velocidade da câmera e do zoom, reduzir efeitos, idioma, dicas, teclas). "Teclas..." abre a
## página de remapear (clique na ação e aperte a tecla nova; Esc cancela; "Restaurar padrão").

signal back_pressed

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Settings := preload("res://scripts/core/settings.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const Efeitos := preload("res://scripts/core/efeitos.gd")
const Camera := preload("res://scripts/core/camera_controller.gd")
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.7, 0.66, 0.6)

var _fullscreen: CheckBox
var _main_page: VBoxContainer
var _keys_page: VBoxContainer
var _key_buttons := {}  # ação -> Button
var _waiting := ""  # ação esperando a tecla nova
var _scale_note: Label


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_main_page = VBoxContainer.new()
	_main_page.add_theme_constant_override("separation", 10)
	add_child(_main_page)
	_keys_page = VBoxContainer.new()
	_keys_page.add_theme_constant_override("separation", 8)
	_keys_page.visible = false
	add_child(_keys_page)
	_build_main()
	_build_keys()


func _build_main() -> void:
	var title := _label("CONFIGURAÇÕES", 22, COLOR_TITLE)
	UiSkin.usa_fonte(title, "titulo", 32)  # Prompt 22
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_page.add_child(title)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	_main_page.add_child(cols)
	var left := _column(cols, "SOM E VÍDEO")
	var right := _column(cols, "JOGO")

	_slider(left, "Volume geral", "master_volume")
	_slider(left, "Música", "music_volume")
	_slider(left, "Ambiente da caverna", "ambience_volume")
	_slider(left, "Efeitos", "sfx_volume")
	var music := CheckBox.new()
	music.text = "Música ligada  (M)"
	music.button_pressed = Audio.music_enabled
	music.toggled.connect(func(on: bool):
		if on != Audio.music_enabled:
			Audio.toggle_music())
	left.add_child(music)
	# Bloco 48: tela cheia (F11 / Alt+Enter também alternam; a escolha fica salva)
	_fullscreen = CheckBox.new()
	_fullscreen.text = "Tela cheia  (F11 / Alt+Enter)"
	_fullscreen.button_pressed = WindowManager.is_fullscreen()
	_fullscreen.toggled.connect(func(on: bool):
		Audio.click()
		WindowManager.set_fullscreen(on))
	left.add_child(_fullscreen)
	WindowManager.fullscreen_changed.connect(_on_fullscreen_changed)
	# Bloco 54: escala da interface (limitada pra caber na janela)
	_percent(left, "Escala da interface", WindowManager.ui_scale(), WindowManager.UI_SCALE_MIN, WindowManager.UI_SCALE_MAX, 0.1,
		func(v: float): WindowManager.set_ui_scale(v))
	_scale_note = _label("", 11, COLOR_DIM)
	left.add_child(_scale_note)
	WindowManager.ui_scale_changed.connect(func(_f: float): _update_scale_note())
	_update_scale_note()

	_percent(right, "Velocidade da câmera", Settings.get_value("camera", "pan_mult", 1.0), 0.5, 2.0, 0.1, func(v: float):
		Settings.set_value("camera", "pan_mult", v)
		Camera.load_speeds())
	_percent(right, "Velocidade do zoom", Settings.get_value("camera", "zoom_mult", 1.0), 0.5, 2.0, 0.1, func(v: float):
		Settings.set_value("camera", "zoom_mult", v)
		Camera.load_speeds())
	var fx := CheckBox.new()
	fx.text = "Reduzir efeitos (clima, tremor, partículas)"
	fx.button_pressed = Efeitos.reduzidos()
	fx.toggled.connect(func(on: bool):
		Audio.click()
		Efeitos.set_reduzidos(on, get_tree()))
	right.add_child(fx)
	var hints := CheckBox.new()
	hints.text = "Mostrar dicas de controle  (H)"
	hints.button_pressed = Settings.get_value("hud", "show_hints", false)
	hints.toggled.connect(func(on: bool):
		Settings.set_value("hud", "show_hints", on)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("set_hints_visible"):
			hud.set_hints_visible(on))
	right.add_child(hints)
	# idioma
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 10)
	right.add_child(lang_row)
	var ll := _label("Idioma", 14, COLOR_TEXT)
	ll.custom_minimum_size.x = 150
	lang_row.add_child(ll)
	var lang := OptionButton.new()
	lang.name = "Idioma"
	for i in WindowManager.IDIOMAS.size():
		lang.add_item(WindowManager.IDIOMAS[i][1], i)
		lang.set_item_metadata(i, WindowManager.IDIOMAS[i][0])
		if WindowManager.IDIOMAS[i][0] == WindowManager.language():
			lang.select(i)
	lang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang.item_selected.connect(func(i: int):
		Audio.click()
		WindowManager.set_language(String(lang.get_item_metadata(i))))
	lang_row.add_child(lang)
	right.add_child(_label("(inglês parcial: textos com números seguem em português)", 11, COLOR_DIM))
	var keys := Button.new()
	keys.text = "Teclas..."
	keys.custom_minimum_size = Vector2(0, 34)
	keys.pressed.connect(func():
		Audio.click()
		_show_keys(true))
	right.add_child(keys)

	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(0, 38)
	back.pressed.connect(func():
		Audio.click()
		back_pressed.emit())
	_main_page.add_child(back)


func _column(parent: Container, titulo: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size.x = 340
	parent.add_child(v)
	v.add_child(_label(titulo, 13, COLOR_TITLE))
	return v


func _update_scale_note() -> void:
	if _scale_note == null:
		return
	var want := WindowManager.ui_scale()
	var got := WindowManager.applied_ui_scale()
	_scale_note.text = "" if is_equal_approx(want, got) else "nesta janela cabe até %d%% (usando %d%%)" % [roundi(WindowManager.max_ui_scale() * 100.0), roundi(got * 100.0)]


## F11 com a janela aberta: a caixinha acompanha.
func _on_fullscreen_changed(on: bool) -> void:
	if _fullscreen:
		_fullscreen.set_pressed_no_signal(on)


## Linha "nome  [====slider====]  75%" ligada a uma variável de volume do Audio.
func _slider(parent: Container, text: String, audio_var: String) -> void:
	_percent(parent, text, float(Audio.get(audio_var)), 0.0, 1.0, 0.05, func(v: float):
		Audio.set(audio_var, v)
		Audio.apply_volumes()
		Audio.save_settings())


## Linha "nome  [====slider====]  100%" de um valor entre lo e hi (mostrado em %).
func _percent(parent: Container, text: String, value: float, lo: float, hi: float, step: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var name_label := _label(text, 14, COLOR_TEXT)
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.name = text
	slider.min_value = lo * 100.0
	slider.max_value = hi * 100.0
	slider.step = step * 100.0
	slider.value = roundf(value * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := _label("%d%%" % slider.value, 13, COLOR_TEXT)
	value_label.custom_minimum_size.x = 44
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float):
		value_label.text = "%d%%" % v
		on_change.call(v / 100.0))
	slider.drag_ended.connect(func(_changed: bool): Audio.click())
	return slider


# ------------------------------------------------------------ teclas (Bloco 54)
func _build_keys() -> void:
	var title := _label("TECLAS", 22, COLOR_TITLE)
	UiSkin.usa_fonte(title, "titulo", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keys_page.add_child(title)
	_keys_page.add_child(_label("Clique numa ação e aperte a tecla nova (Esc cancela). Se outra ação usava a tecla, as duas trocam.", 12, COLOR_DIM))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_keys_page.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for par in Teclas.NOMES:
		var l := _label(par[1], 13, COLOR_TEXT)
		l.custom_minimum_size.x = 190
		grid.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(120, 26)
		b.focus_mode = Control.FOCUS_NONE
		var acao: String = par[0]
		b.pressed.connect(func():
			Audio.click()
			_waiting = acao
			_refresh_keys())
		grid.add_child(b)
		_key_buttons[acao] = b
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_keys_page.add_child(row)
	var reset := Button.new()
	reset.text = "Restaurar padrão"
	reset.custom_minimum_size = Vector2(0, 36)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(func():
		Audio.click()
		Teclas.restaura_padrao()
		_waiting = ""
		_refresh_keys())
	row.add_child(reset)
	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(0, 36)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func():
		Audio.click()
		_show_keys(false))
	row.add_child(back)
	_refresh_keys()


func _show_keys(on: bool) -> void:
	_waiting = ""
	_keys_page.visible = on
	_main_page.visible = not on
	_refresh_keys()


func _refresh_keys() -> void:
	for acao in _key_buttons:
		_key_buttons[acao].text = "aperte uma tecla..." if acao == _waiting else Teclas.nome(acao)
	var hud := get_tree().get_first_node_in_group("hud") if is_inside_tree() else null
	if hud and hud.has_method("_fill_hints"):
		hud._fill_hints()


## Esperando a tecla nova: pega antes do resto do jogo (Esc cancela).
func _input(event: InputEvent) -> void:
	if _waiting == "" or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var k: int = event.physical_keycode
		if k != KEY_ESCAPE:
			if Teclas.permitida(k):
				Teclas.define(_waiting, k)
			else:
				Audio.error()
				return
		_waiting = ""
		_refresh_keys()


## Fechou a página (Esc no menu de pausa / Voltar): volta pra página principal.
func reset_page() -> void:
	_show_keys(false)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
