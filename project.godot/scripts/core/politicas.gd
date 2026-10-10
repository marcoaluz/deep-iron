extends Node
## Bloco 108: as POLÍTICAS DA VILA (nó "Politicas" da cena principal, grupos "politicas" e "modificadores"). Quatro
## decisões da vila inteira, cada uma com UMA opção ativa; o padrão de todas é exatamente o jogo de antes (tudo 1,0).
##   JORNADA   normal / estendida / reduzida — só o quanto rende, o risco de acidente e o ânimo DENTRO do expediente que já
##             existe (nenhum horário muda: volta, portão, invasão, missa e domingo ficam como estão). Os serviços essenciais
##             (funcoes_essenciais: cozinha, enfermaria, guardas, padre) não mudam; o turno extra da noite (tecla T) também não.
##   RAÇÃO     normal / reduzida — só a PORÇÃO por refeição (o cardápio da cozinha escolhe o PRATO; os dois multiplicam, com o
##             teto do comedouro). Porção e fome caem na mesma proporção: não cria comida. Reduzida por fraqueza_dias seguidos
##             traz a FRAQUEZA (rende menos, machuca mais) até fraqueza_recupera_dias depois de voltar. A "farta" foi cortada
##             no plano (repetia o ensopado).
##   SEGURANÇA padrão / vigilância reforçada / treinamento — vigilância: todos os guardas de vigia toda noite, o armazém
##             vigiado (roubo do Ferrugento e saque da brecha x vigilancia_roubo) e quem espera no portão protegido; custo:
##             créditos por guarda por noite (sem créditos, a noite vale o padrão). Treinamento (precisa de campo de treino):
##             treina mais rápido e o teto da habilidade sobe (o que passar de 100% cai devagar ao sair); custo: o ânimo dos
##             guardas.
##   MIGRAÇÃO  aberta / seletiva / fechada — seletiva: intervalo maior, só vem grupo com cama livre (do tamanho das camas) e
##             o prazo no portão cresce; fechada: o relógio do próximo grupo para. A rede de segurança (migrantes.gd) e o
##             satélite (ordem do jogador) valem sempre; quem já espera no portão fica até o prazo, sem punição.
## Regras: troca da mesma política só depois de troca_espera_dias (em greve ou com a vila insatisfeita, VOLTAR ao padrão é
## imediato); a penalidade de ânimo somada das políticas tem teto (animo_penalidade_max), e se a GREVE começar mesmo assim
## as opções que pesam no ânimo voltam sozinhas ao padrão (os grevistas exigem; greve_derruba): a política nunca força uma
## greve sem volta. A janela libera no estágio estagio_minimo da vila.
## Composição: os multiplicadores saem por mult(chave, quem) (o ponto único é modificadores.gd: a Dificuldade do Prompt 5
## entra no mesmo grupo). O ânimo sai por fatores_animo(w) — o ponto único de leitura; _reacao() é onde os traços
## (Prompt R) vão modular a reação de cada um. Save: chave "politicas".

signal mudou(politica: String, opcao: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")

const POLITICAS := ["jornada", "racao", "seguranca", "migracao"]
const OPCOES := {
	"jornada": ["normal", "estendida", "reduzida"],
	"racao": ["normal", "reduzida"],
	"seguranca": ["padrao", "vigilancia", "treinamento"],
	"migracao": ["aberta", "seletiva", "fechada"],
}
const PADRAO := {"jornada": "normal", "racao": "normal", "seguranca": "padrao", "migracao": "aberta"}
const NOME_POLITICA := {"jornada": "Jornada de trabalho", "racao": "Rações", "seguranca": "Segurança", "migracao": "Migração"}
const NOME_OPCAO := {
	"jornada": {"normal": "Normal", "estendida": "Estendida", "reduzida": "Reduzida"},
	"racao": {"normal": "Normal", "reduzida": "Reduzida"},
	"seguranca": {"padrao": "Padrão", "vigilancia": "Vigilância reforçada", "treinamento": "Treinamento"},
	"migracao": {"aberta": "Aberta", "seletiva": "Seletiva", "fechada": "Fechada"},
}

@export_group("Geral")
## Dias de jogo de espera entre duas trocas da MESMA política (a primeira troca é livre).
@export var troca_espera_dias: float = 1.0
## Teto (em pontos de ânimo) da penalidade SOMADA de todas as políticas numa pessoa: nunca empurra sozinha a vila pra greve.
@export var animo_penalidade_max: float = 12.0
## Estágio do Centro da Vila em que a janela libera (2 = Vilarejo).
@export var estagio_minimo: int = 2
## A confirmação avisa em vermelho se o ânimo médio previsto ficar abaixo disto.
@export var aviso_animo: float = 40.0
## Greve começou: as opções que tiram ânimo (jornada estendida, ração reduzida, treinamento) voltam ao padrão, sem espera.
## (Medido no Bloco 108: estendida + reduzida + uma morte na invasão levaram a vila à greve.)
@export var greve_derruba: bool = true

@export_group("Jornada")
## Estendida: multiplica a produção, a chance de acidente de trabalho e soma este ânimo.
@export var estendida_producao: float = 1.15
@export var estendida_acidente: float = 1.30
@export var estendida_animo: float = -8.0
## Reduzida: multiplica a produção, a chance de acidente e soma este ânimo.
@export var reduzida_producao: float = 0.85
@export var reduzida_acidente: float = 1.0
@export var reduzida_animo: float = 5.0
## Funções que a jornada NÃO afeta (os serviços essenciais: rendimento e ânimo ficam como estão).
## (Os nomes são os ROLE_* do ipezinho.gd; sem preload dele aqui: a janela carrega este script antes dos autoloads nos testes.)
@export var funcoes_essenciais: Array[String] = ["cozinheiro", "médico", "guarda", "padre"]

@export_group("Ração")
## Reduzida: multiplica a porção (unidades do comedouro) e a fome que ela enche — a MESMA proporção (não cria comida).
@export var racao_reduzida_porcao: float = 0.75
@export var racao_reduzida_fome: float = 0.75
## Ânimo de quem come a ração reduzida.
@export var racao_reduzida_animo: float = -6.0
## Dias seguidos de ração reduzida (contados a cada amanhecer) até a FRAQUEZA...
@export var fraqueza_dias: int = 3
## ...que dura estes dias depois de voltar à ração normal...
@export var fraqueza_recupera_dias: int = 2
## ...e multiplica a produção e a chance de acidente de trabalho (de quem a jornada afeta). Ninguém morre disso.
@export var fraqueza_producao: float = 0.9
@export var fraqueza_acidente: float = 1.25

@export_group("Segurança")
## Vigilância reforçada: créditos por guarda de vigia, por noite (cobrados ao anoitecer).
@export var vigilancia_custo_guarda: int = 5
## Vigilância reforçada: multiplica o roubo do Ferrugento no armazém e o saque da brecha.
@export var vigilancia_roubo: float = 0.5
## Treinamento: multiplica o ritmo do campo de treino...
@export var treino_ritmo: float = 1.5
## ...e o teto da habilidade de combate (1,0 = 100%: o padrão). A fórmula de dano e vida é a de sempre, esticada.
@export var treino_teto: float = 1.25
## Ânimo dos GUARDAS no treinamento ("treino puxado").
@export var treino_animo: float = -6.0
## Fora do treinamento, o que passou de 100% cai isto por segundo (até 100%).
@export var treino_decai: float = 0.002

@export_group("Migração")
## Seletiva: multiplica o intervalo entre grupos...
@export var seletiva_intervalo: float = 1.5
## ...e o prazo de quem espera no portão (mais tempo pra avaliar).
@export var seletiva_prazo: float = 2.0

## A opção ativa de cada política.
var ativa := PADRAO.duplicate()
## Segundos de jogo até poder trocar cada política de novo.
var espera := {"jornada": 0.0, "racao": 0.0, "seguranca": 0.0, "migracao": 0.0}
## Dias seguidos (amanheceres) na ração reduzida e os dias de recuperação que faltam da fraqueza.
var racao_dias := 0
var fraqueza_recupera := 0
## A vigilância desta noite foi paga? (sem créditos, a noite vale o padrão)
var vigilancia_paga := false
## Total de trocas na partida (telemetria).
var trocas := 0

var _t := 0.0
var _liberada_antes := -1  # -1 = ainda não olhou (o load não avisa de novo)


func _ready() -> void:
	add_to_group("politicas")
	add_to_group("modificadores")
	_liga.call_deferred()


func _liga() -> void:
	var dn := _dn()
	if dn:
		dn.day_started.connect(_amanheceu)
		dn.marco.connect(_marco)
	var mor := get_tree().get_first_node_in_group("morale")
	if mor and mor.has_signal("strike_started"):
		mor.strike_started.connect(_greve)


func _dn() -> Node:
	return get_tree().get_first_node_in_group("day_night")


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func _seg_por_dia() -> float:
	var dn := _dn()
	return dn.cycle_length() if dn and dn.has_method("cycle_length") else 540.0


func _process(delta: float) -> void:
	for p in espera:
		espera[p] = maxf(float(espera[p]) - delta, 0.0)
	_t -= delta
	if _t > 0.0:
		return
	_t = 1.0
	var lib := liberada()
	if _liberada_antes == 0 and lib:
		var hud := _hud()
		if hud:
			hud.show_toast("Nova janela: Políticas da Vila (%s) — jornada, rações, segurança e migração." % preload("res://scripts/core/teclas.gd").nome("painel_politicas"), Color(0.75, 0.9, 1.0))
	_liberada_antes = 1 if lib else 0
	# o que passou de 100% no treino cai devagar fora da política (ou sem campo)
	var teto := teto_treino()
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if float(w.combat_skill) > teto:
			w.combat_skill = maxf(teto, float(w.combat_skill) - treino_decai)


# ------------------------------------------------------------ consulta
func opcao(politica: String) -> String:
	return String(ativa.get(politica, PADRAO.get(politica, "")))


func e_padrao() -> bool:
	for p in POLITICAS:
		if opcao(p) != PADRAO[p]:
			return false
	return true


## A janela já libera? (o estágio da vila)
func liberada() -> bool:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return hub == null or int(hub.level) >= estagio_minimo


func fraqueza_ativa() -> bool:
	return racao_dias >= fraqueza_dias or fraqueza_recupera > 0


## A jornada (e a fraqueza) valem pra este ipezinho agora? Fora: os essenciais e o turno extra da noite.
func afeta(w: Node) -> bool:
	if w == null or not w.has_method("is_guard"):
		return true
	if String(w.job) in funcoes_essenciais:
		return false
	return not (bool(w.overtime) and w.has_method("_is_night") and w._is_night())


## Bloco 108: o multiplicador desta política pra chave (modificadores.gd chama).
func mult(chave: String, quem: Node = null) -> float:
	match chave:
		"producao":
			if not afeta(quem):
				return 1.0
			var m: float = {"estendida": estendida_producao, "reduzida": reduzida_producao}.get(opcao("jornada"), 1.0)
			return m * (fraqueza_producao if fraqueza_ativa() else 1.0)
		"acidente":
			if not afeta(quem):
				return 1.0
			var a: float = {"estendida": estendida_acidente, "reduzida": reduzida_acidente}.get(opcao("jornada"), 1.0)
			return a * (fraqueza_acidente if fraqueza_ativa() else 1.0)
		"porcao":
			return racao_reduzida_porcao if opcao("racao") == "reduzida" else 1.0
		"fome_refeicao":
			return racao_reduzida_fome if opcao("racao") == "reduzida" else 1.0
		"migracao_intervalo":
			return seletiva_intervalo if opcao("migracao") == "seletiva" else 1.0
		"treino":
			return treino_ritmo if treinamento_ativo() else 1.0
		"roubo":
			return vigilancia_roubo if vigilancia_ativa() else 1.0
	return 1.0


## Vigilância reforçada valendo esta noite (escolhida e paga).
func vigilancia_ativa() -> bool:
	return opcao("seguranca") == "vigilancia" and vigilancia_paga


func treinamento_ativo() -> bool:
	return opcao("seguranca") == "treinamento" and not get_tree().get_nodes_in_group("campos").is_empty()


## O teto da habilidade de combate agora (1,0 fora do treinamento).
func teto_treino() -> float:
	return maxf(treino_teto, 1.0) if treinamento_ativo() else 1.0


func migracao_fechada() -> bool:
	return opcao("migracao") == "fechada"


func migracao_seletiva() -> bool:
	return opcao("migracao") == "seletiva"


func prazo_mult() -> float:
	return seletiva_prazo if migracao_seletiva() else 1.0


# ------------------------------------------------------------ ânimo (o ponto único)
## O efeito das políticas no ânimo desta pessoa: [[texto, valor], ...]. A penalidade somada tem teto (animo_penalidade_max).
func fatores_animo(w: Node) -> Array:
	var f: Array = []
	if afeta(w):
		match opcao("jornada"):
			"estendida":
				f.append(["jornada estendida", _reacao(w, "jornada", estendida_animo)])
			"reduzida":
				f.append(["jornada reduzida", _reacao(w, "jornada", reduzida_animo)])
	if opcao("racao") == "reduzida":
		f.append(["ração reduzida", _reacao(w, "racao", racao_reduzida_animo)])
	if treinamento_ativo() and w != null and w.has_method("is_guard") and w.is_guard():
		f.append(["treino puxado", _reacao(w, "seguranca", treino_animo)])
	var neg := 0.0
	for x in f:
		neg += minf(float(x[1]), 0.0)
	if neg < -animo_penalidade_max and neg < 0.0:
		var k := animo_penalidade_max / -neg
		for x in f:
			if float(x[1]) < 0.0:
				x[1] = float(x[1]) * k
	return f


## A reação de UMA pessoa ao efeito de uma política no ânimo. Hoje é o valor puro; o Prompt R (traços) modula aqui.
func _reacao(_w: Node, _politica: String, valor: float) -> float:
	return valor


## O ânimo médio previsto se `politica` virar `nova` (a média de hoje + a diferença dos alvos).
func animo_previsto(politica: String, nova: String) -> float:
	var mor := get_tree().get_first_node_in_group("morale")
	var media: float = mor.average() if mor else -1.0
	var ws := get_tree().get_nodes_in_group("ipezinhos")
	if media < 0.0 or ws.is_empty():
		return media
	var antes := _soma_animo(ws)
	var guarda: String = ativa[politica]
	ativa[politica] = nova
	var depois := _soma_animo(ws)
	ativa[politica] = guarda
	return media + (depois - antes) / ws.size()


func _soma_animo(ws: Array) -> float:
	var s := 0.0
	for w in ws:
		for x in fatores_animo(w):
			s += float(x[1])
	return s


# ------------------------------------------------------------ trocar
## Em apuro: greve ou o aviso de "insatisfeitos" — aí voltar ao padrão é imediato.
func vila_em_apuro() -> bool:
	var mor := get_tree().get_first_node_in_group("morale")
	if mor == null:
		return false
	var media: float = mor.average()
	return bool(mor.on_strike) or (media >= 0.0 and media < float(mor.unhappy_warn_below))


## Por que não dá pra escolher essa opção agora ("" = pode).
func motivo_bloqueio(politica: String, nova: String) -> String:
	if not OPCOES.has(politica) or not nova in OPCOES[politica]:
		return "opção desconhecida"
	if not liberada():
		return "libera no estágio %s da vila" % _nome_estagio()
	if opcao(politica) == nova:
		return "já está valendo"
	if politica == "seguranca" and nova == "treinamento" and get_tree().get_nodes_in_group("campos").is_empty():
		return "precisa de um campo de treino (janela Defesa)"
	if float(espera[politica]) > 0.0 and not (nova == PADRAO[politica] and vila_em_apuro()):
		return "pode trocar daqui a %s" % texto_espera(politica)
	return ""


func _nome_estagio() -> String:
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.has_method("stage_name"):
		return hub.stage_name(estagio_minimo)
	return ["Acampamento", "Vilarejo", "Vila", "Vila Mineira", "Cidade Mineira"][clampi(estagio_minimo, 1, 5) - 1]


## "14 h" / "40 min" (horas do relógio do jogo) até a próxima troca dessa política.
func texto_espera(politica: String) -> String:
	var dn := _dn()
	var sph: float = dn.segundos_por_hora() if dn and dn.has_method("segundos_por_hora") else 22.5
	var h := float(espera[politica]) / maxf(sph, 0.01)
	if h >= 1.0:
		return "%d h" % ceili(h)  # (espaço que não quebra a linha)
	return "%d min" % maxi(ceili(h * 60.0), 1)


## O jogador confirmou a troca. Retorna se valeu.
func escolhe(politica: String, nova: String) -> bool:
	var motivo := motivo_bloqueio(politica, nova)
	if motivo != "":
		var hud := _hud()
		if hud:
			hud.show_toast("%s: %s." % [NOME_POLITICA.get(politica, politica), motivo], Color(1.0, 0.7, 0.4))
		return false
	_aplica(politica, nova)
	espera[politica] = troca_espera_dias * _seg_por_dia()
	trocas += 1
	var hud := _hud()
	if hud:
		hud.show_toast("Política da vila: %s → %s." % [NOME_POLITICA[politica], NOME_OPCAO[politica][nova]], Color(0.75, 0.9, 1.0))
	return true


## Pros testes e a medição: põe a opção sem espera nem bloqueio.
func forca(politica: String, nova: String) -> void:
	if OPCOES.has(politica) and nova in OPCOES[politica]:
		_aplica(politica, nova)


func _aplica(politica: String, nova: String) -> void:
	var antes := opcao(politica)
	ativa[politica] = nova
	if politica == "racao" and antes == "reduzida" and nova != "reduzida":
		if racao_dias >= fraqueza_dias:
			fraqueza_recupera = fraqueza_recupera_dias  # a fraqueza ainda dura uns dias
		racao_dias = 0
	if politica == "seguranca":
		vigilancia_paga = false
		var dn := _dn()
		if nova == "vigilancia" and dn and dn.is_night():
			_cobra_vigilancia()  # escolhida de noite: já vale nesta
	mudou.emit(politica, nova)


## A greve começou: os grevistas exigem o fim do que tira ânimo (volta ao padrão, sem espera pra escolher de novo depois).
func _greve() -> void:
	if not greve_derruba:
		return
	var caiu: Array = []
	for p in ["jornada", "racao", "seguranca"]:
		var op := opcao(p)
		if op == PADRAO[p] or not _tira_animo(p, op):
			continue
		_aplica(p, PADRAO[p])
		espera[p] = 0.0
		caiu.append("%s %s" % [NOME_POLITICA[p].to_lower(), NOME_OPCAO[p][op].to_lower()])
	if caiu.is_empty():
		return
	var hud := _hud()
	if hud:
		hud.show_toast("Os grevistas exigiram: acabou %s (as políticas voltaram ao padrão)." % ", ".join(caiu), Color(1.0, 0.6, 0.4))


func _tira_animo(politica: String, op: String) -> bool:
	match [politica, op]:
		["jornada", "estendida"]:
			return estendida_animo < 0.0
		["jornada", "reduzida"]:
			return reduzida_animo < 0.0
		["racao", "reduzida"]:
			return racao_reduzida_animo < 0.0
		["seguranca", "treinamento"]:
			return treino_animo < 0.0
	return false


# ------------------------------------------------------------ relógio
func _amanheceu(_d: int) -> void:
	vigilancia_paga = false
	if opcao("racao") == "reduzida":
		racao_dias += 1
		if racao_dias == fraqueza_dias:
			var hud := _hud()
			if hud:
				hud.show_toast("A ração reduzida já pesa: a vila está FRACA (rende menos e se machuca mais).", Color(1.0, 0.55, 0.4))
	elif fraqueza_recupera > 0:
		fraqueza_recupera -= 1


func _marco(nome: String) -> void:
	if nome == "anoitecer" and opcao("seguranca") == "vigilancia":
		_cobra_vigilancia()


func guardas() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.is_guard())


func custo_vigilancia() -> int:
	return vigilancia_custo_guarda * guardas().size()


func _cobra_vigilancia() -> void:
	var custo := custo_vigilancia()
	var eco := get_tree().get_first_node_in_group("economy")
	if custo <= 0:
		vigilancia_paga = true
		return
	if eco and int(eco.credits) >= custo and eco.spend(custo, 0):
		vigilancia_paga = true
		return
	vigilancia_paga = false
	var hud := _hud()
	if hud:
		hud.show_toast("Sem %d cr pras tochas: esta noite a vigilância é a de sempre." % custo, Color(1.0, 0.6, 0.4))


# ------------------------------------------------------------ textos da janela
## {porque, ganha: [..], custa: [..], restricao} de uma opção, com os números de agora.
func texto(politica: String, op: String) -> Dictionary:
	var pct := func(x: float) -> String: return "%+d%%" % roundi((x - 1.0) * 100.0)
	var dias := func(n: float) -> String: return "1 dia" if is_equal_approx(n, 1.0) else ("%d dias" % roundi(n) if is_equal_approx(n, roundf(n)) else "%s dias" % str(n))
	match [politica, op]:
		["jornada", "normal"]:
			return {"porque": "O equilíbrio de sempre.", "ganha": ["Nada muda."], "custa": [], "restricao": ""}
		["jornada", "estendida"]:
			return {"porque": "Correr com uma obra ou juntar minério pra uma meta.",
				"ganha": ["Produção %s (minas, corte, colheita, obras, oficinas)." % pct.call(estendida_producao)],
				"custa": ["Ânimo %+d de quem produz." % roundi(estendida_animo), "Acidentes de trabalho %s." % pct.call(estendida_acidente)],
				"restricao": "O horário não muda (nem a volta, o portão, a missa e o domingo). Cozinha, enfermaria, guardas e padre ficam como estão. Se a vila entrar em greve, volta ao normal sozinha."}
		["jornada", "reduzida"]:
			return {"porque": "Segurar uma vila triste longe da greve sem gastar créditos.",
				"ganha": ["Ânimo %+d de quem produz." % roundi(reduzida_animo)],
				"custa": ["Produção %s." % pct.call(reduzida_producao)],
				"restricao": "O horário não muda. Cozinha, enfermaria, guardas e padre ficam como estão."}
		["racao", "normal"]:
			return {"porque": "Cada um come a porção de sempre.", "ganha": ["Nada muda."], "custa": [], "restricao": ""}
		["racao", "reduzida"]:
			return {"porque": "Esticar a comida numa crise (sobra mais no verão; no inverno não tem margem).",
				"ganha": ["Porção %s: a cozinha rende mais refeições." % pct.call(racao_reduzida_porcao)],
				"custa": ["Cada refeição enche %s de fome." % pct.call(racao_reduzida_fome), "Ânimo %+d de todos." % roundi(racao_reduzida_animo),
					"Depois de %s seguidos: FRAQUEZA (produção %s, acidentes %s) até %s depois de voltar." % [
						dias.call(fraqueza_dias), pct.call(fraqueza_producao), pct.call(fraqueza_acidente), dias.call(fraqueza_recupera_dias)]],
				"restricao": "Não cria comida: sem comida na cozinha, ninguém come de qualquer jeito. O prato do cardápio continua valendo. Se a vila entrar em greve, volta ao normal sozinha."}
		["seguranca", "padrao"]:
			return {"porque": "Metade dos guardas vigia cada noite, em rodízio (na invasão, todos).", "ganha": ["Nada muda."], "custa": [], "restricao": ""}
		["seguranca", "vigilancia"]:
			return {"porque": "Proteger o estoque e quem espera no portão.",
				"ganha": ["Todos os guardas de vigia toda noite.", "Roubo do Ferrugento e saque da brecha %s." % pct.call(vigilancia_roubo),
					"Quem espera no portão não é atacado."],
				"custa": ["%d cr por guarda por noite (hoje: %d cr)." % [vigilancia_custo_guarda, custo_vigilancia()]],
				"restricao": "Sem créditos ao anoitecer, aquela noite vale o padrão."}
		["seguranca", "treinamento"]:
			return {"porque": "Preparar os guardas pras ondas mais fortes.",
				"ganha": ["Treino %s mais rápido." % pct.call(treino_ritmo),
					"A habilidade vai até %d%% (dano e vida maiores)." % roundi(treino_teto * 100.0)],
				"custa": ["Ânimo %+d dos guardas (treino puxado)." % roundi(treino_animo)],
				"restricao": "Precisa de um campo de treino. Ao sair, o que passou de 100% cai devagar."}
		["migracao", "aberta"]:
			return {"porque": "A vila cresce com quem chega, pela atratividade.", "ganha": ["Nada muda."], "custa": [], "restricao": ""}
		["migracao", "seletiva"]:
			return {"porque": "Crescer no ritmo das camas e com tempo pra decidir.",
				"ganha": ["Só vem grupo com cama livre, do tamanho das camas.", "Prazo no portão %s." % pct.call(seletiva_prazo)],
				"custa": ["Grupos %s mais espaçados." % pct.call(seletiva_intervalo)],
				"restricao": "A ajuda de quando a vila fica pequena chega sempre."}
		["migracao", "fechada"]:
			return {"porque": "Segurar a população numa crise de comida ou de camas.",
				"ganha": ["Ninguém novo chega."],
				"custa": ["A vila não cresce."],
				"restricao": "Quem já espera no portão fica até o prazo. A ajuda de quando a vila fica pequena e o satélite chegam mesmo assim."}
	return {"porque": "", "ganha": [], "custa": [], "restricao": ""}


## "jornada=estendida racao=normal ..." (telemetria e medição).
func resumo() -> String:
	var p: Array = []
	for k in POLITICAS:
		p.append("%s=%s" % [k, opcao(k)])
	return " ".join(p)


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	return {"ativa": ativa.duplicate(), "espera": espera.duplicate(), "racao_dias": racao_dias,
		"fraqueza_recupera": fraqueza_recupera, "vigilancia_paga": vigilancia_paga, "trocas": trocas}


## Save antigo (sem a chave): tudo no padrão, sem espera.
func load_save_data(d: Dictionary) -> void:
	var a := SaveUtil.dict(d, "ativa")
	for p in POLITICAS:
		var v := SaveUtil.text(a, p, PADRAO[p])
		ativa[p] = v if v in OPCOES[p] else PADRAO[p]
	var e := SaveUtil.dict(d, "espera")
	for p in POLITICAS:
		espera[p] = maxf(SaveUtil.num(e, p, 0.0), 0.0)
	racao_dias = maxi(SaveUtil.integer(d, "racao_dias", 0), 0)
	fraqueza_recupera = maxi(SaveUtil.integer(d, "fraqueza_recupera", 0), 0)
	vigilancia_paga = SaveUtil.boolean(d, "vigilancia_paga", false)
	trocas = maxi(SaveUtil.integer(d, "trocas", 0), 0)
