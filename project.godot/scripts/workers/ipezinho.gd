extends CharacterBody2D

signal state_changed(new_state: String)
signal injured_changed(is_injured: bool)

const STATE_LABELS := {
	"idle": "ocioso",
	"eating": "comendo",
	"mining": "minerando",
	"storing": "armazenando",
	"manual": "ordem manual",
	"home": "indo pra casa",
}
## Distância da porta/cama a partir da qual o ipezinho "chega" em casa.
const REST_REACH := 12.0
const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const STEEL_PICKAXE := preload("res://assets/game/pickaxe_aco.png")
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
## Fome gasta por segundo (ritmo: era 0.7).
@export var hunger_decay: float = 0.8
@export var hunger_threshold: float = 30.0  # abaixo disso, prioridade vira comer
## Come até atingir essa fração da fome máxima.
@export_range(0.5, 1.0) var eat_until_ratio: float = 0.95

@export_group("Turno / casa")
## Fração do gasto normal de fome enquanto dorme (0.2 = gasta 20%). Andando pra casa gasta normal.
@export_range(0.0, 1.0) var sleep_hunger_mult: float = 0.2
## Atraso máximo (s) pra reagir ao anoitecer/amanhecer, pra não saírem todos no mesmo frame.
@export var phase_react_delay: float = 1.5

@export_group("Acidentes")
## Chance de se machucar a cada ciclo de mineração (0.04 = 4%).
@export_range(0.0, 1.0) var injury_chance: float = 0.04
## Minério extraído que conta como um "ciclo de mineração" (16 = uma carga cheia).
@export var mining_cycle_amount: float = 16.0
## Segundos DESCANSANDO em casa até curar (o caminho até lá não conta).
@export var recovery_time: float = 30.0
## Multiplicador de velocidade enquanto está machucado (mancando).
## 0.73 -> pior caso (machucado + carga cheia) ≈ 120 x 0.65 x 0.73 ≈ 57 px/s.
@export var injured_speed_mult: float = 0.73

@export_group("Carga")
## Minério por viagem (ritmo: era 20).
@export var cargo_capacity: float = 16.0

@export_group("IA")
@export var auto_mode: bool = true  # true = IA decide sozinha; false = só controle manual por clique
@export var decision_interval: float = 1.0  # a cada quantos segundos a IA reavalia o que fazer
## Segundos que a IA espera depois de uma ordem manual antes de voltar a decidir.
## Só começa a contar quando ele CHEGA no destino (a caminhada não gasta esse tempo).
@export var manual_override_time: float = 6.0
## Distância máxima de um passeio aleatório quando está ocioso.
@export var idle_wander_radius: float = 50.0

@export_group("Visual")
@export var walk_anim_fps: float = 9.0
@export var head_lamp_enabled: bool = true

var hunger: float = 100.0
var carrying: float = 0.0
## Tipo do minério carregado (um tipo por vez; vale só com carrying > 0).
var cargo_type: String = "ferro"
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
var _home: Node2D = null  # casa com a cama fixa deste ipezinho (null = sem teto)
var _home_slot: int = -1
var _resting: bool = false  # chegou e está dormindo
var _inside: bool = false  # dormindo DENTRO de casa (fica invisível)
var _camp_pos: Variant = null  # onde dorme ao relento quando não tem cama
var _body_base_y: float = 0.0
var injured: bool = false
var _recovery_left: float = 0.0
var _mined_since_roll: float = 0.0
var _hub_node: Node = null
## Preenchido pelo SaveManager antes de entrar na árvore (ipezinho vindo do save).
var pending_save_data: Dictionary = {}
var _saved_home: String = ""  # nome da casa salva (a cama volta pro mesmo dono)
var _saved_home_slot: int = -1

@onready var _hunger_label: Label = $HungerLabel
@onready var _cargo_label: Label = $CargoLabel
@onready var _body: Sprite2D = $Body
@onready var _tool: Sprite2D = $Tool
@onready var _carry_icon: Sprite2D = $CarryIcon
@onready var _injury_icon: Sprite2D = $InjuryIcon
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
	_body_base_y = _body.position.y
	if not pending_save_data.is_empty():
		load_save_data(pending_save_data)
		pending_save_data = {}
	_claim_home.call_deferred()  # as casas precisam estar nos grupos
	_sync_tool_visual.call_deferred()  # recrutado depois da picareta de aço já nasce com ela
	_update_hunger_label()
	_update_cargo_label()


func _exit_tree() -> void:
	_release_station()
	if _home != null and is_instance_valid(_home):
		_home.set_inside(self, false)
		_home.release_slot(self)
	_home = null


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
	if injured and _ai_state == "home":
		return "curando (%ds)" % ceili(_recovery_left) if _resting else "machucado, indo pra casa"
	if _ai_state == "home" and _resting:
		return "dormindo" if _inside else "dormindo ao relento"
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
	_agent.max_speed = speed * _speed_bonus() * 1.2  # o desvio (RVO) limita a velocidade nisso
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
	if injured:
		s *= injured_speed_mult
	return s * _speed_bonus()


## Bônus de velocidade das "Trilhas batidas" do Centro da Vila.
func _speed_bonus() -> float:
	var hub := _village_hub()
	return hub.speed_mult() if hub else 1.0


func _village_hub() -> Node:
	if _hub_node == null or not is_instance_valid(_hub_node):
		_hub_node = get_tree().get_first_node_in_group("village_hub")
	return _hub_node


# ------------------------------------------------------------ fome / IA
func _process(delta: float) -> void:
	var was_starving := hunger <= 0.0
	var decay := hunger_decay * (sleep_hunger_mult if _resting else 1.0)
	hunger = maxf(hunger - decay * delta, 0.0)
	if int(hunger) != _last_hunger_int:
		_update_hunger_label()
	if hunger <= 0.0 and not was_starving:
		_on_starving()

	_work_timer = maxf(_work_timer - delta, 0.0)
	# só cura descansando (em casa ou ao relento)
	if injured and _resting:
		_recovery_left -= delta
		if _recovery_left <= 0.0:
			_heal()
	if _manual_timer > 0.0 and not (_ai_state == "manual" and _moving):
		_manual_timer -= delta

	if auto_mode and _manual_timer <= 0.0 and not (_ai_state == "manual" and _moving):
		_decision_timer -= delta
		if _decision_timer <= 0.0:
			_decision_timer = decision_interval * randf_range(0.85, 1.15)
			_decide_next_action()

	# chegou na porta de casa (ou no cantinho onde dorme ao relento)
	if _ai_state == "home" and not _resting and not _moving:
		if global_position.distance_to(_rest_position()) <= REST_REACH:
			_start_resting()


func _choose_state() -> String:
	# Prioridade 0: de noite o turno acabou — todo mundo pra casa, mesmo com fome ou carga.
	if _is_night():
		return "home"
	# Machucado: vai pra casa descansar, mesmo de dia (antes dos outros).
	if injured:
		return "home"
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

	if desired == "home":
		_release_station()
		_set_state("home")
		_go_home()
		return

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
		if node.has_method("accepts_worker") and not node.accepts_worker(self) and node != _station:
			continue
		var score := global_position.distance_to(node.global_position)
		if node.has_method("occupied_slot_count") and node != _station:
			score += node.occupied_slot_count() * 40.0
		# minério mais valioso "parece mais perto" (cobre vale 2x o ferro -> distância pela metade)
		if node.has_method("get_value_weight"):
			score /= maxf(node.get_value_weight(), 0.1)
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
	if _ai_state == "home":
		_stop_resting()
	_ai_state = new_state
	state_changed.emit(new_state)


# ------------------------------------------------------------ turno / casa
func _sync_tool_visual() -> void:
	var oficina := get_tree().get_first_node_in_group("oficina")
	if oficina and oficina.has_tool("picareta_aco"):
		on_tool_crafted("picareta_aco")


func _is_night() -> bool:
	var cycle := get_tree().get_first_node_in_group("day_night")
	return cycle != null and cycle.is_night()


## Chamado pelo DayNight na virada de fase: reage logo (com um atraso aleatório curto).
func on_phase_changed(_night: bool) -> void:
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, phase_react_delay)


func has_home() -> bool:
	return _home != null and is_instance_valid(_home)


## Pega uma cama (se ainda não tem casa). Vindo do save, tenta a mesma cama de antes;
## senão escolhe a casa com MAIS camas livres (empate: a mais perto), pra espalhar
## os ipezinhos pela vila em vez de empilhar todo mundo na casa mais próxima.
func _claim_home() -> void:
	if has_home():
		return
	if _saved_home != "":
		for casa in get_tree().get_nodes_in_group("casas"):
			if String(casa.name) == _saved_home:
				var bed: int = casa.claim_specific_bed(self, _saved_home_slot)
				if bed >= 0:
					_home = casa
					_home_slot = bed
				break
		_saved_home = ""
		if has_home():
			return
	var best: Node2D = null
	var best_free := 0
	var best_dist := INF
	for casa in get_tree().get_nodes_in_group("casas"):
		if not casa.has_free_slot_for(self):
			continue
		var free: int = casa.free_slot_count()
		var d := global_position.distance_to(casa.global_position)
		if free > best_free or (free == best_free and d < best_dist):
			best_free = free
			best_dist = d
			best = casa
	if best:
		_home = best
		_home_slot = best.claim_bed(self)


func _rest_position() -> Vector2:
	if has_home():
		return _home.get_slot_position(_home_slot)
	if _camp_pos == null:
		# sem cama: dorme do lado de fora da casa mais próxima (ou do armazém)
		var near := _closest_in_group("casas")
		if near == null:
			near = _closest_in_group("armazens")
		_camp_pos = near.get_wait_position(self) if near else global_position
	return _camp_pos


func _go_home() -> void:
	if not has_home():
		_claim_home()  # pode ter sobrado cama (alguém saiu / casa nova)
	if _resting:
		return
	var dest := _rest_position()
	if global_position.distance_to(dest) <= REST_REACH:
		_start_resting()
	elif not _moving or _target.distance_to(dest) > 1.0:
		_go_to(dest)


func _start_resting() -> void:
	_resting = true
	_moving = false
	_inside = has_home()
	if _inside:
		_home.set_inside(self, true)
		_agent.avoidance_enabled = false  # "dentro de casa": não atrapalha quem passa na porta
	queue_redraw()


func _stop_resting() -> void:
	if _inside and has_home():
		_home.set_inside(self, false)
	_resting = false
	_inside = false
	_camp_pos = null
	_agent.avoidance_enabled = avoidance_enabled
	queue_redraw()


# ------------------------------------------------------------ ferramentas (Oficina)
## Chamado pela Oficina: a picareta de aço troca o visual da ferramenta.
func on_tool_crafted(id: String) -> void:
	if id == "picareta_aco":
		_tool.texture = STEEL_PICKAXE


# ------------------------------------------------------------ acidentes
## Machuca o ipezinho (chamado pelo sorteio na mineração; tecla K testa no selecionado).
func hurt() -> void:
	if injured:
		return
	injured = true
	_recovery_left = get_recovery_time()
	_work_timer = 0.0
	_decision_timer = 0.0  # larga a picareta e vai pra casa já
	_popup("Ai!", Color(1.0, 0.4, 0.35))
	Audio.hurt(global_position)
	var flash := create_tween()
	flash.tween_property(_body, "self_modulate", Color(2.0, 0.5, 0.5), 0.06)
	flash.tween_property(_body, "self_modulate", Color.WHITE, 0.3)
	injured_changed.emit(true)


## Tempo total de recuperação (a Enfermaria do Centro da Vila reduz).
func get_recovery_time() -> float:
	var hub := _village_hub()
	return recovery_time * (hub.recovery_mult() if hub else 1.0)


func _heal() -> void:
	injured = false
	_recovery_left = 0.0
	_popup("Curado!", Color(0.55, 1.0, 0.5))
	Audio.heal(global_position)
	# de dia volta ao trabalho logo; de noite continua dormindo
	_decision_timer = randf_range(0.05, phase_react_delay)
	injured_changed.emit(false)


## Sorteia o acidente a cada mining_cycle_amount de minério extraído.
func _roll_injury(mined: float) -> void:
	_mined_since_roll += mined
	while _mined_since_roll >= mining_cycle_amount:
		_mined_since_roll -= mining_cycle_amount
		if randf() < injury_chance:
			hurt()
			return


## Texto flutuante acima da cabeça.
func _popup(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 13)
	label.position = Vector2(-18, -62)
	label.z_index = 20
	add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 22.0, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


# ------------------------------------------------------------ interações (duck typing)
func _on_starving() -> void:
	_hunger_label.modulate = Color.RED


func feed(amount: float) -> void:
	hunger = minf(hunger + amount, hunger_max)
	_hunger_label.modulate = Color.WHITE
	if hunger >= hunger_max * eat_until_ratio and _ai_state == "eating":
		_decision_timer = 0.0  # satisfeito: decide o próximo passo já


func mine(amount: float, ore_type: String = "ferro") -> float:
	if injured:
		return 0.0  # machucado não consegue minerar
	if carrying > 0.0 and ore_type != cargo_type:
		return 0.0  # não mistura minérios na mesma carga
	if carrying <= 0.0 and ore_type != cargo_type:
		cargo_type = ore_type
		_carry_icon.texture = Ores.CHUNK_TEXTURES.get(cargo_type, _carry_icon.texture)
	var space := cargo_capacity - carrying
	var taken: float = minf(amount, space)
	carrying += taken
	if taken > 0.0:
		_work_timer = 0.2
		_roll_injury(taken)
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

	# dormindo: dentro de casa some; ao relento fica deitado no chão
	_body.visible = not _inside
	_tool.visible = not _resting
	_lamp.enabled = head_lamp_enabled and not _resting
	var lying := _resting and not _inside
	var limp := injured and spd > 5.0
	if lying:
		_body.rotation = -PI * 0.5 * _facing
	elif limp:
		_body.rotation = sin(_anim_time * PI) * 0.12  # mancando: tomba pra um lado a cada passo
	else:
		_body.rotation = 0.0
	var bob := absf(sin(_anim_time * PI * 0.5)) * 2.0 if limp else 0.0
	_body.position.y = _body_base_y + (9.0 if lying else 0.0) + bob
	_injury_icon.visible = injured and not _inside
	if _injury_icon.visible:
		_injury_icon.position.y = -40.0 + sin(Time.get_ticks_msec() * 0.005) * 1.5

	# pedrinha de minério em cima da cabeça, maior quanto mais carga
	_carry_icon.visible = carrying > 0.0 and not _resting
	if _carry_icon.visible:
		var r := carrying / cargo_capacity
		_carry_icon.scale = Vector2.ONE * lerpf(1.0, 2.0, r)
		_carry_icon.position.y = -44.0 - (2.0 if _body.frame % 2 == 1 else 0.0)

	# vermelho de fome / rosado de machucado
	if hunger <= 0.0:
		_body.modulate = Color(1.0, 0.6, 0.6)
	elif injured:
		_body.modulate = Color(1.0, 0.78, 0.74)
	else:
		_body.modulate = Color.WHITE


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
	if not _inside:
		draw_circle(Vector2(1.5, 0.5), 12.0, Color(0.02, 0.02, 0.05, 0.5))
	if selected:
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 32, Color(1.0, 0.84, 0.25), 2.5)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {
		"name": String(name),
		"position": SaveUtil.vec2_to_array(global_position),
		"hunger": hunger,
		"carrying": carrying,
		"cargo_type": cargo_type,
		"injured": injured,
		"recovery_left": _recovery_left,
		"mined_since_roll": _mined_since_roll,
		"facing": _facing,
		"home": String(_home.name) if has_home() else "",
		"home_slot": _home_slot if has_home() else -1,
	}


## Aplicado no _ready (via pending_save_data). A IA recomeça do zero e decide sozinha.
func load_save_data(d: Dictionary) -> void:
	hunger = clampf(SaveUtil.num(d, "hunger", hunger_max), 0.0, hunger_max)
	carrying = clampf(SaveUtil.num(d, "carrying", 0.0), 0.0, cargo_capacity)
	var t := SaveUtil.text(d, "cargo_type", "ferro")
	cargo_type = t if Ores.NAMES.has(t) else "ferro"
	_carry_icon.texture = Ores.CHUNK_TEXTURES.get(cargo_type, _carry_icon.texture)
	injured = SaveUtil.boolean(d, "injured", false)
	_recovery_left = maxf(SaveUtil.num(d, "recovery_left", 0.0), 0.0) if injured else 0.0
	if injured and _recovery_left <= 0.0:
		_recovery_left = get_recovery_time()
	_mined_since_roll = maxf(SaveUtil.num(d, "mined_since_roll", 0.0), 0.0)
	_facing = -1.0 if SaveUtil.num(d, "facing", 1.0) < 0.0 else 1.0
	_saved_home = SaveUtil.text(d, "home", "")
	_saved_home_slot = SaveUtil.integer(d, "home_slot", -1)
	_target = global_position
	_update_hunger_label()
	_update_cargo_label()
