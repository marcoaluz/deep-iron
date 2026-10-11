extends Node
## Bloco 125: a CARAVANA (nó "Caravana", grupo "caravana" + "modificadores"; Prompt 13): uma comerciante visitante (Cacilda, ipezinho `visitante` com a arte
## própria "comerciante": retrato, falas) chega a cada `intervalo_dias` dias, para no POSTO DE TROCA (props/posto_troca.gd, obra em etapas do Centro) e fica
## `permanencia_dias` dias. Sem posto pronto ela não para (avisa uma vez e tenta de novo no dia seguinte). A cada visita:
##   • a vila COMPRA dela (créditos): peças raras, pacotes de sementes (a horta rende mais por alguns dias) e carne defumada (comida crua);
##   • a caravana COMPRA da vila (créditos): barras e gemas, com um teto de demanda por visita;
##   • uma ENCOMENDA (ou duas) entra nos pedidos da vila (F7) com o retrato dela: "entregar N barras antes de eu partir" — quem entrega leva um bônus;
##   • os PREÇOS variam por estação (inverno: a comida e o metal sobem), por situação do mercado sorteada na visita (escassez, excedente, metal em alta,
##     feira) e por evento (`Modificadores.mult("caravana_preco")`), com uma variação por item; a DIFICULDADE entra pelo "preco_venda" (quem paga mais ao jogador
##     cobra menos dele).
## NADA compra nem vende sozinho: tudo é botão da janela (clique no posto, ou "Janelas"). Os números estão nos @export; o texto das falas em
## data/caravana/falas.txt (editável). Save: chave "caravana".

signal mudou
signal chegou
signal partiu

const SaveUtil := preload("res://scripts/core/save_util.gd")
const Items := preload("res://scripts/core/items.gd")
const Modificadores := preload("res://scripts/core/modificadores.gd")
const FALAS := "res://data/caravana/falas.txt"

@export_group("Visita")
## Liga a caravana (o Criativo e os testes desligam).
@export var ligado: bool = true
## A primeira visita só a partir deste dia (precisa do posto de troca).
@export var primeiro_dia: int = 8
## Dias entre uma chegada e a seguinte.
@export var intervalo_dias: int = 14
## Dias que ela fica no posto.
@export var permanencia_dias: int = 3
@export var nome_comerciante: String = "Cacilda"
## Segundos que ela espera pra sair do mapa antes de sumir de qualquer jeito (travada no caminho).
@export var saida_limite_s: float = 90.0
@export_group("Preços")
## O que ela COBRA da vila, em vezes o preço base (a vila compra dela).
@export var margem_cobra: float = 1.3
## O que ela PAGA à vila, em vezes o preço base de venda (ela compra barras e gemas).
@export var margem_paga: float = 1.2
## Variação sorteada por item a cada visita (± fração).
@export_range(0.0, 0.5) var variacao: float = 0.12
## Por estação (primavera, verão, outono, inverno): o que ela cobra. O inverno encarece a comida e as sementes.
@export var estacao_cobra: Array[float] = [0.95, 1.0, 1.05, 1.25]
## Por estação: o que ela paga pelo metal e as gemas (no outono e no inverno o metal vale mais).
@export var estacao_paga: Array[float] = [0.95, 1.0, 1.15, 1.25]
## Chance (0..1) de a visita ter uma situação de mercado diferente da normal.
@export_range(0.0, 1.0) var chance_situacao: float = 0.5
@export_group("Mercadoria")
## O que um pacote de sementes faz na horta: + fração do crescimento, por tantos dias.
@export var semente_bonus: float = 0.5
@export var semente_dias: int = 10
## Quanta comida crua (unidades do armazém; uma porção = 8) vem numa carne defumada.
@export var carne_comida: float = 24.0
## Quanto ela quer comprar de cada coisa numa visita (unidades). O que passa disso ela recusa até a próxima.
@export var demanda_visita: Dictionary = {"barra_ferro": 40, "barra_cobre": 25, "barra_prata": 12, "aco": 10,
	"cristal_verde": 8, "cristal_rubro": 6, "gema_azul": 4}
@export_group("Encomendas")
## O bônus da encomenda cumprida, em vezes o valor da mercadoria (preço base).
@export var encomenda_bonus: float = 0.6
## Da visita N em diante ela traz duas encomendas.
@export var segunda_encomenda_visita: int = 3

## O que ela vende: id -> {nome, base (preço base, cr), est [mín, máx] por visita, efeito ("item": entra no armazém; "semente"; "carne"), icone, desc}.
const LOJA := {
	"pecas_raras": {"nome": "Peça rara", "base": 60.0, "est": [2, 4], "efeito": "item", "icone": "it_pecas_raras", "desc": "Peças que nenhuma oficina da vila faz (a Antena, as máquinas)."},
	"semente": {"nome": "Pacote de sementes", "base": 25.0, "est": [3, 5], "efeito": "semente", "icone": "pq_hidroponia", "desc": "A horta cresce mais rápido por alguns dias."},
	"carne_defumada": {"nome": "Carne defumada", "base": 16.0, "est": [6, 12], "efeito": "carne", "icone": "comida", "desc": "Vira comida crua no armazém."},
}
## O que ela compra da vila (a ordem da janela).
const COMPRA := ["barra_ferro", "barra_cobre", "barra_prata", "aco", "cristal_verde", "cristal_rubro", "gema_azul"]
## Encomendas que ela pode trazer: item e a faixa da quantidade.
const ENCOMENDAS := [
	{"id": "barra_ferro", "min": 15, "max": 30}, {"id": "barra_cobre", "min": 10, "max": 20}, {"id": "barra_prata", "min": 5, "max": 10},
	{"id": "aco", "min": 5, "max": 10}, {"id": "cristal_verde", "min": 3, "max": 6}, {"id": "gema_azul", "min": 2, "max": 4},
	{"id": "cristal_rubro", "min": 3, "max": 6},
]
## A situação do mercado da visita: o que ela cobra e o que ela paga (multiplicam), o sorteio e o nome na janela.
const SITUACOES := {
	"normal": {"nome": "preços de sempre", "cobra": 1.0, "paga": 1.0, "peso": 5.0},
	"escassez": {"nome": "estrada perigosa (tudo mais caro)", "cobra": 1.2, "paga": 1.1, "peso": 2.0},
	"excedente": {"nome": "carroça cheia (tudo mais barato)", "cobra": 0.85, "paga": 0.9, "peso": 2.0},
	"demanda": {"nome": "metal em alta", "cobra": 1.0, "paga": 1.3, "peso": 2.0},
	"festa": {"nome": "feira na capital", "cobra": 1.15, "paga": 1.15, "peso": 1.0},
}

static var _falas: Dictionary = {}

var presente := false
var chegou_dia := 0
var parte_dia := 0
var proxima_dia := -1
var visitas := 0
var situacao := "normal"
var estoque: Dictionary = {}  # id -> o que ela ainda tem (unidades)
var demanda: Dictionary = {}  # id -> o que ela ainda quer comprar (unidades)
var preco_cobra: Dictionary = {}  # id -> preço (cr) da visita, antes de dificuldade e eventos
var preco_paga: Dictionary = {}
var semente_ate_dia := 0
var ultima_fala := ""
var _avisou_sem_posto := false
## O que a vila negociou com a caravana desde o começo (as estatísticas finais, Prompt 15).
var vendido_cr := 0.0  # o que a vila ganhou vendendo a ela
var gasto_cr := 0.0  # o que a vila gastou comprando dela
var vendidos: Dictionary = {}  # id -> unidades que a vila vendeu
var comprados: Dictionary = {}  # id -> unidades que a vila comprou
var encomendas_cumpridas := 0
var _comerciante: Node2D = null
var _saindo := false
var _saindo_t := 0.0
var _negocia_t := 0.0
var _t := 0.0


func _ready() -> void:
	add_to_group("caravana")
	add_to_group("modificadores")
	_liga.call_deferred()


func _liga() -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn and dn.has_signal("day_started") and not dn.day_started.is_connected(_novo_dia):
		dn.day_started.connect(_novo_dia)
	var ped := get_tree().get_first_node_in_group("pedidos")
	if ped and ped.has_signal("pedido_cumprido") and not ped.pedido_cumprido.is_connected(_pedido_cumprido):
		ped.pedido_cumprido.connect(_pedido_cumprido)
	if presente and _comerciante == null:
		_cria_comerciante(true)


# ------------------------------------------------------------ os dados
static func falas() -> Dictionary:
	if _falas.is_empty() and FileAccess.file_exists(FALAS):
		for linha in FileAccess.get_file_as_string(FALAS).split("\n"):
			var l := linha.strip_edges()
			if l == "" or l.begins_with("#") or not "=" in l:
				continue
			var i := l.find("=")
			var chave := l.substr(0, i).strip_edges()
			var variantes: Array = []
			for v in l.substr(i + 1).split("|"):
				var t := v.strip_edges()
				if t != "":
					variantes.append(t)
			if chave != "" and not variantes.is_empty():
				_falas[chave] = variantes
	return _falas


## Uma fala sorteada da chave (com {nome}, {dias}, {item}, {meta} trocados).
func fala(chave: String, extra: Dictionary = {}) -> String:
	var v: Array = falas().get(chave, [])
	if v.is_empty():
		return ""
	var t: String = String(v[randi() % v.size()]).replace("{nome}", nome_comerciante).replace("{dias}", str(permanencia_dias))
	for k in extra:
		t = t.replace("{%s}" % k, str(extra[k]))
	return t


func _dia() -> int:
	var dn := get_tree().get_first_node_in_group("day_night")
	return int(dn.day) if dn else 1


func _eco() -> Node:
	return get_tree().get_first_node_in_group("economy")


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func _estacao() -> int:
	var sol := get_tree().get_first_node_in_group("sun")
	return clampi(int(sol.season_index()) if sol and sol.has_method("season_index") else 0, 0, 3)


func posto() -> Node2D:
	for p in get_tree().get_nodes_in_group("postos_troca"):
		if is_instance_valid(p) and p.is_inside_tree():
			return p
	return null


## Quanto da visita ainda resta (dias, contando hoje).
func dias_restantes() -> int:
	return maxi(parte_dia - _dia(), 0) if presente else 0


# ------------------------------------------------------------ o relógio
func _novo_dia(dia: int) -> void:
	if presente:
		if dia >= parte_dia:
			parte()
		return
	if not ligado:
		return
	if proxima_dia < 0:
		proxima_dia = primeiro_dia
	if dia < proxima_dia:
		return
	var sol := get_tree().get_first_node_in_group("sun")
	if sol and sol.has_method("wave_active") and sol.wave_active():  # (a onda solar: ela espera)
		return
	if posto() == null:
		if not _avisou_sem_posto:
			_avisou_sem_posto = true
			var h := _hud()
			if h:
				h.show_toast(fala("sem_posto"), Color(0.95, 0.8, 0.5))
		return
	chega()


func _process(delta: float) -> void:
	if _negocia_t > 0.0:
		_negocia_t -= delta
		if _negocia_t <= 0.0 and _comerciante != null and is_instance_valid(_comerciante):
			_comerciante.set("_work_timer", 0.0)
	_t -= delta
	if _t > 0.0:
		return
	_t = 1.0
	if _saindo:
		_saindo_t += 1.0
		if _comerciante == null or not is_instance_valid(_comerciante):
			_saindo = false
		else:
			var o := _origem()
			if _comerciante.global_position.distance_to(o) < 60.0 or _saindo_t >= saida_limite_s:
				_comerciante.queue_free()
				_comerciante = null
				_saindo = false
	elif presente and (_comerciante == null or not is_instance_valid(_comerciante)):
		_cria_comerciante(true)  # (carregou o save, ou o posto nasceu depois)


# ------------------------------------------------------------ chegar e partir
## A caravana chega agora (o relógio, o F3 e os testes chamam). false = não deu (já está aqui, ou não tem posto).
func chega() -> bool:
	if presente or posto() == null:
		return false
	presente = true
	_saindo = false
	visitas += 1
	chegou_dia = _dia()
	parte_dia = chegou_dia + maxi(permanencia_dias, 1)
	proxima_dia = chegou_dia + maxi(intervalo_dias, permanencia_dias + 1)
	_avisou_sem_posto = false
	situacao = _sorteia_situacao()
	_monta_ofertas()
	_cria_comerciante(false)
	_abre_encomendas()
	ultima_fala = fala("chegada_primeira" if visitas == 1 else "chegada")
	var h := _hud()
	if h:
		h.show_toast("A caravana de %s chegou ao posto de troca (%d dias): clique no posto." % [nome_comerciante, permanencia_dias], Color(1.0, 0.85, 0.5), posto())
	_som("caravana/chegada")
	chegou.emit()
	mudou.emit()
	return true


## Ela parte agora: some pelo caminho de onde veio e as encomendas que sobraram vencem.
func parte() -> void:
	if not presente:
		return
	presente = false
	var ped := get_tree().get_first_node_in_group("pedidos")
	if ped and ped.has_method("vence_da_caravana"):
		ped.vence_da_caravana()
	if _comerciante != null and is_instance_valid(_comerciante):
		_comerciante.set("_work_timer", 0.0)
		_comerciante.call("move_to", _origem())
		_saindo = true
		_saindo_t = 0.0
	ultima_fala = fala("despedida")
	_diario()
	var h := _hud()
	if h:
		h.show_toast("%s: \"%s\"" % [nome_comerciante, ultima_fala], Color(0.85, 0.8, 0.65))
	partiu.emit()
	mudou.emit()


func _origem() -> Vector2:
	var m := get_tree().get_first_node_in_group("migrantes")
	if m != null and m.has_method("_origem"):
		return m._origem()
	var p := posto()
	return (p.global_position + Vector2(-420, 0)) if p else Vector2(-600, 0)


func _cria_comerciante(do_posto: bool) -> void:
	var eco := _eco()
	var p := posto()
	if eco == null or eco.worker_scene == null or p == null:
		return
	var w: Node2D = eco.worker_scene.instantiate()
	w.set("visitante", true)
	w.set("e_comerciante", true)
	w.set("gender", "menina")
	w.set("display_name", nome_comerciante)
	w.name = "Comerciante"
	var hub := get_tree().get_first_node_in_group("village_hub")
	var parent: Node = hub.get_parent() if hub else get_parent()
	w.position = p.ponto_comerciante() if do_posto else _origem()
	parent.add_child(w)
	_comerciante = w
	if not do_posto:
		w.call("move_to", p.ponto_comerciante())


func _garante_comerciante() -> void:
	if presente and (_comerciante == null or not is_instance_valid(_comerciante)):
		_cria_comerciante(true)


func comerciante() -> Node:
	return _comerciante if _comerciante != null and is_instance_valid(_comerciante) else null


# ------------------------------------------------------------ preços e ofertas
func _sorteia_situacao() -> String:
	if randf() >= chance_situacao:
		return "normal"
	var total := 0.0
	for k in SITUACOES:
		if k != "normal":
			total += float(SITUACOES[k].peso)
	var r := randf() * total
	for k in SITUACOES:
		if k == "normal":
			continue
		r -= float(SITUACOES[k].peso)
		if r <= 0.0:
			return k
	return "escassez"


## O preço base (cr) de mercado de um id: a Economia (minério, barras, gemas) ou a tabela da loja.
func preco_base(id: String) -> float:
	if LOJA.has(id):
		return float(LOJA[id].base)
	var eco := _eco()
	return float(eco._preco_base(id)) if eco else Items.preco_base(id)


func _var() -> float:
	return 1.0 + randf_range(-variacao, variacao)


func _monta_ofertas() -> void:
	estoque = {}
	demanda = {}
	preco_cobra = {}
	preco_paga = {}
	var est := _estacao()
	var sit: Dictionary = SITUACOES.get(situacao, SITUACOES.normal)
	for id in LOJA:
		var d: Dictionary = LOJA[id]
		estoque[id] = randi_range(int(d.est[0]), int(d.est[1]))
		preco_cobra[id] = maxf(roundf(float(d.base) * margem_cobra * float(estacao_cobra[est]) * float(sit.cobra) * _var()), 1.0)
	for id in COMPRA:
		demanda[id] = int(demanda_visita.get(id, 0))
		preco_paga[id] = maxf(roundf(preco_base(id) * margem_paga * float(estacao_paga[est]) * float(sit.paga) * _var()), 1.0)


func _dificuldade() -> float:
	return maxf(Modificadores.mult(get_tree(), "preco_venda"), 0.1)


## O preço de agora (cr por unidade) que a vila PAGA por `id` (a dificuldade que paga mais ao jogador cobra menos dele; os eventos mexem).
func preco_pra_vila(id: String) -> float:
	return maxf(roundf(float(preco_cobra.get(id, 0.0)) * Modificadores.mult(get_tree(), "caravana_preco") / _dificuldade()), 1.0)


## O preço de agora (cr por unidade) que a caravana PAGA à vila por `id`.
func preco_da_vila(id: String) -> float:
	return maxf(roundf(float(preco_paga.get(id, 0.0)) * Modificadores.mult(get_tree(), "caravana_preco") * _dificuldade()), 1.0)


func nome_do_item(id: String) -> String:
	return String(LOJA[id].nome) if LOJA.has(id) else Items.nome(id)


func icone_do_item(id: String) -> String:
	return String(LOJA[id].icone) if LOJA.has(id) else Items.icone(id)


func situacao_texto() -> String:
	return String(SITUACOES.get(situacao, SITUACOES.normal).nome)


# ------------------------------------------------------------ negociar (só por botão da janela)
## A vila compra `n` de `id` da caravana. {ok, motivo, custo}.
func compra_da_caravana(id: String, n: int) -> Dictionary:
	var eco := _eco()
	if not presente or eco == null or not LOJA.has(id) or n <= 0:
		return {"ok": false, "motivo": ""}
	if int(estoque.get(id, 0)) < n:
		return _recusa("sem_estoque")
	var custo := preco_pra_vila(id) * n
	if float(eco.credits) < custo:
		return _recusa("sem_dinheiro")
	if not eco.spend(custo, 0.0):
		return _recusa("sem_dinheiro")
	estoque[id] = int(estoque[id]) - n
	match String(LOJA[id].efeito):
		"item":
			eco.devolve(id, float(n))
		"semente":
			semente_ate_dia = maxi(semente_ate_dia, _dia()) + semente_dias * n
		"carne":
			eco.devolve("comida_crua", carne_comida * n)
	gasto_cr += custo
	comprados[id] = int(comprados.get(id, 0)) + n
	_depois("compra")
	return {"ok": true, "motivo": ultima_fala, "custo": custo}


## A vila vende `n` de `id` à caravana. {ok, motivo, ganho}.
func venda_pra_caravana(id: String, n: int) -> Dictionary:
	var eco := _eco()
	if not presente or eco == null or not preco_paga.has(id) or n <= 0:
		return {"ok": false, "motivo": ""}
	if int(demanda.get(id, 0)) < n:
		return _recusa("sem_demanda")
	if float(eco.livre(id)) < float(n):
		return _recusa("sem_item")
	eco.tira(id, float(n))
	var ganho := preco_da_vila(id) * n
	eco.ganha_creditos(ganho)
	demanda[id] = int(demanda[id]) - n
	vendido_cr += ganho
	vendidos[id] = int(vendidos.get(id, 0)) + n
	var ped := get_tree().get_first_node_in_group("pedidos")
	if ped and ped.has_method("registra_venda_caravana"):
		ped.registra_venda_caravana(id, n)
	_depois("venda")
	return {"ok": true, "motivo": ultima_fala, "ganho": ganho}


func _recusa(chave: String) -> Dictionary:
	ultima_fala = fala(chave)
	var a := get_node_or_null("/root/Audio")
	if a != null:
		a.error()
	mudou.emit()
	return {"ok": false, "motivo": ultima_fala}


func _depois(chave: String) -> void:
	ultima_fala = fala(chave)
	_negocia_t = 2.5
	if _comerciante != null and is_instance_valid(_comerciante):
		_comerciante.set("_work_timer", 2.5)  # a animação de negociar
	_som("caravana/moedas")
	mudou.emit()


## O que cabe vender de uma vez: o que a vila tem livre e o que ela ainda quer.
func maximo_venda(id: String) -> int:
	var eco := _eco()
	if eco == null:
		return 0
	return mini(int(demanda.get(id, 0)), int(floorf(float(eco.livre(id)))))


func maximo_compra(id: String) -> int:
	var eco := _eco()
	var p := preco_pra_vila(id)
	if eco == null or p <= 0.0:
		return 0
	return mini(int(estoque.get(id, 0)), int(floorf(float(eco.credits) / p)))


# ------------------------------------------------------------ encomendas (entram nos pedidos da vila)
func _abre_encomendas() -> void:
	var ped := get_tree().get_first_node_in_group("pedidos")
	if ped == null or not ped.has_method("abre_encomenda"):
		return
	var eco := _eco()
	var cand: Array = []
	for e in ENCOMENDAS:
		if eco != null and (float(eco.quantidade(String(e.id))) > 0.0 or String(e.id) == "barra_ferro"):
			cand.append(e)
	if cand.is_empty():
		cand = [ENCOMENDAS[0]]
	cand.shuffle()
	var n := 2 if visitas >= segunda_encomenda_visita else 1
	for i in mini(n, cand.size()):
		var e: Dictionary = cand[i]
		var meta := randi_range(int(e.min), int(e.max))
		var bonus := int(roundf(preco_base(String(e.id)) * meta * encomenda_bonus))
		ped.abre_encomenda(nome_comerciante, String(e.id), meta, parte_dia - 1, bonus)
		if i == 0:
			ultima_fala = fala("encomenda", {"item": Items.plural(String(e.id)), "meta": meta})


func _pedido_cumprido(p: Dictionary) -> void:
	if String(p.get("tipo", "")) == "caravana_encomenda":
		encomendas_cumpridas += 1
		ultima_fala = fala("encomenda_cumprida")
		mudou.emit()


# ------------------------------------------------------------ efeitos nos outros sistemas
## Modificadores: o pacote de sementes faz a horta crescer mais ("horta"). As outras chaves não são dela.
func mult(chave: String, _quem: Node = null) -> float:
	if chave == "horta" and semente_ate_dia >= _dia():
		return 1.0 + semente_bonus
	return 1.0


func _diario() -> void:
	var diary := get_tree().get_first_node_in_group("diary")
	if diary == null:
		return
	var id := "caravana_%d" % visitas
	diary.registra(id, "A caravana de %s" % nome_comerciante, "A caravana de %s ficou do dia %d ao dia %d. A vila vendeu %d cr em barras e gemas e gastou %d cr com ela. %s"
		% [nome_comerciante, chegou_dia, parte_dia, int(vendido_cr), int(gasto_cr), ultima_fala])
	diary.unlock(id, false)


## O Audio por caminho (os testes carregam este script antes dos autoloads).
func _som(id: String) -> void:
	var a := get_node_or_null("/root/Audio")
	if a != null and a.has_method("som_global"):
		a.som_global(id)


func estatisticas() -> Dictionary:
	return {"visitas": visitas, "vendido_cr": vendido_cr, "gasto_cr": gasto_cr, "encomendas": encomendas_cumpridas}


# ------------------------------------------------------------ save/load
func get_save_data() -> Dictionary:
	return {"presente": presente, "chegou_dia": chegou_dia, "parte_dia": parte_dia, "proxima_dia": proxima_dia, "visitas": visitas, "situacao": situacao,
		"estoque": estoque.duplicate(), "demanda": demanda.duplicate(), "preco_cobra": preco_cobra.duplicate(), "preco_paga": preco_paga.duplicate(),
		"semente_ate_dia": semente_ate_dia, "ultima_fala": ultima_fala, "avisou_sem_posto": _avisou_sem_posto, "vendido_cr": vendido_cr, "gasto_cr": gasto_cr,
		"vendidos": vendidos.duplicate(), "comprados": comprados.duplicate(), "encomendas_cumpridas": encomendas_cumpridas, "ligado": ligado}


func load_save_data(d: Dictionary) -> void:
	ligado = SaveUtil.boolean(d, "ligado", ligado)
	presente = SaveUtil.boolean(d, "presente", false)
	chegou_dia = SaveUtil.integer(d, "chegou_dia", 0)
	parte_dia = SaveUtil.integer(d, "parte_dia", 0)
	proxima_dia = SaveUtil.integer(d, "proxima_dia", -1)
	visitas = SaveUtil.integer(d, "visitas", 0)
	var sit := SaveUtil.text(d, "situacao", "normal")
	situacao = sit if SITUACOES.has(sit) else "normal"
	estoque = _numeros(SaveUtil.dict(d, "estoque"))
	demanda = _numeros(SaveUtil.dict(d, "demanda"))
	preco_cobra = _numeros(SaveUtil.dict(d, "preco_cobra"))
	preco_paga = _numeros(SaveUtil.dict(d, "preco_paga"))
	semente_ate_dia = SaveUtil.integer(d, "semente_ate_dia", 0)
	ultima_fala = SaveUtil.text(d, "ultima_fala", "")
	_avisou_sem_posto = SaveUtil.boolean(d, "avisou_sem_posto", false)
	vendido_cr = SaveUtil.num(d, "vendido_cr", 0.0)
	gasto_cr = SaveUtil.num(d, "gasto_cr", 0.0)
	vendidos = _numeros(SaveUtil.dict(d, "vendidos"))
	comprados = _numeros(SaveUtil.dict(d, "comprados"))
	encomendas_cumpridas = SaveUtil.integer(d, "encomendas_cumpridas", 0)
	_saindo = false
	if _comerciante != null and is_instance_valid(_comerciante):
		_comerciante.queue_free()
	_comerciante = null
	if presente and posto() == null:
		presente = false  # (o posto sumiu: a caravana já foi)
	if presente:
		_garante_comerciante.call_deferred()
	mudou.emit()


## Dicionário id -> número, só com valores de verdade (save quebrado vira vazio).
func _numeros(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		if typeof(src[k]) in [TYPE_INT, TYPE_FLOAT]:
			out[String(k)] = src[k]
	return out
