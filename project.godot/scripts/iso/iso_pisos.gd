extends Node2D
## Bloco 130 / 134: os PISOS (caminhos) com a arte do PixelLab, desenhados em LOTE.
##
## Bloco 134: a arte é a do chão da vila (assets/game/iso/chao/chao134.png, `chao134.py integra` em
## prototipos/camera/arte_iso/chao134): por tipo (terra, cascalho, pedra) as 16 peças de TRANSIÇÃO "terra batida x caminho"
## pelos cantos (máscara NW<<3 | NE<<2 | SW<<1 | SE; bit = o canto é terra). Antes (Bloco 130) cada célula era um ladrilho
## inteiro com laje na ponta, e a trilha lia como tábuas soltas; agora:
## - cada célula pintada marca os 4 VÉRTICES dela com o tipo (pedra > cascalho > terra quando dois se encontram);
## - toda célula com algum vértice de caminho é desenhada com a peça pelos cantos, então a borda da trilha se mistura com a
##   terra em volta, e curva, T, cruzamento e ponta saem sozinhos (emenda automática pelos vizinhos);
## - o mesmo atlas faz os cartões do CONSTRUIR e o fantasma do pincel (o caminho inteiro, máscara 0).
## - O desenho: UM MultiMeshInstance2D, refeito só quando os caminhos mudam (`versao` do caminhos.gd).
## - Terraços: cada instância sobe pela altura do chão (iso_view.height_at).

const ATLAS := "res://assets/game/iso/chao/chao134.png"
const DADOS := "res://assets/game/iso/chao/chao134.json"
const Tipo := preload("res://scripts/ui/tipografia.gd")
const SHADER_CODIGO := """
shader_type canvas_item;
uniform vec2 grade = vec2(16.0, 4.0);
varying vec2 cel;
void vertex() {
	cel = INSTANCE_CUSTOM.xy;
}
void fragment() {
	COLOR = texture(TEXTURE, (vec2(UV.x, 1.0 - UV.y) + cel) / grade);  // (o QuadMesh no 2D vira a textura de cabeça pra baixo)
}
"""
## Quem ganha o vértice quando dois tipos se encontram.
const PRIORIDADE := {"terra": 1, "cascalho": 2, "pedra": 3}
static var _dados: Dictionary = {}
static var _lido := false
var _view: Node
var _mmi: MultiMeshInstance2D
var _mm: MultiMesh
var _tex: Texture2D
var _fantasma: Sprite2D
var _fantasma_texto: Label
var _instancias := 0
var _celulas := 0
## Quantas vezes o desenho foi refeito (o teste confere que só refaz quando os caminhos mudam).
var refeitos := 0


## O atlas existe (a arte integrada)?
static func disponivel() -> bool:
	return ResourceLoader.exists(ATLAS) and not dados().is_empty()


static func dados() -> Dictionary:
	if not _lido:
		_lido = true
		if FileAccess.file_exists(DADOS):
			var j = JSON.parse_string(FileAccess.get_file_as_string(DADOS))
			if j is Dictionary:
				_dados = j
	return _dados


## A linha do atlas do tipo de caminho (a 0 é o mato da vila).
static func linha_do_tipo(tipo: String) -> int:
	return maxi((dados().get("linhas", ["mato", "terra", "cascalho", "pedra"]) as Array).find(tipo), 1)


## A máscara dos vizinhos da célula `c` que NÃO são caminho (bit 1 = -y, 2 = +x, 4 = +y, 8 = -x). (Bloco 130; diagnóstico.)
static func mascara(celulas: Dictionary, c: Vector2i) -> int:
	var m := 0
	if not celulas.has(c + Vector2i(0, -1)):
		m |= 1
	if not celulas.has(c + Vector2i(1, 0)):
		m |= 2
	if not celulas.has(c + Vector2i(0, 1)):
		m |= 4
	if not celulas.has(c + Vector2i(-1, 0)):
		m |= 8
	return m


## Os vértices de caminho: vértice (x, y) = canto de cima (NW) da célula (x, y). Valor = o tipo que ganhou.
static func vertices(celulas: Dictionary) -> Dictionary:
	var v := {}
	for c in celulas:
		var t: String = celulas[c]
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var p: Vector2i = c + d
			if not v.has(p) or int(PRIORIDADE.get(t, 0)) > int(PRIORIDADE.get(v[p], 0)):
				v[p] = t
	return v


## A peça da célula `c`: [tipo, máscara] (máscara: bit ligado = o canto é terra; tipo "" = sem caminho).
static func peca(v: Dictionary, c: Vector2i) -> Array:
	var cantos := [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]  # NW (cima), NE (dir.), SW (esq.), SE (baixo)
	var tipo := ""
	for p in cantos:
		if v.has(p) and int(PRIORIDADE.get(v[p], 0)) > int(PRIORIDADE.get(tipo, 0)):
			tipo = v[p]
	if tipo == "":
		return ["", 15]
	var m := 0
	var bits := [8, 4, 2, 1]
	for k in 4:
		if v.get(cantos[k], "") != tipo:
			m |= bits[k]
	return [tipo, m]


func setup(view: Node) -> void:
	_view = view
	name = "PisosIso"
	var d := dados()
	_tex = load(ATLAS)
	var shader := Shader.new()
	shader.code = SHADER_CODIGO
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("grade", Vector2(float(d.get("colunas", 16)), float((d.get("linhas", []) as Array).size())))
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(float(d.get("largura", 64)), float(d.get("altura", 32)))
	_mm.mesh = q
	_mmi = MultiMeshInstance2D.new()
	_mmi.multimesh = _mm
	_mmi.texture = _tex
	_mmi.material = mat
	_mmi.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_mmi)
	# o fantasma do pincel
	_fantasma = Sprite2D.new()
	_fantasma.name = "Fantasma"
	_fantasma.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fantasma.visible = false
	_fantasma.z_index = 2
	add_child(_fantasma)
	_fantasma_texto = Label.new()
	_fantasma_texto.add_theme_font_size_override("font_size", Tipo.MAPA)
	_fantasma_texto.add_theme_color_override("font_outline_color", Tipo.CONTORNO_MAPA)
	_fantasma_texto.add_theme_constant_override("outline_size", Tipo.CONTORNO_MAPA_PX)
	if Tipo.fonte() != null:
		_fantasma_texto.add_theme_font_override("font", Tipo.fonte())
	_fantasma_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fantasma_texto.custom_minimum_size = Vector2(120, 0)
	_fantasma_texto.position = Vector2(-60, -34)
	_fantasma_texto.visible = false
	_fantasma_texto.z_index = 3
	add_child(_fantasma_texto)


## Refaz o desenho com as células de `cam` (nó Caminhos). Ordem: de trás pra frente (y da tela, depois x).
func refaz(cam: Node) -> void:
	refeitos += 1
	var celulas: Dictionary = cam.celulas
	_celulas = celulas.size()
	var v := vertices(celulas)
	var desenhar := {}  # célula -> true (as pintadas e as em volta que têm algum vértice de caminho)
	for p in v:
		for d in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
			desenhar[p + d] = true
	var lista: Array = []
	for c in desenhar:
		var pc := peca(v, c)
		if pc[0] == "":
			continue
		var centro: Vector2 = cam.centro_de(c)
		var s: Vector2 = _view.to_screen(centro, _view.height_at(centro))
		lista.append([s.y, s.x, s, Vector2(float(pc[1]), float(linha_do_tipo(pc[0])))])
	lista.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var n: int = lista.size()
	_mm.instance_count = n
	for i in n:
		_mm.set_instance_transform_2d(i, Transform2D(0.0, (lista[i][2] as Vector2).round()))
		var lugar: Vector2 = lista[i][3]
		_mm.set_instance_custom_data(i, Color(lugar.x, lugar.y, 0.0, 0.0))
	_instancias = n


## Quantas instâncias estão desenhadas (as células pintadas e a borda em volta).
func instancias() -> int:
	return _instancias


func celulas_desenhadas() -> int:
	return _celulas


## O fantasma do pincel: o caminho inteiro do tipo na célula `c` (verde = dá, vermelho = não), com o texto (custo / falta).
func mostra_fantasma(cam: Node, c: Vector2i, tipo: String, ok: bool, texto: String) -> void:
	var d := dados()
	var w: int = int(d.get("largura", 64))
	var h: int = int(d.get("altura", 32))
	var at := AtlasTexture.new()
	at.atlas = _tex
	at.region = Rect2(0, linha_do_tipo(tipo if PRIORIDADE.has(tipo) else "terra") * h, w, h)
	_fantasma.texture = at
	var centro: Vector2 = cam.centro_de(c)
	var s: Vector2 = _view.to_screen(centro, _view.height_at(centro))
	_fantasma.position = s.round()
	_fantasma.modulate = Color(0.75, 1.0, 0.7, 0.85) if ok else Color(1.0, 0.45, 0.4, 0.85)
	_fantasma.visible = true
	_fantasma_texto.text = texto
	_fantasma_texto.add_theme_color_override("font_color", Color(0.9, 1.0, 0.8) if ok else Color(1.0, 0.6, 0.5))
	_fantasma_texto.position = s.round() + Vector2(-60, -40)
	_fantasma_texto.visible = texto != ""


func esconde_fantasma() -> void:
	if _fantasma:
		_fantasma.visible = false
	if _fantasma_texto:
		_fantasma_texto.visible = false


func fantasma_visivel() -> bool:
	return _fantasma != null and _fantasma.visible
