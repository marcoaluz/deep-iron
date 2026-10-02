extends Node2D
## Bloco 31b: CANTEIRO de uma construção encomendada que ainda não existe (taverna,
## laboratório, campo de treino) ou de uma ampliação (taverna nível 2).
##
## A encomenda já foi paga. Aqui fica "esperando engenheiro"; o engenheiro trabalha
## (interface de obra, ver obra_site.gd) e, quando termina, o sistema dono ergue o
## prédio de verdade (finish_build) e o canteiro some. Nenhum prédio precisou mudar.
##
## Visual: as estacas do lote no chão + o prédio em OBRA POR ESTÁGIOS (Prompt 28:
## fundação 0–33%, paredes 33–66%, prédio cru 66–100%; ver obra_estagio.gd), barrinha de
## progresso e poeira enquanto trabalham.
## Vai pro save (SaveManager, lista "canteiros").

const IsoArt := preload("res://scripts/iso/iso_art.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const ObraEstagio := preload("res://scripts/core/obra_estagio.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const SELF := "res://scripts/props/canteiro.gd"
const LOT_TEXTURE := preload("res://assets/game/casa.png")  # quadro 2 = lote com estacas
## kind -> [título, grupo do sistema dono, textura do prédio ("" = ampliação), hframes]
const KINDS := {
	"taverna": ["Taverna", "morale", "res://assets/game/taverna.png", 2],
	"taverna_up": ["Ampliar taverna", "morale", "", 1],
	"laboratorio": ["Laboratório", "research", "res://assets/game/laboratorio.png", 2],
	"campo": ["Campo de treino", "defense", "res://assets/game/campo_treino.png", 1],
	"arsenal": ["Arsenal", "defense", "res://assets/game/arsenal.png", 4],  # Bloco 35
	"comedouro": ["Cozinha", "village_hub", "res://assets/game/comedouro.png", 3],  # Bloco 37
	"parque": ["Parque", "morale", "res://assets/game/parque.png", 1],  # Bloco 41
	"vestiario": ["Vestiário", "equipment", "res://assets/game/vestiario.png", 1],  # Bloco 44
	"coletor": ["Coletor de madeira", "village_hub", "res://assets/game/coletor_madeira.png", 2],  # Bloco 45
	"coletor_minerio": ["Coletor de minério", "village_hub", "res://assets/game/coletor_minerio.png", 2],  # Bloco 57
	"oficina": ["Oficina", "village_hub", "res://assets/game/oficina.png", 2],  # Bloco 58
	"enfermaria": ["Enfermaria", "village_hub", "res://assets/game/enfermaria.png", 2],  # Bloco 47 (extra)
}

var kind: String = ""
var total: float = 30.0
var left: float = 30.0
var _obra := ObraSite.new()
var _ghost: Sprite2D
var _label: Label
var _dust: CPUParticles2D


## Encomenda: cria o canteiro no mundo (quem chama já cobrou o custo).
static func order(tree: SceneTree, what: String, pos: Vector2, seconds: float) -> Node2D:
	var c: Node2D = load(SELF).new()
	c.kind = what
	c.total = maxf(seconds, 1.0)
	c.left = c.total
	c.position = pos
	c.name = "Canteiro_%s" % what
	tree.get_first_node_in_group("village_hub").get_parent().add_child(c)
	c._obra.start()
	if KINDS.get(what, ["", "", ""])[2] != "":
		var env := tree.get_first_node_in_group("environment")
		if env:
			env.clear_decor_under_extras()
			env.rebuild_navigation()
	return c


## Canteiro desse tipo já encomendado (ou null).
static func pending(tree: SceneTree, what: String) -> Node:
	for c in tree.get_nodes_in_group("canteiros"):
		if c.kind == what:
			return c
	return null


## Recria um canteiro a partir do save.
static func restore(tree: SceneTree, d: Dictionary) -> void:
	var what := SaveUtil.text(d, "kind", "")
	if not KINDS.has(what) or pending(tree, what) != null:
		return
	var c: Node2D = load(SELF).new()
	c.kind = what
	c.total = maxf(SaveUtil.num(d, "total", 30.0), 1.0)
	c.left = clampf(SaveUtil.num(d, "left", c.total), 0.0, c.total)
	c.position = SaveUtil.vec2(d, "position", Vector2.ZERO)
	c.name = "Canteiro_%s" % what
	tree.get_first_node_in_group("village_hub").get_parent().add_child(c)
	c._obra.load_save_data(SaveUtil.dict(d, "obra"))


func _ready() -> void:
	add_to_group("canteiros")
	add_to_group("obras")
	var info: Array = KINDS.get(kind, ["?", "", "", 1])
	if info[2] != "":
		var lot := Sprite2D.new()
		lot.texture = LOT_TEXTURE
		lot.hframes = 3
		lot.frame = 2
		lot.scale = Vector2(2, 2)
		lot.offset = Vector2(0, -LOT_TEXTURE.get_height() * 0.5)
		lot.z_index = -1
		add_child(lot)
		_ghost = Sprite2D.new()
		_ghost.name = "Visual"  # o posicionador de casas usa pra não sobrepor
		_ghost.texture = load(info[2])
		_ghost.hframes = info[3]
		_ghost.frame = 0
		_ghost.scale = Vector2(2, 2)
		_ghost.offset = Vector2(0, -_ghost.texture.get_height() * 0.5)
		add_child(_ghost)
	_dust = CPUParticles2D.new()
	_dust.amount = 10
	_dust.lifetime = 0.9
	_dust.emitting = false
	_dust.position = Vector2(0, -6)
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(22, 4)
	_dust.direction = Vector2(0, -1)
	_dust.spread = 50.0
	_dust.gravity = Vector2(0, -12)
	_dust.initial_velocity_min = 6.0
	_dust.initial_velocity_max = 18.0
	_dust.scale_amount_min = 2.0
	_dust.scale_amount_max = 3.5
	_dust.color = Color(0.75, 0.66, 0.55, 0.55)
	add_child(_dust)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(200, 36)
	_label.position = Vector2(-100, -(_top() + 44.0))
	_label.z_index = 20
	add_child(_label)
	_refresh()


## Altura do desenho (pra pôr o texto e a barra por cima).
func _top() -> float:
	if _ghost:
		return _ghost.texture.get_height() * 2.0
	var tav := get_tree().get_first_node_in_group("tavernas") if is_inside_tree() else null
	return 60.0 if tav else 40.0


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var p := obra_progress()
	var working := _obra.has_engineer()
	if _ghost:
		# Prompt 28: o prédio sobe por estágios conforme a obra anda
		ObraEstagio.apply(_ghost, p)
	_dust.emitting = working
	_label.text = "obra: %s\n%s" % [obra_title(), _obra.status(p)]
	_label.modulate = Color(1.0, 0.8, 0.5) if working else Color(1.0, 0.62, 0.3)
	queue_redraw()


func _draw() -> void:
	var y := -(_top() + 8.0)
	draw_rect(Rect2(-26, y, 52, 5), Color(0.05, 0.04, 0.03, 0.85))
	draw_rect(Rect2(-25, y + 1, 50 * obra_progress(), 3), Color(1.0, 0.6, 0.25) if _obra.has_engineer() else Color(0.7, 0.5, 0.3))


## Base aproximada do prédio que vai nascer (bloqueia a navegação e o posicionador).
func get_obstacle_outline() -> PackedVector2Array:
	if _ghost == null:
		return PackedVector2Array()
	var art := IsoArt.base_rect(self)
	if art.has_area():
		return IsoArt.outline(art)  # Prompt 29: a pegada do desenho novo

	var w := _ghost.texture.get_width() / float(_ghost.hframes) * 2.0 * 0.8
	var c := global_position + Vector2(0, -8)
	return PackedVector2Array([c + Vector2(-w * 0.5, -10), c + Vector2(w * 0.5, -10), c + Vector2(w * 0.5, 8), c + Vector2(-w * 0.5, 8)])


# ------------------------------------------------------------ obra
func obra_pending() -> bool:
	return left > 0.0


func obra_title() -> String:
	return KINDS.get(kind, ["?"])[0]


func obra_progress() -> float:
	return clampf(1.0 - left / total, 0.0, 1.0) if total > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return IsoArt.front(self, Vector2(0, 26)) + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	if left <= 0.0:
		return
	left -= seconds
	if left <= 0.0:
		left = 0.0
		_finish()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


func _finish() -> void:
	# sai dos grupos antes do prédio nascer (a malha de navegação é refeita sem o canteiro)
	remove_from_group("canteiros")
	remove_from_group("obras")
	var sys := get_tree().get_first_node_in_group(KINDS[kind][1])
	if sys and sys.has_method("finish_build"):
		sys.finish_build(kind, global_position)
	queue_free()


func get_save_data() -> Dictionary:
	return {"kind": kind, "position": SaveUtil.vec2_to_array(global_position), "total": total,
		"left": left, "obra": _obra.get_save_data()}
