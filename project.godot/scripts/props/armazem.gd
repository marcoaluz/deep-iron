extends "res://scripts/props/station.gd"
## Armazém: onde a vila guarda minério, madeira, matéria-prima, couro e itens processados.
## Bloco 106: o limite é POR COMPARTIMENTO (lógico, dentro do mesmo prédio): alimentos, madeira, minérios e barras,
## manufaturados e demais. Um cheio não bloqueia os outros (o minério não tira mais o lugar da comida e da madeira).
## Bloco 97: tem LIMITE (capacidade = total de unidades guardadas, de tudo junto) e sobe até o nível 3. A ampliação
## é OBRA de engenheiro com material (ObraSite, Bloco 96). Cheio: quem vem ENTREGAR espera (balão "armazém cheio")
## ou vai pra outro armazém com espaço; as máquinas param de mandar. Devolução, prêmio e fundação entram mesmo
## cheio (nada do jogador some). Quem vem BUSCAR (cozinheiro, fundidor, engenheiro) é sempre atendido.

signal stored_changed(total: float)

@export_group("Ritmo")
## Minério descarregado por segundo por ipezinho (era 10.0).
@export var DEPOSIT_RATE: float = 8.0
@export_group("Capacidade e níveis (Bloco 97; por compartimento: Bloco 106)")
## Bloco 106: quanto cabe em cada COMPARTIMENTO, por nível (unidades; índice 0 = nível 1). A ampliação multiplica cada
## um como antes (1.000/400 = 2,5x no nível 2; 2.000/400 = 5x no nível 3). Antes era 400 de tudo junto.
## Alimentos = comida crua (a caça e a horta). Uma vila de 10 come ~90 por dia (bench_comida, Bloco 101).
@export var cap_alimentos: Array[float] = [150.0, 375.0, 750.0]
## Madeira = madeira + tábua. Folga pra 1 dia de jogo de 4 lenhadores sem gastar (telemetria do Bloco 106: com 300 o
## caso "10 coletando" enchia no fim do 1º expediente; a madeira é o material das obras, então não cortei o ritmo dela).
@export var cap_madeira: Array[float] = [350.0, 875.0, 1750.0]
## Minérios e barras = todo minério (ferro é a "pedra" das obras) + as barras/aço/lingote.
@export var cap_minerios: Array[float] = [400.0, 1000.0, 2000.0]
## Manufaturados e demais = couro, pregos, ferragens, camas, mochilas...
@export var cap_manufaturados: Array[float] = [100.0, 250.0, 500.0]
## Ampliar PARA o nível do índice (0 = nível 1, não usado): créditos.
@export var ampliar_creditos: Array[int] = [0, 250, 600]
## Ampliar: ferro (a partir do estágio da fornalha vira barra: 100 de ferro = 50 barras).
@export var ampliar_ferro: Array[int] = [0, 60, 100]
## Ampliar: madeira.
@export var ampliar_madeira: Array[int] = [0, 100, 150]
## Ampliar: itens a mais ({item: qtd}).
@export var ampliar_itens: Array[Dictionary] = [{}, {}, {"prego": 20}]
## Ampliar: segundos de engenheiro.
@export var ampliar_segundos: Array[float] = [0.0, 45.0, 70.0]
## Ampliar: estágio mínimo da vila.
@export var ampliar_estagio: Array[int] = [0, 2, 3]
@export_group("Visual e som")
## Quantidade armazenada para cada estágio da pilha de minério (1, 2, 3).
@export var pile_thresholds: Array[float] = [1.0, 60.0, 200.0]
## Intervalo entre os textos flutuantes "+N".
@export var popup_interval: float = 0.8
## Intervalo entre os sons de minério caindo na pilha enquanto alguém deposita.
@export var deposit_sound_interval: float = 0.5

const Ores := preload("res://scripts/core/ores.gd")
const Items := preload("res://scripts/core/items.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 97: a ampliação é obra

## Soma de todos os tipos (a pilha e o texto usam isso).
var total_stored: float = 0.0
## Estoque por tipo de minério ("ferro", "cobre", "carvao").
var stock: Dictionary = {"ferro": 0.0, "cobre": 0.0, "carvao": 0.0, "prata": 0.0, "solarita": 0.0, "cristal_verde": 0.0, "cristal_rubro": 0.0, "gema_azul": 0.0}
## Tudo que já entrou neste armazém desde o começo (não diminui com venda/gasto).
var lifetime_stored: float = 0.0
## Madeira (coluna separada: não é minério, não vende, não conta nos marcos da vila).
var wood_stored: float = 0.0
## Matéria-prima da cozinha (Bloco 27): fruta e caça cruas que o caçador traz e o
## cozinheiro busca pra preparar. Coluna separada como a madeira: não vende, não é minério.
var raw_stored: float = 0.0
## Bloco 42: couro da caça (material do casaco de inverno e dos trajes). Não se vende.
var leather_stored: float = 0.0
## Bloco 82: itens PROCESSADOS (barras, aço, lingote, prego...: items.gd com onde = "itens") — id -> quantidade.
## Fora do `stock` de propósito: não entram no total de minério (pilha, marcos, custo em minério qualquer).
var itens: Dictionary = {}
var _pending_popup: float = 0.0
var _popup_timer: float = 0.0
var _sound_timer: float = 0.0
## Bloco 97: o nível (1..3) e a ampliação em obra.
var nivel: int = 1
var ampliando := false
var amp_total := 0.0
var amp_left := 0.0
var _obra := ObraSite.new()
## Bloco 97: construído pelo jogador (o "Armazém novo"): o save recria.
var construido := false

@onready var _label: Label = $AmountLabel
@onready var _visual: Sprite2D = $Visual
@onready var _pile: Sprite2D = $OrePile


## Bloco 39: clicar no armazém abre a janela de venda.
var panel_id := "armazem"


func _ready() -> void:
	super()
	add_to_group("armazens")
	add_to_group("clickable")
	$WindowLight.add_to_group("cullable_lights")
	_update_label()


func _accepts(body: Node2D) -> bool:
	return body.has_method("deposit")


## Área clicável (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-40, -70), Vector2(80, 74)).has_point(p)


func _process(delta: float) -> void:
	var received := 0.0
	var wood_in := 0.0
	var raw_moved := false
	# Bloco 106: o que ainda cabe em cada compartimento (quem entrega espera se o DELE não couber)
	var cabe_cat := {}
	for c in CATEGORIAS:
		cabe_cat[c] = espaco_cat(c)
	for body in _working_bodies():
		# lenhador descarregando madeira
		if body.has_method("deliver_wood") and body.get_state() == "hauling":
			var w: float = body.deliver_wood(minf(DEPOSIT_RATE * delta, cabe_cat.madeira))
			wood_stored += w
			wood_in += w
			cabe_cat.madeira -= w
			continue
		# Bloco 27: caçador descarregando / cozinheiro buscando matéria-prima
		if body.get("leather_carrying") != null and body.leather_carrying > 0.0 and cabe_cat.manufaturados >= float(body.leather_carrying):
			var c: float = body.deliver_leather()  # Bloco 42: couro vai junto
			leather_stored += c
			cabe_cat.manufaturados -= c
			raw_moved = true
		if body.has_method("deliver_raw") and body.get_state() == "stocking":
			var r: float = body.deliver_raw(minf(DEPOSIT_RATE * delta, cabe_cat.alimentos))
			raw_stored += r
			cabe_cat.alimentos -= r
			raw_moved = true
			continue
		if body.has_method("na_armazem_fundidor") and body.get_state() == "buscando_insumo":
			var por_cat := {}  # Bloco 107: cada item no compartimento dele (barra: minérios; carvão vegetal: madeira; curtido: manufaturados)
			for item in body.barras_mao:
				var cat_i := categoria_de(item)
				por_cat[cat_i] = float(por_cat.get(cat_i, 0.0)) + float(body.barras_mao[item])
			var cabe_tudo := true
			for cat_i in por_cat:
				if float(por_cat[cat_i]) > float(cabe_cat[cat_i]):
					cabe_tudo = false  # Bloco 97: cheio, quem leva espera com a carga
			if cabe_tudo:
				body.na_armazem_fundidor(self)  # Bloco 86: larga as barras e pega os insumos da próxima leva
				for cat_i in por_cat:
					cabe_cat[cat_i] -= float(por_cat[cat_i])
			continue
		if body.has_method("receive_raw") and body.get_state() == "fetching":
			raw_stored -= body.receive_raw(minf(DEPOSIT_RATE * delta, raw_stored))
			raw_stored = maxf(raw_stored, 0.0)
			raw_moved = true
			continue
		if body.has_method("pega_mochila") and body.get_state() == "storing":
			body.pega_mochila(self)  # Bloco 94: o minerador sem mochila pega uma, se tiver
		var got: float = body.deposit(minf(DEPOSIT_RATE * delta, cabe_cat.minerios)) if cabe_cat.minerios > 0.0 else 0.0
		if got > 0.0:
			var t: String = body.cargo_type
			stock[t] = stock.get(t, 0.0) + got
			received += got
			cabe_cat.minerios -= got
	_sound_timer -= delta
	if raw_moved:
		_update_label()
	if wood_in > 0.0:
		_update_label()
		if received <= 0.0 and _sound_timer <= 0.0:  # madeira caindo na pilha também faz barulho
			_sound_timer = deposit_sound_interval
			Audio.deposit(global_position)
	if received > 0.0:
		total_stored = 0.0
		for t in stock:
			total_stored += stock[t]
		lifetime_stored += received
		_pending_popup += received
		_update_label()
		stored_changed.emit(total_stored)
		if _sound_timer <= 0.0:
			_sound_timer = deposit_sound_interval
			Audio.deposit(global_position)

	_popup_timer -= delta
	var finished_batch := _popup_timer <= 0.0 and _pending_popup >= 1.0 and received <= 0.0
	if finished_batch or _pending_popup >= 20.0:
		show_popup("+%d" % int(_pending_popup), Color(1.0, 0.85, 0.35))
		_pending_popup -= int(_pending_popup)
		_popup_timer = popup_interval


## Minério que chega sem ipezinho (a broca da escavadeira). Conta pro total da vila.
func add_ore(amount: float, ore_type: String) -> void:
	stock[ore_type] = stock.get(ore_type, 0.0) + amount
	lifetime_stored += amount
	_pending_popup += amount
	_recount()


## Tira todo o minério do armazém (usado na venda). Retorna quanto saiu.
## Tira todo o minério inteiro de cada tipo (venda). Retorna {tipo: quantidade}.
func take_all() -> Dictionary:
	var taken := {}
	for t in stock:
		var amount := floorf(stock[t])
		if amount > 0.0:
			stock[t] -= amount
			taken[t] = amount
	_recount()
	return taken


## Tira até `amount` de minério do tipo `ore_type` (custos). Retorna quanto saiu.
func take(amount: float, ore_type: String) -> float:
	var taken := minf(amount, stock.get(ore_type, 0.0))
	stock[ore_type] = stock.get(ore_type, 0.0) - taken
	_recount()
	return taken


## Bloco 82: guarda um item processado (barra, prego...).
func add_item(id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	itens[id] = itens.get(id, 0.0) + amount
	_update_label()


## Bloco 82: tira até `amount` de um item processado. Retorna quanto saiu.
func take_item(id: String, amount: float) -> float:
	var taken := minf(amount, itens.get(id, 0.0))
	if taken <= 0.0:
		return 0.0
	itens[id] = itens.get(id, 0.0) - taken
	if itens[id] <= 0.0001:
		itens.erase(id)
	_update_label()
	return taken


## Bloco 82: quanto tem de um item processado.
func item_count(id: String) -> float:
	return itens.get(id, 0.0)


## Cozinheiro indo buscar matéria-prima: só serve se tiver o que pegar.
func accepts_worker(worker: Node) -> bool:
	if worker.has_method("get_state") and worker.get_state() == "fetching":
		return raw_stored >= 0.5
	if worker.has_method("get_state"):
		var cat: String = {"storing": "minerios", "hauling": "madeira", "stocking": "alimentos"}.get(worker.get_state(), "")
		if cat != "" and cheio_cat(cat):
			return false  # Bloco 97/106: o compartimento dele cheio: procura outro armazém (ou espera)
	return true


# ------------------------------------------------------------ capacidade e níveis (Bloco 97)
## Desliga o limite (os testes antigos em que o limite não é o assunto; o jogo nunca liga isto).
static var limite_desligado := false


## Bloco 106: os compartimentos (lógicos) e o nome deles na tela (os dados ficam no items.gd).
const CATEGORIAS := Items.COMPARTIMENTOS
const NOME_CATEGORIA := Items.NOME_COMPARTIMENTO


## Bloco 106: o compartimento de um item/minério (Items.compartimento).
static func categoria_de(id: String) -> String:
	return Items.compartimento(id)


func _cap_de(cat: String) -> Array[float]:
	match cat:
		"alimentos":
			return cap_alimentos
		"madeira":
			return cap_madeira
		"minerios":
			return cap_minerios
	return cap_manufaturados


func capacidade_cat(cat: String) -> float:
	if limite_desligado:
		return INF
	var c := _cap_de(cat)
	return c[clampi(nivel - 1, 0, c.size() - 1)] if not c.is_empty() else 0.0


## O que está guardado num compartimento.
func usado_cat(cat: String) -> float:
	match cat:
		"alimentos":
			var n := raw_stored
			for k in itens:
				if categoria_de(k) == "alimentos":
					n += float(itens[k])
			return n
		"madeira":
			var n2 := wood_stored
			for k in itens:
				if categoria_de(k) == "madeira":
					n2 += float(itens[k])
			return n2
		"minerios":
			var n3 := 0.0
			for t in stock:
				n3 += float(stock[t])
			for k in itens:
				if categoria_de(k) == "minerios":
					n3 += float(itens[k])
			return n3
	var n4 := leather_stored
	for k in itens:
		if categoria_de(k) == "manufaturados":
			n4 += float(itens[k])
	return n4


func espaco_cat(cat: String) -> float:
	return maxf(capacidade_cat(cat) - usado_cat(cat), 0.0)


func cheio_cat(cat: String) -> bool:
	return espaco_cat(cat) < 1.0


## Os compartimentos cheios agora (a placa, o alerta, a janela).
func categorias_cheias() -> Array[String]:
	var out: Array[String] = []
	for c in CATEGORIAS:
		if cheio_cat(c):
			out.append(c)
	return out


## O total: a soma dos compartimentos.
func capacidade() -> float:
	if limite_desligado:
		return INF
	var n := 0.0
	for c in CATEGORIAS:
		n += capacidade_cat(c)
	return n


## Tudo guardado aqui, junto (minério + madeira + matéria-prima + couro + itens).
func usado() -> float:
	var n := wood_stored + raw_stored + leather_stored
	for t in stock:
		n += float(stock[t])
	for k in itens:
		n += float(itens[k])
	return n


## O que ainda cabe somando os compartimentos (cada um no limite dele).
func espaco() -> float:
	var n := 0.0
	for c in CATEGORIAS:
		n += espaco_cat(c)
	return n


## Todos os compartimentos cheios.
func cheio() -> bool:
	return espaco() < 1.0


func nivel_maximo() -> int:
	return cap_minerios.size()


## A soma dos compartimentos num nível (a janela mostra o que a ampliação dá).
func capacidade_minima_no_nivel(n: int) -> float:
	var t := 0.0
	for c in CATEGORIAS:
		var a := _cap_de(c)
		t += a[clampi(n - 1, 0, a.size() - 1)]
	return t


## "" = pode ampliar; senão o motivo.
func ampliar_motivo() -> String:
	if ampliando:
		return "em obra (%s)" % _obra.status(obra_progress())
	if nivel >= nivel_maximo():
		return "nível máximo"
	var i := nivel  # (índice = nível de destino - 1)
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and int(hub.level) < ampliar_estagio[i]:
		return "precisa da vila no estágio %d" % ampliar_estagio[i]
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.metal_falta(ampliar_creditos[i], ampliar_ferro[i], "ferro", ampliar_madeira[i], ampliar_itens[i]) if eco else "sem recursos"


func ampliar_custo_texto() -> String:
	if nivel >= nivel_maximo():
		return ""
	var i := nivel
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.custo_metal_texto(ampliar_creditos[i], ampliar_ferro[i], "ferro", ampliar_madeira[i], ampliar_itens[i]) if eco else ""


## Encomenda a ampliação: paga os créditos, o material fica reservado e o engenheiro leva (Bloco 96).
func ampliar() -> bool:
	if ampliar_motivo() != "":
		Audio.error()
		return false
	var i := nivel
	if not get_tree().get_first_node_in_group("economy").paga_metal(ampliar_creditos[i], ampliar_ferro[i], "ferro", ampliar_madeira[i], ampliar_itens[i]):
		return false
	ampliando = true
	amp_total = maxf(ampliar_segundos[i], 1.0)
	amp_left = amp_total
	_obra.start()
	add_to_group("obras")
	_update_label()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Armazém: ampliação pro nível %d encomendada — precisa de engenheiro (tecla 4)." % (nivel + 1), Color(1.0, 0.8, 0.45), self)
	return true


func obra_pending() -> bool:
	return ampliando


func obra_title() -> String:
	return "Ampliar armazém (nível %d)" % (nivel + 1)


func obra_progress() -> float:
	return clampf(1.0 - amp_left / amp_total, 0.0, 1.0) if ampliando and amp_total > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return global_position + Vector2(0, 40) + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	if not ampliando:
		return
	amp_left -= seconds
	if amp_left > 0.0:
		return
	ampliando = false
	amp_left = 0.0
	amp_total = 0.0
	nivel = mini(nivel + 1, nivel_maximo())
	remove_from_group("obras")
	_update_label()
	show_popup("Nível %d: cabe %d" % [nivel, int(capacidade())], Color(0.55, 1.0, 0.5))
	Audio.build_done(global_position)


## Cancelada: fica no nível de antes (créditos e material: ObraSite.cancelar).
func obra_cancelar() -> void:
	ampliando = false
	amp_left = 0.0
	amp_total = 0.0
	remove_from_group("obras")
	_update_label()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


## Tira até `amount` de madeira (custos). Retorna quanto saiu.
func take_wood(amount: float) -> float:
	var taken := minf(amount, wood_stored)
	wood_stored -= taken
	_update_label()
	return taken


func _recount() -> void:
	total_stored = 0.0
	for t in stock:
		total_stored += stock[t]
	_update_label()
	stored_changed.emit(total_stored)


func _update_label() -> void:
	_label.text = "Minério: %d" % int(total_stored)
	if wood_stored >= 1.0:
		_label.text += "  •  madeira %d" % int(wood_stored)
	if raw_stored >= 1.0:
		_label.text += "  •  matéria-prima %d" % int(raw_stored)
	if leather_stored >= 1.0:
		_label.text += "  •  couro %d" % int(leather_stored)
	var proc := 0.0
	for k in itens:
		proc += itens[k]
	if proc >= 1.0:
		_label.text += "  •  itens %d" % int(proc)  # Bloco 82
	if not limite_desligado:
		# Bloco 106: o compartimento cheio aparece pelo nome (os outros continuam recebendo)
		var cheias := categorias_cheias()
		_label.text += "\n%d/%d%s" % [int(usado()), int(capacidade()), ("  CHEIO: " + ", ".join(cheias.map(func(c): return NOME_CATEGORIA[c]))) if not cheias.is_empty() else ""]  # Bloco 97
	var stage := 0
	for t in pile_thresholds:
		if total_stored >= t:
			stage += 1
	_pile.frame = clampi(stage, 0, _pile.hframes - 1)


## Texto flutuante acima do prédio + "pulinho".
func show_popup(text: String, color: Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.position = Vector2(-16, -76)
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 26.0, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.chain().tween_callback(popup.queue_free)
	var bump := create_tween()
	bump.tween_property(_visual, "scale", Vector2(2.1, 1.9), 0.08)
	bump.tween_property(_visual, "scale", Vector2(2, 2), 0.12)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"stock": stock.duplicate(), "lifetime_stored": lifetime_stored, "wood_stored": wood_stored,
		"raw_stored": raw_stored, "leather_stored": leather_stored, "itens": itens.duplicate(),
		"nivel": nivel, "ampliando": ampliando, "amp_total": amp_total, "amp_left": amp_left, "obra": _obra.get_save_data()}


func load_save_data(d: Dictionary) -> void:
	var saved := SaveUtil.dict(d, "stock")
	for t in Ores.TYPES:
		stock[t] = maxf(SaveUtil.num(saved, t, 0.0), 0.0)
	lifetime_stored = maxf(SaveUtil.num(d, "lifetime_stored", lifetime_stored), 0.0)
	wood_stored = maxf(SaveUtil.num(d, "wood_stored", 0.0), 0.0)
	raw_stored = maxf(SaveUtil.num(d, "raw_stored", 0.0), 0.0)  # save antigo: 0
	leather_stored = maxf(SaveUtil.num(d, "leather_stored", 0.0), 0.0)  # Bloco 42
	# Bloco 82: itens processados (save antigo: nenhum). Só os do catálogo guardados aqui.
	itens.clear()
	var salvos := SaveUtil.dict(d, "itens")
	for id in Items.processados():
		var n := maxf(SaveUtil.num(salvos, id, 0.0), 0.0)
		if n > 0.0:
			itens[id] = n
	# Bloco 97: o nível e a ampliação em obra (save antigo: nível 1, sem obra; o que já tem fica, mesmo passando)
	nivel = clampi(SaveUtil.integer(d, "nivel", 1), 1, nivel_maximo())
	ampliando = SaveUtil.boolean(d, "ampliando", false) and nivel < nivel_maximo()
	amp_total = maxf(SaveUtil.num(d, "amp_total", 0.0), 1.0) if ampliando else 0.0
	amp_left = clampf(SaveUtil.num(d, "amp_left", amp_total), 0.0, amp_total) if ampliando else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	if ampliando:
		add_to_group("obras")
	elif is_in_group("obras"):
		remove_from_group("obras")
	_recount()
