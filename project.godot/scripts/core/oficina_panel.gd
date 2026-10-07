extends PanelContainer
## Janela da Oficina: fabricar ferramentas que liberam minérios novos.
## Criada pelo HUD (setup) e montada por código; usa os helpers de estilo do HUD.
## Abre clicando na oficina, pela tecla O ou pelo botão no painel do HUD.

const Ores := preload("res://scripts/core/ores.gd")

const Items := preload("res://scripts/core/items.gd")  # Bloco 87
const Icones := preload("res://scripts/ui/icones.gd")  # Bloco 94: o ícone de cada ferramenta e equipamento
const Tipo := preload("res://scripts/ui/tipografia.gd")
## Bloco 94: equipamento -> ícone (assets/game/ui/icones/it_*.png)
const ICONE_EQUIP := {"casaco": "it_casaco", "gas": "it_traje_gas", "calor": "it_traje_calor",
	"radiacao": "it_traje_radiacao", "botas": "it_botas"}
var _hud: CanvasLayer
var _oficina: Node
var _economy: Node
var _craft_label: Label
var _craft_bar: ProgressBar
var _rows: Dictionary = {}  # id -> {status, button}
var _eq_rows: Dictionary = {}  # Bloco 42: tipo -> {status, make, fix}
var _eq_queue: Label
var _vest_label: Label  # Bloco 44
var _vest_button: Button


func setup(hud: CanvasLayer, oficina: Node, economy: Node) -> void:
	_hud = hud
	_oficina = oficina
	_economy = economy
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
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("OFICINA", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.03))
	title.add_theme_constant_override("outline_size", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.tooltip_text = "Fechar (Esc / O)"
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)

	var intro: Label = _hud._label(
		"Ferramentas novas liberam minérios que antes não dava pra minerar. "
		+ "Uma por vez na forja; o custo é pago ao começar.", Tipo.DETALHE, _hud.COLOR_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)

	_craft_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	vbox.add_child(_craft_label)
	_craft_bar = _hud._bar(_hud.COLOR_CARGO)
	_craft_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_craft_bar.custom_minimum_size.y = 6
	vbox.add_child(_craft_bar)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("FERRAMENTAS", Tipo.DETALHE, _hud.COLOR_DIM))
	for id in _oficina.TOOL_IDS:
		_rows[id] = _make_tool_row(vbox, id)
	# Bloco 42: equipamento (vestiário da vila)
	var eq := get_tree().get_first_node_in_group("equipment") if _oficina.is_inside_tree() else null
	if eq:
		vbox.add_child(HSeparator.new())
		var hint: Label = _hud._label("EQUIPAMENTO — o vestiário da vila: cada um pega e devolve sozinho. Casaco no inverno; traje na zona de perigo.", Tipo.DETALHE, _hud.COLOR_DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(hint)
		_vest_label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
		_vest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(_vest_label)
		_vest_button = _hud._button("")
		_vest_button.pressed.connect(func():
			Audio.click()
			eq.build_vestiario()
			refresh())
		vbox.add_child(_vest_button)
		_eq_queue = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
		_eq_queue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(_eq_queue)
		for id in eq.TYPES:
			var row := HBoxContainer.new()
			vbox.add_child(row)
			var ic := _icone(ICONE_EQUIP.get(id, ""))
			if ic:
				row.add_child(ic)
			var st: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
			st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(st)
			var btns := VBoxContainer.new()
			row.add_child(btns)
			var make: Button = _hud._button("")
			make.add_theme_font_size_override("font_size", Tipo.DETALHE)
			make.custom_minimum_size.x = 190
			make.pressed.connect(func():
				Audio.click()
				eq.order(id)
				refresh())
			btns.add_child(make)
			var fix: Button = _hud._button("")
			fix.add_theme_font_size_override("font_size", Tipo.DETALHE)
			fix.pressed.connect(func():
				Audio.click()
				eq.repair(id)
				refresh())
			btns.add_child(fix)
			_eq_rows[id] = {"status": st, "make": make, "fix": fix}
	_monta_encomendas(vbox)


# ------------------------------------------------------------ encomendas do ferreiro (Bloco 87)
var _enc_status: Label
var _enc_linhas: Dictionary = {}  # receita -> {qtd, botao, info}
var _enc_fila: VBoxContainer
var _enc_qtd: Dictionary = {}


## Pregos e ferragens: receita, quantidade (+/-), Encomendar e a fila com Cancelar (só por ordem).
func _monta_encomendas(vbox: VBoxContainer) -> void:
	if _oficina.get("fila_ferreiro") == null:
		return
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hud._label("ENCOMENDAS DO FERREIRO", Tipo.TITULO, _hud.COLOR_TITLE))
	_enc_status = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	_enc_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_enc_status)
	for r in _oficina.receitas_ferreiro:
		var id: String = r.id
		_enc_qtd[id] = 5
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var info: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info)
		for passo in [-5, -1]:
			row.add_child(_botao_qtd(id, passo))
		var q: Label = _hud._label("", Tipo.TITULO, _hud.COLOR_TITLE)
		q.custom_minimum_size.x = 28
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(q)
		for passo in [1, 5]:
			row.add_child(_botao_qtd(id, passo))
		var b: Button = _hud._button("Encomendar")
		b.add_theme_font_size_override("font_size", Tipo.DETALHE)
		b.pressed.connect(func():
			_oficina.encomendar(id, int(_enc_qtd[id]))
			refresh())
		row.add_child(b)
		_enc_linhas[id] = {"qtd": q, "botao": b, "info": info}
	_enc_fila = VBoxContainer.new()
	vbox.add_child(_enc_fila)


func _botao_qtd(id: String, passo: int) -> Button:
	var b: Button = _hud._button(("%+d" % passo) if absi(passo) > 1 else ("+" if passo > 0 else "−"))
	b.add_theme_font_size_override("font_size", Tipo.DETALHE)
	b.custom_minimum_size = Vector2(26, 0)
	b.pressed.connect(func():
		Audio.click()
		_enc_qtd[id] = clampi(int(_enc_qtd.get(id, 5)) + passo, 1, _oficina.fila_ferreiro.max_quantidade)
		refresh())
	return b


func _refresh_encomendas() -> void:
	if _enc_status == null:
		return
	var fila = _oficina.fila_ferreiro
	var smiths := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.has_method("is_smith") and w.is_smith()).size()
	var falta: String = _oficina.falta_encomenda()
	_enc_status.text = "Pregos e ferragens só por ORDEM. O FERREIRO faz (ferreiros: %d%s). Os insumos saem do armazém quando cada unidade começa; o produto vai pro armazém.%s" % [
		smiths, " — dê a função Ferreiro a alguém, tecla 7" if smiths == 0 else "", ("\nPAUSADA: " + falta) if falta != "" else ""]
	var hub := get_tree().get_first_node_in_group("village_hub")
	var lvl: int = int(hub.level) if hub else 1
	for id in _enc_linhas:
		var l: Dictionary = _enc_linhas[id]
		var r: Dictionary = fila.receita(id)
		var q := int(_enc_qtd.get(id, 5))
		l.qtd.text = str(q)
		var motivo: String = fila.motivo_encomenda(id, q, lvl)
		var produto: String = ", ".join(r.produto.keys().map(func(k): return "%d %s" % [int(r.produto[k]), Items.plural(k)]))
		l.info.text = "%s: %s -> %s (%ds)%s" % [r.get("nome", id), fila.texto_insumos(id), produto, int(r.get("segundos", 8)), ("  — " + motivo) if motivo != "" else ""]
		l.botao.disabled = motivo != ""
	for c in _enc_fila.get_children():
		_enc_fila.remove_child(c)
		c.queue_free()
	for i in fila.fila.size():
		var row := HBoxContainer.new()
		_enc_fila.add_child(row)
		var txt := "%d. %s" % [i + 1, fila.texto_ordem(i)]
		if i == 0 and fila.comecadas() > 0:
			txt += "  —  %d%% da unidade" % roundi(fila.progresso_unidade() * 100.0)
		var lb: Label = _hud._label(txt, Tipo.DETALHE, _hud.COLOR_TEXT)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lb)
		var cancel: Button = _hud._button("Cancelar")
		cancel.add_theme_font_size_override("font_size", Tipo.DETALHE)
		cancel.pressed.connect(func():
			_oficina.cancelar(i)
			refresh())
		row.add_child(cancel)


func _make_tool_row(parent: VBoxContainer, id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud._row_style(false))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var ic := _icone("it_" + id)
	if ic:
		top.add_child(ic)
	var name_label: Label = _hud._label(_oficina.TOOL_NAMES[id], Tipo.TITULO, _hud.COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var status: Label = _hud._label("", Tipo.DETALHE, _hud.COLOR_DIM)
	top.add_child(status)

	var ore: String = _oficina.TOOL_UNLOCKS.get(id, "")
	var unlock: Label = _hud._label("Libera: %s" % _oficina.unlock_label(id), Tipo.DETALHE, Ores.UI_COLORS.get(ore, _hud.COLOR_TEXT))
	v.add_child(unlock)
	var desc: Label = _hud._label(_oficina.TOOL_DESCRIPTIONS[id], Tipo.DETALHE, _hud.COLOR_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	v.add_child(bottom)
	var cost: Vector3i = _oficina.tool_cost(id)
	var cost_label: Label = _hud._label("%s  •  %ds  •  vila nível %d" % [_oficina.tool_cost_text(id), cost.z, _oficina.tool_stage(id)],
		Tipo.DETALHE, _hud.COLOR_TEXT)  # Bloco 94: tool_cost_text (a picareta de aço leva aço)
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cost_label)
	var button: Button = _hud._button("Fabricar")
	button.custom_minimum_size.x = 140
	button.pressed.connect(func():
		Audio.click()
		_oficina.start_tool(id)
		refresh())
	bottom.add_child(button)
	return {"status": status, "button": button}


## Bloco 94: o ícone (28 px) de uma ferramenta/equipamento; null = sem ícone.
func _icone(nome: String) -> TextureRect:
	var tex: Texture2D = Icones.tex(nome) if nome != "" else null
	if tex == null:
		return null
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(28, 28)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r


## Bloco 58: Oficina ainda não construída: a janela mostra só o construir.
var _build_box: VBoxContainer
var _build_info: Label
var _build_button: Button


func _ensure_build_box() -> void:
	if _build_box != null:
		return
	var vbox: Node = get_child(0)
	if vbox is ScrollContainer:
		vbox = vbox.get_child(0)
	_build_box = VBoxContainer.new()
	_build_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_build_box)
	vbox.move_child(_build_box, 1)
	_build_info = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	_build_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_box.add_child(_build_info)
	_build_button = _hud._button("")
	_build_button.pressed.connect(func():
		Audio.click()
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub and hub.build_oficina():
			visible = false
		else:
			Audio.error())
	_build_box.add_child(_build_button)


func refresh() -> void:
	if not visible or _oficina == null:
		return
	_ensure_build_box()
	var built: bool = not _oficina.has_method("is_built") or _oficina.is_built()
	var vbox: Node = _build_box.get_parent()
	for i in vbox.get_child_count():
		var ch: Node = vbox.get_child(i)
		if i == 0:
			continue  # cabeçalho
		ch.visible = (ch == _build_box) != built
	if not built:
		var hub := get_tree().get_first_node_in_group("village_hub")
		var r: String = hub.oficina_block_reason() if hub else "sem Centro da Vila"
		_build_info.text = "A vila ainda não tem Oficina. Construa uma (o engenheiro ergue) pra forjar ferramentas e equipamento."
		_build_button.text = ("Construir a Oficina — escolher o lugar  (%s)" % hub.oficina_cost_text()) if r == "" else "Construir a Oficina: %s" % r
		_build_button.disabled = r != ""
		return
	var busy: String = _oficina.crafting
	_craft_label.visible = busy != ""
	_craft_bar.visible = busy != ""
	if busy != "":
		if _oficina.obra_workers().is_empty():
			_craft_label.text = "%s: esperando engenheiro (tecla 4)  —  %ds de trabalho" % [_oficina.TOOL_NAMES[busy], ceili(_oficina.craft_left)]
		else:
			_craft_label.text = "Forjando: %s  —  faltam %ds" % [_oficina.TOOL_NAMES[busy], ceili(_oficina.craft_left)]
		_craft_bar.max_value = 1.0
		_craft_bar.value = _oficina.craft_progress()

	for id in _rows:
		var row: Dictionary = _rows[id]
		var reason: String = _oficina.tool_block_reason(id)
		var status: Label = row.status
		var button: Button = row.button
		match reason:
			"pronta":
				status.text = "pronta"
				status.add_theme_color_override("font_color", _hud.COLOR_HUNGER_OK)
				button.text = "Pronta"
			"fabricando":
				status.text = ("forjando %d%%" if not _oficina.obra_workers().is_empty() else "esperando engenheiro %d%%") % roundi(_oficina.craft_progress() * 100.0)
				status.add_theme_color_override("font_color", _hud.COLOR_TITLE)
				button.text = "Forjando..."
			"":
				status.text = "disponível"
				status.add_theme_color_override("font_color", _hud.COLOR_TEXT)
				button.text = "Fabricar"
			_:
				status.text = reason
				status.add_theme_color_override("font_color", _hud.COLOR_DIM)
				button.text = "Fabricar"
		button.disabled = reason != ""
	_refresh_equipment()
	_refresh_encomendas()  # Bloco 87


func _refresh_equipment() -> void:
	var eq := get_tree().get_first_node_in_group("equipment")
	if eq == null or _eq_queue == null:
		return
	var has_vest: bool = eq.vestiario() != null
	var vr: String = eq.vestiario_block_reason()
	_vest_label.text = "Vestiário: construído — casacos e trajes ficam lá." if has_vest else \
		"SEM VESTIÁRIO: não dá pra fazer nem pegar casaco/traje (não tem onde guardar)."
	_vest_label.add_theme_color_override("font_color", _hud.COLOR_TEXT if has_vest else _hud.COLOR_HUNGER_BAD)
	_vest_button.visible = not has_vest
	_vest_button.text = ("Construir Vestiário — escolher lugar  (%d cr + %d ferro + %d madeira)" % [eq.vestiario_credits, eq.vestiario_ore, eq.vestiario_wood]) \
		if vr == "" else "Vestiário: " + vr
	_vest_button.disabled = vr != ""
	_eq_queue.visible = eq.pending()
	if eq.pending():
		var eng: bool = not _oficina.obra_workers().is_empty()
		_eq_queue.text = "Fila: %s — %d%%%s%s" % [eq.title(), roundi(eq.progress() * 100.0),
			"" if eng else "  (esperando engenheiro — tecla 4)", "  •  +%d na fila" % (eq.queue.size() - 1) if eq.queue.size() > 1 else ""]
	for id in _eq_rows:
		var row: Dictionary = _eq_rows[id]
		var extra := ""
		if id == "casaco":
			extra = "  •  faz %d por vez; sem casaco no inverno trabalha a %d%%" % [eq.coat_batch, roundi(eq.cold_work_mult * 100.0)]
		elif id == "botas":  # Bloco 94
			extra = "  •  sem botas, na neve, anda a %d%%" % roundi(eq.neve_speed_mult * 100.0)
		else:
			extra = "  •  pra entrar no %s" % eq.ZONE_NAMES[id].to_lower()
		row.status.text = "%s: %d no vestiário, %d em uso, %d quebrado%s%s" % [eq.NAMES[id], eq.available(id), eq.in_use(id), eq.broken_count(id),
			"s" if eq.broken_count(id) != 1 else "", extra]
		var r: String = eq.order_block_reason(id)
		row.make.text = ("Fazer  (%s)" % eq.cost_text(eq.cost(id), id)) if r == "" else (r.substr(0, 1).to_upper() + r.substr(1))
		row.make.disabled = r != ""
		var fr: String = eq.repair_block_reason(id)
		row.fix.visible = eq.broken_count(id) > 0
		row.fix.text = ("Consertar  (%s)" % eq.cost_text(eq.repair_cost(id), id)) if fr == "" else "Consertar: " + fr
		row.fix.disabled = fr != ""


func button_text() -> String:
	if _oficina.has_method("is_built") and not _oficina.is_built():
		return "Oficina: construir (O)"
	if _oficina.crafting != "":
		return "Oficina %d%%%s (O)" % [roundi(_oficina.craft_progress() * 100.0), "" if not _oficina.obra_workers().is_empty() else " sem eng."]
	var done := 0
	for id in _oficina.TOOL_IDS:
		if _oficina.has_tool(id):
			done += 1
	return "Oficina %d/%d (O)" % [done, _oficina.TOOL_IDS.size()]


func has_available_action() -> bool:
	if _oficina.has_method("is_built") and not _oficina.is_built():
		return false
	for id in _oficina.TOOL_IDS:
		if _oficina.tool_block_reason(id) == "":
			return true
	return false
