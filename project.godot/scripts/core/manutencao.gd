extends Node
## Bloco 105: a MANUTENÇÃO das máquinas (nó "Manutencao" na main.tscn, grupo "manutencao") — o trabalho do MECÂNICO.
##
## - As MÁQUINAS (grupo "maquinas") falam pela interface (duck typing):
##     manut_tipo() -> String           "escavadeira", "coletor_madeira", "coletor_minerio", "ventilador", "robo",
##                                      "cabine", "trilho"
##     manut_condicao() -> float        1 nova .. 0 quebrada
##     manut_quebrada() -> bool
##     manut_titulo() -> String         "Coletor de madeira"
##     manut_pos(worker) -> Vector2     onde o mecânico trabalha
##     manut_preventiva()               a preventiva acabou: volta a 1 (sem material)
##     manut_conserto_proprio() -> bool true = a máquina já tem a obra do conserto dela (cabine, trilho; Bloco 99)
##   As de desgaste novo (desgaste.gd) gastam pela vida daqui (minério, madeira, horas, quedas) e rendem menos depois de
##   `desgaste_inicio_perda`; em 0 quebram e param.
## - A QUEBRA vira obra de conserto com material (conserto_maquina.gd: ObraSite, ofício "mecanico"). Paga só quando dá
##   pra pagar TUDO e tem quem conserte (mecânico ou engenheiro) — nada é gasto à toa; tenta de novo a cada pouco.
## - A PREVENTIVA (só o tempo do mecânico): a máquina mais gasta abaixo de `limite_preventiva`, reservada pra um mecânico.
##   Sem mecânico, não tem preventiva (o engenheiro só conserta a quebra, quando não tem obra).
## Save: chave "manutencao" (os consertos pendentes e os contadores); a condição de cada máquina vai no save dela.

signal manutencao_feita(maquina: Node, tipo: String)
signal conserto_feito(maquina: Node, tipo: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const CONSERTO := preload("res://scripts/props/conserto_maquina.gd")

@export_group("Desgaste (Bloco 105) — PROVISÓRIO até a análise da telemetria")
## Desgaste (fração) a partir do qual a máquina começa a render menos (0.4 = com 40% de desgaste).
@export_range(0.0, 1.0) var desgaste_inicio_perda: float = 0.4
## O quanto ela rende no fim (logo antes de quebrar).
@export_range(0.0, 1.0) var eficiencia_min: float = 0.5
## A preventiva do mecânico começa abaixo desta condição.
@export_range(0.0, 1.0) var limite_preventiva: float = 0.6
## Condição em que a máquina avisa que vai falhar (o aviso e o alerta do ventilador).
@export_range(0.0, 1.0) var condicao_aviso: float = 0.25
## A VIDA de cada tipo até quebrar, na unidade dele: escavadeira = minério tirado; coletores = unidades produzidas;
## ventilador = horas de jogo ligado; robô = quedas na luta.
@export var vida: Dictionary = {"escavadeira": 600.0, "coletor_madeira": 300.0, "coletor_minerio": 300.0,
	"ventilador": 72.0, "robo": 4.0}
## Segundos de jogo de trabalho do mecânico na preventiva, por tipo.
@export var segundos_preventiva: Dictionary = {"escavadeira": 30.0, "coletor_madeira": 20.0, "coletor_minerio": 20.0,
	"ventilador": 15.0, "robo": 25.0, "cabine": 20.0, "trilho": 15.0}
## O conserto da QUEBRA por tipo: [créditos, metal (ferro/barra), madeira, segundos de trabalho].
@export var conserto: Dictionary = {"escavadeira": [120, 30, 10, 45.0], "coletor_madeira": [60, 15, 15, 30.0],
	"coletor_minerio": [60, 20, 10, 30.0], "ventilador": [80, 15, 0, 25.0], "robo": [100, 20, 0, 40.0]}
## Segundos (reais) entre uma tentativa e outra de pagar um conserto que faltava material.
@export var conserto_tenta_cada: float = 5.0
## Segundos de jogo andando sem chegar na máquina da preventiva antes de o mecânico desistir (caminho fechado, andar sem
## acesso: a telemetria achou o mecânico preso horas atrás dos ventiladores do S2).
@export var preventiva_desiste: float = 60.0
## Depois de desistir, segundos de jogo em que essa máquina fica fora da lista da preventiva.
@export var preventiva_evita: float = 240.0

var preventivas := 0
var consertos_feitos := 0
## Quantas vezes cada tipo quebrou na partida (telemetria, teste): {tipo: n}.
var quebras := {}
var _reservas := {}  # máquina -> mecânico
var _t := 0.0
var _avisou := {}  # máquina -> true (o aviso de falha já foi dado)
var _evita := {}  # máquina -> segundos de jogo fora da preventiva (o mecânico não conseguiu chegar)


func _ready() -> void:
	add_to_group("manutencao")


func maquinas() -> Array:
	return get_tree().get_nodes_in_group("maquinas").filter(func(m): return is_instance_valid(m) and m.has_method("manut_condicao"))


## A fração da vida que `quantidade` gasta (pra máquina chamar: _desgaste.gasta(manutencao.fracao(tipo, q))).
## As máquinas pro alerta: quebradas ou falhando (condição no aviso ou abaixo).
func com_problema() -> Array:
	return maquinas().filter(func(m): return m.manut_quebrada() or float(m.manut_condicao()) <= condicao_aviso)


func total_quebras() -> int:
	var n := 0
	for k in quebras:
		n += int(quebras[k])
	return n


func fracao(tipo: String, quantidade: float) -> float:
	var v := float(vida.get(tipo, 0.0))
	return quantidade / v if v > 0.0 else 0.0


## Gasta a máquina pela unidade dela (escavadeira: minério; ventilador: horas...).
static func gasta_em(no: Node, tipo: String, quantidade: float) -> void:
	var d = no.get("_desgaste")
	var m: Node = no.get_tree().get_first_node_in_group("manutencao") if no.is_inside_tree() else null
	if d == null or m == null:
		return
	d.gasta(m.fracao(tipo, quantidade))


func tem_mecanico() -> bool:
	return get_tree().get_nodes_in_group("ipezinhos").any(func(w): return w.has_method("is_mechanic") and w.is_mechanic() and not w.injured)


func tem_quem_conserte() -> bool:
	return get_tree().get_nodes_in_group("ipezinhos").any(func(w): return not w.injured and ((w.has_method("is_mechanic") and w.is_mechanic()) or (w.has_method("is_engineer") and w.is_engineer())))


# ------------------------------------------------------------ avisos (a Desgaste chama)
func mudou_condicao(maq: Node, antes: float, depois: float) -> void:
	if maq == null or not is_instance_valid(maq):
		return
	if antes > condicao_aviso and depois <= condicao_aviso and depois > 0.0 and not _avisou.has(maq):
		_avisou[maq] = true
		_aviso("%s está falhando (%d%%): chame o mecânico." % [maq.manut_titulo(), roundi(depois * 100.0)], Color(1.0, 0.8, 0.4), maq)
	if depois > condicao_aviso:
		_avisou.erase(maq)


## Uma máquina com o conserto próprio (a cabine, o trilho) quebrou: só conta (o aviso e a obra são dela).
func conta_quebra(maq: Node) -> void:
	if maq != null and is_instance_valid(maq) and maq.has_method("manut_tipo"):
		quebras[maq.manut_tipo()] = int(quebras.get(maq.manut_tipo(), 0)) + 1


## O conserto próprio (cabine, trilho) acabou: conta como conserto (missões, telemetria).
func conserto_proprio_terminou(maq: Node) -> void:
	conserto_terminou(maq)


func quebrou(maq: Node) -> void:
	if maq == null or not is_instance_valid(maq):
		return
	quebras[maq.manut_tipo()] = int(quebras.get(maq.manut_tipo(), 0)) + 1
	_aviso("%s QUEBROU: parou. O mecânico conserta (com material)." % maq.manut_titulo(), Color(1.0, 0.5, 0.4), maq)
	var au := get_node_or_null("/root/Audio")
	if au and au.has_method("som"):
		au.som("maquinas/quebrou", (maq as Node2D).global_position)  # Bloco 115 (sem arquivo, a quebra de sempre)
	_tenta_consertos()


func _aviso(t: String, cor: Color, alvo: Node = null) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if alvo is Node2D:
			hud.show_toast(t, cor, alvo)
		else:
			hud.show_toast(t, cor)


# ------------------------------------------------------------ a quebra: a obra do conserto
func conserto_de(maq: Node) -> Node:
	for c in get_tree().get_nodes_in_group("consertos_maquina"):
		if is_instance_valid(c) and c.maquina == maq:
			return c
	return null


func custo(tipo: String) -> Array:
	var c: Array = conserto.get(tipo, [50, 10, 0, 30.0])
	return c


## As máquinas quebradas sem obra: paga o conserto se der (tudo) e se tem quem conserte; senão espera.
func _tenta_consertos() -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return
	for maq in maquinas():
		if not maq.manut_quebrada() or maq.manut_conserto_proprio() or conserto_de(maq) != null:
			continue
		if not tem_quem_conserte():
			continue  # (ninguém pra consertar: não gasta material à toa)
		var c := custo(maq.manut_tipo())
		if eco.metal_falta(int(c[0]), int(c[1]), "ferro", int(c[2])) != "":
			continue  # falta material: tenta de novo daqui a pouco (nada é gasto)
		if not eco.paga_metal(int(c[0]), int(c[1]), "ferro", int(c[2])):
			continue
		var obra: Node2D = CONSERTO.new()
		obra.maquina = maq
		obra.segundos = float(c[3])
		obra.position = (maq as Node2D).global_position
		get_tree().get_first_node_in_group("village_hub").get_parent().add_child(obra)
		obra._obra.start()  # (no MESMO quadro do pagamento: o material vira a lista da obra)


## O que falta pra pagar o conserto dessa máquina ("" = dá).
func conserto_falta(maq: Node) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	var c := custo(maq.manut_tipo())
	return eco.metal_falta(int(c[0]), int(c[1]), "ferro", int(c[2])) if eco else ""


## A obra do conserto acabou (conserto_maquina.gd chama).
func conserto_terminou(maq: Node) -> void:
	consertos_feitos += 1
	_avisou.erase(maq)
	conserto_feito.emit(maq, maq.manut_tipo() if is_instance_valid(maq) else "")


# ------------------------------------------------------------ a preventiva (só o mecânico)
## A máquina mais gasta (abaixo do limite, não quebrada, sem outro mecânico nela) pra esse mecânico. null = nenhuma.
func alvo_preventiva(w: Node) -> Node:
	for maq in _reservas.keys():
		if _reservas[maq] == w and is_instance_valid(maq) and not maq.manut_quebrada() and maq.manut_condicao() < limite_preventiva:
			return maq
	var melhor: Node = null
	for maq in maquinas():
		if maq.manut_quebrada() or maq.manut_condicao() >= limite_preventiva or _evita.has(maq):
			continue
		var dono = _reservas.get(maq)
		if dono != null and dono != w and is_instance_valid(dono):
			continue
		if melhor == null or maq.manut_condicao() < melhor.manut_condicao():
			melhor = maq
	return melhor


func reserva(maq: Node, w: Node) -> void:
	for m in _reservas.keys():
		if _reservas[m] == w and m != maq:
			_reservas.erase(m)
	_reservas[maq] = w


## O mecânico não chegou na máquina a tempo: larga e ela sai da lista por um tempo (ele vai pra outra).
func desiste(maq: Node, w: Node) -> void:
	solta(w)
	if maq != null and is_instance_valid(maq):
		_evita[maq] = preventiva_evita


func solta(w: Node) -> void:
	for m in _reservas.keys():
		if _reservas[m] == w:
			_reservas.erase(m)


func segundos_de(maq: Node) -> float:
	return float(segundos_preventiva.get(maq.manut_tipo(), 20.0))


## A preventiva acabou.
func preventiva_feita(maq: Node, w: Node) -> void:
	_reservas.erase(maq)
	if not is_instance_valid(maq):
		return
	maq.manut_preventiva()
	preventivas += 1
	_avisou.erase(maq)
	manutencao_feita.emit(maq, maq.manut_tipo())


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = conserto_tenta_cada
	for m in _evita.keys():
		_evita[m] = float(_evita[m]) - conserto_tenta_cada
		if _evita[m] <= 0.0 or not is_instance_valid(m):
			_evita.erase(m)
	_tenta_consertos()
	for m in _reservas.keys():
		var w = _reservas[m]
		if not is_instance_valid(m) or not is_instance_valid(w) or not w.is_mechanic() or w.get_state() != "manutencao":
			_reservas.erase(m)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var cs: Array = []
	for c in get_tree().get_nodes_in_group("consertos_maquina"):
		if is_instance_valid(c) and is_instance_valid(c.maquina):
			cs.append(c.get_save_data())
	return {"consertos": cs, "preventivas": preventivas, "consertos_feitos": consertos_feitos, "quebras": quebras.duplicate()}


func load_save_data(d: Dictionary) -> void:
	for c in get_tree().get_nodes_in_group("consertos_maquina"):
		c.queue_free()
	preventivas = maxi(SaveUtil.integer(d, "preventivas", 0), 0)
	consertos_feitos = maxi(SaveUtil.integer(d, "consertos_feitos", 0), 0)
	quebras.clear()
	var qd := SaveUtil.dict(d, "quebras")
	for k in qd:
		quebras[String(k)] = maxi(SaveUtil.integer(qd, k, 0), 0)
	_reservas.clear()
	var world: Node = get_tree().get_first_node_in_group("village_hub").get_parent()
	for x in SaveUtil.array(d, "consertos"):
		if not (x is Dictionary):
			continue
		var maq: Node = get_node_or_null(NodePath(SaveUtil.text(x, "maquina", "")))
		if maq == null:
			continue
		var obra: Node2D = CONSERTO.new()
		obra.maquina = maq
		obra.position = (maq as Node2D).global_position
		world.add_child(obra)
		obra.load_save_data(x)
