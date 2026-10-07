extends Node2D
## Prompt 28: o ESPELHO de uma coisa em pé do World na vista isométrica (ver iso_view.gd).
##
## Copia a arte que a coisa tem HOJE (sprites, rótulos, luzes, partículas) e a mantém igual
## (quadro da animação, textura, visível, cor...), desenhada de pé no ponto isométrico do pé.
## Nada aqui mexe na coisa de verdade: ela continua andando/trabalhando no chão cartesiano.
## A CAIXA (pegada + altura) decide a ordem de desenho e o clique.
##
## Prompt 29 (parte 2): quando a coisa tem ARTE NOVA (iso_art.gd: prédios, portões), o desenho
## antigo some do espelho e as camadas novas entram no lugar, cada uma na sua âncora; a caixa
## passa a ser a do desenho novo. Rótulos, luzes e partículas continuam (espelhados), levados
## pra proporção do desenho novo.
##
## Prédio em "L" (côncavo) = VÁRIAS caixas: a coisa declara `iso_parts()` -> [{rect, h}]
## (rect no chão relativo ao pé). Cada parte vira uma caixa na ordem e um pedaço da arte,
## recortado pela silhueta da sua caixa (clip), desenhado com o z da sua caixa.

const Iso := preload("res://scripts/iso/iso_core.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const IsoLuz := preload("res://scripts/iso/iso_luz.gd")
const IsoFx := preload("res://scripts/iso/iso_fx.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const ObraEstagio := preload("res://scripts/core/obra_estagio.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96: a pilha de material da obra
## Bloco 96: a pilha do material entregue ao lado da obra (as pilhas que já existem no jogo): [pequena, média, grande].
const PILHAS := {"madeira": ["tabuas", "tabuas", "tabuas"], "tabua": ["tabuas", "tabuas", "tabuas"],
	"carvao": ["carvao_p", "carvao_m", "carvao_m"], "minerio": ["pedra_p", "pedra_m", "pedra_g"],
	"barra": ["aco_p", "aco_m", "aco_m"], "outro": ["caixote", "caixote", "caixote"]}
## Bloco 96: a partir de quantas unidades a pilha é média / grande.
const PILHA_MEDIA := 15.0
const PILHA_GRANDE := 40.0
## Bloco 95: os rótulos de prédio (nome + detalhes) que ficam compactos no mapa: só o nome, pequeno.
const ROTULOS_COMPACTOS := ["NameLabel", "StatusLabel"]

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
## Arte nova (Prompt 29): o nó com as camadas, o que está desenhado e a caixa dela
var _art: Node2D = null
var _art_key := ""
var _art_box := {}  # {rect, h}: px de arte, relativa ao pé ({} = sem arte nova)
var _janelas: Sprite2D = null  # Prompt 19: janelas acesas (máscara do desenho)
var _old_size := Vector2.ZERO  # tamanho do desenho antigo (px da lógica): pra levar rótulos/luzes
## Boneco com a arte nova (Prompt 29 parte 3): [atrás, corpo, na frente] e a altura dele (px de arte)
var _char: Node2D = null
var _char_h := 0.0
var _char_foot := 0.0  # pegada da caixa do boneco novo (px da lógica; 0 = a de sempre)
var _clock := 0.0
var _moving_now := false
## Pedaços do desenho antigo que o boneco novo esconde: não precisam ser copiados a cada quadro
var _hidden_by_char := {}
var _c_back: Sprite2D
var _c_body: Sprite2D
var _c_front: Sprite2D
var _props_synced := false
var _caiu := false  # criatura: a poeira da queda já subiu
var _chamas := {}  # Prompt 18: nome da luz -> chama animada no ponto de fogueira/forja
## Bloco 73: quem anda pela física (ipezinho) só muda de lugar nos passos da física (60/s); a tela
## desenha em outro ritmo (mais quadros, ou dois passos num quadro) e o boneco ia aos trancos.
## O espelho desenha entre o passo anterior e o atual, pela fração do passo (~16 ms de atraso).
var _f_ant := Vector2.INF
var _f_cur := Vector2.INF
var _f_quadro := -1
## Bloco 73: a caminhada pela DISTÂNCIA andada no chão da vista (antes era pelo relógio, 9 quadros/s:
## andando a 180 px/s o chão escorregava embaixo do pé, e empurrando alguém ele marchava no lugar).
## Um ciclo (2 passos) a cada PASSO_CICLO px de arte; parado de fato abaixo de MEXENDO px/s.
const PASSO_CICLO := 56.0
const MEXENDO := 20.0
var _passo := 0.0
var _chao_ant := Vector2.INF
var _desloc := 0.0  # px de arte por segundo (suavizado)


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
	if not dynamic:
		_sync_art()  # arte nova: já nasce com a caixa do desenho (não troca no 1º quadro)
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
	_art = null
	_art_key = ""
	_char = null
	_hidden_by_char = {}
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
		# Prompt 19: a ordem de desenho usa z de -4060 a 4096 (iso_order.gd); o alcance padrão da
		# luz (-1024..1024) deixava o terreno e boa parte das coisas sem luz nenhuma
		(d as PointLight2D).range_z_min = RenderingServer.CANVAS_ITEM_Z_MIN
		(d as PointLight2D).range_z_max = RenderingServer.CANVAS_ITEM_Z_MAX
	if d is AnimatedSprite2D:
		(d as AnimatedSprite2D).stop()  # o quadro vem da coisa de verdade
	if d is CPUParticles2D and _view.get("S") != null:
		IsoFx.particula(d, s, src, _view.S)  # Prompt 18: textura de pixel por papel
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
		if _char != null and _hidden_by_char.has(d):
			continue  # escondido pelo boneco novo (corpo, acessórios, ferramenta antigos)
		if dynamic and not s.visible:
			if d.visible:
				d.visible = false  # ícone escondido (zanga, greve...): o resto não precisa copiar
			continue
		_copy(s, d, SYNC_ITEM)
		if s is Control and not _view.labels_on:
			d.visible = false  # zoom "longe": sem rótulo (Prompt 30)
		if s is Node2D:
			_copy(s, d, SYNC_NODE2D)
		elif s is Control:
			_copy(s, d, ["position", "size", "rotation", "scale"])
		var list: Array = SYNC_BY_CLASS.get(s.get_class(), [])
		if not list.is_empty():
			_copy(s, d, list)
		if s is Label and ROTULOS_COMPACTOS.has(String(s.name)):
			_rotulo_compacto(s, d)  # Bloco 95
		if _char != null and d is Sprite2D and d.texture != null:
			_icone_novo(d)  # Prompt 21: ícone por cima da cabeça com o desenho novo
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
	if not dynamic:
		_sync_art()


# ------------------------------------------------------------ arte nova (Prompt 29)
## Troca o desenho antigo pelas camadas da arte nova (iso_art.gd), quando a coisa tem.
func _sync_art() -> void:
	var layers: Array = IsoArt.layers(src)
	if layers.is_empty():
		if _art:
			_art.queue_free()
			_art = null
			_art_key = ""
			_art_box = {}
		return
	if _old_size == Vector2.ZERO:
		var vr := _visual_rect()
		_old_size = Vector2(maxf(vr.size.x, 1.0), maxf(-vr.position.y, 1.0))
	var key := ""
	for l in layers:
		key += "%s|%s;" % [l.tex.resource_path, l.obra >= 0.0]
	if _art == null:
		_art = Node2D.new()
		_art.name = "ArteNova"
		add_child(_art)
		move_child(_art, 0)
	if key != _art_key:
		_art_key = key
		for c in _art.get_children():
			_art.remove_child(c)  # sai na hora (a camada nova pode ter o mesmo nome)
			c.queue_free()
		for l in layers:
			var sp := Sprite2D.new()
			sp.texture = l.tex
			sp.centered = false
			sp.offset = -l.ancora
			if l.get("flip", false):  # Bloco 74: virada de lado (espelho em volta da âncora)
				sp.flip_h = true
				sp.offset.x = l.ancora.x - l.tex.get_width()
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.light_mask = 2
			_art.add_child(sp)
		_janelas = null
		if layers[0].has("janelas"):  # Prompt 19: janelas acesas por cima do desenho
			_janelas = Sprite2D.new()
			_janelas.name = "Janelas"
			_janelas.texture = layers[0].janelas
			_janelas.centered = false
			_janelas.offset = -layers[0].ancora
			_janelas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_janelas.light_mask = 0  # a luz das janelas é dela mesma
			_art.add_child(_janelas)
	for i in mini(layers.size(), _art.get_child_count()):
		var sp: Sprite2D = _art.get_child(i)
		if layers[i].obra >= 0.0:
			ObraEstagio.apply(sp, layers[i].obra)  # a peça em montagem sobe por estágios
		else:
			ObraEstagio.clear(sp)
			sp.modulate = layers[i].get("mod", Color.WHITE)  # jazida travada fica cinza
		if layers[i].has("em"):  # outra ponta (gaiola do elevador): no chão do andar dela
			var e: Vector2 = layers[i].em
			sp.position = Iso.iso(_view.art(e), _view.height_at(e)) - Iso.iso(_view.art(src.global_position), _view.height_at(src.global_position))
		if layers[i].has("anim"):  # chama da tocha
			var fr: Array = layers[i].anim
			sp.texture = fr[int(Time.get_ticks_msec() / 1000.0 * IsoArt.TORCH_FPS) % fr.size()]
	_art_box = IsoArt.box_of(layers)
	pickable = true
	# a arte nova é desenhada no tamanho dela (px de arte): desfaz a escala do espelho
	_art.scale = Vector2(1.0 / scale.x, 1.0 / scale.y) if scale.x != 0.0 and scale.y != 0.0 else Vector2.ONE
	# o desenho antigo some; rótulos, luzes e partículas vão pra proporção do desenho novo
	var k: float = _view.S
	var new_size := Vector2(240.0, 200.0)
	if not _art_box.is_empty():
		var r: Rect2 = _art_box.rect
		new_size = Vector2(r.size.x + r.size.y, _art_box.h) / k
	var ratio := Vector2(new_size.x / _old_size.x, new_size.y / _old_size.y)
	var lift := new_size.y - _old_size.y
	for pr in _pairs:
		var d = pr[1]
		if d is Sprite2D or d is AnimatedSprite2D or d is Polygon2D or d is Line2D:
			if d.get_child_count() > 0:
				d.self_modulate.a = 0.0  # some só o desenho dele: os filhos (a luz da tocha) continuam
			else:
				d.visible = false
		elif d is Control and d.get_parent() == self:
			d.position.y = pr[0].position.y - lift  # rótulo: a mesma folga acima do telhado novo
		elif d is Node2D and d.get_parent() == self:
			d.position = pr[0].position * ratio  # luz, fumaça: no mesmo lugar do desenho
	_sync_luzes(layers)
	if layers[0].tex.resource_path.get_file().begins_with("achado_"):
		_brilho_achado()
	# elevador: a ponta de baixo (rótulo, luz) vai pro andar de baixo, junto da gaiola
	var bottom = src.get_node_or_null("Bottom")
	if bottom and src.get("bottom_position") != null:
		var e: Vector2 = src.bottom_position
		var off := Iso.iso(_view.art(e), _view.height_at(e)) - Iso.iso(_view.art(src.global_position), _view.height_at(src.global_position))
		for pr in _pairs:
			if pr[0] == bottom and scale.x != 0.0 and scale.y != 0.0:
				pr[1].position = Vector2(off.x / scale.x, off.y / scale.y)


func _copy(s: Object, d: Object, props: Array) -> void:
	for p in props:
		var v = s.get(p)
		if d.get(p) != v:
			d.set(p, v)


## Bloco 95: o rótulo do prédio no mapa mostra só o NOME, menor; o texto inteiro (quantidade, estágio, a obra)
## aparece com o mouse em cima ou com a janela do prédio aberta. A linha da obra ("40% — esperando engenheiro")
## vira a barrinha com o martelo (_draw_top).
func _rotulo_compacto(s: Label, d: Label) -> void:
	if not d.has_meta("_compacto"):
		d.set_meta("_compacto", true)
		d.add_theme_font_size_override("font_size", Tipo.MAPA)
		if Tipo.fonte() != null:
			d.add_theme_font_override("font", Tipo.fonte())  # (o tema não chega no mundo: a mesma letra da interface)
		d.add_theme_color_override("font_outline_color", Tipo.CONTORNO_MAPA)
		d.add_theme_constant_override("outline_size", Tipo.CONTORNO_MAPA_PX)
		d.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM  # (o nome fica embaixo, perto do prédio)
	var cheio: bool = is_instance_valid(src) and (_view.hover == src or _view.foco == src)
	var t: String = s.text if cheio else s.text.get_slice("
", 0)
	if d.text != t:
		d.text = t


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
	if not dynamic and not _art_box.is_empty():
		return _update_box_art(feet)  # Bloco 53: fixa com a arte nova: a caixa é a do desenho
	# boneco novo: a altura vem dele (medir o desenho antigo a cada quadro custa)
	var vr := Rect2(0, -_char_h / _view.S, 1, 1) if dynamic and _char_h > 0.0 else _visual_rect()
	var rect: Rect2
	var k: float = _view.S
	var top := maxf(MIN_HEIGHT, -vr.position.y)
	if dynamic:
		rect = Rect2(feet - Vector2.ONE * WALKER_FOOT * 0.5, Vector2.ONE * WALKER_FOOT)
		top = maxf(16.0, top)
		if _char_h > 0.0:
			top = _char_h / k  # boneco novo: a altura dele (vira px de arte logo abaixo)
		if _char_foot > 0.0:
			rect = Rect2(feet - Vector2(_char_foot, _char_foot * (70.0 / 190.0 if _char_h <= 60.0 else 1.0)) * 0.5,
				Vector2(_char_foot, _char_foot * (70.0 / 190.0 if _char_h <= 60.0 else 1.0)))
	else:
		rect = _footprint(feet, vr)
	rect = _view.art_rect(rect)  # caixa em px de arte (escala da vista; andar de baixo na laje dele)
	top *= k
	if not _art_box.is_empty():  # arte nova: a caixa declarada do desenho (px de arte)
		var ar: Rect2 = _art_box.rect
		rect = Rect2(_view.art(feet) + ar.position, ar.size)
		top = _art_box.h
	var zb: float = _view.height_at(feet) if _view.has_method("height_at") else 0.0
	if _parts.size() > 1:
		return _update_parts(feet, zb)
	var changed: bool = rect != box.rect or absf(box.zt - (zb + top)) > 1.0 or box.zb != zb
	box.rect = rect
	box.zb = zb
	box.zt = zb + top
	return changed


## Bloco 53: a mesma conta do _update_box pra fixa com a arte nova, sem medir o desenho antigo
## nem a pegada (que a caixa declarada do desenho substitui).
func _update_box_art(feet: Vector2) -> bool:
	var zb: float = _view.height_at(feet) if _view.has_method("height_at") else 0.0
	if _parts.size() > 1:
		return _update_parts(feet, zb)
	var ar: Rect2 = _art_box.rect
	var rect := Rect2(_view.art(feet) + ar.position, ar.size)
	var top: float = _art_box.h
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
	if src.is_in_group("canteiros") or src.is_in_group("parques") or src.is_in_group("obras"):
		_top.queue_redraw()
		queue_redraw()
	var changed := _update_box()
	position = Iso.iso(_view.art(src.global_position), box.zb).round()
	return changed


## view_rect: a parte da tela que se vê (com folga). Fora dela, o boneco só atualiza posição e caixa
## (sem animação, rótulos, ícones): voltando pra tela, sincroniza tudo de novo.
func sync_dynamic(view_rect: Rect2 = Rect2()) -> void:
	_update_box()
	var g: Vector2 = _view.art(_pos_suave())
	var scr := Iso.iso(g, box.zb)
	_conta_passo(g, get_process_delta_time())
	if view_rect.has_area() and not view_rect.has_point(scr) and _char != null:
		position = scr.round()
		_last_screen = scr
		never_synced = true  # na volta pra tela: tudo de novo
		return
	if _last_screen != Vector2.INF:
		_vel = _vel.lerp(scr - _last_screen, 0.35)
	_last_screen = scr
	var moving: bool = src is CharacterBody2D and (src as CharacterBody2D).velocity.length() > 5.0 and _desloc > MEXENDO
	if src.is_in_group("robos") or src.is_in_group("criaturas") or src.is_in_group("animais"):
		moving = _vel.length() > 0.2  # robô e criaturas andam mexendo a posição (não são CharacterBody)
	_moving_now = moving
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
	_clock += get_process_delta_time()
	# Bloco 53: rótulos/ícones/luz E a pose do boneco novo a cada 2 quadros (alternando entre os
	# bonecos; a animação é de ~10 quadros/s, então não se vê): a posição continua a cada quadro.
	# Chamado sem view_rect (testes, sincronizar já): tudo agora.
	_props_synced = false
	if not view_rect.has_area() or _char == null or never_synced or (Engine.get_process_frames() + get_instance_id()) % 2 == 0:
		never_synced = false
		_sync_props()
		_props_synced = true
		_tool_rule(moving)
		_sync_char()
		_redraw_if_changed()


## Bloco 73: a posição de quem anda pela física, entre o passo anterior e o atual (ver _f_ant).
func _pos_suave() -> Vector2:
	var p: Vector2 = src.global_position
	if not (src is CharacterBody2D):
		return p
	var f := Engine.get_physics_frames()
	if f != _f_quadro:
		_f_ant = _f_cur if _f_cur != Vector2.INF else p
		_f_cur = p
		_f_quadro = f
	elif p != _f_cur:  # mudou fora da física (gaiola do elevador, porta, save): vai direto
		_f_ant = p
		_f_cur = p
	if _f_ant.distance_squared_to(_f_cur) > 400.0:  # pulo de lugar: sem meio-termo
		return p
	return _f_ant.lerp(_f_cur, Engine.get_physics_interpolation_fraction())


## Bloco 73: a fase da caminhada (ciclos) e a velocidade de verdade, pelo chão da vista (px de arte).
func _conta_passo(g: Vector2, dt: float) -> void:
	if _chao_ant != Vector2.INF:
		var d := g.distance_to(_chao_ant)
		if d > 24.0:  # pulo de lugar (elevador, porta, save): não conta como passo
			d = 0.0
		_passo = fmod(_passo + d / PASSO_CICLO, 6400.0)  # (Bloco 76: grande — o robô e as criaturas leem em px)
		if dt > 0.0:
			_desloc = lerpf(_desloc, d / dt, minf(1.0, dt * 12.0))
	_chao_ant = g


## Bloco 53: sombra/anel/barra de vida só se redesenham quando muda o que eles mostram (antes era
## todo quadro, pra cada boneco).
var _draw_sig := []


func _redraw_if_changed() -> void:
	var sig := [src.get("_inside"), src.get("selected"), _char != null, scale, src.get("hp"), src.get("_dying"),
		_char_h, _flip, src.get("_target") if src.is_in_group("criaturas") else null]
	if sig != _draw_sig:
		_draw_sig = sig
		_top.queue_redraw()
		queue_redraw()


# ------------------------------------------------------------ luz e noite (Prompt 19)
## Cada luz copiada vai pro ponto de luz anotado no desenho (prédios) ou pro alto do desenho
## novo (tocha, cristal), com a textura/cor do tipo dela; as janelas acendem quando a luz do
## prédio está acesa e está escuro.
func _sync_luzes(layers: Array) -> void:
	var luzes: Array = layers[0].get("luzes", []) if not layers.is_empty() else []
	var usados := {}
	var acesa := false
	var tem_luz_de_janela := false
	var h: float = _art_box.get("h", 60.0)
	for pr in _pairs:
		var d = pr[1]
		if not (d is PointLight2D):
			continue
		var s = pr[0]
		d.global_scale = Vector2.ONE  # o alcance em px de arte (a luz da tocha herdava ~3x da peça antiga)
		var tipo := IsoLuz.tipo_de(s)
		var pt := IsoLuz.ponto_para(s, luzes, usados) if not luzes.is_empty() else {}
		if not pt.is_empty():
			tipo = pt.tipo
			d.global_position = global_position + pt.pos
		elif tipo == "tocha":
			d.global_position = global_position + Vector2(0, -h * 0.8)  # a chama, no alto da tocha
		elif tipo == "cristal":
			d.global_position = global_position + Vector2(0, -h * 0.45)
		if tipo != "":
			IsoLuz.aplica(d, tipo, tipo == "cristal", s)  # o cristal mantém a cor dele
		if not pt.is_empty() and (tipo == "fogueira" or tipo == "forja"):
			_chama(String(s.name), pt.pos, s.enabled)  # Prompt 18: o fogo mexendo
		if String(s.name) in ["WindowLight", "Glow", "Light", "ForgeLight"]:
			tem_luz_de_janela = true
			acesa = acesa or s.enabled  # (visível não: o Environment apaga as luzes fora da tela)
	if _janelas:
		if not is_inside_tree():
			_janelas.visible = false  # (criando o espelho: ainda fora da árvore)
			return
		var c := IsoLuz.cor_janela(get_tree())
		_janelas.visible = (acesa or not tem_luz_de_janela) and c.a > 0.01
		_janelas.modulate = c


## Prompt 18: brilho piscando em cima do achado (bobina, cristal, peça, painel no chão da mina).
func _brilho_achado() -> void:
	if _art.get_node_or_null("Brilho") != null:
		return
	var t := IsoFx.tex("brilho_achado")
	if t == null:
		return
	var b := Sprite2D.new()
	b.name = "Brilho"
	b.texture = t
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.light_mask = 0
	var h: float = _art_box.get("h", 20.0)
	b.position = Vector2(4, -h * 0.7).round()
	_art.add_child(b)
	var tw := b.create_tween().set_loops()
	tw.tween_property(b, "modulate:a", 0.0, 0.5).set_delay(randf_range(0.6, 1.6))
	tw.tween_property(b, "modulate:a", 1.0, 0.25)


## Prompt 18: a chama animada (fx chama_p) no ponto de fogueira/forja do desenho, acesa junto
## com a luz do prédio.
func _chama(nome: String, pos: Vector2, on: bool) -> void:
	var a = _chamas.get(nome)
	if a == null or not is_instance_valid(a):
		if not on or _art == null:
			return
		var sf := IsoFx.sprite_frames("chama_p")
		if sf.get_frame_count("default") == 0:
			return
		var fr: Texture2D = sf.get_frame_texture("default", 0)
		a = AnimatedSprite2D.new()
		a.name = "Chama_" + nome
		a.sprite_frames = sf
		a.centered = false
		a.offset = -Vector2(fr.get_width() * 0.5, fr.get_height() - 1.0)
		a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		a.light_mask = 0  # o fogo brilha sozinho
		a.play("default")
		_art.add_child(a)
		_chamas[nome] = a
	a.position = pos + Vector2(0, 5)
	a.visible = on


# ------------------------------------------------------------ boneco com a arte nova (Prompt 29)
## O corpo antigo (Body e os acessórios) e a ferramenta da mão somem; o boneco novo entra no
## tamanho dele (px de arte) com a animação/direção/pele do estado (iso_bonecos.gd), o saco e a
## ferramenta nas costas por cima ou por trás. Ícones (machucado, zanga, carga) ficam, acima da
## cabeça nova; a cor de estado do corpo (fome, frio, traje) passa pro boneco novo.
func _sync_char() -> void:
	var p: Dictionary
	if src.is_in_group("robos"):
		p = IsoBonecos.robo_pose(src, iso_dir, _clock, _moving_now, _passo * PASSO_CICLO)
	elif src.is_in_group("criaturas"):
		p = IsoBonecos.criatura_pose(src, iso_dir, _moving_now, _passo * PASSO_CICLO)  # Prompt 17 (Bloco 76: + distância)
	else:
		p = IsoBonecos.pose(src, iso_dir, _clock, _passo, _desloc > MEXENDO)
	if p.is_empty():
		if _char:
			_char.queue_free()
			_char = null
			_char_h = 0.0
		return
	if _char == null:
		_char = Node2D.new()
		_char.name = "BonecoNovo"
		for nm in ["Atras", "Corpo", "Frente"]:  # nessa ordem: atrás, corpo, na frente
			var sp := Sprite2D.new()
			sp.name = nm
			sp.centered = false
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.light_mask = 2
			_char.add_child(sp)
		_c_back = _char.get_child(0)
		_c_body = _char.get_child(1)
		_c_front = _char.get_child(2)
		add_child(_char)
		move_child(_char, 0)
		_props_synced = true
	var sc := Vector2(1.0 / scale.x, 1.0 / scale.y) if scale.x != 0.0 and scale.y != 0.0 else Vector2.ONE
	if _char.scale != sc:
		_char.scale = sc
	_char.visible = not p.get("hidden", false)
	if _hidden_by_char.is_empty():
		for pr in _pairs:
			var s = pr[0]
			if not is_instance_valid(s):
				continue
			var placa: bool = s is Sprite2D and s.texture != null and s.texture.resource_path.ends_with("strike_sign.png")  # Prompt 2: a placa vai na mão
			if (placa or s == _body_pair_src() or s.name == "Tool" or s.name == "Visual" or (s.get_parent() != null and s.get_parent().name == "Body")):
				_hidden_by_char[pr[1]] = true
	for d in _hidden_by_char:
		if is_instance_valid(d) and d.visible:
			d.visible = false
	if not _char.visible:
		return
	if p.get("anim") == "morrer" and not _caiu:
		_caiu = true
		IsoFx.puff(_char, Vector2(0, -4))  # Prompt 18: cai e levanta poeira
	var body: Sprite2D = _c_body
	if body.texture != p.tex:  # (só mexe no que mudou: trocar textura/grade a cada quadro custa)
		body.texture = p.tex
	if body.hframes != p.n:
		body.hframes = p.n
	if body.frame != p.frame:
		body.frame = p.frame
	if body.offset != -p.ancora:
		body.offset = -p.ancora
	# cor de estado do boneco antigo: fome e frio continuam; machucado e traje a arte nova já mostra
	var bs = _body_pair_src()
	var tint_ok: bool = not src.get("injured") and not String(p.pasta).begins_with("traje_")
	body.modulate = bs.modulate if tint_ok and bs != null and is_instance_valid(bs) else Color.WHITE
	var used := {}
	for k in ["saco", "item"]:
		if p.has(k) and not p[k].is_empty():
			var l: Dictionary = p[k]
			var sp: Sprite2D = _c_front if l.front else _c_back
			if used.has(sp):  # saco e ferramenta do mesmo lado: o saco ganha (carregando)
				continue
			used[sp] = true
			if sp.texture != l.tex:
				sp.texture = l.tex
			sp.flip_h = l.flip
			sp.position = l.pos
	_c_back.visible = used.has(_c_back)
	_c_front.visible = used.has(_c_front)
	# ícones acima da cabeça nova (eles ficavam acima do boneco antigo, mais baixo)
	if _char_h == 0.0:
		var vr := _visual_rect()
		_old_size = Vector2(maxf(vr.size.x, 1.0), maxf(-vr.position.y, 1.0))
	_char_h = maxf(float(p.altura), 16.0)
	# robô: deitado no chão ocupa a pegada dele (190×70); em pé, 52 (contrato do Prompt 5)
	_char_foot = (190.0 if p.get("deitado", false) else 52.0) / _view.S if src.is_in_group("robos") else 0.0
	if not _props_synced:
		return  # os ícones só mudam quando foram copiados (a cada 2 quadros)
	for pr in _pairs:  # Prompt 19: lanterna do capacete, olho do robô
		if pr[1] is PointLight2D:
			pr[1].global_scale = Vector2.ONE
			var tl := IsoLuz.tipo_de(pr[0])
			if tl != "":
				IsoLuz.aplica(pr[1], tl, false, pr[0])
	var lift: float = _char_h / _view.S - _old_size.y
	for pr in _pairs:
		var d = pr[1]
		if d is Node2D and d.get_parent() == self and d.visible and pr[0].name != "Body" and pr[0].name != "Tool":
			if pr[0].position.y < -16.0:
				d.position.y = pr[0].position.y - lift


func _body_pair_src():
	return _body_pair[0] if not _body_pair.is_empty() else null


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
			var ring := IsoFx.tex("anel_selecao")
			if ring and _char != null:  # Prompt 18: anel de pixel no chão (px de arte)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / scale.x, 1.0 / scale.y))
				draw_texture(ring, -ring.get_size() * 0.5 + Vector2(0, 1))
			else:
				draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 32, Color(1.0, 0.84, 0.25), 2.5)
	elif src.is_in_group("parques") and src.has_method("radius"):
		var r: float = src.radius() * 1.4142
		draw_set_transform(Iso.iso(Vector2(0, -10)), 0.0, Vector2(1.0, 0.5))
		var n := 48
		for i in n:
			if i % 2 == 0:
				draw_arc(Vector2.ZERO, r, TAU * i / n, TAU * (i + 1) / n, 3, Color(0.6, 1.0, 0.55, 0.13), 1.5)


## Prompt 21: ícones antigos por cima da cabeça -> os novos (16 px), em px de arte (1:1).
const ICONE_NOVO := {"bandage.png": "p_ferido", "anger.png": "p_zanga"}


func _icone_novo(d: Sprite2D) -> void:
	var nome: String = ICONE_NOVO.get(d.texture.resource_path.get_file(), "")
	if nome == "":
		return
	var t := Icones.tex(nome)
	if t == null:
		return
	d.texture = t
	d.hframes = 1
	d.vframes = 1
	d.frame = 0
	d.region_enabled = false
	var gs: Vector2 = d.get_parent().global_transform.get_scale() if d.get_parent() is Node2D else scale
	d.scale = Vector2(1.0 / maxf(absf(gs.x), 0.01), 1.0 / maxf(absf(gs.y), 0.01))


## Bloco 96: a pilha do material entregue e ainda não usado, no pé da obra, ao lado (diminui conforme a obra anda).
var _pilha_tex := {}


func _desenha_pilha(k: Vector2) -> void:
	var site = ObraSite.de(src)
	if site == null or not site.tem_material():
		return
	var pilha: Dictionary = site.pilha(src.obra_progress())
	if pilha.is_empty():
		return
	var item := ""
	var qtd := 0.0
	for it in pilha:
		if float(pilha[it]) > qtd:
			qtd = float(pilha[it])
			item = it
	var tipo := "outro"
	if item in ["madeira", "tabua"]:
		tipo = item
	elif item == "carvao":
		tipo = "carvao"
	elif item.begins_with("barra") or item in ["aco", "lingote_solar"]:
		tipo = "barra"
	elif item in ["ferro", "cobre", "prata", "solarita"] or item.begins_with("cristal"):
		tipo = "minerio"
	var nome: String = PILHAS[tipo][0 if qtd < PILHA_MEDIA else (1 if qtd < PILHA_GRANDE else 2)]
	if not _pilha_tex.has(nome):
		var path := "res://assets/game/iso/props/%s.png" % nome
		_pilha_tex[nome] = load(path) if ResourceLoader.exists(path) else null
	var tex: Texture2D = _pilha_tex[nome]
	if tex == null:
		return
	var x := 40.0
	if not _art_box.is_empty():
		x = (_art_box.rect as Rect2).end.x - 6.0  # no canto da frente da obra
	_top.draw_set_transform(Vector2.ZERO, 0.0, k)
	_top.draw_texture(tex, Vector2(x - tex.get_width() * 0.5, -tex.get_height() + 4.0))
	_top.draw_set_transform(Vector2.ZERO)


## Por cima da arte: barra de vida das criaturas e barrinha de progresso da obra (canteiro e, no Bloco 95, toda
## obra encomendada: melhoria do Centro, ampliação da casa, conserto...). O martelo do lado: colorido com gente
## trabalhando, CINZA esperando engenheiro (ou ferreiro).
func _draw_top() -> void:
	if not is_instance_valid(src):
		return
	var e_obra: bool = src.is_in_group("obras") and src.has_method("obra_pending") and src.obra_pending()
	if (src.is_in_group("canteiros") and src.has_method("obra_progress") and src.has_method("_top")) or e_obra:
		var y: float = -(src._top() + 8.0) if src.has_method("_top") else -48.0
		if not _art_box.is_empty():
			y = -(_art_box.h / _view.S + 8.0)  # em cima do desenho novo
		var eng: bool
		if src.has_method("obra_workers"):
			eng = not src.obra_workers().is_empty()
		else:
			eng = src._obra.has_engineer() if src.get("_obra") else false
		var k := Vector2(1.0 / maxf(absf(scale.x), 0.01), 1.0 / maxf(absf(scale.y), 0.01))  # px de tela, não da arte
		_top.draw_set_transform(Vector2(0, y), 0.0, k)
		_top.draw_rect(Rect2(-26, -3, 52, 6), Color(0.05, 0.04, 0.03, 0.85))
		_top.draw_rect(Rect2(-25, -2, 50 * clampf(src.obra_progress(), 0.0, 1.0), 4), Color(1.0, 0.6, 0.25) if eng else Color(0.62, 0.58, 0.54))
		var martelo := Icones.tex("construir", true)
		if martelo:
			_top.draw_texture(martelo, Vector2(30, -12), Color.WHITE if eng else Color(0.5, 0.5, 0.5, 0.95))
		_top.draw_set_transform(Vector2.ZERO)
		_desenha_pilha(k)
		return
	if not src.is_in_group("criaturas"):
		return
	var hp = src.get("hp")
	var max_hp = src.get("max_hp")
	var alvo = src.get("_target")
	var alerta := Icones.tex("p_alerta")
	if alerta and _char != null and not src.get("_dying") and alvo != null and is_instance_valid(alvo) and alvo.is_in_group("ipezinhos"):
		# Prompt 17/21: "!" em cima de quem está caçando alguém
		var ya: float = -(_char_h / _view.S + 14.0)
		_top.draw_set_transform(Vector2(0, ya), 0.0, Vector2(1.0 / absf(scale.x), 1.0 / absf(scale.y)))
		_top.draw_texture(alerta, Vector2(-8, -16))
		_top.draw_set_transform(Vector2.ZERO)
	if hp == null or max_hp == null or src.get("_dying") or hp >= max_hp:
		return
	var w := 22.0
	var y := -32.0
	if _char != null and _char_h > 0.0:
		y = -(_char_h / _view.S + 5.0)  # Prompt 17: em cima da arte nova
	_top.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_flip, 1.0))
	_top.draw_rect(Rect2(-w * 0.5, y, w, 3), Color(0, 0, 0, 0.7))
	_top.draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 3), Color(0.9, 0.3, 0.25))
