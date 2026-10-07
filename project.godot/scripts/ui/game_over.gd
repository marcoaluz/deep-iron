extends CanvasLayer
## Fim de jogo: a greve passou do ultimato e os ipezinhos expulsaram o jogador.
## Criado pelo morale.gd. Pausa o jogo; o save NÃO é sobrescrito (SaveManager.game_over),
## então "Carregar último save" volta pro último ponto salvo antes da derrota.

const Icones := preload("res://scripts/ui/icones.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const START_MENU := "res://scenes/ui/start_menu.tscn"
const COLOR_TITLE := Color(1.0, 0.42, 0.32)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.65, 0.6, 0.55)
const COLOR_PANEL := Color(0.09, 0.06, 0.06, 0.96)
const COLOR_BORDER := Color(0.6, 0.22, 0.16)

var _box: VBoxContainer


func _ready() -> void:
	UiSkin.tema_na_camada(self)  # Bloco 95: o tema (escala e fonte) chega nos Controls da camada
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_over")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style: StyleBox = UiSkin.painel(18)  # Prompt 20: a pele nova
	if not UiSkin.ok():
		var f := StyleBoxFlat.new()
		f.bg_color = COLOR_PANEL
		f.border_color = COLOR_BORDER
		f.set_border_width_all(2)
		f.set_corner_radius_all(4)
		f.set_content_margin_all(22)
		style = f
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.custom_minimum_size = Vector2(440, 0)
	panel.add_child(_box)
	get_tree().paused = true


func setup(stats: Dictionary) -> void:
	var ilu := Icones.ilustracao("expulso_derrota")
	if ilu:  # Prompt 24/26: a cena (2x, pixel inteiro)
		var img := TextureRect.new()
		img.texture = ilu
		img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = ilu.get_size() * 2.0
		_box.add_child(img)
	_label("EXPULSO DA VILA", Tipo.TELA, COLOR_TITLE)
	var text := _label(
		"A greve passou do limite. Numa assembleia na praça, os ipezinhos votaram, "
		+ "tiraram você do comando da vila e te puseram pra fora da mina.", Tipo.TITULO, COLOR_TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Dia %d  •  %d ipezinhos  •  %s  •  %d de minério extraído" % [
		int(stats.get("day", 1)), int(stats.get("workers", 0)), str(stats.get("stage", "")),
		int(stats.get("ore", 0.0))], Tipo.DETALHE, COLOR_DIM)
	_box.add_child(HSeparator.new())
	if SaveManager.has_save():
		_button("Carregar último save", func(): SaveManager.load_game())
	_button("Novo jogo", func():
		get_tree().paused = false
		SaveManager.start_new_game())
	_button("Voltar ao menu inicial", func():
		get_tree().paused = false
		get_tree().change_scene_to_file(START_MENU))
	# some junto com a partida (troca de cena)
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
	b.add_theme_font_size_override("font_size", Tipo.TITULO)
	b.pressed.connect(func():
		Audio.click()
		action.call())
	_box.add_child(b)
