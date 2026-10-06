extends Node2D
## Barricada (grupo "barricadas"): o muro no portão por onde as criaturas da floresta entram.
##   "tunel" — o portão da floresta na paliçada (Lumívoros). É o ÚNICO portão: o do poço do elevador
##             saiu no Bloco 80 (o que sobe do fundo entra direto; os guardas fazem posto lá).
## Níveis: 0 = só as estacas (não segura nada), 1 = paliçada de madeira, 2 = muro de
## pedra, 3 = portão de ferro. Tem vida: as criaturas param aqui e batem até quebrar.
## Os ipezinhos passam pelo portão normalmente. Conserto e ampliação: janela de Defesa (G).

signal broken
signal repaired

const SaveUtil := preload("res://scripts/core/save_util.gd")
const LEVEL_NAMES := ["sem muro", "Paliçada de madeira", "Muro de pedra", "Portão de ferro"]

@export_enum("tunel") var gate_id: String = "tunel"
## Bloco 74: o portão numa paliçada de norte a sul (a vila fica a leste): a arte vira de lado.
@export var vertical := false
@export var display_name: String = "Portão do túnel"
## Vida por nível (índice = nível).
@export var hp_per_level: Array[float] = [0.0, 120.0, 260.0, 450.0]
## Ampliar pro nível i: x = créditos, y = minério, z = madeira. (índice 0 não usado)
@export var upgrade_costs: Array[Vector3i] = [Vector3i.ZERO, Vector3i(80, 0, 60), Vector3i(250, 120, 40), Vector3i(500, 200, 30)]
## Minério gasto em cada nível ("" = qualquer).
@export var upgrade_ore: Array[String] = ["", "", "ferro", "ferro"]
## Madeira gasta por ponto de vida consertado.
@export var repair_wood_per_hp: float = 0.25

var panel_id := "defesa"
var level: int = 0
var hp: float = 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $StatusLabel
@onready var _bar: ProgressBar = $HpBar


func _ready() -> void:
	add_to_group("barricadas")
	add_to_group("clickable")
	_update_visual()


func contains_point(p: Vector2) -> bool:
	if vertical:  # (a mesma caixa, de lado: a abertura corre de norte a sul)
		return Rect2(global_position + Vector2(-36, -38), Vector2(42, 76)).has_point(p)
	return Rect2(global_position + Vector2(-38, -36), Vector2(76, 42)).has_point(p)


## Bloco 74: pra que lado fica a vila (os guardas ficam desse lado do portão).
func inside_dir() -> Vector2:
	return Vector2.RIGHT if vertical else Vector2.DOWN


## Área onde a decoração do mapa é escondida (environment.gd).
func decor_clear_rect() -> Rect2:
	if vertical:
		return Rect2(global_position + Vector2(-30, -40), Vector2(36, 80))
	return Rect2(global_position + Vector2(-40, -30), Vector2(80, 36))


func max_hp() -> float:
	return hp_per_level[clampi(level, 0, hp_per_level.size() - 1)]


## Segura as criaturas agora?
func is_standing() -> bool:
	return level > 0 and hp > 0.0


func damage(amount: float) -> void:
	if not is_standing():
		return
	hp = maxf(hp - amount, 0.0)
	_visual.position.x = randf_range(-1.5, 1.5)
	create_tween().tween_property(_visual, "position:x", 0.0, 0.12)
	if hp <= 0.0:
		Audio.gate_break(global_position)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("%s foi derrubado! As criaturas estão entrando." % display_name, Color(1.0, 0.4, 0.35))
		broken.emit()
	_update_visual()


func upgrade_block_reason() -> String:
	if level >= hp_per_level.size() - 1:
		return "nível máximo"
	var c := upgrade_costs[level + 1]
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.metal_falta(c.x, c.y, upgrade_ore[level + 1], c.z) if eco else "sem recursos"  # Bloco 87: barra


func upgrade() -> bool:
	if upgrade_block_reason() != "":
		Audio.error()
		return false
	var c := upgrade_costs[level + 1]
	if not get_tree().get_first_node_in_group("economy").paga_metal(c.x, c.y, upgrade_ore[level + 1], c.z):
		return false
	level += 1
	hp = max_hp()  # muro novo, inteiro
	_visual.scale = Vector2(2.0, 1.4)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.forge(global_position)
	_update_visual()
	return true


func repair_cost() -> int:
	return ceili((max_hp() - hp) * repair_wood_per_hp)


func repair_block_reason() -> String:
	if level == 0:
		return "sem muro"
	if hp >= max_hp():
		return "inteiro"
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(0, 0, "", repair_cost()) if eco else "sem recursos"


func repair() -> bool:
	if repair_block_reason() != "":
		Audio.error()
		return false
	if not get_tree().get_first_node_in_group("economy").spend(0, 0, "", repair_cost()):
		return false
	hp = max_hp()
	Audio.forge(global_position)
	repaired.emit()
	_update_visual()
	return true


func _update_visual() -> void:
	_visual.frame = level if is_standing() else 0
	_visual.modulate = Color.WHITE if is_standing() or level == 0 else Color(0.7, 0.6, 0.55)
	_bar.visible = level > 0 and hp < max_hp()
	_bar.max_value = maxf(max_hp(), 1.0)
	_bar.value = hp
	if level == 0:
		_label.text = "%s\n(sem muro)" % display_name
		_label.modulate = Color(0.8, 0.75, 0.7, 0.8)
	elif hp <= 0.0:
		_label.text = "%s\nDERRUBADO" % display_name
		_label.modulate = Color(1.0, 0.45, 0.4)
	else:
		_label.text = display_name
		_label.modulate = Color(0.9, 0.85, 0.75, 0.85)


# ------------------------------------------------------------ save/load (SaveManager, pelo nome do nó)
func get_save_data() -> Dictionary:
	return {"level": level, "hp": hp}


func load_save_data(d: Dictionary) -> void:
	level = clampi(SaveUtil.integer(d, "level", 0), 0, hp_per_level.size() - 1)
	hp = clampf(SaveUtil.num(d, "hp", max_hp()), 0.0, max_hp())
	_update_visual()
