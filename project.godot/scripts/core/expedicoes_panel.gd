extends PanelContainer
## Bloco 104: a janela das EXPEDIÇÕES (tecla ;; estilo do layout v2).
## - O MAPA DA REGIÃO (a arte de assets/game/ui/expedicoes/mapa_regiao.png) com as regiões da superfície: o nome se
##   revelada, "?" se escondida (dá pra explorar com o batedor), o cadeado se trancada; ao lado, as regiões NA MINA.
## - A região escolhida: o texto, o perigo, os dias, o traje; a EQUIPE (2 a 4: batedor obrigatório, guardas, pesquisadora,
##   médico), as PROVISÕES (ração da cozinha, kit de ferramentas), os DIAS e o RISCO calculado com as partes; o Partir.
## - As expedições EM CURSO (quem, quando volta, a decisão pendente com os dois botões) e os últimos RELATÓRIOS.
## A lógica toda é a expedicoes.gd.
const Tipo := preload("res://scripts/ui/tipografia.gd")
const MAPA := preload("res://assets/game/ui/expedicoes/mapa_regiao.png")
const ESCALA := 1.25

var _hud: CanvasLayer
var _ex: Node
var _mapa: TextureRect
var _marcas := {}  # região -> Button
var _mina_box: VBoxContainer
var _det: VBoxContainer
var _curso: VBoxContainer
var _rel: VBoxContainer
var _cadeia: Label
var _sel := "floresta"
var _equipe: Array = []
var _racao := true
var _kit := false
var _dias := 1
var _sig := ""


func setup(hud: CanvasLayer, ex: Node, _economy: Node) -> void:
	_hud = hud
	_ex = ex
	_build()
	visible = false
	_ex.mudou.connect(func():
		_sig = ""
		if visible:
			refresh())


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(760, 0)
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
	var title: Label = _hud._label("EXPEDIÇÕES", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_cadeia = _hud._label("", Tipo.DETALHE, Color(0.8, 0.85, 1.0))
	_cadeia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cadeia.custom_minimum_size.x = 720
	vbox.add_child(_cadeia)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	vbox.add_child(linha)
	# o mapa e as marcas das regiões da superfície
	_mapa = TextureRect.new()
	_mapa.name = "Mapa"
	_mapa.texture = MAPA
	_mapa.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mapa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mapa.stretch_mode = TextureRect.STRETCH_SCALE
	_mapa.custom_minimum_size = Vector2(MAPA.get_width(), MAPA.get_height()) * ESCALA
	linha.add_child(_mapa)
	for r in _ex.regioes():
		var m: Array = r.get("mapa", [])
		if m.size() < 2:
			continue
		var b: Button = _hud._button("")
		b.name = "Regiao_" + String(r.id)
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.position = Vector2(float(m[0]), float(m[1])) * ESCALA - Vector2(40, 12)
		var id := String(r.id)
		b.pressed.connect(func():
			Audio.click()
			escolhe(id))
		_mapa.add_child(b)
		_marcas[id] = b
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 4)
	lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(lado)
	lado.add_child(_hud._label("NA MINA", Tipo.DETALHE, _hud.COLOR_DIM))
	_mina_box = VBoxContainer.new()
	_mina_box.name = "NaMina"
	lado.add_child(_mina_box)
	for r in _ex.regioes():
		if (r.get("mapa", []) as Array).size() >= 2:
			continue
		var b: Button = _hud._button("")
		b.name = "Regiao_" + String(r.id)
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		var id := String(r.id)
		b.pressed.connect(func():
			Audio.click()
			escolhe(id))
		_mina_box.add_child(b)
		_marcas[id] = b
	vbox.add_child(HSeparator.new())
	_det = VBoxContainer.new()
	_det.name = "Detalhe"
	_det.add_theme_constant_override("separation", 4)
	vbox.add_child(_det)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("EM CURSO", Tipo.DETALHE, _hud.COLOR_DIM))
	_curso = VBoxContainer.new()
	_curso.name = "EmCurso"
	vbox.add_child(_curso)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("RELATÓRIOS", Tipo.DETALHE, _hud.COLOR_DIM))
	_rel = VBoxContainer.new()
	_rel.name = "Relatorios"
	vbox.add_child(_rel)


func focus(_node: Node) -> void:
	pass


func escolhe(id: String) -> void:
	_sel = id
	var r: Dictionary = _ex.regiao(id)
	_dias = clampi(_dias, int((r.get("dias", [1, 1]) as Array)[0]), int((r.get("dias", [1, 1]) as Array)[1]))
	_sig = ""
	refresh()


## Pros testes: monta a equipe por código.
func define_equipe(lista: Array) -> void:
	_equipe = lista.duplicate()
	_sig = ""
	refresh()


func _texto(t: String, cor: Color, tipo: int = Tipo.DETALHE) -> Label:
	var l: Label = _hud._label(t, tipo, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 720
	return l


func _assinatura() -> String:
	var dn := get_tree().get_first_node_in_group("day_night")
	var s := "%s|%s|%s|%s|%d|%d|%d" % [_sel, _equipe.map(func(w): return w.name if is_instance_valid(w) else ""), _racao, _kit, _dias,
		_ex.cadeia, int(dn.time / 10.0) if dn else 0]
	for e in _ex.em_curso:
		s += "|%d%s%s" % [int(e.n), e.fase, e.decisoes.map(func(d): return String(d.escolha) + str(d.mostrada))]
	return s + "|%d" % _ex.relatorios.size()


func refresh() -> void:
	if not visible:
		return
	var sig := _assinatura()
	if sig == _sig:
		return
	_sig = sig
	_equipe = _equipe.filter(func(w): return is_instance_valid(w) and _ex.membro_ok(w))
	_cadeia.text = _texto_cadeia()
	for id in _marcas:
		var sit: Array = _ex.situacao(id)
		var b: Button = _marcas[id]
		var nm: String = _ex.nome(id)
		var no_mapa: bool = not (_ex.regiao(id).get("mapa", []) as Array).is_empty()
		match String(sit[0]):
			"revelada":
				b.text = nm
			"escondida":
				b.text = "?"
			_:
				b.text = "?" if no_mapa else "%s (trancada)" % nm  # (no mapa, o trancado é um "?" apagado)
		if _ex.em_curso.any(func(e): return String(e.regiao) == id):
			b.text += "  [equipe lá]"
		b.modulate = Color(1.2, 1.15, 0.8) if id == _sel else (Color(0.55, 0.55, 0.6) if String(sit[0]) == "trancada" else Color.WHITE)
		b.tooltip_text = String(sit[1]) if String(sit[0]) == "trancada" else ""
		if no_mapa:  # o botão cabe dentro do mapa (centrado no ponto da região)
			var m: Array = _ex.regiao(id).mapa
			b.reset_size()
			var w: float = b.get_combined_minimum_size().x
			b.position = Vector2(clampf(float(m[0]) * ESCALA - w * 0.5, 2.0, _mapa.custom_minimum_size.x - w - 2.0), float(m[1]) * ESCALA - 12.0)
	_monta_detalhe()
	_monta_curso()
	for c in _rel.get_children():
		_rel.remove_child(c)
		c.queue_free()
	if _ex.relatorios.is_empty():
		_rel.add_child(_texto("Nenhuma expedição voltou ainda.", _hud.COLOR_DIM))
	for i in range(_ex.relatorios.size() - 1, maxi(_ex.relatorios.size() - 3, 0) - 1, -1):
		var r: Dictionary = _ex.relatorios[i]
		_rel.add_child(_texto("%s — dia %d" % [_ex.nome(String(r.regiao)), int(r.dia)], _hud.COLOR_TITLE, Tipo.CORPO))
		_rel.add_child(_texto(String(r.texto), _hud.COLOR_TEXT))


func _texto_cadeia() -> String:
	match int(_ex.cadeia):
		0:
			return "O robô antigo: ninguém sabe de onde vêm os Ferrugentos. (Estude o corpo de um: Catálogo, R)"
		1:
			return "O robô antigo: o Ferrugento tem o número de série de uma fábrica. Falta captar o sinal (o Rádio da vila, ou a Antena improvisada da Oficina) — de noite."
		2, 3:
			return "O robô antigo: o sinal foi captado. A pesquisadora precisa de 3 escutas (o portão, o alto da pedreira, a boca do poço)."
		4:
			return "O robô antigo: o sinal vem da FÁBRICA SOTERRADA, atrás da radiação do S2. Mande uma expedição (traje antirradiação)."
	return "O robô antigo foi achado."


func _monta_detalhe() -> void:
	for c in _det.get_children():
		_det.remove_child(c)
		c.queue_free()
	var r: Dictionary = _ex.regiao(_sel)
	if r.is_empty():
		return
	var sit: Array = _ex.situacao(_sel)
	var nm: String = _ex.nome(_sel) if String(sit[0]) != "escondida" else "Região desconhecida (?)"
	_det.add_child(_texto(nm, _hud.COLOR_TITLE, Tipo.TITULO))
	if String(sit[0]) == "escondida":
		_det.add_child(_texto("Ninguém foi lá ainda. Uma expedição com o batedor explora (o risco é maior e os achados, a metade).", _hud.COLOR_DIM))
	else:
		_det.add_child(_texto(_ex.texto(_sel, "texto"), _hud.COLOR_TEXT))
	var eq := get_tree().get_first_node_in_group("equipment")
	var traje := String(r.get("traje", ""))
	_det.add_child(_texto("Perigo: %d%% por pessoa por dia  •  %d a %d dia%s  •  traje: %s" % [roundi(float(r.perigo) * 100.0),
		int((r.dias as Array)[0]), int((r.dias as Array)[1]), "s" if int((r.dias as Array)[1]) > 1 else "",
		(String(eq.NAMES.get(traje, traje)) if eq else traje) if traje != "" else "nenhum"], Color(1.0, 0.85, 0.5)))
	if String(sit[0]) == "trancada":
		_det.add_child(_texto("Trancada: %s." % String(sit[1]), Color(1.0, 0.6, 0.45)))
		return
	# a equipe
	_det.add_child(_texto("EQUIPE (%d a %d; o batedor lidera):" % [_ex.equipe_min, _ex.equipe_max], _hud.COLOR_DIM))
	var grade := GridContainer.new()
	grade.name = "Candidatos"
	grade.columns = 3
	_det.add_child(grade)
	var cand := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.job in ["batedor", "guarda", "pesquisador", "médico"])
	if cand.is_empty():
		_det.add_child(_texto("Ninguém pode ir: dê a função de batedor (K) a alguém (e guardas, pesquisadora, médico pra equipe).", Color(1.0, 0.6, 0.45)))
	for w in cand:
		var b := Button.new()
		b.name = "Membro_" + String(w.name)
		b.toggle_mode = true
		b.button_pressed = _equipe.has(w)
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		var extra := ""
		if w.job == "guarda":
			extra = " (%s)" % (w.weapon_label() if w.has_method("weapon_label") else "")
		b.text = "%s — %s%s%s" % [w.display_name, w.job, extra, "" if _ex.membro_ok(w) else " [não pode]"]
		b.disabled = not _ex.membro_ok(w)
		b.toggled.connect(func(on: bool):
			Audio.click()
			if on and not _equipe.has(w):
				_equipe.append(w)
			elif not on:
				_equipe.erase(w)
			_sig = ""
			refresh())
		grade.add_child(b)
	# provisões e dias
	var prov := HBoxContainer.new()
	prov.add_theme_constant_override("separation", 8)
	_det.add_child(prov)
	var cr := CheckBox.new()
	cr.name = "Racao"
	cr.button_pressed = _racao
	cr.text = "Ração (%d de comida)" % int(_ex.racao_total(maxi(_equipe.size(), 1), _dias))
	cr.add_theme_font_size_override("font_size", Tipo.DETALHE)
	cr.toggled.connect(func(on: bool):
		_racao = on
		_sig = ""
		refresh())
	prov.add_child(cr)
	var ck := CheckBox.new()
	ck.name = "Kit"
	ck.button_pressed = _kit
	ck.text = "Kit de ferramentas (%d ferro + %d madeira)" % [_ex.kit_ferro, _ex.kit_madeira]
	ck.add_theme_font_size_override("font_size", Tipo.DETALHE)
	ck.toggled.connect(func(on: bool):
		_kit = on
		_sig = ""
		refresh())
	prov.add_child(ck)
	for passo in [-1, 1]:
		var b: Button = _hud._button("−" if passo < 0 else "+")
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.pressed.connect(func():
			Audio.click()
			_dias = clampi(_dias + passo, int((r.dias as Array)[0]), int((r.dias as Array)[1]))
			_sig = ""
			refresh())
		prov.add_child(b)
		if passo < 0:
			prov.add_child(_hud._label("%d dia%s" % [_dias, "s" if _dias > 1 else ""], Tipo.CORPO, _hud.COLOR_TEXT))
	# o risco
	var rk: Dictionary = _ex.risco(_sel, _equipe, _racao, _kit)
	var partes: Array[String] = []
	for p in rk.partes:
		partes.append("%s %s" % [p[0], ("%d%%" % roundi(float(p[1]) * 100.0)) if p == rk.partes[0] else ("x%.2f" % float(p[1]))])
	var risco := _texto("Risco: %d%% por pessoa por dia (%s)  •  chance de alguém voltar ferido: %d%%" % [roundi(float(rk.total) * 100.0),
		", ".join(partes), roundi(_ex.chance_alguem_ferido(_sel, _equipe, _racao, _kit, _dias) * 100.0)], Color(1.0, 0.75, 0.55))
	risco.name = "Risco"
	_det.add_child(risco)
	var motivo: String = _ex.motivo(_sel, _equipe, _racao, _kit, _dias)
	var parte: Button = _hud._button(("Partir (%s)" % ("explorar" if String(sit[0]) == "escondida" else "%d dia%s" % [_dias, "s" if _dias > 1 else ""])) if motivo == "" else "Partir: %s" % motivo)
	parte.name = "Partir"
	parte.disabled = motivo != ""
	parte.pressed.connect(func():
		if _ex.parte(_sel, _equipe, _racao, _kit, _dias):
			Audio.click()
			_equipe = []
		_sig = ""
		refresh())
	_det.add_child(parte)


func _monta_curso() -> void:
	for c in _curso.get_children():
		_curso.remove_child(c)
		c.queue_free()
	if _ex.em_curso.is_empty():
		_curso.add_child(_texto("Nenhuma expedição fora agora (máximo %d ao mesmo tempo)." % _ex.max_agora(), _hud.COLOR_DIM))
	for e in _ex.em_curso:
		var nomes := ", ".join(PackedStringArray(e.membros.filter(func(w): return is_instance_valid(w)).map(func(w): return String(w.display_name))))
		_curso.add_child(_texto("%s: %s — %s, volta no dia %d" % [_ex.nome(String(e.regiao)), nomes,
			"saindo pela %s" % ("floresta" if String(_ex.regiao(String(e.regiao)).get("saida", "portao")) == "portao" else "mina") if String(e.fase) == "saindo" else "fora",
			int(e.volta_dia)], _hud.COLOR_TEXT))
		for d in e.decisoes:
			if not d.mostrada or String(d.escolha) != "":
				continue
			var sec := "evento." + String(d.evento)
			_curso.add_child(_texto("%s: %s" % [_ex.texto(sec, "titulo"), _ex.texto(sec, "texto")], Color(1.0, 0.85, 0.5)))
			var row := HBoxContainer.new()
			_curso.add_child(row)
			for op in ["a", "b"]:
				var b: Button = _hud._button(_ex.texto(sec, op))
				b.name = "Decide_" + op
				b.add_theme_font_size_override("font_size", Tipo.DETALHE)
				var n := int(e.n)
				var ev := String(d.evento)
				b.pressed.connect(func():
					Audio.click()
					_ex.decide(n, ev, op))
				row.add_child(b)


func is_available() -> bool:
	return true


func button_text() -> String:
	return "Expedições %d fora" % _ex.em_curso.size() if not _ex.em_curso.is_empty() else "Expedições"


func has_available_action() -> bool:
	return _ex.em_curso.any(func(e): return e.decisoes.any(func(d): return d.mostrada and String(d.escolha) == ""))
