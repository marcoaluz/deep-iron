extends PanelContainer
## Bloco 77: janela TRABALHADORES — as áreas de trabalho e quantos trabalham em cada uma (o esquema do
## Frostpunk). Botão na coluna do HUD, tecla 5, clique numa área no mapa, ou abre sozinha ao marcar área.
##
##   Disponíveis: N (sem função)
##   [+ Madeira] [+ Alimentos] [+ Mina]      -> marca a área no mapa (area_placer.gd)
##   Madeira 1 — Corte de árvores   [Ver] [Apagar]
##   [ - ]  3 / 5  [ + ]   Status / Produção
##   (mina) [Ligar o carrinho] / [Desligar]
##
## Os botões respeitam os limites sozinhos (− no zero, + na área cheia ou sem ninguém disponível). A
## lógica é toda do work_areas.gd; aqui é só mostrar e chamar.

var _hud: CanvasLayer
var _disp: Label
var _lista: VBoxContainer
var _vazio: Label
var _cards := {}  # id da área -> {box, titulo, conta, menos, mais, status, ativar, carrinho}
var _ids: Array = []
var _sel = null  # a área destacada (no mapa também)


func setup(hud: CanvasLayer, _target: Node, _economy: Node) -> void:
	_hud = hud
	_build()
	visible = false


func _wa() -> Node:
	return get_tree().get_first_node_in_group("work_areas") if is_inside_tree() else null


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(470, 0)
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
	var title: Label = _hud._label("TRABALHADORES", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.tooltip_text = "Fechar (Esc / 5)"
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_disp = _hud._label("", 16, _hud.COLOR_TEXT)
	vbox.add_child(_disp)
	var intro: Label = _hud._label("Marque no mapa onde trabalhar e diga quantos vão pra lá (até 5 por área). Quem vai sai dos disponíveis (sem função) e só trabalha dentro da área; tirando, volta a ficar disponível.", 12, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	var novas := HBoxContainer.new()
	novas.add_theme_constant_override("separation", 6)
	vbox.add_child(novas)
	for tipo in ["madeira", "comida", "mina"]:
		var b: Button = _hud._button("+ Área de %s" % _info(tipo).get("curto", tipo).to_lower())
		b.tooltip_text = "Marcar no mapa uma área de %s (arraste com o botão esquerdo)" % str(_info(tipo).get("nome", tipo)).to_lower()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t: String = tipo
		b.pressed.connect(func():
			Audio.click()
			var placer := get_tree().get_first_node_in_group("area_placer")
			if placer:
				placer.begin(t))
		novas.add_child(b)
	vbox.add_child(HSeparator.new())
	_vazio = _hud._label("Nenhuma área marcada ainda. Sem área, quem tem função (teclas 1, 2, L...) trabalha onde achar, como sempre.", 12, _hud.COLOR_DIM)
	_vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_vazio)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 8)
	vbox.add_child(_lista)


func _info(tipo: String) -> Dictionary:
	var wa := _wa()
	return wa.TIPOS.get(tipo, {}) if wa else preload("res://scripts/core/work_areas.gd").TIPOS.get(tipo, {})


## Abriu clicando numa área no mapa / acabou de marcar uma: ela fica destacada.
func focus_area(a) -> void:
	_sel = a
	refresh()


func selected_area():
	var wa := _wa()
	if _sel != null and wa and wa.areas.has(_sel):
		return _sel
	return null


func _card(a) -> Dictionary:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var top := HBoxContainer.new()
	box.add_child(top)
	var titulo: Label = _hud._label("", 15, _hud.COLOR_TITLE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(titulo)
	var ver: Button = _hud._button("Ver")
	ver.tooltip_text = "Mostrar a área no mapa"
	ver.pressed.connect(func():
		Audio.click()
		_sel = a
		var cam := get_tree().get_first_node_in_group("camera")
		if cam == null:
			var main := get_tree().get_first_node_in_group("game_main")
			cam = main.get_node_or_null("Camera2D") if main else null
		if cam and cam.has_method("focus_on"):
			cam.focus_on(a.centro())
		refresh())
	top.add_child(ver)
	var apagar: Button = _hud._button("Apagar")
	apagar.tooltip_text = "Desfazer a área (os trabalhadores voltam a ficar disponíveis)"
	apagar.pressed.connect(func():
		Audio.click()
		var wa := _wa()
		if wa:
			wa.apagar(a)
		refresh())
	top.add_child(apagar)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	box.add_child(linha)
	var menos: Button = _hud._button("  -  ")
	menos.pressed.connect(func():
		var wa := _wa()
		var why: String = wa.remover(a) if wa else "?"
		if why == "":
			Audio.click()
		else:
			Audio.error()
		refresh())
	linha.add_child(menos)
	var conta: Label = _hud._label("", 18, _hud.COLOR_TEXT)
	conta.custom_minimum_size.x = 70
	conta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	linha.add_child(conta)
	var mais: Button = _hud._button("  +  ")
	mais.pressed.connect(func():
		var wa := _wa()
		var why: String = wa.adicionar(a) if wa else "?"
		if why == "":
			Audio.click()
		else:
			Audio.error()
			if _hud.has_method("show_toast"):
				_hud.show_toast(why.left(1).to_upper() + why.substr(1), Color(1.0, 0.6, 0.45))
		refresh())
	linha.add_child(mais)
	var quem: Label = _hud._label("", 12, _hud.COLOR_DIM)
	quem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(quem)
	var status: Label = _hud._label("", 13, _hud.COLOR_TEXT)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)
	var ativar: Button = _hud._button("")
	ativar.pressed.connect(func():
		Audio.click()
		var wa := _wa()
		if wa:
			wa.ativar(a, not a.ativa)
		refresh())
	box.add_child(ativar)
	box.add_child(HSeparator.new())
	return {"box": box, "titulo": titulo, "conta": conta, "menos": menos, "mais": mais, "quem": quem,
		"status": status, "ativar": ativar}


func refresh() -> void:
	var wa := _wa()
	if wa == null:
		return
	var livres: int = wa.disponiveis().size()
	_disp.text = "Disponíveis: %d   (de %d ipezinhos; disponível = sem função)" % [livres, wa.total_trabalhadores()]
	if not visible:
		return
	var ids: Array = wa.areas.map(func(a): return a.id)
	if ids != _ids:  # área nova ou apagada: refaz os cartões
		for c in _cards.values():
			c.box.queue_free()
		_cards.clear()
		for a in wa.areas:
			var c := _card(a)
			_lista.add_child(c.box)
			_cards[a.id] = c
		_ids = ids
	_vazio.visible = wa.areas.is_empty()
	var sel = selected_area()
	for a in wa.areas:
		var c: Dictionary = _cards[a.id]
		var info: Dictionary = a.info()
		var n: int = a.quantos()
		c.titulo.text = "%s%s — %s" % ["▶ " if a == sel else "", a.nome(), info.nome]
		c.titulo.add_theme_color_override("font_color", info.cor if a == sel or sel == null else _hud.COLOR_DIM)
		c.conta.text = "%d / %d" % [n, a.capacidade]
		c.quem.text = info.quem
		c.menos.disabled = n == 0
		c.mais.disabled = a.cheia() or livres == 0
		c.mais.tooltip_text = "área cheia" if a.cheia() else ("nenhum trabalhador disponível" if livres == 0 else "mandar mais um")
		var est: String = wa.estado(a)
		var prod: float = a.producao_min()
		c.status.text = "Status: %s   •   Produção: %.1f %s/min   (total: %d)" % [est, prod, info.unidade, int(a.total)]
		c.status.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6) if wa.funcionando(a) else Color(1.0, 0.75, 0.5))
		c.ativar.visible = a.precisa_ativar()
		if a.precisa_ativar():
			var nc: int = wa.carrinhos(a).size()
			var cart := ("o carrinho (%d ponto%s de carga)" % [nc, "s" if nc > 1 else ""]) if nc > 0 else "a mina (sem carrinho nesta área)"
			c.ativar.text = ("Desligar %s" % cart) if a.ativa else ("Ligar %s — precisa de pelo menos 1 mineiro" % cart)


func button_text() -> String:
	var wa := _wa()
	if wa == null:
		return "Trabalhadores"
	return "Trabalhadores: %d disponíve%s" % [wa.disponiveis().size(), "l" if wa.disponiveis().size() == 1 else "is"]


func has_available_action() -> bool:
	var wa := _wa()
	if wa == null:
		return false
	return not wa.disponiveis().is_empty() and wa.areas.any(func(a): return not a.cheia())
