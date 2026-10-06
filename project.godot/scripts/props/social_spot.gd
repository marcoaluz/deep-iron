extends Node2D
## Bloco 85: PONTO SOCIAL (grupo "social_spots") — um lugar da hora social (18:30–21:30) onde os ipezinhos
## param pra conversar em RODAS (pares e grupos). É um componente: o prédio cria um destes como filho
## (SocialSpot.criar(...) no _ready dele) — refeitório (comedouro, com as mesas), praça (Centro da Vila),
## taverna, parque; e, no futuro, bancos, fogueira e igreja (Blocos 88 e 90) entram do mesmo jeito.
##
## Cada ponto tem VAGAS fixas (rodas x lugares por roda) que o ipezinho RESERVA antes de ir: ninguém empilha
## no mesmo pixel e a roda se forma de verdade (quem chega prefere uma roda que já tem gente). Os lugares
## ficam na frente do prédio (deslocamento), encaixados na navegação na primeira vez que alguém pede.
## Coberto (refeitório, taverna, igreja) = onde vão com chuva ou onda solar.
##
## Custo baixo: nada roda por quadro aqui; tudo é consulta quando alguém chega, sai ou troca de ponto.

const SocialSpot := preload("res://scripts/props/social_spot.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")

## "refeitorio", "praca", "taverna", "parque", "banco", "fogueira", "igreja".
@export var tipo: String = "praca"
## Nome pra janela/rótulo ("Praça", "Refeitório"...).
@export var nome: String = "Praça"
## Coberto: vale com chuva e onda solar.
@export var coberto: bool = false
## Quantas rodas de conversa e quantos lugares em cada.
@export_range(1, 8) var rodas: int = 2
@export_range(2, 6) var por_roda: int = 3
## Distância (px do chão) do centro da roda até cada lugar; e entre os centros das rodas.
@export var raio_roda: float = 18.0
@export var espaco_rodas: float = 62.0
## Onde ficam as rodas em relação ao dono (na frente do prédio = +y).
@export var deslocamento: Vector2 = Vector2(0, 44)
## Multiplica o ânimo de conversar aqui (taverna e igreja animam mais).
@export var animo_mult: float = 1.0

var _lugares: Array[Vector2] = []  # posições globais, já na navegação
var _ocupante: Array = []  # o ipezinho de cada lugar (ou null)
var _origem := Vector2.INF  # onde o dono estava quando os lugares foram calculados


## Cria o componente com os números de um tipo de ponto (o prédio chama no _ready e faz add_child).
static func criar(p_tipo: String, p_nome: String, p_coberto: bool, p_rodas: int, p_por_roda: int, p_desloc: Vector2, p_animo := 1.0) -> Node2D:
	var s: Node2D = SocialSpot.new()
	s.name = "PontoSocial"
	s.tipo = p_tipo
	s.nome = p_nome
	s.coberto = p_coberto
	s.rodas = p_rodas
	s.por_roda = p_por_roda
	s.deslocamento = p_desloc
	s.animo_mult = p_animo
	return s


func _ready() -> void:
	add_to_group("social_spots")
	visible = false  # (não desenha nada: só os lugares)


func vagas() -> int:
	return rodas * por_roda


func livres() -> int:
	_prepara()
	return _ocupante.count(null)


## Centro do ponto (pros passeios): na FRENTE do prédio, fora da pegada da arte (como as obras).
func centro() -> Vector2:
	var dono := get_parent() as Node2D
	if dono and dono.is_inside_tree():
		return IsoArt.front(dono, deslocamento)
	return global_position + deslocamento


## Lugar i (posição global no chão).
func lugar(i: int) -> Vector2:
	_prepara()
	return _lugares[i] if i >= 0 and i < _lugares.size() else centro()


func roda_de(i: int) -> int:
	return i / maxi(por_roda, 1)


## Reserva um lugar pra `w`: de preferência numa roda que já tem gente (forma o par/grupo), senão a mais
## vazia. -1 = cheio. (Já reservado: devolve o mesmo.)
func reservar(w: Node) -> int:
	_prepara()
	var ja := _ocupante.find(w)
	if ja >= 0:
		return ja
	var melhor := -1
	var melhor_nota := -INF
	for r in rodas:
		var gente := 0
		var livre := -1
		for k in por_roda:
			var i := r * por_roda + k
			if _ocupante[i] == null:
				if livre < 0:
					livre = i
			else:
				gente += 1
		if livre < 0:
			continue
		# roda com 1-2 pessoas é a melhor (vira par/grupo); vazia vem depois; um pouco de sorte desempata
		var nota := (3.0 if gente in [1, 2] else (1.0 if gente == 0 else 0.5)) + randf() * 0.5
		if nota > melhor_nota:
			melhor_nota = nota
			melhor = livre
	if melhor >= 0:
		_ocupante[melhor] = w
	return melhor


func liberar(w: Node) -> void:
	var i := _ocupante.find(w)
	if i >= 0:
		_ocupante[i] = null


## Os outros da mesma roda de `w` que já chegaram (estão conversando).
func companheiros(w: Node) -> Array:
	var i := _ocupante.find(w)
	if i < 0:
		return []
	var r := roda_de(i)
	var out: Array = []
	for k in por_roda:
		var o = _ocupante[r * por_roda + k]
		if o != null and o != w and is_instance_valid(o) and o.has_method("esta_conversando") and o.esta_conversando():
			out.append(o)
	return out


## Quem está reservado aqui (pra janela/teste).
func ocupantes() -> Array:
	_prepara()
	return _ocupante.filter(func(o): return o != null and is_instance_valid(o))


## Calcula os lugares (rodas lado a lado na frente do prédio; os lugares de cada roda num círculo achatado
## da vista) e encaixa cada um no ponto navegável mais perto. Refaz se o dono mudou de lugar.
func _prepara() -> void:
	if _origem.distance_to(global_position) < 0.5 and _lugares.size() == vagas():
		return
	_origem = global_position
	var antigos := _ocupante.duplicate()
	_lugares.clear()
	_ocupante.clear()
	var mapa: RID = get_world_2d().navigation_map if is_inside_tree() else RID()
	for r in rodas:
		var c := centro() + Vector2((r - (rodas - 1) * 0.5) * espaco_rodas, 0.0)
		for k in por_roda:
			var a := TAU * (float(k) / por_roda) + PI * 0.5
			var p := c + Vector2(cos(a), sin(a) * 0.6) * raio_roda
			if mapa.is_valid() and NavigationServer2D.map_get_iteration_id(mapa) > 0:
				p = NavigationServer2D.map_get_closest_point(mapa, p)
			_lugares.append(p)
			_ocupante.append(null)
	for i in mini(antigos.size(), _ocupante.size()):
		_ocupante[i] = antigos[i]
