extends "res://scripts/props/station.gd"
## Casa da vila. Cada slot é uma cama FIXA: o ipezinho reivindica uma cama
## quando nasce (claim_bed) e só a devolve quando sai do jogo.
##
## À noite o ipezinho vai até a porta (posição da cama dele) e "entra": some do
## mapa até amanhecer. Com alguém dentro, a janela acende e sai fumaça da chaminé.
##
## Com built = false a casa é só um LOTE (estacas, madeira, pedras): não tem
## camas e espera a melhoria "Moradias" do Centro da Vila chamar build().
## O lote já ocupa o espaço na navegação, então construir não precisa refazer a malha.

signal built_changed

const SaveUtil := preload("res://scripts/core/save_util.gd")
const FRAME_EMPTY := 0
const FRAME_LIT := 1
const FRAME_LOT := 2

## false = lote vazio (formato antigo; hoje as casas novas são posicionadas pelo jogador).
@export var built: bool = true
## true = casa nova que o jogador posicionou (a posição vai pro save; as 3 iniciais são fixas).
@export var placed_by_player: bool = false

var _inside: Array[Node] = []

@onready var _visual: Sprite2D = $Visual
@onready var _window_light: PointLight2D = $WindowLight
@onready var _smoke: CPUParticles2D = $Smoke
@onready var _sleep_label: Label = $SleepLabel


func _ready() -> void:
	super()
	add_to_group("casas")
	_window_light.add_to_group("cullable_lights")
	_update_visual()


## Constrói a casa no lote (chamado pelo Centro da Vila).
func build() -> void:
	if built:
		return
	built = true
	_update_visual()
	var pop := create_tween()
	_visual.scale = Vector2(2.3, 1.6)
	pop.tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	built_changed.emit()


## "Pulo" + poeira de quando a casa acaba de ser construída.
func pop_in() -> void:
	var pop := create_tween()
	_visual.scale = Vector2(2.3, 1.6)
	pop.tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func has_free_slot_for(worker: Node) -> bool:
	return built and super(worker)


## Reserva uma cama permanente. Retorna o índice ou -1 se a casa estiver cheia.
func claim_bed(worker: Node2D) -> int:
	if not built:
		return -1
	return reserve_slot(worker)


## Reserva uma cama específica (ao carregar o save). -1 se estiver ocupada/não existir.
func claim_specific_bed(worker: Node2D, bed: int) -> int:
	if not built or bed < 0 or bed >= slot_count or _slot_taken(bed):
		return -1
	_slot_owners[bed] = worker
	return bed


func beds_total() -> int:
	return slot_count if built else 0


func beds_taken() -> int:
	return occupied_slot_count() if built else 0


## Chamado pelo ipezinho ao entrar/sair de casa.
func set_inside(worker: Node, inside: bool) -> void:
	if inside and not _inside.has(worker):
		_inside.append(worker)
	elif not inside:
		_inside.erase(worker)
	_update_visual()


func sleeping_count() -> int:
	_inside = _inside.filter(func(w): return is_instance_valid(w))
	return _inside.size()


func _update_visual() -> void:
	if not built:
		_visual.frame = FRAME_LOT
		_window_light.enabled = false
		_smoke.emitting = false
		_sleep_label.visible = true
		_sleep_label.text = "lote vazio"
		_sleep_label.modulate = Color(1, 1, 1, 0.5)
		return
	var occupied := sleeping_count() > 0
	_visual.frame = FRAME_LIT if occupied else FRAME_EMPTY
	_window_light.enabled = occupied
	_smoke.emitting = occupied
	_sleep_label.visible = occupied
	_sleep_label.modulate = Color.WHITE
	if occupied:
		_sleep_label.text = "Zz  %d" % sleeping_count()


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"built": built}


func load_save_data(d: Dictionary) -> void:
	built = SaveUtil.boolean(d, "built", built)
	_update_visual()
