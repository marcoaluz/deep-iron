extends PanelContainer
## Janela do Armazém (Bloco 39): quanto tem de cada coisa, quanto vale e vender. Abre clicando no
## armazém ou pelo botão no painel do HUD. Os preços vêm do nó Economy (Inspector).
##
## Bloco 82: uma GRADE por categoria do catálogo de itens (items.gd: minério, metal, madeira, comida, peças e
## materiais, equipamento), cada célula com ícone, nome, quantidade e preço. Quantidade zero fica esmaecida.
## Vender: a categoria inteira (botão do título; no minério é o "Vender tudo" de sempre) ou UM item na
## quantidade escolhida: o botão "Vender…" da célula seleciona o item na barra de venda embaixo da grade
## (-10 / -1 / +1 / +10 / Tudo e "Vender N"; a quantidade começa em tudo o que tem). Os números somam TODOS os armazéns (Bloco 47: cada armazém guarda o seu, a vila vende a soma).
## Minério ainda não liberado pela Oficina e sem estoque fica escondido (não estraga a surpresa).

const Ores := preload("res://scripts/core/ores.gd")
const Items := preload("res://scripts/core/items.gd")
const Icones := preload("res://scripts/ui/icones.gd")
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
var _other_label: Label
## Barra de venda: o item selecionado e a quantidade.
var _sel_id := ""
var _sel_qtd := 0
var _sel_box: HBoxContainer
var _sel_info: Label
var _sel_qtd_label: Label
var _sel_vender: Button
var _sel_tudo: Button


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
	var title: Label = _hud._label("ARMAZÉM", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var intro: Label = _hud._label("Tudo o que a vila guardou (soma dos armazéns). Minério e metal vendidos viram créditos; madeira, comida, couro e peças raras ficam pras obras, a cozinha e a Oficina.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_credits_label = _hud._label("", 15, _hud.COLOR_TEXT)
	vbox.add_child(_credits_label)
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
	_monta_barra_venda(vbox)
	vbox.add_child(HSeparator.new())
	_other_label = _hud._label("", 12, _hud.COLOR_DIM)
	_other_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_other_label)


## Título da categoria (com o botão de vender a categoria) e a grade das células.
func _secao(pai: Control, cat: String, ids: Array) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	pai.add_child(box)
	var topo := HBoxContainer.new()
	box.add_child(topo)
	var nome: Label = _hud._label(Items.nome_categoria(cat).to_upper(), 14, _hud.COLOR_TITLE)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(nome)
	var vende: Button = null
	if ids.any(func(i): return _economy.pode_vender(i)):
		vende = _hud._button("")
		vende.add_theme_font_size_override("font_size", 12)
		vende.pressed.connect(func():
			Audio.click()
			_economy.sell_categoria(cat)
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
	var qtd: Label = _hud._label("0", 16, Ores.UI_COLORS.get(id, _hud.COLOR_TEXT))
	qtd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qtd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(qtd)
	var nome: Label = _hud._label(Items.nome(id), 12, _hud.COLOR_TEXT)
	nome.clip_text = true
	col.add_child(nome)
	var preco: Label = _hud._label("", 10, _hud.COLOR_DIM)
	col.add_child(preco)
	var b: Button = null
	if _economy.pode_vender(id):
		b = _hud._button("Vender…")
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func():
			Audio.click()
			seleciona(id))
		col.add_child(b)
	return {"cell": cell, "label": qtd, "name": nome, "price": preco, "button": b}


## A barra de venda: [ícone nome (tem N)] [-10][-1] N [+1][+10] [Tudo] [Vender N (+X cr)].
func _monta_barra_venda(vbox: VBoxContainer) -> void:
	vbox.add_child(HSeparator.new())
	_sel_box = HBoxContainer.new()
	_sel_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_sel_box)
	_sel_info = _hud._label("Escolha um item (Vender…) pra vender a quantidade que quiser.", 12, _hud.COLOR_DIM)
	_sel_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sel_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sel_box.add_child(_sel_info)
	for passo in [-10, -1]:
		_sel_box.add_child(_botao_passo(passo))
	_sel_qtd_label = _hud._label("", 15, _hud.COLOR_TITLE)
	_sel_qtd_label.custom_minimum_size.x = 40
	_sel_qtd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sel_box.add_child(_sel_qtd_label)
	for passo in [1, 10]:
		_sel_box.add_child(_botao_passo(passo))
	_sel_tudo = _hud._button("Tudo")
	_sel_tudo.add_theme_font_size_override("font_size", 12)
	_sel_tudo.pressed.connect(func():
		Audio.click()
		_sel_qtd = _tem(_sel_id)
		refresh())
	_sel_box.add_child(_sel_tudo)
	_sel_vender = _hud._button("")
	_sel_vender.add_theme_font_size_override("font_size", 12)
	_sel_vender.pressed.connect(func():
		Audio.click()
		vender_selecionado())
	_sel_box.add_child(_sel_vender)


func _botao_passo(passo: int) -> Button:
	var b: Button = _hud._button("%+d" % passo)
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size = Vector2(34, 0)
	b.pressed.connect(func():
		Audio.click()
		_sel_qtd = clampi(_sel_qtd + passo, 0, _tem(_sel_id))
		refresh())
	return b


## Quantas unidades inteiras a vila tem do item.
func _tem(id: String) -> int:
	return int(floorf(_economy.quantidade(id))) if id != "" else 0


## Seleciona o item na barra de venda (a quantidade começa em tudo o que tem).
func seleciona(id: String) -> void:
	_sel_id = id if _economy.pode_vender(id) else ""
	_sel_qtd = _tem(_sel_id)
	refresh()


## Vende a quantidade escolhida do item selecionado. Retorna os créditos.
func vender_selecionado() -> float:
	if _sel_id == "" or _sel_qtd <= 0:
		Audio.error()
		return 0.0
	var ganho: float = _economy.sell(_sel_id, float(_sel_qtd))
	_sel_qtd = mini(_sel_qtd, _tem(_sel_id))
	refresh()
	return ganho


func _refresh_barra_venda() -> void:
	var tem := _tem(_sel_id)
	_sel_qtd = clampi(_sel_qtd, 0, tem)
	var ativo := _sel_id != ""
	for c in _sel_box.get_children():
		if c is Button:
			c.disabled = not ativo or tem <= 0
	if not ativo:
		_sel_info.text = "Escolha um item (Vender…) pra vender a quantidade que quiser."
		_sel_qtd_label.text = "-"
		_sel_vender.text = "Vender"
		return
	_sel_info.text = "%s (tem %d, %s cr cada)" % [Items.nome(_sel_id), tem, str(snappedf(_economy.price_of(_sel_id), 0.1))]
	_sel_qtd_label.text = str(_sel_qtd)
	_sel_vender.text = "Vender %d  (+%d cr)" % [_sel_qtd, int(_sel_qtd * _economy.price_of(_sel_id))]
	_sel_vender.disabled = _sel_qtd <= 0
	for id in _rows:
		var st: StyleBoxFlat = _rows[id].cell.get_theme_stylebox("panel")
		if st:
			st.border_color = Color(1.0, 0.8, 0.35) if id == _sel_id else Color(0.36, 0.28, 0.2)
			st.set_border_width_all(2 if id == _sel_id else 1)


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
	_refresh_barra_venda()


func button_text() -> String:
	return "Armazém: %d cr à venda" % _economy.sale_value()


func has_available_action() -> bool:
	return false
