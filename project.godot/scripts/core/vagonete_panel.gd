extends PanelContainer
## Bloco 106: janela do VAGONETE DA BOCA DA MINA (clique na boca). Em partida nova ele está em RUÍNA: a restauração por
## etapas (limpar o trilho, trilhos e dormentes, o vagonete) — só com um MECÂNICO na vila; o jogador pede (paga), o
## material vai pela obra (o carregador ou quem trabalha leva) e o mecânico faz. Restaurado: o estado do carrinho, a carga
## no ponto, o desgaste do trilho. Lembra que restaurar NÃO liga a mina (a área de mina é o comando do jogador, Bloco 77).
## O padrão é o da janela do elevador (elevador_panel.gd, Bloco 99).
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _v: Node
var _status: Label
var _etapas: Label
var _info: Label
var _bar: ProgressBar
var _button: Button


func setup(hud: CanvasLayer, vagonete: Node, _economy: Node) -> void:
	_hud = hud
	_v = vagonete
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
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("VAGONETE DA MINA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var lore: Label = _hud._label(
		"O trilho velho sai da boca da mina até o armazém. Restaurado, o minerador entrega na boca e o carrinho leva 100 de "
		+ "cada vez. A restauração é trabalho de MECÂNICO. Sem o vagonete, o minerador leva na mão (mais devagar, nada trava). "
		+ "Restaurar não liga a mina: quem manda minerar é você (área de mina, tecla 5).", Tipo.DETALHE, _hud.COLOR_DIM)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lore)
	_status = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	vbox.add_child(_status)
	_etapas = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	vbox.add_child(_etapas)
	_bar = _hud._bar(_hud.COLOR_TITLE)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.max_value = 1.0
	vbox.add_child(_bar)
	_info = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_info)
	_button = _hud._button("")
	_button.pressed.connect(func():
		Audio.click()
		_v.pedir_etapa()
		refresh())
	vbox.add_child(_button)


func focus(_node: Node) -> void:
	pass


func refresh() -> void:
	if not visible:
		return
	var linhas: Array[String] = []
	for i in range(1, _v.ETAPA_PRONTA):
		var marca := "✔" if _v.etapa > i or _v.restaurado() else ("▶" if i == _v.etapa_atual() else "·")
		var extra := "" if _v.etapa > i or _v.restaurado() else "  —  %s, %ds de mecânico" % [_v.custo_texto(i), roundi(_v.segundos_etapa(i))]
		linhas.append("%s %d. %s%s" % [marca, i, _v.etapa_nome(i), extra])
	_etapas.text = "\n".join(linhas)
	_bar.visible = _v.obra_pending()
	_bar.value = _v.obra_progress()
	if not _v.restaurado():
		_status.text = ("Restaurando: %s" % _v.etapa_nome(_v.etapa)) if _v.pago else "Em ruína (%d de %d etapas)" % [maxi(_v.etapa - 1, 0), _v.ETAPA_PRONTA - 1]
		_info.text = "Enquanto isso, o minerador leva o minério na mão até o armazém." if not _v.pago \
			else "Obra: %s" % _v._obra.status(_v.obra_progress())
	elif _v.is_broken():
		_status.text = "Trilho quebrado"
		_info.text = "O mecânico conserta (sem mecânico, o engenheiro). Enquanto isso, o minerador leva na mão."
	else:
		_status.text = "Funcionando"
		_info.text = "No ponto: %d de %d  •  já levou %d  •  trilho %d%%" % [int(_v.buffered()), int(_v.buffer_capacity),
			int(_v.total_moved), roundi(100.0 * _v.manut_condicao())]
		if _v.parado_por_area():
			_info.text += "\nParado: a área de mina está desligada (tecla 5)."
	var reason: String = _v.etapa_block_reason()
	_button.visible = not _v.restaurado() and not _v.pago
	if _button.visible:
		var i: int = _v.etapa_atual()
		_button.text = ("Restaurar: %s (%s)" % [_v.etapa_nome(i), _v.custo_texto(i)]) if reason == "" else "Restaurar: " + reason
		_button.disabled = reason != ""
		_button.tooltip_text = reason


func button_text() -> String:
	if not _v.restaurado():
		return "Vagonete: restaurar" if not _v.pago else "Vagonete %d%%" % roundi(_v.obra_progress() * 100.0)
	return "Vagonete"


func has_available_action() -> bool:
	return not _v.restaurado() and _v.etapa_block_reason() == ""
