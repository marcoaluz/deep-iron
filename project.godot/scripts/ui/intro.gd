extends Control
## Bloco 112: a INTRODUÇÃO, entre o menu e a partida (scenes/ui/intro.tscn). Forma híbrida, ~60 s no total:
##
##   quadros 1 a 3 (aqui): três ilustrações do PixelLab (assets/game/ui/intro/), no estilo dos cartões de evento — o sol
##     explode, as cidades em silêncio, a caravana. Cada uma com um zoom lento e o texto letra a letra embaixo.
##   quadros 4 a 7 (no mapa da partida, intro_cinema.gd): a pedreira, o coletor em ruína, o corte da mina e a primeira
##     fogueira com o título. Assim não carrega o mapa duas vezes e a Fundação começa onde a câmera parou.
##
## Esc ou Espaço pulam a introdução inteira (direto pra partida, ou de volta ao menu no "Ver a introdução"); um clique
## completa o texto e, com o texto completo, passa pro próximo quadro. Quem decide o que vem depois é o SaveManager
## (intro_terminou). Os sons são ganchos (Audio.intro): tocam quando o arquivo existir.

const Tipo := preload("res://scripts/ui/tipografia.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const DIR := "res://assets/game/ui/intro/"
## [imagem, texto, som]
const QUADROS := [
	["q1_sol", "No ano em que o sol explodiu, o céu ardeu por três dias seguidos.", "explosao"],
	["q2_cidades", "Depois veio o silêncio. As cidades ficaram de pé, mas ninguém ficou nelas.", "vento"],
	["q3_caravana", "Os que sobraram andaram atrás de abrigo e de ferro. O velho capataz lembrava de uma pedreira.", "caravana"],
]
const COR_TEXTO := Color(0.95, 0.88, 0.74)
## Altura (px) da faixa escura da legenda: cabe duas linhas.
const ALTURA_FAIXA := 112.0
const COR_DICA := Color(0.7, 0.64, 0.55)

## Segundos de cada quadro (o texto aparece no começo e fica pra ler).
@export var segundos_por_quadro: float = 7.0
## Letras por segundo do texto.
@export var letras_por_segundo: float = 30.0
## Zoom lento da ilustração: de 1 até isto, no quadro inteiro.
@export var zoom_final: float = 1.08
## Segundos do escurecer/clarear entre os quadros.
@export var fade_segundos: float = 0.6

var _i := -1
var _t := 0.0
var _img: TextureRect
var _texto: Label
var _preto: ColorRect
var _acabou := false
var _trocando := false


func _ready() -> void:
	Audio.tema("intro")  # Bloco 114: a música da introdução (segue tocando nos quadros no mapa)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_img = TextureRect.new()
	_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_img)
	var faixa := ColorRect.new()  # a faixa escura do texto, embaixo
	faixa.color = Color(0.0, 0.0, 0.0, 0.62)
	faixa.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	faixa.offset_top = -ALTURA_FAIXA
	add_child(faixa)
	_texto = Label.new()
	_texto.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_texto.offset_top = -ALTURA_FAIXA + 8.0
	_texto.offset_bottom = -12.0
	_texto.offset_left = 48.0
	_texto.offset_right = -48.0
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_color_override("font_color", COR_TEXTO)
	_texto.add_theme_font_size_override("font_size", Tipo.FAIXA)  # (sem a fonte pixel; com ela, o tamanho dela)
	UiSkin.usa_fonte(_texto, "texto", Tipo.PIXEL_2)
	_texto.add_theme_color_override("font_shadow_color", Tipo.SOMBRA)
	add_child(_texto)
	var dica := Label.new()
	dica.text = "Esc ou Espaço: pular"
	dica.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dica.offset_left = -220.0
	dica.offset_right = -16.0
	dica.offset_top = 12.0
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dica.add_theme_font_size_override("font_size", Tipo.DETALHE)
	dica.add_theme_color_override("font_color", COR_DICA)
	add_child(dica)
	_preto = ColorRect.new()  # o escurecer entre os quadros (por cima de tudo menos da dica)
	_preto.color = Color.BLACK
	_preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_preto)
	move_child(dica, -1)
	_proximo()


## O quadro de agora (0..2; -1 antes; 3 = acabou) — pro teste.
func quadro() -> int:
	return _i


func _proximo() -> void:
	_i += 1
	if _i >= QUADROS.size():
		_fim(true)
		return
	var q: Array = QUADROS[_i]
	var tex: Texture2D = load(DIR + String(q[0]) + ".png") if ResourceLoader.exists(DIR + String(q[0]) + ".png") else null
	_img.texture = tex
	_texto.text = String(q[1])
	_texto.visible_characters = 0
	_t = 0.0
	await get_tree().process_frame  # (o tamanho do TextureRect já valeu: o pivô no meio)
	if not is_inside_tree():
		return
	_img.pivot_offset = _img.size * 0.5
	_img.scale = Vector2.ONE
	var zoom := create_tween()  # o zoom lento (devagar no começo e no fim: não parece máquina)
	zoom.tween_property(_img, "scale", Vector2.ONE * zoom_final, segundos_por_quadro).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var clareia := create_tween()
	clareia.tween_property(_preto, "color:a", 0.0, fade_segundos)
	Audio.intro(String(q[2]))
	_trocando = false


func _process(delta: float) -> void:
	if _acabou or _i < 0 or _i >= QUADROS.size():
		return
	_t += delta
	_texto.visible_characters = int(_t * letras_por_segundo)
	if _t >= segundos_por_quadro and not _trocando:
		_passa()


## Escurece e vai pro próximo quadro.
func _passa() -> void:
	if _trocando or _acabou:
		return
	_trocando = true
	var escurece := create_tween()
	escurece.tween_property(_preto, "color:a", 1.0, fade_segundos)
	escurece.finished.connect(_proximo)


func _unhandled_input(e: InputEvent) -> void:
	if _acabou:
		return
	if e.is_action_pressed("ui_cancel") or (e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ESCAPE, KEY_SPACE]):
		get_viewport().set_input_as_handled()
		pula()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if _texto.visible_characters >= 0 and _texto.visible_characters < _texto.text.length():
			_t = maxf(_t, float(_texto.text.length()) / letras_por_segundo)  # completa o texto
		else:
			_passa()


## Pula a introdução inteira (Esc/Espaço).
func pula() -> void:
	_fim(false)


func _fim(com_mapa: bool) -> void:
	if _acabou:
		return
	_acabou = true
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.intro_terminou(com_mapa)
