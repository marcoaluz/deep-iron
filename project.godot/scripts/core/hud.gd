extends CanvasLayer
## HUD no estilo Frostpunk (Bloco 31), montado por código:
##   - TOPO: barra de recursos (dia/noite, créditos, minério + vender, madeira,
##     matéria-prima, comida, camas, ânimo, saúde, estação). Detalhes no tooltip.
##   - ESQUERDA: força de trabalho (total, SEM FUNÇÃO em destaque, recrutar e a lista).
##   - EMBAIXO: barra de ordens — um botão grande por função (ícone, nome, tecla e
##     quantos já estão nela). Sempre à vista, nunca coberta por nada.
##   - DIREITA: construções (abre a janela de cada prédio).
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
		"Busca matéria-prima no armazém e prepara a comida no comedouro."],
	["lenhador", "Lenhador", "L", "res://assets/game/axe.png", "toggle_lumber", COLOR_LUMBER,
		"Corta madeira na clareira e leva pro armazém."],
	["guarda", "Guarda", "X", "res://assets/game/lanca.png", "toggle_guard", COLOR_GUARD,
		"Treina de dia no campo e defende os portões à noite. A arma se gasta na luta: quebrou, busca outra no Arsenal."],
	["pesquisador", "Pesquisador", "Z", "res://assets/game/note.png", "toggle_research", COLOR_RESEARCH,
		"Trabalha no laboratório de dia, gerando pontos pra pesquisa em andamento."],
]
const TOP_BAR_H := 40.0
const SIDE_MARGIN := 10.0

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
var _sell_button: Button
var _auto_sell_check: CheckBox
var _last_credits: float = -1.0
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
var _recruit_button: Button
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
# direita
var _buildings_box: VBoxContainer
var _panels: Dictionary = {}  # id ("hub", "escavadeira", ...) -> janela
var _panel_buttons: Dictionary = {}  # id -> botão na coluna de construções
# atalhos
var _hint_panel: PanelContainer

var _refresh_timer := 0.0
var _style_row := _row_style(false)
var _style_row_selected := _row_style(true)


func _ready() -> void:
	add_to_group("hud")
	_main = get_parent()
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


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 1.0 / refresh_rate
		_refresh()


# =================================================================== montagem
func _build() -> void:
	_build_top_bar()
	_build_order_bar()
	_build_menu = preload("res://scripts/core/build_menu.gd").new()
	add_child(_build_menu)
	_build_menu.setup(self)
	_build_workforce_panel()
	_build_buildings_column()
	_build_hints()
	set_hints_visible(Settings.get_value("hud", "show_hints", false))
	set_collapsed.call_deferred(Settings.get_value("hud", "collapsed", false), false)


# ------------------------------------------------------------ topo: recursos
func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	var style := _panel_style()
	style.set_corner_radius_all(0)
	style.border_width_top = 0
	style.border_width_left = 0
	style.border_width_right = 0
	style.set_content_margin_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = TOP_BAR_H
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	# dia/noite com a barrinha da fase
	var phase := VBoxContainer.new()
	phase.add_theme_constant_override("separation", 1)
	row.add_child(phase)
	var phase_top := HBoxContainer.new()
	phase_top.add_theme_constant_override("separation", 6)
	phase.add_child(phase_top)
	_phase_label = _label("DIA 1", 14, COLOR_DAY)
	phase_top.add_child(_phase_label)
	_phase_time_label = _label("", 11, COLOR_DIM)
	phase_top.add_child(_phase_time_label)
	_phase_bar = _bar(COLOR_DAY)
	_phase_bar.custom_minimum_size = Vector2(130, 4)
	phase.add_child(_phase_bar)
	row.add_child(VSeparator.new())

	_chip(row, "credits", coin_icon, "Créditos")
	_chip(row, "ore", ore_icon, "Minério")
	if _economy:
		_sell_button = _button("Vender")
		_sell_button.add_theme_font_size_override("font_size", 12)
		_sell_button.tooltip_text = "Vende todo o minério do armazém (V)"
		_sell_button.pressed.connect(_on_sell_pressed)
		row.add_child(_sell_button)
		_auto_sell_check = CheckBox.new()
		_auto_sell_check.text = "auto"
		_auto_sell_check.focus_mode = Control.FOCUS_NONE
		_auto_sell_check.tooltip_text = "Vende sozinho o que chegar no armazém"
		_auto_sell_check.add_theme_font_size_override("font_size", 11)
		_auto_sell_check.button_pressed = _economy.auto_sell
		_auto_sell_check.toggled.connect(_on_auto_sell_toggled)
		row.add_child(_auto_sell_check)
	row.add_child(VSeparator.new())
	_chip(row, "wood", load("res://assets/game/wood_log.png"), "Madeira")
	_chip(row, "raw", load("res://assets/game/raw_food.png"), "Matéria-prima")
	_chip(row, "food", load("res://assets/game/food_basket.png"), "Comida pronta")
	row.add_child(VSeparator.new())
	_chip(row, "beds", null, "Camas")
	_chip(row, "joy", null, "Ânimo")
	_chip(row, "health", load("res://assets/game/bandage.png"), "Saúde")

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_chip(row, "sun", null, "Estação", false)
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
		box.add_child(_icon(icon_tex))
	elif show_title:
		box.add_child(_label(title, 11, COLOR_DIM))
	var value := _label("0", 15, COLOR_TEXT)
	box.add_child(value)
	_chips[id] = {"box": box, "value": value, "title": title}


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
	var style := _panel_style()
	style.set_content_margin_all(8)
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -SIDE_MARGIN
	add_child(bar)
	_order_bar = bar
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	bar.add_child(v)
	_selection_caption = _label("", 13, COLOR_DIM)
	_selection_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_selection_caption)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	# Bloco 46: CONSTRUIR abre o menu de construção por abas (também na barra de espaço)
	var build := _order_button(row, "Construir", "Espaço", load("res://assets/game/hammer.png"), COLOR_TITLE,
		"Menu de construção: casas, comedouro, lazer, pesquisa, defesa, coleta automática…")
	build.button.pressed.connect(toggle_build_menu)
	_build_button = build.button
	row.add_child(VSeparator.new())
	for entry in ORDER_JOBS:
		var job: String = entry[0]
		var info := _order_button(row, entry[1], entry[2], load(entry[3]), entry[5], entry[6])
		info.button.pressed.connect(Callable(_main, entry[4]))
		_job_buttons[job] = info
	row.add_child(VSeparator.new())
	var none := _order_button(row, "Sem função", "0", null, COLOR_NO_JOB,
		"Tira a função: entregam o que estiverem carregando e esperam no Centro da Vila.")
	none.button.pressed.connect(_main.clear_job)
	none.button.toggle_mode = false
	_no_job_button = none.button
	var extra := _order_button(row, "Turno extra", "T", null, COLOR_OVERTIME,
		"Continuam trabalhando à noite (e vão ficando zangados).")
	extra.button.pressed.connect(_main.toggle_overtime)
	_overtime_button = extra.button


## Botão grande da barra de ordens: ícone, nome, tecla e contador. Fica "aceso"
## (pressionado) quando TODOS os selecionados já têm aquela função.
func _order_button(row: HBoxContainer, title: String, key: String, icon_tex: Texture2D, color: Color, tip: String) -> Dictionary:
	var b := _button("")
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(90, 62)
	b.tooltip_text = "%s  (tecla %s)\n%s\nCom ipezinhos selecionados: aplica. Se todos já forem, tira." % [title, key, tip]
	var on := StyleBoxFlat.new()
	on.bg_color = Color(0.42, 0.3, 0.12)
	on.border_color = COLOR_TITLE
	on.set_border_width_all(2)
	on.set_corner_radius_all(3)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	row.add_child(b)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	if icon_tex:
		var icon := _icon(icon_tex)
		icon.custom_minimum_size = Vector2(22, 22)
		top.add_child(icon)
	var count := _label("", 14, COLOR_TEXT)
	top.add_child(count)
	var name_label := _label(title, 12, color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_label)
	var key_label := _label("[%s]" % key, 10, COLOR_DIM)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(key_label)
	return {"button": b, "count": count}


# ------------------------------------------------------------ esquerda: força de trabalho
func _build_workforce_panel() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.position = Vector2(SIDE_MARGIN, TOP_BAR_H + SIDE_MARGIN)
	panel.custom_minimum_size = Vector2(290, 0)
	add_child(panel)
	_left_panel = panel
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("FORÇA DE TRABALHO", 13, COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_workers_count_label = _label("", 13, COLOR_TEXT)
	head.add_child(_workers_count_label)
	_collapse_button = _button("–")
	_collapse_button.tooltip_text = "Recolher/abrir a lista de ipezinhos"
	_collapse_button.custom_minimum_size = Vector2(26, 0)
	_collapse_button.pressed.connect(func():
		Audio.click()
		set_collapsed(_collapse_button.text == "–"))
	head.add_child(_collapse_button)

	_no_job_label = _label("", 13, COLOR_NO_JOB)
	_no_job_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_no_job_label)
	_obras_label = _label("", 13, COLOR_ENGINEER)
	_obras_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_obras_label)
	_unarmed_label = _label("", 13, COLOR_NO_JOB)
	_unarmed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unarmed_label.visible = false
	v.add_child(_unarmed_label)
	_downed_label = _label("", 13, Color(1.0, 0.4, 0.35))
	_downed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_downed_label.visible = false
	v.add_child(_downed_label)
	_cold_label = _label("", 13, Color(0.7, 0.85, 1.0))
	_cold_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cold_label.visible = false
	v.add_child(_cold_label)
	if _economy:
		_recruit_button = _button("Recrutar ipezinho")
		_recruit_button.pressed.connect(_on_recruit_pressed)
		v.add_child(_recruit_button)

	_workers_title = _label("IPEZINHOS", 11, COLOR_DIM)
	v.add_child(_workers_title)
	_rows_scroll = ScrollContainer.new()
	_rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_rows_scroll)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 4)
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_scroll.add_child(_rows_box)


# ------------------------------------------------------------ direita: construções
func _build_buildings_column() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -SIDE_MARGIN
	panel.offset_top = TOP_BAR_H + SIDE_MARGIN
	add_child(panel)
	_buildings_box = VBoxContainer.new()
	_buildings_box.add_theme_constant_override("separation", 4)
	panel.add_child(_buildings_box)
	_buildings_box.add_child(_label("CONSTRUÇÕES", 13, COLOR_TITLE))
	if _hub:
		_add_panel("hub", preload("res://scripts/core/hub_panel.gd"), _hub)
	var arm := get_tree().get_first_node_in_group("armazens")
	if arm and _economy:
		_add_panel("armazem", preload("res://scripts/core/armazem_panel.gd"), arm)  # Bloco 39
	if _hub:
		_add_panel("coletor", preload("res://scripts/core/coletor_panel.gd"), _hub)  # Bloco 45
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
	v.add_child(_label("ATALHOS  (H fecha)", 14, COLOR_TITLE))
	var lines := [
		"Seleção:  clique  •  arrastar = vários  •  Shift+clique = somar/tirar  •  Esc = soltar  •  Tab = próximo  •  F = seguir",
		"Ordens:  botão direito = mover / minerar a jazida clicada",
		"Funções:  1 minerador  •  2 caçador  •  3 médico  •  4 engenheiro  •  C cozinheiro  •  L lenhador  •  X guarda  •  Z pesquisador  •  0 sem função  •  T turno extra",
		"Economia:  V vender minério  •  R recrutar",
		"Construir:  Espaço = menu de construção (casas, comedouro, lazer, pesquisa, defesa, coleta automática…)",
		"Prédios:  U Centro da Vila  •  E Escavadeira  •  O Oficina  •  I Enfermaria  •  B Bem-estar  •  G Defesa  •  Q Laboratório  •  Y Sol  •  J Diário  (ou clique no prédio)",
		"Câmera:  roda = zoom  •  botão do meio / WASD / setas = mover  •  Home = centralizar",
		"Jogo:  F5 salvar  •  F9 carregar  •  M música  •  Esc/P pausa  •  N pular fase (teste)  •  K machucar (teste; Shift+K grave)",
	]
	for line in lines:
		v.add_child(_label(line, 12, COLOR_TEXT))


# =================================================================== janelas das estruturas
## Cada janela é um PanelContainer com setup(hud, alvo, economia), refresh(),
## button_text() e has_available_action().
func _add_panel(id: String, script: GDScript, target: Node) -> void:
	var button := _button("")
	button.add_theme_font_size_override("font_size", 12)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.x = 170
	button.pressed.connect(func():
		Audio.click()
		toggle_panel(id))
	_buildings_box.add_child(button)
	var panel: PanelContainer = script.new()
	add_child(panel)
	panel.setup(self, target, _economy)
	_panels[id] = panel
	_panel_buttons[id] = button


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
		Audio.click()
	panel.visible = true
	panel.refresh()


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
	if closed:
		Audio.click()
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


## Aviso curto no canto inferior direito, acima da barra de ordens (ex.: "Jogo salvo").
func show_toast(text: String, color: Color = COLOR_TITLE) -> void:
	var l := _label(text, 14, color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# empilha acima dos avisos que ainda estão na tela
	var stacked := get_children().filter(func(c): return c.has_meta("toast")).size()
	l.set_meta("toast", true)
	var base := (_order_bar.size.y + SIDE_MARGIN * 2.0) if _order_bar else 12.0
	l.offset_right = -16.0
	l.offset_bottom = -base - 22.0 * stacked
	add_child(l)
	var tween := l.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(l, "modulate:a", 0.0, 0.8)
	tween.tween_callback(l.queue_free)


## Faixa de conquista no topo da tela (some sozinha).
func show_banner(title: String, subtitle: String) -> void:
	var panel := PanelContainer.new()
	var style := _panel_style()
	style.border_color = COLOR_TITLE
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# empilha abaixo das faixas que ainda estão na tela (ex.: duas mortes seguidas)
	var stacked := get_children().filter(func(c): return c.has_meta("banner")).size()
	panel.set_meta("banner", true)
	panel.offset_top = 70.0 + 96.0 * stacked
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var t := _label(title, 26, COLOR_TITLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	t.add_theme_constant_override("outline_size", 5)
	v.add_child(t)
	var st := _label(subtitle, 14, COLOR_TEXT)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	add_child(panel)
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(6.0)
	tween.tween_property(panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(panel.queue_free)


func _on_sell_pressed() -> void:
	Audio.click()
	_economy.sell_all()
	_refresh()


func _on_auto_sell_toggled(on: bool) -> void:
	Audio.click()
	_economy.auto_sell = on


func _on_recruit_pressed() -> void:
	Audio.click()
	var worker: Node2D = _economy.recruit()
	if worker:
		var cam := _main.get_node_or_null("Camera2D")
		if cam:
			cam.focus_on(worker.global_position)
	_refresh()


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
	var name_label := _label(_worker_name(worker), 14, COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var tag_label := _label("", 11, COLOR_DIM)  # função / "turno extra" / "irritado"
	top.add_child(tag_label)

	var state_label := _label("", 12, COLOR_DIM)
	state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_label.custom_minimum_size.x = 250
	v.add_child(state_label)

	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 6)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bars)
	bars.add_child(_label("fome", 11, COLOR_DIM))
	var hunger_bar := _bar(COLOR_HUNGER_OK)
	bars.add_child(hunger_bar)
	bars.add_child(_label("carga", 11, COLOR_DIM))
	var cargo_bar := _bar(COLOR_CARGO)
	bars.add_child(cargo_bar)
	bars.add_child(_label("ânimo", 11, COLOR_DIM))
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
	_refresh_order_bar(workers)
	_refresh_worker_rows(workers)


func _refresh_phase() -> void:
	if _day_night == null:
		return
	var night: bool = _day_night.is_night()
	var color := COLOR_NIGHT if night else COLOR_DAY
	_phase_label.text = ("NOITE %d" if night else "DIA %d") % _day_night.day
	_phase_label.add_theme_color_override("font_color", color)
	var left := ceili(_day_night.time_left_in_phase())
	_phase_time_label.text = ("amanhece em %d:%02d" if night else "anoitece em %d:%02d") % [left / 60, left % 60]
	_phase_bar.value = _day_night.phase_progress() * 100.0
	(_phase_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = color


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
		var value: int = _economy.sale_value()
		_sell_button.text = "Vender +%d" % value
		_sell_button.disabled = value <= 0
		if _auto_sell_check.button_pressed != _economy.auto_sell:
			_auto_sell_check.set_pressed_no_signal(_economy.auto_sell)

	# minério: total na barra; por tipo + jazidas no tooltip
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.total_stored
	var parts: Array[String] = []
	for t in Ores.TYPES:
		var amount: float = _economy.stored_ore(t) if _economy else 0.0
		var unlocked: bool = _oficina == null or _oficina.is_ore_unlocked(t)
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
	_set_chip("food", "ACABOU" if stock <= 0.0 else "%d/%d" % [int(stock), int(capacity)], food_color,
		"No comedouro." + ("\nNinguém cozinhando!" if cooks == 0 else ""))

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


## Força de trabalho: total, SEM FUNÇÃO em destaque e o botão de recrutar.
func _refresh_workforce(workers: Array) -> void:
	var no_job := workers.filter(func(w): return w.has_method("has_no_job") and w.has_no_job()).size()
	if no_job > 0:
		_no_job_label.text = "SEM FUNÇÃO: %d  —  selecione e escolha uma função na barra de baixo" % no_job
		_no_job_label.add_theme_color_override("font_color", COLOR_NO_JOB)
	else:
		_no_job_label.text = "Todos com função"
		_no_job_label.add_theme_color_override("font_color", COLOR_DIM)
	# Bloco 31: obras encomendadas e se tem engenheiro pra elas
	var obras := get_tree().get_nodes_in_group("obras").filter(func(o): return o.has_method("obra_pending") and o.obra_pending())
	var engineers := workers.filter(func(w): return w.has_method("is_engineer") and w.is_engineer()).size()
	var working := obras.filter(func(o): return not o.obra_workers().is_empty()).size()
	_obras_label.visible = not obras.is_empty()
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
		_workers_count_label.text = "%d / %d" % [workers.size(), _economy.max_workers]
		var cost: int = _economy.recruit_cost()
		var why: String = _economy.recruit_block_reason()
		_recruit_button.text = "Recrutar ipezinho  (%d cr)" % cost if why == "" or why.begins_with("falta") \
			else "Recrutar: " + why
		_recruit_button.tooltip_text = why if why != "" else "Chega na frente do Centro da Vila e ganha uma cama."
		_recruit_button.disabled = why != ""
	else:
		_workers_count_label.text = str(workers.size())


## Barra de ordens: quantos em cada função e quais estão "acesas" pra seleção atual.
func _refresh_order_bar(workers: Array) -> void:
	var counts := {}
	for w in workers:
		if w.get("job") != null:
			counts[w.job] = counts.get(w.job, 0) + 1
	var sel: Array = _main.selection.filter(func(u): return is_instance_valid(u))
	for job in _job_buttons:
		var info: Dictionary = _job_buttons[job]
		var n: int = counts.get(job, 0)
		info.count.text = str(n) if n > 0 else ""
		info.button.set_pressed_no_signal(not sel.is_empty() and sel.all(func(u): return u.job == job))
		info.button.modulate = Color.WHITE if (n > 0 or not sel.is_empty()) else Color(1, 1, 1, 0.7)
	_overtime_button.set_pressed_no_signal(not sel.is_empty() and sel.all(func(u): return u.overtime))
	_no_job_button.disabled = sel.is_empty() or sel.all(func(u): return u.has_no_job())
	if sel.is_empty():
		_selection_caption.text = "Nenhum ipezinho selecionado  —  clique ou arraste no mapa (ou na lista) e escolha a função"
		_selection_caption.add_theme_color_override("font_color", COLOR_DIM)
	else:
		var names: Array[String] = []
		for u in sel.slice(0, 4):
			names.append(_worker_name(u))
		var more := "  +%d" % (sel.size() - 4) if sel.size() > 4 else ""
		_selection_caption.text = "%d selecionado%s: %s%s  —  escolha a função" % [
			sel.size(), "s" if sel.size() > 1 else "", ", ".join(names), more]
		_selection_caption.add_theme_color_override("font_color", COLOR_TITLE)


func _refresh_worker_rows(workers: Array) -> void:
	# cria/remove linhas se entrar ou sair ipezinho
	for w in workers:
		if not _rows.has(w):
			_rows[w] = _make_row(w)
	for w in _rows.keys():
		if not is_instance_valid(w) or not workers.has(w):
			_rows[w].panel.queue_free()
			_rows.erase(w)

	# a lista cresce até caber: nunca invade a barra de ordens embaixo
	var bottom_limit := get_viewport().get_visible_rect().size.y - (_order_bar.size.y + SIDE_MARGIN * 3.0)
	var room := bottom_limit - _rows_scroll.global_position.y
	var max_h := clampf(room, 60.0, worker_list_max_height)
	_rows_scroll.custom_minimum_size.y = minf(_rows_box.get_combined_minimum_size().y, max_h)
	_left_panel.reset_size()

	var picked: int = _main.selection.size()
	_workers_title.text = "IPEZINHOS  —  %d selecionados" % picked if picked > 1 else "IPEZINHOS  (clique pra selecionar)"
	_workers_title.add_theme_color_override("font_color", COLOR_TITLE if picked > 1 else COLOR_DIM)
	for w in workers:
		var row: Dictionary = _rows[w]
		row.name.text = _worker_name(w)
		var hunger_ratio: float = w.hunger / w.hunger_max
		row.hunger.max_value = w.hunger_max
		row.hunger.value = w.hunger
		var fill := COLOR_HUNGER_OK
		if w.hunger <= 0.0:
			fill = COLOR_HUNGER_BAD
		elif w.hunger < w.hunger_threshold:
			fill = COLOR_HUNGER_LOW if hunger_ratio > 0.15 else COLOR_HUNGER_BAD
		(row.hunger.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = fill
		row.cargo.max_value = w.cargo_capacity
		row.cargo.value = w.carrying
		row.joy.value = w.happiness
		(row.joy.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = _joy_color(w.happiness)
		row.joy.tooltip_text = "ânimo %d (%s)" % [roundi(w.happiness), w.happiness_label()]
		(row.cargo.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Ores.UI_COLORS.get(w.cargo_type, COLOR_CARGO)
		var state: String = w.get_state()
		row.state.text = w.get_state_label() if w.hunger > 0.0 else "FAMINTO!"
		var state_color: Color = STATE_COLORS.get(state, COLOR_DIM)
		if w.hunger <= 0.0:
			state_color = COLOR_HUNGER_BAD
		elif w.injured:
			state_color = COLOR_INJURED
		elif state == "idle" and w.has_no_job():
			state_color = COLOR_NO_JOB
		row.state.add_theme_color_override("font_color", state_color)
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
		if w.overtime:
			tags.append("turno extra")
		if w.mood() > 0:
			tags.append(w.mood_label())
			if not w.has_no_job():
				tag_color = [COLOR_OVERTIME, COLOR_IRRITATED, COLOR_FURIOUS][w.mood()]
		row.tag.text = "  ".join(tags)
		row.tag.add_theme_color_override("font_color", tag_color)
		row.panel.add_theme_stylebox_override("panel", _style_row_selected if _main.is_selected(w) else _style_row)


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
	for id in _panels:
		var panel: PanelContainer = _panels[id]
		var button: Button = _panel_buttons[id]
		if panel.has_method("is_available"):
			button.visible = panel.is_available()  # ex.: robô só depois de achado
		button.text = panel.button_text()
		button.tooltip_text = button.text  # a coluna corta textos longos
		# destaca o botão quando dá pra comprar/fabricar alguma coisa
		button.add_theme_color_override("font_color", COLOR_TITLE if panel.has_available_action() else COLOR_TEXT)
		panel.refresh()


# =================================================================== helpers de estilo
# (usados também pelas janelas dos prédios: _label, _button, _bar, _panel_style, _row_style)
func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", COLOR_TEXT)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.46, 0.42))
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
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _panel_style() -> StyleBoxFlat:
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
