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
##
## Bloco 102: o CATÁLOGO (catalogo.gd). Jazida de um tipo ainda não estudado é "pedra desconhecida": a placa não diz o
## nome, a vista iso desenha a pedra cinza, e o que sai dela é "minério desconhecido" (o catálogo anota de que tipo era
## e troca no armazém quando o tipo for estudado). A ferramenta continua valendo: sem ela, não minera.

const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const RUBBLE_TEXTURE := preload("res://assets/game/entulho.png")

signal depleted
signal replenished

@export_group("Mineração")
## Tipo de minério desta jazida: "ferro", "cobre" ou "carvao".
@export_enum("ferro", "cobre", "carvao", "prata", "solarita", "cristal_verde", "cristal_rubro", "gema_azul") var ore_type: String = "ferro"
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
var _motivo_descida := ""  # Bloco 71: por que a descida até aqui está fechada (texto do nível)
var _rubble: Sprite2D = null  # entulho com tábuas em X na frente da galeria lacrada
## Bloco 60: o entulho foi explodido com dinamite (a galeria abriu antes da vila crescer).
var blasted := false
var panel_id := "galeria"
## Bloco 102: o catálogo já estudou este tipo? (guardado: o catálogo avisa quando muda — on_unlock_changed)
var conhecido := true

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
	return worker.carrying <= 0.0 or worker.cargo_type == tipo_extraido()


## Bloco 102: o que sai daqui — o minério de verdade, ou "desconhecido" enquanto o catálogo não estudou o tipo.
func tipo_extraido() -> String:
	return ore_type if conhecido else Ores.DESCONHECIDO


## Bloco 102: dá pra chegar aqui? (não lacrada, com a descida aberta e fora do leste trancado; a ferramenta não conta:
## é o que a pesquisadora precisa pra estudar)
func acessivel() -> bool:
	if _needs_descent or _needs_village:
		return false
	var env := get_tree().get_first_node_in_group("environment")
	return not (env and env.has_method("trancado") and env.trancado(global_position))


func _catalogo() -> Node:
	return get_tree().get_first_node_in_group("catalogo") if is_inside_tree() else null


## Bloco 102: saiu minério desconhecido daqui — o catálogo anota de que tipo era.
func _anota_bruto(qtd: float) -> void:
	if conhecido or qtd <= 0.0:
		return
	var cat := _catalogo()
	if cat:
		cat.anota_bruto(ore_type, qtd)


## Quanto este minério vale em relação ao ferro (os ipezinhos preferem os mais valiosos).
func get_value_weight() -> float:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return 1.0
	return eco.price_of(tipo_extraido()) / maxf(eco.price_of("ferro"), 0.01)  # Bloco 102: pedra desconhecida vale pouco


## Chamado pela Oficina quando uma ferramenta fica pronta (animate = false ao carregar save).
func on_unlock_changed(animate: bool = true) -> void:
	var oficina := get_tree().get_first_node_in_group("oficina")
	var was := _unlocked
	var was_sealed := _needs_village
	var cat := _catalogo()
	var era_conhecido := conhecido
	conhecido = cat == null or cat.minerio_conhecido(ore_type)  # Bloco 102
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
	# Bloco 71: nos níveis novos (S4, S5), toda ligação do caminho até aqui aberta
	if env != null and env.has_method("nivel_extra_em"):
		var nx: Resource = env.nivel_extra_em(global_position)
		if nx:
			_needs_descent = _needs_descent or preload("res://scripts/core/niveis.gd").motivo(get_tree(), nx) != ""
	# Bloco 33: galeria lacrada até a vila chegar no estágio
	var hub := get_tree().get_first_node_in_group("village_hub")
	_needs_village = hub != null and hub.level < min_village_level and not blasted
	if _needs_village and not is_in_group("clickable"):
		add_to_group("clickable")  # Bloco 60: clique no entulho abre a janela da galeria
	elif not _needs_village and is_in_group("clickable"):
		remove_from_group("clickable")
	_unlocked = tool_ok and not _needs_descent and not _needs_village
	_motivo_descida = ""
	if _needs_descent and env != null:  # Bloco 71: o motivo do nível (pesquisa, plataforma...), não sempre "escavadeira"
		var nv: Resource = preload("res://scripts/core/niveis.gd").do_ponto(env, global_position)
		_motivo_descida = preload("res://scripts/core/niveis.gd").motivo(get_tree(), nv) if nv else ""
	_update_rubble(was_sealed and animate)
	if animate and ((_unlocked and not was) or (conhecido and not era_conhecido)):  # (Bloco 102: estudou o tipo)
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


## Bloco 57: o coletor de minério tira `amount` daqui (0 se trancada/esgotada). Esgotou: entra no
## descanso como na mineração manual.
func extract(amount: float) -> float:
	if not _unlocked or _cooldown > 0.0 or ore_remaining <= 0.0:
		return 0.0
	var taken := minf(amount, ore_remaining)
	ore_remaining -= taken
	_anota_bruto(taken)  # Bloco 102
	if ore_remaining <= 0.0:
		ore_remaining = 0.0
		_cooldown = depleted_cooldown
		depleted.emit()
	_update_visual()
	return taken


## Bloco 102: o nome na placa ("Pedra desconhecida" até o catálogo estudar o tipo).
func nome_visivel() -> String:
	return Ores.display_name(ore_type) if conhecido else "Pedra desconhecida"


## Bloco 71: a jazida fica num nível novo (S4, S5...)? Lá o motivo vem dos dados; no nível 2 e no
## abismo o texto de sempre continua.
func env_nivel_novo() -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	return env != null and env.has_method("nivel_extra_em") and env.nivel_extra_em(global_position) != null


## Bloco 60: dinamite no entulho.
func blast_open() -> void:
	blasted = true
	on_unlock_changed(true)


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-40, -60), Vector2(80, 70)).has_point(p)


func has_ore() -> bool:
	return ore_remaining > 0.0


func is_depleted() -> bool:
	return _cooldown > 0.0


var _eco: Node = null  # (Bloco 106: o ritmo_mineracao da Economia)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown <= 0.0:
			replenished.emit()
	elif regen_rate > 0.0 and ore_remaining < ore_total:
		ore_remaining = minf(ore_remaining + regen_rate * delta, ore_total)

	var mined_any := false
	if ore_remaining > 0.0 and _unlocked:
		if _eco == null or not is_instance_valid(_eco):
			_eco = get_tree().get_first_node_in_group("economy")
		var ritmo: float = float(_eco.ritmo_mineracao) if _eco and _eco.get("ritmo_mineracao") != null else 1.0  # Bloco 106
		for body in _working_bodies():
			var amount: float = minf(MINE_RATE * ritmo * delta, ore_remaining)
			var taken: float = body.mine(amount, tipo_extraido())  # Bloco 102: pedra desconhecida dá "desconhecido"
			_anota_bruto(taken)
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
		var nome := nome_visivel()  # Bloco 102: sem estudo, "Pedra desconhecida"
		if _needs_village:
			var hub := get_tree().get_first_node_in_group("village_hub")
			_label.text = "Galeria lacrada (%s)\nabre com a vila: %s" % [nome.to_lower(), hub.stage_name(min_village_level) if hub else "?"]
		elif _needs_descent and _motivo_descida != "" and env_nivel_novo():
			_label.text = "%s: %s" % [nome, _motivo_descida]
		elif _needs_descent:
			_label.text = "%s: fechado até a\nescavadeira ficar pronta" % nome
		elif not conhecido:
			_label.text = "Pedra desconhecida:\ndura demais (estude)"
		else:
			_label.text = "%s: precisa de\n%s" % [nome, oficina.TOOL_NAMES[tool] if tool != "" else "?"]
		_label.modulate = Color(0.75, 0.75, 0.85, 0.8)
		_padlock.position.y = -16.0 + sin(Time.get_ticks_msec() * 0.003) * 1.5
	elif _cooldown > 0.0:
		_visual.modulate = Color(0.45, 0.45, 0.5)
		_label.text = "esgotado (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.55, 0.45)
	else:
		_visual.modulate = Color.WHITE
		_label.text = str(int(ore_remaining)) if conhecido else "Pedra desconhecida  %d" % int(ore_remaining)
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
		"blasted": blasted,
	}


func load_save_data(d: Dictionary) -> void:
	ore_remaining = clampf(SaveUtil.num(d, "ore_remaining", ore_remaining), 0.0, ore_total)
	_cooldown = maxf(SaveUtil.num(d, "cooldown", 0.0), 0.0)
	var variant := SaveUtil.integer(d, "variant", -1)
	if variant >= 0 and variant < textures.size():
		_visual.texture = textures[variant]
	_visual.flip_h = SaveUtil.boolean(d, "flip", _visual.flip_h)
	blasted = SaveUtil.boolean(d, "blasted", false)  # Bloco 60
	on_unlock_changed(false)
