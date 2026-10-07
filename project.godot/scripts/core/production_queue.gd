extends RefCounted
## Bloco 86: ORDENS DE PRODUÇÃO — módulo genérico (Fornalha agora; Ferreiro no Bloco 87), baseado na fila
## da forja do defense.gd. Regras (CLAUDE.md, regra 9):
##   - NADA é produzido sozinho: o jogador escolhe a receita e a QUANTIDADE e confirma (encomendar);
##   - o trabalhador faz exatamente essa quantidade e a ordem sai da fila;
##   - sem ordem ativa ele não pega material nem produz nada (tem_trabalho() = false);
##   - cada UNIDADE consome os insumos só quando COMEÇA (comecar_unidades); faltando insumo, a ordem fica
##     PAUSADA com o aviso do que falta (falta) e nada mais é gasto; quando o insumo chega, ela continua;
##   - o jogador pode CANCELAR a qualquer momento (as unidades já começadas devolvem os insumos);
##   - a fila tem tamanho máximo (max_fila, @export de quem usa).
##
## Receita (Dictionary): {id, nome, insumos {item: qtd}, produto {item: qtd}, segundos (de trabalho por
## unidade), estagio (estágio mínimo da vila, 0 = qualquer)}. Itens = ids do items.gd (minério, barras...).
## Quem usa (a estação) guarda um destes, passa as receitas e a Economia, e chama trabalhar(s) com o
## trabalhador no posto; o que sai vai pro armazém (Economy.add_item/add_ore) por quem usa.

const Items := preload("res://scripts/core/items.gd")
const Ores := preload("res://scripts/core/ores.gd")

## Receitas: id -> receita.
var receitas: Dictionary = {}
## Máximo de ordens na fila.
var max_fila := 4
## Máximo de unidades numa ordem.
var max_quantidade := 50
## A fila: [{receita, quantidade, feitas, comecadas (pagas, ainda não prontas), progresso (s na unidade da
## vez), falta ("" ou "falta 2 carvão"), ordered_at}]. A primeira é a da vez.
var fila: Array = []


func _init(lista: Array = [], p_max_fila := 4) -> void:
	for r in lista:
		receitas[r.id] = r
	max_fila = p_max_fila


func receita(id: String) -> Dictionary:
	return receitas.get(id, {})


# ------------------------------------------------------------ encomendar / cancelar
## "" se dá pra encomendar; senão o motivo.
func motivo_encomenda(id: String, quantidade: int, estagio_vila: int) -> String:
	var r := receita(id)
	if r.is_empty():
		return "receita desconhecida"
	if quantidade < 1:
		return "quantidade zero"
	if fila.size() >= max_fila:
		return "fila cheia (%d)" % max_fila
	var minimo := int(r.get("estagio", 0))
	if minimo > 0 and estagio_vila < minimo:
		return "precisa da vila no estágio %d" % minimo
	return ""


## Põe a ordem na fila (não gasta nada agora: cada unidade paga quando começa).
func encomendar(id: String, quantidade: int, estagio_vila: int) -> bool:
	if motivo_encomenda(id, quantidade, estagio_vila) != "":
		return false
	fila.append({"receita": id, "quantidade": clampi(quantidade, 1, max_quantidade), "feitas": 0, "comecadas": 0,
		"progresso": 0.0, "falta": "", "ordered_at": Time.get_unix_time_from_system()})
	return true


## Cancela a ordem i. Devolve (pela economia) os insumos das unidades começadas e não prontas.
func cancelar(i: int, eco: Node, perto: Vector2 = Vector2.INF) -> bool:
	if i < 0 or i >= fila.size():
		return false
	var o: Dictionary = fila[i]
	var r := receita(o.receita)
	if int(o.comecadas) > 0 and eco and not r.is_empty():
		for item in r.insumos:
			_devolve(eco, item, float(r.insumos[item]) * int(o.comecadas), perto)
	fila.remove_at(i)
	return true


# ------------------------------------------------------------ trabalhar
## Tem ordem pra trabalhar? (sem ordem: o trabalhador não pega material nem produz)
func tem_trabalho() -> bool:
	return not fila.is_empty()


func atual() -> Dictionary:
	return fila[0] if not fila.is_empty() else {}


## Unidades da ordem da vez já pagas e esperando trabalho.
func comecadas() -> int:
	return int(atual().get("comecadas", 0))


## Unidades que ainda faltam começar na ordem da vez.
func a_comecar() -> int:
	var o := atual()
	return 0 if o.is_empty() else int(o.quantidade) - int(o.feitas) - int(o.comecadas)


## O que falta pra começar UMA unidade da ordem da vez ("" = tem tudo).
func falta_para(eco: Node) -> String:
	var o := atual()
	if o.is_empty() or eco == null:
		return ""
	var r := receita(o.receita)
	var partes: Array[String] = []
	for item in r.insumos:
		var tem: float = eco.livre(item) if eco.has_method("livre") else eco.quantidade(item)  # Bloco 96: não o reservado
		var precisa := float(r.insumos[item])
		if tem < precisa:
			var n := ceili(precisa - tem)
			partes.append("%d %s" % [n, Items.plural(item) if n > 1 else Items.nome(item).to_lower()])
	return "" if partes.is_empty() else "falta " + ", ".join(partes)


## COMEÇA até `n` unidades da ordem da vez: tira os insumos (tudo ou nada por unidade) pela economia.
## Retorna quantas começaram. 0 com insumo faltando = a ordem fica PAUSADA com o aviso (falta).
func comecar_unidades(n: int, eco: Node) -> int:
	var o := atual()
	if o.is_empty() or eco == null:
		return 0
	var r := receita(o.receita)
	var feitas := 0
	for k in mini(n, a_comecar()):
		if falta_para(eco) != "":
			break
		for item in r.insumos:
			_tira(eco, item, float(r.insumos[item]))
		feitas += 1
	o.comecadas = int(o.comecadas) + feitas
	o.falta = falta_para(eco) if feitas == 0 and int(o.comecadas) == 0 else ""
	return feitas


## A ordem da vez está parada por falta de insumo?
func pausada() -> bool:
	var o := atual()
	return not o.is_empty() and String(o.falta) != ""


## Trabalho de `segundos` na unidade começada da vez. Retorna o que ficou PRONTO ({item: qtd}; vazio =
## nada ainda). A ordem sai da fila quando faz a quantidade pedida.
func trabalhar(segundos: float) -> Dictionary:
	var o := atual()
	if o.is_empty() or int(o.comecadas) <= 0:
		return {}
	var r := receita(o.receita)
	var total := maxf(float(r.get("segundos", 10.0)), 0.1)
	o.progresso = float(o.progresso) + segundos
	var pronto := {}
	while float(o.progresso) >= total and int(o.comecadas) > 0:
		o.progresso = float(o.progresso) - total
		o.comecadas = int(o.comecadas) - 1
		o.feitas = int(o.feitas) + 1
		for item in r.produto:
			pronto[item] = pronto.get(item, 0.0) + float(r.produto[item])
	if int(o.comecadas) <= 0:
		o.progresso = 0.0
	if int(o.feitas) >= int(o.quantidade):
		fila.pop_front()
	return pronto


## 0..1 da unidade da vez.
func progresso_unidade() -> float:
	var o := atual()
	if o.is_empty():
		return 0.0
	var r := receita(o.receita)
	return clampf(float(o.progresso) / maxf(float(r.get("segundos", 10.0)), 0.1), 0.0, 1.0)


## "Barra de ferro 3/10" da ordem i.
func texto_ordem(i: int) -> String:
	if i < 0 or i >= fila.size():
		return ""
	var o: Dictionary = fila[i]
	var r := receita(o.receita)
	return "%s %d/%d" % [r.get("nome", o.receita), int(o.feitas), int(o.quantidade)]


## Texto dos insumos de uma unidade ("2 ferro + 1 carvão") e do produto.
func texto_insumos(id: String) -> String:
	var r := receita(id)
	var partes: Array[String] = []
	for item in r.get("insumos", {}):
		var n := int(r.insumos[item])
		partes.append("%d %s" % [n, Items.plural(item) if n > 1 else Items.nome(item).to_lower()])  # Bloco 94: plural
	return " + ".join(partes)


## Bloco 94: a Economia tira/devolve qualquer item do catálogo (processado, minério, madeira, couro).
func _tira(eco: Node, item: String, n: float) -> void:
	eco.tira(item, n)


func _devolve(eco: Node, item: String, n: float, perto: Vector2) -> void:
	eco.devolve(item, n, perto)


# ------------------------------------------------------------ save
func get_save_data() -> Array:
	return fila.map(func(o): return o.duplicate())


## Ordens de receitas que não existem mais saem; números fora do lugar viram o padrão.
func load_save_data(lista: Array) -> void:
	fila.clear()
	for o in lista:
		if typeof(o) != TYPE_DICTIONARY or not receitas.has(String(o.get("receita", ""))):
			continue
		var q := clampi(int(o.get("quantidade", 1)), 1, max_quantidade)
		var f := clampi(int(o.get("feitas", 0)), 0, q)
		fila.append({"receita": String(o.receita), "quantidade": q, "feitas": f,
			"comecadas": clampi(int(o.get("comecadas", 0)), 0, q - f), "progresso": maxf(float(o.get("progresso", 0.0)), 0.0),
			"falta": "", "ordered_at": float(o.get("ordered_at", 0.0))})
		if fila.size() >= max_fila:
			break
