extends Control
## Prompt 26: o FUNDO ANIMADO do menu inicial: a key art (vila no platô, a pedreira, a escavadeira,
## o sol ameaçador) cobrindo a tela em pixel inteiro, com camadas mexendo de leve por cima: o céu
## de fogo pulsando, fumaça subindo das chaminés, faíscas da broca e brasas no ar.

const DIR := "res://assets/game/ui/titulo/"
const IsoFx := preload("res://scripts/iso/iso_fx.gd")

var _arte: TextureRect
var _ceu: ColorRect
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(DIR + "keyart_a.png") if ResourceLoader.exists(DIR + "keyart_a.png") else null
	if tex == null:
		return
	_arte = TextureRect.new()
	_arte.texture = tex
	_arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_arte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arte)
	_ceu = ColorRect.new()  # o céu de fogo respira (luz quente por cima da parte de cima)
	_ceu.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_ceu.offset_bottom = 240.0
	_ceu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ceu.color = Color(1.0, 0.5, 0.15, 0.0)
	add_child(_ceu)
	_particulas("fumaca", Vector2(0.18, 0.28), Vector2(160, 30), 14, Vector2(-0.3, -1), 14.0, 4.5, Color(0.45, 0.4, 0.38, 0.55), 3.0)
	_particulas("faisca", Vector2(0.86, 0.72), Vector2(24, 16), 18, Vector2(0.2, -1), 70.0, 0.7, Color(1, 0.62, 0.3, 1), 2.0)
	_particulas("brasa", Vector2(0.5, 1.02), Vector2(700, 10), 30, Vector2(0, -1), 30.0, 7.0, Color(1, 0.6, 0.3, 0.9), 3.0)


func _particulas(textura: String, onde: Vector2, ext: Vector2, n: int, dir: Vector2, vel: float, vida: float, cor: Color, esc: float) -> void:
	var p := CPUParticles2D.new()
	p.texture = IsoFx.tex(textura)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.amount = n
	p.lifetime = vida
	p.preprocess = vida
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = ext
	p.direction = dir
	p.spread = 15.0
	p.gravity = Vector2(0, 2.0)
	p.initial_velocity_min = vel * 0.6
	p.initial_velocity_max = vel
	p.scale_amount_min = esc
	p.scale_amount_max = esc
	p.color = cor
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
	p.color_ramp = g
	p.set_meta("onde", onde)
	add_child(p)


func _process(delta: float) -> void:
	_t += delta
	if _ceu:
		_ceu.color.a = 0.06 + 0.05 * sin(_t * 1.3) + 0.02 * sin(_t * 3.7)
	for c in get_children():
		if c is CPUParticles2D:
			var o: Vector2 = c.get_meta("onde")
			c.position = (size * o).round()
