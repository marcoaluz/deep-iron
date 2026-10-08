extends Node2D
## Bloco 99: a ESCADA EM ESPIRAL (grupo "espirais") — a rota LENTA de emergência entre dois andares, ao lado do poço
## do elevador. Antes (Bloco 72) era só desenho na coluna; agora é uma ligação de navegação (NavigationLink2D) SEMPRE
## aberta junto com o andar de baixo, com custo alto: o caminho prefere o elevador e só vem por aqui quando a cabine
## está quebrada, arruinada ou ainda não foi restaurada (assim ninguém fica preso embaixo sem comida). Quem chega na
## casinha da escada some e aparece no patamar do outro andar depois de `segundos_por_andar` (ipezinho.gd
## _on_link_reached usa o ride_wait daqui). Montada pelo environment.gd (_build_espirais), uma por ligação; sem save
## (a posição vem do mapa e o "aberto" vem da ligação do andar).

## Segundos (de jogo) pra subir ou descer um andar pela escada.
@export var segundos_por_andar: float = 20.0
## Custo de navegação por px (o elevador custa 0,05: alto aqui = só quando a cabine não serve).
@export var custo: float = 1.0

## A ligação do andar de baixo (o elevador do S2 ou a plataforma): a escada abre quando o andar abre.
var ligacao: Node = null
## O patamar de cima e o de baixo (lógica do chão).
var topo := Vector2.ZERO
var fundo := Vector2.ZERO
var _link: NavigationLink2D


func _ready() -> void:
	add_to_group("espirais")
	global_position = topo
	_link = NavigationLink2D.new()
	_link.name = "Link"
	_link.bidirectional = true
	_link.start_position = Vector2.ZERO
	_link.end_position = fundo - topo
	_link.travel_cost = custo
	_link.enter_cost = 0.0
	add_child(_link)
	sync()


## Aberta junto com o andar de baixo.
func sync() -> void:
	if _link:
		_link.enabled = aberta()


## Os patamares grudados no chão andável (a ligação só pega a até 4 px da malha). A malha muda (casa nova, leste
## desbravado...): confere de vez em quando e gruda de novo.
var _confere_t := 0.0


func _physics_process(delta: float) -> void:
	_confere_t -= delta
	if _confere_t > 0.0 or _link == null:
		return
	_confere_t = 2.0
	var map := get_world_2d().navigation_map
	if not map.is_valid() or NavigationServer2D.map_get_iteration_id(map) == 0:
		return
	var a := NavigationServer2D.map_get_closest_point(map, topo)
	var b := NavigationServer2D.map_get_closest_point(map, fundo)
	if a.distance_to(topo) > 0.5 and a.distance_to(topo) < 120.0:
		topo = a
	if b.distance_to(fundo) > 0.5 and b.distance_to(fundo) < 120.0:
		fundo = b
	global_position = topo
	_link.start_position = Vector2.ZERO
	_link.end_position = fundo - topo


func aberta() -> bool:
	return ligacao != null and is_instance_valid(ligacao) and ligacao.get("unlocked") == true


## Quanto tempo o ipezinho fica na escada (ipezinho.gd: some e aparece do outro lado).
func ride_wait() -> float:
	return segundos_por_andar
