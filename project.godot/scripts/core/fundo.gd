extends Node
## Bloco 70: o CONTEÚDO DOS NÍVEIS DE BAIXO — S2 (ácido e gás) e S3 (lava). Nó "Fundo", grupo "fundo".
##
## - Poças de perigo (props/poca_perigo.gd) e jazidas de cristal vêm dos DADOS do nível
##   (data/niveis/*.tres: perigos, jazidas; o ambiente monta). Aqui ficam os números (@export).
##   Poça de ácido (S2): sem máscara de gás anda devagar e, ficando, queima (machucado leve).
##   Poço de lava (S3): sem traje térmico anda bem devagar e queima rápido (pode ser grave).
##   Com o traje (pega no vestiário ao pisar, como nas zonas do Bloco 42) nada acontece.
## - VENTILADOR (S2): pesquisa "Ventilação" + obra do engenheiro no nível 2. No alcance, a máscara
##   gasta menos e o ácido queima mais devagar; cada um tira um pouco da névoa verde do S2.
## - Escavadeira: com o S2 aberto a broca acha cristal verde; com o S3, cristal rubro e rende mais.
## - Contadores pra telemetria (queimaduras de ácido e de lava).

const SaveUtil := preload("res://scripts/core/save_util.gd")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const VENTILADOR_SCRIPT := preload("res://scripts/props/ventilador.gd")
const VENTILADOR_TEXTURE := preload("res://assets/game/ventilador.png")
const VENTILADOR_FOOTPRINT := Rect2(-16, -12, 32, 22)

@export_group("Poça de ácido (S2)")
## Velocidade de quem está dentro sem máscara (0.6 = 60%).
@export var acido_lentidao: float = 0.6
## Segundos dentro sem máscara até queimar (machucado leve).
@export var acido_exposicao: float = 5.0
## Chance da queimadura de ácido ser grave.
@export_range(0.0, 1.0) var acido_grave: float = 0.0

@export_group("Poço de lava (S3)")
@export var lava_lentidao: float = 0.5
@export var lava_exposicao: float = 2.5
@export_range(0.0, 1.0) var lava_grave: float = 0.3

@export_group("Ventilador (S2)")
@export var ventilador_credits: int = 400
@export var ventilador_ore: int = 60
@export var ventilador_ore_type: String = "prata"
@export var ventilador_wood: int = 40
## Segundos de engenheiro pra montar.
@export var ventilador_build_time: float = 45.0
@export var ventilador_max: int = 4
## Alcance (px da lógica) e quanto ele corta: a máscara gasta e o ácido queima x (1 - redução).
@export var ventilador_alcance: float = 260.0
@export_range(0.0, 1.0) var ventilador_reducao: float = 0.5
## Cada ventilador tira essa fração da névoa verde do S2 (no máximo ventilador_nevoa_max).
@export var ventilador_nevoa: float = 0.2
@export var ventilador_nevoa_max: float = 0.6

@export_group("Escavadeira no fundo")
## Chance de cada minério da broca virar cristal (S2 aberto: verde; S3 aberto: rubro).
@export_range(0.0, 1.0) var broca_cristal_verde: float = 0.12
@export_range(0.0, 1.0) var broca_cristal_rubro: float = 0.08
## Com o S3 aberto a broca rende mais (o fundo do abismo é mais quente e mais mole).
@export var broca_s3_mult: float = 1.25

## Queimaduras desde o começo da partida (telemetria).
var queimaduras := {"acido": 0, "lava": 0}


func _ready() -> void:
	add_to_group("fundo")


# ------------------------------------------------------------ poças
func lentidao(kind: String) -> float:
	return lava_lentidao if kind == "lava" else acido_lentidao


func exposicao(kind: String) -> float:
	return lava_exposicao if kind == "lava" else acido_exposicao


func grave_chance(kind: String) -> float:
	return lava_grave if kind == "lava" else acido_grave


## A poça nesse ponto (null = nenhuma).
func poca_at(pos: Vector2) -> Node:
	for p in get_tree().get_nodes_in_group("pocas_perigo"):
		if p.contains(pos):
			return p
	return null


func registra_queimadura(kind: String) -> void:
	queimaduras[kind] = int(queimaduras.get(kind, 0)) + 1


# ------------------------------------------------------------ ventiladores
func ventiladores() -> Array:
	return get_tree().get_nodes_in_group("ventiladores")


## 1.0 = sem ventilação; menos = o ventilador está ajudando nesse ponto (só no S2).
func ventilacao_mult(pos: Vector2) -> float:
	for v in ventiladores():
		if (v as Node2D).global_position.distance_to(pos) <= ventilador_alcance:
			return 1.0 - ventilador_reducao
	return 1.0


## Quanto sobra da névoa verde do S2 com os ventiladores (1 = toda).
func nevoa_mult() -> float:
	return 1.0 - minf(ventiladores().size() * ventilador_nevoa, ventilador_nevoa_max)


func ventilador_cost_text() -> String:
	return "%d cr + %d %s + %d madeira" % [ventilador_credits, ventilador_ore, ventilador_ore_type, ventilador_wood]


func ventilador_block_reason() -> String:
	var res := get_tree().get_first_node_in_group("research")
	if res and not res.has("ventilacao"):
		return "precisa pesquisar: %s" % res.TECHS.ventilacao.name
	var shaft := get_tree().get_first_node_in_group("elevador")
	if shaft and not shaft.unlocked:
		return "o nível 2 ainda está fechado"
	var em_obra := get_tree().get_nodes_in_group("canteiros").filter(func(c): return c.kind == "ventilador").size()
	if ventiladores().size() + em_obra >= ventilador_max:
		return "no máximo %d no nível 2" % ventilador_max
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(ventilador_credits, ventilador_ore, ventilador_ore_type, ventilador_wood) if eco else "sem recursos"


func build_ventilador() -> bool:
	if ventilador_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	var env := get_tree().get_first_node_in_group("environment")
	if placer == null or env == null:
		return false
	placer.begin(_confirm_ventilador, VENTILADOR_TEXTURE, 1, "o ventilador", {"footprint": VENTILADOR_FOOTPRINT,
		"area": (env.deep_rect as Rect2).grow(-30.0), "area_name": "do nível 2", "start": (env.deep_rect as Rect2).get_center()})
	return true


func _confirm_ventilador(pos: Vector2) -> bool:
	if ventilador_block_reason() != "":
		Audio.error()
		return false
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(ventilador_credits, ventilador_ore, ventilador_ore_type, ventilador_wood):
		return false
	Canteiro.order(get_tree(), "ventilador", pos, ventilador_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Ventilador encomendado no nível 2 — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


## O canteiro terminou (canteiro.gd chama o dono do tipo).
func finish_build(kind: String, pos: Vector2) -> void:
	if kind != "ventilador":
		return
	var v := spawn_ventilador(pos)
	v.pop_in()
	Audio.recruit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Ventilador ligado: menos gás e ácido em volta dele.", Color(0.55, 1.0, 0.5))


func spawn_ventilador(pos: Vector2) -> Node2D:
	var v: Node2D = VENTILADOR_SCRIPT.new()
	v.name = "Ventilador%d" % (ventiladores().size() + 1)
	v.position = pos
	get_tree().get_first_node_in_group("village_hub").get_parent().add_child(v)
	get_tree().call_group("efeitos", "efeitos_mudaram")  # a névoa do S2 afina
	return v


# ------------------------------------------------------------ escavadeira
## Minério que a broca acha a mais no fundo ("" = o da mistura do reator).
func cristal_da_broca() -> String:
	var tree := get_tree()
	var ab := tree.get_first_node_in_group("elevador_abismo")
	if ab and ab.unlocked and randf() < broca_cristal_rubro:
		return "cristal_rubro"
	var sh := tree.get_first_node_in_group("elevador")
	if sh and sh.unlocked and randf() < broca_cristal_verde:
		return "cristal_verde"
	return ""


func broca_mult() -> float:
	var ab := get_tree().get_first_node_in_group("elevador_abismo")
	return broca_s3_mult if ab and ab.unlocked else 1.0


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"ventiladores": ventiladores().map(func(v): return SaveUtil.vec2_to_array(v.global_position)),
		"queimaduras": queimaduras.duplicate()}


func load_save_data(d: Dictionary) -> void:
	for v in ventiladores():
		v.remove_from_group("ventiladores")
		v.queue_free()
	for p in SaveUtil.array(d, "ventiladores"):
		if p is Array and p.size() >= 2:
			spawn_ventilador(Vector2(float(p[0]), float(p[1])))
	var q := SaveUtil.dict(d, "queimaduras")
	queimaduras = {"acido": int(SaveUtil.num(q, "acido", 0.0)), "lava": int(SaveUtil.num(q, "lava", 0.0))}
	get_tree().call_group("efeitos", "efeitos_mudaram")
