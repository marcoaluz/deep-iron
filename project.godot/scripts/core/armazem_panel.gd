extends PanelContainer
## Janela do Armazém (Bloco 39): quanto tem de cada coisa, quanto vale e vender (Bloco 95: e o "auto", que saiu da
## barra de cima). Abre clicando no armazém ou pelo menu "Janelas" do HUD. Os preços vêm do nó Economy (Inspector).
##
## Bloco 82: uma GRADE por categoria do catálogo de itens (items.gd: minério, metal, madeira, comida, peças e
## materiais, equipamento), cada célula com ícone, nome, quantidade e preço. Quantidade zero fica esmaecida.
## Vender: a categoria inteira (botão do título; no minério é o "Vender tudo" de sempre) ou UM item na
## quantidade escolhida. Bloco 136: os dois abrem a CAIXA DE VENDA (ui/caixa_venda.gd: o item com ícone, quanto tem e o
## preço, a quantidade −10/−/campo/+/+10/máx com o valor, Vender tudo, Confirmar e Cancelar): nada vende sem confirmar. Os números somam TODOS os armazéns (Bloco 47: cada armazém guarda o seu, a vila vende a soma).
## Minério ainda não liberado pela Oficina e sem estoque fica escondido (não estraga a surpresa).

const Ores := preload("res://scripts/core/ores.gd")
const Items := preload("res://scripts/core/items.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const CaixaVenda := preload("res://scripts/ui/caixa_venda.gd")
## Colunas da grade.
const COLUNAS := 4
## Transparência de um item com quantidade zero.
const ALFA_VAZIO := 0.38

var _hud: CanvasLayer
var _arm: Node
var _economy: Node
var _credits_label: Label
## id -> {cell, label (quantidade), name, price, button}. (O b39 lê _rows["ferro"].label.)
var _rows: Dictionary = {}
## categoria -> {box, button}
var _secoes: Dictionary = {}
## O "Vender tudo" (todo o minério) — o botão do título da categoria Minério.
var _sell_all: Button
var _auto_check: CheckBox  # Bloco 95: o "auto" que ficava na barra de cima
## Bloco 97: o espaço (deste armazém e de todos) e a ampliação.
var _espaco_label: Label
var _espaco_barra: ProgressBar
const Itens := preload("res://scripts/core/items.gd")  # (Bloco 106: os compartimentos)
## Bloco 106: uma linha (texto + barra) por compartimento: alimentos, madeira, minérios e barras, manufaturados.
var _cat_linhas: Dictionary = {}  # categoria -> {label, barra}
var _ampliar: Button
var _ampliar_motivo: Label
var _other_label: Label
## Bloco 136: a caixa de venda. _sel_id / _sel_qtd / _sel_tudo são o item, a quantidade e o "máx" dela (o b82 lê).
var _caixa: Control
var _sel_id: String:
	get:
		return _caixa.id if _caixa and _caixa.visible else ""
var _sel_qtd: int:
	get:
		return _caixa.qtd if _caixa else 0
	set(v):
		if _caixa:
			_caixa._define(v)
var _sel_tudo: Button:
	get:
		return _caixa._max if _caixa else null


func setup(hud: CanvasLayer, arm: Node, economy: Node) -> void:
	_hud = hud
	_arm = arm
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(560, 0)
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
	var title: Label = _hud._label("ARMAZÉM", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var intro: Label = _hud._label("Tudo o que a vila guardou (soma dos armazéns). Minério e metal vendidos viram créditos; madeira, comida, couro e peças raras ficam pras obras, a cozinha e a Oficina.", Tipo.DETALHE, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	var linha := HBoxContainer.new()  # Bloco 95: os créditos e o "auto" (saiu da barra de cima)
	vbox.add_child(linha)
	_credits_label = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	_credits_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(_credits_label)
	_auto_check = CheckBox.new()
	_auto_check.text = "Vender sozinho (auto)"
	_auto_check.focus_mode = Control.FOCUS_NONE
	_auto_check.tooltip_text = "Vende sozinho o minério que chegar no armazém."
	_auto_check.button_pressed = _economy.auto_sell
	_auto_check.toggled.connect(func(on: bool):
		Audio.click()
		_economy.auto_sell = on)
	linha.add_child(_auto_check)
	# Bloco 97: o espaço e a ampliação (até o nível 3, obra de engenheiro com material)
	var esp := HBoxContainer.new()
	esp.add_theme_constant_override("separation", 8)
	vbox.add_child(esp)
	var ev := VBoxContainer.new()
	ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esp.add_child(ev)
	_espaco_label = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	ev.add_child(_espaco_label)
	_espaco_barra = _hud._bar(Color(0.75, 0.62, 0.35))
	_espaco_barra.custom_minimum_size = Vector2(260, 8)
	ev.add_child(_espaco_barra)
	var cores := {"alimentos": Color(0.62, 0.8, 0.4), "madeira": Color(0.72, 0.52, 0.3), "minerios": Color(0.78, 0.45, 0.25),
		"manufaturados": Color(0.6, 0.62, 0.78)}
	for cat in Itens.COMPARTIMENTOS:
		var linha_c := HBoxContainer.new()
		linha_c.add_theme_constant_override("separation", 8)
		var l: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
		l.custom_minimum_size = Vector2(230, 0)
		linha_c.add_child(l)
		var b: ProgressBar = _hud._bar(cores.get(cat, Color(0.75, 0.62, 0.35)))
		b.custom_minimum_size = Vector2(150, 8)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha_c.add_child(b)
		ev.add_child(linha_c)
		_cat_linhas[cat] = {"label": l, "barra": b}
	_ampliar_motivo = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_ampliar_motivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ev.add_child(_ampliar_motivo)
	_ampliar = _hud._button("Ampliar")
	_ampliar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ampliar.pressed.connect(func():
		Audio.click()
		if _arm and is_instance_valid(_arm) and _arm.has_method("ampliar"):
			_arm.ampliar()
		refresh())
	esp.add_child(_ampliar)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var corpo := VBoxContainer.new()
	corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 8)
	scroll.add_child(corpo)
	for cat in Items.CATEGORIAS:
		var ids: Array = Items.da_categoria(cat)
		if ids.is_empty():
			continue  # (equipamento: entra quando houver item — Bloco 87)
		_secao(corpo, cat, ids)
	_monta_caixa()
	vbox.add_child(HSeparator.new())
	_other_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_other_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_other_label)


## Título da categoria (com o botão de vender a categoria) e a grade das células.
func _secao(pai: Control, cat: String, ids: Array) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	pai.add_child(box)
	var topo := HBoxContainer.new()
	box.add_child(topo)
	var nome: Label = _hud._label(Items.nome_categoria(cat).to_upper(), Tipo.TITULO, _hud.COLOR_TITLE)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(nome)
	var vende: Button = null
	if ids.any(func(i): return _economy.pode_vender(i)):
		vende = _hud._button("")
		vende.add_theme_font_size_override("font_size", Tipo.DETALHE)
		vende.pressed.connect(func():
			Audio.click()
			_caixa.abre_categoria(cat)  # Bloco 136: pede a confirmação
			refresh())
		topo.add_child(vende)
		if cat == "minerio":
			_sell_all = vende
	var grade := GridContainer.new()
	grade.columns = COLUNAS
	grade.add_theme_constant_override("h_separation", 6)
	grade.add_theme_constant_override("v_separation", 6)
	box.add_child(grade)
	for id in ids:
		_rows[id] = _celula(grade, id)
	_secoes[cat] = {"box": box, "button": vende}


func _celula(grade: GridContainer, id: String) -> Dictionary:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(124, 0)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.075, 0.065, 0.9)
	sb.border_color = Color(0.36, 0.28, 0.2)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	cell.add_theme_stylebox_override("panel", sb)
	cell.tooltip_text = Items.nome(id)
	grade.add_child(cell)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	cell.add_child(col)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	col.add_child(linha)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = _icone(id)
	linha.add_child(icon)
	var qtd: Label = _hud._label("0", Tipo.TITULO, Ores.UI_COLORS.get(id, _hud.COLOR_TEXT))
	qtd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qtd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(qtd)
	var nome: Label = _hud._label(Items.nome(id), Tipo.DETALHE, _hud.COLOR_TEXT)
	nome.clip_text = true
	col.add_child(nome)
	var preco: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	col.add_child(preco)
	var b: Button = null
	if _economy.pode_vender(id):
		b = _hud._button("Vender…")
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.pressed.connect(func():
			Audio.click()
			seleciona(id))
		col.add_child(b)
	return {"cell": cell, "label": qtd, "name": nome, "price": preco, "button": b}


## Bloco 136: o "Vender…" abre a CAIXA DE VENDA (ui/caixa_venda.gd), que pede a quantidade e a confirmação.
func _monta_caixa() -> void:
	_caixa = CaixaVenda.new()
	var camada := CanvasLayer.new()  # (por cima do HUD e do capataz do primeiro dia, que fica na camada 20)
	camada.name = "CamadaCaixaVenda"
	camada.layer = 25
	_hud.add_child(camada)
	camada.add_child(_caixa)
	_caixa.setup(_hud, _economy)
	_caixa.vendeu.connect(func(_id, _q, _g): refresh())


## Quantas unidades inteiras a vila tem do item.
func _tem(id: String) -> int:
	return int(floorf(_economy.quantidade(id))) if id != "" else 0


## Abre a caixa de venda do item (a quantidade começa em tudo o que tem). Nada vende ainda.
func seleciona(id: String) -> void:
	if _caixa:
		_caixa.abre_item(id)
	refresh()


## Vende o que está na caixa (o Confirmar). Retorna os créditos.
func vender_selecionado() -> float:
	if _caixa == null or not _caixa.visible:
		Audio.error()
		return 0.0
	return _caixa.confirmar()


func _refresh_selecao() -> void:
	var sel := _sel_id
	for id in _rows:
		var st: StyleBoxFlat = _rows[id].cell.get_theme_stylebox("panel")
		if st:
			st.border_color = Color(1.0, 0.8, 0.35) if id == sel else Color(0.36, 0.28, 0.2)
			st.set_border_width_all(2 if id == sel else 1)
	if _caixa:
		_caixa.refresh()


## Ícone do item: o da pasta de ícones; sem arquivo, o pedaço de minério (ou nada).
func _icone(id: String) -> Texture2D:
	var t: Texture2D = Icones.tex(Items.icone(id))
	if t == null and Ores.CHUNK_TEXTURES.has(id):
		t = Ores.CHUNK_TEXTURES[id]
	return t


func refresh() -> void:
	if not visible or _economy == null:
		return
	_credits_label.text = "Créditos: %d" % int(_economy.credits)
	_refresh_espaco()
	if _auto_check.button_pressed != _economy.auto_sell:
		_auto_check.set_pressed_no_signal(_economy.auto_sell)
	var oficina := get_tree().get_first_node_in_group("oficina")
	for id in _rows:
		var r: Dictionary = _rows[id]
		var n: float = _economy.quantidade(id)
		var travado: bool = Ores.TYPES.has(id) and oficina != null and not oficina.is_ore_unlocked(id)
		r.cell.visible = not (travado and n < 1.0)
		r.cell.modulate = Color(1, 1, 1, 1.0 if n >= 1.0 else ALFA_VAZIO)
		r.label.text = str(int(n))
		var p: float = _economy.price_of(id)
		if _economy.pode_vender(id):
			r.price.text = "%s cr cada" % str(snappedf(p, 0.1)) + ("  (= %d cr)" % _economy.valor_de(id) if n >= 1.0 else "")
		else:
			r.price.text = "não se vende"
		if r.button:
			r.button.disabled = n < 1.0
	for cat in _secoes:
		var s: Dictionary = _secoes[cat]
		var b: Button = s.button
		if b == null:
			continue
		var total := 0
		for id in Items.da_categoria(cat):
			total += _economy.valor_de(id)
		if cat == "minerio":
			b.text = ("Vender tudo  (+%d cr)" % total) if total > 0 else "Nada pra vender"
		else:
			b.text = ("Vender %s  (+%d cr)" % [Items.nome_categoria(cat).to_lower(), total]) if total > 0 else "Nada pra vender"
		b.disabled = total <= 0
	_other_label.text = "Os itens de metal saem da Fornalha (quando houver); minério bruto ainda serve pras obras do começo."
	_refresh_selecao()


## Bloco 97: clicou num armazém: a janela mostra o espaço e a ampliação DELE (os números de cima somam todos).
func focus(n: Node) -> void:
	if n != null and n.is_in_group("armazens"):
		_arm = n


func _refresh_espaco() -> void:
	if _arm == null or not is_instance_valid(_arm) or not _arm.has_method("capacidade"):
		_arm = get_tree().get_first_node_in_group("armazens")
	if _arm == null or not _arm.has_method("capacidade"):
		return
	var arms := get_tree().get_nodes_in_group("armazens")
	var u := 0.0
	var c := 0.0
	for a in arms:
		u += a.usado()
		c += a.capacidade()
	_espaco_label.text = "Este armazém (nível %d): %d / %d%s" % [_arm.nivel, int(_arm.usado()), int(_arm.capacidade()), "  —  CHEIO" if _arm.cheio() else ""]
	if arms.size() > 1:
		_espaco_label.text += "   •   todos (%d): %d / %d" % [arms.size(), int(u), int(c)]
	_espaco_barra.max_value = _arm.capacidade()
	_espaco_barra.value = minf(_arm.usado(), _arm.capacidade())
	for cat in _cat_linhas:  # Bloco 106: os compartimentos (um cheio não bloqueia os outros)
		var cap: float = _arm.capacidade_cat(cat)
		var uso: float = _arm.usado_cat(cat)
		var li: Dictionary = _cat_linhas[cat]
		li.label.text = "%s: %d / %d%s" % [String(Itens.NOME_COMPARTIMENTO[cat]).left(1).to_upper() + String(Itens.NOME_COMPARTIMENTO[cat]).substr(1), int(uso), int(cap), "  CHEIO" if _arm.cheio_cat(cat) else ""]
		li.label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if _arm.cheio_cat(cat) else _hud.COLOR_TEXT)
		li.barra.max_value = maxf(cap, 1.0)
		li.barra.value = minf(uso, cap)
	var motivo: String = _arm.ampliar_motivo()
	_ampliar.visible = _arm.nivel < _arm.nivel_maximo() or _arm.ampliando
	_ampliar.disabled = motivo != ""
	_ampliar.text = "Ampliar pro nível %d" % (_arm.nivel + 1)
	_ampliar.tooltip_text = "Ampliar: cabe %d. Custo: %s (obra de engenheiro: ele leva o material)." % [
		int(_arm.capacidade_minima_no_nivel(_arm.nivel + 1)), _arm.ampliar_custo_texto()]
	_ampliar_motivo.text = ("Ampliar: %s" % _arm.ampliar_custo_texto()) if motivo == "" else ("Ampliar: %s" % motivo)


func button_text() -> String:
	return "Armazém: %d cr à venda" % _economy.sale_value()


func has_available_action() -> bool:
	return false
