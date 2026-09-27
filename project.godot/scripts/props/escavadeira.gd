extends "res://scripts/props/station.gd"
## Canteiro da Escavadeira: projeto de fim de jogo montado peça por peça,
## como uma plataforma de perfuração (grupo "escavadeira").
##
## - 5 peças: Estrutura, Motor, Sistema hidráulico, Cabine e Broca.
## - Cada peça custa créditos + minério do armazém e leva um tempo de fabricação
##   aqui no canteiro (uma peça por vez). Os custos são pagos ao começar.
## - A Estrutura vem primeiro (o resto é montado nela); as outras em qualquer ordem.
## - Cada peça exige um estágio mínimo da vila (Centro da Vila).
## - No mapa, a escavadeira inteira aparece como "projeto" translúcido azulado;
##   cada peça pronta vira sólida. Com as 5, ela liga: a broca gira, a cabine e
##   o giroflex acendem e o sinal `completed` dispara (o HUD mostra a conquista).
##
## REATORES (Bloco 19): pronta, a escavadeira perfura sozinha e manda minério pro
## armazém. O ritmo e o efeito colateral dependem do reator instalado (um por vez,
## troca quando quiser). A Caldeira a vapor vem junto; os outros são construídos
## com peças raras, e três deles precisam de um achado do fundo da mina (finds.gd).

signal part_started(id: String)
signal part_installed(id: String)
signal completed

const SaveUtil := preload("res://scripts/core/save_util.gd")
const PART_IDS := ["estrutura", "motor", "hidraulica", "cabine", "broca"]
const PART_NAMES := {
	"estrutura": "Estrutura",
	"motor": "Motor",
	"hidraulica": "Sistema hidráulico",
	"cabine": "Cabine",
	"broca": "Broca",
}
const PART_DESCRIPTIONS := {
	"estrutura": "Torre treliçada e convés de aço. Base de todas as outras peças.",
	"motor": "Motor a diesel que dá força pra broca.",
	"hidraulica": "Cilindros e tanque de óleo que empurram a broca pra baixo.",
	"cabine": "Onde o operador controla a máquina.",
	"broca": "A broca helicoidal gigante. A última peça do projeto.",
}
const REACTOR_IDS := ["vapor", "diesel", "cristal", "solar", "fusao"]
const REACTOR_NAMES := {
	"vapor": "Caldeira a vapor",
	"diesel": "Motor a diesel",
	"cristal": "Cristal ressonante",
	"solar": "Núcleo solar",
	"fusao": "Fusão improvisada",
}
const REACTOR_DESCRIPTIONS := {
	"vapor": "Gasta carvão do armazém; sem carvão, a broca para.",
	"diesel": "Não gasta nada, mas o barulho tira ânimo da vila.",
	"cristal": "Fraco, mas a ressonância dobra a chance de achados.",
	"solar": "Forte e sem combustível, mas vaza: mais acidentes na mina.",
	"fusao": "O mais forte, mas instável: às vezes explode e machuca quem está perto.",
}
## Achado necessário pra construir o reator (finds.gd).
const REACTOR_ITEM := {"cristal": "cristal", "solar": "solar", "fusao": "bobina"}
## Que minério sai da broca com cada reator (pesos).
const REACTOR_MIX := {
	"vapor": {"ferro": 0.7, "cobre": 0.2, "carvao": 0.1},
	"diesel": {"ferro": 0.7, "cobre": 0.2, "carvao": 0.1},
	"cristal": {"ferro": 0.4, "cobre": 0.3, "prata": 0.3},
	"solar": {"ferro": 0.5, "cobre": 0.3, "prata": 0.2},
	"fusao": {"ferro": 0.5, "cobre": 0.25, "carvao": 0.1, "prata": 0.15},
}

## "Planta" azulada das peças que ainda não foram feitas (valores > 1 brilham mesmo no escuro).
const GHOST_COLOR := Color(0.75, 1.0, 1.5, 0.4)

@export_group("Peças (na ordem de PART_IDS)")
## Custo de cada peça: x = créditos, y = minério do armazém, z = segundos de fabricação.
@export var part_costs: Array[Vector3i] = [
	Vector3i(500, 190, 45),   # estrutura
	Vector3i(875, 310, 60),   # motor
	Vector3i(750, 375, 50),   # hidráulica
	Vector3i(625, 250, 45),   # cabine
	Vector3i(1500, 625, 90),  # broca
]
## Estágio mínimo da vila pra fabricar cada peça.
@export var part_min_stage: Array[int] = [2, 3, 3, 3, 4]

@export_group("Reatores (na ordem de REACTOR_IDS)")
## Minério por segundo que a broca manda pro armazém com cada reator.
@export var reactor_rates: Array[float] = [0.3, 0.55, 0.35, 0.9, 1.5]
## Construir: x = créditos, y = ferro, z = peças raras. (A Caldeira vem com a escavadeira.)
@export var reactor_costs: Array[Vector3i] = [
	Vector3i(0, 0, 0),
	Vector3i(300, 60, 4),
	Vector3i(200, 0, 3),
	Vector3i(500, 80, 5),
	Vector3i(800, 150, 8),
]
## Caldeira: carvão gasto por segundo.
@export var vapor_coal_per_sec: float = 0.08
## Diesel: ânimo a menos pra todos enquanto liga.
@export var diesel_noise: float = 4.0
## Cristal: multiplica a chance de achado.
@export var cristal_find_mult: float = 2.0
## Solar: multiplica a chance de acidente na mina.
@export var solar_accident_mult: float = 1.5
## Fusão: a cada fusao_check_interval s, fusao_meltdown_chance de pane.
@export var fusao_check_interval: float = 60.0
@export_range(0.0, 1.0) var fusao_meltdown_chance: float = 0.08
## Segundos desligada depois da pane, e raio da explosão (machuca grave).
@export var fusao_outage: float = 90.0
@export var fusao_blast_radius: float = 150.0

@export_group("Efeitos")
## Intervalo entre as marteladas enquanto fabrica.
@export var forge_sound_interval: float = 0.8
## Velocidade da animação da broca quando pronta (quadros por segundo).
@export var drill_fps: float = 8.0

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "escavadeira"
var installed: Dictionary = {}
var fabricating: String = ""
var fab_left: float = 0.0
var complete: bool = false
## Reator instalado ("" antes de ficar pronta) e os que já foram construídos.
var reactor: String = ""
var built_reactors: Array = []
var drill_on: bool = true
## Segundos até voltar da pane (fusão).
var outage_left: float = 0.0
var no_fuel: bool = false
var _drill_accum := 0.0
var _fuel_accum := 0.0
var _fuel_retry := 0.0
var _fusao_timer := 0.0

var _sound_timer: float = 0.0
var _anim_time: float = 0.0

@onready var _layers: Dictionary = {
	"estrutura": $Estrutura,
	"hidraulica": $Hidraulica,
	"motor": $Motor,
	"broca": $Broca,
	"cabine": $Cabine,
}
@onready var _sparks: CPUParticles2D = $Sparks
@onready var _dust: CPUParticles2D = $Dust
@onready var _beacon: PointLight2D = $Beacon
@onready var _cab_light: PointLight2D = $CabLight
@onready var _work_light: PointLight2D = $WorkLight
@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("escavadeira")
	add_to_group("clickable")
	for id in PART_IDS:
		installed[id] = false
	for light in [_beacon, _cab_light, _work_light]:
		light.add_to_group("cullable_lights")
	_update_visual()


func _process(delta: float) -> void:
	if fabricating != "":
		fab_left -= delta
		_sound_timer -= delta
		if _sound_timer <= 0.0:
			_sound_timer = forge_sound_interval * randf_range(0.8, 1.2)
			Audio.forge(global_position + Vector2(0, -90))
		if fab_left <= 0.0:
			_install(fabricating)
		else:
			# o "projeto" da peça pulsa enquanto é fabricada
			var layer: Sprite2D = _layers[fabricating]
			layer.modulate.a = 0.4 + 0.35 * (sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5)
		_update_label()
	if complete:
		_drill(delta)
		if reactor_active():
			_anim_time += delta
			_layers.broca.frame = int(_anim_time * drill_fps) % 2
		_beacon.energy = 0.9 + 0.6 * absf(sin(_anim_time * 3.0)) if reactor_active() else 0.3
		_update_label()


## Área clicável (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-80, -192), Vector2(160, 196)).has_point(p)


## Pro ambiente não espalhar pedras/tochas em cima da torre.
func get_clear_center() -> Vector2:
	return global_position + Vector2(0, -90)


func get_clear_radius() -> float:
	return 130.0


# ------------------------------------------------------------ consulta (UI)
func installed_count() -> int:
	var n := 0
	for id in PART_IDS:
		if installed[id]:
			n += 1
	return n


func part_cost(id: String) -> Vector3i:
	return part_costs[PART_IDS.find(id)]


func part_stage(id: String) -> int:
	return part_min_stage[PART_IDS.find(id)]


## 0..1 da peça em fabricação.
func fab_progress() -> float:
	if fabricating == "":
		return 0.0
	var total := float(part_cost(fabricating).z)
	return clampf(1.0 - fab_left / total, 0.0, 1.0) if total > 0.0 else 1.0


## "" se dá pra fabricar agora; senão o motivo.
func part_block_reason(id: String) -> String:
	if installed[id]:
		return "instalada"
	if fabricating == id:
		return "fabricando"
	if fabricating != "":
		return "canteiro ocupado"
	if id != "estrutura" and not installed.estrutura:
		return "precisa da Estrutura"
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < part_stage(id):
		return "requer vila nível %d" % part_stage(id)
	var cost := part_cost(id)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return "sem recursos"
	var missing: String = eco.missing_text(cost.x, cost.y)
	if missing != "":
		return missing
	return ""


# ------------------------------------------------------------ ações
## Paga e começa a fabricar a peça.
func start_part(id: String) -> bool:
	if part_block_reason(id) != "":
		Audio.error()
		return false
	var cost := part_cost(id)
	if not get_tree().get_first_node_in_group("economy").spend(cost.x, cost.y):
		return false
	fabricating = id
	fab_left = float(cost.z)
	_sound_timer = 0.0
	_update_visual()
	_popup("Fabricando: %s" % PART_NAMES[id], Color(1.0, 0.8, 0.45))
	part_started.emit(id)
	return true


func _install(id: String) -> void:
	installed[id] = true
	fabricating = ""
	fab_left = 0.0
	_update_visual()
	var layer: Sprite2D = _layers[id]
	layer.scale = Vector2(2.15, 1.85)
	create_tween().tween_property(layer, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_dust.restart()
	Audio.forge(global_position + Vector2(0, -90))
	_popup("%s instalada!" % PART_NAMES[id], Color(0.55, 1.0, 0.5))
	part_installed.emit(id)
	if installed_count() == PART_IDS.size():
		_complete()


func _complete() -> void:
	complete = true
	if built_reactors.is_empty():
		built_reactors = ["vapor"]
		reactor = "vapor"
	_update_visual()
	Audio.fanfare()
	_popup("ESCAVADEIRA PRONTA!", Color(1.0, 0.85, 0.35))
	completed.emit()


# ------------------------------------------------------------ visual
func _update_visual() -> void:
	for id in PART_IDS:
		var layer: Sprite2D = _layers[id]
		layer.modulate = Color.WHITE if installed[id] else GHOST_COLOR
	_layers.cabine.frame = 1 if complete else 0  # janelas acesas + giroflex
	_sparks.emitting = fabricating != ""
	_work_light.enabled = fabricating != ""
	_beacon.enabled = complete
	_cab_light.enabled = complete
	_update_label()


func _update_label() -> void:
	if complete:
		_label.text = "Escavadeira — %s\n%s" % [REACTOR_NAMES.get(reactor, "?"), drill_status()]
		_label.modulate = Color(1.0, 0.85, 0.4) if reactor_active() else Color(1.0, 0.55, 0.45)
	elif fabricating != "":
		_label.text = "Escavadeira  %d/5\n%s  %d%%" % [installed_count(), PART_NAMES[fabricating], roundi(fab_progress() * 100.0)]
		_label.modulate = Color(1.0, 0.8, 0.5)
	else:
		_label.text = "Escavadeira\n%d/5 peças" % installed_count()
		_label.modulate = Color(0.85, 0.85, 0.9)


func _popup(text: String, color: Color) -> void:
	var stacked := get_children().filter(func(c): return c.has_meta("popup")).size()
	var popup := Label.new()
	popup.set_meta("popup", true)
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", 14)
	popup.position = Vector2(-100, -240 - stacked * 20)
	popup.size = Vector2(200, 20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 1.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(1.0)
	tween.chain().tween_callback(popup.queue_free)


# ------------------------------------------------------------ reatores / perfuração
func reactor_active() -> bool:
	return complete and drill_on and reactor != "" and outage_left <= 0.0 and not no_fuel


func reactor_rate(id: String = reactor) -> float:
	var i := REACTOR_IDS.find(id)
	return reactor_rates[i] if i >= 0 else 0.0


func reactor_cost(id: String) -> Vector3i:
	return reactor_costs[REACTOR_IDS.find(id)]


## "ligada • 0.3 minério/s" / "SEM CARVÃO" / "PANE! 45s" / "desligada"
func drill_status() -> String:
	if not drill_on:
		return "desligada"
	if outage_left > 0.0:
		return "PANE! volta em %ds" % ceili(outage_left)
	if no_fuel:
		return "SEM CARVÃO"
	return "perfurando  %.2f minério/s" % reactor_rate()


## Multiplicador da chance de achado (reator Cristal).
func find_mult() -> float:
	return cristal_find_mult if reactor_active() and reactor == "cristal" else 1.0


## Multiplicador da chance de acidente na mina (reator Solar).
func accident_mult() -> float:
	return solar_accident_mult if reactor_active() and reactor == "solar" else 1.0


## Ânimo a menos pra vila (reator Diesel).
func noise_penalty() -> float:
	return diesel_noise if reactor_active() and reactor == "diesel" else 0.0


## "" = pode construir; "instalado" / "construído"; senão o que falta.
func reactor_block_reason(id: String) -> String:
	if not complete:
		return "escavadeira não está pronta"
	if id == reactor:
		return "instalado"
	if built_reactors.has(id):
		return "construído"
	var finds := get_tree().get_first_node_in_group("finds")
	if REACTOR_ITEM.has(id) and (finds == null or not finds.has_item(REACTOR_ITEM[id])):
		return "precisa achar: %s" % finds.ITEM_NAMES[REACTOR_ITEM[id]] if finds else "precisa de um achado"
	var cost := reactor_cost(id)
	var parts: Array[String] = []
	if finds and finds.rare_parts < cost.z:
		parts.append("%d peças raras" % (cost.z - finds.rare_parts))
	var eco := get_tree().get_first_node_in_group("economy")
	if eco:
		var m: String = eco.missing_text(cost.x, cost.y, "ferro")
		if m != "":
			parts.append(m.trim_prefix("falta "))
	return "falta " + ", ".join(parts) if not parts.is_empty() else ""


## Constrói (paga) e já instala.
func build_reactor(id: String) -> bool:
	if reactor_block_reason(id) != "":
		Audio.error()
		return false
	var cost := reactor_cost(id)
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(cost.x, cost.y, "ferro"):
		return false
	get_tree().get_first_node_in_group("finds").spend_parts(cost.z)
	built_reactors.append(id)
	_popup("Reator novo: %s!" % REACTOR_NAMES[id], Color(0.55, 1.0, 0.5))
	return install_reactor(id)


## Troca pro reator (já construído).
func install_reactor(id: String) -> bool:
	if not built_reactors.has(id) or outage_left > 0.0:
		Audio.error()
		return false
	reactor = id
	no_fuel = false
	_fusao_timer = 0.0
	_dust.restart()
	Audio.forge(global_position + Vector2(0, -90))
	_update_label()
	return true


func toggle_drill() -> void:
	drill_on = not drill_on
	_update_label()


func _drill(delta: float) -> void:
	if outage_left > 0.0:
		outage_left = maxf(outage_left - delta, 0.0)
		return
	if not drill_on or reactor == "":
		return
	if reactor == "vapor":
		if no_fuel:
			_fuel_retry -= delta
			if _fuel_retry > 0.0:
				return
			_fuel_retry = 2.0
			no_fuel = not _take_coal(1.0)
			if no_fuel:
				return
		_fuel_accum += vapor_coal_per_sec * delta
		while _fuel_accum >= 1.0:
			_fuel_accum -= 1.0
			if not _take_coal(1.0):
				no_fuel = true
				_fuel_retry = 2.0
				return
	_drill_accum += reactor_rate() * delta
	while _drill_accum >= 1.0:
		_drill_accum -= 1.0
		_deliver_ore(_pick_ore())
	if reactor == "fusao":
		_fusao_timer += delta
		if _fusao_timer >= fusao_check_interval:
			_fusao_timer = 0.0
			if randf() < fusao_meltdown_chance:
				meltdown()


func _take_coal(amount: float) -> bool:
	var need := amount
	for a in get_tree().get_nodes_in_group("armazens"):
		if a.stock.get("carvao", 0.0) >= need:
			a.take(need, "carvao")
			return true
	return false


func _pick_ore() -> String:
	var mix: Dictionary = REACTOR_MIX.get(reactor, {"ferro": 1.0})
	var r := randf()
	for t in mix:
		r -= mix[t]
		if r <= 0.0:
			return t
	return "ferro"


func _deliver_ore(t: String) -> void:
	var best: Node2D = null
	var best_d := INF
	for a in get_tree().get_nodes_in_group("armazens"):
		var d := global_position.distance_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	if best:
		best.add_ore(1.0, t)


## Pane do reator de fusão: explode, desliga e machuca (grave) quem estiver perto.
func meltdown() -> void:
	outage_left = fusao_outage
	_dust.restart()
	_sparks.restart()
	Audio.boom(global_position)
	var hurt_n := 0
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.global_position.distance_to(global_position + Vector2(0, -20)) <= fusao_blast_radius and not w.injured:
			w.hurt("explosao", "grave")
			hurt_n += 1
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("PANE NO REATOR DE FUSÃO!",
			"A escavadeira explodiu e ficou %ds desligada. %s" % [roundi(fusao_outage),
				"%d ipezinho%s se machucou feio." % [hurt_n, "s" if hurt_n > 1 else ""] if hurt_n > 0 else "Ninguém estava perto, ufa."])
	_update_label()


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {
		"installed": installed.duplicate(), "fabricating": fabricating, "fab_left": fab_left,
		"reactor": reactor, "built_reactors": built_reactors.duplicate(), "drill_on": drill_on,
		"outage_left": outage_left,
	}


## Carregar uma escavadeira pronta NÃO repete a fanfarra nem o banner de conquista.
func load_save_data(d: Dictionary) -> void:
	var saved := SaveUtil.dict(d, "installed")
	for id in PART_IDS:
		installed[id] = SaveUtil.boolean(saved, id, false)
	fabricating = SaveUtil.text(d, "fabricating", "")
	if fabricating not in PART_IDS or installed[fabricating]:
		fabricating = ""
	fab_left = maxf(SaveUtil.num(d, "fab_left", 0.0), 0.0) if fabricating != "" else 0.0
	complete = installed_count() == PART_IDS.size()
	built_reactors = []
	for id in SaveUtil.array(d, "built_reactors"):
		if id is String and id in REACTOR_IDS and not built_reactors.has(id):
			built_reactors.append(id)
	if complete and built_reactors.is_empty():
		built_reactors = ["vapor"]  # save de antes dos reatores: vem a caldeira
	var r := SaveUtil.text(d, "reactor", "vapor" if complete else "")
	reactor = r if built_reactors.has(r) else ("vapor" if complete else "")
	drill_on = SaveUtil.boolean(d, "drill_on", true)
	outage_left = clampf(SaveUtil.num(d, "outage_left", 0.0), 0.0, fusao_outage)
	no_fuel = false
	_update_visual()
