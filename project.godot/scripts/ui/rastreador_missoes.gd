extends PanelContainer
## Bloco 95 (layout v2): o ESPAÇO RESERVADO do rastreador de missões (canto direito, acima da barra de baixo).
## Ainda não há missões (vêm no Prompt 3, "Sistema de missões + Capítulo 1"): o painel existe, tem o tamanho
## e o lugar certos e fica escondido. O sistema de missões só precisa chamar mostra() / esconde().

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")

## Tamanho reservado (px lógicos): capítulo + 3 objetivos.
@export var tamanho := Vector2(240, 110)

var _hud: CanvasLayer
var _titulo: Label
var _lista: VBoxContainer


func setup(hud: CanvasLayer) -> void:
	_hud = hud
	add_theme_stylebox_override("panel", UiSkin.dica() if UiSkin.ok() else hud._panel_style())
	custom_minimum_size = tamanho
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	var ic := TextureRect.new()
	ic.texture = Icones.tex("missoes", true)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	_titulo = hud._label("MISSÃO", Tipo.TITULO, hud.COLOR_TITLE)
	h.add_child(_titulo)
	_lista = VBoxContainer.new()
	_lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_lista)
	visible = false


## capitulo = "Cap. 2  Fogo e ferro"; objetivos = [[texto, feito?], ...] (até 3).
func mostra(capitulo: String, objetivos: Array) -> void:
	_titulo.text = capitulo
	for c in _lista.get_children():
		c.queue_free()
	for o in objetivos.slice(0, 3):
		var feito: bool = o[1]
		_lista.add_child(_hud._label(("[x] " if feito else "[ ] ") + String(o[0]), Tipo.DETALHE,
			_hud.COLOR_DIM if feito else _hud.COLOR_TEXT))
	visible = true


func esconde() -> void:
	visible = false
