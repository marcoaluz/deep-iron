extends RefCounted
## PROTÓTIPO ROTA A (endurecida): o núcleo reutilizável do isométrico, sem cena nenhuma.
##
## Tudo que existe no mundo é uma CAIXA no chão: retângulo (x, y) + altura da base (zb) e do
## topo (zt). Prédio, pedaço de terreno (platô, beira de buraco), ipezinho — tudo caixa. A
## partir disso, sem configurar nada por prédio:
##   - iso() / iso_inv(): projeção 2:1 e a volta (tela -> chão numa altura)
##   - behind(): quem fica ATRÁS de quem (a "verdade" 3D, separação por eixo)
##   - topo_order(): ordem de desenho correta pra um conjunto de caixas (sem fatiar nada)
##   - slice_rect(): o fatiamento automático (a alternativa com y_sort do Godot)
##   - pick(): o que está embaixo do mouse, lançando o "raio" da câmera pelas caixas

class Box:
	var rect: Rect2
	var zb: float
	var zt: float
	var kind: String  # "predio", "terreno", "ipezinho", "rampa"...
	var name: String
	var owner = null  # quem é (Building, Worker, bloco de terreno)
	var ramp_axis := Vector2.ZERO  # rampa: direção em que o chão SOBE (topo inclinado)
	var hide: Array = []  # faces que não se desenham (enterradas no chão): "top", "left", "right"

	func _init(r: Rect2, b: float, t: float, k: String, n: String = "", o = null) -> void:
		rect = r
		zb = b
		zt = t
		kind = k
		name = n
		owner = o


static func iso(p: Vector2, z: float = 0.0) -> Vector2:
	return Vector2(p.x - p.y, (p.x + p.y) * 0.5 - z)


## Tela -> chão, supondo que o ponto está na altura z.
static func iso_inv(s: Vector2, z: float = 0.0) -> Vector2:
	var sy := s.y + z
	return Vector2((s.x + 2.0 * sy) * 0.5, (2.0 * sy - s.x) * 0.5)


static func corners(r: Rect2) -> Array[Vector2]:
	return [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]


## Contorno da caixa na tela (hexágono).
static func silhouette(b: Box) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for c in corners(b.rect):
		pts.append(iso(c, b.zb))
		pts.append(iso(c, b.zt))
	return Geometry2D.convex_hull(pts)


static func screen_rect(b: Box) -> Rect2:
	var r := Rect2(iso(b.rect.position, b.zt), Vector2.ZERO)
	for c in corners(b.rect):
		r = r.expand(iso(c, b.zb)).expand(iso(c, b.zt))
	return r


const EPS := 0.01


## A VERDADE: a está atrás de b (a desenha antes)? Separação por eixo: a está inteira do lado
## "de trás" de b em x, em y, ou embaixo em z. Se nenhum eixo separa, se atravessam (null).
static func behind(a: Box, b: Box):
	if a.rect.end.x <= b.rect.position.x + EPS or a.rect.end.y <= b.rect.position.y + EPS or a.zt <= b.zb + EPS:
		return true
	if b.rect.end.x <= a.rect.position.x + EPS or b.rect.end.y <= a.rect.position.y + EPS or b.zt <= a.zb + EPS:
		return false
	return null


## Ordem de desenho correta (ordenação topológica): só compara quem se sobrepõe na tela.
## Empate/ciclo (caixas que se atravessam) cai na chave antiga (x + y)/2 + z.
static func topo_order(boxes: Array) -> Array:
	var n := boxes.size()
	var rects := []
	for b in boxes:
		rects.append(screen_rect(b))
	var after := []  # after[i] = quem tem que vir depois de i
	var indeg := PackedInt32Array()
	indeg.resize(n)
	for i in n:
		after.append([])
	for i in n:
		for j in range(i + 1, n):
			if not rects[i].intersects(rects[j]):
				continue
			var r = behind(boxes[i], boxes[j])
			if r == true:
				after[i].append(j)
				indeg[j] += 1
			elif r == false:
				after[j].append(i)
				indeg[i] += 1
	# Kahn, sempre tirando o de menor chave primeiro (estável e sem tremer)
	var ready := []
	for i in n:
		if indeg[i] == 0:
			ready.append(i)
	var out := []
	var done := PackedByteArray()
	done.resize(n)
	while out.size() < n:
		if ready.is_empty():
			# ciclo: pega o de menor chave entre os que sobraram
			var best := -1
			for i in n:
				if not done[i] and (best < 0 or key(boxes[i]) < key(boxes[best])):
					best = i
			ready.append(best)
		var k := 0
		for q in range(1, ready.size()):
			if key(boxes[ready[q]]) < key(boxes[ready[k]]):
				k = q
		var i: int = ready[k]
		ready.remove_at(k)
		if done[i]:
			continue
		done[i] = 1
		out.append(boxes[i])
		for j in after[i]:
			indeg[j] -= 1
			if indeg[j] == 0 and not done[j]:
				ready.append(j)
	return out


## A chave do y_sort de hoje: (x + y)/2 do centro + a altura da base.
static func key(b: Box) -> float:
	var c := b.rect.get_center()
	return (c.x + c.y) * 0.5 + b.zb


## FATIAMENTO AUTOMÁTICO (a alternativa com y_sort): corta a pegada em pedaços quadrados de
## no máximo `max_side` — a regra é só essa, vale pra qualquer prédio.
static func slice_rect(r: Rect2, max_side: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var nx := maxi(ceili(r.size.x / max_side - 0.001), 1)
	var ny := maxi(ceili(r.size.y / max_side - 0.001), 1)
	var sx := r.size.x / nx
	var sy := r.size.y / ny
	for i in nx:
		for j in ny:
			out.append(Rect2(r.position + Vector2(i * sx, j * sy), Vector2(sx, sy)))
	return out


## O RAIO DA CÂMERA: o que está embaixo do ponto da tela `m`. Andando pelo raio de cima pra
## baixo (z alto = mais perto da câmera), a 1ª coisa sólida que ele encontra é o que se vê.
## `solids` = caixas; `planes` = [{rect, z, name}] (chão, fundo de buraco).
## Retorna {what: "topo"|"face"|"plano"|"nada", box/plane, ground: Vector2, z: float}.
static func pick(m: Vector2, solids: Array, planes: Array) -> Dictionary:
	var best := {"what": "nada", "z": -INF}
	for b in solids:
		# o raio, visto no chão, é a reta g(z) = iso_inv(m, z); dentro do retângulo pra z num
		# intervalo [za, zc] — cruzar com [zb, zt] e pegar o z mais alto
		var hit := _ray_box_top_z(m, b)
		if hit.z == -INF or hit.z <= best.z:
			continue
		best = {"what": hit.what, "box": b, "z": hit.z, "ground": iso_inv(m, hit.z)}
	for p in planes:
		var g := iso_inv(m, p.z)
		if p.rect.has_point(g) and p.z > best.z and not p.get("holes", []).any(func(h): return h.has_point(g)):
			best = {"what": "plano", "plane": p, "z": p.z, "ground": g}
	return best


## Maior z em que o raio está dentro da caixa: {z, what: "topo"|"face"} (z = -INF: não pega).
## Rampa: o sólido é a cunha embaixo do topo inclinado.
static func _ray_box_top_z(m: Vector2, b: Box) -> Dictionary:
	# g(z) = iso_inv(m, z): x = g0.x + z, y = g0.y + z
	var g0 := iso_inv(m, 0.0)
	var lo := maxf(maxf(b.zb, b.rect.position.x - g0.x), b.rect.position.y - g0.y)
	var hi := minf(minf(b.zt, b.rect.end.x - g0.x), b.rect.end.y - g0.y)
	if lo > hi:
		return {"z": -INF}
	if b.kind != "rampa":
		return {"z": hi, "what": "topo" if absf(hi - b.zt) < 0.01 else "face"}
	# rampa que sobe pro norte: topo z(y) = zt - k (y - y0). O raio cruza o topo em z*:
	# z* = zt - k (g0.y + z* - y0)  ->  z* = (zt - k (g0.y - y0)) / (1 + k)
	var k := (b.zt - b.zb) / b.rect.size.y
	var zs := (b.zt - k * (g0.y - b.rect.position.y)) / (1.0 + k)
	var z := minf(hi, zs)
	if z < lo:
		return {"z": -INF}
	return {"z": z, "what": "topo" if absf(z - zs) < 0.01 else "face"}
