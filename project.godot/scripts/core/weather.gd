extends Node2D
## Bloco 40: CLIMA VISUAL da clareira (grupo "weather"), criado pelo main.gd. 100% visual:
## só LÊ a estação (sun.gd: season_index) e o relógio (day_night.gd) — nenhum número muda.
##
##   Primavera: chuva de vez em quando          Verão: pólen bem de leve
##   Outono: folhas caindo (e às vezes chuva)   Inverno: neve + geada no chão
##
## Só na clareira (a mina é coberta). Cada efeito tem uma intensidade que anda devagar até
## o alvo (fade_speed): troca de estação / começo e fim da chuva sem corte. A chuva é
## sorteada POR DIA com uma semente do próprio dia, então é sempre igual pra aquele dia —
## por isso nada vai pro save: ao carregar, o clima certo aparece na hora (snap).
## Partícula não recebe clique: não atrapalha selecionar ipezinho/prédio nem o HUD.

const LEAF := preload("res://assets/game/weather_leaf.png")
const SNOW := preload("res://assets/game/weather_snow.png")
const RAIN := preload("res://assets/game/weather_rain.png")
const POLLEN := preload("res://assets/game/weather_pollen.png")
const SEASON_AUTUMN := 2
const SEASON_WINTER := 3
const SEASON_SUMMER := 1

@export_group("Transição")
## Quanto a intensidade de cada efeito anda por segundo (0.12 = de 0 a 1 em ~8 s).
@export var fade_speed: float = 0.12

@export_group("Outono: folhas")
@export var leaf_amount: int = 45
@export var leaf_fall_speed: float = 26.0
## Quanto as folhas vão de lado (vento).
@export var leaf_drift: float = 18.0

@export_group("Inverno: neve")
@export var snow_amount: int = 240
@export var snow_fall_speed: float = 38.0
## Geada no chão da clareira (0 = sem).
@export_range(0.0, 1.0) var frost_alpha: float = 0.22

@export_group("Chuva")
@export var rain_amount: int = 260
@export var rain_fall_speed: float = 430.0
## Chance de um dia ter pancada de chuva, por estação (primavera, verão, outono, inverno).
@export var rain_chance: Array[float] = [0.5, 0.1, 0.35, 0.0]
## Duração da pancada (fração do ciclo dia+noite: mínimo, máximo).
@export var rain_duration: Vector2 = Vector2(0.12, 0.3)

@export_group("Verão: pólen")
@export var pollen_amount: int = 18

var _fx: Dictionary = {}  # nome -> {node: CPUParticles2D, level: float}
## Bloco 52/53: chuva forçada (painel de debug F3 e benchmark); não vai no save.
var forcar_chuva := false
var _frost: Polygon2D
var _frost_level := 0.0
var _rect := Rect2()


const Efeitos := preload("res://scripts/core/efeitos.gd")


func _ready() -> void:
	add_to_group("weather")
	add_to_group("efeitos")  # Bloco 54: reduzir efeitos
	z_index = 20  # por cima dos prédios e das árvores (o HUD é outra camada)
	var env := get_tree().get_first_node_in_group("environment")
	_rect = env.clearing_rect if env else Rect2()
	if not _rect.has_area():
		return
	_frost = Polygon2D.new()
	_frost.polygon = PackedVector2Array([_rect.position, Vector2(_rect.end.x, _rect.position.y), _rect.end, Vector2(_rect.position.x, _rect.end.y)])
	_frost.color = Color(0.88, 0.93, 1.0, 0.0)
	_frost.z_as_relative = false
	_frost.z_index = -9  # logo acima do chão (-10), embaixo de tudo que fica em pé
	add_child(_frost)
	_fx["leaves"] = {"node": _make(LEAF, leaf_amount, 5.0, Vector2(0.55, 1.0), 35.0, leaf_fall_speed, Vector2(leaf_drift * 0.2, 5.0),
		_ramp([Color(0.86, 0.46, 0.16), Color(0.72, 0.28, 0.12), Color(0.92, 0.7, 0.24), Color(0.55, 0.36, 0.2)]), 1.6, 2.2, 140.0), "level": 0.0}
	_fx["snow"] = {"node": _make(SNOW, snow_amount, 6.0, Vector2(0.18, 1.0), 20.0, snow_fall_speed, Vector2(0, 2.0),
		_ramp([Color(0.94, 0.97, 1.0), Color(0.85, 0.9, 1.0)]), 1.0, 2.0, 0.0), "level": 0.0}
	_fx["rain"] = {"node": _make(RAIN, rain_amount, 0.8, Vector2(0.12, 1.0), 4.0, rain_fall_speed, Vector2(0, 60.0),
		_ramp([Color(0.7, 0.8, 1.0, 0.75)]), 1.6, 2.2, 0.0), "level": 0.0}
	_fx["pollen"] = {"node": _make(POLLEN, pollen_amount, 6.0, Vector2(0.3, -1.0), 180.0, 7.0, Vector2(0, -3.0),
		_ramp([Color(1.0, 0.95, 0.62)]), 1.5, 2.0, 0.0), "level": 0.0}
	for k in _fx:
		_fx[k].base = _fx[k].node.amount
	efeitos_mudaram()
	SaveManager.loaded.connect(snap)
	snap.call_deferred()


## Bloco 54: "reduzir efeitos" liga/desliga: menos partículas de clima.
func efeitos_mudaram() -> void:
	for k in _fx:
		var n: CPUParticles2D = _fx[k].node
		var want := Efeitos.qtd(int(_fx[k].get("base", n.amount)))
		if n.amount != want:
			n.amount = want


## Cria um emissor cobrindo a clareira inteira; a partícula aparece e some (sem borda seca).
func _make(tex: Texture2D, amount: int, life: float, dir: Vector2, spread: float, vel: float, grav: Vector2,
		colors: Gradient, s_min: float, s_max: float, spin: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = tex
	p.amount = maxi(amount, 1)
	p.lifetime = life
	p.emitting = false
	p.local_coords = false
	p.position = _rect.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = _rect.size * 0.5
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = vel * 0.75
	p.initial_velocity_max = vel * 1.25
	p.gravity = grav
	p.scale_amount_min = s_min
	p.scale_amount_max = s_max
	p.angular_velocity_min = -spin
	p.angular_velocity_max = spin
	p.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	p.color_ramp = fade
	p.modulate.a = 0.0
	add_child(p)
	return p


func _ramp(cols: Array) -> Gradient:
	var g := Gradient.new()
	if cols.size() == 1:
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([cols[0], cols[0]])
		return g
	var offs := PackedFloat32Array()
	var cs := PackedColorArray()
	for i in cols.size():
		offs.append(float(i) / (cols.size() - 1))
		cs.append(cols[i])
	g.offsets = offs
	g.colors = cs
	return g


# ------------------------------------------------------------ o que deveria estar acontecendo
func _season() -> int:
	var sun := get_tree().get_first_node_in_group("sun")
	return sun.season_index() if sun else 0


## Janela da pancada de chuva do dia (fração do ciclo: início, fim); x < 0 = dia seco.
func rain_window(day: int) -> Vector2:
	var sun := get_tree().get_first_node_in_group("sun")
	var s: int = sun.season_index(day) if sun else 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(day * 7919 + 17)
	var chance: float = rain_chance[s] if s < rain_chance.size() else 0.0
	if rng.randf() >= chance:
		return Vector2(-1, -1)
	var start := rng.randf_range(0.05, 0.6)
	return Vector2(start, start + rng.randf_range(rain_duration.x, rain_duration.y))


func is_raining() -> bool:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn == null or _season() == SEASON_WINTER:
		return false
	var w := rain_window(dn.day)
	var f: float = dn.time / dn.cycle_length()
	return w.x >= 0.0 and f >= w.x and f <= w.y


## Alvo de cada efeito agora (0..1).
func targets() -> Dictionary:
	var s := _season()
	var rain := forcar_chuva or is_raining()
	return {
		"leaves": 1.0 if s == SEASON_AUTUMN else 0.0,
		"snow": 1.0 if s == SEASON_WINTER else 0.0,
		"rain": 1.0 if rain else 0.0,
		"pollen": 1.0 if s == SEASON_SUMMER and not rain else 0.0,
		"frost": 1.0 if s == SEASON_WINTER else 0.0,
	}


## Nível atual de um efeito (pros testes/HUD).
func level(fx: String) -> float:
	if fx == "frost":
		return _frost_level
	return _fx[fx].level if _fx.has(fx) else 0.0


# ------------------------------------------------------------ andamento
func _process(delta: float) -> void:
	if _fx.is_empty():
		return
	var tg := targets()
	var step := fade_speed * delta
	for k in _fx:
		var fx: Dictionary = _fx[k]
		fx.level = move_toward(fx.level, tg[k], step)
		_apply(fx)
	_frost_level = move_toward(_frost_level, tg.frost, step)
	_frost.color.a = frost_alpha * _frost_level


func _apply(fx: Dictionary) -> void:
	var p: CPUParticles2D = fx.node
	p.modulate.a = fx.level
	var on: bool = fx.level > 0.01
	if p.emitting != on:
		p.emitting = on


## Pula direto pro clima certo (jogo começando / save carregado): sem esperar o fade e
## já com as partículas espalhadas pela clareira (não "começando a cair" do nada).
func snap() -> void:
	if _fx.is_empty():
		return
	var tg := targets()
	for k in _fx:
		var fx: Dictionary = _fx[k]
		fx.level = tg[k]
		var p: CPUParticles2D = fx.node
		p.preprocess = p.lifetime if fx.level > 0.0 else 0.0
		_apply(fx)
		if fx.level > 0.0:
			p.restart()
	_frost_level = tg.frost
	_frost.color.a = frost_alpha * _frost_level
