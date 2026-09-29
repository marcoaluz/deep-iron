extends Node2D
## PROTÓTIPO ROTA A — isométrico completo (isolado do jogo; rode esta cena com F6).
##
## - O jogo "de verdade" continua no chão (proto_logic.gd): prédios, platô, navegação e os
##   ipezinhos andam em coordenada de chão. Esta cena só PROJETA pra tela e desprojeta o clique.
## - Ordem de profundidade: tudo que fica em pé vai num Node2D com y_sort_enabled; o y de cada
##   nó é a chave (x + y)/2 do chão + a altura em que está (ver iso_box.gd).
## - Prédio grande (Centro da Vila) é CORTADO em pedaços de ~40 px, cada um com a sua chave:
##   é a solução clássica pro boneco que passa do lado. N alterna pro modo ingênuo (um ponto
##   só pro prédio inteiro) pra ver o erro acontecer.
##
## Controles: roda = zoom • botão do meio / WASD = mover • clique esq. = selecionar
## • clique dir. = mandar o ipezinho selecionado (ou o 2º) andar até ali • C = construir casa
## • N = ordenação ingênua x cortada • Tab = mostrar pegadas/pontos de ordenação • Esc = cancela

const Logic := preload("res://prototipos/camera/proto_logic.gd")
const IsoBox := preload("res://prototipos/camera/iso_box.gd")
const SHEETS := [preload("res://assets/game/ipezinho_m0.png"), preload("res://assets/game/ipezinho_engenheiro_f2.png")]
const FLOOR := preload("res://assets/game/floor_cave.png")
const SLICE := 40.0
const CASA := Vector2(60, 40)
const COLORS := {
	"centro": [Color(0.55, 0.45, 0.36), Color(0.62, 0.3, 0.22)],
	"armazem": [Color(0.5, 0.42, 0.3), Color(0.45, 0.5, 0.55)],
	"casa": [Color(0.62, 0.52, 0.4), Color(0.7, 0.36, 0.26)],
	"plato": [Color(0.42, 0.37, 0.33), Color(0.46, 0.52, 0.34)],
}

var logic := Logic.new()
var _sorted: Node2D
var _floor: Node2D
var _views := {}  # Building -> Array de IsoBox
var _wviews := {}  # Worker -> Node2D
var _plateau_boxes: Array = []
var _ramp_view: Node2D
var _naive := false
var _debug := false
var _placing := false
var _ghost: Node2D
var _ghost_reason := ""
var _selected = null  # Building ou Worker
var _hud: Label
var _mouse_ground := Vector2.ZERO
var _mouse_h := 0.0
var _force_mouse := Vector2.INF  # (captura) finge o mouse neste ponto do chão


func _ready() -> void:
	_build_logic()
	_floor = Node2D.new()
	_floor.transform = Transform2D(Vector2(1, 0.5), Vector2(-1, 0.5), Vector2.ZERO)  # chão projetado
	_floor.z_index = -10
	add_child(_floor)
	var fs := Sprite2D.new()
	fs.texture = FLOOR
	fs.centered = false
	fs.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fs.region_enabled = true
	fs.region_rect = Rect2(Vector2.ZERO, logic.bounds.size / 2.0)
	fs.scale = Vector2(2, 2)
	fs.position = logic.bounds.position
	_floor.add_child(fs)
	var overlay := Node2D.new()
	_floor.add_child(overlay)
	overlay.draw.connect(_draw_floor_overlay.bind(overlay))
	_sorted = Node2D.new()
	_sorted.y_sort_enabled = true
	add_child(_sorted)
	_build_terrain()
	for b in logic.buildings:
		_make_building_view(b)
	for i in logic.workers.size():
		_make_worker_view(logic.workers[i], SHEETS[i % SHEETS.size()])
	_ghost = IsoBox.new()
	_ghost.visible = false
	_sorted.add_child(_ghost)
	add_child(preload("res://prototipos/camera/proto_camera.gd").new())
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	_hud.add_theme_font_size_override("font_size", 14)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 5)
	layer.add_child(_hud)
	_apply_demo_args()


func _exit_tree() -> void:
	logic.free_nav()


# ------------------------------------------------------------ o mundo (no chão)
func _build_logic() -> void:
	logic.plateau = Rect2(-380, -280, 240, 150)
	logic.plateau_h = 36.0
	logic.gap = Vector2(-290, -250)
	logic.ramp = Rect2(-290, -130, 40, 60)
	logic.add_cliff_edges()
	logic.terrain_blocks.append(Rect2(-296, -130, 6, 60))  # laterais da rampa
	logic.terrain_blocks.append(Rect2(-250, -130, 6, 60))
	logic.buildings.append(Logic.Building.new("centro", Rect2(-90, -40, 180, 80), 110.0))
	logic.buildings.append(Logic.Building.new("armazem", Rect2(150, -40, 80, 56), 60.0))
	logic.buildings.append(Logic.Building.new("casa", Rect2(-360, -260, 60, 40), 50.0, logic.plateau_h))  # em cima do platô
	logic.buildings.append(Logic.Building.new("casa", Rect2(-200, 80, 60, 40), 50.0))
	logic.buildings.append(Logic.Building.new("casa", Rect2(40, 130, 60, 40), 50.0))
	logic.setup_nav()
	# 1º ipezinho: dá a volta no Centro da Vila (atrás, dos lados e na frente) — o caso difícil
	var w1 := Logic.Worker.new("Zeca", Vector2(-110, -60))
	w1.loop = [Vector2(-110, -60), Vector2(110, -60), Vector2(110, 60), Vector2(-110, 60)]
	# 2º: sobe e desce o platô pela rampa (e obedece o clique direito)
	var w2 := Logic.Worker.new("Mel", Vector2(0, 110))
	w2.loop = [Vector2(0, 110), Vector2(-230, -200)]
	logic.workers.append(w1)
	logic.workers.append(w2)


func _build_terrain() -> void:
	for r in _slices(logic.plateau):
		var b: Node2D = IsoBox.new()
		b.setup(r, 0.0, logic.plateau_h, COLORS.plato[0], COLORS.plato[1])
		_sorted.add_child(b)
		_plateau_boxes.append(b)
	_ramp_view = Node2D.new()
	var c := logic.ramp.get_center()
	_ramp_view.position = Vector2(IsoBox.iso(c).x, (c.x + c.y) * 0.5)
	_ramp_view.draw.connect(_draw_ramp)
	_sorted.add_child(_ramp_view)


## Pedaços de ~SLICE px (quadrados) de uma pegada.
func _slices(r: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var nx := maxi(ceili(r.size.x / SLICE), 1)
	var ny := maxi(ceili(r.size.y / SLICE), 1)
	var sx := r.size.x / nx
	var sy := r.size.y / ny
	for i in nx:
		for j in ny:
			out.append(Rect2(r.position + Vector2(i * sx, j * sy), Vector2(sx, sy)))
	return out


func _make_building_view(b) -> void:
	for old in _views.get(b, []):
		old.queue_free()
	var boxes := []
	var col: Array = COLORS[b.kind]
	var parts: Array[Rect2] = _slices(b.rect)
	if _naive:
		parts = [b.rect]
	for r in parts:
		var box: Node2D = IsoBox.new()
		box.setup(r, b.level, b.height, col[0], col[1])
		box.show_sort = _debug
		box.highlight = _selected == b
		_sorted.add_child(box)
		boxes.append(box)
	_views[b] = boxes


func _make_worker_view(w, sheet: Texture2D) -> void:
	var v := Node2D.new()
	var s := Sprite2D.new()
	s.name = "S"
	s.texture = sheet
	s.hframes = 4
	s.scale = Vector2(2, 2)
	s.offset = Vector2(0, -8.5)
	v.add_child(s)
	var mark := Node2D.new()
	mark.name = "M"
	v.add_child(mark)
	mark.draw.connect(func():
		if _debug:
			mark.draw_circle(Vector2.ZERO, 3.0, Color(0.2, 0.8, 1.0)))
	_sorted.add_child(v)
	_wviews[w] = v


# ------------------------------------------------------------ desenho por quadro
var _trace_t := 0.0


func _process(delta: float) -> void:
	logic.tick(delta)
	if "trace" in OS.get_cmdline_user_args():
		_trace_t += delta
		if fmod(_trace_t, 0.5) < delta:
			print("t=%.1f  Zeca %s  Mel %s" % [_trace_t, logic.workers[0].pos.round(), logic.workers[1].pos.round()])
	for w in logic.workers:
		var v: Node2D = _wviews[w]
		var h := logic.height_at(w.pos)
		v.position = Vector2(IsoBox.iso(w.pos).x, (w.pos.x + w.pos.y) * 0.5 + h)  # y = chave
		var s: Sprite2D = v.get_node("S")
		s.position = Vector2(0, -2.0 * h)  # desenha na altura certa
		s.frame = int(w.anim) % 4 if w.moving else 0
		var sv := IsoBox.iso(w.velocity) - IsoBox.iso(Vector2.ZERO)
		if absf(sv.x) > 0.01:
			s.flip_h = sv.x < 0.0
		s.modulate = Color(1.3, 1.3, 0.8) if _selected == w else Color.WHITE
		v.get_node("M").queue_redraw()
	_update_mouse()
	_update_hud()


## Clique volta pro chão: primeiro tenta o topo do platô (desprojeta na altura dele), senão o chão.
func _update_mouse() -> void:
	var m := get_global_mouse_position() if _force_mouse == Vector2.INF else IsoBox.iso(_force_mouse)
	var g_top := IsoBox.iso_inv(m, logic.plateau_h)
	if logic.plateau.has_point(g_top):
		_mouse_ground = g_top
		_mouse_h = logic.plateau_h
	else:
		_mouse_ground = IsoBox.iso_inv(m)
		_mouse_h = logic.height_at(_mouse_ground)
	if _placing:
		var r := Rect2(_mouse_ground.snapped(Vector2(10, 10)) - CASA * 0.5, CASA)
		_ghost_reason = logic.can_place(r)
		_ghost.setup(r, logic.level_of(r), 50.0, COLORS.casa[0], COLORS.casa[1])
		_ghost.modulate = Color(0.6, 1.0, 0.6, 0.65) if _ghost_reason == "" else Color(1.0, 0.4, 0.4, 0.65)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_C:
				_placing = not _placing
				_ghost.visible = _placing
			KEY_ESCAPE:
				_placing = false
				_ghost.visible = false
			KEY_N:
				_naive = not _naive
				for b in logic.buildings:
					_make_building_view(b)
			KEY_TAB:
				_set_debug(not _debug)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _placing:
				_try_place()
			else:
				_select(_pick())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _placing:
				_placing = false
				_ghost.visible = false
			else:
				var w = _selected if _selected is Logic.Worker else logic.workers[1]
				w.loop.clear()
				logic.send(w, _mouse_ground)


func _try_place() -> void:
	var r := Rect2(_mouse_ground.snapped(Vector2(10, 10)) - CASA * 0.5, CASA)
	if logic.can_place(r) != "":
		return
	var b := Logic.Building.new("casa", r, 50.0, logic.level_of(r))
	logic.buildings.append(b)
	logic.rebuild_nav()
	_make_building_view(b)


## O que está embaixo do mouse: o mais "da frente" (maior chave) entre prédios e ipezinhos.
func _pick():
	var m := get_global_mouse_position()
	var best = null
	var best_key := -INF
	for b in _views:
		for box in _views[b]:
			if box.position.y > best_key and Geometry2D.is_point_in_polygon(m, box.silhouette()):
				best = b
				best_key = box.position.y
	for w in _wviews:
		var v: Node2D = _wviews[w]
		var s: Sprite2D = v.get_node("S")
		var r := Rect2(v.position + s.position + Vector2(-16, -34), Vector2(32, 34))
		if r.has_point(m) and v.position.y + 0.1 > best_key:
			best = w
			best_key = v.position.y
	return best


func _select(what) -> void:
	_selected = what
	for b in _views:
		for box in _views[b]:
			box.highlight = b == what
			box.queue_redraw()


func _set_debug(on: bool) -> void:
	_debug = on
	for b in _views:
		for box in _views[b]:
			box.show_sort = on
			box.queue_redraw()
	for box in _plateau_boxes:
		box.show_sort = on
		box.queue_redraw()
	for n in _floor.get_children():
		n.queue_redraw()


# ------------------------------------------------------------ desenhos auxiliares
func _draw_floor_overlay(o: Node2D) -> void:
	# (dentro do nó projetado: desenhar em coordenada de CHÃO já sai em losango)
	if not _debug:
		return
	for x in range(int(logic.bounds.position.x), int(logic.bounds.end.x) + 1, 40):
		o.draw_line(Vector2(x, logic.bounds.position.y), Vector2(x, logic.bounds.end.y), Color(1, 1, 1, 0.12))
	for y in range(int(logic.bounds.position.y), int(logic.bounds.end.y) + 1, 40):
		o.draw_line(Vector2(logic.bounds.position.x, y), Vector2(logic.bounds.end.x, y), Color(1, 1, 1, 0.12))
	for b in logic.buildings:
		o.draw_rect(b.rect, Color(1, 0.8, 0.2, 0.9), false, 1.0)
	for t in logic.terrain_blocks:
		o.draw_rect(t, Color(1, 0.3, 0.3, 0.7))


func _draw_ramp() -> void:
	var r := logic.ramp
	var h := logic.plateau_h
	var o := _ramp_view.position
	var p := func(q: Vector2, z: float) -> Vector2: return IsoBox.iso(q, z) - o
	var c00 := r.position
	var c10 := Vector2(r.end.x, r.position.y)
	var c11 := r.end
	var c01 := Vector2(r.position.x, r.end.y)
	var top := PackedVector2Array([p.call(c00, h), p.call(c10, h), p.call(c11, 0.0), p.call(c01, 0.0)])
	var side := PackedVector2Array([p.call(c10, 0.0), p.call(c11, 0.0), p.call(c10, h)])
	_ramp_view.draw_colored_polygon(side, COLORS.plato[0].darkened(0.3))
	_ramp_view.draw_colored_polygon(top, Color(0.55, 0.47, 0.36))
	for i in range(1, 6):  # degraus
		var t := i / 6.0
		var a: Vector2 = p.call(c00.lerp(c01, t), h * (1.0 - t))
		var bb: Vector2 = p.call(c10.lerp(c11, t), h * (1.0 - t))
		_ramp_view.draw_line(a, bb, Color(0, 0, 0, 0.35), 1.0)


func _update_hud() -> void:
	var sel := "nada"
	if _selected is Logic.Worker:
		sel = "ipezinho %s" % _selected.name
	elif _selected is Logic.Building:
		sel = _selected.kind
	_hud.text = "ROTA A — isométrico  (protótipo, arte provisória)\n" \
		+ "mouse no chão: (%d, %d)  altura %d   •   selecionado: %s\n" % [_mouse_ground.x, _mouse_ground.y, _mouse_h, sel] \
		+ "ordenação do Centro/prédios: %s  (N alterna)   •   Tab: pegadas e pontos de ordenação\n" % ("INGÊNUA (1 ponto por prédio)" if _naive else "CORTADA em pedaços de 40") \
		+ ("CONSTRUINDO casa: %s  (clique esq. confirma, dir./Esc cancela)" % ("pode aqui" if _ghost_reason == "" else _ghost_reason) if _placing else "C = construir casa • clique esq. seleciona • clique dir. manda andar") \
		+ "\n%d FPS" % Engine.get_frames_per_second()


# ------------------------------------------------------------ captura (linha de comando)
## `-- naive debug ghost` etc. só pra gerar as imagens de comparação.
func _apply_demo_args() -> void:
	var args := OS.get_cmdline_user_args()
	if "naive" in args:
		_naive = true
		for b in logic.buildings:
			_make_building_view(b)
	if "debug" in args:
		_set_debug.call_deferred(true)
	for a in args:
		if a.begins_with("mouse="):
			var xy := a.trim_prefix("mouse=").split(",")
			_force_mouse = Vector2(float(xy[0]), float(xy[1]))
	if "ghost" in args:
		_placing = true
		_ghost.visible = true
