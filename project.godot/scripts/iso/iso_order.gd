extends RefCounted
## Prompt 28: a ORDEM DE DESENHO por caixas, incremental (veio de prototipos/camera/
## iso_incremental.gd e ganhou o que faltava no endurecimento da Rota A).
##
## O cenário fixo (prédios, árvores, pedras) é ordenado UMA vez (Iso.topo_order). Depois:
##   - construir/demolir/trocar de tamanho: add_static / remove_static encaixam ou tiram SÓ
##     aquela caixa (sem reordenar tudo: era o tranco de 10 a 100 ms no mapa cheio);
##   - quem anda (ipezinhos, criaturas) é encaixado a cada quadro entre as fixas que ele cruza
##     na tela: logo depois da última fixa que fica atrás dele.
## Pra z_index: fixa de rank r -> BASE + r*K; quem anda depois de r -> BASE + r*K + 1..K-1.

const Iso := preload("res://scripts/iso/iso_core.gd")
const K := 8
## z_index da 1ª fixa. O Godot aceita de -4096 a 4096: cabem ~500 fixas abaixo de 0, e o que
## fica por cima de tudo (marcador, fantasma, clima) continua com z positivo.
const BASE := -4000
const CELL := 128.0

var order: Array = []  # [Box] fixas, de trás pra frente
var ranks := {}  # Box -> índice em order
var _grid := {}  # célula da tela -> [Box]
var _srect := {}  # Box -> retângulo na tela
## Quantas vezes um encaixe não coube no lugar e caiu na reordenação completa (teste/relatório).
var full_rebuilds := 0


func build(statics: Array) -> void:
	order = Iso.topo_order(statics)
	_reindex()
	_grid.clear()
	_srect.clear()
	for b in order:
		_grid_add(b)


func _reindex(from: int = 0) -> void:
	for i in range(from, order.size()):
		ranks[order[i]] = i


func _cells(r: Rect2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cx in range(floori(r.position.x / CELL), floori(r.end.x / CELL) + 1):
		for cy in range(floori(r.position.y / CELL), floori(r.end.y / CELL) + 1):
			out.append(Vector2i(cx, cy))
	return out


func _grid_add(b) -> void:
	var r := Iso.screen_rect(b)
	_srect[b] = r
	for k in _cells(r):
		if not _grid.has(k):
			_grid[k] = []
		_grid[k].append(b)


func _grid_remove(b) -> void:
	if not _srect.has(b):
		return
	for k in _cells(_srect[b]):
		if _grid.has(k):
			_grid[k].erase(b)
	_srect.erase(b)


## As fixas que se cruzam com o retângulo da tela r.
func _near(r: Rect2) -> Array:
	var out := []
	var seen := {}
	for k in _cells(r):
		for s in _grid.get(k, []):
			if seen.has(s):
				continue
			seen[s] = true
			if r.intersects(_srect[s]):
				out.append(s)
	return out


## Construiu (ou a caixa mudou): encaixa SÓ ela. Fica logo depois da última fixa que está
## atrás dela; se alguma que tem que vir depois já estiver antes desse ponto (o encaixe não
## cabe), reordena tudo — raro, e o contador conta.
func add_static(b) -> void:
	if ranks.has(b):
		remove_static(b)
	var lo := -1
	var hi := order.size()
	for s in _near(Iso.screen_rect(b)):
		var r = Iso.behind(s, b)
		if r == true:
			lo = maxi(lo, ranks[s])
		elif r == false:
			hi = mini(hi, ranks[s])
	if lo < hi:
		order.insert(lo + 1, b)
		_reindex(lo + 1)
		_grid_add(b)
		return
	full_rebuilds += 1
	var all := order.duplicate()
	all.append(b)
	build(all)


## Demoliu: tira a caixa. A ordem das outras continua válida.
func remove_static(b) -> void:
	if not ranks.has(b):
		return
	var i: int = ranks[b]
	order.remove_at(i)
	ranks.erase(b)
	_reindex(i)
	_grid_remove(b)


func z_of_static(b) -> int:
	return BASE + int(ranks.get(b, 0)) * K


## Pra cada caixa que anda: o "espaço" na ordem fixa (rank da última fixa atrás dela; -1 =
## antes de todas). Depois acerta quem anda × quem anda.
func place(dynamic: Array) -> Dictionary:
	var out := {}
	var rects := {}
	for d in dynamic:
		var r := Iso.screen_rect(d)
		rects[d] = r
		var lo := -1
		for s in _near(r):
			if Iso.behind(s, d) == true:
				lo = maxi(lo, ranks[s])
		out[d] = lo
	# se A fica atrás de B mas caiu num espaço DEPOIS do de B, B sobe pro espaço de A (nunca
	# desce: tem que continuar depois das fixas que ficam atrás dele)
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


## z_index de cada um que anda: {Box: z}. Os que caíram no mesmo espaço são ordenados entre
## si pela verdade 3D.
func dynamic_z(dynamic: Array) -> Dictionary:
	var slots := place(dynamic)
	var by_slot := {}
	for d in dynamic:
		var s: int = slots[d]
		if not by_slot.has(s):
			by_slot[s] = []
		by_slot[s].append(d)
	var out := {}
	for s in by_slot:
		var group: Array = by_slot[s]
		if group.size() > 1:
			group = Iso.topo_order(group)
		for i in group.size():
			out[group[i]] = BASE + s * K + 1 + mini(i, K - 2)
	return out
