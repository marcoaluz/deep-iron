extends RefCounted
## PROTÓTIPO ROTA A (endurecida): ORDEM INCREMENTAL (o jeito de produção da ordem por caixas).
## O cenário fixo é ordenado UMA vez (Iso.topo_order) e cada coisa que anda é encaixada entre
## as fixas que ela cruza na tela: logo depois da última que fica atrás dela. Custo por quadro
## ~ (quem anda) × (fixas perto dele), não (todos)². Pra z_index: fixa de rank r -> r*K;
## quem anda depois de r -> r*K + 1.. (K-1), desempatando pela chave.

const Iso := preload("res://prototipos/camera/iso_core.gd")
const K := 8

var ranks := {}  # Box -> posição na ordem fixa
var order := []
var _grid := {}  # célula da tela -> [Box]
var _srect := {}  # Box -> retângulo na tela (fixas não mudam)
const CELL := 128.0

func build(statics: Array) -> void:
	order = Iso.topo_order(statics)
	ranks.clear()
	_grid.clear()
	for i in order.size():
		ranks[order[i]] = i
		var r := Iso.screen_rect(order[i])
		_srect[order[i]] = r
		for cx in range(floori(r.position.x / CELL), floori(r.end.x / CELL) + 1):
			for cy in range(floori(r.position.y / CELL), floori(r.end.y / CELL) + 1):
				var k := Vector2i(cx, cy)
				if not _grid.has(k):
					_grid[k] = []
				_grid[k].append(order[i])

## Pra cada caixa que anda: o "espaço" na ordem fixa (depois do rank devolvido).
## Retorna {box: slot} (slot = rank da última fixa atrás dela; -1 = antes de todas).
func place(dynamic: Array) -> Dictionary:
	var out := {}
	for d in dynamic:
		var r := Iso.screen_rect(d)
		var lo := -1
		var seen := {}
		for cx in range(floori(r.position.x / CELL), floori(r.end.x / CELL) + 1):
			for cy in range(floori(r.position.y / CELL), floori(r.end.y / CELL) + 1):
				for s in _grid.get(Vector2i(cx, cy), []):
					if seen.has(s):
						continue
					seen[s] = true
					if not r.intersects(_srect[s]):
						continue
					if Iso.behind(s, d) == true:
						lo = maxi(lo, ranks[s])
		out[d] = lo
	# quem anda × quem anda: se A fica atrás de B mas caiu num espaço DEPOIS do de B, B sobe
	# pro espaço de A (nunca desce: tem que continuar depois das fixas que ficam atrás dele)
	var rects := {}
	for d in dynamic:
		rects[d] = Iso.screen_rect(d)
	for _pass in 4:
		var changed := false
		for i in dynamic.size():
			for j in range(i + 1, dynamic.size()):
				var a = dynamic[i]
				var b = dynamic[j]
				if not rects[a].intersects(rects[b]):
					continue
				var r = Iso.behind(a, b)
				if r == true and out[a] > out[b]:
					out[b] = out[a]
					changed = true
				elif r == false and out[b] > out[a]:
					out[a] = out[b]
					changed = true
		if not changed:
			break
	return out


## Ordem dos que caíram no MESMO espaço (poucos): a verdade 3D entre eles.
func order_within(boxes: Array) -> Array:
	return Iso.topo_order(boxes)
