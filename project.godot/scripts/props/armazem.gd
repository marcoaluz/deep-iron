extends "res://scripts/props/station.gd"

signal stored_changed(total: float)

@export_group("Ritmo")
## Minério descarregado por segundo por ipezinho (era 10.0).
@export var DEPOSIT_RATE: float = 8.0
@export_group("Visual e som")
## Quantidade armazenada para cada estágio da pilha de minério (1, 2, 3).
@export var pile_thresholds: Array[float] = [1.0, 60.0, 200.0]
## Intervalo entre os textos flutuantes "+N".
@export var popup_interval: float = 0.8
## Intervalo entre os sons de minério caindo na pilha enquanto alguém deposita.
@export var deposit_sound_interval: float = 0.5

const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")

## Soma de todos os tipos (a pilha e o texto usam isso).
var total_stored: float = 0.0
## Estoque por tipo de minério ("ferro", "cobre", "carvao").
var stock: Dictionary = {"ferro": 0.0, "cobre": 0.0, "carvao": 0.0, "prata": 0.0, "solarita": 0.0}
## Tudo que já entrou neste armazém desde o começo (não diminui com venda/gasto).
var lifetime_stored: float = 0.0
## Madeira (coluna separada: não é minério, não vende, não conta nos marcos da vila).
var wood_stored: float = 0.0
## Matéria-prima da cozinha (Bloco 27): fruta e caça cruas que o caçador traz e o
## cozinheiro busca pra preparar. Coluna separada como a madeira: não vende, não é minério.
var raw_stored: float = 0.0
var _pending_popup: float = 0.0
var _popup_timer: float = 0.0
var _sound_timer: float = 0.0

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
	for body in _working_bodies():
		# lenhador descarregando madeira
		if body.has_method("deliver_wood") and body.get_state() == "hauling":
			var w: float = body.deliver_wood(DEPOSIT_RATE * delta)
			wood_stored += w
			wood_in += w
			continue
		# Bloco 27: caçador descarregando / cozinheiro buscando matéria-prima
		if body.has_method("deliver_raw") and body.get_state() == "stocking":
			raw_stored += body.deliver_raw(DEPOSIT_RATE * delta)
			raw_moved = true
			continue
		if body.has_method("receive_raw") and body.get_state() == "fetching":
			raw_stored -= body.receive_raw(minf(DEPOSIT_RATE * delta, raw_stored))
			raw_stored = maxf(raw_stored, 0.0)
			raw_moved = true
			continue
		var got: float = body.deposit(DEPOSIT_RATE * delta)
		if got > 0.0:
			var t: String = body.cargo_type
			stock[t] = stock.get(t, 0.0) + got
			received += got
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


## Cozinheiro indo buscar matéria-prima: só serve se tiver o que pegar.
func accepts_worker(worker: Node) -> bool:
	if worker.has_method("get_state") and worker.get_state() == "fetching":
		return raw_stored >= 0.5
	return true


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
		"raw_stored": raw_stored}


func load_save_data(d: Dictionary) -> void:
	var saved := SaveUtil.dict(d, "stock")
	for t in Ores.TYPES:
		stock[t] = maxf(SaveUtil.num(saved, t, 0.0), 0.0)
	lifetime_stored = maxf(SaveUtil.num(d, "lifetime_stored", lifetime_stored), 0.0)
	wood_stored = maxf(SaveUtil.num(d, "wood_stored", 0.0), 0.0)
	raw_stored = maxf(SaveUtil.num(d, "raw_stored", 0.0), 0.0)  # save antigo: 0
	_recount()
