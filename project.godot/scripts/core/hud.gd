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
const STATE_COLORS := {
	"idle": Color(0.65, 0.6, 0.55),
	"eating": Color(0.5, 0.85, 0.4),
	"mining": Color(0.95, 0.6, 0.3),
	"storing": Color(0.45, 0.7, 1.0),
	"manual": Color(1.0, 0.84, 0.25),
	"home": Color(0.55, 0.62, 1.0),
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
var _stored_label: Label
var _deposits_label: Label
var _credits_label: Label
var _sell_button: Button
var _auto_sell_check: CheckBox
var _recruit_button: Button
var _workers_count_label: Label
var _rows_scroll: ScrollContainer
var _rows_box: VBoxContainer
var _last_credits: float = -1.0
var _rows: Dictionary = {}  # ipezinho -> {panel, name, state, hunger, cargo}
var _refresh_timer := 0.0
var _style_row := _row_style(false)
var _style_row_selected := _row_style(true)


func _ready() -> void:
	_main = get_parent()
	_economy = get_tree().get_first_node_in_group("economy")
	_day_night = get_tree().get_first_node_in_group("day_night")
	_build()
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

	var title := _label("DEEP IRON", 20, COLOR_TITLE)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)

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

	_deposits_label = _label("", 13, COLOR_DIM)
	vbox.add_child(_deposits_label)
	_village_label = _label("", 13, COLOR_DIM)
	vbox.add_child(_village_label)

	if _economy:
		_build_economy(vbox)

	vbox.add_child(HSeparator.new())
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var workers_title := _label("IPEZINHOS", 12, COLOR_DIM)
	workers_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(workers_title)
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
		"Clique: selecionar / mover   •   Botão dir. / Esc: soltar   •   Tab: próximo   •   F: seguir\n"
		+ "Roda: zoom   •   Botão do meio / WASD / setas: mover câmera   •   Home: centralizar\n"
		+ "V: vender minério   •   R: recrutar   •   M: liga/desliga música   •   N: pular pra próxima fase (teste)",
		12, Color(0.85, 0.8, 0.72, 0.75))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_left = 14.0
	hint.offset_bottom = -10.0
	hint.offset_top = -10.0
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
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
	var name_label := _label(worker.name, 14, COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
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

	return {"panel": row_panel, "state": state_label, "hunger": hunger_bar, "cargo": cargo_bar}


func _on_row_input(event: InputEvent, worker: Node2D) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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

	var ore_left := 0.0
	var active := 0
	var nodes := get_tree().get_nodes_in_group("minerios")
	for m in nodes:
		ore_left += m.ore_remaining
		if m.is_usable():
			active += 1
	_deposits_label.text = "Jazidas: %d/%d ativas  •  %d de minério restante" % [active, nodes.size(), int(ore_left)]

	var workers := get_tree().get_nodes_in_group("ipezinhos")
	_refresh_phase()
	_refresh_village(workers)
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
	_rows_scroll.custom_minimum_size.y = minf(_rows_box.get_combined_minimum_size().y, worker_list_max_height)

	var selected = _main.get("selected")
	for w in workers:
		var row: Dictionary = _rows[w]
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
		var state: String = w.get_state()
		row.state.text = w.get_state_label() if w.hunger > 0.0 else "FAMINTO!"
		row.state.add_theme_color_override("font_color",
			STATE_COLORS.get(state, COLOR_DIM) if w.hunger > 0.0 else COLOR_HUNGER_BAD)
		row.panel.add_theme_stylebox_override("panel", _style_row_selected if w == selected else _style_row)


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


func _refresh_village(workers: Array) -> void:
	var beds := 0
	var taken := 0
	var sleeping := 0
	for casa in get_tree().get_nodes_in_group("casas"):
		beds += casa.beds_total()
		taken += casa.beds_taken()
		sleeping += casa.sleeping_count()
	var homeless := 0
	for w in workers:
		if w.has_method("has_home") and not w.has_home():
			homeless += 1
	var text := "Casas: %d/%d camas" % [taken, beds]
	if sleeping > 0:
		text += "  •  %d dormindo" % sleeping
	if homeless > 0:
		text += "  •  %d sem teto" % homeless
	_village_label.text = text
	_village_label.add_theme_color_override("font_color", COLOR_HUNGER_LOW if homeless > 0 else COLOR_DIM)


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
