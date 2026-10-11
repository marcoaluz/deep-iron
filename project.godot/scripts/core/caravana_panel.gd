extends PanelContainer
## Bloco 125: a janela da CARAVANA (clique no posto de troca, ou "Janelas"): o retrato e a fala da comerciante, quando ela chega/parte, o que ela VENDE
## (a vila paga em créditos: peças raras, sementes, carne defumada), o que ela COMPRA (barras e gemas, com o teto de demanda da visita), as encomendas abertas
## e o saldo do que a vila já negociou. Tudo é botão: nada compra nem vende sozinho. Vem do caravana.gd.
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Items := preload("res://scripts/core/items.gd")

var _hud: CanvasLayer
var _car: Node
var _eco: Node
var _topo: VBoxContainer
var _loja: VBoxContainer
var _compra: VBoxContainer
var _rodape: VBoxContainer


func setup(hud: CanvasLayer, caravana: Node, economy: Node) -> void:
	_hud = hud
	_car = caravana
	_eco = economy
	_build()
	visible = false
	_car.mudou.connect(func():
		if visible:
			refresh())


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(620, 0)
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
	var title: Label = _hud._label("CARAVANA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_topo = VBoxContainer.new()
	_topo.add_theme_constant_override("separation", 6)
	vbox.add_child(_topo)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("ELA VENDE (você paga em créditos)", Tipo.TITULO, _hud.COLOR_TITLE))
	_loja = VBoxContainer.new()
	_loja.add_theme_constant_override("separation", 4)
	vbox.add_child(_loja)
	vbox.add_child(_hud._label("ELA COMPRA (barras e gemas do armazém)", Tipo.TITULO, _hud.COLOR_TITLE))
	_compra = VBoxContainer.new()
	_compra.add_theme_constant_override("separation", 4)
	vbox.add_child(_compra)
	vbox.add_child(HSeparator.new())
	_rodape = VBoxContainer.new()
	_rodape.add_theme_constant_override("separation", 2)
	vbox.add_child(_rodape)


func button_text() -> String:
	return "Caravana" + (" (aqui!)" if _car.presente else "")


func has_available_action() -> bool:
	return bool(_car.presente)


func _limpa(c: Control) -> void:
	for f in c.get_children():
		f.queue_free()


func refresh() -> void:
	_limpa(_topo)
	_limpa(_loja)
	_limpa(_compra)
	_limpa(_rodape)
	_topo.add_child(_cabecalho())
	if _car.presente:
		for id in _car.LOJA:
			_loja.add_child(_linha_loja(String(id)))
		for id in _car.COMPRA:
			_compra.add_child(_linha_compra(String(id)))
	else:
		_loja.add_child(_hud._label("A banca está fechada: a caravana não está no posto.", Tipo.CORPO, _hud.COLOR_DIM))
		_compra.add_child(_hud._label("O que a vila produz em barras e gemas pode esperar a próxima visita.", Tipo.CORPO, _hud.COLOR_DIM))
	_rodape_monta()


func _cabecalho() -> Control:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	var w: Node = _car.comerciante()
	var foto := TextureRect.new()
	foto.custom_minimum_size = Vector2(64, 64)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if w != null:
		foto.texture = Retratos.de(w)
	elif Retratos.de_nome("comerciante") != null:
		foto.texture = Retratos.de_nome("comerciante")
	linha.add_child(foto)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(col)
	var dn := _hud.get_tree().get_first_node_in_group("day_night")
	var dia: int = int(dn.day) if dn else 1
	if _car.presente:
		col.add_child(_hud._label("%s está no posto até o dia %d (%d dia%s)  •  mercado: %s" % [_car.nome_comerciante, int(_car.parte_dia) - 1, _car.dias_restantes(),
			"" if _car.dias_restantes() == 1 else "s", _car.situacao_texto()], Tipo.CORPO, Color(1.0, 0.9, 0.55)))
	else:
		var tem_posto: bool = _car.posto() != null
		var prox: int = maxi(int(_car.proxima_dia), 1)
		col.add_child(_hud._label("Próxima visita: %s" % ("dia %d" % maxi(prox, dia) if tem_posto else "só quando houver um POSTO DE TROCA pronto (Construir → Vila)"),
			Tipo.CORPO, _hud.COLOR_TEXT))
	var fala: Label = _hud._label("\"%s\"" % (String(_car.ultima_fala) if String(_car.ultima_fala) != "" else _car.fala("saudacao")), Tipo.DETALHE, Color(0.85, 0.9, 0.75))
	fala.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fala.custom_minimum_size.x = 460.0
	col.add_child(fala)
	return linha


func _linha_base(id: String, nome: String, detalhe: String, preco_txt: String) -> HBoxContainer:
	var l := HBoxContainer.new()
	l.add_theme_constant_override("separation", 8)
	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(28, 28)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var nome_icone: String = _car.icone_do_item(id)
	if nome_icone != "":
		ic.texture = Icones.tex(nome_icone)
	l.add_child(ic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_child(col)
	col.add_child(_hud._label(nome, Tipo.CORPO, _hud.COLOR_TEXT))
	var d: Label = _hud._label(detalhe, Tipo.DETALHE, _hud.COLOR_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 300.0
	col.add_child(d)
	var p: Label = _hud._label(preco_txt, Tipo.CORPO, Color(1.0, 0.85, 0.4))
	p.custom_minimum_size.x = 80.0
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_child(p)
	return l


func _botao(l: HBoxContainer, texto: String, ativo: bool, acao: Callable) -> void:
	var b: Button = _hud._button(texto)
	b.disabled = not ativo
	b.pressed.connect(func():
		Audio.click()
		acao.call()
		refresh())
	l.add_child(b)


func _linha_loja(id: String) -> Control:
	var info: Dictionary = _car.LOJA[id]
	var tem: int = int(_car.estoque.get(id, 0))
	var preco: float = _car.preco_pra_vila(id)
	var l := _linha_base(id, String(info.nome), "%s  (restam %d)" % [String(info.desc), tem], "%d cr" % int(preco))
	var cabe: int = _car.maximo_compra(id)
	_botao(l, "Comprar 1", cabe >= 1, func(): _car.compra_da_caravana(id, 1))
	_botao(l, "Comprar %d" % maxi(cabe, 1) if cabe > 1 else "Comprar tudo", cabe >= 2, func(): _car.compra_da_caravana(id, cabe))
	return l


func _linha_compra(id: String) -> Control:
	var tem := int(floorf(float(_eco.livre(id))))
	var quer: int = int(_car.demanda.get(id, 0))
	var preco: float = _car.preco_da_vila(id)
	var l := _linha_base(id, _car.nome_do_item(id), "tem %d no armazém  •  ela ainda quer %d" % [tem, quer], "%d cr" % int(preco))
	var max_v: int = _car.maximo_venda(id)
	_botao(l, "Vender 1", max_v >= 1, func(): _car.venda_pra_caravana(id, 1))
	_botao(l, "Vender %d" % max_v if max_v > 1 else "Vender tudo", max_v >= 2, func(): _car.venda_pra_caravana(id, max_v))
	return l


func _rodape_monta() -> void:
	var ped := _hud.get_tree().get_first_node_in_group("pedidos")
	if ped != null:
		var enc: Array = ped.abertos.filter(func(p): return String(p.tipo) == "caravana_encomenda")
		if not enc.is_empty():
			_rodape.add_child(_hud._label("ENCOMENDAS (também em Pedidos, F7)", Tipo.DETALHE, _hud.COLOR_TITLE))
			for p in enc:
				var pr: Array = ped.progresso(p)
				_rodape.add_child(_hud._label("%d/%d %s  •  bônus de %d cr até ela partir" % [int(pr[0]), int(pr[1]), Items.plural(String(p.item)), int(p.bonus)],
					Tipo.DETALHE, Color(0.75, 0.9, 0.7)))
	var s: Dictionary = _car.estatisticas()
	_rodape.add_child(_hud._label("Até agora: %d visita%s  •  a vila vendeu %d cr e gastou %d cr  •  %d encomenda%s cumprida%s" % [int(s.visitas), "" if int(s.visitas) == 1 else "s",
		int(s.vendido_cr), int(s.gasto_cr), int(s.encomendas), "" if int(s.encomendas) == 1 else "s", "" if int(s.encomendas) == 1 else "s"], Tipo.DETALHE, _hud.COLOR_DIM))
	if int(_car.semente_ate_dia) >= _dia():
		_rodape.add_child(_hud._label("Sementes novas: a horta cresce +%d%% até o dia %d." % [int(_car.semente_bonus * 100.0), int(_car.semente_ate_dia)], Tipo.DETALHE, Color(0.6, 0.9, 0.5)))


func _dia() -> int:
	var dn := _hud.get_tree().get_first_node_in_group("day_night")
	return int(dn.day) if dn else 1
