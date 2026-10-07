extends RefCounted
## Bloco 31: o pedaço comum de toda OBRA (casa, melhoria da Vila, ferramenta da Oficina,
## peça da Escavadeira). Cada local guarda um destes e expõe a interface de obra
## (duck typing, consultada pelo engenheiro no ipezinho.gd):
##
##   obra_pending() -> bool          tem obra encomendada/em andamento aqui?
##   obra_title() -> String          "Casa nova", "Picareta de aço"...
##   obra_progress() -> float        0..1
##   obra_position(worker) -> Vector2  onde o engenheiro fica trabalhando
##   obra_work(seconds)              o engenheiro trabalhou `seconds` (só assim a obra anda)
##   obra_ordered_at() -> float      pra fila: a mais antiga é atendida primeiro
##   obra_join / obra_leave / obra_workers
##   obra_cancelar()                 (Bloco 96) desfaz a encomenda no dono (o reembolso é aqui: cancelar())
##
## Sem engenheiro no local, o relógio da obra NÃO anda (fica "esperando engenheiro").
## O que foi feito nunca se perde: tirar o engenheiro só pausa.
##
## Bloco 96: OBRAS COM MATERIAL. Na encomenda, o que o pagamento tirou do armazém (o RECIBO da Economy, deste
## quadro) volta pro armazém como RESERVA desta obra: `necessario` = {item: qtd}. O engenheiro busca no armazém
## (até a carga dele por viagem) e entrega aqui (`entregue`); a obra só anda até a fração entregue
## (`fracao()`). Os créditos ficam cobrados (`creditos`, devolvidos se cancelar). Sem lista (obra sem material,
## save antigo) = tudo entregue: anda como antes. Quem está levando o quê vem dos próprios engenheiros
## (`material_mao` / `material_pedido` + `_material_obra`): não fica estado solto aqui.

## Quando a obra foi encomendada (horário do sistema): define a ordem da fila.
var ordered_at: float = 0.0
var _workers: Array[Node] = []
## Bloco 87: quem trabalha aqui e o verbo ("engenheiro"/"construindo"; Oficina e Arsenal: "ferreiro"/"forjando").
var trabalhador := "engenheiro"
var verbo := "construindo"
## Bloco 96: o material da encomenda {item: qtd}, o que já chegou na obra e os créditos pagos.
var necessario: Dictionary = {}
var entregue: Dictionary = {}
var creditos: float = 0.0


## (Prompt 28: o "fantasma que fica nítido" saiu; a obra aparece por estágios, ver
## obra_estagio.gd.)


## A ObraSite de um dono de obra (todo dono guarda a sua em `_obra`), ou null.
static func de(dono: Object) -> RefCounted:
	if dono == null or not is_instance_valid(dono):
		return null
	var o = dono.get("_obra")
	return o if o != null and o is RefCounted and o.has_method("fracao") else null


## Obra nova encomendada agora. Bloco 96: pega o recibo do pagamento deste quadro (o material volta pro
## armazém como reserva desta obra). As da forja (ferreiro) são produção: continuam pagando na hora.
func start() -> void:
	ordered_at = Time.get_unix_time_from_system()
	_workers.clear()
	necessario = {}
	entregue = {}
	creditos = 0.0
	if trabalhador != "engenheiro":
		return
	var tree := Engine.get_main_loop() as SceneTree
	var eco: Node = tree.get_first_node_in_group("economy") if tree else null
	if eco and eco.has_method("recibo_da_encomenda"):
		var r: Dictionary = eco.recibo_da_encomenda()
		necessario = r.get("materiais", {})
		creditos = float(r.get("creditos", 0.0))


func join(worker: Node) -> void:
	if not _workers.has(worker):
		_workers.append(worker)


func leave(worker: Node) -> void:
	_workers.erase(worker)


func workers() -> Array[Node]:
	_workers = _workers.filter(func(w): return is_instance_valid(w))
	return _workers


func has_engineer() -> bool:
	return not workers().is_empty()


# ------------------------------------------------------------ material (Bloco 96)
func tem_material() -> bool:
	return not necessario.is_empty()


func total_necessario() -> float:
	var t := 0.0
	for k in necessario:
		t += float(necessario[k])
	return t


func total_entregue() -> float:
	var t := 0.0
	for k in necessario:
		t += minf(float(entregue.get(k, 0.0)), float(necessario[k]))
	return t


## Até onde a obra pode andar: a fração do material que já chegou (1 = sem material ou tudo entregue).
func fracao() -> float:
	var t := total_necessario()
	return 1.0 if t <= 0.0 else clampf(total_entregue() / t, 0.0, 1.0)


func tudo_entregue() -> bool:
	return fracao() >= 1.0 - 0.0001


## O que ainda falta CHEGAR desse item (sem contar o que está a caminho).
func falta(item: String) -> float:
	return maxf(float(necessario.get(item, 0.0)) - float(entregue.get(item, 0.0)), 0.0)


## Os engenheiros ligados a esta obra (levando ou indo buscar).
func _do_material() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	return tree.get_nodes_in_group("ipezinhos").filter(func(w): return _ligado(w))


## Esse engenheiro está levando/buscando material pra esta obra?
func _ligado(w: Node) -> bool:
	var o = w.get("_material_obra")
	return o != null and is_instance_valid(o) and de(o) == self


## Nas mãos dos engenheiros, vindo pra cá.
func em_maos(item: String) -> float:
	var n := 0.0
	for w in _do_material():
		n += float(w.material_mao.get(item, 0.0))
	return n


## Já prometido por um engenheiro que está indo ao armazém buscar.
func pedido(item: String) -> float:
	var n := 0.0
	for w in _do_material():
		n += float(w.material_pedido.get(item, 0.0))
	return n


## O que ainda precisa de uma viagem (nem chegou, nem está nas mãos, nem prometido).
func a_buscar(item: String) -> float:
	return maxf(falta(item) - em_maos(item) - pedido(item), 0.0)


## O que ainda está NO ARMAZÉM reservado pra esta obra (falta chegar e não está nas mãos de ninguém).
func reservado(item: String) -> float:
	return maxf(falta(item) - em_maos(item), 0.0)


## O material entregue e ainda não usado (a pilha ao lado da obra): {item: qtd}.
func pilha(progresso: float) -> Dictionary:
	var out := {}
	for k in necessario:
		var sobra := float(entregue.get(k, 0.0)) - float(necessario[k]) * clampf(progresso, 0.0, 1.0)
		if sobra > 0.5:
			out[k] = sobra
	return out


## Chegou material (o engenheiro entregou).
func entregar(item: String, qtd: float) -> void:
	entregue[item] = minf(float(entregue.get(item, 0.0)) + qtd, float(necessario.get(item, qtd)))
	_reserva_mudou()


static func _reserva_mudou() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var eco: Node = tree.get_first_node_in_group("economy") if tree else null
	if eco and eco.has_method("reserva_mudou"):
		eco.reserva_mudou()


## "madeira 20/40 · ferro 10/20" (vazio = sem material).
func material_texto() -> String:
	var bits: Array[String] = []
	for k in necessario:
		bits.append("%s %d/%d" % [_nome(k), int(minf(float(entregue.get(k, 0.0)), float(necessario[k]))), int(necessario[k])])
	return "  ·  ".join(bits)


static func _nome(item: String) -> String:
	var Items = load("res://scripts/core/items.gd")
	return String(Items.nome(item)).to_lower() if Items.existe(item) else item


# ------------------------------------------------------------ estado
## "40% — construindo" / "40% — esperando engenheiro". Bloco 96: com material, "buscando material",
## "levando N/M" ou "falta material no armazém".
func status(progress: float) -> String:
	return "%d%% — %s" % [roundi(progress * 100.0), estado(progress)]


func estado(progress: float = 0.0) -> String:
	var ligados := _do_material()
	if not tem_material() or tudo_entregue():
		return verbo if has_engineer() else "esperando " + trabalhador
	if ligados.any(func(w): return not w.material_mao.is_empty()):
		var vindo := 0.0
		for w in ligados:
			for k in w.material_mao:
				vindo += float(w.material_mao[k])
		return "levando %d/%d" % [int(total_entregue() + vindo), int(total_necessario())]
	if ligados.any(func(w): return not w.material_pedido.is_empty()):
		return "buscando material"
	if has_engineer() and progress < fracao() - 0.0001:
		return verbo
	var tree := Engine.get_main_loop() as SceneTree
	var eco: Node = tree.get_first_node_in_group("economy") if tree else null
	if eco and eco.has_method("tem_no_armazem"):
		for k in necessario:
			if a_buscar(k) > 0.0 and not eco.tem_no_armazem(k):
				return "falta material no armazém"
	return verbo if has_engineer() else "esperando " + trabalhador


## Lado a lado quando mais de um engenheiro trabalha no mesmo lugar.
func offset_for(worker: Node) -> Vector2:
	var i := workers().find(worker)
	if i < 0:
		i = workers().size()
	return Vector2(-18.0 + 18.0 * (i % 3), 8.0 * floorf(i / 3.0))


# ------------------------------------------------------------ cancelar (Bloco 96)
## Cancela a obra do dono: devolve ao armazém o que já foi entregue e o que está nas mãos (o reservado só deixa
## de ser reservado: nunca saiu), devolve os créditos por inteiro e manda o dono desfazer a encomenda.
static func cancelar(dono: Node) -> bool:
	var site = de(dono)
	if site == null or not dono.has_method("obra_cancelar") or not dono.obra_pending():
		return false
	var tree := dono.get_tree()
	var eco := tree.get_first_node_in_group("economy")
	var perto: Vector2 = (dono as Node2D).global_position if dono is Node2D else Vector2.INF
	for w in site._do_material():
		w.solta_material(true)  # o que está nas mãos volta pro armazém (e a promessa some)
	if eco:
		for k in site.entregue:
			eco.devolve(k, float(site.entregue[k]), perto)
		if site.creditos > 0.0:
			eco._add_credits(site.creditos)
	for w in site.workers():
		if w.has_method("_obra_stop"):
			w._obra_stop()
	site.necessario = {}
	site.entregue = {}
	site.creditos = 0.0
	site._workers.clear()
	dono.obra_cancelar()
	_reserva_mudou()
	return true


func get_save_data() -> Dictionary:
	var d := {"ordered_at": ordered_at}
	if tem_material():  # Bloco 96
		d["necessario"] = necessario.duplicate()
		d["entregue"] = entregue.duplicate()
		d["creditos"] = creditos
	return d


## Bloco 96: save antigo (sem "necessario") = obra sem material = tudo entregue (anda como antes).
func load_save_data(d: Dictionary) -> void:
	var v = d.get("ordered_at", 0.0)
	ordered_at = float(v) if (v is float or v is int) else 0.0
	_workers.clear()
	necessario = {}
	entregue = {}
	var n = d.get("necessario", {})
	var e = d.get("entregue", {})
	if n is Dictionary:
		for k in n:
			if (n[k] is float or n[k] is int) and float(n[k]) > 0.0:
				necessario[String(k)] = float(n[k])
	if e is Dictionary:
		for k in e:
			if necessario.has(String(k)) and (e[k] is float or e[k] is int):
				entregue[String(k)] = clampf(float(e[k]), 0.0, float(necessario[String(k)]))
	var c = d.get("creditos", 0.0)
	creditos = float(c) if (c is float or c is int) else 0.0
