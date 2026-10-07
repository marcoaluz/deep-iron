extends CanvasLayer
## Menu de pausa (criado pelo main.gd). Esc (sem janela aberta nem seleção) ou P.
## Pausa o jogo; Continuar, Configurações, Salvar, Menu inicial e Sair.
## "Menu inicial" e "Sair" salvam antes (mesmo save do F5).

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const START_MENU := "res://scenes/ui/start_menu.tscn"
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_PANEL := Color(0.09, 0.075, 0.07, 0.95)
const COLOR_BORDER := Color(0.55, 0.38, 0.18)

var _main_page: VBoxContainer
var _settings_page: VBoxContainer
var _panel: PanelContainer


func _ready() -> void:
	UiSkin.tema_na_camada(self)  # Bloco 95: o tema (escala e fonte) chega nos Controls da camada
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	add_to_group("pause_menu")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	var style: StyleBox = UiSkin.painel(18)  # Prompt 20: a pele nova
	if not UiSkin.ok():
		var f := StyleBoxFlat.new()
		f.bg_color = COLOR_PANEL
		f.border_color = COLOR_BORDER
		f.set_border_width_all(2)
		f.set_corner_radius_all(4)
		f.set_content_margin_all(18)
		style = f
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	_main_page = VBoxContainer.new()
	_main_page.add_theme_constant_override("separation", 10)
	_main_page.custom_minimum_size = Vector2(300, 0)
	_panel.add_child(_main_page)
	var title := Label.new()
	title.text = "PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Tipo.FAIXA)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	_main_page.add_child(title)
	_button("Continuar  (Esc)", close)
	_button("Configurações", _show_settings)
	_button("Salvar jogo  (F5)", func():
		SaveManager.save_game("manual"))
	_button("Salvar e voltar ao menu inicial", _to_start_menu)
	_button("Salvar e sair do jogo", _quit)

	_settings_page = SettingsPanel.new()
	_settings_page.back_pressed.connect(_show_main)
	_panel.add_child(_settings_page)
	_settings_page.visible = false
	visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	visible = true
	_show_main()
	get_tree().paused = true
	Audio.click()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode in [KEY_ESCAPE, preload("res://scripts/core/teclas.gd").tecla("pausa")]:
		get_viewport().set_input_as_handled()
		Audio.click()
		if _settings_page.visible:
			_show_main()
		else:
			close()


func _show_settings() -> void:
	_main_page.visible = false
	_settings_page.visible = true


func _show_main() -> void:
	if _settings_page.has_method("reset_page"):
		_settings_page.reset_page()  # Bloco 54: saiu da página de teclas também
	_settings_page.visible = false
	_main_page.visible = true


func _to_start_menu() -> void:
	SaveManager.save_game("ao sair pro menu")
	get_tree().paused = false
	get_tree().change_scene_to_file(START_MENU)


func _quit() -> void:
	SaveManager.save_game("ao fechar")
	get_tree().quit()


func _button(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", Tipo.TITULO)
	b.pressed.connect(func():
		Audio.click()
		action.call())
	_main_page.add_child(b)
