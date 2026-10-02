extends Node
## Bloco 42: EQUIPAMENTO (nó Equipment da cena principal, grupo "equipment").
##
## Um VESTIÁRIO comum da vila: casacos de inverno e trajes de perigo ficam aqui (cada
## peça com a sua durabilidade), os ipezinhos pegam e devolvem SOZINHOS, sem microgestão:
##   - Casaco: no inverno cada um pega um (ao ar livre, acordado, no nível da mina/clareira
##     ele gasta; lá embaixo é quente). Sem casaco no frio: trabalha bem mais devagar
##     (cold_work_mult), mas ninguém morre. Acabou o inverno, devolve.
##   - Trajes (máscara de gás, traje térmico, traje antirradiação): cada ZONA DE PERIGO do
##     fundo (hazard_zone.gd) só entra quem veste o traje certo. Veste na entrada, devolve na
##     saída, gasta só lá dentro (taxa própria por tipo). Quebrou lá dentro: sai na hora.
##     Sem traje no vestiário a ordem/entrada é bloqueada com aviso.
## Fabricar e consertar: na Oficina, numa fila que só anda com ENGENHEIRO (a Oficina chama
## pending()/work()). Mesmo padrão do Arsenal (Bloco 35): peça quebrada vai pra pilha de
## conserto; consertar custa repair_cost_mult do custo e repair_time_mult do tempo.
## Bloco 44: o VESTIÁRIO é um prédio (vestiario.gd), posicionado pelo jogador e erguido pelo
## engenheiro. Sem ele: a Oficina não faz equipamento e ninguém pega casaco/traje (o que já
## estava guardado continua contado, só volta a ser usado quando o Vestiário existir).
## Os trajes precisam da pesquisa "Trajes de proteção" (ramo Mina). Casaco é de couro
## (vem da caça, Bloco 42) + madeira + créditos.
## As zonas e as ferramentas antigas (lampião, traje de chumbo) são coisas separadas: a
## ferramenta continua liberando o minério pra todo mundo; o traje é o gate a mais da zona.

const SaveUtil := preload("res://scripts/core/save_util.gd")
const TYPES := ["casaco", "gas", "calor", "radiacao"]
const SUITS := ["gas", "calor", "radiacao"]
const NAMES := {
	"casaco": "Casaco de inverno",
	"gas": "Máscara de gás",
	"calor": "Traje térmico",
	"radiacao": "Traje antirradiação",
}
const ZONE_NAMES := {"gas": "Bolsão de gás", "calor": "Fenda de calor", "radiacao": "Veio radioativo"}
const VESTIARIO_SCENE := preload("res://scenes/props/vestiario.tscn")
const VESTIARIO_TEXTURE := preload("res://assets/game/vestiario.png")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const VESTIARIO_FOOTPRINT := Rect2(-42, -68, 84, 78)

@export_group("Casaco de inverno")
@export var coat_credits: int = 30
@export var coat_leather: int = 3
@export var coat_wood: int = 6
## Cada encomenda faz tantos casacos de uma vez.
@export var coat_batch: int = 3
## Segundos de engenheiro por encomenda.
@export var coat_time: float = 15.0
## Segundos de uso no frio até rasgar.
@export var coat_durability: float = 240.0
## Sem casaco, no inverno, no nível da mina/clareira: o trabalho rende isso (0.55 = 45% mais lento).
@export_range(0.1, 1.0) var cold_work_mult: float = 0.55

@export_group("Trajes de perigo (gás, calor, radiação)")
@export var suit_credits: Array[int] = [80, 90, 120]
@export var suit_ore: Array[int] = [20, 25, 15]
## Filtro de carvão na máscara, ferro no traje térmico, prata no antirradiação.
@export var suit_ore_type: Array[String] = ["carvao", "ferro", "prata"]
@export var suit_leather: Array[int] = [1, 2, 2]
@export var suit_time: Array[float] = [25.0, 30.0, 35.0]
## Segundos de exposição que cada traje aguenta...
@export var suit_durability: Array[float] = [180.0, 150.0, 120.0]
## ...gastos nessa taxa por segundo lá dentro (o calor e a radiação comem mais rápido).
@export var suit_wear_rate: Array[float] = [1.0, 1.3, 1.6]
## Pesquisa que libera os trajes ("" = sem pesquisa).
@export var suit_research: String = "trajes"

@export_group("Vestiário (Bloco 44)")
@export var vestiario_credits: int = 120
## Pedra (ferro) e madeira pra erguer o Vestiário.
@export var vestiario_ore: int = 30
@export var vestiario_wood: int = 50
@export var vestiario_build_time: float = 30.0

@export_group("Conserto e fila")
@export_range(0.1, 1.0) var repair_cost_mult: float = 0.4
@export_range(0.1, 1.0) var repair_time_mult: float = 0.5
@export var queue_max: int = 6

## Vestiário: tipo -> [durabilidade de cada peça guardada].
var pool: Dictionary = {}
## Peças quebradas esperando conserto (tipo -> qtd).
var broken: Dictionary = {}
## Fila da Oficina: [{what: "fazer"/"consertar", id, left, total, ordered_at}].
var queue: Array = []
var _winter_warned := -1


func _ready() -> void:
	add_to_group("equipment")
	for t in TYPES:
		pool[t] = []
		broken[t] = 0


# ------------------------------------------------------------ consultas
func max_durability(id: String) -> float:
	if id == "casaco":
		return coat_durability
	var i := SUITS.find(id)
	return suit_durability[i] if i >= 0 else 0.0


func wear_rate(id: String) -> float:
	var i := SUITS.find(id)
	return suit_wear_rate[i] if i >= 0 else 1.0


func available(id: String) -> int:
	return (pool.get(id, []) as Array).size()


## Dá pra pegar agora? (tem no estoque E o Vestiário existe)
func usable(id: String) -> int:
	return available(id) if vestiario() != null else 0


# ------------------------------------------------------------ o prédio (Bloco 44)
func vestiario() -> Node:
	return get_tree().get_first_node_in_group("vestiarios")


func vestiario_block_reason() -> String:
	if vestiario() != null:
		return "construído"
	var c := Canteiro.pending(get_tree(), "vestiario")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(vestiario_credits, vestiario_ore, "ferro", vestiario_wood) if eco else "sem recursos"


func build_vestiario() -> bool:
	if vestiario_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_vestiario, VESTIARIO_TEXTURE, 1, "o Vestiário", {"footprint": VESTIARIO_FOOTPRINT})
	return true


func _confirm_vestiario(pos: Vector2) -> bool:
	if vestiario_block_reason() != "":
		Audio.error()
		return false
	if not get_tree().get_first_node_in_group("economy").spend(vestiario_credits, vestiario_ore, "ferro", vestiario_wood):
		return false
	Canteiro.order(get_tree(), "vestiario", pos, vestiario_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Vestiário encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


## O canteiro terminou (canteiro.gd chama o dono do tipo).
func finish_build(kind: String, pos: Vector2) -> void:
	if kind != "vestiario" or vestiario() != null:
		return
	var v := spawn_vestiario(pos)
	v.pop_in()
	Audio.recruit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Vestiário pronto! Casacos e trajes ficam guardados aqui (Oficina, tecla O, faz).", Color(0.55, 1.0, 0.5))
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.wake_decision()


func spawn_vestiario(pos: Vector2) -> Node2D:
	var v: Node2D = VESTIARIO_SCENE.instantiate()
	v.name = "Vestiario"
	v.position = pos
	get_tree().get_first_node_in_group("village_hub").get_parent().add_child(v)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return v


func in_use(id: String) -> int:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.get("wearing") != null and w.wearing.has(id)).size()


func broken_count(id: String) -> int:
	return int(broken.get(id, 0))


func is_winter() -> bool:
	var sun := get_tree().get_first_node_in_group("sun")
	return sun != null and sun.season_index() == 3


## Frio que pede casaco: inverno, no nível da mina/clareira (o fundo é quente).
func is_cold_at(pos: Vector2) -> bool:
	if not is_winter():
		return false
	var env := get_tree().get_first_node_in_group("environment")
	return env == null or env.level_at(pos) == 0


## Tipo da zona de perigo nesse ponto ("" = nenhuma).
func hazard_at(pos: Vector2) -> String:
	for z in get_tree().get_nodes_in_group("zonas_perigo"):
		if z.contains(pos):
			return z.kind
	return ""


func zone_of(pos: Vector2) -> Node:
	for z in get_tree().get_nodes_in_group("zonas_perigo"):
		if z.contains(pos):
			return z
	return null


func recipe_unlocked(id: String) -> bool:
	if id == "casaco" or suit_research == "":
		return true
	var res := get_tree().get_first_node_in_group("research")
	return res != null and res.has(suit_research)


## Quem está no frio sem casaco agora (pro aviso).
func cold_without_coat() -> Array:
	if not is_winter():
		return []
	return get_tree().get_nodes_in_group("ipezinhos").filter(
		func(w): return not w.wearing.has("casaco") and not w.injured and not w.get("downed"))


# ------------------------------------------------------------ vestiário
## Pega a peça mais inteira (retorna a durabilidade; -1 = não tem ou sem Vestiário).
func take(id: String) -> float:
	if vestiario() == null:
		return -1.0
	var list: Array = pool.get(id, [])
	if list.is_empty():
		return -1.0
	list.sort()
	var v := vestiario()
	if v:
		Audio.equip((v as Node2D).global_position)  # Bloco 55
	return list.pop_back()


## Devolve (dur <= 0 = quebrou: vai pra pilha de conserto).
func give_back(id: String, dur: float) -> void:
	if dur <= 0.0:
		broken[id] = broken_count(id) + 1
	else:
		(pool[id] as Array).append(minf(dur, max_durability(id)))


# ------------------------------------------------------------ fabricar / consertar (Oficina)
## x créditos, y minério, z madeira, w couro.
func cost(id: String) -> Vector4i:
	if id == "casaco":
		return Vector4i(coat_credits, 0, coat_wood, coat_leather)
	var i := SUITS.find(id)
	return Vector4i(suit_credits[i], suit_ore[i], 0, suit_leather[i])


func ore_type(id: String) -> String:
	var i := SUITS.find(id)
	return suit_ore_type[i] if i >= 0 else ""


func repair_cost(id: String) -> Vector4i:
	var c := cost(id)
	return Vector4i(ceili(c.x * repair_cost_mult), ceili(c.y * repair_cost_mult), ceili(c.z * repair_cost_mult), ceili(c.w * repair_cost_mult))


func build_time(id: String) -> float:
	if id == "casaco":
		return coat_time
	return suit_time[SUITS.find(id)]


func cost_text(c: Vector4i, id: String) -> String:
	var bits: Array[String] = []
	if c.x > 0:
		bits.append("%d cr" % c.x)
	if c.y > 0:
		bits.append("%d %s" % [c.y, ore_type(id)])
	if c.z > 0:
		bits.append("%d madeira" % c.z)
	if c.w > 0:
		bits.append("%d couro" % c.w)
	return " + ".join(bits)


func leather_stored() -> float:
	var n := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		n += a.get("leather_stored") if a.get("leather_stored") != null else 0.0
	return n


func _missing(c: Vector4i, id: String) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return "sem recursos"
	var m: String = eco.missing_text(c.x, c.y, ore_type(id), c.z)
	if leather_stored() < c.w:
		var lt := "%d couro (caçador com arco)" % ceili(c.w - leather_stored())
		m = (m + ", " + lt) if m != "" else "falta " + lt
	return m


func _pay(c: Vector4i, id: String) -> bool:
	if _missing(c, id) != "":
		return false
	if not get_tree().get_first_node_in_group("economy").spend(c.x, c.y, ore_type(id), c.z):
		return false
	var left := float(c.w)
	for a in get_tree().get_nodes_in_group("armazens"):
		var got := minf(left, a.leather_stored)
		a.leather_stored -= got
		left -= got
	return true


func order_block_reason(id: String) -> String:
	if vestiario() == null:
		return "precisa do Vestiário (onde guardar)"
	if not recipe_unlocked(id):
		return "precisa pesquisar: Trajes de proteção"
	if get_tree().get_first_node_in_group("oficina") == null:
		return "sem Oficina"
	if queue.size() >= queue_max:
		return "fila da Oficina cheia"
	return _missing(cost(id), id)


func repair_block_reason(id: String) -> String:
	if vestiario() == null:
		return "precisa do Vestiário"
	if broken_count(id) <= 0:
		return "nenhum quebrado"
	if queue.size() >= queue_max:
		return "fila da Oficina cheia"
	return _missing(repair_cost(id), id)


func order(id: String) -> bool:
	if order_block_reason(id) != "" or not _pay(cost(id), id):
		Audio.error()
		return false
	_enqueue("fazer", id, build_time(id))
	return true


func repair(id: String) -> bool:
	if repair_block_reason(id) != "" or not _pay(repair_cost(id), id):
		Audio.error()
		return false
	broken[id] = broken_count(id) - 1
	_enqueue("consertar", id, build_time(id) * repair_time_mult)
	return true


func _enqueue(what: String, id: String, seconds: float) -> void:
	var t := maxf(seconds, 1.0)
	queue.append({"what": what, "id": id, "left": t, "total": t, "ordered_at": Time.get_unix_time_from_system()})
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s: %s — na fila da Oficina, precisa de engenheiro (tecla 4)." % [
			"Fazer" if what == "fazer" else "Consertar", NAMES[id]], Color(1.0, 0.8, 0.45))


## A Oficina pergunta: tem equipamento na fila?
func pending() -> bool:
	return not queue.is_empty()


func title() -> String:
	if queue.is_empty():
		return ""
	var o: Dictionary = queue[0]
	var n := coat_batch if o.id == "casaco" and o.what == "fazer" else 1
	return "%s: %s%s" % ["Fazer" if o.what == "fazer" else "Consertar", NAMES[o.id], " x%d" % n if n > 1 else ""]


func progress() -> float:
	if queue.is_empty():
		return 0.0
	var o: Dictionary = queue[0]
	return clampf(1.0 - float(o.left) / float(o.total), 0.0, 1.0)


func ordered_at() -> float:
	return float(queue[0].ordered_at) if not queue.is_empty() else 0.0


## O engenheiro trabalhou na Oficina: só assim a fila anda.
func work(seconds: float) -> void:
	if queue.is_empty():
		return
	var o: Dictionary = queue[0]
	o.left = float(o.left) - seconds
	if o.left > 0.0:
		return
	queue.pop_front()
	var n: int = coat_batch if o.id == "casaco" and o.what == "fazer" else 1
	for i in n:
		(pool[o.id] as Array).append(max_durability(o.id))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s %s: %d no vestiário agora." % [NAMES[o.id], "pronto" if o.what == "fazer" else "consertado", available(o.id)],
			Color(0.55, 1.0, 0.5))
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.wake_decision()


# ------------------------------------------------------------ aviso do inverno
func _process(_delta: float) -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn == null or not is_winter() or _winter_warned == dn.day:
		return
	_winter_warned = dn.day
	var missing := get_tree().get_nodes_in_group("ipezinhos").size() - (usable("casaco") + in_use("casaco"))
	if missing > 0:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast(("Inverno: faltam %d casaco%s — sem casaco trabalham bem mais devagar (Oficina, tecla O)." % [
				missing, "s" if missing > 1 else ""]) if vestiario() != null else
				"Inverno e a vila não tem Vestiário: ninguém tem casaco (construa pela Oficina, tecla O).", Color(0.7, 0.85, 1.0))


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var d := {"pool": pool.duplicate(true), "broken": broken.duplicate(), "queue": queue.duplicate(true), "winter_warned": _winter_warned}
	var v := vestiario()
	if v:
		d["vestiario"] = SaveUtil.vec2_to_array(v.global_position)  # Bloco 44
	return d


func load_save_data(d: Dictionary) -> void:
	var p := SaveUtil.dict(d, "pool")
	var b := SaveUtil.dict(d, "broken")
	for t in TYPES:
		var list: Array = []
		for v in SaveUtil.array(p, t):
			if v is float or v is int:
				list.append(clampf(float(v), 0.1, max_durability(t)))
		pool[t] = list
		broken[t] = maxi(int(SaveUtil.num(b, t, 0.0)), 0)
	queue = []
	for o in SaveUtil.array(d, "queue"):
		if typeof(o) != TYPE_DICTIONARY:
			continue
		var id := SaveUtil.text(o, "id", "")
		var what := SaveUtil.text(o, "what", "fazer")
		if id not in TYPES or what not in ["fazer", "consertar"]:
			continue
		var total := maxf(SaveUtil.num(o, "total", build_time(id)), 1.0)
		queue.append({"what": what, "id": id, "total": total, "left": clampf(SaveUtil.num(o, "left", total), 0.0, total),
			"ordered_at": SaveUtil.num(o, "ordered_at", 0.0)})
	_winter_warned = SaveUtil.integer(d, "winter_warned", -1)
	# Bloco 44 (save antigo: sem Vestiário)
	var v := vestiario()
	if v:
		v.get_parent().remove_child(v)
		v.queue_free()
	var pos := SaveUtil.vec2(d, "vestiario", Vector2.INF)
	if pos != Vector2.INF:
		spawn_vestiario(pos)
