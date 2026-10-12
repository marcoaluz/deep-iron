extends PanelContainer
## Bloco 128: o CARTÃO DE REQUISITOS da função. Aparece ao dar uma função (main.toggle_job) e lista, com ✓/✗, o que
## ela precisa pra ter trabalho ("✗ Falta o arco: a Oficina faz", "✗ Construa a horta: CONSTRUIR > Alimentação"). Os
## requisitos vêm de dados (requisitos_funcao.gd). O cartão confere de novo a cada meio segundo enquanto está aberto
## (o ✗ vira ✓ quando o jogador resolve) e some sozinho; fecha no clique, no Esc ou ao dar outra função.

const Tipo := preload("res://scripts/ui/tipografia.gd")
const Req := preload("res://scripts/core/requisitos_funcao.gd")
const COR_OK := Color(0.45, 0.8, 0.35)
const COR_FALTA := Color(0.95, 0.45, 0.35)
const COR_TEXTO := Color(0.92, 0.88, 0.8)
const COR_DICA := Color(0.65, 0.6, 0.55)

## Segundos que o cartão fica aberto sozinho (0 = só fecha no clique).
@export var segundos_aberto: float = 14.0
## Segundos entre uma conferência e outra dos requisitos.
@export var intervalo: float = 0.5

var job := ""
var nome := ""
var _hud: Node
var _w: Node
var _titulo: Label
var _resumo: Label
var _linhas: VBoxContainer
var _situacao: Label
var _t_vida := 0.0
var _t_confere := 0.0


func setup(hud: Node) -> void:
	_hud = hud
	name = "CartaoRequisitos"
	add_to_group("requisitos_cartao")
	add_theme_stylebox_override("panel", hud._panel_style())
	custom_minimum_size = Vector2(430, 0)
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	add_child(v)
	var topo := HBoxContainer.new()
	v.add_child(topo)
	_titulo = hud._label("", Tipo.TITULO, hud.COLOR_TITLE)
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(_titulo)
	var fecha: Button = hud._button("X")
	fecha.pressed.connect(func():
		Audio.click()
		visible = false)
	topo.add_child(fecha)
	_resumo = hud._label("", Tipo.DETALHE, COR_DICA)
	_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_resumo)
	_linhas = VBoxContainer.new()
	_linhas.add_theme_constant_override("separation", 2)
	v.add_child(_linhas)
	_situacao = hud._label("", Tipo.DETALHE, COR_TEXTO)
	_situacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_situacao)
	visible = false


## Abre o cartão da função `job` (o nome pra mostrar e o ipezinho que recebeu, pra conferir do jeito que a IA dele confere).
func mostra(p_job: String, p_nome: String, cor: Color, w: Node = null) -> void:
	if not Req.tem(p_job):
		visible = false
		return
	job = p_job
	nome = p_nome
	_w = w
	_titulo.text = "%s — o que precisa" % p_nome
	_titulo.add_theme_color_override("font_color", cor)
	_resumo.text = Req.resumo(p_job)
	_t_vida = 0.0
	_t_confere = 0.0
	visible = true
	move_to_front()
	_monta()
	# em cima da barra de ordens (que cresce com a escala da interface)
	var ordem = _hud.get("_order_bar")
	var base: float = (ordem.size.y if ordem != null else 90.0) + 20.0
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)  # (Bloco 135: o gerente pode ter solto as âncoras)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -base
	offset_top = -base
	reset_size.call_deferred()
	var ger = _hud.get("gerente")
	if ger:
		ger.posiciona.call_deferred(self, true)  # Bloco 135: sem cobrir a ficha nem outra janela


## O texto de cada linha (pro teste): "✓ ..." / "✗ ...".
func linhas_texto() -> Array[String]:
	var out: Array[String] = []
	for c in _linhas.get_children():
		if c is Label:
			out.append((c as Label).text)
	return out


func situacao() -> String:
	return _situacao.text


func _monta() -> void:
	var av := Req.avalia(get_tree(), job, _w if is_instance_valid(_w) else null)
	for c in _linhas.get_children():
		_linhas.remove_child(c)
		c.queue_free()
	var itens: Array = av.itens
	for it in itens:
		var ok: bool = it.ok
		var l: Label = _hud._label("%s %s" % [Req.OK if ok else Req.FALTA, it.texto], Tipo.CORPO, COR_OK if ok else COR_FALTA)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 400
		_linhas.add_child(l)
	if bool(av.pode):
		_situacao.text = "Tem trabalho: é só esperar a agenda do dia."
		_situacao.add_theme_color_override("font_color", COR_OK)
	else:
		_situacao.text = "Sem trabalho por enquanto — resolva o que está com ✗ (um caminho basta)."
		_situacao.add_theme_color_override("font_color", COR_FALTA)


func _process(delta: float) -> void:
	if not visible:
		return
	_t_vida += delta
	if segundos_aberto > 0.0 and _t_vida >= segundos_aberto:
		visible = false
		return
	_t_confere += delta
	if _t_confere >= intervalo:
		_t_confere = 0.0
		_monta()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		visible = false
		accept_event()
