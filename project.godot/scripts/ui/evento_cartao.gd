extends CanvasLayer
## Bloco 123: o CARTÃO de um evento com escolha (criado pelo eventos.gd): a ilustração (uma das que o jogo já tem), o título, o texto e 2 ou 3 opções,
## cada uma com o CUSTO e a CONSEQUÊNCIA embaixo; opção que a vila não pode pagar fica desabilitada e diz o que falta. O jogo fica pausado até escolher
## (a camada roda em PROCESS_MODE_ALWAYS). O jogador sempre decide: não há fechar sem escolher.

const Icones := preload("res://scripts/ui/icones.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const COR_TITULO := Color(1.0, 0.85, 0.5)
const COR_TEXTO := Color(0.92, 0.88, 0.8)
const COR_DIM := Color(0.7, 0.66, 0.6)
const COR_CUSTO := Color(1.0, 0.8, 0.45)
const COR_EFEITO := Color(0.75, 0.9, 0.7)
const COR_FALTA := Color(1.0, 0.5, 0.45)

var _eventos: Node
var _box: VBoxContainer
var botoes: Array[Button] = []
var titulo := ""


func _ready() -> void:
	UiSkin.tema_na_camada(self)
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("evento_cartao")


func setup(eventos: Node, e: Dictionary) -> void:
	_eventos = eventos
	titulo = String(e.titulo)
	var dim := ColorRect.new()
	dim.color = Color(0, 0.02, 0.05, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style: StyleBox = UiSkin.painel(16)
	if not UiSkin.ok():
		var f := StyleBoxFlat.new()
		f.bg_color = Color(0.06, 0.07, 0.1, 0.97)
		f.border_color = Color(0.8, 0.6, 0.3)
		f.set_border_width_all(2)
		f.set_content_margin_all(18)
		style = f
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_box.custom_minimum_size = Vector2(540, 0)
	panel.add_child(_box)
	var ilu := Icones.ilustracao(String(e.ilustracao))
	if ilu:
		var img := TextureRect.new()
		img.texture = ilu
		img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = ilu.get_size() * 2.0
		_box.add_child(img)
	_label(String(e.titulo).to_upper(), Tipo.TELA, COR_TITULO, true)
	var txt := _label(_eventos.texto_de(e), Tipo.TITULO, COR_TEXTO, false)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(HSeparator.new())
	var opcoes: Array = e.opcoes
	for i in opcoes.size():
		var op: Dictionary = opcoes[i]
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, String(op.texto)]
		b.custom_minimum_size = Vector2(0, 36)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", Tipo.TITULO)
		var motivo: String = _eventos.motivo_opcao(String(e.id), i)
		b.disabled = motivo != ""
		var idx := i
		b.pressed.connect(func():
			_som("click")
			_eventos.escolhe(idx))
		_box.add_child(b)
		botoes.append(b)
		var l := _label("Custo: %s   •   %s" % [_eventos.custo_texto(op.get("custo", {})), _eventos.descreve_efeitos(op)], Tipo.DETALHE, COR_CUSTO, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if motivo != "":
			var m := _label("Não dá agora: " + motivo, Tipo.DETALHE, COR_FALTA, false)
			m.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _label(text: String, size: int, color: Color, centro: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centro else HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)
	return l


## Atalho: as teclas 1, 2 e 3 escolhem a opção.
func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var i := -1
		match ev.keycode:
			KEY_1, KEY_KP_1:
				i = 0
			KEY_2, KEY_KP_2:
				i = 1
			KEY_3, KEY_KP_3:
				i = 2
		if i >= 0 and i < botoes.size() and not botoes[i].disabled:
			get_viewport().set_input_as_handled()
			_som("click")
			_eventos.escolhe(i)


## O autoload Audio por caminho (os testes carregam este script antes dos autoloads).
func _som(metodo: String, arg: String = "") -> void:
	var a := get_node_or_null("/root/Audio")
	if a == null:
		return
	if arg != "":
		a.call(metodo, arg)
	else:
		a.call(metodo)
