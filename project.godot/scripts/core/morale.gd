extends Node
## Ânimo da vila (nó Morale, grupo "morale"): greve, expulsão, festa, luto e taverna.
##
## Cada ipezinho tem a própria FELICIDADE (0-100, ipezinho.gd), que anda devagar em
## direção a um alvo: as condições dele (cama, fome, zanga, machucado) + as da vila,
## que vêm daqui (village_factors: luto, estágio da vila, taverna, festa).
##
## Regras da vila:
##   - Ânimo médio abaixo de strike_below por strike_grace segundos -> GREVE: ninguém
##     trabalha (só comem, dormem, se tratam e vão à taverna). Acaba quando a média
##     volta a strike_end_at.
##   - Greve que passa de strike_ultimatum segundos -> os ipezinhos EXPULSAM o jogador
##     (derrota: tela de fim de jogo; o save não é sobrescrito).
##   - Festa: créditos + comida do comedouro, +festa_boost na hora e +festa_bonus no
##     alvo por festa_duration. Uma por dia.
##   - Luto: cada morte soma grief_per_death no alvo de todos, que some aos poucos.
##   - Taverna: o jogador escolhe onde construir (igual às casas) e pode ampliar.

signal strike_started
signal strike_ended
signal expelled

const SaveUtil := preload("res://scripts/core/save_util.gd")
const TAVERNA_SCENE := preload("res://scenes/props/taverna.tscn")
const TAVERNA_TEXTURE := preload("res://assets/game/taverna.png")
const GameOver := preload("res://scripts/ui/game_over.gd")

@export_group("Greve")
## Abaixo disso a vila avisa que está insatisfeita.
@export var unhappy_warn_below: float = 40.0
## Ânimo médio abaixo disso por strike_grace segundos começa a greve...
@export var strike_below: float = 30.0
@export var strike_grace: float = 60.0
## ...que só acaba quando a média chega aqui.
@export var strike_end_at: float = 45.0
## Segundos de greve até expulsarem o jogador.
@export var strike_ultimatum: float = 300.0
## Faixa de "último aviso" quando faltar isso.
@export var last_warning_at: float = 60.0
## Save carregado no meio da greve: o ultimato nunca volta com menos que isso.
@export var min_ultimatum_on_load: float = 90.0
## Segundos entre as batucadas da greve.
@export var drum_interval: float = 3.2

@export_group("Festa")
@export var festa_credits: int = 150
@export var festa_food: float = 30.0
## Felicidade dada na hora pra todo mundo.
@export var festa_boost: float = 20.0
## E somada no alvo por festa_duration segundos.
@export var festa_bonus: float = 10.0
@export var festa_duration: float = 240.0

@export_group("Luto")
@export var grief_per_death: float = 20.0
@export var grief_max: float = 40.0
## Segundos pra um luto de grief_per_death sumir.
@export var grief_time: float = 300.0

@export_group("Vila")
## Felicidade no alvo de todos por estágio da vila acima do 1.
@export var stage_bonus: float = 3.0

@export_group("Taverna")
## Construir: créditos, madeira. Ampliar (nível 2): créditos, madeira e pedra (ferro).
@export var taverna_credits: int = 120
@export var taverna_wood: int = 40
@export var taverna_up_credits: int = 350
@export var taverna_up_wood: int = 60
@export var taverna_up_ore: int = 40
@export var taverna_up_ore_type: String = "ferro"
## Alvo de felicidade de todos por ter taverna (nível 1 / 2).
@export var taverna_bonus: Array[float] = [5.0, 8.0]

var on_strike := false
## Segundos que faltam do ultimato (só vale em greve).
var strike_left := 0.0
var grief := 0.0
var festa_left := 0.0
var last_festa_day := -1
var is_expelled := false
## Segundos seguidos com a média abaixo de strike_below (contagem pra greve).
var below_time := 0.0
var _warned_unhappy := false
var _last_warned := false
var _drum_timer := 0.0


func _ready() -> void:
	add_to_group("morale")
	_connect_deaths.call_deferred()


func _connect_deaths() -> void:
	var inf := get_tree().get_first_node_in_group("enfermarias")
	if inf:
		inf.patient_died.connect(func(_who: String, _cause: String): add_grief())


# ------------------------------------------------------------ consultas
func workers() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos")


## Felicidade média (-1 sem ipezinhos).
func average() -> float:
	var ws := workers()
	if ws.is_empty():
		return -1.0
	var total := 0.0
	for w in ws:
		total += w.happiness
	return total / ws.size()


static func mood_word(h: float) -> String:
	if h >= 75.0:
		return "felizes"
	if h >= 40.0:
		return "contentes"
	if h >= 25.0:
		return "tristes"
	return "revoltados"


## [texto, valor] que valem pra todo mundo (somados no alvo de cada ipezinho).
func village_factors() -> Array:
	var f: Array = []
	if grief > 0.5:
		f.append(["luto", -grief])
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level > 1:
		f.append(["vila crescendo", stage_bonus * (hub.level - 1)])
	var tav := taverna()
	if tav:
		f.append(["tem taverna", taverna_bonus[clampi(tav.level, 1, taverna_bonus.size()) - 1]])
	if festa_left > 0.0:
		f.append(["festa recente", festa_bonus])
	var dig := get_tree().get_first_node_in_group("escavadeira")
	if dig and dig.has_method("noise_penalty") and dig.noise_penalty() > 0.0:
		f.append(["barulho do motor a diesel", -dig.noise_penalty()])
	var sun := get_tree().get_first_node_in_group("sun")
	if sun and sun.season_index() == 3 and sun.winter_joy != 0.0:
		f.append(["frio do inverno", sun.winter_joy])
	var res := get_tree().get_first_node_in_group("research")
	if res and res.has("radio"):
		f.append(["rádio da vila", res.radio_joy])
	var def := get_tree().get_first_node_in_group("defense")
	if def and def.creatures_inside() > 0:
		f.append(["medo das criaturas na vila", -10.0])
	var robo := get_tree().get_first_node_in_group("robos")
	if robo and robo.state == "active":
		f.append(["robô guarda vigia a vila", robo.guard_bonus])
	return f


func taverna() -> Node:
	return get_tree().get_first_node_in_group("tavernas")


func _economy() -> Node:
	return get_tree().get_first_node_in_group("economy")


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


# ------------------------------------------------------------ tempo
func _process(delta: float) -> void:
	if is_expelled:
		return
	if grief > 0.0:
		grief = maxf(grief - grief_per_death / grief_time * delta, 0.0)
	festa_left = maxf(festa_left - delta, 0.0)
	var avg := average()
	if avg < 0.0:
		return
	if not on_strike:
		if avg < unhappy_warn_below and not _warned_unhappy:
			_warned_unhappy = true
			_toast("Os ipezinhos estão insatisfeitos (ânimo %d). Veja o Bem-estar (B)." % roundi(avg), Color(1.0, 0.7, 0.4))
		elif avg >= unhappy_warn_below + 5.0:
			_warned_unhappy = false
		if avg < strike_below:
			below_time += delta
			if below_time >= strike_grace:
				_start_strike()
		else:
			below_time = 0.0
		return
	# em greve
	if avg >= strike_end_at:
		_end_strike()
		return
	strike_left -= delta
	_drum_timer -= delta
	if _drum_timer <= 0.0:
		_drum_timer = drum_interval
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub:
			Audio.protest(hub.global_position)
	if strike_left <= last_warning_at and not _last_warned:
		_last_warned = true
		var hud := _hud()
		if hud:
			hud.show_banner("ÚLTIMO AVISO", "Se a greve não acabar em %d segundos, os ipezinhos tiram você do comando." % ceili(strike_left))
		Audio.toll()
	if strike_left <= 0.0:
		_expel()


func _start_strike() -> void:
	on_strike = true
	strike_left = strike_ultimatum
	below_time = 0.0
	_last_warned = false
	_drum_timer = 0.0
	var hud := _hud()
	if hud:
		hud.show_banner("GREVE!", "Os ipezinhos cruzaram os braços na praça. Levante o ânimo até %d em %d:%02d ou eles te expulsam.  (B: Bem-estar)" % [
			roundi(strike_end_at), int(strike_ultimatum) / 60, int(strike_ultimatum) % 60])
	_wake_workers()
	strike_started.emit()


func _end_strike() -> void:
	on_strike = false
	strike_left = 0.0
	below_time = 0.0
	var hud := _hud()
	if hud:
		hud.show_banner("GREVE ENCERRADA", "Os ipezinhos voltam ao trabalho. Cuide pra não acontecer de novo.")
	Audio.fanfare()
	_wake_workers()
	strike_ended.emit()


func _expel() -> void:
	is_expelled = true
	on_strike = false
	SaveManager.game_over = true  # não sobrescreve o save com a partida perdida
	var dn := get_tree().get_first_node_in_group("day_night")
	var hub := get_tree().get_first_node_in_group("village_hub")
	var screen: CanvasLayer = GameOver.new()
	get_tree().root.add_child(screen)
	screen.setup({
		"day": dn.day if dn else 1,
		"workers": workers().size(),
		"stage": hub.stage_name() if hub else "",
		"ore": hub.lifetime_ore() if hub else 0.0,
	})
	Audio.toll()
	expelled.emit()


func _wake_workers() -> void:
	for w in workers():
		w.wake_decision()


# ------------------------------------------------------------ luto
func add_grief() -> void:
	grief = minf(grief + grief_per_death, grief_max)


# ------------------------------------------------------------ festa
func total_food() -> float:
	var total := 0.0
	for c in get_tree().get_nodes_in_group("comedouros"):
		total += c.food_stock
	return total


## "" se pode dar festa agora; senão o motivo.
func festa_block_reason() -> String:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn and dn.day == last_festa_day:
		return "já teve festa hoje"
	var parts: Array[String] = []
	var eco := _economy()
	if eco and eco.credits < festa_credits:
		parts.append("%d cr" % ceili(festa_credits - eco.credits))
	if total_food() < festa_food:
		parts.append("%d comida" % ceili(festa_food - total_food()))
	return "falta " + " + ".join(parts) if not parts.is_empty() else ""


func throw_festa() -> bool:
	if festa_block_reason() != "":
		Audio.error()
		return false
	var eco := _economy()
	if not eco.spend(festa_credits, 0):
		return false
	var left := festa_food
	for c in get_tree().get_nodes_in_group("comedouros"):
		var take := minf(left, c.food_stock)
		c.food_stock -= take
		c._update_visual()
		left -= take
		if left <= 0.0:
			break
	var dn := get_tree().get_first_node_in_group("day_night")
	last_festa_day = dn.day if dn else 1
	festa_left = festa_duration
	for w in workers():
		w.cheer(festa_boost)
	var hud := _hud()
	if hud:
		hud.show_banner("FESTA NA VILA!", "+%d de ânimo pra todo mundo agora, e mais alegria pelos próximos %d minutos." % [
			roundi(festa_boost), roundi(festa_duration / 60.0)])
	Audio.fanfare()
	return true


# ------------------------------------------------------------ taverna
## "" se dá pra construir/ampliar; senão o motivo.
func taverna_block_reason() -> String:
	var eco := _economy()
	if eco == null:
		return "sem recursos"
	var tav := taverna()
	if tav == null:
		return eco.missing_text(taverna_credits, 0, "", taverna_wood)
	if tav.level >= tav.max_level():
		return "nível máximo"
	return eco.missing_text(taverna_up_credits, taverna_up_ore, taverna_up_ore_type, taverna_up_wood, "pedra (%s)" % taverna_up_ore_type)


## Construir (abre o modo de escolher lugar) ou ampliar.
func build_or_upgrade_taverna() -> bool:
	if taverna_block_reason() != "":
		Audio.error()
		return false
	var tav := taverna()
	if tav:
		if not _economy().spend(taverna_up_credits, taverna_up_ore, taverna_up_ore_type, taverna_up_wood):
			return false
		tav.level += 1
		tav.refresh_seats()
		tav.pop_in()
		Audio.recruit()
		_toast("Taverna ampliada: %d lugares, diversão mais rápida." % tav.slot_count, Color(0.55, 1.0, 0.5))
		return true
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_taverna, TAVERNA_TEXTURE, 2, "a taverna")
	return true


## HousePlacer chama quando o jogador clica num lugar válido. Só aqui a taverna é paga.
func _confirm_taverna(pos: Vector2) -> bool:
	if taverna() != null or taverna_block_reason() != "":
		Audio.error()
		return false
	if not _economy().spend(taverna_credits, 0, "", taverna_wood):
		return false
	var tav := spawn_taverna(pos, 1)
	tav.pop_in()
	Audio.recruit()
	_toast("Taverna construída! Quem estiver triste vai lá se animar.", Color(0.55, 1.0, 0.5))
	return true


func spawn_taverna(pos: Vector2, lvl: int) -> Node2D:
	var tav: Node2D = TAVERNA_SCENE.instantiate()
	tav.name = "Taverna"
	tav.position = pos
	tav.level = lvl
	var world := get_tree().get_first_node_in_group("village_hub").get_parent()
	world.add_child(tav)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return tav


func _toast(text: String, color: Color) -> void:
	var hud := _hud()
	if hud:
		hud.show_toast(text, color)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var d := {
		"on_strike": on_strike,
		"strike_left": strike_left,
		"below_time": below_time,
		"grief": grief,
		"festa_left": festa_left,
		"last_festa_day": last_festa_day,
	}
	var tav := taverna()
	if tav:
		d["taverna"] = tav.get_save_data()
	return d


func load_save_data(d: Dictionary) -> void:
	on_strike = SaveUtil.boolean(d, "on_strike", false)
	strike_left = maxf(SaveUtil.num(d, "strike_left", strike_ultimatum), min_ultimatum_on_load) if on_strike else 0.0
	below_time = clampf(SaveUtil.num(d, "below_time", 0.0), 0.0, strike_grace)
	grief = clampf(SaveUtil.num(d, "grief", 0.0), 0.0, grief_max)
	festa_left = clampf(SaveUtil.num(d, "festa_left", 0.0), 0.0, festa_duration)
	last_festa_day = SaveUtil.integer(d, "last_festa_day", -1)
	_last_warned = false
	var td := SaveUtil.dict(d, "taverna")
	if not td.is_empty() and taverna() == null:
		var pos := SaveUtil.vec2(td, "position", Vector2.INF)
		if pos != Vector2.INF:
			spawn_taverna(pos, clampi(SaveUtil.integer(td, "level", 1), 1, 2))
