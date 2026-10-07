extends Node2D
## Prompt 18: EFEITOS na vista iso (só com o mapa novo; a vista de cima continua como era).
##
## Funções estáticas (usadas pelo espelho, iso_billboard.gd, e pela arte, iso_art.gd):
##   particula(d, s, dono, k) — a partícula copiada ganha a textura de pixel do papel dela
##     (faísca, fumaça, lasca, serragem, poeira, gás, brasa, radiação, folha) no tamanho de arte;
##     as texturas cinza são tingidas pela cor de sempre, as coloridas ficam só com o alfa dela.
##   puff(pai, pos) — nuvenzinha de poeira que some sozinha (criatura caindo).
##   fx_layer(nome) — camada animada (fogueira do barril, bandeirinhas) pra quem tem meta "iso_fx".
##
## Como nó (filho do Overlay da IsoView, por cima de tudo, coordenadas do canvas iso):
##   onda solar (a tela esquenta e treme), escudo ativo (domo), festa (bandeirinhas em mastros,
##   fogos à noite, confete), greve (barril em chamas e placas perto do Centro), satélite (pulsos
##   saindo da antena), explosivos perto do poço da mina, gotas pingando nos andares de baixo.
## Nada aqui muda o jogo: só lê o estado (Sun, Morale, Research).

const DIR := "res://assets/game/iso/fx/"
const FILE := DIR + "fx.json"
const ANIM_FPS := 9.0
## papel -> [textura, já é colorida?]
const PAPEIS := {
	"faisca": ["faisca", true], "brasa": ["brasa", true], "lasca": ["lasca", false], "serragem": ["serragem", true],
	"folha": ["folha", true], "poeira": ["poeira", false], "poeira_p": ["poeira_p", false], "fumaca": ["fumaca", false],
	"vapor": ["vapor", false], "gas": ["nuvem_gas", true], "radiacao": ["radiacao", true], "pedra": ["pedra", true],
}
## Quanto tempo (s) entre as conferências do estado (festa, greve, pesquisa...).
const CHECK_EVERY := 0.25
const FOGOS_CORES := [Color(1.0, 0.85, 0.4), Color(1.0, 0.45, 0.35), Color(0.45, 0.9, 0.85), Color(1.0, 1.0, 0.92)]
const PULSO_EVERY := 2.4

static var _data: Dictionary = {}
static var _tex: Dictionary = {}
static var _frames: Dictionary = {}

var _view: Node2D
var _check := 0.0
var _t := 0.0
# onda solar
var _wave_layer: CanvasLayer
var _wave_mat: ShaderMaterial
var _wave_k := 0.0
# escudo
var _domo: ColorRect
var _domo_mat: ShaderMaterial
var _domo_grow := 0.0
# festa
var _festa_on := false
var _bandeiras: Array = []  # [AnimatedSprite2D, ponto do chão do mastro esquerdo, do direito]
var _fogos_cd := 0.0
# greve
var _greve: Array = []  # nós no World (barril, placas)
# satélite e explosivos
var _antenas := {}  # laboratório -> nó da antena (no World)
var _pulsos: Array = []  # [centro no canvas, idade]
var _pulso_cd := 0.0
var _explosivos: Node2D = null
# mina
var _gotas: CPUParticles2D


# ------------------------------------------------------------ dados e texturas
static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(FILE):
		var d = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = d if typeof(d) == TYPE_DICTIONARY else {}
	return _data


static func tex(nome: String) -> Texture2D:
	if not _tex.has(nome):
		var p := DIR + nome + ".png"
		_tex[nome] = load(p) if ResourceLoader.exists(p) else null
	return _tex[nome]


## Os quadros de um efeito animado (tira do fx.json) como AtlasTexture.
static func frames(nome: String) -> Array:
	if _frames.has(nome):
		return _frames[nome]
	var out: Array = []
	var a: Dictionary = data().get("anim", {}).get(nome, {})
	var strip: Texture2D = tex(nome) if not a.is_empty() else null
	if strip:
		var w := float(a.quadro[0])
		var h := float(a.quadro[1])
		for k in int(a.n):
			var at := AtlasTexture.new()
			at.atlas = strip
			at.region = Rect2(k * w, 0, w, h)
			out.append(at)
	_frames[nome] = out
	return out


static func sprite_frames(nome: String) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", ANIM_FPS)
	for f in frames(nome):
		sf.add_frame("default", f)
	return sf


## Camada da arte nova de um efeito animado (barril em chamas): anima como a chama da tocha.
static func fx_layer(nome: String) -> Dictionary:
	var a: Dictionary = data().get("anim", {}).get(nome, {})
	var fr := frames(nome)
	if a.is_empty() or fr.is_empty():
		return {}
	return {"tex": fr[0], "ancora": Vector2(a.ancora[0], a.ancora[1]), "peg": a.get("peg", []), "h": float(a.get("h", 0.0)),
		"obra": -1.0, "mod": Color.WHITE, "anim": fr}


# ------------------------------------------------------------ partículas copiadas
static func papel_de(s: CPUParticles2D, dono: Node) -> String:
	if dono != null and dono.is_in_group("zonas_perigo"):
		match String(dono.get("kind")):
			"gas":
				return "gas"
			"calor":
				return "brasa"
			"radiacao":
				return "radiacao"
	match String(s.name):
		"Sparks":
			return "faisca"
		"Smoke":
			return "fumaca"
		"Dust":
			return "poeira"
		"Rocks":
			return "pedra"
		"Chips":
			return "serragem" if dono != null and dono.is_in_group("arvores") else "lasca"
	if dono != null and dono.is_in_group("arvores"):
		return "folha"  # agulhas caindo da copa
	if s.texture != null:
		return ""  # já tem desenho (chuva, neve...): fica
	return "poeira" if s.scale_amount_max >= 3.0 else "poeira_p"


## A cópia da partícula (d) no espelho ganha a textura do papel, em px de arte (k = escala da
## vista: o espelho cresce k, a textura volta pro tamanho dela).
static func particula(d: CPUParticles2D, s: CPUParticles2D, dono: Node, k: float) -> void:
	var papel := papel_de(s, dono)
	if papel == "" or not PAPEIS.has(papel):
		return
	var t := tex(PAPEIS[papel][0])
	if t == null:
		return
	d.texture = t
	d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var antes := (s.scale_amount_min + s.scale_amount_max) * 0.5 * k  # px de arte do quadradinho de antes
	var lado := float(maxi(t.get_width(), t.get_height()))
	var m := 2.0 if antes > lado * 2.2 else 1.0  # (só múltiplo inteiro: o pixel continua quadrado)
	d.scale_amount_min = m / k
	d.scale_amount_max = m / k
	if papel == "gas":
		d.scale = Vector2.ONE  # a mancha era achatada (elipse no chão); a nuvem fica redonda
	if PAPEIS[papel][1]:  # já colorida: da cor de antes fica só o alfa
		d.color = Color(1, 1, 1, s.color.a)
		d.color_initial_ramp = null
		if s.color_ramp != null:
			var g := Gradient.new()
			g.offsets = s.color_ramp.offsets
			var cs := PackedColorArray()
			for c in s.color_ramp.colors:
				cs.append(Color(1, 1, 1, c.a))
			g.colors = cs
			d.color_ramp = g


## Nuvenzinha que sobe e some (px de arte do pai).
static func puff(pai: Node, pos: Vector2, papel: String = "poeira", n: int = 10, cor: Color = Color(0.74, 0.68, 0.6, 0.85)) -> void:
	var t := tex(PAPEIS.get(papel, ["poeira"])[0])
	if t == null:
		return
	var p := CPUParticles2D.new()
	p.texture = t
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = n
	p.lifetime = 0.9
	p.position = pos
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(14, 4)
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 26.0
	p.color = cor
	p.color_ramp = _fade()
	p.light_mask = 2
	pai.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func _fade() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	return g


# ------------------------------------------------------------ o nó dos grandes eventos
func setup(view: Node2D) -> void:
	_view = view
	name = "Efeitos"
	_build_wave()
	_build_domo()
	_build_gotas()


func set_active(on: bool) -> void:
	set_process(on)
	visible = on
	if not on:
		_wave_layer.visible = false
		_set_festa(false)
		_set_greve(false)
		for lab in _antenas.keys():
			_drop_node(_antenas[lab])
		_antenas.clear()
		_drop_node(_explosivos)
		_explosivos = null


func _process(delta: float) -> void:
	_t += delta
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_check_state()
	_sync_wave(delta)
	_sync_domo(delta)
	_sync_festa(delta)
	_sync_pulsos(delta)
	_sync_gotas()
	queue_redraw()


func _node(group: String) -> Node:
	return get_tree().get_first_node_in_group(group)


func _check_state() -> void:
	var m := _node("morale")
	_set_festa(m != null and float(m.get("festa_left")) > 0.0)
	_set_greve(m != null and m.get("on_strike") == true)
	var res := _node("research")
	var sat: bool = res != null and res.has_method("has") and res.has("satelite")
	var labs: Array = get_tree().get_nodes_in_group("laboratorios") if sat else []
	for lab in _antenas.keys():
		if not is_instance_valid(lab) or not labs.has(lab):
			_drop_node(_antenas[lab])
			_antenas.erase(lab)
	for lab in labs:
		if not _antenas.has(lab) and lab is Node2D:
			_antenas[lab] = _spawn_prop("antena", (lab as Node2D).global_position + Vector2(52, 28))
	var boom: bool = res != null and res.has_method("has") and res.has("explosivos")
	if boom and _explosivos == null:
		var shaft := _node("elevador") as Node2D
		if shaft:
			_explosivos = _spawn_prop("explosivos", shaft.global_position + Vector2(-38, 18))
	elif not boom and _explosivos != null:
		_drop_node(_explosivos)
		_explosivos = null


## Peça da arte nova solta no World (meta iso_prop/iso_fx): a vista iso desenha na ordem certa;
## a vista de cima não desenha nada (Node2D vazio).
func _spawn_prop(nome: String, pos: Vector2, fx := false) -> Node2D:
	var world := _view.get("_world") as Node
	if world == null:
		return null
	var n := Node2D.new()
	n.name = "Fx_%s" % nome
	n.position = pos
	n.set_meta("iso_fx" if fx else "iso_prop", nome)
	world.add_child(n)
	return n


func _drop_node(n) -> void:
	if n != null and is_instance_valid(n):
		n.queue_free()


# ------------------------------------------------------------ onda solar
const WAVE_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float k = 0.0;
uniform float t = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	float wob = floor(sin(uv.y * 60.0 + t * 7.0) * 2.0) * 0.0012 * k;  // tremor do calor (em degraus)
	vec3 c = texture(screen_tex, uv + vec2(wob, 0.0)).rgb;
	vec3 hot = vec3(1.0, 0.84, 0.58);
	float pulse = 0.6 + 0.4 * sin(t * 2.4);
	float sol = 1.0 - smoothstep(0.0, 1.1, distance(uv, vec2(0.5, -0.1)));  // o sol vem de cima
	float q = floor((0.35 + 0.65 * sol) * pulse * 5.0) / 5.0;  // faixas, sem degradê liso
	c = mix(c, c * hot * 1.5 + hot * 0.22, clamp(k * q, 0.0, 0.85));
	COLOR = vec4(c, 1.0);
}
"""


func _build_wave() -> void:
	_wave_layer = CanvasLayer.new()
	_wave_layer.name = "OndaSolar"
	_wave_layer.layer = 1  # por cima do mundo, embaixo do HUD
	_wave_layer.visible = false
	add_child(_wave_layer)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WAVE_SHADER
	_wave_mat.shader = sh
	r.material = _wave_mat
	_wave_layer.add_child(r)


func _sync_wave(delta: float) -> void:
	var sun := _node("sun")
	var on: bool = sun != null and sun.has_method("wave_active") and sun.wave_active()
	_wave_k = move_toward(_wave_k, 1.0 if on else 0.0, delta * 0.8)
	_wave_layer.visible = _wave_k > 0.01
	if _wave_layer.visible:
		_wave_mat.set_shader_parameter("k", _wave_k * (0.35 if preload("res://scripts/core/efeitos.gd").reduzidos() else 1.0))  # Bloco 54
		_wave_mat.set_shader_parameter("t", _t)


# ------------------------------------------------------------ escudo solar (vitória)
const DOMO_SHADER := """
shader_type canvas_item;
uniform vec2 size = vec2(800.0, 600.0);
uniform float grow = 1.0;
uniform float t = 0.0;
uniform vec4 cor : source_color = vec4(0.55, 0.88, 1.0, 1.0);
void fragment() {
	vec2 px = floor(UV * size / 2.0) * 2.0 + 1.0;  // blocos de 2 px (pixel art)
	vec2 c = vec2(size.x * 0.5, size.y - size.x * 0.25);  // centro da base (elipse 2:1 no chão)
	float rx = max(size.x * 0.5 * grow, 1.0);
	vec2 d = px - c;
	float chao = length(vec2(d.x / rx, d.y / (rx * 0.5)));
	float domo = length(vec2(d.x / rx, d.y / (rx * 0.8)));
	float a = 0.0;
	if (d.y <= 0.0 && domo <= 1.0) {
		float borda = step(0.9, domo) * 0.45 + step(0.97, domo) * 0.25;
		float faixa = step(0.85, fract(-d.y / 14.0 + t * 0.5)) * 0.18;
		a = 0.10 + borda + faixa * (1.0 - borda);
	}
	if (d.y > 0.0 && chao <= 1.0 && chao > 0.95) {
		a = 0.55;
	}
	a = floor(a * 5.0) / 5.0;
	COLOR = vec4(cor.rgb, a * cor.a);
}
"""


func _build_domo() -> void:
	_domo = ColorRect.new()
	_domo.name = "Domo"
	_domo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_domo.visible = false
	_domo_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = DOMO_SHADER
	_domo_mat.shader = sh
	_domo.material = _domo_mat
	add_child(_domo)


func _sync_domo(delta: float) -> void:
	var sun := _node("sun")
	var shield := _node("escudos") as Node2D
	var on: bool = sun != null and sun.get("won") == true and shield != null
	if not on:
		_domo.visible = false
		_domo_grow = 0.0
		return
	_domo_grow = minf(_domo_grow + delta / 3.0, 1.0)  # ativando: cresce do gerador pra fora
	var e := ease(_domo_grow, 0.4)
	var r: float = 520.0 * _view.S  # cobre a vila
	var c: Vector2 = _view.to_screen(shield.global_position)
	var size := Vector2(r * 2.0, r * 0.8 + r * 0.5)
	_domo.visible = true
	_domo.position = c - Vector2(r, r * 0.8)
	_domo.size = size
	_domo_mat.set_shader_parameter("size", size)
	_domo_mat.set_shader_parameter("grow", e)
	_domo_mat.set_shader_parameter("t", _t)
	var flash := 1.0 + (1.0 - _domo_grow) * 1.5  # clarão ao ligar
	_domo_mat.set_shader_parameter("cor", Color(0.55 * flash, 0.88 * flash, 1.0, 1.0))


# ------------------------------------------------------------ festa
func _set_festa(on: bool) -> void:
	if on == _festa_on:
		return
	_festa_on = on
	for b in _bandeiras:
		b[0].queue_free()
	_bandeiras.clear()
	if not on:
		return
	var hub := _node("village_hub") as Node2D
	if hub == null:
		return
	var sf := sprite_frames("bandeirinhas")
	if sf.get_frame_count("default") == 0:
		return
	var p0 := hub.global_position
	# três varais na frente do Centro (mastros nas pontas): [esquerda, direita] no chão da lógica
	for par in [[Vector2(-120, 60), Vector2(-40, 92)], [Vector2(-30, 96), Vector2(50, 96)], [Vector2(60, 92), Vector2(140, 60)]]:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = sf
		a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		a.light_mask = 2
		a.frame = randi() % maxi(sf.get_frame_count("default"), 1)
		a.play("default")
		add_child(a)
		_bandeiras.append([a, p0 + par[0], p0 + par[1]])
	_confete(p0)


const MASTRO := 34.0  # altura dos mastros das bandeirinhas (px de arte)


func _sync_festa(delta: float) -> void:
	for b in _bandeiras:
		var a: AnimatedSprite2D = b[0]
		var l: Vector2 = _view.to_screen(b[1]) + Vector2(0, -MASTRO)
		var r: Vector2 = _view.to_screen(b[2]) + Vector2(0, -MASTRO)
		var w: float = a.sprite_frames.get_frame_texture("default", 0).get_width()
		a.position = ((l + r) * 0.5).round()
		a.rotation = (r - l).angle()
		a.scale = Vector2((r - l).length() / w, 1.0)
	if not _festa_on:
		return
	var dn := _node("day_night")
	var noite: bool = dn != null and dn.has_method("darkness") and dn.darkness() > 0.45
	_fogos_cd -= delta
	if noite and _fogos_cd <= 0.0:
		_fogos_cd = randf_range(0.7, 1.6)
		var hub := _node("village_hub") as Node2D
		if hub:
			var c: Vector2 = _view.to_screen(hub.global_position + Vector2(randf_range(-120, 120), randf_range(-60, 60)))
			_fogo(c + Vector2(0, -randf_range(110, 170)))


func _fogo(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.texture = tex("fogos")
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 40
	p.lifetime = 1.3
	p.scale_amount_min = 2.0  # faísca de 2x2 px de arte
	p.scale_amount_max = 2.0
	p.position = at
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 70.0
	p.gravity = Vector2(0, 45)
	p.damping_min = 30.0
	p.damping_max = 40.0
	p.color = FOGOS_CORES[randi() % FOGOS_CORES.size()] * _contra_ambiente()  # brilha mesmo no escuro
	p.color_ramp = _fade()
	p.light_mask = 0
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## A noite escurece tudo (CanvasModulate): o que brilha sozinho leva a cor de volta (até 4x).
func _contra_ambiente() -> Color:
	var amb := get_tree().current_scene.get_node_or_null("Ambient") as CanvasModulate if get_tree().current_scene else null
	if amb == null:
		return Color.WHITE
	var c := amb.color
	return Color(minf(1.0 / maxf(c.r, 0.05), 4.0), minf(1.0 / maxf(c.g, 0.05), 4.0), minf(1.0 / maxf(c.b, 0.05), 4.0), 1.0)


## Um lugar livre perto do ponto (sem pedra/tocha/decoração em cima, chão andável).
func _livre(p0: Vector2, offs: Array) -> Vector2:
	var env := _node("environment")
	var outros: Array = []
	if env:
		for c in env.get_children():
			if c is Node2D:
				outros.append((c as Node2D).global_position)
	for o in offs:
		var p: Vector2 = p0 + o
		var ok := true
		for q in outros:
			if q.distance_to(p) < 30.0:
				ok = false
				break
		if ok:
			return p
	return p0 + offs[0]


func _confete(hub_ground: Vector2) -> void:
	var c: Vector2 = _view.to_screen(hub_ground) + Vector2(0, -120)
	for k in 4:
		var t := tex("confete_%d" % k)
		if t == null:
			continue
		var p := CPUParticles2D.new()
		p.texture = t
		p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = 14
		p.lifetime = 3.0
		p.position = c
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(90, 10)
		p.direction = Vector2(0, -1)
		p.spread = 60.0
		p.initial_velocity_min = 30.0
		p.initial_velocity_max = 70.0
		p.gravity = Vector2(0, 40)
		p.damping_min = 10.0
		p.damping_max = 20.0
		p.angular_velocity_min = -180.0
		p.angular_velocity_max = 180.0
		p.color_ramp = _fade()
		p.light_mask = 2
		add_child(p)
		p.emitting = true
		p.finished.connect(p.queue_free)


# ------------------------------------------------------------ greve
func _set_greve(on: bool) -> void:
	var ativa := not _greve.is_empty()
	if on == ativa:
		return
	for n in _greve:
		_drop_node(n)
	_greve.clear()
	if not on:
		return
	var hub := _node("village_hub") as Node2D
	if hub == null:
		return
	var p0 := hub.global_position
	var lugares := [Vector2(36, 78), Vector2(-20, 86), Vector2(70, 40), Vector2(-60, 70), Vector2(10, 110), Vector2(90, 90)]
	var bp := _livre(p0, lugares)
	var barril := _spawn_prop("barril_fogo", bp, true)
	if barril:
		var fumaca := CPUParticles2D.new()  # fumaça escura (vira a textura de fumaça no espelho)
		fumaca.name = "Smoke"
		fumaca.position = Vector2(0, -26)
		fumaca.amount = 10
		fumaca.lifetime = 2.6
		fumaca.direction = Vector2(0.2, -1)
		fumaca.spread = 14.0
		fumaca.gravity = Vector2(4, -6)
		fumaca.initial_velocity_min = 8.0
		fumaca.initial_velocity_max = 14.0
		fumaca.scale_amount_min = 3.0
		fumaca.scale_amount_max = 5.0
		fumaca.color = Color(0.22, 0.2, 0.19, 0.85)
		fumaca.color_ramp = _fade()
		barril.add_child(fumaca)
		var luz := PointLight2D.new()  # a luz do fogo (tipo fogueira, iso_luz.gd)
		luz.name = "FireLight"
		luz.position = Vector2(0, -24)
		luz.color = Color(1.0, 0.6, 0.3)
		luz.energy = 0.7
		luz.texture = load("res://assets/game/light_radial.tres")
		luz.texture_scale = 0.4
		barril.add_child(luz)
		_greve.append(barril)
	for off in [Vector2(34, -16), Vector2(-28, 14)]:
		var s := _spawn_prop("placa_greve", _livre(bp, [off, off * 1.6, -off]))
		if s:
			_greve.append(s)


# ------------------------------------------------------------ satélite: pulsos saindo da antena
func _sync_pulsos(delta: float) -> void:
	_pulso_cd -= delta
	if _pulso_cd <= 0.0 and not _antenas.is_empty():
		_pulso_cd = PULSO_EVERY
		for lab in _antenas:
			var a = _antenas[lab]
			if a != null and is_instance_valid(a):
				_pulsos.append([_view.to_screen((a as Node2D).global_position) + Vector2(-6, -60), 0.0])
	for p in _pulsos:
		p[1] += delta
	_pulsos = _pulsos.filter(func(p): return p[1] < 1.6)


func _draw() -> void:
	for p in _pulsos:
		var k: float = p[1] / 1.6
		var r := roundf(lerpf(4.0, 34.0, k))
		var col := Color(0.6, 1.0, 0.75, (1.0 - k) * 0.8)
		draw_set_transform(p[0], 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, r, PI * 1.1, PI * 1.9, 10, col, 2.0)  # arcos subindo (sinal)
	draw_set_transform(Vector2.ZERO)
	for b in _bandeiras:  # mastros das bandeirinhas
		for g in [b[1], b[2]]:
			var base: Vector2 = _view.to_screen(g).round()
			draw_rect(Rect2(base + Vector2(-1, -MASTRO - 2), Vector2(2, MASTRO + 2)), Color(0.28, 0.2, 0.14))
			draw_rect(Rect2(base + Vector2(-1, -MASTRO - 2), Vector2(1, MASTRO + 2)), Color(0.45, 0.33, 0.22))


# ------------------------------------------------------------ mina: gotas pingando
func _build_gotas() -> void:
	_gotas = CPUParticles2D.new()
	_gotas.name = "Gotas"
	_gotas.texture = tex("gota")
	_gotas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_gotas.amount = 24
	_gotas.lifetime = 1.1
	_gotas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_gotas.direction = Vector2(0, 1)
	_gotas.spread = 0.0
	_gotas.gravity = Vector2(0, 260)
	_gotas.initial_velocity_min = 10.0
	_gotas.initial_velocity_max = 30.0
	_gotas.color = Color(0.62, 0.72, 0.8, 0.8)
	_gotas.color_ramp = _fade()
	_gotas.emitting = false
	_gotas.light_mask = 2
	add_child(_gotas)


func _sync_gotas() -> void:
	var env := _node("environment")
	var cam := _view.get("_camera") as Node
	if env == null or cam == null or not cam.has_method("ground_center") or not env.has_method("level_at"):
		_gotas.emitting = false
		return
	var g: Vector2 = cam.ground_center()
	var deep: bool = env.level_at(g) > 0
	if _gotas.emitting != deep:
		_gotas.emitting = deep
	if deep:
		var v: Rect2 = _view.call("_screen_view")
		_gotas.position = v.get_center() + Vector2(0, -v.size.y * 0.3)
		_gotas.emission_rect_extents = v.size * Vector2(0.5, 0.2)
