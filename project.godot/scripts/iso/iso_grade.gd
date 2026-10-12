extends Node2D
## Bloco 132: a VISÃO DE CONSTRUÇÃO — a grade de células (grade.gd) desenhada em losangos no chão da área da vila.
##
## Aparece com o menu CONSTRUIR aberto ou com qualquer ferramenta de posicionar (prédio, casa, decoração, pincel de caminho),
## se a grade estiver ligada (a tecla da Defesa, G, enquanto posiciona). Cores:
##   - célula livre: só a linha da grade, em tom neutro;
##   - ocupada (base de prédio, pedra, decoração): vermelho suave; a PORTA de um prédio (a fileira da frente que fica livre):
##     amarelo bem fraco;
##   - o fantasma, célula a célula: verde onde cabe, vermelho onde não (o motivo vai escrito no topo da tela, pelo
##     posicionador); a porta dele em verde/vermelho mais claro.
## Desenho barato: o losango de cada célula é calculado UMA vez (a posição na tela do chão não muda com a câmera); a camada da
## grade só é refeita quando a parte visível ou a ocupação mudam, e a do fantasma quando ele muda — cada uma num único
## lote de triângulos + um de linhas.

const Grade := preload("res://scripts/core/grade.gd")
const HousePlacer := preload("res://scripts/core/house_placer.gd")
## Teto de células desenhadas (vista muito longe: a grade some antes de virar um borrão caro).
const MAX_CELULAS := 6000
const COR_LINHA := Color(1.0, 0.97, 0.88, 0.16)
const COR_OCUPADA := Color(1.0, 0.36, 0.3, 0.22)
const COR_PORTA := Color(1.0, 0.86, 0.42, 0.12)
const COR_CABE := Color(0.45, 1.0, 0.5, 0.42)
const COR_NAO := Color(1.0, 0.3, 0.25, 0.55)
const COR_PORTA_CABE := Color(0.45, 1.0, 0.5, 0.2)
const COR_PORTA_NAO := Color(1.0, 0.3, 0.25, 0.28)

var _view: Node
var _base: Node2D
var _fantasma: Node2D
var _losangos := {}  # célula -> PackedVector2Array (4 pontos na tela)
var _chave_base := ""
var _chave_fantasma := ""
var _celulas_vis: Rect2i
## Quantas vezes a camada da grade foi refeita (o teste confere que não é todo quadro).
var refeitos := 0


func setup(view: Node) -> void:
	_view = view
	name = "GradeConstrucao"
	_base = Node2D.new()
	_base.name = "Base"
	add_child(_base)
	_base.draw.connect(_desenha_base)
	_fantasma = Node2D.new()
	_fantasma.name = "Fantasma"
	add_child(_fantasma)
	_fantasma.draw.connect(_desenha_fantasma)
	visible = false


func _hp() -> Node:
	return get_tree().get_first_node_in_group("house_placer")


## Deve aparecer agora? (menu CONSTRUIR aberto ou uma ferramenta de posicionar ligada, e a grade ligada)
func deve_mostrar() -> bool:
	if not HousePlacer.grade_ligada:
		return false
	var hp := _hp()
	if hp and hp.active:
		return true
	var cp := get_tree().get_first_node_in_group("caminho_placer")
	if cp and cp.get("active"):
		return true
	var menu := get_tree().get_first_node_in_group("menu_construir")
	return menu != null and menu.is_visible_in_tree()


## Chamado pela vista a cada quadro: liga/desliga e refaz só o que mudou.
func sincroniza() -> void:
	var on := deve_mostrar()
	if on != visible:
		visible = on
		if on:
			var hp := _hp()
			if hp and not hp.active:
				hp._collect_blockers()  # (o pincel e o menu: a ocupação de agora, sem prédio no fantasma)
		_chave_base = ""
		_chave_fantasma = ""
	if not on:
		return
	var hp := _hp()
	var env := get_tree().get_first_node_in_group("environment")
	if hp == null or env == null:
		return
	var area: Rect2 = env.area_vila() if env.has_method("area_vila") else Rect2()
	var vis: Rect2 = _view.ground_view_rect()
	var r := vis.intersection(area) if area.has_area() else Rect2()
	if hp.active:  # (fora da área da vila — clareira, pedreira — a grade acompanha o fantasma)
		var em_volta: Rect2 = Grade.rect_de(hp.fantasma_celulas).grow(Grade.CELULA * 8.0).intersection(vis)
		r = r.merge(em_volta) if r.has_area() else em_volta
	_celulas_vis = Grade.celulas(r) if r.has_area() else Rect2i()
	var chave := "%s|%d" % [str(_celulas_vis), int(hp.versao_ocupacao)]
	if chave != _chave_base:
		_chave_base = chave
		refeitos += 1
		_base.queue_redraw()
	var cf := ""
	if hp.active:
		cf = "%s|%s|%s|%d" % [str(hp.fantasma_celulas), str(hp.fantasma_porta), hp._reason, hp.celulas_ruins.size()]
	if cf != _chave_fantasma:
		_chave_fantasma = cf
		_fantasma.queue_redraw()


func _losango(c: Vector2i) -> PackedVector2Array:
	if not _losangos.has(c):
		var r := Grade.rect(c)
		var z: float = _view.height_at(r.get_center())
		_losangos[c] = PackedVector2Array([_view.to_screen(r.position, z), _view.to_screen(Vector2(r.end.x, r.position.y), z),
			_view.to_screen(r.end, z), _view.to_screen(Vector2(r.position.x, r.end.y), z)])
	return _losangos[c]


func _desenha_base() -> void:
	var cs := _celulas_vis
	if cs.get_area() <= 0 or cs.get_area() > MAX_CELULAS:
		return
	var hp := _hp()
	var linhas := PackedVector2Array()
	var pts := PackedVector2Array()
	var cores := PackedColorArray()
	for c in Grade.lista(cs):
		var l := _losango(c)
		linhas.append_array([l[0], l[1], l[1], l[2], l[2], l[3], l[3], l[0]])
		if hp.ocupadas.has(c):
			_quad(pts, cores, l, COR_OCUPADA)
		elif hp.portas.has(c):
			_quad(pts, cores, l, COR_PORTA)
	_tris(_base, pts, cores)
	_base.draw_multiline(linhas, COR_LINHA, 1.0)


func _desenha_fantasma() -> void:
	var hp := _hp()
	if hp == null or not hp.active:
		return
	var pts := PackedVector2Array()
	var cores := PackedColorArray()
	var ok: bool = hp._reason == ""
	var ruins: Dictionary = hp.celulas_ruins
	for c in Grade.lista(hp.fantasma_celulas):
		_quad(pts, cores, _losango(c), COR_CABE if ok or not (ruins.is_empty() or ruins.has(c)) else COR_NAO)
	if (hp.fantasma_porta as Rect2i).has_area():
		for c in Grade.lista(hp.fantasma_porta):
			_quad(pts, cores, _losango(c), COR_PORTA_CABE if ok or not (ruins.is_empty() or ruins.has(c)) else COR_PORTA_NAO)
	_tris(_fantasma, pts, cores)


## Dois triângulos de um losango, com a cor.
func _quad(pts: PackedVector2Array, cores: PackedColorArray, l: PackedVector2Array, cor: Color) -> void:
	pts.append_array([l[0], l[1], l[2], l[0], l[2], l[3]])
	for i in 6:
		cores.append(cor)


## Todos os triângulos num lote só.
func _tris(no: Node2D, pts: PackedVector2Array, cores: PackedColorArray) -> void:
	if pts.is_empty():
		return
	var idx := PackedInt32Array()
	idx.resize(pts.size())
	for i in pts.size():
		idx[i] = i
	RenderingServer.canvas_item_add_triangle_array(no.get_canvas_item(), idx, pts, cores)


## Pro teste e pras capturas: as células desenhadas agora.
func celulas_visiveis() -> Rect2i:
	return _celulas_vis
