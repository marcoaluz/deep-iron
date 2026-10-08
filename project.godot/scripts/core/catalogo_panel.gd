extends PanelContainer
## Bloco 102: janela do CATÁLOGO (tecla R; estilo do layout v2). Abas Minerais / Animais / Criaturas / Locais com o
## contador de estudados. Cada entrada:
##   desconhecida — o ícone em SILHUETA e "???";
##   avistada     — o ícone apagado, "avistado: falta estudar", quem está estudando no campo e o botão do PLANO B
##                  ("Estudar no laboratório": o laboratório sozinho, mais devagar);
##   estudada     — o ícone, o texto da pesquisadora e a ficha (para que serve, ferramenta, receita, o que libera...).
## Os dados e os textos vêm do catálogo (catalogo.gd, data/catalogo/).
const Tipo := preload("res://scripts/ui/tipografia.gd")
const LARGURA_TEXTO := 400.0

var _hud: CanvasLayer
var _cat: Node
var _aba := "minerio"
var _abas := {}  # categoria -> Button
var _lista: VBoxContainer
var _rodape: Label
var _mostrado := ""


func setup(hud: CanvasLayer, catalogo: Node, _economy: Node) -> void:
	_hud = hud
	_cat = catalogo
	_build()
	visible = false
	_cat.mudou.connect(func():
		_mostrado = ""
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
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("CATÁLOGO", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var intro: Label = _hud._label("O que a vila descobriu do mundo depois da explosão. A pesquisadora sem pesquisa no laboratório sai pra estudar o que foi avistado.", Tipo.DETALHE, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = 500
	vbox.add_child(intro)
	var abas := HBoxContainer.new()
	abas.add_theme_constant_override("separation", 4)
	vbox.add_child(abas)
	for c in _cat.CATEGORIAS:
		var b: Button = _hud._button(_cat.NOMES_CATEGORIA[c])
		b.name = "Aba_" + c
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.pressed.connect(func():
			Audio.click()
			mostra_aba(c))
		abas.add_child(b)
		_abas[c] = b
	vbox.add_child(HSeparator.new())
	_lista = VBoxContainer.new()
	_lista.name = "Lista"
	_lista.add_theme_constant_override("separation", 8)
	vbox.add_child(_lista)
	vbox.add_child(HSeparator.new())
	_rodape = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_rodape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rodape.custom_minimum_size.x = 500
	vbox.add_child(_rodape)


func focus(_node: Node) -> void:
	pass


func mostra_aba(c: String) -> void:
	_aba = c
	_mostrado = ""
	refresh()


## A assinatura do que está na tela (só remonta quando muda).
func _assinatura() -> String:
	var s := _aba
	for e in _cat.da_categoria(_aba):
		var id := String(e.id)
		var quem: Node = _cat.reservado_por(id)
		s += "|%s%d%d%s%s" % [id, _cat.estado(id), int(_cat.amostras.get(id, 0)), quem.name if quem else "",
			_cat.motivo_lab(id)]
	s += "|lab%s%d" % [_cat.estudo_lab.get("id", ""), roundi(_cat.progresso_lab() * 100.0)]
	return s


func refresh() -> void:
	if not visible:
		return
	for c in _abas:
		var n_est: int = _cat.quantos_estudados(c)
		var n_tot: int = _cat.da_categoria(c).size()
		_abas[c].text = "%s %d/%d" % [_cat.NOMES_CATEGORIA[c], n_est, n_tot]
		_abas[c].button_pressed = c == _aba
	var sig := _assinatura()
	if sig == _mostrado:
		return
	_mostrado = sig
	for c in _lista.get_children():
		_lista.remove_child(c)
		c.queue_free()
	for e in _cat.da_categoria(_aba):
		_lista.add_child(_linha(String(e.id)))
	var rod: Array[String] = []
	if not _cat.estudo_lab.is_empty():
		var res := get_tree().get_first_node_in_group("research")
		rod.append("Laboratório estudando sozinho: %s (%d%%)%s" % [_cat.nome(String(_cat.estudo_lab.id)),
			roundi(_cat.progresso_lab() * 100.0), " — parado: tem pesquisa em andamento" if res and res.current != "" else ""])
	var pesq := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.is_researcher()).size()
	rod.append("Pesquisadores: %d%s" % [pesq, "  (sem ninguém: o laboratório estuda sozinho, mais devagar — o plano B)" if pesq == 0 else ""])
	_rodape.text = "\n".join(rod)


func _linha(id: String) -> Control:
	var est: int = _cat.estado(id)
	var row := HBoxContainer.new()
	row.name = "Entrada_" + id
	row.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.name = "Icone"
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = _cat.icone(id)
	if est == _cat.DESCONHECIDO:
		icon.modulate = Color(0.0, 0.0, 0.0, 0.85)  # silhueta
	elif est == _cat.AVISTADO:
		icon.modulate = Color(0.32, 0.32, 0.38, 1.0)
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var titulo: Label = _hud._label("???" if est != _cat.ESTUDADO else _cat.nome(id), Tipo.TITULO,
		_hud.COLOR_TEXT if est == _cat.ESTUDADO else _hud.COLOR_DIM)
	titulo.name = "Nome"
	col.add_child(titulo)
	if est == _cat.DESCONHECIDO:
		col.add_child(_texto(_dica_desconhecida(id), _hud.COLOR_DIM))
	elif est == _cat.AVISTADO:
		var quem: Node = _cat.reservado_por(id)
		var t := "Avistado: falta estudar."
		if quem:
			t += "  %s está estudando no campo." % quem.display_name
		if String(_cat.entrada(id).categoria) == "criatura":
			t += "  Amostras: %d." % int(_cat.amostras.get(id, 0))
		col.add_child(_texto(t, Color(0.75, 0.85, 1.0)))
		if _cat.estudo_lab.get("id", "") == id:
			col.add_child(_texto("No laboratório: %d%%" % roundi(_cat.progresso_lab() * 100.0), Color(0.6, 1.0, 0.75)))
		else:
			var motivo: String = _cat.motivo_lab(id)
			var b: Button = _hud._button("Estudar no laboratório (devagar)" if motivo == "" else "Estudar no laboratório: %s" % motivo)
			b.name = "PlanoB"
			b.add_theme_font_size_override("font_size", Tipo.DETALHE)
			b.disabled = motivo != ""
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			b.pressed.connect(func():
				Audio.click()
				_cat.estudar_no_lab(id))
			col.add_child(b)
	else:
		var tx: String = _cat.texto(id, "texto")
		if tx != "":
			col.add_child(_texto(tx, _hud.COLOR_TEXT))
		for f in _cat.ficha(id):
			col.add_child(_texto("%s: %s" % [f[0], f[1]], Color(1.0, 0.85, 0.5)))
	return row


func _dica_desconhecida(id: String) -> String:
	match String(_cat.entrada(id).categoria):
		"minerio":
			return "Ainda não visto. Talvez mais fundo na mina."
		"animal":
			return "Ainda não visto. Alguém precisa passar perto da toca."
		"criatura":
			return "Ainda não visto. Talvez de noite..."
		"local":
			return "Ainda fechado."
	return "Ainda não visto."


func _texto(t: String, cor: Color) -> Label:
	var l: Label = _hud._label(t, Tipo.DETALHE, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = LARGURA_TEXTO
	return l


func is_available() -> bool:
	return true


func button_text() -> String:
	return "Catálogo %d/%d" % [_cat.quantos_estudados(), _cat.entradas().size()]


## Tem o que fazer: alguma entrada avistada esperando estudo sem ninguém estudando.
func has_available_action() -> bool:
	for e in _cat.entradas():
		var id := String(e.id)
		if _cat.estado(id) == _cat.AVISTADO and _cat.reservado_por(id) == null and _cat.motivo_lab(id) == "":
			return true
	return false
