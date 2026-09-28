extends "res://scripts/props/station.gd"
## Centro da Vila: hub de progressão (grupo "village_hub").
##
## - Mostra o progresso geral (população, minério coletado no total, estágio).
## - "Expandir a vila": sobe o estágio (1 a 5). Precisa de um marco de minério
##   coletado no total (tudo que já entrou nos armazéns, mesmo o que foi vendido)
##   e custa créditos.
##   Bloco 33 — o que EXPANDIR faz (e o que NÃO faz):
##     * NÃO muda o tamanho do mapa: a mina (map_rect do environment) é fixa.
##     * Abre uma GALERIA LACRADA dentro da mina de sempre (nível 1): uma jazida atrás
##       de entulho (mineral_node: min_village_level). 2 Vilarejo = ferro (oeste),
##       3 Vila = cobre (sudeste), 4 Vila Mineira = carvão (norte), 5 Cidade Mineira =
##       veio rico de ferro (nordeste). Cobre e carvão ainda pedem a ferramenta da Oficina.
##     * Continua liberando o que pede "vila nível N" (melhorias, peças da Escavadeira,
##       ferramentas, laboratório, escudo, conserto do abismo).
##     * Os NÍVEIS DE PROFUNDIDADE são outra coisa e não mudaram: o nível 2 abre com a
##       Escavadeira pronta (elevador) e o abismo com o conserto da plataforma.
## - Melhorias compradas com créditos + minério do armazém. Cada melhoria só pode
##   ter no máximo tantos níveis quanto o estágio atual da vila.
##     Moradias:         +workers_per_moradia no limite de ipezinhos e uma casa
##                       nova (4 camas) que o JOGADOR posiciona no mapa (HousePlacer).
##                       O custo só é pago quando ele confirma o lugar; Esc cancela.
##     Enfermaria:       +1 leito na Enfermaria e -recovery_cut_per_level no tempo de cura (por nível).
##     Trilhas batidas:  +speed_bonus_per_level na velocidade de caminhada (por nível).
##
## Bloco 31: comprar uma melhoria (ou uma casa) paga na hora e ENCOMENDA a obra —
## ela só anda com um engenheiro trabalhando (melhoria: aqui na frente do Centro;
## casa: no canteiro). Uma melhoria da vila por vez; casas, quantas quiser.
## O +limite de ipezinhos da casa só entra quando ela fica pronta (on_house_built).
##
## Os ipezinhos consultam recovery_mult() e speed_mult(); a economia guarda o limite.
## Ninguém trabalha aqui (sem slots): é só a base que bloqueia a navegação.

signal level_changed(level: int)
signal upgrade_bought(id: String, new_level: int)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const Ores := preload("res://scripts/core/ores.gd")
const STAGE_NAMES := ["Acampamento", "Vilarejo", "Vila", "Vila Mineira", "Cidade Mineira"]
const UPGRADE_IDS := ["moradias", "enfermaria", "trilhas"]
const CASA_SCENE := preload("res://scenes/props/casa.tscn")
const UPGRADE_NAMES := {
	"moradias": "Moradias",
	"enfermaria": "Enfermaria",
	"trilhas": "Trilhas batidas",
}

@export_group("Estágios da vila")
## Minério coletado no total pra chegar em cada estágio (índice 0 = estágio 1).
@export var level_ore_required: Array[int] = [0, 375, 1250, 3100, 6250]
## Créditos pra expandir pra cada estágio (índice 0 = estágio 1, não usado).
@export var level_credit_cost: Array[int] = [0, 190, 625, 1500, 3100]

@export_group("Melhoria: Moradias")
## Custo de cada nível: x = créditos, y = minério do armazém.
## Casa = créditos (x) + PEDRA (y). "Pedra" = minério de ferro (Bloco 13: o jogo não tem
## um recurso pedra separado; o ferro é a rocha que a mina já dá).
@export var moradias_costs: Array[Vector2i] = [Vector2i(190, 40), Vector2i(375, 60), Vector2i(750, 150), Vector2i(1250, 310)]
## Madeira de cada casa (por nível de Moradias).
@export var moradias_wood: Array[int] = [20, 30, 45, 60]
## Minério usado como "pedra" nas casas.
@export var house_stone_ore: String = "ferro"
@export var workers_per_moradia: int = 4

@export_group("Melhoria: Enfermaria")
@export var enfermaria_costs: Array[Vector2i] = [Vector2i(125, 25), Vector2i(310, 75), Vector2i(625, 190)]
## Fração do tempo de cura cortada por nível (0.2 = -20% por nível).
@export_range(0.0, 0.3) var recovery_cut_per_level: float = 0.2

@export_group("Melhoria: Trilhas batidas")
@export var trilhas_costs: Array[Vector2i] = [Vector2i(150, 25), Vector2i(375, 100), Vector2i(810, 250)]
## Velocidade extra por nível (0.1 = +10% por nível).
@export var speed_bonus_per_level: float = 0.1

@export_group("Obras (Bloco 31)")
## Segundos de trabalho de engenheiro pra cada nível de cada melhoria.
@export var enfermaria_build_times: Array[float] = [30.0, 45.0, 60.0]
@export var trilhas_build_times: Array[float] = [25.0, 40.0, 55.0]
## Segundos de trabalho de engenheiro pra erguer cada casa (por nível de Moradias).
@export var house_build_times: Array[float] = [35.0, 45.0, 55.0, 65.0]
## Bloco 31b: segundos de engenheiro pra EXPANDIR a vila (estágio 2, 3, 4, 5).
@export var expand_build_times: Array[float] = [60.0, 90.0, 120.0, 150.0]

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "hub"
## Melhoria da vila encomendada e ainda em obra ("" = nenhuma).
var pending_upgrade: String = ""
var upgrade_left: float = 0.0
var upgrade_total: float = 0.0
var _obra := ObraSite.new()
var level: int = 1
var upgrades: Dictionary = {"moradias": 0, "enfermaria": 0, "trilhas": 0}

@onready var _visual: Sprite2D = $Visual
@onready var _name_label: Label = $NameLabel


func _ready() -> void:
	super()
	add_to_group("village_hub")
	add_to_group("obras")
	add_to_group("clickable")
	$WindowLight.add_to_group("cullable_lights")
	_update_visual()


## Área clicável do prédio (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-58, -100), Vector2(116, 104)).has_point(p)


## Pro ambiente não espalhar pedras/tochas em cima do prédio.
func get_clear_center() -> Vector2:
	return global_position + Vector2(0, -45)


func get_clear_radius() -> float:
	return 85.0


# ------------------------------------------------------------ efeitos (consultados pelos ipezinhos)
func recovery_mult() -> float:
	return maxf(0.1, 1.0 - recovery_cut_per_level * upgrades.enfermaria)


func speed_mult() -> float:
	return 1.0 + speed_bonus_per_level * upgrades.trilhas


# ------------------------------------------------------------ progresso
func stage_name(lvl: int = level) -> String:
	return STAGE_NAMES[clampi(lvl, 1, STAGE_NAMES.size()) - 1]


func max_level() -> int:
	return STAGE_NAMES.size()


## Minério que já entrou nos armazéns desde o começo do jogo (inclui o vendido).
func lifetime_ore() -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.lifetime_stored
	return total


func next_level_ore() -> int:
	return level_ore_required[level] if level < max_level() else 0


func next_level_cost() -> int:
	return level_credit_cost[level] if level < max_level() else 0


func can_level_up() -> bool:
	var eco := _economy()
	return level < max_level() and eco != null and pending_upgrade == "" \
		and lifetime_ore() >= next_level_ore() and eco.credits >= next_level_cost()


func level_up() -> bool:
	if not can_level_up():
		Audio.error()
		return false
	_economy().spend(next_level_cost(), 0)
	# Bloco 31b: pagou -> vira obra (uma obra da vila por vez, como as melhorias)
	pending_upgrade = "expandir"
	upgrade_total = build_time("expandir")
	upgrade_left = upgrade_total
	_obra.start()
	_update_visual()
	_popup("Expansão encomendada — precisa de engenheiro", Color(1.0, 0.8, 0.45))
	Audio.click()
	return true


func _finish_expansion() -> void:
	pending_upgrade = ""
	upgrade_left = 0.0
	upgrade_total = 0.0
	level += 1
	_update_visual()
	_popup("A vila agora é: %s!" % stage_name(), Color(1.0, 0.85, 0.4))
	Audio.recruit()
	_refresh_galleries(true)
	var opened := galleries_for_level(level)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and not opened.is_empty():
		var names: Array[String] = []
		for m in opened:
			names.append(_gallery_text(m))
		hud.show_banner("A VILA AGORA É: %s" % stage_name().to_upper(),
			"Galeria aberta dentro da mina: %s." % ", ".join(names))
	level_changed.emit(level)


# ------------------------------------------------------------ galerias lacradas (Bloco 33)
## Jazidas que abrem quando a vila chega nesse estágio.
func galleries_for_level(lvl: int) -> Array:
	return get_tree().get_nodes_in_group("minerios").filter(
		func(m): return m.get("min_village_level") == lvl)


## "galeria oeste (ferro)" (+ a ferramenta que ainda falta, se faltar).
func _gallery_text(m: Node) -> String:
	var t := "galeria %s (%s)" % [m.gallery_name, Ores.display_name(m.ore_type).to_lower()]
	var oficina := get_tree().get_first_node_in_group("oficina")
	if oficina and not oficina.is_ore_unlocked(m.ore_type):
		t += " — precisa de %s" % oficina.TOOL_NAMES[oficina.tool_for_ore(m.ore_type)]
	return t


## O que o estágio `lvl` libera (pro painel da vila).
func stage_unlocks_text(lvl: int) -> String:
	var parts: Array[String] = []
	for m in galleries_for_level(lvl):
		parts.append(_gallery_text(m))
	parts.append("melhorias até o nível %d" % lvl)
	return ", ".join(parts)


func _refresh_galleries(animate: bool) -> void:
	for m in get_tree().get_nodes_in_group("minerios"):
		if m.has_method("on_unlock_changed"):
			m.on_unlock_changed(animate)


# ------------------------------------------------------------ melhorias
func upgrade_costs(id: String) -> Array[Vector2i]:
	match id:
		"moradias":
			return moradias_costs
		"enfermaria":
			return enfermaria_costs
		"trilhas":
			return trilhas_costs
	return []


func upgrade_max(id: String) -> int:
	return upgrade_costs(id).size()


## Custo do próximo nível (Vector2i(-1, -1) se já está no máximo).
func upgrade_cost(id: String) -> Vector2i:
	var lvl: int = upgrades[id]
	var costs := upgrade_costs(id)
	return costs[lvl] if lvl < costs.size() else Vector2i(-1, -1)


## "" se pode comprar; senão o motivo (pra mostrar no botão).
func upgrade_block_reason(id: String) -> String:
	if pending_upgrade == id:
		return "em obra"
	if pending_upgrade != "" and id != "moradias":
		return "outra melhoria em obra"
	var lvl: int = upgrades[id]
	if lvl >= upgrade_max(id):
		return "nível máximo"
	if lvl >= level:
		return "requer vila nível %d" % (lvl + 1)
	var cost := upgrade_cost(id)
	var eco := _economy()
	if eco == null:
		return "sem recursos"
	var missing: String = eco.missing_text(cost.x, cost.y, upgrade_ore_type(id), upgrade_wood(id), upgrade_ore_label(id))
	return missing


## Madeira do próximo nível (só as casas usam).
func upgrade_wood(id: String) -> int:
	if id != "moradias":
		return 0
	var lvl: int = upgrades[id]
	return moradias_wood[lvl] if lvl < moradias_wood.size() else 0


## Tipo de minério gasto ("" = qualquer, o mais barato primeiro). Casas usam ferro como pedra.
func upgrade_ore_type(id: String) -> String:
	return house_stone_ore if id == "moradias" else ""


func upgrade_ore_label(id: String) -> String:
	return "pedra (%s)" % house_stone_ore if id == "moradias" else "minério"


func buy_upgrade(id: String) -> bool:
	if upgrade_block_reason(id) != "":
		Audio.error()
		return false
	if id == "moradias":
		return _start_house_placement()  # paga só ao confirmar o lugar
	var cost := upgrade_cost(id)
	if not _economy().spend(cost.x, cost.y):
		return false
	# Bloco 31: pagou -> vira obra; o nível só sobe quando o engenheiro terminar
	pending_upgrade = id
	upgrade_total = build_time(id)
	upgrade_left = upgrade_total
	_obra.start()
	_update_visual()
	_popup("Encomendado: %s %d — precisa de engenheiro" % [UPGRADE_NAMES[id], upgrades[id] + 1], Color(1.0, 0.8, 0.45))
	Audio.click()
	return true


## Segundos de engenheiro pro PRÓXIMO nível dessa melhoria.
func build_time(id: String) -> float:
	if id == "expandir":
		return expand_build_times[clampi(level - 1, 0, expand_build_times.size() - 1)] if not expand_build_times.is_empty() else 60.0
	var lvl: int = upgrades[id]
	var times: Array[float] = house_build_times
	if id == "enfermaria":
		times = enfermaria_build_times
	elif id == "trilhas":
		times = trilhas_build_times
	return times[mini(lvl, times.size() - 1)] if not times.is_empty() else 30.0


func _finish_upgrade() -> void:
	if pending_upgrade == "expandir":
		_finish_expansion()
		return
	var id := pending_upgrade
	pending_upgrade = ""
	upgrade_left = 0.0
	upgrade_total = 0.0
	upgrades[id] += 1
	_apply_upgrade(id)
	_update_visual()
	_popup("%s %d pronta!" % [UPGRADE_NAMES[id], upgrades[id]], Color(0.55, 1.0, 0.5))
	Audio.recruit()
	upgrade_bought.emit(id, upgrades[id])


# ------------------------------------------------------------ obra (Bloco 31)
func obra_pending() -> bool:
	return pending_upgrade != ""


func obra_title() -> String:
	if pending_upgrade == "expandir":
		return "Expandir vila → %s" % stage_name(level + 1)
	return "%s %d" % [UPGRADE_NAMES.get(pending_upgrade, "melhoria"), upgrades.get(pending_upgrade, 0) + 1]


func obra_progress() -> float:
	return clampf(1.0 - upgrade_left / upgrade_total, 0.0, 1.0) if upgrade_total > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return global_position + Vector2(0, 40) + _obra.offset_for(worker)


## O engenheiro trabalhou `seconds` na melhoria: só assim ela anda.
func obra_work(seconds: float) -> void:
	if pending_upgrade == "":
		return
	upgrade_left -= seconds
	if upgrade_left <= 0.0:
		_finish_upgrade()
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


## "Trilhas batidas 2: 40% — esperando engenheiro" (pra UI).
func obra_status() -> String:
	return "%s: %s" % [obra_title(), _obra.status(obra_progress())] if obra_pending() else ""


## Texto do efeito atual e do próximo nível (pra UI).
func upgrade_effect_text(id: String, lvl: int) -> String:
	match id:
		"moradias":
			return "limite %d ipezinhos" % (_base_max_workers() + workers_per_moradia * lvl)
		"enfermaria":
			var mult := maxf(0.1, 1.0 - recovery_cut_per_level * lvl)
			var inf := get_tree().get_first_node_in_group("enfermarias")
			if inf == null:
				return "cura em %ds" % roundi(_base_recovery_time() * mult)
			return "%d leitos, cura %ds/%ds" % [inf.base_beds + inf.beds_per_level * lvl,
				roundi(inf.heal_time_leve * mult), roundi(inf.heal_time_grave * mult)]
		"trilhas":
			return "velocidade +%d%%" % roundi(speed_bonus_per_level * lvl * 100.0)
	return ""


func upgrade_description(id: String) -> String:
	match id:
		"moradias":
			return "+%d no limite de ipezinhos e uma casa nova (4 camas) — você escolhe onde. Custa madeira e pedra." % workers_per_moradia
		"enfermaria":
			return "+1 leito na Enfermaria e cura %d%% mais rápida por nível. Machucado só se cura lá." % roundi(recovery_cut_per_level * 100.0)
		"trilhas":
			return "Todos os ipezinhos andam %d%% mais rápido por nível." % roundi(speed_bonus_per_level * 100.0)
	return ""


func _apply_upgrade(_id: String) -> void:
	pass  # Moradias é aplicada em _confirm_house (depois de escolher o lugar)


# ------------------------------------------------------------ casas posicionadas
func _start_house_placement() -> bool:
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		push_warning("Centro da Vila: sem HousePlacer na cena")
		return false
	placer.begin(_confirm_house)
	return true


## HousePlacer chama quando o jogador clica num lugar válido. Só aqui a Moradias é paga.
func _confirm_house(pos: Vector2) -> bool:
	if upgrade_block_reason("moradias") != "":  # recursos podem ter mudado enquanto escolhia
		Audio.error()
		return false
	var cost := upgrade_cost("moradias")
	if not _economy().spend(cost.x, cost.y, upgrade_ore_type("moradias"), upgrade_wood("moradias")):
		return false
	# Bloco 31: o nível sobe já (o preço da próxima casa não repete), mas a casa nasce
	# como CANTEIRO e o +limite de ipezinhos só entra quando ela fica pronta.
	var build_seconds := build_time("moradias")
	upgrades.moradias += 1
	var casa := spawn_house(pos)
	casa.start_construction(build_seconds)
	_popup("Casa encomendada — precisa de engenheiro", Color(1.0, 0.8, 0.45))
	Audio.click()
	return true


## A casa terminou (chamado pela própria casa): agora sim entra o limite de ipezinhos.
func on_house_built(_casa: Node) -> void:
	var eco := _economy()
	if eco:
		eco.max_workers += workers_per_moradia
	_popup("Casa pronta! +%d no limite de ipezinhos" % workers_per_moradia, Color(0.55, 1.0, 0.5))
	Audio.recruit()
	upgrade_bought.emit("moradias", upgrades.moradias)


## Casas encomendadas que ainda estão em obra (não contam no limite de ipezinhos ainda).
func pending_houses() -> int:
	return get_tree().get_nodes_in_group("casas").filter(
		func(c): return c.has_method("obra_pending") and c.obra_pending()).size()


## Cria uma casa construída pelo jogador (também usado ao carregar o save).
func spawn_house(pos: Vector2, house_name: String = "", rebuild_nav: bool = true) -> Node2D:
	var casa: Node2D = CASA_SCENE.instantiate()
	casa.name = house_name if house_name != "" else _next_house_name()
	casa.position = pos
	casa.placed_by_player = true
	get_parent().add_child(casa)
	if rebuild_nav:
		var env := get_tree().get_first_node_in_group("environment")
		if env:
			env.rebuild_navigation()
	return casa


func _next_house_name() -> String:
	var n := 1
	while get_parent().has_node("CasaNova%d" % n):
		n += 1
	return "CasaNova%d" % n


# ------------------------------------------------------------ internos
func _economy() -> Node:
	return get_tree().get_first_node_in_group("economy")


## Limite de ipezinhos sem as Moradias (pra mostrar o efeito na UI).
func _base_max_workers() -> int:
	var eco := _economy()
	var current: int = eco.max_workers if eco else 0
	return current - workers_per_moradia * (upgrades.moradias - pending_houses())


func _base_recovery_time() -> float:
	var w := get_tree().get_first_node_in_group("ipezinhos")
	return w.recovery_time if w else 30.0


func _update_visual() -> void:
	# quadro 0: começo, 1: sino + estandartes (estágio 3+), 2: lanternas + ouro (estágio 5)
	_visual.frame = 2 if level >= 5 else (1 if level >= 3 else 0)
	_name_label.text = "Centro da Vila\n%s" % stage_name()
	if obra_pending():
		_name_label.text += "\nobra: " + obra_status()


func _popup(text: String, color: Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", 14)
	# empilha se já houver outro aviso subindo (ex.: expandir + melhorar em seguida)
	var stacked := get_children().filter(func(c): return c.has_meta("popup")).size()
	popup.set_meta("popup", true)
	popup.position = Vector2(-100, -150 - stacked * 20)
	popup.size = Vector2(200, 20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 1.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.8)
	tween.chain().tween_callback(popup.queue_free)
	var bump := create_tween()
	bump.tween_property(_visual, "scale", Vector2(2.1, 1.9), 0.08)
	bump.tween_property(_visual, "scale", Vector2(2, 2), 0.14)


# ------------------------------------------------------------ save/load (SaveManager)
## O efeito das melhorias NÃO é reaplicado aqui: max_workers vem salvo na
## economia e as casas construídas vêm salvas em cada casa.
func get_save_data() -> Dictionary:
	return {"level": level, "upgrades": upgrades.duplicate(), "pending_upgrade": pending_upgrade,
		"upgrade_left": upgrade_left, "upgrade_total": upgrade_total, "obra": _obra.get_save_data()}


func load_save_data(d: Dictionary) -> void:
	level = clampi(SaveUtil.integer(d, "level", level), 1, max_level())
	var saved := SaveUtil.dict(d, "upgrades")
	for id in UPGRADE_IDS:
		upgrades[id] = clampi(SaveUtil.integer(saved, id, upgrades[id]), 0, upgrade_max(id))
	# Bloco 31 (save antigo: nenhuma obra pendente)
	var p := SaveUtil.text(d, "pending_upgrade", "")
	pending_upgrade = p if (p in UPGRADE_IDS and p != "moradias" and upgrades[p] < upgrade_max(p)) \
		or (p == "expandir" and level < max_level()) else ""
	upgrade_total = maxf(SaveUtil.num(d, "upgrade_total", 0.0), 0.0) if pending_upgrade != "" else 0.0
	upgrade_left = clampf(SaveUtil.num(d, "upgrade_left", upgrade_total), 0.0, upgrade_total)
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	_update_visual()
	_refresh_galleries(false)  # Bloco 33: galerias batem com o estágio carregado
