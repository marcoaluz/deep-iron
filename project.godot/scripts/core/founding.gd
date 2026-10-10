extends Node
## Bloco 37: FUNDAÇÃO da vila (partida nova; grupo "founding"). Criado pelo main.gd.
##
## 1. O jogador escolhe onde fica o CENTRO DA VILA (o fantasma começa no meio da mina).
## 2. Depois escolhe onde fica o ARMAZÉM.
## Os dois são na hora e sem custo (é a fundação) e não dá pra cancelar. No fim entra o
## pacote inicial (centro_vila: founding_*), que dá pras casas iniciais e um comedouro —
## esses o engenheiro constrói, como toda obra (Bloco 31).
##
## As 3 casas e o comedouro que a cena traz (layout antigo) somem ao começar: numa
## partida nova é o jogador quem constrói os dele. Save antigo não passa por aqui.
##
## Bloco 74 (maquete v3): o armazém é da MINA (fica na frente da boca, onde o vagonete descarrega):
## no mapa novo a fundação escolhe só o Centro da Vila, dentro da vila.

signal done

const HUB_TEXTURE := preload("res://assets/game/centro_vila.png")
const ARMAZEM_TEXTURE := preload("res://assets/game/armazem.png")
## (do tamanho do MAIOR estágio do prédio — Bloco 38 — pra ele poder crescer sem invadir nada)
const HUB_FOOTPRINT := Rect2(-90, -152, 180, 166)
const ARMAZEM_FOOTPRINT := Rect2(-40, -70, 80, 86)

var step := ""  # "hub" -> "armazem" -> "done"
## Bloco 101: a partida nova começa com esta população (os da cena contam), metade homens e metade mulheres, todos sem
## função. Acabou o "Recrutar": depois disso a vila cresce com os migrantes.
@export var populacao_inicial: int = 10
var _fresh := false


func _ready() -> void:
	add_to_group("founding")


func _hub() -> Node2D:
	return get_tree().get_first_node_in_group("village_hub")


func _armazem() -> Node2D:
	return get_tree().get_first_node_in_group("armazens")


func _placer() -> Node:
	return get_tree().get_first_node_in_group("house_placer")


## Começa a fundação. fresh = partida nova (tira as casas/comedouro da cena e zera as
## casas iniciais); false = save salvo no meio da fundação (só volta a escolher).
func start(fresh: bool = true) -> void:
	var hub := _hub()
	if hub == null or _placer() == null:
		return
	_fresh = fresh
	if fresh:
		prepara()
	hub.founded = false
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.rebuild_navigation()
	_place_hub()


## A pedreira vazia de uma partida nova: sem o Centro, as casas, a cozinha e a horta do layout da cena (o jogador ergue
## os dele). Bloco 112: a introdução chama isto ANTES dos quadros no mapa (a câmera passa por uma pedreira vazia).
func prepara() -> void:
	var hub := _hub()
	if hub:
		hub.founded = false
		hub.visible = false
		hub.starter_houses_left = hub.starter_houses
	for casa in get_tree().get_nodes_in_group("casas"):
		if not casa.placed_by_player:
			_remove(casa)
	for c in get_tree().get_nodes_in_group("comedouros"):
		_remove(c)
	for h in get_tree().get_nodes_in_group("hortas") + get_tree().get_nodes_in_group("estufas"):
		_remove(h)  # Bloco 107: a horta da clareira sai: o jogador constrói a dele DENTRO da vila (o pacote paga)


func _remove(n: Node) -> void:
	n.get_parent().remove_child(n)  # sai dos grupos já (o nome fica livre pro save)
	n.queue_free()


func _map_center() -> Vector2:
	var env := get_tree().get_first_node_in_group("environment")
	if env and _armazem_fixo():  # Bloco 74: o meio da vila (a praça)
		var v: Array = env.areas.get("vila", [])
		if v.size() == 2:
			return Vector2((float(v[0]) + float(v[1])) * 0.5 - 90.0, -140.0)
	return env.walkable_rect().get_center() + Vector2(0, 60) if env else Vector2.ZERO


## Bloco 74: mapa da maquete v3 — o armazém já está no lugar dele (na frente da mina).
func _armazem_fixo() -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	return env != null and env.has_method("vertical_palisade") and env.vertical_palisade()


func _place_hub() -> void:
	step = "hub"
	var hub := _hub()
	hub.visible = false
	var start := _map_center()
	var cam := get_tree().get_first_node_in_group("game_main").get_node_or_null("Camera2D")
	if cam and cam.has_method("focus_on"):
		cam.focus_on(start)
	_placer().begin(_confirm_hub, HUB_TEXTURE, 5, "o CENTRO DA VILA (fundação)" if _armazem_fixo() else "o CENTRO DA VILA (fundação 1/2)", {
		"footprint": HUB_FOOTPRINT, "ignore": [hub, _armazem()], "cancelable": false, "start": start})
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("FUNDE SUA VILA", "Escolha onde fica o Centro da Vila. As casas vão ficar em volta dele.")


func _confirm_hub(pos: Vector2) -> bool:
	var hub := _hub()
	hub.global_position = pos
	hub.visible = true
	var v := hub.get_node_or_null("Visual") as Sprite2D
	if v:
		v.scale = Vector2(2.0, 0.2)
		hub.create_tween().tween_property(v, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.forge(pos)
	_refresh_world()
	if _armazem_fixo():
		_finish.call_deferred()  # Bloco 74: o armazém é o da mina
	else:
		_place_armazem.call_deferred()  # o posicionador termina esta rodada antes de abrir a próxima
	return true


func _place_armazem() -> void:
	step = "armazem"
	var arm := _armazem()
	arm.visible = false
	_placer().begin(_confirm_armazem, ARMAZEM_TEXTURE, 1, "o ARMAZÉM (fundação 2/2)", {
		"footprint": ARMAZEM_FOOTPRINT, "ignore": [arm], "cancelable": false,
		"start": _hub().global_position + Vector2(150, 30)})


func _confirm_armazem(pos: Vector2) -> bool:
	var arm := _armazem()
	arm.global_position = pos
	arm.visible = true
	Audio.forge(pos)
	_refresh_world()
	_finish.call_deferred()
	return true


## Bloco 101: completa a população inicial (metade de cada), todos sem função, na frente do Centro da Vila.
func completa_populacao() -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return
	var ws := get_tree().get_nodes_in_group("ipezinhos")
	var homens := ws.filter(func(w): return w.get("gender") == "menino").size()
	var mulheres := ws.size() - homens
	var meta_mulheres := populacao_inicial / 2
	var meta_homens := populacao_inicial - meta_mulheres
	while ws.size() < populacao_inicial:
		# alterna (o que tem menos vem primeiro) até cada lado chegar na metade
		var falta_h := homens < meta_homens
		var falta_m := mulheres < meta_mulheres
		var g := "menino" if falta_h and (homens <= mulheres or not falta_m) else "menina"
		var w: Node2D = eco.novo_ipezinho(g)
		if w == null:
			break
		if g == "menino":
			homens += 1
		else:
			mulheres += 1
		ws.append(w)
	for w in ws:
		if w.has_method("set_job"):
			w.set_job("ocioso")


func _finish() -> void:
	step = "done"
	var hub := _hub()
	hub.founded = true
	var eco := get_tree().get_first_node_in_group("economy")
	var arm := _armazem()
	var dif := get_tree().get_first_node_in_group("dificuldade")  # Bloco 113: o Criativo traz um pacote maior
	var pacote: float = dif.recursos_pacote_mult() if dif else 1.0
	var extras: int = dif.creditos_extras() if dif else 0
	if eco:
		eco.credits += roundi(hub.founding_credits * pacote) + extras
		eco.credits_changed.emit(eco.credits)
	if arm:
		arm.stock[hub.house_stone_ore] = arm.stock.get(hub.house_stone_ore, 0.0) + hub.founding_ore * pacote
		arm.wood_stored += hub.founding_wood * pacote
		arm._recount()
	if _fresh:
		completa_populacao()
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.wake_decision()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("VILA FUNDADA!",
			"Você tem recurso pra %d casas, 1 cozinha e 1 horta. Faça um engenheiro (tecla 4) e construa pelo menu CONSTRUIR (espaço)." % hub.starter_houses_left)
	done.emit()


func _refresh_world() -> void:
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
