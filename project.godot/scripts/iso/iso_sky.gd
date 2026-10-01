extends Node2D
## Prompt 29: o CÉU da vila a céu aberto (vista iso com o mapa novo).
##
## Camadas, de trás pra frente (as do cenário aprovado, docs/arte/prompt27/LAYOUT_MAPA.md):
##   1. céu em degradê (tela inteira, CanvasLayer -3), na cor da hora;
##   2. nuvens soltas passando devagar (na mesma camada);
##   3. montanhas nevadas ao longe e 4. serra com floresta: no mundo, atrás da moldura de morros,
##      andando mais devagar que a câmera (parallax: parecem longe);
## A hora vem do DayNight (dia -> entardecer/amanhecer -> noite) e a chuva do Weather. A
## moldura de morros puxa pra cor do horizonte (névoa), como no cenário.

const Order := preload("res://scripts/iso/iso_order.gd")
const TEX_FAR := preload("res://assets/game/iso/ceu/montanhas_longe.png")
const TEX_RIDGE := preload("res://assets/game/iso/ceu/serra.png")
const TEX_CLOUDS := preload("res://assets/game/iso/ceu/nuvens.png")

## [topo, horizonte] por hora (as cores do cenário aprovado).
const HORAS := {
	"manha": [Color8(96, 128, 170), Color8(236, 190, 150)],
	"meio_dia": [Color8(70, 122, 190), Color8(176, 206, 226)],
	"tarde": [Color8(64, 56, 104), Color8(244, 136, 72)],
	"noite": [Color8(6, 8, 20), Color8(30, 36, 64)],
	"chuva": [Color8(64, 68, 78), Color8(112, 118, 124)],
}
## Quanto cada camada acompanha a câmera (0 = parada no fundo, 1 = presa no mapa).
const FAR_FOLLOW := 0.25
const RIDGE_FOLLOW := 0.5
## Ampliação (pixel inteiro) das camadas pintadas, como no cenário.
const FAR_SCALE := 4
const RIDGE_SCALE := 5
const CLOUD_SCALE := 3
const CLOUDS := 7

var _view: Node2D
var _day_night: Node
var _weather: Node
var _sky_layer: CanvasLayer
var _sky: ColorRect
var _sky_mat: ShaderMaterial
var _clouds: Array[Sprite2D] = []
var _far: Sprite2D
var _ridge: Sprite2D
## Onde a serra e as montanhas ficam com a câmera no meio do mapa (canvas iso).
var _anchor := Vector2.ZERO
var _cam_ref := Vector2.ZERO
var _moldura: CanvasItem


func setup(view: Node2D, moldura_top_left: Vector2, map_center_screen: Vector2, moldura: CanvasItem) -> void:
	_view = view
	_moldura = moldura
	_day_night = get_tree().get_first_node_in_group("day_night")
	_weather = get_tree().get_first_node_in_group("weather")
	name = "Ceu"
	# 1-2: céu e nuvens, na tela
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = -3
	add_child(_sky_layer)
	_sky = ColorRect.new()
	_sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec4 top_color : source_color;
uniform vec4 horizon_color : source_color;
uniform float horizon = 0.6;  // altura do horizonte na tela (0 = topo, 1 = embaixo)
uniform float fog_span = 0.5; // quanto da tela leva pra névoa escurecer de vez
void fragment() {
	// acima do horizonte: o céu; abaixo (embaixo do corte do terreno): névoa da cor do
	// horizonte, escurecendo (o vale some na névoa, como no cenário aprovado)
	vec4 fog = vec4(horizon_color.rgb * 0.45, 1.0);
	vec4 deep = vec4(0.07, 0.07, 0.09, 1.0);  // bem embaixo (andares de baixo): quase preto
	if (UV.y < horizon) {
		COLOR = mix(top_color, horizon_color, clamp(UV.y / max(horizon, 0.01), 0.0, 1.0));
	} else {
		float k = (UV.y - horizon) / fog_span;
		COLOR = k < 1.0 ? mix(horizon_color, fog, k) : mix(fog, deep, clamp(k - 1.0, 0.0, 1.0));
	}
}"""
	_sky_mat.shader = sh
	_sky.material = _sky_mat
	_sky_layer.add_child(_sky)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var pieces := _cloud_pieces()
	for k in CLOUDS:
		var c := Sprite2D.new()
		c.texture = TEX_CLOUDS
		c.region_enabled = true
		c.region_rect = pieces[k % pieces.size()]
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var esc: int = [2, 3, 3, 4][rng.randi() % 4]
		c.scale = Vector2(esc, esc)
		c.flip_h = rng.randf() < 0.5
		c.set_meta("frac", Vector2(rng.randf_range(0.0, 1.0), rng.randf_range(0.05, 0.45)))  # fração da tela
		c.set_meta("speed", rng.randf_range(0.004, 0.012))
		_sky_layer.add_child(c)
		_clouds.append(c)
	# 3-4: montanhas e serra, no mundo (atrás da moldura de morros)
	_cam_ref = map_center_screen
	_anchor = moldura_top_left
	_far = _band(TEX_FAR, FAR_SCALE, Order.BASE - 90)
	_ridge = _band(TEX_RIDGE, RIDGE_SCALE, Order.BASE - 80)
	_place_bands(map_center_screen)


## Uma faixa que repete na horizontal (normal e espelhada, pra a emenda casar).
func _band(tex: Texture2D, esc: int, z: int) -> Sprite2D:
	var img := tex.get_image()
	var w := img.get_width()
	var both := Image.create(w * 2, img.get_height(), false, img.get_format())
	both.blit_rect(img, Rect2i(0, 0, w, img.get_height()), Vector2i.ZERO)
	var m := img.duplicate()
	m.flip_x()
	both.blit_rect(m, Rect2i(0, 0, w, img.get_height()), Vector2i(w, 0))
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(both)
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, w * 2 * 12, img.get_height())
	s.scale = Vector2(esc, esc)
	s.z_index = z
	s.light_mask = 0
	add_child(s)
	return s


## As nuvens grandes da camada (componentes do alfa), pra espalhar soltas no céu.
func _cloud_pieces() -> Array:
	var img := TEX_CLOUDS.get_image()
	var used := []
	var out := []
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	for y0 in h:
		for x0 in w:
			if seen[y0 * w + x0] or img.get_pixel(x0, y0).a8 < 20:
				continue
			var stack := [Vector2i(x0, y0)]
			seen[y0 * w + x0] = 1
			var r := Rect2i(x0, y0, 1, 1)
			var n := 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				n += 1
				r = r.expand(p).expand(p + Vector2i.ONE)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + d
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and not seen[q.y * w + q.x] and img.get_pixel(q.x, q.y).a8 >= 20:
						seen[q.y * w + q.x] = 1
						stack.append(q)
			if n >= 300 and r.position.x > 0 and r.end.x < w:
				out.append(Rect2(r))
	if out.is_empty():
		out.append(Rect2(0, 0, w, h))
	return out


## Serra atrás do topo da moldura; montanhas aparecendo por cima da serra (como no cenário).
func _place_bands(cam: Vector2) -> void:
	var d := cam - _cam_ref
	var ridge_h := TEX_RIDGE.get_height() * RIDGE_SCALE
	var far_h := TEX_FAR.get_height() * FAR_SCALE
	var x0 := _anchor.x - 4000.0
	# parallax só na horizontal: na vertical ficam presas ao mapa (descendo pros andares de
	# baixo, o horizonte sai da tela por cima e fica só a névoa escura)
	_ridge.position = Vector2(x0 + d.x * (1.0 - RIDGE_FOLLOW), _anchor.y + 560.0 - ridge_h * 0.5)
	_far.position = Vector2(x0 - 700.0 + d.x * (1.0 - FAR_FOLLOW), _anchor.y + 600.0 - far_h)


## Liga/desliga junto com a vista iso (a camada do céu não segue a visibilidade do pai).
func set_active(on: bool) -> void:
	_sky_layer.visible = on
	set_process(on)


## Cores da hora agora: [topo, horizonte, chuva 0..1].
func colors_now() -> Array:
	var k: float = _day_night.darkness() if _day_night else 0.0
	var morning := true
	if _day_night:
		var dl: float = _day_night.day_duration
		morning = _day_night.time < dl * 0.5 or _day_night.time >= _day_night.cycle_length() - _day_night.dawn_starts_before
	var tw: Array = HORAS.manha if morning else HORAS.tarde
	var top: Color
	var hor: Color
	if k < 0.5:
		top = HORAS.meio_dia[0].lerp(tw[0], k * 2.0)
		hor = HORAS.meio_dia[1].lerp(tw[1], k * 2.0)
	else:
		top = tw[0].lerp(HORAS.noite[0], k * 2.0 - 1.0)
		hor = tw[1].lerp(HORAS.noite[1], k * 2.0 - 1.0)
	var rain := 0.0
	if _weather and _weather.has_method("level"):
		rain = clampf(_weather.level("rain"), 0.0, 1.0)
	if rain > 0.0:
		top = top.lerp(HORAS.chuva[0] * (1.0 - k * 0.7), rain * 0.85)
		hor = hor.lerp(HORAS.chuva[1] * (1.0 - k * 0.7), rain * 0.85)
	return [top, hor, rain]


func _process(delta: float) -> void:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var size := vp.get_visible_rect().size
	var cam: Vector2 = inv * (size * 0.5)
	_place_bands(cam)
	var c := colors_now()
	# horizonte da tela = o pé das montanhas ao longe
	var far_base_canvas := _far.position.y + TEX_FAR.get_height() * FAR_SCALE * 0.85
	var hor_screen := (vp.get_canvas_transform() * Vector2(0, far_base_canvas)).y / maxf(size.y, 1.0)
	_sky_mat.set_shader_parameter("top_color", c[0])
	_sky_mat.set_shader_parameter("horizon_color", c[1])
	_sky_mat.set_shader_parameter("horizon", hor_screen)
	# montanhas e serra: névoa da cor do horizonte (mais longe = mais névoa) e a luz da hora
	_far.self_modulate = Color(1, 1, 1).lerp(c[1], 0.45)
	_ridge.self_modulate = Color(0.85, 0.9, 0.85).lerp(c[1], 0.2)
	if _moldura:
		_moldura.self_modulate = Color(1, 1, 1).lerp(c[1], 0.18)
	# nuvens: andam devagar e dão a volta; tingidas pela hora; mais escuras na chuva
	var cloud_col := Color(1, 1, 1).lerp(c[1], 0.35).lerp(Color(0.45, 0.47, 0.52), c[2] * 0.7)
	for cl in _clouds:
		var f: Vector2 = cl.get_meta("frac")
		f.x += float(cl.get_meta("speed")) * delta
		if f.x > 1.15:
			f.x = -0.15
		cl.set_meta("frac", f)
		# a posição é fração do céu (da borda de cima da tela até o horizonte)
		var top_y := clampf(hor_screen, 0.0, 1.0) * size.y
		cl.position = Vector2(f.x * size.x, f.y * top_y * 1.6)
		cl.visible = hor_screen > 0.08
		cl.modulate = cloud_col
