extends Node2D
## Bloco 88: IGREJA (grupo "igrejas"; uma por vila) — posicionada pelo jogador e erguida pelo engenheiro
## (canteiro "igreja", dono: Centro da Vila). É um PONTO SOCIAL coberto (social_spot.gd, tipo "igreja": os
## bancos na frente dela), onde acontecem a missa de domingo, os funerais e o aconselhamento do padre (quem
## está aqui perde zanga). O calendário (calendario.gd) manda as pessoas pra cá na hora certa.

const SocialSpot := preload("res://scripts/props/social_spot.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")

## Bancos (lugares) na frente da igreja: rodas x lugares por roda.
@export var rodas_bancos: int = 6
@export var lugares_por_banco: int = 4

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "calendario"
var _spot: Node2D

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $NameLabel
@onready var _luz: PointLight2D = $Luz


func _ready() -> void:
	add_to_group("igrejas")
	add_to_group("clickable")
	_luz.add_to_group("cullable_lights")
	_spot = SocialSpot.criar("igreja", "Igreja", true, rodas_bancos, lugares_por_banco, Vector2(0, 30), 1.3)
	_spot.espaco_rodas = 44.0
	add_child(_spot)


## O ponto social da igreja (os bancos).
func ponto() -> Node2D:
	return _spot


## Onde o padre fica (na porta, aconselhando).
func altar_pos() -> Vector2:
	return IsoArt.front(self, Vector2(0, 12))


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-56, -124), Vector2(112, 128)).has_point(p)


func decor_clear_rect() -> Rect2:
	return Rect2(global_position + Vector2(-58, -40), Vector2(116, 46))


## A pegada da igreja na navegação (environment: NAV_EXTRA_GROUPS "igrejas").
func get_obstacle_outline() -> PackedVector2Array:
	var art := IsoArt.base_rect(self)
	var r := art if art.has_area() else Rect2(global_position + Vector2(-48, -18), Vector2(96, 20))
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## O texto da placa (o calendário escreve: "missa agora", "funeral de ...").
func set_status(text: String) -> void:
	if _label:
		_label.text = "Igreja" + ("\n" + text if text != "" else "")
	_luz.enabled = text != ""


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
