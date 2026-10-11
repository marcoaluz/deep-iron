extends "res://scripts/props/station.gd"
## Bloco 125: o POSTO DE TROCA (grupo "postos_troca"; obra em etapas do Centro, OBRAS_107, obra 1 -> 2 -> 3 -> pronto). Ninguém trabalha aqui:
## é onde a CARAVANA (caravana.gd) para e a comerciante se instala. Clicar abre a janela da caravana (panel_id "caravana"). Sem posto pronto
## a caravana não tem onde parar e não vem.

var panel_id := "caravana"

@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("postos_troca")
	add_to_group("clickable")


func _accepts(_body: Node2D) -> bool:
	return false


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-60, -90), Vector2(120, 100)).has_point(p)


## Onde a comerciante fica (atrás do balcão) e onde espera quem vem comprar (na frente).
func ponto_comerciante() -> Vector2:
	return global_position + Vector2(18, -6)


func ponto_fila(i: int) -> Vector2:
	return global_position + Vector2(-26 + 18 * (i % 4), 34 + 10 * (i / 4))


func _process(_delta: float) -> void:
	var car := get_tree().get_first_node_in_group("caravana")
	_label.text = "Posto de troca" + ("\nCaravana aqui!" if car != null and bool(car.get("presente")) else "")


func pop_in() -> void:
	var v: Sprite2D = $Visual
	v.scale = Vector2(1.0, 0.1)
	create_tween().tween_property(v, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func get_save_data() -> Dictionary:
	return {"position": [global_position.x, global_position.y]}


func load_save_data(_d: Dictionary) -> void:
	pass
