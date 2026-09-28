extends "res://scripts/props/station.gd"
## Jazida de minério. Esgota com a mineração e regenera aos poucos.
##
## ore_type diz o que ela dá (ferro, cobre, carvão). Tipos que precisam de
## ferramenta ficam BLOQUEADOS (escuros, com cadeado, ninguém minera) até a
## Oficina fabricar a ferramenta certa.
##
## Bloco 33: GALERIAS LACRADAS. Uma jazida com min_village_level > 1 fica atrás de
## entulho, dentro da mina de sempre, até a vila chegar nesse estágio ("Expandir a
## vila" no Centro). O mapa não cresce: expandir só abre essas galerias.

const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const RUBBLE_TEXTURE := preload("res://assets/game/entulho.png")

signal depleted
signal replenished

@export_group("Mineração")
## Tipo de minério desta jazida: "ferro", "cobre" ou "carvao".
@export_enum("ferro", "cobre", "carvao", "prata", "solarita") var ore_type: String = "ferro"
## Minério tirado por segundo por ipezinho (ritmo: era 4.0).
@export var MINE_RATE: float = 3.0
@export var ore_total: float = 200.0
## Minério regenerado por segundo (0 = não regenera).
@export var regen_rate: float = 0.45
## Segundos "morta" depois de esgotar, antes de começar a regenerar.
@export var depleted_cooldown: float = 20.0
## Abaixo disso a jazida não atrai novos ipezinhos (quem já está minerando continua).
@export var min_ore_to_mine: float = 15.0

@export_group("Zona de perigo (Bloco 42)")
## Jazida dentro de uma zona de perigo (hazard_zone.gd): só minera quem veste o traje certo.
## "" = jazida comum; "gas", "calor" ou "radiacao" = precisa do traje desse perigo.
@export var hazard: String = ""

@export_group("Galeria lacrada (Bloco 33)")
## Estágio da vila que abre esta jazida (1 = aberta desde o começo).
@export_range(1, 5) var min_village_level: int = 1
## Nome da galeria pros avisos ("oeste", "sudeste"...).
@export var gallery_name: String = ""

@export_group("Visual")
## Variantes de sprite sorteadas no _ready (vazio = mantém a textura da cena).
@export var textures: Array[Texture2D] = []
@export var min_visual_scale: float = 0.6

var ore_remaining: float = 0.0
var _cooldown: float = 0.0
var _hit_time: float = 0.0
var _base_scale: Vector2
var _unlocked: bool = true
var _needs_descent: bool = false  # trancada porque o nível 2 ainda não abriu
var _needs_village: bool = false  # Bloco 33: galeria lacrada até a vila crescer
var _rubble: Sprite2D = null  # entulho com tábuas em X na frente da galeria lacrada

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel
@onready var _chips: CPUParticles2D = $Chips
@onready var _padlock: Sprite2D = $Padlock


func _ready() -> void:
	super()
	add_to_group("minerios")
	ore_remaining = ore_total
	if not textures.is_empty():
		_visual.texture = textures[randi() % textures.size()]
		_visual.flip_h = randf() < 0.5
	_base_scale = _visual.scale
	if min_village_level > 1:
		_rubble = Sprite2D.new()
		_rubble.name = "Entulho"
		_rubble.texture = RUBBLE_TEXTURE
		_rubble.scale = Vector2(2, 2)
		_rubble.offset = Vector2(0, -8)
		_rubble.position = Vector2(0, 8)
		add_child(_rubble)
		move_child(_rubble, _visual.get_index() + 1)  # na frente da pedra, atrás do texto
	_chips.color = Ores.CHIP_COLORS.get(ore_type, _chips.color)
	on_unlock_changed.call_deferred()  # a Oficina pode entrar na árvore depois
	_update_visual()


func _accepts(body: Node2D) -> bool:
	return body.has_method("mine")


func is_usable() -> bool:
	return _unlocked and _cooldown <= 0.0 and ore_remaining >= minf(min_ore_to_mine, ore_total)


func is_unlocked() -> bool:
	return _unlocked


## Bloco 33: ainda atrás do entulho (a vila não chegou no estágio)?
func is_sealed() -> bool:
	return _needs_village


## Ipezinho só vem pra cá de mãos vazias ou já carregando o mesmo tipo.
func accepts_worker(worker: Node) -> bool:
	if hazard != "" and worker.has_method("can_enter_hazard") and not worker.can_enter_hazard(hazard):
		return false  # Bloco 42: sem o traje (nem no vestiário), nem tenta
	return worker.carrying <= 0.0 or worker.cargo_type == ore_type


## Quanto este minério vale em relação ao ferro (os ipezinhos preferem os mais valiosos).
func get_value_weight() -> float:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return 1.0
	return eco.price_of(ore_type) / maxf(eco.price_of("ferro"), 0.01)


## Chamado pela Oficina quando uma ferramenta fica pronta (animate = false ao carregar save).
func on_unlock_changed(animate: bool = true) -> void:
	var oficina := get_tree().get_first_node_in_group("oficina")
	var was := _unlocked
	var was_sealed := _needs_village
	# sem Oficina no mapa, nada fica bloqueado
	var tool_ok: bool = oficina == null or oficina.is_ore_unlocked(ore_type)
	# no nível 2, também precisa da descida aberta (escavadeira pronta)
	var env := get_tree().get_first_node_in_group("environment")
	var shaft := get_tree().get_first_node_in_group("elevador")
	_needs_descent = env != null and env.is_deep(global_position) and not (shaft != null and shaft.unlocked)
	# no abismo (nível 3), também precisa da plataforma consertada
	if env != null and env.has_method("is_abyss") and env.is_abyss(global_position):
		var abyss := get_tree().get_first_node_in_group("elevador_abismo")
		_needs_descent = _needs_descent or not (abyss != null and abyss.unlocked)
	# Bloco 33: galeria lacrada até a vila chegar no estágio
	var hub := get_tree().get_first_node_in_group("village_hub")
	_needs_village = hub != null and hub.level < min_village_level
	_unlocked = tool_ok and not _needs_descent and not _needs_village
	_update_rubble(was_sealed and animate)
	if _unlocked and not was and animate:
		var pop := create_tween()
		_visual.scale = _base_scale * 1.25
		pop.tween_property(_visual, "scale", _base_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_update_visual()


## Entulho aparece enquanto lacrada; ao abrir (animate) ele "desmancha" e some.
func _update_rubble(animate: bool) -> void:
	if _rubble == null:
		return
	if _needs_village:
		_rubble.visible = true
		_rubble.modulate = Color.WHITE
		_rubble.scale = Vector2(2, 2)
		return
	if not animate or not _rubble.visible:
		_rubble.visible = false
		return
	Audio.boom(global_position)
	var t := create_tween().set_parallel()
	t.tween_property(_rubble, "scale", Vector2(2.6, 0.6), 0.5).set_ease(Tween.EASE_IN)
	t.tween_property(_rubble, "modulate:a", 0.0, 0.5)
	t.chain().tween_callback(func(): _rubble.visible = false)


func has_ore() -> bool:
	return ore_remaining > 0.0


func is_depleted() -> bool:
	return _cooldown > 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown <= 0.0:
			replenished.emit()
	elif regen_rate > 0.0 and ore_remaining < ore_total:
		ore_remaining = minf(ore_remaining + regen_rate * delta, ore_total)

	var mined_any := false
	if ore_remaining > 0.0 and _unlocked:
		for body in _working_bodies():
			var amount: float = minf(MINE_RATE * delta, ore_remaining)
			var taken: float = body.mine(amount, ore_type)
			if taken > 0.0:
				mined_any = true
			ore_remaining -= taken
			if ore_remaining <= 0.0:
				ore_remaining = 0.0
				_cooldown = depleted_cooldown
				depleted.emit()
				break

	_hit_time = _hit_time + delta if mined_any else 0.0
	_chips.emitting = mined_any
	_update_visual()


func _update_visual() -> void:
	var ratio := ore_remaining / ore_total if ore_total > 0.0 else 0.0
	var s := lerpf(min_visual_scale, 1.0, sqrt(ratio))
	_visual.scale = _base_scale * s
	# tremidinha enquanto alguém bate com a picareta
	_visual.position.x = sin(_hit_time * 40.0) * 1.0 if _hit_time > 0.0 else 0.0
	_padlock.visible = not _unlocked and not _needs_village  # lacrada: o entulho já diz tudo
	if not _unlocked:
		_visual.modulate = Color(0.42, 0.42, 0.5)
		var oficina := get_tree().get_first_node_in_group("oficina")
		var tool: String = oficina.tool_for_ore(ore_type) if oficina else ""
		if _needs_village:
			var hub := get_tree().get_first_node_in_group("village_hub")
			_label.text = "Galeria lacrada (%s)\nabre com a vila: %s" % [Ores.display_name(ore_type).to_lower(), hub.stage_name(min_village_level) if hub else "?"]
		elif _needs_descent:
			_label.text = "%s: fechado até a\nescavadeira ficar pronta" % Ores.display_name(ore_type)
		else:
			_label.text = "%s: precisa de\n%s" % [Ores.display_name(ore_type), oficina.TOOL_NAMES[tool] if tool != "" else "?"]
		_label.modulate = Color(0.75, 0.75, 0.85, 0.8)
		_padlock.position.y = -16.0 + sin(Time.get_ticks_msec() * 0.003) * 1.5
	elif _cooldown > 0.0:
		_visual.modulate = Color(0.45, 0.45, 0.5)
		_label.text = "esgotado (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.55, 0.45)
	else:
		_visual.modulate = Color.WHITE
		_label.text = str(int(ore_remaining))
		if hazard != "":  # Bloco 42: zona de perigo — sem traje no vestiário, ninguém vem
			var eq := get_tree().get_first_node_in_group("equipment")
			if eq and eq.usable(hazard) + eq.in_use(hazard) == 0:
				_label.text += "\nsem %s" % eq.NAMES[hazard].to_lower()
		_label.modulate = Color(1, 1, 1, 0.9) if is_usable() else Color(1, 0.8, 0.4)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {
		"ore_remaining": ore_remaining,
		"cooldown": _cooldown,
		"variant": textures.find(_visual.texture),
		"flip": _visual.flip_h,
	}


func load_save_data(d: Dictionary) -> void:
	ore_remaining = clampf(SaveUtil.num(d, "ore_remaining", ore_remaining), 0.0, ore_total)
	_cooldown = maxf(SaveUtil.num(d, "cooldown", 0.0), 0.0)
	var variant := SaveUtil.integer(d, "variant", -1)
	if variant >= 0 and variant < textures.size():
		_visual.texture = textures[variant]
	_visual.flip_h = SaveUtil.boolean(d, "flip", _visual.flip_h)
	on_unlock_changed(false)
