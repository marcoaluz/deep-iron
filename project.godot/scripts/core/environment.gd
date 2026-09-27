extends Node2D
## Monta a caverna: chão, parede de rocha em volta, pedras, cristais, tochas
## (com luz tremulando) e escoras de madeira. A distribuição é sorteada a partir
## de `map_seed`, então o mapa é sempre igual até você trocar a seed.
##
## Depois de posicionar tudo, "assa" a malha de navegação (NavigationRegion2D):
## a borda do mapa, as pedras grandes, os cristais, as tochas e a base de cada
## estação viram obstáculos que os ipezinhos contornam.
##
## Também desliga as luzes que estão fora da câmera (grupo "cullable_lights").

signal navigation_ready

## Grupos de estruturas que bloqueiam a navegação e afastam a decoração.
const STATION_GROUPS := ["minerios", "comedouros", "armazens", "casas", "village_hub", "escavadeira", "oficina", "coleta_comida"]

@export_group("Mapa")
@export var map_rect: Rect2 = Rect2(-720, -440, 1440, 880)
@export var map_seed: int = 1337
## Escala dos pixels (os personagens usam 2x).
@export var pixel_scale: float = 2.0
@export var floor_texture: Texture2D
@export var wall_texture: Texture2D

@export_group("Decoração")
@export var boulder_count: int = 14
@export var pebble_count: int = 70
@export var crystal_count: int = 7
@export var torch_count: int = 10
## Espaço entre as pedras grandes que contornam a borda do mapa.
@export var edge_boulder_spacing: float = 44.0
## Distância livre ao redor das estações (minério, comedouro, armazém).
@export var keep_clear_radius: float = 70.0
@export var boulder_textures: Array[Texture2D] = []
@export var pebble_textures: Array[Texture2D] = []
@export var crystal_textures: Array[Texture2D] = []
## Tocha acesa (a chama é desenhada por cima da apagada e some de dia).
@export var torch_texture: Texture2D
## Tocha apagada (base). Sem ela, a tocha fica sempre com a chama.
@export var torch_unlit_texture: Texture2D
@export var support_texture: Texture2D
## Sombra projetada no chão (elipse com borda em xadrez) posta sob pedras, cristais, tochas e escoras.
@export var shadow_texture: Texture2D

@export_group("Navegação")
## Raio usado pra afastar o caminho das paredes/obstáculos (≈ raio do ipezinho).
@export var nav_agent_radius: float = 7.0
## Quanto a área andável fica pra dentro da borda do mapa (cobre a base das pedras da borda).
@export var nav_edge_inset: float = 36.0
## Pedras e cristais bloqueiam a passagem.
@export var decorations_block: bool = true

@export_group("Luz")
@export var light_texture: Texture2D
@export var torch_light_color: Color = Color(1.0, 0.6, 0.26)
@export var torch_light_energy: float = 1.25
@export var torch_light_scale: float = 1.4
@export var crystal_light_color: Color = Color(0.45, 0.75, 1.0)
@export var crystal_light_energy: float = 0.7
@export var flicker_amount: float = 0.15
## Liga/desliga luzes conforme estejam perto da área visível da câmera.
@export var cull_lights: bool = true
## Folga (px do mundo) além da tela antes de desligar uma luz — ~ raio da luz.
@export var light_cull_margin: float = 260.0
@export var light_cull_interval: float = 0.2

var navigation_region: NavigationRegion2D

var _rng := RandomNumberGenerator.new()
var _placed: Array[Vector2] = []
var _obstacles: Array[PackedVector2Array] = []
var _torch_lights: Array[PointLight2D] = []
var _torch_flames: Array[Sprite2D] = []
var _day_night: Node = null
var _time: float = 0.0
var _cull_timer: float = 0.0


func _ready() -> void:
	add_to_group("environment")
	_rng.seed = map_seed
	_build_ground()
	# as estações são irmãs deste nó; espera um frame pra elas entrarem nos grupos
	await get_tree().process_frame
	_build_edges()
	_scatter(pebble_count, pebble_textures, 10.0, 0.4, _add_pebble)
	_scatter(boulder_count, boulder_textures, 40.0, 1.0, _add_boulder)
	_scatter(crystal_count, crystal_textures, 50.0, 1.0, _add_crystal)
	_scatter(torch_count, [torch_texture], 60.0, 0.6, _add_torch)
	_build_navigation()


func _process(delta: float) -> void:
	_time += delta
	# tochas acendem/apagam com a escuridão do DayNight (fade suave)
	var level := _torch_level()
	for flame in _torch_flames:
		flame.modulate.a = level
	for i in _torch_lights.size():
		var light := _torch_lights[i]
		light.enabled = level > 0.005
		if not light.visible or not light.enabled:
			continue
		var f := sin(_time * 9.0 + i * 1.7) * 0.5 + sin(_time * 23.0 + i * 3.1) * 0.5
		light.energy = torch_light_energy * level * (1.0 + f * flicker_amount)

	if cull_lights:
		_cull_timer -= delta
		if _cull_timer <= 0.0:
			_cull_timer = light_cull_interval
			_cull_offscreen_lights()


# ------------------------------------------------------------ performance: luzes
func _cull_offscreen_lights() -> void:
	var vp := get_viewport()
	var view := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	view = view.grow(light_cull_margin)
	for light in get_tree().get_nodes_in_group("cullable_lights"):
		light.visible = view.has_point(light.global_position)


# ------------------------------------------------------------ navegação
func _build_navigation() -> void:
	navigation_region = NavigationRegion2D.new()
	navigation_region.name = "NavigationRegion"
	navigation_region.navigation_polygon = _bake_navigation()
	add_child(navigation_region)
	navigation_ready.emit()


## Refaz a malha de navegação (ex.: casa nova posicionada pelo jogador).
func rebuild_navigation() -> void:
	if navigation_region:
		navigation_region.navigation_polygon = _bake_navigation()


func _bake_navigation() -> NavigationPolygon:
	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = nav_agent_radius
	var source := NavigationMeshSourceGeometryData2D.new()
	source.add_traversable_outline(_rect_outline(walkable_rect()))
	if decorations_block:
		for o in _obstacles:
			source.add_obstruction_outline(o)
	for group in STATION_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			if node.has_method("get_obstacle_outline"):
				var outline: PackedVector2Array = node.get_obstacle_outline()
				if outline.size() >= 3:
					source.add_obstruction_outline(outline)
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source)
	return nav_poly


## Área onde dá pra andar (dentro da borda de pedras do mapa).
func walkable_rect() -> Rect2:
	return map_rect.grow(-nav_edge_inset)


## Contornos dos obstáculos da decoração (pedras, cristais, tochas) — pra validar construção.
func decoration_obstacles() -> Array[PackedVector2Array]:
	return _obstacles


func _rect_outline(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## Registra a "base" de uma decoração como obstáculo (elipse).
func _add_obstacle(center: Vector2, radius: Vector2) -> void:
	var outline := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		outline.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	_obstacles.append(outline)


# ------------------------------------------------------------ chão e paredes
func _build_ground() -> void:
	var wall_margin := 1200.0
	if wall_texture:
		_tiled_sprite(wall_texture, map_rect.grow(wall_margin), -11)
	if floor_texture:
		_tiled_sprite(floor_texture, map_rect, -10)


func _tiled_sprite(tex: Texture2D, rect: Rect2, z: int) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, rect.size / pixel_scale)
	s.scale = Vector2.ONE * pixel_scale
	s.position = rect.position
	s.z_index = z
	add_child(s)


func _build_edges() -> void:
	if boulder_textures.is_empty():
		return
	var r := map_rect
	var points: Array[Vector2] = []
	var x := r.position.x
	while x <= r.end.x:
		points.append(Vector2(x, r.position.y))
		points.append(Vector2(x, r.end.y))
		x += edge_boulder_spacing
	var y := r.position.y + edge_boulder_spacing
	while y < r.end.y:
		points.append(Vector2(r.position.x, y))
		points.append(Vector2(r.end.x, y))
		y += edge_boulder_spacing
	for p in points:
		var jitter := Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-8, 8))
		var k := _rng.randf_range(1.1, 1.8)
		var sprite := _deco_sprite(boulder_textures[_rng.randi() % boulder_textures.size()], p + jitter)
		sprite.scale = Vector2.ONE * pixel_scale * k
		sprite.flip_h = _rng.randf() < 0.5
		_add_shadow(sprite, 1.2)
		# sem obstáculo individual: nav_edge_inset já mantém todo mundo longe da borda

	# escoras de madeira ao longo da parede de cima, como entradas de túnel
	if support_texture:
		var sx := r.position.x + 140.0
		while sx < r.end.x - 100.0:
			var pos := Vector2(sx + _rng.randf_range(-30, 30), r.position.y + 18.0)
			_add_shadow(_deco_sprite(support_texture, pos), 1.1)
			_placed.append(pos)
			sx += _rng.randf_range(260.0, 380.0)


## Base de uma pedra de 16px desenhada com a escala `s` (a origem fica no pé).
func _add_boulder_obstacle(p: Vector2, s: float) -> void:
	_add_obstacle(p + Vector2(0, -3.5 * s), Vector2(6.0 * s, 3.5 * s))


# ------------------------------------------------------------ decoração espalhada
func _scatter(count: int, textures: Array, min_spacing: float, clear_factor: float, add_fn: Callable) -> void:
	if textures.is_empty() or textures[0] == null:
		return
	var inner := map_rect.grow(-40.0)
	for i in count:
		for attempt in 30:
			var p := Vector2(
				_rng.randf_range(inner.position.x, inner.end.x),
				_rng.randf_range(inner.position.y, inner.end.y))
			if _is_free(p, min_spacing, keep_clear_radius * clear_factor):
				_placed.append(p)
				add_fn.call(textures[_rng.randi() % textures.size()], p)
				break


func _is_free(p: Vector2, min_spacing: float, clear_radius: float) -> bool:
	for group in STATION_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			# estruturas grandes informam o próprio centro/raio livre
			var center: Vector2 = node.get_clear_center() if node.has_method("get_clear_center") else node.global_position
			var r := clear_radius
			if node.has_method("get_clear_radius"):
				r = maxf(r, node.get_clear_radius())
			if p.distance_to(center) < r:
				return false
	for q in _placed:
		if p.distance_to(q) < min_spacing:
			return false
	return true


func _add_pebble(tex: Texture2D, p: Vector2) -> void:
	var s := _deco_sprite(tex, p)
	s.z_index = -5  # sempre no chão, por baixo de todo mundo
	s.flip_h = _rng.randf() < 0.5
	s.modulate = Color(1, 1, 1, 0.9)


func _add_boulder(tex: Texture2D, p: Vector2) -> void:
	var s := _deco_sprite(tex, p)
	var k := _rng.randf_range(0.8, 1.3)
	s.scale = Vector2.ONE * pixel_scale * k
	s.flip_h = _rng.randf() < 0.5
	_add_shadow(s, 1.2)
	_add_boulder_obstacle(p, pixel_scale * k)


func _add_crystal(tex: Texture2D, p: Vector2) -> void:
	var s := _deco_sprite(tex, p)
	var k := _rng.randf_range(1.0, 1.4)  # cristais já são 32px
	s.scale = Vector2.ONE * k
	s.flip_h = _rng.randf() < 0.5
	_add_shadow(s, 0.9)
	_add_obstacle(p + Vector2(0, -3.0 * k), Vector2(tex.get_width() * 0.4 * k, 4.0 * k))
	if light_texture:
		var light := PointLight2D.new()
		light.texture = light_texture
		light.color = crystal_light_color
		light.energy = crystal_light_energy
		light.texture_scale = 0.6
		light.position = Vector2(0, -tex.get_height() * 0.5)
		light.add_to_group("cullable_lights")
		s.add_child(light)


## 0..1 de quanto as tochas estão acesas (1 se não houver DayNight na cena).
func _torch_level() -> float:
	if _day_night == null or not is_instance_valid(_day_night):
		_day_night = get_tree().get_first_node_in_group("day_night")
	return _day_night.torch_level() if _day_night else 1.0


func _add_torch(tex: Texture2D, p: Vector2) -> void:
	# base = tocha apagada; a chama (sprite aceso inteiro) vai por cima e faz o fade
	var s := _deco_sprite(torch_unlit_texture if torch_unlit_texture else tex, p)
	s.add_to_group("tochas")
	if torch_unlit_texture:
		var flame := Sprite2D.new()
		flame.texture = tex
		flame.offset = s.offset
		s.add_child(flame)
		_torch_flames.append(flame)
	_add_shadow(s, 1.4)
	_add_obstacle(p + Vector2(0, -2), Vector2(5, 3))
	if light_texture:
		var light := PointLight2D.new()
		light.texture = light_texture
		light.color = torch_light_color
		light.energy = torch_light_energy
		light.texture_scale = torch_light_scale / pixel_scale  # compensa a escala do sprite
		light.position = Vector2(0, -tex.get_height() + 2)
		light.add_to_group("cullable_lights")
		s.add_child(light)
		_torch_lights.append(light)


## Sombra no pé de uma decoração, um pouco deslocada pra baixo/direita (sombra "longa").
## `width_factor` é a largura da sombra em relação à largura do sprite.
func _add_shadow(s: Sprite2D, width_factor: float) -> void:
	if shadow_texture == null:
		return
	var shadow := Sprite2D.new()
	shadow.texture = shadow_texture
	shadow.z_index = -4  # acima do chão e das pedrinhas, abaixo de tudo que fica em pé
	var k := s.texture.get_width() * width_factor / shadow_texture.get_width()
	shadow.scale = Vector2(k, k * 0.8)
	shadow.position = Vector2(s.texture.get_width() * 0.08, 0.5)
	s.add_child(shadow)


## Sprite com a origem no "pé" (base da imagem), pro y-sort funcionar direito.
func _deco_sprite(tex: Texture2D, p: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.offset = Vector2(0, -tex.get_height() * 0.5)
	s.scale = Vector2.ONE * pixel_scale
	s.position = p
	add_child(s)
	return s
