extends "res://scripts/props/station.gd"
## Bloco 86: FORNALHA (grupo "fornalhas") — transforma minério em barra, SÓ POR ORDEM do jogador (fila de
## ordens: production_queue.gd; regra 9 do CLAUDE.md).
##
## - Posicionada pelo jogador e erguida pelo engenheiro (canteiro "fornalha", dono: Centro da Vila); liberada
##   no estágio centro_vila.fornalha_estagio; o custo dela é só minério e créditos (não trava o começo).
## - Quem opera é o FUNDIDOR (ipezinho.gd, função "fundidor"): busca os insumos no armazém (como o
##   cozinheiro busca a matéria-prima) — cada unidade paga os insumos só quando ele os pega —, funde aqui
##   (segundos da receita x o ritmo dele) e leva as barras pro armazém. Sem ordem ele não pega nada.
## - Faltou insumo: a ordem fica PAUSADA com o aviso do que falta (a janela e a placa mostram).
## - Receitas (@export): ferro + carvão = barra de ferro; cobre + carvão = barra de cobre; prata = barra de
##   prata; solarita = lingote solar; aço (barra de ferro + carvão) só com a vila no estágio 3 (a Fundição).
## Bloco 94: a CARPINTARIA (carpintaria.gd) é a mesma oficina de ordens com outro ofício: grupo, operador, estado
## de trabalho e nomes são variáveis daqui (o resto é igual).

const ProductionQueue := preload("res://scripts/core/production_queue.gd")
const Items := preload("res://scripts/core/items.gd")

@export_group("Receitas (Bloco 86)")
## {id, nome, insumos {item: qtd}, produto {item: qtd}, segundos (de fundidor por unidade), estagio (mínimo
## da vila; 0 = qualquer)}. Itens = ids do items.gd.
@export var receitas: Array[Dictionary] = [
	{"id": "barra_ferro", "nome": "Barra de ferro", "insumos": {"ferro": 2, "carvao": 1}, "produto": {"barra_ferro": 1}, "segundos": 10.0, "estagio": 0},
	{"id": "barra_cobre", "nome": "Barra de cobre", "insumos": {"cobre": 2, "carvao": 1}, "produto": {"barra_cobre": 1}, "segundos": 12.0, "estagio": 0},
	{"id": "barra_prata", "nome": "Barra de prata", "insumos": {"prata": 2}, "produto": {"barra_prata": 1}, "segundos": 14.0, "estagio": 0},
	{"id": "lingote_solar", "nome": "Lingote solar", "insumos": {"solarita": 2}, "produto": {"lingote_solar": 1}, "segundos": 18.0, "estagio": 0},
	{"id": "aco", "nome": "Aço (Fundição)", "insumos": {"barra_ferro": 1, "carvao": 1}, "produto": {"aco": 1}, "segundos": 20.0, "estagio": 3},
]
## Máximo de ordens na fila.
@export var max_fila: int = 4
## Unidades que o fundidor começa (pega os insumos) por viagem ao armazém.
@export var lote: int = 2

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "fornalha"
## Bloco 94: o que muda de uma oficina de ordens pra outra (a Carpintaria troca no _init).
var grupo := "fornalhas"
var nome_predio := "Fornalha"
var nome_operador := "fundidor"
## Estado do ipezinho trabalhando aqui (ipezinho.gd STATE_GROUP) e o verbo da placa.
var estado_trabalho := "fundindo"
var verbo := "fundindo"
## A fila de ordens (ProductionQueue).
var fila
## Bloco 105: as barras prontas esperando o CARREGADOR levar pro armazém (com carregador, o operador não sai daqui).
var barras_prontas := {}
## Bloco 107: tudo que esta oficina já fez (item -> quantidade; a telemetria soma; vai pro save).
var produzido := {}
var _acesa := false
var _sound_timer := 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $StatusLabel
@onready var _smoke: CPUParticles2D = $Smoke
@onready var _luz: PointLight2D = $Luz


func _ready() -> void:
	super()
	add_to_group(grupo)
	add_to_group("clickable")
	_luz.add_to_group("cullable_lights")
	fila = ProductionQueue.new(receitas, max_fila)
	refresh()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-46, -80), Vector2(92, 84)).has_point(p)


func decor_clear_rect() -> Rect2:
	return Rect2(global_position + Vector2(-48, -82), Vector2(96, 88))


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_smelter")


## Este ipezinho é quem opera aqui? (o fundidor; na Carpintaria, o carpinteiro)
func e_operador(worker: Node) -> bool:
	return worker.has_method("is_smelter") and worker.is_smelter()


## Só o operador, e só com ordem pra trabalhar.
func accepts_worker(worker: Node) -> bool:
	return e_operador(worker) and fila.tem_trabalho()


func _tem_operador() -> bool:
	return get_tree().get_nodes_in_group("ipezinhos").any(e_operador)


func is_usable() -> bool:
	return fila.tem_trabalho()


func _process(delta: float) -> void:
	_acesa = false
	for body in _working_bodies():
		if body.get_state() != estado_trabalho or fila.comecadas() <= 0:
			continue
		_acesa = true
		var pronto: Dictionary = fila.trabalhar(delta * body.work_mult())
		if body.has_method("fundir_tick"):
			body.fundir_tick()
		if not pronto.is_empty():
			for k in pronto:
				produzido[k] = float(produzido.get(k, 0.0)) + float(pronto[k])  # Bloco 107
			var lg := get_tree().get_first_node_in_group("logistica")
			if lg and lg.tem_carregador():
				for k in pronto:
					barras_prontas[k] = float(barras_prontas.get(k, 0.0)) + float(pronto[k])  # Bloco 105: o carregador leva
			else:
				body.pega_barras(pronto)
			_som_pronto()
			refresh()
	_mostra_trabalho(_acesa)
	if _acesa:
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = 1.4 * randf_range(0.8, 1.2)
			Audio.chop(global_position)  # (o fole/martelo: som provisório)
	if Engine.get_process_frames() % 20 == 0:
		refresh()


## Saiu uma leva pronta.
func _som_pronto() -> void:
	Audio.forge(global_position)


## Liga/desliga o visual de "trabalhando" (a fornalha acende, solta fumaça e luz).
func _mostra_trabalho(ativo: bool) -> void:
	_visual.frame = 1 if ativo else 0
	_smoke.emitting = ativo
	_luz.enabled = ativo


func _economy() -> Node:
	return get_tree().get_first_node_in_group("economy")


## Estágio da vila agora (receitas com estágio mínimo).
func estagio_vila() -> int:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return int(hub.level) if hub else 1


func motivo_encomenda(id: String, qtd: int) -> String:
	if minerio_nao_estudado(id) != "":
		return "precisa estudar o minério (Catálogo, R)"  # Bloco 102
	return fila.motivo_encomenda(id, qtd, estagio_vila())


## Bloco 102: o minério da receita que o catálogo ainda não estudou ("" = todos conhecidos). Receita de minério sem nome
## não anda: a janela mostra "???".
func minerio_nao_estudado(id: String) -> String:
	var cat := get_tree().get_first_node_in_group("catalogo")
	if cat == null:
		return ""
	var r: Dictionary = fila.receita(id)
	for k in r.get("insumos", {}):
		if Items.categoria(k) == "minerio" and not cat.minerio_conhecido(k):
			return k
	return ""


## O jogador encomendou `qtd` unidades da receita (nada é gasto agora: cada unidade paga quando começa).
func encomendar(id: String, qtd: int) -> bool:
	if motivo_encomenda(id, qtd) != "":
		Audio.error()
		return false
	fila.encomendar(id, qtd, estagio_vila())
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Encomendado: %d x %s.%s" % [qtd, fila.receita(id).get("nome", id),
			(" O %s busca os insumos no armazém." % nome_operador) if _tem_operador() else (" Precisa de um %s (barra de funções)." % nome_operador.to_upper())],
			Color(1.0, 0.8, 0.45))
	_acorda_fundidores()
	refresh()
	return true


## O jogador cancelou a ordem i (as unidades começadas devolvem os insumos ao armazém).
func cancelar(i: int) -> bool:
	var ok: bool = fila.cancelar(i, _economy(), global_position)
	if ok:
		Audio.click()
		_acorda_fundidores()
		refresh()
	return ok


func _acorda_fundidores() -> void:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if e_operador(w):
			w.wake_decision()


## O que falta pra continuar a ordem da vez ("" = nada; parada por falta de insumo = "falta ...").
func falta() -> String:
	if not fila.tem_trabalho() or fila.comecadas() > 0 or fila.a_comecar() <= 0:
		return ""
	return fila.falta_para(_economy())


func status_text() -> String:
	if not fila.tem_trabalho():
		return "parada — sem ordem (clique e encomende)"
	var f := falta()
	if f != "":
		return "PAUSADA: %s" % f
	if not _tem_operador():
		return "esperando um %s (barra de funções)" % nome_operador
	if _acesa:
		return "%s: %s (%d%%)" % [verbo, fila.texto_ordem(0), roundi(fila.progresso_unidade() * 100.0)]
	return "%s — o %s está buscando os insumos" % [fila.texto_ordem(0), nome_operador]


func refresh() -> void:
	if not is_inside_tree():
		return
	_label.text = "%s\n%s" % [nome_predio, status_text()]
	_label.modulate = Color(1.0, 0.6, 0.45) if falta() != "" else (Color(1.0, 0.85, 0.5) if _acesa else Color(0.9, 0.86, 0.8))


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------ save/load (pelo Centro da Vila)
func get_save_data() -> Dictionary:
	return {"position": [snappedf(global_position.x, 0.1), snappedf(global_position.y, 0.1)], "fila": fila.get_save_data(),
		"barras_prontas": barras_prontas.duplicate(), "produzido": produzido.duplicate()}  # Bloco 105 / 107


func load_save_data(d: Dictionary) -> void:
	var lista = d.get("fila", [])
	fila.load_save_data(lista if lista is Array else [])
	produzido = {}  # Bloco 107 (save antigo: zero)
	var pr = d.get("produzido", {})
	if pr is Dictionary:
		for k in pr:
			produzido[String(k)] = maxf(float(pr[k]), 0.0)
	barras_prontas = {}  # Bloco 105 (save antigo: nenhuma esperando)
	var bp = d.get("barras_prontas", {})
	if bp is Dictionary:
		for k in bp:
			if float(bp[k]) > 0.0:
				barras_prontas[String(k)] = float(bp[k])
	refresh()
