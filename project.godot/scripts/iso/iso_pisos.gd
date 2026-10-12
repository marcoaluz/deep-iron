extends Node2D
## Bloco 130: os PISOS (caminhos) com a arte do PixelLab, desenhados em LOTE.
##
## - A arte: assets/game/iso/pisos/pisos.png (o atlas dos 3 tipos: terra, cascalho e pedra; `python pisos130.py integra`
##   em prototipos/camera/arte_iso/pisos, a partir dos ladrilhos do PixelLab). Cada tipo tem VARIANTES colunas (variações
##   do ladrilho, uma por hash da célula) x 4 linhas (as lajes à mostra: bit 1 = sem vizinho em +y, a da esquerda; bit 2 =
##   sem vizinho em +x, a da direita). A peça é escolhida pelos vizinhos de cada célula: entre dois ladrilhos só o topo
##   (a trilha lê contínua) e a laje só onde o caminho acaba. O mesmo atlas faz os cartões do CONSTRUIR e o fantasma.
## - O desenho: UM MultiMeshInstance2D (uma instância por célula, na ordem de profundidade), refeito só quando os
##   caminhos mudam (`versao` do caminhos.gd) e no máximo uma vez por quadro. Nada de refazer polígono por célula: uma
##   trilha de milhares de células é um único desenho.
## - Terraços: cada instância sobe pela altura do chão (iso_view.height_at), como o desenho antigo.
## - Fantasma do pincel: o ladrilho de verdade (topo do tipo) na célula do mouse, verde (dá) ou vermelho (não dá), com o
##   custo ou o que falta escrito.

const ATLAS := "res://assets/game/iso/pisos/pisos.png"
const DADOS := "res://assets/game/iso/pisos/pisos.json"
const Tipo := preload("res://scripts/ui/tipografia.gd")

const SHADER_CODIGO := """
shader_type canvas_item;
uniform vec2 grade = vec2(8.0, 9.0);
varying vec2 cel;
void vertex() {
	cel = INSTANCE_CUSTOM.xy;
}
void fragment() {
	COLOR = texture(TEXTURE, (UV + cel) / grade);
}
"""

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


## A máscara dos vizinhos da célula `c` que NÃO são caminho (bit 1 = -y, 2 = +x, 4 = +y, 8 = -x).
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


## A variação do ladrilho da célula (estável: o mesmo caminho nunca "muda" de desenho).
static func variante(c: Vector2i, quantas: int) -> int:
	return absi((c.x * 73856093) ^ (c.y * 19349663)) % maxi(quantas, 1)


## Que lajes ficam à mostra na célula `c` (0 nenhuma, 1 a da esquerda: sem vizinho em +y, 2 a da direita: sem vizinho em +x).
static func exposicao(celulas: Dictionary, c: Vector2i) -> int:
	var e := 0
	if not celulas.has(c + Vector2i(0, 1)):
		e |= 1
	if not celulas.has(c + Vector2i(1, 0)):
		e |= 2
	return e


## Onde a peça está no atlas: [coluna, linha] — a coluna é a variação do ladrilho, a linha o tipo e as lajes à mostra.
static func lugar_no_atlas(tipo: String, variante_i: int, expos: int) -> Vector2:
	var d := dados()
	var tipos: Array = d.get("tipos", [])
	var i := maxi(tipos.find(tipo), 0)
	var por_tipo: int = int(d.get("linhas_por_tipo", 4))
	var cols: int = int(d.get("colunas", 8))
	return Vector2(variante_i % cols, i * por_tipo + clampi(expos, 0, por_tipo - 1))


func setup(view: Node) -> void:
	_view = view
	name = "PisosIso"
	var d := dados()
	_tex = load(ATLAS)
	var shader := Shader.new()
	shader.code = SHADER_CODIGO
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var linhas: int = int(d.get("linhas_por_tipo", 4)) * (d.get("tipos", []) as Array).size()
	mat.set_shader_parameter("grade", Vector2(float(d.get("colunas", 8)), float(linhas)))
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(float(d.get("largura", 64)), float(d.get("celula_h", 64)))
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
	var d := dados()
	var vars: int = int(d.get("variantes", 3))
	var lista: Array = []
	for c in celulas:
		var centro: Vector2 = cam.centro_de(c)
		var h: float = _view.height_at(centro)
		var s: Vector2 = _view.to_screen(centro, h)
		lista.append([s.y, s.x, c, s])
	lista.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var dados_inst: Array = []  # [posição, lugar no atlas]
	for it in lista:
		var c: Vector2i = it[2]
		var tipo: String = celulas[c]
		dados_inst.append([it[3], lugar_no_atlas(tipo, variante(c, vars), exposicao(celulas, c))])
	var n: int = dados_inst.size()
	_mm.instance_count = n
	for i in n:
		var inst: Array = dados_inst[i]
		_mm.set_instance_transform_2d(i, Transform2D(0.0, (inst[0] as Vector2).round()))
		var lugar: Vector2 = inst[1]
		_mm.set_instance_custom_data(i, Color(lugar.x, lugar.y, 0.0, 0.0))
	_instancias = n


## Quantas instâncias estão desenhadas (pro teste: uma por célula).
func instancias() -> int:
	return _instancias


func celulas_desenhadas() -> int:
	return _celulas


## O fantasma do pincel: o topo do tipo na célula `c` (verde = dá, vermelho = não), com o texto (custo / o que falta).
func mostra_fantasma(cam: Node, c: Vector2i, tipo: String, ok: bool, texto: String) -> void:
	var d := dados()
	var celula_h: int = int(d.get("celula_h", 64))
	var w: int = int(d.get("largura", 64))
	var t := tipo if tipo in (d.get("tipos", []) as Array) else "terra"
	var lugar := lugar_no_atlas(t, 0, 3)  # o ladrilho inteiro (com as duas lajes)
	var at := AtlasTexture.new()
	at.atlas = _tex
	at.region = Rect2(lugar.x * w, lugar.y * celula_h, w, celula_h)
	_fantasma.texture = at
	var centro: Vector2 = cam.centro_de(c)
	var s: Vector2 = _view.to_screen(centro, _view.height_at(centro))
	_fantasma.position = s.round()
	_fantasma.modulate = Color(0.75, 1.0, 0.7, 0.78) if ok else Color(1.0, 0.45, 0.4, 0.78)
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
