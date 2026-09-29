extends Node2D
## PROTÓTIPO ROTA A: uma caixa isométrica (prédio, pedaço de prédio ou bloco do platô).
##
## Projeção 2:1: tela = (x − y, (x + y)/2 − altura). A posição do NÓ não é onde ele aparece:
## o y do nó é a CHAVE DE ORDENAÇÃO pro y_sort do Godot, (x + y)/2 do centro no chão + o nível
## em que está. O desenho é deslocado pra aparecer no lugar certo.

var rect: Rect2  # pegada no chão
var level := 0.0  # altura da base
var height := 20.0  # altura da caixa
var side := Color(0.5, 0.45, 0.4)
var roof := Color(0.7, 0.6, 0.5)
var show_sort := false
var highlight := false


static func iso(p: Vector2, z: float = 0.0) -> Vector2:
	return Vector2(p.x - p.y, (p.x + p.y) * 0.5 - z)


## Tela -> chão (no nível z).
static func iso_inv(s: Vector2, z: float = 0.0) -> Vector2:
	var sy := s.y + z
	return Vector2((s.x + 2.0 * sy) * 0.5, (2.0 * sy - s.x) * 0.5)


func setup(r: Rect2, lvl: float, h: float, side_col: Color, roof_col: Color) -> void:
	rect = r
	level = lvl
	height = h
	side = side_col
	roof = roof_col
	var c := r.get_center()
	position = Vector2(iso(c).x, (c.x + c.y) * 0.5 + lvl)
	queue_redraw()


func _p(p: Vector2, z: float) -> Vector2:
	return iso(p, z) - position


func _corners() -> Array[Vector2]:
	var r := rect
	return [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]


func _draw() -> void:
	var c := _corners()  # c[0]=(x0,y0) c[1]=(x1,y0) c[2]=(x1,y1) c[3]=(x0,y1)
	var zb := level
	var zt := level + height
	var left := PackedVector2Array([_p(c[3], zb), _p(c[2], zb), _p(c[2], zt), _p(c[3], zt)])  # face y1
	var right := PackedVector2Array([_p(c[1], zb), _p(c[2], zb), _p(c[2], zt), _p(c[1], zt)])  # face x1
	var top := PackedVector2Array([_p(c[0], zt), _p(c[1], zt), _p(c[2], zt), _p(c[3], zt)])
	if height > 0.5:
		draw_colored_polygon(left, side)
		draw_colored_polygon(right, side.darkened(0.3))
	draw_colored_polygon(top, roof)
	var line := Color(1.0, 0.9, 0.2) if highlight else Color(0, 0, 0, 0.45)
	var w := 2.0 if highlight else 1.0
	for poly in ([left, right, top] if height > 0.5 else [top]):
		var closed: PackedVector2Array = poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, line, w)
	if show_sort:
		# ponto de ordenação: centro da pegada no chão (a chave é o y do nó)
		draw_circle(_p(rect.get_center(), zb), 3.0, Color(1, 0.2, 0.2))
		draw_line(_p(rect.get_center(), zb), Vector2.ZERO, Color(1, 0.2, 0.2, 0.6), 1.0)


## Contorno na tela (pra clique): o fecho convexo das 8 quinas.
func silhouette() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for c in _corners():
		pts.append(iso(c, level))
		pts.append(iso(c, level + height))
	return Geometry2D.convex_hull(pts)
