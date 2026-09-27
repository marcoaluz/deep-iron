extends CanvasLayer
## Vitória: o escudo solar ficou pronto (criado pelo sun.gd). Pausa o jogo;
## "Continuar jogando" volta pra partida (sem ondas solares daqui pra frente).

const START_MENU := "res://scenes/ui/start_menu.tscn"
const COLOR_TITLE := Color(0.6, 0.9, 1.0)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.65, 0.6, 0.55)

var _box: VBoxContainer


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("victory_screen")
	var dim := ColorRect.new()
	dim.color = Color(0, 0.02, 0.05, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.96)
	style.border_color = Color(0.4, 0.7, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.custom_minimum_size = Vector2(460, 0)
	panel.add_child(_box)
	get_tree().paused = true


func setup(stats: Dictionary) -> void:
	_label("A VILA ESTÁ A SALVO!", 30, COLOR_TITLE)
	var text := _label(
		"O escudo solar acendeu sobre a mina. Pela primeira vez desde a explosão, o sol "
		+ "não é mais uma ameaça. Os ipezinhos saem das casas pra olhar o céu azulado.", 14, COLOR_TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Vitória no dia %d (%s)  •  %d ipezinhos" % [int(stats.get("day", 1)), str(stats.get("season", "")),
		int(stats.get("workers", 0))], 12, COLOR_DIM)
	_box.add_child(HSeparator.new())
	_button("Continuar jogando", func():
		get_tree().paused = false
		queue_free())
	_button("Voltar ao menu inicial", func():
		SaveManager.save_game("vitória")
		get_tree().paused = false
		get_tree().change_scene_to_file(START_MENU))
	get_tree().scene_changed.connect(queue_free, CONNECT_ONE_SHOT)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)
	return l


func _button(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(func():
		Audio.click()
		action.call())
	_box.add_child(b)
