extends VBoxContainer
## Bloco 136: a seção PESQUISA da ficha do pesquisador. Mostra o que ele está fazendo agora (a pesquisa do laboratório
## com a % e o tempo que falta, ou o estudo de campo), a FILA (pesquisas e estudos encomendados, cada um com Cancelar) e
## o que dá pra mandar estudar: as entradas do Catálogo que a vila avistou (minerais, animais, criaturas — o corpo no
## chão aparece como "pronta para estudar" — e lugares) e as pesquisas do Laboratório, com custo e tempo. Nada começa
## sozinho: só o botão Pesquisar (research.pede / catalogo.pede_estudo), como as ordens de produção.

const Tipo := preload("res://scripts/ui/tipografia.gd")

var _hud: CanvasLayer
var _w: Node
var _agora: Label
var _barra: ProgressBar
var _corpo: VBoxContainer
var _assinatura := ""


func setup(hud: CanvasLayer) -> void:
	_hud = hud
	name = "Pesquisa"
	add_theme_constant_override("separation", 4)
	add_child(_hud._label("PESQUISA", Tipo.TITULO, _hud.COLOR_TITLE))
	_agora = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	_agora.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_agora)
	_barra = _hud._bar(Color(0.55, 0.75, 1.0))
	_barra.custom_minimum_size = Vector2(0, 8)
	add_child(_barra)
	_corpo = VBoxContainer.new()
	_corpo.add_theme_constant_override("separation", 3)
	add_child(_corpo)


func _res() -> Node:
	return get_tree().get_first_node_in_group("research")


func _cat() -> Node:
	return get_tree().get_first_node_in_group("catalogo")


func _sph() -> float:
	var dn := get_tree().get_first_node_in_group("day_night")
	return maxf(float(dn.segundos_por_hora()), 0.001) if dn else 30.0


## Segundos reais -> "~N h de jogo" (ou minutos, se for pouco).
func _horas(seg: float) -> String:
	if seg == INF:
		return "parada (ninguém no laboratório)"
	var h := seg / _sph()
	if h < 1.0:
		return "menos de 1 h de jogo"
	return "~%d h de jogo" % roundi(h)


func mostra(w: Node) -> void:
	_w = w
	_assinatura = ""
	refresh()


func refresh() -> void:
	if _w == null or not is_instance_valid(_w) or not is_inside_tree():
		return
	var res := _res()
	var cat := _cat()
	_agora.text = agora_texto()
	_barra.visible = res != null and String(res.current) != ""
	if _barra.visible:
		_barra.value = float(res.current_progress()) * 100.0
	var ass := _assina(res, cat)
	if ass != _assinatura:
		_assinatura = ass
		_refaz(res, cat)


## O que ESTE pesquisador está fazendo agora (e a pesquisa do laboratório, se houver).
func agora_texto() -> String:
	var res := _res()
	var cat := _cat()
	var st := String(_w.get_state()) if _w.has_method("get_state") else ""
	var linhas: Array = []
	if st == "research" and res and String(res.current) != "":
		linhas.append("No laboratório: %s — %d%% (falta %s)" % [res.TECHS[res.current].name, roundi(res.current_progress() * 100.0), _horas(res.tempo_restante())])
	elif st == "catalogando" and cat:
		var id := String(_w.get("nota_campo"))
		if id == "":
			id = String((_w.get("_campo") as Dictionary).get("id", "")) if _w.get("_campo") is Dictionary else ""
		linhas.append(("Estudando no campo: %s" % cat.nome(id)) if id != "" else "Saindo pro estudo de campo")
	else:
		linhas.append("Agora: %s" % (String(_w.get_state_label()) if _w.has_method("get_state_label") else st))
		if res and String(res.current) != "":
			linhas.append("Pesquisa do laboratório: %s — %d%% (falta %s)" % [res.TECHS[res.current].name, roundi(res.current_progress() * 100.0), _horas(res.tempo_restante())])
	if (res == null or String(res.current) == "") and (cat == null or cat.fila_estudo.is_empty()):
		linhas.append("Sem ordem: escolha abaixo o que pesquisar (nada começa sozinho).")
	elif res and res.motivo_fila() != "":
		linhas.append("A próxima da fila espera: %s" % res.motivo_fila())
	return "\n".join(linhas)


func _assina(res: Node, cat: Node) -> String:
	var p: Array = []
	if res:
		p.append(String(res.current))
		p.append(",".join(res.fila))
		for id in res.ORDER:
			p.append(res.motivo_pedido(id))
	if cat:
		p.append(",".join(cat.fila_estudo))
		for id in cat.estudaveis():
			p.append(id + ":" + cat.situacao(id))
	return "|".join(p)


func _refaz(res: Node, cat: Node) -> void:
	for c in _corpo.get_children():
		c.queue_free()
	# a fila (o laboratório + o campo)
	var fila: Array = []
	if res:
		if String(res.current) != "":
			fila.append(["lab_atual", String(res.current), "Pesquisando: %s" % res.TECHS[res.current].name])
		for id in res.fila:
			fila.append(["lab", String(id), "Pesquisa: %s" % res.TECHS[id].name])
	if cat:
		for id in cat.fila_estudo:
			var quem: Node = cat.reservado_por(String(id))
			fila.append(["campo", String(id), "Estudo: %s%s" % [cat.nome(String(id)), (" (%s vai)" % _hud._worker_name(quem)) if quem else ""]])
	_corpo.add_child(_hud._label("FILA (%d)" % fila.size(), Tipo.DETALHE, _hud.COLOR_DIM))
	if fila.is_empty():
		_corpo.add_child(_hud._label("   vazia", Tipo.DETALHE, _hud.COLOR_DIM))
	for f in fila:
		var h := HBoxContainer.new()
		var l: Label = _hud._label(String(f[2]), Tipo.DETALHE, _hud.COLOR_TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(l)
		var b: Button = _hud._button("Cancelar")
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.tooltip_text = "Para e devolve o custo (o progresso se perde)." if f[0] == "lab_atual" else "Tira da fila."
		var tipo := String(f[0])
		var id := String(f[1])
		b.pressed.connect(func():
			Audio.click()
			if tipo == "campo":
				cat.cancela_estudo(id)
			else:
				res.cancela(id)
			_assinatura = ""
			refresh())
		h.add_child(b)
		_corpo.add_child(h)
	# o catálogo: o que a vila avistou
	if cat:
		var ids: Array = cat.estudaveis()
		_corpo.add_child(_hud._label("PARA ESTUDAR — CATÁLOGO (%d)" % ids.size(), Tipo.DETALHE, _hud.COLOR_DIM))
		if ids.is_empty():
			_corpo.add_child(_hud._label("   nada avistado esperando estudo (o batedor e quem anda pelo mapa avistam)", Tipo.DETALHE, _hud.COLOR_DIM))
		for id in ids:
			var nome_cat: String = String(cat.NOMES_CATEGORIA.get(String(cat.entrada(id).categoria), ""))
			var motivo: String = cat.motivo_estudo(id)
			var txt := "%s  (%s)\n%s • %s" % [cat.nome(id), nome_cat.to_lower(), cat.situacao(id), cat.tempo_texto(id)]
			_linha(txt, motivo, func(): return cat.pede_estudo(id), id)
	# o laboratório: a árvore
	if res:
		var disp: Array = res.ORDER.filter(func(id): return not res.has(id) and id != res.current and not res.fila.has(id) and not String(res.motivo_pedido(id)).begins_with("caminho fechado"))
		_corpo.add_child(_hud._label("PESQUISAS DO LABORATÓRIO (%d)" % disp.size(), Tipo.DETALHE, _hud.COLOR_DIM))
		var n: int = maxi(res.researchers().size(), 1)
		for id in disp:
			var t: Dictionary = res.TECHS[id]
			var c: Vector3i = t.cost
			var bits: Array[String] = []
			if c.x > 0:
				bits.append("%d cr" % c.x)
			if c.y > 0:
				bits.append("%d %s" % [c.y, t.ore])
			if c.z > 0:
				bits.append("%d madeira" % c.z)
			var tempo := _horas(float(t.points) / (res.points_per_researcher * n))
			var txt := "%s  (%s)\n%s • %d pontos, %s com %d pesquisador%s" % [t.name, t.branch, " + ".join(bits) if not bits.is_empty() else "sem custo",
				t.points, tempo, n, "es" if n > 1 else ""]
			_linha(txt, res.motivo_pedido(id), func(): return res.pede(id), id)


func _linha(txt: String, motivo: String, acao: Callable, id: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l: Label = _hud._label(txt, Tipo.DETALHE, _hud.COLOR_TEXT if motivo == "" else _hud.COLOR_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	var b: Button = _hud._button("Pesquisar")
	b.name = "Pesquisar_" + id
	b.add_theme_font_size_override("font_size", Tipo.DETALHE)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = motivo != ""
	b.tooltip_text = motivo if motivo != "" else "Manda pesquisar (entra na fila se já houver outra)."
	b.pressed.connect(func():
		if acao.call():
			Audio.ui("confirmar")
		else:
			Audio.error()
		_assinatura = ""
		refresh())
	h.add_child(b)
	_corpo.add_child(h)
