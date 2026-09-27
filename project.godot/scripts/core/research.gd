extends Node
## Pesquisa (nó Research, grupo "research"): a árvore de tecnologias do Laboratório.
##
## - O Laboratório é posicionado pelo jogador (janela do Laboratório, tecla Q).
## - Pesquisa gasta recursos ao começar e depois precisa de PONTOS, que só os
##   PESQUISADORES (função, tecla Z) geram trabalhando no laboratório de dia.
## - Três ramos. No 2º nível de cada ramo há uma ESCOLHA: pesquisar um tranca o outro
##   pra sempre ("caminhos diferentes" da árvore).
##     Mina:  Carrinhos -> Explosivos OU Escoramento
##     Vila:  Medicina de campo -> Rádio OU Hidroponia
##     Sol:   Estudo da explosão -> Satélite OU Holofotes;  Estudo -> Projeto do escudo
## Os efeitos são consultados pelos outros sistemas (cargo_mult, accident_mult...).

signal researched(id: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const LAB_SCENE := preload("res://scenes/props/laboratorio.tscn")
const LAB_TEXTURE := preload("res://assets/game/laboratorio.png")
const ORDER := ["carrinhos", "explosivos", "escoramento", "medicina", "radio", "hidroponia",
	"estudo_solar", "satelite", "holofotes", "escudo"]
## points = pontos de pesquisa; cost = créditos, minério, madeira; ore = tipo do minério.
const TECHS := {
	"carrinhos": {"name": "Carrinhos de mina", "branch": "Mina", "req": "", "excl": "", "points": 80,
		"cost": Vector3i(150, 100, 0), "ore": "ferro",
		"desc": "Cada ipezinho carrega 25% mais minério por viagem."},
	"explosivos": {"name": "Explosivos controlados", "branch": "Mina", "req": "carrinhos", "excl": "escoramento", "points": 140,
		"cost": Vector3i(300, 60, 0), "ore": "carvao",
		"desc": "Mineração 30% mais rápida, mas acidentes na mina 25% mais comuns."},
	"escoramento": {"name": "Escoramento", "branch": "Mina", "req": "carrinhos", "excl": "explosivos", "points": 140,
		"cost": Vector3i(250, 0, 100), "ore": "",
		"desc": "Vigas nas galerias: acidentes na mina 40% menos comuns."},
	"medicina": {"name": "Medicina de campo", "branch": "Vila", "req": "", "excl": "", "points": 80,
		"cost": Vector3i(200, 40, 0), "ore": "cobre",
		"desc": "Cura no leito 30% mais rápida; machucado sem leito aguenta 50% mais tempo."},
	"radio": {"name": "Rádio da vila", "branch": "Vila", "req": "medicina", "excl": "hidroponia", "points": 120,
		"cost": Vector3i(300, 40, 0), "ore": "cobre",
		"desc": "Música o dia todo: +6 de ânimo pra todo mundo."},
	"hidroponia": {"name": "Hidroponia", "branch": "Vila", "req": "medicina", "excl": "radio", "points": 120,
		"cost": Vector3i(250, 0, 60), "ore": "",
		"desc": "A horta rende o dobro e o comedouro guarda +60 de comida."},
	"estudo_solar": {"name": "Estudo da explosão solar", "branch": "Sol", "req": "", "excl": "", "points": 150,
		"cost": Vector3i(300, 30, 0), "ore": "prata",
		"desc": "Entender o que aconteceu com o sol. Abre os projetos do ramo (e o aviso das ondas solares)."},
	"satelite": {"name": "Satélite de comunicação", "branch": "Sol", "req": "estudo_solar", "excl": "holofotes", "points": 200,
		"cost": Vector3i(600, 60, 0), "ore": "prata",
		"desc": "Antena parabólica: a cada 2 dias chega um colono de outra colônia (se tiver vaga)."},
	"holofotes": {"name": "Holofotes", "branch": "Sol", "req": "estudo_solar", "excl": "satelite", "points": 200,
		"cost": Vector3i(500, 80, 0), "ore": "cobre",
		"desc": "Luz forte nos portões: Lumívoros 30% mais lentos e guardas batem 30% mais forte."},
	"escudo": {"name": "Projeto do escudo solar", "branch": "Sol", "req": "estudo_solar", "excl": "", "points": 300,
		"cost": Vector3i(800, 40, 0), "ore": "solarita",
		"desc": "O projeto da única coisa que protege a vila do sol pra sempre. Libera a construção do escudo."},
}

@export_group("Laboratório")
@export var lab_credits: int = 300
@export var lab_wood: int = 60
@export var lab_iron: int = 80
@export var lab_min_stage: int = 2
## Pontos por segundo que cada pesquisador gera no laboratório.
@export var points_per_researcher: float = 1.0

@export_group("Efeitos")
@export var cargo_bonus: float = 0.25
@export var explosive_speed: float = 1.3
@export var explosive_accidents: float = 1.25
@export var shoring_accidents: float = 0.6
@export var medicine_heal: float = 0.7
@export var medicine_untreated: float = 1.5
@export var radio_joy: float = 6.0
@export var hydro_regen: float = 2.0
@export var hydro_food_capacity: float = 60.0
@export var floodlight_slow: float = 0.7
@export var floodlight_damage: float = 1.3
@export var satellite_every_days: int = 2

var done: Array = []
var current: String = ""
var progress: float = 0.0


func _ready() -> void:
	add_to_group("research")
	_connect_cycle.call_deferred()


func _connect_cycle() -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn:
		dn.day_started.connect(_on_day_started)


func has(id: String) -> bool:
	return done.has(id)


func lab() -> Node:
	return get_tree().get_first_node_in_group("laboratorios")


func researchers() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.is_researcher())


# ------------------------------------------------------------ laboratório
func lab_block_reason() -> String:
	if lab() != null:
		return "construído"
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < lab_min_stage:
		return "requer vila nível %d" % lab_min_stage
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(lab_credits, lab_iron, "ferro", lab_wood) if eco else "sem recursos"


func build_lab() -> bool:
	if lab_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_lab, LAB_TEXTURE, 2, "o laboratório")
	return true


func _confirm_lab(pos: Vector2) -> bool:
	if lab_block_reason() != "":
		Audio.error()
		return false
	if not get_tree().get_first_node_in_group("economy").spend(lab_credits, lab_iron, "ferro", lab_wood):
		return false
	var l := spawn_lab(pos)
	l.pop_in()
	Audio.recruit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Laboratório pronto! Escolha uma pesquisa (Q) e mande pesquisadores (Z).", Color(0.55, 1.0, 0.5))
	return true


func spawn_lab(pos: Vector2) -> Node2D:
	var l: Node2D = LAB_SCENE.instantiate()
	l.name = "Laboratorio"
	l.position = pos
	get_tree().get_first_node_in_group("village_hub").get_parent().add_child(l)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return l


# ------------------------------------------------------------ pesquisar
## "" = dá pra começar; senão o motivo ("pesquisado", "pesquisando", "escolheu X"...).
func block_reason(id: String) -> String:
	var t: Dictionary = TECHS[id]
	if has(id):
		return "pesquisado"
	if current == id:
		return "pesquisando"
	if t.excl != "" and has(t.excl):
		return "caminho fechado (escolheu %s)" % TECHS[t.excl].name
	if t.req != "" and not has(t.req):
		return "precisa: %s" % TECHS[t.req].name
	if lab() == null:
		return "sem laboratório"
	if current != "":
		return "laboratório ocupado"
	var c: Vector3i = t.cost
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(c.x, c.y, t.ore, c.z) if eco else "sem recursos"


func start(id: String) -> bool:
	if block_reason(id) != "":
		Audio.error()
		return false
	var t: Dictionary = TECHS[id]
	var c: Vector3i = t.cost
	if not get_tree().get_first_node_in_group("economy").spend(c.x, c.y, t.ore, c.z):
		return false
	current = id
	progress = 0.0
	for w in researchers():
		w.wake_decision()
	return true


func current_progress() -> float:
	return clampf(progress / float(TECHS[current].points), 0.0, 1.0) if current != "" else 0.0


## O laboratório chama com os pesquisadores trabalhando lá.
func add_points(amount: float) -> void:
	if current == "":
		return
	progress += amount
	if progress >= float(TECHS[current].points):
		_finish(current)


func _finish(id: String) -> void:
	done.append(id)
	current = ""
	progress = 0.0
	apply_all()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("PESQUISA CONCLUÍDA: %s" % TECHS[id].name.to_upper(), TECHS[id].desc)
	Audio.fanfare()
	for w in researchers():
		w.wake_decision()  # sem pesquisa: voltam a trabalhar
	researched.emit(id)


# ------------------------------------------------------------ efeitos
func cargo_mult() -> float:
	return 1.0 + cargo_bonus if has("carrinhos") else 1.0


func mining_speed_mult() -> float:
	return explosive_speed if has("explosivos") else 1.0


func accident_mult() -> float:
	if has("explosivos"):
		return explosive_accidents
	if has("escoramento"):
		return shoring_accidents
	return 1.0


func heal_mult() -> float:
	return medicine_heal if has("medicina") else 1.0


func untreated_mult() -> float:
	return medicine_untreated if has("medicina") else 1.0


func guard_damage_mult() -> float:
	return floodlight_damage if has("holofotes") else 1.0


func lumivoro_speed_mult() -> float:
	return floodlight_slow if has("holofotes") else 1.0


## Aplica os efeitos "de estado" (capacidades) — idempotente; chamado ao pesquisar e ao carregar.
func apply_all() -> void:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		apply_worker(w)
	for h in get_tree().get_nodes_in_group("coleta_comida"):
		if not h.has_meta("base_regen"):
			h.set_meta("base_regen", h.regen_rate)
		h.regen_rate = h.get_meta("base_regen") * (hydro_regen if has("hidroponia") else 1.0)
	for c in get_tree().get_nodes_in_group("comedouros"):
		if not c.has_meta("base_capacity"):
			c.set_meta("base_capacity", c.food_capacity)
		c.food_capacity = c.get_meta("base_capacity") + (hydro_food_capacity if has("hidroponia") else 0.0)
		c._update_visual()
	var l := lab()
	if l:
		l.show_satellite(has("satelite"))


func apply_worker(w: Node) -> void:
	if not w.has_meta("base_cargo"):
		w.set_meta("base_cargo", w.cargo_capacity)
	w.cargo_capacity = w.get_meta("base_cargo") * cargo_mult()


func _on_day_started(day: int) -> void:
	if not has("satelite") or day % maxi(satellite_every_days, 1) != 0:
		return
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return
	var w: Node2D = eco.recruit_free()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if w:
			hud.show_toast("O satélite trouxe um colono: %s chegou de outra colônia!" % w.get("display_name"), Color(0.55, 1.0, 0.5))
		else:
			hud.show_toast("O satélite achou um colono, mas não tem vaga na vila (Moradias).", Color(1.0, 0.7, 0.4))


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var d := {"done": done.duplicate(), "current": current, "progress": progress}
	var l := lab()
	if l:
		d["lab"] = SaveUtil.vec2_to_array(l.global_position)
	return d


func load_save_data(d: Dictionary) -> void:
	done = []
	for id in SaveUtil.array(d, "done"):
		if id is String and TECHS.has(id) and not done.has(id):
			done.append(id)
	current = SaveUtil.text(d, "current", "")
	if not TECHS.has(current) or has(current):
		current = ""
	progress = maxf(SaveUtil.num(d, "progress", 0.0), 0.0) if current != "" else 0.0
	if d.has("lab") and lab() == null:
		var pos := SaveUtil.vec2(d, "lab", Vector2.INF)
		if pos != Vector2.INF:
			spawn_lab(pos)
	apply_all.call_deferred()
