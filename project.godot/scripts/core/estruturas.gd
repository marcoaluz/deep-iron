extends Node
## Bloco 127: as ESTRUTURAS DA VILA FERIDAS (nó "Estruturas" na main.tscn, grupos "estruturas" e "modificadores").
##
## O invasor que JÁ passou o portão (creature.gd) e bate num prédio pode machucá-lo. Cada prédio ferido ganha um filho
## "Integridade" (props/integridade_predio.gd): um `Desgaste` (Bloco 105) com a condição 1..0, no grupo "maquinas". Assim o
## que já existe cuida do resto sem sistema paralelo:
##   - a condição aparece na barra em cima do prédio (iso_billboard `_draw_desgaste`) e no alerta "Máquina quebrada ou
##     falhando" da coluna da direita;
##   - ferido (condição < `limite_conserto`): o MECÂNICO faz a preventiva, só com o tempo dele;
##   - a eficiência cai (desgaste.gd `eficiencia_de`: 100% até 40% de dano, depois até `Manutencao.eficiencia_min`) — quem
##     trabalha na estação rende menos, pelo `mult("producao")` deste nó (grupo "modificadores");
##   - EM RUÍNAS (condição 0): o prédio para de funcionar (a estação some da escolha da IA e quem estava nela sai; a casa
##     fica sem camas e os moradores perdem a cama; o armazém não recebe mais — o que está dentro continua lá) e a
##     reconstrução é uma obra de conserto com material (conserto_maquina.gd): `ruina_custo_pct` do custo original, pelo
##     mecânico ou, sem ele, pelo engenheiro.
##
## QUEM QUEBRA: o golpe do invasor dentro da vila (creature.gd `_quebra_predio`) chama `golpe`. Só o forte, o elite, o chefe
## ou qualquer um a partir do tier `dano_tier_min` da onda. O Centro da Vila nunca vira ruína (`centro_dano_max`).
## Quem está dentro de uma casa atacada NÃO morre (só se assusta, como antes); criança nunca é alvo (creature.gd).
## Save: chave "estruturas" {predios [{path, pos, d {c, q}}], danificados, ruinas}; save antigo = tudo 100%.

signal predio_ferido(predio: Node)
signal predio_em_ruina(predio: Node)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const INTEGRIDADE := preload("res://scripts/props/integridade_predio.gd")

@export_group("Dano dos invasores aos prédios (Bloco 127)")
## A partir deste tier da onda até a criatura comum quebra prédio (o forte, o elite e o chefe quebram em qualquer tier).
@export var dano_tier_min: int = 2
## Por tier acima do mínimo, o dano do golpe cresce esta fração (0,25 = +25% por tier).
@export var dano_por_tier: float = 0.25
## Multiplicadores do dano do golpe (o `dano_predio` do bicho, em fração da condição do prédio): forte, elite e chefe.
@export var mult_forte: float = 1.5
@export var mult_elite: float = 2.0
@export var mult_chefe: float = 6.0
## O Centro da Vila nunca vira ruína: o dano nele para neste valor (0,25 = no máximo 25% de dano).
@export_range(0.0, 1.0) var centro_dano_max: float = 0.25

@export_group("Conserto e reconstrução (Bloco 127)")
## A preventiva do mecânico vale até esta condição (0,9 = conserta quem perdeu mais de 10%).
@export_range(0.0, 1.0) var limite_conserto: float = 0.9
## Reconstruir um prédio em ruínas custa esta fração do custo original (créditos, ferro e madeira; o tempo também).
@export_range(0.0, 1.0) var ruina_custo_pct: float = 0.5
## O custo original por tipo de prédio: [créditos, ferro, madeira, segundos de trabalho] (os da Centro da Vila e da obra).
@export var custo_base: Dictionary = {"casa": [80, 20, 15, 40.0], "armazem": [300, 40, 60, 60.0], "enfermaria": [200, 30, 30, 50.0],
	"taverna": [250, 30, 50, 60.0], "centro": [190, 40, 0, 60.0], "predio": [150, 20, 20, 45.0]}

## Quantos prédios foram feridos pela primeira vez nesta noite (telemetria; a Defesa lê ao fim da invasão).
var danificados_noite := 0
## Quantos prédios já caíram em ruínas na partida (estatística).
var ruinas_total := 0
var _avisou := {}  # id do prédio -> true (o toast do 1º dano da noite)
var _por_predio := {}  # id do prédio -> a Integridade dele


func _ready() -> void:
	add_to_group("estruturas")
	add_to_group("modificadores")
	_liga.call_deferred()


func _liga() -> void:
	var def := get_tree().get_first_node_in_group("defense")
	if def and def.has_signal("invasion_started") and not def.invasion_started.is_connected(_noite_comecou):
		def.invasion_started.connect(_noite_comecou)


func _noite_comecou(_onda: int) -> void:
	danificados_noite = 0
	_avisou.clear()


# ------------------------------------------------------------ consultas (os prédios e a IA perguntam)
## A Integridade desse prédio (null = nunca foi ferido).
func integridade_de(predio: Node) -> Node:
	if predio == null or not is_instance_valid(predio):
		return null
	var a = _por_predio.get(predio.get_instance_id())
	if a != null and is_instance_valid(a):
		return a
	_por_predio.erase(predio.get_instance_id())
	return null


func condicao_de(predio: Node) -> float:
	var a := integridade_de(predio)
	return float(a.condicao()) if a else 1.0


## Em ruínas? (a estação some da escolha, a casa fica sem cama, o armazém não recebe)
func em_ruina(predio: Node) -> bool:
	var a := integridade_de(predio)
	return a != null and a.em_ruina()


func eficiencia_de(predio: Node) -> float:
	var a := integridade_de(predio)
	return float(a.eficiencia()) if a else 1.0


## O grupo "modificadores": quem trabalha numa estação ferida rende menos (em ruínas a IA nem vai).
func mult(chave: String, quem: Node = null) -> float:
	if chave != "producao" or quem == null or _por_predio.is_empty():
		return 1.0
	var st = quem.get("_station")
	if st == null or not is_instance_valid(st):
		return 1.0
	return maxf(eficiencia_de(st), 0.05)


## Os prédios feridos agora (não 100%).
func feridos() -> Array:
	return get_tree().get_nodes_in_group("integridades").filter(func(a): return is_instance_valid(a) and float(a.condicao()) < 0.999)


# ------------------------------------------------------------ o golpe do invasor
## Pode machucar prédio? (forte, elite, chefe, ou a onda já está num tier alto)
func pode_quebrar(c: Node) -> bool:
	if c == null or float(c.get("dano_predio")) <= 0.0:
		return false
	if bool(c.get("elite")) or String(c.get("variant")) in ["forte", "chefe"]:
		return true
	var def := get_tree().get_first_node_in_group("defense")
	return def != null and int(def.tier()) >= dano_tier_min


## O dano de UM golpe desse bicho (fração da condição do prédio), com forte/elite/chefe e o tier da onda.
func dano_do_golpe(c: Node) -> float:
	var d := float(c.get("dano_predio"))
	if String(c.get("variant")) == "forte":
		d *= mult_forte
	if bool(c.get("elite")):
		d *= mult_elite
	if String(c.get("variant")) == "chefe":
		d *= mult_chefe
	var def := get_tree().get_first_node_in_group("defense")
	if def:
		d *= 1.0 + dano_por_tier * float(maxi(int(def.tier()) - dano_tier_min, 0))
	return d


## O invasor `c` bateu em `predio`: machuca (se pode). Chamado pelo creature.gd.
func golpe(c: Node, predio: Node) -> void:
	if predio == null or not is_instance_valid(predio) or not pode_quebrar(c):
		return
	var tipo := tipo_de(predio)
	var a := _integ(predio, true)
	if a == null or a.em_ruina():
		return
	var d := dano_do_golpe(c)
	if tipo == "centro":
		d = minf(d, maxf(float(a.condicao()) - (1.0 - centro_dano_max), 0.0))
	if d <= 0.0:
		return
	var primeira := float(a.condicao()) >= 0.999
	a.gasta(d)
	if primeira:
		danificados_noite += 1
	if not _avisou.has(predio.get_instance_id()) and not a.em_ruina():
		_avisou[predio.get_instance_id()] = true
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and predio is Node2D:
			hud.show_toast("%s está sendo destruído!" % a.titulo, Color(1.0, 0.5, 0.35), predio)
	predio_ferido.emit(predio)
	if a.em_ruina():
		_ruiu(predio, a)


func _ruiu(predio: Node, a: Node) -> void:
	ruinas_total += 1
	predio_em_ruina.emit(predio)
	if predio.is_in_group("casas") and predio.has_method("residents"):
		var n := 0
		for w in predio.residents():
			if w.has_method("perde_a_cama"):
				w.perde_a_cama()
				n += 1
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and n > 0:
			hud.show_toast("%s em ruínas: %d morador%s sem cama até o conserto." % [a.titulo, n, "es" if n != 1 else ""], Color(1.0, 0.4, 0.35), predio)


## O prédio foi consertado (a Integridade avisa): nada a desfazer — a casa volta a aceitar moradores sozinha.
func mudou(_predio: Node) -> void:
	pass


# ------------------------------------------------------------ criar a Integridade
func tipo_de(predio: Node) -> String:
	if predio.is_in_group("casas"):
		return "casa"
	if predio.is_in_group("armazens"):
		return "armazem"
	if predio.is_in_group("enfermarias"):
		return "enfermaria"
	if predio.is_in_group("tavernas"):
		return "taverna"
	if predio.is_in_group("village_hub"):
		return "centro"
	return "predio"


func _titulo(predio: Node, tipo: String) -> String:
	var dn = predio.get("display_name")
	if dn != null and String(dn) != "":
		return String(dn)
	return {"casa": "Casa", "armazem": "Armazém", "enfermaria": "Enfermaria", "taverna": "Taverna", "centro": "Centro da Vila"}.get(tipo, "Prédio")


func _custo(tipo: String) -> Array:
	var b: Array = custo_base.get(tipo, custo_base.get("predio", [150, 20, 20, 45.0]))
	return [maxi(ceili(float(b[0]) * ruina_custo_pct), 1), ceili(float(b[1]) * ruina_custo_pct), ceili(float(b[2]) * ruina_custo_pct),
		maxf(float(b[3]) * ruina_custo_pct, 5.0)]


## A Integridade do prédio; `cria` = cria na 1ª vez.
func _integ(predio: Node, cria: bool) -> Node:
	var a := integridade_de(predio)
	if a != null or not cria:
		return a
	a = INTEGRIDADE.new()
	var tipo := tipo_de(predio)
	a.tipo_predio = tipo
	a.titulo = _titulo(predio, tipo)
	a.custo = _custo(tipo)
	a.limite = limite_conserto
	predio.add_child(a)
	_por_predio[predio.get_instance_id()] = a
	return a


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var l: Array = []
	for a in feridos():
		l.append(a.get_save_data())
	return {"predios": l, "ruinas": ruinas_total}


## Save antigo (sem a chave) = nenhum prédio ferido (100%). Cada ferido volta pelo caminho ou, se o caminho mudou, pelo
## prédio mais perto da posição guardada.
func load_save_data(d: Dictionary) -> void:
	for a in get_tree().get_nodes_in_group("integridades"):
		if is_instance_valid(a):
			a.free()  # (já: o novo filho "Integridade" precisa do mesmo nome, e o conserto salvo acha a máquina pelo caminho)
	_por_predio.clear()
	_avisou.clear()
	danificados_noite = 0
	ruinas_total = maxi(SaveUtil.integer(d, "ruinas", 0), 0)
	for x in SaveUtil.array(d, "predios"):
		if not (x is Dictionary):
			continue
		var predio: Node = get_node_or_null(NodePath(SaveUtil.text(x, "path", ""))) if SaveUtil.text(x, "path", "") != "" else null
		if predio == null or not is_instance_valid(predio):
			predio = _perto(SaveUtil.vec2(x, "pos", Vector2.INF))
		if predio == null:
			continue
		var a := _integ(predio, true)
		a._desgaste.load_save_data(SaveUtil.dict(x, "d"))


## O prédio (casa, armazém, enfermaria, taverna, centro) mais perto de um ponto, até 12 px (ou null).
func _perto(pos: Vector2) -> Node:
	if pos == Vector2.INF:
		return null
	var melhor: Node = null
	var melhor_d := 12.0
	for g in ["casas", "armazens", "enfermarias", "tavernas", "village_hub"]:
		for n in get_tree().get_nodes_in_group(g):
			var dd: float = (n as Node2D).global_position.distance_to(pos)
			if dd < melhor_d:
				melhor_d = dd
				melhor = n
	return melhor
