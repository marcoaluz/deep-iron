extends PanelContainer
## Bloco 136: a JANELA DA FUNÇÃO. Clicar num botão de função da barra de baixo SEM ninguém selecionado abre a lista de
## quem tem aquela função e de quem não tem (com alguém selecionado, o botão segue dando a função, como antes). Cada linha:
## retrato, nome, ânimo, o que está fazendo, o botão de dar/tirar a função e o "Trocar ▾" (o menu de TODAS as funções
## com os requisitos ✓/✗ do Bloco 128, avaliados pra aquela pessoa na hora de abrir o menu). A contagem do botão da barra
## atualiza na hora. O seletor do topo troca a função mostrada sem fechar a janela.
##
## Criança não aparece (não trabalha, Bloco 111); o padre segue a regra de sempre (só homem e um só: `motivo_padre`).
## Nada aqui entra no save: só chama `set_job`.

const Tipo := preload("res://scripts/ui/tipografia.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const Req := preload("res://scripts/core/requisitos_funcao.gd")
## Tamanho do retrato na linha (px).
const RETRATO := 40.0

var _hud: CanvasLayer
var _economy: Node
## A função mostrada (id de hud.ORDER_JOBS).
var job := "minerador"
var _titulo: Label
var _seletor: OptionButton
var _req: Label
var _contagem: Label
var _lista: VBoxContainer
## ipezinho -> {panel, nome, linha, retrato, acao, trocar}
var _linhas: Dictionary = {}
## Quem está em cada lista e com qual função: muda = refaz as linhas; igual = só os textos.
var _assinatura := ""


func setup(hud: CanvasLayer, _target: Node, economy: Node) -> void:
	_hud = hud
	_economy = economy
	name = "JanelaFuncao"
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(560, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 8)
	v.add_child(topo)
	_titulo = _hud._label("", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(_titulo)
	_seletor = OptionButton.new()
	_seletor.name = "Seletor"
	_seletor.focus_mode = Control.FOCUS_NONE
	_seletor.tooltip_text = "Ver outra função"
	for e in _hud.ORDER_JOBS:
		_seletor.add_item(String(e[1]))
		_seletor.set_item_metadata(_seletor.item_count - 1, String(e[0]))
	_seletor.item_selected.connect(func(i: int):
		Audio.click()
		mostra(String(_seletor.get_item_metadata(i))))
	topo.add_child(_seletor)
	var x: Button = _hud._button("X")
	x.pressed.connect(func():
		Audio.click()
		visible = false)
	topo.add_child(x)
	_req = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_req)
	_contagem = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	v.add_child(_contagem)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 4)
	scroll.add_child(_lista)


## Mostra a função `j` (o botão da barra chama pelo hud.abre_funcao).
func mostra(j: String) -> void:
	job = j
	_assinatura = ""
	for i in _seletor.item_count:
		if String(_seletor.get_item_metadata(i)) == j:
			_seletor.select(i)
	refresh()


func _entrada(j: String) -> Array:
	for e in _hud.ORDER_JOBS:
		if String(e[0]) == j:
			return e
	return [j, j.capitalize(), "", "", "", _hud.COLOR_TEXT, ""]


func _gente() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return is_instance_valid(w) and w.get("job") != null and not (w.has_method("e_crianca") and w.e_crianca()))


func com_funcao() -> Array:
	return _gente().filter(func(w): return String(w.job) == job)


func sem_funcao() -> Array:
	return _gente().filter(func(w): return String(w.job) != job)


func refresh() -> void:
	if not visible or _hud == null:
		return
	var e := _entrada(job)
	_titulo.text = String(e[1]).to_upper()
	var av := Req.avalia(get_tree(), job)
	var linhas := Req.linhas(av)
	_req.text = String(e[6]) + ("\n" + "   ".join(linhas) if not linhas.is_empty() else "")
	var com := com_funcao()
	var sem := sem_funcao()
	com.sort_custom(func(a, b): return _hud._worker_name(a) < _hud._worker_name(b))
	sem.sort_custom(func(a, b): return _ordem_sem(a) < _ordem_sem(b))
	_contagem.text = "Com a função: %d   •   sem: %d" % [com.size(), sem.size()]
	var ass := job + "|" + ",".join(com.map(func(w): return str(w.get_instance_id()))) + "|" + ",".join(sem.map(func(w): return "%d:%s" % [w.get_instance_id(), w.job]))
	if ass != _assinatura:
		_assinatura = ass
		_refaz(com, sem)
	for w in _linhas:
		if is_instance_valid(w):
			_atualiza_linha(w)


## Na lista "sem": quem está SEM FUNÇÃO primeiro (os candidatos óbvios), depois pelo nome.
func _ordem_sem(w: Node) -> String:
	return ("0" if w.has_method("has_no_job") and w.has_no_job() else "1") + _hud._worker_name(w)


func _refaz(com: Array, sem: Array) -> void:
	for c in _lista.get_children():
		c.queue_free()
	_linhas.clear()
	var e := _entrada(job)
	_lista.add_child(_hud._label("COM A FUNÇÃO (%d)" % com.size(), Tipo.DETALHE, e[5]))
	if com.is_empty():
		_lista.add_child(_hud._label("   ninguém ainda: dê a função a alguém da lista de baixo", Tipo.DETALHE, _hud.COLOR_DIM))
	for w in com:
		_linha(w, true)
	_lista.add_child(HSeparator.new())
	_lista.add_child(_hud._label("SEM ESTA FUNÇÃO (%d)" % sem.size(), Tipo.DETALHE, _hud.COLOR_DIM))
	for w in sem:
		_linha(w, false)


func _linha(w: Node, tem: bool) -> void:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.075, 0.065, 0.9)
	sb.border_color = Color(0.36, 0.28, 0.2)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", sb)
	_lista.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var ret := TextureRect.new()
	ret.custom_minimum_size = Vector2(RETRATO, RETRATO)
	ret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ret.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	h.add_child(ret)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)
	var nome: Label = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	col.add_child(nome)
	var linha: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	linha.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	linha.custom_minimum_size.x = 220
	col.add_child(linha)
	var e := _entrada(job)
	var acao: Button = _hud._button("Tirar" if tem else "Dar: %s" % String(e[1]))
	acao.name = "Acao"
	acao.add_theme_font_size_override("font_size", Tipo.DETALHE)
	acao.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	acao.tooltip_text = "Fica sem função (entrega o que carrega e espera no Centro)." if tem else "Passa a ser %s." % String(e[1]).to_lower()
	acao.pressed.connect(func(): da(w, "" if tem else job))
	h.add_child(acao)
	var trocar := MenuButton.new()
	trocar.name = "Trocar"
	trocar.text = "Trocar ▾"
	trocar.flat = false
	trocar.add_theme_font_size_override("font_size", Tipo.DETALHE)
	trocar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trocar.tooltip_text = "Escolher outra função (✓ tem trabalho agora / ✗ o que falta)."
	trocar.about_to_popup.connect(func(): _monta_menu(trocar, w))
	trocar.get_popup().id_pressed.connect(func(i: int): da(w, _id_do_menu(i)))
	h.add_child(trocar)
	_linhas[w] = {"panel": p, "nome": nome, "linha": linha, "retrato": ret, "acao": acao, "trocar": trocar, "tem": tem}
	_atualiza_linha(w)


func _atualiza_linha(w: Node) -> void:
	var l: Dictionary = _linhas[w]
	var nome: String = _hud._worker_name(w)
	if String(w.job) != job and not (w.has_method("has_no_job") and w.has_no_job()):
		nome += "  (%s)" % String(_entrada(String(w.job))[1]).to_lower()
	elif w.has_method("has_no_job") and w.has_no_job():
		nome += "  (sem função)"
	l.nome.text = nome
	var animo := roundi(float(w.get("happiness")))
	var faz := String(w.get_state_label()) if w.has_method("get_state_label") else ""
	l.linha.text = "Ânimo %d%%   •   %s" % [animo, faz]
	l.linha.tooltip_text = l.linha.text
	if l.retrato.texture == null:
		l.retrato.texture = Retratos.de(w)
	if bool(l.tem) and w.has_method("has_no_job"):
		l.acao.disabled = false


## As funções do menu "Trocar" (o id do item = o índice em hud.ORDER_JOBS; o último = sem função).
func _id_do_menu(i: int) -> String:
	return "" if i >= _hud.ORDER_JOBS.size() else String(_hud.ORDER_JOBS[i][0])


## Monta o menu na hora de abrir: cada função liberada com ✓ (tem trabalho pra ele agora) ou ✗ e o que falta.
func _monta_menu(mb: MenuButton, w: Node) -> void:
	var pm := mb.get_popup()
	pm.clear()
	for i in _hud.ORDER_JOBS.size():
		var j := String(_hud.ORDER_JOBS[i][0])
		if not _hud.funcao_liberada(j) and String(w.job) != j:
			continue
		var t := String(_hud.ORDER_JOBS[i][1])
		if Req.tem(j):
			var av := Req.avalia(get_tree(), j, w)
			t = ("%s %s" % [Req.OK, t]) if bool(av.pode) else ("%s %s — %s" % [Req.FALTA, t, String(av.primeiro)])
		if String(w.job) == j:
			t += "   (atual)"
		pm.add_item(t, i)
		var k := pm.get_item_index(i)
		if String(w.job) == j:
			pm.set_item_disabled(k, true)
		elif j == "padre" and w.has_method("motivo_padre") and w.motivo_padre() != "":
			pm.set_item_disabled(k, true)
			pm.set_item_tooltip(k, String(w.motivo_padre()))
	pm.add_separator()
	pm.add_item("Sem função", _hud.ORDER_JOBS.size())
	if w.has_method("has_no_job") and w.has_no_job():
		pm.set_item_disabled(pm.get_item_index(_hud.ORDER_JOBS.size()), true)


## Dá a função `novo` ao ipezinho ("" = sem função). A barra de baixo conta na hora.
func da(w: Node, novo: String) -> bool:
	if not is_instance_valid(w):
		return false
	var alvo: String = novo if novo != "" else String(w.ROLE_IDLE)
	if alvo == "padre" and w.has_method("motivo_padre") and w.motivo_padre() != "":
		Audio.error()
		_hud.show_toast("%s: %s" % [_hud._worker_name(w), w.motivo_padre()], Color(1.0, 0.6, 0.45))
		return false
	w.set_job(alvo, true)
	if String(w.job) != alvo:
		Audio.error()
		return false
	Audio.click()
	var e := _entrada(alvo)
	_hud.show_toast("%s: %s" % [_hud._worker_name(w), String(e[1]) if novo != "" else "sem função"],
		e[5] if novo != "" else Color(0.75, 0.75, 0.8))
	var gente := get_tree().get_nodes_in_group("ipezinhos")
	_hud._refresh_order_bar(gente)  # o contador do botão muda na hora
	refresh()
	return true


func button_text() -> String:
	return "Funções: %s" % String(_entrada(job)[1]).to_lower()


func has_available_action() -> bool:
	return false
