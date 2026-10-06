extends Node2D
## Bloco 90: uma peça de DECORAÇÃO construída pelo jogador (grupo "decoracoes"), montada por código a partir do
## catálogo (decor.gd): o desenho, a luz (tocha/lampião: grupo "decor_luzes", acende com o torch_level do
## DayNight pelo gerenciador decoracoes.gd) e, se tem assentos (banco/mesa), um PONTO SOCIAL (Bloco 85).
## Peça grande: grupo "decor_obstaculos" (entra na navegação). Lumívoro que chega numa luz APAGA ela até
## amanhecer (take_hit).

const Decor := preload("res://scripts/core/decor.gd")
const SocialSpot := preload("res://scripts/props/social_spot.gd")

var id := ""
var apagada := false  # um Lumívoro comeu a luz (volta ao amanhecer)
var _luz: PointLight2D = null
var _energia := 0.0


## Monta a peça (antes de entrar na árvore).
func monta(p_id: String) -> void:
	id = p_id
	var d := Decor.info(id)
	var vis := Sprite2D.new()
	vis.name = "Visual"
	vis.texture = load(d.textura)
	vis.scale = Vector2(2, 2)
	vis.centered = true
	vis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vis.offset = Vector2(0, -vis.texture.get_height() * 0.5) if vis.texture else Vector2.ZERO
	add_child(vis)
	if Decor.tem_luz(id):
		_luz = PointLight2D.new()
		_luz.name = "Luz"
		_luz.texture = preload("res://assets/game/light_radial.tres")
		_luz.color = d.luz.cor
		_energia = float(d.luz.energia)
		_luz.energy = 0.0
		_luz.texture_scale = float(d.luz.alcance)
		_luz.position = Vector2(0, -(vis.texture.get_height() if vis.texture else 10) * 2.0 + 6.0)
		add_child(_luz)
	var assentos := int(d.get("assentos", 0))
	if assentos > 0:
		var s := SocialSpot.criar("banco" if id == "banco" else "mesa", Decor.nome(id), false, 1, assentos, Vector2(0, 10), 1.1)
		s.raio_roda = 9.0 if id == "banco" else 14.0
		add_child(s)


func _ready() -> void:
	add_to_group("decoracoes")
	if _luz:
		add_to_group("decor_luzes")
		_luz.add_to_group("cullable_lights")
	if Decor.e_obstaculo(id):
		add_to_group("decor_obstaculos")


## Luz agora (o gerenciador chama com o torch_level do DayNight; apagada = 0).
func acende(nivel: float) -> void:
	if _luz:
		_luz.energy = 0.0 if apagada else _energia * nivel
		_luz.enabled = _luz.energy > 0.01


func acesa() -> bool:
	return _luz != null and not apagada and _luz.energy > 0.05


## Lumívoro: come a luz (até amanhecer).
func take_hit(_amount: float, _attacker: Node) -> void:
	if _luz and not apagada:
		apagada = true
		acende(0.0)


func pegada_rect() -> Rect2:
	return Decor.pegada_rect(id, global_position)


## Peça grande na navegação (environment: NAV_EXTRA_GROUPS "decor_obstaculos").
func get_obstacle_outline() -> PackedVector2Array:
	if not Decor.e_obstaculo(id):
		return PackedVector2Array()
	var r := pegada_rect()
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func decor_clear_rect() -> Rect2:
	return pegada_rect().grow(2.0)


func contains_point(p: Vector2) -> bool:
	return pegada_rect().grow(8.0).merge(Rect2(global_position + Vector2(-12, -40), Vector2(24, 40))).has_point(p)
