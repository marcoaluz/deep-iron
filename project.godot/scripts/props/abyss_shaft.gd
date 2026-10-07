extends Node2D
## Plataforma do ABISMO (nível 3, grupo "elevador_abismo"): fica no fundo do nível 2,
## arruinada. O jogador conserta (peças raras + créditos + prata + tempo) e ela vira
## um elevador igual ao do nível 2 (NavigationLink2D, nos dois sentidos).
## Bloco 96: o conserto é uma OBRA de engenheiro: a prata vai pro lugar nas costas dele (ObraSite) e o tempo só anda
## com ele trabalhando (antes andava sozinho). Save antigo consertando: material todo entregue, falta o engenheiro.
## Lá embaixo: basalto em brasa, SOLARITA (precisa do Traje de chumbo da Oficina),
## acidentes bem mais comuns e mais graves, e o calor tira o ânimo de quem trabalha lá.

signal opened

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96
const RUIN := preload("res://assets/game/elevador_ruina.png")
const CAGE := preload("res://assets/game/elevador.png")

## Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do abismo).
@export var bottom_position: Vector2 = Vector2(-360, 1500)
@export var link_travel_cost: float = 0.05

@export_group("Andar (Bloco 71)")
## A mesma plataforma serve de ligação pros níveis novos (montada pelo ambiente a partir do .tres):
## grupo próprio, o nível que ela abre e a ligação de cima que tem que estar aberta antes.
@export var grupo: String = "elevador_abismo"
@export var nivel_id: String = "S3"
@export var requer_grupo: String = "elevador"
## Minério gasto no conserto (o do abismo é prata).
@export var repair_ore: String = "prata"

@export_group("Conserto")
@export var repair_parts: int = 12
@export var repair_credits: int = 1500
@export var repair_silver: int = 150
@export var repair_time: float = 120.0
## Estágio mínimo da vila pra começar o conserto.
@export var repair_min_stage: int = 4

var panel_id := "abismo"
var unlocked: bool = false

@export_group("Viagem (Bloco 68)")
## Segundos na gaiola por viagem e quantos cabem nela de uma vez (mais gente = espera a próxima).
@export var travel_time: float = 1.6
@export var capacity: int = 4
var _riders: Array = []  # fim da viagem (s do relógio) de quem está na gaiola


## Bloco 68: quanto tempo esse ipezinho fica na gaiola (a viagem + a fila, se lotou).
func ride_wait() -> float:
	var now := Time.get_ticks_msec() / 1000.0
	_riders = _riders.filter(func(t): return t > now)
	var fila := int(_riders.size() / maxi(capacity, 1))
	var espera := travel_time * (1 + fila) / maxf(Engine.time_scale, 0.01)
	_riders.append(now + espera)
	return travel_time * (1 + fila)


## Bloco 68: por que a plataforma ainda está fechada (o nível S3 lê daqui).
func reason_locked() -> String:
	if unlocked:
		return ""
	var r := repair_block_reason()
	return "consertar a plataforma" + ((" (%s)" % r) if r != "" and r != "consertando" else (" (consertando)" if r == "consertando" else ""))
var repairing: bool = false
var repair_left: float = 0.0
var _obra := ObraSite.new()  # Bloco 96
var _sound_timer := 0.0

@onready var _top_sprite: Sprite2D = $Top/Sprite
@onready var _top_lamp: PointLight2D = $Top/Lamp
@onready var _top_label: Label = $Top/Label
@onready var _bottom: Node2D = $Bottom
@onready var _bottom_label: Label = $Bottom/Label
@onready var _link: NavigationLink2D = $Link
@onready var _sparks: CPUParticles2D = $Top/Sparks


func _ready() -> void:
	add_to_group(grupo)
	add_to_group("elevadores")  # Bloco 71: toda ligação entre andares (o ipezinho entra na gaiola)
	add_to_group("clickable")
	_top_lamp.add_to_group("cullable_lights")
	_bottom.position = bottom_position - global_position
	_link.start_position = Vector2.ZERO
	_link.end_position = bottom_position - global_position
	_link.bidirectional = true
	_link.travel_cost = link_travel_cost
	_link.enter_cost = 0.0
	_apply(false)


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-26, -64), Vector2(52, 68)).has_point(p)


func level2_open() -> bool:
	var shaft := get_tree().get_first_node_in_group(requer_grupo)
	return shaft != null and shaft.unlocked


## Bloco 71: o nível que esta ligação abre (dados) — nome e textos.
func nivel() -> Resource:
	return preload("res://scripts/core/niveis.gd").por_id(nivel_id)


func _nome_nivel() -> String:
	var n := nivel()
	return n.nome if n else nivel_id


func _nome_acima() -> String:
	var acima := get_tree().get_first_node_in_group(requer_grupo)
	if acima and acima.has_method("_nome_nivel"):
		return acima._nome_nivel()
	return "o nível 2"


## "" = pode consertar; "aberta" / "consertando"; senão o que falta.
func repair_block_reason() -> String:
	if unlocked:
		return "aberta"
	if repairing:
		return "consertando"
	if not level2_open():
		return "%s ainda está fechado" % _nome_acima()
	var pq := preload("res://scripts/core/niveis.gd").pesquisa_falta(get_tree(), nivel_id)  # Bloco 68: o nível pede pesquisa
	if pq != "":
		return pq
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < repair_min_stage:
		return "requer vila nível %d" % repair_min_stage
	var parts: Array[String] = []
	var finds := get_tree().get_first_node_in_group("finds")
	if finds and finds.rare_parts < repair_parts:
		parts.append("%d peças raras" % (repair_parts - finds.rare_parts))
	var eco := get_tree().get_first_node_in_group("economy")
	if eco:
		var m: String = eco.missing_text(repair_credits, repair_silver, repair_ore)
		if m != "":
			parts.append(m.trim_prefix("falta "))
	return "falta " + ", ".join(parts) if not parts.is_empty() else ""


func start_repair() -> bool:
	if repair_block_reason() != "":
		Audio.error()
		return false
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(repair_credits, repair_silver, repair_ore):
		return false
	get_tree().get_first_node_in_group("finds").spend_parts(repair_parts)
	repairing = true
	repair_left = repair_time
	_obra.start()  # Bloco 96: o material fica reservado; o engenheiro leva e conserta
	add_to_group("obras")
	_apply(false)
	return true


func repair_progress() -> float:
	return clampf(1.0 - repair_left / repair_time, 0.0, 1.0) if repairing else (1.0 if unlocked else 0.0)


func _process(delta: float) -> void:
	if not repairing:
		return
	if _obra.has_engineer():  # Bloco 96: o barulho e as faíscas só com o engenheiro trabalhando
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = 0.8 * randf_range(0.8, 1.2)
			Audio.forge(global_position)
	_top_label.text = "Consertando a plataforma\n%s" % _obra.status(repair_progress())


## Bloco 96: o engenheiro trabalhou `seconds` no conserto.
func obra_work(seconds: float) -> void:
	if not repairing:
		return
	repair_left -= seconds
	if repair_left <= 0.0:
		_termina_conserto()


func _termina_conserto() -> void:
	repairing = false
	remove_from_group("obras")
	unlocked = true
	_apply(true)
	var hud := get_tree().get_first_node_in_group("hud")
	var n := nivel()
	if hud and n and n.titulo_abertura != "":
		hud.show_banner(n.titulo_abertura, n.descricao)  # Bloco 71: os níveis novos (dados)
	elif hud:
		hud.show_banner("O ABISMO ABRIU!",
			"A plataforma desce pro nível 3. Lá tem SOLARITA (precisa do Traje de chumbo), mas o calor e os acidentes são brutais.")
	Audio.fanfare()
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		diary.unlock("nivel_" + nivel_id)  # Bloco 71 (S4, S5; o abismo não tem página própria)
	opened.emit()


func _apply(animate: bool) -> void:
	_top_sprite.texture = CAGE if unlocked else RUIN
	_top_lamp.enabled = unlocked
	_link.enabled = unlocked
	_sparks.emitting = repairing
	var abismo := nivel_id == "S3"
	if unlocked:
		_top_label.text = "descida pro ABISMO (nível 3)" if abismo else "descida pro %s" % _nome_nivel()
		_top_label.modulate = Color(1.0, 0.65, 0.4)
	elif not repairing:
		_top_label.text = "Plataforma arruinada\nclique pra consertar"
		_top_label.modulate = Color(0.8, 0.75, 0.7)
	if unlocked:
		_bottom_label.text = "Nível 3 — o ABISMO" if abismo else _nome_nivel()
	else:
		_bottom_label.text = "%s — sem acesso (a plataforma lá em cima está arruinada)" % ("Nível 3" if abismo else nivel_id)
	_bottom_label.modulate = Color(1.0, 0.6, 0.4, 0.95) if unlocked else Color(1, 0.55, 0.45, 0.8)
	if animate:
		_top_sprite.scale = Vector2(2.6, 1.4)
		create_tween().tween_property(_top_sprite, "scale", Vector2(2, 2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Audio.forge(global_position)
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed(animate)


func obra_pending() -> bool:
	return repairing


func obra_title() -> String:
	return "Plataforma do %s" % (nivel_id if nivel_id != "S3" else "abismo")


func obra_progress() -> float:
	return repair_progress()


func obra_position(worker: Node) -> Vector2:
	return global_position + Vector2(0, 34) + _obra.offset_for(worker)


## Cancelado: a plataforma volta a arruinada; as peças raras voltam (créditos e prata: ObraSite.cancelar).
func obra_cancelar() -> void:
	repairing = false
	repair_left = 0.0
	remove_from_group("obras")
	var finds := get_tree().get_first_node_in_group("finds")
	if finds:
		finds.rare_parts += repair_parts
	_apply(false)


# ------------------------------------------------------------ obra (Bloco 96: conserto por engenheiro, com material)
func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"unlocked": unlocked, "repairing": repairing, "repair_left": repair_left, "obra": _obra.get_save_data()}


func load_save_data(d: Dictionary) -> void:
	unlocked = SaveUtil.boolean(d, "unlocked", false)
	repairing = SaveUtil.boolean(d, "repairing", false) and not unlocked
	repair_left = clampf(SaveUtil.num(d, "repair_left", repair_time), 0.0, repair_time) if repairing else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))  # Bloco 96 (save antigo: sem material = tudo entregue)
	if repairing:
		add_to_group("obras")
	elif is_in_group("obras"):
		remove_from_group("obras")
	_apply(false)
