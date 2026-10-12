extends PanelContainer
## Bloco 128: a janela do CAMPO DE TREINO (clique nele). Só o que ele faz: os GUARDAS e o quanto cada um já treinou (% da
## habilidade de combate até o teto), quem está treinando agora, o ritmo e o que falta pra ficar pronto. Antes o campo abria a
## janela da Defesa. Construir outro campo é no menu CONSTRUIR, nunca aqui.
## Interface das janelas do HUD: setup(hud, alvo, economia), refresh(), focus(no), button_text(), has_available_action().
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Modificadores := preload("res://scripts/core/modificadores.gd")

var _hud: CanvasLayer
var _def: Node
var _focus: Node = null
var _title: Label
var _resumo: Label
var _ritmo: Label
var _lista: VBoxContainer


func setup(hud: CanvasLayer, def: Node, _economy: Node) -> void:
	_hud = hud
	_def = def
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
	_title = _hud._label("CAMPO DE TREINO", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var info: Label = _hud._label("De dia os guardas treinam aqui e lutam melhor (mais dano e mais vida). À noite vão pro portão. "
		+ "Quem treinou até o teto descansa em casa.", Tipo.DETALHE, _hud.COLOR_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)
	_resumo = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_resumo)
	_ritmo = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_ritmo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_ritmo)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("GUARDAS (X faz guarda)", Tipo.DETALHE, _hud.COLOR_DIM))
	_lista = VBoxContainer.new()
	_lista.name = "Guardas"
	_lista.add_theme_constant_override("separation", 2)
	vbox.add_child(_lista)


## O HUD avisa qual campo foi clicado (null = abriu pelo menu: o primeiro).
func focus(node: Node) -> void:
	_focus = node if node != null and node.is_in_group("campos") else null


func _campos() -> Array:
	return get_tree().get_nodes_in_group("campos")


func _atual() -> Node:
	if _focus != null and is_instance_valid(_focus) and _focus.is_inside_tree():
		return _focus
	var cs := _campos()
	return cs[0] if not cs.is_empty() else null


## O ritmo de treino por segundo (habilidade 1.0 = 100%) de um guarda no campo: a taxa do campo x o multiplicador (política).
func _taxa(campo: Node) -> float:
	return float(campo.get("train_rate")) * Modificadores.mult(get_tree(), "treino") if campo else 0.0


func refresh() -> void:
	if not visible:
		return
	var cs := _campos()
	var campo: Node = _atual()
	_title.text = "CAMPO DE TREINO" if cs.size() <= 1 or campo == null else "CAMPO DE TREINO %d de %d" % [cs.find(campo) + 1, cs.size()]
	var guardas: Array = _def.guards()
	var treinando := guardas.filter(func(w): return w.get_state() == "training")
	var prontos := guardas.filter(func(w): return w.combat_skill >= w.teto_treino() - 0.001)
	_resumo.text = "%d guarda%s  •  %d treinando agora  •  %d no teto" % [guardas.size(), "" if guardas.size() == 1 else "s", treinando.size(), prontos.size()]
	var taxa := _taxa(campo)
	if campo == null:
		_ritmo.text = "Sem campo de treino. Construa em CONSTRUIR > Defesa e equipamento."
	elif taxa > 0.0:
		_ritmo.text = "%d campo%s na vila  •  cada guarda ganha %.1f%% de habilidade por minuto treinando (de 0 a 100%% em ~%ds)." % [
			cs.size(), "" if cs.size() == 1 else "s", taxa * 60.0 * 100.0, ceili(1.0 / taxa)]
	else:
		_ritmo.text = "%d campo%s na vila." % [cs.size(), "" if cs.size() == 1 else "s"]
	for c in _lista.get_children():
		_lista.remove_child(c)
		c.queue_free()
	if guardas.is_empty():
		_lista.add_child(_hud._label("Nenhum guarda. Selecione ipezinhos e aperte X.", Tipo.DETALHE, _hud.COLOR_DIM))
	for w in guardas:
		var teto: float = w.teto_treino()
		var pct := roundi(w.combat_skill * 100.0)
		var estado := ""
		if w.get_state() == "training":
			estado = "treinando"
		elif w.combat_skill >= teto - 0.001:
			estado = "no teto (%d%%)" % roundi(teto * 100.0)
		else:
			estado = w.get_state_label()
		var falta := ""
		if w.combat_skill < teto - 0.001 and taxa > 0.0:
			falta = "  •  ~%ds pro teto" % ceili((teto - w.combat_skill) / taxa)
		var l: Label = _hud._label("%s — %d%% de treino  •  %s%s" % [String(w.display_name), pct, estado, falta],
			Tipo.CORPO, _hud.COLOR_HUNGER_OK if w.get_state() == "training" else _hud.COLOR_TEXT)
		l.name = "Guarda"
		_lista.add_child(l)


func button_text() -> String:
	var n: int = _def.guards().filter(func(w): return w.get_state() == "training").size()
	return "Campo de treino" + ("  •  %d treinando" % n if n > 0 else "")


func is_available() -> bool:
	return not _campos().is_empty()


func has_available_action() -> bool:
	return false
