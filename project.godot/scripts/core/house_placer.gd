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
## Bloco 37: begin() aceita `opts` —
##   footprint: Rect2   pegada de outro prédio (Centro da Vila, Armazém, Comedouro)
##   ignore: Array      nós que não contam como obstáculo (o próprio prédio sendo mudado)
##   cancelable: bool   false = Esc/direito não cancelam (fundação da vila)
##   radius / radius_center   só vale até essa distância do centro (casas em volta do
##                      Centro da Vila); o contorno do raio aparece enquanto escolhe
##   start: Vector2     onde o fantasma aparece
##   area: Rect2        onde pode (em vez da área da mina) — Bloco 45: coletor na clareira
##   area_name: String  como chamar essa área no aviso ("fora da clareira")
##   repeat: bool       Bloco 90: depois de confirmar, continua no modo (decoração: várias em sequência)
##
## Bloco 132: a GRADE ÚNICA (grade.gd). O prédio ocupa CÉLULAS INTEIRAS (a pegada da base arredondada pra cima) e o
## fantasma encaixa na grade. A folga entre prédios é ZERO (casas encostadas); o que fica livre é a PORTA: `porta_celulas`
## fileira(s) de células na frente da base (+y, o lado da arte onde fica a entrada e o ponto de trabalho — IsoArt.front),
## na largura do prédio. Regras (check_spot):
##   - a pegada não cobre célula ocupada (base de estrutura, decoração que bloqueia) nem a PORTA de outro prédio;
##   - a porta do prédio novo cai em chão livre;
##   - depois de posto, a porta dele e as portas que já chegavam ao Centro continuam ligadas à porta do Centro por células
##     livres (busca em largura na grade da área da vila): ninguém fica preso.
## A área de trabalho das estações deixou de bloquear o vizinho: o trabalhador fica na frente da base (dentro da porta).
## Peça do mapa que atrapalha e dá pra LIMPAR (pedra, mato, entulho, tocha solta): o clique paga `custo_limpar` (environment)
## e tira a peça (poeira, sem reembolso); o próximo clique constrói. A tecla da Defesa (G) liga/desliga a GRADE enquanto
## posiciona (a vista iso desenha: iso_grade.gd).

signal finished(confirmed: bool)

const CASA_TEXTURE := preload("res://assets/game/casa.png")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Grade := preload("res://scripts/core/grade.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const Settings := preload("res://scripts/core/settings.gd")
## Pegada da casa em volta do ponto clicado (o ponto é o pé da casa): do telhado
## (-54) até o degrau da porta, onde ficam as camas (+24).
const FOOTPRINT := Rect2(-32, -54, 64, 78)
const COLOR_OK := Color(0.45, 1.0, 0.5)
const COLOR_BAD := Color(1.0, 0.35, 0.3)

## Bloco 132: fileiras de células livres na frente (+y) de cada prédio: a porta/entrada e o ponto do trabalhador.
@export var porta_celulas: int = 1

## Bloco 132: a grade aparece enquanto posiciona (liga/desliga na tecla da Defesa; fica nas configurações).
static var grade_ligada := true

var active := false
var _on_confirm: Callable
var _pos := Vector2.ZERO
var _reason := ""
var _blockers: Array = []  # [{rect: Rect2, name: String}] (o retângulo de cada obstáculo; a conferência é por célula)
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
var _repeat := false
## Prompt 29: o prédio da arte nova sendo posicionado ("" = sem arte nova): a pegada é a do desenho
var art_name := ""
## Bloco 76: o fantasma está encaixado num lote livre
var no_lote := false

# ---- Bloco 132: a ocupação da grade (calculada ao entrar no modo; nada se move enquanto escolhe)
## célula -> quem ocupa ("outra casa", "uma pedra"...)
var ocupadas := {}
## célula -> de quem é a porta
var portas := {}
## [{nome, celulas: Array[Vector2i]}] as portas de cada prédio
var _portas_lista: Array = []
## célula -> a peça do mapa que dá pra limpar ali
var _limpaveis := {}
## muda quando a ocupação muda (a vista redesenha)
var versao_ocupacao := 0
## o fantasma em células: a pegada, a porta e as células em conflito (vermelhas)
var fantasma_celulas := Rect2i()
var fantasma_porta := Rect2i()
var celulas_ruins := {}
var _ruins := {}
var _limpar_pendentes: Array = []
# a busca em largura (porta -> Centro)
var _regiao := Rect2i()
var _chao := {}
var _fonte: Array[Vector2i] = []
var _portas_ok0: Array = []


func _ready() -> void:
	add_to_group("house_placer")
	z_index = 60
	grade_ligada = bool(Settings.get_value("jogo", "grade_construcao", true))
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
	_hint.add_theme_font_size_override("font_size", Tipo.TITULO)
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
	var af := IsoArt.footprint_of(get_tree(), art_name)
	if af.has_area():
		_footprint = af  # Bloco 132: a BASE do desenho, sem folga (a porta é conferida à parte, na frente)
	_ignore = opts.get("ignore", [])
	_cancelable = opts.get("cancelable", true)
	_radius = opts.get("radius", 0.0)
	_radius_center = opts.get("radius_center", Vector2.ZERO)
	_area = opts.get("area", Rect2())
	_area_name = opts.get("area_name", "da área")
	_extra_check = opts.get("check", Callable())  # Bloco 57: motivo extra ("" = pode)
	_repeat = opts.get("repeat", false)  # Bloco 90
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
	_repeat = false
	art_name = ""
	fantasma_celulas = Rect2i()
	fantasma_porta = Rect2i()
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
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == Teclas.tecla("painel_defesa"):
		get_viewport().set_input_as_handled()  # Bloco 132: enquanto posiciona, a tecla da Defesa liga/desliga a grade
		alterna_grade()


## Bloco 132: liga/desliga a grade de construção (fica nas configurações).
static func alterna_grade() -> void:
	grade_ligada = not grade_ligada
	Settings.set_value("jogo", "grade_construcao", grade_ligada)


## Tenta construir na posição atual do fantasma.
func try_confirm() -> bool:
	if not active:
		return false
	if _reason != "" and not _limpar_pendentes.is_empty():
		_limpa_pendentes()  # Bloco 132: o clique LIMPA a peça que atrapalha; o próximo constrói
		return false
	if _reason != "":
		Audio.error()
		var flash := create_tween()
		_ghost.scale = Vector2(2.15, 2.15)
		flash.tween_property(_ghost, "scale", Vector2(2, 2), 0.15)
		return false
	if _on_confirm.is_valid() and _on_confirm.call(_pos):
		Audio.place_sound()  # Bloco 55: estaca na terra
		if _repeat:  # Bloco 90: põe outra (a peça nova já conta como obstáculo)
			_collect_blockers()
			_refresh()
			return true
		_end(true)
		return true
	return false


## Bloco 132: paga e tira as peças do mapa que atrapalham o fantasma (sem reembolso).
func _limpa_pendentes() -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	var eco := get_tree().get_first_node_in_group("economy")
	var hud := get_tree().get_first_node_in_group("hud")
	if env == null or eco == null:
		return false
	var custo := float(int(env.custo_limpar) * _limpar_pendentes.size())
	if not eco.spend(custo, 0.0):
		Audio.error()
		if hud and hud.has_method("show_toast"):
			hud.show_toast("Limpar custa %d cr (faltam créditos)" % int(custo), COLOR_BAD)
		return false
	var iso := get_tree().get_first_node_in_group("iso_view")
	var n := 0
	for p in _limpar_pendentes:
		if is_instance_valid(p) and env.limpar_decor(p):
			n += 1
			if iso and iso.has_method("poeira_em"):
				iso.poeira_em((p as Node2D).global_position)
	Audio.place_sound()
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Terreno limpo: %d peça%s (−%d cr)" % [n, "" if n == 1 else "s", int(custo)], Color(0.95, 0.85, 0.5))
	_collect_blockers()
	_refresh()
	return n > 0


## Move o fantasma pra uma posição do mundo (usado pelos testes e pelo mouse).
func move_to(world_pos: Vector2) -> void:
	_pos = world_pos
	_refresh()


## "" se dá pra construir aqui; senão o motivo.
var _extra_check := Callable()


func check_spot(pos: Vector2) -> String:
	_ruins = {}
	_limpar_pendentes = []
	var fp := Rect2(pos + _footprint.position, _footprint.size)
	var env := get_tree().get_first_node_in_group("environment")
	if _area.has_area():
		if not _area.encloses(fp):
			return "fora %s" % _area_name
	elif env and env.has_method("in_forest") and env.in_forest(fp):
		return "fora da vila (além da paliçada é a floresta)"  # Prompt 29 / Bloco 74: a floresta é mata
	elif env and not env.walkable_rect().encloses(fp):
		return "fora da área da mina"
	if env and env.has_method("footprint_reason"):
		var why: String = env.footprint_reason(fp)  # Prompt 29: terraços (chão plano)
		if why != "":
			return why
	if _extra_check.is_valid():
		var extra: String = _extra_check.call(pos)
		if extra != "":
			return extra
	if _radius > 0.0 and pos.distance_to(_radius_center) > _radius:
		return "longe demais do Centro da Vila (a vila cresce e o raio aumenta)"
	# Bloco 132: por célula
	var cs := Grade.celulas(fp)
	var motivo := ""
	var limpar := {}
	for c in Grade.lista(cs):
		if ocupadas.has(c):
			_ruins[c] = true
			if _limpaveis.has(c):
				limpar[_limpaveis[c]] = true
			elif motivo == "":
				motivo = "em cima de %s" % ocupadas[c]
		elif portas.has(c):
			_ruins[c] = true
			if motivo == "":
				motivo = "na frente da porta de %s (a entrada precisa ficar livre)" % portas[c]
	var porta := _porta_de(cs)
	for c in Grade.lista(porta):
		if ocupadas.has(c):
			_ruins[c] = true
			if _limpaveis.has(c):
				limpar[_limpaveis[c]] = true
			elif motivo == "":
				motivo = "a entrada ficaria bloqueada por %s" % ocupadas[c]
		elif not _chao_ok(c):
			_ruins[c] = true
			if motivo == "":
				motivo = "a entrada daria pra fora do chão"
	if motivo != "":
		return motivo
	if not limpar.is_empty():
		_limpar_pendentes = limpar.keys()
		var custo := 0
		if env and env.get("custo_limpar") != null:
			custo = int(env.custo_limpar) * limpar.size()
		return "%s no caminho — clique pra LIMPAR (%d cr)" % ["uma peça" if limpar.size() == 1 else "%d peças" % limpar.size(), custo]
	return _confere_acesso(cs, porta)


## Bloco 132: a porta de um prédio de células `cs` (vazio = sem porta: decoração, prédio sem arte).
func _porta_de(cs: Rect2i) -> Rect2i:
	if art_name == "" or porta_celulas <= 0:
		return Rect2i()
	return Rect2i(cs.position.x, cs.end.y, cs.size.x, porta_celulas)


## Bloco 132: com o prédio posto em `cs`, a porta dele e as portas que chegavam ao Centro continuam ligadas à porta do
## Centro? "" = sim.
func _confere_acesso(cs: Rect2i, porta: Rect2i) -> String:
	if _fonte.is_empty():
		return ""
	var tampa := {}
	for c in Grade.lista(cs):
		tampa[c] = true
	var alcance := _alcance(tampa)
	if porta.has_area() and _regiao.intersects(porta):
		var chega := false
		for c in Grade.lista(porta):
			if alcance.has(c):
				chega = true
				break
		if not chega:
			for c in Grade.lista(porta):
				_ruins[c] = true
			return "a entrada ficaria sem caminho até o Centro da Vila"
	for p in _portas_ok0:
		var ok := false
		for c in p.celulas:
			if alcance.has(c):
				ok = true
				break
		if not ok:
			return "fecharia o acesso de %s" % p.nome
	return ""


## Células livres alcançadas a partir da porta do Centro (4 vizinhos), com `tampa` também ocupada.
func _alcance(tampa: Dictionary) -> Dictionary:
	var visto := {}
	var fila: Array[Vector2i] = []
	for c in _fonte:
		if not tampa.has(c):
			visto[c] = true
			fila.append(c)
	var i := 0
	while i < fila.size():
		var c: Vector2i = fila[i]
		i += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v: Vector2i = c + d
			if visto.has(v) or not _regiao.has_point(v) or ocupadas.has(v) or tampa.has(v) or not _chao_ok(v):
				continue
			visto[v] = true
			fila.append(v)
	return visto


## A célula é chão por onde se anda (fora de paredão, paliçada e do mapa)? Guardado por célula.
func _chao_ok(c: Vector2i) -> bool:
	if not _chao.has(c):
		var env := get_tree().get_first_node_in_group("environment")
		_chao[c] = env == null or not env.has_method("spot_ok") or env.spot_ok(Grade.centro(c), 0.0, true)
	return _chao[c]


func _refresh() -> void:
	_pos = _pos.round()
	# Bloco 76: perto de um lote livre (e cabendo nele), o prédio encaixa no meio do lote
	no_lote = false
	var env := get_tree().get_first_node_in_group("environment")
	if env and env.has_method("lote_perto") and not _area.has_area():
		var l: Vector2 = env.lote_perto(_pos)
		if l != Vector2.INF and check_spot(l) == "":
			_pos = l
			no_lote = true
	if not no_lote:
		_pos = Grade.encaixa(_pos, _footprint)  # Bloco 132: células inteiras (o lote livre é um terreno marcado: vai no meio dele)
	_reason = check_spot(_pos)
	fantasma_celulas = Grade.celulas(Rect2(_pos + _footprint.position, _footprint.size))
	fantasma_porta = _porta_de(fantasma_celulas)
	celulas_ruins = _ruins
	_ghost.position = _pos
	_ghost.modulate = Color(COLOR_OK, 0.6) if _reason == "" else Color(COLOR_BAD, 0.6)
	var cancel_txt := "  •  Esc ou botão direito cancela" if _cancelable else ""
	var grade_txt := "  •  %s: grade" % Teclas.nome("painel_defesa")
	if _reason == "":
		_hint.text = "Onde fica %s?  Clique pra construir%s%s%s" % [_what, "  •  no LOTE LIVRE" if no_lote else "", cancel_txt, grade_txt]
		_hint.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	elif not _limpar_pendentes.is_empty():
		_hint.text = "%s%s" % [_reason, ("\n" + cancel_txt.trim_prefix("  •  ")) if _cancelable else ""]
		_hint.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
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


## A ocupação da grade: a BASE de cada estrutura (sem folga), a porta na frente dela, as pedras/tochas e a decoração do
## jogador; e, pra busca do acesso, a porta do Centro e as portas que já chegam nele. (Calculado ao entrar no modo: nada se
## move enquanto você escolhe.)
func _collect_blockers() -> void:
	_blockers.clear()
	ocupadas.clear()
	portas.clear()
	_portas_lista.clear()
	_limpaveis.clear()
	_chao.clear()
	var env := get_tree().get_first_node_in_group("environment")
	var groups: Array = env.STATION_GROUPS + env.NAV_EXTRA_GROUPS if env else ["casas"]
	var vistos := {}
	for group in groups:
		for node in get_tree().get_nodes_in_group(group):
			if _ignore.has(node) or vistos.has(node):
				continue
			vistos[node] = true
			var nome := _display_name(node)
			var art := IsoArt.blocker_rect(node)
			if art.has_area():
				# Prompt 29: a pegada do desenho novo. Bloco 132: sem folga em volta; a porta na frente fica livre.
				_ocupa(art, nome)
				_porta(Grade.celulas(art), nome, node.is_in_group("village_hub"))
				continue
			var r := Rect2(node.global_position, Vector2.ZERO)
			if node.has_method("get_obstacle_outline"):
				var outline: PackedVector2Array = node.get_obstacle_outline()
				if outline.size() >= 3:
					r = _bbox(outline)
			# área de trabalho (slots) em volta, nos que não têm a arte nova (jazida, árvore, horta, toca)
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
			if r.has_area():
				_ocupa(r, nome)
	if env:
		var pecas: Array = env.pecas_limpaveis() if env.has_method("pecas_limpaveis") else []
		for o in env.decoration_obstacles():
			var bb := _bbox(o)
			var peca := _peca_perto(pecas, bb.get_center())
			_ocupa(bb, "uma pedra/decoração" if peca == null else "uma peça do mapa", peca)
	for dec in get_tree().get_nodes_in_group("decoracoes"):  # Bloco 90: a decoração do jogador
		if not _ignore.has(dec):
			_ocupa(dec.pegada_rect(), "a decoração (%s)" % String(dec.get("id")))
	_prepara_acesso(env)
	versao_ocupacao += 1


## A peça limpável a até 16 px de `p` (o obstáculo dela fica uns px acima do pé), ou null.
func _peca_perto(pecas: Array, p: Vector2) -> Node2D:
	var melhor: Node2D = null
	for n in pecas:
		var d := (n as Node2D).global_position.distance_to(p)
		if d <= 16.0 and (melhor == null or d < melhor.global_position.distance_to(p)):
			melhor = n
	return melhor


func _ocupa(r: Rect2, nome: String, limpavel: Node2D = null) -> void:
	_blockers.append({"rect": r, "name": nome})
	for c in Grade.lista(Grade.celulas(r)):
		if not ocupadas.has(c) or (limpavel == null and _limpaveis.has(c)):
			ocupadas[c] = nome
			if limpavel:
				_limpaveis[c] = limpavel
			else:
				_limpaveis.erase(c)


func _porta(cs: Rect2i, nome: String, do_centro := false) -> void:
	if porta_celulas <= 0:
		return
	var lst := Grade.lista(Rect2i(cs.position.x, cs.end.y, cs.size.x, porta_celulas))
	for c in lst:
		if not portas.has(c):
			portas[c] = nome
	_portas_lista.append({"nome": nome, "celulas": lst, "centro": do_centro})


## A busca do acesso: a região (área da vila no maior estágio, com margem), a porta do Centro (a fonte) e as portas que já
## chegam nela (só essas são cobradas: uma porta que já estava tapada antes não trava o jogador).
func _prepara_acesso(env: Node) -> void:
	_fonte.clear()
	_portas_ok0.clear()
	_regiao = Rect2i()
	if env == null or not env.has_method("area_vila"):
		return
	var area: Rect2 = env.area_vila(5)
	if not area.has_area():
		return
	_regiao = Grade.celulas(area.grow(Grade.CELULA * 4.0))
	for p in _portas_lista:
		if p.centro:
			for c in p.celulas:
				if not ocupadas.has(c) and _chao_ok(c):
					_fonte.append(c)
	if _fonte.is_empty():
		return
	var alcance := _alcance({})
	for p in _portas_lista:
		if p.centro:
			continue
		for c in p.celulas:
			if alcance.has(c):
				_portas_ok0.append(p)
				break


## Bloco 132: o prédio posto em `pos` conta como ocupado (a medição de quantos cabem; o jogo refaz pela árvore).
func ocupa_simulado(pos: Vector2) -> void:
	var cs := Grade.celulas(Rect2(pos + _footprint.position, _footprint.size))
	_ocupa(Grade.rect_de(cs), "simulado")
	var porta := _porta_de(cs)
	if porta.has_area():
		_porta(cs, "simulado")
		for c in Grade.lista(porta):
			if _regiao.has_point(c):
				_portas_ok0.append(_portas_lista[-1])
				break
	versao_ocupacao += 1


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
