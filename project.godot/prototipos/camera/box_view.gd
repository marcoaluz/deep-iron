extends Node2D
## PROTÓTIPO ROTA A (endurecida): desenha UMA caixa (prédio, pedaço, terreno, rampa).
## Dois jeitos de ordenar:
##   - y_sort (ingênuo/fatiado): o y do nó é a CHAVE e o desenho é deslocado;
##   - caixas (topológico): o nó fica na origem e quem manda é o z_index.

const Iso := preload("res://prototipos/camera/iso_core.gd")

var box  # Iso.Box
var side := Color(0.5, 0.45, 0.4)
var roof := Color(0.7, 0.6, 0.5)
var outline := true
var highlight := false


func setup(b, side_col: Color, roof_col: Color, use_key: bool) -> void:
	box = b
	side = side_col
	roof = roof_col
	set_key_mode(use_key)


func set_key_mode(use_key: bool) -> void:
	position = Vector2(Iso.iso(box.rect.get_center()).x, Iso.key(box)) if use_key else Vector2.ZERO
	queue_redraw()


func _p(p: Vector2, z: float) -> Vector2:
	return Iso.iso(p, z) - position


## As faces visíveis (na tela, coordenadas globais): {top, left, right}.
static func faces(b) -> Dictionary:
	var c := Iso.corners(b.rect)  # 0=(x0,y0) 1=(x1,y0) 2=(x1,y1) 3=(x0,y1)
	var zb: float = b.zb
	var zt: float = b.zt
	var top: PackedVector2Array
	if b.kind == "rampa":
		# sobe pro norte: lado norte (y0) em zt, lado sul (y1) em zb
		top = PackedVector2Array([Iso.iso(c[0], zt), Iso.iso(c[1], zt), Iso.iso(c[2], zb), Iso.iso(c[3], zb)])
		return {"top": top, "left": PackedVector2Array(), "right": PackedVector2Array([Iso.iso(c[1], zb), Iso.iso(c[2], zb), Iso.iso(c[1], zt)])}
	top = PackedVector2Array([Iso.iso(c[0], zt), Iso.iso(c[1], zt), Iso.iso(c[2], zt), Iso.iso(c[3], zt)])
	var out := {"top": top,
		"left": PackedVector2Array([Iso.iso(c[3], zb), Iso.iso(c[2], zb), Iso.iso(c[2], zt), Iso.iso(c[3], zt)]),
		"right": PackedVector2Array([Iso.iso(c[1], zb), Iso.iso(c[2], zb), Iso.iso(c[2], zt), Iso.iso(c[1], zt)])}
	for k in b.hide:
		out[k] = PackedVector2Array()
	return out


func _draw() -> void:
	var f := faces(box)
	var off := -position
	var cols := {"left": side, "right": side.darkened(0.3), "top": roof}
	for k in ["left", "right", "top"]:
		var poly: PackedVector2Array = f[k]
		if poly.size() < 3 or k in box.hide:
			continue
		var moved := PackedVector2Array()
		for q in poly:
			moved.append(q + off)
		draw_colored_polygon(moved, cols[k])
		if outline or highlight:
			var closed := moved.duplicate()
			closed.append(moved[0])
			draw_polyline(closed, Color(1.0, 0.9, 0.2) if highlight else Color(0, 0, 0, 0.35), 2.0 if highlight else 1.0)
