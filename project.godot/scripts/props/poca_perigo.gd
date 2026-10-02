extends Node2D
## Bloco 70: POÇA DE PERIGO no chão de um nível de baixo (grupo "pocas_perigo"). Vem dos dados do
## nível (NivelMina.perigos: [tipo, x, y, raio]); o ambiente põe no lugar.
##   acido  Poça de ácido (S2)  -> Máscara de gás
##   lava   Poço de lava  (S3, S4) -> Traje térmico
##   agua   Água da cachoeira (S4) -> nenhum: atrasa e MOLHA (Bloco 71: molhado, a lava queima menos)
## Diferente da zona de perigo (hazard_zone.gd: só entra quem tem traje), a poça é de PASSAGEM:
## quem pisa sem o traje anda mais devagar e, ficando, se queima (ipezinho.gd: _equip_tick). Com o
## traje, nada. Os números ficam no nó Fundo (scripts/core/fundo.gd). Na vista iso o desenho vem do
## iso_view (_poca_add: decalque na laje); aqui fica o desenho da vista de cima (mapa antigo).

const NOMES := {"acido": "Poça de ácido", "lava": "Poço de lava", "agua": "Água da cachoeira"}
const TRAJES := {"acido": "gas", "lava": "calor", "agua": ""}
const CORES := {"acido": Color(0.5, 1.0, 0.3), "lava": Color(1.0, 0.45, 0.12), "agua": Color(0.35, 0.65, 1.0)}

@export_enum("acido", "lava", "agua") var kind: String = "acido"
## Raio (px da lógica), achatado na vertical como o resto do mapa.
@export var radius: float = 44.0


func _ready() -> void:
	add_to_group("pocas_perigo")
	z_index = -9  # no chão, embaixo de quem anda
	queue_redraw()


func traje() -> String:
	return TRAJES.get(kind, "")


func nome() -> String:
	return NOMES.get(kind, kind)


func cor() -> Color:
	return CORES.get(kind, Color.WHITE)


func _fundo() -> Node:
	return get_tree().get_first_node_in_group("fundo") if is_inside_tree() else null


func lentidao() -> float:
	var f := _fundo()
	return f.lentidao(kind) if f else 0.6


func exposicao() -> float:
	var f := _fundo()
	return f.exposicao(kind) if f else 5.0


func grave_chance() -> float:
	var f := _fundo()
	return f.grave_chance(kind) if f else 0.0


## Dentro da poça? (elipse: o mapa é visto meio de cima)
func contains(p: Vector2) -> bool:
	var d := p - global_position
	return (d.x * d.x) / (radius * radius) + (d.y * d.y) / (radius * radius * 0.36) <= 1.0


func _draw() -> void:
	var env := get_tree().get_first_node_in_group("environment") if is_inside_tree() else null
	if env and env.has_method("has_iso_map") and env.has_iso_map():
		return  # vista iso: o decalque da poça vem do iso_view (_poca_add)
	var c := cor()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, radius, Color(c.darkened(0.35), 0.75))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(c, 0.55))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(c.lightened(0.3), 0.8), 2.0)
