extends Node2D
## PROTÓTIPO ROTA A (endurecida): 4 × 8 DIREÇÕES do personagem + a PICARETA HÍBRIDA.
## Isolado do jogo; F6 nesta cena. Boneco provisório desenhado em código (não é arte).
##
## Os dois bonecos fazem o MESMO caminho no chão (projetado em isométrico):
##   esquerda: 4 direções "de losango" (as bordas do chão = diagonais da tela) — 2 desenhos
##             (frente-diagonal e costas-diagonal) + espelho. Com histerese de 15° pra não
##             ficar trocando de desenho quando anda reto pra baixo/cima na tela.
##   direita:  8 direções — 5 desenhos (S, SE, L, NE, N) + espelho.
## Picareta nas costas: quando ele olha pra câmera, ela fica ATRÁS do corpo (aparece o cabo
## por cima do ombro); de costas, fica NA FRENTE. No golpe, ela é parte do desenho do golpe.

const Iso := preload("res://prototipos/camera/iso_core.gd")

## Direções: nome -> ângulo NA TELA (0 = direita, 90 = baixo). As de losango são os eixos do chão.
const DIRS8 := {"L": 0.0, "SE": 26.57, "S": 90.0, "SO": 153.43, "O": 180.0, "NO": 206.57, "N": 270.0, "NE": 333.43}
const DIRS4 := {"SE": 26.57, "SO": 153.43, "NO": 206.57, "NE": 333.43}
## Qual desenho de verdade cada direção usa (o resto é espelho).
const ART8 := {"L": "L", "SE": "SE", "S": "S", "SO": "SE (espelho)", "O": "L (espelho)", "NO": "NE (espelho)", "N": "N", "NE": "NE"}
const ART4 := {"SE": "frente-diagonal", "SO": "frente-diagonal (espelho)", "NO": "costas-diagonal (espelho)", "NE": "costas-diagonal"}

## Caminho no chão (volta fechada): bordas do chão, diagonais e uma curva.
var path: Array[Vector2] = []
var t := 0.0
var speed := 55.0
var _dir4 := "SE"
var _dir8 := "SE"
var _swaps4 := 0
var _swaps8 := 0
var _mining := 0.0
var _hud: Label


func _ready() -> void:
	var pts := [Vector2(-120, -60), Vector2(60, -60), Vector2(60, 60), Vector2(140, 140), Vector2(140, 60)]
	for i in 25:  # meia volta em curva
		var a := PI * 0.5 + PI * i / 24.0
		pts.append(Vector2(90, 60) + Vector2(cos(a), sin(a)) * 50.0 * Vector2(1, -1) + Vector2(0, 0))
	pts.append_array([Vector2(-60, 20), Vector2(-120, 80), Vector2(-160, -20)])
	path.assign(pts.map(func(q): return q * 0.62))
	var cam := Camera2D.new()
	cam.zoom = Vector2(2.0, 2.0)
	cam.position = Vector2(0, 30)
	add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	_hud.add_theme_font_size_override("font_size", 14)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 5)
	layer.add_child(_hud)


func _length() -> float:
	var l := 0.0
	for i in path.size():
		l += path[i].distance_to(path[(i + 1) % path.size()])
	return l


## Posição e direção (no chão) a uma distância d do começo.
func _at(d: float) -> Array:
	d = fmod(d, _length())
	for i in path.size():
		var a := path[i]
		var b := path[(i + 1) % path.size()]
		var seg := a.distance_to(b)
		if d <= seg:
			return [a.lerp(b, d / seg), (b - a).normalized()]
		d -= seg
	return [path[0], Vector2.RIGHT]


func _process(delta: float) -> void:
	t += delta
	_mining = fmod(t, 9.0)
	queue_redraw()


func _snap(ang: float, dirs: Dictionary, current: String, hyst: float) -> String:
	var best := current
	var best_e := absf(wrapf(ang - dirs[current], -180.0, 180.0)) - hyst  # a atual ganha um bônus
	for k in dirs:
		var e := absf(wrapf(ang - dirs[k], -180.0, 180.0))
		if e < best_e:
			best_e = e
			best = k
	return best


func _draw() -> void:
	var mining := _mining > 7.5  # a cada 9 s, 1,5 s minerando (golpe)
	var p: Array = _at(t * speed if not mining else (t - (_mining - 7.5)) * speed)
	var g: Vector2 = p[0]
	var gd: Vector2 = p[1]
	var sd := Iso.iso(gd) - Iso.iso(Vector2.ZERO)
	var ang := rad_to_deg(sd.angle())
	var n4 := _snap(ang, DIRS4, _dir4, 15.0)
	var n8 := _snap(ang, DIRS8, _dir8, 8.0)
	if n4 != _dir4:
		_swaps4 += 1
	if n8 != _dir8:
		_swaps8 += 1
	_dir4 = n4
	_dir8 = n8
	for side in [-1, 1]:
		var origin := Vector2(160.0 * side, 0)
		_draw_ground(origin)
		# o caminho
		var prev := Vector2.INF
		for i in path.size() + 1:
			var q := Iso.iso(path[i % path.size()]) + origin
			if prev != Vector2.INF:
				draw_line(prev, q, Color(1, 1, 1, 0.18), 1.0)
			prev = q
		var name: String = _dir4 if side < 0 else _dir8
		var dirs: Dictionary = DIRS4 if side < 0 else DIRS8
		_draw_guy(Iso.iso(g) + origin, dirs[name], mining)
		draw_line(Iso.iso(g) + origin + Vector2(0, 3), Iso.iso(g) + origin + Vector2(0, 3) + sd.normalized() * 22.0, Color(0.3, 1.0, 0.4, 0.8), 1.0)
	_hud.text = "4 × 8 DIREÇÕES  (boneco provisório; a linha verde é pra onde ele anda de verdade)\n" \
		+ "movimento na tela: %d°\n" % roundi(wrapf(ang, 0.0, 360.0)) \
		+ "ESQUERDA  4 direções: usa %s  → desenho: %s   (trocas: %d)\n" % [_dir4, ART4[_dir4], _swaps4] \
		+ "DIREITA   8 direções: usa %s  → desenho: %s   (trocas: %d)\n" % [_dir8, ART8[_dir8], _swaps8] \
		+ ("MINERANDO: a picareta sai das costas e vira parte do desenho do golpe" if mining else "picareta nas costas: atrás do corpo de frente, na frente dele de costas")


func _draw_ground(o: Vector2) -> void:
	for i in range(-6, 7):
		draw_line(Iso.iso(Vector2(i * 30, -180)) + o, Iso.iso(Vector2(i * 30, 180)) + o, Color(1, 1, 1, 0.06), 1.0)
		draw_line(Iso.iso(Vector2(-180, i * 30)) + o, Iso.iso(Vector2(180, i * 30)) + o, Color(1, 1, 1, 0.06), 1.0)


## Boneco provisório virado pra `face` (graus na tela). Capacete com lanterna na frente,
## olhos quando olha pra câmera, perfil nas laterais, só as costas quando vira pra cima.
func _draw_guy(feet: Vector2, face: float, mining: bool) -> void:
	var dir := Vector2.from_angle(deg_to_rad(face))
	var toward_cam := dir.y > 0.2  # olhando pra baixo na tela = pra câmera
	var away := dir.y < -0.2
	var bob := sin(t * 12.0) * 1.2 if not mining else 0.0
	var body := feet + Vector2(0, -12 + bob)
	var head := feet + Vector2(0, -27 + bob)
	draw_ellipse_shadow(feet)
	var pick_side := Vector2(-dir.x, 0).normalized() * 5.0 if absf(dir.x) > 0.1 else Vector2(4, 0)
	var swing := sin((_mining - 7.5) * 9.0) if mining else 0.0
	# picareta NAS COSTAS atrás do corpo (de frente pra câmera / de lado)
	if not mining and not away:
		_draw_pick(body + pick_side + Vector2(0, -4), false)
	draw_rect(Rect2(body + Vector2(-6, -7), Vector2(12, 14)), Color(0.35, 0.45, 0.6))  # macacão
	draw_rect(Rect2(feet + Vector2(-5, -5 + bob), Vector2(4, 5)), Color(0.2, 0.16, 0.14))  # botas
	draw_rect(Rect2(feet + Vector2(1, -5 - bob), Vector2(4, 5)), Color(0.2, 0.16, 0.14))
	if away:  # de costas: nuca + capacete por trás (sem rosto)
		draw_circle(head, 7.0, Color(0.45, 0.3, 0.22))
		draw_circle(head + Vector2(0, -2), 6.5, Color(0.72, 0.58, 0.28))
	else:
		draw_circle(head, 7.0, Color(0.93, 0.72, 0.58))  # rosto
		draw_arc(head, 7.5, PI, TAU, 12, Color(0.72, 0.58, 0.28), 5.0)  # capacete de latão
	if toward_cam or absf(dir.y) <= 0.2:
		var eye_off := dir.x * 3.0
		if absf(dir.y) <= 0.2:  # perfil: um olho só, pro lado que olha
			draw_circle(head + Vector2(dir.x * 4.0, 1), 1.1, Color.BLACK)
		else:
			draw_circle(head + Vector2(-2.5 + eye_off, 1), 1.1, Color.BLACK)
			draw_circle(head + Vector2(2.5 + eye_off, 1), 1.1, Color.BLACK)
		draw_circle(head + Vector2(dir.x * 5.0, -5), 1.8, Color(1.0, 0.85, 0.3))  # lanterna na frente
	# de costas: a picareta NAS COSTAS fica na frente do corpo
	if not mining and away:
		_draw_pick(body + pick_side * 0.4 + Vector2(0, -2), true)
	if mining:  # golpe: a picareta é parte do desenho do golpe, na mão, pro lado que olha
		var hand := body + dir * 7.0 + Vector2(0, -3)
		var tip := hand + Vector2.from_angle(deg_to_rad(face) - 1.2 + swing * 1.4) * 14.0
		draw_line(hand, tip, Color(0.45, 0.3, 0.18), 2.0)
		draw_line(tip + Vector2(-4, 1), tip + Vector2(4, -1), Color(0.7, 0.72, 0.78), 2.5)


func _draw_pick(at: Vector2, front: bool) -> void:
	var a := at + Vector2(-5, 6)
	var b := at + Vector2(5, -8)
	draw_line(a, b, Color(0.45, 0.3, 0.18) if front else Color(0.36, 0.24, 0.15), 2.0)
	draw_line(b + Vector2(-5, -1), b + Vector2(4, 3), Color(0.7, 0.72, 0.78) if front else Color(0.55, 0.57, 0.62), 2.5)


func draw_ellipse_shadow(feet: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(feet + Vector2(cos(a) * 9.0, sin(a) * 4.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.3))
