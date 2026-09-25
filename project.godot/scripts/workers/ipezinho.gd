extends CharacterBody2D

signal state_changed(new_state: String)

const STATE_LABELS := {
	"idle": "ocioso",
	"eating": "comendo",
	"mining": "minerando",
	"storing": "armazenando",
	"manual": "ordem manual",
}
const STATE_GROUP := {
	"eating": "comedouros",
	"mining": "minerios",
	"storing": "armazens",
}

@export_group("Movimento")
@export var speed: float = 120.0
@export var loaded_speed_penalty: float = 0.35  # 0.35 = até 35% mais lento com carga cheia
## Multiplicador de velocidade quando a fome chega a zero.
@export var starving_speed_mult: float = 0.5
@export var arrive_distance: float = 4.0

@export_group("Navegação")
## Desvio entre ipezinhos (RVO do NavigationAgent2D). Desligado = atravessam uns aos outros.
@export var avoidance_enabled: bool = true
## Raio do ipezinho para o desvio entre agentes.
@export var avoidance_radius: float = 7.0

@export_group("Fome")
@export var hunger_max: float = 100.0
@export var hunger_decay: float = 0.7
@export var hunger_threshold: float = 30.0  # abaixo disso, prioridade vira comer
## Come até atingir essa fração da fome máxima.
@export_range(0.5, 1.0) var eat_until_ratio: float = 0.95

@export_group("Carga")
@export var cargo_capacity: float = 20.0

@export_group("IA")
@export var auto_mode: bool = true  # true = IA decide sozinha; false = só controle manual por clique
@export var decision_interval: float = 1.0  # a cada quantos segundos a IA reavalia o que fazer
## Segundos que a IA espera depois de uma ordem manual (clique) antes de voltar a decidir.
@export var manual_override_time: float = 6.0
## Distância máxima de um passeio aleatório quando está ocioso.
@export var idle_wander_radius: float = 50.0

@export_group("Visual")
@export var walk_anim_fps: float = 9.0
@export var head_lamp_enabled: bool = true

var hunger: float = 100.0
var carrying: float = 0.0
var selected: bool = false

var _target: Vector2 = Vector2.ZERO
var _moving: bool = false
var _ai_state: String = "idle"  # idle | eating | mining | storing | manual
var _decision_timer: float = 0.0
var _manual_timer: float = 0.0
var _station: Node2D = null  # estação cujo slot está reservado
var _slot: int = -1
var _work_timer: float = 0.0  # > 0 enquanto está efetivamente minerando
var _anim_time: float = 0.0
var _swing_time: float = 0.0
var _facing: float = 1.0
var _prev_swing: float = 0.0
var _swing_rising: bool = false
var _last_hunger_int: int = -1

@onready var _hunger_label: Label = $HungerLabel
@onready var _cargo_label: Label = $CargoLabel
@onready var _body: Sprite2D = $Body
@onready var _tool: Sprite2D = $Tool
@onready var _carry_icon: Sprite2D = $CarryIcon
@onready var _lamp: PointLight2D = $HeadLamp
@onready var _agent: NavigationAgent2D = $Agent


func _ready() -> void:
	add_to_group("ipezinhos")
	_target = global_position
	hunger = hunger_max
	_decision_timer = randf_range(0.1, decision_interval)  # dessincroniza os ipezinhos
	_lamp.enabled = head_lamp_enabled
	_lamp.add_to_group("cullable_lights")
	_agent.avoidance_enabled = avoidance_enabled
	_agent.radius = avoidance_radius
	_agent.max_speed = speed * 1.2
	_agent.velocity_computed.connect(_on_velocity_computed)
	_update_hunger_label()
	_update_cargo_label()


func _exit_tree() -> void:
	_release_station()


# ------------------------------------------------------------ comandos
## Ordem do jogador (clique). A IA fica em pausa por manual_override_time.
func move_to(pos: Vector2) -> void:
	_release_station()
	_set_state("manual")
	_manual_timer = manual_override_time
	_go_to(pos)


func _go_to(pos: Vector2) -> void:
	_target = pos
	_moving = true
	_agent.target_position = pos


func get_state() -> String:
	return _ai_state


func get_state_label() -> String:
	var label: String = STATE_LABELS.get(_ai_state, _ai_state)
	if _station == null and STATE_GROUP.has(_ai_state):
		label += " (esperando)"
	return label


## Chamado pelas estações: esse ipezinho está trabalhando nelas agora?
func can_work_at(station: Node) -> bool:
	if _ai_state == "manual" or not auto_mode:
		return not _moving
	return station == _station


# ------------------------------------------------------------ movimento
func _physics_process(delta: float) -> void:
	var desired := Vector2.ZERO
	if _moving:
		var dist_to_target := global_position.distance_to(_target)
		if dist_to_target <= arrive_distance or _agent.is_navigation_finished():
			_moving = false
		else:
			var next := _agent.get_next_path_position()
			var to_next := next - global_position
			var d := to_next.length()
			if d > 0.01:
				var spd := minf(_get_effective_speed(), dist_to_target / delta)
				desired = to_next / d * spd

	if _agent.avoidance_enabled:
		# parado (trabalhando/esperando) tem prioridade: quem está andando desvia dele
		_agent.avoidance_priority = 0.5 if _moving else 1.0
		_agent.velocity = desired  # a resposta chega em _on_velocity_computed
	else:
		_apply_velocity(desired)
	_update_animation(delta)


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_apply_velocity(safe_velocity if _moving else Vector2.ZERO)


func _apply_velocity(v: Vector2) -> void:
	velocity = v
	if velocity.length_squared() > 0.5:
		move_and_slide()


func _get_effective_speed() -> float:
	var load_ratio := carrying / cargo_capacity
	var penalty := 1.0 - (load_ratio * loaded_speed_penalty)
	var s := speed * penalty
	if hunger <= 0.0:
		s *= starving_speed_mult
	return s


# ------------------------------------------------------------ fome / IA
func _process(delta: float) -> void:
	var was_starving := hunger <= 0.0
	hunger = maxf(hunger - hunger_decay * delta, 0.0)
	if int(hunger) != _last_hunger_int:
		_update_hunger_label()
	if hunger <= 0.0 and not was_starving:
		_on_starving()

	_work_timer = maxf(_work_timer - delta, 0.0)
	if _manual_timer > 0.0:
		_manual_timer -= delta

	if auto_mode and _manual_timer <= 0.0 and not (_ai_state == "manual" and _moving):
		_decision_timer -= delta
		if _decision_timer <= 0.0:
			_decision_timer = decision_interval * randf_range(0.85, 1.15)
			_decide_next_action()


func _choose_state() -> String:
	# Prioridade 1: comer. Quem já está comendo só sai quando estiver quase cheio.
	if _ai_state == "eating" and hunger < hunger_max * eat_until_ratio:
		return "eating"
	if hunger < hunger_threshold:
		return "eating"
	# Prioridade 2: depositar carga cheia (e não desistir no meio do caminho).
	if carrying >= cargo_capacity - 0.01:
		return "storing"
	if _ai_state == "storing" and carrying > 0.0:
		return "storing"
	# Prioridade 3: minerar (continua na mesma jazida enquanto ela tiver minério).
	if _ai_state == "mining" and _station_ok_for("mining"):
		return "mining"
	if _find_best_station("minerios") != null:
		return "mining"
	# Sem jazida disponível: guarda o que já tem.
	if carrying > 0.0:
		return "storing"
	return "idle"


func _decide_next_action() -> void:
	var desired := _choose_state()

	if desired == _ai_state and _station_ok_for(desired):
		# Continua o que está fazendo; se foi empurrado pra fora do slot, volta.
		var slot_pos: Vector2 = _station.get_slot_position(_slot)
		if not _moving and global_position.distance_to(slot_pos) > 6.0:
			_go_to(slot_pos)
		return

	_release_station()
	_set_state(desired)

	if desired == "idle":
		if not _moving and randf() < 0.35:
			var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, idle_wander_radius)
			_go_to(global_position + offset)
		return

	var group: String = STATE_GROUP[desired]
	var station := _find_best_station(group)
	if station:
		_station = station
		_slot = station.reserve_slot(self)
		_go_to(station.get_slot_position(_slot))
	else:
		# Tudo ocupado: espera perto da estação mais próxima e tenta de novo no próximo tick.
		var nearest := _closest_in_group(group)
		if nearest:
			_go_to(nearest.get_wait_position(self))


func _station_ok_for(state: String) -> bool:
	if _station == null or not is_instance_valid(_station) or _slot < 0:
		return false
	if state == "mining":
		return _station.has_ore() and carrying < cargo_capacity
	return true


## Estação com slot livre que compensa mais: perto e, de preferência, menos lotada.
func _find_best_station(group_name: String) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group(group_name):
		if node.has_method("is_usable") and not node.is_usable() and node != _station:
			continue
		if node.has_method("has_free_slot_for") and not node.has_free_slot_for(self):
			continue
		var score := global_position.distance_to(node.global_position)
		if node.has_method("occupied_slot_count") and node != _station:
			score += node.occupied_slot_count() * 40.0
		if score < best_score:
			best_score = score
			best = node
	return best


func _closest_in_group(group_name: String) -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	for node in get_tree().get_nodes_in_group(group_name):
		var dist := global_position.distance_to(node.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = node
	return closest


func _release_station() -> void:
	if _station != null and is_instance_valid(_station):
		_station.release_slot(self)
	_station = null
	_slot = -1


func _set_state(new_state: String) -> void:
	if new_state == _ai_state:
		return
	_ai_state = new_state
	state_changed.emit(new_state)


# ------------------------------------------------------------ interações (duck typing)
func _on_starving() -> void:
	_hunger_label.modulate = Color.RED


func feed(amount: float) -> void:
	hunger = minf(hunger + amount, hunger_max)
	_hunger_label.modulate = Color.WHITE
	if hunger >= hunger_max * eat_until_ratio and _ai_state == "eating":
		_decision_timer = 0.0  # satisfeito: decide o próximo passo já


func mine(amount: float) -> float:
	var space := cargo_capacity - carrying
	var taken: float = minf(amount, space)
	carrying += taken
	if taken > 0.0:
		_work_timer = 0.2
	if carrying >= cargo_capacity - 0.01:
		_decision_timer = 0.0  # cheio: vai depositar sem esperar o próximo tick
	_update_cargo_label()
	return taken


func deposit(amount: float) -> float:
	var given: float = minf(amount, carrying)
	carrying -= given
	if carrying <= 0.0:
		carrying = 0.0
		_decision_timer = 0.0
	_update_cargo_label()
	return given


# ------------------------------------------------------------ visual
func _update_animation(delta: float) -> void:
	var spd := velocity.length()
	if spd > 5.0:
		_anim_time += delta * walk_anim_fps * clampf(spd / speed, 0.5, 1.3)
		var new_frame := int(_anim_time) % _body.hframes
		if new_frame != _body.frame and new_frame % 2 == 0:
			Audio.step(global_position)  # pé tocando o chão (quadros 0 e 2)
		_body.frame = new_frame
		if absf(velocity.x) > 3.0:
			_facing = signf(velocity.x)
	else:
		_anim_time = 0.0
		_body.frame = 0

	_body.flip_h = _facing < 0.0
	_body.skew = -0.08 * _facing if spd > 5.0 else 0.0  # leve inclinação ao andar

	# picareta: no ombro andando, balançando enquanto minera
	_tool.position.x = 9.0 * _facing
	_tool.scale = Vector2(2.0 * _facing, 2.0)
	if _work_timer > 0.0:
		_swing_time += delta
		var swing := (sin(_swing_time * 12.0) * 0.5 + 0.5)  # 0..1
		_tool.rotation = _facing * lerpf(-0.9, 1.4, swing * swing)
		# impacto = ponto mais baixo do golpe (a curva para de subir)
		var rising := swing > _prev_swing
		if _swing_rising and not rising:
			Audio.pick(global_position)
		_swing_rising = rising
		_prev_swing = swing
	else:
		_swing_time = 0.0
		_prev_swing = 0.0
		_swing_rising = false
		_tool.rotation = _facing * -0.35

	# pedrinha de minério em cima da cabeça, maior quanto mais carga
	_carry_icon.visible = carrying > 0.0
	if _carry_icon.visible:
		var r := carrying / cargo_capacity
		_carry_icon.scale = Vector2.ONE * lerpf(1.0, 2.0, r)
		_carry_icon.position.y = -44.0 - (2.0 if _body.frame % 2 == 1 else 0.0)

	# vermelho de fome
	_body.modulate = Color(1.0, 0.6, 0.6) if hunger <= 0.0 else Color.WHITE


func _update_hunger_label() -> void:
	_last_hunger_int = int(hunger)
	_hunger_label.text = str(_last_hunger_int)


func _update_cargo_label() -> void:
	_cargo_label.text = "Carga: %d" % int(carrying)


func set_selected(is_selected: bool) -> void:
	selected = is_selected
	queue_redraw()


func _draw() -> void:
	# sombra + anel de seleção (elipses no pé do personagem)
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.35))
	if selected:
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 32, Color(1.0, 0.84, 0.25), 2.5)
