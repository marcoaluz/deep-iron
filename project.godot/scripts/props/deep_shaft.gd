extends Node2D
## Elevador pro NÍVEL 2 (grupo "elevador"), ao lado da plataforma da escavadeira.
##
## Fica fechado até a escavadeira ficar pronta (Bloco 4); aí a descida abre.
## A ligação é um NavigationLink2D: os ipezinhos planejam o caminho passando por
## ele (ex.: ir minerar prata lá embaixo) e, ao chegar na gaiola, são levados pro
## outro lado (ipezinho.gd -> _on_link_reached). Funciona nos dois sentidos.
## Em cima: gaiola ao lado da escavadeira. Embaixo: gaiola de chegada no nível 2.

signal opened

const SaveUtil := preload("res://scripts/core/save_util.gd")

## Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do nível 2).
@export var bottom_position: Vector2 = Vector2(440, 790)
## Custo de navegação da descida (baixo = os ipezinhos acham que "descer é perto").
@export var link_travel_cost: float = 0.05

var unlocked: bool = false

@export_group("Viagem (Bloco 68)")
## Segundos na gaiola por viagem e quantos cabem nela de uma vez (mais gente = espera a próxima).
@export var travel_time: float = 1.6
@export var capacity: int = 4
var _riders: Array = []  # fim da viagem (s do relógio) de quem está na gaiola


## Bloco 68: quanto tempo esse ipezinho fica na gaiola (a viagem + a fila, se lotou).
func ride_wait() -> float:
	var now := Time.get_ticks_msec() / 1000.0
	_riders = _riders.filter(func(t): return t > now)
	var fila := int(_riders.size() / maxi(capacity, 1))
	var espera := travel_time * (1 + fila) / maxf(Engine.time_scale, 0.01)
	_riders.append(now + espera)
	return travel_time * (1 + fila)


## Bloco 68: por que a descida ainda está fechada (o nível S2 lê daqui).
func reason_locked() -> String:
	return "" if unlocked else "abre quando a escavadeira ficar pronta"

@onready var _top: Node2D = $Top
@onready var _bottom: Node2D = $Bottom
@onready var _link: NavigationLink2D = $Link
@onready var _top_label: Label = $Top/Label
@onready var _bottom_label: Label = $Bottom/Label


func _ready() -> void:
	add_to_group("elevador")
	_bottom.position = bottom_position - global_position
	_link.start_position = Vector2.ZERO
	_link.end_position = bottom_position - global_position
	_link.bidirectional = true
	_link.travel_cost = link_travel_cost
	_link.enter_cost = 0.0
	_apply(false)
	_connect_escavadeira.call_deferred()


func _connect_escavadeira() -> void:
	var dig := get_tree().get_first_node_in_group("escavadeira")
	if dig == null:
		return
	dig.completed.connect(func(): unlock(true))
	if dig.complete:
		unlock(false)


## Abre a descida (escavadeira pronta). announce = mostra aviso.
func unlock(announce: bool) -> void:
	if unlocked:
		return
	unlocked = true
	_apply(announce)
	opened.emit()


## Save carregado / escavadeira carregada: garante que o estado bate.
func sync_state() -> void:
	var dig := get_tree().get_first_node_in_group("escavadeira")
	if dig and dig.complete and not unlocked:
		unlocked = true
	_apply(false)


func _apply(animate: bool) -> void:
	_top.visible = unlocked
	_link.enabled = unlocked
	_bottom_label.text = "Nível 2 — mais fundo, mais perigoso" if unlocked \
		else "Nível 2 — fechado (abre quando a escavadeira ficar pronta)"
	_bottom_label.modulate = Color(0.75, 0.8, 1.0, 0.9) if unlocked else Color(1, 0.6, 0.5, 0.8)
	if animate:
		_top.scale = Vector2(1.3, 0.7)
		create_tween().tween_property(_top, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Audio.forge(global_position)
	# jazidas do fundo trancam/destrancam junto
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed(animate)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"unlocked": unlocked}


func load_save_data(d: Dictionary) -> void:
	unlocked = SaveUtil.boolean(d, "unlocked", unlocked)
	_apply(false)
