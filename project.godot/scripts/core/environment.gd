extends Node2D
## Monta a caverna: chão, parede de rocha em volta, pedras, cristais, tochas
## (com luz tremulando) e escoras de madeira. A distribuição é sorteada a partir
## de `map_seed`, então o mapa é sempre igual até você trocar a seed.
##
## Depois de posicionar tudo, "assa" a malha de navegação (NavigationRegion2D):
## a borda do mapa, as pedras grandes, os cristais, as tochas e a base de cada
## estação viram obstáculos que os ipezinhos contornam.
##
## Também desliga as luzes que estão fora da câmera (grupo "cullable_lights").

signal navigation_ready

## Grupos de estruturas que bloqueiam a navegação e afastam a decoração.
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const STATION_GROUPS := ["minerios", "comedouros", "armazens", "casas", "village_hub", "escavadeira", "oficina", "coleta_comida", "arvores"]
## Estruturas que bloqueiam a navegação mas NÃO entram no sorteio da decoração
## (pra não mudar as pedras/cristais da mina de saves antigos). A decoração que
## cair embaixo delas é escondida depois (_clear_decor_under_extras).
const NAV_EXTRA_GROUPS := ["enfermarias", "tavernas", "campos", "laboratorios", "escudos", "caca", "canteiros", "arsenais", "parques", "vestiarios", "coletores"]

@export_group("Mapa")
@export var map_rect: Rect2 = Rect2(-720, -440, 1440, 880)
@export var map_seed: int = 1337
## Escala dos pixels (os personagens usam 2x).
@export var pixel_scale: float = 2.0
@export var floor_texture: Texture2D
@export var wall_texture: Texture2D

@export_group("Clareira (superfície)")
## Área a céu aberto ao norte da mina, onde ficam as árvores (madeira).
@export var clearing_rect: Rect2 = Rect2(-300, -900, 600, 420)
## Túnel que liga a borda de cima da mina à clareira (centro x e largura).
@export var tunnel_x: float = 0.0
@export var tunnel_width: float = 88.0
@export var clearing_floor_texture: Texture2D
## Árvores de enfeite na borda da clareira (usa o quadro 0 da árvore).
@export var clearing_tree_texture: Texture2D
@export var clearing_tree_count: int = 16
## Luz do sol na clareira (some à noite, junto com a escuridão do DayNight).
@export var sun_color: Color = Color(1.0, 0.92, 0.72)
@export var sun_energy: float = 0.9

@export_group("Nível 2 (fundo)")
## Área do nível 2, abaixo (ao sul) da mina; a descida é o elevador da escavadeira.
@export var deep_rect: Rect2 = Rect2(-560, 700, 1120, 620)
@export var deep_floor_texture: Texture2D
## Chance de acidente multiplicada por isso minerando no nível 2 (acumula com a zanga).
@export var deep_injury_mult: float = 2.5
@export var deep_boulder_count: int = 12
@export var deep_crystal_count: int = 7
@export var deep_pebble_count: int = 40
## Tom da decoração do fundo (mais escuro e frio que a mina).
@export var deep_tint: Color = Color(0.7, 0.72, 0.88)

@export_group("Nível 3 (abismo)")
## Área do nível 3, abaixo do nível 2; a descida é a plataforma do abismo (conserto).
@export var abyss_rect: Rect2 = Rect2(-480, 1420, 960, 560)
@export var abyss_floor_texture: Texture2D
## Chance de acidente multiplicada por isso minerando no abismo (no lugar da do nível 2).
@export var abyss_injury_mult: float = 4.0
@export var abyss_boulder_count: int = 10
@export var abyss_pebble_count: int = 34
## Tom da decoração do abismo (escuro e avermelhado).
@export var abyss_tint: Color = Color(0.72, 0.52, 0.48)

@export_group("Decoração")
@export var boulder_count: int = 14
@export var pebble_count: int = 70
@export var crystal_count: int = 7
@export var torch_count: int = 10
## Espaço entre as pedras grandes que contornam a borda do mapa.
@export var edge_boulder_spacing: float = 44.0
## Distância livre ao redor das estações (minério, comedouro, armazém).
@export var keep_clear_radius: float = 70.0
@export var boulder_textures: Array[Texture2D] = []
@export var pebble_textures: Array[Texture2D] = []
@export var crystal_textures: Array[Texture2D] = []
## Tocha acesa (a chama é desenhada por cima da apagada e some de dia).
@export var torch_texture: Texture2D
## Tocha apagada (base). Sem ela, a tocha fica sempre com a chama.
@export var torch_unlit_texture: Texture2D
@export var support_texture: Texture2D
## Sombra projetada no chão (elipse com borda em xadrez) posta sob pedras, cristais, tochas e escoras.
@export var shadow_texture: Texture2D

@export_group("Navegação")
## Raio usado pra afastar o caminho das paredes/obstáculos (≈ raio do ipezinho).
@export var nav_agent_radius: float = 7.0
## Quanto a área andável fica pra dentro da borda do mapa (cobre a base das pedras da borda).
@export var nav_edge_inset: float = 36.0
## Pedras e cristais bloqueiam a passagem.
@export var decorations_block: bool = true

@export_group("Luz")
@export var light_texture: Texture2D
@export var torch_light_color: Color = Color(1.0, 0.6, 0.26)
@export var torch_light_energy: float = 1.25
@export var torch_light_scale: float = 1.4
@export var crystal_light_color: Color = Color(0.45, 0.75, 1.0)
@export var crystal_light_energy: float = 0.7
@export var flicker_amount: float = 0.15
## Liga/desliga luzes conforme estejam perto da área visível da câmera.
@export var cull_lights: bool = true
## Folga (px do mundo) além da tela antes de desligar uma luz — ~ raio da luz.
@export var light_cull_margin: float = 260.0
@export var light_cull_interval: float = 0.2

@export_group("Mapa isométrico (Prompt 29)")
## O terreno novo (floresta, paliçada, vila em terraços, mina): o mapa.json exportado por
## prototipos/camera/arte_iso/mapa/monta.py (`python monta.py exporta`). Vazio = o mapa antigo
## (caverna plana). Com ele: altura por ponto do chão (escadas = rampa), penhasco bloqueia a
## navegação, escada passa; construir só em chão plano.
@export_file("*.json") var iso_map_file: String = ""
## Paliçada entre a floresta e a vila: y da linha e meia largura da abertura do portão.
@export var palisade_y: float = -462.0
@export var gate_half_width: float = 40.0
## Espessura (px do mundo) da "parede" que a navegação vê na beira de um penhasco.
@export var cliff_thickness: float = 6.0

var navigation_region: NavigationRegion2D
## mapa.json (vazio = mapa antigo)
var iso_map: Dictionary = {}
var _alt_rows: PackedStringArray = PackedStringArray()
var _stair_tiles := {}  # Vector2i -> true
## Prompt 29: os andares de baixo empilhados na vista (andares.json): nome -> {rect, z_chao, ...}
var andares: Dictionary = {}
## Coisas que estavam em lugar inválido no mapa novo e foram mudadas de lugar: [{nome, de, para}]
var migrated: Array = []

var _rng := RandomNumberGenerator.new()
var _placed: Array[Vector2] = []
var _obstacles: Array[PackedVector2Array] = []
var _torch_lights: Array[PointLight2D] = []
var _torch_flames: Array[Sprite2D] = []
var _sun: PointLight2D
var _day_night: Node = null
var _time: float = 0.0
var _cull_timer: float = 0.0


func _ready() -> void:
	add_to_group("environment")
	_rng.seed = map_seed
	_load_iso_map()
	if not has_iso_map():
		_build_ground()  # mapa novo: o chão é o terreno isométrico (vista iso)
	# as estações são irmãs deste nó; espera um frame pra elas entrarem nos grupos
	await get_tree().process_frame
	if has_iso_map():
		migrate_positions()  # o que caiu em penhasco/escada/paliçada vai pro lugar válido mais perto
	else:
		_build_edges()
	_build_ligacoes()  # Bloco 71: as plataformas dos níveis novos (S4, S5), dos dados
	_build_conteudo_niveis()  # Bloco 70: poças e jazidas dos dados (antes da decoração: ela desvia)
	_scatter(pebble_count, pebble_textures, 10.0, 0.4, _add_pebble)
	_scatter(boulder_count, boulder_textures, 40.0, 1.0, _add_boulder)
	_scatter(crystal_count, crystal_textures, 50.0, 1.0, _add_crystal)
	_scatter(torch_count, [torch_texture], 60.0, 0.6, _add_torch)
	_build_clearing()  # depois de toda a decoração da mina: tem sorteio próprio
	_build_deep()
	_build_abyss()  # sorteio próprio também
	if has_iso_map():
		_build_map_decor()  # Prompt 30: a decoração da montagem aprovada
		_build_leste()  # Bloco 67: o conteúdo da área nova (trancada até desbravar)
		_build_decoracao_niveis()  # Bloco 69: a decoração declarada em cada nível (data/niveis)
	clear_decor_under_extras()
	_build_navigation()


# ------------------------------------------------------------ o leste (Bloco 67)
## O mapa cresceu pro leste (monta.py: LESTE_EXTRA). A área nova começa TRANCADA (névoa na vista,
## parede na navegação): "Desbravar o leste" no Centro da Vila (obra do engenheiro) abre. Lá:
## floresta (árvores, toca), encosta rochosa e a pedreira nova com mais jazidas. Os nós de lá
## existem desde o começo (nomes fixos: o save acha cada um pelo nome), só não dá pra chegar.
signal leste_mudou(aberto: bool)
var leste_aberto := false
const LESTE_JAZIDAS := [["ferro", Vector2(1000, 160)], ["cobre", Vector2(1400, 300)], ["carvao", Vector2(1820, 120)],
	["prata", Vector2(2260, 320)], ["ferro", Vector2(2700, 180)], ["cobre", Vector2(3100, 330)], ["carvao", Vector2(3420, 200)]]
const LESTE_ARVORES := 14
## Itens de arte do documento: a VILA ANTIGA do leste (decoração, de antes da explosão) — igreja, torre
## do relógio e casas enxaimel; cada uma no chão plano mais perto do ponto, longe das jazidas.
const LESTE_VILA := [["igreja_0", Vector2(2440, -40), Vector2(50, 30)], ["torre_0", Vector2(2620, -120), Vector2(22, 14)],
	["enxaimel_0", Vector2(2250, 60), Vector2(30, 18)], ["enxaimel_1", Vector2(2600, 60), Vector2(30, 18)],
	["enxaimel_2", Vector2(2800, -40), Vector2(30, 18)]]
const LESTE_DECOR := 70


## Onde começa a área nova (x da lógica); INF = mapa sem leste.
func leste_x() -> float:
	return float(iso_map.get("leste_x", INF)) if has_iso_map() else INF


func has_leste() -> bool:
	return leste_x() < iso_ground_rect().end.x - 16.0


## A área nova inteira (floresta + encosta + pedreira) na lógica.
func leste_rect() -> Rect2:
	if not has_leste():
		return Rect2()
	var g := iso_ground_rect()
	return Rect2(leste_x(), g.position.y, g.end.x - leste_x(), g.size.y)


## Bloco 71: a ligação de cada nível novo que ainda não está na cena — a mesma plataforma do abismo
## (arruinada até consertar), com o grupo, os textos e o conserto vindos do .tres.
func _build_ligacoes() -> void:
	var world := get_parent()
	for n in niveis_extra():
		if n.ligacao == "" or get_tree().get_first_node_in_group(n.ligacao) != null:
			continue
		var e: Node2D = preload("res://scenes/props/elevador_abismo.tscn").instantiate()
		e.name = "Elevador%s" % n.id
		e.grupo = n.ligacao
		e.nivel_id = n.id
		e.requer_grupo = n.ligacao_acima
		e.position = n.ligacao_topo
		e.bottom_position = n.ligacao_fundo
		e.repair_credits = n.conserto.x
		e.repair_parts = n.conserto.y
		e.repair_silver = n.conserto.z
		e.repair_time = float(n.conserto.w)
		e.repair_ore = n.conserto_minerio
		e.repair_min_stage = n.conserto_estagio
		world.add_child(e)


## Bloco 70: o conteúdo de jogo declarado em cada nível — poças de perigo e jazidas novas (nomes
## fixos: o save das jazidas é pelo nome).
func _build_conteudo_niveis() -> void:
	var world := get_parent()
	var ms := preload("res://scenes/props/mineral_node.tscn")
	var Poca := preload("res://scripts/props/poca_perigo.gd")
	for n in preload("res://scripts/core/niveis.gd").todos():
		if n.em_breve:
			continue
		for i in n.perigos.size():
			var d = n.perigos[i]
			if not (d is Array) or d.size() < 3 or world.has_node("Poca%s_%d" % [n.id, i + 1]):
				continue
			var p: Node2D = Poca.new()
			p.name = "Poca%s_%d" % [n.id, i + 1]
			p.kind = String(d[0])
			p.position = Vector2(float(d[1]), float(d[2]))
			if d.size() >= 4:
				p.radius = float(d[3])
			world.add_child(p)
		for i in n.jazidas.size():
			var d = n.jazidas[i]
			var nome := "Jazida%s_%d" % [n.id, i + 1]
			if not (d is Array) or d.size() < 3 or world.has_node(nome):
				continue
			var m: Node2D = ms.instantiate()
			m.name = nome
			m.ore_type = String(d[0])
			m.position = Vector2(float(d[1]), float(d[2]))
			if d.size() >= 6:
				m.ore_total = float(d[3])
				m.MINE_RATE = float(d[4])
				m.regen_rate = float(d[5])
			world.add_child(m)


## Bloco 69: decoração por dados — cada NivelMina declara [prop, x, y]; aqui vira um Deco no lugar.
func _build_decoracao_niveis() -> void:
	# nos andares de baixo o chão não é o dos ladrilhos da superfície: vale a regra da decoração de lá
	var placed: Array[Vector2] = []
	var avoid: Array[Vector2] = []
	for grupo in ["elevador", "elevador_abismo"]:
		var sh := get_tree().get_first_node_in_group(grupo)
		if sh and sh.get("bottom_position") != null:
			avoid.append(sh.bottom_position)
	for n in preload("res://scripts/core/niveis.gd").todos():
		if n.em_breve:
			continue
		for d in n.decoracao:
			if not (d is Array) or d.size() < 3:
				continue
			var p := Vector2(float(d[1]), float(d[2]))
			if String(d[0]).begins_with("fx:"):  # Bloco 71: cenário animado (a cachoeira): fixo, sem sorteio de lugar
				var fx := Node2D.new()
				fx.name = "Fx_%s_%d" % [String(d[0]).trim_prefix("fx:"), get_child_count()]
				fx.position = p
				fx.set_meta("iso_fx", String(d[0]).trim_prefix("fx:"))
				add_child(fx)
				fx.add_to_group("nivel_deco")
				continue
			var fixo: bool = d.size() >= 4 and d[3] == true  # [prop, x, y, true]: lugar escolhido (ponte, píer)
			var livre := fixo or (_deep_spot_free(p, 40.0, placed, avoid) if not level_of(p).is_empty() else _is_free(p, 18.0, 24.0))
			if not livre:
				continue
			placed.append(p)
			_decor_node(String(d[0]), p, false)
			get_child(get_child_count() - 1).add_to_group("nivel_deco")


## Esse ponto fica na área do leste ainda trancada?
func trancado(pos: Vector2) -> bool:
	return not leste_aberto and has_leste() and pos.x > leste_x()


func set_leste_aberto(on: bool, animate := true) -> void:
	if on == leste_aberto or not has_leste():
		leste_aberto = on and has_leste()
		return
	leste_aberto = on
	var lr := leste_rect()
	if on:
		map_rect = Rect2(map_rect.position, Vector2(lr.end.x - map_rect.position.x, map_rect.size.y))
		clearing_rect = Rect2(clearing_rect.position, Vector2(lr.end.x - clearing_rect.position.x, clearing_rect.size.y))
	rebuild_navigation()
	_mostra_leste()
	leste_mudou.emit(on)


func _build_leste() -> void:
	if not has_leste():
		return
	var world := get_parent()
	var lr := leste_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed + 67
	var ms := preload("res://scenes/props/mineral_node.tscn")
	for k in LESTE_JAZIDAS.size():
		var nome := "JazidaLeste%d" % (k + 1)
		if world.has_node(nome):
			continue
		var m: Node2D = ms.instantiate()
		m.name = nome
		m.ore_type = LESTE_JAZIDAS[k][0]
		m.position = nearest_ok(LESTE_JAZIDAS[k][1], 20.0)
		m.add_to_group("leste_conteudo")
		world.add_child(m)
	for k in LESTE_VILA.size():  # (antes das árvores: as casas ficam com o lugar)
		var nome := "VilaAntiga%d" % (k + 1)
		if has_node(nome):
			continue
		var pv := nearest_ok(LESTE_VILA[k][1], 46.0)
		var perto_jazida := get_tree().get_nodes_in_group("minerios").any(func(m): return (m as Node2D).global_position.distance_to(pv) < 110.0)
		if perto_jazida:
			continue
		_decor_node(String(LESTE_VILA[k][0]), pv, false)
		_add_obstacle(pv + Vector2(0, -8), LESTE_VILA[k][2])  # a pegada do prédio não anda
		var casa := get_child(get_child_count() - 1)
		casa.name = nome
		casa.add_to_group("leste_conteudo")
	var arv := preload("res://scenes/props/arvore.tscn")
	var postas := 0
	for tries in 600:
		if postas >= LESTE_ARVORES:
			break
		var p := Vector2(rng.randf_range(lr.position.x + 60.0, lr.end.x - 60.0), rng.randf_range(lr.position.y + 40.0, palisade_y - 60.0))
		if not spot_ok(p, 14.0) or not _is_free(p, 50.0, 40.0):
			continue
		var t: Node2D = arv.instantiate()
		t.name = "ArvoreLeste%d" % (postas + 1)
		t.position = p
		t.add_to_group("leste_conteudo")
		world.add_child(t)
		postas += 1
	if not world.has_node("TocaLeste"):
		var toca: Node2D = preload("res://scenes/props/toca.tscn").instantiate()
		toca.name = "TocaLeste"
		toca.position = nearest_ok(Vector2(lr.position.x + lr.size.x * 0.45, lr.position.y + 260.0), 20.0)
		toca.add_to_group("leste_conteudo")
		world.add_child(toca)
	# enfeite: mata na floresta nova e pedras na encosta rochosa
	var colocados := 0
	for tries in 3000:
		if colocados >= LESTE_DECOR:
			break
		var p := Vector2(rng.randf_range(lr.position.x + 20.0, lr.end.x - 20.0), rng.randf_range(lr.position.y + 20.0, lr.end.y - 20.0))
		if not spot_ok(p, 8.0) or not _is_free(p, 18.0, 30.0):
			continue
		var prop: String = FOREST_DECOR[rng.randi() % FOREST_DECOR.size()] if p.y < palisade_y else \
			("rocha_musgo_%d" % (rng.randi() % 6) if p.y < -180.0 else "rocha_mina_%d" % (rng.randi() % 3))
		_decor_node(prop, p, p.y >= palisade_y and rng.randf() < 0.3)
		get_child(get_child_count() - 1).add_to_group("leste_conteudo")
		colocados += 1
	_mostra_leste()


## Bloco 53/67: trancado, o leste fica invisível embaixo da névoa (não custa desenho); abre e aparece.
func _mostra_leste() -> void:
	for n in get_tree().get_nodes_in_group("leste_conteudo"):
		(n as CanvasItem).visible = leste_aberto
		n.set_process(leste_aberto)  # trancado: nem processa (jazida/árvore/toca paradas embaixo da névoa)
	for a in get_tree().get_nodes_in_group("animais"):
		if a.get("toca") != null and is_instance_valid(a.toca) and a.toca.is_in_group("leste_conteudo"):
			a.visible = leste_aberto
			a.set_process(leste_aberto)


func _process(delta: float) -> void:
	_time += delta
	# tochas acendem/apagam com a escuridão do DayNight (fade suave)
	var level := _torch_level()
	if _sun and _day_night:
		_sun.energy = sun_energy * (1.0 - _day_night.darkness())
	for flame in _torch_flames:
		flame.modulate.a = level
	for i in _torch_lights.size():
		var light := _torch_lights[i]
		light.enabled = level > 0.005
		if not light.visible or not light.enabled:
			continue
		var f := sin(_time * 9.0 + i * 1.7) * 0.5 + sin(_time * 23.0 + i * 3.1) * 0.5
		light.energy = torch_light_energy * level * (1.0 + f * flicker_amount)

	if cull_lights:
		_cull_timer -= delta
		if _cull_timer <= 0.0:
			_cull_timer = light_cull_interval
			_cull_offscreen_lights()


# ------------------------------------------------------------ performance: luzes
func _cull_offscreen_lights() -> void:
	var vp := get_viewport()
	var view := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and iso.enabled and iso.has_method("to_screen"):
		# Prompt 19: confere na TELA iso (to_screen leva cada luz pro andar dela). Pelo retângulo do
		# chão da superfície, as luzes dos andares de baixo (empilhados mais embaixo na tela) eram
		# apagadas como se estivessem fora da tela.
		var tela := view.grow(light_cull_margin * 1.5)
		for light in get_tree().get_nodes_in_group("cullable_lights"):
			# (Bloco 69: as luzes que a vista põe direto na tela — lava, zonas de perigo — já estão lá)
			var p: Vector2 = light.global_position if light.has_meta("tela_iso") else iso.to_screen(light.global_position)
			light.visible = tela.has_point(p)
		return
	view = view.grow(light_cull_margin)
	for light in get_tree().get_nodes_in_group("cullable_lights"):
		light.visible = view.has_point(light.global_position)


# ------------------------------------------------------------ navegação
func _build_navigation() -> void:
	navigation_region = NavigationRegion2D.new()
	navigation_region.name = "NavigationRegion"
	navigation_region.navigation_polygon = _bake_navigation()
	add_child(navigation_region)
	navigation_ready.emit()


## Refaz a malha de navegação (ex.: casa nova posicionada pelo jogador).
func rebuild_navigation() -> void:
	if navigation_region:
		navigation_region.navigation_polygon = _bake_navigation()


func _bake_navigation() -> NavigationPolygon:
	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = nav_agent_radius
	var source := NavigationMeshSourceGeometryData2D.new()
	if has_iso_map():
		# mapa novo: a superfície inteira (floresta + vila) anda; penhascos e paliçada bloqueiam
		source.add_traversable_outline(_rect_outline(iso_ground_rect().grow(-8.0)))
		for o in _iso_blockers():
			source.add_obstruction_outline(o)
	else:
		source.add_traversable_outline(_rect_outline(walkable_rect()))
	if clearing_rect.has_area() and not has_iso_map():
		source.add_traversable_outline(_rect_outline(clearing_rect.grow(-30.0)))
		source.add_traversable_outline(_rect_outline(_tunnel_nav_rect()))
	if deep_rect.has_area():
		# ilha separada: só liga com a mina pelo elevador (NavigationLink2D)
		source.add_traversable_outline(_rect_outline(deep_rect.grow(-nav_edge_inset)))
	if abyss_rect.has_area():
		# outra ilha: só liga com o nível 2 pela plataforma do abismo
		source.add_traversable_outline(_rect_outline(abyss_rect.grow(-nav_edge_inset)))
	for n in niveis_extra():  # Bloco 71: os níveis novos (S4, S5): uma ilha cada, ligadas pelas plataformas
		source.add_traversable_outline(_rect_outline((n.rect as Rect2).grow(-nav_edge_inset)))
		for o in n.obstaculos:  # o lago não anda (a elipse dentro do retângulo, como o desenho da laje)
			if o is Array and o.size() >= 4:
				source.add_obstruction_outline(_elipse_outline(Rect2(float(o[0]), float(o[1]), float(o[2]), float(o[3]))))
	if decorations_block:
		for o in _obstacles:
			source.add_obstruction_outline(o)
	for group in STATION_GROUPS + NAV_EXTRA_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			if node.has_method("get_obstacle_outline"):
				var outline: PackedVector2Array = node.get_obstacle_outline()
				if outline.size() >= 3:
					source.add_obstruction_outline(outline)
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source)
	return nav_poly


## Bloco 71: contorno (24 lados) da elipse dentro do retângulo.
func _elipse_outline(r: Rect2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		out.append(r.get_center() + Vector2(cos(a) * r.size.x * 0.5, sin(a) * r.size.y * 0.5))
	return out


## Área onde dá pra andar DENTRO DA MINA (dentro da borda de pedras). Casas só aqui.
## (Mapa novo: a vila em terraços, do portão pra baixo; a borda é o corte do terreno.)
func walkable_rect() -> Rect2:
	return map_rect.grow(-12.0 if has_iso_map() else -nav_edge_inset)


## Mapa inteiro, mina + clareira (câmera e ordens de mover).
func world_rect() -> Rect2:
	var r := map_rect
	if clearing_rect.has_area():
		r = r.merge(clearing_rect)
	if deep_rect.has_area():
		r = r.merge(deep_rect)
	if abyss_rect.has_area():
		r = r.merge(abyss_rect)
	for n in niveis_extra():  # Bloco 71
		r = r.merge(n.rect)
	if has_leste():
		r = r.merge(leste_rect())  # Bloco 67: a câmera vê a área nova (com névoa enquanto trancada)
	return r


## Prompt 28/29: o relevo é um MAPA DE ALTURA (uma altura por ponto do chão; sem ponte nem
## túnel por cima de caminho, então a navegação continua 2D). Altura em px de arte (32 por
## degrau). Na escada a altura desce em rampa do norte (degrau de cima) pro sul.
func height_at(pos: Vector2) -> float:
	if not has_iso_map():
		return 0.0
	var lv := level_of(pos)
	if not lv.is_empty():
		return float(lv.z_chao)  # andar de baixo: o chão da laje dele (bem abaixo da superfície)
	var t := tile_at(pos)
	if t.x < 0:
		return 0.0
	var nivel := float(iso_map.nivel_arte)
	var h := tile_level(t)
	if _stair_tiles.has(t):
		var frac := clampf((pos.y * iso_scale() - float(iso_map.origem_arte[1])) / float(iso_map.tile_arte) - t.y, 0.0, 1.0)
		return (h + 1.0 - frac) * nivel
	return h * nivel


# ------------------------------------------------------------ mapa isométrico (Prompt 29)
func _load_iso_map() -> void:
	if iso_map_file == "":
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(iso_map_file))
	if typeof(d) != TYPE_DICTIONARY or not d.has("altura"):
		push_error("environment: mapa isométrico ilegível: %s" % iso_map_file)
		return
	iso_map = d
	_alt_rows = PackedStringArray(d.altura)
	var fa := iso_map_file.get_base_dir().path_join("andares.json")
	if FileAccess.file_exists(fa):
		var da = JSON.parse_string(FileAccess.get_file_as_string(fa))
		if typeof(da) == TYPE_DICTIONARY:
			andares = da
	for e in d.get("escadas", []):
		for t in e.tiles:
			_stair_tiles[Vector2i(int(t[0]), int(t[1]))] = true


func has_iso_map() -> bool:
	return not iso_map.is_empty()


## Prompt 29: o andar de baixo onde fica esse ponto da lógica ({} = superfície). Os andares
## ficam empilhados na vista (andares.json): o canto da frente do retângulo do andar encosta
## no canto da frente do mapa, e o chão fica em z_chao (px de arte).
func level_of(pos: Vector2) -> Dictionary:
	for nome in andares.get("andares", {}):
		var a: Dictionary = andares.andares[nome]
		var r := Rect2(a.rect[0], a.rect[1], a.rect[2], a.rect[3])
		if r.grow(48.0).has_point(pos):  # (a borda de pedras fica um pouco pra fora do retângulo)
			return {"nome": nome, "rect": r, "z_chao": float(a.z_chao), "info": a}
	return {}


## Ponto da lógica -> chão da VISTA (px de arte): na superfície é só a escala; num andar de
## baixo, o canto da frente dele vai pro canto da frente do mapa.
func view_ground(pos: Vector2) -> Vector2:
	var f := iso_scale()
	var lv := level_of(pos)
	if lv.is_empty():
		return pos * f
	var c: Array = andares.canto_frente_arte
	return (pos - lv.rect.end) * f + Vector2(c[0], c[1])


## Chão da vista (px de arte) numa altura z -> ponto da lógica (o contrário de view_ground).
func logic_from_view(art: Vector2, z: float) -> Vector2:
	var f := iso_scale()
	for nome in andares.get("andares", {}):
		var a: Dictionary = andares.andares[nome]
		if z <= float(a.z[1]) + 200.0 and z >= float(a.z[0]) - 64.0:
			var c: Array = andares.canto_frente_arte
			return (art - Vector2(c[0], c[1])) / f + Vector2(a.rect[0] + a.rect[2], a.rect[1] + a.rect[3])
	return art / f


## Px de arte por px do mundo (a vista iso desenha a arte nova nessa escala; a lógica não muda).
func iso_scale() -> float:
	return float(iso_map.get("fator", 1.0))


## O retângulo (no chão do mundo) coberto pelo terreno novo.
func iso_ground_rect() -> Rect2:
	var f := iso_scale()
	var t := float(iso_map.tile_arte)
	return Rect2(Vector2(iso_map.origem_arte[0], iso_map.origem_arte[1]) / f,
		Vector2(int(iso_map.ni), int(iso_map.nj)) * t / f)


## Tile do terreno novo embaixo de um ponto do chão (Vector2i(-1, -1) = fora do mapa).
func tile_at(pos: Vector2) -> Vector2i:
	var f := iso_scale()
	var t := float(iso_map.tile_arte)
	var i := floori((pos.x * f - float(iso_map.origem_arte[0])) / t)
	var j := floori((pos.y * f - float(iso_map.origem_arte[1])) / t)
	if i < 0 or j < 0 or i >= int(iso_map.ni) or j >= int(iso_map.nj):
		return Vector2i(-1, -1)
	return Vector2i(i, j)


## Degraus de altura de um tile (0 = fundo da pedreira).
func tile_level(t: Vector2i) -> int:
	if t.x < 0 or t.y >= _alt_rows.size():
		return 0
	return _alt_rows[t.y].unicode_at(t.x) - 48


func is_stair_tile(t: Vector2i) -> bool:
	return _stair_tiles.has(t)


## Dá pra passar de um tile pro vizinho? Mesma altura; ou 1 degrau numa escada, no sentido
## dela (norte-sul).
func tiles_connect(a: Vector2i, b: Vector2i) -> bool:
	var ha := tile_level(a)
	var hb := tile_level(b)
	if ha == hb:
		return true
	if absi(ha - hb) != 1 or a.x != b.x:
		return false
	return _stair_tiles.has(a) or _stair_tiles.has(b)


## O que a navegação vê como parede no mapa novo: a beira dos penhascos (onde dois tiles
## vizinhos não se ligam) e a paliçada (menos a abertura do portão).
func _iso_blockers() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var f := iso_scale()
	var t := float(iso_map.tile_arte)
	var ox := float(iso_map.origem_arte[0])
	var oy := float(iso_map.origem_arte[1])
	var ni := int(iso_map.ni)
	var nj := int(iso_map.nj)
	var half := cliff_thickness * 0.5
	# beiras verticais (entre a coluna i e i+1), juntando os trechos seguidos
	for i in ni - 1:
		var start := -1
		for j in nj + 1:
			var cut := j < nj and not tiles_connect(Vector2i(i, j), Vector2i(i + 1, j))
			if cut and start < 0:
				start = j
			elif not cut and start >= 0:
				var x := (ox + (i + 1) * t) / f
				out.append(_rect_outline(Rect2(x - half, (oy + start * t) / f, half * 2.0, (j - start) * t / f)))
				start = -1
	# beiras horizontais (entre a linha j e j+1)
	for j in nj - 1:
		var start := -1
		for i in ni + 1:
			var cut := i < ni and not tiles_connect(Vector2i(i, j), Vector2i(i, j + 1))
			if cut and start < 0:
				start = i
			elif not cut and start >= 0:
				var y := (oy + (j + 1) * t) / f
				out.append(_rect_outline(Rect2((ox + start * t) / f, y - half, (i - start) * t / f, half * 2.0)))
				start = -1
	# Bloco 67: a área nova do leste fechada até desbravar
	if has_leste() and not leste_aberto:
		var lr := leste_rect()
		out.append(_rect_outline(Rect2(lr.position.x - 6.0, lr.position.y, 12.0, lr.size.y)))
	# paliçada: da borda até o portão, dos dois lados
	var g := iso_ground_rect()
	out.append(_rect_outline(Rect2(g.position.x, palisade_y - 4.0, -gate_half_width - g.position.x, 8.0)))
	out.append(_rect_outline(Rect2(gate_half_width, palisade_y - 4.0, g.end.x - gate_half_width, 8.0)))
	return out


## Dá pra ficar parado/construir aqui? Chão plano em volta (raio `margin`), fora de escada,
## do paredão (degrau 4), da paliçada e do mapa.
func spot_ok(pos: Vector2, margin: float = 16.0, walker: bool = false) -> bool:
	if not has_iso_map():
		return true
	var t := tile_at(pos)
	if t.x < 0 or tile_level(t) >= 4:
		return false
	if walker:  # boneco: anda em escada e na beira; impossível só paredão, paliçada e fora do mapa
		return not (absf(pos.y - palisade_y) < 4.0 and absf(pos.x) >= gate_half_width)
	if _stair_tiles.has(t):
		return false
	if absf(pos.y - palisade_y) < margin + 4.0 and absf(pos.x) >= gate_half_width:
		return false
	for d in [Vector2(margin, 0), Vector2(-margin, 0), Vector2(0, margin), Vector2(0, -margin)]:
		var u := tile_at(pos + d)
		if u.x < 0 or u != t and (not tiles_connect(t, u) or tile_level(u) != tile_level(t) or _stair_tiles.has(u)):
			return false
	return true


## Mapa novo: a pegada fica na floresta (além da paliçada)? Prédio da vila vai na pedreira.
func in_forest(fp: Rect2) -> bool:
	return has_iso_map() and fp.end.y <= palisade_y + 6.0


## Pegada de construção no mapa novo: "" se dá pra construir; senão o motivo. O chão
## embaixo tem que ser plano (um degrau só), fora de escada, do paredão e da paliçada.
func footprint_reason(fp: Rect2) -> String:
	if not has_iso_map():
		return ""
	var andar := level_of(fp.get_center())  # Bloco 70: a laje de um andar de baixo é plana
	if not andar.is_empty():
		return "" if (andar.rect as Rect2).encloses(fp) else "fora do andar"
	if fp.position.y < palisade_y + 6.0 and fp.end.y > palisade_y - 6.0:
		return "em cima da paliçada"
	var lv := -1
	var sx := maxf(minf(10.0, fp.size.x), 1.0)
	var sy := maxf(minf(10.0, fp.size.y), 1.0)
	var x := fp.position.x
	while x <= fp.end.x + 0.01:
		var y := fp.position.y
		while y <= fp.end.y + 0.01:
			var t := tile_at(Vector2(x, y))
			if t.x < 0:
				return "fora do mapa"
			if _stair_tiles.has(t):
				return "em cima da escada"
			var l := tile_level(t)
			if l >= 4:
				return "no paredão"
			if lv >= 0 and l != lv:
				return "na beira do penhasco (o chão tem que ser plano)"
			lv = l
			y += sy
		x += sx
	return ""


## O ponto válido mais perto (procura em anéis de 8 px, até 600 px).
func nearest_ok(pos: Vector2, margin: float = 16.0, walker: bool = false) -> Vector2:
	if spot_ok(pos, margin, walker):
		return pos
	for ring in range(1, 76):
		var r := ring * 8.0
		var n := maxi(8, int(r * 0.8))
		for k in n:
			var p := pos + Vector2.RIGHT.rotated(TAU * k / n) * r
			if spot_ok(p, 10.0 if walker else margin):  # boneco mudado vai pra chão plano mesmo
				return p
	return pos


## Prompt 29, migração: tudo que ficou em lugar inválido no mapa novo (cena antiga, save
## antigo) vai pro ponto válido mais perto. Fica registrado em `migrated` (e no console).
## Retorna quantos mudaram (quem chama refaz a navegação se precisar).
func migrate_positions() -> int:
	if not has_iso_map():
		return 0
	var n := 0
	var groups: Array = STATION_GROUPS + NAV_EXTRA_GROUPS + ["ipezinhos", "barricadas", "elevador", "robos"]
	var seen := {}
	for group in groups:
		for node in get_tree().get_nodes_in_group(group):
			if seen.has(node) or not (node is Node2D) or is_deep(node.global_position):
				continue
			seen[node] = true
			if node.is_in_group("barricadas"):
				continue  # portões: ficam na abertura da paliçada / junto do poço (posição da cena)
			# folga pequena: só muda o que está DE FATO em lugar impossível (em cima da beira, da
			# escada, do paredão, da paliçada). Mais branda que a regra de construir, senão um
			# prédio construído certinho perto da beira "andaria" ao carregar o save.
			var margin := 4.0
			var p: Vector2 = node.global_position
			var q := nearest_ok(p, margin, node.is_in_group("ipezinhos") or node is CharacterBody2D)
			if q != p:
				node.global_position = q
				migrated.append({"nome": String(node.name), "de": p, "para": q})
				print("environment: %s mudou de %s pra %s (lugar inválido no mapa novo)" % [node.name, p.round(), q.round()])
				n += 1
	return n + _migrate_overlaps()


## Prompt 29 parte 2: com a arte nova o prédio tem fundo de verdade (a pegada cresceu). Prédio
## posicionado num save antigo que ficou em cima de outro vai pro ponto livre mais perto (chão
## plano, sem encostar em ninguém). Os da cena (layout aprovado) ficam onde estão.
func _migrate_overlaps() -> int:
	var fixed: Array = []
	var movers: Array = []
	var seen := {}
	for group in STATION_GROUPS + NAV_EXTRA_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			if seen.has(node) or not (node is Node2D) or is_deep(node.global_position):
				continue
			seen[node] = true
			var r := IsoArt.base_rect(node)
			if not r.has_area():
				continue
			if node.owner != null:  # da cena (main.tscn)
				fixed.append(r)
			else:
				movers.append(node)
	var n := 0
	for node in movers:
		var r := IsoArt.base_rect(node)
		if not _overlaps(r, fixed):
			fixed.append(r)
			continue
		var p: Vector2 = node.global_position
		var off := r.position - p
		var q := p
		for ring in range(1, 60):
			var rad := ring * 8.0
			var found := false
			for k in maxi(8, int(rad * 0.8)):
				var c := p + Vector2.RIGHT.rotated(TAU * k / maxi(8, int(rad * 0.8))) * rad
				var rr := Rect2(c + off, r.size)
				if footprint_reason(rr) == "" and not _overlaps(rr, fixed):
					q = c
					found = true
					break
			if found:
				break
		if q != p:
			node.global_position = q
			migrated.append({"nome": String(node.name), "de": p, "para": q})
			print("environment: %s mudou de %s pra %s (em cima de outro prédio com a arte nova)" % [node.name, p.round(), q.round()])
			n += 1
		fixed.append(IsoArt.base_rect(node))
	return n


func _overlaps(r: Rect2, others: Array) -> bool:
	for o in others:
		if r.grow(-2.0).intersects(o):
			return true
	return false


## Esse ponto é no fundo (nível 2 ou abismo)?
func is_deep(pos: Vector2) -> bool:
	return (deep_rect.has_area() and deep_rect.has_point(pos)) or is_abyss(pos) or nivel_extra_em(pos) != null


## Esse ponto é no abismo (nível 3)?
func is_abyss(pos: Vector2) -> bool:
	return abyss_rect.has_area() and abyss_rect.has_point(pos)


## 0 = mina/clareira, 2 = nível 2, 3 = abismo (Bloco 71: 4, 5... = a profundidade do nível novo).
func level_at(pos: Vector2) -> int:
	if is_abyss(pos):
		return 3
	var n := nivel_extra_em(pos)
	if n:
		return n.profundidade
	return 2 if is_deep(pos) else 0


## Multiplicador de acidente por profundidade (1 na mina/clareira; os níveis novos = o do abismo).
func danger_mult_at(pos: Vector2) -> float:
	if is_abyss(pos) or nivel_extra_em(pos) != null:
		return abyss_injury_mult
	return deep_injury_mult if is_deep(pos) else 1.0


## Bloco 71: os níveis novos (dados com `rect`: S4, S5...) que já são jogáveis (os dados não mudam
## durante a partida: guardado na primeira vez — is_deep é chamado o tempo todo).
var _extra: Array = []
var _extra_ok := false


func niveis_extra() -> Array:
	if not _extra_ok:
		_extra = preload("res://scripts/core/niveis.gd").todos().filter(func(n): return not n.em_breve and (n.rect as Rect2).has_area())
		_extra_ok = true
	return _extra


## Bloco 71: o nível novo onde fica esse ponto (null = nenhum).
func nivel_extra_em(pos: Vector2) -> Resource:
	for n in niveis_extra():
		if (n.rect as Rect2).has_point(pos):
			return n
	return null


## Bloco 71: a área (nome nos dados) de um ponto: "abyss", "deep", "s4"..., "clareira" ou "mapa".
func area_at(pos: Vector2) -> String:
	if is_abyss(pos):
		return "abyss"
	var n := nivel_extra_em(pos)
	if n:
		return n.area
	if is_deep(pos):
		return "deep"
	return "clareira" if pos.y < map_rect.position.y else "mapa"


## Faixa andável do túnel (entra um pouco na mina e na clareira pra emendar).
func _tunnel_nav_rect() -> Rect2:
	var half := tunnel_width * 0.5 - 12.0
	var top := clearing_rect.end.y - 40.0
	var bottom := map_rect.position.y + nav_edge_inset + 14.0
	return Rect2(tunnel_x - half, top, half * 2.0, bottom - top)


# ------------------------------------------------------------ nível 2
func _build_deep() -> void:
	if not deep_rect.has_area():
		return
	var drng := RandomNumberGenerator.new()
	drng.seed = map_seed + 13  # sorteio próprio: não mexe na mina nem na clareira
	if deep_floor_texture and not has_iso_map():
		_tiled_sprite(deep_floor_texture, deep_rect, -10)
	# pedras grandes na borda
	var r := deep_rect
	var edge: Array[Vector2] = []
	var x := r.position.x
	while x <= r.end.x:
		edge.append(Vector2(x, r.position.y))
		edge.append(Vector2(x, r.end.y))
		x += edge_boulder_spacing
	var y := r.position.y + edge_boulder_spacing
	while y < r.end.y:
		edge.append(Vector2(r.position.x, y))
		edge.append(Vector2(r.end.x, y))
		y += edge_boulder_spacing
	for p in edge:
		if boulder_textures.is_empty():
			break
		var s := _deco_sprite(boulder_textures[drng.randi() % boulder_textures.size()],
			p + Vector2(drng.randf_range(-10, 10), drng.randf_range(-8, 8)))
		s.scale = Vector2.ONE * pixel_scale * drng.randf_range(1.2, 1.9)
		s.flip_h = drng.randf() < 0.5
		s.modulate = deep_tint
	# decoração espalhada (longe das jazidas do fundo e da gaiola de chegada)
	var avoid: Array[Vector2] = []
	var shaft := get_tree().get_first_node_in_group("elevador")
	if shaft:
		avoid.append(shaft.bottom_position)
	var placed: Array[Vector2] = []
	var inner := deep_rect.grow(-50.0)
	for job in [[deep_pebble_count, pebble_textures, 10.0, _add_pebble], [deep_boulder_count, boulder_textures, 45.0, _add_boulder],
			[deep_crystal_count, crystal_textures, 55.0, _add_crystal]]:
		var textures: Array = job[1]
		if textures.is_empty():
			continue
		for i in int(job[0]):
			for attempt in 30:
				var p := Vector2(drng.randf_range(inner.position.x, inner.end.x), drng.randf_range(inner.position.y, inner.end.y))
				if not _deep_spot_free(p, job[2], placed, avoid):
					continue
				placed.append(p)
				var before := get_child_count()
				job[3].call(textures[drng.randi() % textures.size()], p)
				for c in range(before, get_child_count()):
					var sprite := get_child(c) as Sprite2D
					if sprite:
						sprite.modulate *= deep_tint
				break


# ------------------------------------------------------------ nível 3
func _build_abyss() -> void:
	if not abyss_rect.has_area():
		return
	var arng := RandomNumberGenerator.new()
	arng.seed = map_seed + 29  # sorteio próprio: não mexe na mina nem no nível 2
	if abyss_floor_texture and not has_iso_map():
		_tiled_sprite(abyss_floor_texture, abyss_rect, -10)
	var r := abyss_rect
	var edge: Array[Vector2] = []
	var x := r.position.x
	while x <= r.end.x:
		edge.append(Vector2(x, r.position.y))
		edge.append(Vector2(x, r.end.y))
		x += edge_boulder_spacing
	var y := r.position.y + edge_boulder_spacing
	while y < r.end.y:
		edge.append(Vector2(r.position.x, y))
		edge.append(Vector2(r.end.x, y))
		y += edge_boulder_spacing
	for p in edge:
		if boulder_textures.is_empty():
			break
		var s := _deco_sprite(boulder_textures[arng.randi() % boulder_textures.size()],
			p + Vector2(arng.randf_range(-10, 10), arng.randf_range(-8, 8)))
		s.scale = Vector2.ONE * pixel_scale * arng.randf_range(1.2, 1.9)
		s.flip_h = arng.randf() < 0.5
		s.modulate = abyss_tint
	var avoid: Array[Vector2] = []
	var shaft := get_tree().get_first_node_in_group("elevador_abismo")
	if shaft:
		avoid.append(shaft.bottom_position)
	var placed: Array[Vector2] = []
	var inner := abyss_rect.grow(-50.0)
	for job in [[abyss_pebble_count, pebble_textures, 10.0, _add_pebble], [abyss_boulder_count, boulder_textures, 45.0, _add_boulder]]:
		var textures: Array = job[1]
		if textures.is_empty():
			continue
		for i in int(job[0]):
			for attempt in 30:
				var p := Vector2(arng.randf_range(inner.position.x, inner.end.x), arng.randf_range(inner.position.y, inner.end.y))
				if not _deep_spot_free(p, job[2], placed, avoid):
					continue
				placed.append(p)
				var before := get_child_count()
				job[3].call(textures[arng.randi() % textures.size()], p)
				for c in range(before, get_child_count()):
					var sprite := get_child(c) as Sprite2D
					if sprite:
						sprite.modulate *= abyss_tint
				break


## Esconde a decoração (e tira o bloqueio dela) que ficou embaixo das estruturas de
## NAV_EXTRA_GROUPS. Não mexe no sorteio: as posições das outras pedras não mudam.
## (Chamado de novo quando uma estrutura dessas é construída durante o jogo.)
func clear_decor_under_extras() -> void:
	var groups: Array = NAV_EXTRA_GROUPS + ["elevador_abismo", "elevadores", "barricadas", "village_hub", "armazens", "comedouros"]
	if has_iso_map():  # Prompt 30: os prédios novos são maiores; toda estrutura limpa a pegada dela
		groups = groups + ["casas", "escavadeira", "oficina", "elevador"]
	for group in groups:
		for node in get_tree().get_nodes_in_group(group):
			var area: Rect2 = node.decor_clear_rect() if node.has_method("decor_clear_rect") \
				else Rect2(node.global_position + Vector2(-44, -64), Vector2(88, 84))
			if has_iso_map() and node.has_method("get_obstacle_outline"):
				var o: PackedVector2Array = node.get_obstacle_outline()
				if o.size() >= 3:
					var bb := Rect2(o[0], Vector2.ZERO)
					for q in o:
						bb = bb.expand(q)
					# a pegada do desenho novo + folga pra porta e o caminho em volta
					area = area.merge(bb.grow(40.0 if node.is_in_group("village_hub") else 18.0))
			for c in get_children():
				var s := c as Sprite2D
				if s and not s.region_enabled and area.has_point(s.global_position):
					s.visible = false
				elif c is Node2D and c.has_meta("iso_prop") and area.has_point((c as Node2D).global_position):
					(c as Node2D).visible = false  # decoração do mapa novo (Prompt 30)
			for i in range(_obstacles.size() - 1, -1, -1):
				var o: PackedVector2Array = _obstacles[i]
				var center := Vector2.ZERO
				for v in o:
					center += v
				if o.size() > 0 and area.has_point(center / o.size()):
					_obstacles.remove_at(i)


func _deep_spot_free(p: Vector2, spacing: float, placed: Array[Vector2], avoid: Array[Vector2]) -> bool:
	for group in STATION_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			if p.distance_to(node.global_position) < keep_clear_radius:
				return false
	for a in avoid:
		if p.distance_to(a) < 90.0:
			return false
	for q in placed:
		if p.distance_to(q) < spacing:
			return false
	for poca in get_tree().get_nodes_in_group("pocas_perigo"):  # Bloco 70: nada em cima da poça
		if p.distance_to(poca.global_position) < float(poca.radius) + spacing * 0.5:
			return false
	return true


# ------------------------------------------------------------ clareira
func _build_clearing() -> void:
	if not clearing_rect.has_area():
		return
	var crng := RandomNumberGenerator.new()
	crng.seed = map_seed + 7  # sorteio próprio: não mexe na decoração da mina
	if has_iso_map():
		_build_sun()
		return
	if clearing_floor_texture:
		_tiled_sprite(clearing_floor_texture, clearing_rect, -10)
	# chão do túnel cortando a rocha entre a mina e a clareira
	if floor_texture:
		var tunnel := Rect2(tunnel_x - tunnel_width * 0.5, clearing_rect.end.y - 12.0,
			tunnel_width, map_rect.position.y - clearing_rect.end.y + 30.0)
		_tiled_sprite(floor_texture, tunnel, -10)
	# escoras marcando a boca do túnel dos dois lados
	if support_texture:
		for pos in [Vector2(tunnel_x, map_rect.position.y + 20.0), Vector2(tunnel_x, clearing_rect.end.y + 4.0)]:
			_add_shadow(_deco_sprite(support_texture, pos), 1.1)
	# pedras na borda da clareira (menos na saída do túnel) e árvores de enfeite em volta
	var r := clearing_rect
	var edge_points: Array[Vector2] = []
	var x := r.position.x
	while x <= r.end.x:
		edge_points.append(Vector2(x, r.position.y))
		if absf(x - tunnel_x) > tunnel_width * 0.5 + 24.0:
			edge_points.append(Vector2(x, r.end.y))
		x += edge_boulder_spacing
	var y := r.position.y + edge_boulder_spacing
	while y < r.end.y:
		edge_points.append(Vector2(r.position.x, y))
		edge_points.append(Vector2(r.end.x, y))
		y += edge_boulder_spacing
	for p in edge_points:
		if boulder_textures.is_empty():
			break
		var s := _deco_sprite(boulder_textures[crng.randi() % boulder_textures.size()],
			p + Vector2(crng.randf_range(-10, 10), crng.randf_range(-8, 8)))
		s.scale = Vector2.ONE * pixel_scale * crng.randf_range(1.1, 1.7)
		s.flip_h = crng.randf() < 0.5
	if clearing_tree_texture:
		for i in clearing_tree_count:
			# fileira de pinheiros atrás da borda de cima e dos lados (não bloqueiam: estão fora da área andável)
			var t := float(i) / maxf(clearing_tree_count - 1, 1)
			var p: Vector2
			if i % 3 == 0:
				p = Vector2(r.position.x - 12.0, lerpf(r.position.y + 40.0, r.end.y - 40.0, t))
			elif i % 3 == 1:
				p = Vector2(r.end.x + 12.0, lerpf(r.position.y + 40.0, r.end.y - 40.0, t))
			else:
				p = Vector2(lerpf(r.position.x + 20.0, r.end.x - 20.0, t), r.position.y - 6.0)
			var tree := _deco_sprite(clearing_tree_texture, p + Vector2(crng.randf_range(-8, 8), crng.randf_range(-6, 6)))
			tree.hframes = 3
			tree.frame = 0
			tree.offset = Vector2(0, -clearing_tree_texture.get_height() * 0.5)
			tree.flip_h = crng.randf() < 0.5
			tree.scale = Vector2.ONE * pixel_scale * crng.randf_range(0.9, 1.2)
			_add_shadow(tree, 0.35)
	# placa na boca do túnel, do lado da mina
	var sign_label := Label.new()
	sign_label.text = "saída pra clareira (madeira, caça, fruta)"
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_label.position = Vector2(tunnel_x - 90.0, map_rect.position.y + 42.0)
	sign_label.size = Vector2(180, 20)
	sign_label.add_theme_font_size_override("font_size", 11)
	sign_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0.8))
	sign_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	sign_label.add_theme_constant_override("outline_size", 3)
	sign_label.z_index = 5
	add_child(sign_label)
	_build_sun()


## Sol da superfície: luz grande e quente que some à noite (fica sempre ligado, sem cull).
func _build_sun() -> void:
	if light_texture:
		_sun = PointLight2D.new()
		_sun.texture = light_texture
		_sun.color = sun_color
		_sun.energy = sun_energy
		_sun.texture_scale = maxf(clearing_rect.size.x, clearing_rect.size.y) / light_texture.get_width() * 1.6
		_sun.position = clearing_rect.get_center()
		add_child(_sun)
	_day_night = get_tree().get_first_node_in_group("day_night")


# ------------------------------------------------------------ decoração do mapa novo (Prompt 30)
## O que a montagem aprovada (prototipos/camera/arte_iso/mapa/monta.py) tem e o jogo não tinha:
## [peça, ponto do chão, bloqueia a passagem]. Só desenho (a vista iso desenha pelo nome da peça,
## meta "iso_prop"); os grandes bloqueiam como as pedras.
const MAP_DECOR := [
	["guindaste_pedreira", Vector2(-280, 100), true], ["vagonete_cheio_SE", Vector2(200, -60), false],
	["caixotes_2", Vector2(170, -20), false], ["barris_2", Vector2(60, -20), false], ["sacos", Vector2(180, -20), false],
	["pedra_g", Vector2(-320, 120), false], ["tijolo_m", Vector2(-230, 110), false], ["poco", Vector2(-220, -400), true],
	["banco", Vector2(500, -280), false], ["placa_caveira", Vector2(-150, 360), false], ["caixote", Vector2(-600, 160), false],
	["horta_espantalho", Vector2(-140, -660), false],
	["arbusto_0", Vector2(-480, -640), false], ["arbusto_1", Vector2(200, -600), false], ["arbusto_2", Vector2(480, -900), false],
	["arbusto_0", Vector2(-200, -820), false], ["arbusto_1", Vector2(620, -620), false], ["arbusto_2", Vector2(-330, -560), false],
]
## Vegetação rasteira espalhada na floresta (como na montagem: capim, flores, samambaia...)
const FOREST_DECOR := ["capim_0", "capim_1", "capim_2", "capim_3", "flores_0", "flores_1", "flores_2", "flores_3",
	"samambaia_0", "samambaia_1", "cogumelos_0", "cogumelos_1", "cogumelos_2", "tronco_musgo_0", "tronco_musgo_1",
	"tronco_musgo_2", "moita_0", "moita_1", "moita_2"]
const FOREST_DECOR_COUNT := 90


func _build_map_decor() -> void:
	for d in MAP_DECOR:
		if spot_ok(d[1], 6.0) and _is_free(d[1], 14.0, 34.0):
			_decor_node(d[0], d[1], d[2])
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed + 41  # sorteio próprio: não mexe nas pedras/cristais dos saves
	var placed := 0
	for tries in 2500:
		if placed >= FOREST_DECOR_COUNT:
			break
		var p := Vector2(rng.randf_range(-690.0, 740.0), rng.randf_range(-1020.0, -495.0))
		if not spot_ok(p, 8.0) or not _is_free(p, 18.0, 30.0):
			continue
		_decor_node(FOREST_DECOR[rng.randi() % FOREST_DECOR.size()], p, false)
		placed += 1


func _decor_node(prop: String, p: Vector2, blocks: bool) -> void:
	var n := Node2D.new()
	n.name = "Deco_%s_%d" % [prop, get_child_count()]
	n.position = p
	n.set_meta("iso_prop", prop)
	add_child(n)
	_placed.append(p)
	if blocks:
		_add_obstacle(p + Vector2(0, -4), Vector2(24, 12))


## Contornos dos obstáculos da decoração (pedras, cristais, tochas) — pra validar construção.
func decoration_obstacles() -> Array[PackedVector2Array]:
	return _obstacles


func _rect_outline(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## Registra a "base" de uma decoração como obstáculo (elipse).
func _add_obstacle(center: Vector2, radius: Vector2) -> void:
	var outline := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		outline.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	_obstacles.append(outline)


# ------------------------------------------------------------ chão e paredes
func _build_ground() -> void:
	var wall_margin := 1200.0
	if wall_texture:
		_tiled_sprite(wall_texture, map_rect.grow(wall_margin), -11)
	if floor_texture:
		_tiled_sprite(floor_texture, map_rect, -10)


func _tiled_sprite(tex: Texture2D, rect: Rect2, z: int) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, rect.size / pixel_scale)
	s.scale = Vector2.ONE * pixel_scale
	s.position = rect.position
	s.z_index = z
	add_child(s)


func _build_edges() -> void:
	if boulder_textures.is_empty():
		return
	var r := map_rect
	var points: Array[Vector2] = []
	var x := r.position.x
	while x <= r.end.x:
		points.append(Vector2(x, r.position.y))
		points.append(Vector2(x, r.end.y))
		x += edge_boulder_spacing
	var y := r.position.y + edge_boulder_spacing
	while y < r.end.y:
		points.append(Vector2(r.position.x, y))
		points.append(Vector2(r.end.x, y))
		y += edge_boulder_spacing
	for p in points:
		var jitter := Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-8, 8))
		var k := _rng.randf_range(1.1, 1.8)
		var tex: Texture2D = boulder_textures[_rng.randi() % boulder_textures.size()]
		var flip := _rng.randf() < 0.5
		# vão do túnel pra clareira: sorteia igual (a decoração da mina não muda), mas não põe pedra
		if is_equal_approx(p.y, r.position.y) and absf(p.x - tunnel_x) < tunnel_width * 0.5 + 24.0:
			continue
		var sprite := _deco_sprite(tex, p + jitter)
		sprite.scale = Vector2.ONE * pixel_scale * k
		sprite.flip_h = flip
		_add_shadow(sprite, 1.2)
		# sem obstáculo individual: nav_edge_inset já mantém todo mundo longe da borda

	# escoras de madeira ao longo da parede de cima, como entradas de túnel
	if support_texture:
		var sx := r.position.x + 140.0
		while sx < r.end.x - 100.0:
			var pos := Vector2(sx + _rng.randf_range(-30, 30), r.position.y + 18.0)
			_add_shadow(_deco_sprite(support_texture, pos), 1.1)
			_placed.append(pos)
			sx += _rng.randf_range(260.0, 380.0)


## Base de uma pedra de 16px desenhada com a escala `s` (a origem fica no pé).
func _add_boulder_obstacle(p: Vector2, s: float) -> void:
	_add_obstacle(p + Vector2(0, -3.5 * s), Vector2(6.0 * s, 3.5 * s))


# ------------------------------------------------------------ decoração espalhada
func _scatter(count: int, textures: Array, min_spacing: float, clear_factor: float, add_fn: Callable) -> void:
	if textures.is_empty() or textures[0] == null:
		return
	var inner := map_rect.grow(-40.0)
	for i in count:
		for attempt in 30:
			var p := Vector2(
				_rng.randf_range(inner.position.x, inner.end.x),
				_rng.randf_range(inner.position.y, inner.end.y))
			if _is_free(p, min_spacing, keep_clear_radius * clear_factor):
				_placed.append(p)
				add_fn.call(textures[_rng.randi() % textures.size()], p)
				break


func _is_free(p: Vector2, min_spacing: float, clear_radius: float) -> bool:
	if has_iso_map() and not spot_ok(p, 18.0):
		return false  # mapa novo: decoração só em chão plano (fora de penhasco, escada, paliçada)
	for group in STATION_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			# estruturas grandes informam o próprio centro/raio livre
			var center: Vector2 = node.get_clear_center() if node.has_method("get_clear_center") else node.global_position
			var r := clear_radius
			if node.has_method("get_clear_radius"):
				r = maxf(r, node.get_clear_radius())
			if p.distance_to(center) < r:
				return false
	for q in _placed:
		if p.distance_to(q) < min_spacing:
			return false
	return true


func _add_pebble(tex: Texture2D, p: Vector2) -> void:
	var s := _deco_sprite(tex, p)
	s.z_index = -5  # sempre no chão, por baixo de todo mundo
	s.flip_h = _rng.randf() < 0.5
	s.modulate = Color(1, 1, 1, 0.9)
	# Prompt 29: no mapa novo o chão (superfície e lajes dos andares) já tem os detalhes dele; a
	# pedrinha antiga só some (o sorteio continua igual: as pedras/cristais ficam onde sempre)
	s.visible = not has_iso_map()


func _add_boulder(tex: Texture2D, p: Vector2) -> void:
	var s := _deco_sprite(tex, p)
	var k := _rng.randf_range(0.8, 1.3)
	s.scale = Vector2.ONE * pixel_scale * k
	s.flip_h = _rng.randf() < 0.5
	_add_shadow(s, 1.2)
	_add_boulder_obstacle(p, pixel_scale * k)


func _add_crystal(tex: Texture2D, p: Vector2) -> void:
	var s := _deco_sprite(tex, p)
	var k := _rng.randf_range(1.0, 1.4)  # cristais já são 32px
	s.scale = Vector2.ONE * k
	s.flip_h = _rng.randf() < 0.5
	_add_shadow(s, 0.9)
	_add_obstacle(p + Vector2(0, -3.0 * k), Vector2(tex.get_width() * 0.4 * k, 4.0 * k))
	if light_texture:
		var light := PointLight2D.new()
		light.texture = light_texture
		light.color = crystal_light_color
		light.energy = crystal_light_energy
		light.texture_scale = 0.6
		light.position = Vector2(0, -tex.get_height() * 0.5)
		light.add_to_group("cullable_lights")
		s.add_child(light)


## 0..1 de quanto as tochas estão acesas (1 se não houver DayNight na cena).
func _torch_level() -> float:
	if _day_night == null or not is_instance_valid(_day_night):
		_day_night = get_tree().get_first_node_in_group("day_night")
	return _day_night.torch_level() if _day_night else 1.0


func _add_torch(tex: Texture2D, p: Vector2) -> void:
	# base = tocha apagada; a chama (sprite aceso inteiro) vai por cima e faz o fade
	var s := _deco_sprite(torch_unlit_texture if torch_unlit_texture else tex, p)
	s.add_to_group("tochas")
	if torch_unlit_texture:
		var flame := Sprite2D.new()
		flame.texture = tex
		flame.offset = s.offset
		s.add_child(flame)
		_torch_flames.append(flame)
	_add_shadow(s, 1.4)
	_add_obstacle(p + Vector2(0, -2), Vector2(5, 3))
	if light_texture:
		var light := PointLight2D.new()
		light.texture = light_texture
		light.color = torch_light_color
		light.energy = torch_light_energy
		light.texture_scale = torch_light_scale / pixel_scale  # compensa a escala do sprite
		light.position = Vector2(0, -tex.get_height() + 2)
		light.add_to_group("cullable_lights")
		s.add_child(light)
		_torch_lights.append(light)


## Sombra no pé de uma decoração, um pouco deslocada pra baixo/direita (sombra "longa").
## `width_factor` é a largura da sombra em relação à largura do sprite.
func _add_shadow(s: Sprite2D, width_factor: float) -> void:
	if shadow_texture == null:
		return
	var shadow := Sprite2D.new()
	shadow.texture = shadow_texture
	shadow.z_index = -4  # acima do chão e das pedrinhas, abaixo de tudo que fica em pé
	var k := s.texture.get_width() * width_factor / shadow_texture.get_width()
	shadow.scale = Vector2(k, k * 0.8)
	shadow.position = Vector2(s.texture.get_width() * 0.08, 0.5)
	s.add_child(shadow)


## Sprite com a origem no "pé" (base da imagem), pro y-sort funcionar direito.
func _deco_sprite(tex: Texture2D, p: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.offset = Vector2(0, -tex.get_height() * 0.5)
	s.scale = Vector2.ONE * pixel_scale
	s.position = p
	add_child(s)
	return s
