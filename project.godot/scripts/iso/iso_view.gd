extends Node2D
## Prompt 28: a VISTA ISOMÉTRICA do jogo (Prompt 29: é a vista do jogo; o F3 saiu). A lógica não muda: o nó World
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
const Ceu := preload("res://scripts/iso/iso_sky.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const IsoLuz := preload("res://scripts/iso/iso_luz.gd")
const IsoFx := preload("res://scripts/iso/iso_fx.gd")

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
## Mapa novo: a textura do chão só serve pras manchas dos andares de baixo (zonas, marcador):
## refaz a cada N quadros em vez de todo quadro (renderizar o mundo inteiro numa textura custa).
const GROUND_REFRESH_EVERY := 6
## Até quantos que andam a ordem deles é refeita todo quadro (acima disso, a cada 2).
const DYN_ORDER_EVERY_FRAME := 24
## Coisas em pé que não mudam muito: confere caixa/arte a cada N quadros.
const STATIC_SYNC_EVERY := 6
## Histerese da direção de losango (graus além dos 45° da fatia).
const DIR_HYSTERESIS := 15.0

## Direções de losango (bordas do chão = diagonais da tela).
enum { DIR_SE, DIR_SW, DIR_NW, DIR_NE }

var enabled := false
## Prompt 30: no zoom "longe" (menos de 1 px de tela por px de arte) os rótulos somem: o texto
## fica pequeno demais e um cobre o outro.
var labels_on := true
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
## Bloco 72: quem anda (todo quadro) e as fixas em STATIC_SYNC_EVERY grupos (um grupo por quadro), em vez
## de varrer todas as entidades a cada quadro só pra decidir quem sincroniza; as fixas novas sincronizam
## no quadro seguinte (_novas).
var _dinamicos: Array = []
var _baldes: Array = []
var _novas: Array = []
## Bloco 72: as fixas de cada andar de baixo e do leste ficam num container por região; fora da tela, o
## container some (centenas de peças a menos pro desenho processar quando a câmera está longe).
var _grupos := {}  # região -> Node2D (meta "tela": Rect2 da região na tela, calculado na 1ª vez)
## Bloco 72: fixas que entraram depois da ordem montada esperam o quadro seguinte; se chegam muitas de
## uma vez (a decoração do ambiente, um save carregando), a ordem é refeita uma vez só — encaixar uma a
## uma numa rajada de centenas caía em reordenações completas (trancos).
const RAJADA := 20
var _rajada := {}  # Billboard -> true
var _frame := 0
var _saved_layers := {}  # filhos do Main que mudam de camada no modo iso -> camada antiga
## Posicionador (fantasma do prédio): a pegada e o raio caem achatados no chão (textura do
## chão); o desenho do prédio fica EM PÉ aqui, no ponto isométrico do mouse.
var _placer: Node2D
var _ghost_bb: Sprite2D
## Prompt 29: px de ARTE por px do mundo. A lógica continua no chão de sempre; a vista desenha
## a arte nova no tamanho dela (o mapa novo foi montado com as posições do jogo × 1,5).
var S := 1.0
## Terreno do mapa novo: [[Box, Sprite2D]] dos terraços e escadas (entram na ordem e no clique)
var _terrain: Array = []
var _terrain_node: Node2D
## Céu, montanhas e nuvens (só com o mapa novo: a vila é a céu aberto)
var _sky: Node2D
var _fx: Node2D  # Prompt 18: efeitos dos grandes eventos (iso_fx.gd)
## Andares de baixo empilhados: [{nome, art_rect, z, sprite, tint}]
var _levels: Array = []
## Tom de cada andar (o subsolo é sempre mais escuro que a superfície, de dia e de noite)
const LEVEL_TINT := {"nivel2": Color(0.62, 0.66, 0.82), "abismo": Color(0.7, 0.55, 0.5)}


func setup(main: Node2D) -> void:
	_main = main
	_world = main.get_node("World")
	_env = _world.get_node("Environment")
	_camera = main.get_node("Camera2D")
	name = "IsoView"
	add_to_group("iso_view")
	add_to_group("efeitos")
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
	_fx = IsoFx.new()
	_overlay.add_child(_fx)
	_fx.setup(self)
	_fx.set_active(false)
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
		S = _env.iso_scale() if _env.has_method("has_iso_map") and _env.has_iso_map() else 1.0
		_build_terrain()
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
	if _sky:
		_sky.set_active(on)
	_fx.set_active(on and _env.has_method("has_iso_map") and _env.has_iso_map())
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
	if _env.has_method("has_iso_map") and _env.has_iso_map() and _env.deep_rect.has_area():
		# Bloco 67: no mapa novo a textura do chão só serve pros andares de baixo (as decalques);
		# renderizar o mundo inteiro (agora com o leste) a cada poucos quadros era o custo maior
		wr = _env.deep_rect.merge(_env.abyss_rect if _env.abyss_rect.has_area() else _env.deep_rect).grow(GROUND_MARGIN * 0.5)
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
	_ground_sv.render_target_update_mode = SubViewport.UPDATE_ONCE if not _levels.is_empty() else SubViewport.UPDATE_ALWAYS
	_ground_sprite.texture = _ground_sv.get_texture()
	_ground_sprite.transform = Transform2D(Vector2(1.0, 0.5) * S, Vector2(-1.0, 0.5) * S, Iso.iso(_ground_rect.position * S))
	_ground_layer.visible = true
	if not _levels.is_empty():
		# mapa novo: o chão da superfície é o terreno; da textura do chão (o que o jogo desenha no
		# chão: manchas das zonas, pedrinhas, luz) só entram os pedaços dos andares de baixo, por
		# cima do chão novo de cada laje
		_ground_layer.visible = false
		for lv in _levels:
			var dec: Sprite2D = lv.get("decal")
			if dec == null:
				dec = Sprite2D.new()
				dec.name = "ChaoDoJogo"
				dec.centered = false
				dec.region_enabled = true
				dec.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				dec.light_mask = 0
				lv.sprite.add_child(dec)
				lv["decal"] = dec
			dec.texture = _ground_sv.get_texture()
			var r: Rect2 = lv.rect
			dec.visible = _ground_rect.encloses(r)  # Bloco 71: os andares novos ficam fora da textura do chão
			dec.region_rect = Rect2(r.position - _ground_rect.position, r.size)
			var o: Vector2 = Iso.iso(art(r.position), lv.z) - lv.sprite.position
			var kd := float(lv.get("k", 1.0))
			dec.transform = Transform2D(Vector2(1.0, 0.5) * S * kd, Vector2(-1.0, 0.5) * S * kd, o)


# ------------------------------------------------------------ terreno do mapa novo (Prompt 29)
## As imagens do terreno (monta.py exporta): o fundo da pedreira e a moldura de morros ficam
## embaixo de tudo; os terraços (alto, meio, paredão) e as escadas são CAIXAS na ordem e no
## clique, como qualquer coisa em pé (regra do contrato: cada platô = uma imagem = uma caixa).
const BACK_Z := {"moldura": Order.BASE - 60, "fundo": Order.BASE - 50}


func _build_terrain() -> void:
	if _terrain_node != null or not (_env.has_method("has_iso_map") and _env.has_iso_map()):
		return
	_terrain_node = Node2D.new()
	_terrain_node.name = "Terreno"
	add_child(_terrain_node)
	move_child(_terrain_node, 0)
	var dir: String = _env.iso_map_file.get_base_dir()
	var regs: Dictionary = _env.iso_map.get("regioes", {})
	for r in regs:
		var info: Dictionary = regs[r]
		var tex: Texture2D = load(dir.path_join(info.img))
		if tex == null:
			continue
		var sp := Sprite2D.new()
		sp.name = "Terreno_" + r
		sp.texture = tex
		sp.centered = false
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.position = Vector2(info.tela[0], info.tela[1])
		sp.light_mask = 2
		_terrain_node.add_child(sp)
		_em_blocos(sp)
		var back: String = r if BACK_Z.has(r) else ("moldura" if r.begins_with("moldura") else ("fundo" if r.begins_with("fundo") else ""))
		if back != "":  # Bloco 67: os pedaços do leste (moldura_l0, fundo_l1...) ficam no fundo como os de sempre
			sp.z_index = BACK_Z[back]
			if r == "moldura":
				_sky = Ceu.new()
				_terrain_node.add_child(_sky)
				var wr: Rect2 = _env.iso_ground_rect()
				_sky.setup(self, sp.position, Iso.iso(wr.get_center() * S, 0.0), sp)
			continue
		if not info.has("chao"):
			continue
		var c: Array = info.chao
		var b := Iso.Box.new(Rect2(c[0] * S, c[1] * S, c[2] * S, c[3] * S), float(info.z[0]), float(info.z[1]),
			"rampa" if info.get("rampa", false) else "terreno", r, null)
		_terrain.append([b, sp])
	# Bloco 75: a faixa das galerias de madeira logo abaixo da superfície (só desenho; caixa na ordem)
	var gal: Dictionary = _env.andares.get("galerias", {})
	if not gal.is_empty() and gal.has("caixa"):
		var tg: Texture2D = load(dir.path_join(gal.img))
		if tg != null:
			var sg := Sprite2D.new()
			sg.name = "Galerias"
			sg.texture = tg
			sg.centered = false
			sg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sg.position = Vector2(gal.tela[0], gal.tela[1])
			sg.light_mask = 2
			_terrain_node.add_child(sg)
			_em_blocos(sg)
			var gc: Array = gal.caixa
			_terrain.append([Iso.Box.new(Rect2(gc[0], gc[1], gc[2], gc[3]), float(gal.z[0]), float(gal.z[1]), "terreno", "galerias", null), sg])
	# os andares de baixo (nível 2, abismo): uma laje cada, empilhada embaixo da superfície
	var levels: Dictionary = _env.andares.get("andares", {})
	for nome in levels:
		var a: Dictionary = levels[nome]
		var tex2: Texture2D = load(dir.path_join(a.img))
		if tex2 == null:
			continue
		var sp2 := Sprite2D.new()
		sp2.name = "Andar_" + nome
		sp2.texture = tex2
		sp2.centered = false
		sp2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp2.position = Vector2(a.tela[0], a.tela[1])
		sp2.light_mask = 2
		sp2.self_modulate = _tom_do_andar(nome)  # Bloco 69: a luz ambiente vem dos dados do nível
		_terrain_node.add_child(sp2)
		_em_blocos(sp2)
		var cx: Array = a.caixa
		var art_r := Rect2(cx[0], cx[1], cx[2], cx[3])
		var b2 := Iso.Box.new(art_r, float(a.z[0]), float(a.z[1]), "terreno", nome, null)
		_terrain.append([b2, sp2])
		var lr := Rect2(a.rect[0], a.rect[1], a.rect[2], a.rect[3])
		var kk := float(a.get("k", 1.0))  # Bloco 72: escala do andar na vista (mais compacto)
		_levels.append({"nome": nome, "art_rect": Rect2(art(lr.position), lr.size * S * kk), "z": float(a.z_chao), "k": kk,
			"sprite": sp2, "rect": lr, "tint": LEVEL_TINT.get(nome, Color.WHITE)})
	_build_terra()
	_build_decalques()
	_build_palisade()
	_build_lava()
	_build_pocas()
	_build_nevoa_leste()
	_build_atmosfera()


# ------------------------------------------------------------ atmosfera dos níveis (Bloco 69)
const Niveis := preload("res://scripts/core/niveis.gd")
const Efeitos := preload("res://scripts/core/efeitos.gd")
const Settings := preload("res://scripts/core/settings.gd")
const PARTICULA_TEX := {"poeira": "poeira_p", "acido": "nuvem_gas", "calor": "brasa", "gotas": "gota", "bolhas": "vapor"}
const LUZ_ZONA := {"calor": Color(1.0, 0.5, 0.2), "gas": Color(0.45, 1.0, 0.35), "radiacao": Color(0.4, 0.95, 1.0)}
const AREA_DO_ANDAR := {"nivel2": "deep", "abismo": "abyss"}  # (Bloco 71: os outros andares têm o nome da área: s4, s5)
var _atmos: Array = []  # [{nivel, raiz, nevoa, part, alfa, qtd}]
var _luzes_zona: Array = []  # [luz, energia base, fase]
var _pulso_k := 1.0  # força do pulso das luzes (guardada: o settings.cfg só é lido quando muda)


func _nivel_da_area(area: String) -> Resource:
	for n in Niveis.todos():
		if n.area == area and not n.em_breve:
			return n
	return null


func _tom_do_andar(nome: String) -> Color:
	var n := _nivel_da_area(AREA_DO_ANDAR.get(nome, nome))
	return n.cor_ambiente if n else LEVEL_TINT.get(nome, Color.WHITE)


## Intensidade (Configurações > Atmosfera dos níveis, 0..1); reduzir efeitos tira as partículas.
static func atmosfera_intensidade() -> float:
	return clampf(Settings.get_value("video", "atmosfera", 1.0), 0.0, 1.0)


func _build_atmosfera() -> void:
	if not _env.has_method("has_iso_map") or not _env.has_iso_map():
		return
	add_to_group("efeitos")
	# os andares de baixo (laje) e a pedreira (S1, só poeira leve)
	var alvos := []
	for lv in _levels:
		alvos.append([_nivel_da_area(AREA_DO_ANDAR.get(lv.nome, lv.nome)), lv.rect, float(lv.z)])
	alvos.append([_nivel_da_area("mapa"), _env.map_rect, 0.0])
	for a in alvos:
		var n: Resource = a[0]
		if n == null:
			continue
		var r: Rect2 = a[1]
		var z: float = a[2]
		var raiz := Node2D.new()
		raiz.name = "Atmosfera_" + n.id
		raiz.z_as_relative = false
		raiz.z_index = 3700
		_things.add_child(raiz)
		var pts := PackedVector2Array()
		var contorno: PackedVector2Array = _env.contorno_do_andar(r) if _env.has_method("contorno_do_andar") else PackedVector2Array()
		if contorno.size() >= 3:  # Bloco 72: a névoa no formato da caverna (não o retângulo)
			for c in contorno:
				pts.append(to_screen(c, z))
		else:
			for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
				pts.append(to_screen(c, z))
		var nev := Polygon2D.new()
		nev.name = "Nevoa"
		nev.polygon = pts
		nev.color = n.cor_nevoa
		raiz.add_child(nev)
		var part: CPUParticles2D = null
		var tex: Texture2D = IsoFx.tex(PARTICULA_TEX.get(n.particulas, "")) if n.particulas != "" else null
		var qtd := 0
		if tex:
			var bb := Rect2(pts[0], Vector2.ZERO)
			for p in pts:
				bb = bb.expand(p)
			part = CPUParticles2D.new()
			part.name = "Particulas"
			part.texture = tex
			qtd = clampi(int(bb.get_area() / 9000.0), 12, 90)
			part.amount = qtd
			part.lifetime = 5.0
			part.preprocess = 5.0
			part.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			part.position = bb.get_center()
			part.emission_rect_extents = bb.size * 0.45
			part.direction = Vector2(0, -1) if n.particulas in ["calor", "bolhas", "acido"] else Vector2(0.3, 0.2)
			part.spread = 40.0
			part.gravity = Vector2(0, -6) if n.particulas in ["calor", "bolhas", "acido"] else Vector2(2, 4)
			part.initial_velocity_min = 4.0
			part.initial_velocity_max = 12.0
			part.scale_amount_min = 1.0
			part.scale_amount_max = 2.0
			var cor: Color = n.cor_nevoa
			part.color = Color(cor.r, cor.g, cor.b, 0.55) if cor.a > 0.0 else Color(1, 1, 1, 0.4)
			part.light_mask = 0
			raiz.add_child(part)
		_atmos.append({"nivel": n, "raiz": raiz, "nevoa": nev, "part": part, "alfa": n.cor_nevoa.a, "qtd": qtd})
	# Bloco 71: o lago do nível (obstáculo nos dados) brilha azul, de leve
	for n in Niveis.jogaveis():
		for o in n.obstaculos:
			if not (o is Array and o.size() >= 4):
				continue
			var lr := Rect2(float(o[0]), float(o[1]), float(o[2]), float(o[3]))
			var ll := PointLight2D.new()
			ll.name = "Lago_" + n.id
			IsoLuz.aplica(ll, "cristal")
			ll.color = Color(0.35, 0.6, 1.0)
			ll.energy = 1.2  # (Bloco 72: o lago é a luz do S5)
			ll.texture_scale *= maxf(lr.size.x, lr.size.y) / 120.0
			ll.range_item_cull_mask = LIGHT_ISO
			ll.range_z_min = RenderingServer.CANVAS_ITEM_Z_MIN
			ll.range_z_max = RenderingServer.CANVAS_ITEM_Z_MAX
			ll.position = to_screen(lr.get_center())
			ll.set_meta("tela_iso", true)
			ll.add_to_group("cullable_lights")
			_terrain_node.add_child(ll)
			_luzes_zona.append([ll, ll.energy, randf() * TAU])
			var brilho: Texture2D = IsoFx.tex("brilho_achado")  # o reflexo piscando na água (itens de arte)
			if brilho:
				var bb := Rect2(to_screen(lr.position), Vector2.ZERO)
				for c in [Vector2(lr.end.x, lr.position.y), lr.end, Vector2(lr.position.x, lr.end.y)]:
					bb = bb.expand(to_screen(c))
				var sp := CPUParticles2D.new()
				sp.name = "LagoBrilho_" + n.id
				sp.texture = brilho
				sp.amount = 14
				sp.lifetime = 1.8
				sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
				sp.emission_rect_extents = bb.size * 0.3
				sp.position = bb.get_center()
				sp.gravity = Vector2.ZERO
				sp.initial_velocity_min = 0.0
				sp.initial_velocity_max = 2.0
				sp.scale_amount_min = 0.5
				sp.scale_amount_max = 0.9
				sp.color = Color(0.7, 0.85, 1.0, 0.7)
				sp.light_mask = 0
				sp.z_as_relative = false
				sp.z_index = 3650
				_things.add_child(sp)
				_poca_fx.append(sp)  # (reduzir efeitos para, como as bolhas das poças)
	# luz pulsando nas zonas de perigo (a da lava já existe: ganha o pulso; gás e radiação ganham a sua)
	for c in _terrain_node.get_children():
		if c is PointLight2D and String(c.name).begins_with("Lava_"):
			_luzes_zona.append([c, (c as PointLight2D).energy, randf() * TAU])
	for zn in get_tree().get_nodes_in_group("zonas_perigo"):
		var k := String(zn.get("kind"))
		if k == "calor" or not LUZ_ZONA.has(k):
			continue
		var l := PointLight2D.new()
		l.name = "Brilho_" + String(zn.name)
		IsoLuz.aplica(l, "cristal")
		l.color = LUZ_ZONA[k]
		l.energy = 0.9
		l.range_item_cull_mask = LIGHT_ISO
		l.range_z_min = RenderingServer.CANVAS_ITEM_Z_MIN
		l.range_z_max = RenderingServer.CANVAS_ITEM_Z_MAX
		l.position = to_screen((zn as Node2D).global_position)
		l.set_meta("tela_iso", true)
		l.add_to_group("cullable_lights")
		_terrain_node.add_child(l)
		_luzes_zona.append([l, l.energy, randf() * TAU])
	efeitos_mudaram()


## Reduzir efeitos / intensidade mudou.
func atmosfera_aplica() -> void:
	var k := atmosfera_intensidade()
	var red := Efeitos.reduzidos()
	_pulso_k = k * (0.3 if red else 1.0)
	for part in _poca_fx:
		if is_instance_valid(part):
			part.emitting = not red
	var fundo := get_tree().get_first_node_in_group("fundo")
	for a in _atmos:
		a.raiz.visible = k > 0.01
		var c: Color = a.nevoa.color
		var vent: float = fundo.nevoa_mult() if fundo and a.nivel.id == "S2" else 1.0  # Bloco 70
		c.a = a.alfa * k * (0.5 if red else 1.0) * vent
		a.nevoa.color = c
		if a.part:
			a.part.emitting = k > 0.01 and not red
			var want := maxi(int(a.qtd * k), 1)
			if a.part.amount != want:
				a.part.amount = want


func _pulsa_luzes() -> void:
	if _luzes_zona.is_empty() or _frame % 3 != 0:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var k := _pulso_k
	for e in _luzes_zona:
		var l = e[0]
		if is_instance_valid(l):
			l.energy = e[1] * (1.0 + k * (0.12 * sin(t * 2.3 + e[2]) + 0.06 * sin(t * 7.1 + e[2] * 2.0)))


# ------------------------------------------------------------ a terra da coluna (Bloco 72)
## Os andares ficam DENTRO da terra, debaixo da vila, como a referência (docs/arte/referencia_mapa_mundo.jpg
## e a imagem B do mapa do mundo): o andares.py (mapa/andares.py) manda os polígonos da terra (a faixa
## embaixo das faces do mapa e o corpo em volta da coluna, afinando no fundo), o poço do elevador e a
## escada em espiral. Aqui eles viram desenho no fundo (camada 0): atrás das lajes dos andares.
const TERRA_TEX := "res://assets/game/iso/chao/rocha_terra.png"


func _build_terra() -> void:
	var terra: Dictionary = _env.andares.get("terra", {})
	if _levels.is_empty() or terra.is_empty() or not ResourceLoader.exists(TERRA_TEX):
		return
	var tex: Texture2D = load(TERRA_TEX)
	# o corpo da coluna (mais claro em cima, quase preto no fundo) e a faixa das faces (mais clara)
	for parte in [["TerraColuna", terra.get("coluna", []), Color(0.78, 0.72, 0.66), Color(0.26, 0.24, 0.27)],
			["TerraFaixa", terra.get("faixa", []), Color(0.86, 0.8, 0.74), Color(0.6, 0.55, 0.5)]]:
		var pts := PackedVector2Array()
		for q in parte[1]:
			pts.append(Vector2(float(q[0]), float(q[1])))
		if pts.size() < 3:
			continue
		var y0 := INF
		var y1 := -INF
		for q in pts:
			y0 = minf(y0, q.y)
			y1 = maxf(y1, q.y)
		var cores := PackedColorArray()
		for q in pts:
			cores.append((parte[2] as Color).lerp(parte[3], clampf((q.y - y0) / maxf(y1 - y0, 1.0), 0.0, 1.0)))
		var pol := Polygon2D.new()
		pol.name = parte[0]
		pol.polygon = pts
		pol.uv = pts  # a textura repete em px de tela (emenda)
		pol.texture = tex
		pol.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		pol.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pol.vertex_colors = cores
		pol.light_mask = 2
		pol.z_as_relative = false
		pol.z_index = Order.BASE - 55  # camada 0 (fundo): atrás das lajes e do chão da pedreira
		_terrain_node.add_child(pol)
	# o poço do elevador (a vertical das gaiolas) e a escada em espiral ao lado, com um patamar por andar
	var dir_img: String = _env.iso_map_file.get_base_dir()
	for peca in [["Poco", "poco"], ["Espiral", "espiral"]]:
		var info: Dictionary = _env.andares.get(peca[1], {})
		if info.is_empty():
			continue
		var t: Texture2D = load(dir_img.path_join(info.img))
		if t == null:
			continue
		var sp := Sprite2D.new()
		sp.name = peca[0]
		sp.texture = t
		sp.centered = false
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.position = Vector2(info.tela[0], info.tela[1])
		sp.light_mask = 2
		sp.z_as_relative = false
		sp.z_index = Order.BASE - 54  # na frente da terra, atrás dos andares
		_terrain_node.add_child(sp)


## Bloco 72: os decalques de cada nível (NivelMina.decalques) deitados na laje do andar (como a poça).
func _build_decalques() -> void:
	for n in Niveis.jogaveis():
		for d in n.decalques:
			if not (d is Array) or d.size() < 3:
				continue
			var path := "res://assets/game/iso/chao/%s.png" % String(d[0])
			if not ResourceLoader.exists(path):
				continue
			var p := Vector2(float(d[1]), float(d[2]))
			var laje: Sprite2D = null
			for lv in _levels:
				if (lv.rect as Rect2).grow(48.0).has_point(p):
					laje = lv.sprite
			if laje == null:
				continue
			var tela := to_screen(p)
			var dec := Sprite2D.new()
			dec.name = "Decalque_" + String(d[0])
			dec.texture = load(path)
			dec.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			dec.light_mask = 2
			dec.position = (tela - laje.position).round()
			laje.add_child(dec)
			if String(d[0]).begins_with("rio_lava"):  # o rio brilha como lava (e pulsa com as outras)
				var l := PointLight2D.new()
				l.name = "DecalqueLuz_" + String(d[0])
				IsoLuz.aplica(l, "lava")
				l.energy = IsoLuz.TIPOS.lava.forca
				l.texture_scale *= 1.6
				l.range_item_cull_mask = LIGHT_ISO
				l.range_z_min = RenderingServer.CANVAS_ITEM_Z_MIN
				l.range_z_max = RenderingServer.CANVAS_ITEM_Z_MAX
				l.position = tela
				l.set_meta("tela_iso", true)
				l.add_to_group("cullable_lights")
				_terrain_node.add_child(l)
				_luzes_zona.append([l, l.energy, randf() * TAU])


# ------------------------------------------------------------ poças do fundo (Bloco 70)
## A poça é um decalque deitado na laje do andar (assets/game/iso/chao/poca_<tipo>_<n>.png, filho do
## desenho da laje: fica por cima do chão e embaixo de tudo que está em pé); aqui entram também a luz
## pulsando e as bolhas (ácido) / brasas (lava), na camada 4.
const POCA_FX := {"acido": ["vapor", Color(0.55, 1.0, 0.35, 0.7)], "lava": ["brasa", Color(1.0, 0.55, 0.2, 0.95)],
	"agua": ["gota", Color(0.6, 0.85, 1.0, 0.6)]}
const POCA_LUZ := {"acido": Color(0.5, 1.0, 0.35), "lava": Color(1.0, 0.45, 0.15), "agua": Color(0.4, 0.7, 1.0)}
var _poca_fx: Array = []  # CPUParticles2D das poças (reduzir efeitos para)
var _pocas_feitas := {}  # poça -> true (o ambiente põe as poças um quadro depois da vista ligar)


func _build_pocas() -> void:
	for p in get_tree().get_nodes_in_group("pocas_perigo"):
		_poca_add(p)


func _poca_add(p: Node) -> void:
	if _terrain_node == null or not is_instance_valid(p) or not p.is_in_group("pocas_perigo") or _pocas_feitas.has(p):
		return
	_pocas_feitas[p] = true
	var k := String(p.kind)
	var tela := to_screen((p as Node2D).global_position)
	var arte: Texture2D = load("res://assets/game/iso/chao/poca_%s_%d.png" % [k, absi(hash(String(p.name))) % 2]) 		if ResourceLoader.exists("res://assets/game/iso/chao/poca_%s_0.png" % k) else null
	var laje: Sprite2D = null
	for lv in _levels:
		if (lv.rect as Rect2).grow(48.0).has_point((p as Node2D).global_position):
			laje = lv.sprite
	if arte and laje:
		var dec := Sprite2D.new()
		dec.name = "Poca_" + String(p.name)
		dec.texture = arte
		dec.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dec.light_mask = 2
		dec.position = (tela - laje.position).round()
		laje.add_child(dec)
	var l := PointLight2D.new()
	l.name = "PocaLuz_" + String(p.name)
	IsoLuz.aplica(l, "lava" if k == "lava" else "cristal")
	l.color = POCA_LUZ.get(k, Color.WHITE)
	l.energy = (IsoLuz.TIPOS.lava.forca * 1.25 if k == "lava" else 0.8)
	if k == "lava":
		l.texture_scale *= 1.4  # Bloco 72: o poço de lava ilumina o chão em volta (a referência é laranja viva)
	l.range_item_cull_mask = LIGHT_ISO
	l.range_z_min = RenderingServer.CANVAS_ITEM_Z_MIN
	l.range_z_max = RenderingServer.CANVAS_ITEM_Z_MAX
	l.position = tela
	l.set_meta("tela_iso", true)
	l.add_to_group("cullable_lights")
	_terrain_node.add_child(l)
	_luzes_zona.append([l, l.energy, randf() * TAU])
	var fx: Array = POCA_FX.get(k, [])
	var tex: Texture2D = IsoFx.tex(fx[0]) if not fx.is_empty() else null
	if tex == null:
		return
	var r: float = float(p.radius) * S
	var part := CPUParticles2D.new()
	part.name = "PocaFx_" + String(p.name)
	part.texture = tex
	part.amount = 8 if k == "acido" else 12
	part.lifetime = 2.2 if k == "acido" else 1.6
	part.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	part.emission_rect_extents = Vector2(r * 0.8, r * 0.35)
	part.position = tela
	part.direction = Vector2(0, -1)
	part.spread = 20.0
	part.gravity = Vector2(0, -8)
	part.initial_velocity_min = 6.0
	part.initial_velocity_max = 14.0 if k == "acido" else 26.0
	part.color = fx[1]
	part.light_mask = 0
	part.z_as_relative = false
	part.z_index = 3650  # camada 4 (efeitos), embaixo da atmosfera
	_things.add_child(part)
	_poca_fx.append(part)
	part.emitting = not Efeitos.reduzidos()
	# Bloco 72: no nível que tem água e lava (S4), a lava solta vapor — a mistura da referência
	if k == "lava" and _tem_agua_perto(p):
		var vap := part.duplicate() as CPUParticles2D
		vap.name = "PocaVapor_" + String(p.name)
		vap.texture = IsoFx.tex("vapor")
		vap.amount = 6
		vap.lifetime = 2.6
		vap.initial_velocity_min = 8.0
		vap.initial_velocity_max = 18.0
		vap.color = Color(0.85, 0.88, 0.95, 0.45)
		_things.add_child(vap)
		_poca_fx.append(vap)
		vap.emitting = not Efeitos.reduzidos()


## Bloco 72: o nível dessa poça tem água (poça "agua")?
func _tem_agua_perto(p: Node) -> bool:
	var n := Niveis.do_ponto(_env, (p as Node2D).global_position)
	return n != null and n.perigos.any(func(e): return e is Array and String(e[0]) == "agua")


# ------------------------------------------------------------ névoa do leste (Bloco 67)
var _nevoa_leste: Polygon2D


func _build_nevoa_leste() -> void:
	if not _env.has_method("has_leste") or not _env.has_leste():
		return
	var lr: Rect2 = _env.leste_rect()
	var pts := PackedVector2Array()
	for c in [lr.position, Vector2(lr.end.x, lr.position.y), lr.end, Vector2(lr.position.x, lr.end.y)]:
		pts.append(to_screen(c, 96.0))
	pts.append(to_screen(Vector2(lr.position.x, lr.end.y), -160.0))  # cobre o corte da frente também
	pts.append(to_screen(lr.end, -160.0))
	_nevoa_leste = Polygon2D.new()
	_nevoa_leste.name = "NevoaLeste"
	# (o polígono: topo do losango + a faixa do corte; Geometry pra juntar os dois)
	var topo := PackedVector2Array([pts[0], pts[1], pts[2], pts[3]])
	var corte := PackedVector2Array([pts[3], pts[2], pts[5], pts[4]])
	var uniao := Geometry2D.merge_polygons(topo, corte)
	_nevoa_leste.polygon = uniao[0] if not uniao.is_empty() else topo
	_nevoa_leste.color = Color(0.05, 0.05, 0.07, 0.86)
	_nevoa_leste.z_as_relative = false
	_nevoa_leste.z_index = 3800
	_things.add_child(_nevoa_leste)
	_nevoa_leste.visible = not _env.leste_aberto
	_terreno_leste_visivel(_env.leste_aberto)
	if _env.has_signal("leste_mudou") and not _env.leste_mudou.is_connected(_on_leste_mudou):
		_env.leste_mudou.connect(_on_leste_mudou)


## O terreno do leste (pedaços _lN; a moldura de trás fica) só aparece desbravado.
func _terreno_leste_visivel(on: bool) -> void:
	if _terrain_node == null:
		return
	for sp in _terrain_node.get_children():
		var nm := String(sp.name)
		if nm.begins_with("Terreno_") and nm.contains("_l") and not nm.begins_with("Terreno_moldura"):
			sp.visible = on


func _on_leste_mudou(aberto: bool) -> void:
	_terreno_leste_visivel(aberto)
	if _nevoa_leste == null:
		return
	if aberto:
		_nevoa_leste.visible = true
		var t := create_tween()
		t.tween_property(_nevoa_leste, "modulate:a", 0.0, 2.0)
		t.tween_callback(func(): _nevoa_leste.visible = false)
	else:
		_nevoa_leste.modulate.a = 1.0
		_nevoa_leste.visible = true


## A paliçada entre a floresta e a vila (Prompt 29 parte 2): um trecho do muro do Prompt 12 por
## tile, ao longo da linha da navegação (Environment.palisade_y), menos a abertura do portão.
## Cada trecho é uma caixa fina na ordem (como o terreno: não é coisa do jogo, não tem clique).
## Prompt 19: o terreno vem em imagens enormes (até 6.000 px) e o Godot só aplica um número
## limitado de luzes por item desenhado: numa imagem dessas, com várias tochas e janelas no
## alcance, parte das luzes era ignorada (a luz "cortava" na borda entre os pedaços de terreno).
## O pedaço continua sendo o nó do terreno (caixa, z, tons do céu e da geada), mas quem desenha
## são blocos de TERRAIN_BLOCK px (sem os vazios): cada bloco recebe só as luzes perto dele.
const TERRAIN_BLOCK := 256
var _blocados: Array = []  # [pedaço, [blocos]]: o tom (self_modulate) do pedaço vai pros blocos


func _em_blocos(sp: Sprite2D) -> void:
	var tex := sp.texture
	if tex == null:
		return
	var img := tex.get_image()
	var blocos: Array = []
	var w := tex.get_width()
	var h := tex.get_height()
	for y in range(0, h, TERRAIN_BLOCK):
		for x in range(0, w, TERRAIN_BLOCK):
			var r := Rect2i(x, y, mini(TERRAIN_BLOCK, w - x), mini(TERRAIN_BLOCK, h - y))
			if img and img.get_region(r).get_used_rect().size == Vector2i.ZERO:
				continue  # bloco vazio
			var b := Sprite2D.new()
			b.texture = tex
			b.region_enabled = true
			b.region_rect = Rect2(r)
			b.centered = false
			b.position = Vector2(x, y)
			b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			b.light_mask = sp.light_mask
			b.self_modulate = sp.self_modulate
			sp.add_child(b)
			blocos.append(b)
	sp.region_enabled = true
	sp.region_rect = Rect2()  # o pedaço em si não desenha mais (só os blocos)
	_blocados.append([sp, blocos])


## O tom do pedaço (céu na moldura, subsolo nos andares) vai pros blocos dele.
func _sync_blocos() -> void:
	for e in _blocados:
		var sp: Sprite2D = e[0]
		if e[1].is_empty() or not is_instance_valid(sp) or e[1][0].self_modulate == sp.self_modulate:
			continue
		for b in e[1]:
			b.self_modulate = sp.self_modulate


const HEAT_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
void fragment() {
	vec2 d = (UV - vec2(0.5, 0.8)) / vec2(0.5, 0.8);
	float m = clamp(1.0 - length(d), 0.0, 1.0);
	float w = floor(sin(UV.y * 48.0 - TIME * 5.0) * 2.0) / 2.0;
	vec2 off = vec2(w * 2.0 * m, 0.0) * SCREEN_PIXEL_SIZE;
	vec4 c = texture(screen_tex, SCREEN_UV + off);
	COLOR = vec4(c.rgb + vec3(0.06, 0.02, 0.0) * m, step(0.05, m));
}
"""


## Prompt 19: a luz da lava nas fendas de calor (abismo): brilho vermelho constante no chão.
func _build_lava() -> void:
	for z in get_tree().get_nodes_in_group("zonas_perigo"):
		if z.get("kind") != "calor":
			continue
		var l := PointLight2D.new()
		l.name = "Lava_" + String(z.name)
		IsoLuz.aplica(l, "lava")
		l.energy = IsoLuz.TIPOS.lava.forca
		l.range_item_cull_mask = LIGHT_ISO
		l.range_z_min = RenderingServer.CANVAS_ITEM_Z_MIN  # todo o z da ordem de desenho
		l.range_z_max = RenderingServer.CANVAS_ITEM_Z_MAX
		l.position = to_screen((z as Node2D).global_position)
		l.set_meta("tela_iso", true)  # Bloco 69: entra no corte das luzes fora da tela (já na tela)
		l.add_to_group("cullable_lights")
		_terrain_node.add_child(l)
		# Prompt 18: o ar tremendo em cima da fenda (lê a tela e entorta em degraus de pixel)
		var r: float = float(z.get("radius")) * S if z.get("radius") != null else 60.0
		var hz := ColorRect.new()
		hz.name = "Calor_" + String(z.name)
		hz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hz.size = Vector2(r * 2.0, r * 1.6)
		hz.position = l.position - Vector2(r, r * 1.3)
		hz.z_as_relative = false
		hz.z_index = 4000
		var mat := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = HEAT_SHADER
		mat.shader = sh
		hz.material = mat
		hz.visible = not preload("res://scripts/core/efeitos.gd").reduzidos()  # Bloco 54
		_terrain_node.add_child(hz)
		_calor_rects.append(hz)


## Bloco 54: "reduzir efeitos" esconde o ar tremendo do calor.
var _calor_rects: Array = []


func efeitos_mudaram() -> void:
	for hz in _calor_rects:
		if is_instance_valid(hz):
			hz.visible = not preload("res://scripts/core/efeitos.gd").reduzidos()
	atmosfera_aplica()  # Bloco 69


func _build_palisade() -> void:
	if IsoArt.entry("palicada").is_empty():
		return
	var g: Rect2 = _env.iso_ground_rect()
	var step := 32.0 / S  # 1 tile da arte
	var y: float = _env.palisade_y
	var gap: float = _env.gate_half_width + step * 0.5
	var n := 0
	var x := g.position.x + step * 0.5
	# Bloco 74: a paliçada de norte a sul (a peça virada de lado), do alto do mapa até o corte da frente
	var de_lado: bool = _env.has_method("vertical_palisade") and _env.vertical_palisade()
	var fim := g.end.y if de_lado else g.end.x
	if de_lado:
		x = g.position.y + step * 0.5
	while x < fim:
		var fora_do_portao: bool = absf(x - _env.gate_y) > gap if de_lado else absf(x) > gap
		if fora_do_portao:
			var l := IsoArt.state("palicada", "danificada" if n % 7 == 3 else "reta")
			if de_lado:
				l = IsoArt._de_lado(l)
			var ground := Vector2(_env.palisade_x, x) if de_lado else Vector2(x, y)
			var z := height_at(ground)
			var sp := Sprite2D.new()
			sp.name = "Palicada%d" % n
			sp.texture = l.tex
			sp.centered = false
			sp.offset = -l.ancora
			if l.get("flip", false):
				sp.flip_h = true
				sp.offset.x = l.ancora.x - l.tex.get_width()
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.light_mask = 2
			sp.position = Iso.iso(art(ground), z).round()
			_terrain_node.add_child(sp)
			var p: Array = l.peg
			var b := Iso.Box.new(Rect2(art(ground) + Vector2(p[0], p[1]), Vector2(p[2] - p[0], p[3] - p[1])), z, z + l.h,
				"predio", "palicada%d" % n, null)
			_terrain.append([b, sp])
		x += step
		n += 1

# ------------------------------------------------------------ quem é chão, quem fica em pé
## Chão de verdade: vai inteiro pra textura achatada (piso, paredes, pedrinhas: z <= -5).
func _is_ground(n: Node) -> bool:
	return n is CanvasItem and (n as CanvasItem).z_index <= -5 and not _is_mixed(n)


## Misto: a raiz é uma mancha no chão, mas tem coisa em pé por cima (texto, fumaça). A mancha
## fica na textura do chão; os filhos com z >= 0 ganham um espelho em pé.
func _is_mixed(n: Node) -> bool:
	return n.is_in_group("zonas_perigo")


func _is_dynamic(n: Node) -> bool:
	return n is CharacterBody2D or n.is_in_group("ipezinhos") or n.is_in_group("criaturas") or n.is_in_group("robos") or n.is_in_group("animais") \
		or n.is_in_group("vagonetes")


func _wants(n: Node) -> bool:
	if not (n is Node2D) or n == _env or n is NavigationRegion2D:
		return false
	if n.is_in_group("trilhos"):
		return false  # Bloco 64: desenhado à parte (_sync_trilhos), por baixo de tudo
	return not _is_ground(n)  # (os mistos também entram: só com a parte em pé)


func _scan_world() -> void:
	for n in _world.get_children():
		_add(n)
	for n in _env.get_children():
		_add(n)


func _on_world_child_added(n: Node) -> void:
	# entra no próximo quadro: o _ready dela (grupos, arte) ainda não rodou
	_add.call_deferred(n)
	_poca_add.call_deferred(n)  # Bloco 70: a luz e as bolhas da poça


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
	var regiao := "" if bb.dynamic else _regiao_de(n as Node2D)
	if regiao == "":
		_things.add_child(bb)
	else:
		_grupo(regiao).add_child(bb)
	_ents[n] = bb
	if bb.dynamic:
		_dinamicos.append(bb)
	else:
		_balde(bb).append(bb)
		_novas.append(bb)
	if not bb.dynamic and not _order.order.is_empty():
		_rajada[bb] = true  # construiu agora: encaixa no próximo quadro (sozinha, ou a rajada toda de uma vez)


func _balde(bb: Billboard) -> Array:
	if _baldes.size() != STATIC_SYNC_EVERY:
		_baldes = []
		for i in STATIC_SYNC_EVERY:
			_baldes.append([])
	return _baldes[bb.get_instance_id() % STATIC_SYNC_EVERY]


## Bloco 72: em que região fica uma fixa: o andar de baixo (nome da laje), "leste" ou "" (o resto).
func _regiao_de(n: Node2D) -> String:
	if _env == null:
		return ""
	if _env.has_method("level_of"):
		var lv: Dictionary = _env.level_of(n.global_position)
		if not lv.is_empty():
			return String(lv.nome)
	if _env.has_method("has_leste") and _env.has_leste() and n.global_position.x > _env.leste_x():
		return "leste"
	return ""


func _grupo(regiao: String) -> Node2D:
	var g: Node2D = _grupos.get(regiao)
	if g == null:
		g = Node2D.new()
		g.name = "Regiao_" + regiao
		_things.add_child(g)
		_grupos[regiao] = g
	return g


## O retângulo de uma região na tela (a laje do andar; o leste pelo chão dele).
func _tela_da_regiao(regiao: String) -> Rect2:
	if regiao == "leste":
		var lr: Rect2 = _env.leste_rect()
		var r := Rect2(to_screen(lr.position), Vector2.ZERO)
		for c in [Vector2(lr.end.x, lr.position.y), lr.end, Vector2(lr.position.x, lr.end.y)]:
			r = r.expand(to_screen(c))
		return r.grow(400.0)
	for lv in _levels:
		if lv.nome == regiao:
			return Rect2(lv.sprite.position, lv.sprite.texture.get_size()).grow(400.0)
	return Rect2()


func _sync_regioes(view: Rect2) -> void:
	if _frame % 5 != 0:
		return
	for regiao in _grupos:
		var g: Node2D = _grupos[regiao]
		if not g.has_meta("tela"):
			var r := _tela_da_regiao(regiao)
			if not r.has_area():
				continue
			g.set_meta("tela", r)
		var ve: bool = view.intersects(g.get_meta("tela"))
		if g.visible != ve:
			g.visible = ve


func _balde_da_vez() -> Array:
	if _baldes.size() != STATIC_SYNC_EVERY:
		return []
	return _baldes[_frame % STATIC_SYNC_EVERY]


func _drop(src: Node) -> void:
	var bb: Billboard = _ents.get(src)
	_ents.erase(src)
	if bb == null:
		return
	if bb.dynamic:
		_dinamicos.erase(bb)
	else:
		_balde(bb).erase(bb)
		_novas.erase(bb)
		_rajada.erase(bb)
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
	for t in _terrain:
		statics.append(t[0])
	_order.build(statics)
	_apply_static_z()


func _apply_static_z() -> void:
	for bb in _ents.values():
		if bb.dynamic:
			continue
		bb.z_index = _order.z_of_static(bb.box)
		if bb.boxes.size() > 1:
			bb.set_part_z(bb.boxes.map(func(b): return _order.z_of_static(b)))
	for t in _terrain:
		t[1].z_index = _order.z_of_static(t[0])


# ------------------------------------------------------------ a cada quadro
func _process(_delta: float) -> void:
	_frame += 1
	_sync_blocos()
	var stops: Array = _camera.zoom_stops() if _camera.has_method("zoom_stops") else []
	labels_on = stops.size() < 2 or _camera.zoom.x > float(stops[0]) + 0.001
	if not _levels.is_empty() and _ground_sv and _frame % GROUND_REFRESH_EVERY == 0:
		_ground_sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	var view := _screen_view().grow(256.0)
	var moved_static := false
	var dyn_boxes := []
	var dyn_bbs := {}
	var sumiram: Array = []
	for bb in _dinamicos:
		if not is_instance_valid(bb.src):
			sumiram.append(bb)
			continue
		bb.sync_dynamic(view)
		dyn_boxes.append(bb.box)
		dyn_bbs[bb.box] = bb
	# Bloco 72: as fixas do grupo da vez + as novas (antes: varria todas as entidades todo quadro)
	var fixas: Array = _balde_da_vez()
	if not _novas.is_empty():
		fixas = fixas + _novas
		_novas = []
	for bb in fixas:
		if not is_instance_valid(bb) or not is_instance_valid(bb.src):
			if is_instance_valid(bb):
				sumiram.append(bb)
			continue
		if bb.sync_static(view) and not _rajada.has(bb):
			for b in bb.boxes:
				_order.add_static(b)  # mudou de lugar/tamanho: re-encaixa só ela
			moved_static = true
	if not _rajada.is_empty():
		if _rajada.size() > RAJADA:
			_rebuild_order()
		else:
			for bb in _rajada:
				if is_instance_valid(bb):
					for b in bb.boxes:
						_order.add_static(b)
			moved_static = true
		_rajada = {}
	for bb in sumiram:
		for k in _ents.keys():
			if _ents[k] == bb:
				_drop(k)
				break
	_sync_regioes(view)  # Bloco 72
	if moved_static:
		_apply_static_z()
	else:
		_refresh_static_z_if_needed()
	# Prompt 30: com muita gente andando, a ordem de quem anda é refeita a cada 2 quadros (1 quadro de
	# atraso no "quem fica na frente" não se vê; com poucos, todo quadro)
	# (Bloco 72: com mais de 30 andando, a cada 3 quadros)
	if dyn_boxes.size() <= DYN_ORDER_EVERY_FRAME or _frame % (3 if dyn_boxes.size() > 30 else 2) == 0:
		var zs := _order.dynamic_z(dyn_boxes)
		if _order.dirty:  # conserto local na ordem das fixas: os z delas mudaram
			_order.dirty = false
			_apply_static_z()
			zs = _order.dynamic_z(dyn_boxes)
		for b in zs:
			dyn_bbs[b].z_index = zs[b]
	_sync_ghost()
	_sync_trilhos()
	_sync_areas()  # Bloco 77
	_pulsa_luzes()
	_overlay.queue_redraw()


# ------------------------------------------------------------ trilhos (Bloco 64)
## Cada trilho ganha um desenho no chão da vista (z logo acima do fundo da pedreira, abaixo das
## caixas): dois trilhos de ferro e dormentes de madeira, projetados no losango. Quebrado: vermelho.
var _rail_drawers := {}


func _sync_trilhos() -> void:
	if _frame % 10 != 0:
		return
	for r in get_tree().get_nodes_in_group("trilhos"):
		var d: Node2D = _rail_drawers.get(r)
		if d == null or not is_instance_valid(d):
			d = Node2D.new()
			d.name = "TrilhoIso"
			d.z_as_relative = false
			d.z_index = Order.BASE - 45
			_things.add_child(d)
			var rr: Node = r
			d.draw.connect(func(): _draw_rail(d, rr))
			d.set_meta("v", -1)
			_rail_drawers[r] = d
		if int(d.get_meta("v")) != int(r.version):
			d.set_meta("v", int(r.version))
			d.queue_redraw()
	for r in _rail_drawers.keys():
		if not is_instance_valid(r):
			if is_instance_valid(_rail_drawers[r]):
				_rail_drawers[r].queue_free()
			_rail_drawers.erase(r)


func _draw_rail(d: Node2D, r: Node) -> void:
	if not is_instance_valid(r) or r.points.size() < 2:
		return
	# Bloco 74: a bitola e os dormentes no CHÃO (projetados), não na tela — o trilho lê como trilho em
	# qualquer direção do losango; ferro de 2 px com brilho em cima, dormente de madeira grosso
	var ferro := Color(0.62, 0.3, 0.25) if r.broken else Color(0.46, 0.45, 0.44)
	var brilho := Color(0.8, 0.45, 0.38) if r.broken else Color(0.72, 0.7, 0.66)
	var madeira := Color(0.32, 0.21, 0.12)
	var madeira_luz := Color(0.45, 0.31, 0.18)
	const BITOLA := 5.0  # meia bitola (px da lógica)
	const PASSO := 7.0  # entre dormentes (px da lógica)
	var acc := 0.0
	for i in range(1, r.points.size()):
		var a: Vector2 = r.points[i - 1]
		var b: Vector2 = r.points[i]
		var L := a.distance_to(b)
		if L < 0.5:
			continue
		var dirv := (b - a) / L
		var n := dirv.orthogonal() * BITOLA
		var k := fposmod(-acc, PASSO)
		while k < L:
			var c := a + dirv * k
			var s0 := to_screen(c - n * 1.55)
			var s1 := to_screen(c + n * 1.55)
			d.draw_line(s0.round(), s1.round(), madeira, 3.0)
			d.draw_line((s0 + Vector2(0, -1)).round(), (s1 + Vector2(0, -1)).round(), madeira_luz, 1.0)
			k += PASSO
		acc += L
		for lado in [-1.0, 1.0]:
			var ra := to_screen(a + n * lado)
			var rb := to_screen(b + n * lado)
			d.draw_line(ra.round(), rb.round(), ferro, 2.0)
			d.draw_line((ra + Vector2(0, -1)).round(), (rb + Vector2(0, -1)).round(), brilho, 1.0)


# ------------------------------------------------------------ áreas de trabalho (Bloco 77)
## Cada área: o chão dela tingido na cor do tipo e o contorno, no CHÃO (z dos trilhos: debaixo das árvores,
## que continuam por cima); o rótulo ("Madeira 1 · 3/5 · Trabalhando") e o contorno da área destacada vão
## por cima de tudo (overlay). O retângulo é da lógica: o tingido é feito em ladrilhos de 20 px, cada um
## na altura do chão dele (a área pode subir um terraço sem desenhar polígono torto).
var _areas_drawer: Node2D
var _areas_sel = null


func _work_areas() -> Node:
	return get_tree().get_first_node_in_group("work_areas")


func _sync_areas() -> void:
	if _areas_drawer == null:
		_areas_drawer = Node2D.new()
		_areas_drawer.name = "AreasTrabalhoIso"
		_areas_drawer.z_as_relative = false
		_areas_drawer.z_index = Order.BASE - 44
		_things.add_child(_areas_drawer)
		_areas_drawer.draw.connect(_draw_areas_chao)
	if _frame % 12 == 0:
		_areas_drawer.queue_redraw()


func _area_borda(r: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cantos := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		var a: Vector2 = cantos[i]
		var b: Vector2 = cantos[i + 1]
		var n := maxi(int(a.distance_to(b) / 16.0), 1)
		for k in n:
			pts.append(to_screen(a.lerp(b, float(k) / n)))
	pts.append(pts[0])
	return pts


func _draw_area_tinta(d: Node2D, r: Rect2, col: Color) -> void:
	const L := 20.0
	var y := r.position.y
	while y < r.end.y - 0.1:
		var y1 := minf(y + L, r.end.y)
		var x := r.position.x
		while x < r.end.x - 0.1:
			var x1 := minf(x + L, r.end.x)
			var h := height_at(Vector2((x + x1) * 0.5, (y + y1) * 0.5))
			d.draw_colored_polygon(PackedVector2Array([to_screen(Vector2(x, y), h), to_screen(Vector2(x1, y), h),
				to_screen(Vector2(x1, y1), h), to_screen(Vector2(x, y1), h)]), col)
			x = x1
		y = y1


func _draw_areas_chao() -> void:
	_draw_lotes(_areas_drawer)  # Bloco 76
	var wa := _work_areas()
	if wa == null:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	var panel = hud._panels.get("trabalho") if hud and hud.get("_panels") is Dictionary else null
	_areas_sel = panel.selected_area() if panel and panel.visible else null
	for a in wa.areas:
		var col: Color = a.info().cor
		var on: bool = wa.funcionando(a)
		_draw_area_tinta(_areas_drawer, a.rect, Color(col, 0.24 if a == _areas_sel else 0.15))
		_areas_drawer.draw_polyline(_area_borda(a.rect), Color(col, 0.95 if on else 0.65), 2.5)


## Bloco 76: os LOTES LIVRES (environment.lotes_livres): estacas nos cantos e no meio dos lados com uma corda
## caída entre elas, como na maquete. Escolhendo onde construir, o chão do lote acende de leve.
func _draw_lotes(d: Node2D) -> void:
	if not _env.has_method("lotes_livres"):
		return
	var escolhendo: bool = _placer != null and _placer.active
	var madeira := Color(0.3, 0.2, 0.12)
	var madeira_luz := Color(0.5, 0.36, 0.22)
	var corda := Color(0.78, 0.68, 0.46) if not escolhendo else Color(0.95, 0.88, 0.55)
	for r in _env.lotes_livres():
		var cantos := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		var pol := PackedVector2Array()
		for c in cantos:
			pol.append(to_screen(c))
		# o chão do lote: terra preparada (escolhendo onde construir: acende de verde)
		d.draw_colored_polygon(pol, Color(0.6, 1.0, 0.55, 0.13) if escolhendo else Color(0.62, 0.5, 0.34, 0.12))
		var estacas := []
		for i in 4:
			estacas.append(cantos[i])
			estacas.append((cantos[i] + cantos[(i + 1) % 4]) * 0.5)
		const ALTO := 11.0
		for i in estacas.size():
			var a: Vector2 = to_screen(estacas[i])
			var b: Vector2 = to_screen(estacas[(i + 1) % estacas.size()])
			var pts := PackedVector2Array()
			for k in 9:  # a corda caindo no meio (2,5 px)
				var t := k / 8.0
				pts.append((a.lerp(b, t) + Vector2(0, -ALTO + 2.0 + 2.5 * sin(PI * t))).round())
			d.draw_polyline(pts, corda, 1.5)
		for e in estacas:
			var p: Vector2 = to_screen(e).round()
			d.draw_line(p, p + Vector2(0, -ALTO - 2.0), madeira, 2.0)
			d.draw_line(p + Vector2(0, -ALTO - 2.0), p + Vector2(0, -ALTO), madeira_luz, 2.0)


func _draw_areas_overlay() -> void:
	var wa := _work_areas()
	if wa == null:
		return
	var font := ThemeDB.fallback_font
	for a in wa.areas:
		var borda := _area_borda(a.rect)
		if a == _areas_sel:
			_overlay.draw_polyline(borda, Color(a.info().cor, 0.95), 2.5)
		# o rótulo no MEIO da área (de onde se olha pra ela ele está na tela), numa plaquinha escura
		var est: String = wa.estado(a)
		var txt := "%s  %d/%d  ·  %s" % [a.nome(), a.quantos(), a.capacidade, est]
		var tam := 15
		var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
		var c := to_screen(a.centro())
		var placa := Rect2(c - Vector2(sz.x * 0.5 + 8.0, sz.y * 0.5 + 3.0), sz + Vector2(16.0, 6.0))
		_overlay.draw_rect(placa, Color(0.08, 0.06, 0.05, 0.72), true)
		_overlay.draw_rect(placa, Color(a.info().cor, 0.9), false, 1.5)
		var pos := (c + Vector2(-sz.x * 0.5, font.get_ascent(tam) - sz.y * 0.5)).round()
		var cor := Color(0.75, 1.0, 0.7) if wa.funcionando(a) else Color(1.0, 0.8, 0.55)
		_overlay.draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
	# a área sendo marcada
	var ap := get_tree().get_first_node_in_group("area_placer")
	if ap and ap.active and ap.arrastando:
		var r: Rect2 = ap.rect()
		if r.size.x > 1.0 and r.size.y > 1.0:
			var col := Color(1.0, 0.4, 0.35) if ap.reason != "" else Color(0.5, 1.0, 0.55)
			_draw_area_tinta(_overlay, r, Color(col, 0.18))
			_overlay.draw_polyline(_area_borda(r), Color(col, 0.95), 2.0)


# ------------------------------------------------------------ fantasma do posicionador
## Mapa novo: a pegada (verde/vermelha) e o raio das casas, na altura do terraço (a textura
## antiga do chão da superfície não aparece mais).
func _draw_placer() -> void:
	var fp := Rect2(_placer._pos + _placer._footprint.position, _placer._footprint.size)
	var col: Color = _placer.COLOR_OK if _placer._reason == "" else _placer.COLOR_BAD
	var h := height_at(_placer._pos)
	var pts := PackedVector2Array()
	for c in [fp.position, Vector2(fp.end.x, fp.position.y), fp.end, Vector2(fp.position.x, fp.end.y)]:
		pts.append(to_screen(c, h))
	_overlay.draw_colored_polygon(pts, Color(col, 0.16))
	var closed := pts.duplicate()
	closed.append(pts[0])
	_overlay.draw_polyline(closed, Color(col, 0.9), 1.5)
	var mark := IsoFx.tex("obra_ok" if _placer._reason == "" else "obra_x")  # Prompt 18: pode / não pode
	if mark:
		var top := Vector2(INF, INF)
		for p in pts:
			top = p if p.y < top.y else top
		_overlay.draw_texture(mark, (top + Vector2(-mark.get_width() * 0.5, -mark.get_height() - 6.0)).round())
	if _placer._radius > 0.0:
		var c0: Vector2 = _placer._radius_center
		var hc := height_at(c0)
		var n := 72
		for i in n:
			if i % 2 == 0:
				var a0 := to_screen(c0 + Vector2.RIGHT.rotated(TAU * i / n) * _placer._radius, hc)
				var a1 := to_screen(c0 + Vector2.RIGHT.rotated(TAU * (i + 1) / n) * _placer._radius, hc)
				_overlay.draw_line(a0, a1, Color(1.0, 0.88, 0.5, 0.85), 2.0)


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
	var art: Dictionary = IsoArt.preview(_placer.art_name) if _placer.get("art_name") else {}
	if not art.is_empty():  # Prompt 29: o fantasma é o desenho novo, na âncora dele
		_ghost_bb.texture = art.tex
		_ghost_bb.hframes = 1
		_ghost_bb.vframes = 1
		_ghost_bb.frame = 0
		_ghost_bb.centered = false
		_ghost_bb.offset = -art.ancora
		_ghost_bb.scale = Vector2.ONE
	else:
		_ghost_bb.texture = g.texture
		_ghost_bb.hframes = g.hframes
		_ghost_bb.vframes = g.vframes
		_ghost_bb.frame = g.frame
		_ghost_bb.centered = true
		_ghost_bb.offset = g.offset
		_ghost_bb.scale = g.scale * S
	_ghost_bb.modulate = g.modulate
	_ghost_bb.position = to_screen(_placer._pos).round()


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
	var r := Rect2(Iso.iso_inv(v.position) / S, Vector2.ZERO)
	for c in [Vector2(v.end.x, v.position.y), v.end, Vector2(v.position.x, v.end.y)]:
		r = r.expand(Iso.iso_inv(c) / S)
	return r


# ------------------------------------------------------------ chão <-> tela
## Chão do mundo -> canvas iso (z em px de arte; sem z = no nível do relevo ali).
func to_screen(ground: Vector2, z: float = NAN) -> Vector2:
	return Iso.iso(art(ground), height_at(ground) if is_nan(z) else z)


## Ponto da lógica -> chão da vista em px de arte (escala 1,5; os andares de baixo vão pra
## laje deles, empilhada embaixo da superfície).
func art(ground: Vector2) -> Vector2:
	if _env.has_method("view_ground") and _env.has_iso_map():
		return _env.view_ground(ground)
	return ground * S


## Retângulo da lógica -> retângulo na vista (px de arte).
func art_rect(r: Rect2) -> Rect2:
	return Rect2(art(r.position), r.size * S)


## Chão da vista (px de arte) numa altura -> lógica.
func logic_of(art_pos: Vector2, z: float) -> Vector2:
	if _env.has_method("logic_from_view") and _env.has_iso_map():
		return _env.logic_from_view(art_pos, z)
	return art_pos / S


## Canvas iso -> chão do mundo, no plano z = 0 (sem olhar o que está em cima).
func to_ground_plane(canvas_pos: Vector2) -> Vector2:
	return Iso.iso_inv(canvas_pos, 0.0) / S


## O RAIO DA CÂMERA no ponto do canvas: {what, node, ground, z, face}. node = a coisa em pé
## acertada (ipezinho, prédio, jazida...) ou null (chão). Clique em FACE (parede/lado de um
## prédio): ground = o pé da parede, e face = true (construir ali não pode).
func pick(canvas_pos: Vector2) -> Dictionary:
	var solids := []
	for bb in _ents.values():
		if bb.visible_src() and bb.pickable:
			solids.append_array(bb.boxes)
	for t in _terrain:
		if t[0].kind == "predio":
			continue  # paliçada: enfeite fino, o clique passa pro chão
		solids.append(t[0])  # terraço/escada: acerta o chão de cima (ou a parede do penhasco)
	var wr: Rect2 = _env.iso_ground_rect() if _env.has_method("has_iso_map") and _env.has_iso_map() else _env.world_rect()
	var planes := [{"rect": Rect2(wr.position * S, wr.size * S), "z": 0.0, "name": "chão"}]
	for lv in _levels:  # o chão de cada andar de baixo, na laje dele
		planes.append({"rect": lv.art_rect, "z": lv.z, "name": lv.nome})
	var hit := Iso.pick(canvas_pos, solids, planes)
	var gz: float = hit.get("z", 0.0)
	var out := {"what": hit.what, "node": null, "z": gz, "face": hit.what == "face",
		"ground": logic_of(hit.get("ground", Iso.iso_inv(canvas_pos, 0.0)), gz)}
	if hit.has("box"):
		out.node = hit.box.owner
	return out


## O ponto do chão que se vê nesse ponto do canvas (o raio acerta o terraço, a escada, o
## chão do fundo). A câmera usa pra saber pra onde está olhando.
func ground_under(canvas_pos: Vector2) -> Vector2:
	return pick(canvas_pos).ground


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


## Tom do andar onde fica esse ponto (branco na superfície).
func level_tint(ground: Vector2) -> Color:
	for lv in _levels:
		if lv.rect.grow(48.0).has_point(ground):
			return lv.tint
	return Color.WHITE


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
		var c := to_screen(_main._marker_pos)
		var mk := IsoFx.tex("marcador_destino")
		if mk:  # Prompt 18: o anel encolhendo e a setinha descendo (6 quadros)
			var fw := mk.get_width() / 6.0
			var fi := clampi(int((1.0 - t) * 6.0), 0, 5)
			_overlay.draw_texture_rect_region(mk, Rect2((c - Vector2(fw * 0.5, mk.get_height() - 11.0)).round(), Vector2(fw, mk.get_height())),
				Rect2(fi * fw, 0, fw, mk.get_height()), Color(1, 1, 1, clampf(t * 2.5, 0.0, 1.0)))
		else:
			_overlay.draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
			_overlay.draw_arc(Vector2.ZERO, lerpf(18.0, 6.0, t) * 1.41 * S, 0.0, TAU, 24, Color(1.0, 0.84, 0.25, t), 2.0)
			_overlay.draw_set_transform(Vector2.ZERO)
	if _placer and _placer.active and _placer.visible and not _levels.is_empty():
		_draw_placer()
	_draw_areas_overlay()  # Bloco 77
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
