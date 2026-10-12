extends RefCounted
## Bloco 132: a GRADE ÚNICA de construção. Prédios, casas, decoração grande e caminhos usam as mesmas células.
##
## O lado da célula é 64/3 px do chão: o losango de 64x32 px de arte dos pisos do PixelLab (Bloco 130) — uma célula da grade
## é exatamente um ladrilho, sem esticar o desenho. (O pedido falava em 20 px; com 20 a arte dos pisos teria de ser
## escalada ou refeita, então a grade ficou do tamanho do ladrilho.)
##
## - celula(p): a célula de um ponto do chão; rect(c): o retângulo dela; centro(c).
## - celulas(r): as células que um retângulo COBRE (Rect2i, fim exclusivo), arredondando pra cima; uma beirada de até
##   `FOLGA_BORDA` px de cada lado não conta: a "base" da arte traz uns px de contorno (a casa tem 88,7 px = 4 células +
##   3 px) e, sem a tolerância, cada prédio ganharia uma célula inteira de vão e as casas não encostariam.
## - encaixa(pos, pegada): o ponto em que a pegada fica CENTRADA no bloco de células dela (o prédio ocupa células inteiras).

const CELULA := 64.0 / 3.0
## px de contorno da base, de cada lado, que não chegam a ocupar a célula vizinha
const FOLGA_BORDA := 2.0


static func celula(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELULA), floori(p.y / CELULA))


static func rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CELULA, Vector2(CELULA, CELULA))


static func centro(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * CELULA


## As células cobertas por `r` (posição = a primeira, tamanho = quantas em x e y).
static func celulas(r: Rect2) -> Rect2i:
	var x0 := floori((r.position.x + FOLGA_BORDA) / CELULA)
	var y0 := floori((r.position.y + FOLGA_BORDA) / CELULA)
	var x1 := ceili((r.end.x - FOLGA_BORDA) / CELULA)
	var y1 := ceili((r.end.y - FOLGA_BORDA) / CELULA)
	return Rect2i(x0, y0, maxi(x1 - x0, 1), maxi(y1 - y0, 1))


## O retângulo do chão de um bloco de células.
static func rect_de(cs: Rect2i) -> Rect2:
	return Rect2(Vector2(cs.position) * CELULA, Vector2(cs.size) * CELULA)


## Quantas células um lado de `tamanho` px ocupa (arredondado pra cima, com a tolerância do contorno).
static func quantas(tamanho: float) -> int:
	return maxi(ceili((tamanho - 2.0 * FOLGA_BORDA) / CELULA - 0.0001), 1)


## `pos` corrigido pra que a pegada fique centrada num bloco de células inteiras (o canto do bloco numa quina da grade).
static func encaixa(pos: Vector2, pegada: Rect2) -> Vector2:
	var vao := Vector2(quantas(pegada.size.x), quantas(pegada.size.y)) * CELULA
	var canto := pos + pegada.position - (vao - pegada.size) * 0.5
	var alvo := (canto / CELULA).round() * CELULA
	return pos + (alvo - canto)


## Lista das células de um bloco.
static func lista(cs: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(cs.position.y, cs.end.y):
		for x in range(cs.position.x, cs.end.x):
			out.append(Vector2i(x, y))
	return out
