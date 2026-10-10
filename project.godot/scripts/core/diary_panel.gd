extends PanelContainer
## Janela do Diário (tecla J): páginas descobertas + memorial de quem morreu.
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _diary: Node
var _box: VBoxContainer
var _shown := -1


func setup(hud: CanvasLayer, diary: Node, _economy: Node) -> void:
	_hud = hud
	_diary = diary
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(500, 0)
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
	var title: Label = _hud._label("DIÁRIO DA VILA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_box)


func refresh() -> void:
	if not visible:
		return
	var inf := get_tree().get_first_node_in_group("enfermarias")
	var dead: int = inf.memorial.size() if inf else 0
	var sig: int = _diary.pages.size() * 1000 + dead
	if sig == _shown:
		return  # só remonta quando muda
	_shown = sig
	for c in _box.get_children():
		c.queue_free()
	if _diary.pages.is_empty():
		_box.add_child(_hud._label("Nada escrito ainda. As páginas aparecem conforme a vila descobre o mundo lá fora.", Tipo.DETALHE, _hud.COLOR_DIM))
	for p in _diary.pages:
		var e: Dictionary = _diary.entrada(p.id)
		if e.is_empty():
			continue  # (página de missão sem o texto registrado ainda)
		_box.add_child(_hud._label("%s   (dia %d)" % [e.title, p.day], Tipo.TITULO, _hud.COLOR_TITLE))
		var t: Label = _hud._label(e.text, Tipo.DETALHE, _hud.COLOR_TEXT)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size.x = 460
		_box.add_child(t)
	if dead > 0:
		_box.add_child(HSeparator.new())
		_box.add_child(_hud._label("MEMORIAL", Tipo.CORPO, _hud.COLOR_DIM))
		for m in inf.memorial:
			var fam_txt := str(m.get("familia", ""))  # Bloco 111
			_box.add_child(_hud._label("† %s — dia %d%s" % [str(m.get("name", "?")), int(m.get("day", 1)), (" (%s)" % fam_txt) if fam_txt != "" else ""], Tipo.DETALHE, _hud.COLOR_DIM))


func button_text() -> String:
	return "Diário %d (J)" % _diary.pages.size()


func has_available_action() -> bool:
	return false
