extends Node2D
## Bloco 89: a ferramenta de PINTAR CAMINHOS (grupo "caminho_placer"), criada pelo main.gd junto do area_placer
## (recebe o input antes do main e o consome).
##
## begin(tipo) liga o modo ("terra", "cascalho", "pedra" ou "apagar"):
##   segurar e arrastar o botão esquerdo -> pinta (ou apaga) as células por onde o mouse passa (sem pular
##                                          célula: caminhos.celulas_na_linha), pagando cada uma
##   soltar                              -> continua no modo (dá pra pintar outro trecho)
##   Esc ou botão direito                -> termina
## A roda do mouse e WASD continuam movendo a câmera.
## Bloco 132: a mesma GRADE dos prédios (grade.gd; a célula do caminho é a célula da grade) e dois jeitos de traçar rua:
##   Shift + arrastar -> uma RETA (no eixo em que o mouse andou mais), pintada ao soltar
##   Ctrl + arrastar  -> um RETÂNGULO cheio, pintado ao soltar (até `max_retangulo` células)
## Enquanto arrasta, a prévia aparece na grade (iso_grade.gd). A rua pode passar na faixa entre prédios (só a base do
## prédio é proibida) e não conta como obstáculo pra construir (prédio por cima apaga o trecho). A tecla da Defesa (G)
## liga/desliga a grade.
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const HousePlacer := preload("res://scripts/core/house_placer.gd")

## Bloco 132: o maior retângulo de rua de uma vez (células).
@export var max_retangulo: int = 600

signal finished

var active := false
var tipo := ""
var arrastando := false
## Quantas células este modo já pintou/apagou e o último motivo de não conseguir ("" = tudo certo).
var feitas := 0
var reason := ""
var _ultimo := Vector2.INF
## Bloco 132: o traço em curso ("livre", "reta", "retangulo"), de onde começou e as células da prévia (Array[Vector2i]).
var modo := "livre"
var _inicio := Vector2.INF
var previa: Array[Vector2i] = []
var _hint_layer: CanvasLayer
var _hint: Label


func _ready() -> void:
	add_to_group("caminho_placer")
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
	_hint.add_theme_font_size_override("font_size", Tipo.TITULO)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint_layer.add_child(_hint)
	_hint_layer.visible = false


func _cam() -> Node:
	return get_tree().get_first_node_in_group("caminhos")


func begin(novo_tipo: String) -> void:
	var cam := _cam()
	if cam == null or (novo_tipo not in cam.TIPOS and novo_tipo != "apagar"):
		return
	tipo = novo_tipo
	active = true
	arrastando = false
	feitas = 0
	reason = ""
	_ultimo = Vector2.INF
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("close_panels"):
		hud.close_panels()
	_hint_layer.visible = true
	_refresh()


## Bloco 130: o fantasma do pincel — o ladrilho do tipo (a mesma arte do jogo) na célula do mouse, verde se dá e vermelho
## se não, com o custo (ou o que falta) escrito.
func _fantasma(p: Vector2) -> void:
	var cam := _cam()
	var iso := get_tree().get_first_node_in_group("iso_view")
	if cam == null or iso == null or not iso.enabled or not iso.has_method("pisos_fantasma"):
		return
	var c: Vector2i = cam.celula_de(p)
	var motivo: String = cam.motivo_celula(c, tipo)
	var texto := ""
	if tipo == "apagar":
		texto = "apagar (não devolve)" if motivo == "" else motivo
	else:
		texto = cam.custo_texto(tipo) if motivo == "" else motivo
	iso.pisos_fantasma(cam, c, "terra" if tipo == "apagar" else tipo, motivo == "", texto)


func _sem_fantasma() -> void:
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and iso.has_method("pisos_sem_fantasma"):
		iso.pisos_sem_fantasma()


func cancel() -> void:
	if not active:
		return
	active = false
	arrastando = false
	_sem_fantasma()
	_hint_layer.visible = false
	Audio.click()
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		_fantasma(_to_world(event.position))  # Bloco 130: o ladrilho de verdade na célula do mouse
		if arrastando and modo == "livre":
			pinta_ate(_to_world(event.position))
		elif arrastando:
			_atualiza_previa(_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			arrastando = true
			_ultimo = Vector2.INF
			_inicio = _to_world(event.position)
			modo = "retangulo" if event.ctrl_pressed else ("reta" if event.shift_pressed else "livre")
			if modo == "livre":
				pinta_ate(_inicio)
			else:
				_atualiza_previa(_inicio)
		else:
			if arrastando and modo != "livre":
				pinta_celulas(previa)
			arrastando = false
			_ultimo = Vector2.INF
			previa = []
			modo = "livre"
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == Teclas.tecla("painel_defesa"):
		get_viewport().set_input_as_handled()  # Bloco 132: liga/desliga a grade
		HousePlacer.alterna_grade()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			cancel()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancel()


## Bloco 132: as células de uma RETA de `a` até `b` (no eixo em que andou mais, a partir da célula de `a`).
func celulas_reta(a: Vector2, b: Vector2) -> Array[Vector2i]:
	var cam := _cam()
	var out: Array[Vector2i] = []
	if cam == null:
		return out
	var ca: Vector2i = cam.celula_de(a)
	var cb: Vector2i = cam.celula_de(b)
	if absi(cb.x - ca.x) >= absi(cb.y - ca.y):
		for x in range(mini(ca.x, cb.x), maxi(ca.x, cb.x) + 1):
			out.append(Vector2i(x, ca.y))
	else:
		for y in range(mini(ca.y, cb.y), maxi(ca.y, cb.y) + 1):
			out.append(Vector2i(ca.x, y))
	return out


## Bloco 132: as células do RETÂNGULO entre `a` e `b` (cheio; vazio se passar de max_retangulo).
func celulas_retangulo(a: Vector2, b: Vector2) -> Array[Vector2i]:
	var cam := _cam()
	var out: Array[Vector2i] = []
	if cam == null:
		return out
	var ca: Vector2i = cam.celula_de(a)
	var cb: Vector2i = cam.celula_de(b)
	var r := Rect2i(Vector2i(mini(ca.x, cb.x), mini(ca.y, cb.y)), (ca - cb).abs() + Vector2i.ONE)
	if r.get_area() > max_retangulo:
		return out
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(Vector2i(x, y))
	return out


func _atualiza_previa(p: Vector2) -> void:
	previa = celulas_reta(_inicio, p) if modo == "reta" else celulas_retangulo(_inicio, p)
	reason = "" if not previa.is_empty() else "retângulo grande demais (até %d células)" % max_retangulo
	_refresh()


## Bloco 132: pinta (ou apaga) uma lista de células de uma vez (a reta e o retângulo). Devolve quantas.
func pinta_celulas(cs: Array) -> int:
	var cam := _cam()
	if cam == null:
		return 0
	var n := 0
	reason = ""
	for c in cs:
		if tipo == "apagar":
			if cam.apagar(c):
				n += 1
		elif cam.pintar(c, tipo):
			n += 1
		elif cam.celulas.get(c, "") != tipo and reason == "":
			reason = cam.motivo_celula(c, tipo)
	if n > 0:
		feitas += n
		Audio.place_sound()
	_refresh()
	return n


## Pinta/apaga do último ponto até `p` (no chão). Usado pelo mouse e pelos testes.
func pinta_ate(p: Vector2) -> int:
	var cam := _cam()
	if cam == null:
		return 0
	var de := p if _ultimo == Vector2.INF else _ultimo
	_ultimo = p
	var n := 0
	for c in cam.celulas_na_linha(de, p):
		if tipo == "apagar":
			if cam.apagar(c):
				n += 1
		elif cam.pintar(c, tipo):
			n += 1
		elif cam.celulas.get(c, "") != tipo:
			reason = cam.motivo_pintar(tipo)
			if reason == "":
				reason = "aí não dá (prédio ou fora do mapa)"
	if n > 0:
		feitas += n
		reason = ""
		Audio.place_sound()
	_refresh()
	return n


func _refresh() -> void:
	var cam := _cam()
	if cam == null:
		return
	var txt := "Apagando caminhos (sem devolução)" if tipo == "apagar" else "Caminho de %s: %s por célula" % [
		cam.NOMES.get(tipo, tipo).to_lower(), cam.custo_texto(tipo)]
	txt += "  •  %d célula%s  •  arraste pra %s (Shift: reta, Ctrl: retângulo), Esc / botão direito termina" % [feitas,
		"s" if feitas != 1 else "", "apagar" if tipo == "apagar" else "pintar"]
	if arrastando and modo != "livre":
		txt += "\n%s: %d célula%s (solte pra %s)" % ["Reta" if modo == "reta" else "Retângulo", previa.size(),
			"s" if previa.size() != 1 else "", "apagar" if tipo == "apagar" else "pintar"]
	if reason != "":
		txt += "\n" + reason
	_hint.text = txt
	_hint.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if reason != "" else Color(1.0, 0.92, 0.7))


func _to_world(screen_pos: Vector2) -> Vector2:
	var canvas := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and iso.enabled:
		return iso.ground_at(canvas)
	return canvas
