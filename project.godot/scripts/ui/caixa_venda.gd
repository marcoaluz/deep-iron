extends Control
## Bloco 136: a CAIXA DE VENDA do armazém. Nada vende sem passar por ela: o "Vender…" de um item e o botão da categoria
## abrem a caixa, e só Confirmar (ou "Vender tudo", que mostra o total) vende. Cancelar, o X e o Esc fecham sem vender.
##
## Item: "Você está vendendo: [ícone] Gema azul — tem 200, 30 cr cada", a quantidade (−10 / − / campo de digitar / + / +10
## / máx) com o valor em créditos, Vender tudo, Confirmar e Cancelar. Categoria: o resumo (quantos itens e o total) e
## Confirmar/Cancelar. Só o que a Economia deixa vender (`pode_vender`); com "Vender sozinho (auto)" ligado, a caixa avisa
## que o minério que chegar vai ser vendido sozinho.
##
## A caixa cobre a tela com um véu (a roda do mouse não dá zoom: grupo "janela_modal") e fecha com o Esc antes de qualquer
## janela (grupo "fecha_com_esc": `hud.fecha_janela_de_cima`).

const Items := preload("res://scripts/core/items.gd")
const Ores := preload("res://scripts/core/ores.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")

## Vendeu: o item (ou "cat:<categoria>"), a quantidade e os créditos.
signal vendeu(id: String, qtd: int, ganho: float)

var _hud: CanvasLayer
var _economy: Node
## O item à venda ("" = venda da categoria).
var id := ""
## A categoria à venda ("" = venda de um item).
var categoria := ""
## A quantidade escolhida.
var qtd := 0

var _caixa: PanelContainer
var _icone: TextureRect
var _titulo: Label
var _info: Label
var _linha_qtd: HBoxContainer
var _campo: SpinBox
var _total: Label
var _nota: Label
var _tudo: Button
var _max: Button
var _confirmar: Button
var _cancelar: Button


func setup(hud: CanvasLayer, economy: Node) -> void:
	_hud = hud
	_economy = economy
	name = "CaixaVenda"
	add_to_group("janela_modal")
	add_to_group("fecha_com_esc")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # o véu segura o clique: nada atrás vende nem fecha por engano
	var veu := ColorRect.new()
	veu.color = Color(0, 0, 0, 0.45)
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veu)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_caixa = PanelContainer.new()
	_caixa.name = "Caixa"
	_caixa.add_theme_stylebox_override("panel", _hud._panel_style())
	_caixa.custom_minimum_size = Vector2(440, 0)
	centro.add_child(_caixa)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_caixa.add_child(v)
	var topo := HBoxContainer.new()
	v.add_child(topo)
	var t: Label = _hud._label("VENDER", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(t)
	var x: Button = _hud._button("X")
	x.pressed.connect(cancelar)
	topo.add_child(x)
	v.add_child(_hud._label("Você está vendendo:", Tipo.DETALHE, _hud.COLOR_DIM))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	v.add_child(linha)
	_icone = TextureRect.new()
	_icone.custom_minimum_size = Vector2(48, 48)
	_icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	linha.add_child(_icone)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(col)
	_titulo = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	col.add_child(_titulo)
	_info = _hud._label("", Tipo.CORPO, _hud.COLOR_DIM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_info)
	# a quantidade: −10 −1 [campo] +1 +10 máx
	_linha_qtd = HBoxContainer.new()
	_linha_qtd.add_theme_constant_override("separation", 4)
	_linha_qtd.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_linha_qtd)
	for p in [-10, -1]:
		_linha_qtd.add_child(_passo(p))
	_campo = SpinBox.new()
	_campo.name = "Quantidade"
	_campo.min_value = 0
	_campo.step = 1
	_campo.rounded = true
	_campo.custom_minimum_size = Vector2(96, 0)
	_campo.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_campo.select_all_on_focus = true
	_campo.value_changed.connect(func(val: float): _define(int(val)))
	_linha_qtd.add_child(_campo)
	for p in [1, 10]:
		_linha_qtd.add_child(_passo(p))
	_max = _hud._button("máx")
	_max.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_max.pressed.connect(func():
		Audio.click()
		_define(_tem()))
	_linha_qtd.add_child(_max)
	_total = _hud._label("", Tipo.TITULO, _hud.COLOR_TITLE)
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_total)
	_nota = _hud._label("", Tipo.DETALHE, Color(1.0, 0.75, 0.45))
	_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_nota)
	_tudo = _hud._button("")
	_tudo.name = "VenderTudo"
	_tudo.pressed.connect(func(): vender_tudo())
	v.add_child(_tudo)
	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation", 8)
	v.add_child(rodape)
	_cancelar = _hud._button("Cancelar  (Esc)")
	_cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancelar.pressed.connect(cancelar)
	rodape.add_child(_cancelar)
	_confirmar = _hud._button("Confirmar")
	_confirmar.name = "Confirmar"
	_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmar.pressed.connect(func(): confirmar())
	rodape.add_child(_confirmar)
	visible = false


func _passo(p: int) -> Button:
	var b: Button = _hud._button("%+d" % p)
	b.add_theme_font_size_override("font_size", Tipo.DETALHE)
	b.custom_minimum_size = Vector2(38, 0)
	b.pressed.connect(func():
		Audio.click()
		_define(qtd + p))
	return b


## Abre a caixa pra UM item (a quantidade começa em tudo o que tem). Item que não se vende: não abre.
func abre_item(item: String) -> bool:
	if item == "" or not _economy.pode_vender(item) or _tem_de(item) <= 0:
		Audio.error()
		return false
	id = item
	categoria = ""
	qtd = _tem_de(item)
	_mostra()
	return true


## Abre a caixa pra vender a CATEGORIA inteira (só o que se vende dela).
func abre_categoria(cat: String) -> bool:
	if _valor_categoria(cat) <= 0:
		Audio.error()
		return false
	id = ""
	categoria = cat
	qtd = 0
	_mostra()
	return true


func _mostra() -> void:
	visible = true
	move_to_front()
	Audio.ui_open()
	_atualiza()
	_foco.call_deferred()


func _foco() -> void:
	if is_inside_tree() and visible:
		_confirmar.grab_focus()


## Quantas unidades inteiras a vila tem do item aberto.
func _tem() -> int:
	return _tem_de(id)


func _tem_de(item: String) -> int:
	return int(floorf(_economy.quantidade(item))) if item != "" else 0


func _define(n: int) -> void:
	qtd = clampi(n, 0, _tem())
	_atualiza()


func _valor_categoria(cat: String) -> int:
	var total := 0
	for i in Items.da_categoria(cat):
		if _economy.pode_vender(i):
			total += _economy.valor_de(i)
	return total


## Quanto rende a quantidade escolhida agora (o preço da Economia: estação, dificuldade, mercado).
func ganho_previsto() -> int:
	if categoria != "":
		return _valor_categoria(categoria)
	return int(qtd * _economy.price_of(id))


func _atualiza() -> void:
	if not visible:
		return
	var auto: bool = bool(_economy.get("auto_sell"))
	if categoria != "":
		_icone.texture = null
		var ids: Array = Items.da_categoria(categoria).filter(func(i): return _economy.pode_vender(i) and _tem_de(i) > 0)
		_titulo.text = "Toda a categoria %s" % Items.nome_categoria(categoria).to_lower()
		var partes: Array = []
		for i in ids:
			partes.append("%d %s" % [_tem_de(i), Items.nome(i).to_lower()])
		_info.text = ", ".join(partes) if not partes.is_empty() else "nada pra vender"
		_linha_qtd.visible = false
		_tudo.visible = false
		_total.text = "Recebe: +%d cr" % ganho_previsto()
		_confirmar.text = "Confirmar  (+%d cr)" % ganho_previsto()
		_confirmar.disabled = ganho_previsto() <= 0
		_nota.text = "Vender sozinho (auto) está ligado: o minério que chegar também é vendido sozinho." if auto and categoria == "minerio" else ""
		_nota.visible = _nota.text != ""
		return
	var tem := _tem()
	var preco: float = _economy.price_of(id)
	_icone.texture = _icone_de(id)
	_titulo.text = Items.nome(id)
	_info.text = "tem %d, %s cr cada" % [tem, str(snappedf(preco, 0.1))]
	_linha_qtd.visible = true
	_campo.max_value = tem
	_campo.set_value_no_signal(qtd)
	_total.text = "%d × %s cr = %d cr" % [qtd, str(snappedf(preco, 0.1)), ganho_previsto()]
	_tudo.visible = true
	_tudo.text = "Vender tudo  (%d = +%d cr)" % [tem, int(tem * preco)]
	_tudo.disabled = tem <= 0
	_confirmar.text = "Confirmar  (vender %d)" % qtd
	_confirmar.disabled = qtd <= 0
	_nota.text = "Vender sozinho (auto) está ligado: o %s que chegar no armazém é vendido sozinho." % Items.nome(id).to_lower() if auto and Ores.TYPES.has(id) else ""
	_nota.visible = _nota.text != ""


func _icone_de(item: String) -> Texture2D:
	var t: Texture2D = Icones.tex(Items.icone(item))
	if t == null and Ores.CHUNK_TEXTURES.has(item):
		t = Ores.CHUNK_TEXTURES[item]
	return t


## Vende o que está na caixa (a quantidade escolhida ou a categoria). Retorna os créditos.
func confirmar() -> float:
	if not visible:
		return 0.0
	var ganho := 0.0
	var vendido := qtd
	var chave := id
	if categoria != "":
		chave = "cat:" + categoria
		ganho = _economy.sell_categoria(categoria)
	elif qtd > 0:
		ganho = _economy.sell(id, float(qtd))
	if ganho <= 0.0:
		Audio.error()
		_atualiza()
		return 0.0
	Audio.ui("confirmar")
	visible = false
	vendeu.emit(chave, vendido, ganho)
	return ganho


## "Vender tudo" (com o total à vista no botão): a quantidade vira tudo o que tem e vende.
func vender_tudo() -> float:
	_define(_tem())
	return confirmar()


func cancelar() -> void:
	if visible:
		Audio.ui_close()
	visible = false


## O Esc (hud.fecha_janela_de_cima): fecha sem vender.
func fecha_esc() -> bool:
	if not visible:
		return false
	cancelar()
	return true


func refresh() -> void:
	if visible:
		if categoria == "" and _tem() <= 0:  # acabou o estoque com a caixa aberta (o auto vendeu, uma obra levou)
			cancelar()
			return
		qtd = mini(qtd, _tem())
		_atualiza()
