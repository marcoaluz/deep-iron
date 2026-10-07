extends PanelContainer
## Bloco 88: janela do CALENDÁRIO — hoje, os próximos eventos (missa, funerais, domingo à tarde, o festival da
## estação), o padre e a igreja, e a ESCOLHA do domingo à tarde (Festival / Dia livre / Trabalhar). Abre
## sozinha no domingo ao meio-dia, clicando na igreja ou pelo botão da coluna do HUD.
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _cal: Node
var _economy: Node
var _hoje: Label
var _eventos: Label
var _padre: Label
var _igreja_button: Button
var _escolha_info: Label
var _botoes: Dictionary = {}  # opção -> Button


func setup(hud: CanvasLayer, cal: Node, economy: Node) -> void:
	_hud = hud
	_cal = cal
	_economy = economy
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(460, 0)
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
	var title: Label = _hud._label("CALENDÁRIO", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_hoje = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	vbox.add_child(_hoje)
	vbox.add_child(_hud._label("PRÓXIMOS EVENTOS", Tipo.TITULO, _hud.COLOR_TITLE))
	_eventos = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_eventos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_eventos)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("DOMINGO À TARDE", Tipo.TITULO, _hud.COLOR_TITLE))
	_escolha_info = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_escolha_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_escolha_info)
	for op in ["festival", "livre", "trabalhar"]:
		var b: Button = _hud._button("")
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.pressed.connect(func():
			_cal.escolher(op)
			refresh())
		vbox.add_child(b)
		_botoes[op] = b
	vbox.add_child(HSeparator.new())
	_padre = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_padre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_padre)
	_igreja_button = _hud._button("")
	_igreja_button.pressed.connect(func():
		Audio.click()
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub:
			hub.build_igreja()
		refresh())
	vbox.add_child(_igreja_button)


func refresh() -> void:
	if not visible or _cal == null:
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	var sun := get_tree().get_first_node_in_group("sun")
	if dn == null:
		return
	_hoje.text = "Hoje: %s, dia %d (semana %d) — %s" % [dn.nome_dia(), dn.day, dn.semana(), sun.season_name() if sun else ""]
	var linhas: Array[String] = []
	for e in _cal.proximos(6):
		linhas.append("•  " + _cal.texto_evento(e))
	_eventos.text = "\n".join(linhas) if not linhas.is_empty() else "Nada marcado."
	var hoje_esc: String = _cal.escolha_hoje()
	var festival: String = _cal.nome_festival_hoje()
	if dn.e_domingo():
		_escolha_info.text = ("Escolhido hoje: %s." % _cal.NOMES_ESCOLHA.get(hoje_esc, hoje_esc)) if hoje_esc != "" \
			else "Hoje é domingo! Escolha a tarde (%s–%s). Sem escolha: dia livre." % [dn.hora_texto(_cal.tarde_inicio), dn.hora_texto(dn.hora_fim_expediente)]
	else:
		_escolha_info.text = "No domingo (dia %d) você escolhe a tarde. O último domingo de cada estação é dia de festa: %s." % [
			dn.day + (7 - dn.dia_semana()), _cal.nome_festival(dn.day + (7 - dn.dia_semana()))]
	var mor := get_tree().get_first_node_in_group("morale")
	var textos := {
		"festival": "%s  (%d cr + %d comida): grande ânimo, todos na praça" % [festival, mor.festa_credits if mor else 0, roundi(mor.festa_food) if mor else 0],
		"livre": "Dia livre: passeiam e conversam pela vila",
		"trabalhar": "Trabalhar: hora extra (+%d de zanga em todos)" % roundi(_cal.domingo_trabalho_zanga),
	}
	for op in _botoes:
		var motivo: String = _cal.motivo_escolha(op)
		_botoes[op].text = textos[op] if motivo == "" else "%s — %s" % [textos[op].split(":")[0].split("  (")[0], motivo]
		_botoes[op].disabled = motivo != ""
	var pd: Node = _cal.padre()
	var ig: Node = _cal.igreja()
	var hub := get_tree().get_first_node_in_group("village_hub")
	if pd != null:
		_padre.text = "%s: %s.%s" % [pd.display_name, pd.get_state_label(), "" if ig else " Sem igreja: sem missa nem funeral."]
	else:
		_padre.text = "O padre chega quando a vila for %s." % (hub.STAGE_NAMES[clampi(_cal.padre_estagio, 1, 5) - 1] if hub else "maior")
	var reason: String = hub.igreja_block_reason() if hub else "sem Centro da Vila"
	_igreja_button.visible = ig == null
	_igreja_button.text = ("Construir a Igreja — escolher lugar  (%s)" % hub.igreja_cost_text()) if reason == "" else "Igreja: " + reason
	_igreja_button.disabled = reason != ""


func button_text() -> String:
	return "Calendário: %s" % _cal.proximo_texto()


func has_available_action() -> bool:
	var dn := get_tree().get_first_node_in_group("day_night")
	return dn != null and dn.e_domingo() and _cal.escolha_hoje() == "" and _cal.motivo_escolha("livre") == ""
