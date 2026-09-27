extends Node
## Achados da escavação (nó Finds, grupo "finds").
##
## A cada ciclo de mineração (o mesmo do sorteio de acidente) o ipezinho pode achar
## alguma coisa além do minério. No nível 2 a chance é maior e aparecem as coisas boas:
##   - peça rara (engrenagem de antes da explosão): moeda dos reatores e do conserto do robô;
##   - Cristal ressonante (só minerando prata), Núcleo solar e Bobina de plasma:
##     cada um libera um reator da escavadeira (uma vez só);
##   - o ROBÔ ANTIGO (uma vez só; garantido depois de robot_guarantee_after achados no
##     fundo): um Ferrugento desligado. Levado pra Oficina e consertado, vira guarda.
## O reator Cristal ressonante multiplica a chance de achado (escavadeira.find_mult()).

signal found(kind: String, worker_name: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ROBO_SCENE := preload("res://scenes/props/robo.tscn")
const ITEM_IDS := ["cristal", "solar", "bobina"]
const ITEM_NAMES := {
	"peca": "Peça rara",
	"cristal": "Cristal ressonante",
	"solar": "Núcleo solar",
	"bobina": "Bobina de plasma",
	"robo": "Robô antigo",
}
const ITEM_ICONS := {
	"peca": preload("res://assets/game/find_peca.png"),
	"cristal": preload("res://assets/game/find_cristal.png"),
	"solar": preload("res://assets/game/find_solar.png"),
	"bobina": preload("res://assets/game/find_bobina.png"),
}

@export_group("Chances (por ciclo de mineração)")
@export_range(0.0, 1.0) var find_chance_surface: float = 0.05
@export_range(0.0, 1.0) var find_chance_deep: float = 0.12
## No abismo (nível 3) a chance do fundo é multiplicada por isso.
@export var abyss_find_mult: float = 1.5
## Dentro de um achado no fundo: chance de ser cada item raro (se ainda não achado).
@export_range(0.0, 1.0) var cristal_chance: float = 0.25  # só minerando prata
@export_range(0.0, 1.0) var solar_chance: float = 0.12
@export_range(0.0, 1.0) var bobina_chance: float = 0.08
@export_range(0.0, 1.0) var robot_chance: float = 0.1
## Achados no fundo até o robô aparecer com certeza.
@export var robot_guarantee_after: int = 6

var rare_parts: int = 0
## Itens de reator achados (cristal/solar/bobina) -> true.
var items: Dictionary = {}
var finds_total: int = 0
var deep_finds: int = 0
var robot_found: bool = false


func _ready() -> void:
	add_to_group("finds")


func has_item(id: String) -> bool:
	return items.get(id, false)


func robot() -> Node:
	return get_tree().get_first_node_in_group("robos")


func robot_active() -> bool:
	var r := robot()
	return r != null and r.state == "active"


## Chamado pelo ipezinho a cada ciclo de mineração.
func roll(worker: Node2D, ore_type: String) -> void:
	var env := get_tree().get_first_node_in_group("environment")
	var deep: bool = env != null and env.is_deep(worker.global_position)
	var chance := find_chance_deep if deep else find_chance_surface
	if env != null and env.has_method("is_abyss") and env.is_abyss(worker.global_position):
		chance *= abyss_find_mult
	var dig := get_tree().get_first_node_in_group("escavadeira")
	if dig and dig.has_method("find_mult"):
		chance *= dig.find_mult()
	if randf() >= chance:
		return
	finds_total += 1
	var kind := "peca"
	if deep:
		deep_finds += 1
		if not robot_found and (deep_finds >= robot_guarantee_after or randf() < robot_chance):
			kind = "robo"
		elif ore_type == "prata" and not has_item("cristal") and randf() < cristal_chance:
			kind = "cristal"
		elif not has_item("solar") and randf() < solar_chance:
			kind = "solar"
		elif not has_item("bobina") and randf() < bobina_chance:
			kind = "bobina"
	give(kind, worker)


## Entrega o achado (também usado pelos testes).
func give(kind: String, worker: Node2D) -> void:
	var who: String = worker.display_name if worker.get("display_name") else String(worker.name)
	var hud := get_tree().get_first_node_in_group("hud")
	match kind:
		"peca":
			var n := 2 if randf() < 0.2 else 1
			rare_parts += n
			worker._popup("Achou %s!" % ("2 peças raras" if n > 1 else "uma peça rara"), Color(1.0, 0.85, 0.45))
			if hud:
				hud.show_toast("%s achou %s na mina." % [who, "2 peças raras" if n > 1 else "uma peça rara"], Color(1.0, 0.85, 0.45))
		"robo":
			robot_found = true
			var r: Node2D = ROBO_SCENE.instantiate()
			r.position = worker.global_position + Vector2(18, 4)
			get_tree().get_first_node_in_group("village_hub").get_parent().add_child(r)
			worker._popup("Um robô antigo!", Color(0.5, 1.0, 0.95))
			var diary := get_tree().get_first_node_in_group("diary")
			if diary:
				diary.unlock("robo")
			if hud:
				hud.show_banner("ROBÔ ANTIGO!", "%s desenterrou um Ferrugento desligado. Clique nele pra mandar levar até a Oficina." % who)
		_:
			items[kind] = true
			worker._popup("%s!" % ITEM_NAMES[kind], Color(0.8, 0.7, 1.0))
			if hud:
				hud.show_banner("ACHADO: %s" % ITEM_NAMES[kind].to_upper(),
					"%s achou no fundo da mina. Libera um reator novo na Escavadeira (E)." % who)
	Audio.find(worker.global_position)
	found.emit(kind, who)


## Gasta peças raras (custos). false se não tem.
func spend_parts(n: int) -> bool:
	if rare_parts < n:
		return false
	rare_parts -= n
	return true


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var d := {
		"rare_parts": rare_parts,
		"items": items.duplicate(),
		"finds_total": finds_total,
		"deep_finds": deep_finds,
		"robot_found": robot_found,
	}
	var r := robot()
	if r:
		d["robot"] = r.get_save_data()
	return d


func load_save_data(d: Dictionary) -> void:
	rare_parts = maxi(SaveUtil.integer(d, "rare_parts", 0), 0)
	items = {}
	var saved := SaveUtil.dict(d, "items")
	for id in ITEM_IDS:
		if SaveUtil.boolean(saved, id, false):
			items[id] = true
	finds_total = maxi(SaveUtil.integer(d, "finds_total", 0), 0)
	deep_finds = maxi(SaveUtil.integer(d, "deep_finds", 0), 0)
	robot_found = SaveUtil.boolean(d, "robot_found", false)
	var rd := SaveUtil.dict(d, "robot")
	if not rd.is_empty() and robot() == null:
		var r: Node2D = ROBO_SCENE.instantiate()
		r.pending_save_data = rd
		get_tree().get_first_node_in_group("village_hub").get_parent().add_child(r)
