extends CanvasLayer
## HUD do protótipo: recursos no topo, lista de ipezinhos (clicável) e dica de controles.
## Montado por código pra ficar fácil de mexer sem brigar com a cena.

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
}

@export var ore_icon: Texture2D
@export var coin_icon: Texture2D
## Altura máxima da lista de ipezinhos antes de virar rolagem.
@export var worker_list_max_height: float = 300.0
## Atualizações do HUD por segundo.
@export var refresh_rate: float = 10.0

var _main: Node
var _economy: Node
var _day_night: Node
var _phase_label: Label
var _phase_time_label: Label
var _phase_bar: ProgressBar
var _village_label: Label
var _hub: Node
var _dig: Node
var _panels: Dictionary = {}  # id ("hub", "escavadeira", ...) -> janela
var _panel_buttons: Dictionary = {}  # id -> botão no painel principal
var _panel_grid: GridContainer  # botões dos prédios, em 2 colunas
var _stored_label: Label
var _deposits_label: Label
var _stock_label: RichTextLabel
var _oficina: Node
var _inf: Node
var _morale: Node
var _finds: Node
var _abyss: Node
var _defense: Node
var _diary: Node
var _research: Node
var _sun: Node
var _sun_label: Label
var _sun_overlay: ColorRect
var _morale_label: Label
var _credits_label: Label
var _sell_button: Button
var _auto_sell_check: CheckBox
var _recruit_button: Button
var _overtime_button: Button
var _cook_button: Button
var _miner_button: Button
var _no_job_button: Button
var _lumber_button: Button
var _guard_button: Button
var _research_button: Button
var _food_label: Label
var _workers_count_label: Label
var _workers_title: Label
var _main_panel: PanelContainer
var _main_vbox: VBoxContainer
var _collapse_button: Button
var _collapse_index: int = -1  # daqui pra baixo o painel recolhe
var _hint: Label
var _rows_scroll: ScrollContainer
var _rows_box: VBoxContainer
var _last_credits: float = -1.0
var _rows: Dictionary = {}  # ipezinho -> {panel, name, state, hunger, cargo}
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


# ------------------------------------------------------------ montagem
func _build() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(300, 0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	_main_panel = panel
	_main_vbox = vbox
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)
	var title := _label("DEEP IRON", 20, COLOR_TITLE)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	title.add_theme_constant_override("outline_size", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_collapse_button = _button("–")
	_collapse_button.tooltip_text = "Recolher/abrir os botões e a lista de ipezinhos"
	_collapse_button.custom_minimum_size = Vector2(28, 0)
	_collapse_button.pressed.connect(func():
		Audio.click()
		set_collapsed(_collapse_button.text == "–"))
	title_row.add_child(_collapse_button)

	if _day_night:
		var phase_row := HBoxContainer.new()
		phase_row.add_theme_constant_override("separation", 8)
		vbox.add_child(phase_row)
		_phase_label = _label("", 15, COLOR_DAY)
		phase_row.add_child(_phase_label)
		_phase_time_label = _label("", 12, COLOR_DIM)
		_phase_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_phase_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		phase_row.add_child(_phase_time_label)
		_phase_bar = _bar(COLOR_DAY)
		_phase_bar.custom_minimum_size.y = 5
		_phase_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(_phase_bar)
		_sun_label = _label("", 12, COLOR_DIM)
		vbox.add_child(_sun_label)

	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 8)
	vbox.add_child(res_row)
	if ore_icon:
		var icon := TextureRect.new()
		icon.texture = ore_icon
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		res_row.add_child(icon)
	_stored_label = _label("0", 18, COLOR_TEXT)
	res_row.add_child(_stored_label)
	res_row.add_child(_label("minério armazenado", 13, COLOR_DIM))
	# estoque por tipo, cada um na sua cor
	_stock_label = RichTextLabel.new()
	_stock_label.bbcode_enabled = true
	_stock_label.fit_content = true
	_stock_label.scroll_active = false
	_stock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # quebra em vez de alargar o painel
	_stock_label.custom_minimum_size.x = 300
	_stock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stock_label.add_theme_font_size_override("normal_font_size", 13)
	vbox.add_child(_stock_label)

	_deposits_label = _label("", 13, COLOR_DIM)
	vbox.add_child(_deposits_label)
	_village_label = _label("", 13, COLOR_DIM)
	vbox.add_child(_village_label)
	_food_label = _label("", 13, COLOR_DIM)
	vbox.add_child(_food_label)
	_morale_label = _label("", 13, COLOR_DIM)
	vbox.add_child(_morale_label)

	if _economy:
		_build_economy(vbox)

	vbox.add_child(HSeparator.new())
	var header := HBoxContainer.new()
	vbox.add_child(header)
	_workers_title = _label("IPEZINHOS", 12, COLOR_DIM)
	_workers_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_workers_title)
	_workers_count_label = _label("", 12, COLOR_DIM)
	header.add_child(_workers_count_label)

	_rows_scroll = ScrollContainer.new()
	_rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_rows_scroll)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 4)
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_scroll.add_child(_rows_box)

	# dica de controles no canto inferior esquerdo
	var hint := _label(
		"Clique: selecionar   •   Arrastar: selecionar vários   •   Shift+clique: somar/tirar   •   Botão dir.: mover / minerar (jazida)   •   Esc: soltar   •   Tab: próximo   •   F: seguir\n"
		+ "Roda: zoom   •   Botão do meio / WASD / setas: mover câmera   •   Home: centralizar\n"
		+ "V: vender minério   •   R: recrutar   •   M: liga/desliga música   •   N: pular fase (teste)   •   K: machucar selecionado (teste; Shift+K: grave)   •   T: turno extra   •   1: minerador   •   0: sem função   •   C: cozinheiro   •   L: lenhador   •   X: guarda   •   Z: pesquisador   •   H: esconder dicas   •   Esc/P: pausa\n"
		+ "U: Centro da Vila   •   E: Escavadeira   •   O: Oficina   •   I: Enfermaria   •   B: Bem-estar   •   G: Defesa   •   Q: Laboratório   •   Y: Sol   •   J: Diário   •   ou clique no prédio   •   F5: salvar   •   F9: carregar",
		12, Color(0.85, 0.8, 0.72, 0.75))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_left = 14.0
	hint.offset_bottom = -10.0
	hint.offset_top = -10.0
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
	_hint = hint
	set_hints_visible(Settings.get_value("hud", "show_hints", true))
	set_collapsed.call_deferred(Settings.get_value("hud", "collapsed", false), false)
	add_child(hint)


func _build_economy(vbox: VBoxContainer) -> void:
	var credits_row := HBoxContainer.new()
	credits_row.add_theme_constant_override("separation", 8)
	vbox.add_child(credits_row)
	if coin_icon:
		var icon := TextureRect.new()
		icon.texture = coin_icon
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		credits_row.add_child(icon)
	_credits_label = _label("0", 18, COLOR_TITLE)
	credits_row.add_child(_credits_label)
	credits_row.add_child(_label("créditos", 13, COLOR_DIM))
	_collapse_index = vbox.get_child_count()  # botões e lista recolhem daqui pra baixo

	var sell_row := HBoxContainer.new()
	sell_row.add_theme_constant_override("separation", 6)
	vbox.add_child(sell_row)
	_sell_button = _button("Vender minério")
	_sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_button.pressed.connect(_on_sell_pressed)
	sell_row.add_child(_sell_button)
	_auto_sell_check = CheckBox.new()
	_auto_sell_check.text = "auto"
	_auto_sell_check.focus_mode = Control.FOCUS_NONE
	_auto_sell_check.tooltip_text = "Vende sozinho o que chegar no armazém"
	_auto_sell_check.add_theme_font_size_override("font_size", 12)
	_auto_sell_check.button_pressed = _economy.auto_sell
	_auto_sell_check.toggled.connect(_on_auto_sell_toggled)
	sell_row.add_child(_auto_sell_check)

	_recruit_button = _button("Recrutar ipezinho")
	_recruit_button.pressed.connect(_on_recruit_pressed)
	vbox.add_child(_recruit_button)

	# ordens pros selecionados: em grade (3 por linha) pra economizar altura
	var actions := GridContainer.new()
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 4)
	actions.add_theme_constant_override("v_separation", 4)
	vbox.add_child(actions)
	_overtime_button = _button("Turno extra  (T)")
	_overtime_button.tooltip_text = "Os selecionados continuam trabalhando à noite (e vão ficando zangados)"
	_overtime_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overtime_button.pressed.connect(func(): _main.toggle_overtime())
	actions.add_child(_overtime_button)
	_cook_button = _button("Cozinheiro  (C)")
	_cook_button.tooltip_text = "Os selecionados param de minerar e passam a buscar comida na horta pro comedouro"
	_cook_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cook_button.pressed.connect(func(): _main.toggle_cook())
	actions.add_child(_cook_button)
	_lumber_button = _button("Lenhador  (L)")
	_lumber_button.tooltip_text = "Os selecionados param de minerar e vão cortar madeira na clareira"
	_lumber_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lumber_button.pressed.connect(func(): _main.toggle_lumber())
	actions.add_child(_lumber_button)
	_guard_button = _button("Guarda  (X)")
	_guard_button.tooltip_text = "Os selecionados viram guardas: treinam de dia no campo e à noite defendem os portões"
	_guard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guard_button.pressed.connect(func(): _main.toggle_guard())
	actions.add_child(_guard_button)
	_research_button = _button("Pesquisador  (Z)")
	_research_button.tooltip_text = "Os selecionados trabalham no laboratório de dia, gerando pontos pra pesquisa em andamento"
	_research_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_research_button.pressed.connect(func(): _main.toggle_research())
	actions.add_child(_research_button)
	_miner_button = _button("Minerador  (1)")
	_miner_button.tooltip_text = "Os selecionados vão minerar e levar o minério pro armazém"
	_miner_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_miner_button.pressed.connect(func(): _main.toggle_miner())
	actions.add_child(_miner_button)
	_no_job_button = _button("Sem função  (0)")
	_no_job_button.tooltip_text = "Tira a função dos selecionados: entregam o que estiverem carregando e esperam no Centro da Vila"
	_no_job_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_no_job_button.pressed.connect(func(): _main.clear_job())
	actions.add_child(_no_job_button)
	for b in [_overtime_button, _cook_button, _lumber_button, _guard_button, _research_button, _miner_button, _no_job_button]:
		b.add_theme_font_size_override("font_size", 12)

	if _hub:
		_add_panel("hub", preload("res://scripts/core/hub_panel.gd"), _hub, vbox)
	if _dig:
		_add_panel("escavadeira", preload("res://scripts/core/escavadeira_panel.gd"), _dig, vbox)
	if _oficina:
		_add_panel("oficina", preload("res://scripts/core/oficina_panel.gd"), _oficina, vbox)
	if _inf:
		_add_panel("enfermaria", preload("res://scripts/core/enfermaria_panel.gd"), _inf, vbox)
	if _morale:
		_add_panel("moral", preload("res://scripts/core/moral_panel.gd"), _morale, vbox)
	if _finds:
		_add_panel("robo", preload("res://scripts/core/robo_panel.gd"), _finds, vbox)
	if _abyss:
		_add_panel("abismo", preload("res://scripts/core/abyss_panel.gd"), _abyss, vbox)
	if _defense:
		_add_panel("defesa", preload("res://scripts/core/defense_panel.gd"), _defense, vbox)
	if _research:
		_add_panel("lab", preload("res://scripts/core/lab_panel.gd"), _research, vbox)
	if _sun:
		_add_panel("sol", preload("res://scripts/core/sun_panel.gd"), _sun, vbox)
	if _diary:
		_add_panel("diario", preload("res://scripts/core/diary_panel.gd"), _diary, vbox)


# ------------------------------------------------------------ janelas das estruturas
## Cada janela é um PanelContainer com setup(hud, alvo, economia), refresh(),
## button_text() e has_available_action().
func _add_panel(id: String, script: GDScript, target: Node, vbox: VBoxContainer) -> void:
	if _panel_grid == null:
		_panel_grid = GridContainer.new()
		_panel_grid.columns = 3
		_panel_grid.add_theme_constant_override("h_separation", 4)
		_panel_grid.add_theme_constant_override("v_separation", 4)
		vbox.add_child(_panel_grid)
	var button := _button("")
	button.add_theme_font_size_override("font_size", 12)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.x = 118
	button.pressed.connect(func():
		Audio.click()
		toggle_panel(id))
	_panel_grid.add_child(button)
	var panel: PanelContainer = script.new()
	add_child(panel)
	panel.setup(self, target, _economy)
	_panels[id] = panel
	_panel_buttons[id] = button


func open_panel(id: String) -> void:
	if not _panels.has(id):
		return
	for other in _panels:
		if other != id:
			_panels[other].visible = false
	var panel: PanelContainer = _panels[id]
	if not panel.visible:
		Audio.click()
	panel.visible = true
	panel.refresh()


## Abre a janela da estrutura clicada no mapa (ela diz qual pelo panel_id).
func open_panel_for(node: Node) -> void:
	open_panel(node.get("panel_id"))


## Fecha a janela aberta. Retorna true se havia alguma (pro Esc não soltar a seleção junto).
func close_panels() -> bool:
	var closed := false
	for id in _panels:
		if _panels[id].visible:
			_panels[id].visible = false
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


## Recolhe/abre os botões e a lista de ipezinhos (fica lembrado nas configurações).
func set_collapsed(on: bool, remember: bool = true) -> void:
	if _collapse_index < 0 or _main_vbox == null:
		return
	for i in range(_collapse_index, _main_vbox.get_child_count()):
		_main_vbox.get_child(i).visible = not on
	_collapse_button.text = "+" if on else "–"
	_main_panel.reset_size()
	if remember:
		Settings.set_value("hud", "collapsed", on)


## Mostra/esconde as dicas de controle do canto (tecla H; lembrado nas configurações).
func set_hints_visible(on: bool) -> void:
	if _hint:
		_hint.visible = on


func toggle_hints() -> void:
	var on := not _hint.visible
	set_hints_visible(on)
	Settings.set_value("hud", "show_hints", on)
	show_toast("Dicas de controle %s  (H)" % ("ligadas" if on else "escondidas"), COLOR_DIM)


## Aviso curto no canto inferior direito (ex.: "Jogo salvo").
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
	l.offset_right = -16.0
	l.offset_bottom = -12.0 - 22.0 * stacked
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
	var tag_label := _label("", 11, COLOR_DIM)  # "turno extra" / "irritado" / "FURIOSO"
	top.add_child(tag_label)
	var state_label := _label("", 12, COLOR_DIM)
	top.add_child(state_label)

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
		bar.custom_minimum_size.x = 58  # três barras cabem na largura do painel

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


# ------------------------------------------------------------ atualização
func _refresh() -> void:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.total_stored
	_stored_label.text = str(int(total))
	_refresh_stock()

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
	var text := "Jazidas: %d/%d ativas" % [active, nodes.size() - locked]
	if locked > 0:
		text += " (+%d bloq.)" % locked
	_deposits_label.text = text + "  •  %d restante" % int(ore_left)

	var workers := get_tree().get_nodes_in_group("ipezinhos")
	_refresh_phase()
	_refresh_village(workers)
	_refresh_food(workers)
	_refresh_morale()
	_refresh_panels()
	if _economy:
		_refresh_economy(workers.size())
	# cria/remove linhas se entrar ou sair ipezinho
	for w in workers:
		if not _rows.has(w):
			_rows[w] = _make_row(w)
	for w in _rows.keys():
		if not is_instance_valid(w) or not workers.has(w):
			_rows[w].panel.queue_free()
			_rows.erase(w)

	# a lista cresce até worker_list_max_height e depois rola
	# ...mas nunca além da tela (deixa espaço pras dicas de controle embaixo)
	var room := get_viewport().get_visible_rect().size.y - _rows_scroll.global_position.y - 110.0
	var max_h := clampf(room, 80.0, worker_list_max_height)
	_rows_scroll.custom_minimum_size.y = minf(_rows_box.get_combined_minimum_size().y, max_h)

	var picked: int = _main.selection.size()
	if _overtime_button:
		var all_overtime: bool = picked > 0 and _main.selection.all(func(u): return is_instance_valid(u) and u.overtime)
		_overtime_button.text = "Tirar turno (T)" if all_overtime else "Turno extra (T)"
		_overtime_button.disabled = picked == 0
	if _cook_button:
		var all_cooks: bool = picked > 0 and _main.selection.all(func(u): return is_instance_valid(u) and u.is_cook())
		_cook_button.text = "Tirar cozinha (C)" if all_cooks else "Cozinheiro (C)"
		_cook_button.disabled = picked == 0
	if _lumber_button:
		var all_lumber: bool = picked > 0 and _main.selection.all(func(u): return is_instance_valid(u) and u.is_lumber())
		_lumber_button.text = "Tirar lenhador (L)" if all_lumber else "Lenhador (L)"
		_lumber_button.disabled = picked == 0
	if _guard_button:
		var all_guard: bool = picked > 0 and _main.selection.all(func(u): return is_instance_valid(u) and u.is_guard())
		_guard_button.text = "Tirar guarda (X)" if all_guard else "Guarda (X)"
		_guard_button.disabled = picked == 0
	if _research_button:
		var all_res: bool = picked > 0 and _main.selection.all(func(u): return is_instance_valid(u) and u.is_researcher())
		_research_button.text = "Tirar pesquisa (Z)" if all_res else "Pesquisador (Z)"
		_research_button.disabled = picked == 0
	if _miner_button:
		var all_miners: bool = picked > 0 and _main.selection.all(func(u): return is_instance_valid(u) and u.is_miner())
		_miner_button.text = "Tirar mineração (1)" if all_miners else "Minerador (1)"
		_miner_button.disabled = picked == 0
	if _no_job_button:
		_no_job_button.disabled = picked == 0 or _main.selection.all(func(u): return is_instance_valid(u) and u.has_no_job())
	# Bloco 25: quantos estão sem função (pra notar rápido quem falta designar)
	var no_job := workers.filter(func(w): return w.has_no_job()).size()
	var title := "IPEZINHOS  —  %d selecionados" % picked if picked > 1 else "IPEZINHOS"
	if no_job > 0:
		title += "  •  %d SEM FUNÇÃO" % no_job
	_workers_title.text = title
	_workers_title.add_theme_color_override("font_color",
		COLOR_TITLE if picked > 1 else (COLOR_NO_JOB if no_job > 0 else COLOR_DIM))
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
		# etiqueta de turno extra / zanga (o humor tem prioridade de cor)
		var tags: Array[String] = []
		if w.has_no_job():
			tags.append("SEM FUNÇÃO")
		if w.is_miner():
			tags.append("minerador")
		if w.is_cook():
			tags.append("cozinheiro")
		if w.is_lumber():
			tags.append("lenhador")
		if w.is_guard():
			tags.append("guarda %d%%" % roundi(w.combat_skill * 100.0))
		if w.is_researcher():
			tags.append("pesquisador")
		if w.overtime:
			tags.append("turno extra")
		if w.mood() > 0:
			tags.append(w.mood_label())
		row.tag.text = "  ".join(tags) + ("  " if not tags.is_empty() else "")
		var tag_color: Color = [COLOR_OVERTIME, COLOR_IRRITATED, COLOR_FURIOUS][w.mood()]
		if w.has_no_job():
			tag_color = COLOR_NO_JOB  # mesmo zangado, o que importa aqui é "falta designar"
		elif w.mood() == 0 and w.is_miner():
			tag_color = COLOR_MINER
		elif w.mood() == 0 and w.is_cook():
			tag_color = COLOR_COOK
		elif w.mood() == 0 and w.is_lumber():
			tag_color = COLOR_LUMBER
		elif w.mood() == 0 and w.is_guard():
			tag_color = Color(0.95, 0.55, 0.45)
		row.tag.add_theme_color_override("font_color", tag_color)
		row.panel.add_theme_stylebox_override("panel", _style_row_selected if _main.is_selected(w) else _style_row)


## "ferro 120 • cobre 30 • carvão 0" — só mostra tipos já liberados ou com estoque.
func _refresh_stock() -> void:
	var economy := _economy
	var parts: Array[String] = []
	for t in Ores.TYPES:
		var amount: float = economy.stored_ore(t) if economy else 0.0
		var unlocked: bool = _oficina == null or _oficina.is_ore_unlocked(t)
		if not unlocked and amount <= 0.0:
			continue
		parts.append("[color=#%s]%s %d[/color]" % [Ores.UI_COLORS[t].to_html(false), Ores.display_name(t).to_lower(), int(amount)])
	var wood: float = economy.stored_wood() if economy else 0.0
	parts.append("[color=#%s]madeira %d[/color]" % [COLOR_WOOD.to_html(false), int(wood)])
	if _finds and _finds.rare_parts > 0:
		parts.append("[color=#%s]peças raras %d[/color]" % [COLOR_TITLE.to_html(false), _finds.rare_parts])
	_stock_label.text = "  •  ".join(parts)


## "Comida: 45/120 no comedouro • horta 150 • 1 cozinheiro"
func _refresh_food(workers: Array) -> void:
	var stock := 0.0
	var capacity := 0.0
	for c in get_tree().get_nodes_in_group("comedouros"):
		stock += c.food_stock
		capacity += c.food_capacity
	var garden := 0.0
	for h in get_tree().get_nodes_in_group("coleta_comida"):
		garden += h.food_remaining
	var cooks := workers.filter(func(w): return w.has_method("is_cook") and w.is_cook()).size()
	var text := "Comida: %s no comedouro  •  horta %d  •  " % [
		"ACABOU" if stock <= 0.0 else "%d/%d" % [int(stock), int(capacity)], int(garden)]
	text += "%d cozinheiro%s" % [cooks, "s" if cooks != 1 else ""] if cooks > 0 else "sem cozinheiro"
	_food_label.text = text
	var color := COLOR_DIM
	if stock <= 0.0:
		color = COLOR_HUNGER_BAD
	elif capacity > 0.0 and stock / capacity < 0.25 or cooks == 0:
		color = COLOR_HUNGER_LOW
	_food_label.add_theme_color_override("font_color", color)


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
	_refresh_sun()


## Estação + previsão/alerta das ondas solares, e o tom alaranjado na tela durante a onda.
func _refresh_sun() -> void:
	if _sun == null or _sun_label == null:
		return
	var alert: bool = _sun.wave_active() or (_sun.warned and _sun.time_to_wave() >= 0.0)
	_sun_label.text = "%s  •  %s" % [_sun.season_name(), _sun.forecast_text()]
	_sun_label.add_theme_color_override("font_color", COLOR_HUNGER_BAD if alert else COLOR_DIM)
	if _sun_overlay == null:
		_sun_overlay = ColorRect.new()
		_sun_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sun_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sun_overlay.color = Color(1.0, 0.55, 0.2, 0.0)
		add_child(_sun_overlay)
		move_child(_sun_overlay, 0)  # por baixo dos painéis
	var a := 0.0
	if _sun.wave_active():
		a = 0.22 + 0.06 * sin(Time.get_ticks_msec() * 0.006)
	_sun_overlay.color.a = a


func _refresh_village(workers: Array) -> void:
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
	var text := "Casas: %d/%d camas" % [taken, beds]
	if sleeping > 0:
		text += "  •  %d dormindo" % sleeping
	if homeless > 0:
		text += "  •  %d sem teto" % homeless
	if injured > 0:
		text += "  •  %d machucado%s" % [injured, "s" if injured > 1 else ""]
		if grave > 0:
			text += " (%d grave%s)" % [grave, "s" if grave > 1 else ""]
	_village_label.text = text
	var color := COLOR_DIM
	if injured > 0:
		color = COLOR_INJURED
	elif homeless > 0:
		color = COLOR_HUNGER_LOW
	_village_label.add_theme_color_override("font_color", color)


## "Ânimo: 62 — contentes" / contagem pra greve / "GREVE! expulsão em 4:12"
func _refresh_morale() -> void:
	if _morale == null or _morale_label == null:
		return
	var avg: float = _morale.average()
	if avg < 0.0:
		_morale_label.text = ""
		return
	var text := "Ânimo: %d — %s" % [roundi(avg), _morale.mood_word(avg)]
	var color := _joy_color(avg)
	if _morale.on_strike:
		var left := ceili(_morale.strike_left)
		text = "GREVE! ânimo %d/%d  •  expulsão em %d:%02d" % [roundi(avg), roundi(_morale.strike_end_at), left / 60, left % 60]
		color = COLOR_HUNGER_BAD
	elif _morale.below_time > 0.0:
		var left := ceili(_morale.strike_grace - _morale.below_time)
		text += "  •  greve em %d:%02d!" % [left / 60, left % 60]
		color = COLOR_HUNGER_BAD
	var tav: Node = _morale.taverna()
	if tav and not tav.guests().is_empty():
		text += "  •  %d na taverna" % tav.guests().size()
	_morale_label.text = text
	_morale_label.add_theme_color_override("font_color", color)


func _joy_color(h: float) -> Color:
	if h >= 75.0:
		return COLOR_HUNGER_OK
	if h >= 40.0:
		return Color(0.75, 0.72, 0.55)
	if h >= 25.0:
		return COLOR_HUNGER_LOW
	return COLOR_HUNGER_BAD


func _refresh_panels() -> void:
	for id in _panels:
		var panel: PanelContainer = _panels[id]
		var button: Button = _panel_buttons[id]
		if panel.has_method("is_available"):
			button.visible = panel.is_available()  # ex.: robô só depois de achado
		button.text = panel.button_text()
		button.tooltip_text = button.text  # a grade corta textos longos
		# destaca o botão quando dá pra comprar/fabricar alguma coisa
		button.add_theme_color_override("font_color", COLOR_TITLE if panel.has_available_action() else COLOR_TEXT)
		panel.refresh()


func _refresh_economy(worker_count: int) -> void:
	var credits: float = _economy.credits
	_credits_label.text = str(int(credits))
	if _last_credits >= 0.0 and not is_equal_approx(credits, _last_credits):
		_credits_label.modulate = Color(1.6, 1.6, 1.6) if credits > _last_credits else Color(1.5, 0.6, 0.6)
		create_tween().tween_property(_credits_label, "modulate", Color.WHITE, 0.5)
	_last_credits = credits

	var value: int = _economy.sale_value()
	_sell_button.text = "Vender minério  (+%d cr)" % value
	_sell_button.disabled = value <= 0

	var cost: int = _economy.recruit_cost()
	var at_max: bool = worker_count >= _economy.max_workers
	_recruit_button.text = "Limite de ipezinhos atingido" if at_max else "Recrutar ipezinho  (%d cr)" % cost
	_recruit_button.disabled = not _economy.can_recruit()
	_workers_count_label.text = "%d / %d" % [worker_count, _economy.max_workers]
	if _auto_sell_check.button_pressed != _economy.auto_sell:
		_auto_sell_check.set_pressed_no_signal(_economy.auto_sell)


# ------------------------------------------------------------ helpers de estilo
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
