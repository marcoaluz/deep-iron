extends Node2D
## Prompt 28: a VISTA ISOMÉTRICA do jogo (F3 liga/desliga). A lógica não muda: o nó World
## continua no chão cartesiano (navegação, física, saves). Esta vista só DESENHA o mundo de
## outro jeito:
##
##   - CHÃO (piso, paredes, pedrinhas, manchas de perigo, canteiros e o que o Main desenha no
##     chão): renderizado como sempre numa textura (SubViewport que enxerga o mesmo mundo) e
##     essa textura é desenhada ACHATADA em losango (Iso.PROJ). Genérico: nada por cena.
##   - O QUE FICA EM PÉ (prédios, ipezinhos, árvores, pedras, tochas...): um ESPELHO de cada
##     um ("billboard") na posição isométrica do pé, com a arte atual (até o Prompt 29 trocar
##     pela arte nova). Cada um tem uma CAIXA (pegada no chão + altura) que decide a ordem de
##     desenho (iso_order.gd) e o clique (raio da câmera, Iso.pick).
##
## Camadas de visibilidade (CanvasItem.visibility_layer / Viewport.canvas_cull_mask):
##   bit 2 (LAYER_WORLD)    = o World e o que o Main desenha no chão: a tela em iso NÃO mostra
##                            (mostra a textura achatada); a textura do chão mostra.
##   bit 3 (LAYER_STANDING) = raiz das coisas em pé: fora da textura do chão.
##   bit 4 (LAYER_ISO)      = esta vista: fora da textura do chão.
## Na vista de cima (iso desligado) a tela mostra tudo, como sempre.

const Iso := preload("res://scripts/iso/iso_core.gd")
const Order := preload("res://scripts/iso/iso_order.gd")
const Billboard := preload("res://scripts/iso/iso_billboard.gd")

const LAYER_DEFAULT := 1
const LAYER_WORLD := 2
const LAYER_STANDING := 4
const LAYER_ISO := 8
## light_mask dos espelhos: as luzes de verdade (no chão cartesiano) não acendem eles; as
## luzes espelhadas acendem só eles.
const LIGHT_ISO := 2
## Folga em volta do mundo na textura do chão (a parede de rocha continua além do mapa).
const GROUND_MARGIN := 400.0
## Fundo da tela fora do losango do chão (a rocha escura da vista de cima).
const VOID_COLOR := Color(0.086, 0.078, 0.075)
## Maior lado da textura do chão (px). O mapa de hoje cabe (≈ 1500 × 2950).
const GROUND_MAX := 4096
## Coisas em pé que não mudam muito: confere caixa/arte a cada N quadros.
const STATIC_SYNC_EVERY := 6
## Histerese da direção de losango (graus além dos 45° da fatia).
const DIR_HYSTERESIS := 15.0

## Direções de losango (bordas do chão = diagonais da tela).
enum { DIR_SE, DIR_SW, DIR_NW, DIR_NE }

var enabled := false
## F4: mostra as caixas (contorno) por cima de tudo.
var show_boxes := false

var _main: Node2D
var _world: Node2D
var _env: Node2D
var _camera: Camera2D
var _ground_sv: SubViewport
var _ground_layer: CanvasLayer
var _ground_sprite: Sprite2D
var _ground_rect: Rect2
var _things: Node2D
var _overlay: Node2D
var _order := Order.new()
## src (Node2D do World) -> Billboard
var _ents := {}
var _frame := 0
var _saved_layers := {}  # filhos do Main que mudam de camada no modo iso -> camada antiga
## Posicionador (fantasma do prédio): a pegada e o raio caem achatados no chão (textura do
## chão); o desenho do prédio fica EM PÉ aqui, no ponto isométrico do mouse.
var _placer: Node2D
var _ghost_bb: Sprite2D


func setup(main: Node2D) -> void:
	_main = main
	_world = main.get_node("World")
	_env = _world.get_node("Environment")
	_camera = main.get_node("Camera2D")
	name = "IsoView"
	add_to_group("iso_view")
	visibility_layer = LAYER_ISO
	_world.visibility_layer = LAYER_WORLD
	_things = Node2D.new()
	_things.name = "Things"
	add_child(_things)
	_overlay = Node2D.new()
	_overlay.name = "Overlay"
	_overlay.z_index = 4090
	_overlay.z_as_relative = false
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	visible = false
	set_process(false)


# ------------------------------------------------------------ liga / desliga
func toggle() -> void:
	set_enabled(not enabled)


func set_enabled(on: bool) -> void:
	if on == enabled:
		return
	var ground_center: Vector2 = _camera.ground_center() if _camera.has_method("ground_center") else _camera.get_screen_center_position()
	enabled = on
	var vp := get_viewport()
	if on:
		_build_ground()
		RenderingServer.set_default_clear_color(VOID_COLOR)
		_hide_main_children(true)
		vp.canvas_cull_mask = vp.canvas_cull_mask & ~LAYER_WORLD
		_scan_world()
		_rebuild_order()
		_setup_ghost(true)
		_world.child_entered_tree.connect(_on_world_child_added)
		_world.child_exiting_tree.connect(_on_world_child_removed)
		_env.child_entered_tree.connect(_on_world_child_added)
		_env.child_exiting_tree.connect(_on_world_child_removed)
	else:
		_setup_ghost(false)
		vp.canvas_cull_mask = vp.canvas_cull_mask | LAYER_WORLD
		RenderingServer.set_default_clear_color(ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3)))
		_hide_main_children(false)
		_world.child_entered_tree.disconnect(_on_world_child_added)
		_world.child_exiting_tree.disconnect(_on_world_child_removed)
		_env.child_entered_tree.disconnect(_on_world_child_added)
		_env.child_exiting_tree.disconnect(_on_world_child_removed)
		for src in _ents.keys():
			_drop(src)
		_ground_sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_ground_layer.visible = false
	visible = on
	set_process(on)
	if "iso_view" in _camera:
		_camera.iso_view = self if on else null
	if _camera.has_method("on_view_changed"):
		_camera.on_view_changed(ground_center)


## Filhos do Main que desenham no chão cartesiano (clima, fantasma da casa...): no modo iso
## somem da tela e entram na textura do chão (ficam achatados no lugar certo).
func _hide_main_children(on: bool) -> void:
	for c in _main.get_children():
		if not (c is CanvasItem) or c == self or c == _world or c is CanvasModulate:
			continue
		if c.visibility_layer == LAYER_ISO:
			continue  # já é da vista iso (retângulo de seleção)
		if on:
			_saved_layers[c] = c.visibility_layer
			c.visibility_layer = LAYER_WORLD
		elif _saved_layers.has(c) and is_instance_valid(c):
			c.visibility_layer = _saved_layers[c]
	if not on:
		_saved_layers.clear()


# ------------------------------------------------------------ chão (textura achatada)
func _build_ground() -> void:
	var wr: Rect2 = _env.world_rect().grow(GROUND_MARGIN)
	var size := Vector2i(mini(ceili(wr.size.x), GROUND_MAX), mini(ceili(wr.size.y), GROUND_MAX))
	_ground_rect = Rect2(wr.position, Vector2(size))
	if _ground_sv == null:
		_ground_sv = SubViewport.new()
		_ground_sv.name = "GroundView"
		_ground_sv.transparent_bg = true
		_ground_sv.disable_3d = true
		_ground_sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		add_child(_ground_sv)
		_ground_sv.world_2d = get_viewport().world_2d
		# só o chão: o World (bit 2) e os filhos de sempre (bit 1); fora o que fica em pé e esta vista
		_ground_sv.canvas_cull_mask = LAYER_DEFAULT | LAYER_WORLD
		_ground_layer = CanvasLayer.new()
		_ground_layer.name = "GroundLayer"
		_ground_layer.layer = -1  # embaixo do mundo
		_ground_layer.follow_viewport_enabled = true
		add_child(_ground_layer)
		_ground_sprite = Sprite2D.new()
		_ground_sprite.centered = false
		_ground_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_ground_sprite.light_mask = 0  # a luz já está na textura
		_ground_layer.add_child(_ground_sprite)
	_ground_sv.size = size
	_ground_sv.canvas_transform = Transform2D(0.0, -_ground_rect.position)
	_ground_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_ground_sprite.texture = _ground_sv.get_texture()
	_ground_sprite.transform = Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Iso.iso(_ground_rect.position))
	_ground_layer.visible = true


# ------------------------------------------------------------ quem é chão, quem fica em pé
## Chão de verdade: vai inteiro pra textura achatada (piso, paredes, pedrinhas: z <= -5).
func _is_ground(n: Node) -> bool:
	return n is CanvasItem and (n as CanvasItem).z_index <= -5 and not _is_mixed(n)


## Misto: a raiz é uma mancha no chão, mas tem coisa em pé por cima (texto, fumaça). A mancha
## fica na textura do chão; os filhos com z >= 0 ganham um espelho em pé.
func _is_mixed(n: Node) -> bool:
	return n.is_in_group("zonas_perigo")


func _is_dynamic(n: Node) -> bool:
	return n is CharacterBody2D or n.is_in_group("ipezinhos") or n.is_in_group("criaturas")


func _wants(n: Node) -> bool:
	if not (n is Node2D) or n == _env or n is NavigationRegion2D:
		return false
	return not _is_ground(n)  # (os mistos também entram: só com a parte em pé)


func _scan_world() -> void:
	for n in _world.get_children():
		_add(n)
	for n in _env.get_children():
		_add(n)


func _on_world_child_added(n: Node) -> void:
	# entra no próximo quadro: o _ready dela (grupos, arte) ainda não rodou
	_add.call_deferred(n)


func _on_world_child_removed(n: Node) -> void:
	if _ents.has(n):
		_drop(n)


func _add(n: Node) -> void:
	if not enabled or not is_instance_valid(n) or not n.is_inside_tree() or _ents.has(n) or not _wants(n):
		return
	var mixed := _is_mixed(n)
	if mixed:
		for c in n.get_children():  # a parte em pé sai da textura do chão
			if c is CanvasItem and (c as CanvasItem).z_index >= 0:
				(c as CanvasItem).visibility_layer = LAYER_STANDING
	else:
		(n as CanvasItem).visibility_layer = LAYER_STANDING
	var bb := Billboard.new()
	bb.only_standing = mixed
	bb.setup(n, _is_dynamic(n), self)
	_things.add_child(bb)
	_ents[n] = bb
	if not bb.dynamic and not _order.order.is_empty():
		for b in bb.boxes:
			_order.add_static(b)  # construiu agora: encaixa só ela


func _drop(src: Node) -> void:
	var bb: Billboard = _ents.get(src)
	_ents.erase(src)
	if bb == null:
		return
	if not bb.dynamic:
		for b in bb.boxes:
			_order.remove_static(b)
	if is_instance_valid(src):
		(src as CanvasItem).visibility_layer = LAYER_DEFAULT
		if bb.only_standing:
			for c in src.get_children():
				if c is CanvasItem:
					(c as CanvasItem).visibility_layer = LAYER_DEFAULT
	bb.queue_free()


func _rebuild_order() -> void:
	var statics := []
	for bb in _ents.values():
		if not bb.dynamic:
			statics.append_array(bb.boxes)
	_order.build(statics)
	_apply_static_z()


func _apply_static_z() -> void:
	for bb in _ents.values():
		if bb.dynamic:
			continue
		bb.z_index = _order.z_of_static(bb.box)
		if bb.boxes.size() > 1:
			bb.set_part_z(bb.boxes.map(func(b): return _order.z_of_static(b)))


# ------------------------------------------------------------ a cada quadro
func _process(_delta: float) -> void:
	_frame += 1
	var view := _screen_view().grow(256.0)
	var moved_static := false
	var dyn_boxes := []
	var dyn_bbs := {}
	for src in _ents.keys():
		var bb: Billboard = _ents[src]
		if not is_instance_valid(src):
			_drop(src)
			continue
		if bb.dynamic:
			bb.sync_dynamic()
			dyn_boxes.append(bb.box)
			dyn_bbs[bb.box] = bb
		elif (_frame + bb.get_instance_id()) % STATIC_SYNC_EVERY == 0 or bb.never_synced:
			if bb.sync_static(view):
				for b in bb.boxes:
					_order.add_static(b)  # mudou de lugar/tamanho: re-encaixa só ela
				moved_static = true
	if moved_static:
		_apply_static_z()
	else:
		_refresh_static_z_if_needed()
	var zs := _order.dynamic_z(dyn_boxes)
	for b in zs:
		dyn_bbs[b].z_index = zs[b]
	_sync_ghost()
	_overlay.queue_redraw()


# ------------------------------------------------------------ fantasma do posicionador
func _setup_ghost(on: bool) -> void:
	_placer = get_tree().get_first_node_in_group("house_placer")
	if _placer == null:
		return
	var g: Sprite2D = _placer.get("_ghost")
	if g:
		# fora da textura do chão (lá ele ficaria deitado); na vista de cima continua igual
		g.visibility_layer = LAYER_STANDING if on else LAYER_DEFAULT
	if on and _ghost_bb == null:
		_ghost_bb = Sprite2D.new()
		_ghost_bb.name = "Fantasma"
		_overlay.add_child(_ghost_bb)
	if _ghost_bb:
		_ghost_bb.visible = false


func _sync_ghost() -> void:
	if _placer == null or _ghost_bb == null:
		return
	var g: Sprite2D = _placer.get("_ghost")
	var on: bool = _placer.active and _placer.visible and g != null
	_ghost_bb.visible = on
	if not on:
		return
	_ghost_bb.texture = g.texture
	_ghost_bb.hframes = g.hframes
	_ghost_bb.vframes = g.vframes
	_ghost_bb.frame = g.frame
	_ghost_bb.offset = g.offset
	_ghost_bb.scale = g.scale
	_ghost_bb.modulate = g.modulate
	_ghost_bb.position = Iso.iso(_placer._pos, height_at(_placer._pos)).round()


## Construir/demolir muda os ranks de quem vem depois: os z de todas as fixas se ajustam
## (barato: só atribuir um número).
var _last_order_size := -1
func _refresh_static_z_if_needed() -> void:
	if _order.order.size() == _last_order_size:
		return
	_last_order_size = _order.order.size()
	_apply_static_z()


## A parte do canvas (coordenadas iso) que a tela mostra.
func _screen_view() -> Rect2:
	var vp := get_viewport()
	return vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()


## A parte do CHÃO que a tela mostra (retângulo que contém os 4 cantos da tela no chão).
func ground_view_rect() -> Rect2:
	var v := _screen_view()
	var r := Rect2(Iso.iso_inv(v.position), Vector2.ZERO)
	for c in [Vector2(v.end.x, v.position.y), v.end, Vector2(v.position.x, v.end.y)]:
		r = r.expand(Iso.iso_inv(c))
	return r


# ------------------------------------------------------------ chão <-> tela
## Chão -> canvas iso (pé no nível do relevo; hoje o mapa é plano).
func to_screen(ground: Vector2, z: float = 0.0) -> Vector2:
	return Iso.iso(ground, z)


## Canvas iso -> chão, no plano z = 0 (sem olhar o que está em cima).
func to_ground_plane(canvas_pos: Vector2) -> Vector2:
	return Iso.iso_inv(canvas_pos, 0.0)


## O RAIO DA CÂMERA no ponto do canvas: {what, node, ground, z, face}. node = a coisa em pé
## acertada (ipezinho, prédio, jazida...) ou null (chão). Clique em FACE (parede/lado de um
## prédio): ground = o pé da parede, e face = true (construir ali não pode).
func pick(canvas_pos: Vector2) -> Dictionary:
	var solids := []
	for bb in _ents.values():
		if bb.visible_src() and bb.pickable:
			solids.append_array(bb.boxes)
	var planes := [{"rect": _env.world_rect(), "z": 0.0, "name": "chão"}]
	var hit := Iso.pick(canvas_pos, solids, planes)
	var out := {"what": hit.what, "node": null, "z": hit.get("z", 0.0), "face": hit.what == "face",
		"ground": hit.get("ground", Iso.iso_inv(canvas_pos, 0.0))}
	if hit.has("box"):
		out.node = hit.box.owner
	return out


## Pra ordens de andar: o ponto do chão de um clique (pé da parede se caiu numa face; o pé
## da coisa se caiu em cima dela).
func ground_at(canvas_pos: Vector2) -> Vector2:
	var p := pick(canvas_pos)
	if p.node != null and p.what == "topo":
		return (p.node as Node2D).global_position
	return p.ground


## Relevo como MAPA DE ALTURA (uma altura por ponto do chão; sem ponte nem túnel por cima de
## caminho). Hoje o mapa é plano: o ambiente responde 0 em todo lugar. O mapa novo (Prompt 29)
## traz os terraços.
func height_at(ground: Vector2) -> float:
	return _env.height_at(ground) if _env.has_method("height_at") else 0.0


func billboard_of(src: Node) -> Node2D:
	return _ents.get(src)


func static_boxes() -> Array:
	return _order.order


func order_stats() -> Dictionary:
	return {"statics": _order.order.size(), "full_rebuilds": _order.full_rebuilds}


# ------------------------------------------------------------ direção de losango
## Direção de losango pra uma velocidade na TELA, com histerese (não pisca na fronteira).
static func diamond_dir(v_screen: Vector2, prev: int) -> int:
	if v_screen.length_squared() < 0.01:
		return prev
	var ang := rad_to_deg(v_screen.angle())  # 0 = direita, 90 = baixo (y da tela pra baixo)
	if prev >= 0:
		var center := 45.0 + 90.0 * float(prev)  # SE 45°, SW 135°, NW 225°, NE 315°
		var diff := absf(wrapf(ang - center, -180.0, 180.0))
		if diff <= 45.0 + DIR_HYSTERESIS:
			return prev
	var slot := int(floor(wrapf(ang, 0.0, 360.0) / 90.0))  # 0: 0..90 (SE) 1: 90..180 (SW) ...
	return [DIR_SE, DIR_SW, DIR_NW, DIR_NE][slot]


## Olhando pra câmera (SE/SW)? De costas (NE/NW): a ferramenta nas costas vai pra FRENTE.
static func faces_camera(d: int) -> bool:
	return d == DIR_SE or d == DIR_SW


static func faces_right(d: int) -> bool:
	return d == DIR_SE or d == DIR_NE


# ------------------------------------------------------------ por cima de tudo
func _draw_overlay() -> void:
	# marcador da ordem (o anel do Main, achatado no chão)
	if _main.get("_marker_timer") != null and _main._marker_timer > 0.0:
		var t: float = _main._marker_timer / _main.MARKER_TIME
		var c := Iso.iso(_main._marker_pos)
		_overlay.draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
		_overlay.draw_arc(Vector2.ZERO, lerpf(18.0, 6.0, t) * 1.41, 0.0, TAU, 24, Color(1.0, 0.84, 0.25, t), 2.0)
		_overlay.draw_set_transform(Vector2.ZERO)
	if not show_boxes:
		return
	var w := 1.0 / maxf(_camera.zoom.x, 0.1)
	for bb in _ents.values():
		if not bb.visible_src():
			continue
		for b in bb.boxes:
			var sil := Iso.silhouette(b)
			if sil.size() < 3:
				continue
			var col := Color(0.3, 1.0, 0.5, 0.8) if bb.dynamic else Color(1.0, 0.85, 0.2, 0.55)
			var closed := sil.duplicate()
			closed.append(sil[0])
			_overlay.draw_polyline(closed, col, w)
