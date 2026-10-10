extends "res://scripts/props/station.gd"
## Comedouro com ESTOQUE de comida (food_stock).
##
## - Quem vem comer só come se houver estoque; cada unidade de comida repõe
##   hunger_per_food de fome. Sem estoque, ninguém come (quem está com fome segue
##   trabalhando, faminto e lento, até alguém repor).
## - Bloco 27: o cozinheiro (estado "cooking") chega com matéria-prima do armazém e
##   PREPARA aqui: a leva leva um tempo (prep_time_per_raw no ipezinho) e só no fim
##   vira comida pronta no estoque.
## - "delivering" ainda descarrega comida pronta (cesta de saves antigos).
## - Bloco 84 (refeições): quem chega pra comer recebe UMA porção (Schedule.porcao unidades de comida, que
##   restaura Schedule.refeicao_fome) e come o prato aos poucos (FEED_RATE). Sem porção inteira no estoque,
##   serve o que tiver (o prato fica menor).
## - O sprite mostra cheio / pela metade / vazio.
## - Bloco 107: o CARDÁPIO (janela da cozinha): o PRATO da semana — refeição comum (o de sempre) ou ensopado (porção maior,
##   mais ânimo, preparo mais lento) — e a ORDEM de ração de expedição: o cozinheiro prepara N rações (viram item no armazém)
##   e a cozinha volta sozinha ao prato de antes (a ração é ordem, não prato: senão a vila passaria fome).

const SocialSpot := preload("res://scripts/props/social_spot.gd")  # Bloco 85
const SaveUtil := preload("res://scripts/core/save_util.gd")
const Modificadores := preload("res://scripts/core/modificadores.gd")  # Bloco 108

@export_group("Ritmo")
## Fome restaurada por segundo por ipezinho comendo.
@export var FEED_RATE: float = 12.0
## Quanta fome cada unidade de comida repõe (5 -> uma refeição de 30 a 95 gasta ~13 de comida).
@export var hunger_per_food: float = 5.0
## Comida descarregada por segundo pelo cozinheiro.
@export var DELIVER_RATE: float = 8.0

@export_group("Estoque")
## Máximo de comida guardada.
@export var food_capacity: float = 300.0
## Comida no começo de um jogo novo.
@export var start_food: float = 240.0

@export_group("Cardápio (Bloco 107)")
## Ensopado: a porção servida é x isto (gasta mais comida)...
@export var ensopado_porcao_mult: float = 1.5
## ...enche x isto de fome (rende menos por unidade de comida: 1,5x a comida, 1,25x a fome)...
@export var ensopado_fome_mult: float = 1.25
## ...e dá este ânimo a cada refeição (soma até o máximo; some devagar: ipezinho.animo_prato_decai)...
@export var ensopado_animo: float = 2.0
@export var ensopado_animo_max: float = 6.0
## ...e o cozinheiro demora x isto pra preparar a leva.
@export var ensopado_preparo_mult: float = 1.3
## Ração de expedição: comida crua gasta por ração (1 ração = 1 pessoa por 1 dia: 2 porções x 8) e o preparo x isto
## (o cozinheiro faz uma ração em ~40 s: 16 de crua x 0,8 s x 3,1).
@export var racao_cru: float = 16.0
@export var racao_preparo_mult: float = 3.1
## Só faz ração com pelo menos esta comida pronta na cozinha (reserva: a ração não esvazia a vila).
@export var racao_reserva_minima: float = 40.0
## O máximo de rações numa ordem.
@export var racao_max_pedido: int = 30

@export_group("Ração da vila (Bloco 108)")
## A porção (e a fome que ela enche) = básico x prato do cardápio x ração das Políticas, presa entre estes múltiplos do
## básico (o teto é o próprio ensopado: as duas escolhas nunca somam além dele).
@export var porcao_mult_min: float = 0.6
@export var porcao_mult_max: float = 1.5

@export_group("Som")
## Intervalo entre os sons de mastigar enquanto alguém come.
@export var eat_sound_interval: float = 0.9

var food_stock: float = 0.0
## Bloco 105: o ESTOQUE DA COZINHA — matéria-prima que o carregador trouxe do armazém; o cozinheiro prepara direto daqui.
@export var raw_local_max: float = 40.0
var raw_local: float = 0.0
var _sound_timer: float = 0.0
var _was_empty: bool = false
## Bloco 107: o prato da semana ("comum" / "ensopado"), as rações que faltam fazer e a crua já gasta na ração da vez.
var prato := "comum"
var racao_pedida: int = 0
var _racao_acc := 0.0
var panel_id := "cozinha"
## Bloco 108: comida que já saiu servida (unidades, total da partida desta cozinha; a telemetria conta por dia).
var servido_total := 0.0
## Algum cozinheiro preparando uma leva aqui agora (a placa mostra "preparando...").
var is_cooking: bool = false

@onready var _visual: Sprite2D = $Visual
@onready var _name_label: Label = $NameLabel


func _ready() -> void:
	super()
	add_to_group("comedouros")
	add_to_group("clickable")  # Bloco 107: a janela do cardápio
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn and dn.has_signal("day_started"):
		dn.day_started.connect(_novo_dia)
	add_child(SocialSpot.criar("refeitorio", "Refeitório", true, 2, 4, Vector2(0, 26)))  # Bloco 85: as mesas
	food_stock = clampf(start_food, 0.0, food_capacity)
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("feed")


## Quem vem comer precisa de estoque; o cozinheiro precisa de espaço pra descarregar.
func accepts_worker(worker: Node) -> bool:
	if worker.has_method("get_state") and worker.get_state() in ["delivering", "cooking"]:
		return food_stock < food_capacity - 0.5
	return food_stock > 0.0


func has_food() -> bool:
	return food_stock > 0.0


func space_left() -> float:
	return maxf(food_capacity - food_stock, 0.0)


func _process(delta: float) -> void:
	var eating := false
	var cooking := false
	for body in _working_bodies():
		if body.has_method("deliver_food") and body.get_state() == "delivering":
			food_stock += body.deliver_food(minf(DELIVER_RATE * delta, space_left()))
			continue
		if body.has_method("cook_tick") and body.get_state() == "cooking":
			if raw_local >= 0.5 and float(body.raw_carrying) < float(body.cook_carry) - 0.01 and float(body._prep_left) <= 0.0:
				var t := minf(raw_local, float(body.cook_carry) - float(body.raw_carrying))  # Bloco 105: o estoque da cozinha
				raw_local -= t
				body.raw_carrying = float(body.raw_carrying) + t
				body._raw_units = float(body._raw_units) + t
			body.prep_mult = _mult_preparo()  # Bloco 107: o prato / a ração (vale no começo da leva)
			var feito: float = body.cook_tick(delta, 1.0e9 if _fazendo_racao() else space_left())  # 0 até a leva ficar pronta
			if feito > 0.0 or _racao_acc > 0.0:
				feito = _desvia_racao(feito, body)
			food_stock += minf(feito, space_left())
			cooking = true
			continue
		if body.has_method("recebe_prato"):  # Bloco 84: uma porção por refeição
			if body.quer_prato():
				if food_stock <= 0.0:
					continue
				var porcao := _porcao() * _fracao_de(body)  # Bloco 111: a criança come meia porção
				var p := minf(porcao, food_stock)
				food_stock -= p
				servido_total += p
				body.recebe_prato(p / porcao * _fome_da_porcao() * _fracao_de(body))
				if prato == "ensopado" and p >= porcao * 0.5:  # Bloco 107: o ensopado alegra
					body.animo_prato = minf(float(body.animo_prato) + ensopado_animo, ensopado_animo_max)
			if body.come_prato(FEED_RATE * delta) > 0.0:
				eating = true
			continue
		if food_stock <= 0.0 or body.hunger >= body.hunger_max:
			continue
		var wanted := minf(FEED_RATE * delta, body.hunger_max - body.hunger)
		var cost := minf(wanted / hunger_per_food, food_stock)
		food_stock -= cost
		body.feed(cost * hunger_per_food)
		eating = true
	food_stock = clampf(food_stock, 0.0, food_capacity)
	is_cooking = cooking
	_sound_timer -= delta
	if eating and _sound_timer <= 0.0:
		_sound_timer = eat_sound_interval * randf_range(0.8, 1.2)
		Audio.eat(global_position)
	_update_visual()


## Bloco 111: a fração da porção de quem chega (a criança, meia; o adulto, inteira).
func _fracao_de(body: Node) -> float:
	if body.has_method("e_crianca") and body.e_crianca():
		var fam := get_tree().get_first_node_in_group("familias")
		return fam.crianca_porcao if fam else 0.5
	return 1.0


## Bloco 84: a porção e quanto ela enche (do Schedule; sem ele, os padrões).
func _porcao() -> float:
	var s := get_tree().get_first_node_in_group("schedule")
	var base: float = maxf(s.porcao, 0.01) if s else 8.0
	var m: float = (ensopado_porcao_mult if prato == "ensopado" else 1.0) * Modificadores.mult(get_tree(), "porcao")  # Bloco 107 + 108
	return base * clampf(m, porcao_mult_min, porcao_mult_max)


func _fome_da_porcao() -> float:
	var s := get_tree().get_first_node_in_group("schedule")
	var base: float = s.refeicao_fome if s else 45.0
	var m: float = (ensopado_fome_mult if prato == "ensopado" else 1.0) * Modificadores.mult(get_tree(), "fome_refeicao")  # Bloco 107 + 108
	return base * clampf(m, porcao_mult_min, porcao_mult_max)


# ------------------------------------------------------------ o cardápio (Bloco 107)
## Escolhe o prato da semana ("comum" / "ensopado"). Vale até mudar; vale pro próximo prato servido.
func set_prato(p: String) -> bool:
	if not p in ["comum", "ensopado"]:
		return false
	prato = p
	return true


## Tem ração a fazer E a cozinha tem a comida de reserva E cabe a ração no armazém? Então a leva vira ração.
func _fazendo_racao() -> bool:
	if racao_pedida <= 0 or food_stock < racao_reserva_minima:
		return false
	var eco := get_tree().get_first_node_in_group("economy")
	return eco != null and eco.armazem_com_espaco(global_position, 1.0, "alimentos") != null


func _mult_preparo() -> float:
	if _fazendo_racao():
		return racao_preparo_mult
	return ensopado_preparo_mult if prato == "ensopado" else 1.0


## A leva pronta (em comida) vira ração enquanto houver ordem: 1 ração a cada `racao_cru` de crua. Retorna a comida que sobra
## pro estoque (o troco de uma ordem que acabou volta pra comida).
func _desvia_racao(feito: float, body: Node) -> float:
	var fpr: float = maxf(float(body.food_per_raw), 0.01)
	if racao_pedida <= 0 or not _fazendo_racao():
		var sobra := _racao_acc * fpr  # ordem acabou (ou parou): a crua que já estava na ração volta pra comida
		_racao_acc = 0.0
		return feito + sobra
	_racao_acc += feito / fpr
	var n := 0
	while _racao_acc >= racao_cru and racao_pedida > 0:
		_racao_acc -= racao_cru
		racao_pedida -= 1
		n += 1
	if n > 0:
		var eco := get_tree().get_first_node_in_group("economy")
		eco.add_item("racao", float(n), global_position)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("Ração de expedição pronta: %d (faltam %d)." % [n, racao_pedida], Color(0.75, 0.9, 0.5), self)
	return 0.0


## A ordem de ração (a janela da cozinha): mais N rações. "" = ok; senão o motivo.
func motivo_racao(n: int) -> String:
	if n <= 0:
		return "escolha a quantidade"
	if racao_pedida + n > racao_max_pedido:
		return "no máximo %d rações por ordem" % racao_max_pedido
	return ""


func pede_racao(n: int) -> bool:
	if motivo_racao(n) != "":
		return false
	racao_pedida += n
	return true


func cancela_racao() -> void:
	racao_pedida = 0


## No domingo a cozinha lembra de revisar o cardápio da semana.
func _novo_dia(_dia: int) -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	var hud := get_tree().get_first_node_in_group("hud")
	if dn and hud and dn.e_domingo():
		hud.show_toast("Domingo: revise o cardápio da semana (clique na cozinha).", Color(1.0, 0.85, 0.5), self)


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-50, -70), Vector2(100, 78)).has_point(p)


func _update_visual() -> void:
	var ratio := food_stock / food_capacity if food_capacity > 0.0 else 0.0
	# quadro 0 = cheio, 1 = pela metade, 2 = vazio
	_visual.frame = 2 if food_stock <= 0.0 else (1 if ratio < 0.5 else 0)
	var empty := food_stock <= 0.0
	_name_label.text = "Cozinha\n%s" % ("SEM COMIDA" if empty else "%d / %d" % [int(food_stock), int(food_capacity)])
	if is_cooking:
		_name_label.text += "\npreparando..."
	_name_label.modulate = Color(1.0, 0.45, 0.4) if empty else (Color(1.0, 0.8, 0.45) if ratio < 0.25 else Color.WHITE)
	if empty and not _was_empty:
		var pop := create_tween()
		_name_label.scale = Vector2(1.2, 1.2)
		pop.tween_property(_name_label, "scale", Vector2.ONE, 0.3)
	_was_empty = empty


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"food_stock": food_stock, "raw_local": raw_local,  # Bloco 105
		"prato": prato, "racao_pedida": racao_pedida, "racao_acc": _racao_acc}  # Bloco 107


func load_save_data(d: Dictionary) -> void:
	food_stock = clampf(SaveUtil.num(d, "food_stock", food_stock), 0.0, food_capacity)
	raw_local = clampf(SaveUtil.num(d, "raw_local", 0.0), 0.0, raw_local_max)  # Bloco 105 (save antigo: vazio)
	prato = SaveUtil.text(d, "prato", "comum")  # Bloco 107 (save antigo: refeição comum, nenhuma ração pedida)
	if not prato in ["comum", "ensopado"]:
		prato = "comum"
	racao_pedida = clampi(SaveUtil.integer(d, "racao_pedida", 0), 0, racao_max_pedido)
	_racao_acc = maxf(SaveUtil.num(d, "racao_acc", 0.0), 0.0)
	_update_visual()
