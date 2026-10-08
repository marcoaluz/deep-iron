extends Node
## Bloco 101: MIGRANTES (nó "Migrantes" na cena, grupo "migrantes"). Acabou a compra de ipezinhos: a vila cresce com quem
## chega. Pequenos grupos (1 a 3) vêm pela floresta até o PORTÃO (o único, barricada.gd) e esperam do lado de fora: o
## alerta na coluna da direita, o aviso, o som (gancho Audio.migrantes) e a janela "Migrantes" com o cartão de cada um —
## retrato, nome, sexo, condição (saudável, com fome, ferido, doente) e a função de que gostaria (nunca padre).
##   - ACEITAR: precisa de uma cama livre (Economy.free_beds: a capacidade da vila são as camas). Ele vira morador: entra
##     pelo portão (de noite, o guarda abre: Bloco 98) e fica sem função; ferido ou doente vai pra enfermaria.
##   - RECUSAR: volta pra floresta. ESPERAR: fica no portão até o prazo (prazo_dias); sem resposta, vai embora.
##   - Esperando à noite, com criatura no mapa, pode ser atacado (risco_ataque_hora): fica ferido; ferido de novo, morre.
## Frequência: a ATRATIVIDADE da vila (estágio, comida, ânimo médio, camas livres, beleza, missões cumpridas; pesos
## @export) encurta o intervalo entre grupos (entre intervalo_max_dias e intervalo_min_dias). Sempre com aviso. Rede de
## segurança: com menos de `socorro_abaixo_de` ipezinhos chega ajuda logo, atraente ou não. A pesquisa do satélite chama
## um grupo na hora (chama_grupo). O evento "refugiados" do Prompt 11 é este sistema.
## Os migrantes são ipezinhos de verdade (o elenco, os retratos), com `visitante = true`: fora do grupo "ipezinhos" até
## serem aceitos (não comem da cozinha, não ocupam cama, não contam pra nada). Save: chave "migrantes".

signal chegaram(quantos: int)
signal mudou

const SaveUtil := preload("res://scripts/core/save_util.gd")
const Worker := preload("res://scripts/workers/ipezinho.gd")
const CONDICOES := ["saudavel", "com_fome", "ferido", "doente"]
const NOME_CONDICAO := {"saudavel": "saudável", "com_fome": "com fome", "ferido": "ferido", "doente": "doente"}
## As funções que um migrante pode querer (o padre é único e chega pelo evento dele).
const FUNCOES := [Worker.ROLE_MINER, Worker.ROLE_HUNTER, Worker.ROLE_COOK, Worker.ROLE_LUMBER, Worker.ROLE_GUARD,
	Worker.ROLE_ENGINEER, Worker.ROLE_DOCTOR, Worker.ROLE_RESEARCH, Worker.ROLE_SMELTER, Worker.ROLE_SMITH, Worker.ROLE_CARPENTER]

@export_group("Chegada (Bloco 101)")
## Pessoas por grupo (mínimo e máximo).
@export var grupo_min: int = 1
@export var grupo_max: int = 3
## Intervalo entre grupos, em dias de jogo: com a vila muito atraente (min) e pouco atraente (max).
@export var intervalo_min_dias: float = 1.5
@export var intervalo_max_dias: float = 4.0
## Sem nenhuma cama livre, o intervalo é multiplicado por isto (vêm, mas menos).
@export var sem_cama_mult: float = 1.5
## Dias até o primeiro grupo numa partida nova.
@export var primeiro_grupo_dias: float = 2.0
## Rede de segurança: com menos ipezinhos que isto, chega ajuda em `socorro_dias` (2 a 3 pessoas).
@export var socorro_abaixo_de: int = 4
@export var socorro_dias: float = 0.5
## Chance (0..1) de cada condição: com fome, ferido, doente (o resto chega saudável).
@export var chance_com_fome: float = 0.25
@export var chance_ferido: float = 0.12
@export var chance_doente: float = 0.08
## Chance (0..1) de ser mulher.
@export var chance_mulher: float = 0.5

@export_group("Espera (Bloco 101)")
## Dias de jogo que esperam no portão sem resposta até ir embora.
@export var prazo_dias: float = 1.0
## Chance (0..1), por hora de noite com criatura no mapa, de cada um que espera ser atacado.
@export var risco_ataque_hora: float = 0.08
## Distância (px) do portão, do lado de fora, onde esperam.
@export var espera_distancia: float = 46.0

@export_group("Atratividade (Bloco 101)")
## Pesos de cada parte (somam o que quiser: a conta divide pela soma).
@export var peso_estagio: float = 1.0
@export var peso_comida: float = 1.0
@export var peso_animo: float = 1.0
@export var peso_camas: float = 1.0
@export var peso_beleza: float = 0.5
@export var peso_missoes: float = 0.5
## Comida estocada (porções por morador) que conta como "muita" (1,0).
@export var comida_boa_porcoes: float = 3.0
## Camas livres que contam como "muitas" (1,0).
@export var camas_boas: int = 4
## Peças de decoração que contam como "vila bonita" (1,0).
@export var decoracao_boa: int = 8

## Quem espera no portão: [{w (ipezinho visitante), condicao, funcao, prazo (s de jogo)}].
var esperando: Array = []
## Segundos de jogo até o próximo grupo.
var proximo := -1.0
var _t := 0.0
var _hora_t := 0.0
var _ultima_atratividade := 0.0


func _ready() -> void:
	add_to_group("migrantes")


func _dn() -> Node:
	return get_tree().get_first_node_in_group("day_night")


func _seg_por_dia() -> float:
	var dn := _dn()
	return dn.cycle_length() if dn and dn.has_method("cycle_length") else 540.0


func _populacao() -> int:
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.worker_count() if eco else get_tree().get_nodes_in_group("ipezinhos").size()


func _process(delta: float) -> void:
	if proximo < 0.0:
		proximo = primeiro_grupo_dias * _seg_por_dia()
	_t -= delta
	if _t <= 0.0:
		_t = 1.0
		_confere(1.0)
	# o relógio do próximo grupo só anda com ninguém esperando
	if esperando.is_empty():
		var socorro := _populacao() < socorro_abaixo_de
		if socorro:
			proximo = minf(proximo, socorro_dias * _seg_por_dia())
		proximo -= delta
		if proximo <= 0.0:
			chama_grupo(randi_range(2, 3) if socorro else -1, "socorro" if socorro else "")


## Uma vez por segundo: o prazo de quem espera, o ataque à noite e quem já foi embora.
func _confere(dt: float) -> void:
	esperando = esperando.filter(func(e): return is_instance_valid(e.w))
	var dn := _dn()
	var noite: bool = dn != null and dn.has_method("is_night") and dn.is_night()
	_hora_t += dt
	var hora: float = dn.segundos_por_hora() if dn and dn.has_method("segundos_por_hora") else 22.5
	var rola_ataque := _hora_t >= hora
	if rola_ataque:
		_hora_t = 0.0
	var tem_criatura := get_tree().get_nodes_in_group("criaturas").any(func(c): return String(c.get("morador")) == "")  # (Bloco 103: o morador do fundo não chega no portão)
	for e in esperando.duplicate():
		e.prazo = float(e.prazo) - dt
		if e.prazo <= 0.0:
			_vai_embora(e, "%s cansou de esperar no portão e foi embora." % e.w.display_name)
			continue
		if rola_ataque and noite and tem_criatura and randf() < risco_ataque_hora:
			_atacado(e)
	mudou.emit()


func _atacado(e: Dictionary) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if e.condicao == "ferido":
		if hud:
			hud.show_toast("%s foi atacado de novo no portão e não resistiu." % e.w.display_name, Color(1.0, 0.45, 0.4), e.w)
		esperando.erase(e)
		e.w.queue_free()
		mudou.emit()
		return
	e.condicao = "ferido"
	if hud:
		hud.show_toast("As criaturas atacaram %s, que esperava no portão: ferido." % e.w.display_name, Color(1.0, 0.6, 0.4), e.w)


# ------------------------------------------------------------ a atratividade
## 0..1: o quanto a vila atrai gente agora (as partes ponderadas pelos pesos).
func atratividade() -> float:
	var partes := partes_atratividade()
	var soma := 0.0
	var pesos := 0.0
	for k in partes:
		soma += float(partes[k][0]) * float(partes[k][1])
		pesos += float(partes[k][1])
	_ultima_atratividade = clampf(soma / maxf(pesos, 0.001), 0.0, 1.0)
	return _ultima_atratividade


## {nome: [valor 0..1, peso]} — pra janela mostrar o porquê.
func partes_atratividade() -> Dictionary:
	var hub := get_tree().get_first_node_in_group("village_hub")
	var eco := get_tree().get_first_node_in_group("economy")
	var mor := get_tree().get_first_node_in_group("morale")
	var sch := get_tree().get_first_node_in_group("schedule")
	var ms := get_tree().get_first_node_in_group("missoes")
	var pop := maxi(_populacao(), 1)
	var comida := 0.0
	for c in get_tree().get_nodes_in_group("comedouros"):
		comida += float(c.get("food_stock")) if c.get("food_stock") != null else 0.0
	var porcao: float = sch.porcao if sch and sch.get("porcao") != null else 8.0
	var estagio := clampf((float(hub.level) - 1.0) / 4.0, 0.0, 1.0) if hub and hub.get("level") != null else 0.0
	var animo := clampf((mor.average() if mor and mor.has_method("average") else 50.0) / 100.0, 0.0, 1.0)
	var camas := clampf(float(eco.free_beds()) / float(maxi(camas_boas, 1)), 0.0, 1.0) if eco else 0.0
	var beleza := clampf(float(get_tree().get_nodes_in_group("decoracoes").size()) / float(maxi(decoracao_boa, 1)), 0.0, 1.0)
	var missoes := 0.0
	if ms and ms.has_method("todas"):
		var todas: Array = ms.todas()
		missoes = clampf(float(ms.cumpridas.size()) / float(maxi(todas.size(), 1)), 0.0, 1.0)
	return {"estágio da vila": [estagio, peso_estagio],
		"comida estocada": [clampf(comida / (pop * porcao * comida_boa_porcoes), 0.0, 1.0), peso_comida],
		"ânimo médio": [animo, peso_animo], "camas livres": [camas, peso_camas], "beleza": [beleza, peso_beleza],
		"missões cumpridas": [missoes, peso_missoes]}


## Segundos até o próximo grupo, pela atratividade de agora (e sem cama: mais devagar).
func intervalo() -> float:
	var a := atratividade()
	var dias := lerpf(intervalo_max_dias, intervalo_min_dias, a)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and eco.free_beds() <= 0:
		dias *= sem_cama_mult
	return maxf(dias, intervalo_min_dias) * _seg_por_dia()


# ------------------------------------------------------------ a chegada
## O portão (o único): onde esperar, do lado de fora.
func _portao() -> Node2D:
	return get_tree().get_first_node_in_group("barricadas")


func _lugar_de_espera(i: int) -> Vector2:
	var g := _portao()
	if g == null:
		var hub := get_tree().get_first_node_in_group("village_hub")
		return (hub.global_position if hub else Vector2.ZERO) + Vector2(-120 - 12 * i, 40)
	var along: Vector2 = g.inside_dir()
	var perp := Vector2(along.y, along.x)
	return g.global_position - along * espera_distancia + perp * (float(i) - 1.0) * 14.0


## Onde nascem: na floresta, longe do portão (do lado de fora).
func _origem() -> Vector2:
	var g := _portao()
	var env := get_tree().get_first_node_in_group("environment")
	var p: Vector2 = (g.global_position - g.inside_dir() * 260.0) if g else Vector2(-600, 0)
	if env and env.get("clearing_rect") != null and (env.clearing_rect as Rect2).has_area():
		var r: Rect2 = env.clearing_rect
		p = Vector2(r.position.x + r.size.x * 0.2, clampf(p.y + randf_range(-120.0, 120.0), r.position.y + 60.0, r.end.y - 60.0))
	var map := get_viewport().get_world_2d().navigation_map if is_inside_tree() else RID()
	if map.is_valid() and NavigationServer2D.map_get_iteration_id(map) > 0:
		p = NavigationServer2D.map_get_closest_point(map, p)
	return p


## Chama um grupo agora (n = -1: sorteia entre grupo_min e grupo_max). motivo "socorro" / "satelite" muda o aviso.
func chama_grupo(n: int = -1, motivo: String = "") -> Array:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null or eco.worker_scene == null:
		return []
	if n <= 0:
		n = randi_range(grupo_min, maxi(grupo_max, grupo_min))
	var chegaram_agora: Array = []
	var parent := get_tree().get_first_node_in_group("village_hub").get_parent() if get_tree().get_first_node_in_group("village_hub") else get_parent()
	var base := _origem()
	for i in n:
		var w: Node2D = eco.worker_scene.instantiate()
		w.set("visitante", true)
		w.set("gender", "menina" if randf() < chance_mulher else "menino")
		w.name = "Migrante%d" % (Time.get_ticks_usec() % 1000000 + i)
		w.position = base + Vector2(randf_range(-16, 16), randf_range(-16, 16) + i * 10.0)
		parent.add_child(w)
		var e := {"w": w, "condicao": _sorteia_condicao(), "funcao": FUNCOES[randi() % FUNCOES.size()], "prazo": prazo_dias * _seg_por_dia()}
		if e.condicao == "com_fome":
			w.hunger = w.hunger_max * 0.25
		esperando.append(e)
		chegaram_agora.append(e)
		w.move_to(_lugar_de_espera(esperando.size() - 1))
	proximo = intervalo()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		var txt := "%d migrante%s chegando pela floresta: vão esperar no portão (janela Migrantes)." % [n, "s" if n > 1 else ""]
		if motivo == "socorro":
			txt = "A vila está pequena: %d migrante%s ouviram falar de nós e vêm pedir abrigo no portão." % [n, "s" if n > 1 else ""]
		elif motivo == "satelite":
			txt = "O satélite achou gente de outra colônia: %d migrante%s a caminho do portão." % [n, "s" if n > 1 else ""]
		hud.show_toast(txt, Color(0.85, 0.95, 0.7), _portao())
		if hud.has_method("open_panel") and hud._panels.has("migrantes"):
			hud.open_panel("migrantes")
	var som := get_node_or_null("/root/Audio")
	if som and som.has_method("migrantes"):
		som.migrantes(_lugar_de_espera(0))
	chegaram.emit(n)
	mudou.emit()
	return chegaram_agora


func _sorteia_condicao() -> String:
	var r := randf()
	if r < chance_ferido:
		return "ferido"
	if r < chance_ferido + chance_doente:
		return "doente"
	if r < chance_ferido + chance_doente + chance_com_fome:
		return "com_fome"
	return "saudavel"


# ------------------------------------------------------------ as respostas
func _registro(w: Node) -> Dictionary:
	for e in esperando:
		if e.w == w:
			return e
	return {}


## "" = pode aceitar; senão o motivo (a dica do botão).
func motivo_aceitar(w: Node) -> String:
	if _registro(w).is_empty():
		return "não está esperando"
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and eco.free_beds() <= 0:
		return "falta cama"
	return ""


func aceita(w: Node) -> bool:
	var e := _registro(w)
	if e.is_empty() or motivo_aceitar(w) != "":
		var som := get_node_or_null("/root/Audio")
		if som:
			som.error()
		return false
	esperando.erase(e)
	w.vira_morador()  # entra no grupo "ipezinhos", sem função, ganha a cama
	match String(e.condicao):
		"ferido":
			w.hurt("ferimento", "leve")
		"doente":
			w.hurt("doenca", "leve")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s foi aceito na vila%s." % [w.display_name, (" e vai pra enfermaria" if e.condicao in ["ferido", "doente"] else "")], Color(0.55, 1.0, 0.5), w)
	var som2 := get_node_or_null("/root/Audio")
	if som2:
		som2.recruit()
	mudou.emit()
	return true


func recusa(w: Node) -> void:
	var e := _registro(w)
	if e.is_empty():
		return
	_vai_embora(e, "%s foi recusado e voltou pra floresta." % w.display_name)


## Esperar: só fecha a decisão por agora (o prazo continua correndo).
func espera(_w: Node) -> void:
	mudou.emit()


func _vai_embora(e: Dictionary, aviso: String) -> void:
	esperando.erase(e)
	var w: Node2D = e.w
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast(aviso, Color(0.9, 0.8, 0.6))
	if is_instance_valid(w):
		w.move_to(_origem())
		get_tree().create_timer(40.0, false).timeout.connect(func():
			if is_instance_valid(w):
				w.queue_free())
	mudou.emit()


func texto_condicao(e: Dictionary) -> String:
	return NOME_CONDICAO.get(String(e.condicao), String(e.condicao))


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var lista := []
	for e in esperando:
		if is_instance_valid(e.w):
			lista.append({"ipezinho": e.w.get_save_data(), "name": String(e.w.name), "condicao": e.condicao, "funcao": e.funcao,
				"prazo": snappedf(float(e.prazo), 0.1)})
	return {"proximo": snappedf(proximo, 0.1), "esperando": lista}


## Save antigo (sem a chave): ninguém esperando, o primeiro grupo no prazo de uma partida nova.
func load_save_data(d: Dictionary) -> void:
	for e in esperando:
		if is_instance_valid(e.w):
			e.w.queue_free()
	esperando.clear()
	proximo = SaveUtil.num(d, "proximo", primeiro_grupo_dias * _seg_por_dia())
	var eco := get_tree().get_first_node_in_group("economy")
	var hub := get_tree().get_first_node_in_group("village_hub")
	if eco == null or eco.worker_scene == null or hub == null:
		return
	var i := 0
	for x in SaveUtil.array(d, "esperando"):
		if typeof(x) != TYPE_DICTIONARY:
			continue
		var wd := SaveUtil.dict(x, "ipezinho")
		var w: Node2D = eco.worker_scene.instantiate()
		w.set("visitante", true)
		w.name = SaveUtil.text(x, "name", "Migrante%d" % i)
		w.position = _lugar_de_espera(i)
		w.set("pending_save_data", wd)
		hub.get_parent().add_child(w)
		var cond := SaveUtil.text(x, "condicao", "saudavel")
		esperando.append({"w": w, "condicao": cond if cond in CONDICOES else "saudavel",
			"funcao": SaveUtil.text(x, "funcao", Worker.ROLE_MINER), "prazo": maxf(SaveUtil.num(x, "prazo", prazo_dias * _seg_por_dia()), 1.0)})
		i += 1
	mudou.emit()
