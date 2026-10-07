extends PanelContainer
## Bloco 56: JANELA DA CASA (clique numa casa): nível, camas, quem mora, o conforto que ela dá e a
## AMPLIAÇÃO pro nível seguinte (custo, pré-requisito e a obra do engenheiro).
## Bloco 94: as CAMAS DE TÁBUA (da Carpintaria): quantas tem, quantas esperam o carpinteiro e o botão de trocar.
## Interface das janelas do HUD: setup(hud, alvo, economia), refresh(), focus(no), button_text(),
## has_available_action().
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: Node
var _eco: Node
var _casa: Node = null
var _titulo: Label
var _info: Label
var _custo: Label
var _motivo: Label
var _botao: Button
var _camas: Label  # Bloco 94
var _cama_botao: Button


func setup(hud: Node, _target: Node, economy: Node) -> void:
	_hud = hud
	_eco = economy
	visible = false
	add_theme_stylebox_override("panel", _hud._panel_style())
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(380, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_titulo = _hud._label("CASA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_titulo)
	var x: Button = _hud._button("X")
	x.pressed.connect(func():
		Audio.click()
		visible = false)
	head.add_child(x)
	_info = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size.x = 340
	v.add_child(_info)
	# Bloco 94: camas de tábua
	_camas = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_camas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_camas.custom_minimum_size.x = 340
	v.add_child(_camas)
	_cama_botao = _hud._button("Trocar uma cama")
	_cama_botao.pressed.connect(_trocar_cama)
	v.add_child(_cama_botao)
	v.add_child(HSeparator.new())
	_custo = _hud._label("", Tipo.DETALHE, _hud.COLOR_TITLE)
	_custo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_custo.custom_minimum_size.x = 340
	v.add_child(_custo)
	_motivo = _hud._label("", Tipo.DETALHE, _hud.COLOR_HUNGER_BAD)
	_motivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_motivo.custom_minimum_size.x = 340
	v.add_child(_motivo)
	_botao = _hud._button("Ampliar")
	_botao.pressed.connect(_ampliar)
	v.add_child(_botao)


func focus(node: Node) -> void:
	if node != null and node.is_in_group("casas"):
		_casa = node
	elif _casa == null or not is_instance_valid(_casa):
		_casa = _melhor_casa()


## A casa de menor nível (a mais antiga) que ainda pode subir: o que o cartão do menu amplia.
func _melhor_casa() -> Node:
	var melhor: Node = null
	for c in get_tree().get_nodes_in_group("casas"):
		if not c.built or c.level >= c.max_level() or c.upgrade_pending():
			continue
		if melhor == null or c.level < melhor.level:
			melhor = c
	return melhor


func refresh() -> void:
	if not visible:
		return
	if _casa == null or not is_instance_valid(_casa):
		_casa = _melhor_casa()
	if _casa == null:
		_titulo.text = "CASAS"
		_info.text = "Nenhuma casa pra ampliar (todas no nível máximo ou em obra)."
		_custo.text = ""
		_motivo.text = ""
		_botao.visible = false
		_camas.text = ""
		_cama_botao.visible = false
		return
	var c = _casa
	_titulo.text = "CASA  —  nível %d de %d" % [c.level, c.max_level()]
	var moradores: Array = c.residents()
	var nomes := moradores.map(func(w): return _hud._worker_name(w))
	_info.text = "Camas: %d / %d  •  conforto: +%d de ânimo pra quem mora aqui\nMoram aqui: %s" % [
		c.beds_taken(), c.beds_total(), roundi(c.comfort_bonus()), ", ".join(nomes) if not nomes.is_empty() else "ninguém"]
	_refresh_camas(c)
	if c.upgrade_pending():
		_custo.text = "Em obra: %s" % c.upgrade_status()
		_motivo.text = "" if c.upgrade_has_engineer() else "esperando engenheiro (tecla 4)"
		_botao.visible = false
		return
	if c.level >= c.max_level():
		_custo.text = "Nível máximo."
		_motivo.text = ""
		_botao.visible = false
		return
	var prox: int = c.level + 1
	_custo.text = "Nível %d: %d camas, conforto +%d  •  custa %s" % [prox, c.beds_for(prox), roundi(c.comfort_for(prox)), c.upgrade_cost_text()]
	var r: String = c.upgrade_block_reason()
	_motivo.text = r
	_botao.visible = true
	_botao.text = "Ampliar pra nível %d" % prox
	_botao.disabled = r != ""


## Bloco 94: as camas de tábua da casa e o botão de trocar mais uma.
func _refresh_camas(c: Node) -> void:
	var tem: float = _eco.quantidade("cama_boa") if _eco else 0.0
	_camas.text = "Camas de tábua: %d de %d%s  •  +%d de ânimo pra quem dorme numa  •  no armazém: %d" % [
		c.camas_boas, c.beds_total(), ("  (%d esperando o carpinteiro)" % c.camas_pedidas) if c.camas_pedidas > 0 else "",
		roundi(c.conforto_cama_boa), int(tem)]
	var r: String = c.motivo_cama_boa()
	_cama_botao.visible = c.camas_boas + c.camas_pedidas < c.beds_total() or c.camas_pedidas > 0
	_cama_botao.disabled = r != ""
	_cama_botao.text = "Trocar uma cama (usa 1 cama de tábua do armazém)" if r == "" else "Trocar cama: " + r
	_cama_botao.tooltip_text = "O carpinteiro (tecla 9) leva a cama de tábua e monta aqui."


func _trocar_cama() -> void:
	if _casa and is_instance_valid(_casa) and _casa.pedir_cama_boa():
		var tem := get_tree().get_nodes_in_group("ipezinhos").any(func(w): return w.has_method("is_carpenter") and w.is_carpenter())
		_hud.show_toast("Cama de tábua separada pra esta casa. %s" % ("O carpinteiro vem montar." if tem else "Precisa de um CARPINTEIRO (tecla 9) pra montar."),
			Color(0.55, 1.0, 0.5) if tem else Color(1.0, 0.8, 0.45))
	refresh()


func _ampliar() -> void:
	Audio.click()
	if _casa and is_instance_valid(_casa) and _casa.start_upgrade():
		_hud.show_toast("Ampliação da casa encomendada: o engenheiro (tecla 4) vai lá.", Color(0.55, 1.0, 0.5))
	refresh()


func button_text() -> String:
	return "Casas"


func has_available_action() -> bool:
	return false
