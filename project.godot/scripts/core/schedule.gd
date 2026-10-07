extends Node
## Bloco 84: a AGENDA dos ipezinhos (nó "Schedule" da cena principal, grupo "schedule") — a camada de
## horários POR CIMA do _choose_state do ipezinho.gd, sem reescrever o que já funcionava.
##
## Prioridade: EMERGÊNCIA (caído, ferido, resgate, onda solar, invasão, greve) > AGENDA (este nó diz em que
## período cada um está) > NECESSIDADES (comer fora de hora só com fome braba, taverna...).
##
## Os 4 marcos do dia são os do relógio (day_night.gd: amanhecer, fim do expediente, anoitecer, dormir — um
## lugar só pra esses horários); os daqui completam a agenda:
##   amanhecer .. cafe_fim            "cafe"      acordar e tomar café
##   cafe_fim .. almoco_inicio        "trabalho"
##   almoco_inicio .. almoco_fim      "almoco"
##   almoco_fim .. fim do expediente  "trabalho"
##   fim do expediente .. anoitecer   "voltar"    voltar e largar a carga no armazém
##   anoitecer .. dormir              "social"    jantar e hora social (Bloco 85)
##   dormir .. amanhecer              "dormir"
## Exceções:
##   - médico: sempre de PLANTÃO ("plantao"); come em TURNOS — o médico k come na k-ésima fatia de
##     medico_turno horas de cada refeição (um de cada vez, a enfermaria nunca fica sozinha);
##   - guardas: VIGÍLIA noturna em rodízio ("vigilia": vigilia_fracao dos guardas por noite, girando a cada
##     dia; na noite de invasão, todos); quem não está de vigia faz a noite normal (social, dormir);
##   - cozinheiro: começa em cozinheiro_inicio (04:00, prepara o café) e de jantar_preparo (16:00) até o
##     anoitecer fica cozinhando o jantar (não tem o "voltar").
##
## Refeições (fome controlada): a fome cai devagar (ipezinho.hunger_decay); cada refeição (café, almoço,
## jantar) é UMA porção do comedouro (porcao) e restaura refeicao_fome. Quem está sem fome (acima de
## refeicao_dispensa do máximo) pula a refeição sem problema; quem estava com fome e deixou a janela passar sem
## comer PERDEU a refeição: rende perda_por_refeicao a menos (até perda_max seguidas) até comer de novo.
## O HUD mostra as refeições que ainda faltam hoje x as porções no estoque.
##
## Bloco 85: a HORA SOCIAL (anoitecer..dormir, depois do jantar): os ipezinhos escolhem um PONTO SOCIAL
## (social_spot.gd: refeitório, praça, taverna, parque...), reservam um lugar numa roda, vão passando por
## outro ponto no caminho (waypoint) e conversam em pares/grupos (balão com ícone); depois de um tempo trocam
## de ponto. Com chuva ou onda solar só valem os pontos cobertos. Conversar dá um pouco de ânimo.

const MEALS := ["cafe", "almoco", "jantar"]
const NOMES_REFEICAO := {"cafe": "café", "almoco": "almoço", "jantar": "jantar"}

@export_group("Agenda (horas do relógio; os marcos ficam no DayNight)")
## Fim do café (o trabalho da manhã começa). 7.0 = 07:00.
@export_range(0.0, 24.0, 0.25) var cafe_fim: float = 7.0
## Almoço: começo e fim.
@export_range(0.0, 24.0, 0.25) var almoco_inicio: float = 12.0
@export_range(0.0, 24.0, 0.25) var almoco_fim: float = 13.0

@export_group("Exceções")
## O cozinheiro acorda e começa a cozinhar (o café) a esta hora.
@export_range(0.0, 24.0, 0.25) var cozinheiro_inicio: float = 4.0
## Daqui até o anoitecer o cozinheiro prepara o jantar (sem o "voltar" das 18:00).
@export_range(0.0, 24.0, 0.25) var jantar_preparo: float = 16.0
## Horas de cada turno de refeição do médico (o 2º médico come depois do 1º, e assim por diante).
@export_range(0.25, 2.0, 0.25) var medico_turno: float = 0.5
## Fração dos guardas de vigia numa noite comum (gira a cada dia; pelo menos 1). Noite de invasão: todos.
@export_range(0.0, 1.0, 0.05) var vigilia_fracao: float = 0.5

@export_group("Refeições")
## Unidades de comida do comedouro que uma refeição gasta (uma porção).
@export var porcao: float = 8.0
## Fome que uma refeição restaura (a fome vai até 100).
@export var refeicao_fome: float = 45.0
## Acima desta fração da fome máxima ele pula a refeição (sem fome; não conta como perdida).
@export_range(0.0, 1.0, 0.05) var refeicao_dispensa: float = 0.9
## Quanto o trabalho rende a menos por refeição perdida (0.12 = -12%)...
@export_range(0.0, 0.5, 0.01) var perda_por_refeicao: float = 0.12
## ...até este tanto de refeições perdidas seguidas.
@export_range(0, 6) var perda_max: int = 3

@export_group("Hora social (Bloco 85)")
## Segundos REAIS que ele fica em cada ponto antes de trocar (sorteado entre os dois).
@export var conversa_min: float = 10.0
@export var conversa_max: float = 22.0
## Ânimo por segundo conversando com alguém na roda (x animo_mult do ponto)...
@export var animo_por_segundo: float = 0.5
## ...até este tanto (fator "conversou com os amigos" no ânimo)...
@export var animo_max: float = 8.0
## ...que vai sumindo devagar depois (por segundo).
@export var animo_decai: float = 0.01
## Intervalo (s) entre um balão e outro de quem está numa roda (sorteado entre os dois).
@export var balao_min: float = 2.0
@export var balao_max: float = 4.5
## Passeio: passa por outro ponto no caminho se o desvio for até isto (px do chão).
@export var passeio_desvio: float = 160.0

var _dn: Node
var _cache := {}
var _cache_quadro := -1


func _ready() -> void:
	add_to_group("schedule")
	_liga.call_deferred()


func _liga() -> void:
	_dn = get_tree().get_first_node_in_group("day_night")
	if _dn:
		_dn.day_started.connect(_novo_dia)


func _relogio() -> Node:
	if _dn == null or not is_instance_valid(_dn):
		_dn = get_tree().get_first_node_in_group("day_night")
	return _dn


## Amanheceu: as refeições do dia zeram pra todo mundo.
func _novo_dia(_d: int) -> void:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.get("refeicoes_hoje") != null:
			w.refeicoes_hoje.clear()


# ------------------------------------------------------------ períodos
## Em que período da agenda este ipezinho está agora ("" = sem relógio).
func periodo(w: Node) -> String:
	var dn := _relogio()
	if dn == null:
		return ""
	var h: float = dn.hora()
	if w != null and w.has_method("is_doctor") and w.is_doctor():
		return _periodo_medico(w, dn, h)
	# Bloco 88: o domingo (missa de manhã; a tarde que o jogador escolheu) — o padre tem a agenda dele
	var cal := get_tree().get_first_node_in_group("calendario")
	if cal and not (w != null and w.has_method("is_priest") and w.is_priest()):
		var pd: String = cal.periodo_domingo(h)
		if pd != "":
			return pd
	if w != null and w.has_method("is_guard") and w.is_guard() and dn.is_night() and de_vigia(w):
		# o guarda de vigia janta primeiro (na hora do jantar, com fome) e depois vai pro posto
		if periodo_geral(h) == "social" and not w.refeicoes_hoje.has("jantar") and w.hunger < w.hunger_max * refeicao_dispensa:
			return "social"
		return "vigilia"
	if w != null and w.has_method("is_cook") and w.is_cook():
		if dn.entre_horas(cozinheiro_inicio, dn.hora_amanhecer) or dn.entre_horas(jantar_preparo, dn.hora_anoitecer):
			return "trabalho"
	return periodo_geral(h)


## O período de todo mundo (sem as exceções) numa hora.
func periodo_geral(h: float) -> String:
	var dn := _relogio()
	if _entre(h, dn.hora_amanhecer, cafe_fim):
		return "cafe"
	if _entre(h, cafe_fim, almoco_inicio):
		return "trabalho"
	if _entre(h, almoco_inicio, almoco_fim):
		return "almoco"
	if _entre(h, almoco_fim, dn.hora_fim_expediente):
		return "trabalho"
	if _entre(h, dn.hora_fim_expediente, dn.hora_anoitecer):
		return "voltar"
	if _entre(h, dn.hora_anoitecer, dn.hora_dormir):
		return "social"
	return "dormir"


## Médico: plantão o tempo todo, menos na fatia dele de cada refeição (turnos).
func _periodo_medico(w: Node, dn: Node, h: float) -> String:
	var k := maxi(_indice(w, "is_doctor"), 0)
	for par in [["cafe", dn.hora_amanhecer], ["almoco", almoco_inicio], ["social", dn.hora_anoitecer]]:
		var ini: float = par[1] + k * medico_turno
		if _entre(h, ini, ini + medico_turno):
			return par[0]
	return "plantao"


## A refeição de um período ("" = não é hora de comer).
func refeicao_do(p: String) -> String:
	match p:
		"cafe":
			return "cafe"
		"almoco":
			return "almoco"
		"social":
			return "jantar"
	return ""


## Guarda de vigia esta noite? Noite de invasão: todos. Senão vigilia_fracao deles, girando a cada dia.
func de_vigia(w: Node) -> bool:
	var dn := _relogio()
	var def := get_tree().get_first_node_in_group("defense")
	var dia: int = dn.day if dn else 1
	if def and (def.invasion_active or def.is_invasion_night(dia)):
		return true
	var guardas: Array = _da_funcao("is_guard")
	var n := guardas.size()
	var i := guardas.find(w)
	if n == 0 or i < 0:
		return false
	var de_vez := clampi(ceili(n * vigilia_fracao), 1, n)
	return posmod(i - dia, n) < de_vez


func _entre(h: float, a: float, b: float) -> bool:
	return fposmod(h - a, 24.0) < fposmod(b - a, 24.0)


## Quem tem essa função, numa ordem que não muda (pelo nome do nó). Guardado por quadro (todo ipezinho
## pergunta: com muitos, refazer a lista pra cada um pesava).
func _da_funcao(metodo: String) -> Array:
	var f := Engine.get_process_frames()
	if f != _cache_quadro:
		_cache.clear()
		_cache_quadro = f
	if not _cache.has(metodo):
		var out: Array = get_tree().get_nodes_in_group("ipezinhos").filter(func(x): return x.has_method(metodo) and x.call(metodo))
		out.sort_custom(func(a, b): return String(a.name) < String(b.name))
		_cache[metodo] = out
	return _cache[metodo]


func _indice(w: Node, metodo: String) -> int:
	return _da_funcao(metodo).find(w)


# ------------------------------------------------------------ refeições
## Quanto ele rende com as refeições perdidas (1.0 = nenhuma).
func mult_refeicoes(perdidas: int) -> float:
	return 1.0 - perda_por_refeicao * clampi(perdidas, 0, perda_max)


## Refeições que ainda faltam hoje pra vila (de cada um, as que não fez e cuja hora ainda não passou).
func refeicoes_restantes_hoje() -> int:
	var dn := _relogio()
	if dn == null:
		return 0
	var agora: float = dn.time
	var fins := {"cafe": dn.tempo_da_hora(cafe_fim), "almoco": dn.tempo_da_hora(almoco_fim), "jantar": dn.tempo_da_hora(dn.hora_dormir)}
	var total := 0
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		var feitas: Dictionary = w.get("refeicoes_hoje") if w.get("refeicoes_hoje") != null else {}
		for m in MEALS:
			if not feitas.has(m) and fins[m] > agora:
				total += 1
	return total


## Porções no estoque (comedouros).
func porcoes_em_estoque() -> float:
	var comida := 0.0
	for c in get_tree().get_nodes_in_group("comedouros"):
		comida += c.food_stock
	return comida / maxf(porcao, 0.01)


static func nome_refeicao(m: String) -> String:
	return NOMES_REFEICAO.get(m, m)
