extends "res://scripts/props/station.gd"
## Campo de treino (grupo "campos"): onde os GUARDAS treinam de dia.
## O jogador escolhe onde construir (janela de Defesa, tecla G), como as casas.
## Cada guarda treinando aqui ganha habilidade de combate (0 -> 100%) até ficar pronto;
## habilidade dá mais dano e mais vida na luta (ipezinho.gd).

## Habilidade ganha por segundo treinando (1.0 = 100%). 0.009 -> ~110 s pra ficar pronto.
@export var train_rate: float = 0.009

const Modificadores := preload("res://scripts/core/modificadores.gd")

var panel_id := "defesa"

@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("campos")
	add_to_group("clickable")


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-34, -46), Vector2(68, 50)).has_point(p)


func _accepts(body: Node2D) -> bool:
	return body.has_method("train")


func _process(delta: float) -> void:
	var n := 0
	for body in _working_bodies():
		if body.get_state() == "training":
			body.train(train_rate * delta * Modificadores.mult(get_tree(), "treino"))  # Bloco 108: o treinamento (política)
			n += 1
	_label.text = "Campo de treino" + ("\n%d treinando" % n if n > 0 else "")


func pop_in() -> void:
	var v: Sprite2D = $Visual
	v.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(v, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
