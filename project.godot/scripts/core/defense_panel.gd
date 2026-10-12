extends PanelContainer
## Janela de Defesa (tecla G, ou clique numa barricada): a VISÃO GERAL — próxima invasão e previsão, tier das criaturas,
## portão (estado e melhorias), postos dos guardas e patrulhas do fundo.
## Bloco 35: a arma + durabilidade de cada guarda (desarmado em destaque).
## Bloco 128: o Arsenal (forja, cavalete, armas) e o campo de treino ganharam a janela de cada um (arsenal_panel.gd,
## campo_panel.gd): aqui só os links. Construir campo/Arsenal é só no menu CONSTRUIR (Espaço).
## Bloco 103: o BESTIÁRIO (as espécies que já apareceram: "???" sem estudo, a ficha curta com o estudo), a PREVISÃO da
## próxima invasão (tipos e quantidades; espécie sem estudo vira "???") e a PATRULHA do fundo (quantos guardas descem
## caçar os moradores de cada andar, de dia).
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Catalogo := preload("res://scripts/core/catalogo.gd")

var _hud: CanvasLayer
var _def: Node
var _status: Label
var _gate_rows: Dictionary = {}  # gate_id -> {label, up, fix}
var _poco_label: Label
var _guards_label: Label
var _links: HBoxContainer  # Bloco 128: abrir a janela do Arsenal / do campo de treino
var _arsenal_link: Button
var _campo_link: Button
var _cri_box: VBoxContainer
var _tier_label: Label  # Bloco 113: o tier das criaturas e o que o faz subir
var _dif_label: Label  # Bloco 113: a dificuldade da partida
var _cri_sig := ""
var _patrulha_rows := {}  # andar -> {label, qtd}


func setup(hud: CanvasLayer, def: Node, _economy: Node) -> void:
	_hud = hud
	_def = def
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(500, 0)
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
	var title: Label = _hud._label("DEFESA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_status = _hud._label("", Tipo.TITULO, _hud.COLOR_TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status)

	# Bloco 103: o bestiário e a patrulha do fundo
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("CRIATURAS (estude os corpos: Catálogo, R)", Tipo.DETALHE, _hud.COLOR_DIM))
	_tier_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_tier_label.name = "Tier"
	_tier_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_tier_label)
	_dif_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_dif_label.name = "Dificuldade"
	_dif_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_dif_label)
	_cri_box = VBoxContainer.new()
	_cri_box.name = "Bestiario"
	_cri_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_cri_box)
	for andar in ["S2", "S3"]:
		var row := HBoxContainer.new()
		row.name = "Patrulha_" + andar
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var l: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(l)
		for passo in [-1, 1]:
			var b: Button = _hud._button("−" if passo < 0 else "+")
			b.name = "Menos" if passo < 0 else "Mais"
			b.add_theme_font_size_override("font_size", Tipo.DETALHE)
			b.custom_minimum_size = Vector2(28, 0)
			b.pressed.connect(func():
				Audio.click()
				_muda_patrulha(andar, passo))
			row.add_child(b)
		_patrulha_rows[andar] = {"label": l, "row": row}

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("MURO (o que vem da floresta precisa derrubar pra entrar)", Tipo.DETALHE, _hud.COLOR_DIM))
	for id in ["tunel"]:  # Bloco 80: o único portão (o do poço saiu)
		var l: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
		vbox.add_child(l)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var up: Button = _hud._button("")
		up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		up.add_theme_font_size_override("font_size", Tipo.DETALHE)
		up.pressed.connect(func():
			Audio.click()
			var g: Node = _def.gate(id)
			if g:
				g.upgrade()
			refresh())
		row.add_child(up)
		var fix: Button = _hud._button("")
		fix.add_theme_font_size_override("font_size", Tipo.DETALHE)
		fix.custom_minimum_size.x = 150
		fix.pressed.connect(func():
			Audio.click()
			var g: Node = _def.gate(id)
			if g:
				g.repair()
			refresh())
		row.add_child(fix)
		_gate_rows[id] = {"label": l, "up": up, "fix": fix}
	_poco_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)  # Bloco 80: o poço não tem muro
	_poco_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_poco_label)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("POSTOS — quem está onde", Tipo.DETALHE, _hud.COLOR_DIM))
	_guards_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	_guards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_guards_label)
	# Bloco 128: o que o Arsenal e o campo fazem tem janela própria (aqui só o atalho)
	_links = HBoxContainer.new()
	_links.add_theme_constant_override("separation", 4)
	vbox.add_child(_links)
	_arsenal_link = _hud._button("")
	_arsenal_link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_arsenal_link.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_arsenal_link.pressed.connect(func():
		Audio.click()
		_hud.open_panel("arsenal", _def.arsenal()))
	_links.add_child(_arsenal_link)
	_campo_link = _hud._button("")
	_campo_link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campo_link.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_campo_link.pressed.connect(func():
		Audio.click()
		var cs := get_tree().get_nodes_in_group("campos")
		_hud.open_panel("campo", cs[0] if not cs.is_empty() else null))
	_links.add_child(_campo_link)


## Bloco 103: mais ou menos guardas na patrulha de um andar (andar não reconhecido: pergunta antes).
func _muda_patrulha(andar: String, passo: int) -> void:
	var n := clampi(int(_def.patrulhas.get(andar, 0)) + passo, 0, _def.guards().size())
	var faz := func():
		_def.pede_patrulha(andar, n)
		refresh()
	var cat := get_tree().get_first_node_in_group("catalogo")
	if passo > 0 and cat and not cat.reconhecido(andar) and not cat.descida_liberada.has(andar):
		var c: Array = Catalogo.entrada(andar).get("pos", [])
		if c.size() >= 2 and _hud.pergunta_descida(Vector2(float(c[0]), float(c[1])), faz):
			return
	faz.call()


## Bloco 113: o TIER das criaturas (de onde vem, o que faz subir e o que ele muda) e a dificuldade da partida.
func _refresh_tier() -> void:
	var t: Dictionary = _def.tier_detalhe()
	var faltam: int = int(t.prox_pesquisas)
	var elite := "os fortes já vêm como ELITE" if int(t.tier) >= int(_def.elite_from_tier) \
		else "no tier %d os fortes viram ELITE" % int(_def.elite_from_tier)
	_tier_label.text = ("TIER %d das criaturas  =  1 base  +  %d pela onda (onda %d)  +  %d pelas pesquisas (%d feitas)\n"
		+ "Sobe de novo na onda %d ou com mais %d pesquisa%s. Cada tier acima do 1: +%d%% de vida e o forte vem mais vezes; %s.") % [
		int(t.tier), int(t.da_onda), _def.wave, int(t.das_pesquisas), int(t.pesquisas), int(t.prox_onda), faltam,
		"s" if faltam != 1 else "", roundi(_def.tier_hp_bonus * 100.0), elite]
	var dif := get_tree().get_first_node_in_group("dificuldade")
	if dif == null:
		_dif_label.text = ""
	elif _def.sem_invasao():
		_dif_label.text = "Dificuldade %s: sem invasões nesta partida." % dif.nome()
	else:
		_dif_label.text = "Dificuldade %s: 1ª invasão no dia %d, depois a cada %d dias; as criaturas ganham +%d%% de vida por onda." % [
			dif.nome(), _def.first_invasion_day, _def.invasion_every, roundi(_def.hp_growth * 100.0)]


## Bloco 103: o bestiário e a previsão (remonta só quando muda).
func _refresh_bestiario() -> void:
	var cat := get_tree().get_first_node_in_group("catalogo")
	var comp: Dictionary = _def.composicao(_def.wave + (0 if _def.invasion_active else 1))
	var sig := "%s|%s" % [comp, cat.estados if cat else {}]
	for andar in _patrulha_rows:
		sig += "|%s%d%d" % [andar, int(_def.patrulhas.get(andar, 0)), _def.moradores(andar).size()]
	if sig == _cri_sig:
		return
	_cri_sig = sig
	for c in _cri_box.get_children():
		_cri_box.remove_child(c)
		c.queue_free()
	var prev: Label = _hud._label("Previsão da próxima invasão: %s." % _def.texto_onda(comp), Tipo.DETALHE, Color(1.0, 0.85, 0.5))
	prev.name = "Previsao"
	prev.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cri_box.add_child(prev)
	for id in ["lumivoro", "ferrugento", "gosma", "magmante", "matriarca"]:
		var est: int = cat.estado(id) if cat else Catalogo.ESTUDADO
		if est == Catalogo.DESCONHECIDO:
			continue  # (ainda não apareceu)
		var row := HBoxContainer.new()
		row.name = "Especie_" + id
		row.add_theme_constant_override("separation", 6)
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(40, 40)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.texture = Catalogo.icone(id)
		if est != Catalogo.ESTUDADO:
			ic.modulate = Color(0, 0, 0, 0.85)
		row.add_child(ic)
		var txt := "???  — ainda não estudada (um corpo no chão, a pesquisadora estuda)"
		if est == Catalogo.ESTUDADO:
			var f: Array = cat.ficha(id)
			var curto: Array[String] = ["%s  (perigo %d/5)" % [Catalogo.nome(id), cat.perigo(id)]]
			for linha in f:
				if String(linha[0]) in ["Fraqueza", "Deixa", "Dica"]:
					curto.append("%s: %s" % [linha[0], linha[1]])
			txt = "\n".join(curto)
		var l: Label = _hud._label(txt, Tipo.DETALHE, _hud.COLOR_TEXT if est == Catalogo.ESTUDADO else _hud.COLOR_DIM)
		l.name = "Texto"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 400
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		_cri_box.add_child(row)
	for andar in _patrulha_rows:
		var nv: Resource = preload("res://scripts/core/niveis.gd").por_id(andar)
		var aberto: bool = nv != null and preload("res://scripts/core/niveis.gd").liberado(get_tree(), nv)
		var r: Dictionary = _patrulha_rows[andar]
		r.row.visible = aberto
		var vivos: int = _def.moradores(andar).size()
		var quem: String = "moradores" if cat == null else ", ".join(PackedStringArray(_def.moradores(andar).map(func(c): return Catalogo.nome(c.kind) if cat.estudado(c.kind) else "???")))
		r.label.text = "Patrulha no %s: %d guarda%s (de dia descem caçar)  •  %s" % [andar, int(_def.patrulhas.get(andar, 0)),
			"s" if int(_def.patrulhas.get(andar, 0)) != 1 else "", ("vivos lá: %s" % quem) if vivos > 0 else "ninguém vivo lá agora"]


func refresh() -> void:
	if not visible:
		return
	_refresh_bestiario()  # Bloco 103
	_refresh_tier()  # Bloco 113
	var dn := get_tree().get_first_node_in_group("day_night")
	if _def.invasion_active:
		_status.text = "INVASÃO EM ANDAMENTO (onda %d): %d criaturas, %d já dentro da vila, %d derrubadas." % [
			_def.wave, _def.creatures().size(), _def.creatures_inside(), _def.killed_tonight]
		_status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD)
	else:
		var nd: int = _def.next_invasion_day()
		var today: bool = dn != null and nd == dn.day and not dn.is_night()
		_status.text = ("Sem invasões nesta partida (dificuldade Criativo)." if nd < 0 else "Próxima invasão: HOJE À NOITE!" if today else "Próxima invasão: noite do dia %d" % nd) \
			+ ("  •  Ferrugentos também (o nível 2 está aberto)" if _def.level2_open() else "")  # (Bloco 103: a previsão vem embaixo)
		_status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD if today else _hud.COLOR_TEXT)

	for id in _gate_rows:
		var row: Dictionary = _gate_rows[id]
		var g: Node = _def.gate(id)
		if g == null:
			continue
		var name_lvl: String = g.LEVEL_NAMES[g.level]
		var hp_txt := "" if g.level == 0 else "  •  vida %d/%d" % [roundi(g.hp), roundi(g.max_hp())]
		row.label.text = "%s: %s%s" % [g.display_name, name_lvl, hp_txt]
		var up_reason: String = g.upgrade_block_reason()
		if up_reason == "nível máximo":
			row.up.text = "Máximo"
		elif up_reason == "":
			var c: Vector3i = g.upgrade_costs[g.level + 1]
			row.up.text = "Construir %s (%s)" % [g.LEVEL_NAMES[g.level + 1].split(" ")[0].to_lower(), _cost_text(c, g.upgrade_ore[g.level + 1], g.upgrade_item_cost())]
		else:
			row.up.text = "Ampliar: " + up_reason
		row.up.disabled = up_reason != ""
		var fix_reason: String = g.repair_block_reason()
		row.fix.visible = g.level > 0
		row.fix.text = "Consertar (%d madeira)" % g.repair_cost() if fix_reason == "" else ("Inteiro" if fix_reason == "inteiro" else "Consertar: " + fix_reason)
		row.fix.disabled = fix_reason != ""

	_poco_label.text = ("Poço do elevador: SEM MURO — os Ferrugentos (robôs enferrujados) saem direto da boca do poço. "
		+ "Metade dos guardas faz posto lá. (A Gosma e o Magmante moram no andar deles: não sobem.)") if _def.level2_open() \
		else "Poço do elevador: fechado (os Ferrugentos só saem dele depois que o nível 2 abre)."
	var gs: Array = _def.guards()
	var ready_n := gs.filter(func(w): return w.combat_skill >= 1.0).size()
	var unarmed: Array = _def.unarmed_guards()
	var lines: Array[String] = ["Guardas: %d (%d treinados)%s  •  X faz guarda. De dia treinam no campo; à noite ficam fora do portão (e no poço, com o nível 2 aberto)." % [
		gs.size(), ready_n, ("  •  %d DESARMADO%s" % [unarmed.size(), "S" if unarmed.size() > 1 else ""]) if not unarmed.is_empty() else ""]]
	for w in gs:
		var onde: String = _onde_esta(w)
		if w.downed:  # Bloco 36
			lines.append("  • %s: CAÍDO no %s — %s" % [w.display_name, _def.gate_label(w.downed_gate),
				"sendo levado pra enfermaria" if w._carried_by != null else "só o médico resgata (morre em %ds)" % ceili(w._care_left)])
		elif w.weapon == "":
			lines.append("  • %s: DESARMADO — %s" % [w.display_name,
				"indo ao Arsenal" if w.get_state() == "rearming" else ("sem Arsenal, luta no soco" if _def.arsenal() == null else "vai ao Arsenal")])
		else:
			lines.append("  • %s: %s%s  —  %s" % [w.display_name, w.weapon_label(), "  (gasta!)" if w.weapon_condition() < 0.25 else "", onde])
	_guards_label.text = "\n".join(lines)
	_guards_label.add_theme_color_override("font_color", _hud.COLOR_HUNGER_BAD if not unarmed.is_empty() or not _def.downed_guards().is_empty() else _hud.COLOR_TEXT)
	# Bloco 128: os atalhos (as janelas do Arsenal e do campo existem só com o prédio construído)
	var ars: Node = _def.arsenal()
	var n_campos: int = _def.campos().size()
	_arsenal_link.visible = ars != null
	_arsenal_link.text = "Arsenal: forja e armas (%d no cavalete)" % _def.rack_total()
	_campo_link.visible = n_campos > 0
	_campo_link.text = "Campo de treino: %d treinando" % gs.filter(func(w): return w.get_state() == "training").size()
	_links.visible = ars != null or n_campos > 0


## Bloco 128: onde o guarda está agora, em palavras (o posto dele).
func _onde_esta(w: Node) -> String:
	match String(w.get_state()):
		"guard":
			return "de vigia fora do portão" if _def.has_method("guard_post_ativo") else "de vigia no portão"
		"training":
			return "treinando no campo"
		"patrulha":
			return "patrulha do fundo"
		"rearming":
			return "buscando arma no Arsenal"
		"home":
			return "descansando"
	return w.get_state_label()


## Bloco 87: o metal sai em barra a partir do estágio da fornalha (Economy.custo_metal_texto).
func _cost_text(c: Vector3i, ore: String, itens: Dictionary = {}) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco:
		return eco.custo_metal_texto(c.x, c.y, ore, c.z, itens)  # Bloco 94: + itens (o aço, os pregos)
	var bits: Array[String] = []
	if c.x > 0:
		bits.append("%d cr" % c.x)
	if c.y > 0:
		bits.append("%d %s" % [c.y, ore if ore != "" else "minério"])
	if c.z > 0:
		bits.append("%d madeira" % c.z)
	return " + ".join(bits)


func button_text() -> String:
	var un: int = _def.unarmed_guards().size()
	var tail := "  •  %d desarmado%s" % [un, "s" if un > 1 else ""] if un > 0 else ""
	if _def.invasion_active:
		return "INVASÃO! (G)" + tail
	var dn := get_tree().get_first_node_in_group("day_night")
	var nd: int = _def.next_invasion_day()
	if nd < 0:
		return "Defesa (G)" + tail  # Bloco 113: Criativo, sem invasões
	if dn and nd == dn.day:
		return "Defesa: HOJE (G)" + tail
	return "Defesa: dia %d (G)" % nd + tail


func has_available_action() -> bool:
	var dn := get_tree().get_first_node_in_group("day_night")
	return _def.invasion_active or (dn != null and _def.next_invasion_day() == dn.day)
