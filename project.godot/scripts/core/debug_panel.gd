extends CanvasLayer
## Bloco 52: PAINEL DE DEBUG pro balanceamento (F3). Só existe em build de editor/debug
## (OS.is_debug_build()): no executável de release nem é criado.
##   tempo x1/x4/x16 · +créditos/minério/madeira/comida · pular fase/dia/estação ·
##   disparar invasão · curar todos · liberar todas as pesquisas
##   Bloco 79: abrir todos os andares (sem esperar a escavadeira e os consertos) e levar a câmera a cada um
##   (superfície, S2..S5, o cavalete da ferrovia) — pra ver os marcos e testar a ferrovia de carga já no dia 1
## Nada aqui é salvo de um jeito especial: mexe nos mesmos números que o jogo usa.

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _main: Node
var _painel: PanelContainer
var _info: Label


func setup(main: Node) -> void:
	_main = main
	name = "DebugPanel"
	UiSkin.tema_na_camada(self)  # Bloco 95: o tema (escala e fonte) chega nos Controls da camada
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_painel = PanelContainer.new()
	_painel.add_theme_stylebox_override("panel", UiSkin.painel(6) if UiSkin.ok() else StyleBoxFlat.new())
	_painel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_painel.offset_left = 330.0
	_painel.visible = false
	add_child(_painel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_painel.add_child(v)
	var t := Label.new()
	t.text = "DEBUG (F3)"
	t.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	v.add_child(t)
	_linha(v, "Tempo:", [["x1", func(): _tempo(1.0)], ["x4", func(): _tempo(4.0)], ["x16", func(): _tempo(16.0)]])
	_linha(v, "Dar:", [["+1000 cr", _creditos], ["+200 minério", _minerio], ["+200 madeira", _madeira], ["+100 comida", _comida]])
	_linha(v, "Pular:", [["fase", _fase], ["dia", _dia], ["estação", _estacao]])
	_linha(v, "Eventos:", [["invasão agora", _invasao], ["chuva liga/desliga", _chuva], ["curar todos", _curar], ["liberar pesquisas", _pesquisas]])
	_linha(v, "Andares:", [["abrir todos", _abre_andares]])
	_linha(v, "Criaturas:", [["invasão com todos os tipos", _todas_criaturas]])  # Bloco 91
	_linha(v, "Ir para:", [["vila", func(): _vai(Vector2(40, -260))], ["S2", func(): _vai(Vector2(-300, 3730))],
		["S3", func(): _vai(Vector2(-460, 4110))], ["S4", func(): _vai(Vector2(-340, 4530))], ["S5", func(): _vai(Vector2(-460, 4920))],
		["ferrovia", _vai_ferrovia]])
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_info.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	v.add_child(_info)


func _linha(v: VBoxContainer, rotulo: String, botoes: Array) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	v.add_child(h)
	var l := Label.new()
	l.text = rotulo
	l.custom_minimum_size.x = 64
	l.add_theme_font_size_override("font_size", Tipo.DETALHE)
	h.add_child(l)
	for b in botoes:
		var bt := Button.new()
		bt.text = b[0]
		bt.focus_mode = Control.FOCUS_NONE
		bt.add_theme_font_size_override("font_size", Tipo.DETALHE)
		if UiSkin.ok():
			UiSkin.aplica_botao(bt)
		var f: Callable = b[1]
		bt.pressed.connect(func():
			f.call()
			_atualiza())
		h.add_child(bt)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F3:
		_painel.visible = not _painel.visible
		_atualiza()
		get_viewport().set_input_as_handled()


func _atualiza() -> void:
	var dn := _g("day_night")
	var eco := _g("economy")
	_info.text = "dia %s  •  tempo x%.0f  •  %d cr" % [str(dn.day) if dn else "?", Engine.time_scale, int(eco.credits) if eco else 0]


func _g(grupo: String) -> Node:
	return get_tree().get_first_node_in_group(grupo)


func _tempo(v: float) -> void:
	var hud := _g("hud")
	if hud and hud.has_method("set_speed"):
		hud.set_speed(v)
	else:
		Engine.time_scale = v


func _creditos() -> void:
	var eco := _g("economy")
	if eco:
		eco.credits += 1000
		eco.credits_changed.emit(eco.credits)


func _minerio() -> void:
	var arm := _g("armazens")
	if arm:
		for ore in arm.stock.keys():
			arm.add_ore(200.0, ore)


func _madeira() -> void:
	var arm := _g("armazens")
	if arm:
		arm.wood_stored += 200.0


func _comida() -> void:
	var c := _g("comedouros")
	if c and c.get("food_stock") != null:
		c.food_stock = minf(c.food_stock + 100.0, maxf(float(c.get("food_capacity")), c.food_stock + 100.0))


func _fase() -> void:
	var dn := _g("day_night")
	if dn and dn.has_method("skip_phase"):
		dn.skip_phase()


func _dia() -> void:
	var dn := _g("day_night")
	if dn == null:
		return
	var d0: int = dn.day
	for i in 4:  # dia -> noite -> dia seguinte
		if dn.day != d0:
			break
		dn.skip_phase()


func _estacao() -> void:
	var sun := _g("sun")
	var n: int = sun.days_per_season if sun else 4
	for i in n:
		_dia()


func _invasao() -> void:
	var d := _g("defense")
	if d and d.has_method("start_invasion") and not d.invasion_active:
		d.start_invasion()


func _chuva() -> void:
	var w := _g("weather")
	if w and w.get("forcar_chuva") != null:
		w.forcar_chuva = not w.forcar_chuva


func _curar() -> void:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.get("downed"):
			w.downed = false
		if w.get("injured") and w.has_method("_heal"):
			w._heal()


## Bloco 79: abre o S2 (como a escavadeira pronta) e as plataformas do S3, S4 e S5 (como o conserto pronto).
## Bloco 91: uma invasão com UMA DE CADA criatura (Lumívoro, Matriarca, Gosma, Magmante, Ferrugento) — pra ver a
## arte do PixelLab de todas sem esperar o S2/S3 nem a estação do chefe. De noite, na hora.
func _todas_criaturas() -> void:
	var d := _g("defense")
	var dn := _g("day_night")
	if d == null:
		return
	if dn and not dn.is_night():
		dn.ir_para_hora(22.0)
	if not d.invasion_active:
		d.start_invasion()
	for k in ["gosma", "magmante", "ferrugento"]:
		d._spawn(k)
	if not d.boss_alive():
		d._spawn_boss()


func _abre_andares() -> void:
	var sh := _g("elevador")
	if sh and sh.has_method("unlock"):
		sh.unlock(false)
	if sh and sh.has_method("restaura_tudo"):
		sh.restaura_tudo()  # Bloco 99: o elevador restaurado (a cabine anda)
	for e in _main.get_tree().get_nodes_in_group("elevadores"):
		if e.get("unlocked") == false and e.has_method("_apply"):
			e.repairing = false
			e.unlocked = true
			e._apply(false)
			if e.has_signal("opened"):
				e.opened.emit()
	var hud := _g("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Debug: todos os andares abertos.", Color(1.0, 0.6, 0.4))


func _vai(p: Vector2) -> void:
	var cam = _main.get_node_or_null("Camera2D")
	if cam and cam.has_method("focus_on"):
		cam.focus_on(p)


func _vai_ferrovia() -> void:
	var iso = _g("iso_view")
	var cam = _main.get_node_or_null("Camera2D")
	if iso == null or cam == null or not iso.has_method("ferrovia_postes"):
		return
	var px: Vector2 = iso.ferrovia_postes()
	var z := maxf(float(cam.get("iso_zoom_min")) if cam.get("iso_zoom_min") != null else 0.5, 0.5)
	cam.zoom = Vector2(z, z)
	cam.set("_target_zoom", z)
	cam.position = Vector2(px.x - 60, 1800)
	cam._target_pos = cam.position


func _pesquisas() -> void:
	var r := _g("research")
	if r == null:
		return
	for id in r.ORDER:
		if not r.has(id) and r.has_method("_finish"):
			r._finish(id)
