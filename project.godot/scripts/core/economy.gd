extends Node
## Economia do protótipo: vender minério armazenado por créditos e recrutar ipezinhos.
## Fica no nó "Economy" da cena principal (grupo "economy") — ajuste os números no Inspector.
##
## Bloco 39: vender também pela janela do Armazém (clique nele), tudo ou um tipo só
## (sell). Recrutar exige CAMA LIVRE nas casas prontas (recruit_needs_bed) além do
## limite de ipezinhos e dos créditos; bloqueado, avisa o motivo e não gasta nada
## (recruit_block_reason). O recrutado chega na frente do Centro da Vila.
##
## Bloco 82: catálogo de itens (items.gd). quantidade(id) soma qualquer item em todos os armazéns (minério,
## madeira, matéria-prima, couro, peças raras, processados); add_item/take_item guardam e tiram os
## processados (barras, prego...); sell(id) vende qualquer item com preço (minério ou processado);
## sell_categoria(cat) vende uma categoria inteira. "Vender tudo" (sell_all) continua sendo todo o MINÉRIO.

signal credits_changed(credits: float)

const Ores := preload("res://scripts/core/ores.gd")
const Items := preload("res://scripts/core/items.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
signal ore_sold(amount: float, earned: float)
signal worker_recruited(worker: Node2D, cost: int)

@export_group("Venda")
## Créditos por unidade de ferro.
@export var ore_price: float = 2.0
## Créditos por unidade de cobre.
@export var copper_price: float = 4.0
## Créditos por unidade de carvão.
@export var coal_price: float = 3.0
## Créditos por unidade de prata (nível 2: mais perigoso, paga mais).
@export var silver_price: float = 8.0
## Créditos por unidade de solarita (nível 3, o abismo).
@export var solarita_price: float = 14.0
## Bloco 70: cristal verde (S2, galerias de ácido) e cristal rubro (S3, poços de lava).
@export var cristal_verde_price: float = 10.0
@export var cristal_rubro_price: float = 18.0
## Bloco 71: gema azul (S5, a beira do lago).
@export var gema_azul_price: float = 30.0
## Bloco 82: troca o preço de venda (créditos por unidade) de itens do catálogo que não são minério, ex.:
## {"barra_ferro": 10.0}. Vazio = o preço base do items.gd. Preço 0 = não se vende.
@export var precos_itens: Dictionary = {}
@export var starting_credits: float = 0.0

@export_group("Metal: custos em barra (Bloco 87)")
## Nos custos MIGRADOS pra barra (armas, ampliação das barricadas, peças da Escavadeira, reatores, coletores,
## laboratório): quantos minérios valem UMA barra. Os campos de custo continuam em minério; a partir do
## estágio da fornalha (centro_vila.fornalha_estagio) o jogo pede ceil(minério / isto) barras do tipo.
@export var minerios_por_barra: float = 2.0
## Vende sozinho o que estiver no armazém a cada auto_sell_interval segundos.
@export var auto_sell: bool = false
@export var auto_sell_interval: float = 4.0

@export_group("Recrutamento")
@export var worker_scene: PackedScene
@export var recruit_base_cost: float = 150.0
## Multiplica o custo a cada ipezinho recrutado (1.5 = +50%).
@export var recruit_cost_growth: float = 1.5
## Limite inicial; a melhoria "Moradias" do Centro da Vila aumenta.
@export var max_workers: int = 8
## Nó onde os novos ipezinhos são criados (precisa ser o nó com y-sort).
@export var spawn_parent: NodePath = ^"../World"
## Bloco 39: só recruta se tiver cama livre numa casa pronta (sem cama = sem lugar pra morar).
@export var recruit_needs_bed: bool = true

@export_group("Prédios extras (Bloco 47)")
## Cada unidade a mais do mesmo prédio custa isso vezes a anterior (1.5 = +50%; 1.0 = sempre
## o mesmo preço). Vale pra Laboratório, Arsenal, Campo de treino, Taverna, Coletor de madeira
## e Enfermaria extra. (Casas, comedouros e parques seguem com o preço de sempre.)
@export var extra_building_cost_growth: float = 1.5

var credits: float = 0.0
var recruited_count: int = 0
var total_earned: float = 0.0
var _auto_timer: float = 0.0


func _ready() -> void:
	add_to_group("economy")
	credits = starting_credits


func _process(delta: float) -> void:
	if not auto_sell:
		return
	_auto_timer -= delta
	if _auto_timer <= 0.0:
		_auto_timer = auto_sell_interval
		if stored_ore() >= 1.0:
			sell_all()


# ------------------------------------------------------------ venda
## Minério guardado nos armazéns: de um tipo, ou de todos com ore_type = "".
func stored_ore(ore_type: String = "") -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		if ore_type == "":
			total += a.total_stored
		else:
			total += a.stock.get(ore_type, 0.0)
	return total


func price_of(ore_type: String) -> float:
	if not Ores.TYPES.has(ore_type) and Items.existe(ore_type):  # Bloco 82: itens do catálogo
		return float(precos_itens.get(ore_type, Items.preco_base(ore_type)))
	match ore_type:
		"cobre":
			return copper_price
		"carvao":
			return coal_price
		"prata":
			return silver_price
		"solarita":
			return solarita_price
		"cristal_verde":
			return cristal_verde_price
		"cristal_rubro":
			return cristal_rubro_price
		"gema_azul":
			return gema_azul_price
	return ore_price


func sale_value() -> int:
	var value := 0.0
	for t in Ores.TYPES:
		value += floorf(stored_ore(t)) * price_of(t)
	return int(value)


## Bloco 39: vende um tipo só ("" = tudo). Retorna os créditos ganhos.
## Bloco 82: também qualquer item processado com preço (barra, prego...).
func sell(ore_type: String = "") -> float:
	if ore_type == "":
		return sell_all()
	if not Ores.TYPES.has(ore_type):
		return _sell_item(ore_type)
	var sold := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		var amount := floorf(a.stock.get(ore_type, 0.0))
		if amount < 1.0:
			continue
		var got: float = a.take(amount, ore_type)
		sold += got
		if got > 0.0:
			a.show_popup("+%d cr" % int(got * price_of(ore_type)), Color(0.55, 1.0, 0.5))
	if sold <= 0.0:
		return 0.0
	var earned := sold * price_of(ore_type)
	_add_credits(earned)
	total_earned += earned
	ore_sold.emit(sold, earned)
	Audio.sell()
	return earned


# ------------------------------------------------------------ metal (Bloco 87)
## A barra de cada minério ("" = minério qualquer: barra de ferro).
const BARRA_DO_MINERIO := {"": "barra_ferro", "ferro": "barra_ferro", "cobre": "barra_cobre", "prata": "barra_prata",
	"solarita": "lingote_solar"}


## A partir do estágio da fornalha os custos migrados pedem BARRA; antes, minério bruto (não trava o começo).
func pede_barras() -> bool:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return hub != null and hub.get("fornalha_estagio") != null and int(hub.level) >= int(hub.fornalha_estagio)


## O metal de verdade de um custo migrado: [item, quantidade] — barra a partir do estágio da fornalha;
## senão o próprio minério. Quantidade 0 = sem metal.
func metal(qtd_minerio: float, tipo: String) -> Array:
	if qtd_minerio <= 0.0:
		return ["", 0.0]
	if pede_barras() and BARRA_DO_MINERIO.has(tipo):
		return [BARRA_DO_MINERIO[tipo], ceilf(qtd_minerio / maxf(minerios_por_barra, 0.01))]
	return [tipo, qtd_minerio]


## "20 barras de ferro" / "40 ferro" / "40 minério" (vazio = sem metal).
func metal_texto(qtd_minerio: float, tipo: String) -> String:
	var m := metal(qtd_minerio, tipo)
	if m[1] <= 0.0:
		return ""
	if Items.onde(m[0]) == "itens":
		return "%d %s" % [int(m[1]), Items.plural(m[0])]
	return "%d %s" % [int(m[1]), Ores.display_name(tipo).to_lower() if tipo != "" else "minério"]


## Custo completo pra mostrar: "150 cr + 20 barras de ferro + 20 madeira".
func custo_metal_texto(cr: float, qtd_minerio: float, tipo: String, madeira: float = 0.0) -> String:
	var bits: Array[String] = []
	if cr > 0.0:
		bits.append("%d cr" % int(cr))
	var mt := metal_texto(qtd_minerio, tipo)
	if mt != "":
		bits.append(mt)
	if madeira > 0.0:
		bits.append("%d madeira" % int(madeira))
	return " + ".join(bits)


## "" se dá pra pagar créditos + o metal + madeira; senão "falta ...".
func metal_falta(cr: float, qtd_minerio: float, tipo: String, madeira: float = 0.0) -> String:
	var m := metal(qtd_minerio, tipo)
	if Items.onde(m[0]) != "itens":
		return missing_text(cr, qtd_minerio, tipo, madeira)
	var parts: Array[String] = []
	if credits < cr:
		parts.append("%d cr" % ceili(cr - credits))
	var tem := quantidade(m[0])
	if tem < m[1]:
		parts.append("%d %s" % [ceili(m[1] - tem), Items.plural(m[0])])
	var have_wood := stored_wood()
	if have_wood < madeira:
		parts.append("%d madeira" % ceili(madeira - have_wood))
	return "" if parts.is_empty() else "falta " + ", ".join(parts)


## Paga créditos + o metal (barra ou minério, pela regra de cima) + madeira. false = não deu (nada gasto).
func paga_metal(cr: float, qtd_minerio: float, tipo: String, madeira: float = 0.0) -> bool:
	var m := metal(qtd_minerio, tipo)
	if Items.onde(m[0]) != "itens":
		return spend(cr, qtd_minerio, tipo, madeira)
	if metal_falta(cr, qtd_minerio, tipo, madeira) != "":
		Audio.error()
		return false
	if cr > 0.0:
		_add_credits(-cr)
	var wood_left := madeira
	for a in get_tree().get_nodes_in_group("armazens"):
		if wood_left <= 0.0:
			break
		wood_left -= a.take_wood(wood_left)
	take_item(m[0], m[1])
	return true


## Bloco 82: vende um item processado (todas as unidades inteiras, de todos os armazéns).
func _sell_item(id: String) -> float:
	if Items.onde(id) != "itens" or price_of(id) <= 0.0:
		return 0.0
	var sold := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		var amount := floorf(a.item_count(id))
		if amount < 1.0:
			continue
		var got: float = a.take_item(id, amount)
		sold += got
		if got > 0.0:
			a.show_popup("+%d cr" % int(got * price_of(id)), Color(0.55, 1.0, 0.5))
	if sold <= 0.0:
		return 0.0
	var earned := sold * price_of(id)
	_add_credits(earned)
	total_earned += earned
	ore_sold.emit(sold, earned)
	Audio.sell()
	return earned


## Bloco 82: vende tudo o que tem preço numa categoria ("minerio" = sell_all). Retorna os créditos.
func sell_categoria(cat: String) -> float:
	if cat == "minerio":
		return sell_all()
	var earned := 0.0
	for id in Items.da_categoria(cat):
		if pode_vender(id):
			earned += _sell_item(id)
	return earned


## Bloco 82: esse item se vende? (minério sempre; o resto, se for processado e tiver preço)
func pode_vender(id: String) -> bool:
	if Ores.TYPES.has(id):
		return true
	return Items.onde(id) == "itens" and price_of(id) > 0.0


## Bloco 82: quanto valem as unidades inteiras de um item (0 se não se vende).
func valor_de(id: String) -> int:
	return int(floorf(quantidade(id)) * price_of(id)) if pode_vender(id) else 0


## Bloco 82: quanto a vila tem de um item do catálogo (soma dos armazéns; peças raras: Finds).
func quantidade(id: String) -> float:
	match Items.onde(id):
		"stock":
			return stored_ore(id)
		"madeira":
			return stored_wood()
		"materia_prima":
			return _soma_armazens("raw_stored")
		"couro":
			return _soma_armazens("leather_stored")
		"pecas_raras":
			var finds := get_tree().get_first_node_in_group("finds")
			return float(finds.rare_parts) if finds else 0.0
		"itens":
			var total := 0.0
			for a in get_tree().get_nodes_in_group("armazens"):
				total += a.item_count(id)
			return total
	return stored_ore(id) if Ores.TYPES.has(id) else 0.0


func _soma_armazens(campo: String) -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		var v = a.get(campo)
		total += float(v) if v != null else 0.0
	return total


## Bloco 82: guarda um item processado no armazém mais perto de `perto` (sem ponto: o primeiro).
func add_item(id: String, amount: float, perto: Vector2 = Vector2.INF) -> bool:
	if Items.onde(id) != "itens" or amount <= 0.0:
		return false
	var best: Node2D = null
	var best_d := INF
	for a in get_tree().get_nodes_in_group("armazens"):
		var d: float = 0.0 if perto == Vector2.INF else perto.distance_to(a.global_position)
		if best == null or d < best_d:
			best = a
			best_d = d
	if best == null:
		return false
	best.add_item(id, amount)
	return true


## Bloco 82: tira até `amount` de um item processado, de todos os armazéns. Retorna quanto saiu.
func take_item(id: String, amount: float) -> float:
	var left := amount
	for a in get_tree().get_nodes_in_group("armazens"):
		if left <= 0.0:
			break
		left -= a.take_item(id, left)
	return amount - left


func sell_all() -> float:
	var sold := 0.0
	var earned := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		var taken: Dictionary = a.take_all()
		var value := 0.0
		for t in taken:
			sold += taken[t]
			value += taken[t] * price_of(t)
		if value > 0.0:
			a.show_popup("+%d cr" % int(value), Color(0.55, 1.0, 0.5))
		earned += value
	if sold <= 0.0:
		return 0.0
	_add_credits(earned)
	total_earned += earned
	ore_sold.emit(sold, earned)
	Audio.sell()
	return earned


# ------------------------------------------------------------ gastos (Centro da Vila)
## Madeira guardada nos armazéns (não é minério: não vende nem conta nos custos de "minério").
func stored_wood() -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.wood_stored
	return total


## ore_type = "" aceita qualquer minério (custos genéricos do Centro da Vila e da escavadeira).
func can_afford(cost_credits: float, cost_ore: float, ore_type: String = "", cost_wood: float = 0.0) -> bool:
	return credits >= cost_credits and stored_ore(ore_type) >= cost_ore and stored_wood() >= cost_wood


## "" se dá pra pagar; senão "falta 12 madeira, 30 ferro" (aviso pros botões).
## ore_label troca o nome do minério no texto (ex.: "pedra (ferro)" nas casas).
func missing_text(cost_credits: float, cost_ore: float, ore_type: String = "", cost_wood: float = 0.0, ore_label: String = "") -> String:
	var parts: Array[String] = []
	if credits < cost_credits:
		parts.append("%d cr" % ceili(cost_credits - credits))
	var have_ore := stored_ore(ore_type)
	if have_ore < cost_ore:
		var label := ore_label
		if label == "":
			label = "minério" if ore_type == "" else Ores.display_name(ore_type).to_lower()
		parts.append("%d %s" % [ceili(cost_ore - have_ore), label])
	var have_wood := stored_wood()
	if have_wood < cost_wood:
		parts.append("%d madeira" % ceili(cost_wood - have_wood))
	return "" if parts.is_empty() else "falta " + ", ".join(parts)


## Paga em créditos + minério (+ madeira) do armazém. Retorna false (e não gasta nada) se não der.
## Com ore_type = "", gasta primeiro o minério mais barato.
func spend(cost_credits: float, cost_ore: float, ore_type: String = "", cost_wood: float = 0.0) -> bool:
	if not can_afford(cost_credits, cost_ore, ore_type, cost_wood):
		Audio.error()
		return false
	if cost_credits > 0.0:
		_add_credits(-cost_credits)
	var wood_left := cost_wood
	for a in get_tree().get_nodes_in_group("armazens"):
		if wood_left <= 0.0:
			break
		wood_left -= a.take_wood(wood_left)
	var types: Array = [ore_type]
	if ore_type == "":
		types = Ores.TYPES.duplicate()
		types.sort_custom(func(a, b): return price_of(a) < price_of(b))
	var left := cost_ore
	for t in types:
		for a in get_tree().get_nodes_in_group("armazens"):
			if left <= 0.0:
				break
			left -= a.take(left, t)
	return true


## Bloco 47: custo da PRÓXIMA unidade de um prédio que já tem `existing` na vila.
## base/retorno = (créditos, minério, madeira).
func scaled_cost(base: Vector3i, existing: int) -> Vector3i:
	var m := pow(maxf(extra_building_cost_growth, 0.0), maxi(existing, 0))
	return Vector3i(roundi(base.x * m), roundi(base.y * m), roundi(base.z * m))


## "300 cr + 80 ferro + 60 madeira" (pula o que for zero).
static func cost_text(c: Vector3i, ore_label: String = "minério") -> String:
	var parts: Array[String] = []
	if c.x > 0:
		parts.append("%d cr" % c.x)
	if c.y > 0:
		parts.append("%d %s" % [c.y, ore_label])
	if c.z > 0:
		parts.append("%d madeira" % c.z)
	return " + ".join(parts)


func _add_credits(amount: float) -> void:
	credits += amount
	credits_changed.emit(credits)


# ------------------------------------------------------------ recrutamento
func worker_count() -> int:
	return get_tree().get_nodes_in_group("ipezinhos").size()


func recruit_cost() -> int:
	return int(round(recruit_base_cost * pow(recruit_cost_growth, recruited_count)))


## Camas das casas PRONTAS que ninguém ocupa (cada ipezinho precisa de uma).
func free_beds() -> int:
	var total := 0
	for casa in get_tree().get_nodes_in_group("casas"):
		if casa.has_method("beds_total"):
			total += casa.beds_total()
	return total - worker_count()


## "" = pode recrutar; senão o motivo (limite, cama, créditos — nessa ordem).
func recruit_block_reason() -> String:
	if worker_scene == null:
		return "sem ipezinho pra recrutar"
	if worker_count() >= max_workers:
		return "limite de ipezinhos (Moradias aumenta)"
	if recruit_needs_bed and free_beds() <= 0:
		return "sem cama livre — construa uma casa"
	if credits < recruit_cost():
		return "falta %d cr" % ceili(recruit_cost() - credits)
	return ""


func can_recruit() -> bool:
	return recruit_block_reason() == ""


func recruit() -> Node2D:
	var reason := recruit_block_reason()
	if reason != "":
		Audio.error()
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("Não dá pra recrutar: %s." % reason, Color(1.0, 0.55, 0.4))
		return null
	var cost := recruit_cost()
	var parent := get_node_or_null(spawn_parent)
	if parent == null:
		push_warning("Economy: spawn_parent não encontrado")
		return null

	var worker := worker_scene.instantiate() as Node2D
	worker.name = _next_worker_name()
	worker.position = _spawn_position()
	parent.add_child(worker)

	_add_credits(-cost)
	recruited_count += 1
	worker_recruited.emit(worker, cost)
	Audio.recruit()
	return worker


## Colono que chega de graça (satélite de comunicação). Respeita o limite de ipezinhos
## e não encarece o próximo recrutamento. Retorna null se não tiver vaga.
func recruit_free() -> Node2D:
	if worker_scene == null or worker_count() >= max_workers:
		return null
	var parent := get_node_or_null(spawn_parent)
	if parent == null:
		return null
	var worker := worker_scene.instantiate() as Node2D
	worker.name = _next_worker_name()
	worker.position = _spawn_position()
	parent.add_child(worker)
	Audio.recruit()
	return worker


## Bloco 39: o recrutado chega na frente do Centro da Vila (sem Centro: perto do armazém).
func _spawn_position() -> Vector2:
	var hub: Node2D = get_tree().get_first_node_in_group("village_hub")
	if hub:
		return hub.global_position + Vector2(randf_range(-50.0, 50.0), randf_range(40.0, 70.0))
	var armazem: Node2D = get_tree().get_first_node_in_group("armazens")
	var base := armazem.global_position if armazem else Vector2.ZERO
	return base + Vector2(randf_range(-50.0, 50.0), randf_range(70.0, 95.0))


func _next_worker_name() -> String:
	var n := worker_count() + 1
	var parent := get_node_or_null(spawn_parent)
	while parent and parent.has_node("Ipezinho%d" % n):
		n += 1
	return "Ipezinho%d" % n


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {
		"credits": credits,
		"recruited_count": recruited_count,
		"total_earned": total_earned,
		"max_workers": max_workers,
		"auto_sell": auto_sell,
	}


func load_save_data(d: Dictionary) -> void:
	credits = maxf(SaveUtil.num(d, "credits", credits), 0.0)
	recruited_count = maxi(SaveUtil.integer(d, "recruited_count", recruited_count), 0)
	total_earned = SaveUtil.num(d, "total_earned", total_earned)
	max_workers = maxi(SaveUtil.integer(d, "max_workers", max_workers), 1)
	auto_sell = SaveUtil.boolean(d, "auto_sell", auto_sell)
	credits_changed.emit(credits)
