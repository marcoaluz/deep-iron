extends Node2D
## Bloco 77: a ferramenta de marcar ÁREA DE TRABALHO (grupo "area_placer"), criada pelo main.gd depois do
## house_placer (recebe o input antes do main e o consome).
##
## begin(tipo) liga o modo:
##   arrastar com o botão esquerdo -> marca o retângulo no chão (na lógica: na vista iso ele aparece como o
##                                    losango do terreno); soltar cria a área (work_areas.criar) e abre a
##                                    janela dos trabalhadores nela
##   Esc ou botão direito          -> cancela
## A roda do mouse e WASD continuam movendo a câmera enquanto isso. O desenho (verde/vermelho) é da vista
## iso (iso_view.gd: _draw_areas); na vista de cima (testes) é este nó que desenha.

signal finished(area)

var active := false
var tipo := ""
var arrastando := false
var reason := ""  # por que o retângulo atual não vale ("" = vale)
var _a := Vector2.ZERO
var _b := Vector2.ZERO
var _hint_layer: CanvasLayer
var _hint: Label


func _ready() -> void:
	add_to_group("area_placer")
	z_index = 60
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 5
	add_child(_hint_layer)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.offset_top = 58.0  # abaixo da barra de cima
	_hint.offset_left = 220.0
	_hint.offset_right = 220.0
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint_layer.add_child(_hint)
	_set_visible(false)


func _wa() -> Node:
	return get_tree().get_first_node_in_group("work_areas")


func begin(novo_tipo: String) -> void:
	var wa := _wa()
	if wa == null or not wa.TIPOS.has(novo_tipo):
		return
	tipo = novo_tipo
	active = true
	arrastando = false
	reason = ""
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("close_panels"):
		hud.close_panels()
	_refresh()
	_set_visible(true)


func cancel() -> void:
	if not active:
		return
	_end(null)
	Audio.click()


func _end(area) -> void:
	active = false
	arrastando = false
	_set_visible(false)
	finished.emit(area)


func _set_visible(on: bool) -> void:
	visible = on
	_hint_layer.visible = on
	queue_redraw()


## O retângulo marcado (na lógica).
func rect() -> Rect2:
	return Rect2(_a, _b - _a).abs()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		if arrastando:
			_b = _to_world(event.position)
			_refresh()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			_a = _to_world(event.position)
			_b = _a
			arrastando = true
			_refresh()
		elif arrastando:
			_b = _to_world(event.position)
			arrastando = false
			try_confirm()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			cancel()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancel()


## Marca o retângulo entre dois pontos do chão (usado pelos testes e pelo mouse).
func drag(from: Vector2, to: Vector2) -> void:
	_a = from
	_b = to
	_refresh()


## Cria a área com o retângulo atual. Devolve a área (ou null, com o motivo em `reason`).
func try_confirm():
	if not active:
		return null
	var wa := _wa()
	reason = wa.motivo_invalido(tipo, rect()) if wa else "sem sistema de áreas"
	if reason != "":
		Audio.error()
		_refresh()
		return null
	var area = wa.criar(tipo, rect())
	Audio.place_sound()
	_end(area)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_panel"):
		hud.open_panel("trabalho", null)
		var panel = hud.get("_panels").get("trabalho") if hud.get("_panels") is Dictionary else null
		if panel and panel.has_method("focus_area"):
			panel.focus_area(area)
	return area


func _refresh() -> void:
	var wa := _wa()
	var info: Dictionary = wa.TIPOS.get(tipo, {}) if wa else {}
	if arrastando:
		reason = wa.motivo_invalido(tipo, rect()) if wa else ""
	var txt := "Arraste no mapa pra marcar a área de %s  •  Esc / botão direito cancela" % str(info.get("nome", "trabalho")).to_lower()
	if reason != "":
		txt += "\n" + reason
	_hint.text = txt
	_hint.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if reason != "" else Color(1.0, 0.92, 0.7))
	queue_redraw()


func _to_world(screen_pos: Vector2) -> Vector2:
	var canvas := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and iso.enabled:
		return iso.ground_at(canvas)
	return canvas


## Vista de cima (sem a iso): o retângulo desenhado aqui mesmo.
func _draw() -> void:
	if not active or not arrastando:
		return
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and iso.enabled:
		return
	var col := Color(1.0, 0.4, 0.35) if reason != "" else Color(0.5, 1.0, 0.55)
	draw_rect(rect(), Color(col, 0.15), true)
	draw_rect(rect(), Color(col, 0.9), false, 1.5)
