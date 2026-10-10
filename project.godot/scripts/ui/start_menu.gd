extends Control
## Tela inicial (cena principal do projeto): "Continuar" / "Novo jogo".
##
## - Sem save e sem backups na pasta: abre a tela de Nova partida (Bloco 113: a escolha da dificuldade).
## - Save legível: mostra o resumo (dia, estágio, ipezinhos, quando salvou).
##     Continuar  -> carrega o save.
##     Novo jogo  -> pede confirmação; o save atual NÃO é apagado: vira um backup
##                   com data/hora em user://backups e a partida nova passa a
##                   salvar em user://savegame.json.
## - Save ilegível (JSON quebrado): avisa, move o arquivo pra
##   user://savegame_corrompido.json e deixa começar um jogo novo.
## - Backups (N): lista os backups (data/hora + resumo) e carrega qualquer um.
## Visual propositalmente simples (funcional primeiro).

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const BG := Color(0.05, 0.045, 0.06)
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.65, 0.6, 0.55)

var _confirm: ConfirmationDialog
var _confirm_backup: ConfirmationDialog
var _chosen_backup: String = ""
## Bloco 113: a tela de Nova partida (a dificuldade) e a coluna do menu que ela esconde.
var _nova: VBoxContainer
var _box: VBoxContainer


func _ready() -> void:
	Audio.tema("abertura")  # Bloco 114: a música de abertura (sem arquivo, segue a música de sempre)
	if UiSkin.ok():
		get_tree().root.theme = UiSkin.theme()  # Prompt 20: a pele nova (botões, painéis, dicas)
	var status: String = SaveManager.save_status()
	if status == "none" and SaveManager.list_backups().is_empty():
		_build(status)
		_abre_nova()  # Bloco 113: o primeiro jogo também escolhe a dificuldade
		return
	_build(status)


func _build(status: String) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	add_child(preload("res://scripts/ui/menu_fundo.gd").new())  # Prompt 26: a key art animada

	var logo_tex: Texture2D = load("res://assets/game/ui/titulo/logo.png") if ResourceLoader.exists("res://assets/game/ui/titulo/logo.png") else null
	if logo_tex:  # Prompt 26: o logo em cima, no meio (1,5x: na tela de 1080p vira 2,25... fica 3x/2)
		var logo := TextureRect.new()
		logo.texture = logo_tex
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
		logo.offset_left = -logo_tex.get_width() * 0.75
		logo.offset_right = logo_tex.get_width() * 0.75
		logo.offset_top = 28.0
		logo.offset_bottom = 28.0 + logo_tex.get_height() * 1.5
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(logo)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 150.0 if logo_tex else 0.0
	add_child(center)
	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", UiSkin.painel(10))
	center.add_child(moldura)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(360, 0)
	moldura.add_child(box)
	_box = box
	_nova = preload("res://scripts/ui/nova_partida_panel.gd").new()  # Bloco 113
	_nova.visible = false
	moldura.add_child(_nova)
	_nova.comecar.connect(func(escolha: Dictionary):
		Audio.click()
		SaveManager.start_new_game(escolha))
	_nova.voltar.connect(func():
		_nova.visible = false
		_box.visible = true)

	if logo_tex == null:
		var title := _label("DEEP IRON", Tipo.TELA, COLOR_TITLE)
		UiSkin.usa_fonte(title, "titulo", Tipo.PIXEL_4)  # Prompt 22
		title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
		title.add_theme_constant_override("outline_size", 6)
		box.add_child(title)

	if status == "ok":
		var s: Dictionary = SaveManager.save_summary()
		var info := "Dia %d  •  %s  •  %d ipezinhos  •  %d créditos\nsalvo em %s" % [
			int(s.get("day", 1)), str(s.get("stage", "?")), int(s.get("workers", 0)),
			int(s.get("credits", 0)), str(s.get("saved_at", "?")).replace("T", " ")]
		if str(s.get("dificuldade", "")) != "":  # Bloco 113
			info += "
dificuldade: " + str(s.dificuldade)
		box.add_child(_label(info, Tipo.CORPO, COLOR_DIM))
		var cont := _button("Continuar")
		cont.pressed.connect(func(): SaveManager.load_game())
		box.add_child(cont)
		cont.grab_focus.call_deferred()
		var new_game := _button("Novo jogo")
		new_game.pressed.connect(func(): _confirm.popup_centered())
		box.add_child(new_game)
		_confirm = ConfirmationDialog.new()
		_confirm.title = "Novo jogo"
		_confirm.dialog_text = "Começar uma partida nova?\n\nO save atual NÃO é apagado: ele vira um backup com data/hora\n(em Backups, aqui na tela inicial) e a partida nova passa a salvar no lugar dele."
		_confirm.ok_button_text = "Começar do zero"
		_confirm.cancel_button_text = "Voltar"
		_confirm.confirmed.connect(_abre_nova)  # Bloco 113: depois de confirmar, escolhe a dificuldade
		add_child(_confirm)
	elif status == "none":
		box.add_child(_label("Nenhum save em andamento.", Tipo.CORPO, COLOR_DIM))
		var new_game := _button("Novo jogo")
		new_game.pressed.connect(_abre_nova)
		box.add_child(new_game)
		new_game.grab_focus.call_deferred()
	else:
		box.add_child(_label("O save encontrado está corrompido e não pôde ser lido.\nEle será guardado como savegame_corrompido.json.", Tipo.CORPO, Color(1.0, 0.55, 0.45)))
		var new_game := _button("Novo jogo")
		new_game.pressed.connect(func():
			SaveManager.quarantine_corrupt_save()
			_abre_nova())
		box.add_child(new_game)
		new_game.grab_focus.call_deferred()

	# Bloco 112: ver a introdução de novo (não mexe no save: os quadros no mapa rodam numa partida que não salva)
	var intro := _button("Ver a introdução")
	intro.pressed.connect(func():
		Audio.click()
		SaveManager.ver_introducao())
	box.add_child(intro)

	var backups: Array[Dictionary] = SaveManager.list_backups_with_summary()
	if not backups.is_empty():
		var backups_button := _button("Backups (%d)" % backups.size())
		box.add_child(backups_button)
		var backups_panel := _build_backups(backups, status)
		backups_panel.visible = false
		moldura.add_child(backups_panel)  # (dentro da mesma moldura)
		backups_button.pressed.connect(func():
			Audio.click()
			box.visible = false
			backups_panel.visible = true)
		backups_panel.get_meta("back_button").pressed.connect(func():
			backups_panel.visible = false
			box.visible = true)

	var settings_button := _button("Configurações")
	box.add_child(settings_button)
	var settings: VBoxContainer = preload("res://scripts/ui/settings_panel.gd").new()
	settings.visible = false
	moldura.add_child(settings)
	settings_button.pressed.connect(func():
		Audio.click()
		box.visible = false
		settings.visible = true)
	settings.back_pressed.connect(func():
		settings.visible = false
		box.visible = true)

	var quit := _button("Sair")
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	box.add_child(_label("pasta do save: %s" % ProjectSettings.globalize_path("user://"), Tipo.DETALHE, COLOR_DIM))


## Bloco 113: a tela de Nova partida no lugar do menu.
func _abre_nova() -> void:
	_box.visible = false
	_nova.visible = true


## Lista de backups: data/hora do backup + o mesmo resumo do "Continuar".
func _build_backups(backups: Array[Dictionary], status: String) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.add_child(_label("BACKUPS", Tipo.FAIXA, COLOR_TITLE))
	panel.add_child(_label("Guardados quando uma partida nova começou por cima de um save.\nMais novo primeiro; ficam só os %d mais recentes." % SaveManager.max_backups, Tipo.DETALHE, COLOR_DIM))
	for b in backups:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var text := "backup de %s\n" % b.label
		if b.ok:
			var s: Dictionary = b.summary
			text += "Dia %d  •  %s  •  %d ipezinhos  •  %d créditos  •  salvo em %s" % [
				int(s.get("day", 1)), str(s.get("stage", "?")), int(s.get("workers", 0)),
				int(s.get("credits", 0)), str(s.get("saved_at", "?")).replace("T", " ")]
		else:
			text += "(arquivo ilegível)"
		var info := _label(text, Tipo.DETALHE, COLOR_TEXT if b.ok else Color(1.0, 0.55, 0.45))
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var load_button := _button("Carregar")
		load_button.custom_minimum_size = Vector2(110, 36)
		load_button.disabled = not b.ok
		var path: String = b.path
		var label: String = b.label
		load_button.pressed.connect(func():
			_chosen_backup = path
			_confirm_backup.dialog_text = "Carregar o backup de %s?\n\n%s" % [label,
				"O save atual NÃO é apagado: ele vira um backup novo antes." if status == "ok"
				else "O save atual (ilegível) vai pra savegame_corrompido.json." if status == "corrupt"
				else "A partida carregada volta a salvar normalmente."]
			_confirm_backup.popup_centered())
		row.add_child(load_button)
		panel.add_child(row)
	var back := _button("Voltar")
	panel.add_child(back)
	panel.set_meta("back_button", back)

	_confirm_backup = ConfirmationDialog.new()
	_confirm_backup.title = "Carregar backup"
	_confirm_backup.ok_button_text = "Carregar"
	_confirm_backup.cancel_button_text = "Voltar"
	_confirm_backup.confirmed.connect(func(): SaveManager.load_backup(_chosen_backup))
	add_child(_confirm_backup)
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", Tipo.TITULO)
	return b
