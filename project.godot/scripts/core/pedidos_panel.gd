extends PanelContainer
## Bloco 123: a janela "Pedidos da vila" (F7): cada pedido aberto com o RETRATO e o nome de quem pediu, o que ele quer, o andamento, o prazo e a recompensa;
## embaixo, os últimos que se encerraram (cumpridos e vencidos). Vem do pedidos.gd (data/pedidos/pedidos.json).
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")

var _hud: CanvasLayer
var _ped: Node
var _lista: VBoxContainer
var _rodape: VBoxContainer


func setup(hud: CanvasLayer, pedidos: Node, _economy: Node) -> void:
	_hud = hud
	_ped = pedidos
	_build()
	visible = false
	_ped.mudou.connect(func():
		if visible:
			refresh())


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(540, 0)
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
	var title: Label = _hud._label("PEDIDOS DA VILA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var lore: Label = _hud._label("Gente da vila pede coisas pequenas: um banco, um casaco, uma praça acesa. Nada é obrigatório; cumprir dá ânimo ou uma recompensa. "
		+ "Cada pedido tem prazo.", Tipo.DETALHE, _hud.COLOR_DIM)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.x = 500.0
	vbox.add_child(lore)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 8)
	vbox.add_child(_lista)
	vbox.add_child(HSeparator.new())
	_rodape = VBoxContainer.new()
	_rodape.add_theme_constant_override("separation", 2)
	vbox.add_child(_rodape)


func button_text() -> String:
	return "Pedidos (%d)" % _ped.abertos.size()


func has_available_action() -> bool:
	return not _ped.abertos.is_empty()


func refresh() -> void:
	for c in _lista.get_children():
		c.queue_free()
	for c in _rodape.get_children():
		c.queue_free()
	if _ped.abertos.is_empty():
		_lista.add_child(_hud._label("Nenhum pedido agora. De tempos em tempos alguém vem com um.", Tipo.CORPO, _hud.COLOR_DIM))
	for p in _ped.abertos:
		_lista.add_child(_cartao(p))
	if not _ped.historico.is_empty():
		_rodape.add_child(_hud._label("Encerrados", Tipo.DETALHE, _hud.COLOR_TITLE))
		var ult: Array = _ped.historico.slice(maxi(_ped.historico.size() - 5, 0))
		ult.reverse()
		for h in ult:
			var ok: bool = String(h.estado) == "cumprido"
			_rodape.add_child(_hud._label("%s Dia %d — %s (%s)" % ["[x]" if ok else "[ ]", int(h.dia), String(h.titulo), String(h.autor)], Tipo.DETALHE,
				Color(0.65, 0.9, 0.6) if ok else _hud.COLOR_DIM))


func _cartao(p: Dictionary) -> Control:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	var w: Node = _ped._acha(String(p.autor))
	var foto := TextureRect.new()
	foto.custom_minimum_size = Vector2(56, 56)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if w != null:
		foto.texture = Retratos.de(w)
	linha.add_child(foto)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(col)
	col.add_child(_hud._label("%s — %s" % [String(p.autor), _ped.titulo_de(p)], Tipo.CORPO, Color(1.0, 0.9, 0.55)))
	var t: Label = _hud._label(_ped.texto_de(p), Tipo.DETALHE, _hud.COLOR_TEXT)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = 400.0
	col.add_child(t)
	var pr: Array = _ped.progresso(p)
	var falta: int = _ped.dias_restantes(p)
	col.add_child(_hud._label("Andamento: %d/%d   •   prazo: %d dia%s   •   recompensa: %s" % [int(pr[0]), int(pr[1]), maxi(falta, 0), "" if falta == 1 else "s", _ped.recompensa_texto(p)],
		Tipo.DETALHE, Color(0.75, 0.9, 0.7)))
	if w != null:
		var ir: Button = _hud._button("Ver %s" % String(p.autor))
		ir.pressed.connect(func():
			Audio.click()
			var main = _hud.get_tree().current_scene
			if main and main.has_method("select"):
				main.select(w))
		col.add_child(ir)
	return linha
