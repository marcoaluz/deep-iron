extends Node
## Bloco 126: as ESTATÍSTICAS DA PARTIDA (nó "Estatisticas", grupo "estatisticas"; Prompt 15): o que a tela de vitória e a janela do Sol mostram — dias, ipezinhos
## que passaram pela vila, mortes e causas, invasões vencidas, minério e barras produzidos, festivais, pedidos cumpridos, a caravana. Soma o que já existe
## (os contadores do missoes.gd, `armazem.lifetime_stored`, a `produzido` das fornalhas, `caravana.estatisticas()`) e guarda só o que faltava: quem passou
## (conta cada ipezinho NOVO do grupo "ipezinhos", uma vez), as mortes por causa (`registra_morte`, chamada pelo ipezinho), os festivais (`registra_festa`) e os
## pedidos cumpridos. Save: chave "estatisticas" (save antigo: as mortes e invasões saem dos contadores das missões e "passaram" recomeça da população atual).

signal mudou

const SaveUtil := preload("res://scripts/core/save_util.gd")

## De quanto em quanto tempo (s) procura ipezinhos novos.
@export var varre_a_cada: float = 1.0

var passaram := 0
var mortes := 0
var causas := {}  # rótulo -> quantas
var invasoes := 0
var festas := 0
var pedidos_cumpridos := 0
var _vistos := {}  # instance_id -> true (só desta sessão)
var _conta_novos := true
var _t := 0.0


func _ready() -> void:
	add_to_group("estatisticas")
	_liga.call_deferred()


func _liga() -> void:
	var def := get_tree().get_first_node_in_group("defense")
	if def and def.has_signal("invasion_ended") and not def.invasion_ended.is_connected(_invasao):
		def.invasion_ended.connect(_invasao)
	var ped := get_tree().get_first_node_in_group("pedidos")
	if ped and ped.has_signal("pedido_cumprido") and not ped.pedido_cumprido.is_connected(_pedido):
		ped.pedido_cumprido.connect(_pedido)
	_varre()


func _invasao(_mortos: int) -> void:
	invasoes += 1


func _pedido(_p: Dictionary) -> void:
	pedidos_cumpridos += 1


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = varre_a_cada
	_varre()


## Cada ipezinho que aparece no grupo da vila pela primeira vez conta uma vez (nascido, migrante aceito, o elenco inicial). Quem sai pra uma expedição e volta
## não conta de novo (a instância é a mesma).
func _varre() -> void:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		var id: int = w.get_instance_id()
		if _vistos.has(id):
			continue
		_vistos[id] = true
		if _conta_novos:
			passaram += 1
	_conta_novos = true


## O ipezinho morreu (chamado por `ipezinho._die`): conta e guarda a causa.
func registra_morte(_nome: String, causa: String) -> void:
	mortes += 1
	var r := rotulo_causa(causa)
	causas[r] = int(causas.get(r, 0)) + 1
	mudou.emit()


func registra_festa() -> void:
	festas += 1


## A causa do ferimento vira um grupo legível.
static func rotulo_causa(causa: String) -> String:
	var c := causa.strip_edges().to_lower()
	if c in ["lumivoro", "ferrugento", "gosma", "magmante", "rato", "morcego", "sombra", "criatura", "matriarca"]:
		return "criaturas"
	if c.begins_with("radia"):
		return "radiação"
	if c.begins_with("expedi"):
		return "expedições"
	if c in ["mina", "acidente", "desabamento"]:
		return "acidentes na mina"
	if c in ["acido", "ácido", "lava", "queimadura"]:
		return "ácido e lava"
	return "outras causas"


# ------------------------------------------------------------ o que se soma do que já existe
func _missoes() -> Node:
	return get_tree().get_first_node_in_group("missoes")


func dias() -> int:
	var dn := get_tree().get_first_node_in_group("day_night")
	return int(dn.day) if dn else 1


func vivos() -> int:
	return get_tree().get_nodes_in_group("ipezinhos").size()


func mortes_total() -> int:
	var ms := _missoes()
	return maxi(mortes, int(ms.contadores.mortes) if ms else 0)


func invasoes_total() -> int:
	var ms := _missoes()
	return maxi(invasoes, int(ms.contadores.invasoes) if ms else 0)


## Todo o minério e a pedra que entrou nos armazéns desde o começo (cada armazém guarda o seu total).
func minerio_produzido() -> int:
	var t := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		var v = a.get("lifetime_stored")
		t += float(v) if v != null else 0.0
	return int(t)


## Barras, aço e lingotes que as fornalhas já fizeram.
func barras_produzidas() -> int:
	var t := 0
	for f in get_tree().get_nodes_in_group("fornalhas"):
		var p = f.get("produzido")
		if typeof(p) != TYPE_DICTIONARY:
			continue
		for id in p:
			var s := String(id)
			if s.begins_with("barra_") or s == "aco" or s == "lingote_solar":
				t += int(p[id])
	return t


## As linhas da tela de vitória: "rótulo: valor". As do missoes.gd (missões, pesquisas, matriarcas, títulos) vêm junto, sem repetir.
func linhas() -> Array:
	var out: Array = []
	out.append("Dias de vila: %d" % dias())
	out.append("Ipezinhos que passaram pela vila: %d (%d vivos agora)" % [maxi(passaram, vivos()), vivos()])
	out.append("Mortes na vila: %d" % mortes_total())
	if not causas.is_empty():
		var partes: Array = []
		var ks: Array = causas.keys()
		ks.sort_custom(func(a, b): return int(causas[a]) > int(causas[b]))
		for k in ks:
			partes.append("%s %d" % [k, int(causas[k])])
		out.append("Mortes por causa: " + ", ".join(partes))
	out.append("Invasões vencidas: %d" % invasoes_total())
	out.append("Minério guardado nos armazéns (total): %d" % minerio_produzido())
	out.append("Barras, aço e lingotes produzidos: %d" % barras_produzidas())
	out.append("Festivais realizados: %d" % festas)
	out.append("Pedidos da vila cumpridos: %d" % pedidos_cumpridos)
	var car := get_tree().get_first_node_in_group("caravana")
	if car != null and car.has_method("estatisticas") and int(car.visitas) > 0:
		var c: Dictionary = car.estatisticas()
		out.append("Caravana: %d visita%s, %d cr em vendas, %d encomenda%s entregue%s" % [int(c.visitas), "" if int(c.visitas) == 1 else "s", int(c.vendido_cr),
			int(c.encomendas), "" if int(c.encomendas) == 1 else "s", "" if int(c.encomendas) == 1 else "s"])
	var ms := _missoes()
	if ms:
		for l in ms.estatisticas():
			var s := String(l)
			if s.begins_with("Missões") or s.begins_with("Pesquisas") or s.begins_with("Matriarcas") or s.begins_with("Títulos") or s.begins_with("Minério vendido"):
				out.append(s)
	return out


# ------------------------------------------------------------ save/load
func get_save_data() -> Dictionary:
	return {"passaram": maxi(passaram, vivos()), "mortes": mortes, "causas": causas.duplicate(), "invasoes": invasoes, "festas": festas, "pedidos_cumpridos": pedidos_cumpridos}


func load_save_data(d: Dictionary) -> void:
	passaram = maxi(SaveUtil.integer(d, "passaram", 0), 0)
	mortes = maxi(SaveUtil.integer(d, "mortes", 0), 0)
	invasoes = maxi(SaveUtil.integer(d, "invasoes", 0), 0)
	festas = maxi(SaveUtil.integer(d, "festas", 0), 0)
	pedidos_cumpridos = maxi(SaveUtil.integer(d, "pedidos_cumpridos", 0), 0)
	causas = {}
	var c := SaveUtil.dict(d, "causas")
	for k in c:
		if typeof(c[k]) in [TYPE_INT, TYPE_FLOAT] and int(c[k]) > 0:
			causas[String(k)] = int(c[k])
	# quem já está na vila foi contado no "passaram" salvo: marca sem contar de novo
	_vistos = {}
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		_vistos[w.get_instance_id()] = true
	mudou.emit()
