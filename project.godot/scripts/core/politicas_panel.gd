extends PanelContainer
## Bloco 108: janela POLÍTICAS DA VILA (tecla F6, menu Janelas; libera no estágio Vilarejo). Um cartão por política com a
## opção que vale agora em destaque e as outras como botões. Clicar numa opção abre o DETALHE embaixo (por que escolher, o
## que ganha, o que custa, a restrição e o ânimo previsto) e o botão Confirmar — ou o motivo de não poder (espera, campo de
## treino...). Bloco 111: a 5ª política, a FAMÍLIA (o cartão que estava reservado). Sem gráficos: leitura rápida. Os cartões
## ficam numa grade de 2 colunas (cabe em 720p com o detalhe aberto). O padrão visual é o das janelas do layout v2 (cozinha_panel.gd).
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Politicas := preload("res://scripts/core/politicas.gd")
const COR_GANHA := Color(0.55, 0.9, 0.5)
const COR_CUSTA := Color(1.0, 0.55, 0.45)

var _hud: CanvasLayer
var _pol: Node
var _status: Label
var _cartoes := {}  # política -> {botoes: {opção: Button}, info: Label}
var _det_box: VBoxContainer
var _det_titulo: Label
var _det_porque: Label
var _det_ganha: Label
var _det_custa: Label
var _det_restricao: Label
var _det_previsto: Label
var _btn_confirma: Button
var _familia: Label
var _sel_pol := ""
var _sel_op := ""


func setup(hud: CanvasLayer, pol: Node, _economy: Node) -> void:
	_hud = hud
	_pol = pol
	_build()
	visible = false
	if _pol:
		_pol.mudou.connect(func(_p, _o): refresh())


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(740, 0)  # (cabe entre a aba da esquerda e o rastreador de missões em 1280x720)
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
	var title: Label = _hud._label("POLÍTICAS DA VILA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_status = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grade)
	for p in Politicas.POLITICAS:
		grade.add_child(_cartao(p))
	# o detalhe da opção clicada (some sem nada escolhido)
	_det_box = VBoxContainer.new()
	_det_box.add_theme_constant_override("separation", 3)
	vbox.add_child(_det_box)
	_det_box.add_child(HSeparator.new())
	_det_titulo = _hud._label("", Tipo.TITULO, _hud.COLOR_TITLE)
	_det_box.add_child(_det_titulo)
	_det_porque = _det_label(_hud.COLOR_TEXT)
	_det_ganha = _det_label(COR_GANHA)
	_det_custa = _det_label(COR_CUSTA)
	_det_restricao = _det_label(_hud.COLOR_DIM)
	_det_previsto = _det_label(_hud.COLOR_DIM)
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 6)
	_det_box.add_child(botoes)
	_btn_confirma = _hud._button("Confirmar")
	_btn_confirma.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_confirma.pressed.connect(_confirma)
	botoes.add_child(_btn_confirma)
	var cancela: Button = _hud._button("Cancelar")
	cancela.pressed.connect(func():
		Audio.click()
		_sel_pol = ""
		refresh())
	botoes.add_child(cancela)


func _det_label(cor: Color) -> Label:
	var l: Label = _hud._label("", Tipo.CORPO, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_det_box.add_child(l)
	return l


func _cartao(p: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_hud._label(Politicas.NOME_POLITICA[p].to_upper(), Tipo.TITULO, _hud.COLOR_TITLE))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	box.add_child(linha)
	var botoes := {}
	for op in Politicas.OPCOES[p]:
		var b: Button = _hud._button(Politicas.NOME_OPCAO[p][op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _seleciona(p, op))
		linha.add_child(b)
		botoes[op] = b
	var info: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	_cartoes[p] = {"botoes": botoes, "info": info}
	return box


func _seleciona(p: String, op: String) -> void:
	Audio.click()
	_sel_pol = p
	_sel_op = op
	refresh()


func _confirma() -> void:
	if _pol == null or _sel_pol == "":
		return
	if _pol.escolhe(_sel_pol, _sel_op):
		Audio.click()
		_sel_pol = ""
	else:
		Audio.error()
	refresh()


func refresh() -> void:
	if not visible or _pol == null:
		return
	var fatores := _efeito_agora()
	_status.text = "Uma opção por política. As escolhas valem na hora para a vila inteira; trocar de novo a mesma política espera %s. Efeito no ânimo agora: %s." % [
		"1 dia" if is_equal_approx(_pol.troca_espera_dias, 1.0) else "%s dias" % str(_pol.troca_espera_dias), fatores]
	for p in Politicas.POLITICAS:
		var c: Dictionary = _cartoes[p]
		var ativa: String = _pol.opcao(p)
		for op in c.botoes:
			var b: Button = c.botoes[op]
			var nome: String = Politicas.NOME_OPCAO[p][op]
			b.text = ("✔ " + nome) if op == ativa else nome
			b.disabled = op == ativa
		var extra := ""
		if float(_pol.espera[p]) > 0.0:
			extra = "  •  troca em %s" % _pol.texto_espera(p)
		if p == "racao" and _pol.fraqueza_ativa():
			extra += "  •  a vila está FRACA"
		if p == "seguranca" and ativa == "vigilancia":
			extra += "  •  esta noite: %s" % ("paga" if _pol.vigilancia_paga else "ainda não paga (cobra ao anoitecer)")
		(c.info as Label).text = String(_pol.texto(p, ativa).porque) + extra
	_det_box.visible = _sel_pol != ""
	if _sel_pol == "":
		return
	var t: Dictionary = _pol.texto(_sel_pol, _sel_op)
	_det_titulo.text = "%s → %s" % [Politicas.NOME_POLITICA[_sel_pol], Politicas.NOME_OPCAO[_sel_pol][_sel_op]]
	_det_porque.text = "Por que escolher: " + String(t.porque)
	_det_ganha.text = "Ganha: " + " ".join(t.ganha) if not (t.ganha as Array).is_empty() else ""
	_det_ganha.visible = _det_ganha.text != ""
	_det_custa.text = "Custa: " + " ".join(t.custa) if not (t.custa as Array).is_empty() else ""
	_det_custa.visible = _det_custa.text != ""
	_det_restricao.text = String(t.restricao)
	_det_restricao.visible = _det_restricao.text != ""
	var prev: float = _pol.animo_previsto(_sel_pol, _sel_op)
	_det_previsto.visible = prev >= 0.0
	if prev >= 0.0:
		_det_previsto.text = "Ânimo médio previsto: %d%s" % [roundi(prev), "  — perto da insatisfação (greve abaixo de 30)" if prev < _pol.aviso_animo else ""]
		_det_previsto.add_theme_color_override("font_color", COR_CUSTA if prev < _pol.aviso_animo else _hud.COLOR_DIM)
	var motivo: String = _pol.motivo_bloqueio(_sel_pol, _sel_op)
	_btn_confirma.disabled = motivo != ""
	_btn_confirma.text = "Confirmar" if motivo == "" else "Não dá: " + motivo


## "−8 (jornada estendida)" — o efeito médio das políticas no ânimo agora.
func _efeito_agora() -> String:
	var ws := get_tree().get_nodes_in_group("ipezinhos")
	if ws.is_empty():
		return "nenhum"
	var soma := {}
	for w in ws:
		for f in _pol.fatores_animo(w):
			soma[f[0]] = float(soma.get(f[0], 0.0)) + float(f[1])
	if soma.is_empty():
		return "nenhum"
	var partes: Array = []
	for k in soma:
		partes.append("%+.0f %s" % [float(soma[k]) / ws.size(), k])
	return ", ".join(partes) + " (média)"


func button_text() -> String:
	if _pol == null or _pol.e_padrao():
		return "Políticas da Vila"
	var mud: Array = []
	for p in Politicas.POLITICAS:
		if _pol.opcao(p) != Politicas.PADRAO[p]:
			mud.append(String(Politicas.NOME_OPCAO[p][_pol.opcao(p)]).to_lower())
	return "Políticas: " + ", ".join(mud)


func is_available() -> bool:
	return _pol != null and _pol.liberada()


func has_available_action() -> bool:
	return false
