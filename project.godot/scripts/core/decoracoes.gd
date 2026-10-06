extends Node2D
## Bloco 90: o GERENCIADOR DA DECORAÇÃO construída pelo jogador (nó "Decoracoes", criado pelo main.gd depois dos
## posicionadores — recebe o input antes deles; grupo "decoracoes_mgr").
##
## - Colocar: comecar(id) abre o house_placer com a pegada da peça e repeat = true (dá pra pôr VÁRIAS em
##   sequência; Esc / botão direito termina). Construção INSTANTÂNEA, sem engenheiro, pagando o custo.
## - Remover: comecar_remover() — clicar numa peça tira ela e devolve `reembolso` do custo. Esc / direito sai.
## - Luz: tochas e lampiões acendem com o torch_level do DayNight (as luzes estão em cullable_lights); um
##   Lumívoro que chega numa luz apaga ela até o amanhecer. Os Lumívoros preferem lugares iluminados
##   (creature.gd: atracao_luz).
## - Bancos e mesas viram pontos sociais (Bloco 85).
## - Beleza: decoração a até `beleza_raio` de uma casa dá aos moradores o fator "casa enfeitada" (soma da
##   beleza das peças, até `beleza_teto`).
## - Navegação: só peças grandes entram (decor_obstaculos) e o rebuild_navigation é AGRUPADO: espera
##   `nav_espera` segundos depois da última peça (pôr muita coisa não trava).
## - As tochas sorteadas pelo environment.gd (seed) não mudam: estas são outra lista, com save próprio.

const Decor := preload("res://scripts/props/decoracao.gd")
const Catalogo := preload("res://scripts/core/decor.gd")

## Fração do custo devolvida ao remover uma peça.
@export_range(0.0, 1.0, 0.05) var reembolso: float = 0.5
## Distância (px do chão) em que a decoração enfeita uma casa.
@export var beleza_raio: float = 110.0
## Teto do ânimo de "casa enfeitada".
@export var beleza_teto: float = 6.0
## Segundos sem pôr/tirar peça grande até refazer a navegação (uma vez só pra várias).
@export var nav_espera: float = 0.6

var removendo := false
var _nav_t := -1.0
var _beleza_cache := {}  # casa -> beleza (refeito quando a decoração muda)
var _beleza_versao := 0
var _beleza_feita := -1
var _id_colocando := ""
var _hint_layer: CanvasLayer
var _hint: Label
var _luz_t := 0.0


func _ready() -> void:
	add_to_group("decoracoes_mgr")
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 5
	add_child(_hint_layer)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.offset_top = 58.0
	_hint.offset_left = 240.0
	_hint.offset_right = 240.0
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint_layer.add_child(_hint)
	_hint_layer.visible = false


func pecas() -> Array:
	return get_tree().get_nodes_in_group("decoracoes")


# ------------------------------------------------------------ colocar
func motivo(id: String) -> String:
	if not Catalogo.existe(id):
		return "peça desconhecida"
	var eco := get_tree().get_first_node_in_group("economy")
	var c := Catalogo.custo(id)
	return eco.missing_text(c.x, c.y, "ferro", c.z) if eco else ""


func custo_texto(id: String) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.cost_text(Catalogo.custo(id), "ferro") if eco else ""


## Abre o posicionador pra pôr várias peças `id` em sequência.
func comecar(id: String) -> bool:
	if motivo(id) != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	sair_remover()
	_id_colocando = id
	var p := Catalogo.pegada(id)
	placer.begin(_confirma, load(Catalogo.info(id).textura), 1, Catalogo.nome(id).to_lower(),
		{"footprint": Rect2(-p * 0.5, p), "repeat": true, "check": func(_pos): return motivo(id)})
	return true


func _confirma(pos: Vector2) -> bool:
	return colocar(_id_colocando, pos) != null


## Põe uma peça agora (paga; sem engenheiro). null = sem recursos.
func colocar(id: String, pos: Vector2) -> Node2D:
	if motivo(id) != "":
		Audio.error()
		return null
	var c := Catalogo.custo(id)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and not eco.spend(c.x, c.y, "ferro", c.z):
		return null
	return _cria(id, pos)


func _cria(id: String, pos: Vector2) -> Node2D:
	var n: Node2D = Decor.new()
	n.monta(id)
	n.name = "Decor_%s" % id
	n.position = pos
	var hub := get_tree().get_first_node_in_group("village_hub")
	(hub.get_parent() if hub else get_parent()).add_child(n, true)
	_mudou(Catalogo.e_obstaculo(id))
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn:
		n.acende(dn.torch_level())
	return n


## Tira uma peça e devolve `reembolso` do custo.
func remover(n: Node) -> bool:
	if n == null or not is_instance_valid(n) or not n.is_in_group("decoracoes"):
		return false
	var c := Catalogo.custo(n.id)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco:
		eco._add_credits(floorf(c.x * reembolso))
		var arm := get_tree().get_first_node_in_group("armazens")
		if arm:
			if c.y > 0:
				arm.add_ore(floorf(c.y * reembolso), "ferro")
			arm.wood_stored += floorf(c.z * reembolso)
			arm._update_label()
	var grande: bool = Catalogo.e_obstaculo(n.id)
	n.get_parent().remove_child(n)
	n.queue_free()
	_mudou(grande)
	Audio.click()
	return true


# ------------------------------------------------------------ modo remover
func comecar_remover() -> void:
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer and placer.active:
		placer.cancel()
	removendo = true
	_hint_layer.visible = true
	_hint.text = "Clique numa decoração pra tirar (devolve %d%% do custo)  •  Esc / botão direito sai" % roundi(reembolso * 100.0)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))


func sair_remover() -> void:
	removendo = false
	_hint_layer.visible = false


## A peça mais perto de `p` (no chão), até 26 px. null = nenhuma.
func peca_em(p: Vector2) -> Node:
	var melhor: Node = null
	var d_min := 26.0
	for n in pecas():
		var d: float = n.global_position.distance_to(p)
		if d < d_min or n.pegada_rect().grow(4.0).has_point(p):
			if d < d_min:
				d_min = d
			melhor = n
	return melhor


func _unhandled_input(event: InputEvent) -> void:
	if not removendo:
		return
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			sair_remover()
			Audio.click()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if not remover(peca_em(_to_world(event.position))):
				Audio.error()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		sair_remover()


func _to_world(screen_pos: Vector2) -> Vector2:
	var canvas := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and iso.enabled:
		return iso.ground_at(canvas)
	return canvas


# ------------------------------------------------------------ luz, navegação, beleza
func _process(delta: float) -> void:
	if _nav_t > 0.0:
		_nav_t -= delta
		if _nav_t <= 0.0:
			_nav_t = -1.0
			var env := get_tree().get_first_node_in_group("environment")
			if env:
				env.rebuild_navigation()
	_luz_t -= delta
	if _luz_t <= 0.0:
		_luz_t = 0.25
		var dn := get_tree().get_first_node_in_group("day_night")
		if dn:
			var nivel: float = dn.torch_level()
			for n in get_tree().get_nodes_in_group("decor_luzes"):
				if nivel <= 0.01:
					n.apagada = false  # amanheceu: a luz que o Lumívoro comeu volta
				n.acende(nivel)


## A decoração mudou: refaz a beleza e (peça grande) agenda UM rebuild da navegação.
func _mudou(grande: bool) -> void:
	_beleza_versao += 1
	if grande:
		_nav_t = nav_espera


## Navegação esperando o agrupamento? (pros testes)
func nav_pendente() -> bool:
	return _nav_t > 0.0


## Beleza em volta de uma casa (soma das peças a até beleza_raio, até beleza_teto). Refeito só quando muda.
func beleza_da_casa(casa: Node) -> float:
	if casa == null or not is_instance_valid(casa):
		return 0.0
	if _beleza_feita != _beleza_versao:
		_beleza_feita = _beleza_versao
		_beleza_cache.clear()
	if not _beleza_cache.has(casa):
		var b := 0.0
		for n in pecas():
			if n.global_position.distance_to(casa.global_position) <= beleza_raio:
				b += float(Catalogo.info(n.id).get("beleza", 0.0))
		_beleza_cache[casa] = minf(b, beleza_teto)
	return _beleza_cache[casa]


# ------------------------------------------------------------ save (lista própria)
func get_save_data() -> Dictionary:
	return {"pecas": pecas().map(func(n): return [n.id, snappedf(n.global_position.x, 0.1), snappedf(n.global_position.y, 0.1)])}


## Save antigo: sem decoração. Peça de id que não existe mais é ignorada.
func load_save_data(d: Dictionary) -> void:
	for n in pecas():
		n.get_parent().remove_child(n)
		n.queue_free()
	var grande := false
	for p in d.get("pecas", []):
		if p is Array and p.size() == 3 and Catalogo.existe(String(p[0])):
			_cria(String(p[0]), Vector2(float(p[1]), float(p[2])))
			grande = grande or Catalogo.e_obstaculo(String(p[0]))
	_nav_t = nav_espera if grande else -1.0
