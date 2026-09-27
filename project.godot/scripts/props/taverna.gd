extends "res://scripts/props/station.gd"
## Taverna (grupo "tavernas"): onde ipezinho triste vai se animar.
##
## - O jogador escolhe onde construir (Bem-estar, tecla B), como as casas.
## - Cada slot é um LUGAR no balcão. Quem entra some lá dentro e ganha felicidade
##   (fun_per_level por segundo) até se animar (leisure_until, no ipezinho.gd).
## - Ter taverna na vila já anima um pouco todo mundo (taverna_bonus, no morale.gd).
## - Nível 2 (ampliação): mais lugares e diversão mais rápida.

const NOTE := preload("res://assets/game/note.png")

@export_group("Lugares e diversão")
## Lugares no balcão por nível (índice 0 = nível 1).
@export var seats_per_level: Array[int] = [3, 5]
## Felicidade ganha por segundo lá dentro, por nível.
@export var fun_per_level: Array[float] = [3.0, 4.5]
## Segundos entre as notinhas musicais que saem da janela.
@export var note_interval: float = 0.9
## Segundos entre um brinde e outro (som).
@export var cheers_interval: float = 7.0

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "moral"
var level: int = 1

var _inside: Array[Node] = []
var _note_timer := 0.0
var _cheers_timer := 2.0

@onready var _visual: Sprite2D = $Visual
@onready var _window_light: PointLight2D = $WindowLight
@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("tavernas")
	add_to_group("clickable")
	_window_light.add_to_group("cullable_lights")
	refresh_seats()
	_update_visual()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-36, -58), Vector2(72, 62)).has_point(p)


func max_level() -> int:
	return seats_per_level.size()


## Ajusta os lugares ao nível (sem tirar ninguém de lá de dentro).
func refresh_seats() -> void:
	var n: int = seats_per_level[clampi(level, 1, max_level()) - 1]
	if n > slot_count:
		slot_count = n
		_slot_owners.resize(n)
	_update_visual()


func fun_rate() -> float:
	return fun_per_level[clampi(level, 1, fun_per_level.size()) - 1]


func set_inside(worker: Node, inside: bool) -> void:
	if inside and not _inside.has(worker):
		_inside.append(worker)
		Audio.cheers(global_position)
	elif not inside:
		_inside.erase(worker)
	_update_visual()


func guests() -> Array:
	_inside = _inside.filter(func(w): return is_instance_valid(w))
	return _inside


## Animação de "acabou de construir".
func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var list := guests()
	for w in list:
		w.have_fun(fun_rate() * delta)
	if not list.is_empty():
		_note_timer -= delta
		if _note_timer <= 0.0:
			_note_timer = note_interval * randf_range(0.7, 1.3)
			_spawn_note()
		_cheers_timer -= delta
		if _cheers_timer <= 0.0:
			_cheers_timer = cheers_interval * randf_range(0.7, 1.3)
			Audio.cheers(global_position)
	_update_visual()


func _spawn_note() -> void:
	var n := Sprite2D.new()
	n.texture = NOTE
	n.scale = Vector2(2, 2)
	n.position = Vector2(randf_range(-22, 22), -40)
	n.z_index = 5
	add_child(n)
	var t := n.create_tween().set_parallel(true)
	t.tween_property(n, "position", n.position + Vector2(randf_range(-8, 8), -28), 1.6)
	t.tween_property(n, "modulate:a", 0.0, 1.6).set_delay(0.4)
	t.chain().tween_callback(n.queue_free)


func _update_visual() -> void:
	var n := guests().size()
	_visual.frame = 1 if n > 0 else 0
	_window_light.enabled = n > 0
	_label.text = "Taverna  %d/%d" % [n, slot_count] if level <= 1 else "Taverna nv.%d  %d/%d" % [level, n, slot_count]


# ------------------------------------------------------------ save/load (via morale.gd)
func get_save_data() -> Dictionary:
	return {"position": [global_position.x, global_position.y], "level": level}
