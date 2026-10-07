extends CanvasLayer
## Prompt 20: JANELA DE EVENTO (pele nova): plaquinha de título, a ilustração do evento (Prompt 24),
## o texto e os botões. Não pausa o jogo (a não ser que peça) e fecha sozinha ao escolher.
##
##   EventWindow.abre(arvore, "ROBÔ ANTIGO", "Os mineiros acharam...", textura, [["Ver", func()...], ["Fechar", null]])
##
## Uma por vez: se já tem uma aberta, a nova espera na fila.

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const LARGURA := 520.0

static var _fila: Array = []
static var _aberta: CanvasLayer = null

var _botoes: HBoxContainer
var _pausou := false


static func abre(tree: SceneTree, titulo: String, texto: String, imagem: Texture2D = null, botoes: Array = [], pausa := false) -> void:
	var pedido := [titulo, texto, imagem, botoes, pausa]
	if _aberta != null and is_instance_valid(_aberta):
		_fila.append(pedido)
		return
	var w = load("res://scripts/ui/event_window.gd").new()
	tree.root.add_child(w)
	w._monta(pedido)


static func aberta() -> CanvasLayer:
	return _aberta if _aberta != null and is_instance_valid(_aberta) else null


func _monta(p: Array) -> void:
	_aberta = self
	UiSkin.tema_na_camada(self)  # Bloco 95: o tema (escala e fonte) chega nos Controls da camada
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.35)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.painel(10))
	panel.custom_minimum_size = Vector2(LARGURA, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var tit := PanelContainer.new()
	tit.add_theme_stylebox_override("panel", UiSkin.titulo())
	tit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(tit)
	var tl := Label.new()
	tl.text = p[0]
	tl.add_theme_font_size_override("font_size", Tipo.TITULO_JANELA)
	UiSkin.usa_fonte(tl, "titulo", Tipo.PIXEL_2)  # Prompt 22
	tl.add_theme_color_override("font_color", COLOR_TITLE)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.custom_minimum_size.x = 220
	tit.add_child(tl)
	if p[2] != null:
		var moldura := PanelContainer.new()
		moldura.add_theme_stylebox_override("panel", UiSkin.caixa("progresso", [3, 3, 3, 3]))
		v.add_child(moldura)
		var img := TextureRect.new()
		img.texture = p[2]
		img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tw: float = (p[2] as Texture2D).get_width()
		var th: float = (p[2] as Texture2D).get_height()
		var k := maxf(1.0, floorf((LARGURA - 40.0) / maxf(tw, 1.0)))  # pixel inteiro
		img.custom_minimum_size = Vector2(tw, th) * k
		moldura.add_child(img)
	var txt := Label.new()
	txt.text = p[1]
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size.x = LARGURA - 40.0
	txt.add_theme_font_size_override("font_size", Tipo.TITULO)
	txt.add_theme_color_override("font_color", COLOR_TEXT)
	v.add_child(txt)
	_botoes = HBoxContainer.new()
	_botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	_botoes.add_theme_constant_override("separation", 12)
	v.add_child(_botoes)
	var lista: Array = p[3] if not p[3].is_empty() else [["Fechar", null]]
	for b in lista:
		var bt := Button.new()
		bt.text = b[0]
		bt.custom_minimum_size = Vector2(120, 34)
		bt.focus_mode = Control.FOCUS_NONE
		UiSkin.aplica_botao(bt)
		var acao = b[1] if b.size() > 1 else null
		bt.pressed.connect(func(): _escolhe(acao))
		_botoes.add_child(bt)
	if p[4] and not get_tree().paused:
		get_tree().paused = true
		_pausou = true


func _escolhe(acao) -> void:
	if Engine.has_singleton("Audio") or get_node_or_null("/root/Audio"):
		get_node("/root/Audio").click()
	if _pausou:
		get_tree().paused = false
	if acao is Callable and (acao as Callable).is_valid():
		(acao as Callable).call()
	_fecha()


func _fecha() -> void:
	_aberta = null
	var tree := get_tree()
	queue_free()
	if not _fila.is_empty():
		var p: Array = _fila.pop_front()
		var w = load("res://scripts/ui/event_window.gd").new()
		tree.root.add_child(w)
		w._monta(p)
