extends Node
## Economia do protótipo: vender minério armazenado por créditos. (Bloco 101: acabou o "Recrutar"; quem chega são os
## migrantes, migrantes.gd, e a capacidade da vila são as camas livres: free_beds.)
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

const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96
const Ores := preload("res://scripts/core/ores.gd")
const Items := preload("res://scripts/core/items.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
signal ore_sold(amount: float, earned: float)

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
## Bloco 102: créditos por unidade de minério desconhecido (de jazida que o catálogo ainda não estudou).
@export var desconhecido_price: float = 1.0
## Bloco 82: troca o preço de venda (créditos por unidade) de itens do catálogo que não são minério, ex.:
## {"barra_ferro": 10.0}. Vazio = o preço base do items.gd. Preço 0 = não se vende.
@export var precos_itens: Dictionary = {}
@export var starting_credits: float = 0.0

@export_group("Metal: custos em barra (Bloco 87)")
## Nos custos MIGRADOS pra barra (armas, ampliação das barricadas, peças da Escavadeira, reatores, coletores,
## laboratório): quantos minérios valem UMA barra. Os campos de custo continuam em minério; a partir do
## estágio da fornalha (centro_vila.fornalha_estagio) o jogo pede ceil(minério / isto) barras do tipo.
@export var minerios_por_barra: float = 2.0

@export_group("Peças nos custos (Bloco 94)")
## Pregos e ferragens só entram nos custos A PARTIR do estágio da fornalha (é o ferreiro que faz). Antes, cada
## peça vira o minério (ferro) que ela custaria — o custo fica como era e nada trava no começo.
## Ferro por prego (1 barra = 2 ferro dá 6 pregos).
@export var ferro_por_prego: float = 0.34
## Ferro por ferragem (2 barras + 4 pregos).
@export var ferro_por_ferragem: float = 6.7
## Vende sozinho o que estiver no armazém a cada auto_sell_interval segundos.
@export var auto_sell: bool = false
@export var auto_sell_interval: float = 4.0

@export_group("Ritmo da coleta (Bloco 106)")
## Multiplica o ritmo de extração de TODA jazida (o MINE_RATE, minério por segundo com o mineiro batendo; cada jazida
## guarda o dela). 1 = o de antes do Bloco 106. A telemetria do Bloco 106 mediu ~27 minério por hora de jogo por mineiro:
## 4 mineradores enchiam os 400 do armazém em ~2,5 h de jogo (~1 min real). O minério era a única coleta acima do
## necessário (madeira ~5/h por lenhador e comida ~6/h por caçador ficaram como estavam).
@export var ritmo_mineracao: float = 0.045

@export_group("Ipezinhos")
## A cena do ipezinho (a Fundação e os migrantes nascem daqui).
@export var worker_scene: PackedScene
## Bloco 101: NÃO manda mais em nada (a capacidade são as camas); fica só pra o save antigo não estranhar.
var max_workers: int = 8
## Nó onde os novos ipezinhos são criados (precisa ser o nó com y-sort).
@export var spawn_parent: NodePath = ^"../World"

@export_group("Prédios extras (Bloco 47)")
## Cada unidade a mais do mesmo prédio custa isso vezes a anterior (1.5 = +50%; 1.0 = sempre
## o mesmo preço). Vale pra Laboratório, Arsenal, Campo de treino, Taverna, Coletor de madeira
## e Enfermaria extra. (Casas, comedouros e parques seguem com o preço de sempre.)
@export var extra_building_cost_growth: float = 1.5

@export_group("Obras com material (Bloco 96)")
## Liga as obras com material: na encomenda o material fica RESERVADO no armazém e o engenheiro leva (desligado =
## como antes: tudo sai do armazém na hora). Serve também pra medir o antes e o depois (tests/bench_obras.gd).
@export var obras_com_material: bool = true

var credits: float = 0.0
var recruited_count: int = 0
var total_earned: float = 0.0
var _auto_timer: float = 0.0
## Bloco 96: o RECIBO dos pagamentos deste quadro: [armazém, item, qtd] tirados e os créditos. A obra que
## nasce no mesmo quadro (ObraSite.start) pega o recibo: o material volta pro armazém como reserva dela.
var _recibo: Array = []
var _recibo_cr := 0.0
var _recibo_quadro := -1
var _reserva_cache := {}
var _reserva_quadro := -1


func _ready() -> void:
	add_to_group("economy")
	credits = starting_credits


func _process(delta: float) -> void:
	if not auto_sell:
		return
	_auto_timer -= delta
	if _auto_timer <= 0.0:
		_auto_timer = auto_sell_interval
		if sale_value() > 0:  # Bloco 96: o reservado pras obras não vende
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
		"desconhecido":
			return desconhecido_price  # Bloco 102
	return ore_price


func sale_value() -> int:
	var value := 0.0
	for t in Ores.TYPES:
		value += floorf(livre(t)) * price_of(t)  # Bloco 96: sem o reservado pras obras
	return int(value)


## Bloco 39: vende um tipo só ("" = tudo). Retorna os créditos ganhos.
## Bloco 82: também qualquer item processado com preço (barra, prego...). `quantidade` (unidades inteiras)
## vende só isso, tirando dos armazéns um atrás do outro; < 0 = tudo o que tem.
func sell(ore_type: String = "", quantidade: float = -1.0) -> float:
	if ore_type == "":
		return sell_all()
	if not Ores.TYPES.has(ore_type):
		return _sell_item(ore_type, quantidade)
	var sold := 0.0
	var resta := minf(floorf(quantidade) if quantidade >= 0.0 else INF, floorf(livre(ore_type)))  # Bloco 96: não o reservado
	for a in get_tree().get_nodes_in_group("armazens"):
		var amount := minf(floorf(a.stock.get(ore_type, 0.0)), resta - sold)
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


## Custo completo pra mostrar: "150 cr + 20 barras de ferro + 20 madeira + 12 pregos".
## Bloco 94: `itens` = peças e materiais a mais ({prego: 12, aco: 6}); antes da fornalha, pregos e ferragens
## viram ferro (itens_efetivos).
func custo_metal_texto(cr: float, qtd_minerio: float, tipo: String, madeira: float = 0.0, itens: Dictionary = {}) -> String:
	var ef := itens_efetivos(itens)
	qtd_minerio += float(ef.minerio)
	var bits: Array[String] = []
	if cr > 0.0:
		bits.append("%d cr" % int(cr))
	var mt := metal_texto(qtd_minerio, tipo)
	if mt != "":
		bits.append(mt)
	if madeira > 0.0:
		bits.append("%d madeira" % int(madeira))
	var it := itens_texto(ef.itens)
	if it != "":
		bits.append(it)
	return " + ".join(bits)


## "" se dá pra pagar créditos + o metal + madeira (+ itens, Bloco 94); senão "falta ...".
func metal_falta(cr: float, qtd_minerio: float, tipo: String, madeira: float = 0.0, itens: Dictionary = {}) -> String:
	var ef := itens_efetivos(itens)
	qtd_minerio += float(ef.minerio)
	var m := metal(qtd_minerio, tipo)
	if Items.onde(m[0]) != "itens":
		return _junta_falta(missing_text(cr, qtd_minerio, tipo, madeira), itens_falta(ef.itens))
	var parts: Array[String] = []
	if credits < cr:
		parts.append("%d cr" % ceili(cr - credits))
	var tem := livre(m[0])  # Bloco 96
	if tem < m[1]:
		parts.append("%d %s" % [ceili(m[1] - tem), Items.plural(m[0])])
	var have_wood := livre("madeira")
	if have_wood < madeira:
		parts.append("%d madeira" % ceili(madeira - have_wood))
	return _junta_falta("" if parts.is_empty() else "falta " + ", ".join(parts), itens_falta(ef.itens))


## Paga créditos + o metal (barra ou minério, pela regra de cima) + madeira (+ itens, Bloco 94). false = não deu
## (nada gasto).
func paga_metal(cr: float, qtd_minerio: float, tipo: String, madeira: float = 0.0, itens: Dictionary = {}) -> bool:
	if metal_falta(cr, qtd_minerio, tipo, madeira, itens) != "":
		Audio.error()
		return false
	var ef := itens_efetivos(itens)
	qtd_minerio += float(ef.minerio)
	paga_itens(ef.itens)
	var m := metal(qtd_minerio, tipo)
	if Items.onde(m[0]) != "itens":
		return spend(cr, qtd_minerio, tipo, madeira)
	if cr > 0.0:
		_add_credits(-cr)
	var wood_left := madeira
	for a in get_tree().get_nodes_in_group("armazens"):
		if wood_left <= 0.0:
			break
		wood_left -= _tira_de(a, "madeira", wood_left)
	take_item(m[0], m[1])
	return true


# ------------------------------------------------------------ itens nos custos (Bloco 94)
## Os itens de um custo como o jogo cobra AGORA: {itens: {id: qtd}, minerio: ferro a mais}. A partir do estágio da
## fornalha, os itens como estão; antes, pregos e ferragens viram o ferro equivalente (o resto continua).
func itens_efetivos(itens: Dictionary) -> Dictionary:
	if itens.is_empty() or pede_barras():
		return {"itens": itens, "minerio": 0.0}
	var resto := {}
	var ferro := 0.0
	for id in itens:
		var n := float(itens[id])
		if id == "prego":
			ferro += n * ferro_por_prego
		elif id == "ferragem":
			ferro += n * ferro_por_ferragem
		else:
			resto[id] = n
	return {"itens": resto, "minerio": ceilf(ferro)}


## "12 pregos + 2 ferragens" (vazio = nada).
func itens_texto(itens: Dictionary) -> String:
	var bits: Array[String] = []
	for id in itens:
		var n := ceili(float(itens[id]))
		if n > 0:
			bits.append("%d %s" % [n, Items.plural(id) if n > 1 else Items.nome(id).to_lower()])
	return " + ".join(bits)


## "" se tem todos os itens; senão "falta 4 pregos, 1 ferragem".
func itens_falta(itens: Dictionary) -> String:
	var parts: Array[String] = []
	for id in itens:
		var precisa := float(itens[id])
		var tem := livre(id)  # Bloco 96
		if tem < precisa:
			var n := ceili(precisa - tem)
			parts.append("%d %s" % [n, Items.plural(id) if n > 1 else Items.nome(id).to_lower()])
	return "" if parts.is_empty() else "falta " + ", ".join(parts)


## Tira os itens do armazém (tudo ou nada). false = faltou (nada gasto).
func paga_itens(itens: Dictionary) -> bool:
	if itens_falta(itens) != "":
		return false
	for id in itens:
		tira(id, float(itens[id]))
	return true


## Devolve itens ao armazém (cancelar uma encomenda paga).
func devolve_itens(itens: Dictionary, perto: Vector2 = Vector2.INF) -> void:
	for id in itens:
		devolve(id, float(itens[id]), perto)


## Tira `n` de QUALQUER item do catálogo, de onde ele fica guardado (processado, minério, madeira, couro).
func tira(id: String, n: float) -> void:
	match Items.onde(id):
		"itens":
			take_item(id, n)
		"madeira":
			var left := n
			for a in get_tree().get_nodes_in_group("armazens"):
				if left <= 0.0:
					break
				left -= _tira_de(a, "madeira", left)
		"couro":
			var left := n
			for a in get_tree().get_nodes_in_group("armazens"):
				left -= _tira_de(a, "couro", left)
		"pecas_raras":  # Bloco 104 (a Antena improvisada leva peças raras)
			var finds := get_tree().get_first_node_in_group("finds")
			if finds:
				finds.rare_parts = maxi(int(finds.rare_parts) - int(ceilf(n)), 0)
		_:
			if Ores.TYPES.has(id):
				spend(0.0, n, id)


## Devolve `n` de qualquer item do catálogo ao armazém (o mais perto de `perto`, nos processados).
func devolve(id: String, n: float, perto: Vector2 = Vector2.INF) -> void:
	if n <= 0.0:
		return
	if Items.onde(id) == "itens":
		add_item(id, n, perto)
		return
	var arm := get_tree().get_first_node_in_group("armazens")
	if arm == null:
		return
	match Items.onde(id):
		"madeira":
			arm.wood_stored += n
		"couro":
			arm.leather_stored += n
		"materia_prima":  # Bloco 104: a caça e as raízes que a expedição traz
			arm.raw_stored += n
		"pecas_raras":
			var finds := get_tree().get_first_node_in_group("finds")
			if finds:
				finds.rare_parts += int(roundf(n))
		_:
			if Ores.TYPES.has(id):
				arm.add_ore(n, id)
	if arm.has_method("_update_label"):
		arm._update_label()


func _junta_falta(a: String, b: String) -> String:
	if b == "":
		return a
	if a == "":
		return b
	return a + ", " + b.trim_prefix("falta ")


## Bloco 82: vende um item processado (as unidades inteiras pedidas; < 0 = todas), de todos os armazéns.
func _sell_item(id: String, quantidade: float = -1.0) -> float:
	if Items.onde(id) != "itens" or price_of(id) <= 0.0:
		return 0.0
	var sold := 0.0
	var resta := minf(floorf(quantidade) if quantidade >= 0.0 else INF, floorf(livre(id)))  # Bloco 96: não o reservado
	for a in get_tree().get_nodes_in_group("armazens"):
		var amount := minf(floorf(a.item_count(id)), resta - sold)
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
		left -= _tira_de(a, id, left)
	return amount - left


func sell_all() -> float:
	var sold := 0.0
	var earned := 0.0
	# Bloco 96: vende só o LIVRE de cada tipo (o reservado pras obras fica), armazém por armazém
	var pode := {}
	for t in Ores.TYPES:
		pode[t] = floorf(livre(t))
	for a in get_tree().get_nodes_in_group("armazens"):
		var value := 0.0
		for t in Ores.TYPES:
			var amount := minf(floorf(a.stock.get(t, 0.0)), float(pode[t]))
			if amount < 1.0:
				continue
			var got: float = a.take(amount, t)
			pode[t] -= got
			sold += got
			value += got * price_of(t)
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
	return credits >= cost_credits and _livre_minerio(ore_type) >= cost_ore and livre("madeira") >= cost_wood  # Bloco 96


## "" se dá pra pagar; senão "falta 12 madeira, 30 ferro" (aviso pros botões).
## ore_label troca o nome do minério no texto (ex.: "pedra (ferro)" nas casas).
func missing_text(cost_credits: float, cost_ore: float, ore_type: String = "", cost_wood: float = 0.0, ore_label: String = "") -> String:
	var parts: Array[String] = []
	if credits < cost_credits:
		parts.append("%d cr" % ceili(cost_credits - credits))
	var have_ore := _livre_minerio(ore_type)  # Bloco 96: o reservado pras obras não conta
	if have_ore < cost_ore:
		var label := ore_label
		if label == "":
			label = "minério" if ore_type == "" else Ores.display_name(ore_type).to_lower()
		parts.append("%d %s" % [ceili(cost_ore - have_ore), label])
	var have_wood := livre("madeira")
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
		wood_left -= _tira_de(a, "madeira", wood_left)
	var types: Array = [ore_type]
	if ore_type == "":
		types = Ores.TYPES.filter(func(t): return t != Ores.DESCONHECIDO)  # Bloco 102: o sem nome não paga custo
		types.sort_custom(func(a, b): return price_of(a) < price_of(b))
	var left := cost_ore
	for t in types:
		var teto := minf(left, livre(t)) if ore_type == "" else left  # Bloco 96: o reservado de outra obra fica
		for a in get_tree().get_nodes_in_group("armazens"):
			if left <= 0.0 or teto <= 0.0:
				break
			var got := _tira_de(a, t, minf(left, teto))
			left -= got
			teto -= got
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


## Bloco 100: créditos ganhos de fora (recompensa de missão).
func ganha_creditos(amount: float) -> void:
	_add_credits(amount)


func _add_credits(amount: float) -> void:
	credits += amount
	credits_changed.emit(credits)
	if amount < 0.0:
		_novo_recibo()
		_recibo_cr -= amount  # Bloco 96: o pagamento entra no recibo (devolvido se a obra for cancelada)


# ------------------------------------------------------------ reserva das obras (Bloco 96)
## O que está no armazém e NÃO está reservado pra uma obra (é o que conta pra pagar, vender e produzir).
func livre(id: String) -> float:
	return maxf(quantidade(id) - reservado(id), 0.0)


## Minério livre de um tipo ("" = de todos os tipos somados).
func _livre_minerio(ore_type: String) -> float:
	if ore_type != "":
		return livre(ore_type)
	var t := 0.0
	for o in Ores.TYPES:
		if o != Ores.DESCONHECIDO:  # Bloco 102: o minério sem nome não paga custo de "minério qualquer"
			t += livre(o)
	return t


## O que as obras encomendadas ainda têm reservado no armazém (falta chegar e não está nas mãos de ninguém).
## (Guardado por quadro: os cartões do CONSTRUIR perguntam muitas vezes; reserva_mudou() limpa na hora.)
func reservado(id: String) -> float:
	var q := Engine.get_process_frames()
	if q != _reserva_quadro:
		_reserva_quadro = q
		_reserva_cache = {}
	if _reserva_cache.has(id):
		return _reserva_cache[id]
	var n := 0.0
	for o in get_tree().get_nodes_in_group("obras"):
		var site = ObraSite.de(o)
		if site != null and site.tem_material() and o.has_method("obra_pending") and o.obra_pending():
			n += site.reservado(id)
	_reserva_cache[id] = n
	return n


## Alguém pegou/entregou/cancelou material: a reserva conta de novo.
func reserva_mudou() -> void:
	_reserva_quadro = -1


## Bloco 97: o armazém mais perto de `perto` em que cabem `n` unidades (null = todos cheios). Bloco 106: `cat` = o
## compartimento ("minerios", "madeira", "alimentos", "manufaturados"; "" = a soma de todos).
func armazem_com_espaco(perto: Vector2, n: float = 1.0, cat: String = "") -> Node:
	var melhor: Node = null
	var melhor_d := INF
	for a in get_tree().get_nodes_in_group("armazens"):
		if not a.has_method("espaco"):
			continue
		if (a.espaco_cat(cat) if cat != "" and a.has_method("espaco_cat") else a.espaco()) < n:
			continue
		var d: float = perto.distance_squared_to(a.global_position)
		if d < melhor_d:
			melhor_d = d
			melhor = a
	return melhor


## Bloco 97: todos os armazéns estão cheios? Bloco 106: `cat` = só aquele compartimento ("" = todos os compartimentos).
func armazens_cheios(cat: String = "") -> bool:
	if cat != "":
		return get_tree().get_nodes_in_group("armazens").all(func(a): return not a.has_method("cheio_cat") or a.cheio_cat(cat))
	return get_tree().get_nodes_in_group("armazens").all(func(a): return not a.has_method("cheio") or a.cheio())


## Bloco 106: os compartimentos cheios em TODOS os armazéns (o alerta "armazém de X cheio").
func categorias_cheias() -> Array[String]:
	var out: Array[String] = []
	for c in Items.COMPARTIMENTOS:
		if armazens_cheios(c):
			out.append(c)
	return out


## Algum armazém tem esse item de verdade (pra buscar agora)?
func tem_no_armazem(id: String) -> bool:
	return not armazens_com(id).is_empty()


## Os armazéns que têm o item (pelo menos 1), do mais perto de `perto` pro mais longe.
func armazens_com(id: String, perto: Vector2 = Vector2.INF) -> Array:
	var out: Array = get_tree().get_nodes_in_group("armazens").filter(func(a): return _no_armazem(a, id) >= 1.0)
	if perto != Vector2.INF:
		out.sort_custom(func(a, b): return perto.distance_squared_to(a.global_position) < perto.distance_squared_to(b.global_position))
	return out


## Quanto de um item tem NESTE armazém.
func _no_armazem(a: Node, id: String) -> float:
	match Items.onde(id):
		"madeira":
			return float(a.wood_stored)
		"couro":
			return float(a.leather_stored)
		"itens":
			return float(a.item_count(id))
	return float(a.stock.get(id, 0.0)) if Ores.TYPES.has(id) else 0.0


## Tira `n` de um item DESTE armazém (o engenheiro pegando o material). Retorna quanto saiu.
func tira_do_armazem(a: Node, id: String, n: float) -> float:
	var got := 0.0
	match Items.onde(id):
		"madeira":
			got = a.take_wood(n)
		"couro":
			got = minf(n, float(a.leather_stored))
			a.leather_stored -= got
		"itens":
			got = a.take_item(id, n)
		_:
			if Ores.TYPES.has(id):
				got = a.take(n, id)
	if a.has_method("_update_label"):
		a._update_label()
	return got


## Põe de volta NESTE armazém (o recibo da encomenda, o material que o engenheiro largou).
func poe_no_armazem(a: Node, id: String, n: float) -> void:
	if n <= 0.0:
		return
	match Items.onde(id):
		"madeira":
			a.wood_stored += n
		"couro":
			a.leather_stored += n
		"itens":
			a.add_item(id, n)
		_:
			if Ores.TYPES.has(id):
				a.stock[id] = float(a.stock.get(id, 0.0)) + n
				a._recount()
	if a.has_method("_update_label"):
		a._update_label()


## Tira do armazém pelos pagamentos e anota no recibo.
func _tira_de(a: Node, id: String, n: float) -> float:
	var got := tira_do_armazem(a, id, n)
	if got > 0.0:
		_novo_recibo()
		_recibo.append([a, id, got])
	return got


func _novo_recibo() -> void:
	var q := Engine.get_process_frames()
	if q != _recibo_quadro:
		_recibo_quadro = q
		_recibo = []
		_recibo_cr = 0.0


## A obra que acabou de ser encomendada (ObraSite.start, no MESMO quadro do pagamento) pega o recibo: o material
## volta pro armazém de onde saiu e vira a lista da obra ({item: qtd}); os créditos ficam anotados (cancelar
## devolve). Obras com material desligadas: o material fica gasto, como antes.
func recibo_da_encomenda() -> Dictionary:
	if _recibo_quadro != Engine.get_process_frames():
		return {}
	var mats := {}
	for r in _recibo:
		if not is_instance_valid(r[0]):
			continue
		if obras_com_material:
			poe_no_armazem(r[0], r[1], r[2])
			mats[r[1]] = float(mats.get(r[1], 0.0)) + float(r[2])
	var out := {"materiais": mats, "creditos": _recibo_cr}
	_reserva_quadro = -1  # a obra nova reserva: a conta do quadro vale de novo
	_recibo = []
	_recibo_cr = 0.0
	_recibo_quadro = -1
	return out


# ------------------------------------------------------------ recrutamento
func worker_count() -> int:
	# Bloco 88: o padre não é recrutado (não conta no limite nem precisa de cama)
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return not (w.has_method("is_priest") and w.is_priest())).size()


## Camas das casas PRONTAS que ninguém ocupa (cada ipezinho precisa de uma).
func free_beds() -> int:
	var total := 0
	for casa in get_tree().get_nodes_in_group("casas"):
		if casa.has_method("beds_total"):
			total += casa.beds_total()
	return total - worker_count()


## Bloco 101: um ipezinho NOVO na vila, na frente do Centro (a população inicial da Fundação; os testes). Não é compra:
## acabou o "Recrutar" — quem chega depois são os migrantes (migrantes.gd). gender "" = sorteado.
func novo_ipezinho(gender: String = "") -> Node2D:
	if worker_scene == null:
		return null
	var parent := get_node_or_null(spawn_parent)
	if parent == null:
		return null
	var worker := worker_scene.instantiate() as Node2D
	worker.name = _next_worker_name()
	worker.position = _spawn_position()
	if gender != "":
		worker.set("gender", gender)
	parent.add_child(worker)
	return worker


## (o nome antigo, pros testes e medições de antes do Bloco 101)
func recruit_free() -> Node2D:
	return novo_ipezinho()


## Bloco 101: cabe mais um na vila? (a capacidade são as CAMAS livres das casas prontas)
func tem_cama_livre() -> bool:
	return free_beds() > 0


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
