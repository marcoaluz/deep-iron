extends Node2D
## Bicho da clareira (grupo "animais") — Bloco 61: coelho ou javali que mora numa toca.
##
## Vaga em volta da toca; foge de quem chega perto (o caçador espanta, mas a caça é pela toca:
## hunt_spot.gd tira a carne do bicho-alvo e, quando acaba, o bicho é ABATIDO — cai, vira carcaça
## por um tempo e some). Não vai no save sozinho: a toca guarda os bichos dela.
## Desenho: assets/game/iso/animais (andar/fugir/abatido x SE/SO/NO/NE), copiado pela vista iso
## como qualquer Sprite2D (escala 1/S: 1 px de arte = 1 px de tela, como os bonecos).

const FILE := "res://assets/game/iso/animais/animais.json"
const DIR := "res://assets/game/iso/animais/"
const DIRS := ["SE", "SO", "NO", "NE"]
const ANIM_FPS := 8.0

var kind := "coelho"
var toca: Node = null
## Carne que ainda dá (unidades de caça; a toca define quanto cada um vale).
var meat_left := 4.0
var meat_total := 4.0
var state := "vagar"  # vagar, fugir, abatido
## Raio em volta da toca e velocidades (px da lógica / s).
var roam_radius := 90.0
var walk_speed := 22.0
var flee_speed := 70.0
var carcass_time := 25.0

var _target := Vector2.ZERO
var _wait := 0.0
var _clock := 0.0
var _dead_t := 0.0
var _dir := 0
var _sprite: Sprite2D

static var _data: Dictionary = {}
static var _tex: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(FILE):
		var d = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = d.get("animais", {}) if typeof(d) == TYPE_DICTIONARY else {}
	return _data


static func frame_tex(k: String, anim: String, d: String, i: int) -> Texture2D:
	var key := "%s/%s/%s/%d" % [k, anim, d, i]
	if not _tex.has(key):
		var p := DIR + key + ".png"
		_tex[key] = load(p) if ResourceLoader.exists(p) else null
	return _tex[key]


func _ready() -> void:
	add_to_group("animais")
	_sprite = Sprite2D.new()
	_sprite.name = "Visual"
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	var env := get_tree().get_first_node_in_group("environment")
	var s: float = env.iso_scale() if env and env.has_method("iso_scale") and env.has_method("has_iso_map") and env.has_iso_map() else 0.5
	_sprite.scale = Vector2.ONE / maxf(s, 0.01)
	_pick_target()
	_update_sprite()


func is_alive() -> bool:
	return state != "abatido"


## A toca chama quando a carne dele acabou (foi caçado).
func kill() -> void:
	if state == "abatido":
		return
	state = "abatido"
	_clock = 0.0
	_dead_t = 0.0
	Audio.hit(global_position)


func _process(delta: float) -> void:
	_clock += delta
	if state == "abatido":
		_dead_t += delta
		if _dead_t > carcass_time:
			modulate.a = maxf(modulate.a - delta, 0.0)
			if modulate.a <= 0.0:
				queue_free()
		_update_sprite()
		return
	# foge de ipezinho perto (caçador chegando, alguém passando)
	var perigo := _nearest_worker(70.0)
	if perigo:
		state = "fugir"
		var away := (global_position - perigo.global_position).normalized()
		_target = _clamp_home(global_position + away * 60.0)
	elif state == "fugir":
		state = "vagar"
		_wait = randf_range(0.5, 1.5)
	if _wait > 0.0:
		_wait -= delta
	else:
		var spd := flee_speed if state == "fugir" else walk_speed
		var to := _target - global_position
		if to.length() < 4.0:
			_wait = randf_range(1.0, 4.0)
			_pick_target()
		else:
			var step := to.normalized() * spd * delta
			_set_dir(step)
			global_position += step if step.length() < to.length() else to
	_update_sprite()


func _nearest_worker(r: float) -> Node2D:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.visible and w.global_position.distance_to(global_position) < r:
			return w
	return null


func _home() -> Vector2:
	return (toca as Node2D).global_position if toca != null and is_instance_valid(toca) else global_position


func _clamp_home(p: Vector2) -> Vector2:
	var h := _home()
	if p.distance_to(h) > roam_radius:
		p = h + (p - h).normalized() * roam_radius
	var map := get_world_2d().navigation_map
	if not map.is_valid() or NavigationServer2D.map_get_iteration_id(map) == 0:
		return p  # malha ainda não montada
	var cp := NavigationServer2D.map_get_closest_point(map, p)
	return cp if cp.distance_to(p) < 40.0 else p  # longe do chão andável: fica no círculo mesmo


func _pick_target() -> void:
	var ang := randf() * TAU
	_target = _clamp_home(_home() + Vector2(cos(ang), sin(ang) * 0.6) * randf_range(20.0, roam_radius))


## Direção do desenho: a vista iso anota a direção na tela ("iso_dir"); sem ela, pelo andar.
func _set_dir(step: Vector2) -> void:
	if has_meta("iso_dir"):
		_dir = clampi(int(get_meta("iso_dir")), 0, 3)
		return
	var scr := Vector2(step.x - step.y, (step.x + step.y) * 0.5)
	var ang := wrapf(rad_to_deg(scr.angle()), 0.0, 360.0)
	_dir = int(floor(ang / 90.0)) % 4


func _update_sprite() -> void:
	var d: Dictionary = data().get(kind, {})
	if d.is_empty() or _sprite == null:
		return
	var anim := "abatido" if state == "abatido" else ("fugir" if state == "fugir" else "andar")
	var dn: String = DIRS[_dir]
	var info: Dictionary = d.anims[anim][dn]
	var n: int = int(info.n)
	var i := 0
	if anim == "abatido":
		i = mini(int(_clock * ANIM_FPS), n - 1)  # cai e fica no último quadro
	elif _wait > 0.0 and state == "vagar":
		i = 0  # parado
	else:
		i = int(_clock * ANIM_FPS * (1.5 if anim == "fugir" else 1.0)) % n
	var tx := frame_tex(kind, anim, dn, i)
	if tx and _sprite.texture != tx:
		_sprite.texture = tx
	var q: Array = info.quadro
	_sprite.offset = Vector2(-float(q[0]) * 0.5, -float(info.pe))


func get_save_data() -> Array:
	return [kind, meat_left, global_position.x, global_position.y]
