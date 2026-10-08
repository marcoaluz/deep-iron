extends PanelContainer
## Bloco 100: janela "Missões" (tecla vírgula; também o botão da aba fina da esquerda). Mostra o capítulo em
## andamento (título, subtítulo, introdução), as missões dele com os objetivos (caixinha + quanto falta), a recompensa e,
## embaixo, a lista dos capítulos já cumpridos e o que vem depois. Os textos vêm do arquivo do capítulo
## (data/missoes/capitulo_N.txt), pelo gerenciador (missoes.gd).
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _m: Node
var _conteudo: VBoxContainer
var _titulo: Label


func setup(hud: CanvasLayer, missoes: Node, _economy: Node) -> void:
	_hud = hud
	_m = missoes
	_build()
	visible = false
	_m.mudou.connect(func():
		if visible:
			refresh())


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(500, 0)
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
	_titulo = _hud._label("MISSÕES", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_titulo)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_conteudo = VBoxContainer.new()
	_conteudo.add_theme_constant_override("separation", 6)
	vbox.add_child(_conteudo)


func focus(_node: Node) -> void:
	pass


func _texto(t: String, tipo: int, cor: Color) -> Label:
	var l: Label = _hud._label(t, tipo, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 460.0
	return l


func refresh() -> void:
	if not visible:
		return
	for c in _conteudo.get_children():
		c.queue_free()
	var cap: int = _m.capitulo_atual()
	var ativas: Array = _m.ativas()
	_titulo.text = "MISSÕES — Cap. %d  %s" % [cap, _m.capitulo_titulo(cap).to_upper()]
	var sub: String = _m.capitulo_subtitulo(cap)
	if sub != "":
		_conteudo.add_child(_texto("Fase da vila: %s" % sub, Tipo.DETALHE, _hud.COLOR_DIM))
	var intro: String = _m.capitulo_intro(cap)
	if intro != "":
		_conteudo.add_child(_texto(intro, Tipo.DETALHE, _hud.COLOR_DIM))
	if ativas.is_empty():
		_conteudo.add_child(_texto("Nenhuma missão valendo agora.", Tipo.CORPO, _hud.COLOR_TEXT))
	for m in ativas:
		_conteudo.add_child(HSeparator.new())
		_conteudo.add_child(_texto(_m.titulo_da(m), Tipo.TITULO, _hud.COLOR_TEXT))
		var tx: String = _m.texto_da(m)
		if tx != "":
			_conteudo.add_child(_texto(tx, Tipo.DETALHE, _hud.COLOR_DIM))
		for i in m.objetivos.size():
			var feito: bool = _m.objetivo_feito(m, i)
			_conteudo.add_child(_texto(("[x] " if feito else "[ ] ") + _m.objetivo_texto(m, i), Tipo.CORPO,
				_hud.COLOR_DIM if feito else _hud.COLOR_TEXT))
		var rec: String = _m.recompensa_texto(m)
		if rec != "":
			_conteudo.add_child(_texto("Recompensa: %s" % rec, Tipo.DETALHE, Color(1.0, 0.85, 0.5)))
	# o que já foi cumprido e o que vem
	var feitas: Array = _m.todas().filter(func(m): return _m.cumprida(m.id))
	if not feitas.is_empty():
		_conteudo.add_child(HSeparator.new())
		_conteudo.add_child(_texto("Cumpridas", Tipo.TITULO, _hud.COLOR_TEXT))
		for m in feitas:
			_conteudo.add_child(_texto("[x] Cap. %d — %s" % [m.capitulo, _m.titulo_da(m)], Tipo.DETALHE, _hud.COLOR_DIM))
	var prox: int = _m.capitulo_liberado
	if ativas.is_empty() and not _m.capitulo_existe(prox):  # liberado, mas ainda não escrito: o arquivo do capítulo anterior fala dele
		var sec: Dictionary = _m.textos(maxi(prox - 1, 1)).get("proximo_capitulo", {})
		_conteudo.add_child(HSeparator.new())
		_conteudo.add_child(_texto(String(sec.get("titulo", "Capítulo %d" % prox)), Tipo.TITULO, Color(1.0, 0.85, 0.5)))
		_conteudo.add_child(_texto(String(sec.get("texto", "Em breve.")), Tipo.DETALHE, _hud.COLOR_DIM))


func is_available() -> bool:
	return true


func button_text() -> String:
	var ativas: Array = _m.ativas()
	if ativas.is_empty():
		return "Missões"
	var feitos := 0
	var total := 0
	for m in ativas:
		for i in m.objetivos.size():
			total += 1
			if _m.objetivo_feito(m, i):
				feitos += 1
	return "Missões %d/%d" % [feitos, total]


func has_available_action() -> bool:
	return false
