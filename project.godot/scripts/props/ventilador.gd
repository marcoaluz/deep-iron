extends Node2D
## Bloco 70: VENTILADOR do nível 2 (grupo "ventiladores"). Construído pelo engenheiro (fundo.gd:
## pesquisa Ventilação + obra). No alcance (Fundo.ventilador_alcance) a máscara de gás gasta menos e o
## ácido das poças queima mais devagar; cada um afina a névoa verde do S2. Na vista iso vira o prop
## "ventilador" (meta iso_prop); aqui fica o desenho da vista de cima.

const TEXTURE := preload("res://assets/game/ventilador.png")

var _sprite: Sprite2D
var _air: CPUParticles2D


func _ready() -> void:
	add_to_group("ventiladores")
	set_meta("iso_prop", "ventilador")
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2(2, 2)
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	_air = CPUParticles2D.new()  # o ar subindo (leva o gás)
	_air.amount = 10
	_air.lifetime = 1.6
	_air.position = Vector2(0, -26)
	_air.direction = Vector2(0, -1)
	_air.spread = 18.0
	_air.gravity = Vector2.ZERO
	_air.initial_velocity_min = 20.0
	_air.initial_velocity_max = 34.0
	_air.scale_amount_min = 1.5
	_air.scale_amount_max = 3.0
	_air.color = Color(0.75, 1.0, 0.7, 0.35)
	add_child(_air)
	add_to_group("efeitos")
	efeitos_mudaram()


func pop_in() -> void:
	scale = Vector2(0.4, 0.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Reduzir efeitos: sem o ar subindo.
func efeitos_mudaram() -> void:
	_air.emitting = not preload("res://scripts/core/efeitos.gd").reduzidos()
