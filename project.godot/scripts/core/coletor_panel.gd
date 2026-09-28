extends PanelContainer
## Janela do Coletor de madeira (Bloco 45): construir, quem opera, quanto produz.
## Abre clicando na máquina ou pelo botão no painel do HUD.

var _hud: CanvasLayer
var _hub: Node
var _economy: Node
var _status: Label
var _build_button: Button
var _designate_button: Button
var _release_button: Button


func setup(hud: CanvasLayer, hub: Node, economy: Node) -> void:
	_hud = hud
	_hub = hub
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(420, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("COLETOR DE MADEIRA", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var intro: Label = _hud._label("Serraria a vapor na clareira. Um LENHADOR opera e ela manda madeira sozinha pro armazém. O lenhador manual continua cortando árvore em paralelo.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_status = _hud._label("", 13, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)
	_build_button = _hud._button("")
	_build_button.pressed.connect(func():
		Audio.click()
		_hub.build_coletor()
		refresh())
	vbox.add_child(_build_button)
	_designate_button = _hud._button("")
	_designate_button.pressed.connect(func():
		Audio.click()
		var w := _pick_lumber()
		var c: Node = _hub.coletor()
		if c and w:
			c.designate(w)
		else:
			Audio.error()
		refresh())
	vbox.add_child(_designate_button)
	_release_button = _hud._button("Liberar o operador (a máquina para)")
	_release_button.pressed.connect(func():
		Audio.click()
		var c: Node = _hub.coletor()
		if c:
			c.release()
		refresh())
	vbox.add_child(_release_button)


## Lenhador pra operar: o selecionado (se for lenhador); senão o lenhador mais perto da máquina.
func _pick_lumber() -> Node:
	var c: Node = _hub.coletor()
	if c == null:
		return null
	var main := get_tree().get_first_node_in_group("game_main")
	if main:
		for u in main.selection:
			if is_instance_valid(u) and u.is_lumber():
				return u
	var best: Node = null
	var best_d := INF
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if not w.is_lumber() or w.injured or w == c.operator:
			continue
		var d: float = w.global_position.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			best = w
	return best


func refresh() -> void:
	if not visible:
		return
	var c: Node = _hub.coletor()
	var reason: String = _hub.coletor_block_reason()
	_build_button.visible = c == null
	_build_button.text = ("Construir — escolher lugar na clareira  (%s)" % _hub.coletor_cost_text()) if reason == "" else "Construir: " + reason
	_build_button.disabled = reason != ""
	_designate_button.visible = c != null
	_release_button.visible = c != null and c.has_operator()
	if c == null:
		_status.text = "Ainda não construído."
		return
	_status.text = "%s\nMadeira produzida no total: %d  •  %.1f madeira/s com operador" % [c.status_text(), int(c.total_produced), c.wood_per_sec]
	var cand := _pick_lumber()
	_designate_button.text = ("Designar lenhador: %s" % cand.display_name) if cand else "Designar lenhador: nenhum disponível (tecla L faz lenhador)"
	_designate_button.disabled = cand == null


func button_text() -> String:
	var c: Node = _hub.coletor()
	if c == null:
		return "Coletor de madeira: construir"
	return "Coletor: %s" % ("produzindo" if c.get("_producing") else ("sem operador" if not c.has_operator() else "parado"))


func has_available_action() -> bool:
	var c: Node = _hub.coletor()
	return c != null and not c.has_operator()
