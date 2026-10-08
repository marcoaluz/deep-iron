extends Node
## Pesquisa (nó Research, grupo "research"): a árvore de tecnologias do Laboratório.
##
## - O Laboratório é posicionado pelo jogador (janela do Laboratório, tecla Q).
##   Bloco 47: pode ter vários (cada um a mais custa mais — Economy.extra_building_cost_growth).
##   A pesquisa é UMA só: todos os laboratórios somam pontos na mesma pesquisa; ter mais
##   laboratório = mais vagas pra pesquisador trabalhar ao mesmo tempo.
## - Pesquisa gasta recursos ao começar e depois precisa de PONTOS, que só os
##   PESQUISADORES (função, tecla Z) geram trabalhando no laboratório de dia.
## - Três ramos. No 2º nível de cada ramo há uma ESCOLHA: pesquisar um tranca o outro
##   pra sempre ("caminhos diferentes" da árvore).
##     Mina:  Carrinhos -> Explosivos OU Escoramento
##     Vila:  Medicina de campo -> Rádio OU Hidroponia
##     Sol:   Estudo da explosão -> Satélite OU Holofotes;  Estudo -> Projeto do escudo
## Os efeitos são consultados pelos outros sistemas (cargo_mult, accident_mult...).
## Bloco 102: o CATÁLOGO (catalogo.gd) pode travar uma pesquisa até uma entrada ser estudada (nos dados da entrada:
## "libera": ["pesquisa:<id>"]), e cada estudo de campo dá uns pontos: vão pra pesquisa em andamento ou ficam
## GUARDADOS e entram na próxima que começar (pontos_guardados).

signal researched(id: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const LAB_SCENE := preload("res://scenes/props/laboratorio.tscn")
const LAB_TEXTURE := preload("res://assets/game/laboratorio.png")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const ORDER := ["carrinhos", "explosivos", "escoramento", "trajes", "ventilacao", "bombas", "medicina", "radio", "hidroponia", "ritos",
	"estudo_solar", "satelite", "holofotes", "escudo"]
## points = pontos de pesquisa; cost = créditos, minério, madeira; ore = tipo do minério.
const TECHS := {
	"carrinhos": {"name": "Carrinhos de mina", "branch": "Mina", "req": "", "excl": "", "points": 80,
		"cost": Vector3i(150, 100, 0), "ore": "ferro",
		"desc": "Cada ipezinho carrega 25% mais minério por viagem."},
	"explosivos": {"name": "Explosivos controlados", "branch": "Mina", "req": "carrinhos", "excl": "escoramento", "points": 140,
		"cost": Vector3i(300, 60, 0), "ore": "carvao",
		"desc": "Mineração 30% mais rápida, mas acidentes na mina 25% mais comuns. Libera a DINAMITE: abre galeria lacrada antes da hora (clique no entulho)."},
	"escoramento": {"name": "Escoramento", "branch": "Mina", "req": "carrinhos", "excl": "explosivos", "points": 140,
		"cost": Vector3i(250, 0, 100), "ore": "",
		"desc": "Vigas nas galerias: acidentes na mina 40% menos comuns."},
	"trajes": {"name": "Trajes de proteção", "branch": "Mina", "req": "carrinhos", "excl": "", "points": 120,
		"cost": Vector3i(250, 40, 0), "ore": "cobre",
		"desc": "A Oficina passa a fazer máscara de gás, traje térmico e traje antirradiação — pras zonas de perigo do fundo (Bloco 42). Sem ela, a plataforma do abismo (S3, lava) não desce."},
	"ventilacao": {"name": "Ventilação", "branch": "Mina", "req": "trajes", "excl": "", "points": 120,
		"cost": Vector3i(300, 40, 0), "ore": "prata",
		"desc": "Ventiladores no nível 2 (menu de construção): em volta deles a máscara de gás gasta metade e o ácido das poças queima mais devagar; a névoa verde afina."},
	"bombas": {"name": "Bombas d'água", "branch": "Mina", "req": "ventilacao", "excl": "", "points": 160,
		"cost": Vector3i(600, 60, 0), "ore": "solarita",
		"desc": "Bombas pra segurar a cachoeira do fundo: libera o conserto da plataforma que desce do abismo pro S4 (cachoeira e lava)."},
	"medicina": {"name": "Medicina de campo", "branch": "Vila", "req": "", "excl": "", "points": 80,
		"cost": Vector3i(200, 40, 0), "ore": "cobre",
		"desc": "Cura no leito 30% mais rápida; machucado sem leito aguenta 50% mais tempo."},
	"radio": {"name": "Rádio da vila", "branch": "Vila", "req": "medicina", "excl": "hidroponia", "points": 120,
		"cost": Vector3i(300, 40, 0), "ore": "cobre",
		"desc": "Música o dia todo: +6 de ânimo pra todo mundo. Escuta as criaturas: aviso de invasão bem mais cedo; com o satélite, chega colono todo dia."},
	"hidroponia": {"name": "Hidroponia", "branch": "Vila", "req": "medicina", "excl": "radio", "points": 120,
		"cost": Vector3i(250, 0, 60), "ore": "",
		"desc": "A horta rende o dobro e a cozinha guarda +60 de comida."},
	"ritos": {"name": "Ritos fúnebres", "branch": "Vila", "req": "medicina", "excl": "", "points": 90,
		"cost": Vector3i(150, 0, 40), "ore": "",
		"desc": "O padre faz o funeral de quem se foi (no cemitério, depois do enterro; sem cemitério, na igreja): a vila se despede, o luto pesa menos e o ânimo sobe um pouco."},
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
## Bloco 31b: segundos de engenheiro pra erguer o laboratório.
@export var lab_build_time: float = 60.0
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

@export_group("Dinamite e rádio (Bloco 60)")
## Custo de uma dinamite (créditos e carvão) e quantas cabem no paiol.
@export var dynamite_credits: int = 40
@export var dynamite_coal: int = 15
@export var dynamite_max: int = 5
## Chance de acidente ao explodir: minerador (sabe mexer) e qualquer outro.
@export var dynamite_risk_miner: float = 0.04
@export var dynamite_risk_untrained: float = 0.2
## Segundos do pavio depois de chegar no entulho; desiste (devolve a dinamite) depois deste tempo andando.
@export var dynamite_fuse: float = 2.5
@export var dynamite_walk_timeout: float = 60.0
## Rádio: o aviso de invasão vem estes segundos antes do normal; com satélite, um colono a cada N dias.
@export var radio_warning_bonus: float = 60.0
@export var radio_satellite_every_days: int = 1

var dynamite := 0
var _blast := {}  # trabalho em andamento: {galeria, quem, t, fase ("andando"/"pavio")}

var done: Array = []
var current: String = ""
var progress: float = 0.0
## Bloco 102: pontos dos estudos do catálogo sem pesquisa em andamento (entram na próxima).
var pontos_guardados: float = 0.0


func _ready() -> void:
	add_to_group("research")
	set_process(true)
	_connect_cycle.call_deferred()


func _connect_cycle() -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn:
		dn.day_started.connect(_on_day_started)


func has(id: String) -> bool:
	return done.has(id)


func lab() -> Node:
	return get_tree().get_first_node_in_group("laboratorios")


## Bloco 47: todos os laboratórios da vila.
func labs() -> Array:
	return get_tree().get_nodes_in_group("laboratorios")


## Custo do PRÓXIMO laboratório (x cr, y ferro, z madeira): cresce a cada um que já existe.
func lab_cost() -> Vector3i:
	var base := Vector3i(lab_credits, lab_iron, lab_wood)
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.scaled_cost(base, labs().size()) if eco else base


func lab_cost_text() -> String:
	var c := lab_cost()
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.custo_metal_texto(c.x, c.y, "ferro", c.z) if eco else "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]  # Bloco 87


func researchers() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.is_researcher())


# ------------------------------------------------------------ laboratório
func lab_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "laboratorio")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < lab_min_stage:
		return "requer vila nível %d" % lab_min_stage
	var eco := get_tree().get_first_node_in_group("economy")
	var cost := lab_cost()
	return eco.metal_falta(cost.x, cost.y, "ferro", cost.z) if eco else "sem recursos"  # Bloco 87: barra


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
	var cost := lab_cost()
	if not get_tree().get_first_node_in_group("economy").paga_metal(cost.x, cost.y, "ferro", cost.z):
		return false
	Canteiro.order(get_tree(), "laboratorio", pos, lab_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Laboratório encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


## Bloco 31b: o canteiro terminou (chamado por canteiro.gd).
func finish_build(kind: String, pos: Vector2) -> void:
	if kind != "laboratorio":
		return
	var l := spawn_lab(pos)
	l.pop_in()
	Audio.recruit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Laboratório pronto! Escolha uma pesquisa (Q) e mande pesquisadores (Z).", Color(0.55, 1.0, 0.5))


func spawn_lab(pos: Vector2) -> Node2D:
	var l: Node2D = LAB_SCENE.instantiate()
	var n := labs().size()
	l.name = "Laboratorio" if n == 0 else "Laboratorio%d" % (n + 1)
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
	var falta_estudo := estudo_que_falta(id)
	if falta_estudo != "":
		return "precisa estudar: %s" % falta_estudo  # Bloco 102 (Catálogo, tecla R)
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
	if pontos_guardados > 0.0:  # Bloco 102: os pontos dos estudos de campo entram aqui
		var usa := minf(pontos_guardados, float(t.points))
		pontos_guardados -= usa
		add_points(usa)
	for w in researchers():
		w.wake_decision()
	return true


## Bloco 102: o nome da entrada do catálogo que esta pesquisa ainda espera ser estudada ("" = nenhuma).
func estudo_que_falta(id: String) -> String:
	var cat := get_tree().get_first_node_in_group("catalogo")
	return cat.falta_para_pesquisa(id) if cat else ""


## Bloco 102: pontos de fora do laboratório (o estudo do catálogo): na pesquisa em andamento, ou guardados.
func ganha_pontos(n: float) -> void:
	if n <= 0.0:
		return
	if current != "":
		add_points(n)
	else:
		pontos_guardados += n


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


## Bloco 60: com o rádio, o satélite acha colono mais vezes.
func satellite_days() -> int:
	return maxi(radio_satellite_every_days if has("radio") else satellite_every_days, 1)


func _on_day_started(day: int) -> void:
	if not has("satelite") or day % satellite_days() != 0:
		return
	# Bloco 101: o satélite acha gente de outra colônia: um grupo de migrantes vem pro portão (aceitar precisa de cama)
	var mig := get_tree().get_first_node_in_group("migrantes")
	if mig and mig.esperando.is_empty():
		mig.chama_grupo(-1, "satelite")


# ------------------------------------------------------------ dinamite (Bloco 60)
func dynamite_cost_text() -> String:
	return "%d cr + %d carvão" % [dynamite_credits, dynamite_coal]


func craft_dynamite_reason() -> String:
	if not has("explosivos"):
		return "precisa pesquisar Explosivos controlados"
	if dynamite >= dynamite_max:
		return "paiol cheio (%d)" % dynamite_max
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(dynamite_credits, dynamite_coal, "carvao", 0, "carvão") if eco else "sem recursos"


func craft_dynamite() -> bool:
	if craft_dynamite_reason() != "":
		return false
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(dynamite_credits, dynamite_coal, "carvao"):
		return false
	dynamite += 1
	return true


func blast_reason(gallery: Node) -> String:
	if gallery == null or not gallery.is_sealed():
		return "não está lacrada"
	if not has("explosivos"):
		return "precisa pesquisar Explosivos controlados"
	if dynamite <= 0:
		return "sem dinamite (faça uma)"
	if not _blast.is_empty():
		return "já tem uma explosão em andamento"
	if _blaster_for(gallery) == null:
		return "ninguém disponível pra levar"
	return ""


## Quem leva a carga: o minerador mais perto (sabe mexer); senão o ipezinho mais perto.
func _blaster_for(gallery: Node) -> Node:
	var best: Node = null
	var best_d := INF
	for pass_miner in [true, false]:
		for w in get_tree().get_nodes_in_group("ipezinhos"):
			if w.injured or w.get("downed") or (pass_miner and not w.is_miner()):
				continue
			var d: float = w.global_position.distance_to(gallery.global_position)
			if d < best_d:
				best_d = d
				best = w
		if best:
			return best
	return null


func start_blast(gallery: Node) -> bool:
	if blast_reason(gallery) != "":
		return false
	var w := _blaster_for(gallery)
	dynamite -= 1
	_blast = {"galeria": gallery, "quem": w, "t": 0.0, "fase": "andando"}
	w.move_to(gallery.global_position + Vector2(0, 46))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s leva a dinamite até a galeria %s." % [w.display_name, gallery.gallery_name], Color(1.0, 0.8, 0.45))
	return true


func blast_in_progress() -> bool:
	return not _blast.is_empty()


func _process(delta: float) -> void:
	if _blast.is_empty():
		return
	var g = _blast.galeria
	var w = _blast.quem
	if not is_instance_valid(g) or not g.is_sealed():
		_blast = {}
		return
	_blast.t += delta
	if _blast.fase == "andando":
		if not is_instance_valid(w) or w.injured or w.get("downed") or _blast.t > dynamite_walk_timeout:
			dynamite = mini(dynamite + 1, dynamite_max)  # não chegou: a dinamite volta pro paiol
			_blast = {}
			return
		if w.global_position.distance_to(g.global_position) < 70.0:
			_blast.fase = "pavio"
			_blast.t = 0.0
			w.move_to(g.global_position + Vector2(0, 150))  # acende e corre
	elif _blast.t >= dynamite_fuse:
		_explode(g, w if is_instance_valid(w) else null)
		_blast = {}


func _explode(g: Node, w: Node) -> void:
	g.blast_open()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("BUM! A galeria %s abriu (%s)." % [g.gallery_name, g.ore_type], Color(0.55, 1.0, 0.5))
	if w == null:
		return
	var risk := dynamite_risk_miner if w.is_miner() else dynamite_risk_untrained
	if randf() < risk:
		w.hurt("mina", "grave" if randf() < 0.3 else "")
		if hud:
			hud.show_toast("%s se machucou com a explosão!" % w.display_name, Color(1.0, 0.5, 0.4))


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var d := {"done": done.duplicate(), "current": current, "progress": progress, "dynamite": dynamite,
		"guardados": pontos_guardados}  # Bloco 102
	var ls := []
	for l in labs():
		ls.append(SaveUtil.vec2_to_array(l.global_position))
	d["labs"] = ls  # Bloco 47: lista (antes: "lab" com um só)
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
	dynamite = clampi(SaveUtil.integer(d, "dynamite", 0), 0, dynamite_max)  # Bloco 60 (save antigo: 0)
	pontos_guardados = maxf(SaveUtil.num(d, "guardados", 0.0), 0.0)  # Bloco 102 (save antigo: 0)
	_blast = {}
	if labs().is_empty():
		for pos in SaveUtil.positions(d, "labs", "lab"):  # Bloco 47 (save antigo: "lab", um só)
			spawn_lab(pos)
	apply_all.call_deferred()
