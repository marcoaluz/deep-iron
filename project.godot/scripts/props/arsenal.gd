extends "res://scripts/props/station.gd"
## Arsenal (grupo "arsenais") — Bloco 35: onde as armas dos guardas são forjadas e
## consertadas, e onde o guarda desarmado vem buscar outra.
##
## O jogador escolhe o lugar (janela de Defesa, tecla G) e o engenheiro ergue (canteiro).
## Pronto, ele é uma OBRA como a Oficina: a fila da forja (defense.gd: queue) só anda com
## um engenheiro trabalhando aqui. Os dados (cavalete, pilha de conserto, fila) ficam no
## Defense; este nó é o lugar no mapa: visual, obra e os slots onde os guardas trocam de arma.
##
## Bloco 47: pode ter vários. O cavalete e a fila são UM só (no Defense); a FORJA fica no
## Arsenal principal (o primeiro) — senão a mesma encomenda viraria duas obras. Os outros
## são postos de armas: o guarda pega/devolve no Arsenal mais perto dele.

const ObraSite := preload("res://scripts/core/obra_site.gd")

## Intervalo entre as marteladas enquanto forja.
@export var forge_sound_interval: float = 0.9

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "defesa"
var _obra := ObraSite.new()
var _sound_timer := 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $StatusLabel
@onready var _sparks: CPUParticles2D = $Sparks
@onready var _light: PointLight2D = $ForgeLight


func _ready() -> void:
	super()
	add_to_group("arsenais")
	add_to_group("obras")
	add_to_group("clickable")
	_light.add_to_group("cullable_lights")
	refresh()


func _def() -> Node:
	return get_tree().get_first_node_in_group("defense")


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-46, -78), Vector2(92, 82)).has_point(p)


func get_clear_center() -> Vector2:
	return global_position + Vector2(0, -34)


func get_clear_radius() -> float:
	return 60.0


func _accepts(body: Node2D) -> bool:
	return body.has_method("rearm")


func _process(delta: float) -> void:
	for body in _working_bodies():
		if body.get_state() == "rearming":
			body.rearm(self)
	var working := obra_pending() and _obra.has_engineer()
	_sparks.emitting = working
	if working:
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = forge_sound_interval * randf_range(0.8, 1.2)
			Audio.forge(global_position)
	refresh()


## Quadro (parado/forjando x cavalete vazio/com armas) + texto.
func refresh() -> void:
	if not is_inside_tree():
		return
	var def := _def()
	var stocked: bool = def != null and def.rack_total() > 0
	var working := obra_pending() and _obra.has_engineer()
	_visual.frame = (2 if working else 0) + (1 if stocked else 0)
	_light.enabled = working
	var lines: Array[String] = ["Arsenal" if is_forge() else "Arsenal (posto de armas)"]
	if def:
		var bits: Array[String] = []
		for id in def.WEAPON_IDS:
			if def.rack_count(id) > 0:
				bits.append("%d %s" % [def.rack_count(id), def.WEAPON_NAMES[id].to_lower()])
		lines.append("cavalete: " + (", ".join(bits) if not bits.is_empty() else "vazio (só porrete)"))
		if def.broken_total() > 0:
			lines.append("%d pra consertar" % def.broken_total())
		if obra_pending():
			lines.append("%s  %s%s" % [def.forge_title(), _obra.status(obra_progress()),
				"  (+%d na fila)" % (def.queue.size() - 1) if def.queue.size() > 1 else ""])
		elif not def.queue.is_empty():
			lines.append("forjando no Arsenal principal")
	_label.text = "\n".join(lines)
	_label.modulate = Color(1.0, 0.8, 0.5) if working else (Color(1.0, 0.62, 0.3) if obra_pending() else Color(0.9, 0.88, 0.85))


func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------ obra (a fila da forja)
func obra_pending() -> bool:
	var def := _def()
	return def != null and not def.queue.is_empty() and is_forge()


## Bloco 47: é o Arsenal onde a forja trabalha (o principal)?
func is_forge() -> bool:
	var def := _def()
	return def == null or def.arsenal() == self


func obra_title() -> String:
	var def := _def()
	return def.forge_title() if def else "Arsenal"


func obra_progress() -> float:
	var def := _def()
	return def.forge_progress() if def else 0.0


func obra_position(worker: Node) -> Vector2:
	return IsoArt.front(self, Vector2(-24, 30)) + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	var def := _def()
	if def:
		def.forge_work(seconds)


func obra_ordered_at() -> float:
	var def := _def()
	return def.forge_ordered_at() if def else 0.0


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()
