extends Area2D
## Base comum das estações de trabalho (minério, comedouro, armazém).
##
## Cada estação tem "slots": posições fixas ao redor dela. O ipezinho reserva um
## slot antes de sair andando e vai exatamente pra lá — assim ninguém briga pelo
## mesmo pixel. Se todos os slots estiverem ocupados, o ipezinho procura outra
## estação ou espera por perto (get_wait_position).
##
## Só interage com a estação quem "está trabalhando nela" (can_work_at), então
## um ipezinho passando por perto a caminho de outro lugar não come/minera sem querer.

@export_group("Slots")
@export var slot_count: int = 3
## Raio (elíptico) onde ficam os slots, em pixels.
@export var slot_radius: Vector2 = Vector2(28, 20)
## Abertura do arco de slots, em graus (360 = volta inteira).
@export_range(0.0, 360.0) var slot_arc_deg: float = 360.0
## Direção central do arco, em graus (90 = para baixo/frente da estação).
@export_range(-180.0, 180.0) var slot_arc_center_deg: float = 90.0
## Ajusta sozinho o raio da área de interação para cobrir os slots.
@export var auto_fit_area: bool = true
@export var area_margin: float = 12.0

var _slot_owners: Array = []
var _bodies: Array[Node2D] = []


func _ready() -> void:
	_slot_owners.resize(slot_count)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if auto_fit_area:
		_fit_area()


func _fit_area() -> void:
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is CircleShape2D):
		return
	var circle := shape_node.shape.duplicate() as CircleShape2D
	circle.radius = maxf(slot_radius.x, slot_radius.y) + area_margin
	shape_node.shape = circle


## Sobrescrito pelas estações: esse corpo sabe usar a estação? (duck typing)
func _accepts(_body: Node2D) -> bool:
	return false


## Sobrescrito pelas estações: vale a pena ir até aqui agora?
func is_usable() -> bool:
	return true


func _on_body_entered(body: Node2D) -> void:
	if _accepts(body) and not _bodies.has(body):
		_bodies.append(body)


func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body)


## Corpos dentro da área que de fato estão trabalhando nesta estação.
func _working_bodies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for body in _bodies:
		if is_instance_valid(body) and (not body.has_method("can_work_at") or body.can_work_at(self)):
			result.append(body)
	return result


# ------------------------------------------------------------------ slots
func _slot_taken(i: int) -> bool:
	var owner_node = _slot_owners[i]
	return owner_node != null and is_instance_valid(owner_node)


func free_slot_count() -> int:
	var n := 0
	for i in slot_count:
		if not _slot_taken(i):
			n += 1
	return n


func occupied_slot_count() -> int:
	return slot_count - free_slot_count()


func slot_of(worker: Node) -> int:
	for i in slot_count:
		if _slot_taken(i) and _slot_owners[i] == worker:
			return i
	return -1


func has_free_slot_for(worker: Node) -> bool:
	return slot_of(worker) >= 0 or free_slot_count() > 0


## Reserva o slot livre mais próximo do worker. Retorna o índice ou -1.
func reserve_slot(worker: Node2D) -> int:
	var current := slot_of(worker)
	if current >= 0:
		return current
	var best := -1
	var best_dist := INF
	for i in slot_count:
		if _slot_taken(i):
			continue
		var d := worker.global_position.distance_squared_to(get_slot_position(i))
		if d < best_dist:
			best_dist = d
			best = i
	if best >= 0:
		_slot_owners[best] = worker
	return best


func release_slot(worker: Node) -> void:
	for i in slot_count:
		if _slot_owners[i] == worker:
			_slot_owners[i] = null


func get_slot_position(i: int) -> Vector2:
	var angle: float
	if slot_count <= 1:
		angle = deg_to_rad(slot_arc_center_deg)
	elif slot_arc_deg >= 359.0:
		angle = deg_to_rad(slot_arc_center_deg) + TAU * float(i) / float(slot_count)
	else:
		var start := slot_arc_center_deg - slot_arc_deg * 0.5
		angle = deg_to_rad(start + slot_arc_deg * float(i) / float(slot_count - 1))
	return global_position + Vector2(cos(angle) * slot_radius.x, sin(angle) * slot_radius.y)


## Ponto de espera, fora da estação, do lado de onde o worker está vindo.
func get_wait_position(worker: Node2D) -> Vector2:
	var dir := worker.global_position - global_position
	if dir.length_squared() < 1.0:
		dir = Vector2.DOWN
	return global_position + dir.normalized() * (maxf(slot_radius.x, slot_radius.y) + 34.0)
