extends "res://scripts/props/station.gd"
## Coletor de madeira (grupo "coletores") — Bloco 45: serraria a vapor na CLAREIRA.
##
## Um LENHADOR designado (janela do coletor) vai até a máquina e fica operando: enquanto ele
## está no posto, a máquina produz wood_per_sec de madeira e manda direto pro armazém mais
## perto (como a Escavadeira faz com o minério). Sem operador ela para — nada quebra. O
## lenhador manual (cortar árvore e levar) continua existindo em paralelo.
## De noite o operador vai pra casa como todo lenhador (turno extra: continua).
## Bloco 47: pode ter vários, cada um com o seu operador e a sua produção (independentes).
##
## Bloco 81: o PRIMEIRO coletor não se constrói — ele já está na floresta, em RUÍNA (enferrujado e
## coberto de folhas; nó "ColetorMadeira" da cena, `fixo`), e o jogador o RESTAURA por etapas, como as
## peças da Escavadeira e a plataforma do abismo (ruína que vira máquina):
##   0 ruína -> 1 limpar folhas e entulho -> 2 desenferrujar -> 3 consertar caldeira e serra -> 4 funcionando.
## Cada etapa (1..3) tem custo, segundos de engenheiro e estágio mínimo da vila (`etapa_*`, @export): o
## jogador PEDE a etapa (paga) e o engenheiro trabalha nela (interface de obra, ObraSite); pronta, a
## próxima espera ser pedida. Só funcionando dá pra designar o operador. Os extras (Centro da Vila,
## canteiro "coletor") nascem já funcionando (etapa 4). Visual: iso_art.gd (_coletor_madeira) — camadas
## provisórias por cima da arte (folhas, entulho, tom de ferrugem) que saem a cada etapa; com desenhos
## "etapa_N" no predios.json, eles entram no lugar.

## Madeira por segundo com o operador no posto (antes da zanga/ânimo dele).
@export var wood_per_sec: float = 0.6

@export_group("Restauração (Bloco 81)")
## A ruína da cena (o primeiro coletor): começa em `etapa_inicial` e salva a etapa no save do Centro da Vila.
@export var fixo := false
## Etapa em que ele nasce (0 = ruína; os extras construídos nascem funcionando).
@export_range(0, 4) var etapa_inicial: int = 4
## Nome de cada etapa (índice = etapa).
@export var etapa_nomes: PackedStringArray = PackedStringArray(["Ruína", "Limpar folhas e entulho", "Desenferrujar",
	"Consertar caldeira e serra", "Funcionando"])
## Custo de cada etapa (índice 1..3): x = créditos, y = ferro, z = madeira.
@export var etapa_custo: Array[Vector3i] = [Vector3i.ZERO, Vector3i(0, 0, 30), Vector3i(0, 45, 0), Vector3i(180, 50, 0), Vector3i.ZERO]
## Segundos de engenheiro de cada etapa (índice 1..3).
@export var etapa_segundos: PackedFloat32Array = PackedFloat32Array([0.0, 25.0, 35.0, 45.0, 0.0])
## Estágio mínimo da vila pra pedir cada etapa (índice 1..3; 0 = qualquer).
@export var etapa_estagio: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0])

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "coletor"
## O lenhador designado (null = sem operador).
var operator: Node = null
## Madeira produzida desde que foi construída.
var total_produced: float = 0.0
var _acc := 0.0
var _producing := false
var _sound_timer := 0.0
## Bloco 81: a etapa (0 ruína .. 4 funcionando), se a etapa atual já foi paga (o engenheiro pode
## trabalhar) e os segundos de engenheiro feitos nela.
var etapa: int = 4
var pago := false
var progresso := 0.0
var _obra := preload("res://scripts/core/obra_site.gd").new()
var _posicao_cena := Vector2.ZERO

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $StatusLabel
@onready var _smoke: CPUParticles2D = $Smoke


func _ready() -> void:
	super()
	add_to_group("coletores")
	add_to_group("clickable")
	add_to_group("obras")  # Bloco 81: a restauração é obra de engenheiro
	if fixo:
		add_to_group("coletor_fixo")
	_posicao_cena = global_position
	etapa = clampi(etapa_inicial, 0, ETAPA_PRONTA)
	refresh()


# ------------------------------------------------------------ restauração (Bloco 81)
const ETAPA_PRONTA := 4


func restaurado() -> bool:
	return etapa >= ETAPA_PRONTA


## Quantas etapas já foram feitas (0..3).
func etapas_feitas() -> int:
	return ETAPA_PRONTA - 1 if restaurado() else maxi(etapa - 1, 0)


## A etapa que vem agora (1..3), ou -1 (funcionando). Na ruína (0) é a 1.
func etapa_atual() -> int:
	if restaurado():
		return -1
	return maxi(etapa, 1)


func etapa_nome(i: int) -> String:
	return etapa_nomes[i] if i >= 0 and i < etapa_nomes.size() else "?"


func custo_etapa(i: int) -> Vector3i:
	return etapa_custo[i] if i >= 0 and i < etapa_custo.size() else Vector3i.ZERO


func segundos_etapa(i: int) -> float:
	return maxf(etapa_segundos[i], 1.0) if i >= 0 and i < etapa_segundos.size() else 1.0


func custo_texto(i: int) -> String:
	var c := custo_etapa(i)
	var partes: Array[String] = []
	if c.x > 0:
		partes.append("%d cr" % c.x)
	if c.y > 0:
		partes.append("%d ferro" % c.y)
	if c.z > 0:
		partes.append("%d madeira" % c.z)
	return " + ".join(partes) if not partes.is_empty() else "grátis"


## "" se dá pra pedir a etapa atual agora; senão o motivo (o que falta).
func etapa_block_reason() -> String:
	var i := etapa_atual()
	if i < 0:
		return "já está funcionando"
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
	return eco.missing_text(c.x, c.y, "ferro", c.z, "ferro")


## O jogador pede (paga) a etapa atual; o engenheiro faz.
func pedir_etapa() -> bool:
	if etapa_block_reason() != "":
		Audio.error()
		return false
	var i := etapa_atual()
	var c := custo_etapa(i)
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(c.x, c.y, "ferro", c.z):
		return false
	etapa = i
	pago = true
	progresso = 0.0
	_obra.start()
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s encomendado — precisa de engenheiro (tecla 4)." % etapa_nome(i), Color(1.0, 0.8, 0.45))
	refresh()
	return true


## Termina tudo de uma vez (testes e atalho do F3).
func restaura_tudo() -> void:
	etapa = ETAPA_PRONTA
	pago = false
	progresso = 0.0
	refresh()


## A ruína como na cena (save sem coletor nenhum): etapa inicial, no lugar da cena, sem operador.
func volta_pra_ruina() -> void:
	if has_operator():
		release()
	etapa = clampi(etapa_inicial, 0, ETAPA_PRONTA)
	pago = false
	progresso = 0.0
	total_produced = 0.0
	if global_position.distance_to(_posicao_cena) > 1.0:
		global_position = _posicao_cena
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub and hub.has_method("_coletor_mudou"):
			hub._coletor_mudou()
	refresh()


func _etapa_pronta() -> void:
	var feita := etapa
	pago = false
	progresso = 0.0
	etapa = feita + 1
	Audio.build_done(global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if restaurado():
			hud.show_banner("COLETOR DE MADEIRA RESTAURADO!", "A serraria a vapor da floresta voltou a funcionar. Designe um lenhador pra operar (clique nela).")
		else:
			hud.show_toast("%s: pronto. Próxima etapa: %s (%s)." % [etapa_nome(feita), etapa_nome(etapa), custo_texto(etapa)], Color(0.55, 1.0, 0.5))
	refresh()


# interface de obra (engenheiro: ipezinho._pick_obra / obra_site.gd)
func obra_pending() -> bool:
	return pago and not restaurado()


func obra_title() -> String:
	return "Coletor: " + etapa_nome(etapa)


func obra_progress() -> float:
	return clampf(progresso / segundos_etapa(etapa), 0.0, 1.0) if pago else 0.0


func obra_position(worker: Node) -> Vector2:
	return IsoArt.front(self, Vector2(0, 34)) + _obra.offset_for(worker)  # na frente, fora da pegada da arte


func obra_work(seconds: float) -> void:
	if not obra_pending():
		return
	progresso += seconds
	if progresso >= segundos_etapa(etapa):
		_etapa_pronta()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


## Bloco 96: a etapa cancelada volta a "não encomendada" (ObraSite.cancelar devolveu créditos e material).
func obra_cancelar() -> void:
	pago = false
	progresso = 0.0
	refresh()


func get_save_data() -> Dictionary:
	return {"position": [snappedf(global_position.x, 0.1), snappedf(global_position.y, 0.1)], "fixo": fixo, "etapa": etapa,
		"pago": pago, "progresso": progresso, "total": total_produced, "obra": _obra.get_save_data()}


## Save antigo sem a chave "etapa" = já funcionava.
func load_save_data(d: Dictionary) -> void:
	etapa = clampi(int(d.get("etapa", ETAPA_PRONTA)), 0, ETAPA_PRONTA)
	pago = bool(d.get("pago", false)) and not restaurado()
	progresso = maxf(float(d.get("progresso", 0.0)), 0.0) if pago else 0.0
	total_produced = maxf(float(d.get("total", total_produced)), 0.0)
	if d.get("obra") is Dictionary:
		_obra.load_save_data(d.obra)
	refresh()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-50, -76), Vector2(100, 80)).has_point(p)


func decor_clear_rect() -> Rect2:
	return Rect2(global_position + Vector2(-52, -78), Vector2(104, 84))


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_lumber")


## Só o operador designado usa a vaga.
func accepts_worker(worker: Node) -> bool:
	return worker == operator and restaurado()


func is_usable() -> bool:
	return operator != null and restaurado()


func has_operator() -> bool:
	if operator != null and not is_instance_valid(operator):
		operator = null
	return operator != null


## Designa um lenhador pra operar (substitui o anterior).
func designate(worker: Node) -> bool:
	if worker == null or not worker.is_lumber() or not restaurado():
		return false  # Bloco 81: ruína não tem operador
	if has_operator() and operator != worker:
		release()
	# Bloco 47: um lenhador opera UMA máquina só (sai da outra, se estava nela)
	for other in get_tree().get_nodes_in_group("coletores"):
		if other != self and other.operator == worker:
			other.release()
	operator = worker
	worker.wake_decision()
	refresh()
	return true


## Tira o operador (a máquina para).
func release() -> void:
	var w := operator
	operator = null
	if w != null and is_instance_valid(w):
		release_slot(w)
		w.wake_decision()
	refresh()


func _process(delta: float) -> void:
	has_operator()
	_producing = false
	if not restaurado():  # Bloco 81: ruína não produz
		_smoke.emitting = false
		_visual.frame = 0
		if Engine.get_process_frames() % 15 == 0:
			refresh()
		return
	for body in _working_bodies():
		if body == operator and body.get_state() == "operating":
			_producing = true
			body.operate_tick()
			_acc += wood_per_sec * body.work_mult() * delta
	while _acc >= 1.0:
		_acc -= 1.0
		total_produced += 1.0
		_deliver(1.0)
	if _producing:
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = 1.1 * randf_range(0.8, 1.2)
			Audio.chop(global_position)
	_visual.frame = 1 if _producing else 0
	_smoke.emitting = _producing
	if Engine.get_process_frames() % 15 == 0:
		refresh()


func _deliver(amount: float) -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	var best: Node2D = eco.armazem_com_espaco(global_position, amount) if eco else null  # Bloco 97: só onde cabe
	_sem_espaco = best == null
	if best:
		best.wood_stored += amount
		best._recount()


## Texto da placa (e da janela).
## Bloco 97: o armazém estava cheio na última entrega (a máquina para de mandar).
var _sem_espaco := false


func status_text() -> String:
	if restaurado() and has_operator() and _sem_espaco:
		return "parado — armazém cheio (venda, gaste ou amplie o armazém)"
	if not restaurado():  # Bloco 81
		var i := etapa_atual()
		if pago:
			return "%s: %s" % [etapa_nome(i), _obra.status(obra_progress())]
		return "próxima etapa: %s (%s)" % [etapa_nome(i), custo_texto(i)]
	if not has_operator():
		return "parado — sem operador (designe um lenhador)"
	if _producing:
		return "produzindo %.1f madeira/s (%s)" % [wood_per_sec * operator.work_mult(), operator.display_name]
	return "parado — %s: %s" % [operator.display_name, operator.get_state_label()]


func refresh() -> void:
	if not is_inside_tree():
		return
	if not restaurado():  # Bloco 81
		var i := etapa_atual()  # (placa curta: a janela tem o resto)
		_label.text = "Coletor de madeira (ruína)\n%s" % ("%s: %d%%" % [etapa_nome(i), roundi(obra_progress() * 100.0)] if pago
			else "próxima: %s\n%s" % [etapa_nome(i), custo_texto(i)])
		_label.modulate = Color(1.0, 0.75, 0.5)
		_visual.self_modulate = Color(0.85, 0.55, 0.38) if etapa <= 2 else Color(0.7, 0.68, 0.66)  # (vista de cima)
		return
	_visual.self_modulate = Color.WHITE
	_label.text = "Coletor de madeira\n%s\ntotal: %d" % [status_text(), int(total_produced)]
	_label.modulate = Color(0.75, 1.0, 0.6) if _producing else Color(0.9, 0.86, 0.8)


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
