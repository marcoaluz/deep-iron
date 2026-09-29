extends PanelContainer
## Janela do Coletor de madeira (Bloco 45): construir, quem opera, quanto produz.
## Abre clicando na máquina ou pelo botão no painel do HUD.
## Bloco 47: pode ter vários coletores. A janela mostra o que foi CLICADO (pelo botão do HUD
## ou tecla: o primeiro); "Designar"/"Liberar" valem pra essa máquina.

var _hud: CanvasLayer
var _hub: Node
var _economy: Node
var _title: Label
var _status: Label
var _build_button: Button
var _designate_button: Button
var _release_button: Button
var _focus: Node = null


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
	_title = _hud._label("COLETOR DE MADEIRA", 20, _hud.COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
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
	_designate_button = _hud._button("")
	_designate_button.pressed.connect(func():
		Audio.click()
		var w := _pick_lumber()
		var c: Node = _current()
		if c and w:
			c.designate(w)
		else:
			Audio.error()
		refresh())
	vbox.add_child(_designate_button)
	_release_button = _hud._button("Liberar o operador (a máquina para)")
	_release_button.pressed.connect(func():
		Audio.click()
		var c: Node = _current()
		if c:
			c.release()
		refresh())
	vbox.add_child(_release_button)
	_build_button = _hud._button("")
	_build_button.pressed.connect(func():
		Audio.click()
		_hub.build_coletor()
		refresh())
	vbox.add_child(_build_button)


## Bloco 47: o HUD avisa qual máquina foi clicada (null = abriu pelo botão/tecla: a primeira).
func focus(node: Node) -> void:
	_focus = node if node != null and node.is_in_group("coletores") else null


## A máquina que a janela está mostrando.
func _current() -> Node:
	if _focus != null and is_instance_valid(_focus) and _focus.is_inside_tree():
		return _focus
	return _hub.coletor()


## Lenhador pra operar: o selecionado (se for lenhador); senão o lenhador mais perto da
## máquina que ainda não opera nenhuma (Bloco 47: pode ter várias).
func _pick_lumber() -> Node:
	var c: Node = _current()
	if c == null:
		return null
	var main := get_tree().get_first_node_in_group("game_main")
	if main:
		for u in main.selection:
			if is_instance_valid(u) and u.is_lumber():
				return u
	var busy: Array = _hub.coletores().map(func(k): return k.operator)
	var best: Node = null
	var best_d := INF
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if not w.is_lumber() or w.injured or busy.has(w):
			continue
		var d: float = w.global_position.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			best = w
	return best


func refresh() -> void:
	if not visible:
		return
	var c: Node = _current()
	var all: Array = _hub.coletores()
	var reason: String = _hub.coletor_block_reason()
	var what := "Construir" if all.is_empty() else "Construir outro coletor"
	_build_button.text = ("%s — escolher lugar na clareira  (%s)" % [what, _hub.coletor_cost_text()]) if reason == "" else "%s: %s" % [what, reason]
	_build_button.disabled = reason != ""
	_designate_button.visible = c != null
	_release_button.visible = c != null and c.has_operator()
	_title.text = "COLETOR DE MADEIRA" if all.size() <= 1 or c == null else "COLETOR DE MADEIRA %d de %d" % [all.find(c) + 1, all.size()]
	if c == null:
		_status.text = "Ainda não construído."
		return
	_status.text = "%s\nMadeira produzida no total: %d  •  %.1f madeira/s com operador" % [c.status_text(), int(c.total_produced), c.wood_per_sec]
	if all.size() > 1:
		var on := all.filter(func(k): return k.get("_producing")).size()
		_status.text += "\nNa vila: %d coletores, %d produzindo (cada um tem o seu operador; clique na máquina pra ver ela)." % [all.size(), on]
	var cand := _pick_lumber()
	_designate_button.text = ("Designar lenhador: %s" % cand.display_name) if cand else "Designar lenhador: nenhum disponível (tecla L faz lenhador)"
	_designate_button.disabled = cand == null


func button_text() -> String:
	var all: Array = _hub.coletores()
	if all.is_empty():
		return "Coletor de madeira: construir"
	if all.size() > 1:
		return "Coletores: %d/%d produzindo" % [all.filter(func(k): return k.get("_producing")).size(), all.size()]
	var c: Node = all[0]
	return "Coletor: %s" % ("produzindo" if c.get("_producing") else ("sem operador" if not c.has_operator() else "parado"))


func has_available_action() -> bool:
	return _hub.coletores().any(func(k): return not k.has_operator())
