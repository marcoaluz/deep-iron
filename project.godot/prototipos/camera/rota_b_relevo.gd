extends Node2D
## PROTÓTIPO ROTA B — top-down com relevo em camadas (isolado do jogo; rode esta cena com F6).
##
## - Mesma lógica de chão da rota A (proto_logic.gd) e a MESMA projeção do jogo de hoje:
##   posição no chão = posição na tela. Nenhuma conta de projeção, clique = mouse direto.
## - Relevo é só desenho, como no Stardew: o platô é uma área do chão com outro piso, e a
##   borda de baixo dele vira uma FACE DE ROCHA que ocupa espaço no chão (não dá pra andar)
##   com uma escada aberta. Quem está em cima do platô está simplesmente "mais pro norte".
## - Ordem de profundidade: o y_sort do jogo de hoje (um ponto por objeto, na base).
## - Prédios em escala 3 (casa ≈ 2,3× a altura do minerador).
##
## Controles: roda = zoom • botão do meio / WASD = mover • clique esq. = selecionar
## • clique dir. = mandar o ipezinho selecionado (ou o 2º) andar até ali • C = construir casa
## • Tab = mostrar pegadas/pontos de ordenação • Esc = cancela

const Logic := preload("res://prototipos/camera/proto_logic.gd")
const SHEETS := [preload("res://assets/game/ipezinho_m0.png"), preload("res://assets/game/ipezinho_engenheiro_f2.png")]
const FLOOR := preload("res://assets/game/floor_cave.png")
const GRASS := preload("res://assets/game/floor_clareira.png")
## tipo -> [textura, quadros, quadro usado]
const ART := {
	"centro": [preload("res://assets/game/centro_vila.png"), 5, 2],
	"armazem": [preload("res://assets/game/armazem.png"), 1, 0],
	"casa": [preload("res://assets/game/casa.png"), 3, 0],
}
const BSCALE := 3.0  # prédios maiores que no jogo (lá é 2)
const FACE_H := 40.0  # altura da face do penhasco (em px de chão)

var logic := Logic.new()
var _sorted: Node2D
var _overlay: Node2D
var _views := {}  # Building -> Sprite2D
var _wviews := {}  # Worker -> Node2D
var _debug := false
var _placing := false
var _ghost: Sprite2D
var _ghost_reason := ""
var _selected = null
var _hud: Label
var _mouse := Vector2.ZERO
var _force_mouse := Vector2.INF
var _faces: Array[Rect2] = []


func _ready() -> void:
	_build_logic()
	var fs := _tiled(FLOOR, logic.bounds, -10)
	add_child(fs)
	add_child(_tiled(GRASS, logic.plateau, -9))  # topo do platô
	var decal := Node2D.new()  # escada e beiras (no chão, atrás de tudo)
	decal.z_index = -8
	decal.draw.connect(_draw_decals.bind(decal))
	add_child(decal)
	_sorted = Node2D.new()
	_sorted.y_sort_enabled = true
	add_child(_sorted)
	for f in _faces:
		var n := Node2D.new()
		n.position = Vector2(f.get_center().x, f.end.y)  # ponto de ordenação: a base da face
		n.draw.connect(_draw_face.bind(n, f))
		_sorted.add_child(n)
	for b in logic.buildings:
		_make_building_view(b)
	for i in logic.workers.size():
		_make_worker_view(logic.workers[i], SHEETS[i % SHEETS.size()])
	_ghost = Sprite2D.new()
	_ghost.texture = ART.casa[0]
	_ghost.hframes = ART.casa[1]
	_ghost.scale = Vector2.ONE * BSCALE
	_ghost.offset = _art_offset("casa")
	_ghost.visible = false
	_sorted.add_child(_ghost)
	_overlay = Node2D.new()
	_overlay.z_index = 50
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
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


func _tiled(tex: Texture2D, r: Rect2, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, r.size / 2.0)
	s.scale = Vector2(2, 2)
	s.position = r.position
	s.z_index = z
	return s


# ------------------------------------------------------------ o mundo (no chão)
## Pegada de um prédio desenhado com a base em `base` (centro de baixo): a faixa de baixo do
## desenho, ~40% da altura — o resto do desenho é "o prédio de pé", que cobre quem passa atrás.
func _footprint(kind: String, base: Vector2) -> Rect2:
	var used := _art_rect(kind)
	var w: float = used.size.x * BSCALE - 6.0
	var d: float = used.size.y * BSCALE * 0.4
	return Rect2(base.x - w * 0.5, base.y - d, w, d)


## Parte DESENHADA do quadro (sem a sobra transparente), em px da textura.
var _art_cache := {}


func _art_rect(kind: String) -> Rect2i:
	if not _art_cache.has(kind):
		var tex: Texture2D = ART[kind][0]
		var fw: int = tex.get_width() / int(ART[kind][1])
		var img := tex.get_image().get_region(Rect2i(fw * int(ART[kind][2]), 0, fw, tex.get_height()))
		_art_cache[kind] = img.get_used_rect()
	return _art_cache[kind]


## Sprite com a BASE da parte desenhada no ponto de ordenação (centro de baixo).
func _art_offset(kind: String) -> Vector2:
	var tex: Texture2D = ART[kind][0]
	var fw: float = tex.get_width() / float(ART[kind][1])
	var used := _art_rect(kind)
	return Vector2(fw * 0.5 - (used.position.x + used.size.x * 0.5), tex.get_height() * 0.5 - used.end.y)


func _build_logic() -> void:
	logic.bounds = Rect2(-440, -320, 880, 640)
	logic.plateau = Rect2(-410, -300, 270, 150)
	logic.gap = Vector2(-320, -280)  # escada na face de baixo
	var p := logic.plateau
	# beiras do platô (norte, oeste, leste) e a FACE de rocha embaixo dele, menos a escada
	logic.terrain_blocks.append(Rect2(p.position.x, p.position.y - 6, p.size.x, 6))
	logic.terrain_blocks.append(Rect2(p.position.x - 6, p.position.y, 6, p.size.y + FACE_H))
	logic.terrain_blocks.append(Rect2(p.end.x, p.position.y, 6, p.size.y + FACE_H))
	_faces = [Rect2(p.position.x, p.end.y, logic.gap.x - p.position.x, FACE_H),
		Rect2(logic.gap.y, p.end.y, p.end.x - logic.gap.y, FACE_H)]
	logic.terrain_blocks.append_array(_faces)
	logic.buildings.append(Logic.Building.new("centro", _footprint("centro", Vector2(0, 60)), 0.0))
	logic.buildings.append(Logic.Building.new("armazem", _footprint("armazem", Vector2(240, 40)), 0.0))
	logic.buildings.append(Logic.Building.new("casa", _footprint("casa", Vector2(-340, -190)), 0.0))  # em cima do platô
	logic.buildings.append(Logic.Building.new("casa", _footprint("casa", Vector2(-220, 190)), 0.0))
	logic.buildings.append(Logic.Building.new("casa", _footprint("casa", Vector2(80, 230)), 0.0))
	logic.setup_nav()
	# mesmos papéis da rota A: Zeca dá a volta no Centro; Mel sobe e desce o platô (pela escada)
	var c: Rect2 = logic.buildings[0].rect
	var w1 := Logic.Worker.new("Zeca", Vector2(c.position.x - 20, c.position.y - 20))
	w1.loop = [w1.pos, Vector2(c.end.x + 20, c.position.y - 20), Vector2(c.end.x + 20, c.end.y + 20), Vector2(c.position.x - 20, c.end.y + 20)]
	var w2 := Logic.Worker.new("Mel", Vector2(0, 140))
	w2.loop = [Vector2(0, 140), Vector2(-260, -230)]
	logic.workers.append(w1)
	logic.workers.append(w2)


## Base (centro de baixo) de um prédio a partir da pegada.
func _base_of(b) -> Vector2:
	return Vector2(b.rect.get_center().x, b.rect.end.y)


func _make_building_view(b) -> void:
	var s := Sprite2D.new()
	var art: Array = ART[b.kind]
	s.texture = art[0]
	s.hframes = art[1]
	s.frame = art[2]
	s.scale = Vector2.ONE * BSCALE
	s.offset = _art_offset(b.kind)  # base do desenho no ponto de ordenação
	s.position = _base_of(b)
	_sorted.add_child(s)
	_views[b] = s


func _make_worker_view(w, sheet: Texture2D) -> void:
	var v := Node2D.new()
	var s := Sprite2D.new()
	s.name = "S"
	s.texture = sheet
	s.hframes = 4
	s.scale = Vector2(2, 2)
	s.offset = Vector2(0, -8.5)
	v.add_child(s)
	_sorted.add_child(v)
	_wviews[w] = v


# ------------------------------------------------------------ por quadro
func _process(delta: float) -> void:
	logic.tick(delta)
	for w in logic.workers:
		var v: Node2D = _wviews[w]
		v.position = w.pos  # sem projeção: chão = tela
		var s: Sprite2D = v.get_node("S")
		s.frame = int(w.anim) % 4 if w.moving else 0
		if absf(w.velocity.x) > 0.01:
			s.flip_h = w.velocity.x < 0.0
		s.modulate = Color(1.3, 1.3, 0.8) if _selected == w else Color.WHITE
	_mouse = get_global_mouse_position() if _force_mouse == Vector2.INF else _force_mouse
	if _placing:
		var r := _footprint("casa", _mouse.snapped(Vector2(10, 10)))
		_ghost_reason = logic.can_place(r)
		_ghost.position = Vector2(r.get_center().x, r.end.y)
		_ghost.modulate = Color(0.6, 1.0, 0.6, 0.7) if _ghost_reason == "" else Color(1.0, 0.4, 0.4, 0.7)
	_overlay.queue_redraw()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_C:
				_placing = not _placing
				_ghost.visible = _placing
			KEY_ESCAPE:
				_placing = false
				_ghost.visible = false
			KEY_TAB:
				_debug = not _debug
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
				logic.send(w, _mouse)


func _try_place() -> void:
	var r := _footprint("casa", _mouse.snapped(Vector2(10, 10)))
	if logic.can_place(r) != "":
		return
	var b := Logic.Building.new("casa", r, 0.0)
	logic.buildings.append(b)
	logic.rebuild_nav()
	_make_building_view(b)


## O que está embaixo do mouse: o retângulo do DESENHO (como no jogo), o mais da frente.
func _pick():
	var best = null
	var best_y := -INF
	for b in _views:
		var s: Sprite2D = _views[b]
		var sr: Rect2 = s.get_global_transform() * s.get_rect()
		if sr.has_point(_mouse) and s.position.y > best_y:
			best = b
			best_y = s.position.y
	for w in _wviews:
		var v: Node2D = _wviews[w]
		if Rect2(v.position + Vector2(-16, -34), Vector2(32, 34)).has_point(_mouse) and v.position.y + 0.1 > best_y:
			best = w
			best_y = v.position.y
	return best


func _select(what) -> void:
	_selected = what
	for b in _views:
		_views[b].modulate = Color(1.25, 1.2, 0.8) if b == what else Color.WHITE


# ------------------------------------------------------------ desenhos auxiliares
## Face de rocha do penhasco (provisória): paredão com rachaduras, lábio claro em cima,
## sombra embaixo. Ela entra no y_sort pela base, igual a um prédio.
func _draw_face(n: Node2D, f: Rect2) -> void:
	var r := Rect2(f.position - n.position, f.size)
	n.draw_rect(r, Color(0.36, 0.31, 0.28))
	n.draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(0.55, 0.5, 0.4))  # lábio
	n.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), Color(0.22, 0.19, 0.18))  # pé
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in int(r.size.x / 14.0):
		var x := r.position.x + 7.0 + i * 14.0 + rng.randf_range(-3, 3)
		n.draw_line(Vector2(x, r.position.y + 6), Vector2(x + rng.randf_range(-4, 4), r.end.y - 6), Color(0.25, 0.21, 0.2), 1.5)
	n.draw_rect(r, Color(0, 0, 0, 0.5), false, 1.0)


func _draw_decals(d: Node2D) -> void:
	var p := logic.plateau
	# escada no vão da face
	var g := Rect2(logic.gap.x, p.end.y, logic.gap.y - logic.gap.x, FACE_H)
	d.draw_rect(g, Color(0.5, 0.45, 0.38))
	for i in 5:
		var y := g.position.y + (i + 1) * g.size.y / 6.0
		d.draw_line(Vector2(g.position.x, y), Vector2(g.end.x, y), Color(0.25, 0.21, 0.18), 2.0)
	# beiras do platô (norte/oeste/leste): linha clara em cima, escura por fora
	d.draw_line(p.position, Vector2(p.end.x, p.position.y), Color(0.7, 0.75, 0.5), 2.0)
	d.draw_line(p.position, Vector2(p.position.x, p.end.y + FACE_H), Color(0.22, 0.19, 0.18), 3.0)
	d.draw_line(Vector2(p.end.x, p.position.y), Vector2(p.end.x, p.end.y + FACE_H), Color(0.22, 0.19, 0.18), 3.0)


func _draw_overlay() -> void:
	if not _debug:
		return
	for b in logic.buildings:
		_overlay.draw_rect(b.rect, Color(1, 0.8, 0.2, 0.9), false, 1.0)
		_overlay.draw_circle(_base_of(b), 3.0, Color(1, 0.2, 0.2))
	for t in logic.terrain_blocks:
		_overlay.draw_rect(t, Color(1, 0.3, 0.3, 0.35))
	for w in _wviews:
		_overlay.draw_circle(_wviews[w].position, 3.0, Color(0.2, 0.8, 1.0))


func _update_hud() -> void:
	var sel := "nada"
	if _selected is Logic.Worker:
		sel = "ipezinho %s" % _selected.name
	elif _selected is Logic.Building:
		sel = _selected.kind
	_hud.text = "ROTA B — top-down com relevo  (protótipo, arte provisória)\n" \
		+ "mouse no chão: (%d, %d)   •   selecionado: %s   •   Tab: pegadas e pontos de ordenação\n" % [_mouse.x, _mouse.y, sel] \
		+ ("CONSTRUINDO casa: %s  (clique esq. confirma, dir./Esc cancela)" % ("pode aqui" if _ghost_reason == "" else _ghost_reason) if _placing else "C = construir casa • clique esq. seleciona • clique dir. manda andar") \
		+ "\n%d FPS" % Engine.get_frames_per_second()


func _apply_demo_args() -> void:
	var args := OS.get_cmdline_user_args()
	if "debug" in args:
		_debug = true
	for a in args:
		if a.begins_with("mouse="):
			var xy := a.trim_prefix("mouse=").split(",")
			_force_mouse = Vector2(float(xy[0]), float(xy[1]))
	if "ghost" in args:
		_placing = true
		_ghost.visible = true
