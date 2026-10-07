extends RefCounted
## Prompt 28: VERIFICADOR "o sprite cabe na caixa" (regra 2 do docs/arte/CONTRATO_ARTE.md).
##
## Cada desenho (prédio, estágio, variação) declara uma caixa: pegada no chão relativa à
## ÂNCORA (o centro da pegada, no chão, no quadro da imagem) + altura. O desenho tem que caber
## na silhueta da caixa na tela (o hexágono dos 8 cantos projetados), com no máximo
## MAX_OUTSIDE pixels fora — é isso que garante que a ordem por caixas desenha certo.
##
## A conta é a mesma do pipeline de arte (prototipos/camera/arte_iso/predio.py, `_fora`), pra
## o jogo e a ferramenta concordarem pixel a pixel. Roda em cada arte importada (Prompt 29) e
## no teste tests/test_iso_arte.gd.

const MAX_OUTSIDE := 4
## Pixel conta como desenhado com alfa acima disto (o mesmo 40/255 do predio.py).
const ALPHA_MIN := 40


static func _iso(x: float, y: float, z: float) -> Vector2:
	return Vector2(x - y, (x + y) * 0.5 - z)


## Casco convexo (monotone chain, igual ao predio.py) dos cantos projetados.
static func silhouette(pegada: Rect2, h: float) -> PackedVector2Array:
	var pts := []
	for x in [pegada.position.x, pegada.end.x]:
		for y in [pegada.position.y, pegada.end.y]:
			for z in [0.0, h]:
				var p := _iso(x, y, z)
				if not pts.has(p):
					pts.append(p)
	pts.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
	var lo := []
	var up := []
	for q in pts:
		while lo.size() >= 2 and _cr(lo[-2], lo[-1], q) <= 0.0:
			lo.pop_back()
		lo.append(q)
	for i in range(pts.size() - 1, -1, -1):
		var q: Vector2 = pts[i]
		while up.size() >= 2 and _cr(up[-2], up[-1], q) <= 0.0:
			up.pop_back()
		up.append(q)
	var hull := PackedVector2Array()
	for k in lo.size() - 1:
		hull.append(lo[k])
	for k in up.size() - 1:
		hull.append(up[k])
	return hull


static func _cr(o: Vector2, a: Vector2, b: Vector2) -> float:
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)


## Quantos pixels desenhados ficam FORA da caixa. `anchor` = âncora no quadro (px);
## `pegada` = retângulo no chão relativo à âncora; `h` = altura.
static func pixels_outside(img: Image, anchor: Vector2, pegada: Rect2, h: float) -> int:
	var hull := silhouette(pegada, h)
	var n := hull.size()
	var out := 0
	var w := img.get_width()
	var hh := img.get_height()
	if img.get_format() != Image.FORMAT_RGBA8:
		img = img.duplicate()
		img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	for py in hh:
		for px in w:
			if data[(py * w + px) * 4 + 3] <= ALPHA_MIN:
				continue
			var sx := px + 0.5 - anchor.x
			var sy := py + 0.5 - anchor.y
			for k in n:
				var a := hull[k]
				var b := hull[(k + 1) % n]
				if (b.x - a.x) * (sy - a.y) - (b.y - a.y) * (sx - a.x) < -0.5:
					out += 1
					break
	return out


## Confere uma pasta de arte com contrato.json: [{nome, fora, ok}] por desenho.
static func check_folder(dir: String) -> Array:
	var out := []
	var path := dir.path_join("contrato.json")
	if not FileAccess.file_exists(path):
		return out
	var c = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(c) != TYPE_DICTIONARY or not c.has("caixas"):
		return out
	var anc: Array = c.get("ancora_no_quadro", [0, 0])
	for nome in c.caixas:
		var cx = c.caixas[nome]
		if typeof(cx) != TYPE_DICTIONARY or not cx.has("pegada_rel_ancora"):
			continue
		var file := dir.path_join(nome + ".png")
		if not FileAccess.file_exists(file):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(file))
		if img == null:
			continue
		img.convert(Image.FORMAT_RGBA8)
		var p: Array = cx.pegada_rel_ancora
		var peg := Rect2(p[0], p[1], p[2] - p[0], p[3] - p[1])
		var fora := pixels_outside(img, Vector2(anc[0], anc[1]), peg, cx.altura)
		out.append({"nome": nome, "fora": fora, "fora_contrato": cx.get("fora", -1), "ok": fora <= MAX_OUTSIDE})
	return out
