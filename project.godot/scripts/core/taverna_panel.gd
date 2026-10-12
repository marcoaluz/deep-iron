extends PanelContainer
## Bloco 128: a janela da TAVERNA (clique nela). Só o que ela faz: os FREQUENTADORES (quem está lá dentro e o ânimo de cada
## um), os lugares, o ritmo de diversão e o que ela dá de ânimo à vila toda. Antes a taverna abria a janela de Bem-estar.
## "Melhorias": ampliar (a mesma ação do cartão "Ampliar taverna" do CONSTRUIR). Construir outra taverna é no CONSTRUIR.
## Interface das janelas do HUD: setup(hud, alvo, economia), refresh(), focus(no), button_text(), has_available_action().
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _morale: Node
var _focus: Node = null
var _title: Label
var _resumo: Label
var _bonus: Label
var _lista: VBoxContainer
var _melhorias: Label
var _ampliar: Button


func setup(hud: CanvasLayer, morale: Node, _economy: Node) -> void:
	_hud = hud
	_morale = morale
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
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	_title = _hud._label("TAVERNA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var info: Label = _hud._label("Quem está triste vai lá se animar: entra, ganha ânimo por segundo e sai quando se anima. "
		+ "Ter taverna na vila anima um pouco todo mundo.", Tipo.DETALHE, _hud.COLOR_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)
	_resumo = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_resumo)
	_bonus = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_bonus)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("FREQUENTADORES", Tipo.DETALHE, _hud.COLOR_DIM))
	_lista = VBoxContainer.new()
	_lista.name = "Frequentadores"
	_lista.add_theme_constant_override("separation", 2)
	vbox.add_child(_lista)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("MELHORIAS", Tipo.DETALHE, _hud.COLOR_DIM))
	_melhorias = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_melhorias.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_melhorias)
	_ampliar = _hud._button("")
	_ampliar.pressed.connect(func():
		Audio.click()
		_morale.upgrade_taverna()
		refresh())
	vbox.add_child(_ampliar)


## O HUD avisa qual taverna foi clicada (null = abriu pelo menu: a primeira).
func focus(node: Node) -> void:
	_focus = node if node != null and node.is_in_group("tavernas") else null


func _atual() -> Node:
	if _focus != null and is_instance_valid(_focus) and _focus.is_inside_tree():
		return _focus
	return _morale.taverna()


func refresh() -> void:
	if not visible or _morale == null:
		return
	var tavs: Array = _morale.tavernas()
	var tav: Node = _atual()
	_title.text = "TAVERNA" if tavs.size() <= 1 or tav == null else "TAVERNA %d de %d" % [tavs.find(tav) + 1, tavs.size()]
	for c in _lista.get_children():
		_lista.remove_child(c)
		c.queue_free()
	if tav == null:
		_resumo.text = "Sem taverna. Construa em CONSTRUIR > Lazer."
		_bonus.text = ""
		_melhorias.text = ""
		_ampliar.visible = false
		return
	var hospedes: Array = tav.guests()
	_resumo.text = "Nível %d  •  %d de %d lugares ocupados  •  diversão %.1f por segundo lá dentro" % [
		tav.level, hospedes.size(), tav.slot_count, tav.fun_rate()]
	var avg: float = _morale.average()
	_bonus.text = "Ânimo da vila: %s  •  só ter taverna dá +%d a todos (o bônus não soma entre tavernas: vale o da melhor)." % [
		"—" if avg < 0.0 else str(roundi(avg)),
		roundi(_morale.taverna_bonus[clampi(tav.level, 1, _morale.taverna_bonus.size()) - 1])]
	if hospedes.is_empty():
		_lista.add_child(_hud._label("Ninguém lá dentro agora.", Tipo.DETALHE, _hud.COLOR_DIM))
	for w in hospedes:
		var l: Label = _hud._label("%s — ânimo %d" % [String(w.display_name), roundi(w.happiness)], Tipo.CORPO, _hud.COLOR_TEXT)
		l.name = "Frequentador"
		_lista.add_child(l)
	var up_reason: String = _morale.taverna_upgrade_reason()
	if up_reason == "nível máximo":
		_melhorias.text = "Todas as tavernas no tamanho máximo."
	else:
		var alvo: Node = _morale.taverna_to_upgrade()
		var mais := 0
		if alvo != null and alvo.level < alvo.max_level():
			mais = int(alvo.seats_per_level[alvo.level]) - int(alvo.seats_per_level[alvo.level - 1])
		_melhorias.text = "Ampliar dá +%d lugares e diversão mais rápida (amplia a primeira taverna que ainda não está no máximo)." % mais
		if up_reason != "":
			_melhorias.text += "\nAmpliação: " + up_reason
	_ampliar.visible = true
	if up_reason == "nível máximo":
		_ampliar.text = "Tavernas no tamanho máximo" if tavs.size() > 1 else "Taverna no tamanho máximo"
	elif up_reason == "":
		_ampliar.text = "Ampliar taverna  (%s)" % _morale.taverna_up_cost_text()
	else:
		_ampliar.text = "Ampliar taverna: " + up_reason
	_ampliar.disabled = up_reason != ""


func button_text() -> String:
	var tavs: Array = _morale.tavernas()
	var n := 0
	for t in tavs:
		n += t.guests().size()
	return "Taverna" + ("  •  %d lá dentro" % n if n > 0 else "")


func is_available() -> bool:
	return _morale.taverna() != null


func has_available_action() -> bool:
	return false
