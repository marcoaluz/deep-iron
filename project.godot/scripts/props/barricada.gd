extends Node2D
## Barricada (grupo "barricadas"): o muro no portão por onde as criaturas da floresta entram.
##   "tunel" — o portão da floresta na paliçada (Lumívoros). É o ÚNICO portão: o do poço do elevador
##             saiu no Bloco 80 (o que sobe do fundo entra direto; os guardas fazem posto lá).
## Níveis: 0 = só as estacas (não segura nada), 1 = paliçada de madeira, 2 = muro de
## pedra, 3 = portão de ferro. Tem vida: as criaturas param aqui e batem até quebrar.
## Os ipezinhos passam pelo portão normalmente. Conserto e ampliação: janela de Defesa (G).
## Bloco 96: subir de nível e o conserto GRANDE viram OBRA de engenheiro, com o material levado por ele (ObraSite);
## o muro sobe/fica inteiro quando a obra acaba. Conserto pequeno (até conserto_na_hora de madeira): na hora.

signal broken
signal repaired

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96
const LEVEL_NAMES := ["sem muro", "Paliçada de madeira", "Muro de pedra", "Portão de ferro"]

@export_enum("tunel") var gate_id: String = "tunel"
## Bloco 74: o portão numa paliçada de norte a sul (a vila fica a leste): a arte vira de lado.
@export var vertical := false
@export var display_name: String = "Portão do túnel"
## Vida por nível (índice = nível).
@export var hp_per_level: Array[float] = [0.0, 120.0, 260.0, 450.0]
## Ampliar pro nível i: x = créditos, y = minério, z = madeira. (índice 0 não usado)
## Bloco 94: o nível 3 baixou de 200 pra 170 ferro (85 barras) e pede pregos e ferragens (upgrade_itens).
@export var upgrade_costs: Array[Vector3i] = [Vector3i.ZERO, Vector3i(80, 0, 60), Vector3i(250, 120, 40), Vector3i(500, 170, 30)]
## Minério gasto em cada nível ("" = qualquer).
@export var upgrade_ore: Array[String] = ["", "", "ferro", "ferro"]
## Bloco 94: itens a mais de cada nível ({item: qtd}); antes da fornalha, pregos e ferragens viram ferro (Economy).
@export var upgrade_itens: Array[Dictionary] = [{}, {}, {}, {"prego": 12, "ferragem": 4}]
## Madeira gasta por ponto de vida consertado.
@export var repair_wood_per_hp: float = 0.25
## Bloco 96: segundos de engenheiro pra subir pro nível i (índice 0 não usado).
@export var upgrade_tempos: Array[float] = [0.0, 30.0, 45.0, 60.0]
## Bloco 96: conserto de até esta madeira é feito NA HORA (pequeno); acima, vira obra de engenheiro.
@export var conserto_na_hora: float = 10.0
## Bloco 96: segundos de engenheiro por unidade de madeira do conserto grande.
@export var conserto_segundos_por_madeira: float = 0.8

var panel_id := "defesa"
var level: int = 0
var hp: float = 0.0
## Bloco 96: a obra em andamento ("" / "nivel" / "conserto"), o tempo dela e a peça comum de obra.
var obra_tipo := ""
var obra_total := 0.0
var obra_left := 0.0
var _obra := ObraSite.new()

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


## Bloco 94: os itens a mais do próximo nível.
func upgrade_item_cost() -> Dictionary:
	var i := level + 1
	return upgrade_itens[i] if i < upgrade_itens.size() else {}


func upgrade_block_reason() -> String:
	if obra_tipo != "":
		return "em obra (%s)" % _obra.status(obra_progress())  # Bloco 96
	if level >= hp_per_level.size() - 1:
		return "nível máximo"
	var c := upgrade_costs[level + 1]
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.metal_falta(c.x, c.y, upgrade_ore[level + 1], c.z, upgrade_item_cost()) if eco else "sem recursos"  # Bloco 87: barra; 94: peças


func upgrade() -> bool:
	if upgrade_block_reason() != "":
		Audio.error()
		return false
	var c := upgrade_costs[level + 1]
	if not get_tree().get_first_node_in_group("economy").paga_metal(c.x, c.y, upgrade_ore[level + 1], c.z, upgrade_item_cost()):
		return false
	_comeca_obra("nivel", upgrade_tempos[level + 1] if level + 1 < upgrade_tempos.size() else 45.0)  # Bloco 96
	return true


## Bloco 96: o muro sobe quando a obra acaba.
func _sobe_nivel() -> void:
	level += 1
	hp = max_hp()  # muro novo, inteiro
	_visual.scale = Vector2(2.0, 1.4)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.forge(global_position)
	_update_visual()


func repair_cost() -> int:
	return ceili((max_hp() - hp) * repair_wood_per_hp)


func repair_block_reason() -> String:
	if obra_tipo != "":
		return "em obra (%s)" % _obra.status(obra_progress())  # Bloco 96
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
	var madeira := repair_cost()
	if not get_tree().get_first_node_in_group("economy").spend(0, 0, "", madeira):
		return false
	if madeira > conserto_na_hora:  # Bloco 96: conserto grande = obra de engenheiro (a madeira vai nas costas)
		_comeca_obra("conserto", float(madeira) * conserto_segundos_por_madeira)
		return true
	_conserta()
	return true


func _conserta() -> void:
	hp = max_hp()
	Audio.forge(global_position)
	repaired.emit()
	_update_visual()


func _comeca_obra(tipo: String, segundos: float) -> void:
	obra_tipo = tipo
	obra_total = maxf(segundos, 1.0)
	obra_left = obra_total
	_obra.start()
	add_to_group("obras")
	_update_visual()


# ------------------------------------------------------------ obra (Bloco 96)
func obra_pending() -> bool:
	return obra_tipo != ""


func obra_title() -> String:
	return "%s: %s" % [display_name, LEVEL_NAMES[mini(level + 1, LEVEL_NAMES.size() - 1)] if obra_tipo == "nivel" else "conserto"]


func obra_progress() -> float:
	return clampf(1.0 - obra_left / obra_total, 0.0, 1.0) if obra_total > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return global_position + inside_dir() * 34.0 + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	if obra_tipo == "":
		return
	obra_left -= seconds
	if obra_left > 0.0:
		return
	var tipo := obra_tipo
	_fim_obra()
	if tipo == "nivel":
		_sobe_nivel()
	else:
		_conserta()


func _fim_obra() -> void:
	obra_tipo = ""
	obra_total = 0.0
	obra_left = 0.0
	remove_from_group("obras")
	_update_visual()


## Cancelado: o muro fica como estava (créditos e material: ObraSite.cancelar).
func obra_cancelar() -> void:
	_fim_obra()


# ------------------------------------------------------------ obra (Bloco 96: conserto por engenheiro, com material)
func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()



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
	return {"level": level, "hp": hp, "obra_tipo": obra_tipo, "obra_total": obra_total, "obra_left": obra_left,
		"obra": _obra.get_save_data()}


## Bloco 96: save antigo = sem obra (as ampliações eram na hora).
func load_save_data(d: Dictionary) -> void:
	level = clampi(SaveUtil.integer(d, "level", 0), 0, hp_per_level.size() - 1)
	hp = clampf(SaveUtil.num(d, "hp", max_hp()), 0.0, max_hp())
	var t := SaveUtil.text(d, "obra_tipo", "")
	obra_tipo = t if t in ["nivel", "conserto"] and not (t == "nivel" and level >= hp_per_level.size() - 1) else ""
	obra_total = maxf(SaveUtil.num(d, "obra_total", 0.0), 1.0) if obra_tipo != "" else 0.0
	obra_left = clampf(SaveUtil.num(d, "obra_left", obra_total), 0.0, obra_total) if obra_tipo != "" else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	if obra_tipo != "":
		add_to_group("obras")
	elif is_in_group("obras"):
		remove_from_group("obras")
	_update_visual()
