extends PanelContainer
## Bloco 86: janela da FORNALHA — as receitas (insumos -> produto), a QUANTIDADE de cada ordem (+/-), o botão
## de encomendar (com o motivo quando não dá), a fila com o progresso e o cancelar. Nada é produzido sem
## ordem (regra 9). Pode ter mais de uma fornalha: a janela mostra a clicada (sem clique: a primeira).
## Abre clicando na fornalha ou pelo botão da coluna do HUD; também constrói a primeira.
## Bloco 94: a janela da CARPINTARIA (carpintaria_panel.gd) é esta com outro grupo, nomes e as chamadas do
## Centro da Vila trocadas (as funções _construir_* e os textos lá embaixo).

const Items := preload("res://scripts/core/items.gd")
const Icones := preload("res://scripts/ui/icones.gd")
## Quantidade inicial de uma ordem e o máximo.
const QTD_PADRAO := 5

var _hud: CanvasLayer
var _hub: Node
var _economy: Node
var _title: Label
var _status: Label
var _receitas_box: VBoxContainer
var _fila_box: VBoxContainer
var _build_button: Button
var _focus: Node = null
var _qtd: Dictionary = {}  # receita -> quantidade escolhida
var _linhas: Dictionary = {}  # receita -> {qtd: Label, botao: Button, info: Label}
var _receitas_de: Node = null  # a fornalha de quem as linhas foram montadas
## Bloco 94: o que muda de uma oficina de ordens pra outra.
var grupo := "fornalhas"
var titulo := "FORNALHA"
var nome_predio := "Fornalha"
var nome_operador := "Fundidor"
var nome_operadores := "Fundidores"
var intro_texto := "Funde minério em barra — só por ORDEM: escolha a receita e a quantidade e encomende. O FUNDIDOR busca os insumos no armazém (cada unidade gasta os dela só quando começa), funde aqui e leva as barras pro armazém. Faltou insumo: a ordem pausa."


func setup(hud: CanvasLayer, hub: Node, economy: Node) -> void:
	_hud = hud
	_hub = hub
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(520, 0)
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
	_title = _hud._label(titulo, 20, _hud.COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var intro: Label = _hud._label(intro_texto, 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_status = _hud._label("", 13, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)
	vbox.add_child(_hud._label("RECEITAS", 14, _hud.COLOR_TITLE))
	_receitas_box = VBoxContainer.new()
	_receitas_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_receitas_box)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("FILA DE ORDENS", 14, _hud.COLOR_TITLE))
	_fila_box = VBoxContainer.new()
	_fila_box.add_theme_constant_override("separation", 3)
	vbox.add_child(_fila_box)
	vbox.add_child(HSeparator.new())
	_build_button = _hud._button("")
	_build_button.pressed.connect(func():
		Audio.click()
		_construir()
		refresh())
	vbox.add_child(_build_button)


## O HUD avisa qual fornalha foi clicada (null = abriu pelo botão: a primeira).
func focus(node: Node) -> void:
	_focus = node if node != null and node.is_in_group(grupo) else null


func _current() -> Node:
	if _focus != null and is_instance_valid(_focus) and _focus.is_inside_tree():
		return _focus
	return get_tree().get_first_node_in_group(grupo)


# Bloco 94: as chamadas ao Centro da Vila (a carpintaria troca)
func _construir() -> void:
	_hub.build_fornalha()


func _motivo_construir() -> String:
	return _hub.fornalha_block_reason()


func _custo_construir() -> String:
	return _hub.fornalha_cost_text()


func _estagio() -> int:
	return int(_hub.fornalha_estagio)


## Uma linha por receita da fornalha: ícone, nome, insumos, [-5][-] qtd [+][+5], Encomendar.
func _monta_receitas(f: Node) -> void:
	for c in _receitas_box.get_children():
		_receitas_box.remove_child(c)  # (sai já: a contagem e o layout não veem a linha velha)
		c.queue_free()
	_linhas.clear()
	_receitas_de = f
	if f == null:
		return
	for r in f.receitas:
		var id: String = r.id
		if not _qtd.has(id):
			_qtd[id] = QTD_PADRAO
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		_receitas_box.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = Icones.tex(Items.icone(r.produto.keys()[0])) if not r.produto.is_empty() else null
		row.add_child(icon)
		var info: Label = _hud._label("", 12, _hud.COLOR_TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info)
		for passo in [-5, -1]:
			row.add_child(_botao_qtd(id, passo))
		var qtd: Label = _hud._label("", 14, _hud.COLOR_TITLE)
		qtd.custom_minimum_size.x = 30
		qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(qtd)
		for passo in [1, 5]:
			row.add_child(_botao_qtd(id, passo))
		var b: Button = _hud._button("Encomendar")
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func():
			var ff := _current()
			if ff:
				ff.encomendar(id, int(_qtd[id]))
			refresh())
		row.add_child(b)
		_linhas[id] = {"qtd": qtd, "botao": b, "info": info}


func _botao_qtd(id: String, passo: int) -> Button:
	var b: Button = _hud._button(("%+d" % passo) if absi(passo) > 1 else ("+" if passo > 0 else "−"))
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size = Vector2(28, 0)
	b.pressed.connect(func():
		Audio.click()
		var f := _current()
		var maximo: int = f.fila.max_quantidade if f else 50
		_qtd[id] = clampi(int(_qtd.get(id, QTD_PADRAO)) + passo, 1, maximo)
		refresh())
	return b


func refresh() -> void:
	if not visible:
		return
	var f := _current()
	var todas := get_tree().get_nodes_in_group(grupo)
	var reason: String = _motivo_construir()
	var what := ("Construir a %s" if todas.is_empty() else "Construir outra %s") % nome_predio
	_build_button.text = ("%s — escolher lugar  (%s)" % [what, _custo_construir()]) if reason == "" else "%s: %s" % [what, reason]
	_build_button.disabled = reason != ""
	_title.text = titulo if todas.size() <= 1 or f == null else "%s %d de %d" % [titulo, todas.find(f) + 1, todas.size()]
	if f != _receitas_de:
		_monta_receitas(f)
	if f == null:
		_status.text = "Ainda não construída."
		for c in _fila_box.get_children():
			_fila_box.remove_child(c)
			c.queue_free()
		return
	var operadores := get_tree().get_nodes_in_group("ipezinhos").filter(f.e_operador)
	_status.text = "%s\n%s: %d%s" % [f.status_text(), nome_operadores, operadores.size(),
		("  (escolha um ipezinho e dê a função %s)" % nome_operador) if operadores.is_empty() else ""]
	for id in _linhas:
		var l: Dictionary = _linhas[id]
		var r: Dictionary = f.fila.receita(id)
		var q := int(_qtd.get(id, QTD_PADRAO))
		l.qtd.text = str(q)
		var motivo: String = f.motivo_encomenda(id, q)
		var produto: String = ", ".join(r.produto.keys().map(func(k): return "%d %s" % [int(r.produto[k]),
			Items.plural(k) if int(r.produto[k]) > 1 else Items.nome(k).to_lower()]))  # Bloco 94: plural
		l.info.text = "%s\n%s -> %s  (%ds cada)%s" % [r.get("nome", id), f.fila.texto_insumos(id), produto, int(r.get("segundos", 10)),
			("\n" + motivo) if motivo != "" else ""]
		l.botao.disabled = motivo != ""
	for c in _fila_box.get_children():
		_fila_box.remove_child(c)
		c.queue_free()
	if f.fila.fila.is_empty():
		_fila_box.add_child(_hud._label("Nenhuma ordem: a %s fica parada (o %s não pega nada)." % [nome_predio.to_lower(), nome_operador.to_lower()], 12, _hud.COLOR_DIM))
	for i in f.fila.fila.size():
		var row := HBoxContainer.new()
		_fila_box.add_child(row)
		var txt := "%d. %s" % [i + 1, f.fila.texto_ordem(i)]
		if i == 0:
			var falta: String = f.falta()
			txt += ("  —  PAUSADA: %s" % falta) if falta != "" else ("  —  %d%% da unidade" % roundi(f.fila.progresso_unidade() * 100.0) if f.fila.comecadas() > 0 else "  —  esperando o %s" % nome_operador.to_lower())
		var l: Label = _hud._label(txt, 12, Color(1.0, 0.6, 0.45) if i == 0 and f.falta() != "" else _hud.COLOR_TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var cancel: Button = _hud._button("Cancelar")
		cancel.add_theme_font_size_override("font_size", 11)
		cancel.pressed.connect(func():
			var ff := _current()
			if ff:
				ff.cancelar(i)
			refresh())
		row.add_child(cancel)


func button_text() -> String:
	var todas := get_tree().get_nodes_in_group(grupo)
	if todas.is_empty():
		return "%s: construir" % nome_predio
	var f: Node = todas[0]
	if not f.fila.tem_trabalho():
		return "%s: sem ordem" % nome_predio
	return "%s: %s" % [nome_predio, "PAUSADA" if f.falta() != "" else f.fila.texto_ordem(0)]


## Aparece na coluna quando já dá pra construir (estágio) ou já tem uma.
func is_available() -> bool:
	return not get_tree().get_nodes_in_group(grupo).is_empty() or int(_hub.level) >= _estagio()


func has_available_action() -> bool:
	return get_tree().get_nodes_in_group(grupo).any(func(f): return f.falta() != "")
