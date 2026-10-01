extends Node2D
## Prompt 28: o ESPELHO de uma coisa em pé do World na vista isométrica (ver iso_view.gd).
##
## Copia a arte que a coisa tem HOJE (sprites, rótulos, luzes, partículas) e a mantém igual
## (quadro da animação, textura, visível, cor...), desenhada de pé no ponto isométrico do pé.
## Nada aqui mexe na coisa de verdade: ela continua andando/trabalhando no chão cartesiano.
## A CAIXA (pegada + altura) decide a ordem de desenho e o clique.
##
## No Prompt 29 a arte nova entra no lugar do espelho, presa na mesma caixa.
##
## Prédio em "L" (côncavo) = VÁRIAS caixas: a coisa declara `iso_parts()` -> [{rect, h}]
## (rect no chão relativo ao pé). Cada parte vira uma caixa na ordem e um pedaço da arte,
## recortado pela silhueta da sua caixa (clip), desenhado com o z da sua caixa.

const Iso := preload("res://scripts/iso/iso_core.gd")

## Tipos que não são desenho (física, navegação, som...): não espelha.
const SKIP := ["CollisionShape2D", "CollisionPolygon2D", "Area2D", "StaticBody2D", "CharacterBody2D",
	"RigidBody2D", "AnimatableBody2D", "NavigationRegion2D", "NavigationLink2D", "NavigationObstacle2D",
	"Camera2D", "AudioListener2D", "AudioStreamPlayer2D", "RayCast2D", "ShapeCast2D",
	"VisibleOnScreenNotifier2D", "VisibleOnScreenEnabler2D", "RemoteTransform2D", "Marker2D"]
## Propriedades que não se copiam (identidade do nó, camada da vista de cima).
const NO_COPY := ["script", "owner", "name", "unique_name_in_owner", "scene_file_path",
	"visibility_layer", "light_mask", "process_mode", "process_priority", "process_physics_priority",
	"editor_description", "physics_interpolation_mode", "auto_translate_mode"]
## O que muda durante o jogo e é copiado sempre.
const SYNC_ITEM := ["visible", "modulate", "self_modulate", "z_index", "material"]
const SYNC_NODE2D := ["position", "rotation", "scale", "skew"]
const SYNC_BY_CLASS := {
	"Sprite2D": ["texture", "frame", "flip_h", "flip_v", "offset", "region_rect", "region_enabled", "hframes", "vframes", "centered"],
	"AnimatedSprite2D": ["sprite_frames", "animation", "frame", "flip_h", "flip_v", "offset", "centered"],
	"Label": ["text", "size"],
	"Polygon2D": ["polygon", "color"],
	"Line2D": ["points", "default_color", "width"],
	"CPUParticles2D": ["emitting"],
	"GPUParticles2D": ["emitting"],
	"PointLight2D": ["enabled", "energy", "color", "texture_scale", "texture"],
	"TextureRect": ["texture"],
	"ColorRect": ["color"],
	"ProgressBar": ["value", "max_value"],
}
## Tamanho da caixa de quem anda (pegada) e o mínimo de altura.
const WALKER_FOOT := 12.0
const MIN_HEIGHT := 8.0

var src: Node2D
var dynamic := false
var box  # Iso.Box (a 1ª parte)
var boxes: Array = []  # todas as caixas (prédio em "L": 2 ou mais)
var pickable := true
var never_synced := true
## Coisa mista (zona de perigo): só os filhos em pé (z >= 0) são espelhados; a mancha da raiz
## fica na textura do chão.
var only_standing := false
## Direção de losango atual (IsoView.DIR_*) de quem anda.
var iso_dir := 0

var _view: Node
var _pairs: Array = []  # [[nó de verdade, espelho, nº de filhos quando espelhou]]
var _root_copy: Node2D = null  # quando a própria coisa é um sprite/rótulo/luz
var _last_screen := Vector2.INF
var _vel := Vector2.ZERO
var _flip := 1.0
var _top: Node2D  # desenho por cima do espelho (barra de vida)
var _tool_pair: Array = []
var _body_pair: Array = []
var _root_children := 0  # quantos filhos a coisa tinha quando espelhou
var _parts: Array = []  # [{rect, h}] relativas ao pé (vazio = uma caixa só, a de sempre)
var _part_clips: Array = []  # Polygon2D de recorte por parte (só com 2+ partes)


func setup(n: Node2D, is_dynamic: bool, view: Node) -> void:
	src = n
	dynamic = is_dynamic
	_view = view
	name = "BB_" + String(n.name)
	light_mask = 2
	if not dynamic and n.has_method("iso_parts"):
		_parts = n.iso_parts()
	var kind := "ipezinho" if dynamic else "predio"
	for k in maxi(_parts.size(), 1):
		boxes.append(Iso.Box.new(Rect2(), 0.0, 1.0, kind, "%s#%d" % [n.name, k], n))
	box = boxes[0]
	_build_mirror()
	_update_box()
	position = Iso.iso(_view.art(src.global_position), box.zb).round()


# ------------------------------------------------------------ espelho
func _build_mirror() -> void:
	for c in get_children():
		c.queue_free()
	_pairs.clear()
	_root_copy = null
	_tool_pair = []
	_body_pair = []
	_part_clips.clear()
	_root_children = src.get_child_count()
	if _parts.size() > 1:
		for k in _parts.size():  # um recorte por parte, cada um com uma cópia da arte
			var clip := Polygon2D.new()
			clip.name = "Parte%d" % k
			clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
			clip.z_as_relative = false
			add_child(clip)
			_part_clips.append(clip)
			_mirror_into(clip)
	else:
		_mirror_into(self)
	pickable = _pairs.any(func(p): return p[0] is Sprite2D or p[0] is AnimatedSprite2D)
	_top = Node2D.new()
	_top.name = "Top"
	_top.z_index = 1
	_top.draw.connect(_draw_top)
	add_child(_top)


func _mirror_into(parent: Node) -> void:
	if _is_visual_leaf(src):
		var rc := _mirror(src)
		if rc:
			_root_copy = rc
			parent.add_child(rc)
	else:
		for c in src.get_children():
			if only_standing and c is CanvasItem and (c as CanvasItem).z_index < 0:
				continue
			var m := _mirror(c)
			if m:
				parent.add_child(m)


## A coisa é ela mesma um desenho (pedra/árvore de enfeite = Sprite2D; placa = Label; luz)?
func _is_visual_leaf(n: Node) -> bool:
	return not (n is CollisionObject2D) and n.get_class() != "Node2D"


func _mirror(s: Node) -> Node:
	if not (s is CanvasItem) or s.get_class() in SKIP or s is CollisionObject2D:
		return null
	var d: Node = ClassDB.instantiate(s.get_class())
	if d == null:
		return null
	for p in s.get_property_list():
		if not (p.usage & PROPERTY_USAGE_STORAGE) or p.name in NO_COPY:
			continue
		d.set(p.name, s.get(p.name))
	(d as CanvasItem).light_mask = 2
	if d is PointLight2D:
		(d as PointLight2D).range_item_cull_mask = 2  # acende só os espelhos
	if d is AnimatedSprite2D:
		(d as AnimatedSprite2D).stop()  # o quadro vem da coisa de verdade
	_pairs.append([s, d, s.get_child_count()])
	if s.name == "Tool" and _tool_pair.is_empty():
		_tool_pair = [s, d]
	elif s.name == "Body" and _body_pair.is_empty():
		_body_pair = [s, d]
	for c in s.get_children():
		var m := _mirror(c)
		if m:
			d.add_child(m)
	return d


func _sync_props() -> void:
	for pr in _pairs:
		# (sem tipo: o nó pode ter sido apagado — ícone, ferramenta — e um Variant tipado
		# não aceita instância liberada)
		var s = pr[0]
		if not is_instance_valid(s) or not is_instance_valid(pr[1]):
			_build_mirror()
			return
		if s.get_child_count() != pr[2]:
			_build_mirror()  # entrou/saiu um filho (ícone, ferramenta, popup): espelha de novo
			return
	if not only_standing and src.get_child_count() != _root_children:
		_build_mirror()  # filho novo direto na coisa (popup "+1", poeira)
		return
	for pr in _pairs:
		var s: CanvasItem = pr[0]
		var d: CanvasItem = pr[1]
		_copy(s, d, SYNC_ITEM)
		if s is Node2D:
			_copy(s, d, SYNC_NODE2D)
		elif s is Control:
			_copy(s, d, ["position", "size", "rotation", "scale"])
		var list: Array = SYNC_BY_CLASS.get(s.get_class(), [])
		if not list.is_empty():
			_copy(s, d, list)
	for pr in _pairs:
		if pr[0] == src:
			pr[1].position = Vector2.ZERO  # o pé já é a posição do espelho
	visible = src.visible
	modulate = src.modulate * _view.level_tint(src.global_position)  # subsolo: mais escuro
	var k: float = _view.S  # a arte de hoje cresce junto com o mapa novo (escala da vista)
	if not _root_copy:
		scale = Vector2(src.scale.x * _flip * k, src.scale.y * k)
		rotation = src.rotation
	else:
		scale = Vector2(k, k)
	if _flip < 0.0:
		_unflip_labels()


func _copy(s: Object, d: Object, props: Array) -> void:
	for p in props:
		var v = s.get(p)
		if d.get(p) != v:
			d.set(p, v)


## Espelhado na horizontal (virou pro outro lado na tela): os rótulos voltam a ler direito.
func _unflip_labels() -> void:
	for pr in _pairs:
		if pr[0] is Control:
			var s: Control = pr[0]
			var d: Control = pr[1]
			d.scale.x = -s.scale.x
			d.position.x = s.position.x + s.size.x * s.scale.x


# ------------------------------------------------------------ caixa
## Retângulo (no espaço da coisa, pé = 0,0) do que está desenhado: sprites visíveis.
func _visual_rect() -> Rect2:
	var out := Rect2()
	var first := true
	var inv := src.global_transform.affine_inverse()
	for pr in _pairs:
		var s = pr[0]
		if not is_instance_valid(s) or not s.is_visible_in_tree() and s != src:
			continue
		var r := Rect2()
		if s is Sprite2D:
			r = (s as Sprite2D).get_rect()
		elif s is AnimatedSprite2D:
			var a := s as AnimatedSprite2D
			if a.sprite_frames == null or not a.sprite_frames.has_animation(a.animation):
				continue
			var tex := a.sprite_frames.get_frame_texture(a.animation, a.frame)
			if tex == null:
				continue
			var sz := tex.get_size()
			r = Rect2(a.offset - (sz * 0.5 if a.centered else Vector2.ZERO), sz)
		else:
			continue
		var xf: Transform2D = inv * (s as Node2D).global_transform
		var rr := xf * r
		out = rr if first else out.merge(rr)
		first = false
	return out


## Recalcula a caixa. true = mudou (a ordem precisa re-encaixar).
func _update_box() -> bool:
	var feet := src.global_position
	var vr := _visual_rect()
	var rect: Rect2
	var k: float = _view.S
	var top := maxf(MIN_HEIGHT, -vr.position.y)
	if dynamic:
		rect = Rect2(feet - Vector2.ONE * WALKER_FOOT * 0.5, Vector2.ONE * WALKER_FOOT)
		top = maxf(16.0, top)
	else:
		rect = _footprint(feet, vr)
	rect = _view.art_rect(rect)  # caixa em px de arte (escala da vista; andar de baixo na laje dele)
	top *= k
	var zb: float = _view.height_at(feet) if _view.has_method("height_at") else 0.0
	if _parts.size() > 1:
		return _update_parts(feet, zb)
	var changed: bool = rect != box.rect or absf(box.zt - (zb + top)) > 1.0 or box.zb != zb
	box.rect = rect
	box.zb = zb
	box.zt = zb + top
	return changed


## Prédio em "L": cada parte tem a sua caixa (declarada) e o seu recorte da arte.
func _update_parts(feet: Vector2, zb: float) -> bool:
	var changed := false
	var sk: float = _view.S
	var origin := Iso.iso(_view.art(feet), zb)
	for k in _parts.size():
		var b = boxes[k]
		var r: Rect2 = _parts[k].rect
		r.position += feet
		r = _view.art_rect(r)
		var zt: float = zb + float(_parts[k].h) * sk
		if r != b.rect or b.zb != zb or absf(b.zt - zt) > 0.01:
			changed = true
		b.rect = r
		b.zb = zb
		b.zt = zt
		# recorte da arte: a silhueta da caixa desta parte
		var poly := PackedVector2Array()
		for q in Iso.silhouette(b):
			poly.append(q - origin)
		if k < _part_clips.size():
			_part_clips[k].polygon = poly
	return changed


## z de cada parte (prédio em "L"): vem da ordem de cada caixa.
func set_part_z(zs: Array) -> void:
	for k in mini(zs.size(), _part_clips.size()):
		_part_clips[k].z_index = zs[k]


## Pegada no chão: a da navegação (o que bloqueia de verdade) quando a coisa tem; senão uma
## pegada pequena centrada no pé, proporcional à largura da arte (pedra, árvore, tocha).
func _footprint(feet: Vector2, vr: Rect2) -> Rect2:
	if src.has_method("get_obstacle_outline"):
		var o: PackedVector2Array = src.get_obstacle_outline()
		if o.size() >= 3:
			var r := Rect2(o[0], Vector2.ZERO)
			for q in o:
				r = r.expand(q)
			return r
	var w := clampf(vr.size.x * 0.5, 6.0, 120.0)
	return Rect2(feet - Vector2(w * 0.5, w * 0.25), Vector2(w, w * 0.5))


func visible_src() -> bool:
	return is_instance_valid(src) and src.visible


# ------------------------------------------------------------ a cada quadro
## Coisa parada: só confere se está na tela. true = a caixa mudou.
func sync_static(view_rect: Rect2) -> bool:
	if not never_synced and not view_rect.intersects(Iso.screen_rect(box)):
		return false
	never_synced = false
	_sync_props()
	if src.is_in_group("canteiros") or src.is_in_group("parques"):
		_top.queue_redraw()
		queue_redraw()
	var changed := _update_box()
	position = Iso.iso(_view.art(src.global_position), box.zb).round()
	return changed


func sync_dynamic() -> void:
	_update_box()
	var scr := Iso.iso(_view.art(src.global_position), box.zb)
	if _last_screen != Vector2.INF:
		_vel = _vel.lerp(scr - _last_screen, 0.35)
	_last_screen = scr
	var moving: bool = src is CharacterBody2D and (src as CharacterBody2D).velocity.length() > 5.0
	if moving:
		iso_dir = _view.diamond_dir(_vel, iso_dir)
	src.set_meta("iso_dir", iso_dir)
	# a arte de hoje só vira pros lados (_facing = sinal do x no chão); na tela, o lado é
	# o da direção de losango: espelha o desenho inteiro quando os dois discordam
	var src_f := 1.0
	var f = src.get("_facing")
	if f != null:
		src_f = signf(f) if f != 0.0 else 1.0
		var want := 1.0 if _view.faces_right(iso_dir) else -1.0
		_flip = want * src_f
	position = scr.round()
	_sync_props()
	_tool_rule(moving)
	_top.queue_redraw()
	queue_redraw()


## Picareta/ferramenta nas costas: de frente pra câmera (SE/SW) fica ATRÁS do corpo; de
## costas (NE/NW), na FRENTE. No golpe a arte da animação manda (Prompt 29).
func _tool_rule(moving: bool) -> void:
	if _tool_pair.is_empty() or _body_pair.is_empty():
		return
	for n in _tool_pair + _body_pair:
		if not is_instance_valid(n):
			return
	var d_tool: CanvasItem = _tool_pair[1]
	var d_body: CanvasItem = _body_pair[1]
	if moving and _view.faces_camera(iso_dir):
		d_tool.z_index = d_body.z_index - 1
	else:
		d_tool.z_index = (_tool_pair[0] as CanvasItem).z_index


# ------------------------------------------------------------ o que a coisa desenha à mão
## O que as coisas desenham à mão (o _draw delas não vem no espelho): sombra e anel de
## seleção do ipezinho; o raio do parque (círculo no chão = elipse 2:1 na tela).
func _draw() -> void:
	if not is_instance_valid(src):
		return
	if src.is_in_group("ipezinhos"):
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		if not src.get("_inside"):
			draw_circle(Vector2(1.5, 0.5), 12.0, Color(0.02, 0.02, 0.05, 0.5))
		if src.get("selected"):
			draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 32, Color(1.0, 0.84, 0.25), 2.5)
	elif src.is_in_group("parques") and src.has_method("radius"):
		var r: float = src.radius() * 1.4142
		draw_set_transform(Iso.iso(Vector2(0, -10)), 0.0, Vector2(1.0, 0.5))
		var n := 48
		for i in n:
			if i % 2 == 0:
				draw_arc(Vector2.ZERO, r, TAU * i / n, TAU * (i + 1) / n, 3, Color(0.6, 1.0, 0.55, 0.13), 1.5)


## Por cima da arte: barra de vida das criaturas e barrinha de progresso da obra (canteiro).
func _draw_top() -> void:
	if not is_instance_valid(src):
		return
	if src.is_in_group("canteiros") and src.has_method("obra_progress") and src.has_method("_top"):
		var y: float = -(src._top() + 8.0)
		var eng: bool = src._obra.has_engineer() if src.get("_obra") else false
		_top.draw_rect(Rect2(-26, y, 52, 5), Color(0.05, 0.04, 0.03, 0.85))
		_top.draw_rect(Rect2(-25, y + 1, 50 * src.obra_progress(), 3), Color(1.0, 0.6, 0.25) if eng else Color(0.7, 0.5, 0.3))
		return
	if not src.is_in_group("criaturas"):
		return
	var hp = src.get("hp")
	var max_hp = src.get("max_hp")
	if hp == null or max_hp == null or src.get("_dying") or hp >= max_hp:
		return
	var w := 22.0
	_top.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_flip, 1.0))
	_top.draw_rect(Rect2(-w * 0.5, -32, w, 3), Color(0, 0, 0, 0.7))
	_top.draw_rect(Rect2(-w * 0.5, -32, w * clampf(hp / max_hp, 0.0, 1.0), 3), Color(0.9, 0.3, 0.25))
