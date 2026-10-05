extends CanvasLayer
## Prompt 25: tela "CORTE DA MINA" (F2, ou o botão na coluna de construções): a mina vista de lado,
## com os andares empilhados como um formigueiro, montada com os dados do jogo naquela hora:
##
##   superfície (clareira) / mina e vila (pedreira) / nível 2 (gás, radiação) / abismo (calor)
##
## Em cada andar: quem está lá (mini-boneco da função; escuro = dentro de um prédio), as zonas de
## perigo, a escavadeira, o robô, os invasores; entre os andares, o túnel (escada) e os poços do
## elevador com a gaiola onde ela está. Clicar num ipezinho seleciona e leva a câmera até ele;
## clicar no andar leva a câmera pra lá. Esc/F2/X fecha. Nada aqui muda o jogo.
## Bloco 72: o fundo é o MAPA DO MUNDO (mapa_mundo.png, do PixelLab: a coluna inteira da floresta ao lago,
## como a referência). Cada nível tem a sua região na imagem (NivelMina.mapa_regiao): ali aparecem os
## ipezinhos, jazidas e perigos dele; ao lado, a lista dos andares (aberto/fechado, quem está, jazidas).
## Bloco 63: também as JAZIDAS/GALERIAS (aberta = cor do minério, lacrada = entulho, trancada =
## cadeado: falta ferramenta ou descida), os REATORES da escavadeira (instalado e construídos), os
## bichos da clareira, os coletores e uma legenda. Clique numa galeria leva a câmera até ela. O
## desenho se refaz ~20x/s (não todo quadro) e só com a tela aberta.

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const DIR := "res://assets/game/ui/corte/"
## Bloco 68: os andares vêm de res://data/niveis (Niveis.todos()): os jogáveis com a faixa deles e os
## "em breve" como uma faixa escura trancada embaixo.
const Niveis := preload("res://scripts/core/niveis.gd")
var ANDARES: Array = []
var EM_BREVE: Array = []
## Bloco 72: o mapa do mundo em 4/3 (no 1080p vira 2x exato: pixel nítido) e a lista ao lado.
const MAPA := "mapa_mundo"
const MAPA_ESC := 4.0 / 3.0
const MAPA_POS := Vector2(6, 2)
const PAINEL_W := 500.0
const FX_PERIGO := {"gas": "nuvem_gas", "calor": "brasa", "radiacao": "radiacao"}

var _main: Node
var _env: Node
var _root: Control
var _area: Control
var _rects: Array[Rect2] = []  # retângulo do andar na tela (pra clicar)
var _pontos: Array = []  # [Rect2 na tela, nó] dos ipezinhos (pra clicar)
var _t := 0.0
var _redraw_t := 0.0
const REDRAW_EVERY := 0.05  # Bloco 63: ~20 quadros/s bastam pra os mini-bonecos andarem
const ORE_COR := {"ferro": Color(0.72, 0.62, 0.55), "cobre": Color(0.9, 0.5, 0.25), "carvao": Color(0.3, 0.3, 0.32),
	"prata": Color(0.85, 0.88, 0.95), "solarita": Color(1.0, 0.85, 0.3), "cristal_verde": Color(0.55, 1.0, 0.35),
	"cristal_rubro": Color(1.0, 0.3, 0.25), "gema_azul": Color(0.4, 0.65, 1.0)}


func setup(main: Node) -> void:
	_main = main
	ANDARES.clear()
	EM_BREVE.clear()
	for n in Niveis.todos():
		if n.em_breve:
			EM_BREVE.append(n)  # (uma faixa baixa embaixo, não uma faixa inteira)
			continue
		ANDARES.append({"id": n.id, "nome": n.nome, "faixa": n.faixa, "perigo": n.perigo, "em_breve": false,
			"cor": n.cor_faixa, "nivel": n})
	layer = 15
	visible = false
	name = "CorteDaMina"
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.025, 0.02, 0.92)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(fundo)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.painel(6))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var tit := Label.new()
	tit.text = "CORTE DA MINA"
	tit.add_theme_color_override("font_color", UiSkin.COLOR_TITLE)
	tit.add_theme_font_size_override("font_size", 20)
	UiSkin.usa_fonte(tit, "titulo", 32)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tit)
	var dica := Label.new()
	dica.text = "clique num ipezinho pra ir até ele  •  clique no andar pra levar a câmera  •  F2/Esc fecha"
	dica.add_theme_font_size_override("font_size", 11)
	dica.add_theme_color_override("font_color", UiSkin.COLOR_DIM)
	head.add_child(dica)
	var x := Button.new()
	x.text = "X"
	x.focus_mode = Control.FOCUS_NONE
	UiSkin.aplica_botao(x)
	x.pressed.connect(fecha)
	head.add_child(x)
	_area = Control.new()
	_area.custom_minimum_size = Vector2(_painel_x() + PAINEL_W, _mapa_tam().y + 6.0)
	_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_area.draw.connect(_desenha)
	_area.gui_input.connect(_clique)
	v.add_child(_area)


func abre() -> void:
	_env = get_tree().get_first_node_in_group("environment")
	visible = true
	_area.queue_redraw()


func fecha() -> void:
	visible = false


func toggle() -> void:
	if visible:
		fecha()
	else:
		abre()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_F2:
			toggle()
			get_viewport().set_input_as_handled()
		elif visible and e.keycode == KEY_ESCAPE:
			fecha()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if visible:
		_t += delta
		_redraw_t -= delta
		if _redraw_t <= 0.0:
			_redraw_t = REDRAW_EVERY
			_area.queue_redraw()  # (os ipezinhos andam)


# ------------------------------------------------------------ de onde é cada coisa
## Andar (0..3) e x na faixa (0..1) de um ponto do chão.
func _onde(p: Vector2) -> Array:
	if _env == null:
		return [1, 0.5]
	# (o índice é a ordem dos dados: S0 superfície, S1 mina, S2 nível 2, S3 abismo, S4, S5...)
	var n := Niveis.do_ponto(_env, p)
	var i := 1
	for k in ANDARES.size():
		if n and ANDARES[k].id == n.id:
			i = k
	var r := _rect_do(n)
	return [i, clampf((p.x - r.position.x) / maxf(r.size.x, 1.0), 0.03, 0.97)]


## Bloco 71: o retângulo na lógica de um nível (os antigos pelo ambiente; os novos pelo .tres).
func _rect_do(n: Resource) -> Rect2:
	if n == null:
		return _env.map_rect
	match String(n.area):
		"abyss":
			return _env.abyss_rect
		"deep":
			return _env.deep_rect
		"clareira":
			return _env.clearing_rect
		"mapa":
			return _env.map_rect
	return n.rect if (n.rect as Rect2).has_area() else _env.map_rect


func _no_corte(p: Vector2, alto := 0.72) -> Vector2:
	var o := _onde(p)
	var r := _regiao(o[0])
	return r.position + Vector2(o[1] * r.size.x, r.size.y * alto)


## Bloco 72: o tamanho do mapa na tela, e onde começa a lista ao lado.
func _mapa_tam() -> Vector2:
	var t := _tex(MAPA)
	return (t.get_size() if t else Vector2(300, 492)) * MAPA_ESC


func _painel_x() -> float:
	return MAPA_POS.x + _mapa_tam().x + 22.0


## A região do andar i no mapa (px da tela).
func _regiao(i: int) -> Rect2:
	var n: Resource = ANDARES[clampi(i, 0, ANDARES.size() - 1)].nivel
	var r: Rect2 = n.mapa_regiao
	if not r.has_area():
		r = Rect2(10, 10 + i * 60, 160, 50)
	return Rect2(MAPA_POS + r.position * MAPA_ESC, r.size * MAPA_ESC)


## (guardadas: o desenho só guarda o RID; uma textura solta seria liberada antes de aparecer)
var _cache := {}


func _tex(nome: String) -> Texture2D:
	if not _cache.has(nome):
		var p := DIR + nome + ".png"
		_cache[nome] = load(p) if ResourceLoader.exists(p) else null
	return _cache[nome]


# ------------------------------------------------------------ desenho
var _linhas: Array = []  # [Rect2, índice do andar] (a lista ao lado: clique leva a câmera)


func _desenha() -> void:
	_rects.clear()
	_pontos.clear()
	_linhas.clear()
	var f := ThemeDB.fallback_font
	var mapa := _tex(MAPA)
	if mapa:
		_area.draw_texture_rect(mapa, Rect2(MAPA_POS, _mapa_tam()), false)
	for i in ANDARES.size():
		var r := _regiao(i)
		_rects.append(r)
		if Niveis.motivo(get_tree(), ANDARES[i].nivel) != "":  # Bloco 68: nível fechado escurece (o motivo vai na lista)
			_area.draw_rect(r, Color(0, 0, 0, 0.6))
			_area.draw_string(f, r.get_center() + Vector2(-28, 4), "FECHADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.7, 0.5))
	_perigos()
	_jazidas()
	_maquinas()
	_bichos()
	_bonecos()
	_lista()
	_legenda()


## Bloco 72: a lista dos andares ao lado do mapa: nome, quem está, jazidas e se está aberto.
func _lista() -> void:
	var f := ThemeDB.fallback_font
	var x := _painel_x()
	var y := 6.0
	_area.draw_string(f, Vector2(x, y + 12), "ANDARES (clique pra ir até lá)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiSkin.COLOR_TITLE)
	y += 24.0
	var d := get_tree().get_first_node_in_group("escavadeira")
	for i in ANDARES.size():
		var a: Dictionary = ANDARES[i]
		var linha := Rect2(x - 4, y - 2, PAINEL_W - 8, 62)
		_linhas.append([linha, i])
		_area.draw_rect(linha, Color(0, 0, 0, 0.35))
		_area.draw_rect(Rect2(linha.position, Vector2(6, linha.size.y)), (a.cor as Color).lightened(0.35))
		_area.draw_string(f, Vector2(x + 10, y + 14), a.nome, HORIZONTAL_ALIGNMENT_LEFT, PAINEL_W - 130, 13, UiSkin.COLOR_TITLE)
		var n := _gente_no_andar(i)
		_area.draw_string(f, Vector2(x + PAINEL_W - 16, y + 14), "%d ipezinho%s" % [n, "s" if n != 1 else ""],
			HORIZONTAL_ALIGNMENT_RIGHT, 110, 12, UiSkin.COLOR_TEXT)
		var motivo: String = Niveis.motivo(get_tree(), a.nivel)
		var abertas := 0
		var trancadas := 0
		for m in get_tree().get_nodes_in_group("minerios"):
			if _onde((m as Node2D).global_position)[0] == i:
				if m.is_unlocked():
					abertas += 1
				else:
					trancadas += 1
		var info := "aberto" if motivo == "" else "FECHADO — " + motivo
		_area.draw_string(f, Vector2(x + 10, y + 32), info, HORIZONTAL_ALIGNMENT_LEFT, PAINEL_W - 24, 11,
			Color(0.7, 0.95, 0.6) if motivo == "" else Color(1.0, 0.7, 0.5))
		var extra := "jazidas: %d abertas%s" % [abertas, (", %d trancadas" % trancadas) if trancadas > 0 else ""]
		if String(a.perigo) != "":
			extra += "  •  perigo: %s" % String(a.perigo)
		if d != null and d.get("REACTOR_IDS") != null and _onde((d as Node2D).global_position)[0] == i:
			extra += "  •  escavadeira: %s" % d.REACTOR_NAMES.get(d.reactor, "-")
		_area.draw_string(f, Vector2(x + 10, y + 50), extra, HORIZONTAL_ALIGNMENT_LEFT, PAINEL_W - 24, 10, UiSkin.COLOR_DIM)
		y += 68.0


func _gente_no_andar(i: int) -> int:
	var n := 0
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if _onde((w as Node2D).global_position)[0] == i:
			n += 1
	return n


func _perigos() -> void:
	const IsoFx := preload("res://scripts/iso/iso_fx.gd")
	for z in get_tree().get_nodes_in_group("zonas_perigo"):
		var p := _no_corte((z as Node2D).global_position, 0.62)
		var t := IsoFx.tex(FX_PERIGO.get(String(z.get("kind")), "poeira"))
		if t:
			for k in 3:
				var s := 1.0 + 0.15 * sin(_t * 2.0 + k)
				_area.draw_set_transform(p + Vector2(-14 + k * 14, -4 * k), 0.0, Vector2(s, s))
				_area.draw_texture(t, -t.get_size() * 0.5)
			_area.draw_set_transform(Vector2.ZERO)


func _maquinas() -> void:
	for r in get_tree().get_nodes_in_group("robos"):
		var t := _tex("mini_robo")
		if t:
			var p := _no_corte((r as Node2D).global_position, 0.95)
			var tam := t.get_size() * 0.4  # (no mapa do mundo o robô fica do tamanho de um ipezinho grande)
			_area.draw_texture_rect(t, Rect2((p - Vector2(tam.x * 0.5, tam.y)).round(), tam), false)
	for c in get_tree().get_nodes_in_group("criaturas"):
		if not c.has_method("is_alive") or not c.is_alive():
			continue
		var folha: Texture2D = c.get("visual_textura")
		if folha:  # Bloco 80: criatura com folha de quadros (o Ferrugento robô): o 1º quadro, reduzido
			var q: Vector2 = Vector2(c.visual_quadro)
			var pf := _no_corte((c as Node2D).global_position, 0.95)
			var tf := q * 0.6
			_area.draw_texture_rect_region(folha, Rect2((pf - Vector2(tf.x * 0.5, tf.y)).round(), tf), Rect2(Vector2.ZERO, q), Color(1.0, 0.85, 0.85))
			continue
		var forte: bool = c.get("variant") == "forte"
		var nome: String = {"lumivoro": "criatura_lumivoro"}.get(String(c.get("kind")), "")
		var t := _tex("mini_" + nome + ("_bruto" if forte and nome == "criatura_lumivoro" else ("_carregador" if forte else "")))
		if t:
			var p := _no_corte((c as Node2D).global_position, 0.95)
			_area.draw_texture(t, (p - Vector2(t.get_width() * 0.5, t.get_height())).round(), Color(1.0, 0.8, 0.8))


func _bonecos() -> void:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		var pasta := Retratos.pasta(w)
		var tom := IsoBonecos._tone(w)
		var t := _tex("mini_%s__%s" % [pasta, tom]) if tom != "" else null
		if t == null:
			t = _tex("mini_" + pasta)
		if t == null:
			continue
		var p := _no_corte((w as Node2D).global_position, 0.95)
		var r := Rect2((p - Vector2(t.get_width() * 0.5, t.get_height())).round(), t.get_size())
		var dentro: bool = w.get("_inside") == true
		_area.draw_texture(t, r.position, Color(0.45, 0.45, 0.5, 0.8) if dentro else Color.WHITE)
		if w.get("selected"):
			_area.draw_rect(r.grow(2), UiSkin.COLOR_TITLE, false, 1.0)
		if w.get("injured"):
			var ic := Icones.tex("p_ferido")
			if ic:
				_area.draw_texture(ic, r.position + Vector2(r.size.x * 0.5 - 8, -18))
		_pontos.append([r, w])


# ------------------------------------------------------------ Bloco 63
## Cada jazida: bolinha da cor do minério (aberta), entulho com X (lacrada: a vila precisa crescer
## ou dinamite), cadeado (falta ferramenta/descida). Contagem por andar no título do andar.
var _galerias: Array = []  # [Rect2, nó] (pra clicar)


func _jazidas() -> void:
	_galerias.clear()
	for m in get_tree().get_nodes_in_group("minerios"):
		var p := _no_corte((m as Node2D).global_position, 0.86)
		var r := Rect2(p - Vector2(6, 6), Vector2(12, 12))
		var cor: Color = ORE_COR.get(String(m.ore_type), Color.WHITE)
		if m.is_sealed():
			_area.draw_rect(r, Color(0.35, 0.25, 0.15))
			_area.draw_line(r.position, r.end, Color(0.85, 0.7, 0.45), 2.0)
			_area.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Color(0.85, 0.7, 0.45), 2.0)
		elif not m.is_unlocked():
			_area.draw_circle(p, 6.0, cor.darkened(0.6))
			_area.draw_rect(Rect2(p + Vector2(-3, -1), Vector2(6, 5)), Color(0.9, 0.8, 0.4))
			_area.draw_arc(p + Vector2(0, -2), 2.5, PI, TAU, 6, Color(0.9, 0.8, 0.4), 1.0)
		else:
			var cheio: float = clampf(m.ore_remaining / maxf(m.ore_total, 1.0), 0.0, 1.0)
			_area.draw_circle(p, 6.0, cor.darkened(0.5) if m.is_depleted() else cor)
			_area.draw_arc(p, 8.0, -PI * 0.5, -PI * 0.5 + TAU * cheio, 16, Color(1, 1, 1, 0.7), 1.5)
		_galerias.append([r.grow(4), m])


## Bichos da clareira (Bloco 61) e coletores (madeira/minério).
func _bichos() -> void:
	for a in get_tree().get_nodes_in_group("animais"):
		if not a.is_alive():
			continue
		var p := _no_corte((a as Node2D).global_position, 0.93)
		_area.draw_circle(p, 3.0 if a.kind == "coelho" else 4.5, Color(0.75, 0.62, 0.48) if a.kind == "coelho" else Color(0.42, 0.3, 0.24))
	for grupo in ["coletores", "coletores_minerio"]:
		for c in get_tree().get_nodes_in_group(grupo):
			var p := _no_corte((c as Node2D).global_position, 0.9)
			var on: bool = c.get("_producing") == true
			_area.draw_rect(Rect2(p - Vector2(7, 9), Vector2(14, 9)), Color(0.55, 0.85, 0.5) if on else Color(0.5, 0.45, 0.4))


func _legenda() -> void:
	var f := ThemeDB.fallback_font
	var x := _painel_x()
	var y := 30.0 + ANDARES.size() * 68.0 + 10.0
	for n in EM_BREVE:  # Bloco 68: os níveis declarados que ainda não existem
		_area.draw_string(f, Vector2(x, y), "%s — em breve" % n.nome, HORIZONTAL_ALIGNMENT_LEFT, PAINEL_W, 11, Color(0.75, 0.8, 0.95))
		y += 16.0
	var itens := [["●", Color(0.72, 0.62, 0.55), "jazida aberta (anel = quanto tem)"], ["✕", Color(0.85, 0.7, 0.45), "galeria lacrada"],
		["▣", Color(0.9, 0.8, 0.4), "trancada (ferramenta/descida)"], ["■", Color(0.55, 0.85, 0.5), "coletor produzindo"],
		["●", Color(0.42, 0.3, 0.24), "bicho da clareira"]]
	var col := 0
	for it in itens:
		_area.draw_string(f, Vector2(x + col * 250.0, y), "%s %s" % [it[0], it[2]], HORIZONTAL_ALIGNMENT_LEFT, 245, 10, it[1])
		col += 1
		if col == 2:
			col = 0
			y += 14.0


func _clique(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Vector2 = e.position
	for gl in _galerias:  # Bloco 63: clique numa jazida/galeria leva a câmera até ela
		if (gl[0] as Rect2).has_point(p) and is_instance_valid(gl[1]):
			var cam0 = _main.get_node_or_null("Camera2D") if _main else null
			if cam0 and cam0.has_method("focus_on"):
				cam0.focus_on((gl[1] as Node2D).global_position)
			fecha()
			return
	for pt in _pontos:
		if (pt[0] as Rect2).grow(3).has_point(p) and is_instance_valid(pt[1]):
			if _main and _main.has_method("select"):
				_main.select(pt[1])
			var cam = _main.get_node_or_null("Camera2D") if _main else null
			if cam and cam.has_method("focus_on"):
				cam.focus_on((pt[1] as Node2D).global_position)
			fecha()
			return
	for li in _linhas:  # Bloco 72: a lista ao lado também leva até o andar
		if (li[0] as Rect2).has_point(p) and _env:
			var cam1 = _main.get_node_or_null("Camera2D") if _main else null
			if cam1 and cam1.has_method("focus_on"):
				cam1.focus_on(_rect_do(ANDARES[li[1]].nivel).get_center())
			fecha()
			return
	for i in _rects.size():
		if _rects[i].has_point(p) and _env:
			if i >= ANDARES.size():
				return  # Bloco 68: os "em breve" não têm lugar no mapa ainda
			var alvo: Vector2 = _rect_do(ANDARES[i].nivel).get_center()  # (Bloco 71: os níveis novos também)
			var cam = _main.get_node_or_null("Camera2D") if _main else null
			if cam and cam.has_method("focus_on"):
				cam.focus_on(alvo)
			fecha()
			return
