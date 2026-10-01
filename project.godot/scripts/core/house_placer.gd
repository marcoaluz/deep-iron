extends Node2D
## Modo de posicionamento de casa (grupo "house_placer"), criado pelo main.gd.
## Também usado pra taverna: begin() aceita outra textura e outro nome.
##
## begin(on_confirm) liga o modo: um fantasma da casa segue o mouse, verde onde
## pode construir e vermelho onde não pode (com o motivo escrito no topo da tela).
##   clique esquerdo num lugar válido -> chama on_confirm(posição); se ele devolver
##                                       true, o modo termina
##   Esc ou botão direito              -> cancela (nada é gasto)
## A roda do mouse e WASD continuam movendo a câmera enquanto isso.
##
## Lugar válido: a "pegada" da casa (base + degrau da porta, onde ficam as camas)
## tem que caber na área andável do mapa e não pode encostar em nenhuma estrutura
## (e na área de trabalho dela), jazida, horta, casa ou decoração que bloqueia.
##
## Bloco 37: begin() aceita `opts` —
##   footprint: Rect2   pegada de outro prédio (Centro da Vila, Armazém, Comedouro)
##   ignore: Array      nós que não contam como obstáculo (o próprio prédio sendo mudado)
##   cancelable: bool   false = Esc/direito não cancelam (fundação da vila)
##   radius / radius_center   só vale até essa distância do centro (casas em volta do
##                      Centro da Vila); o contorno do raio aparece enquanto escolhe
##   start: Vector2     onde o fantasma aparece
##   area: Rect2        onde pode (em vez da área da mina) — Bloco 45: coletor na clareira
##   area_name: String  como chamar essa área no aviso ("fora da clareira")

signal finished(confirmed: bool)

const CASA_TEXTURE := preload("res://assets/game/casa.png")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
## Pegada da casa em volta do ponto clicado (o ponto é o pé da casa): do telhado
## (-54) até o degrau da porta, onde ficam as camas (+24).
const FOOTPRINT := Rect2(-32, -54, 64, 78)
const COLOR_OK := Color(0.45, 1.0, 0.5)
const COLOR_BAD := Color(1.0, 0.35, 0.3)

var active := false
var _on_confirm: Callable
var _pos := Vector2.ZERO
var _reason := ""
var _blockers: Array = []  # [{rect: Rect2, name: String}]
var _ghost: Sprite2D
var _hint_layer: CanvasLayer
var _hint: Label
var _what := "a casa nova"
var _footprint := FOOTPRINT
var _ignore: Array = []
var _cancelable := true
var _radius := 0.0
var _radius_center := Vector2.ZERO
var _area := Rect2()
var _area_name := ""
## Prompt 29: o prédio da arte nova sendo posicionado ("" = sem arte nova): a pegada é a do desenho
var art_name := ""


func _ready() -> void:
	add_to_group("house_placer")
	z_index = 60
	_ghost = Sprite2D.new()
	_ghost.texture = CASA_TEXTURE
	_ghost.hframes = 3
	_ghost.scale = Vector2(2, 2)
	_ghost.offset = Vector2(0, -13)
	add_child(_ghost)
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 5
	add_child(_hint_layer)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.offset_top = 16.0
	# centraliza no espaço à direita do painel do HUD (que ocupa a esquerda da tela)
	_hint.offset_left = 220.0
	_hint.offset_right = 220.0
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint_layer.add_child(_hint)
	_set_visible(false)


## Liga o modo. on_confirm(pos: Vector2) -> bool constrói de fato (e paga).
## texture/hframes/what trocam o fantasma e o texto (padrão: casa).
func begin(on_confirm: Callable, texture: Texture2D = CASA_TEXTURE, hframes: int = 3, what: String = "a casa nova", opts: Dictionary = {}) -> void:
	_on_confirm = on_confirm
	_ghost.texture = texture
	_ghost.hframes = hframes
	_ghost.frame = 0
	# o pé do prédio fica no ponto clicado (desenhos de alturas diferentes)
	_ghost.offset = Vector2(0, -texture.get_height() * 0.5)
	_what = what
	_footprint = opts.get("footprint", FOOTPRINT)
	art_name = IsoArt.name_for_texture(texture)
	var af := IsoArt.placer_footprint(get_tree(), art_name)
	if af.has_area():
		_footprint = af  # o prédio novo tem fundo de verdade (a pegada antiga era o desenho de frente)
	_ignore = opts.get("ignore", [])
	_cancelable = opts.get("cancelable", true)
	_radius = opts.get("radius", 0.0)
	_radius_center = opts.get("radius_center", Vector2.ZERO)
	_area = opts.get("area", Rect2())
	_area_name = opts.get("area_name", "da área")
	active = true
	_collect_blockers()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("close_panels"):
		hud.close_panels()
	_pos = opts.get("start", _to_world(get_viewport().get_mouse_position()))
	_refresh()
	_set_visible(true)


func cancel() -> void:
	if not active or not _cancelable:
		return
	_end(false)
	Audio.click()


func _end(confirmed: bool) -> void:
	active = false
	_set_visible(false)
	_footprint = FOOTPRINT
	_ignore = []
	_cancelable = true
	_radius = 0.0
	_area = Rect2()
	finished.emit(confirmed)


func _set_visible(on: bool) -> void:
	visible = on
	_hint_layer.visible = on


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		_pos = _to_world(event.position)
		_refresh()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pos = _to_world(event.position)
			_refresh()
			get_viewport().set_input_as_handled()
			try_confirm()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			cancel()
	elif event is InputEventMouseButton and not event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		get_viewport().set_input_as_handled()  # o main não pode tratar a soltura como clique
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancel()


## Tenta construir na posição atual do fantasma.
func try_confirm() -> bool:
	if not active:
		return false
	if _reason != "":
		Audio.error()
		var flash := create_tween()
		_ghost.scale = Vector2(2.15, 2.15)
		flash.tween_property(_ghost, "scale", Vector2(2, 2), 0.15)
		return false
	if _on_confirm.is_valid() and _on_confirm.call(_pos):
		_end(true)
		return true
	return false


## Move o fantasma pra uma posição do mundo (usado pelos testes e pelo mouse).
func move_to(world_pos: Vector2) -> void:
	_pos = world_pos
	_refresh()


## "" se dá pra construir aqui; senão o motivo.
func check_spot(pos: Vector2) -> String:
	var fp := Rect2(pos + _footprint.position, _footprint.size)
	var env := get_tree().get_first_node_in_group("environment")
	if _area.has_area():
		if not _area.encloses(fp):
			return "fora %s" % _area_name
	elif env and not env.walkable_rect().encloses(fp):
		return "fora da área da mina"
	if env and env.has_method("footprint_reason"):
		var why: String = env.footprint_reason(fp)  # Prompt 29: terraços (chão plano)
		if why != "":
			return why
	if _radius > 0.0 and pos.distance_to(_radius_center) > _radius:
		return "longe demais do Centro da Vila (a vila cresce e o raio aumenta)"
	for b in _blockers:
		if fp.intersects(b.rect):
			return "em cima de %s" % b.name
	return ""


func _refresh() -> void:
	_pos = _pos.round()
	_reason = check_spot(_pos)
	_ghost.position = _pos
	_ghost.modulate = Color(COLOR_OK, 0.6) if _reason == "" else Color(COLOR_BAD, 0.6)
	var cancel_txt := "  •  Esc ou botão direito cancela" if _cancelable else ""
	if _reason == "":
		_hint.text = "Onde fica %s?  Clique pra construir%s" % [_what, cancel_txt]
		_hint.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	else:
		_hint.text = "Não dá pra construir aqui: %s%s" % [_reason, ("\n" + cancel_txt.trim_prefix("  •  ")) if _cancelable else ""]
		_hint.add_theme_color_override("font_color", COLOR_BAD)
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	if _radius > 0.0:
		# Bloco 37: onde pode construir casa (em volta do Centro da Vila), tracejado
		draw_circle(_radius_center, _radius, Color(1.0, 0.9, 0.55, 0.06))
		var n := 72
		for i in n:
			if i % 2 == 0:
				draw_arc(_radius_center, _radius, TAU * i / n, TAU * (i + 1) / n, 4, Color(1.0, 0.88, 0.5, 0.85), 2.0)
	var fp := Rect2(_pos + _footprint.position, _footprint.size)
	var c := COLOR_OK if _reason == "" else COLOR_BAD
	draw_rect(fp, Color(c, 0.12), true)
	draw_rect(fp, Color(c, 0.9), false, 1.5)


## Áreas proibidas: base + área de trabalho de cada estrutura e as pedras/cristais/tochas.
## (Calculado ao entrar no modo: nada se move enquanto você escolhe.)
func _collect_blockers() -> void:
	_blockers.clear()
	var env := get_tree().get_first_node_in_group("environment")
	var groups: Array = env.STATION_GROUPS + env.NAV_EXTRA_GROUPS if env else ["casas"]
	for group in groups:
		for node in get_tree().get_nodes_in_group(group):
			if _ignore.has(node):
				continue
			var r := Rect2(node.global_position, Vector2.ZERO)
			var art := IsoArt.blocker_rect(node)
			if art.has_area():
				# Prompt 29: a pegada do desenho novo + a faixa dos slots em volta (a porta/o acesso)
				r = art
				if int(node.get("slot_count") if node.get("slot_count") != null else 0) > 0:
					r = art.grow(IsoArt.FRONT_GAP + 2.0)
				_blockers.append({"rect": r.grow(6.0), "name": _display_name(node)})
				continue
			if node.has_method("get_obstacle_outline"):
				var outline: PackedVector2Array = node.get_obstacle_outline()
				if outline.size() >= 3:
					r = _bbox(outline)
			# área de trabalho (slots) em volta: não pode tapar a porta/o acesso
			var slots: int = node.get("slot_count") if node.get("slot_count") != null else 0
			if slots > 0:
				var sr: Vector2 = node.slot_radius
				r = r.merge(Rect2(node.global_position - sr, sr * 2.0))
			# o desenho inteiro também conta (telhado, torre...): uma construção não invade a outra
			var visual := node.get_node_or_null("Visual") as Sprite2D
			if visual and visual.texture:
				r = r.merge(visual.get_global_transform() * visual.get_rect())
			# prédios grandes: a área livre em volta deles também
			if node.has_method("get_clear_center"):
				var cc: Vector2 = node.get_clear_center()
				var cr: float = node.get_clear_radius() * 0.8
				r = r.merge(Rect2(cc - Vector2(cr, cr), Vector2(cr, cr) * 2.0))
			_blockers.append({"rect": r.grow(6.0), "name": _display_name(node)})
	if env:
		for o in env.decoration_obstacles():
			_blockers.append({"rect": _bbox(o).grow(4.0), "name": "uma pedra/decoração"})


func _display_name(node: Node) -> String:
	if node.is_in_group("casas"):
		return "outra casa"
	if node.is_in_group("minerios"):
		return "uma jazida"
	return String(node.name)


func _bbox(points: PackedVector2Array) -> Rect2:
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r


func _to_world(screen_pos: Vector2) -> Vector2:
	var canvas := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and iso.enabled:
		return iso.ground_at(canvas)  # Prompt 28: o chão embaixo do mouse na vista iso
	return canvas
