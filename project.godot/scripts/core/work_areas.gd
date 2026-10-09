extends Node
## Bloco 77: ÁREAS DE TRABALHO com postos (o esquema do Frostpunk) — grupo "work_areas", criado pelo main.gd.
##
## O jogador marca um retângulo no mapa (area_placer.gd) e diz quantos trabalham ali (0..capacidade); o
## sistema pega os ipezinhos SEM FUNÇÃO (os "disponíveis"), dá a função do tipo da área e prende a busca
## de trabalho deles ao retângulo (ipezinho.gd: _find_best_station / _has_usable_station perguntam
## pode_usar). Tirar devolve o ipezinho pra sem função (ele entrega o que estiver carregando antes, como
## em qualquer troca de função). A produção é a de sempre — cada um corta/colhe/minera no seu slot —, então
## 5 trabalhadores rendem o de 5 e 2 rendem o de 2; a área só mede (producao_min) pra mostrar.
##
## O que fica dentro de uma área é DELA: quem tem a função mas não está na área (designado à mão, pelas
## teclas) não usa árvore/horta/jazida de dentro de área nenhuma — e mina desativada não é usada por
## ninguém. Sem área nenhuma no mapa, tudo funciona como antes do Bloco 77.
##
## Tipo novo de área (caça, agricultura, pesca...) = mais uma entrada em TIPOS (a função do ipezinho que
## faz o trabalho e os grupos de estação que contam como "o recurso" dela) e o texto dos estados.

signal changed  # área criada/apagada, trabalhador entrou/saiu, mina ligada/desligada

const Worker := preload("res://scripts/workers/ipezinho.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const CAPACIDADE := 5
const LADO_MINIMO := 40.0  # px da lógica: menor que isso não vira área (clique sem arrastar)
const JANELA := 60.0       # s de jogo: a produção mostrada é a do último minuto

const TIPOS := {
	"madeira": {"nome": "Corte de árvores", "curto": "Madeira", "recurso": "madeira", "unidade": "madeira",
		"job": Worker.ROLE_LUMBER, "grupos": ["arvores"], "quem": "Trabalhadores",
		"sem_recurso": "Sem árvores disponíveis", "cor": Color(0.55, 0.85, 0.4), "ativacao": false},
	"comida": {"nome": "Coleta de alimentos", "curto": "Alimentos", "recurso": "comida", "unidade": "comida crua",
		"job": Worker.ROLE_HUNTER, "grupos": ["coleta_comida", "caca"], "quem": "Trabalhadores",
		"sem_recurso": "Sem alimento disponível", "cor": Color(0.95, 0.75, 0.35), "ativacao": false},
	"mina": {"nome": "Mineração", "curto": "Mina", "recurso": "minério", "unidade": "minério",
		"job": Worker.ROLE_MINER, "grupos": ["minerios"], "quem": "Mineiros",
		"sem_recurso": "Sem recurso disponível", "cor": Color(0.6, 0.75, 1.0), "ativacao": true},
}
const ESTADO_TRABALHANDO := "Trabalhando"
const ESTADO_OPERANDO := "Operando"
const ESTADO_SEM_GENTE := "Sem trabalhadores"
const ESTADO_SEM_MINEIRO := "Sem mineiro"
const ESTADO_DESATIVADA := "Desativada"


## Um posto de trabalho no mapa.
class WorkArea extends RefCounted:
	var id := 0
	var tipo := "madeira"
	var rect := Rect2()          # na lógica (o chão do mundo)
	var capacidade := 5
	var trabalhadores: Array = []  # ipezinhos (Node) designados aqui
	var ativa := true            # a mina nasce desligada: o jogador liga o carrinho
	var _baldes: Array = []      # produção em baldes de 5 s (o último minuto)
	var _balde := 0.0
	var _t := 0.0
	var total := 0.0             # tudo que já saiu daqui

	func info() -> Dictionary:
		return TIPOS.get(tipo, TIPOS["madeira"])

	func job() -> String:
		return info().job

	func grupos() -> Array:
		return info().grupos

	func precisa_ativar() -> bool:
		return bool(info().ativacao)

	func centro() -> Vector2:
		return rect.get_center()

	func contem(p: Vector2) -> bool:
		return rect.has_point(p)

	func vivos() -> Array:
		trabalhadores = trabalhadores.filter(func(w): return is_instance_valid(w) and w.is_inside_tree() and w.get("work_area") == self)
		return trabalhadores

	func quantos() -> int:
		return vivos().size()

	func cheia() -> bool:
		return quantos() >= capacidade

	## Pode trabalhar agora? (mina: ligada e com pelo menos 1 mineiro)
	func liberada() -> bool:
		return ativa or not precisa_ativar()

	func registra(qtd: float) -> void:
		if qtd > 0.0:
			_balde += qtd
			total += qtd

	func passa(delta: float) -> void:
		_t += delta
		while _t >= JANELA / 12.0:
			_t -= JANELA / 12.0
			_baldes.append(_balde)
			_balde = 0.0
			if _baldes.size() > 12:
				_baldes.pop_front()

	## O que saiu daqui no último minuto (enquanto o minuto não fechou, projeta o que já tem).
	func producao_min() -> float:
		var s := _balde
		for b in _baldes:
			s += b
		var seg := _baldes.size() * JANELA / 12.0 + _t
		return s * JANELA / seg if seg > 5.0 else 0.0

	func nome() -> String:
		return "%s %d" % [info().curto, id]


var areas: Array = []  # [WorkArea]
var _proximo_id := 1
var _t_carrinho := 0.0


func _ready() -> void:
	add_to_group("work_areas")


func _process(delta: float) -> void:
	for a in areas:
		a.passa(delta)
		a.vivos()
	_t_carrinho -= delta
	if _t_carrinho <= 0.0:
		_t_carrinho = 0.5
		_sincroniza_carrinhos()


# ------------------------------------------------------------ áreas
## "" se dá pra criar essa área; senão o motivo.
func motivo_invalido(tipo: String, rect: Rect2) -> String:
	if not TIPOS.has(tipo):
		return "tipo de área desconhecido"
	var r := rect.abs()
	if r.size.x < LADO_MINIMO or r.size.y < LADO_MINIMO:
		return "arraste pra marcar uma área maior"
	var env := get_tree().get_first_node_in_group("environment")
	if env and env.has_method("level_at"):
		if env.level_at(r.position) != env.level_at(r.end) or env.level_at(r.position) != env.level_at(r.get_center()):
			return "a área tem que ficar num andar só"
	for a in areas:
		if a.tipo == tipo and a.rect.intersects(r):
			return "já tem uma área de %s aí" % TIPOS[tipo].curto.to_lower()
	return ""


func criar(tipo: String, rect: Rect2) -> WorkArea:
	if motivo_invalido(tipo, rect) != "":
		return null
	var a := WorkArea.new()
	a.id = _proximo_id
	_proximo_id += 1
	a.tipo = tipo
	a.rect = rect.abs()
	a.capacidade = CAPACIDADE
	a.ativa = not a.precisa_ativar()
	areas.append(a)
	changed.emit()
	return a


func apagar(a: WorkArea) -> void:
	if not areas.has(a):
		return
	definir(a, 0)
	areas.erase(a)
	_sincroniza_carrinhos()
	changed.emit()


func por_id(id: int) -> WorkArea:
	for a in areas:
		if a.id == id:
			return a
	return null


func area_em(p: Vector2) -> WorkArea:
	for i in range(areas.size() - 1, -1, -1):
		if areas[i].contem(p):
			return areas[i]
	return null


## A mina liga/desliga (o carrinho). Desligada: os mineiros dela esperam na área e ninguém minera ali.
func ativar(a: WorkArea, on: bool) -> void:
	if a == null or not a.precisa_ativar() or a.ativa == on:
		return
	a.ativa = on
	_sincroniza_carrinhos()
	changed.emit()


# ------------------------------------------------------------ trabalhadores
## Os disponíveis: ipezinhos sem função (e sem área), de pé.
func disponiveis() -> Array:
	var out := []
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.job == Worker.ROLE_IDLE and w.get("work_area") == null and not w.downed:
			out.append(w)
	return out


func total_trabalhadores() -> int:
	return get_tree().get_nodes_in_group("ipezinhos").size()


## Põe mais um na área. "" = pôs; senão o motivo (área cheia / ninguém disponível).
func adicionar(a: WorkArea) -> String:
	if a == null or not areas.has(a):
		return "área não existe"
	if a.cheia():
		return "área cheia (%d/%d)" % [a.quantos(), a.capacidade]
	var livres := disponiveis()
	if livres.is_empty():
		return "nenhum trabalhador disponível"
	# o mais perto da área (os sãos primeiro: machucado vai pra enfermaria antes de trabalhar)
	var c := a.centro()
	livres.sort_custom(func(x, y):
		var px: float = x.global_position.distance_to(c) + (5000.0 if x.injured else 0.0)
		var py: float = y.global_position.distance_to(c) + (5000.0 if y.injured else 0.0)
		return px < py)
	var w: Node = livres[0]
	w.set_job(a.job())
	w.entrar_area(a)
	a.trabalhadores.append(w)
	changed.emit()
	return ""


## Tira um da área (volta pra disponível). "" = tirou; senão o motivo.
func remover(a: WorkArea) -> String:
	if a == null or a.quantos() == 0:
		return "ninguém nessa área"
	# quem está com menos carga sai primeiro (o que está cheio termina a entrega como sem função)
	var ws := a.vivos().duplicate()
	ws.sort_custom(func(x, y): return _carga(x) < _carga(y))
	var w: Node = ws[0]
	sair(w)
	w.set_job(Worker.ROLE_IDLE)
	changed.emit()
	return ""


func _carga(w: Node) -> float:
	return float(w.carrying) + float(w.wood_carrying) + float(w.raw_carrying)


## Leva a área a `n` trabalhadores (limitado à capacidade e aos disponíveis). Devolve quantos ficaram.
func definir(a: WorkArea, n: int) -> int:
	if a == null:
		return 0
	n = clampi(n, 0, a.capacidade)
	while a.quantos() < n:
		if adicionar(a) != "":
			break
	while a.quantos() > n:
		if remover(a) != "":
			break
	return a.quantos()


## O ipezinho sai da área (sem mexer na função: quem chama decide).
func sair(w: Node) -> void:
	var a = w.get("work_area")
	if a != null:
		a.trabalhadores.erase(w)
	w.sair_area()


## Religa depois de carregar o save (o ipezinho guardou o id da área dele).
func religar(w: Node, id: int) -> void:
	var a := por_id(id)
	if a == null or a.cheia() or w.job != a.job():
		return
	w.entrar_area(a)
	if not a.trabalhadores.has(w):
		a.trabalhadores.append(w)
	changed.emit()


# ------------------------------------------------------------ o que o ipezinho pode usar
## Esse ipezinho pode trabalhar nessa estação (do grupo `grupo`, na posição `p`)?
##   - da área dele (do tipo do grupo): só dentro do retângulo, e só com a área liberada (mina ligada);
##   - fora disso: não usa o que está dentro de área nenhuma que seja desse recurso.
func pode_usar(w: Node, p: Vector2, grupo: String) -> bool:
	if grupo == "coleta_comida" and w.has_method("is_farmer") and w.is_farmer():
		return true  # Bloco 107: a horta e a estufa são do agricultor, esteja ou não dentro de uma área de alimentos
	var minha = w.get("work_area")
	if minha != null and grupo in minha.grupos():
		return minha.contem(p) and minha.liberada()
	for a in areas:
		if grupo in a.grupos() and a.contem(p):
			return false
	return true


## Tem recurso pra trabalhar dentro da área?
func tem_recurso(a: WorkArea) -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	for g in a.grupos():
		for node in get_tree().get_nodes_in_group(g):
			if not a.contem(node.global_position):
				continue
			if node.has_method("is_usable") and not node.is_usable():
				continue
			if env and env.has_method("trancado") and env.trancado(node.global_position):
				continue
			return true
	return false


## O estado da atividade (texto da janela e do rótulo no mapa).
func estado(a: WorkArea) -> String:
	if a.precisa_ativar():
		if not a.ativa:
			return ESTADO_DESATIVADA
		if a.quantos() == 0:
			return ESTADO_SEM_MINEIRO
		if not tem_recurso(a):
			return a.info().sem_recurso
		return ESTADO_OPERANDO
	if a.quantos() == 0:
		return ESTADO_SEM_GENTE
	if not tem_recurso(a):
		return a.info().sem_recurso
	return ESTADO_TRABALHANDO


## Funcionando de verdade (trabalho saindo)?
func funcionando(a: WorkArea) -> bool:
	return estado(a) in [ESTADO_TRABALHANDO, ESTADO_OPERANDO]


# ------------------------------------------------------------ o carrinho da mina
## Os pontos de carga do vagonete dentro (ou na beira) da área.
func carrinhos(a: WorkArea) -> Array:
	var out := []
	for st in get_tree().get_nodes_in_group("pontos_carga"):
		if a.rect.grow(80.0).has_point(st.global_position):
			out.append(st)
	return out


## O carrinho de cada mina só anda com ela operando (ligada + pelo menos 1 mineiro + jazida).
func _sincroniza_carrinhos() -> void:
	for st in get_tree().get_nodes_in_group("pontos_carga"):
		var parar := false
		var motivo := ""
		for a in areas:
			if a.precisa_ativar() and a.rect.grow(80.0).has_point(st.global_position) and not funcionando(a):
				parar = true
				motivo = estado(a).to_lower()
		if st.has_method("parar_por_area"):
			st.parar_por_area(parar, motivo)


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	var lista := []
	for a in areas:
		lista.append({"id": a.id, "tipo": a.tipo, "rect": [a.rect.position.x, a.rect.position.y, a.rect.size.x, a.rect.size.y],
			"ativa": a.ativa, "total": a.total})
	return {"proximo_id": _proximo_id, "areas": lista}


## Antes dos ipezinhos (eles religam pelo id da área no _ready deles).
func load_save_data(d: Dictionary) -> void:
	areas.clear()
	for ad in SaveUtil.array(d, "areas"):
		if typeof(ad) != TYPE_DICTIONARY or not TIPOS.has(SaveUtil.text(ad, "tipo", "")):
			continue
		var r = ad.get("rect", [])
		if not (r is Array) or r.size() != 4:
			continue
		var a := WorkArea.new()
		a.id = maxi(SaveUtil.integer(ad, "id", 0), 1)
		a.tipo = SaveUtil.text(ad, "tipo", "madeira")
		a.rect = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).abs()
		a.capacidade = CAPACIDADE
		a.ativa = SaveUtil.boolean(ad, "ativa", not a.precisa_ativar())
		a.total = maxf(SaveUtil.num(ad, "total", 0.0), 0.0)
		areas.append(a)
	var maior := 0
	for a in areas:
		maior = maxi(maior, a.id)
	_proximo_id = maxi(SaveUtil.integer(d, "proximo_id", maior + 1), maior + 1)
	changed.emit()
