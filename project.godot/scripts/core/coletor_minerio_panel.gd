extends PanelContainer
## Janela do Coletor de minério (Bloco 57): construir, quem opera, de qual jazida tira, quanto
## produziu. Abre clicando na máquina ou pelo botão da coluna. Pode ter vários: mostra o clicado (pelo
## botão: o primeiro); "Designar"/"Liberar"/"Trocar jazida" valem pra essa máquina.

var _hud: CanvasLayer
var _hub: Node
var _economy: Node
var _title: Label
var _status: Label
var _build_button: Button
var _designate_button: Button
var _release_button: Button
var _jazida_button: Button
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
	_title = _hud._label("COLETOR DE MINÉRIO", 20, _hud.COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var intro: Label = _hud._label("Broca a vapor em cima de uma jazida. Um MINERADOR opera e ela manda minério sozinha pro armazém, do tipo da jazida. Os mineradores manuais continuam tirando da mesma jazida.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_status = _hud._label("", 13, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)
	_designate_button = _hud._button("")
	_designate_button.pressed.connect(func():
		Audio.click()
		var w := _pick_miner()
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
	_jazida_button = _hud._button("Trocar de jazida")
	_jazida_button.pressed.connect(func():
		Audio.click()
		var c: Node = _current()
		if c:
			c.choose_next()
		refresh())
	vbox.add_child(_jazida_button)
	_build_button = _hud._button("")
	_build_button.pressed.connect(func():
		Audio.click()
		_hub.build_coletor_minerio()
		refresh())
	vbox.add_child(_build_button)


func focus(node: Node) -> void:
	_focus = node if node != null and node.is_in_group("coletores_minerio") else null


func _current() -> Node:
	if _focus != null and is_instance_valid(_focus) and _focus.is_inside_tree():
		return _focus
	var all: Array = _hub.coletores_minerio()
	return all[0] if not all.is_empty() else null


## Minerador pra operar: o selecionado (se for minerador); senão o mais perto da máquina que ainda
## não opera nenhuma.
func _pick_miner() -> Node:
	var c: Node = _current()
	if c == null:
		return null
	var main := get_tree().get_first_node_in_group("game_main")
	if main:
		for u in main.selection:
			if is_instance_valid(u) and u.is_miner():
				return u
	var busy: Array = _hub.coletores_minerio().map(func(k): return k.operator)
	var best: Node = null
	var best_d := INF
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if not w.is_miner() or w.injured or busy.has(w):
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
	var all: Array = _hub.coletores_minerio()
	var reason: String = _hub.coletor_minerio_block_reason()
	var what := "Construir" if all.is_empty() else "Construir outro coletor"
	_build_button.text = ("%s — escolher lugar perto de uma jazida  (%s)" % [what, _hub.coletor_minerio_cost_text()]) if reason == "" else "%s: %s" % [what, reason]
	_build_button.disabled = reason != ""
	_designate_button.visible = c != null
	_release_button.visible = c != null and c.has_operator()
	_jazida_button.visible = c != null and c.jazidas_no_alcance().size() > 1
	_title.text = "COLETOR DE MINÉRIO" if all.size() <= 1 or c == null else "COLETOR DE MINÉRIO %d de %d" % [all.find(c) + 1, all.size()]
	if c == null:
		_status.text = "Ainda não construído."
		return
	var j: Node = c.jazida()
	var jtxt := "jazida: %s (%d de %d)" % [j.ore_type, int(j.ore_remaining), int(j.ore_total)] if j else "nenhuma jazida no alcance"
	_status.text = "%s\n%s\nMinério produzido no total: %d  •  %.1f/s com operador" % [c.status_text(), jtxt, int(c.total_produced), c.ore_per_sec]
	if all.size() > 1:
		var on := all.filter(func(k): return k.get("_producing")).size()
		_status.text += "\nNa vila: %d coletores de minério, %d produzindo." % [all.size(), on]
	var cand := _pick_miner()
	_designate_button.text = ("Designar minerador: %s" % cand.display_name) if cand else "Designar minerador: nenhum disponível (tecla 1 faz minerador)"
	_designate_button.disabled = cand == null


func button_text() -> String:
	var all: Array = _hub.coletores_minerio()
	if all.is_empty():
		return "Coletor de minério: construir"
	var on := all.filter(func(k): return k.get("_producing")).size()
	if all.size() > 1:
		return "Coletores de minério: %d/%d" % [on, all.size()]
	var c: Node = all[0]
	return "Coletor de minério: %s" % ("produzindo" if c.get("_producing") else ("sem operador" if not c.has_operator() else "parado"))


func has_available_action() -> bool:
	return _hub.coletores_minerio().any(func(k): return not k.has_operator())
