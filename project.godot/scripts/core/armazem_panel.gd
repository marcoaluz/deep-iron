extends PanelContainer
## Janela do Armazém (Bloco 39): quanto tem de cada minério, quanto vale e vender (tudo
## ou um tipo só). Madeira e matéria-prima aparecem mas não se vendem. Abre clicando no
## armazém ou pelo botão no painel do HUD. Os preços vêm do nó Economy (Inspector).

const Ores := preload("res://scripts/core/ores.gd")

var _hud: CanvasLayer
var _arm: Node
var _economy: Node
var _credits_label: Label
var _rows: Dictionary = {}  # tipo -> {label, button}
var _sell_all: Button
var _other_label: Label


func setup(hud: CanvasLayer, arm: Node, economy: Node) -> void:
	_hud = hud
	_arm = arm
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(420, 0)
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
	var intro: Label = _hud._label("Minério vendido vira créditos (preço fixo por tipo). Créditos recrutam ipezinhos e pagam as obras.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	_credits_label = _hud._label("", 15, _hud.COLOR_TEXT)
	vbox.add_child(_credits_label)
	vbox.add_child(HSeparator.new())
	for t in Ores.TYPES:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var l: Label = _hud._label("", 13, Ores.UI_COLORS.get(t, _hud.COLOR_TEXT))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b: Button = _hud._button("Vender")
		b.custom_minimum_size.x = 120
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func():
			Audio.click()
			_economy.sell(t)
			refresh())
		row.add_child(b)
		_rows[t] = {"label": l, "button": b}
	_sell_all = _hud._button("")
	_sell_all.pressed.connect(func():
		Audio.click()
		_economy.sell_all()
		refresh())
	vbox.add_child(_sell_all)
	vbox.add_child(HSeparator.new())
	_other_label = _hud._label("", 12, _hud.COLOR_DIM)
	_other_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_other_label)


func refresh() -> void:
	if not visible or _economy == null:
		return
	_credits_label.text = "Créditos: %d" % int(_economy.credits)
	var oficina := get_tree().get_first_node_in_group("oficina")
	for t in _rows:
		var amount: float = _economy.stored_ore(t)
		var unlocked: bool = oficina == null or oficina.is_ore_unlocked(t)
		var row: Dictionary = _rows[t]
		row.label.get_parent().visible = unlocked or amount >= 1.0
		var price: float = _economy.price_of(t)
		row.label.text = "%s: %d  ×  %s cr  =  %d cr" % [Ores.display_name(t), int(amount), str(snappedf(price, 0.1)), int(floorf(amount) * price)]
		row.button.disabled = amount < 1.0
	var total: int = _economy.sale_value()
	_sell_all.text = "Vender tudo  (+%d cr)" % total if total > 0 else "Nada pra vender"
	_sell_all.disabled = total <= 0
	var raw := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		raw += a.get("raw_stored") if a.get("raw_stored") != null else 0.0
	_other_label.text = "Não se vende: madeira %d (obras) e matéria-prima %d (o cozinheiro prepara)." % [int(_economy.stored_wood()), int(raw)]


func button_text() -> String:
	return "Armazém: %d cr à venda" % _economy.sale_value()


func has_available_action() -> bool:
	return false
