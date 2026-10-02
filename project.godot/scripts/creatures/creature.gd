extends Node2D
## Criatura noturna (grupo "criaturas"), criada pela Defesa (defense.gd) nas noites de invasão.
##
##   Lumívoro   — come luz e calor. Vem da clareira pelo túnel. Ataca quem está acordado
##                lá fora e, nas casas/prédios acesos, assusta quem está dentro (ânimo cai).
##   Ferrugento — máquina de antes da explosão. Sobe pelo poço do elevador (só depois que
##                o nível 2 abre). Ataca quem estiver perto e rouba minério do armazém.
## Antes de entrar, precisa derrubar a barricada do caminho (se tiver uma de pé).
## Bloco 36: com o guarda do portão dele CAÍDO (brecha), vai direto no armazém saquear
## (defense.gd: raid — uma parte do minério e dos créditos, uma vez por portão por invasão).
## Ao amanhecer: o Lumívoro foge da luz e o Ferrugento desliga.
## Prompt 17: na vista iso a arte nova vem de iso_bonecos.gd (criatura_pose), pelo estado daqui:
## andando, atacando (_attack_at), levando golpe (_hit_at), morrendo (_died_at, fica deitado um
## pouco antes de sumir) e desligando ao amanhecer. Variante FORTE (bruto/carregador): defense.gd
## escolhe nas ondas altas (make_strong).

const IsoArt := preload("res://scripts/iso/iso_art.gd")
signal died(killed: bool)

@export_enum("lumivoro", "ferrugento") var kind: String = "lumivoro"
@export var max_hp: float = 18.0
@export var speed: float = 68.0
@export var damage: float = 4.0
@export var attack_interval: float = 1.0
@export var attack_range: float = 18.0
## Ipezinho (não guarda) atingido: chance do machucado ser grave.
@export_range(0.0, 1.0) var grave_chance: float = 0.15
## Ferrugento no armazém: minério roubado por golpe.
@export var steal_amount: float = 3.0
## Lumívoro num prédio aceso: ânimo tirado de cada um lá dentro, por golpe.
@export var scare_amount: float = 1.0
## Distância em que ele larga o alvo e parte pra cima de quem está perto.
@export var notice_range: float = 150.0

var hp: float = 0.0
## Portão por onde ele vem ("tunel"/"poco") — Bloco 36, pra saber se a brecha é a dele.
var gate_id: String = ""
## Já passou (ou derrubou) a barricada do caminho?
var inside: bool = false
var _gate: Node2D = null
var _target: Node2D = null
var _aggressor: Node2D = null
var _attack_cd := 0.0
var _retarget := 0.0
var _anim := 0.0
var _dying := false
var _leaving := false
## Prompt 17: "" ou "forte" (Lumívoro bruto / Ferrugento carregador).
var variant := ""
## Quando (no relógio _anim) atacou, levou golpe, caiu e começou a ir embora: escolhem a animação.
var _attack_at := -100.0
var _hit_at := -100.0
var _died_at := -100.0
var _left_at := -100.0
## Ferrugento que já roubou minério: a caçamba vai cheia.
var looted := false

@onready var _visual: Sprite2D = $Visual
@onready var _agent: NavigationAgent2D = $Agent
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group("criaturas")
	hp = max_hp
	_light.add_to_group("cullable_lights")


## Chamado pela Defesa logo depois de nascer: qual barricada fica no caminho e quão forte é a onda.
func setup(gate: Node2D, hp_mult: float) -> void:
	_gate = gate
	max_hp *= hp_mult
	hp = max_hp
	inside = gate == null or not gate.is_standing()


## Prompt 17: a variante forte (mais vida e dano, um pouco mais lenta).
func make_strong(hp_mult: float, damage_mult: float) -> void:
	variant = "forte"
	max_hp *= hp_mult
	hp = max_hp
	damage *= damage_mult
	speed *= 0.9
	_visual.scale *= 1.25


func is_alive() -> bool:
	return not _dying and not _leaving


func _process(delta: float) -> void:
	_anim += delta
	_visual.frame = int(_anim * (9.0 if kind == "lumivoro" else 5.0)) % 2
	if _dying or _leaving:
		return
	_attack_cd -= delta
	_retarget -= delta
	if _gate != null and (not is_instance_valid(_gate) or not _gate.is_standing()):
		_gate = null
		inside = true
	if _gate != null:
		_target = _gate
	elif _retarget <= 0.0 or _target == null or not is_instance_valid(_target) or not _target_ok(_target):
		_retarget = 0.7
		_target = _pick_target()
	if _target == null:
		return
	var tpos := _target.global_position
	var d := global_position.distance_to(tpos)
	var reach := attack_range + (22.0 if _target.is_in_group("barricadas") or _is_building(_target) else 0.0)
	var wall := IsoArt.base_rect(_target) if _is_building(_target) else Rect2()
	if wall.has_area():
		# Prompt 29: o prédio novo tem fundo de verdade; conta até a parede (o centro fica longe)
		d = global_position.distance_to(global_position.clamp(wall.position, wall.end))
		reach = attack_range + 10.0
	if d > reach:
		if _agent.target_position.distance_to(tpos) > 8.0:
			_agent.target_position = tpos
		var next := _agent.get_next_path_position()
		var step := (next - global_position).limit_length(speed * delta)
		global_position += step
		if absf(step.x) > 0.01:
			_visual.flip_h = step.x < 0.0
	elif _attack_cd <= 0.0:
		_attack_cd = attack_interval
		_attack(_target)
	queue_redraw()


func _is_building(n: Node) -> bool:
	return n.is_in_group("casas") or n.is_in_group("armazens") or n.is_in_group("enfermarias") \
		or n.is_in_group("tavernas") or n.is_in_group("village_hub")


func _target_ok(t: Node2D) -> bool:
	if t.is_in_group("ipezinhos"):
		return not t.get("injured") and not t.get("_inside") and _on_surface(t)
	if t.is_in_group("robos"):
		return t.can_fight()
	return true


func _on_surface(n: Node2D) -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	return env == null or env.level_at(n.global_position) == 0


func _nearest(candidates: Array, max_d: float = INF) -> Node2D:
	var best: Node2D = null
	var best_d := max_d
	for c in candidates:
		var d := global_position.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


func _pick_target() -> Node2D:
	# Bloco 36: guarda do meu portão caído = brecha: direto pro armazém
	var def := get_tree().get_first_node_in_group("defense")
	if def and def.breached(gate_id):
		var stores := get_tree().get_nodes_in_group("armazens")
		if not stores.is_empty():
			return _nearest(stores)
	# quem me bateu por último, se ainda estiver perto
	if _aggressor != null and is_instance_valid(_aggressor) and _target_ok(_aggressor) \
			and global_position.distance_to(_aggressor.global_position) < notice_range:
		return _aggressor
	var awake := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return _target_ok(w))
	if kind == "lumivoro":
		# atraído pela luz: gente acordada lá fora (lanterna na cabeça) ou prédio aceso
		var who := _nearest(awake, notice_range * 1.8)
		if who:
			return who
		var lit: Array = []
		for c in get_tree().get_nodes_in_group("casas"):
			if c.sleeping_count() > 0:
				lit.append(c)
		for g in ["enfermarias", "tavernas"]:
			for n in get_tree().get_nodes_in_group(g):
				if n.has_method("guests") and not n.guests().is_empty():
					lit.append(n)
				elif n.has_method("patients") and not n.patients().is_empty():
					lit.append(n)
		if lit.is_empty():
			lit = get_tree().get_nodes_in_group("village_hub")
		return _nearest(lit)
	# ferrugento: quem estiver perto; senão o minério do armazém
	var near := _nearest(awake, notice_range)
	if near:
		return near
	var full := get_tree().get_nodes_in_group("armazens").filter(func(a): return a.total_stored >= 1.0)
	if not full.is_empty():
		return _nearest(full)
	return _nearest(awake)


func _attack(t: Node2D) -> void:
	_attack_at = _anim
	_visual.position.y = -3.0
	create_tween().tween_property(_visual, "position:y", 0.0, 0.15)
	if t.is_in_group("barricadas"):
		t.damage(damage)
		if kind == "ferrugento":
			Audio.clank(global_position)
		return
	if t.is_in_group("armazens"):
		var def := get_tree().get_first_node_in_group("defense")
		if def and def.breached(gate_id):
			def.raid(self, t)  # Bloco 36: saque pela brecha
	if t.has_method("take_hit"):
		t.take_hit(damage, self)
		if kind == "lumivoro":
			Audio.screech(global_position)
		else:
			Audio.clank(global_position)
		return
	if kind == "ferrugento" and t.is_in_group("armazens"):
		var left := steal_amount
		for ore in ["ferro", "cobre", "carvao", "prata", "solarita"]:
			if left <= 0.0:
				break
			left -= t.take(left, ore)
		if left < steal_amount:
			looted = true
			t.show_popup("-%d (Ferrugento)" % roundi(steal_amount - left), Color(1.0, 0.45, 0.35))
		Audio.clank(global_position)
		return
	if kind == "lumivoro":
		# prédio aceso: quem está lá dentro morre de medo
		for w in get_tree().get_nodes_in_group("ipezinhos"):
			if w.get("_inside") and w.global_position.distance_to(t.global_position) < 90.0:
				w.happiness = maxf(w.happiness - scare_amount, 0.0)
		Audio.screech(global_position)


func take_hit(amount: float, attacker: Node2D) -> void:
	if not is_alive():
		return
	hp -= amount
	_hit_at = _anim
	_aggressor = attacker
	_visual.modulate = Color(2.2, 2.2, 2.2)
	create_tween().tween_property(_visual, "modulate", Color.WHITE, 0.15)
	if hp <= 0.0:
		die(true)
	queue_redraw()


func die(killed: bool) -> void:
	if _dying:
		return
	_dying = true
	_died_at = _anim
	_light.enabled = false
	died.emit(killed)
	if killed and kind == "ferrugento" and randf() < 0.35:
		var finds := get_tree().get_first_node_in_group("finds")
		if finds:
			finds.rare_parts += 1
			var hud := get_tree().get_first_node_in_group("hud")
			if hud:
				hud.show_toast("Um Ferrugento virou sucata: +1 peça rara.", Color(1.0, 0.85, 0.45))
	var t := create_tween()
	if _iso_art():
		t.tween_interval(1.4)  # Prompt 17: cai (animação) e fica um pouco no chão antes de sumir
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)


## Amanhecer: o Lumívoro foge voando; o Ferrugento desliga e vira pó de ferrugem.
func leave_at_dawn() -> void:
	if not is_alive():
		return
	_leaving = true
	_left_at = _anim
	var t := create_tween()
	if kind == "lumivoro":
		t.set_parallel(true)
		t.tween_property(self, "global_position", global_position + Vector2(randf_range(-60, 60), -160), 1.6)
		t.tween_property(self, "modulate:a", 0.0, 1.6)
	else:
		_light.enabled = false
		_visual.modulate = Color(0.55, 0.5, 0.5)
		t.tween_interval(1.5)
		t.tween_property(self, "modulate:a", 0.0, 1.2)
	t.chain().tween_callback(queue_free)


## A vista iso está desenhando esta criatura com a arte nova?
func _iso_art() -> bool:
	var env := get_tree().get_first_node_in_group("environment") if is_inside_tree() else null
	return env != null and env.has_method("has_iso_map") and env.has_iso_map()


func _draw() -> void:
	if _dying or hp >= max_hp:
		return
	var w := 22.0
	draw_rect(Rect2(-w * 0.5, -32, w, 3), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-w * 0.5, -32, w * clampf(hp / max_hp, 0.0, 1.0), 3), Color(0.9, 0.3, 0.25))
