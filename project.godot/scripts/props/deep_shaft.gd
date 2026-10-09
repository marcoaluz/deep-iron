extends Node2D
## Elevador pro NÍVEL 2 (grupo "elevador"), ao lado da plataforma da escavadeira.
##
## Fica fechado até a escavadeira ficar pronta (Bloco 4); aí a descida abre (`unlocked`: o S2 está aberto).
## A ligação é um NavigationLink2D: os ipezinhos planejam o caminho passando por ele (ex.: ir minerar prata lá embaixo)
## e, ao chegar na gaiola, entram na cabine (ipezinho.gd -> _on_link_reached). Funciona nos dois sentidos.
## Em cima: a torre ao lado da escavadeira. Embaixo: a gaiola de chegada no nível 2.
##
## Bloco 99: é a ENTRADA PRINCIPAL da mina.
## - Começa em RUÍNA e é RESTAURADO por etapas (padrão do coletor em ruína, Bloco 81): limpar o poço, guincho e cabos,
##   a cabine. Cada etapa o jogador pede (paga) e o engenheiro faz levando o material (Bloco 96). Em PARALELO com a
##   escavadeira: dá pra restaurar antes dela acabar; o S2 abre com a escavadeira, e enquanto o elevador não está pronto
##   (ou quebrou) a descida é pela ESCADA EM ESPIRAL, lenta (espiral.gd).
## - A viagem é de verdade (cabine.gd): fila, embarque até a capacidade, a cabine andando pelo poço, desembarque.
## - O cabo gasta a cada viagem; arrebentou: a ligação some (o caminho vai pela espiral) e o conserto vira obra com
##   material, pedido sozinho assim que o armazém tem o material.

signal opened

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const Cabine := preload("res://scripts/props/cabine.gd")

## Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do nível 2).
@export var bottom_position: Vector2 = Vector2(440, 790)
## Custo de navegação da descida (baixo = os ipezinhos acham que "descer é perto").
@export var link_travel_cost: float = 0.05

var unlocked: bool = false
var panel_id := "elevador"

@export_group("Viagem (Blocos 68 e 99)")
## Quantos cabem na cabine de uma vez.
@export var capacity: int = 4
## Segundos (de jogo) da cabine de uma ponta à outra do poço.
@export var segundos_viagem: float = 7.0
## Segundos de porta aberta pra embarcar (cada um que entra renova).
@export var segundos_embarque: float = 1.2
## Viagens até o cabo gastar e arrebentar.
@export var viagens_ate_quebrar: int = 60

@export_group("Restauração (Bloco 99)")
## Nome de cada etapa (índice 1..3; 0 = a ruína).
@export var etapa_nomes: PackedStringArray = PackedStringArray(["Ruína", "Limpar o poço", "Guincho e cabos", "A cabine"])
## Custo de cada etapa (índice 1..3): x = créditos, y = ferro (barras a partir da fornalha), z = madeira.
@export var etapa_custo: Array[Vector3i] = [Vector3i.ZERO, Vector3i(0, 0, 40), Vector3i(120, 80, 0), Vector3i(200, 60, 40)]
## Itens a mais de cada etapa ({item: qtd}; antes da fornalha os pregos viram ferro).
@export var etapa_itens: Array[Dictionary] = [{}, {}, {}, {"prego": 10}]
## Segundos de engenheiro de cada etapa.
@export var etapa_segundos: PackedFloat32Array = PackedFloat32Array([0.0, 30.0, 45.0, 50.0])
## Estágio mínimo da vila pra pedir cada etapa.
@export var etapa_estagio: PackedInt32Array = PackedInt32Array([0, 1, 2, 2])

@export_group("Conserto do cabo (Bloco 99)")
## Material do conserto: x = créditos, y = ferro, z = madeira; e os segundos de engenheiro.
@export var conserto_custo: Vector3i = Vector3i(40, 20, 10)
@export var conserto_segundos: float = 30.0
## De quantos em quantos segundos tenta pagar o conserto quando falta material.
@export var conserto_tenta_cada: float = 5.0

const ETAPA_PRONTA := 3
## Etapas feitas (0 = ruína .. 3 = restaurado), se a próxima já foi paga e os segundos de engenheiro feitos nela.
var etapa := 0
var pago := false
var progresso := 0.0
var cabine := Cabine.new(self)
var _obra := ObraSite.new()
var _tenta_t := 0.0

@onready var _top: Node2D = $Top
@onready var _bottom: Node2D = $Bottom
@onready var _link: NavigationLink2D = $Link
@onready var _top_label: Label = $Top/Label
@onready var _bottom_label: Label = $Bottom/Label


func _ready() -> void:
	add_to_group("maquinas")  # Bloco 105: a cabine gasta (o mecânico revisa)
	add_to_group("elevador")  # (não entra em "elevadores": aquele grupo é das plataformas S3..S5, salvas por nome)
	add_to_group("clickable")
	add_to_group("obras")
	_bottom.position = bottom_position - global_position
	_link.start_position = Vector2.ZERO
	_link.end_position = bottom_position - global_position
	_link.bidirectional = true
	_link.travel_cost = link_travel_cost
	_link.enter_cost = 0.0
	_copia_numeros()
	_apply(false)
	_connect_escavadeira.call_deferred()


func _copia_numeros() -> void:
	cabine.capacidade = capacity
	cabine.segundos_viagem = segundos_viagem
	cabine.embarque = segundos_embarque
	cabine.viagens_ate_quebrar = viagens_ate_quebrar
	cabine.conserto_segundos = conserto_segundos


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-40, -90), Vector2(80, 100)).has_point(p)


## Bloco 99: a cabine anda por aqui.
func usa_cabine() -> bool:
	return true


func _connect_escavadeira() -> void:
	var dig := get_tree().get_first_node_in_group("escavadeira")
	if dig == null:
		return
	dig.completed.connect(func(): unlock(true))
	if dig.complete:
		unlock(false)


## Abre a descida (escavadeira pronta). announce = mostra aviso.
func unlock(announce: bool) -> void:
	if unlocked:
		return
	unlocked = true
	_apply(announce)
	opened.emit()
	if announce and not restaurado():
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("O nível 2 abriu! Sem o elevador restaurado, a descida é pela escada em espiral (lenta). Clique no elevador.", Color(1.0, 0.8, 0.45))


## Save carregado / escavadeira carregada: garante que o estado bate.
func sync_state() -> void:
	var dig := get_tree().get_first_node_in_group("escavadeira")
	if dig and dig.complete and not unlocked:
		unlocked = true
	_apply(false)


## Bloco 68: por que a descida ainda está fechada (o nível S2 lê daqui).
func reason_locked() -> String:
	return "" if unlocked else "abre quando a escavadeira ficar pronta"


## A cabine leva gente agora? (aberto, restaurado e com o cabo inteiro)
func funcionando() -> bool:
	return unlocked and restaurado() and not cabine.quebrada


func _process(delta: float) -> void:
	if funcionando():
		cabine.tick(delta)
	elif cabine.quebrada and not cabine.consertando and unlocked:
		_tenta_t -= delta
		if _tenta_t <= 0.0:
			_tenta_t = conserto_tenta_cada
			_pede_conserto()
	if Engine.get_process_frames() % 20 == 0:
		_atualiza_rotulo()


func _apply(animate: bool) -> void:
	_top.visible = true  # Bloco 99: a torre aparece sempre (arruinada até restaurar)
	_link.enabled = funcionando()
	_atualiza_rotulo()
	if animate:
		_top.scale = Vector2(1.3, 0.7)
		create_tween().tween_property(_top, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Audio.forge(global_position)
	# jazidas do fundo trancam/destrancam junto
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed(animate)
	var env := get_tree().get_first_node_in_group("environment") if is_inside_tree() else null
	if env and env.has_method("espirais_sync"):
		env.espirais_sync()  # a escada em espiral do S2 abre junto


func _atualiza_rotulo() -> void:
	if _top_label == null:
		return
	if not restaurado():
		_top_label.text = "Elevador arruinado — %s" % (("restaurando: %s" % etapa_nome(etapa + 1)) if pago else "clique pra restaurar")
	elif not unlocked:
		_top_label.text = "Elevador pronto\n(o nível 2 abre com a escavadeira)"
	else:
		_top_label.text = "Elevador — " + cabine.estado_texto()
	_top_label.modulate = Color(1, 0.6, 0.45, 0.9) if cabine.quebrada else Color(0.75, 0.8, 1.0, 0.95)
	_bottom_label.text = "Nível 2 — mais fundo, mais perigoso" if unlocked \
		else "Nível 2 — fechado (abre quando a escavadeira ficar pronta)"
	_bottom_label.modulate = Color(0.75, 0.8, 1.0, 0.9) if unlocked else Color(1, 0.6, 0.5, 0.8)


# ------------------------------------------------------------ restauração (Bloco 99)
func restaurado() -> bool:
	return etapa >= ETAPA_PRONTA


## A próxima etapa (1..3) ou -1 (restaurado).
func etapa_atual() -> int:
	return -1 if restaurado() else etapa + 1


func etapa_nome(i: int) -> String:
	return etapa_nomes[i] if i >= 0 and i < etapa_nomes.size() else "?"


func custo_etapa(i: int) -> Vector3i:
	return etapa_custo[i] if i >= 0 and i < etapa_custo.size() else Vector3i.ZERO


func itens_etapa(i: int) -> Dictionary:
	return etapa_itens[i] if i >= 0 and i < etapa_itens.size() else {}


func segundos_etapa(i: int) -> float:
	return maxf(etapa_segundos[i], 1.0) if i >= 0 and i < etapa_segundos.size() else 1.0


func custo_texto(i: int) -> String:
	var c := custo_etapa(i)
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	return eco.custo_metal_texto(c.x, c.y, "ferro", c.z, itens_etapa(i)) if eco else ""


## "" se dá pra pedir a próxima etapa agora; senão o motivo.
func etapa_block_reason() -> String:
	var i := etapa_atual()
	if i < 0:
		return "restaurado"
	if pago:
		return "em obra (%s)" % _obra.status(obra_progress())
	var minimo: int = etapa_estagio[i] if i < etapa_estagio.size() else 0
	var hub := get_tree().get_first_node_in_group("village_hub") if is_inside_tree() else null
	if minimo > 0 and hub and int(hub.level) < minimo:
		var nomes: Array = hub.get("STAGE_NAMES") if hub.get("STAGE_NAMES") != null else []
		return "precisa da vila no estágio %s" % (nomes[minimo - 1] if minimo - 1 < nomes.size() else str(minimo))
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	if eco == null:
		return "sem recursos"
	var c := custo_etapa(i)
	return eco.metal_falta(c.x, c.y, "ferro", c.z, itens_etapa(i))


## O jogador pede (paga) a próxima etapa; o engenheiro leva o material e faz.
func pedir_etapa() -> bool:
	if etapa_block_reason() != "":
		Audio.error()
		return false
	var i := etapa_atual()
	var c := custo_etapa(i)
	if not get_tree().get_first_node_in_group("economy").paga_metal(c.x, c.y, "ferro", c.z, itens_etapa(i)):
		return false
	pago = true
	progresso = 0.0
	_obra.start()  # (no mesmo quadro do pagamento: o material vira a lista da obra)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Elevador: %s encomendado — precisa de engenheiro (tecla 4)." % etapa_nome(i), Color(1.0, 0.8, 0.45))
	_apply(false)
	return true


## Termina tudo de uma vez (testes, atalho do F3, save antigo com o S2 aberto).
func restaura_tudo() -> void:
	etapa = ETAPA_PRONTA
	pago = false
	progresso = 0.0
	_apply(false)


func _etapa_pronta() -> void:
	pago = false
	progresso = 0.0
	etapa += 1
	Audio.build_done(global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if restaurado():
			hud.show_banner("ELEVADOR RESTAURADO!", "A cabine desce e sobe pelo poço levando %d de cada vez. É a entrada principal da mina; a escada em espiral fica pra emergência." % capacity)
		else:
			hud.show_toast("Elevador: %s pronto. Próxima etapa: %s (%s)." % [etapa_nome(etapa), etapa_nome(etapa + 1), custo_texto(etapa + 1)], Color(0.55, 1.0, 0.5))
	_apply(false)


# ------------------------------------------------------------ o cabo (Bloco 99)
func _cabine_quebrou() -> void:
	_link.enabled = false
	Audio.gate_break(global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("O cabo do elevador arrebentou! A descida vai pela escada em espiral até o conserto (mecânico; sem mecânico, o engenheiro).", Color(1.0, 0.55, 0.4), self)
	_tenta_t = 0.0
	_pede_conserto()
	_apply(false)


## Paga o conserto (se o armazém tem) e vira obra; senão tenta de novo daqui a pouco.
func _pede_conserto() -> void:
	if not cabine.quebrada or cabine.consertando:
		return
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null or eco.metal_falta(conserto_custo.x, conserto_custo.y, "ferro", conserto_custo.z) != "":
		return
	var mt := get_tree().get_first_node_in_group("manutencao")
	if mt and not mt.tem_quem_conserte():
		return  # Bloco 105: sem mecânico nem engenheiro, não gasta o material (tenta de novo daqui a pouco)
	if not eco.paga_metal(conserto_custo.x, conserto_custo.y, "ferro", conserto_custo.z):
		return
	cabine.comeca_conserto()
	_obra.start()


func conserto_falta() -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.metal_falta(conserto_custo.x, conserto_custo.y, "ferro", conserto_custo.z) if eco else ""


# ------------------------------------------------------------ obra (restauração ou conserto do cabo)
func obra_pending() -> bool:
	return (pago and not restaurado()) or cabine.consertando


func obra_title() -> String:
	return "Elevador: conserto do cabo" if cabine.consertando else "Elevador: " + etapa_nome(etapa + 1)


func obra_progress() -> float:
	if cabine.consertando:
		return cabine.conserto_progresso()
	return clampf(progresso / segundos_etapa(etapa + 1), 0.0, 1.0) if pago else 0.0


func obra_position(worker: Node) -> Vector2:
	return global_position + Vector2(0, 34) + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	if cabine.consertando:
		if cabine.trabalha(seconds):
			Audio.build_done(global_position)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud:
				hud.show_toast("Elevador consertado: a cabine voltou a andar.", Color(0.55, 1.0, 0.5))
			var mt := get_tree().get_first_node_in_group("manutencao")
			if mt:
				mt.conserto_proprio_terminou(self)  # Bloco 105
			_apply(false)
		return
	if not pago or restaurado():
		return
	progresso += seconds
	if progresso >= segundos_etapa(etapa + 1):
		_etapa_pronta()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


## Bloco 96: cancelou (ObraSite.cancelar devolveu créditos e material).
func obra_cancelar() -> void:
	if cabine.consertando:
		cabine.consertando = false
		cabine.conserto_left = 0.0
		_tenta_t = conserto_tenta_cada * 6.0  # (não paga de novo na hora: o jogador cancelou)
	else:
		pago = false
		progresso = 0.0
	_apply(false)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"unlocked": unlocked, "etapa": etapa, "pago": pago, "progresso": progresso, "obra": _obra.get_save_data(),
		"cabine": cabine.get_save_data()}


## Save antigo (sem "etapa"): o elevador que já estava aberto vem RESTAURADO e inteiro (ninguém perde o acesso);
## fechado, começa em ruína como na partida nova.
func load_save_data(d: Dictionary) -> void:
	unlocked = SaveUtil.boolean(d, "unlocked", unlocked)
	etapa = clampi(SaveUtil.integer(d, "etapa", ETAPA_PRONTA if unlocked else 0), 0, ETAPA_PRONTA)
	pago = SaveUtil.boolean(d, "pago", false) and not restaurado()
	progresso = maxf(SaveUtil.num(d, "progresso", 0.0), 0.0) if pago else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	cabine.load_save_data(SaveUtil.dict(d, "cabine"))
	_apply(false)


# ------------------------------------------------------------ manutenção (Bloco 105: o cabo da cabine)
## O conserto do cabo é do mecânico (sem mecânico, do engenheiro); a restauração/conserto da plataforma é construção.
func oficio_obra() -> String:
	return "mecanico" if cabine.consertando else ""


func manut_tipo() -> String:
	return "cabine"


func manut_condicao() -> float:
	return cabine.condicao() if funcionando() else 1.0


func manut_quebrada() -> bool:
	return cabine.quebrada


func manut_titulo() -> String:
	return "Cabine do elevador"


func manut_pos(_w: Node) -> Vector2:
	return global_position + Vector2(0, 40)


func manut_preventiva() -> void:
	cabine.viagens = 0  # cabo revisado: conta de novo


func manut_conserto_proprio() -> bool:
	return true  # (o conserto do cabo já é a obra daqui, com material — Bloco 99)
