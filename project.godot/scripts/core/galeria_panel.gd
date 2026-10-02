extends PanelContainer
## Bloco 60: JANELA DA GALERIA LACRADA (clique no entulho). Diz quando ela abre sozinha (estágio da
## vila) e, com a pesquisa Explosivos controlados, deixa fazer DINAMITE e explodir o entulho antes:
## um ipezinho leva a carga até lá (minerador sabe mexer: risco baixo; outro: risco maior).
## Interface das janelas do HUD: setup(hud, alvo, economia), refresh(), focus(no), button_text(),
## has_available_action().

var _hud: Node
var _res: Node
var _galeria: Node = null
var _titulo: Label
var _info: Label
var _motivo: Label
var _fazer: Button
var _explodir: Button


func setup(hud: Node, _target: Node, _economy: Node) -> void:
	_hud = hud
	visible = false
	add_theme_stylebox_override("panel", _hud._panel_style())
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(400, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_titulo = _hud._label("GALERIA LACRADA", 20, _hud.COLOR_TITLE)
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_titulo)
	var x: Button = _hud._button("X")
	x.pressed.connect(func():
		Audio.click()
		visible = false)
	head.add_child(x)
	_info = _hud._label("", 13, _hud.COLOR_TEXT)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size.x = 360
	v.add_child(_info)
	_motivo = _hud._label("", 12, _hud.COLOR_HUNGER_BAD)
	_motivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_motivo.custom_minimum_size.x = 360
	v.add_child(_motivo)
	_fazer = _hud._button("")
	_fazer.pressed.connect(func():
		Audio.click()
		if not _r().craft_dynamite():
			Audio.error()
		refresh())
	v.add_child(_fazer)
	_explodir = _hud._button("")
	_explodir.pressed.connect(func():
		Audio.click()
		if _galeria and _r().start_blast(_galeria):
			visible = false
		else:
			Audio.error()
		refresh())
	v.add_child(_explodir)


func _r() -> Node:
	if _res == null or not is_instance_valid(_res):
		_res = get_tree().get_first_node_in_group("research")
	return _res


func focus(node: Node) -> void:
	if node != null and node.is_in_group("minerios"):
		_galeria = node


func refresh() -> void:
	if not visible:
		return
	var r := _r()
	if _galeria == null or not is_instance_valid(_galeria) or r == null:
		visible = false
		return
	var hub := get_tree().get_first_node_in_group("village_hub")
	var g = _galeria
	_titulo.text = "GALERIA %s" % String(g.gallery_name).to_upper() if g.gallery_name != "" else "GALERIA LACRADA"
	if not g.is_sealed():
		_info.text = "Aberta."
		_motivo.text = ""
		_fazer.visible = false
		_explodir.visible = false
		return
	_info.text = "Entulho com tábuas em X tapa a galeria (%s). Abre sozinha quando a vila chegar no estágio: %s.\nDinamite na vila: %d" % [
		g.ore_type, hub.stage_name(g.min_village_level) if hub else "?", r.dynamite]
	var rf: String = r.craft_dynamite_reason()
	_fazer.visible = true
	_fazer.text = ("Fazer dinamite  (%s)" % r.dynamite_cost_text()) if rf == "" else "Fazer dinamite: %s" % rf
	_fazer.disabled = rf != ""
	var rb: String = r.blast_reason(g)
	_explodir.visible = true
	_explodir.text = "Explodir o entulho (gasta 1 dinamite)" if rb == "" else "Explodir: %s" % rb
	_explodir.disabled = rb != ""
	_motivo.text = "Risco de acidente: %d%% com minerador, %d%% com outro ipezinho." % [
		roundi(r.dynamite_risk_miner * 100.0), roundi(r.dynamite_risk_untrained * 100.0)]


func button_text() -> String:
	return "Galeria"


func has_available_action() -> bool:
	return false
