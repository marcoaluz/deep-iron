extends RefCounted
## PROTÓTIPO DE CÂMERA (isolado do jogo): o "chão lógico" que as duas rotas compartilham.
##
## Tudo aqui é coordenada de CHÃO (x, y), igual ao jogo de hoje: prédio = retângulo no chão,
## navegação feita no chão, ipezinho anda no chão. A rota A (isométrica) e a rota B (top-down
## com relevo) só mudam COMO isso aparece na tela e como o clique volta pro chão.
## Nada aqui conhece a câmera ou a projeção.

class Building:
	var kind: String
	var rect: Rect2  # pegada no chão
	var height: float  # altura do prédio (a rota A desenha como caixa)
	var level: float  # altura do chão embaixo dele (0 = chão; platô = plateau_h)

	func _init(k: String, r: Rect2, h: float, lvl: float = 0.0) -> void:
		kind = k
		rect = r
		height = h
		level = lvl


class Worker:
	var name: String
	var pos: Vector2
	var path := PackedVector2Array()
	var speed := 70.0
	var loop: Array[Vector2] = []  # patrulha (vai de ponto em ponto pela navegação)
	var loop_i := 0
	var facing := 1.0  # +1 direita na TELA, -1 esquerda (a rota decide)
	var moving := false
	var anim := 0.0
	var velocity := Vector2.ZERO  # no chão

	func _init(n: String, p: Vector2) -> void:
		name = n
		pos = p


var bounds := Rect2(-420, -300, 840, 620)
var buildings: Array[Building] = []
var workers: Array[Worker] = []
## Platô (relevo): retângulo no chão, a altura dele e a abertura por onde se sobe.
var plateau := Rect2()
var plateau_h := 0.0
var gap := Vector2()  # x inicial/final da abertura na borda de baixo (sul) do platô
var ramp := Rect2()  # rota A: rampa que desce da abertura
## Obstáculos extras de terreno (beiras do penhasco, face do penhasco na rota B).
var terrain_blocks: Array[Rect2] = []
## Folga da navegação (metade da largura do corpo).
var agent_radius := 7.0

var _map: RID
var _region: RID


func setup_nav() -> void:
	_map = NavigationServer2D.map_create()
	NavigationServer2D.map_set_active(_map, true)
	_region = NavigationServer2D.region_create()
	NavigationServer2D.region_set_map(_region, _map)
	rebuild_nav()


func free_nav() -> void:
	NavigationServer2D.free_rid(_region)
	NavigationServer2D.free_rid(_map)


## Refaz a navegação (ao construir): o mesmo esquema do jogo — chão andável menos obstáculos.
func rebuild_nav() -> void:
	var poly := NavigationPolygon.new()
	poly.agent_radius = agent_radius
	var src := NavigationMeshSourceGeometryData2D.new()
	src.add_traversable_outline(_outline(bounds))
	for b in buildings:
		src.add_obstruction_outline(_outline(b.rect))
	for r in terrain_blocks:
		src.add_obstruction_outline(_outline(r))
	NavigationServer2D.bake_from_source_geometry_data(poly, src)
	NavigationServer2D.region_set_navigation_polygon(_region, poly)
	NavigationServer2D.map_force_update(_map)


static func _outline(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## Altura do chão num ponto (rota A usa; na rota B o relevo é só desenho).
func height_at(p: Vector2) -> float:
	if plateau.has_point(p):
		return plateau_h
	if ramp.has_area() and ramp.has_point(p):
		return plateau_h * (1.0 - clampf((p.y - ramp.position.y) / ramp.size.y, 0.0, 1.0))
	return 0.0


## Borda de penhasco (rota A): as 4 beiras do platô são obstáculo, menos a abertura da rampa;
## as laterais da rampa também.
func add_cliff_edges(thick: float = 6.0) -> void:
	var r := plateau
	terrain_blocks.append(Rect2(r.position.x - thick, r.position.y - thick, r.size.x + thick * 2.0, thick))  # norte
	terrain_blocks.append(Rect2(r.position.x - thick, r.position.y, thick, r.size.y))  # oeste
	terrain_blocks.append(Rect2(r.end.x, r.position.y, thick, r.size.y))  # leste
	terrain_blocks.append(Rect2(r.position.x - thick, r.end.y, gap.x - r.position.x + thick, thick))  # sul, antes da abertura
	terrain_blocks.append(Rect2(gap.y, r.end.y, r.end.x - gap.y + thick, thick))  # sul, depois


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return NavigationServer2D.map_get_path(_map, from, NavigationServer2D.map_get_closest_point(_map, to), true)


func send(w: Worker, to: Vector2) -> void:
	w.path = find_path(w.pos, to)
	if w.path.size() > 0 and w.path[0].distance_to(w.pos) < 1.0:
		w.path.remove_at(0)


func tick(delta: float) -> void:
	for w in workers:
		if w.path.is_empty() and not w.loop.is_empty():
			# só avança quando CHEGOU (a 1ª consulta pode voltar vazia: a navegação do Godot
			# ainda não sincronizou no 1º quadro)
			if w.pos.distance_to(w.loop[w.loop_i]) < 3.0:
				w.loop_i = (w.loop_i + 1) % w.loop.size()
			send(w, w.loop[w.loop_i])
		w.moving = not w.path.is_empty()
		w.velocity = Vector2.ZERO
		var step := w.speed * delta
		while step > 0.0 and not w.path.is_empty():
			var to := w.path[0]
			var d := w.pos.distance_to(to)
			if d <= step:
				w.velocity = (to - w.pos)
				w.pos = to
				w.path.remove_at(0)
				step -= d
			else:
				w.velocity = (to - w.pos).normalized() * step
				w.pos += w.velocity
				step = 0.0
		if w.moving:
			w.anim += delta * 8.0


## O retângulo cabe aqui? (dentro do mapa, sem encostar em prédio/penhasco, e todo no mesmo
## nível: inteiro em cima do platô ou inteiro fora dele)
func can_place(r: Rect2) -> String:
	if not bounds.encloses(r):
		return "fora do mapa"
	for b in buildings:
		if b.rect.grow(4.0).intersects(r):
			return "em cima de " + b.kind
	for t in terrain_blocks:
		if t.intersects(r):
			return "no penhasco"
	if ramp.has_area() and ramp.intersects(r):
		return "na rampa"
	if plateau.has_area() and plateau.intersects(r) and not plateau.encloses(r):
		return "metade no platô"
	return ""


func level_of(r: Rect2) -> float:
	return plateau_h if plateau.has_area() and plateau.encloses(r) else 0.0
