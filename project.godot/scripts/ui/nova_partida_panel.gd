extends VBoxContainer
## Bloco 113: a tela de NOVA PARTIDA — a escolha da dificuldade (seção 25 do guia). Mora dentro da moldura do menu inicial,
## no padrão do painel de Backups. Cinco perfis (Tranquilo, Normal, Ferro, Personalizado, Criativo): cada um mostra a
## descrição e os 8 números; no Personalizado os sliders ficam liberados (as faixas vêm de perfil_dificuldade.gd).
## "Começar" entrega {perfil, custom} (o que o SaveManager.start_new_game guarda e o nó Dificuldade aplica).

signal comecar(escolha: Dictionary)
signal voltar

const Dificuldade := preload("res://scripts/core/dificuldade.gd")
const Perfil := preload("res://scripts/core/perfil_dificuldade.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.7, 0.66, 0.6)
const COLOR_ALTO := Color(1.0, 0.75, 0.45)
## A barra dos sliders (a pele do jogo só desenha o botão): o trilho escuro e o pedaço já cheio.
const COLOR_TRILHO := Color(0.09, 0.07, 0.06)
const COLOR_TRILHO_BORDA := Color(0.42, 0.31, 0.2)
const COLOR_CHEIO := Color(0.72, 0.48, 0.2)
## Slider travado (fora do Personalizado): só mostra o número.
const ALFA_TRAVADO := 0.65

## Os 8 números, na ordem da tela: [chave, rótulo].
const LINHAS := [
	["primeira_invasao_dia", "Primeira invasão"],
	["invasao_a_cada", "Invasão a cada"],
	["vida_por_onda", "Vida das criaturas por onda"],
	["fome_mult", "Fome"],
	["onda_verao", "Onda solar no verão"],
	["ultimato_greve", "Ultimato da greve"],
	["comida_inicial", "Comida inicial"],
	["preco_venda_mult", "Preço de venda"],
]
const NOMES := {"tranquilo": "Tranquilo", "normal": "Normal", "ferro": "Ferro", "personalizado": "Personalizado", "criativo": "Criativo"}

var _id: String = Dificuldade.PADRAO
## Os números do Personalizado (começam no Normal).
var _custom: Dictionary = {}
var _botoes := {}  # perfil -> Button
var _sliders := {}  # chave -> HSlider
var _valores := {}  # chave -> Label
var _descricao: Label
var _extra: Label
var _montando := false


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	custom_minimum_size = Vector2(560, 0)
	_custom = Dificuldade.perfil_de(Dificuldade.PADRAO).numeros()
	var titulo := _label("NOVA PARTIDA", Tipo.FAIXA, COLOR_TITLE)
	add_child(titulo)
	add_child(_label("Escolha a dificuldade. Ela vale a partida inteira.", Tipo.DETALHE, COLOR_DIM))

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	add_child(fila)
	var grupo := ButtonGroup.new()
	for id in Dificuldade.PERFIS:
		var b := Button.new()
		b.text = NOMES[id]
		b.toggle_mode = true
		b.button_group = grupo
		b.custom_minimum_size = Vector2(0, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", Tipo.CORPO)
		b.pressed.connect(seleciona.bind(id))
		fila.add_child(b)
		_botoes[id] = b

	_descricao = _label("", Tipo.CORPO, COLOR_TEXT)
	_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descricao.custom_minimum_size = Vector2(540, 40)
	add_child(_descricao)

	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 4)
	add_child(grade)
	for linha in LINHAS:
		var chave: String = linha[0]
		var nome := _label(linha[1], Tipo.CORPO, COLOR_TEXT)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nome.custom_minimum_size = Vector2(230, 0)
		grade.add_child(nome)
		var lim: Array = Perfil.AJUSTAVEIS[chave]
		var s := HSlider.new()
		s.min_value = lim[0]
		s.max_value = lim[1]
		s.step = lim[2]
		s.custom_minimum_size = Vector2(190, 20)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var trilho := StyleBoxFlat.new()
		trilho.bg_color = COLOR_TRILHO
		trilho.border_color = COLOR_TRILHO_BORDA
		trilho.set_border_width_all(1)
		trilho.content_margin_top = 4.0
		trilho.content_margin_bottom = 4.0
		s.add_theme_stylebox_override("slider", trilho)
		var cheio := StyleBoxFlat.new()
		cheio.bg_color = COLOR_CHEIO
		cheio.content_margin_top = 4.0
		cheio.content_margin_bottom = 4.0
		s.add_theme_stylebox_override("grabber_area", cheio)
		s.add_theme_stylebox_override("grabber_area_highlight", cheio)
		s.value_changed.connect(_mudou.bind(chave))
		grade.add_child(s)
		_sliders[chave] = s
		var v := _label("", Tipo.CORPO, COLOR_ALTO)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.custom_minimum_size = Vector2(70, 0)
		grade.add_child(v)
		_valores[chave] = v

	_extra = _label("", Tipo.DETALHE, COLOR_ALTO)
	_extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_extra.custom_minimum_size = Vector2(540, 0)
	add_child(_extra)

	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation", 10)
	add_child(rodape)
	var volta := Button.new()
	volta.text = "Voltar"
	volta.custom_minimum_size = Vector2(0, 40)
	volta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volta.add_theme_font_size_override("font_size", Tipo.TITULO)
	volta.pressed.connect(func(): voltar.emit())
	rodape.add_child(volta)
	var comeca := Button.new()
	comeca.text = "Começar"
	comeca.custom_minimum_size = Vector2(0, 40)
	comeca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comeca.add_theme_font_size_override("font_size", Tipo.TITULO)
	comeca.pressed.connect(func(): comecar.emit(escolha()))
	rodape.add_child(comeca)
	set_meta("comeca_button", comeca)
	set_meta("volta_button", volta)

	seleciona(Dificuldade.PADRAO)


## Marca o perfil `id` e mostra os números dele.
func seleciona(id: String) -> void:
	_id = id if id in Dificuldade.PERFIS else Dificuldade.PADRAO
	_botoes[_id].button_pressed = true
	_atualiza()


## O que o "Começar" entrega: {perfil, custom} (custom só vale no Personalizado).
func escolha() -> Dictionary:
	return {"perfil": _id, "custom": _custom.duplicate() if _id == "personalizado" else {}}


func perfil_escolhido() -> String:
	return _id


func slider(chave: String) -> HSlider:
	return _sliders[chave]


func _mudou(valor: float, chave: String) -> void:
	if _montando or _id != "personalizado":
		return
	_custom[chave] = valor
	_atualiza()


func _atualiza() -> void:
	_montando = true
	var p: Resource = Dificuldade.perfil_de(_id, _custom)
	_descricao.text = String(p.descricao)
	for linha in LINHAS:
		var chave: String = linha[0]
		_sliders[chave].value = float(p.get(chave))
		_sliders[chave].editable = _id == "personalizado"
		_sliders[chave].modulate.a = 1.0 if _id == "personalizado" else ALFA_TRAVADO
		_valores[chave].text = _formata(chave, float(p.get(chave)))
	_extra.text = ""
	if p.sem_invasao:
		_extra.text = "Sem invasões. O pacote da Fundação vem x%d e a vila começa com +%d créditos." % [
			roundi(p.recursos_pacote_mult), p.creditos_extras]
	_montando = false


## O valor do jeito que o jogador lê.
static func _formata(chave: String, v: float) -> String:
	match chave:
		"primeira_invasao_dia":
			return "dia %d" % roundi(v)
		"invasao_a_cada":
			return "%d dias" % roundi(v)
		"vida_por_onda":
			return "+%d%%" % roundi(v * 100.0)
		"fome_mult", "preco_venda_mult":
			return "x%s" % str(snappedf(v, 0.01)).replace(".", ",")
		"onda_verao":
			return "%d%%" % roundi(v * 100.0)
		"ultimato_greve":
			return "%d:%02d" % [int(v) / 60, int(v) % 60]
		"comida_inicial":
			return "%d" % roundi(v)
	return str(v)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
