extends "res://scripts/props/station.gd"
## Toca de caça na clareira (grupo "caca") — Bloco 27.
##
## Funciona como a horta, só que de caça: tem uma quantidade, esgota, fica um tempo
## vazia e regenera — bem mais devagar que a horta, pra não ser sempre a escolha óbvia.
## Só o CAÇADOR com ARCO E FLECHA (Oficina) caça aqui. Cada unidade de caça vale
## meat_raw_value de matéria-prima (fruta vale 1), então rende mais por viagem.
##
## Bloco 61: a caça agora é de BICHOS DE VERDADE (animal.gd). A toca é de coelhos ou de javalis:
## faz nascer bichos até o limite (mais devagar no inverno), eles vagam em volta e fogem. O caçador
## caça pela toca como antes, mas cada caçada tira a carne de UM bicho, que cai abatido quando ela
## acaba. Javali rende muito mais, e pode ferir caçador NOVATO (poucos abates) — aí vai pra
## enfermaria e o médico cuida. A caça da toca = a carne dos bichos vivos.

const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Caça")
## Unidades de caça por segundo por caçador.
@export var HUNT_RATE: float = 1.0
## Caça total quando a toca está cheia.
@export var game_total: float = 20.0
## Caça que volta por segundo (a horta volta 0.35/s: aqui é bem mais lento).
@export var regen_rate: float = 0.04
## Segundos vazia depois de esgotar, antes de começar a regenerar.
@export var depleted_cooldown: float = 90.0
## Abaixo disso a toca não atrai caçadores novos.
@export var min_game_to_hunt: float = 4.0
## Matéria-prima que cada unidade de caça rende (uma unidade de fruta rende 1).
@export var meat_raw_value: float = 2.5
## Ferramenta da Oficina exigida pra caçar aqui.
@export var required_tool: String = "arco"

@export_group("Bichos (Bloco 61)")
## "coelho" ou "javali" (javali: mais carne, menos bichos, nasce mais devagar, pode ferir).
@export_enum("coelho", "javali") var animal: String = "coelho"
## Por tipo: [coelho, javali].
@export var max_animals_by_kind: Array[int] = [4, 2]
@export var meat_by_kind: Array[float] = [4.0, 12.0]
@export var spawn_every_by_kind: Array[float] = [45.0, 120.0]
## Ritmo de nascer por estação (primavera, verão, outono, inverno) e o limite no inverno.
@export var season_spawn_mult: Array[float] = [1.0, 1.2, 0.8, 0.3]
@export var winter_max_mult: float = 0.5
## Javali fere o caçador: chance por javali caçado, novato x experiente (abates pra deixar de ser novato).
@export var javali_risk_novice: float = 0.3
@export var javali_risk_expert: float = 0.05
@export var javali_xp: int = 5

const AnimalScript := preload("res://scripts/creatures/animal.gd")
var _animals: Array = []
var _spawn_t := 0.0

var game_remaining: float = 0.0
var _cooldown: float = 0.0
var _hit_time: float = 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $AmountLabel


func _ready() -> void:
	super()
	add_to_group("caca")
	game_total = max_animals() * meat_per_animal()
	game_remaining = 0.0
	_fill_start.call_deferred()
	_update_visual()


func _k() -> int:
	return 1 if animal == "javali" else 0


func max_animals() -> int:
	var n: int = max_animals_by_kind[_k()]
	if _season() == 3:
		n = maxi(int(round(n * winter_max_mult)), 1)
	return n


func meat_per_animal() -> float:
	return meat_by_kind[_k()]


func _season() -> int:
	var sun := get_tree().get_first_node_in_group("sun") if is_inside_tree() else null
	return sun.season_index() if sun else 0


func alive() -> Array:
	_animals = _animals.filter(func(a): return is_instance_valid(a))
	return _animals.filter(func(a): return a.is_alive())


## Jogo novo: a toca já começa com os bichos dela.
func _fill_start() -> void:
	if not _animals.is_empty() or SaveManager.pending_load:
		return
	for i in max_animals():
		spawn_animal()


func spawn_animal(meat: float = -1.0, at: Vector2 = Vector2.INF) -> Node2D:
	var a: Node2D = AnimalScript.new()
	a.kind = animal
	a.toca = self
	a.meat_total = meat_per_animal()
	a.meat_left = meat_per_animal() if meat < 0.0 else clampf(meat, 0.1, meat_per_animal())
	if animal == "javali":
		a.walk_speed = 16.0
		a.flee_speed = 50.0
		a.roam_radius = 110.0
	a.name = "%s_%s" % [animal.capitalize(), name]
	var ang := randf() * TAU
	a.position = at if at != Vector2.INF else global_position + Vector2(cos(ang), sin(ang) * 0.6) * randf_range(25.0, 70.0)
	get_parent().add_child(a)
	_animals.append(a)
	return a


func _accepts(body: Node2D) -> bool:
	return body.has_method("hunt")


## O caçador já tem arco e flecha (a Oficina fabricou)?
func bow_ready() -> bool:
	var oficina := get_tree().get_first_node_in_group("oficina")
	return oficina != null and oficina.has_tool(required_tool)


func is_usable() -> bool:
	return bow_ready() and _cooldown <= 0.0 and not alive().is_empty()


func accepts_worker(_worker: Node) -> bool:
	return bow_ready()


func has_game() -> bool:
	return _cooldown <= 0.0 and not alive().is_empty()


func _process(delta: float) -> void:
	var vivos := alive()
	if _cooldown > 0.0:  # bichos escondidos (toca "esgotada"): sem caça, sem nascer
		_cooldown -= delta
		_hit_time = 0.0
		_update_visual()
		return
	# nascer: até o limite, no ritmo da estação
	if vivos.size() < max_animals():
		_spawn_t += delta * season_spawn_mult[clampi(_season(), 0, season_spawn_mult.size() - 1)]
		if _spawn_t >= spawn_every_by_kind[_k()]:
			_spawn_t = 0.0
			spawn_animal()
	else:
		_spawn_t = 0.0
	var hunting := false
	if bow_ready():
		for body in _working_bodies():
			var alvo: Node = _target_for(body)
			if alvo == null:
				break
			var taken: float = body.hunt(minf(HUNT_RATE * delta, alvo.meat_left), meat_raw_value)
			if taken > 0.0:
				hunting = true
				_javali_risk(body, alvo)
			alvo.meat_left -= taken
			if alvo.meat_left <= 0.0:
				alvo.meat_left = 0.0
				alvo.kill()
				body.hunt_kills = int(body.get("hunt_kills")) + 1
	game_remaining = 0.0
	for a in alive():
		game_remaining += a.meat_left
	_hit_time = _hit_time + delta if hunting else 0.0
	_update_visual()


## O bicho que esse caçador está caçando (o vivo mais perto dele).
func _target_for(body: Node2D) -> Node:
	var best: Node = null
	var best_d := INF
	for a in alive():
		var d: float = a.global_position.distance_to(body.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


## Javali reage uma vez por caçada: caçador novato pode sair ferido.
func _javali_risk(body: Node2D, alvo: Node) -> void:
	if animal != "javali" or alvo.has_meta("reagiu"):
		return
	alvo.set_meta("reagiu", true)
	var novato := int(body.get("hunt_kills")) < javali_xp
	if randf() < (javali_risk_novice if novato else javali_risk_expert):
		body.hurt("javali")
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("O javali avançou em %s! Ferido, vai pra enfermaria." % body.get("display_name"), Color(1.0, 0.5, 0.4))


func _update_visual() -> void:
	var n := alive().size()
	var nome := "javalis" if animal == "javali" else "coelhos"
	# quadro 0 = bicho do lado de fora, 1 = só as orelhas, 2 = vazia
	_visual.frame = 2 if (n == 0 or _cooldown > 0.0) else (1 if n * 2 < max_animals() else 0)
	_visual.position.x = sin(_hit_time * 30.0) * 0.8 if _hit_time > 0.0 else 0.0
	if not bow_ready():
		_label.text = "Toca de %s\n(precisa de arco)" % nome
		_label.modulate = Color(0.85, 0.8, 0.75, 0.75)
	elif _cooldown > 0.0:
		_label.text = "toca vazia (%ds)" % ceili(_cooldown)
		_label.modulate = Color(1, 0.6, 0.45)
	elif n == 0:
		_label.text = "toca vazia (%s voltam)" % nome
		_label.modulate = Color(1, 0.6, 0.45)
	else:
		_label.text = "Toca de %s  %d" % [nome, n]
		_label.modulate = Color(0.95, 0.85, 0.7, 0.9)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"game_remaining": game_remaining, "cooldown": _cooldown, "spawn_t": _spawn_t,
		"animais": alive().map(func(a): return a.get_save_data())}  # Bloco 61


func load_save_data(d: Dictionary) -> void:
	for a in _animals:
		if is_instance_valid(a):
			a.queue_free()
	_animals.clear()
	_spawn_t = maxf(SaveUtil.num(d, "spawn_t", 0.0), 0.0)
	var lista: Array = SaveUtil.array(d, "animais")
	if d.has("animais"):
		for e in lista:
			if e is Array and e.size() >= 4 and String(e[0]) == animal:
				spawn_animal(float(e[1]), Vector2(float(e[2]), float(e[3])))
	else:
		# Bloco 61: save antigo (só a quantidade de caça): os bichos equivalentes
		var g := SaveUtil.num(d, "game_remaining", game_total)
		for i in mini(ceili(g / meat_per_animal()), max_animals()):
			spawn_animal()
	_update_visual()
