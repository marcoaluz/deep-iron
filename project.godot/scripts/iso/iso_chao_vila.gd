extends Node2D
## Bloco 134: o CHÃO DA VILA com a arte do PixelLab, por cima do desenho antigo do terreno (terreno_fundo.png), na faixa da
## vila (environment.areas["vila"]: da paliçada até a mina).
##
## O desenho antigo tinha terra marrom repetida e chapada e manchas de mato oliva com borda dura (pintadas na imagem). Agora:
## - a TERRA BATIDA ocupa a mancha da vila — a área da vila do estágio (environment.area_vila) com a borda ondulada por
##   ruído (nada de retângulo) e um pouco de terra pisada em volta de cada prédio que fica fora dela; ela cresce quando a vila
##   sobe de estágio;
## - fora dela, o MATO baixo; a fronteira terra↔mato sai das 16 peças de transição pelos cantos (conjunto do PixelLab,
##   máscara NW<<3 | NE<<2 | SW<<1 | SE, bit = terra), então não há borda reta nem remendo;
## - junto da mina (faixa_mina) o chão volta a ser terra, pra emendar com a pedreira;
## - a PRAÇA do Centro: um largo de pedra em volta da base dele (`praca_celulas`, borda irregular), com as peças "terra x
##   pedra" dos caminhos — o desenho antigo tinha a praça pintada no terreno;
## - a variação vem de DETALHES SOLTOS (rachadura, pedrinha, tufo, talo seco) sorteados por célula e deslocados, nunca de
##   ladrilhos inteiros diferentes (que deixavam a grade à mostra).
## Desenho em LOTE: um MultiMesh pras células e outro pros detalhes, refeitos só quando a vila muda (estágio, Centro, prédios).

const ATLAS := "res://assets/game/iso/chao/chao134.png"
const DETALHES := "res://assets/game/iso/chao/chao134_detalhes.png"
const DADOS := "res://assets/game/iso/chao/chao134.json"
const Grade := preload("res://scripts/core/grade.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const SHADER_CELULA := """
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
const SHADER_DETALHE := """
shader_type canvas_item;
varying vec4 reg;
void vertex() {
	reg = INSTANCE_CUSTOM;
}
void fragment() {
	COLOR = texture(TEXTURE, reg.xy + vec2(UV.x, 1.0 - UV.y) * reg.zw);
}
"""

## Quanto a borda da vila ondula (fração do tamanho da área da vila; 0 = retângulo de cantos redondos).
@export var borda_ruido: float = 0.22
## Tamanho das ondas da borda (em células).
@export var borda_escala: float = 5.0
## Células de terra pisada em volta da base de cada prédio (os que ficam fora da mancha também ganham chão de terra).
@export var terra_em_volta: int = 2
## Chance de um detalhe solto por célula (0 a 1), na terra e no mato.
@export var detalhe_terra: float = 0.22
@export var detalhe_mato: float = 0.30
## Faixa (px do chão) do lado da mina em que o chão volta a ser terra (emenda com a pedreira).
@export var faixa_mina: float = 90.0
## Células de pedra em volta da base do Centro (a praça; 0 = sem praça).
@export var praca_celulas: int = 2
## Semente do ruído da borda e dos detalhes (a mesma vila sempre com o mesmo chão).
@export var semente: int = 134

static var _dados: Dictionary = {}
static var _lido := false
var _view: Node
var _mm: MultiMesh
var _mm_det: MultiMesh
var _assinatura := ""
## Quantas vezes o chão foi refeito e quantas células/detalhes desenha (pro teste e pro diagnóstico).
var refeitos := 0
var celulas := 0
var detalhes := 0


static func disponivel() -> bool:
	return ResourceLoader.exists(ATLAS) and ResourceLoader.exists(DETALHES) and not dados().is_empty()


static func dados() -> Dictionary:
	if not _lido:
		_lido = true
		if FileAccess.file_exists(DADOS):
			var j = JSON.parse_string(FileAccess.get_file_as_string(DADOS))
			if j is Dictionary:
				_dados = j
	return _dados


func setup(view: Node) -> void:
	_view = view
	name = "ChaoVila"
	var d := dados()
	_mm = _cria_mm(load(ATLAS), SHADER_CELULA, Vector2(float(d.get("largura", 64)), float(d.get("altura", 32))),
		Vector2(float(d.get("colunas", 16)), float((d.get("linhas", []) as Array).size())))
	_mm_det = _cria_mm(load(DETALHES), SHADER_DETALHE, Vector2.ONE, Vector2.ZERO)


func _cria_mm(tex: Texture2D, codigo: String, tam: Vector2, grade: Vector2) -> MultiMesh:
	var shader := Shader.new()
	shader.code = codigo
	var mat := ShaderMaterial.new()
	mat.shader = shader
	if grade != Vector2.ZERO:
		mat.set_shader_parameter("grade", grade)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = tam
	mm.mesh = q
	var mmi := MultiMeshInstance2D.new()
	mmi.multimesh = mm
	mmi.texture = tex
	mmi.material = mat
	mmi.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(mmi)
	return mm


## Chamado pela vista: refaz só se a vila mudou (estágio, lugar do Centro, quantos prédios).
func sincroniza() -> void:
	var env := get_tree().get_first_node_in_group("environment")
	var hub := get_tree().get_first_node_in_group("village_hub") as Node2D
	if env == null or not env.has_method("area_vila"):
		return
	var n := 0
	for g in env.STATION_GROUPS + env.NAV_EXTRA_GROUPS:
		n += get_tree().get_nodes_in_group(g).size()
	var a := "%s|%s|%d" % [str(hub.global_position) if hub else "-", str(hub.get("level")) if hub else "-", n]
	if a == _assinatura:
		return
	_assinatura = a
	refaz(env)


## A faixa da vila (px do chão): da paliçada até o começo da mina, na altura andável.
func regiao(env: Node) -> Rect2:
	var faixa: Array = env.areas.get("vila", []) if env.get("areas") is Dictionary else []
	var w: Rect2 = env.walkable_rect()
	if faixa.size() < 2:
		return w
	return Rect2(float(faixa[0]), w.position.y, float(faixa[1]) - float(faixa[0]), w.size.y)


## A ordem de desenho e a posição na tela de cada célula não mudam (o chão não anda): calculadas uma vez por região.
## Cada item: [posição na tela, célula, i, j].
var _ordem: Array = []
var _ordem_cs := Rect2i()
## O buffer do MultiMesh (12 floats por célula: a transformação 2D em 8 + o dado próprio em 4) — refazer o chão só troca
## os 2 floats da peça (máscara e linha do atlas) e manda o buffer inteiro de uma vez.
var _buf := PackedFloat32Array()


func _prepara_ordem(cs: Rect2i) -> void:
	if cs == _ordem_cs and not _ordem.is_empty():
		return
	_ordem_cs = cs
	var lista: Array = []
	for j in range(cs.size.y):
		for i in range(cs.size.x):
			var c := cs.position + Vector2i(i, j)
			var centro := Grade.centro(c)
			var s: Vector2 = _view.to_screen(centro, _view.height_at(centro))
			lista.append([s.round(), c, i, j])
	lista.sort_custom(func(a, b): return a[0].y < b[0].y or (a[0].y == b[0].y and a[0].x < b[0].x))
	_ordem = lista
	_mm.instance_count = lista.size()
	# o buffer montado aqui (o do servidor pode vir vazio): por célula, a transformação 2D no formato da Godot
	# (x.x, y.x, 0, origem.x, x.y, y.y, 0, origem.y) e o dado próprio (máscara, linha, 0, 0)
	_buf = PackedFloat32Array()
	_buf.resize(lista.size() * 12)
	for k in lista.size():
		var p: Vector2 = lista[k][0]
		var b := k * 12
		_buf[b] = 1.0
		_buf[b + 3] = p.x
		_buf[b + 5] = 1.0
		_buf[b + 7] = p.y
	_mm.buffer = _buf


func refaz(env: Node) -> void:
	refeitos += 1
	var reg := regiao(env)
	var cs := Grade.celulas(reg)
	_prepara_ordem(cs)
	var terra := _vertices_terra(env, cs, reg)
	var praca := _vertices_praca(cs)
	var linha_pedra := maxi((dados().get("linhas", []) as Array).find("pedra"), 0)
	var lista: Array = []  # [posição, máscara, célula, linha do atlas] (na ordem de desenho)
	lista.resize(_ordem.size())
	var nx := cs.size.x + 1
	var stride := 12
	for k in _ordem.size():
		var item: Array = _ordem[k]
		var a: int = int(item[3]) * nx + int(item[2])  # NW (cima); NE = a+1; SW = a+nx; SE = a+nx+1
		var m := 0
		var linha := 0
		if praca[a] == 1 or praca[a + 1] == 1 or praca[a + nx] == 1 or praca[a + nx + 1] == 1:
			linha = linha_pedra  # peça "terra x pedra": bit = o canto é terra (fora da praça)
			m = (8 if praca[a] == 0 else 0) | (4 if praca[a + 1] == 0 else 0) | (2 if praca[a + nx] == 0 else 0) | (1 if praca[a + nx + 1] == 0 else 0)
		else:
			m = (8 if terra[a] else 0) | (4 if terra[a + 1] else 0) | (2 if terra[a + nx] else 0) | (1 if terra[a + nx + 1] else 0)
		lista[k] = [item[0], m, item[1], linha]
		_buf[k * stride + 8] = float(m)
		_buf[k * stride + 9] = float(linha)
	_mm.buffer = _buf
	celulas = lista.size()
	_refaz_detalhes(lista)


## Os detalhes soltos: um sorteio estável por célula (o hash dela), só nas células inteiras de terra ou de mato.
func _refaz_detalhes(lista: Array) -> void:
	var d := dados()
	var regs: Dictionary = d.get("detalhes", {})
	var tex_w := 1.0
	var tex_h := 1.0
	var t: Texture2D = (_mm_det.get_meta("tex") if _mm_det.has_meta("tex") else null)
	if t == null:
		t = load(DETALHES)
		_mm_det.set_meta("tex", t)
	tex_w = float(t.get_width())
	tex_h = float(t.get_height())
	var sel: Array = []  # [posição, rect]
	for it in lista:
		var m: int = it[1]
		if (m != 15 and m != 0) or int(it[3]) != 0:
			continue
		var c: Vector2i = it[2]
		var h := _hash(c)
		var tipo := "terra" if m == 15 else "mato"
		var chance := detalhe_terra if m == 15 else detalhe_mato
		if float(h % 1000) / 1000.0 >= chance:
			continue
		var opcoes: Array = regs.get(tipo, [])
		if opcoes.is_empty():
			continue
		var r: Array = opcoes[(h / 1000) % opcoes.size()]
		var desloca := Vector2(float((h / 7) % 29) - 14.0, float((h / 13) % 13) - 6.0)
		sel.append([(it[0] as Vector2) + desloca, r])
	_mm_det.instance_count = sel.size()
	for k in sel.size():
		var r: Array = sel[k][1]
		var p: Vector2 = (sel[k][0] as Vector2).round()
		_mm_det.set_instance_transform_2d(k, Transform2D(Vector2(float(r[2]), 0.0), Vector2(0.0, float(r[3])), p))
		_mm_det.set_instance_custom_data(k, Color(float(r[0]) / tex_w, float(r[1]) / tex_h, float(r[2]) / tex_w, float(r[3]) / tex_h))
	detalhes = sel.size()


func _hash(c: Vector2i) -> int:
	return absi((c.x * 73856093) ^ (c.y * 19349663) ^ (semente * 83492791))


## Os vértices da grade (cs.size + 1 em cada eixo) que são TERRA: a mancha da vila (área do estágio com a borda ondulada),
## a terra pisada em volta dos prédios e a faixa junto da mina.
func _vertices_terra(env: Node, cs: Rect2i, reg: Rect2) -> PackedByteArray:
	var nx := cs.size.x + 1
	var ny := cs.size.y + 1
	var out := PackedByteArray()
	out.resize(nx * ny)
	var area: Rect2 = env.area_vila()
	var centro := area.get_center()
	var meia := area.size * 0.5
	var ruido := _ruido_grade(nx, ny)
	for j in ny:
		for i in nx:
			var p := Vector2(cs.position + Vector2i(i, j)) * Grade.CELULA
			var dentro := false
			if area.has_area():
				# um "retângulo de cantos redondos" (superelipse) com a borda empurrada pelo ruído
				var dx := absf(p.x - centro.x) / maxf(meia.x, 1.0)
				var dy := absf(p.y - centro.y) / maxf(meia.y, 1.0)
				var r := pow(pow(dx, 4.0) + pow(dy, 4.0), 0.25)
				dentro = r < 1.0 + (ruido[j * nx + i] - 0.5) * 2.0 * borda_ruido
			if not dentro and p.x > reg.end.x - faixa_mina * (0.6 + ruido[j * nx + i] * 0.8):
				dentro = true
			out[j * nx + i] = 1 if dentro else 0
	# terra pisada em volta dos prédios
	var vistos := {}
	for g in env.STATION_GROUPS + env.NAV_EXTRA_GROUPS:
		for n in get_tree().get_nodes_in_group(g):
			if vistos.has(n):
				continue
			vistos[n] = true
			var b := IsoArt.base_rect(n)
			if not b.has_area() or not reg.intersects(b):
				continue
			var bc := Grade.celulas(b).grow(terra_em_volta)
			for y in range(bc.position.y, bc.end.y + 1):
				for x in range(bc.position.x, bc.end.x + 1):
					var vi := x - cs.position.x
					var vj := y - cs.position.y
					if vi >= 0 and vj >= 0 and vi < nx and vj < ny:
						out[vj * nx + vi] = 1
	return out


## Os vértices da PRAÇA (1 = pedra): a base do Centro + `praca_celulas`, com os cantos do retângulo comidos pelo ruído.
func _vertices_praca(cs: Rect2i) -> PackedByteArray:
	var nx := cs.size.x + 1
	var ny := cs.size.y + 1
	var out := PackedByteArray()
	out.resize(nx * ny)
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub == null or praca_celulas <= 0:
		return out
	var b := IsoArt.base_rect(hub)
	if not b.has_area():
		return out
	var pc := Grade.celulas(b).grow(praca_celulas)
	for y in range(pc.position.y, pc.end.y + 1):
		for x in range(pc.position.x, pc.end.x + 1):
			var vi := x - cs.position.x
			var vj := y - cs.position.y
			if vi < 0 or vj < 0 or vi >= nx or vj >= ny:
				continue
			# nas beiradas do largo, o ruído decide (a borda fica irregular, sem retângulo)
			var borda := mini(mini(x - pc.position.x, pc.end.x - x), mini(y - pc.position.y, pc.end.y - y))
			if borda == 0 and _hash(Vector2i(x, y)) % 100 < 45:
				continue
			out[vj * nx + vi] = 1
	return out


## Ruído suave (valor interpolado) nos vértices, 0..1, estável pela semente.
func _ruido_grade(nx: int, ny: int) -> PackedFloat32Array:
	var esc := maxf(borda_escala, 1.0)
	var gx := int(nx / esc) + 3
	var gy := int(ny / esc) + 3
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var g := PackedFloat32Array()
	g.resize(gx * gy)
	for k in g.size():
		g[k] = rng.randf()
	var out := PackedFloat32Array()
	out.resize(nx * ny)
	for j in ny:
		for i in nx:
			var fx := i / esc
			var fy := j / esc
			var x0 := int(fx)
			var y0 := int(fy)
			var tx := fx - x0
			var ty := fy - y0
			tx = tx * tx * (3.0 - 2.0 * tx)
			ty = ty * ty * (3.0 - 2.0 * ty)
			var a := lerpf(g[y0 * gx + x0], g[y0 * gx + x0 + 1], tx)
			var b := lerpf(g[(y0 + 1) * gx + x0], g[(y0 + 1) * gx + x0 + 1], tx)
			out[j * nx + i] = lerpf(a, b, ty)
	return out
