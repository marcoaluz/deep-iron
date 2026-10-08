extends PanelContainer
## Bloco 99: janela do ELEVADOR DA MINA (clique na torre, ao lado da escavadeira). A restauração por etapas (limpar o
## poço, guincho e cabos, a cabine — cada uma o jogador pede e o engenheiro faz com o material) e, restaurado, a cabine:
## onde está, quem espera, quantas viagens o cabo ainda aguenta e o conserto quando arrebenta. Lembra que sem o elevador
## a descida é pela escada em espiral (lenta).
const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _el: Node
var _status: Label
var _etapas: Label
var _cabine: Label
var _bar: ProgressBar
var _button: Button


func setup(hud: CanvasLayer, elevador: Node, _economy: Node) -> void:
	_hud = hud
	_el = elevador
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
	var title: Label = _hud._label("ELEVADOR DA MINA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var lore: Label = _hud._label(
		"A torre velha sobre o poço é a entrada principal da mina. Restaurada, a cabine leva gente até o nível 2 e volta. "
		+ "Sem ela (ou com o cabo arrebentado) a descida é pela escada em espiral, ao lado: funciona, mas é lenta.", Tipo.DETALHE, _hud.COLOR_DIM)
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
	_cabine = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_cabine.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_cabine)
	_button = _hud._button("")
	_button.pressed.connect(func():
		Audio.click()
		_el.pedir_etapa()
		refresh())
	vbox.add_child(_button)


func focus(_node: Node) -> void:
	pass


func refresh() -> void:
	if not visible:
		return
	var linhas: Array[String] = []
	for i in range(1, _el.ETAPA_PRONTA + 1):
		var marca := "✔" if _el.etapa >= i else ("▶" if i == _el.etapa + 1 else "·")
		var extra := "" if _el.etapa >= i else "  —  %s, %ds de engenheiro" % [_el.custo_texto(i), roundi(_el.segundos_etapa(i))]
		linhas.append("%s %d. %s%s" % [marca, i, _el.etapa_nome(i), extra])
	_etapas.text = "\n".join(linhas)
	_bar.visible = _el.obra_pending()
	_bar.value = _el.obra_progress()
	var c = _el.cabine
	if not _el.restaurado():
		_status.text = "Restaurando: %s" % _el.etapa_nome(_el.etapa + 1) if _el.pago else "Arruinado (%d de %d etapas)" % [_el.etapa, _el.ETAPA_PRONTA]
		_cabine.text = "O nível 2 abre com a escavadeira; dá pra restaurar o elevador antes (em paralelo)." if not _el.unlocked \
			else "O nível 2 já está aberto: por enquanto todo mundo desce pela escada em espiral (lenta)."
	elif not _el.unlocked:
		_status.text = "Restaurado — esperando a escavadeira abrir o nível 2"
		_cabine.text = "A cabine leva %d de cada vez (%ds de ponta a ponta)." % [_el.capacity, roundi(_el.segundos_viagem)]
	elif c.quebrada:
		_status.text = "Cabo arrebentado"
		var falta: String = _el.conserto_falta()
		_cabine.text = ("Consertando (%d%%): o engenheiro troca o cabo." % roundi(c.conserto_progresso() * 100.0)) if c.consertando \
			else ("O conserto espera o material: %s." % falta if falta != "" else "O conserto vai ser pedido já (precisa de engenheiro).")
		_cabine.text += " Enquanto isso, a descida é pela escada em espiral."
	else:
		_status.text = "Funcionando — " + c.estado_texto()
		_cabine.text = "Leva %d de cada vez, %ds de ponta a ponta. O cabo aguenta mais %d viagens (%d feitas no total)." % [
			_el.capacity, roundi(_el.segundos_viagem), c.viagens_restantes(), c.total_viagens]
	var reason: String = _el.etapa_block_reason()
	_button.visible = not _el.restaurado() and not _el.pago
	if _button.visible:
		var i: int = _el.etapa_atual()
		_button.text = ("Restaurar: %s (%s)" % [_el.etapa_nome(i), _el.custo_texto(i)]) if reason == "" else "Restaurar: " + reason
		_button.disabled = reason != ""


func button_text() -> String:
	if not _el.restaurado():
		return "Elevador: restaurar" if not _el.pago else "Elevador %d%%" % roundi(_el.obra_progress() * 100.0)
	if _el.cabine.quebrada:
		return "Elevador: cabo arrebentado"
	return "Elevador"


func has_available_action() -> bool:
	return not _el.restaurado() and _el.etapa_block_reason() == ""
