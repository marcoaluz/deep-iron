extends "res://scripts/props/station.gd"
## Centro da Vila: hub de progressão (grupo "village_hub").
##
## - Mostra o progresso geral (população, minério coletado no total, estágio).
## - "Expandir a vila": sobe o estágio (1 a 5). Precisa de um marco de minério
##   coletado no total (tudo que já entrou nos armazéns, mesmo o que foi vendido)
##   e custa créditos.
## - Melhorias compradas com créditos + minério do armazém. Cada melhoria só pode
##   ter no máximo tantos níveis quanto o estágio atual da vila.
##     Moradias:         +workers_per_moradia no limite de ipezinhos e uma casa
##                       nova (4 camas) que o JOGADOR posiciona no mapa (HousePlacer).
##                       O custo só é pago quando ele confirma o lugar; Esc cancela.
##     Enfermaria:       -recovery_cut_per_level no tempo de cura (por nível).
##     Trilhas batidas:  +speed_bonus_per_level na velocidade de caminhada (por nível).
##
## Os ipezinhos consultam recovery_mult() e speed_mult(); a economia guarda o limite.
## Ninguém trabalha aqui (sem slots): é só a base que bloqueia a navegação.

signal level_changed(level: int)
signal upgrade_bought(id: String, new_level: int)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const STAGE_NAMES := ["Acampamento", "Vilarejo", "Vila", "Vila Mineira", "Cidade Mineira"]
const UPGRADE_IDS := ["moradias", "enfermaria", "trilhas"]
const CASA_SCENE := preload("res://scenes/props/casa.tscn")
const UPGRADE_NAMES := {
	"moradias": "Moradias",
	"enfermaria": "Enfermaria",
	"trilhas": "Trilhas batidas",
}

@export_group("Estágios da vila")
## Minério coletado no total pra chegar em cada estágio (índice 0 = estágio 1).
@export var level_ore_required: Array[int] = [0, 375, 1250, 3100, 6250]
## Créditos pra expandir pra cada estágio (índice 0 = estágio 1, não usado).
@export var level_credit_cost: Array[int] = [0, 190, 625, 1500, 3100]

@export_group("Melhoria: Moradias")
## Custo de cada nível: x = créditos, y = minério do armazém.
@export var moradias_costs: Array[Vector2i] = [Vector2i(190, 0), Vector2i(375, 50), Vector2i(750, 150), Vector2i(1250, 310)]
@export var workers_per_moradia: int = 4

@export_group("Melhoria: Enfermaria")
@export var enfermaria_costs: Array[Vector2i] = [Vector2i(125, 25), Vector2i(310, 75), Vector2i(625, 190)]
## Fração do tempo de cura cortada por nível (0.2 = -20% por nível).
@export_range(0.0, 0.3) var recovery_cut_per_level: float = 0.2

@export_group("Melhoria: Trilhas batidas")
@export var trilhas_costs: Array[Vector2i] = [Vector2i(150, 25), Vector2i(375, 100), Vector2i(810, 250)]
## Velocidade extra por nível (0.1 = +10% por nível).
@export var speed_bonus_per_level: float = 0.1

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "hub"
var level: int = 1
var upgrades: Dictionary = {"moradias": 0, "enfermaria": 0, "trilhas": 0}

@onready var _visual: Sprite2D = $Visual
@onready var _name_label: Label = $NameLabel


func _ready() -> void:
	super()
	add_to_group("village_hub")
	add_to_group("clickable")
	$WindowLight.add_to_group("cullable_lights")
	_update_visual()


## Área clicável do prédio (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-58, -100), Vector2(116, 104)).has_point(p)


## Pro ambiente não espalhar pedras/tochas em cima do prédio.
func get_clear_center() -> Vector2:
	return global_position + Vector2(0, -45)


func get_clear_radius() -> float:
	return 85.0


# ------------------------------------------------------------ efeitos (consultados pelos ipezinhos)
func recovery_mult() -> float:
	return maxf(0.1, 1.0 - recovery_cut_per_level * upgrades.enfermaria)


func speed_mult() -> float:
	return 1.0 + speed_bonus_per_level * upgrades.trilhas


# ------------------------------------------------------------ progresso
func stage_name(lvl: int = level) -> String:
	return STAGE_NAMES[clampi(lvl, 1, STAGE_NAMES.size()) - 1]


func max_level() -> int:
	return STAGE_NAMES.size()


## Minério que já entrou nos armazéns desde o começo do jogo (inclui o vendido).
func lifetime_ore() -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.lifetime_stored
	return total


func next_level_ore() -> int:
	return level_ore_required[level] if level < max_level() else 0


func next_level_cost() -> int:
	return level_credit_cost[level] if level < max_level() else 0


func can_level_up() -> bool:
	var eco := _economy()
	return level < max_level() and eco != null \
		and lifetime_ore() >= next_level_ore() and eco.credits >= next_level_cost()


func level_up() -> bool:
	if not can_level_up():
		Audio.error()
		return false
	_economy().spend(next_level_cost(), 0)
	level += 1
	_update_visual()
	_popup("A vila agora é: %s!" % stage_name(), Color(1.0, 0.85, 0.4))
	Audio.recruit()
	level_changed.emit(level)
	return true


# ------------------------------------------------------------ melhorias
func upgrade_costs(id: String) -> Array[Vector2i]:
	match id:
		"moradias":
			return moradias_costs
		"enfermaria":
			return enfermaria_costs
		"trilhas":
			return trilhas_costs
	return []


func upgrade_max(id: String) -> int:
	return upgrade_costs(id).size()


## Custo do próximo nível (Vector2i(-1, -1) se já está no máximo).
func upgrade_cost(id: String) -> Vector2i:
	var lvl: int = upgrades[id]
	var costs := upgrade_costs(id)
	return costs[lvl] if lvl < costs.size() else Vector2i(-1, -1)


## "" se pode comprar; senão o motivo (pra mostrar no botão).
func upgrade_block_reason(id: String) -> String:
	var lvl: int = upgrades[id]
	if lvl >= upgrade_max(id):
		return "nível máximo"
	if lvl >= level:
		return "requer vila nível %d" % (lvl + 1)
	var cost := upgrade_cost(id)
	var eco := _economy()
	if eco == null or not eco.can_afford(cost.x, cost.y):
		return "sem recursos"
	return ""


func buy_upgrade(id: String) -> bool:
	if upgrade_block_reason(id) != "":
		Audio.error()
		return false
	if id == "moradias":
		return _start_house_placement()  # paga só ao confirmar o lugar
	var cost := upgrade_cost(id)
	if not _economy().spend(cost.x, cost.y):
		return false
	upgrades[id] += 1
	_apply_upgrade(id)
	_popup("%s %d!" % [UPGRADE_NAMES[id], upgrades[id]], Color(0.55, 1.0, 0.5))
	Audio.recruit()
	upgrade_bought.emit(id, upgrades[id])
	return true


## Texto do efeito atual e do próximo nível (pra UI).
func upgrade_effect_text(id: String, lvl: int) -> String:
	match id:
		"moradias":
			return "limite %d ipezinhos" % (_base_max_workers() + workers_per_moradia * lvl)
		"enfermaria":
			return "cura em %ds" % roundi(_base_recovery_time() * maxf(0.1, 1.0 - recovery_cut_per_level * lvl))
		"trilhas":
			return "velocidade +%d%%" % roundi(speed_bonus_per_level * lvl * 100.0)
	return ""


func upgrade_description(id: String) -> String:
	match id:
		"moradias":
			return "+%d no limite de ipezinhos e uma casa nova (4 camas) — você escolhe onde." % workers_per_moradia
		"enfermaria":
			return "Ipezinhos machucados curam %d%% mais rápido por nível." % roundi(recovery_cut_per_level * 100.0)
		"trilhas":
			return "Todos os ipezinhos andam %d%% mais rápido por nível." % roundi(speed_bonus_per_level * 100.0)
	return ""


func _apply_upgrade(_id: String) -> void:
	pass  # Moradias é aplicada em _confirm_house (depois de escolher o lugar)


# ------------------------------------------------------------ casas posicionadas
func _start_house_placement() -> bool:
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		push_warning("Centro da Vila: sem HousePlacer na cena")
		return false
	placer.begin(_confirm_house)
	return true


## HousePlacer chama quando o jogador clica num lugar válido. Só aqui a Moradias é paga.
func _confirm_house(pos: Vector2) -> bool:
	if upgrade_block_reason("moradias") != "":  # recursos podem ter mudado enquanto escolhia
		Audio.error()
		return false
	var cost := upgrade_cost("moradias")
	if not _economy().spend(cost.x, cost.y):
		return false
	upgrades.moradias += 1
	_economy().max_workers += workers_per_moradia
	var casa := spawn_house(pos)
	casa.pop_in()
	_popup("%s %d!" % [UPGRADE_NAMES.moradias, upgrades.moradias], Color(0.55, 1.0, 0.5))
	Audio.recruit()
	upgrade_bought.emit("moradias", upgrades.moradias)
	return true


## Cria uma casa construída pelo jogador (também usado ao carregar o save).
func spawn_house(pos: Vector2, house_name: String = "", rebuild_nav: bool = true) -> Node2D:
	var casa: Node2D = CASA_SCENE.instantiate()
	casa.name = house_name if house_name != "" else _next_house_name()
	casa.position = pos
	casa.placed_by_player = true
	get_parent().add_child(casa)
	if rebuild_nav:
		var env := get_tree().get_first_node_in_group("environment")
		if env:
			env.rebuild_navigation()
	return casa


func _next_house_name() -> String:
	var n := 1
	while get_parent().has_node("CasaNova%d" % n):
		n += 1
	return "CasaNova%d" % n


# ------------------------------------------------------------ internos
func _economy() -> Node:
	return get_tree().get_first_node_in_group("economy")


## Limite de ipezinhos sem as Moradias (pra mostrar o efeito na UI).
func _base_max_workers() -> int:
	var eco := _economy()
	var current: int = eco.max_workers if eco else 0
	return current - workers_per_moradia * upgrades.moradias


func _base_recovery_time() -> float:
	var w := get_tree().get_first_node_in_group("ipezinhos")
	return w.recovery_time if w else 30.0


func _update_visual() -> void:
	# quadro 0: começo, 1: sino + estandartes (estágio 3+), 2: lanternas + ouro (estágio 5)
	_visual.frame = 2 if level >= 5 else (1 if level >= 3 else 0)
	_name_label.text = "Centro da Vila\n%s" % stage_name()


func _popup(text: String, color: Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", 14)
	# empilha se já houver outro aviso subindo (ex.: expandir + melhorar em seguida)
	var stacked := get_children().filter(func(c): return c.has_meta("popup")).size()
	popup.set_meta("popup", true)
	popup.position = Vector2(-100, -150 - stacked * 20)
	popup.size = Vector2(200, 20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 1.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.8)
	tween.chain().tween_callback(popup.queue_free)
	var bump := create_tween()
	bump.tween_property(_visual, "scale", Vector2(2.1, 1.9), 0.08)
	bump.tween_property(_visual, "scale", Vector2(2, 2), 0.14)


# ------------------------------------------------------------ save/load (SaveManager)
## O efeito das melhorias NÃO é reaplicado aqui: max_workers vem salvo na
## economia e as casas construídas vêm salvas em cada casa.
func get_save_data() -> Dictionary:
	return {"level": level, "upgrades": upgrades.duplicate()}


func load_save_data(d: Dictionary) -> void:
	level = clampi(SaveUtil.integer(d, "level", level), 1, max_level())
	var saved := SaveUtil.dict(d, "upgrades")
	for id in UPGRADE_IDS:
		upgrades[id] = clampi(SaveUtil.integer(saved, id, upgrades[id]), 0, upgrade_max(id))
	_update_visual()
