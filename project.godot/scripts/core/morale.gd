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
##   - Parque (Bloco 41): lazer PASSIVO. Quem está ao ar livre a até park_radius de um
##     parque ganha park_rate de ânimo por segundo, até park_cap (o teto de 100 vale
##     sempre). Vários parques não somam. Posicionado como as casas (raio do Centro da
##     Vila) — é pra quem mora perto. Pode ter mais de um; um canteiro por vez.

signal strike_started
signal strike_ended
signal expelled

const SaveUtil := preload("res://scripts/core/save_util.gd")
const TAVERNA_SCENE := preload("res://scenes/props/taverna.tscn")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const TAVERNA_TEXTURE := preload("res://assets/game/taverna.png")
const PARQUE_SCENE := preload("res://scenes/props/parque.tscn")
const PARQUE_TEXTURE := preload("res://assets/game/parque.png")
const PARQUE_FOOTPRINT := Rect2(-50, -72, 100, 80)
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

@export_group("Funeral (Bloco 93)")
## Ânimo a mais pra vila toda depois de um funeral digno (pesquisa "Ritos fúnebres"), e por quantos segundos.
@export var funeral_bonus: float = 5.0
@export var funeral_bonus_tempo: float = 240.0

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
## Bloco 31b: segundos de engenheiro pra erguer / ampliar a taverna.
@export var taverna_build_time: float = 45.0
@export var taverna_up_build_time: float = 40.0
## Alvo de felicidade de todos por ter taverna (nível 1 / 2).
@export var taverna_bonus: Array[float] = [5.0, 8.0]

@export_group("Parque (Bloco 41)")
## Construir: créditos, minério (tipo abaixo) e madeira; segundos de engenheiro.
@export var park_credits: int = 100
@export var park_ore: int = 20
@export var park_ore_type: String = "ferro"
@export var park_wood: int = 40
@export var park_build_time: float = 30.0
## Até onde o parque alegra (px do mundo, a partir do parque).
@export var park_radius: float = 120.0
## Ânimo ganho por segundo por quem está no raio (ao ar livre).
@export var park_rate: float = 0.5
## O parque só leva o ânimo até aqui (o teto geral é 100).
@export_range(0.0, 100.0) var park_cap: float = 100.0

var on_strike := false
## Segundos que faltam do ultimato (só vale em greve).
var strike_left := 0.0
var grief := 0.0
var festa_left := 0.0
var funeral_left := 0.0  # Bloco 93: o "funeral digno" ainda vale por estes segundos
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
	# Bloco 47: com várias tavernas o bônus NÃO soma — vale o da melhor (mais tavernas = mais
	# lugares e mais perto, não mais ânimo de graça)
	var best_lvl := 0
	for tav in tavernas():
		best_lvl = maxi(best_lvl, tav.level)
	if best_lvl > 0:
		f.append(["tem taverna", taverna_bonus[clampi(best_lvl, 1, taverna_bonus.size()) - 1]])
	if festa_left > 0.0:
		f.append(["festa recente", festa_bonus])
	if funeral_left > 0.0:
		f.append(["funeral digno", funeral_bonus])
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


## Bloco 47: todas as tavernas (cada uma com os seus lugares; o triste vai na mais perto livre).
func tavernas() -> Array:
	return get_tree().get_nodes_in_group("tavernas")


## A que "Ampliar" melhora: a primeira que ainda não está no nível máximo (ou null).
func taverna_to_upgrade() -> Node:
	for tav in tavernas():
		if tav.level < tav.max_level():
			return tav
	return null


## Custo da PRÓXIMA taverna (x cr, z madeira): cresce a cada uma que já existe.
func taverna_cost() -> Vector3i:
	var base := Vector3i(taverna_credits, 0, taverna_wood)
	var eco := _economy()
	return eco.scaled_cost(base, tavernas().size()) if eco else base


func taverna_cost_text() -> String:
	var c := taverna_cost()
	return "%d cr + %d madeira" % [c.x, c.z]


func taverna_up_cost_text() -> String:
	return "%d cr + %d madeira + %d %s" % [taverna_up_credits, taverna_up_wood, taverna_up_ore, taverna_up_ore_type]


func _economy() -> Node:
	return get_tree().get_first_node_in_group("economy")


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


# ------------------------------------------------------------ tempo
func _process(delta: float) -> void:
	if is_expelled:
		return
	_park_tick(delta)
	if grief > 0.0:
		grief = maxf(grief - grief_per_death / grief_time * delta, 0.0)
	festa_left = maxf(festa_left - delta, 0.0)
	funeral_left = maxf(funeral_left - delta, 0.0)
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


## Bloco 88: a festa é o FESTIVAL do domingo à tarde (calendario.gd chama). mult: o festival do dia de festa
## da estação anima mais; titulo: o nome dele.
func throw_festa(mult: float = 1.0, titulo: String = "") -> bool:
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
		w.cheer(festa_boost * mult)
	var hud := _hud()
	if hud:
		hud.show_banner(("%s!" % titulo.to_upper()) if titulo != "" and titulo != "Festival" else "FESTIVAL NA VILA!",
			"+%d de ânimo pra todo mundo agora, todos na praça, e mais alegria pelos próximos %d minutos." % [
			roundi(festa_boost * mult), roundi(festa_duration / 60.0)])
	Audio.party()  # Bloco 55
	return true


# ------------------------------------------------------------ parque (Bloco 41)
func parks() -> Array:
	return get_tree().get_nodes_in_group("parques")


## Quem está ao ar livre perto de algum parque ganha ânimo (uma vez só, mesmo com vários).
func _park_tick(delta: float) -> void:
	var list := parks()
	if list.is_empty() or park_rate <= 0.0:
		return
	var amount := park_rate * delta
	for w in workers():
		if w.get("_inside") or w.get("downed"):
			continue
		for p in list:
			if w.global_position.distance_to(p.global_position) <= park_radius:
				w.enjoy_park(amount, minf(park_cap, 100.0))
				break


func park_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "parque")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	return eco.missing_text(park_credits, park_ore, park_ore_type, park_wood) if eco else "sem recursos"


## Escolher o lugar (no raio das casas, em volta do Centro da Vila); paga ao confirmar.
func build_park() -> bool:
	if park_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	var opts := {"footprint": PARQUE_FOOTPRINT}
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.has_method("house_radius") and hub.house_radius() > 0.0:
		opts["radius"] = hub.house_radius()
		opts["radius_center"] = hub.global_position
	placer.begin(_confirm_park, PARQUE_TEXTURE, 1, "o parque", opts)
	return true


func _confirm_park(pos: Vector2) -> bool:
	if park_block_reason() != "":
		Audio.error()
		return false
	if not _economy().spend(park_credits, park_ore, park_ore_type, park_wood):
		return false
	Canteiro.order(get_tree(), "parque", pos, park_build_time)
	Audio.click()
	_toast("Parque encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_park(pos: Vector2) -> Node2D:
	var p: Node2D = PARQUE_SCENE.instantiate()
	var n := 1
	var world := get_tree().get_first_node_in_group("village_hub").get_parent()
	while world.has_node("Parque%d" % n):
		n += 1
	p.name = "Parque%d" % n
	p.position = pos
	world.add_child(p)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return p


# ------------------------------------------------------------ taverna
## Bloco 47: construir OUTRA taverna e AMPLIAR uma que existe são coisas separadas.
## "" se dá pra construir uma taverna nova; senão o motivo.
func taverna_build_reason() -> String:
	var eco := _economy()
	if eco == null:
		return "sem recursos"
	var c := Canteiro.pending(get_tree(), "taverna")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var cost := taverna_cost()
	return eco.missing_text(cost.x, 0, "", cost.z)


## "" se dá pra ampliar (a primeira taverna abaixo do máximo); senão o motivo.
func taverna_upgrade_reason() -> String:
	var eco := _economy()
	if eco == null:
		return "sem recursos"
	if tavernas().is_empty():
		return "sem taverna"
	var c := Canteiro.pending(get_tree(), "taverna_up")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	if taverna_to_upgrade() == null:
		return "nível máximo"
	return eco.missing_text(taverna_up_credits, taverna_up_ore, taverna_up_ore_type, taverna_up_wood, "pedra (%s)" % taverna_up_ore_type)


## (compatível com antes) o motivo do que build_or_upgrade_taverna faria: construir a
## primeira taverna ou ampliar.
func taverna_block_reason() -> String:
	if tavernas().is_empty():
		var c := Canteiro.pending(get_tree(), "taverna")
		if c:
			return "em obra (%s)" % c._obra.status(c.obra_progress())
		return taverna_build_reason()
	return taverna_upgrade_reason()


## Construir (sem taverna ainda) ou ampliar (já tem) — o botão antigo da janela de Bem-estar.
func build_or_upgrade_taverna() -> bool:
	if tavernas().is_empty():
		return build_taverna()
	return upgrade_taverna()


## Abre o modo de escolher lugar pra uma taverna NOVA (pode ter várias).
func build_taverna() -> bool:
	if taverna_build_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_taverna, TAVERNA_TEXTURE, 2, "a taverna" if tavernas().is_empty() else "outra taverna")
	return true


## Encomenda a ampliação da primeira taverna que ainda não está no máximo.
func upgrade_taverna() -> bool:
	if taverna_upgrade_reason() != "":
		Audio.error()
		return false
	var tav := taverna_to_upgrade()
	if not _economy().spend(taverna_up_credits, taverna_up_ore, taverna_up_ore_type, taverna_up_wood):
		return false
	Canteiro.order(get_tree(), "taverna_up", tav.global_position, taverna_up_build_time)
	Audio.click()
	_toast("Ampliação da taverna encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


## HousePlacer chama quando o jogador clica num lugar válido. Só aqui a taverna é paga.
func _confirm_taverna(pos: Vector2) -> bool:
	if taverna_build_reason() != "":
		Audio.error()
		return false
	var cost := taverna_cost()
	if not _economy().spend(cost.x, 0, "", cost.z):
		return false
	Canteiro.order(get_tree(), "taverna", pos, taverna_build_time)
	Audio.click()
	_toast("Taverna encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


## Bloco 31b: o canteiro terminou (chamado por canteiro.gd).
func finish_build(kind: String, pos: Vector2) -> void:
	if kind == "parque":  # Bloco 41
		var p := spawn_park(pos)
		p.pop_in()
		Audio.recruit()
		_toast("Parque pronto! Quem passa perto fica mais animado.", Color(0.55, 1.0, 0.5))
		return
	if kind == "taverna":
		var tav := spawn_taverna(pos, 1)
		tav.pop_in()
		Audio.recruit()
		_toast("Taverna construída! Quem estiver triste vai lá se animar.", Color(0.55, 1.0, 0.5))
	elif kind == "taverna_up" and not tavernas().is_empty():
		# Bloco 47: amplia a taverna onde está o canteiro (a mais perto dele)
		var tav: Node2D = null
		for t in tavernas():
			if tav == null or t.global_position.distance_to(pos) < tav.global_position.distance_to(pos):
				tav = t
		tav.level = mini(tav.level + 1, tav.max_level())
		tav.refresh_seats()
		tav.pop_in()
		Audio.recruit()
		_toast("Taverna ampliada: %d lugares, diversão mais rápida." % tav.slot_count, Color(0.55, 1.0, 0.5))


func spawn_taverna(pos: Vector2, lvl: int) -> Node2D:
	var tav: Node2D = TAVERNA_SCENE.instantiate()
	var n := tavernas().size()
	tav.name = "Taverna" if n == 0 else "Taverna%d" % (n + 1)
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
		"funeral_left": funeral_left,
		"last_festa_day": last_festa_day,
	}
	d["tavernas"] = tavernas().map(func(t): return t.get_save_data())  # Bloco 47 (antes: "taverna", uma só)
	var ps := []
	for p in parks():
		ps.append(SaveUtil.vec2_to_array(p.global_position))
	d["parques"] = ps  # Bloco 41
	return d


func load_save_data(d: Dictionary) -> void:
	on_strike = SaveUtil.boolean(d, "on_strike", false)
	strike_left = maxf(SaveUtil.num(d, "strike_left", strike_ultimatum), min_ultimatum_on_load) if on_strike else 0.0
	below_time = clampf(SaveUtil.num(d, "below_time", 0.0), 0.0, strike_grace)
	grief = clampf(SaveUtil.num(d, "grief", 0.0), 0.0, grief_max)
	festa_left = clampf(SaveUtil.num(d, "festa_left", 0.0), 0.0, festa_duration)
	funeral_left = clampf(SaveUtil.num(d, "funeral_left", 0.0), 0.0, funeral_bonus_tempo)
	last_festa_day = SaveUtil.integer(d, "last_festa_day", -1)
	_last_warned = false
	if tavernas().is_empty():
		var list: Array = SaveUtil.array(d, "tavernas")
		if list.is_empty() and not SaveUtil.dict(d, "taverna").is_empty():
			list = [SaveUtil.dict(d, "taverna")]  # Bloco 47: save antigo, uma só
		for td in list:
			if typeof(td) != TYPE_DICTIONARY:
				continue
			var pos := SaveUtil.vec2(td, "position", Vector2.INF)
			if pos != Vector2.INF:
				spawn_taverna(pos, clampi(SaveUtil.integer(td, "level", 1), 1, 2))
	# Bloco 41 (save antigo: sem parque)
	for p in parks():
		p.get_parent().remove_child(p)
		p.queue_free()
	for v in SaveUtil.array(d, "parques"):
		if typeof(v) == TYPE_ARRAY and v.size() >= 2:
			spawn_park(Vector2(float(v[0]), float(v[1])))
