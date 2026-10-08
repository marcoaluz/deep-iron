extends CanvasLayer
## HUD no estilo Frostpunk (Bloco 31), montado por código. Bloco 95 (layout v2): mais espaço pro mapa.
##   - TOPO: os recursos à esquerda (créditos, minério, madeira, matéria-prima, comida, camas, ânimo, saúde;
##     detalhes na dica), a HORA grande no meio, e à direita a estação, a velocidade, o menu "Janelas" e o "?".
##     ("Vender" e "auto" ficam na janela do Armazém.)
##   - ESQUERDA: a ABA FINA com ícones — Pessoas (Tab ou o mouse abre a lista da força de trabalho, com os
##     parados e os com problema primeiro), Obras (barrinha + martelo cinza = esperando engenheiro), Missões.
##   - DIREITA: a coluna de ALERTAS (ícone + número; clicar leva ao lugar) — scripts/ui/alertas.gd.
##   - EMBAIXO: a barra de funções AGRUPADA (Produção | Serviço | Defesa), só ícone + contador, só as funções
##     já liberadas; o nome e a tecla vão na dica. Acima dela, à esquerda, o cartão do selecionado.
##   - Canto de baixo à direita: a pilha de avisos (avisos.gd) e o espaço do rastreador de missões.
##   - Atalhos de teclado num painel que só aparece com H (ou o botão "?").

const COLOR_PANEL := Color(0.09, 0.075, 0.07, 0.88)
const COLOR_BORDER := Color(0.55, 0.38, 0.18)
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.65, 0.6, 0.55)
const COLOR_HUNGER_OK := Color(0.45, 0.8, 0.35)
const COLOR_HUNGER_LOW := Color(0.95, 0.75, 0.2)
const COLOR_HUNGER_BAD := Color(0.9, 0.25, 0.2)
const COLOR_CARGO := Color(0.78, 0.45, 0.25)
const COLOR_DAY := Color(1.0, 0.78, 0.4)
const COLOR_NIGHT := Color(0.55, 0.62, 1.0)
const COLOR_INJURED := Color(1.0, 0.5, 0.45)
const COLOR_OVERTIME := Color(0.6, 0.7, 1.0)
const COLOR_COOK := Color(0.95, 0.9, 0.6)
const COLOR_LUMBER := Color(0.85, 0.66, 0.45)
const COLOR_WOOD := Color(0.78, 0.6, 0.4)
const COLOR_IRRITATED := Color(1.0, 0.72, 0.35)
const COLOR_FURIOUS := Color(1.0, 0.35, 0.28)
const COLOR_NO_JOB := Color(1.0, 0.62, 0.3)  # Bloco 25: "sem função" salta aos olhos
const COLOR_MINER := Color(0.95, 0.75, 0.45)
const COLOR_HUNTER := Color(0.8, 0.9, 0.55)
const COLOR_GUARD := Color(0.95, 0.55, 0.45)
const COLOR_RESEARCH := Color(0.55, 0.95, 0.65)
const COLOR_DOCTOR := Color(0.6, 0.9, 0.85)
const COLOR_ENGINEER := Color(1.0, 0.6, 0.25)
const Ores := preload("res://scripts/core/ores.gd")
const Settings := preload("res://scripts/core/settings.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96
const Tipo := preload("res://scripts/ui/tipografia.gd")
const STATE_COLORS := {
	"idle": Color(0.65, 0.6, 0.55),
	"eating": Color(0.5, 0.85, 0.4),
	"mining": Color(0.95, 0.6, 0.3),
	"storing": Color(0.45, 0.7, 1.0),
	"manual": Color(1.0, 0.84, 0.25),
	"home": Color(0.55, 0.62, 1.0),
	"gathering": Color(0.75, 0.9, 0.5),
	"delivering": Color(0.95, 0.85, 0.5),
	"chopping": Color(0.85, 0.66, 0.45),
	"hauling": Color(0.8, 0.7, 0.5),
	"infirmary": Color(1.0, 0.5, 0.45),
	"leisure": Color(0.95, 0.75, 0.45),
	"strike": Color(1.0, 0.35, 0.28),
	"robot": Color(0.5, 1.0, 0.95),
	"guard": Color(0.95, 0.55, 0.45),
	"training": Color(0.9, 0.75, 0.5),
	"research": Color(0.55, 0.95, 0.65),
	"foraging": Color(0.75, 0.9, 0.5),  # Bloco 27
	"hunting": Color(0.8, 0.9, 0.55),
	"stocking": Color(0.8, 0.85, 0.6),
	"fetching": Color(0.95, 0.85, 0.5),
	"cooking": Color(1.0, 0.75, 0.45),
	"doctor": Color(0.6, 0.9, 0.85),  # Bloco 30
	"building": Color(1.0, 0.6, 0.25),  # Bloco 31
}
## Barra de ordens: uma entrada por função, na ordem dos botões.
## [job, nome, tecla, ícone, método do main.gd, cor, dica]
## Função nova = uma linha aqui (e o outfit + item na mão dela, regra do Bloco 28/29).
const ORDER_JOBS := [
	["minerador", "Minerador", "1", "res://assets/game/pickaxe.png", "toggle_miner", COLOR_MINER,
		"Minera nas jazidas e leva o minério pro armazém."],
	["caçador", "Caçador", "2", "res://assets/game/bow.png", "toggle_hunter", COLOR_HUNTER,
		"Trabalha na clareira: caça nas tocas (com arco) e colhe fruta na horta; só desce pra mina pra deixar a matéria-prima no armazém."],
	["médico", "Médico", "3", "res://assets/game/bandage.png", "toggle_doctor", COLOR_DOCTOR,
		"Plantão dentro da Enfermaria: internados curam bem mais rápido."],
	["engenheiro", "Engenheiro", "4", "res://assets/game/hammer.png", "toggle_engineer", COLOR_ENGINEER,
		"Vai até as obras encomendadas (casa, melhoria da Vila, ferramenta, peça da Escavadeira) e constrói. Sem engenheiro, nada sai do lugar."],
	["cozinheiro", "Cozinheiro", "C", "res://assets/game/food_basket.png", "toggle_cook", COLOR_COOK,
		"Busca matéria-prima no armazém e prepara a comida na cozinha."],
	["lenhador", "Lenhador", "L", "res://assets/game/axe.png", "toggle_lumber", COLOR_LUMBER,
		"Corta madeira na clareira e leva pro armazém."],
	["guarda", "Guarda", "X", "res://assets/game/lanca.png", "toggle_guard", COLOR_GUARD,
		"Treina de dia no campo e defende os portões à noite. A arma se gasta na luta: quebrou, busca outra no Arsenal."],
	["pesquisador", "Pesquisador", "Z", "res://assets/game/note.png", "toggle_research", COLOR_RESEARCH,
		"Trabalha no laboratório de dia, gerando pontos pra pesquisa em andamento."],
	["fundidor", "Fundidor", "6", "res://assets/game/ui/icones/it_barra_ferro.png", "toggle_smelter", Color(1.0, 0.62, 0.32),
		"Opera a Fornalha: busca o minério no armazém, funde as barras encomendadas e leva pro armazém. Sem ordem, não faz nada."],
	["ferreiro", "Ferreiro", "7", "res://assets/game/ui/icones/it_martelo.png", "toggle_smith", Color(0.62, 0.74, 1.0),
		"Opera a Oficina e o Arsenal: ferramentas, armas, equipamentos, pregos e ferragens — só o que foi encomendado. (O engenheiro fica nas obras.)"],
	["padre", "Padre", "8", "res://assets/game/ui/icones/padre.png", "toggle_priest", Color(0.78, 0.7, 0.95),
		"Só UM, e só homem (selecione um ipezinho). Fica na igreja: missa de domingo, funeral e aconselha quem anda zangado. Abre com a Vila no estágio do padre."],
	["carpinteiro", "Carpinteiro", "9", "res://assets/game/ui/icones/carpinteiro.png", "toggle_carpenter", Color(0.86, 0.7, 0.45),
		"Opera a Carpintaria: tábuas e camas de tábua, só o que foi encomendado. Monta as camas novas nas casas."],  # Bloco 94
]
## Bloco 92: largura do botão da barra de ordens (era 90; com o Padre são 14 botões na tela de 1280 px).
## Bloco 94: com o Carpinteiro são 15: 78 px.
const ORDER_BUTTON_W := 78.0
const TOP_BAR_H := 40.0
const SIDE_MARGIN := 10.0
## Bloco 95: a barra de funções AGRUPADA (só ícone + contador; o nome e a tecla na dica).
const GRUPOS_FUNCOES := [["PRODUÇÃO", ["minerador", "lenhador", "caçador", "cozinheiro", "fundidor", "ferreiro", "carpinteiro"]],
	["SERVIÇO", ["engenheiro", "médico", "pesquisador", "padre"]], ["DEFESA", ["guarda"]]]
## Bloco 95: botão de função (ícone 32 no meio, o contador no canto).
const BOTAO_FUNCAO := Vector2(46, 46)
## Bloco 95: a aba fina da esquerda e a gaveta da lista que sai dela.
const TIRA_W := 40.0
const GAVETA_W := 300.0
## Bloco 95: abaixo desta largura lógica (px) a barra de cima esconde os textos que têm dica (estação, semana).
const LARGURA_ESTREITA := 1200.0

@export var ore_icon: Texture2D
@export var coin_icon: Texture2D
## Altura máxima da lista de ipezinhos antes de virar rolagem.
@export var worker_list_max_height: float = 300.0
## Atualizações do HUD por segundo.
@export var refresh_rate: float = 10.0

var _main: Node
var _economy: Node
var _day_night: Node
var _hub: Node
var _dig: Node
var _oficina: Node
var _inf: Node
var _morale: Node
var _finds: Node
var _abyss: Node
var _defense: Node
var _diary: Node
var _research: Node
var _sun: Node
var _sun_overlay: ColorRect

# topo
var _phase_label: Label
var _phase_time_label: Label
var _phase_bar: ProgressBar
var _chips: Dictionary = {}  # id -> {box, value}
var _last_credits: float = -1.0
var _clock_box: HBoxContainer  # Bloco 95: a hora grande no meio da barra de cima
var _dia_semana_label: Label
var _menu_janelas: MenuButton
var _falta_porcoes := 0
# esquerda
var _left_panel: PanelContainer
var _workers_count_label: Label
var _no_job_label: Label
var _obras_label: Label
var _unarmed_label: Label  # Bloco 35: guardas desarmados (arma quebrou)
var _downed_label: Label  # Bloco 36: guardas caídos esperando o médico
var _cold_label: Label  # Bloco 42: sem casaco no inverno
var _build_menu: PanelContainer  # Bloco 46: menu de construção (estilo Frostpunk)
var _build_button: Button
var _collapse_button: Button
var _workers_title: Label
var _rows_scroll: ScrollContainer
var _rows_box: VBoxContainer
var _rows: Dictionary = {}  # ipezinho -> {panel, name, state, tag, hunger, cargo, joy}
# embaixo
var _order_bar: PanelContainer
var _selection_caption: Label
var _job_buttons: Dictionary = {}  # job -> {button, count}
var _no_job_button: Button
var _overtime_button: Button
var _grupos: Dictionary = {}  # Bloco 95: nome do grupo -> a coluna dele na barra
# esquerda (Bloco 95): a aba fina e as gavetas
var _tira: VBoxContainer
var _tira_pessoas: Button
var _tira_obras: Button
var _gaveta_por_mouse := false
var _obras_panel: PanelContainer
var _obras_box: VBoxContainer
# direita (Bloco 95): alertas; canto: avisos e missões
var _alertas: Node
var _avisos: Node
var _missoes: Node
var _missoes_mgr: Node  # Bloco 100: o gerenciador de missões (o _missoes acima é o rastreador do canto)
var _tira_missoes: Button
var _panels: Dictionary = {}  # id ("hub", "escavadeira", ...) -> janela
var _panel_ordem: Array[String] = []  # Bloco 95: a ordem no menu "Janelas"
# atalhos
var _hint_panel: PanelContainer

var _refresh_timer := 0.0
var _style_row := _row_style(false)
var _style_row_selected := _row_style(true)


func _ready() -> void:
	add_to_group("hud")
	if UiSkin.ok():
		get_tree().root.theme = UiSkin.theme()  # Prompt 20: a pele nova vale pra tudo (dicas, menus)
	UiSkin.tema_na_camada(self)  # Bloco 95: e chega nos Controls do HUD (o tema da raiz não atravessa o CanvasLayer)
	_main = get_parent()
	_ferramentas_debug.call_deferred()
	_economy = get_tree().get_first_node_in_group("economy")
	_day_night = get_tree().get_first_node_in_group("day_night")
	_hub = get_tree().get_first_node_in_group("village_hub")
	_dig = get_tree().get_first_node_in_group("escavadeira")
	_oficina = get_tree().get_first_node_in_group("oficina")
	_inf = get_tree().get_first_node_in_group("enfermarias")
	_morale = get_tree().get_first_node_in_group("morale")
	_finds = get_tree().get_first_node_in_group("finds")
	_abyss = get_tree().get_first_node_in_group("elevador_abismo")
	_defense = get_tree().get_first_node_in_group("defense")
	_diary = get_tree().get_first_node_in_group("diary")
	_research = get_tree().get_first_node_in_group("research")
	_sun = get_tree().get_first_node_in_group("sun")
	if _inf:
		_inf.patient_died.connect(func(who: String, cause: String):
			show_banner("%s MORREU" % who.to_upper(),
				"Machucado grave (%s) e sem leito na enfermaria. Descansa no cemitério ao lado dela." % (
					{"galho": "queda de galho", "explosao": "explosão do reator", "lumivoro": "ataque de Lumívoro", "ferrugento": "ataque de Ferrugento", "radiacao": "radiação solar"}.get(cause, "acidente na mina"))))
	if _dig:
		_dig.completed.connect(func():
			show_banner("ESCAVADEIRA CONCLUÍDA!",
				"Conquista: Deep Iron — a descida pro nível 2 abriu ao lado da escavadeira."))
	_build()
	SaveManager.saved.connect(func(reason: String):
		show_toast("Jogo salvo (%s)" % reason))
	SaveManager.save_failed.connect(func(msg: String):
		show_toast("Falha ao salvar: %s" % msg, COLOR_HUNGER_BAD))
	SaveManager.loaded.connect(func(): show_toast("Save carregado"))
	if _main.has_signal("selection_changed"):
		_main.selection_changed.connect(func(_u): _refresh())
	WindowManager.ui_scale_changed.connect(func(_f: float): _reposiciona.call_deferred())


func _process(delta: float) -> void:
	_update_cursor(delta)
	_gaveta_mouse()
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 1.0 / refresh_rate
		_refresh()


# =================================================================== montagem
func _build() -> void:
	_build_top_bar()
	_build_order_bar()
	_monta_cartao_selecionado()
	_build_menu = preload("res://scripts/core/build_menu.gd").new()
	add_child(_build_menu)
	_build_menu.setup(self)
	_build_workforce_panel()
	_build_janelas()
	_build_hints()
	_build_avisos()
	set_hints_visible(Settings.get_value("hud", "show_hints", false))
	set_collapsed.call_deferred(Settings.get_value("hud", "collapsed", false), false)
	_reposiciona.call_deferred()


# ------------------------------------------------------------ topo: recursos
func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	var style: StyleBox
	if UiSkin.ok():
		style = UiSkin.barra_topo()  # Prompt 20: a viga de madeira com cintas de ferro
	else:
		var f := _panel_style() as StyleBoxFlat
		f.set_corner_radius_all(0)
		f.border_width_top = 0
		f.border_width_left = 0
		f.border_width_right = 0
		f.set_content_margin_all(6)
		f.content_margin_left = 12
		f.content_margin_right = 12
		style = f
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = TOP_BAR_H
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	# Bloco 95: os recursos à esquerda (o "Vender" e o "auto" foram pra janela do Armazém)
	_chip(row, "credits", _ic("creditos", coin_icon), "Créditos")
	_chip(row, "ore", _ic("minerio", ore_icon), "Minério")
	_chip(row, "wood", _ic("madeira", load("res://assets/game/wood_log.png")), "Madeira")
	_chip(row, "raw", _ic("materia_prima", load("res://assets/game/raw_food.png")), "Matéria-prima")
	_chip(row, "food", _ic("comida", load("res://assets/game/food_basket.png")), "Comida pronta")
	row.add_child(VSeparator.new())
	_chip(row, "beds", _ic("camas", null), "Camas")
	_chip(row, "joy", _ic("animo", null), "Ânimo")
	_chip(row, "health", _ic("saude", load("res://assets/game/bandage.png")), "Saúde")

	# Bloco 95: a HORA grande no meio (o dia da semana e o dia do jogo do lado, a fase embaixo)
	var esq := Control.new()
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(esq)
	var relogio := HBoxContainer.new()
	relogio.add_theme_constant_override("separation", 6)
	row.add_child(relogio)
	_clock_box = relogio
	var hora := VBoxContainer.new()
	hora.add_theme_constant_override("separation", 0)
	relogio.add_child(hora)
	_phase_label = _label("05:00", Tipo.TITULO_JANELA, COLOR_DAY)
	UiSkin.usa_fonte(_phase_label, "texto", Tipo.PIXEL_2)
	_phase_label.mouse_filter = Control.MOUSE_FILTER_STOP  # (dica com os horários do dia)
	hora.add_child(_phase_label)
	_phase_bar = _bar(COLOR_DAY)
	_phase_bar.custom_minimum_size = Vector2(80, 3)
	hora.add_child(_phase_bar)
	var dia := VBoxContainer.new()
	dia.add_theme_constant_override("separation", 0)
	dia.alignment = BoxContainer.ALIGNMENT_CENTER
	relogio.add_child(dia)
	_dia_semana_label = _label("SEG", Tipo.CORPO, COLOR_TEXT)
	dia.add_child(_dia_semana_label)
	_phase_time_label = _label("", Tipo.DETALHE, COLOR_DIM)
	_phase_time_label.mouse_filter = Control.MOUSE_FILTER_STOP
	dia.add_child(_phase_time_label)
	var dir := Control.new()
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dir)

	_chip(row, "sun", _ic("primavera", null), "Estação", false)
	_build_speed(row)
	_menu_janelas = MenuButton.new()  # Bloco 95: as janelas que não abrem clicando num prédio (e todas as outras)
	_menu_janelas.text = "Janelas"
	_menu_janelas.flat = false
	_menu_janelas.focus_mode = Control.FOCUS_NONE
	_menu_janelas.tooltip_text = "Todas as janelas (as teclas de cada uma aparecem na lista). Os prédios também abrem clicando no mapa."
	_menu_janelas.add_theme_font_size_override("font_size", Tipo.CORPO)
	if UiSkin.ok():
		UiSkin.aplica_botao(_menu_janelas)
	_menu_janelas.about_to_popup.connect(_monta_menu_janelas)
	_menu_janelas.get_popup().id_pressed.connect(_menu_janelas_escolheu)
	_menu_janelas.get_popup().add_theme_font_size_override("font_size", Tipo.CORPO)
	row.add_child(_menu_janelas)
	var help := _button("?")
	help.tooltip_text = "Atalhos de teclado (H)"
	help.custom_minimum_size = Vector2(26, 0)
	help.pressed.connect(func():
		Audio.click()
		toggle_hints())
	row.add_child(help)


## Ícone + número (+ rótulo curto). O nome e os detalhes vão no tooltip.
func _chip(row: HBoxContainer, id: String, icon_tex: Texture2D, title: String, show_title: bool = true) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.mouse_filter = Control.MOUSE_FILTER_STOP  # pra ter tooltip
	box.tooltip_text = title
	row.add_child(box)
	if icon_tex:
		var ic := _icon(icon_tex)
		if icon_tex.get_width() == 24:
			ic.custom_minimum_size = Vector2(24, 24)  # Prompt 21: ícone novo em pixel inteiro
		box.add_child(ic)
	elif show_title:
		box.add_child(_label(title, Tipo.DETALHE, COLOR_DIM))
	var value := _label("0", Tipo.TITULO, COLOR_TEXT)
	UiSkin.usa_fonte(value, "texto", Tipo.PIXEL_1)  # Prompt 22: números do HUD (largura fixa)
	box.add_child(value)
	_chips[id] = {"box": box, "value": value, "title": title, "icon": box.get_child(0) if icon_tex else null}


func _set_chip(id: String, text: String, color: Color, tip: String, show: bool = true) -> void:
	if not _chips.has(id):
		return
	var c: Dictionary = _chips[id]
	c.box.visible = show
	c.value.text = text
	c.value.add_theme_color_override("font_color", color)
	c.box.tooltip_text = "%s\n%s" % [c.title, tip] if tip != "" else c.title


func _icon(tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


# ------------------------------------------------------------ embaixo: barra de ordens
func _build_order_bar() -> void:
	var bar := PanelContainer.new()
	var style: StyleBox = UiSkin.barra() if UiSkin.ok() else _panel_style()
	if style is StyleBoxFlat:
		style.set_content_margin_all(8)
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -SIDE_MARGIN
	add_child(bar)
	_order_bar = bar
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(row)
	# Bloco 46: CONSTRUIR abre o menu de construção por abas (também na barra de espaço)
	var g_build := _grupo_barra(row, "")
	var build := _order_button(g_build, "Construir", "Espaço", _ic("construir", load("res://assets/game/hammer.png"), false), COLOR_TITLE,
		"Menu de construção: casas, cozinha, lazer, pesquisa, defesa, coleta automática…", true)
	build.button.pressed.connect(toggle_build_menu)
	_build_button = build.button
	# Bloco 95: as funções em grupos (Produção | Serviço | Defesa); só ícone + contador; o nome vai na dica
	var por_job := {}
	for entry in ORDER_JOBS:
		por_job[entry[0]] = entry
	for g in GRUPOS_FUNCOES:
		var gh := _grupo_barra(row, g[0])
		_grupos[g[0]] = gh.get_parent()
		for job in g[1]:
			var entry: Array = por_job[job]
			var info := _order_button(gh, entry[1], entry[2], _ic(Icones.FUNCAO.get(job, ""), load(entry[3]), false), entry[5], entry[6])
			info.button.pressed.connect(Callable(_main, entry[4]))
			info["grupo"] = g[0]
			_job_buttons[job] = info
	var g_ordem := _grupo_barra(row, "ORDENS")
	var none := _order_button(g_ordem, "Sem função", "0", _ic("sem_funcao", null, false), COLOR_NO_JOB,
		"Tira a função: entregam o que estiverem carregando e esperam no Centro da Vila.")
	none.button.pressed.connect(_main.clear_job)
	none.button.toggle_mode = false
	_no_job_button = none.button
	var extra := _order_button(g_ordem, "Turno extra", "T", _ic("turno_extra", null, false), COLOR_OVERTIME,
		"Continuam trabalhando à noite (e vão ficando zangados).")
	extra.button.pressed.connect(_main.toggle_overtime)
	_overtime_button = extra.button


## Bloco 95: um grupo da barra de funções: o nome pequeno em cima e os botões em fila. Devolve a fila.
func _grupo_barra(row: HBoxContainer, nome: String) -> HBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v)
	var l := _label(nome, Tipo.DETALHE, COLOR_DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	return h


## Botão grande da barra de ordens: ícone, nome, tecla e contador. Fica "aceso"
## (pressionado) quando TODOS os selecionados já têm aquela função.
func _order_button(row: HBoxContainer, title: String, key: String, icon_tex: Texture2D, color: Color, tip: String, com_nome := false) -> Dictionary:
	var b := _button("")
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(BOTAO_FUNCAO.x * (2.0 if com_nome else 1.0), BOTAO_FUNCAO.y)
	if UiSkin.ok():
		UiSkin.aplica_botao(b, true)  # Prompt 20: placa de ferro com rebites; aceso = borda âmbar
	b.tooltip_text = "%s  (tecla %s)\n%s\nCom ipezinhos selecionados: aplica. Se todos já forem, tira." % [title, key, tip]
	if not UiSkin.ok():
		var on := StyleBoxFlat.new()
		on.bg_color = Color(0.42, 0.3, 0.12)
		on.border_color = COLOR_TITLE
		on.set_border_width_all(2)
		on.set_corner_radius_all(3)
		b.add_theme_stylebox_override("pressed", on)
		b.add_theme_stylebox_override("hover_pressed", on)
	row.add_child(b)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(top)
	if icon_tex:
		var icon := _icon(icon_tex)
		icon.custom_minimum_size = Vector2(32, 32) if icon_tex.get_width() == 32 else Vector2(22, 22)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(icon)
	if com_nome:
		var name_label := _label(title, Tipo.CORPO, color)
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(name_label)
	# o contador no canto de baixo (número pixel com contorno: lê em cima do ícone)
	var count := _label("", Tipo.TITULO, COLOR_TEXT)
	UiSkin.usa_fonte(count, "texto", Tipo.PIXEL_1)
	count.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	count.add_theme_constant_override("outline_size", 4)
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	count.grow_vertical = Control.GROW_DIRECTION_BEGIN
	count.offset_right = -3.0
	count.offset_bottom = 1.0
	b.add_child(count)
	return {"button": b, "count": count, "nome": title}


# ------------------------------------------------------------ esquerda: força de trabalho
func _build_workforce_panel() -> void:
	# Bloco 95: a ABA FINA da esquerda (ícones): pessoas (Tab ou o mouse), obras e missões (em breve)
	_tira = VBoxContainer.new()
	_tira.add_theme_constant_override("separation", 4)
	_tira.position = Vector2(SIDE_MARGIN, TOP_BAR_H + SIDE_MARGIN)
	add_child(_tira)
	_tira_pessoas = _tira_botao("pessoas", "Pessoas  (Tab, ou passe o mouse)\nA força de trabalho: primeiro quem está parado e quem tem problema.")
	_tira_pessoas.pressed.connect(func():
		Audio.click()
		toggle_pessoas())
	_tira_pessoas.mouse_entered.connect(func():
		if not _left_panel.visible:
			_abre_gaveta(true))
	_tira_obras = _tira_botao("construir", "Obras\nO que foi encomendado e quanto falta (martelo cinza = esperando engenheiro).")
	_tira_obras.pressed.connect(func():
		Audio.click()
		toggle_obras())
	_tira_missoes = _tira_botao("missoes", "Missões  (,)\nA campanha: o capítulo em andamento e o que falta.")
	_tira_missoes.pressed.connect(func():
		Audio.click()
		_tira_missoes.set_pressed_no_signal(false)
		toggle_panel("missoes"))

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.position = Vector2(SIDE_MARGIN + TIRA_W + 6.0, TOP_BAR_H + SIDE_MARGIN)
	panel.custom_minimum_size = Vector2(GAVETA_W, 0)
	panel.visible = false
	add_child(panel)
	_left_panel = panel
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("FORÇA DE TRABALHO", Tipo.TITULO, COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_workers_count_label = _label("", Tipo.CORPO, COLOR_TEXT)
	head.add_child(_workers_count_label)
	_collapse_button = _button("–")
	_collapse_button.tooltip_text = "Recolher/abrir a lista de ipezinhos"
	_collapse_button.custom_minimum_size = Vector2(26, 0)
	_collapse_button.pressed.connect(func():
		Audio.click()
		set_collapsed(_collapse_button.text == "–"))
	head.add_child(_collapse_button)

	_no_job_label = _label("", Tipo.CORPO, COLOR_NO_JOB)
	_no_job_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_no_job_label)
	_obras_label = _label("", Tipo.CORPO, COLOR_ENGINEER)
	_obras_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_obras_label)
	_unarmed_label = _label("", Tipo.CORPO, COLOR_NO_JOB)
	_unarmed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unarmed_label.visible = false
	v.add_child(_unarmed_label)
	_downed_label = _label("", Tipo.CORPO, Color(1.0, 0.4, 0.35))
	_downed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_downed_label.visible = false
	v.add_child(_downed_label)
	_cold_label = _label("", Tipo.CORPO, Color(0.7, 0.85, 1.0))
	_cold_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cold_label.visible = false
	v.add_child(_cold_label)

	_workers_title = _label("IPEZINHOS", Tipo.DETALHE, COLOR_DIM)
	v.add_child(_workers_title)
	_rows_scroll = ScrollContainer.new()
	_rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_rows_scroll)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 4)
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_scroll.add_child(_rows_box)

	# Bloco 95: a gaveta das OBRAS (a barrinha, o martelo e quanto falta; clicar leva até a obra)
	_obras_panel = PanelContainer.new()
	_obras_panel.add_theme_stylebox_override("panel", _panel_style())
	_obras_panel.position = panel.position
	_obras_panel.custom_minimum_size = Vector2(GAVETA_W, 0)
	_obras_panel.visible = false
	add_child(_obras_panel)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 4)
	_obras_panel.add_child(ov)
	ov.add_child(_label("OBRAS", Tipo.TITULO, COLOR_TITLE))
	_obras_box = VBoxContainer.new()
	_obras_box.add_theme_constant_override("separation", 4)
	ov.add_child(_obras_box)


## Bloco 95: botão da aba fina (ícone, dica e um numerozinho no canto).
func _tira_botao(icone: String, dica: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(TIRA_W, TIRA_W)
	b.icon = Icones.tex(icone, true)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.tooltip_text = dica
	if UiSkin.ok():
		UiSkin.aplica_botao(b, true)
	_tira.add_child(b)
	var n := _label("", Tipo.DETALHE, Color(1.0, 0.85, 0.5))
	UiSkin.usa_fonte(n, "texto", Tipo.PIXEL_1)
	n.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	n.add_theme_constant_override("outline_size", 4)
	n.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	n.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	n.grow_vertical = Control.GROW_DIRECTION_BEGIN
	n.offset_right = -2.0
	n.offset_bottom = 2.0
	n.name = "Num"
	b.add_child(n)
	return b


## Bloco 95: abre/fecha a lista de pessoas (Tab). por_mouse = abriu passando o mouse (fecha quando o mouse sai).
func toggle_pessoas() -> void:
	if _left_panel.visible:
		_fecha_gavetas()
	else:
		_abre_gaveta(false)


func _abre_gaveta(por_mouse: bool) -> void:
	_obras_panel.visible = false
	_tira_obras.set_pressed_no_signal(false)
	_left_panel.visible = true
	_left_panel.move_to_front()
	_tira_pessoas.set_pressed_no_signal(true)
	_gaveta_por_mouse = por_mouse
	_refresh()


func toggle_obras() -> void:
	if _obras_panel.visible:
		_fecha_gavetas()
		return
	_left_panel.visible = false
	_tira_pessoas.set_pressed_no_signal(false)
	_obras_panel.visible = true
	_obras_panel.move_to_front()
	_tira_obras.set_pressed_no_signal(true)
	_gaveta_por_mouse = false
	_refresh_obras()


func _fecha_gavetas() -> void:
	_left_panel.visible = false
	_obras_panel.visible = false
	_tira_pessoas.set_pressed_no_signal(false)
	_tira_obras.set_pressed_no_signal(false)
	_gaveta_por_mouse = false


## A gaveta aberta pelo mouse fecha quando ele sai da aba fina e da lista.
func _gaveta_mouse() -> void:
	if not _gaveta_por_mouse or _left_panel == null or not _left_panel.visible:
		return
	var m := _left_panel.get_global_mouse_position()
	var dentro := _left_panel.get_global_rect().grow(8.0).has_point(m) or _tira.get_global_rect().grow(8.0).has_point(m)
	if not dentro:
		_fecha_gavetas()


# ------------------------------------------------------------ direita: construções
## Bloco 95: as janelas das estruturas (sem a coluna de botões: abrem clicando no prédio, pela tecla ou pelo
## menu "Janelas" da barra de cima) e a coluna de ALERTAS no lugar da coluna de construções.
func _build_janelas() -> void:
	_alertas = preload("res://scripts/ui/alertas.gd").new()
	_alertas.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_alertas.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_alertas.offset_right = -SIDE_MARGIN
	_alertas.offset_top = TOP_BAR_H + SIDE_MARGIN
	add_child(_alertas)
	_alertas.setup(self)
	if _hub:
		_add_panel("hub", preload("res://scripts/core/hub_panel.gd"), _hub)
	_add_panel("trabalho", preload("res://scripts/core/work_panel.gd"), null)  # Bloco 77: áreas de trabalho
	var arm := get_tree().get_first_node_in_group("armazens")
	if arm and _economy:
		_add_panel("armazem", preload("res://scripts/core/armazem_panel.gd"), arm)  # Bloco 39
	if _hub:
		_add_panel("coletor", preload("res://scripts/core/coletor_panel.gd"), _hub)  # Bloco 45
		_add_panel("coletor_minerio", preload("res://scripts/core/coletor_minerio_panel.gd"), _hub)  # Bloco 57
		_add_panel("fornalha", preload("res://scripts/core/fornalha_panel.gd"), _hub)  # Bloco 86
		_add_panel("carpintaria", preload("res://scripts/core/carpintaria_panel.gd"), _hub)  # Bloco 94
	var cal := get_tree().get_first_node_in_group("calendario")
	if cal:
		_add_panel("calendario", preload("res://scripts/core/calendario_panel.gd"), cal)  # Bloco 88
	if _dig:
		_add_panel("escavadeira", preload("res://scripts/core/escavadeira_panel.gd"), _dig)
	if _oficina:
		_add_panel("oficina", preload("res://scripts/core/oficina_panel.gd"), _oficina)
	if _inf:
		_add_panel("enfermaria", preload("res://scripts/core/enfermaria_panel.gd"), _inf)
	if _morale:
		_add_panel("moral", preload("res://scripts/core/moral_panel.gd"), _morale)
	if _finds:
		_add_panel("robo", preload("res://scripts/core/robo_panel.gd"), _finds)
	var migr := get_tree().get_first_node_in_group("migrantes")
	if migr:  # Bloco 101: a janela dos migrantes que esperam no portão
		_add_panel("migrantes", preload("res://scripts/core/migrantes_panel.gd"), migr)
	_missoes_mgr = get_tree().get_first_node_in_group("missoes")
	if _missoes_mgr:  # Bloco 100: a janela e o rastreador do canto
		_add_panel("missoes", preload("res://scripts/core/missoes_panel.gd"), _missoes_mgr)
		_missoes_mgr.mudou.connect(_atualiza_rastreador)
		_atualiza_rastreador.call_deferred()
	var elev := get_tree().get_first_node_in_group("elevador")
	if elev and elev.has_method("pedir_etapa"):
		_add_panel("elevador", preload("res://scripts/core/elevador_panel.gd"), elev)  # Bloco 99
	if _abyss:
		_add_panel("abismo", preload("res://scripts/core/abyss_panel.gd"), _abyss)
	if _defense:
		_add_panel("defesa", preload("res://scripts/core/defense_panel.gd"), _defense)
	if _research:
		_add_panel("lab", preload("res://scripts/core/lab_panel.gd"), _research)
	if _sun:
		_add_panel("sol", preload("res://scripts/core/sun_panel.gd"), _sun)
	if _diary:
		_add_panel("diario", preload("res://scripts/core/diary_panel.gd"), _diary)
	var cat := get_tree().get_first_node_in_group("catalogo")
	if cat:  # Bloco 102: o catálogo de descobertas (tecla R)
		_add_panel("catalogo", preload("res://scripts/core/catalogo_panel.gd"), cat)
	# Bloco 56: janela da casa (fora do menu: clique na casa ou o cartão do menu)
	var casa_panel: PanelContainer = preload("res://scripts/core/casa_panel.gd").new()
	add_child(casa_panel)
	casa_panel.setup(self, null, _economy)
	_wrap_scroll(casa_panel)
	_panels["casa"] = casa_panel
	# Bloco 60: janela da galeria lacrada (clique no entulho)
	var galeria_panel: PanelContainer = preload("res://scripts/core/galeria_panel.gd").new()
	add_child(galeria_panel)
	galeria_panel.setup(self, null, _economy)
	_wrap_scroll(galeria_panel)
	_panels["galeria"] = galeria_panel
	# Prompt 25: o corte da mina (vista de lado, todos os andares)
	_corte = preload("res://scripts/ui/corte_mina.gd").new()
	add_child(_corte)
	_corte.setup(_main)


# ------------------------------------------------------------ atalhos (H)
func _build_hints() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_hint_panel = panel
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	_hint_box = v
	_fill_hints()


## Bloco 54: as linhas da ajuda com as teclas de agora (remapeáveis nas Configurações).
var _hint_box: VBoxContainer


func _fill_hints() -> void:
	if _hint_box == null:
		return
	for c in _hint_box.get_children():
		c.queue_free()
	var k := func(a: String) -> String: return Teclas.nome(a)
	_hint_box.add_child(_label("ATALHOS  (%s fecha)" % k.call("dicas"), Tipo.TITULO, COLOR_TITLE))
	var lines := [
		"Seleção:  clique  •  arrastar = vários  •  Shift+clique = somar/tirar  •  Esc = soltar  •  %s = próximo  •  %s = seguir" % [k.call("proximo"), k.call("seguir")],
		"Ordens:  botão direito = mover / minerar a jazida clicada",
		"Funções:  %s minerador  •  %s caçador  •  %s médico  •  %s engenheiro  •  %s cozinheiro  •  %s lenhador  •  %s guarda  •  %s pesquisador  •  %s sem função  •  %s turno extra" % [
			k.call("minerador"), k.call("cacador"), k.call("medico"), k.call("engenheiro"), k.call("cozinheiro"), k.call("lenhador"),
			k.call("guarda"), k.call("pesquisador"), k.call("sem_funcao"), k.call("turno_extra")] + "  •  %s fundidor  •  %s ferreiro  •  %s padre (só um)  •  %s carpinteiro" % [k.call("fundidor"), k.call("ferreiro"), k.call("padre"), k.call("carpinteiro")],
		"Economia:  %s vender todo o minério (ou na janela do Armazém, a quantidade que quiser)  •  gente nova: os migrantes chegam no portão (precisa de cama livre)" % k.call("vender"),
		"Pessoas:  %s = a lista da força de trabalho (ou passe o mouse na aba da esquerda)  •  alertas à direita: clique pra ir até lá" % k.call("pessoas"),
		"Trabalho:  %s = TRABALHADORES — marcar áreas (madeira, alimentos, mina) e quantos trabalham em cada uma (até 5)" % k.call("painel_trabalho"),
		"Construir:  %s = menu de construção (casas, cozinha, lazer, pesquisa, defesa, coleta automática…)" % k.call("construir"),
		"Prédios:  %s Centro da Vila  •  %s Escavadeira  •  %s Oficina  •  %s Enfermaria  •  %s Bem-estar  •  %s Defesa  •  %s Laboratório  •  %s Sol  •  %s Diário  •  %s Catálogo  (ou clique no prédio, ou o menu Janelas lá em cima)" % [
			k.call("painel_hub"), k.call("painel_escavadeira"), k.call("painel_oficina"), k.call("painel_enfermaria"), k.call("painel_moral"),
			k.call("painel_defesa"), k.call("painel_lab"), k.call("painel_sol"), k.call("painel_diario"), k.call("painel_catalogo")],
		"Câmera:  roda = zoom (paradas nítidas)  •  botão do meio / WASD / setas = mover  •  Home = centralizar  •  F11 / Alt+Enter = tela cheia",
		"Jogo:  %s salvar  •  %s carregar  •  %s música  •  Esc/%s pausa  •  F2 corte da mina  •  N pular fase (teste)  •  K machucar (teste; Shift+K grave)" % [
			k.call("salvar"), k.call("carregar"), k.call("musica"), k.call("pausa")],
		"Teclas: Configurações > Teclas (remapear e restaurar o padrão)",
	]
	for line in lines:
		_hint_box.add_child(_label(line, Tipo.DETALHE, COLOR_TEXT))


# =================================================================== janelas das estruturas
## Cada janela é um PanelContainer com setup(hud, alvo, economia), refresh(),
## button_text() e has_available_action().
func _add_panel(id: String, script: GDScript, target: Node) -> void:
	var panel: PanelContainer = script.new()
	add_child(panel)
	panel.setup(self, target, _economy)
	_wrap_scroll(panel)
	_panels[id] = panel
	_panel_ordem.append(id)  # Bloco 95: a ordem no menu "Janelas"


## Bloco 95: tecla de cada janela no menu (a ação de teclas.gd).
const TECLA_JANELA := {"hub": "painel_hub", "trabalho": "painel_trabalho", "escavadeira": "painel_escavadeira",
	"oficina": "painel_oficina", "enfermaria": "painel_enfermaria", "moral": "painel_moral", "defesa": "painel_defesa",
	"lab": "painel_lab", "sol": "painel_sol", "diario": "painel_diario", "missoes": "painel_missoes",
	"catalogo": "painel_catalogo"}
const ID_CORTE := 1000


## Bloco 95: o menu "Janelas" monta na hora de abrir (o texto de cada uma, com o número de agora; "•" = tem o
## que fazer lá, como o destaque da coluna de antes).
func _monta_menu_janelas() -> void:
	var pm := _menu_janelas.get_popup()
	pm.clear()
	for i in _panel_ordem.size():
		var id: String = _panel_ordem[i]
		var panel: PanelContainer = _panels[id]
		if panel.has_method("is_available") and not panel.is_available():
			continue
		var txt: String = panel.button_text()
		if TECLA_JANELA.has(id):
			txt += "   [%s]" % Teclas.nome(TECLA_JANELA[id])
		if panel.has_method("has_available_action") and panel.has_available_action():
			txt = "•  " + txt
		pm.add_item(txt, i)
	pm.add_separator()
	pm.add_item("Corte da mina   [F2]", ID_CORTE)


func _menu_janelas_escolheu(i: int) -> void:
	Audio.click()
	if i == ID_CORTE:
		_corte.toggle()
	elif i >= 0 and i < _panel_ordem.size():
		open_panel(_panel_ordem[i])


## Bloco 54: janela mais alta que a tela (escala da interface grande, ou muito conteúdo — a Oficina
## e o Centro da Vila já passavam de 720 px): o conteúdo vai numa rolagem e a janela fica do
## tamanho que cabe entre a barra de cima e a borda de baixo, centrada.
func _wrap_scroll(panel: PanelContainer) -> void:
	if panel.get_child_count() != 1 or panel.get_child(0) is ScrollContainer or not (panel.get_child(0) is Control):
		return
	var content: Control = panel.get_child(0)
	var sc := ScrollContainer.new()
	sc.name = "Rolagem"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.remove_child(content)
	sc.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(sc)
	panel.set_meta("_rolagem", sc)


func _fit_panel(panel: Control) -> void:
	if not is_instance_valid(panel) or not panel.visible or not panel.has_meta("_rolagem") or not panel.is_inside_tree():
		return
	var sc: ScrollContainer = panel.get_meta("_rolagem")
	var content: Control = sc.get_child(0)
	var vis := get_viewport().get_visible_rect().size
	var sb := panel.get_theme_stylebox("panel")
	var borda: float = sb.get_minimum_size().y if sb else 0.0
	var max_h := maxf(vis.y - 2.0 * (TOP_BAR_H + 6.0) - borda, 120.0)
	var want := minf(content.get_combined_minimum_size().y, max_h)
	if not is_equal_approx(sc.custom_minimum_size.y, want):
		sc.custom_minimum_size.y = want
	elif absf(panel.size.y - panel.get_combined_minimum_size().y) < 1.0:
		return  # já do tamanho certo (a janela só cresce sozinha: encolher é aqui)
	panel.reset_size()
	if is_equal_approx(panel.anchor_top, 0.5) and is_equal_approx(panel.anchor_left, 0.5):
		panel.offset_left = -panel.size.x * 0.5
		panel.offset_right = panel.size.x * 0.5
		panel.offset_top = -panel.size.y * 0.5
		panel.offset_bottom = panel.size.y * 0.5


## Bloco 46: abre/fecha o menu de construção.
func toggle_build_menu() -> void:
	if not _build_menu.visible:
		for id in _panels:
			_panels[id].visible = false
	Audio.click()
	_build_menu.toggle()
	_build_button.set_pressed_no_signal(_build_menu.visible)


## Bloco 47: `focus` = o prédio clicado, pra janela que pode mostrar um de vários (coletor,
## enfermaria). Pelo botão/tecla vem null: a janela mostra o primeiro.
func open_panel(id: String, focus: Node = null) -> void:
	if not _panels.has(id):
		return
	_build_menu.visible = false
	for other in _panels:
		if other != id:
			_panels[other].visible = false
	var panel: PanelContainer = _panels[id]
	if panel.has_method("focus"):
		panel.focus(focus)
	if not panel.visible:
		Audio.ui_open()  # Bloco 55
	panel.visible = true
	panel.refresh()
	_fit_panel(panel)
	_fit_panel.call_deferred(panel)  # (texto quebrando muda a altura no quadro seguinte)
	_foco_mapa(focus)


## Bloco 95: o prédio da janela aberta mostra o rótulo inteiro no mapa (os detalhes), como ao passar o mouse.
func _foco_mapa(n: Node) -> void:
	var iso := get_tree().get_first_node_in_group("iso_view")
	if iso and "foco" in iso:
		iso.foco = n


## Abre a janela da estrutura clicada no mapa (ela diz qual pelo panel_id).
func open_panel_for(node: Node) -> void:
	open_panel(node.get("panel_id"), node)


## Fecha a janela aberta (ou os atalhos). Retorna true se havia alguma
## (pro Esc não soltar a seleção junto).
func close_panels() -> bool:
	var closed := false
	for id in _panels:
		if _panels[id].visible:
			_panels[id].visible = false
			closed = true
	if _hint_panel and _hint_panel.visible:
		_hint_panel.visible = false
		closed = true
	if _build_menu and _build_menu.visible:
		_build_menu.visible = false
		closed = true
	if _left_panel and (_left_panel.visible or _obras_panel.visible):  # Bloco 95: as gavetas da aba fina
		_fecha_gavetas()
		closed = true
	if closed:
		Audio.ui_close()  # Bloco 55
	_foco_mapa(null)
	return closed


func toggle_panel(id: String) -> void:
	if _panels.has(id) and _panels[id].visible:
		close_panels()
	else:
		open_panel(id)


## Nome próprio do ipezinho (Bloco 15); cai pro nome do nó se ainda não tiver.
func _worker_name(w: Node) -> String:
	var n = w.get("display_name")
	return n if n is String and n != "" else String(w.name)


## Recolhe/abre a lista de ipezinhos (fica lembrado nas configurações).
func set_collapsed(on: bool, remember: bool = true) -> void:
	if _rows_scroll == null:
		return
	_rows_scroll.visible = not on
	_workers_title.visible = not on
	_collapse_button.text = "+" if on else "–"
	_left_panel.reset_size()
	if remember:
		Settings.set_value("hud", "collapsed", on)


## Mostra/esconde o painel de atalhos (tecla H, botão "?" e a opção nas configurações).
func set_hints_visible(on: bool) -> void:
	if _hint_panel:
		_hint_panel.visible = on


func toggle_hints() -> void:
	var on := not _hint_panel.visible
	set_hints_visible(on)
	Settings.set_value("hud", "show_hints", on)


## Bloco 95: o aviso curto vai pra PILHA no canto (ícone + texto; clicar leva ao lugar, se tiver um).
func show_toast(text: String, color: Color = COLOR_TITLE, alvo: Node = null) -> void:
	if _avisos == null:
		return
	var ic := _banner_icon(text)
	if ic == "":
		ic = "p_alerta" if color == COLOR_HUNGER_BAD or color.r > 0.9 and color.g < 0.5 else ""
	_avisos.avisa(text, color, ic, alvo)


## Bloco 100: o rastreador do canto: o capítulo e até 3 objetivos (os que faltam primeiro; sem missão valendo, some).
func _atualiza_rastreador() -> void:
	if _missoes == null or _missoes_mgr == null:
		return
	var ativas: Array = _missoes_mgr.ativas()
	if ativas.is_empty():
		_missoes.esconde()
	else:
		var cap: int = _missoes_mgr.capitulo_atual()
		var pend: Array = []
		var feitos: Array = []
		for m in ativas:
			for i in m.objetivos.size():
				var par := [_missoes_mgr.objetivo_texto(m, i), _missoes_mgr.objetivo_feito(m, i)]
				(feitos if par[1] else pend).append(par)
		_missoes.mostra("Cap. %d  %s" % [cap, _missoes_mgr.capitulo_titulo(cap)], pend + feitos)
	_reposiciona()


## Bloco 95: a pilha de avisos e o espaço do rastreador de missões (canto de baixo à direita).
func _build_avisos() -> void:
	_missoes = preload("res://scripts/ui/rastreador_missoes.gd").new()
	_missoes.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_missoes.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_missoes.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_missoes)
	_missoes.setup(self)
	_avisos = preload("res://scripts/ui/avisos.gd").new()
	_avisos.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_avisos.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_avisos.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_avisos)
	_avisos.setup(self)


## Bloco 95: o que depende da altura da barra de baixo (missões, avisos, o cartão do selecionado, o CONSTRUIR).
func _reposiciona() -> void:
	if _order_bar == null:
		return
	var base := _order_bar.size.y + SIDE_MARGIN * 2.0
	if _missoes:
		_missoes.offset_right = -SIDE_MARGIN
		_missoes.offset_bottom = -base
	if _avisos:
		_avisos.offset_right = -SIDE_MARGIN
		_avisos.offset_bottom = -base - ((_missoes.size.y + 6.0) if _missoes and _missoes.visible else 0.0)
	if _portrait_card:
		_portrait_card.offset_bottom = -base
	if _build_menu and _build_menu.visible:
		_build_menu._posiciona()
	# tela estreita (interface a 125% numa janela de 720p): a estação e o "dia N · sem. N" ficam só na dica
	var estreito := get_viewport().get_visible_rect().size.x < LARGURA_ESTREITA
	if _chips.has("sun") and _chips.sun.value.visible == estreito:
		_chips.sun.value.visible = not estreito
	if _phase_time_label and _phase_time_label.visible == estreito:
		_phase_time_label.visible = not estreito


## Faixa de conquista no topo da tela (some sozinha).
## Bloco 103: uma pergunta de sim/não (descer pra um andar não reconhecido...). sim = o que fazer no "sim".
var _confirma: ConfirmationDialog = null


func confirma(titulo: String, texto: String, sim: Callable, botao_sim := "Sim", botao_nao := "Não") -> void:
	if _confirma == null:
		_confirma = ConfirmationDialog.new()
		_confirma.name = "Confirma"
		_confirma.exclusive = false
		add_child(_confirma)
	for c in _confirma.confirmed.get_connections():
		_confirma.confirmed.disconnect(c.callable)
	_confirma.title = titulo
	_confirma.dialog_text = texto
	_confirma.dialog_autowrap = true
	_confirma.ok_button_text = botao_sim
	_confirma.cancel_button_text = botao_nao
	_confirma.min_size = Vector2i(460, 0)
	_confirma.confirmed.connect(sim, CONNECT_ONE_SHOT)
	_confirma.popup_centered()


## Bloco 103: mandar gente pra esse ponto pede confirmação (andar não reconhecido)? Se pede, pergunta e, no "sim",
## libera a descida e faz `depois`. Retorna true se perguntou (quem chamou não faz nada agora).
func pergunta_descida(pos: Vector2, depois: Callable) -> bool:
	var cat := get_tree().get_first_node_in_group("catalogo")
	var andar: String = cat.precisa_confirmar(pos) if cat and cat.has_method("precisa_confirmar") else ""
	if andar == "":
		return false
	var sim := func():
		cat.libera_descida(andar)
		depois.call()
	confirma("Andar não reconhecido", cat.texto_confirmar(andar), sim, "Descer mesmo assim", "Esperar o reconhecimento")
	return true


func show_banner(title: String, subtitle: String, ilustracao: String = "") -> void:
	var panel := PanelContainer.new()
	var style: StyleBox = UiSkin.faixa() if UiSkin.ok() else _panel_style()
	if style is StyleBoxFlat:
		(style as StyleBoxFlat).border_color = COLOR_TITLE
		style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# empilha abaixo das faixas que ainda estão na tela (ex.: duas mortes seguidas)
	var y := 70.0
	for c in get_children():
		if c.has_meta("banner") and c is Control:
			y += (c as Control).size.y + 8.0
	panel.set_meta("banner", true)
	panel.offset_top = y
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var ilu := Icones.ilustracao(ilustracao if ilustracao != "" else _banner_ilustracao(title))
	if ilu:  # Prompt 24: a cena do evento em cima do título
		var img := TextureRect.new()
		img.texture = ilu
		img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(img)
	var t := _label(title, Tipo.FAIXA, COLOR_TITLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	t.add_theme_constant_override("outline_size", 5)
	var linha := HBoxContainer.new()  # Prompt 21: o ícone do alerta do lado do título
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 10)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(linha)
	var ic := Icones.tex(_banner_icon(title))
	if ic:
		var tr := _icon(ic)
		tr.custom_minimum_size = Vector2(32, 32)
		linha.add_child(tr)
	linha.add_child(t)
	var st := _label(subtitle, Tipo.TITULO, COLOR_TEXT)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	add_child(panel)
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(6.0)
	tween.tween_property(panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(panel.queue_free)


func _make_row(worker: Node) -> Dictionary:
	var row_panel := PanelContainer.new()
	row_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	row_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row_panel.gui_input.connect(_on_row_input.bind(worker))
	_rows_box.add_child(row_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_panel.add_child(v)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var name_label := _label(_worker_name(worker), Tipo.TITULO, COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var tag_label := _label("", Tipo.DETALHE, COLOR_DIM)  # função / "turno extra" / "irritado"
	top.add_child(tag_label)

	var state_label := _label("", Tipo.DETALHE, COLOR_DIM)
	state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_label.custom_minimum_size.x = 250
	v.add_child(state_label)

	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 6)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bars)
	bars.add_child(_label("fome", Tipo.DETALHE, COLOR_DIM))
	var hunger_bar := _bar(COLOR_HUNGER_OK)
	bars.add_child(hunger_bar)
	bars.add_child(_label("carga", Tipo.DETALHE, COLOR_DIM))
	var cargo_bar := _bar(COLOR_CARGO)
	bars.add_child(cargo_bar)
	bars.add_child(_label("ânimo", Tipo.DETALHE, COLOR_DIM))
	var joy_bar := _bar(COLOR_HUNGER_OK)
	bars.add_child(joy_bar)
	for bar in [hunger_bar, cargo_bar, joy_bar]:
		bar.custom_minimum_size.x = 48  # três barras cabem na largura do painel

	return {"panel": row_panel, "name": name_label, "state": state_label, "tag": tag_label, "hunger": hunger_bar, "cargo": cargo_bar, "joy": joy_bar}


func _on_row_input(event: InputEvent, worker: Node2D) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.shift_pressed:
			_main.toggle_selected(worker)  # Shift na lista também soma/tira do grupo
			return
		_main.select(worker)
		var cam := _main.get_node_or_null("Camera2D")
		if cam:
			cam.focus_on(worker.global_position)


# =================================================================== atualização
func _refresh() -> void:
	var workers := get_tree().get_nodes_in_group("ipezinhos")
	_refresh_phase()
	_refresh_top_bar(workers)
	_refresh_panels()
	_refresh_workforce(workers)
	_refresh_alertas(workers)
	_refresh_order_bar(workers)
	_refresh_worker_rows(workers)
	if _obras_panel and _obras_panel.visible:
		_refresh_obras()
	_reposiciona()  # (a barra de baixo muda de largura/altura quando uma função é liberada)


## Bloco 83: nome curto de cada marco do relógio (o próximo aparece do lado da hora).
const MARCO_TEXTO := {"amanhecer": "amanhece", "fim_expediente": "fim do turno", "anoitecer": "anoitece", "dormir": "dormir"}


## Bloco 83: relógio de 24 h — "14:35 TER" e "dia 3 · sem. 1" (o próximo marco e os horários na dica).
func _refresh_phase() -> void:
	if _day_night == null:
		return
	var night: bool = _day_night.is_night()
	var color := COLOR_NIGHT if night else COLOR_DAY
	_set_text(_phase_label, _day_night.hora_texto())  # Bloco 95: a hora grande no meio da barra
	_set_font_color(_phase_label, color)
	_set_text(_dia_semana_label, _day_night.nome_dia(true))
	_set_text(_phase_time_label, "dia %d · sem. %d" % [_day_night.day, _day_night.semana()])
	var prox: Array = _day_night.proximo_marco()
	var dica := "%s, dia %d (semana %d).%s
Amanhece às %s, fim do turno às %s, anoitece às %s, dormir às %s." % [
		_day_night.nome_dia(), _day_night.day, _day_night.semana(),
		(" Próximo: %s às %s." % [MARCO_TEXTO.get(prox[0], prox[0]), _day_night.hora_texto(prox[1])]) if not prox.is_empty() else "",
		_day_night.hora_texto(_day_night.hora_amanhecer), _day_night.hora_texto(_day_night.hora_fim_expediente),
		_day_night.hora_texto(_day_night.hora_anoitecer), _day_night.hora_texto(_day_night.hora_dormir)]
	var cal_dica := get_tree().get_first_node_in_group("calendario")
	if cal_dica:
		dica += "\nPróximo evento: %s" % cal_dica.proximo_texto()  # Bloco 88
	if _phase_label.tooltip_text != dica:
		_phase_label.tooltip_text = dica
		_phase_time_label.tooltip_text = dica
		_phase_bar.tooltip_text = dica
	_phase_bar.value = _day_night.phase_progress() * 100.0
	(_phase_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = color
	if _pular_button:
		_pular_button.set_pressed_no_signal(_day_night.pulando)


func _refresh_top_bar(workers: Array) -> void:
	# créditos (pisca ao ganhar/gastar)
	if _economy:
		var credits: float = _economy.credits
		var credits_label: Label = _chips.credits.value
		_set_chip("credits", str(int(credits)), COLOR_TITLE, "")
		if _last_credits >= 0.0 and not is_equal_approx(credits, _last_credits):
			credits_label.modulate = Color(1.6, 1.6, 1.6) if credits > _last_credits else Color(1.5, 0.6, 0.6)
			create_tween().tween_property(credits_label, "modulate", Color.WHITE, 0.5)
		_last_credits = credits

	# minério: total na barra; por tipo + jazidas no tooltip (Bloco 95: vender e auto no Armazém)
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.total_stored
	var parts: Array[String] = []
	var cat_ores := get_tree().get_first_node_in_group("catalogo")
	for t in Ores.TYPES:
		var amount: float = _economy.stored_ore(t) if _economy else 0.0
		var unlocked: bool = (_oficina == null or _oficina.is_ore_unlocked(t)) and t != Ores.DESCONHECIDO \
			and (cat_ores == null or cat_ores.minerio_conhecido(t))  # Bloco 102: o que o catálogo não estudou não tem nome
		if unlocked or amount > 0.0:
			parts.append("%s %d" % [Ores.display_name(t).to_lower(), int(amount)])
	var ore_left := 0.0
	var active := 0
	var locked := 0
	var nodes := get_tree().get_nodes_in_group("minerios")
	for m in nodes:
		if m.has_method("is_unlocked") and not m.is_unlocked():
			locked += 1
			continue
		ore_left += m.ore_remaining
		if m.is_usable():
			active += 1
	var ore_tip := "  •  ".join(parts) + "\nJazidas: %d/%d ativas%s  •  %d restante" % [
		active, nodes.size() - locked, " (+%d bloqueadas)" % locked if locked > 0 else "", int(ore_left)]
	if _finds and _finds.rare_parts > 0:
		ore_tip += "\nPeças raras: %d" % _finds.rare_parts
	if _economy:
		ore_tip += "\nVender: na janela do Armazém (ou tecla %s, tudo)." % Teclas.nome("vender")
	_set_chip("ore", str(int(total)), COLOR_TEXT, ore_tip)

	# madeira / matéria-prima / comida
	var wood: float = _economy.stored_wood() if _economy else 0.0
	_set_chip("wood", str(int(wood)), COLOR_WOOD, "")
	var raw := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		raw += a.get("raw_stored") if a.get("raw_stored") != null else 0.0
	var garden := 0.0
	for h in get_tree().get_nodes_in_group("coleta_comida"):
		garden += h.food_remaining
	var game := 0.0
	for tc in get_tree().get_nodes_in_group("caca"):
		game += tc.game_remaining
	_set_chip("raw", str(int(raw)), COLOR_TEXT, "Fruta e caça cruas no armazém (o cozinheiro prepara).\nHorta %d  •  tocas %d" % [int(garden), int(game)])
	var stock := 0.0
	var capacity := 0.0
	for c in get_tree().get_nodes_in_group("comedouros"):
		stock += c.food_stock
		capacity += c.food_capacity
	var cooks := workers.filter(func(w): return w.has_method("is_cook") and w.is_cook()).size()
	var food_color := COLOR_TEXT
	if stock <= 0.0:
		food_color = COLOR_HUNGER_BAD
	elif capacity > 0.0 and stock / capacity < 0.25:
		food_color = COLOR_HUNGER_LOW
	var sched := get_tree().get_first_node_in_group("schedule")
	if sched:
		# Bloco 84: porções no estoque x refeições que ainda faltam hoje (vermelho se não dá pra todos)
		var porcoes := floori(sched.porcoes_em_estoque())
		var faltam: int = sched.refeicoes_restantes_hoje()
		if stock > 0.0 and porcoes < faltam:
			food_color = COLOR_HUNGER_LOW if porcoes * 2 >= faltam else COLOR_HUNGER_BAD
		_set_chip("food", "ACABOU" if stock <= 0.0 else "%d (hoje %d)" % [porcoes, faltam], food_color,
			"Porções na cozinha: %d (%d de comida de %d; %s por porção).\nRefeições que ainda faltam hoje: %d (café, almoço e jantar de cada um).%s%s" % [
			porcoes, int(stock), int(capacity), str(snappedf(sched.porcao, 0.1)), faltam,
			("\nNão dá pra todo mundo: faltam %d porções!" % (faltam - porcoes)) if porcoes < faltam else "",
			"\nNinguém cozinhando!" if cooks == 0 else ""])
		_falta_porcoes = maxi(faltam - porcoes, 0) if stock > 0.0 else maxi(faltam, 1)
	else:
		_set_chip("food", "ACABOU" if stock <= 0.0 else "%d/%d" % [int(stock), int(capacity)], food_color,
			"Na cozinha." + ("\nNinguém cozinhando!" if cooks == 0 else ""))
		_falta_porcoes = 1 if stock <= 0.0 else 0
	_chip_icon("food", "al_falta_comida" if stock <= 0.0 else "comida")  # Prompt 21

	# camas
	var beds := 0
	var taken := 0
	var sleeping := 0
	for casa in get_tree().get_nodes_in_group("casas"):
		beds += casa.beds_total()
		taken += casa.beds_taken()
		sleeping += casa.sleeping_count()
	var homeless := 0
	var injured := 0
	var grave := 0
	for w in workers:
		if w.has_method("has_home") and not w.has_home():
			homeless += 1
		if w.get("injured"):
			injured += 1
			if w.get("injury_severity") == "grave":
				grave += 1
	_set_chip("beds", "%d/%d" % [taken, beds], COLOR_HUNGER_LOW if homeless > 0 else COLOR_TEXT,
		"%d dormindo%s" % [sleeping, "  •  %d sem teto" % homeless if homeless > 0 else ""])

	# ânimo (greve vira alerta vermelho na própria barra)
	if _morale:
		var avg: float = _morale.average()
		var text := "%d" % roundi(maxf(avg, 0.0))
		var color := _joy_color(avg)
		var tip: String = _morale.mood_word(avg) if avg >= 0.0 else ""
		if _morale.on_strike:
			var left := ceili(_morale.strike_left)
			text = "GREVE! %d:%02d" % [left / 60, left % 60]
			color = COLOR_HUNGER_BAD
			tip = "Greve! Expulsão em %d:%02d se o ânimo não voltar a %d." % [left / 60, left % 60, roundi(_morale.strike_end_at)]
		elif _morale.below_time > 0.0:
			var left := ceili(_morale.strike_grace - _morale.below_time)
			text += " (greve em %d:%02d!)" % [left / 60, left % 60]
			color = COLOR_HUNGER_BAD
		var at_tav := 0
		for tav in _morale.tavernas():  # Bloco 47: pode ter várias
			at_tav += tav.guests().size()
		if at_tav > 0:
			tip += "\n%d na taverna" % at_tav
		_set_chip("joy", text, color, tip, avg >= 0.0)

	# saúde (só aparece com alguém machucado)
	_set_chip("health", "%d%s" % [injured, " (%d grave%s)" % [grave, "s" if grave > 1 else ""] if grave > 0 else ""],
		COLOR_HUNGER_BAD if grave > 0 else COLOR_INJURED, "Machucados (tratam na Enfermaria).", injured > 0)

	# estação + onda solar (alerta vira texto vermelho) e o tom alaranjado na tela
	if _sun:
		var alert: bool = _sun.wave_active() or (_sun.warned and _sun.time_to_wave() >= 0.0)
		_set_chip("sun", ("ONDA SOLAR!" if _sun.wave_active() else _sun.season_name() + (" — onda chegando!" if alert else "")),
			COLOR_HUNGER_BAD if alert else COLOR_DIM, _sun.forecast_text())
		_chip_icon("sun", "al_onda_solar" if alert else Icones.ESTACAO[clampi(_sun.season_index(), 0, 3)])
		if _sun_overlay == null:
			_sun_overlay = ColorRect.new()
			_sun_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			_sun_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_sun_overlay.color = Color(1.0, 0.55, 0.2, 0.0)
			add_child(_sun_overlay)
			move_child(_sun_overlay, 0)  # por baixo dos painéis
		_sun_overlay.color.a = 0.22 + 0.06 * sin(Time.get_ticks_msec() * 0.006) if _sun.wave_active() else 0.0
	else:
		_set_chip("sun", "", COLOR_DIM, "", false)


## Força de trabalho: total (e as camas: a capacidade da vila) e os SEM FUNÇÃO em destaque.
func _refresh_workforce(workers: Array) -> void:
	var no_job := workers.filter(func(w): return w.has_method("has_no_job") and w.has_no_job()).size()
	if no_job > 0:
		_no_job_label.text = "SEM FUNÇÃO: %d  —  selecione e escolha uma função na barra de baixo" % no_job
		_no_job_label.add_theme_color_override("font_color", COLOR_NO_JOB)
	else:
		_no_job_label.text = "Todos com função"
		_no_job_label.add_theme_color_override("font_color", COLOR_DIM)
	# Bloco 31: obras encomendadas e se tem engenheiro pra elas
	var todas := get_tree().get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending())
	var obras := todas.filter(func(o): return o.get("oficio") != "ferreiro")  # Bloco 87: as da forja são do ferreiro
	var forja := todas.filter(func(o): return o.get("oficio") == "ferreiro")
	var smiths := workers.filter(func(w): return w.has_method("is_smith") and w.is_smith()).size()
	var engineers := workers.filter(func(w): return w.has_method("is_engineer") and w.is_engineer()).size()
	var working := obras.filter(func(o): return not o.obra_workers().is_empty()).size()
	_obras_label.visible = not obras.is_empty() or (not forja.is_empty() and smiths == 0)
	if obras.is_empty() and not forja.is_empty() and smiths == 0:
		_obras_label.text = "FORJA: %d encomenda%s esperando FERREIRO (tecla 7)" % [forja.size(), "s" if forja.size() > 1 else ""]
		_obras_label.add_theme_color_override("font_color", COLOR_NO_JOB)
	if not obras.is_empty():
		var names: Array[String] = []
		for o in obras.slice(0, 3):
			names.append("%s %d%%" % [o.obra_title(), roundi(o.obra_progress() * 100.0)])
		if engineers == 0:
			_obras_label.text = "OBRAS: %d esperando engenheiro (tecla 4)\n%s" % [obras.size(), "  •  ".join(names)]
			_obras_label.add_theme_color_override("font_color", COLOR_NO_JOB)
		else:
			_obras_label.text = "OBRAS: %d  (%d em andamento)\n%s" % [obras.size(), working, "  •  ".join(names)]
			_obras_label.add_theme_color_override("font_color", COLOR_ENGINEER)
	# Bloco 35: guarda com a arma quebrada
	var def := get_tree().get_first_node_in_group("defense")
	var unarmed: Array = def.unarmed_guards() if def else []
	_unarmed_label.visible = not unarmed.is_empty()
	if not unarmed.is_empty():
		var names: Array[String] = []
		for w in unarmed.slice(0, 3):
			names.append(w.display_name)
		_unarmed_label.text = "DESARMADOS: %d (%s) — %s" % [unarmed.size(), ", ".join(names),
			"indo ao Arsenal pegar outra arma" if def.arsenal() != null else "sem Arsenal pra pegar outra (G: Defesa)"]
	# Bloco 42: inverno sem casaco (trabalha mais devagar, não morre)
	var eqp := get_tree().get_first_node_in_group("equipment")
	var cold: Array = eqp.cold_without_coat() if eqp else []
	_cold_label.visible = not cold.is_empty()
	if not cold.is_empty():
		_cold_label.text = "SEM CASACO: %d de %d — no frio trabalham a %d%% (%s)" % [
			cold.size(), workers.size(), roundi(eqp.cold_work_mult * 100.0),
			"faça casacos na Oficina, tecla O" if eqp.vestiario() != null else "construa o Vestiário pela Oficina, tecla O"]
	# Bloco 36: guarda caído em combate (só o médico resgata)
	var downed: Array = workers.filter(func(w): return w.get("downed"))
	_downed_label.visible = not downed.is_empty()
	if not downed.is_empty():
		var docs := workers.filter(func(w): return w.has_method("is_doctor") and w.is_doctor() and not w.injured).size()
		var parts: Array[String] = []
		for w in downed.slice(0, 3):
			parts.append("%s (%s)" % [w.display_name, "sendo carregado" if w._carried_by != null else "morre em %ds" % ceili(w._care_left)])
		_downed_label.text = "CAÍDO%s EM COMBATE: %s — %s" % ["S" if downed.size() > 1 else "", ", ".join(parts),
			"médico a caminho" if docs > 0 else "SEM MÉDICO! Designe um (tecla 3)"]
	if _economy:
		# Bloco 101: a capacidade são as camas (quem chega são os migrantes, no portão)
		_workers_count_label.text = "%d / %d camas" % [workers.size(), _economy.worker_count() + _economy.free_beds()]
	else:
		_workers_count_label.text = str(workers.size())


## Barra de ordens: quantos em cada função e quais estão "acesas" pra seleção atual.
func _refresh_order_bar(workers: Array) -> void:
	var counts := {}
	for w in workers:
		if w.get("job") != null:
			counts[w.job] = counts.get(w.job, 0) + 1
	var sel: Array = _main.selection.filter(func(u): return is_instance_valid(u))
	var grupos_vivos := {}
	for job in _job_buttons:
		var info: Dictionary = _job_buttons[job]
		var n: int = counts.get(job, 0)
		_set_text(info.count, str(n) if n > 0 else "")
		info.button.set_pressed_no_signal(not sel.is_empty() and sel.all(func(u): return u.job == job))
		var liberada := n > 0 or funcao_liberada(job)  # Bloco 95: só as funções já liberadas aparecem
		if info.button.visible != liberada:
			info.button.visible = liberada
		if liberada:
			grupos_vivos[info.get("grupo", "")] = true
	for g in _grupos:
		var vivo: bool = grupos_vivos.has(g)
		if _grupos[g].visible != vivo:
			_grupos[g].visible = vivo
	_overtime_button.set_pressed_no_signal(not sel.is_empty() and sel.all(func(u): return u.overtime))
	_no_job_button.disabled = sel.is_empty() or sel.all(func(u): return u.has_no_job())
	if sel.is_empty():
		_set_text(_selection_caption, "Nenhum ipezinho selecionado  —  clique ou arraste no mapa (ou na lista) e escolha a função")
	else:
		var names: Array[String] = []
		for u in sel.slice(0, 4):
			names.append(_worker_name(u))
		var more := "  +%d" % (sel.size() - 4) if sel.size() > 4 else ""
		_set_text(_selection_caption, "%d selecionado%s: %s%s  —  escolha a função" % [
			sel.size(), "s" if sel.size() > 1 else "", ", ".join(names), more])
	_update_portrait(sel)


## Bloco 95: a função já está liberada? (o lugar de trabalho dela existe). As de sempre estão desde o começo.
func funcao_liberada(job: String) -> bool:
	match job:
		"pesquisador":
			return not get_tree().get_nodes_in_group("laboratorios").is_empty()
		"fundidor":
			return not get_tree().get_nodes_in_group("fornalhas").is_empty()
		"ferreiro":
			var of_ok: bool = _oficina != null and (not _oficina.has_method("is_built") or _oficina.is_built())
			return of_ok or not get_tree().get_nodes_in_group("arsenais").is_empty()
		"padre":
			var cal := get_tree().get_first_node_in_group("calendario")
			return cal != null and (bool(cal.get("padre_chegou")) or (_hub != null and int(_hub.level) >= int(cal.padre_estagio)))
		"carpinteiro":
			return not get_tree().get_nodes_in_group("carpintarias").is_empty()
	return true


func _refresh_worker_rows(workers: Array) -> void:
	# cria/remove linhas se entrar ou sair ipezinho
	for w in workers:
		if not _rows.has(w):
			_rows[w] = _make_row(w)
	for w in _rows.keys():
		if not is_instance_valid(w) or not workers.has(w):
			_rows[w].panel.queue_free()
			_rows.erase(w)
	if not _left_panel.visible:
		return  # Bloco 95: a gaveta fechada não precisa de nada (as contas dos alertas são à parte)

	# a lista cresce até caber: nunca invade a barra de ordens embaixo
	var bottom_limit := get_viewport().get_visible_rect().size.y - (_order_bar.size.y + SIDE_MARGIN * 3.0)
	var room := bottom_limit - _rows_scroll.global_position.y
	var max_h := clampf(room, 60.0, worker_list_max_height)
	var want_h := minf(_rows_box.get_combined_minimum_size().y, max_h)
	if not is_equal_approx(_rows_scroll.custom_minimum_size.y, want_h):  # Bloco 53: layout só quando muda
		_rows_scroll.custom_minimum_size.y = want_h
		_left_panel.reset_size()

	# Bloco 95: primeiro quem está PARADO, depois quem tem PROBLEMA, depois o resto (pelo nome)
	var ordem := workers.duplicate()
	ordem.sort_custom(func(a, b):
		var pa := prioridade_na_lista(a)
		var pb := prioridade_na_lista(b)
		return pa < pb if pa != pb else _worker_name(a) < _worker_name(b))
	for i in ordem.size():
		var p: Control = _rows[ordem[i]].panel
		if p.get_index() != i:
			_rows_box.move_child(p, i)

	var picked: int = _main.selection.size()
	_set_text(_workers_title, "IPEZINHOS  —  %d selecionados" % picked if picked > 1 else "IPEZINHOS  (parados e com problema primeiro)")
	_set_font_color(_workers_title, COLOR_TITLE if picked > 1 else COLOR_DIM)
	for w in workers:
		var row: Dictionary = _rows[w]
		_set_text(row.name, _worker_name(w))
		var hunger_ratio: float = w.hunger / w.hunger_max
		row.hunger.max_value = w.hunger_max
		row.hunger.value = w.hunger
		var fill := COLOR_HUNGER_OK
		if w.hunger <= 0.0:
			fill = COLOR_HUNGER_BAD
		elif w.hunger < w.hunger_threshold:
			fill = COLOR_HUNGER_LOW if hunger_ratio > 0.15 else COLOR_HUNGER_BAD
		_set_fill(row.hunger, fill)
		row.cargo.max_value = w.cargo_capacity
		row.cargo.value = w.carrying
		row.joy.value = w.happiness
		_set_fill(row.joy, _joy_color(w.happiness))
		var tip := "ânimo %d (%s)" % [roundi(w.happiness), w.happiness_label()]
		if row.joy.tooltip_text != tip:
			row.joy.tooltip_text = tip
		_set_fill(row.cargo, Ores.UI_COLORS.get(w.cargo_type, COLOR_CARGO))
		var state: String = w.get_state()
		_set_text(row.state, w.get_state_label() if w.hunger > 0.0 else "FAMINTO!")
		var state_color: Color = STATE_COLORS.get(state, COLOR_DIM)
		if w.hunger <= 0.0:
			state_color = COLOR_HUNGER_BAD
		elif w.injured:
			state_color = COLOR_INJURED
		elif state == "idle" and w.has_no_job():
			state_color = COLOR_NO_JOB
		_set_font_color(row.state, state_color)
		# etiqueta: função (na cor dela) + turno extra / zanga
		var tags: Array[String] = []
		var tag_color := COLOR_DIM
		if w.has_no_job():
			tags.append("SEM FUNÇÃO")
			tag_color = COLOR_NO_JOB
		else:
			for entry in ORDER_JOBS:
				if entry[0] == w.job:
					tags.append(String(entry[1]).to_lower() + (" %d%%" % roundi(w.combat_skill * 100.0) if w.is_guard() else ""))
					tag_color = entry[5]
			if w.work_area != null:
				tags.append("· " + w.work_area.nome())  # Bloco 77: a área onde trabalha
		if w.overtime:
			tags.append("turno extra")
		if w.mood() > 0:
			tags.append(w.mood_label())
			if not w.has_no_job():
				tag_color = [COLOR_OVERTIME, COLOR_IRRITATED, COLOR_FURIOUS][w.mood()]
		_set_text(row.tag, "  ".join(tags))
		_set_font_color(row.tag, tag_color)
		var st: StyleBox = _style_row_selected if _main.is_selected(w) else _style_row
		if not row.panel.has_meta("_sb") or row.panel.get_meta("_sb") != st:
			row.panel.set_meta("_sb", st)
			row.panel.add_theme_stylebox_override("panel", st)


## Bloco 95: a ordem da lista — 0 = parado (sem função ou sem o que fazer), 1 = com problema (ferido, caído,
## fome, zangado, sem cama), 2 = o resto.
func prioridade_na_lista(w: Node) -> int:
	if w.has_method("has_no_job") and (w.has_no_job() or w.get_state() == "idle"):
		return 0
	if w.get("injured") or w.get("downed") or w.hunger < w.hunger_threshold or w.mood() > 0 \
			or (w.has_method("has_home") and not w.has_home()):
		return 1
	return 2


## Bloco 53: só mexe no controle quando o valor muda (trocar cor/estilo dispara tema e layout de
## novo; com 40 ipezinhos isso era a maior parte do custo da HUD).
func _set_text(c: Control, t: String) -> void:
	if c.text != t:
		c.text = t


func _set_font_color(c: Control, col: Color) -> void:
	if not c.has_meta("_fc") or c.get_meta("_fc") != col:
		c.set_meta("_fc", col)
		c.add_theme_color_override("font_color", col)


func _set_fill(bar: Range, col: Color) -> void:
	var sb := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if sb and sb.bg_color != col:
		sb.bg_color = col


func _joy_color(h: float) -> Color:
	if h >= 75.0:
		return COLOR_HUNGER_OK
	if h >= 40.0:
		return Color(0.75, 0.72, 0.55)
	if h >= 25.0:
		return COLOR_HUNGER_LOW
	return COLOR_HUNGER_BAD


func _refresh_panels() -> void:
	if _build_menu:
		_build_menu.refresh()
		_build_button.set_pressed_no_signal(_build_menu.visible)
	var tem_acao := false
	for id in _panels:
		var panel: PanelContainer = _panels[id]
		if _panel_ordem.has(id) and panel.has_method("has_available_action") and (not panel.has_method("is_available") or panel.is_available()):
			if panel.has_available_action():
				tem_acao = true
		if panel.visible:  # Bloco 95: só a aberta precisa se atualizar (o menu "Janelas" pergunta na hora)
			panel.refresh()
			_fit_panel(panel)  # Bloco 54
	# o menu "Janelas" fica âmbar quando dá pra comprar/fabricar alguma coisa numa delas
	if _menu_janelas:
		_set_font_color(_menu_janelas, COLOR_TITLE if tem_acao else COLOR_TEXT)


# =================================================================== debug (Bloco 52)
## Painel de debug (F3) e telemetria: só em build de editor/debug (no executável de release não
## existem). A telemetria também liga com [debug] telemetria=true no settings.cfg.
func _ferramentas_debug() -> void:
	if not is_inside_tree() or _main == null:
		return
	if OS.is_debug_build():
		var dbg: CanvasLayer = preload("res://scripts/core/debug_panel.gd").new()
		_main.add_child(dbg)
		dbg.setup(_main)
	if OS.is_debug_build() or Settings.get_value("debug", "telemetria", false):
		_main.add_child(preload("res://scripts/core/telemetria.gd").new())


# =================================================================== retrato (Prompt 23)
var _corte: CanvasLayer
var _portrait_card: PanelContainer
var _portrait_img: TextureRect
var _portrait_name: Label
var _portrait_info: Label
var _portrait_job: Label
var _portrait_doing: Label


## Bloco 95: monta o cartão do selecionado (escondido até alguém ser selecionado).
func _monta_cartao_selecionado() -> void:
	_portrait_card = PanelContainer.new()
	_portrait_card.add_theme_stylebox_override("panel", UiSkin.dica() if UiSkin.ok() else _panel_style())
	_portrait_card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_portrait_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_portrait_card.offset_left = SIDE_MARGIN
	_portrait_card.offset_bottom = -(_order_bar.size.y + SIDE_MARGIN * 2.0)
	_portrait_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_card.visible = false
	add_child(_portrait_card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_card.add_child(h)
	_portrait_img = TextureRect.new()
	_portrait_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_img.custom_minimum_size = Vector2(96, 96)  # 48 px x2 (pixel inteiro)
	_portrait_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_portrait_img)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.custom_minimum_size.x = 210
	h.add_child(v)
	_portrait_name = _label("", Tipo.TITULO, COLOR_TITLE)
	v.add_child(_portrait_name)
	_portrait_job = _label("", Tipo.DETALHE, COLOR_TEXT)
	v.add_child(_portrait_job)
	_portrait_doing = _label("", Tipo.CORPO, COLOR_TEXT)
	_portrait_doing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_portrait_doing.custom_minimum_size.x = 210
	v.add_child(_portrait_doing)
	_portrait_info = _label("", Tipo.DETALHE, COLOR_DIM)
	v.add_child(_portrait_info)
	_selection_caption = _label("", Tipo.CORPO, COLOR_TITLE)
	v.add_child(_selection_caption)
	_selection_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_caption.custom_minimum_size.x = 210


## Bloco 95: o CARTÃO DO SELECIONADO, acima da barra de baixo à esquerda (não cobre mais o Construir): retrato,
## nome, função e o que está fazendo. Com vários selecionados, a lista dos nomes (sem retrato).
func _update_portrait(sel: Array) -> void:
	var w = sel[0] if sel.size() == 1 and sel[0].is_in_group("ipezinhos") else null
	if sel.is_empty():
		if _portrait_card:
			_portrait_card.visible = false
		return
	if _portrait_card == null:
		return
	_portrait_card.visible = true
	var tex: Texture2D = Retratos.de(w) if w != null else null
	_portrait_img.visible = tex != null
	_portrait_img.texture = tex
	var um: bool = w != null
	_portrait_name.visible = um
	_portrait_job.visible = um
	_portrait_doing.visible = um
	_portrait_info.visible = um
	_selection_caption.visible = not um
	if not um:
		return
	_set_text(_portrait_name, _worker_name(w))
	var job_name: String = "sem função"
	var job_color := COLOR_NO_JOB
	if not w.has_no_job():
		for entry in ORDER_JOBS:
			if entry[0] == w.job:
				job_name = entry[1]
				job_color = entry[5]
	_set_text(_portrait_job, job_name + ("  •  turno extra" if w.overtime else ""))
	_set_font_color(_portrait_job, job_color)
	_set_text(_portrait_doing, w.get_state_label() if w.hunger > 0.0 else "FAMINTO!")
	_set_text(_portrait_info, "%s  •  ânimo %d" % [{"ferido": "machucado", "bravo": "zangado",
		"cansado": "cansado", "contente": "contente", "neutro": "tranquilo"}.get(Retratos.expressao(w), ""), roundi(w.happiness)])


# =================================================================== ícones (Prompt 21)
## Ícone de cada faixa de aviso, pelo título.
const BANNER_ICONS := [["INVASÃO", "al_invasao"], ["ROUBO", "al_invasao"], ["ONDA SOLAR", "al_onda_solar"],
	["GREVE ENCERRADA", "animo"], ["GREVE", "greve"], ["ÚLTIMO AVISO", "greve"], ["REATOR", "al_reator"],
	["ROBÔ", "it_robo"], ["FERRUGENTO", "it_robo"], ["ACHADO", "solarita"], ["MORREU", "ferido_grave"], ["CAÍDO", "ferido_grave"],
	["FESTA", "animo"], ["PESQUISA", "pesquisador"], ["ESCAVADEIRA", "minerador"], ["ABISMO", "al_reator"],
	["FOME", "al_falta_comida"], ["COMIDA", "al_falta_comida"], ["PARADA", "al_obra_parada"], ["VILA", "construir"]]


## Ilustração de cada faixa de aviso, pelo título (Prompt 24).
const BANNER_ILUSTRA := [["ROBÔ ANTIGO", "robo_achado"], ["ACHADO", "reator_achado"], ["INVASÃO", "invasao"],
	["ROUBO", "invasao"], ["GREVE!", "greve"], ["FESTA", "festa"], ["ONDA SOLAR", "onda_solar"], ["ABISMO", "abismo"],
	["ACIDENTE", "acidente_mina"]]


func _banner_ilustracao(title: String) -> String:
	for b in BANNER_ILUSTRA:
		if title.to_upper().contains(b[0]):
			return b[1]
	return ""


func _banner_icon(title: String) -> String:
	for b in BANNER_ICONS:
		if title.to_upper().contains(b[0]):
			return b[1]
	return ""


## O ícone novo (24 px na barra de cima; 32 px na de baixo) ou, sem ele, o de antes.
func _ic(nome: String, antes: Texture2D, pequeno := true) -> Texture2D:
	var t := Icones.tex(nome, pequeno) if nome != "" else null
	return t if t != null else antes


func _chip_icon(id: String, nome: String) -> void:
	var c: Dictionary = _chips.get(id, {})
	var t := Icones.tex(nome, true)
	if c.get("icon") != null and t != null and c.icon.texture != t:
		c.icon.texture = t


# =================================================================== velocidade (Prompt 20/21)
## Bloco 83: pausa, 1x, 2x, 4x (o F3 e o "Pular dia" passam por aqui também).
const SPEEDS := [0.0, 1.0, 2.0, 4.0]
var _speed_buttons: Array[Button] = []
var _pular_button: Button


## Pausa, 1x, 2x, 4x (Engine.time_scale): botões pequenos no canto da barra de cima. Bloco 83: e o
## "Pular dia" (acelera até as 05:00 com a simulação rodando; para sozinho se algo importante acontecer).
func _build_speed(row: HBoxContainer) -> void:
	if Icones.tex("vel_1") == null:
		return
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	row.add_child(box)
	for i in SPEEDS.size():
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.icon = Icones.tex(["vel_pausa", "vel_1", "vel_2", "vel_3"][i])
		b.custom_minimum_size = Vector2(30, 28)
		b.tooltip_text = ["Pausar o tempo (sem menu)", "Velocidade normal", "Velocidade 2x", "Velocidade 4x"][i]
		if UiSkin.ok():
			UiSkin.aplica_botao(b, true)
		b.pressed.connect(func():
			Audio.click()
			set_speed(SPEEDS[i]))
		box.add_child(b)
		_speed_buttons.append(b)
	_pular_button = Button.new()
	_pular_button.toggle_mode = true
	_pular_button.focus_mode = Control.FOCUS_NONE
	_pular_button.icon = Icones.tex("vel_pular")  # (⏭: cabe na barra junto dos outros)
	if _pular_button.icon == null:
		_pular_button.text = "Pular dia"
	_pular_button.custom_minimum_size = Vector2(30, 28)
	_pular_button.tooltip_text = "Pular dia: acelera até as 05:00 do dia seguinte (a vila trabalha de verdade, só mais rápido). Para sozinho em invasão, onda solar, ferido grave, morte ou greve."
	if UiSkin.ok():
		UiSkin.aplica_botao(_pular_button, true)
	_pular_button.pressed.connect(func():
		Audio.click()
		pular_dia())
	box.add_child(_pular_button)
	_mark_speed()


## Bloco 83: liga/desliga o "Pular dia".
func pular_dia() -> void:
	if _day_night == null:
		return
	if _day_night.pulando:
		_day_night.parar_pulo("")
		set_speed(1.0)
	else:
		_day_night.pular_dia()
		_speed_mexeu = true
	_mark_speed()


## O controle de velocidade mudou o tempo? (só então volta pro normal ao sair da partida: quem
## mais mexe no Engine.time_scale, como o teste de save, decide sozinho)
static var _speed_mexeu := false


func _exit_tree() -> void:
	if _speed_mexeu:
		_speed_mexeu = false
		Engine.time_scale = 1.0  # (saindo da partida: o menu e a próxima partida voltam no normal)


func set_speed(v: float) -> void:
	if _day_night and _day_night.pulando:
		_day_night.parar_pulo("")  # Bloco 83: mexer na velocidade cancela o "Pular dia"
	Engine.time_scale = v
	_speed_mexeu = not is_equal_approx(v, 1.0)
	_mark_speed()


func _mark_speed() -> void:
	var pulando: bool = _day_night != null and _day_night.pulando
	for i in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(not pulando and is_equal_approx(Engine.time_scale, SPEEDS[i]))
	if _pular_button:
		_pular_button.set_pressed_no_signal(pulando)


# =================================================================== cursor (Prompt 20)
var _cursor_now := ""
var _cursor_cd := 0.0
var _cursor_mouse := Vector2.INF
var _cursor_pick_cd := 0.0


## Cursor pelo que está embaixo do mouse: construir/proibido com o posicionador, atacar em cima de
## criatura, selecionar em cima de ipezinho/robô; senão a seta.
func _update_cursor(delta: float) -> void:
	if not UiSkin.ok():
		return
	_cursor_cd -= delta
	if _cursor_cd > 0.0:
		return
	_cursor_cd = 0.1
	var want := "normal"
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer and placer.get("active"):
		want = "construir" if String(placer.get("_reason")) == "" else "proibido"
	elif get_viewport().gui_get_hovered_control() == null:
		var iso := get_tree().get_first_node_in_group("iso_view") as Node2D
		var mp := get_viewport().get_mouse_position()
		if mp.distance_to(_cursor_mouse) < 2.0 and _cursor_pick_cd > 0.0 and _cursor_now != "construir" and _cursor_now != "proibido":
			_cursor_pick_cd -= 0.1
			return  # Bloco 53: mouse parado: o que está debaixo dele muda pouco (procura a cada 0,5 s)
		_cursor_mouse = mp
		_cursor_pick_cd = 0.5
		if iso and iso.get("enabled"):
			var n = iso.pick(iso.get_global_mouse_position()).get("node")
			iso.hover = n if n != null and is_instance_valid(n) else null  # Bloco 95: o rótulo inteiro de quem está debaixo
			if n != null and is_instance_valid(n):
				if n.is_in_group("criaturas"):
					want = "atacar"
				elif n.is_in_group("ipezinhos") or n.is_in_group("robos"):
					want = "selecionar"
	elif get_viewport().gui_get_hovered_control() != null:
		var iso2 := get_tree().get_first_node_in_group("iso_view")
		if iso2 and "hover" in iso2:
			iso2.hover = null
	if want != _cursor_now:
		_cursor_now = want
		UiSkin.cursor(want)


# =================================================================== helpers de estilo
# (usados também pelas janelas dos prédios: _label, _button, _bar, _panel_style, _row_style)
func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", Tipo.CORPO)
	b.add_theme_color_override("font_color", COLOR_TEXT)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.46, 0.42))
	if UiSkin.ok():
		UiSkin.aplica_botao(b)  # Prompt 20: tábua com borda de ferro (4 estados)
		return b
	var states := {
		"normal": Color(0.3, 0.2, 0.1),
		"hover": Color(0.42, 0.28, 0.12),
		"pressed": Color(0.22, 0.14, 0.07),
		"disabled": Color(0.16, 0.14, 0.13),
	}
	for state in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[state]
		sb.border_color = COLOR_BORDER if state != "disabled" else Color(0.3, 0.27, 0.24)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		b.add_theme_stylebox_override(state, sb)
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if size >= Tipo.TITULO_JANELA and color == COLOR_TITLE:
		UiSkin.usa_fonte(l, "titulo", Tipo.PIXEL_4 if size >= Tipo.FAIXA else Tipo.PIXEL_2)  # Prompt 22: cabeçalhos e faixas na fonte de título
	return l


func _bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(84, 9)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.03, 0.03, 0.8)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(2)
	if UiSkin.ok():  # Prompt 20: aro de ferro fino e o recheio com a faixa de luz em cima
		bg.set_corner_radius_all(0)
		bg.border_color = Color(0.36, 0.3, 0.26)
		bg.set_border_width_all(1)
		bg.border_width_top = 2
		bg.border_color = Color(0.3, 0.25, 0.22)
		fill.set_corner_radius_all(0)
		fill.expand_margin_left = -1
		fill.expand_margin_right = -1
		fill.expand_margin_top = -2
		fill.expand_margin_bottom = -1
		fill.border_width_top = 1
		fill.border_color = fill_color.lightened(0.35)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _panel_style() -> StyleBox:
	if UiSkin.ok():
		return UiSkin.painel()  # Prompt 20: tábuas escuras com moldura de ferro e rebites nos cantos
	var s := StyleBoxFlat.new()
	s.bg_color = COLOR_PANEL
	s.border_color = COLOR_BORDER
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(10)
	return s


func _row_style(is_selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.25, 0.18, 0.08, 0.9) if is_selected else Color(0.14, 0.12, 0.11, 0.8)
	s.border_color = COLOR_TITLE if is_selected else Color(0, 0, 0, 0)
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(5)
	return s


# =================================================================== alertas e obras (Bloco 95)
## A coluna de ALERTAS (alertas.gd) e os numerozinhos da aba fina: tudo que pede atenção, com onde está.
func _refresh_alertas(workers: Array) -> void:
	if _alertas == null:
		return
	# sem comida: a cozinha acabou ou não dá pra todas as refeições de hoje
	var cozinhas := get_tree().get_nodes_in_group("comedouros")
	_alertas.poe("sem_comida", _falta_porcoes, "Faltam %d porções pras refeições de hoje. Cozinheiro (tecla C) e matéria-prima (caçador, horta)." % _falta_porcoes, cozinhas)
	# obras paradas (sem ninguém trabalhando) — a da forja é do ferreiro
	var obras := get_tree().get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending())
	var paradas := obras.filter(func(o): return o.obra_workers().is_empty())
	var engs := workers.filter(func(w): return w.has_method("is_engineer") and w.is_engineer()).size()
	_alertas.poe("obra_parada", paradas.size(), "%d obra%s sem ninguém trabalhando.%s" % [paradas.size(), "s" if paradas.size() != 1 else "",
		" Nenhum engenheiro: tecla 4." if engs == 0 else " Os engenheiros estão ocupados em outra."], paradas)
	# feridos e caídos
	var feridos := workers.filter(func(w): return w.get("injured") or w.get("downed"))
	var graves := feridos.filter(func(w): return w.get("downed") or w.get("injury_severity") == "grave").size()
	_alertas.poe("ferido", feridos.size(), "%d machucado%s%s. Tratam na Enfermaria (médico: tecla 3)." % [feridos.size(),
		"s" if feridos.size() != 1 else "", " (%d grave%s)" % [graves, "s" if graves != 1 else ""] if graves > 0 else ""], feridos)
	# invasão: o aviso (21:00) e a invasão em andamento
	var inv_n := 0
	var inv_txt := ""
	var inv_dica := ""
	var inv_alvos: Array = []
	if _defense and _day_night:
		var portoes := get_tree().get_nodes_in_group("barricadas")
		if _defense.invasion_active:
			var cs: Array = _defense.creatures()
			inv_n = maxi(cs.size(), 1)
			inv_dica = "Invasão! %d criatura%s na vila. Guardas no portão (tecla X)." % [cs.size(), "s" if cs.size() != 1 else ""]
			inv_alvos = cs + portoes
		elif _defense.is_invasion_night(_day_night.day) and int(_defense.get("_warned_day")) == _day_night.day:
			inv_n = 1
			inv_txt = "%dh" % int(_defense.hora_invasao)
			inv_dica = "Invasão hoje às %s. Todos pra casa; guardas no portão." % _day_night.hora_texto(_defense.hora_invasao)
			inv_alvos = portoes
	_alertas.poe("invasao", inv_n, inv_dica, inv_alvos, inv_txt)
	# onda solar
	var onda := 0
	if _sun and (_sun.wave_active() or (_sun.warned and _sun.time_to_wave() >= 0.0)):
		onda = 1
	_alertas.poe("onda_solar", onda, (_sun.forecast_text() if _sun else ""), [_hub] if _hub else [])
	# parados: sem função ou sem o que fazer
	var parados := workers.filter(_parado)
	var sem_f := parados.filter(func(w): return w.has_no_job()).size()
	_alertas.poe("ociosos", parados.size(), "%d parado%s (%d sem função). Selecione e escolha a função na barra de baixo." % [
		parados.size(), "s" if parados.size() != 1 else "", sem_f], parados)
	# greve
	var gv := 0
	var gv_dica := ""
	if _morale and (_morale.on_strike or _morale.below_time > 0.0):
		gv = 1
		gv_dica = "Greve!" if _morale.on_strike else "O ânimo está baixo: greve em %ds se não melhorar (taverna, festa, comida, camas)." % ceili(_morale.strike_grace - _morale.below_time)
	_alertas.poe("greve", gv, gv_dica, [_hub] if _hub else [])
	# Bloco 97: armazém cheio (quem entrega espera; as máquinas param)
	var cheios := get_tree().get_nodes_in_group("armazens").filter(func(a): return a.has_method("cheio") and a.cheio())
	var esperando := workers.filter(func(w): return w.has_method("motivo_no_balao") and w.motivo_parado() == "armazem_cheio").size()
	_alertas.poe("armazem_cheio", cheios.size(), "%d armazém%s cheio%s%s. Venda, gaste ou amplie (janela do Armazém); ou construa um Armazém novo." % [
		cheios.size(), "" if cheios.size() == 1 else "s", "" if cheios.size() == 1 else "s",
		(" — %d esperando pra entregar" % esperando) if esperando > 0 else ""], cheios)
	# Bloco 101: migrantes esperando no portão
	var mig := get_tree().get_first_node_in_group("migrantes")
	var esp: Array = mig.esperando.map(func(e): return e.w).filter(func(w): return is_instance_valid(w)) if mig else []
	_alertas.poe("migrantes", esp.size(), "%d migrante%s esperando no portão. Aceitar precisa de cama livre (janela Migrantes)." % [
		esp.size(), "s" if esp.size() != 1 else ""], esp)
	# desarmados, sem casaco, sem cama
	var unarmed: Array = _defense.unarmed_guards() if _defense else []
	_alertas.poe("desarmados", unarmed.size(), _unarmed_label.text, unarmed)
	var eqp := get_tree().get_first_node_in_group("equipment")
	var cold: Array = eqp.cold_without_coat() if eqp else []
	_alertas.poe("frio", cold.size(), _cold_label.text, cold)
	var sem_teto := workers.filter(func(w): return w.has_method("has_home") and not w.has_home())
	_alertas.poe("sem_teto", sem_teto.size(), "%d sem cama: dormem ao relento (ânimo cai). Construa casas (CONSTRUIR > Moradia)." % sem_teto.size(),
		get_tree().get_nodes_in_group("casas"))
	# os numerozinhos da aba fina
	var problema := workers.filter(func(w): return prioridade_na_lista(w) < 2).size()
	_set_text(_tira_pessoas.get_node("Num"), str(problema) if problema > 0 else "")
	_set_text(_tira_obras.get_node("Num"), str(obras.size()) if not obras.is_empty() else "")


## Parado de verdade: sem função ou sem o que fazer (quem está ferido conta no alerta de feridos).
func _parado(w: Node) -> bool:
	if not w.has_method("has_no_job") or w.get("injured") or w.get("downed"):
		return false
	return w.has_no_job() or w.get_state() == "idle"


## A gaveta das obras: uma linha por obra (nome, barrinha, martelo colorido trabalhando / cinza esperando).
func _refresh_obras() -> void:
	var obras := get_tree().get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending())
	if _obras_box.get_child_count() != maxi(obras.size(), 1):
		for c in _obras_box.get_children():
			_obras_box.remove_child(c)
			c.queue_free()
		if obras.is_empty():
			_obras_box.add_child(_label("Nenhuma obra encomendada. (CONSTRUIR: espaço)", Tipo.CORPO, COLOR_DIM))
			return
		for i in obras.size():
			var linha := PanelContainer.new()
			linha.add_theme_stylebox_override("panel", _style_row)
			linha.mouse_filter = Control.MOUSE_FILTER_STOP
			linha.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			_obras_box.add_child(linha)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 6)
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			linha.add_child(h)
			var ic := _icon(Icones.tex("construir", true))
			ic.custom_minimum_size = Vector2(24, 24)
			ic.name = "Martelo"
			h.add_child(ic)
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 1)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(v)
			var nome := _label("", Tipo.CORPO, COLOR_TEXT)
			nome.name = "Nome"
			nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			nome.clip_text = true
			v.add_child(nome)
			var barra := _bar(COLOR_ENGINEER)
			barra.name = "Barra"
			barra.custom_minimum_size = Vector2(170, 6)
			v.add_child(barra)
			var mat := _label("", Tipo.DETALHE, COLOR_DIM)  # Bloco 96: entregue/necessário por item
			mat.name = "Material"
			mat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mat.custom_minimum_size.x = 170
			v.add_child(mat)
			var cancela := _button("Cancelar")  # Bloco 96: devolve créditos e material
			cancela.name = "Cancelar"
			cancela.add_theme_font_size_override("font_size", Tipo.DETALHE)
			cancela.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cancela.tooltip_text = "Cancelar a obra: os créditos voltam por inteiro e o material (o já entregue e o que estiver nas mãos) volta pro armazém."
			cancela.pressed.connect(func():
				var lista := get_tree().get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending())
				if i < lista.size() and ObraSite.cancelar(lista[i]):
					Audio.click()
					show_toast("Obra cancelada: %s (créditos e material devolvidos)" % lista[i].obra_title(), COLOR_TITLE, null)
					_refresh_obras.call_deferred()
				else:
					Audio.error())
			h.add_child(cancela)
			linha.gui_input.connect(func(ev: InputEvent):
				var lista := get_tree().get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending())
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and i < lista.size():
					var cam := _main.get_node_or_null("Camera2D")
					if cam:
						cam.focus_on(lista[i].global_position))
	for i in obras.size():
		var o: Node = obras[i]
		var linha: Control = _obras_box.get_child(i)
		var trabalhando: bool = not o.obra_workers().is_empty()
		var pct := roundi(o.obra_progress() * 100.0)
		var quem := "ferreiro" if o.get("oficio") == "ferreiro" else "engenheiro"
		var site = ObraSite.de(o)
		var estado: String = site.estado(o.obra_progress()) if site else ("trabalhando" if trabalhando else "esperando " + quem)
		_set_text(linha.find_child("Nome", true, false), "%s  %d%%  —  %s" % [o.obra_title(), pct, estado])
		var mat: Label = linha.find_child("Material", true, false)
		var mt: String = site.material_texto() if site else ""
		_set_text(mat, mt)
		mat.visible = mt != ""
		var cancela: Button = linha.find_child("Cancelar", true, false)
		cancela.visible = o.has_method("obra_cancelar")
		var barra: ProgressBar = linha.find_child("Barra", true, false)
		barra.value = pct
		_set_fill(barra, COLOR_ENGINEER if trabalhando else Color(0.55, 0.5, 0.45))
		var martelo: TextureRect = linha.find_child("Martelo", true, false)
		martelo.modulate = Color.WHITE if trabalhando else Color(0.45, 0.45, 0.45)  # martelo cinza = esperando
