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
const STATE_COLORS := {
	"idle": Color(0.65, 0.6, 0.55),
	"eating": Color(0.5, 0.85, 0.4),
	"mining": Color(0.95, 0.6, 0.3),
	"storing": Color(0.45, 0.7, 1.0),
	"manual": Color(1.0, 0.84, 0.25),
}

@export var ore_icon: Texture2D
## Atualizações do HUD por segundo.
@export var refresh_rate: float = 10.0

var _main: Node
var _stored_label: Label
var _deposits_label: Label
var _rows_box: VBoxContainer
var _rows: Dictionary = {}  # ipezinho -> {panel, name, state, hunger, cargo}
var _refresh_timer := 0.0
var _style_row := _row_style(false)
var _style_row_selected := _row_style(true)


func _ready() -> void:
	_main = get_parent()
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

	vbox.add_child(HSeparator.new())
	vbox.add_child(_label("IPEZINHOS", 12, COLOR_DIM))

	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_rows_box)

	# dica de controles no canto inferior esquerdo
	var hint := _label(
		"Clique: selecionar / mover   •   Botão dir. / Esc: soltar   •   Tab: próximo   •   F: seguir\n"
		+ "Roda: zoom   •   Botão do meio / WASD / setas: mover câmera   •   Home: centralizar",
		12, Color(0.85, 0.8, 0.72, 0.75))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_left = 14.0
	hint.offset_bottom = -10.0
	hint.offset_top = -10.0
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
	add_child(hint)


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
	# cria/remove linhas se entrar ou sair ipezinho
	for w in workers:
		if not _rows.has(w):
			_rows[w] = _make_row(w)
	for w in _rows.keys():
		if not is_instance_valid(w) or not workers.has(w):
			_rows[w].panel.queue_free()
			_rows.erase(w)

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


# ------------------------------------------------------------ helpers de estilo
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
