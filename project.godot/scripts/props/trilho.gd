extends Node2D
## Trilho do vagonete (grupo "trilhos") — Bloco 64. Só os pontos (lógica do chão) e se está
## quebrado; quem desenha é a vista iso (iso_view: por baixo de tudo que fica em pé) e, na vista
## antiga, este nó mesmo (_draw).

var points := PackedVector2Array()
var broken := false:
	set(v):
		broken = v
		version += 1
		queue_redraw()
## Muda quando os pontos ou o estado mudam (a vista iso redesenha).
var version := 0
var _acc: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	add_to_group("trilhos")
	z_index = -6  # vista antiga: no chão


func set_points(pts: PackedVector2Array) -> void:
	points = pts
	_acc = PackedFloat32Array()
	var s := 0.0
	_acc.append(0.0)
	for i in range(1, points.size()):
		s += points[i].distance_to(points[i - 1])
		_acc.append(s)
	version += 1
	queue_redraw()


func length() -> float:
	return _acc[_acc.size() - 1] if _acc.size() > 0 else 0.0


## Ponto a `d` px do começo do trilho.
func point_at(d: float) -> Vector2:
	if points.is_empty():
		return global_position
	if d <= 0.0:
		return points[0]
	for i in range(1, points.size()):
		if _acc[i] >= d:
			var seg := _acc[i] - _acc[i - 1]
			var k := (d - _acc[i - 1]) / seg if seg > 0.0 else 0.0
			return points[i - 1].lerp(points[i], k)
	return points[points.size() - 1]


## Direção (lógica do chão) do trilho em `d`.
func dir_at(d: float) -> Vector2:
	for i in range(1, points.size()):
		if _acc[i] >= d:
			return (points[i] - points[i - 1]).normalized()
	return Vector2.RIGHT if points.size() < 2 else (points[points.size() - 1] - points[points.size() - 2]).normalized()


func _draw() -> void:
	if points.size() < 2:
		return
	var env := get_tree().get_first_node_in_group("environment") if is_inside_tree() else null
	if env and env.has_method("has_iso_map") and env.has_iso_map():
		return  # a vista iso desenha
	for i in range(1, points.size()):
		var a := points[i - 1] - global_position
		var b := points[i] - global_position
		var n := (b - a).normalized().orthogonal() * 3.0
		draw_line(a + n, b + n, Color(0.45, 0.42, 0.4), 1.5)
		draw_line(a - n, b - n, Color(0.45, 0.42, 0.4), 1.5)
