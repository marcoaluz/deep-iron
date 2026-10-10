extends "res://scripts/props/station.gd"
## Bloco 111: a ESCOLA (grupo "escolas"). As CRIANÇAS vêm pra cá no horário de trabalho dos adultos (sem professor: ela
## funciona sozinha — decisão do Marco, "sem novas funções"). Quem está numa vaga estuda: o ESTUDO (0..1) sobe e, quando vira
## aprendiz e depois adulto, rende (familias.gd: aprende mais rápido e começa com mais habilidade). Estar aqui anima a
## criança. Construída pelo engenheiro (centro_vila OBRAS_107, obra 1 -> 2 -> 3 -> pronto).

var panel_id := ""

@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("escolas")


func _accepts(body: Node2D) -> bool:
	return body.has_method("e_crianca") and body.e_crianca() and body.get("fase") == "crianca"


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-60, -90), Vector2(120, 100)).has_point(p)


func _process(delta: float) -> void:
	var fam := get_tree().get_first_node_in_group("familias")
	var n := 0
	for body in _working_bodies():
		if body.get_state() == "escola":
			n += 1
			if fam:
				fam.estuda(body, delta)
	_label.text = "Escola" + ("\n%d na aula" % n if n > 0 else "")


func pop_in() -> void:
	var v: Sprite2D = $Visual
	v.scale = Vector2(1.0, 0.1)
	create_tween().tween_property(v, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func get_save_data() -> Dictionary:
	return {"position": [global_position.x, global_position.y]}


func load_save_data(_d: Dictionary) -> void:
	pass
