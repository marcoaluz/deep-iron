extends RefCounted
## Prompt 28: PALETAS DE PELE POR CÓDIGO (regra de diversidade do docs/arte/CONTRATO_ARTE.md).
##
## O mesmo desenho sai em pele clara, parda e negra trocando só as cores de pele, sem gerar
## arte nova. É a mesma regra do pipeline (prototipos/camera/arte_iso/tons_de_pele.py), pra o
## jogo e a ferramenta darem o mesmo resultado:
##   - as cores de pele saem do ROSTO (faixa de 10% a 30% da altura do desenho): capacete,
##     colete e luvas também são tons quentes;
##   - cor que aparece mais no corpo do que no rosto é roupa: no corpo ela não troca;
##   - cada cor de pele vira a cor de mesma luminosidade na rampa do tom (escuro -> claro).
## MÁSCARA POR QUADRO: numa folha de animação a regra roda quadro a quadro (a cabeça muda de
## lugar). O resultado fica em cache por (textura, tom).
##
## As rampas são as de paletas_pele.json (fonte única, lida também pelo tons_de_pele.py).

## Bloco 50: a cópia em assets/ vai no executável (o protótipo fica fora do build); o integra.py
## (bonecos) mantém as duas iguais. Sem a cópia, lê a do protótipo.
const RAMPS_FILE := "res://assets/game/iso/paletas_pele.json"
const RAMPS_FILE_PROTO := "res://prototipos/camera/arte_iso/paletas_pele.json"
const ALPHA_MIN := 40

static var _data := {}
static var _cache := {}


static func _load() -> void:
	if not _data.is_empty():
		return
	var f := RAMPS_FILE if FileAccess.file_exists(RAMPS_FILE) else RAMPS_FILE_PROTO
	var d = JSON.parse_string(FileAccess.get_file_as_string(f))
	if typeof(d) != TYPE_DICTIONARY:
		push_error("skin_palette: não li %s" % RAMPS_FILE)
		return
	_data = d


## Nomes dos tons ("clara", "parda", "negra").
static func tones() -> Array:
	_load()
	return _data.get("rampas", {}).keys()


static func ramp(tone: String) -> Array:
	_load()
	var out := []
	for c in _data.get("rampas", {}).get(tone, []):
		out.append(Vector3i(int(c[0]), int(c[1]), int(c[2])))
	return out


## (h, l, s) igual ao colorsys.rgb_to_hls do Python.
static func rgb_to_hls(r8: int, g8: int, b8: int) -> Vector3:
	var r := r8 / 255.0
	var g := g8 / 255.0
	var b := b8 / 255.0
	var maxc := maxf(r, maxf(g, b))
	var minc := minf(r, minf(g, b))
	var sumc := maxc + minc
	var rangec := maxc - minc
	var l := sumc / 2.0
	if minc == maxc:
		return Vector3(0.0, l, 0.0)
	var s := rangec / sumc if l <= 0.5 else rangec / (2.0 - sumc)
	var rc := (maxc - r) / rangec
	var gc := (maxc - g) / rangec
	var bc := (maxc - b) / rangec
	var h: float
	if r == maxc:
		h = bc - gc
	elif g == maxc:
		h = 2.0 + rc - bc
	else:
		h = 4.0 + gc - rc
	h = fposmod(h / 6.0, 1.0)
	return Vector3(h, l, s)


static func is_skin(r: int, g: int, b: int) -> bool:
	var hls := rgb_to_hls(r, g, b)
	return hls.x >= 0.0 and hls.x <= 0.11 and hls.y >= 0.18 and hls.y <= 0.82 \
		and hls.z >= 0.18 and hls.z <= 0.75 and r > g and g > b


static func _key(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8


## As cores de pele de UM quadro: {solta: {cor: true}, estrita: {cor: true}, y_cab: int}.
static func skin_colors(img: Image, rect: Rect2i) -> Dictionary:
	var used := img.get_region(rect).get_used_rect()
	if used.size.x <= 0:
		return {"solta": {}, "estrita": {}, "y_cab": rect.position.y}
	var bx0 := rect.position.x + used.position.x
	var by0 := rect.position.y + used.position.y
	var bx1 := bx0 + used.size.x
	var by1 := by0 + used.size.y
	var h := used.size.y
	var y0 := by0 + int(h * 0.10)
	var y1 := by0 + int(h * 0.30)
	var cols := {}
	for y in range(y0, y1):
		for x in range(bx0, bx1):
			var p := img.get_pixel(x, y)
			if p.a8 > ALPHA_MIN and is_skin(p.r8, p.g8, p.b8) and rgb_to_hls(p.r8, p.g8, p.b8).z <= 0.6:
				var k := _key(p)
				cols[k] = cols.get(k, 0) + 1
	var corpo := {}
	for y in range(y1, by1):
		for x in range(bx0, bx1):
			var p := img.get_pixel(x, y)
			if p.a8 > ALPHA_MIN and cols.has(_key(p)):
				var k := _key(p)
				corpo[k] = corpo.get(k, 0) + 1
	var solta := {}
	var estrita := {}
	for k in cols:
		if cols[k] >= 2:
			solta[k] = true
			if corpo.get(k, 0) <= cols[k]:
				estrita[k] = true
	return {"solta": solta, "estrita": estrita, "y_cab": y1}


## Troca a pele de um quadro (rect) da imagem, no lugar. Retorna quantos pixels trocou.
static func recolor_frame(img: Image, rect: Rect2i, tone_ramp: Array) -> int:
	_load()
	var sk := skin_colors(img, rect)
	if sk.solta.is_empty() or tone_ramp.is_empty():
		return 0
	var lum: Array = _data.get("luminosidade_da_pele", [0.22, 0.62])
	var lo: float = lum[0]
	var hi: float = lum[1]
	var mapa := {}
	for k: int in sk.solta:
		var r: int = (k >> 16) & 255
		var g: int = (k >> 8) & 255
		var b: int = k & 255
		var t := clampf((rgb_to_hls(r, g, b).y - lo) / (hi - lo), 0.0, 1.0)
		var i := t * (tone_ramp.size() - 1)
		var a: Vector3i = tone_ramp[int(i)]
		var c: Vector3i = tone_ramp[mini(int(i) + 1, tone_ramp.size() - 1)]
		var f := i - int(i)
		mapa[k] = Color8(roundi(a.x + (c.x - a.x) * f), roundi(a.y + (c.y - a.y) * f), roundi(a.z + (c.z - a.z) * f))
	var n := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var p := img.get_pixel(x, y)
			if p.a8 <= ALPHA_MIN:
				continue
			var k := _key(p)
			if mapa.has(k) and (y < sk.y_cab or sk.estrita.has(k)):
				var m: Color = mapa[k]
				m.a = p.a
				img.set_pixel(x, y, m)
				n += 1
	return n


## A folha inteira (hframes × vframes quadros), quadro a quadro. Devolve uma imagem nova.
static func recolor_sheet(src: Image, tone: String, hframes: int = 1, vframes: int = 1) -> Image:
	var img := src.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var rmp := ramp(tone)
	var fw: int = img.get_width() / maxi(hframes, 1)
	var fh: int = img.get_height() / maxi(vframes, 1)
	for vy in vframes:
		for hx in hframes:
			recolor_frame(img, Rect2i(hx * fw, vy * fh, fw, fh), rmp)
	return img


## Textura com a pele do tom (cache por textura + tom + grade de quadros).
static func texture_for(tex: Texture2D, tone: String, hframes: int = 1, vframes: int = 1) -> Texture2D:
	if tex == null or tone == "":
		return tex
	var key := "%s|%s|%d|%d" % [tex.get_rid(), tone, hframes, vframes]
	if _cache.has(key):
		return _cache[key]
	var out := ImageTexture.create_from_image(recolor_sheet(tex.get_image(), tone, hframes, vframes))
	_cache[key] = out
	return out
