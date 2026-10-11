extends CanvasLayer
## Vitória: o escudo solar ficou pronto (criado pelo sun.gd). Pausa o jogo. Bloco 126: o EPÍLOGO (data/epilogo/epilogo.txt, editável, com uma ilustração que
## já existe), a tela de ESTATÍSTICAS completa (estatisticas.gd) e as duas saídas: "Continuar em modo infinito" (a vila segue com invasões e eventos, sem
## vitória nova; sun.entra_modo_infinito) e "Voltar ao menu inicial" (salva).

const Icones := preload("res://scripts/ui/icones.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const START_MENU := "res://scenes/ui/start_menu.tscn"
const EPILOGO := "res://data/epilogo/epilogo.txt"
const COLOR_TITLE := Color(0.6, 0.9, 1.0)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.65, 0.6, 0.55)

var _box: VBoxContainer
var _altura_max := 640.0


## O epílogo do arquivo: {imagem, titulo, subtitulo, paragrafos}. Arquivo ausente = {} (a tela usa o texto que o sun.gd mandar).
static func carrega_epilogo() -> Dictionary:
	if not FileAccess.file_exists(EPILOGO):
		return {}
	var out := {"imagem": "", "titulo": "", "subtitulo": "", "paragrafos": []}
	var no_texto := false
	var atual := ""
	for linha in FileAccess.get_file_as_string(EPILOGO).split("
"):
		var l := linha.strip_edges()
		if no_texto:
			if l == "":
				if atual != "":
					out.paragrafos.append(atual)
					atual = ""
			else:
				atual = l if atual == "" else atual + " " + l
			continue
		if l == "[texto]":
			no_texto = true
			continue
		if l == "" or l.begins_with("#") or not "=" in l:
			continue
		var i := l.find("=")
		var k := l.substr(0, i).strip_edges()
		if out.has(k) and k != "paragrafos":
			out[k] = l.substr(i + 1).strip_edges()
	if atual != "":
		out.paragrafos.append(atual)
	return out


func _ready() -> void:
	UiSkin.tema_na_camada(self)  # Bloco 95: o tema (escala e fonte) chega nos Controls da camada
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
	_altura_max = clampf(get_viewport().get_visible_rect().size.y * 0.9, 320.0, 760.0)
	var panel := PanelContainer.new()
	var style: StyleBox = UiSkin.painel(18)  # Prompt 20: a pele nova
	if not UiSkin.ok():
		var f := StyleBoxFlat.new()
		f.bg_color = Color(0.05, 0.07, 0.1, 0.96)
		f.border_color = Color(0.4, 0.7, 0.9)
		f.set_border_width_all(2)
		f.set_corner_radius_all(4)
		f.set_content_margin_all(22)
		style = f
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var rolagem := ScrollContainer.new()  # (muita estatística: a tela rola, os botões ficam no fim)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.custom_minimum_size = Vector2(540, 0)
	panel.add_child(rolagem)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.custom_minimum_size = Vector2(520, 0)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(_box)
	rolagem.custom_minimum_size.y = _altura_max
	get_tree().paused = true


func setup(stats: Dictionary) -> void:
	var ep := carrega_epilogo()
	var ilu := Icones.ilustracao(String(ep.get("imagem", "escudo_vitoria")) if String(ep.get("imagem", "")) != "" else "escudo_vitoria")
	if ilu:  # Prompt 24/26: a cena (2x, pixel inteiro)
		var img := TextureRect.new()
		img.texture = ilu
		img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = ilu.get_size() * 2.0
		_box.add_child(img)
	_label(String(ep.get("titulo", "")) if String(ep.get("titulo", "")) != "" else "A VILA ESTÁ A SALVO!", Tipo.TELA, COLOR_TITLE)
	var sub := String(ep.get("subtitulo", ""))
	if sub == "":
		sub = "O escudo solar acendeu sobre a mina. Pela primeira vez desde a explosão, o sol não é mais uma ameaça. Os ipezinhos saem das casas pra olhar o céu azulado."
	_label(sub, Tipo.TITULO, COLOR_TEXT).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Vitória no dia %d (%s)  •  %d ipezinhos" % [int(stats.get("day", 1)), str(stats.get("season", "")),
		int(stats.get("workers", 0))], Tipo.DETALHE, COLOR_DIM)
	var paragrafos: Array = ep.get("paragrafos", [])
	if paragrafos.is_empty() and String(stats.get("epilogo", "")) != "":
		paragrafos = [String(stats.get("epilogo", ""))]  # (Bloco 122: o epílogo de data/missoes/capitulo_6.txt)
	if not paragrafos.is_empty():
		_box.add_child(HSeparator.new())
		for t in paragrafos:
			_label(String(t), Tipo.DETALHE, COLOR_TEXT).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var linhas: Array = stats.get("estatisticas", [])
	if not linhas.is_empty():
		_box.add_child(HSeparator.new())
		_label("Estatísticas da vila", Tipo.TITULO, COLOR_TITLE)
		for l in linhas:
			_label(String(l), Tipo.CORPO, COLOR_DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(HSeparator.new())
	if bool(stats.get("infinito", false)):
		_label("Modo infinito ligado: a vila segue com invasões e eventos.", Tipo.DETALHE, COLOR_TITLE)
		_button("Fechar", func():
			get_tree().paused = false
			queue_free())
	else:
		_button("Continuar em modo infinito", func():
			var sol := get_tree().get_first_node_in_group("sun")
			if sol and sol.has_method("entra_modo_infinito"):
				sol.entra_modo_infinito()
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
	b.add_theme_font_size_override("font_size", Tipo.TITULO)
	b.pressed.connect(func():
		Audio.click()
		action.call())
	_box.add_child(b)
