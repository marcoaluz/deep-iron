extends PanelContainer
## Bloco 101: janela "Migrantes" — o CARTÃO de cada um que espera no portão: retrato, nome, sexo, condição e a função de
## que gostaria, e os botões Aceitar (precisa de cama livre: sem ela, desabilitado com a dica "falta cama"), Recusar e
## Esperar. Embaixo, a atratividade da vila (o que faz vir mais gente) e quando chega o próximo grupo. Abre sozinha quando
## um grupo chega; também pelo alerta e pelo menu "Janelas".
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const NOME_FUNCAO := {"minerador": "minerador", "caçador": "caçador", "cozinheiro": "cozinheiro", "lenhador": "lenhador",
	"guarda": "guarda", "engenheiro": "engenheiro", "médico": "médico", "pesquisador": "pesquisador", "fundidor": "fundidor",
	"ferreiro": "ferreiro", "carpinteiro": "carpinteiro"}
const COR_CONDICAO := {"saudavel": Color(0.6, 0.95, 0.55), "com_fome": Color(1.0, 0.8, 0.4), "ferido": Color(1.0, 0.5, 0.4),
	"doente": Color(0.85, 0.7, 1.0)}

var _hud: CanvasLayer
var _mig: Node
var _lista: VBoxContainer
var _rodape: Label
var _assinatura := ""


func setup(hud: CanvasLayer, migrantes: Node, _economy: Node) -> void:
	_hud = hud
	_mig = migrantes
	_build()
	visible = false
	_mig.mudou.connect(func():
		if visible:
			refresh())


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(520, 0)
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
	var title: Label = _hud._label("MIGRANTES NO PORTÃO", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var lore: Label = _hud._label("Gente que fugiu do sol procura abrigo. Quem entra precisa de uma cama; ferido ou doente vai "
		+ "pra enfermaria. De noite, quem espera do lado de fora corre perigo.", Tipo.DETALHE, _hud.COLOR_DIM)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.x = 480.0
	vbox.add_child(lore)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 6)
	vbox.add_child(_lista)
	_rodape = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_rodape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rodape.custom_minimum_size.x = 480.0
	vbox.add_child(_rodape)


func focus(_node: Node) -> void:
	pass


func _cartao(e: Dictionary) -> Control:
	var w: Node = e.w
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	var ret := TextureRect.new()
	ret.texture = Retratos.de(w)
	ret.custom_minimum_size = Vector2(64, 64)
	ret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ret.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	linha.add_child(ret)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(info)
	var sexo := "mulher" if w.get("gender") == "menina" else "homem"
	info.add_child(_hud._label("%s  (%s)" % [w.display_name, sexo], Tipo.TITULO, _hud.COLOR_TEXT))
	info.add_child(_hud._label("Condição: %s" % _mig.texto_condicao(e), Tipo.DETALHE, COR_CONDICAO.get(String(e.condicao), _hud.COLOR_TEXT)))
	info.add_child(_hud._label("Gostaria de ser: %s" % NOME_FUNCAO.get(String(e.funcao), String(e.funcao)), Tipo.DETALHE, _hud.COLOR_DIM))
	var horas := float(e.prazo) / maxf(_mig._seg_por_dia() / 24.0, 0.01)
	info.add_child(_hud._label("Vai embora em %dh" % ceili(horas), Tipo.DETALHE, _hud.COLOR_DIM))
	var botoes := VBoxContainer.new()
	linha.add_child(botoes)
	var motivo: String = _mig.motivo_aceitar(w)
	var aceitar: Button = _hud._button("Aceitar")
	aceitar.name = "Aceitar"
	aceitar.disabled = motivo != ""
	aceitar.tooltip_text = motivo if motivo != "" else "Entra na vila, sem função, e ganha uma cama."
	aceitar.pressed.connect(func():
		Audio.click()
		_mig.aceita(w)
		refresh())
	botoes.add_child(aceitar)
	var recusar: Button = _hud._button("Recusar")
	recusar.name = "Recusar"
	recusar.pressed.connect(func():
		Audio.click()
		_mig.recusa(w)
		refresh())
	botoes.add_child(recusar)
	var esperar: Button = _hud._button("Esperar")
	esperar.name = "Esperar"
	esperar.tooltip_text = "Ficam no portão até o prazo (de noite, correm perigo)."
	esperar.pressed.connect(func():
		Audio.click()
		_mig.espera(w)
		visible = false)
	botoes.add_child(esperar)
	return linha


func refresh() -> void:
	if not visible:
		return
	var eco := get_tree().get_first_node_in_group("economy")
	var camas: int = eco.free_beds() if eco else 0
	var esp: Array = _mig.esperando.filter(func(e): return is_instance_valid(e.w))
	# só refaz os cartões quando muda quem espera ou as camas (o prazo anda no rodapé de cada um a cada abertura)
	var assinatura := "%s|%d|%s" % [esp.map(func(e): return e.w.get_instance_id()), camas, esp.map(func(e): return [e.condicao, int(float(e.prazo) / 10.0)])]
	if assinatura != _assinatura:
		_assinatura = assinatura
		for c in _lista.get_children():
			c.queue_free()
		if esp.is_empty():
			_lista.add_child(_hud._label("Ninguém esperando no portão agora.", Tipo.CORPO, _hud.COLOR_TEXT))
		for e in esp:
			_lista.add_child(_cartao(e))
	var a: float = _mig.atratividade()
	var dias := maxf(float(_mig.proximo), 0.0) / maxf(_mig._seg_por_dia(), 1.0)
	_rodape.text = "Camas livres: %d   •   Atratividade da vila: %d%%   •   Próximo grupo: %s" % [camas, roundi(a * 100.0),
		"quando estes forem atendidos" if not esp.is_empty() else ("em ~%.1f dia%s" % [dias, "s" if dias >= 2.0 else ""])]


func is_available() -> bool:
	return true


func button_text() -> String:
	var n: int = _mig.esperando.size()
	return "Migrantes (%d no portão)" % n if n > 0 else "Migrantes"


func has_available_action() -> bool:
	return not _mig.esperando.is_empty()
