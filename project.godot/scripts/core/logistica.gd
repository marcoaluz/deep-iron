extends Node
## Bloco 105: a LOGÍSTICA (nó "Logistica" na main.tscn, grupo "logistica") — o trabalho do CARREGADOR.
##
## As ENTREGAS (montadas na hora, nada solto guardado):
##   "obra"    o material que uma obra ainda precisa (ObraSite.a_buscar): do armazém (o reservado DELA) pro canteiro.
##             O carregador usa os mesmos campos do engenheiro (material_pedido / material_mao / _material_obra), então a
##             reserva, a pilha e o cancelar da obra continuam valendo (Bloco 96).
##   "insumo"  a Fornalha/Carpintaria tem ordem e nenhuma unidade começada: ele paga no armazém os insumos do próximo lote
##             (só o LIVRE) e leva; as unidades ficam "a caminho" (production_queue) e só começam na entrega.
##   "barras"  as barras prontas que ficaram na fornalha (com carregador o fundidor não sai dela): pro armazém com espaço.
##   "cozinha" matéria-prima (o LIVRE) do armazém pro estoque da cozinha (comedouro.raw_local); o cozinheiro prepara dali.
## Cada entrega é reservada pra UM carregador. Quem precisava (engenheiro, fundidor, cozinheiro) espera o carregador; se a
## entrega ficar `espera_carregador` segundos sem ninguém pegar (ou não houver carregador), ele mesmo vai: nada trava.
## Save: chave "logistica" (só os contadores: as entregas em curso recomeçam).

signal entrega_feita(tipo: String)

const ObraSite := preload("res://scripts/core/obra_site.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const PRIORIDADE := {"obra": 0, "barras": 1, "insumo": 1, "cozinha": 2}

## Segundos de jogo que uma entrega espera um carregador antes de quem precisa ir buscar ele mesmo.
@export var espera_carregador: float = 30.0

var entregas := 0
var _reservas := {}  # chave -> carregador
var _pendente := {}  # chave -> segundos esperando sem carregador


func _ready() -> void:
	add_to_group("logistica")


func tem_carregador() -> bool:
	return get_tree().get_nodes_in_group("ipezinhos").any(func(w): return w.has_method("is_carrier") and w.is_carrier() and not w.injured)


static func chave(tipo: String, alvo: Object) -> String:
	return "%s:%d" % [tipo, alvo.get_instance_id()] if alvo != null and is_instance_valid(alvo) else tipo


## As entregas de agora: [{tipo, alvo, chave, ordem}].
func entregas_abertas() -> Array:
	var out: Array = []
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return out
	for site in get_tree().get_nodes_in_group("obras"):
		if not site.has_method("obra_pending") or not site.obra_pending():
			continue
		var os = ObraSite.de(site)
		if os == null or not os.tem_material():
			continue
		for k in os.necessario:
			if os.a_buscar(k) >= 0.5 and not eco.armazens_com(k, (site as Node2D).global_position).is_empty():
				out.append({"tipo": "obra", "alvo": site, "chave": chave("obra", site), "ordem": float(site.obra_ordered_at())})
				break
	for grupo in ["fornalhas", "carpintarias"]:
		for f in get_tree().get_nodes_in_group(grupo):
			if f.get("fila") == null:
				continue
			if not (f.get("barras_prontas") as Dictionary).is_empty():
				out.append({"tipo": "barras", "alvo": f, "chave": chave("barras", f), "ordem": 0.0})
			var fl = f.fila
			if fl.a_comecar() > 0 and fl.comecadas() + fl.a_caminho() == 0 and fl.falta_para(eco) == "" \
					and get_tree().get_nodes_in_group("ipezinhos").any(f.e_operador):
				out.append({"tipo": "insumo", "alvo": f, "chave": chave("insumo", f), "ordem": 0.0})
	if eco.livre("comida_crua") >= 1.0 and get_tree().get_nodes_in_group("ipezinhos").any(func(w): return w.is_cook()):
		for c in get_tree().get_nodes_in_group("comedouros"):
			if c.get("raw_local") != null and float(c.raw_local) < float(c.raw_local_max) * 0.5:
				out.append({"tipo": "cozinha", "alvo": c, "chave": chave("cozinha", c), "ordem": 0.0})
	return out


## A entrega pra esse carregador (a que ele já tem, ou a mais importante livre e mais perto). {} = nenhuma.
func reserva(w: Node) -> Dictionary:
	var lista := entregas_abertas()
	for e in lista:
		if _reservas.get(e.chave) == w:
			return e
	var melhor := {}
	var nota := INF
	var de: Vector2 = (w as Node2D).global_position
	for e in lista:
		var dono = _reservas.get(e.chave)
		if dono != null and dono != w and is_instance_valid(dono):
			continue
		var n: float = PRIORIDADE.get(String(e.tipo), 9) * 100000.0 + de.distance_to((e.alvo as Node2D).global_position)
		if e.tipo == "obra":
			n = float(e.ordem) - 1.0e12  # (as obras vêm antes de tudo, a mais antiga primeiro)
		if n < nota:
			nota = n
			melhor = e
	if not melhor.is_empty():
		solta(w)
		_reservas[melhor.chave] = w
		_pendente.erase(melhor.chave)
	return melhor


func tem_entrega_para(w: Node) -> bool:
	for e in entregas_abertas():
		var dono = _reservas.get(e.chave)
		if dono == null or dono == w or not is_instance_valid(dono):
			return true
	return false


func solta(w: Node) -> void:
	for k in _reservas.keys():
		if _reservas[k] == w:
			_reservas.erase(k)


func feita(w: Node, tipo: String) -> void:
	solta(w)
	entregas += 1
	entrega_feita.emit(tipo)


## Quem precisa (engenheiro, fundidor, cozinheiro) deixa essa entrega pro carregador? true = espere; false = vá você.
func deixa_pro_carregador(tipo: String, alvo: Object) -> bool:
	if not tem_carregador():
		return false
	var k := chave(tipo, alvo)
	var dono = _reservas.get(k)
	if dono != null and is_instance_valid(dono):
		return true
	return float(_pendente.get(k, 0.0)) < espera_carregador


var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t < 0.5:
		return  # (a cada meio segundo: as entregas são montadas na hora)
	delta = _t
	_t = 0.0
	var abertas := {}
	for e in entregas_abertas():
		abertas[e.chave] = true
		var dono = _reservas.get(e.chave)
		if dono == null or not is_instance_valid(dono):
			_pendente[e.chave] = float(_pendente.get(e.chave, 0.0)) + delta
	for k in _pendente.keys():
		if not abertas.has(k):
			_pendente.erase(k)
	for k in _reservas.keys():
		var w = _reservas[k]
		if not is_instance_valid(w) or not w.is_carrier():
			_reservas.erase(k)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"entregas": entregas}


func load_save_data(d: Dictionary) -> void:
	entregas = maxi(SaveUtil.integer(d, "entregas", 0), 0)
	_reservas.clear()
	_pendente.clear()
