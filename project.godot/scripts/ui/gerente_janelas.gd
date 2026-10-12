extends Node
## Bloco 135: o GERENTE DAS JANELAS FLUTUANTES do HUD (filho do hud.gd, grupo "gerente_janelas").
##
## Antes cada janela se posicionava sozinha (a maioria no centro da tela): a ficha do ipezinho, o cartão de requisitos da
## função e a ajuda abriam uma por cima da outra, às vezes cortadas na borda, e o texto virava uma bagunça. Agora toda janela
## registrada aqui (as dos prédios, a ficha, o cartão de requisitos, a ajuda de atalhos):
## - abre DENTRO da área útil da tela (entre a barra de cima e a barra de baixo, com margem) — nunca cortada;
## - nunca cobre outra janela aberta, a gaveta da esquerda (Pessoas/Obras) nem um cartão fixo (grupo "janela_fixa": o
##   capataz do primeiro dia): com duas ou mais abertas, elas são
##   ARRUMADAS em colunas (na ordem em que abriram, lado a lado, o conjunto centrado); sem lugar, a nova entra em CASCATA
##   por cima da última (deslocada, o título das de trás sempre à mostra);
## - fecha a anterior do MESMO TIPO (uma janela de prédio troca pela outra; uma ficha pela outra);
## - Esc fecha a de CIMA primeiro (`fecha_de_cima`);
## - toda janela tem o botão X (as que não tinham ganham um).

const MARGEM := 8.0
## px que a cascata anda pro lado a cada janela empilhada.
const PASSO_CASCATA := 32.0
## px que a cascata desce: a altura do cabeçalho de uma janela (o nome/título da de trás fica à mostra).
const PASSO_CASCATA_Y := 72.0

var _hud: Node
var _tipos := {}  # janela -> tipo
var _pilha: Array = []  # as abertas, na ordem em que abriram (a última é a de cima)


func setup(hud: Node) -> void:
	_hud = hud
	name = "GerenteJanelas"
	add_to_group("gerente_janelas")
	get_viewport().size_changed.connect(func():
		for j in _pilha:
			posiciona.call_deferred(j, false))


## Passa a cuidar da janela `j` (tipo: "predio", "ficha", "requisitos", "ajuda"...).
func registra(j: Control, tipo: String) -> void:
	if _tipos.has(j):
		return
	_tipos[j] = tipo
	j.visibility_changed.connect(_mudou.bind(j))
	if j.visible:
		_mudou(j)


func tipo_de(j: Control) -> String:
	return String(_tipos.get(j, ""))


func abertas() -> Array:
	return _pilha.filter(func(j): return is_instance_valid(j) and j.visible)


func _mudou(j: Control) -> void:
	if not is_instance_valid(j):
		return
	if not j.visible:
		_pilha.erase(j)
		return
	_pilha.erase(j)
	_pilha.append(j)
	var t := tipo_de(j)
	for o in _pilha.duplicate():
		if o != j and is_instance_valid(o) and o.visible and tipo_de(o) == t:
			o.visible = false  # a anterior do mesmo tipo fecha
	j.move_to_front()
	_arruma_depois.call_deferred(j)


## Uma janela só: o lugar dela (centrada, presa na tela). Duas ou mais: arruma todas. (No quadro seguinte de novo: o
## tamanho assenta depois que o texto quebra e a lista monta.)
func _arruma_depois(j: Control) -> void:
	if not is_inside_tree():  # (a partida trocou de cena: nada pra arrumar)
		return
	_arruma(j)
	await get_tree().process_frame
	if is_inside_tree() and is_instance_valid(j):
		_arruma(j)


func _arruma(j: Control) -> void:
	var lista := abertas()
	if lista.size() <= 1:
		posiciona(j, false)
	else:
		arruma(lista)


## Arruma as janelas `lista` (na ordem) em colunas dentro da área útil, sem cobrir a gaveta da esquerda; o conjunto fica
## centrado. A que não cabe vai em cascata por cima da anterior.
func arruma(lista: Array) -> void:
	var a := area()
	var fixos: Array[Rect2] = []
	for nome in ["_left_panel", "_obras_panel"]:
		var gv = _hud.get(nome)
		if gv is Control and (gv as Control).visible:
			fixos.append((gv as Control).get_global_rect())
	var x0 := a.position.x
	for f in fixos:
		if f.position.x <= a.position.x + 4.0:
			x0 = maxf(x0, f.end.x + MARGEM)  # (a gaveta fica à esquerda: as colunas começam depois dela)
	var util := Rect2(x0, a.position.y, a.end.x - x0, a.size.y)
	var extra := _fixos_extra()
	var postos: Array = []  # [janela, Rect2]
	var cascata: Array = []
	for j in lista:
		var tam := _cabe(j, util)
		var p := Vector2.INF
		# 1) embaixo de uma coluna que já existe
		for pr in postos:
			var r: Rect2 = pr[1]
			var cand := Rect2(Vector2(r.position.x, _fundo_da_coluna(postos, r.position.x) + MARGEM), tam)
			if util.encloses(cand) and not _bate(cand, postos) and not _bate_fixo(cand, extra):
				p = cand.position
				break
		# 2) uma coluna nova à direita
		if p == Vector2.INF:
			var xd := util.position.x
			for pr in postos:
				xd = maxf(xd, (pr[1] as Rect2).end.x + MARGEM)
			var cand := Rect2(Vector2(xd, util.position.y), tam)
			for f in extra:  # um cartão fixo no caminho: a coluna começa embaixo dele
				if cand.grow(-1.0).intersects(f):
					cand.position.y = maxf(cand.position.y, f.end.y + MARGEM)
			if util.encloses(cand) and not _bate_fixo(cand, extra):
				p = cand.position
		if p == Vector2.INF:
			cascata.append(j)
			continue
		postos.append([j, Rect2(p, tam)])
	# o conjunto centrado na área útil
	var fim := util.position.x
	for pr in postos:
		fim = maxf(fim, (pr[1] as Rect2).end.x)
	var desloca := maxf((util.end.x - fim) * 0.5, 0.0)
	for pr in postos:
		_poe(pr[0], (pr[1] as Rect2).position + Vector2(desloca, 0.0))
	# cascata: por cima da última posta, um degrau pra baixo e pro lado (o título de trás fica à mostra)
	var base: Vector2 = (postos[-1][1] as Rect2).position + Vector2(desloca, 0.0) if not postos.is_empty() else util.position
	for j in cascata:
		base += Vector2(PASSO_CASCATA, PASSO_CASCATA_Y)
		_poe(j, _dentro(base, j.size, util))
		j.move_to_front()


func _fundo_da_coluna(postos: Array, x: float) -> float:
	var y := -INF
	for pr in postos:
		var r: Rect2 = pr[1]
		if absf(r.position.x - x) < 1.0:
			y = maxf(y, r.end.y)
	return y


func _bate_fixo(r: Rect2, fixos: Array[Rect2]) -> bool:
	for f in fixos:
		if r.grow(-1.0).intersects(f):
			return true
	return false


func _bate(r: Rect2, postos: Array) -> bool:
	for pr in postos:
		if r.grow(-1.0).intersects(pr[1]):
			return true
	return false


## O tamanho da janela, sem passar da área (a que tem rolagem encolhe; as outras ficam no mínimo delas).
func _cabe(j: Control, a: Rect2) -> Vector2:
	var tam := j.size
	if tam.x > a.size.x or tam.y > a.size.y:
		j.reset_size()
		tam = Vector2(minf(j.size.x, a.size.x), minf(j.size.y, a.size.y))
	return tam


## Esc: fecha a janela de cima (a última aberta). true se fechou alguma.
func fecha_de_cima() -> bool:
	for i in range(_pilha.size() - 1, -1, -1):
		var j = _pilha[i]
		if is_instance_valid(j) and j.visible:
			j.visible = false
			return true
	return false


## A área útil da tela (coordenadas do HUD): entre a barra de cima e a de baixo, com margem.
func area() -> Rect2:
	var tela: Rect2 = _hud.get_viewport().get_visible_rect()
	var topo: float = float(_hud.get("TOP_BAR_H")) if _hud.get("TOP_BAR_H") != null else 40.0
	var barra = _hud.get("_order_bar")
	var baixo: float = (barra as Control).size.y if barra is Control and (barra as Control).visible else 0.0
	return Rect2(tela.position.x + MARGEM, tela.position.y + topo + MARGEM,
		tela.size.x - 2.0 * MARGEM, tela.size.y - topo - baixo - 2.0 * MARGEM)


## O que a janela `j` não pode cobrir: as outras abertas e as gavetas da esquerda.
func obstaculos(j: Control) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for o in _pilha:
		if o != j and is_instance_valid(o) and o.visible:
			out.append((o as Control).get_global_rect())
	for nome in ["_left_panel", "_obras_panel"]:
		var g = _hud.get(nome)
		if g is Control and (g as Control).visible:
			out.append((g as Control).get_global_rect())
	out.append_array(_fixos_extra())
	return out


## Os cartões fixos visíveis (grupo "janela_fixa").
func _fixos_extra() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for n in get_tree().get_nodes_in_group("janela_fixa"):
		if n is Control and (n as Control).is_visible_in_tree():
			out.append((n as Control).get_global_rect())
	return out


## Põe a janela num lugar livre e dentro da tela. `nova` = acabou de abrir (refaz no quadro seguinte, quando o tamanho
## assenta: texto quebrando, lista montando).
func posiciona(j: Control, nova: bool = false) -> void:
	if not is_instance_valid(j) or not j.visible or not j.is_inside_tree():
		return
	var tam := j.size
	var a := area()
	if tam.x > a.size.x or tam.y > a.size.y:  # maior que a área: encolhe até o mínimo e usa a área toda
		j.reset_size()
		tam = Vector2(minf(j.size.x, a.size.x), minf(j.size.y, a.size.y))
	var obs := obstaculos(j)
	var atual := j.get_global_rect()
	var cands: Array[Vector2] = [_dentro(atual.position, tam, a)]
	for o in obs:
		cands.append(_dentro(Vector2(o.end.x + MARGEM, atual.position.y), tam, a))
		cands.append(_dentro(Vector2(o.position.x - tam.x - MARGEM, atual.position.y), tam, a))
		cands.append(_dentro(Vector2(atual.position.x, o.end.y + MARGEM), tam, a))
		cands.append(_dentro(Vector2(atual.position.x, o.position.y - tam.y - MARGEM), tam, a))
	var escolhido := Vector2.INF
	for p in cands:
		var r := Rect2(p, tam)
		var livre := true
		for o in obs:
			if r.grow(-1.0).intersects(o):
				livre = false
				break
		if livre:
			escolhido = p
			break
	if escolhido == Vector2.INF:  # sem lugar livre: cascata a partir da de cima
		var base := a.position
		for o in _pilha:
			if o != j and is_instance_valid(o) and o.visible:
				base = (o as Control).get_global_rect().position
		escolhido = _dentro(base + Vector2(PASSO_CASCATA, PASSO_CASCATA_Y), tam, a)
	_poe(j, escolhido)
	if nova:
		_reconfere.call_deferred(j)


func _reconfere(j: Control) -> void:
	await get_tree().process_frame
	posiciona(j, false)


func _dentro(p: Vector2, tam: Vector2, a: Rect2) -> Vector2:
	return Vector2(clampf(p.x, a.position.x, maxf(a.end.x - tam.x, a.position.x)),
		clampf(p.y, a.position.y, maxf(a.end.y - tam.y, a.position.y)))


## Solta a janela das âncoras (centro, embaixo...) e põe no ponto `p` (canto de cima à esquerda).
func _poe(j: Control, p: Vector2) -> void:
	if not (is_equal_approx(j.anchor_left, 0.0) and is_equal_approx(j.anchor_top, 0.0) and is_equal_approx(j.anchor_right, 0.0) and is_equal_approx(j.anchor_bottom, 0.0)):
		var tam := j.size
		j.set_anchors_preset(Control.PRESET_TOP_LEFT)
		j.grow_horizontal = Control.GROW_DIRECTION_END
		j.grow_vertical = Control.GROW_DIRECTION_END
		j.size = tam
	j.global_position = p.round()


## A janela tem um X? (procura um botão "X" nela)
static func tem_x(j: Node) -> bool:
	for b in j.find_children("*", "Button", true, false):
		if String((b as Button).text).strip_edges() == "X":
			return true
	return false
