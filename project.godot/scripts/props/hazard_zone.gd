extends Node2D
## Zona de perigo do fundo (grupo "zonas_perigo") — Bloco 42.
##   gas      Bolsão de gás    (nível 2)  -> Máscara de gás
##   calor    Fenda de calor   (abismo)   -> Traje térmico
##   radiacao Veio radioativo  (nível 2)  -> Traje antirradiação
## Só entra quem veste o traje certo (equipment.gd + ipezinho.gd). Dentro ficam jazidas
## ricas (mineral_node.gd: hazard) que valem o traje. Visual: área tingida com a borda
## tracejada, partículas do perigo (gás subindo, brasa, faísca verde), placa na entrada
## e o aviso escrito. A zona é andável; quem não pode entrar é o ipezinho sem traje.

const SIGN := preload("res://assets/game/placa_perigo.png")
const KINDS := ["gas", "calor", "radiacao"]
const COLORS := {"gas": Color(0.45, 0.8, 0.35), "calor": Color(1.0, 0.45, 0.15), "radiacao": Color(0.75, 1.0, 0.3)}

@export_enum("gas", "calor", "radiacao") var kind: String = "gas"
## Raio da zona (px do mundo), achatado na vertical como o resto do mapa.
@export var radius: float = 90.0
## Onde fica a placa (em relação ao centro): a "entrada".
@export var sign_offset: Vector2 = Vector2(-70, 60)

var _label: Label


func _ready() -> void:
	add_to_group("zonas_perigo")
	z_index = -9  # a mancha fica no chão, embaixo de quem anda
	var c: Color = COLORS[kind]
	var p := CPUParticles2D.new()
	p.amount = 26
	p.lifetime = 2.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius * 0.85
	p.scale = Vector2(1.0, 0.55)
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 6.0 if kind == "gas" else 14.0
	p.initial_velocity_max = 14.0 if kind == "gas" else 30.0
	p.scale_amount_min = 3.0 if kind == "gas" else 1.5
	p.scale_amount_max = 6.0 if kind == "gas" else 2.5
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	fade.colors = PackedColorArray([Color(c, 0.0), Color(c.lightened(0.2), 0.55 if kind == "gas" else 0.9), Color(c, 0.0)])
	p.color_ramp = fade
	p.z_as_relative = false
	p.z_index = 15  # a fumaça/brasa passa por cima de quem está lá dentro
	add_child(p)
	var s := Sprite2D.new()
	s.texture = SIGN
	s.hframes = 3
	s.frame = KINDS.find(kind)
	s.scale = Vector2(2, 2)
	s.offset = Vector2(0, -10)
	s.position = sign_offset
	s.z_as_relative = false
	s.z_index = 0
	add_child(s)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", c.lightened(0.3))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(180, 30)
	_label.position = sign_offset + Vector2(-90, -62)
	_label.z_as_relative = false
	_label.z_index = 20
	add_child(_label)
	refresh()


## Dentro da zona? (elipse: o mapa é visto meio de cima)
func contains(p: Vector2) -> bool:
	var d := p - global_position
	return (d.x * d.x) / (radius * radius) + (d.y * d.y) / (radius * radius * 0.36) <= 1.0


## Ponto andável logo FORA da zona (pra quem é mandado sair). Tenta primeiro o lado de
## `from`, depois a entrada (a placa) e depois em volta — a zona pode encostar na parede,
## e aí o ponto andável mais perto daquele lado ainda cairia dentro dela.
func exit_point(from: Vector2) -> Vector2:
	var map := get_world_2d().navigation_map
	var dirs: Array[Vector2] = []
	var own := from - global_position
	if own.length() >= 1.0:
		dirs.append(own.normalized())
	dirs.append(sign_offset.normalized())
	for i in 8:
		dirs.append(Vector2.RIGHT.rotated(TAU * i / 8.0))
	for dir in dirs:
		var p := global_position + Vector2(dir.x * (radius + 28.0), dir.y * (radius * 0.6 + 20.0))
		var q := NavigationServer2D.map_get_closest_point(map, p)
		if not contains(q):
			return q
	return NavigationServer2D.map_get_closest_point(map, global_position + sign_offset * 2.0)


func refresh() -> void:
	var eq := get_tree().get_first_node_in_group("equipment") if is_inside_tree() else null
	var suit: String = eq.NAMES[kind] if eq else "traje"
	var n: int = eq.usable(kind) if eq else 0
	_label.text = "%s\nsó com %s (%d no vestiário)" % [eq.ZONE_NAMES[kind].to_upper() if eq else kind, suit.to_lower(), n]


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 30 == 0:
		refresh()


func _draw() -> void:
	var c: Color = COLORS[kind]
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, radius, Color(c, 0.13))
	var n := 56
	for i in n:
		if i % 2 == 0:
			draw_arc(Vector2.ZERO, radius, TAU * i / n, TAU * (i + 1) / n, 3, Color(c, 0.55), 2.0)
