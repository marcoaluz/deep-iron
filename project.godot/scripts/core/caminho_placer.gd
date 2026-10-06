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

signal finished

var active := false
var tipo := ""
var arrastando := false
## Quantas células este modo já pintou/apagou e o último motivo de não conseguir ("" = tudo certo).
var feitas := 0
var reason := ""
var _ultimo := Vector2.INF
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
	_hint.add_theme_font_size_override("font_size", 15)
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


func cancel() -> void:
	if not active:
		return
	active = false
	arrastando = false
	_hint_layer.visible = false
	Audio.click()
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		if arrastando:
			pinta_ate(_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			arrastando = true
			_ultimo = Vector2.INF
			pinta_ate(_to_world(event.position))
		else:
			arrastando = false
			_ultimo = Vector2.INF
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			cancel()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancel()


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
	txt += "  •  %d célula%s  •  arraste pra %s, Esc / botão direito termina" % [feitas, "s" if feitas != 1 else "",
		"apagar" if tipo == "apagar" else "pintar"]
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
