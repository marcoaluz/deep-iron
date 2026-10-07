extends "res://scripts/props/station.gd"
## Casa da vila. Cada slot é uma cama FIXA: o ipezinho reivindica uma cama
## quando nasce (claim_bed) e só a devolve quando sai do jogo.
##
## À noite o ipezinho vai até a porta (posição da cama dele) e "entra": some do
## mapa até amanhecer. Com alguém dentro, a janela acende e sai fumaça da chaminé.
##
## Com built = false a casa é só um LOTE (estacas, madeira, pedras): não tem
## camas e espera a melhoria "Moradias" do Centro da Vila chamar build().
## O lote já ocupa o espaço na navegação, então construir não precisa refazer a malha.
##
## Bloco 31: casa nova encomendada nasce como CANTEIRO (start_construction) e só fica
## pronta com um engenheiro trabalhando nela (interface de obra, ver obra_site.gd).
##
## Bloco 56: NÍVEIS 2 e 3. Ampliar custa créditos + ferro + madeira, pede estágio da vila (e
## pesquisa, no 3) e é obra do engenheiro; a casa continua habitada durante a obra. Cada nível
## dá mais camas e CONFORTO (ânimo de quem mora nela). Clique na casa: janela da casa.
##
## Bloco 94: o nível 3 pede pregos e ferragens (do ferreiro). CAMAS DE TÁBUA (da Carpintaria): o jogador manda
## trocar (janela da casa; a cama sai do armazém na hora) e o CARPINTEIRO vem montar; quem dorme numa cama de
## tábua ganha conforto_cama_boa de ânimo. As camas de tábua são as primeiras da casa (índice < camas_boas).

signal built_changed

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const FRAME_EMPTY := 0
const FRAME_LIT := 1
const FRAME_LOT := 2

## false = lote vazio (formato antigo; hoje as casas novas são posicionadas pelo jogador).
@export var built: bool = true
## true = casa nova que o jogador posicionou (a posição vai pro save; as 3 iniciais são fixas).
@export var placed_by_player: bool = false
## Bloco 37: casa inicial da fundação (não soma no limite de ipezinhos quando fica pronta).
@export var starter_house: bool = false

@export_group("Níveis (Bloco 56)")
@export var max_nivel: int = 3
## Camas e conforto (ânimo de quem mora) por nível: [nível 1, nível 2, nível 3].
@export var beds_by_level: Array[int] = [4, 6, 8]
@export var comfort_by_level: Array[float] = [0.0, 4.0, 8.0]
## Custo pra CHEGAR em cada nível [nível 1 (não usado), nível 2, nível 3]: créditos, ferro, madeira, segundos de engenheiro.
@export var upgrade_credits: Array[int] = [0, 220, 420]
## Bloco 94: o nível 3 baixou de 90 pra 70 ferro (o resto vai em pregos e ferragens: upgrade_pregos/upgrade_ferragens).
@export var upgrade_ore: Array[int] = [0, 40, 70]
@export var upgrade_wood: Array[int] = [0, 40, 70]
@export var upgrade_seconds: Array[float] = [0.0, 40.0, 60.0]
## Bloco 94: pregos e ferragens pra chegar em cada nível [1, 2, 3] (antes da fornalha viram ferro: Economy).
@export var upgrade_pregos: Array[int] = [0, 0, 24]
@export var upgrade_ferragens: Array[int] = [0, 0, 2]
@export_group("Camas de tábua (Bloco 94)")
## Ânimo de quem dorme numa cama de tábua (soma no conforto da casa).
@export var conforto_cama_boa: float = 3.0
## Segundos de carpinteiro pra montar uma cama na casa.
@export var cama_segundos: float = 12.0
## Pré-requisitos de cada nível [nível 1, 2, 3]: estágio mínimo do Centro da Vila e pesquisa ("" = nenhuma).
@export var level_min_stage: Array[int] = [0, 2, 3]
@export var level_research: Array[String] = ["", "", "medicina"]

var panel_id := "casa"  # Bloco 56: clique abre a janela da casa
var level := 1
var upgrade_left := 0.0
var upgrade_total := 0.0
## Bloco 94: camas de tábua montadas e as que esperam o carpinteiro (já saíram do armazém).
var camas_boas := 0
var camas_pedidas := 0
## O carpinteiro que está vindo montar (não vai pro save: ele escolhe de novo).
var montador: Node = null

var _inside: Array[Node] = []
## Obra (Bloco 31): segundos de engenheiro que faltam / total. build_total 0 = não é obra.
var build_left: float = 0.0
var build_total: float = 0.0
var _obra := ObraSite.new()

@onready var _visual: Sprite2D = $Visual
@onready var _window_light: PointLight2D = $WindowLight
@onready var _smoke: CPUParticles2D = $Smoke
@onready var _sleep_label: Label = $SleepLabel


func _ready() -> void:
	_apply_level_beds()
	super()
	add_to_group("casas")
	add_to_group("obras")
	add_to_group("clickable")
	_window_light.add_to_group("cullable_lights")
	_update_visual()


## Constrói a casa no lote (chamado pelo Centro da Vila).
func build() -> void:
	if built:
		return
	built = true
	_update_visual()
	var pop := create_tween()
	_visual.scale = Vector2(2.3, 1.6)
	pop.tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	built_changed.emit()


## Casa encomendada: vira canteiro esperando engenheiro (Bloco 31).
func start_construction(seconds: float) -> void:
	built = false
	build_total = maxf(seconds, 1.0)
	build_left = build_total
	_obra.start()
	_update_visual()


# ------------------------------------------------------------ obra (Bloco 31)
func obra_pending() -> bool:
	return (not built and build_total > 0.0) or upgrade_pending()


func obra_title() -> String:
	return "Ampliar casa (nível %d)" % (level + 1) if upgrade_pending() else "Casa nova"


func obra_progress() -> float:
	if upgrade_pending():
		return clampf(1.0 - upgrade_left / upgrade_total, 0.0, 1.0)
	return clampf(1.0 - build_left / build_total, 0.0, 1.0) if build_total > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return IsoArt.front(self, Vector2(0, 30)) + _obra.offset_for(worker)


## O engenheiro trabalhou `seconds` aqui: só assim a casa sobe.
func obra_work(seconds: float) -> void:
	if not obra_pending():
		return
	if upgrade_pending():
		upgrade_left -= seconds
		if upgrade_left <= 0.0:
			_finish_upgrade()
		else:
			_update_visual()
		return
	build_left -= seconds
	if build_left <= 0.0:
		build_left = 0.0
		build_total = 0.0
		build()
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub and hub.has_method("on_house_built"):
			hub.on_house_built(self)
	else:
		_update_visual()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)
	_update_visual()


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)
	_update_visual()


func obra_workers() -> Array[Node]:
	return _obra.workers()


## Bloco 96: cancelada. Ampliação: a casa fica como estava. Casa nova: some, e a Moradias (ou a casa inicial)
## volta um passo (ObraSite.cancelar já devolveu créditos e material).
func obra_cancelar() -> void:
	if upgrade_pending():
		upgrade_left = 0.0
		upgrade_total = 0.0
		_update_visual()
		return
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub:
		if starter_house:
			hub.starter_houses_left += 1
		elif hub.upgrades.get("moradias", 0) > 0:
			hub.upgrades.moradias -= 1
	remove_from_group("casas")
	remove_from_group("obras")
	var env := get_tree().get_first_node_in_group("environment")
	queue_free()
	if env and env.has_method("rebuild_navigation"):
		env.rebuild_navigation.call_deferred()


## "Pulo" + poeira de quando a casa acaba de ser construída.
func pop_in() -> void:
	var pop := create_tween()
	_visual.scale = Vector2(2.3, 1.6)
	pop.tween_property(_visual, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Bloco 56: clique na casa (vista antiga; na iso o raio da câmera acerta a caixa do desenho).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-44, -76), Vector2(88, 80)).has_point(p)


# ------------------------------------------------------------ níveis (Bloco 56)
func max_level() -> int:
	return clampi(max_nivel, 1, beds_by_level.size())


func beds_for(lv: int) -> int:
	return beds_by_level[clampi(lv, 1, beds_by_level.size()) - 1]


func comfort_for(lv: int) -> float:
	return comfort_by_level[clampi(lv, 1, comfort_by_level.size()) - 1]


func comfort_bonus() -> float:
	return comfort_for(level) if built else 0.0


func upgrade_pending() -> bool:
	return upgrade_total > 0.0


func upgrade_has_engineer() -> bool:
	return _obra.has_engineer()


func upgrade_status() -> String:
	return _obra.status(obra_progress())


## Valor do array por nível de DESTINO (índice 0 = nível 1, 1 = nível 2, 2 = nível 3).
func _idx(arr: Array, lv: int):
	return arr[clampi(lv - 1, 0, arr.size() - 1)]


## Bloco 94: os pregos e as ferragens do nível de destino.
func _itens_nivel(lv: int) -> Dictionary:
	var d := {}
	if int(_idx(upgrade_pregos, lv)) > 0:
		d["prego"] = int(_idx(upgrade_pregos, lv))
	if int(_idx(upgrade_ferragens, lv)) > 0:
		d["ferragem"] = int(_idx(upgrade_ferragens, lv))
	return d


## [ferro, itens] do nível de destino como a Economia cobra agora (antes da fornalha as peças viram ferro).
func _custo_nivel(lv: int) -> Array:
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	var ef: Dictionary = eco.itens_efetivos(_itens_nivel(lv)) if eco else {"itens": _itens_nivel(lv), "minerio": 0.0}
	return [float(_idx(upgrade_ore, lv)) + float(ef.minerio), ef.itens]


func upgrade_cost_text() -> String:
	var lv := level + 1
	var c := _custo_nivel(lv)
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	var it: String = eco.itens_texto(c[1]) if eco else ""
	return "%d cr + %d ferro + %d madeira%s" % [_idx(upgrade_credits, lv), int(c[0]), _idx(upgrade_wood, lv), (" + " + it) if it != "" else ""]


## Por que não dá pra ampliar agora ("" = dá).
func upgrade_block_reason() -> String:
	if not built:
		return "a casa ainda está em obra"
	if upgrade_pending():
		return "já está sendo ampliada"
	if level >= max_level():
		return "nível máximo"
	var lv := level + 1
	var hub := get_tree().get_first_node_in_group("village_hub")
	var est: int = _idx(level_min_stage, lv)
	if hub and int(hub.level) < est:
		return "precisa da vila no estágio %d" % est
	var pq: String = _idx(level_research, lv)
	var res := get_tree().get_first_node_in_group("research")
	if pq != "" and res and not res.has(pq):
		var nome: String = res.TECHS[pq].name if res.TECHS.has(pq) else pq
		return "precisa da pesquisa %s" % nome
	var eco := get_tree().get_first_node_in_group("economy")
	if eco:
		var c := _custo_nivel(lv)
		var m: String = eco._junta_falta(eco.missing_text(_idx(upgrade_credits, lv), c[0], "ferro", _idx(upgrade_wood, lv), "ferro"),
			eco.itens_falta(c[1]))  # Bloco 94: + pregos e ferragens
		if m != "":
			return m
	return ""


## Encomenda a ampliação: cobra e vira obra do engenheiro (a casa segue habitada).
func start_upgrade() -> bool:
	if upgrade_block_reason() != "":
		return false
	var lv := level + 1
	var eco := get_tree().get_first_node_in_group("economy")
	var c := _custo_nivel(lv)
	if eco == null or not eco.spend(_idx(upgrade_credits, lv), c[0], "ferro", _idx(upgrade_wood, lv)):
		return false
	eco.paga_itens(c[1])  # Bloco 94 (já conferido no upgrade_block_reason)
	upgrade_total = maxf(float(_idx(upgrade_seconds, lv)), 1.0)
	upgrade_left = upgrade_total
	_obra.start()
	_update_visual()
	return true


func _finish_upgrade() -> void:
	upgrade_left = 0.0
	upgrade_total = 0.0
	level = mini(level + 1, max_level())
	_apply_level_beds()
	pop_in()
	_update_visual()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Casa ampliada pro nível %d: %d camas." % [level, slot_count], Color(0.55, 1.0, 0.5))
	built_changed.emit()


# ------------------------------------------------------------ camas de tábua (Bloco 94)
## Camas que esperam o carpinteiro montar.
func camas_a_montar() -> int:
	return camas_pedidas if built else 0


## A cama `i` da casa é de tábua?
func cama_boa(i: int) -> bool:
	return i >= 0 and i < camas_boas


## Onde o carpinteiro monta: a porta da próxima cama a trocar.
func porta_montagem() -> Vector2:
	return get_slot_position(clampi(camas_boas, 0, slot_count - 1))


## Por que não dá pra mandar trocar mais uma cama ("" = dá).
func motivo_cama_boa() -> String:
	if not built:
		return "a casa ainda está em obra"
	if camas_boas + camas_pedidas >= slot_count:
		return "todas as camas já são de tábua"
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null or eco.quantidade("cama_boa") < 1.0:
		return "sem cama de tábua no armazém (encomende na Carpintaria)"
	return ""


## O jogador mandou trocar uma cama: a cama de tábua sai do armazém agora e o carpinteiro vem montar.
func pedir_cama_boa() -> bool:
	if motivo_cama_boa() != "":
		Audio.error()
		return false
	get_tree().get_first_node_in_group("economy").take_item("cama_boa", 1.0)
	camas_pedidas += 1
	Audio.click()
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.has_method("is_carpenter") and w.is_carpenter():
			w.wake_decision()
	return true


## O carpinteiro terminou de montar uma cama.
func instala_cama_boa() -> bool:
	if camas_pedidas <= 0:
		return false
	camas_pedidas -= 1
	camas_boas = mini(camas_boas + 1, slot_count)
	pop_in()
	return true


## Camas = as do nível (o nível só sobe: ninguém perde a cama).
func _apply_level_beds() -> void:
	slot_count = maxi(beds_for(level), 1)
	if _slot_owners.size() < slot_count:
		_slot_owners.resize(slot_count)


## Quem tem cama aqui.
func residents() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.get("_home") == self)


func has_free_slot_for(worker: Node) -> bool:
	return built and super(worker)


## Reserva uma cama permanente. Retorna o índice ou -1 se a casa estiver cheia.
func claim_bed(worker: Node2D) -> int:
	if not built:
		return -1
	return reserve_slot(worker)


## Reserva uma cama específica (ao carregar o save). -1 se estiver ocupada/não existir.
func claim_specific_bed(worker: Node2D, bed: int) -> int:
	if not built or bed < 0 or bed >= slot_count or _slot_taken(bed):
		return -1
	_slot_owners[bed] = worker
	return bed


func beds_total() -> int:
	return slot_count if built else 0


func beds_taken() -> int:
	return occupied_slot_count() if built else 0


## Chamado pelo ipezinho ao entrar/sair de casa.
func set_inside(worker: Node, inside: bool) -> void:
	if inside and not _inside.has(worker):
		_inside.append(worker)
	elif not inside:
		_inside.erase(worker)
	_update_visual()


func sleeping_count() -> int:
	_inside = _inside.filter(func(w): return is_instance_valid(w))
	return _inside.size()


func _update_visual() -> void:
	if not built:
		_visual.frame = FRAME_LOT
		_window_light.enabled = false
		_smoke.emitting = false
		_sleep_label.visible = true
		if obra_pending():
			_sleep_label.text = "obra: casa\n%s" % _obra.status(obra_progress())
			_sleep_label.modulate = Color(1.0, 0.8, 0.5) if _obra.has_engineer() else Color(1.0, 0.62, 0.3)
		else:
			_sleep_label.text = "lote vazio"
			_sleep_label.modulate = Color(1, 1, 1, 0.5)
		return
	var occupied := sleeping_count() > 0
	_visual.frame = FRAME_LIT if occupied else FRAME_EMPTY
	_window_light.enabled = occupied
	_smoke.emitting = occupied
	_sleep_label.visible = occupied or upgrade_pending()
	_sleep_label.modulate = Color.WHITE
	if upgrade_pending():
		_sleep_label.text = "ampliando (nível %d)\n%s" % [level + 1, _obra.status(obra_progress())]
		_sleep_label.modulate = Color(1.0, 0.8, 0.5) if _obra.has_engineer() else Color(1.0, 0.62, 0.3)
	elif occupied:
		_sleep_label.text = "Zz  %d" % sleeping_count()


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"built": built, "build_left": build_left, "build_total": build_total,
		"obra": _obra.get_save_data(), "starter_house": starter_house,
		"level": level, "upgrade_left": upgrade_left, "upgrade_total": upgrade_total,
		"camas_boas": camas_boas, "camas_pedidas": camas_pedidas}  # Bloco 94


func load_save_data(d: Dictionary) -> void:
	built = SaveUtil.boolean(d, "built", built)
	starter_house = SaveUtil.boolean(d, "starter_house", false)
	# Bloco 31 (save antigo: casa sem obra)
	build_total = maxf(SaveUtil.num(d, "build_total", 0.0), 0.0) if not built else 0.0
	build_left = clampf(SaveUtil.num(d, "build_left", build_total), 0.0, build_total)
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	# Bloco 56 (save antigo: sem nível = 1)
	level = clampi(int(SaveUtil.num(d, "level", 1.0)), 1, max_level())
	upgrade_total = maxf(SaveUtil.num(d, "upgrade_total", 0.0), 0.0)
	upgrade_left = clampf(SaveUtil.num(d, "upgrade_left", upgrade_total), 0.0, upgrade_total)
	_apply_level_beds()
	# Bloco 94 (save antigo: nenhuma cama de tábua)
	camas_boas = clampi(SaveUtil.integer(d, "camas_boas", 0), 0, slot_count)
	camas_pedidas = clampi(SaveUtil.integer(d, "camas_pedidas", 0), 0, slot_count - camas_boas)
	_update_visual()
