extends CharacterBody2D

signal state_changed(new_state: String)
signal injured_changed(is_injured: bool)
signal mood_changed(level: int)  # 0 calmo, 1 irritado, 2 furioso

const STATE_LABELS := {
	"idle": "ocioso",
	"eating": "comendo",
	"mining": "minerando",
	"storing": "armazenando",
	"manual": "ordem manual",
	"home": "indo pra casa",
	"gathering": "colhendo comida",
	"delivering": "levando comida",
	"chopping": "cortando madeira",
	"hauling": "levando madeira",
}
## Distância da porta/cama a partir da qual o ipezinho "chega" em casa.
const REST_REACH := 12.0
const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const STEEL_PICKAXE := preload("res://assets/game/pickaxe_aco.png")
const FOOD_BASKET := preload("res://assets/game/food_basket.png")
## Visual do corpo por gênero: 3 variações de cor de roupa/cabelo cada (tools/gen_sprites.py).
## Todas têm o mesmo layout de 4 quadros e o mesmo capacete, então os ícones por cima
## (carga, chapéu de cozinheiro, zanga, curativo) encaixam igual.
const BODY_TEXTURES := {
	"menino": [
		preload("res://assets/game/ipezinho_m0.png"),
		preload("res://assets/game/ipezinho_m1.png"),
		preload("res://assets/game/ipezinho_m2.png"),
	],
	"menina": [
		preload("res://assets/game/ipezinho_f0.png"),
		preload("res://assets/game/ipezinho_f1.png"),
		preload("res://assets/game/ipezinho_f2.png"),
	],
}
const STATE_GROUP := {
	"eating": "comedouros",
	"mining": "minerios",
	"storing": "armazens",
	"gathering": "coleta_comida",
	"delivering": "comedouros",
	"chopping": "arvores",
	"hauling": "armazens",
}
## Função fixa (designada pelo jogador). "" = faz de tudo (minerar etc.).
const ROLE_COOK := "cozinheiro"
const ROLE_LUMBER := "lenhador"
const AXE := preload("res://assets/game/axe.png")
const WOOD_LOG := preload("res://assets/game/wood_log.png")

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

@export_group("Turno extra / zanga")
## Zanga ganha por segundo trabalhando à noite em turno extra (0.8 -> ~+48 por noite).
@export var anger_gain_per_sec: float = 0.8
## Zanga perdida por segundo DORMINDO (em casa, ao relento ou curando). De dia acordado não muda.
@export var anger_decay_per_sec: float = 1.5
## A partir dessa zanga fica "irritado"...
@export_range(0.0, 100.0) var anger_irritated_at: float = 40.0
## ...e a partir dessa, "furioso".
@export_range(0.0, 100.0) var anger_furious_at: float = 75.0
## Multiplica a chance de acidente (injury_chance) quando irritado / furioso.
@export var irritated_injury_mult: float = 2.0
@export var furious_injury_mult: float = 4.0
## Multiplica quanto ele minera por segundo quando irritado / furioso.
@export var irritated_work_mult: float = 0.8
@export var furious_work_mult: float = 0.55
## Multiplica a velocidade de caminhada (acumula com carga, fome e lesão).
@export var irritated_speed_mult: float = 0.95
@export var furious_speed_mult: float = 0.85

@export_group("Cozinheiro")
## Comida que o cozinheiro carrega por viagem (horta -> comedouro).
@export var cook_carry: float = 12.0

@export_group("Lenhador")
## Madeira que o lenhador carrega por viagem (árvore -> armazém).
@export var lumber_carry: float = 8.0

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
## Turno extra: de noite continua trabalhando em vez de ir pra cama (ligado pelo jogador).
var overtime: bool = false
## Função: "" (faz de tudo) ou ROLE_COOK (só busca comida pro comedouro).
var role: String = ""
## "menino" ou "menina": sorteado ao nascer (jogo novo / recrutamento), fixo depois.
var gender: String = ""
## Variação de cor de roupa/cabelo dentro do gênero (índice em BODY_TEXTURES).
var look: int = -1
## Comida na cesta (só o cozinheiro colhe; qualquer um que tenha na mão entrega).
var food_carrying: float = 0.0
## Madeira nas costas (só o lenhador corta; qualquer um que tenha na mão leva pro armazém).
var wood_carrying: float = 0.0
var _default_tool: Texture2D
var _has_steel_pickaxe := false
## Zanga 0..100: sobe no turno extra da noite, desce dormindo.
var anger: float = 0.0
var _mood: int = 0
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
@onready var _anger_icon: Sprite2D = $AngerIcon
@onready var _cook_icon: Sprite2D = $CookIcon
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
	_agent.link_reached.connect(_on_link_reached)
	_body_base_y = _body.position.y
	_default_tool = _tool.texture
	if not pending_save_data.is_empty():
		load_save_data(pending_save_data)
		pending_save_data = {}
	_ensure_appearance()
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
	if overtime and _is_night() and _ai_state != "home":
		label += " (turno extra)"
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
	s *= [1.0, irritated_speed_mult, furious_speed_mult][_mood]  # zanga acumula com a lesão
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
	_update_anger(delta)
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
	# Exceção: quem está em TURNO EXTRA continua trabalhando (e ficando zangado).
	if _is_night() and not overtime:
		return "home"
	# Machucado: vai pra casa descansar, mesmo de dia (antes dos outros).
	if injured:
		return "home"
	# Prioridade 1: comer. Quem já está comendo só sai quando estiver quase cheio.
	# Sem comida no comedouro não adianta esperar lá: segue trabalhando (com fome).
	var food_ok := _food_available()
	if _ai_state == "eating" and hunger < hunger_max * eat_until_ratio and food_ok:
		return "eating"
	if hunger < hunger_threshold and food_ok:
		return "eating"
	# Comida na cesta: leva pro comedouro (cozinheiro com a cesta cheia, sem horta
	# disponível, ou quem deixou de ser cozinheiro com comida na mão).
	if food_carrying > 0.0:
		var basket_full := food_carrying >= cook_carry - 0.01
		# (quem já está colhendo continua até a horta acabar; só depois vai entregar)
		var keep_gathering := _ai_state == "gathering" and _station_ok_for("gathering")
		if not is_cook() or basket_full or _ai_state == "delivering" or (not keep_gathering and not _has_usable_station("coleta_comida")):
			return "delivering"
	# Madeira nas costas: leva pro armazém (lenhador cheio / sem árvore, ou quem deixou de ser lenhador).
	if wood_carrying > 0.0:
		var wood_full := wood_carrying >= lumber_carry - 0.01
		# (quem já está cortando continua até a árvore virar toco; só depois vai descarregar)
		var keep_chopping := _ai_state == "chopping" and _station_ok_for("chopping")
		if not is_lumber() or wood_full or _ai_state == "hauling" or (not keep_chopping and not _has_usable_station("arvores")):
			return "hauling"
	# Lenhador: larga o minério que tiver e passa a só cortar e levar madeira.
	if is_lumber():
		if carrying > 0.0:
			return "storing"
		if _ai_state == "chopping" and _station_ok_for("chopping"):
			return "chopping"
		if _has_usable_station("arvores"):
			return "chopping"
		return "idle"
	# Cozinheiro: larga o minério que tiver e passa a só colher e levar comida.
	if is_cook():
		if carrying > 0.0:
			return "storing"
		if _ai_state == "gathering" and _station_ok_for("gathering"):
			return "gathering"
		if _has_usable_station("coleta_comida"):
			return "gathering"
		return "idle"
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
	if state == "gathering":
		return _station.has_food() and food_carrying < cook_carry - 0.01
	if state == "delivering":
		return food_carrying > 0.0 and _station.space_left() > 0.5
	if state == "eating":
		return _station.has_food()
	if state == "chopping":
		return _station.has_wood() and wood_carrying < lumber_carry - 0.01
	if state == "hauling":
		return wood_carrying > 0.0
	return true


## Chegou na gaiola do elevador (NavigationLink2D): desce/sobe na hora.
func _on_link_reached(details: Dictionary) -> void:
	var link = details.get("owner")
	if not (link is Node) or not link.get_parent() or not link.get_parent().is_in_group("elevador"):
		return
	var exit: Vector2 = details.get("link_exit_position", global_position)
	global_position = exit
	Audio.deposit(exit)  # "clanc" da gaiola
	_body.modulate.a = 0.0
	create_tween().tween_property(_body, "modulate:a", 1.0, 0.35)


## Multiplicador de acidente pela profundidade (nível 2 = mais perigoso).
func depth_danger() -> float:
	var env := get_tree().get_first_node_in_group("environment")
	return env.danger_mult_at(global_position) if env else 1.0


## Existe alguma estação do grupo REALMENTE disponível agora? (Diferente de
## _find_best_station, não aceita a estação atual só por ser a atual: árvore que
## virou toco ou horta colhida não contam — aí o lenhador/cozinheiro vai descarregar.)
func _has_usable_station(group_name: String) -> bool:
	for node in get_tree().get_nodes_in_group(group_name):
		if node.has_method("is_usable") and not node.is_usable():
			continue
		if node.has_method("has_free_slot_for") and not node.has_free_slot_for(self):
			continue
		return true
	return false


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
	else:
		_refresh_tool_texture()


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
	if overtime:
		set_overtime(false)  # foi dormir por conta própria (ex.: machucou): acabou o turno extra
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
		_has_steel_pickaxe = true
	_refresh_tool_texture()


## Machado pro lenhador; picareta (de aço, se já existir) pros outros.
func _refresh_tool_texture() -> void:
	if is_lumber():
		_tool.texture = AXE
	elif _has_steel_pickaxe:
		_tool.texture = STEEL_PICKAXE
	elif _default_tool:
		_tool.texture = _default_tool


# ------------------------------------------------------------ visual: menino/menina
## Sorteia gênero e variação se ainda não tiver (ou se vier inválido do save) e aplica.
func _ensure_appearance() -> void:
	if not BODY_TEXTURES.has(gender):
		gender = "menino" if randf() < 0.5 else "menina"
	var options: Array = BODY_TEXTURES[gender]
	if look < 0 or look >= options.size():
		look = randi() % options.size()
	_body.texture = options[look]


# ------------------------------------------------------------ cozinheiro
func is_cook() -> bool:
	return role == ROLE_COOK


func is_lumber() -> bool:
	return role == ROLE_LUMBER


## Designa/tira a função de cozinheiro (tecla C com o ipezinho selecionado).
func set_role(new_role: String) -> void:
	if role == new_role:
		return
	role = new_role
	_popup({ROLE_COOK: "Cozinheiro!", ROLE_LUMBER: "Lenhador!"}.get(role, "De volta à mina"), Color(0.95, 0.9, 0.6))
	_refresh_tool_texture()
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, 0.4)  # troca de tarefa já


## Horta chama: o cozinheiro põe comida na cesta. Retorna quanto pegou.
func harvest(amount: float) -> float:
	if not is_cook() or injured or _ai_state != "gathering":
		return 0.0
	var taken := minf(amount, cook_carry - food_carrying)
	if taken <= 0.0:
		return 0.0
	food_carrying += taken
	_work_timer = 0.2
	if food_carrying >= cook_carry - 0.01:
		_decision_timer = 0.0  # cesta cheia: vai pro comedouro já
	return taken


## Árvore chama: o lenhador põe madeira nas costas. Retorna quanto pegou.
func chop(amount: float) -> float:
	if not is_lumber() or injured or _ai_state != "chopping":
		return 0.0
	var taken := minf(amount * work_mult(), lumber_carry - wood_carrying)  # zangado corta menos
	if taken <= 0.0:
		return 0.0
	wood_carrying += taken
	_work_timer = 0.2
	if wood_carrying >= lumber_carry - 0.01:
		_decision_timer = 0.0  # carga cheia: vai pro armazém já
	return taken


## Armazém chama: descarrega a madeira. Retorna quanto entregou.
func deliver_wood(amount: float) -> float:
	var given := minf(amount, wood_carrying)
	wood_carrying -= given
	if wood_carrying <= 0.001:
		wood_carrying = 0.0
		_decision_timer = 0.0
	return given


## Comedouro chama: descarrega comida da cesta. Retorna quanto entregou.
func deliver_food(amount: float) -> float:
	var given := minf(amount, food_carrying)
	food_carrying -= given
	if food_carrying <= 0.001:
		food_carrying = 0.0
		_decision_timer = 0.0
	return given


## Algum comedouro com comida?
func _food_available() -> bool:
	for c in get_tree().get_nodes_in_group("comedouros"):
		if not c.has_method("has_food") or c.has_food():
			return true
	return false


# ------------------------------------------------------------ turno extra / zanga
## Liga/desliga o turno extra (tecla T com o ipezinho selecionado).
func set_overtime(on: bool) -> void:
	if overtime == on:
		return
	overtime = on
	if on:
		_popup("Turno extra!", Color(0.6, 0.7, 1.0))
	elif _is_night():
		_popup("Hora de dormir", Color(0.6, 0.7, 1.0))
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, 0.4)  # de noite: acorda ou vai pra cama já


## 0 = calmo, 1 = irritado, 2 = furioso.
func mood() -> int:
	return _mood


func mood_label() -> String:
	return ["", "irritado", "FURIOSO"][_mood]


## Multiplicador da mineração pela zanga.
func work_mult() -> float:
	return [1.0, irritated_work_mult, furious_work_mult][_mood]


func _update_anger(delta: float) -> void:
	if overtime and not _resting and _is_night():
		anger = minf(anger + anger_gain_per_sec * delta, 100.0)
	elif _resting:
		anger = maxf(anger - anger_decay_per_sec * delta, 0.0)
	_refresh_mood()


func _refresh_mood(announce: bool = true) -> void:
	var m := 0
	if anger >= anger_furious_at:
		m = 2
	elif anger >= anger_irritated_at:
		m = 1
	if m == _mood:
		return
	var worse := m > _mood
	_mood = m
	if announce and worse:
		_popup("Grrr!" if m == 2 else "Hmpf...", Color(1.0, 0.45, 0.3) if m == 2 else Color(1.0, 0.75, 0.4))
	mood_changed.emit(m)


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
		# zanga x profundidade: os dois multiplicadores se acumulam
		if randf() < injury_chance * [1.0, irritated_injury_mult, furious_injury_mult][_mood] * depth_danger():
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
	var taken: float = minf(amount * work_mult(), space)  # zangado minera menos
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
			if _ai_state != "gathering" and _ai_state != "chopping":
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
	# zanga: "veia saltando" pulsando (mais rápida e maior quando furioso) + tremidinha
	_anger_icon.visible = _mood > 0 and not _inside
	if _anger_icon.visible:
		var ms := Time.get_ticks_msec()
		var pulse := 1.0 + 0.18 * sin(ms * (0.018 if _mood == 2 else 0.008))
		_anger_icon.scale = Vector2.ONE * (2.0 if _mood == 2 else 1.5) * pulse
		_anger_icon.modulate = Color.WHITE if _mood == 2 else Color(1.0, 0.8, 0.55)
	if _mood == 2 and not lying:
		_body.position.x = sin(Time.get_ticks_msec() * 0.09) * 0.6
	else:
		_body.position.x = 0.0

	# pedrinha de minério em cima da cabeça, maior quanto mais carga
	_cook_icon.visible = is_cook() and not _inside
	_carry_icon.visible = (carrying > 0.0 or food_carrying > 0.0 or wood_carrying > 0.0) and not _resting
	if wood_carrying > 0.0:
		_carry_icon.texture = WOOD_LOG
	elif food_carrying > 0.0:
		_carry_icon.texture = FOOD_BASKET
	elif carrying > 0.0 and (_carry_icon.texture == FOOD_BASKET or _carry_icon.texture == WOOD_LOG):
		_carry_icon.texture = Ores.CHUNK_TEXTURES.get(cargo_type, _carry_icon.texture)
	if _carry_icon.visible:
		var r := carrying / cargo_capacity
		if wood_carrying > 0.0:
			r = wood_carrying / lumber_carry
		elif food_carrying > 0.0:
			r = food_carrying / cook_carry
		_carry_icon.scale = Vector2.ONE * lerpf(1.0, 2.0, r)
		_carry_icon.position.y = -44.0 - (8.0 if is_cook() else 0.0) - (2.0 if _body.frame % 2 == 1 else 0.0)

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
		"anger": anger,
		"overtime": overtime,
		"role": role,
		"food_carrying": food_carrying,
		"wood_carrying": wood_carrying,
		"gender": gender,
		"look": look,
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
	anger = clampf(SaveUtil.num(d, "anger", 0.0), 0.0, 100.0)
	overtime = SaveUtil.boolean(d, "overtime", false)
	var r := SaveUtil.text(d, "role", "")
	role = r if r in [ROLE_COOK, ROLE_LUMBER] else ""
	wood_carrying = clampf(SaveUtil.num(d, "wood_carrying", 0.0), 0.0, lumber_carry)
	food_carrying = clampf(SaveUtil.num(d, "food_carrying", 0.0), 0.0, cook_carry)
	# save antigo (sem visual) ou valor inválido: _ensure_appearance sorteia e o próximo save guarda
	gender = SaveUtil.text(d, "gender", "")
	look = SaveUtil.integer(d, "look", -1)
	_refresh_mood(false)
	_target = global_position
	_update_hunger_label()
	_update_cargo_label()
