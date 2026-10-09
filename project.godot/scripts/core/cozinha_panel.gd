extends PanelContainer
## Bloco 107: janela da COZINHA (clique nela) — o CARDÁPIO. Escolhe o PRATO DA SEMANA (refeição comum ou ensopado) e pede
## RAÇÃO DE EXPEDIÇÃO (uma ordem: o cozinheiro prepara N rações, que vão pro armazém, e a cozinha volta sozinha ao prato de
## antes). Mostra a comida pronta, o estoque da cozinha e as rações. Nada é feito sem ordem (regra 9): o prato é escolha do
## jogador e a ração só anda por encomenda. O padrão é o da janela do elevador (elevador_panel.gd).
const Tipo := preload("res://scripts/ui/tipografia.gd")
const QTD_PADRAO := 4

var _hud: CanvasLayer
var _economy: Node
var _focus: Node = null
var _status: Label
var _prato_info: Label
var _btn_comum: Button
var _btn_ensopado: Button
var _racao_info: Label
var _qtd_label: Label
var _btn_pedir: Button
var _btn_cancelar: Button
var _qtd := QTD_PADRAO


func setup(hud: CanvasLayer, _alvo: Node, economy: Node) -> void:
	_hud = hud
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(480, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("COZINHA — CARDÁPIO", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_status = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)
	vbox.add_child(_hud._label("PRATO DA SEMANA", Tipo.TITULO, _hud.COLOR_TITLE))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	vbox.add_child(linha)
	_btn_comum = _hud._button("Refeição comum")
	_btn_comum.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_comum.pressed.connect(func(): _escolhe("comum"))
	linha.add_child(_btn_comum)
	_btn_ensopado = _hud._button("Ensopado")
	_btn_ensopado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_ensopado.pressed.connect(func(): _escolhe("ensopado"))
	linha.add_child(_btn_ensopado)
	_prato_info = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_prato_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_prato_info)
	vbox.add_child(_hud._label("RAÇÃO DE EXPEDIÇÃO (ordem)", Tipo.TITULO, _hud.COLOR_TITLE))
	_racao_info = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_racao_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_racao_info)
	var ordem := HBoxContainer.new()
	ordem.add_theme_constant_override("separation", 4)
	vbox.add_child(ordem)
	for par in [["-5", -5], ["-", -1]]:
		var b: Button = _hud._button(par[0])
		var passo: int = par[1]
		b.pressed.connect(func(): _muda(passo))
		ordem.add_child(b)
	_qtd_label = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	_qtd_label.custom_minimum_size = Vector2(40, 0)
	_qtd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ordem.add_child(_qtd_label)
	for par in [["+", 1], ["+5", 5]]:
		var b2: Button = _hud._button(par[0])
		var passo2: int = par[1]
		b2.pressed.connect(func(): _muda(passo2))
		ordem.add_child(b2)
	_btn_pedir = _hud._button("Encomendar")
	_btn_pedir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_pedir.pressed.connect(_pede)
	ordem.add_child(_btn_pedir)
	_btn_cancelar = _hud._button("Cancelar a ordem")
	_btn_cancelar.pressed.connect(func():
		Audio.click()
		var c := _cozinha()
		if c:
			c.cancela_racao()
		refresh())
	vbox.add_child(_btn_cancelar)


func focus(node: Node) -> void:
	_focus = node


func _cozinha() -> Node:
	if _focus != null and is_instance_valid(_focus) and _focus.is_in_group("comedouros"):
		return _focus
	return get_tree().get_first_node_in_group("comedouros")


func _escolhe(p: String) -> void:
	var c := _cozinha()
	if c and c.set_prato(p):
		Audio.click()
		_hud.show_toast("Prato da semana: %s." % ("ensopado" if p == "ensopado" else "refeição comum"), Color(1.0, 0.85, 0.5))
	refresh()


func _muda(d: int) -> void:
	var c := _cozinha()
	var mx: int = c.racao_max_pedido if c else 30
	_qtd = clampi(_qtd + d, 1, mx)
	Audio.click()
	refresh()


func _pede() -> void:
	var c := _cozinha()
	if c and c.pede_racao(_qtd):
		Audio.click()
		_hud.show_toast("Encomendadas %d rações de expedição." % _qtd, Color(1.0, 0.85, 0.5))
	else:
		Audio.error()
	refresh()


func refresh() -> void:
	if not visible:
		return
	var c := _cozinha()
	if c == null:
		_status.text = "Sem cozinha."
		return
	var racoes: float = _economy.quantidade("racao") if _economy else 0.0
	var cozinheiros := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.has_method("is_cook") and w.is_cook()).size()
	_status.text = "Comida pronta: %d / %d  •  estoque cru da cozinha: %d  •  rações prontas: %d  •  cozinheiros: %d%s" % [
		int(c.food_stock), int(c.food_capacity), int(c.raw_local), int(racoes), cozinheiros,
		"" if cozinheiros > 0 else "  (sem cozinheiro, nada é preparado: tecla C)"]
	_btn_comum.disabled = c.prato == "comum"
	_btn_ensopado.disabled = c.prato == "ensopado"
	_btn_comum.text = ("✔ " if c.prato == "comum" else "") + "Refeição comum"
	_btn_ensopado.text = ("✔ " if c.prato == "ensopado" else "") + "Ensopado"
	_prato_info.text = ("Refeição comum: porção de %d, enche %d de fome." % [int(c._porcao()), int(c._fome_da_porcao())]) if c.prato == "comum" \
		else ("Ensopado: porção de %d (gasta mais comida), enche %d de fome, +%d de ânimo a cada refeição (até +%d, some devagar); o cozinheiro demora %.1fx." % [
			int(c._porcao()), int(c._fome_da_porcao()), int(c.ensopado_animo), int(c.ensopado_animo_max), c.ensopado_preparo_mult])
	_racao_info.text = "O cozinheiro prepara rações (cada uma = 1 pessoa por 1 dia, gasta %d de comida crua e ~40 s) e a cozinha volta ao prato de antes. As expedições (;) gastam a ração pronta primeiro. Só prepara com pelo menos %d de comida pronta na cozinha.%s" % [
		int(c.racao_cru), int(c.racao_reserva_minima), ("\nEm ordem: faltam %d." % c.racao_pedida) if c.racao_pedida > 0 else ""]
	_qtd_label.text = str(_qtd)
	var motivo: String = c.motivo_racao(_qtd)
	_btn_pedir.disabled = motivo != ""
	_btn_pedir.tooltip_text = motivo
	_btn_cancelar.visible = c.racao_pedida > 0


func button_text() -> String:
	var c := _cozinha()
	return "Cozinha: %s" % ("ensopado" if c and c.prato == "ensopado" else "cardápio")


func has_available_action() -> bool:
	return false
