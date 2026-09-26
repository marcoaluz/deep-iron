extends Control
## Tela inicial (cena principal do projeto): "Continuar" / "Novo jogo".
##
## - Sem save na pasta: vai direto pra um jogo novo.
## - Save legível: mostra o resumo (dia, estágio, ipezinhos, quando salvou).
##     Continuar  -> carrega o save.
##     Novo jogo  -> pede confirmação; o save atual NÃO é apagado: vira
##                   user://savegame_backup.json e a partida nova passa a salvar
##                   em user://savegame.json.
## - Save ilegível (JSON quebrado): avisa, move o arquivo pra
##   user://savegame_corrompido.json e deixa começar um jogo novo.
## Visual propositalmente simples (funcional primeiro).

const BG := Color(0.05, 0.045, 0.06)
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.65, 0.6, 0.55)

var _confirm: ConfirmationDialog


func _ready() -> void:
	var status: String = SaveManager.save_status()
	if status == "none":
		SaveManager.start_new_game.call_deferred()
		return
	_build(status)


func _build(status: String) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(360, 0)
	center.add_child(box)

	var title := _label("DEEP IRON", 40, COLOR_TITLE)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	title.add_theme_constant_override("outline_size", 6)
	box.add_child(title)

	if status == "ok":
		var s: Dictionary = SaveManager.save_summary()
		var info := "Dia %d  •  %s  •  %d ipezinhos  •  %d créditos\nsalvo em %s" % [
			int(s.get("day", 1)), str(s.get("stage", "?")), int(s.get("workers", 0)),
			int(s.get("credits", 0)), str(s.get("saved_at", "?")).replace("T", " ")]
		box.add_child(_label(info, 13, COLOR_DIM))
		var cont := _button("Continuar")
		cont.pressed.connect(func(): SaveManager.load_game())
		box.add_child(cont)
		cont.grab_focus.call_deferred()
		var new_game := _button("Novo jogo")
		new_game.pressed.connect(func(): _confirm.popup_centered())
		box.add_child(new_game)
		_confirm = ConfirmationDialog.new()
		_confirm.title = "Novo jogo"
		_confirm.dialog_text = "Começar uma partida nova?\n\nO save atual NÃO é apagado: ele vira savegame_backup.json\ne a partida nova passa a salvar no lugar dele."
		_confirm.ok_button_text = "Começar do zero"
		_confirm.cancel_button_text = "Voltar"
		_confirm.confirmed.connect(func(): SaveManager.start_new_game())
		add_child(_confirm)
	else:
		box.add_child(_label("O save encontrado está corrompido e não pôde ser lido.\nEle será guardado como savegame_corrompido.json.", 13, Color(1.0, 0.55, 0.45)))
		var new_game := _button("Novo jogo")
		new_game.pressed.connect(func():
			SaveManager.quarantine_corrupt_save()
			SaveManager.start_new_game())
		box.add_child(new_game)
		new_game.grab_focus.call_deferred()

	var quit := _button("Sair")
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	box.add_child(_label("pasta do save: %s" % ProjectSettings.globalize_path("user://"), 11, COLOR_DIM))


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
	b.add_theme_font_size_override("font_size", 16)
	return b
