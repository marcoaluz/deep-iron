extends VBoxContainer
## Bloco 95 (layout v2): a PILHA DE AVISOS no canto de baixo à direita (no lugar dos toasts soltos no meio
## da tela). Cada aviso tem ícone e texto, some sozinho, e o mais novo fica embaixo; clicar leva ao lugar
## (quando o aviso tem um). No máximo `maximo` na tela: o mais velho sai.

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")

## Avisos na tela ao mesmo tempo.
@export var maximo := 4
## Segundos (reais) que o aviso fica antes de sumir.
@export var duracao := 4.0
## Largura máxima do aviso (px lógicos).
@export var largura := 300.0

var _hud: CanvasLayer


func setup(hud: CanvasLayer) -> void:
	_hud = hud
	add_theme_constant_override("separation", 4)
	alignment = BoxContainer.ALIGNMENT_END
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Um aviso novo. alvo = o nó onde a câmera vai ao clicar (null = sem lugar).
func avisa(texto: String, cor: Color, icone := "", alvo: Node = null) -> Control:
	while get_child_count() >= maximo:
		var velho := get_child(0)
		remove_child(velho)
		velho.queue_free()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.dica() if UiSkin.ok() else _hud._panel_style())
	p.mouse_filter = Control.MOUSE_FILTER_STOP if alvo != null else Control.MOUSE_FILTER_IGNORE
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if alvo != null else Control.CURSOR_ARROW
	p.size_flags_horizontal = Control.SIZE_SHRINK_END
	p.set_meta("toast", true)
	add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var tex := Icones.tex(icone, true) if icone != "" else null
	if tex:
		var ic := TextureRect.new()
		ic.texture = tex
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		ic.custom_minimum_size = Vector2(24, 24)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(ic)
	var l: Label = _hud._label(texto, Tipo.CORPO, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = minf(largura, l.get_theme_font("font").get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, Tipo.CORPO).x + 4.0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	if alvo != null:
		p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(alvo):
				var cam: Node = _hud._main.get_node_or_null("Camera2D") if _hud._main else null
				if cam and alvo is Node2D:
					cam.focus_on((alvo as Node2D).global_position))
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	tw.tween_interval(duracao)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)
	return p
