extends "res://scripts/props/station.gd"
## Enfermaria (grupo "enfermarias"): o ÚNICO lugar onde ipezinho machucado se cura.
##
## - Cada slot é um LEITO. Começa com base_beds e ganha beds_per_level a cada nível
##   da melhoria "Enfermaria" do Centro da Vila (que também acelera a cura).
## - Internado fica lá dentro (some do mapa), com a janela acesa. A cura só anda no leito.
## - Sem leito (lotada ou longe), o relógio de "sem cuidado" do ipezinho corre:
##   leve piora pra grave, grave morre (regras no ipezinho.gd).
## - Quem morre vai pro MEMORIAL (nome, causa, gravidade, dia) e ganha uma cruzinha
##   no cemitério ao lado da enfermaria. O memorial é salvo e vai servir pro diário.
## - Bloco 47: dá pra construir enfermarias EXTRAS (Centro da Vila). Cada uma tem os seus
##   leitos (mesmo nível da melhoria "Enfermaria", que vale pra todas) e o seu médico de
##   plantão. O memorial e o cemitério ficam só na PRINCIPAL (a que vem com a vila).

signal patient_died(worker_name: String, cause: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const GRAVE := preload("res://assets/game/grave.png")

@export_group("Leitos e cura")
@export var base_beds: int = 2
@export var beds_per_level: int = 1
## Segundos NO LEITO pra curar cada gravidade. A melhoria "Enfermaria" do Centro
## da Vila corta esse tempo (recovery_cut_per_level, lá no Centro da Vila).
@export var heal_time_leve: float = 20.0
@export var heal_time_grave: float = 45.0

@export_group("Médico (Bloco 30)")
## Sem médico a cura é a de sempre (passiva). Cada médico LÁ DENTRO soma essa
## velocidade de cura aos internados (1.5 = +150%: um grave de 45 s cura em ~18 s).
@export var doctor_heal_bonus: float = 1.5
## Quantos médicos somam bônus ao mesmo tempo (os outros ficam de reserva).
@export var max_doctors_effective: int = 2
## Com médico lá dentro, o relógio de "sem cuidado" de quem espera leito na porta corre
## nessa fração (0.5 = metade: demora o dobro pra piorar/morrer).
@export_range(0.0, 1.0) var doctor_waiting_clock_mult: float = 0.5

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "enfermaria"
## Bloco 47: construída pelo jogador (a principal vem na cena e é false).
var extra := false
## [{name, cause, severity, day, position: [x, y]}]
var memorial: Array = []

var _inside: Array[Node] = []
## Médicos de plantão lá dentro (Bloco 30). Não ocupam leito e não vão pro save:
## saem da função (job "médico"), que já é salva — ao carregar eles voltam sozinhos.
var _doctors: Array[Node] = []

@onready var _visual: Sprite2D = $Visual
@onready var _window_light: PointLight2D = $WindowLight
@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("enfermarias")
	add_to_group("clickable")
	_window_light.add_to_group("cullable_lights")
	refresh_beds()
	_connect_hub.call_deferred()
	_update_visual()


func _connect_hub() -> void:
	if not is_inside_tree():
		return  # saiu antes (ex.: carregou um save no mesmo quadro)
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub:
		hub.upgrade_bought.connect(func(id: String, _lvl: int):
			if id == "enfermaria":
				refresh_beds())
	refresh_beds()


## Área clicável (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-34, -58), Vector2(68, 62)).has_point(p)


# ------------------------------------------------------------ leitos / cura
func level() -> int:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return int(hub.upgrades.get("enfermaria", 0)) if hub else 0


## Ajusta o número de leitos ao nível atual (sem tirar ninguém que já está deitado).
func refresh_beds() -> void:
	var n := base_beds + beds_per_level * level()
	if n > slot_count:
		slot_count = n
		_slot_owners.resize(n)
	_update_visual()


func beds_total() -> int:
	return slot_count


func beds_taken() -> int:
	return occupied_slot_count()


## Segundos de leito pra curar essa gravidade, com o desconto da melhoria.
func heal_time(severity: String) -> float:
	var t := heal_time_grave if severity == "grave" else heal_time_leve
	var hub := get_tree().get_first_node_in_group("village_hub")
	var res := get_tree().get_first_node_in_group("research")
	return t * (hub.recovery_mult() if hub else 1.0) * (res.heal_mult() if res else 1.0)


func set_inside(worker: Node, inside: bool) -> void:
	if inside and not _inside.has(worker):
		_inside.append(worker)
	elif not inside:
		_inside.erase(worker)
	_update_visual()


func patients() -> Array:
	_inside = _inside.filter(func(w): return is_instance_valid(w))
	return _inside


## Bloco 47: a enfermaria principal (a da cena): memorial, cemitério e o sinal de morte.
func primary() -> Node:
	for w in get_tree().get_nodes_in_group("enfermarias"):
		if not w.extra:
			return w
	return self


## A enfermaria mais perto de um ipezinho (onde ele espera leito).
func _nearest_ward(worker: Node2D, wards: Array) -> Node:
	var best: Node = null
	var best_d := INF
	for w in wards:
		var d: float = worker.global_position.distance_to(w.global_position)
		if d < best_d:
			best_d = d
			best = w
	return best


# ------------------------------------------------------------ médico (Bloco 30)
## Onde o médico entra (a porta, na frente da fachada).
func doctor_spot() -> Vector2:
	return global_position + Vector2(0, 26)


func add_doctor(worker: Node) -> void:
	if not _doctors.has(worker):
		_doctors.append(worker)
	_update_visual()


func remove_doctor(worker: Node) -> void:
	_doctors.erase(worker)
	_update_visual()


func doctors() -> Array[Node]:
	_doctors = _doctors.filter(func(w): return is_instance_valid(w))
	return _doctors


## Velocidade da cura no leito: 1 sem médico (passiva, como sempre), mais com médico.
func heal_rate() -> float:
	return 1.0 + doctor_heal_bonus * mini(doctors().size(), max_doctors_effective)


## Quão rápido corre o relógio de "sem cuidado" de quem espera leito aqui.
func waiting_clock_mult() -> float:
	return doctor_waiting_clock_mult if not doctors().is_empty() else 1.0


## Machucados que ainda não estão num leito (a caminho ou esperando).
## Bloco 47: com mais de uma enfermaria, "daqui" = a caminho de um leito DAQUI, ou sem leito
## em nenhuma e esta é a mais perto dele (é na porta dela que ele espera).
func waiting() -> Array:
	var wards := get_tree().get_nodes_in_group("enfermarias")
	var inside: Array = []
	for w in wards:
		inside.append_array(w.patients())
	var out: Array = []
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if not w.injured or inside.has(w):
			continue
		if slot_of(w) >= 0:
			out.append(w)  # a caminho de um leito daqui
			continue
		var has_bed := false
		for o in wards:
			if o.slot_of(w) >= 0:
				has_bed = true
				break
		if not has_bed and _nearest_ward(w, wards) == self:
			out.append(w)
	return out


## Fila de quem espera leito: na frente da porta, lado a lado (não atrás do prédio).
func get_wait_position(worker: Node2D) -> Vector2:
	var i := maxi(without_bed().find(worker), 0)
	return global_position + Vector2(-36.0 + 24.0 * (i % 4), 40.0 + 14.0 * floorf(i / 4.0))


## Machucados SEM leito reservado (lotada): o relógio deles está correndo à toa.
func without_bed() -> Array:
	return waiting().filter(func(w): return slot_of(w) < 0)


# ------------------------------------------------------------ mortes
func record_death(worker: Node2D) -> void:
	var main := primary()
	if main != self:
		main.record_death(worker)  # Bloco 47: memorial e cemitério só na principal
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	var pos := _grave_spot()
	var entry := {
		"name": worker.display_name if worker.get("display_name") else String(worker.name),
		"cause": worker.injury_cause,
		"severity": worker.injury_severity,
		"day": dn.day if dn else 1,
		"position": SaveUtil.vec2_to_array(pos),
	}
	memorial.append(entry)
	_spawn_grave(pos, entry.name)
	patient_died.emit(entry.name, entry.cause)


## Cemitério: o cantinho livre mais perto do lado direito da enfermaria — fora do
## prédio, da placa e da fila, longe das outras estruturas e das outras cruzes, e
## em chão andável (a navegação já exclui pedras, tochas e paredes).
func _grave_spot() -> Vector2:
	var anchor := global_position + Vector2(64, 4)
	var cands: Array[Vector2] = []
	for gx in range(-5, 6):
		for gy in range(-6, 7):
			cands.append(anchor + Vector2(gx * 28, gy * 16))
	cands.sort_custom(func(a: Vector2, b: Vector2): return a.distance_squared_to(anchor) < b.distance_squared_to(anchor))
	var map := get_world_2d().navigation_map
	for p in cands:
		if _grave_spot_ok(p, map):
			return p
	return anchor


func _grave_spot_ok(p: Vector2, map: RID) -> bool:
	if Rect2(global_position + Vector2(-44, -100), Vector2(88, 160)).has_point(p):
		return false  # prédio, placa e fila da porta
	for g in get_tree().get_nodes_in_group("graves"):
		if g.global_position.distance_to(p) < 26.0:  # espaço pro nome
			return false
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		for group in env.STATION_GROUPS + env.NAV_EXTRA_GROUPS:
			for n in get_tree().get_nodes_in_group(group):
				if n != self and n.global_position.distance_to(p) < 44.0:
					return false
	return NavigationServer2D.map_get_closest_point(map, p).distance_to(p) < 1.0


func _spawn_grave(pos: Vector2, who: String) -> void:
	var g := Sprite2D.new()
	g.texture = GRAVE
	g.scale = Vector2(2, 2)
	g.offset = Vector2(0, -GRAVE.get_height() * 0.5)
	g.position = pos
	g.add_to_group("graves")
	var tag := Label.new()
	tag.text = who
	# filho do sprite (escala 2): escala 0.5 volta pro tamanho de tela normal
	tag.size = Vector2(60, 14)
	tag.scale = Vector2(0.5, 0.5)
	tag.position = Vector2(-15, -GRAVE.get_height() - 8)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75, 0.8))
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tag.add_theme_constant_override("outline_size", 4)
	g.add_child(tag)
	get_parent().add_child(g)


func _update_visual() -> void:
	var n := patients().size()
	_visual.frame = 1 if n > 0 else 0
	_window_light.enabled = n > 0
	var waiting_n := without_bed().size() if is_inside_tree() else 0
	_label.text = "Enfermaria%s  %d/%d" % [" (extra)" if extra else "", n, slot_count]
	var docs := doctors().size() if is_inside_tree() else 0
	_label.text += "\n%s" % ("%d médico%s de plantão" % [docs, "s" if docs > 1 else ""] if docs > 0 else "sem médico (cura lenta)")
	_window_light.enabled = n > 0 or docs > 0
	if waiting_n > 0:
		_label.text += "\n%d esperando leito!" % waiting_n
	_label.modulate = Color(1.0, 0.55, 0.5) if waiting_n > 0 else Color(0.95, 0.9, 0.85)


func _process(_delta: float) -> void:
	_update_visual()


## Bloco 47: "brota" quando a obra da enfermaria extra termina.
func pop_in() -> void:
	_visual.scale = Vector2(2.0, 0.2)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"memorial": memorial.duplicate(true)}


func load_save_data(d: Dictionary) -> void:
	for g in get_tree().get_nodes_in_group("graves"):
		g.queue_free()
	memorial = []
	for e in SaveUtil.array(d, "memorial"):
		if typeof(e) != TYPE_DICTIONARY:
			continue
		memorial.append(e)
		_spawn_grave(SaveUtil.vec2(e, "position", global_position + Vector2(40, 30)), SaveUtil.text(e, "name", "?"))
	refresh_beds()
