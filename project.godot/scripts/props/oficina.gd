extends "res://scripts/props/station.gd"
## Oficina de ferramentas (grupo "oficina").
##
## Fabrica ferramentas novas gastando créditos + minério de um tipo específico.
## Cada ferramenta libera um tipo de minério que antes não dava pra minerar:
##   Picareta temperada         -> cobre   (custa ferro; Bloco 94: era "de aço temperado" — o id ficou)
##   Picareta de aço (Bloco 94) -> +minério por golpe (custa AÇO da Fundição; estágio 3)
##   Lampião de segurança       -> carvão  (custa cobre: o carvão vem depois do cobre)
##   Arco e flecha (Bloco 27)   -> caça de animais pro caçador (não libera minério)
## Uma ferramenta por vez; o custo é pago ao começar e ela fica pronta depois de
## alguns segundos na forja. As jazidas consultam is_ore_unlocked() e são avisadas
## (on_unlock_changed) quando algo muda; os ipezinhos, via on_tool_crafted().
## Bloco 42: quando não tem ferramenta na forja, o engenheiro toca a fila de EQUIPAMENTO
## (casacos e trajes — equipment.gd): a obra da Oficina é "ferramenta, senão equipamento".

signal tool_started(id: String)
signal tool_crafted(id: String)

const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const ProductionQueue := preload("res://scripts/core/production_queue.gd")  # Bloco 87
const Items := preload("res://scripts/core/items.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const TOOL_IDS := ["picareta_aco", "lampiao", "broca", "traje", "arco", "picareta_de_aco", "antena"]
const TOOL_NAMES := {
	"picareta_aco": "Picareta temperada",  # Bloco 94: o nome mudou (o id ficou: saves e testes)
	"lampiao": "Lampião de segurança",
	"broca": "Broca manual",
	"traje": "Traje de chumbo",
	"arco": "Arco e flecha",
	"picareta_de_aco": "Picareta de aço",  # Bloco 94
	"antena": "Antena improvisada",  # Bloco 104: capta o sinal do robô sem o Rádio
}
const TOOL_DESCRIPTIONS := {
	"picareta_aco": "Ferro temperado, duro o bastante pra quebrar os veios de cobre.",
	"lampiao": "Avisa do gás dos veios de carvão. Sem ele, ninguém entra lá.",
	"broca": "Fura a rocha dura do nível 2, onde a prata se esconde.",
	"traje": "Protege do calor e da energia da solarita, lá no abismo (nível 3).",
	"arco": "Deixa o caçador caçar os coelhos das tocas da clareira: rende mais que fruta por viagem.",
	"picareta_de_aco": "Aço de verdade, da Fundição: cada golpe arranca mais minério (todos os mineradores).",
	"antena": "Fio de cobre enrolado num mastro e duas peças raras de antes: capta o sinal fraco que vem do fundo, mesmo sem o Rádio.",
}
## O que libera cada ferramenta que NÃO é de minério (texto do painel e do aviso de pronta).
const TOOL_UNLOCK_LABELS := {"arco": "caça de animais", "picareta_de_aco": "mais minério por golpe", "antena": "o sinal do robô antigo"}
## Tipo de minério que cada ferramenta libera (as que liberam outra coisa ficam de fora).
const TOOL_UNLOCKS := {
	"picareta_aco": "cobre",
	"lampiao": "carvao",
	"broca": "prata",
	"traje": "solarita",
}
## Bloco 70: minérios a mais que a mesma ferramenta libera (a broca fura o cristal verde do S2; o
## traje de chumbo aguenta o calor do cristal rubro do S3).
const TOOL_UNLOCKS_EXTRA := {"cristal_verde": "broca", "cristal_rubro": "traje"}

@export_group("Ferramentas (na ordem de TOOL_IDS)")
## x = créditos, y = quantidade de minério, z = segundos na forja.
@export var tool_costs: Array[Vector3i] = [
	Vector3i(310, 150, 30),  # picareta de aço
	Vector3i(560, 125, 45),  # lampião
	Vector3i(800, 150, 60),  # broca manual
	Vector3i(1400, 120, 75),  # traje de chumbo
	Vector3i(180, 40, 25),  # arco e flecha (Bloco 27)
	Vector3i(400, 0, 40),  # picareta de aço (Bloco 94: o metal é o aço, em tool_itens)
	Vector3i(150, 30, 25),  # antena improvisada (Bloco 104: cobre + 2 peças raras, em tool_itens)
]
## Tipo do minério gasto em cada ferramenta.
@export var tool_ore_types: Array[String] = ["ferro", "cobre", "carvao", "prata", "ferro", "ferro", "cobre"]
## Madeira gasta em cada ferramenta (cabo/estrutura) — referência: 1 madeira pra 5 minério.
@export var tool_wood_costs: Array[int] = [30, 25, 40, 30, 35, 20, 10]
## Estágio mínimo da vila (Centro da Vila) pra fabricar cada ferramenta.
@export var tool_min_stage: Array[int] = [1, 2, 4, 4, 1, 3, 2]
## Bloco 94: itens a mais de cada ferramenta (id -> {item: qtd}). A picareta de aço leva aço da Fundição.
@export var tool_itens: Dictionary = {"picareta_de_aco": {"aco": 12}, "antena": {"pecas_raras": 2}}
## Bloco 94: minério por golpe com a picareta de aço (1.25 = +25%), pra todos os mineradores.
@export var picareta_aco_mult: float = 1.25

@export_group("Encomendas do ferreiro (Bloco 87)")
## Pregos e ferragens: só por ORDEM (quantidade do jogador), o FERREIRO faz aqui; os insumos saem do armazém
## quando cada unidade começa e o produto vai pro armazém. (Ferramentas, armas e equipamentos são as filas
## de sempre — Oficina, Arsenal, Equipment —, agora feitas pelo ferreiro.)
@export var receitas_ferreiro: Array[Dictionary] = [
	{"id": "prego", "nome": "Pregos (6)", "insumos": {"barra_ferro": 1}, "produto": {"prego": 6}, "segundos": 8.0, "estagio": 0},
	{"id": "ferragem", "nome": "Ferragem", "insumos": {"barra_ferro": 2, "prego": 4}, "produto": {"ferragem": 1}, "segundos": 12.0, "estagio": 0},
	# Bloco 94: o couro deixa de servir só pro casaco — a mochila do minerador (+carga); as botas são da fila de
	# equipamento (vestiário), como o casaco
	{"id": "mochila", "nome": "Mochila de couro", "insumos": {"couro": 3, "prego": 2}, "produto": {"mochila": 1}, "segundos": 14.0, "estagio": 0},
]
## Máximo de ordens na fila do ferreiro.
@export var max_fila_ferreiro: int = 4

@export_group("Efeitos")
@export var forge_sound_interval: float = 0.7
@export var idle_forge_energy: float = 0.45
@export var active_forge_energy: float = 1.1

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "oficina"
## Bloco 87: a obra daqui é do FERREIRO (o engenheiro só faz obras de construção).
var oficio := "ferreiro"
## Bloco 87: as encomendas de pregos e ferragens (ProductionQueue).
var fila_ferreiro
## Bloco 58: a Oficina é construída pelo engenheiro (jogo novo com fundação). Não construída: fica
## no mapa invisível, sem clique, sem obra, sem bloquear caminho — mas no grupo "oficina" (as
## ferramentas que ela ainda não fez continuam trancando os minérios). Save antigo: já construída.
var built := true
var crafted: Dictionary = {}
var crafting: String = ""
var craft_left: float = 0.0

var _sound_timer: float = 0.0
## Bloco 31: a ferramenta encomendada só é forjada com um ENGENHEIRO trabalhando aqui.
var _obra := ObraSite.new()

@onready var _visual: Sprite2D = $Visual
@onready var _sparks: CPUParticles2D = $Sparks
@onready var _forge_light: PointLight2D = $ForgeLight
@onready var _label: Label = $NameLabel


func _ready() -> void:
	super()
	fila_ferreiro = ProductionQueue.new(receitas_ferreiro, max_fila_ferreiro)  # Bloco 87
	_obra.trabalhador = "ferreiro"
	_obra.verbo = "forjando"
	add_to_group("oficina")
	if built:
		add_to_group("obras")
		add_to_group("clickable")
	_forge_light.add_to_group("cullable_lights")
	for id in TOOL_IDS:
		crafted[id] = false
	_update_visual()


func _equip() -> Node:
	return get_tree().get_first_node_in_group("equipment")


func _process(delta: float) -> void:
	if not obra_pending():
		return
	var working := _obra.has_engineer()
	_sparks.emitting = working
	if not working:  # encomendada, esperando engenheiro: a forja fica em brasa, parada
		_forge_light.energy = idle_forge_energy
		_update_label()
		return
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = forge_sound_interval * randf_range(0.8, 1.2)
		Audio.forge(global_position)
	# forja tremeluzindo enquanto trabalha
	_forge_light.energy = active_forge_energy * (1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.12)
	_update_label()


# ------------------------------------------------------------ obra (Bloco 31)
func obra_pending() -> bool:
	if not built:
		return false
	var eq := _equip()
	return crafting != "" or (eq != null and eq.pending()) or _encomenda_andando()


## Bloco 87: tem encomenda de pregos/ferragens pra fazer agora (começada, ou com insumo pra começar)?
func _encomenda_andando() -> bool:
	if fila_ferreiro == null or not fila_ferreiro.tem_trabalho():
		return false
	return fila_ferreiro.comecadas() > 0 or fila_ferreiro.falta_para(get_tree().get_first_node_in_group("economy")) == ""


func obra_title() -> String:
	if crafting == "" and _equip() and _equip().pending():
		return _equip().title()
	if crafting == "" and _encomenda_andando():
		return fila_ferreiro.texto_ordem(0)
	return TOOL_NAMES.get(crafting, "ferramenta")


func obra_progress() -> float:
	if crafting == "" and _equip() and _equip().pending():
		return _equip().progress()
	if crafting == "" and _encomenda_andando():
		return fila_ferreiro.progresso_unidade()
	return craft_progress()


func obra_position(worker: Node) -> Vector2:
	return IsoArt.front(self, Vector2(0, 30)) + _obra.offset_for(worker)


## O FERREIRO (Bloco 87; era o engenheiro) trabalhou `seconds` aqui: só assim a forja anda.
func obra_work(seconds: float) -> void:
	if crafting == "":
		var eq := _equip()
		if eq and eq.pending():
			eq.work(seconds)
			_update_label()
			return
		if _encomenda_andando():
			_trabalha_encomenda(seconds)
		return
	craft_left -= seconds
	if craft_left <= 0.0:
		_finish(crafting)


## Bloco 87: uma unidade de prego/ferragem por vez: começa (paga os insumos) e, pronta, vai pro armazém.
func _trabalha_encomenda(seconds: float) -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	if fila_ferreiro.comecadas() <= 0 and fila_ferreiro.comecar_unidades(1, eco) <= 0:
		return  # faltou insumo: pausada (nada gasto)
	var pronto: Dictionary = fila_ferreiro.trabalhar(seconds)
	for item in pronto:
		eco.add_item(item, pronto[item], global_position)
	if not pronto.is_empty():
		_popup("+%s" % ", ".join(pronto.keys().map(func(k): return "%d %s" % [int(pronto[k]), Items.plural(k)])), Color(0.55, 1.0, 0.5))
		Audio.forge(global_position)
	_update_label()


## Bloco 87: o jogador encomendou `qtd` unidades (nada é gasto agora).
func encomendar(id: String, qtd: int) -> bool:
	var hub := get_tree().get_first_node_in_group("village_hub")
	var lvl: int = int(hub.level) if hub else 1
	if fila_ferreiro.motivo_encomenda(id, qtd, lvl) != "":
		Audio.error()
		return false
	fila_ferreiro.encomendar(id, qtd, lvl)
	if _obra.ordered_at <= 0.0:
		_obra.start()  # (entra na fila das obras pela ordem de encomenda)
	Audio.click()
	_update_label()
	return true


func cancelar(i: int) -> bool:
	var ok: bool = fila_ferreiro.cancelar(i, get_tree().get_first_node_in_group("economy"), global_position)
	if ok:
		Audio.click()
		_update_label()
	return ok


## O que falta pra encomenda da vez continuar ("" = nada).
func falta_encomenda() -> String:
	if fila_ferreiro == null or not fila_ferreiro.tem_trabalho() or fila_ferreiro.comecadas() > 0:
		return ""
	return fila_ferreiro.falta_para(get_tree().get_first_node_in_group("economy"))


func obra_ordered_at() -> float:
	if crafting == "" and _equip() and _equip().pending():
		return _equip().ordered_at()
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)
	_update_visual()


func obra_workers() -> Array[Node]:
	return _obra.workers()


## Área clicável (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-42, -70), Vector2(84, 74)).has_point(p)


# ------------------------------------------------------------ consulta
# ------------------------------------------------------------ construída (Bloco 58)
func is_built() -> bool:
	return built


## Liga/desliga a Oficina no mapa (sem efeito nas ferramentas já feitas).
func set_built(on: bool) -> void:
	built = on
	visible = on
	set_process(on)
	for grp in ["obras", "clickable"]:
		if on and not is_in_group(grp):
			add_to_group(grp)
		elif not on and is_in_group(grp):
			remove_from_group(grp)
	if is_instance_valid(_forge_light):
		_forge_light.enabled = on


## Ficou pronta no lugar escolhido (canteiro do engenheiro).
func build_at(pos: Vector2) -> void:
	global_position = pos
	set_built(true)
	_update_visual()
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()


## Não construída: não bloqueia o caminho.
func get_obstacle_outline() -> PackedVector2Array:
	return super() if built else PackedVector2Array()


func has_tool(id: String) -> bool:
	return crafted.get(id, false)


## Ferro está sempre liberado; os outros dependem da ferramenta.
func is_ore_unlocked(ore_type: String) -> bool:
	var tool := tool_for_ore(ore_type)
	return tool == "" or has_tool(tool)


## Ferramenta que libera o minério ("" = não precisa de nenhuma).
func tool_for_ore(ore_type: String) -> String:
	if TOOL_UNLOCKS_EXTRA.has(ore_type):
		return TOOL_UNLOCKS_EXTRA[ore_type]
	for id in TOOL_UNLOCKS:
		if TOOL_UNLOCKS[id] == ore_type:
			return id
	return ""


## Texto do que a ferramenta libera ("Cobre", "caça de animais"...).
func unlock_label(id: String) -> String:
	if TOOL_UNLOCKS.has(id):
		var cat := get_tree().get_first_node_in_group("catalogo")
		if cat and not cat.minerio_conhecido(TOOL_UNLOCKS[id]):
			return "um minério desconhecido"  # Bloco 102: o catálogo ainda não estudou
		return Ores.display_name(TOOL_UNLOCKS[id])
	return TOOL_UNLOCK_LABELS.get(id, "?")


func tool_cost(id: String) -> Vector3i:
	return tool_costs[TOOL_IDS.find(id)]


func tool_ore_type(id: String) -> String:
	return tool_ore_types[TOOL_IDS.find(id)]


func tool_wood(id: String) -> int:
	var i := TOOL_IDS.find(id)
	return tool_wood_costs[i] if i < tool_wood_costs.size() else 0


func tool_stage(id: String) -> int:
	return tool_min_stage[TOOL_IDS.find(id)]


## Bloco 94: os itens a mais da ferramenta ({aco: 12}).
func tool_item_cost(id: String) -> Dictionary:
	var d = tool_itens.get(id, {})
	return d if d is Dictionary else {}


## "310 cr + 150 ferro + 30 madeira" / "400 cr + 20 madeira + 12 aço".
func tool_cost_text(id: String) -> String:
	var c := tool_cost(id)
	var bits: Array[String] = ["%d cr" % c.x]
	if c.y > 0:
		bits.append("%d %s" % [c.y, Ores.display_name(tool_ore_type(id)).to_lower()])
	if tool_wood(id) > 0:
		bits.append("%d madeira" % tool_wood(id))
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	var it: String = eco.itens_texto(tool_item_cost(id)) if eco else ""
	if it != "":
		bits.append(it)
	return " + ".join(bits)


## Bloco 94: multiplicador do minério por golpe (a picareta de aço).
func mult_mineracao() -> float:
	return picareta_aco_mult if has_tool("picareta_de_aco") else 1.0


func craft_progress() -> float:
	if crafting == "":
		return 0.0
	var total := float(tool_cost(crafting).z)
	return clampf(1.0 - craft_left / total, 0.0, 1.0) if total > 0.0 else 1.0


## "" se dá pra fabricar agora; senão o motivo.
func tool_block_reason(id: String) -> String:
	if has_tool(id):
		return "pronta"
	if crafting == id:
		return "fabricando"
	if crafting != "":
		return "forja ocupada"
	if id == "antena":  # Bloco 104: só serve depois da pista do Ferrugento (e não precisa com o Rádio)
		var ex := get_tree().get_first_node_in_group("expedicoes")
		if ex and int(ex.cadeia) < 1:
			return "estude o corpo de um Ferrugento primeiro"
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and hub.level < tool_stage(id):
		return "requer vila nível %d" % tool_stage(id)
	var cost := tool_cost(id)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return "sem recursos"
	var missing: String = eco._junta_falta(eco.missing_text(cost.x, cost.y, tool_ore_type(id), tool_wood(id)),
		eco.itens_falta(tool_item_cost(id)))  # Bloco 94: + o aço
	if missing != "":
		return missing
	return ""


# ------------------------------------------------------------ ações
func start_tool(id: String) -> bool:
	if tool_block_reason(id) != "":
		Audio.error()
		return false
	var cost := tool_cost(id)
	var eco := get_tree().get_first_node_in_group("economy")
	if not eco.spend(cost.x, cost.y, tool_ore_type(id), tool_wood(id)):
		return false
	eco.paga_itens(tool_item_cost(id))  # Bloco 94 (já conferido no tool_block_reason)
	crafting = id
	craft_left = float(cost.z)
	_obra.start()
	_sound_timer = 0.0
	_update_visual()
	_popup("Encomendado: %s — precisa de engenheiro" % TOOL_NAMES[id], Color(1.0, 0.8, 0.45))
	tool_started.emit(id)
	return true


func _finish(id: String) -> void:
	crafted[id] = true
	crafting = ""
	craft_left = 0.0
	_update_visual()
	Audio.recruit()
	_popup("%s pronta! %s liberado" % [TOOL_NAMES[id], unlock_label(id)], Color(0.55, 1.0, 0.5))
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed()
	for worker in get_tree().get_nodes_in_group("ipezinhos"):
		if worker.has_method("on_tool_crafted"):
			worker.on_tool_crafted(id)
	tool_crafted.emit(id)


# ------------------------------------------------------------ visual
func _update_visual() -> void:
	var active := obra_pending() and _obra.has_engineer()
	_visual.frame = 1 if active else 0
	_sparks.emitting = active
	_forge_light.energy = active_forge_energy if active else idle_forge_energy
	_update_label()


func _update_label() -> void:
	if crafting != "":
		_label.text = "Oficina\n%s  %s" % [TOOL_NAMES[crafting], _obra.status(craft_progress())]
		_label.modulate = Color(1.0, 0.8, 0.5) if _obra.has_engineer() else Color(1.0, 0.62, 0.3)
	elif obra_pending():
		_label.text = "Oficina\n%s  %s" % [obra_title(), _obra.status(obra_progress())]
		_label.modulate = Color(1.0, 0.8, 0.5) if _obra.has_engineer() else Color(1.0, 0.62, 0.3)
	else:
		_label.text = "Oficina"
		_label.modulate = Color(0.9, 0.86, 0.8)


func _popup(text: String, color: Color) -> void:
	var stacked := get_children().filter(func(c): return c.has_meta("popup")).size()
	var popup := Label.new()
	popup.set_meta("popup", true)
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", Tipo.MAPA_POPUP)
	popup.position = Vector2(-130, -110 - stacked * 20)
	popup.size = Vector2(260, 20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 1.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(1.2)
	tween.chain().tween_callback(popup.queue_free)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"crafted": crafted.duplicate(), "crafting": crafting, "craft_left": craft_left,
		"obra": _obra.get_save_data(), "built": built, "position": SaveUtil.vec2_to_array(global_position),
		"encomendas": fila_ferreiro.get_save_data()}  # Bloco 87


func load_save_data(d: Dictionary) -> void:
	var saved := SaveUtil.dict(d, "crafted")
	for id in TOOL_IDS:
		crafted[id] = SaveUtil.boolean(saved, id, false)
	crafting = SaveUtil.text(d, "crafting", "")
	if crafting not in TOOL_IDS or has_tool(crafting):
		crafting = ""
	craft_left = maxf(SaveUtil.num(d, "craft_left", 0.0), 0.0) if crafting != "" else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))  # save antigo: ordered_at 0 (vai primeiro na fila)
	fila_ferreiro.load_save_data(SaveUtil.array(d, "encomendas"))  # Bloco 87 (save antigo: nenhuma)
	# Bloco 58: save antigo (Oficina fixa) = já construída, no lugar da cena
	var pos := SaveUtil.vec2(d, "position", Vector2.INF)
	if pos != Vector2.INF:
		global_position = pos
	set_built(SaveUtil.boolean(d, "built", true))
	_update_visual()
	for node in get_tree().get_nodes_in_group("minerios"):
		if node.has_method("on_unlock_changed"):
			node.on_unlock_changed(false)
	for worker in get_tree().get_nodes_in_group("ipezinhos"):
		for id in TOOL_IDS:
			if has_tool(id) and worker.has_method("on_tool_crafted"):
				worker.on_tool_crafted(id)
