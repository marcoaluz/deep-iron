extends Node
## O Sol (nó Sun, grupo "sun"): ESTAÇÕES do ano, ONDAS SOLARES e o ESCUDO (vitória).
##
## Estações: days_per_season dias cada (Primavera, Verão, Outono, Inverno). Mudam o
## tamanho do dia/noite, a fome, a horta e a chance de onda solar.
## Ondas solares: só de dia. Quem está exposto no nível da mina/clareira (fora de casa)
## acumula radiação e se machuca; os ipezinhos correm pros abrigos, e quem está no
## nível 2 ou no abismo segue trabalhando (a rocha protege). A cada dia as ondas ficam
## mais fortes. Com a pesquisa "Estudo da explosão solar" a vila recebe a previsão do dia
## e o aviso chega bem antes.
## Escudo: projeto final (pesquisa "Projeto do escudo solar"), em 4 etapas no gerador
## (escudo.gd). Pronto: as ondas acabam e é VITÓRIA (dá pra continuar jogando).

signal wave_started(intensity: float)
signal wave_ended
signal season_changed(index: int)
signal victory

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ESCUDO_SCENE := preload("res://scenes/props/escudo.tscn")
const ESCUDO_TEXTURE := preload("res://assets/game/escudo.png")
const VictoryScreen := preload("res://scripts/ui/victory.gd")
const SEASONS := ["Primavera", "Verão", "Outono", "Inverno"]
const SEASON_NOTES := [
	"a horta cresce mais rápido",
	"dias longos e o sol no pico: mais ondas solares",
	"a horta desacelera",
	"dias curtos, frio (mais fome) e a horta quase para",
]

@export_group("Estações (índice 0 = Primavera)")
@export var days_per_season: int = 4
## Mexe na duração do dia/noite conforme a estação (desligue pra testar com dia fixo).
@export var adjust_day_length: bool = true
@export var season_day_mult: Array[float] = [1.0, 1.2, 1.0, 0.8]
@export var season_night_mult: Array[float] = [1.0, 0.8, 1.0, 1.25]
@export var season_wave_chance: Array[float] = [0.3, 0.6, 0.3, 0.15]
@export var season_hunger_mult: Array[float] = [1.0, 1.0, 1.0, 1.25]
@export var season_garden_mult: Array[float] = [1.3, 1.0, 0.8, 0.5]
## Ânimo no inverno (frio).
@export var winter_joy: float = -3.0

@export_group("Ondas solares")
@export var first_wave_day: int = 2
@export var wave_duration: float = 35.0
## Intensidade cresce isso por dia (o sol está piorando).
@export var wave_growth: float = 0.08
## Aviso antes da onda: com o Estudo da explosão solar / sem.
@export var warn_time_studied: float = 60.0
@export var warn_time_blind: float = 10.0
## Radiação por segundo exposto (x intensidade) e quanto acumula até machucar.
@export var rad_per_sec: float = 1.0
@export var rad_hurt_at: float = 10.0
@export_range(0.0, 1.0) var rad_grave_chance: float = 0.25
## Fração da comida da horta que murcha em cada onda.
@export_range(0.0, 1.0) var garden_wilt: float = 0.3

@export_group("Escudo")
## Estágio mínimo da vila pra começar o gerador.
@export var shield_min_stage: int = 4

var wave_today: bool = false
## Quando a onda chega (segundos desde o amanhecer).
var wave_at: float = 0.0
var wave_left: float = 0.0
var wave_intensity: float = 1.0
var warned: bool = false
var won: bool = false
var _base_day: float = -1.0
var _base_night: float = -1.0
var _last_season: int = -1


func _ready() -> void:
	add_to_group("sun")
	_connect_cycle.call_deferred()


func _connect_cycle() -> void:
	var dn := _dn()
	if dn:
		dn.day_started.connect(_on_day_started)
		_base_day = dn.day_duration
		_base_night = dn.night_duration
		_last_season = season_index()


func _dn() -> Node:
	return get_tree().get_first_node_in_group("day_night")


# ------------------------------------------------------------ estações
func season_index(day: int = -1) -> int:
	if day < 0:
		var dn := _dn()
		day = dn.day if dn else 1
	return ((day - 1) / maxi(days_per_season, 1)) % 4


func season_name() -> String:
	return SEASONS[season_index()]


func day_in_season() -> int:
	var dn := _dn()
	return ((dn.day if dn else 1) - 1) % maxi(days_per_season, 1) + 1


func hunger_mult() -> float:
	return season_hunger_mult[season_index()]


func garden_mult() -> float:
	return season_garden_mult[season_index()]


func _apply_day_length() -> void:
	var dn := _dn()
	if dn == null or not adjust_day_length or _base_day <= 0.0:
		return
	var s := season_index()
	dn.day_duration = _base_day * season_day_mult[s]
	dn.night_duration = _base_night * season_night_mult[s]


func _on_day_started(day: int) -> void:
	_apply_day_length()
	var s := season_index(day)
	if s != _last_season:
		_last_season = s
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("Começou o %s: %s." % [SEASONS[s], SEASON_NOTES[s]], Color(0.8, 0.9, 1.0))
		season_changed.emit(s)
	_plan_wave(day)


# ------------------------------------------------------------ ondas solares
func studied() -> bool:
	var res := get_tree().get_first_node_in_group("research")
	return res != null and res.has("estudo_solar")


func _plan_wave(day: int) -> void:
	warned = false
	wave_today = false
	if won or day < first_wave_day:
		return
	if randf() < season_wave_chance[season_index(day)]:
		var dn := _dn()
		wave_today = true
		wave_at = randf_range(0.25, 0.7) * (dn.day_duration if dn else 180.0)
		wave_intensity = 1.0 + wave_growth * (day - 1)


func wave_active() -> bool:
	return wave_left > 0.0


## Hora de ir pro abrigo: a onda chegou ou já tocou o alarme dela.
## (Com o Estudo da explosão solar o alarme toca 60 s antes; sem, só 10 s.)
func shelter_now() -> bool:
	return wave_active() or (warned and time_to_wave() >= 0.0)


## Segundos até a onda de hoje (-1 = não tem / já passou).
func time_to_wave() -> float:
	var dn := _dn()
	if not wave_today or dn == null or dn.is_night() or wave_active():
		return -1.0
	return maxf(wave_at - dn.time, 0.0)


func warn_time() -> float:
	return warn_time_studied if studied() else warn_time_blind


## Texto da previsão pro HUD/janela.
func forecast_text() -> String:
	if won:
		return "O escudo protege a vila: não há mais ondas solares."
	if wave_active():
		return "ONDA SOLAR! abriguem-se — %ds" % ceili(wave_left)
	var t := time_to_wave()
	if t >= 0.0 and (warned or studied()):
		return "Onda solar hoje: em %d:%02d" % [int(t) / 60, int(t) % 60]
	if not studied():
		return "Sem previsão das ondas (pesquise o Estudo da explosão solar)"
	return "Céu calmo hoje"


func _process(delta: float) -> void:
	if won:
		return
	if wave_active():
		wave_left -= delta
		_expose(delta)
		if wave_left <= 0.0:
			_end_wave()
		return
	var t := time_to_wave()
	if t < 0.0:
		return
	if not warned and t <= warn_time():
		warned = true
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_banner("ONDA SOLAR CHEGANDO",
				"Em %d segundos o sol castiga a superfície. Todo mundo pros abrigos; no nível 2 e no abismo a rocha protege." % ceili(t))
		Audio.alarm()
		for w in get_tree().get_nodes_in_group("ipezinhos"):
			w.wake_decision()  # já vão pros abrigos
	if t <= 0.0:
		_start_wave()


func _start_wave() -> void:
	wave_today = false
	wave_left = wave_duration
	for h in get_tree().get_nodes_in_group("coleta_comida"):
		h.food_remaining *= 1.0 - garden_wilt
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("ONDA SOLAR! (força %.1fx) A horta murchou um pouco." % wave_intensity, Color(1.0, 0.6, 0.3))
	Audio.solar()
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.wake_decision()
	wave_started.emit(wave_intensity)


func _end_wave() -> void:
	wave_left = 0.0
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("A onda solar passou. De volta ao trabalho.", Color(0.8, 0.9, 1.0))
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.wake_decision()
	wave_ended.emit()


func _expose(delta: float) -> void:
	var env := get_tree().get_first_node_in_group("environment")
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.get("_inside") or w.get("injured"):
			continue
		if env and env.level_at(w.global_position) != 0:
			continue
		w.radiate(rad_per_sec * wave_intensity * delta)


# ------------------------------------------------------------ escudo / vitória
func shield() -> Node:
	return get_tree().get_first_node_in_group("escudos")


func shield_block_reason() -> String:
	if shield() != null:
		return "construído"
	var res := get_tree().get_first_node_in_group("research")
	if res == null or not res.has("escudo"):
		return "precisa pesquisar: Projeto do escudo solar"
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < shield_min_stage:
		return "requer vila nível %d" % shield_min_stage
	return ""


## Escolher o lugar do gerador (a obra em si é paga por etapa, no gerador).
func place_shield() -> bool:
	if shield_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_shield, ESCUDO_TEXTURE, 5, "o gerador do escudo")
	return true


func _confirm_shield(pos: Vector2) -> bool:
	if shield_block_reason() != "":
		Audio.error()
		return false
	var s := spawn_shield(pos)
	s.pop_in()
	Audio.forge(pos)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Lote do gerador marcado. Construa as 4 etapas na janela do Sol (Y).", Color(0.55, 1.0, 0.5))
	return true


func spawn_shield(pos: Vector2) -> Node2D:
	var s: Node2D = ESCUDO_SCENE.instantiate()
	s.name = "Escudo"
	s.position = pos
	get_tree().get_first_node_in_group("village_hub").get_parent().add_child(s)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return s


## O gerador chama quando a última etapa fica pronta.
func win() -> void:
	if won:
		return
	won = true
	wave_today = false
	wave_left = 0.0
	Audio.fanfare()
	var dn := _dn()
	var screen: CanvasLayer = VictoryScreen.new()
	get_tree().root.add_child(screen)
	screen.setup({
		"day": dn.day if dn else 1,
		"workers": get_tree().get_nodes_in_group("ipezinhos").size(),
		"season": season_name(),
	})
	victory.emit()


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var d := {
		"wave_today": wave_today, "wave_at": wave_at, "wave_left": wave_left,
		"wave_intensity": wave_intensity, "warned": warned, "won": won,
	}
	var s := shield()
	if s:
		d["shield"] = s.get_save_data()
	return d


func load_save_data(d: Dictionary) -> void:
	wave_today = SaveUtil.boolean(d, "wave_today", false)
	wave_at = maxf(SaveUtil.num(d, "wave_at", 0.0), 0.0)
	wave_left = clampf(SaveUtil.num(d, "wave_left", 0.0), 0.0, wave_duration)
	wave_intensity = maxf(SaveUtil.num(d, "wave_intensity", 1.0), 1.0)
	warned = SaveUtil.boolean(d, "warned", false)
	won = SaveUtil.boolean(d, "won", false)
	_last_season = season_index()
	_apply_day_length()
	var sd := SaveUtil.dict(d, "shield")
	if not sd.is_empty() and shield() == null:
		var pos := SaveUtil.vec2(sd, "position", Vector2.INF)
		if pos != Vector2.INF:
			var s := spawn_shield(pos)
			s.load_save_data(sd)
