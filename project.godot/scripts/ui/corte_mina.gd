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
const FAIXA_BREVE := 26.0
const ALTURA := 128.0  # px de cada faixa (a arte tem 128)
const LARGURA := 1024.0  # a faixa de 512 em 2x
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
	"cristal_rubro": Color(1.0, 0.3, 0.25)}


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
	_area.custom_minimum_size = Vector2(LARGURA, ALTURA * maxi(ANDARES.size(), 4) + FAIXA_BREVE + 22.0)  # + em breve (68) + legenda (63)
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
	var r: Rect2
	var i := 1
	if _env.abyss_rect.has_point(p):
		i = 3; r = _env.abyss_rect
	elif _env.deep_rect.has_point(p):
		i = 2; r = _env.deep_rect
	elif p.y < _env.map_rect.position.y:
		i = 0; r = _env.clearing_rect
	else:
		r = _env.map_rect
	# (o índice é a ordem dos dados: S0 superfície, S1 mina, S2 nível 2, S3 abismo)
	return [i, clampf((p.x - r.position.x) / maxf(r.size.x, 1.0), 0.03, 0.97)]


func _no_corte(p: Vector2, alto := 0.72) -> Vector2:
	var o := _onde(p)
	return Vector2(o[1] * LARGURA, o[0] * ALTURA + ALTURA * alto)


## (guardadas: o desenho só guarda o RID; uma textura solta seria liberada antes de aparecer)
var _cache := {}


func _tex(nome: String) -> Texture2D:
	if not _cache.has(nome):
		var p := DIR + nome + ".png"
		_cache[nome] = load(p) if ResourceLoader.exists(p) else null
	return _cache[nome]


# ------------------------------------------------------------ desenho
func _desenha() -> void:
	_rects.clear()
	_pontos.clear()
	var f := ThemeDB.fallback_font
	for i in ANDARES.size():
		var a: Dictionary = ANDARES[i]
		var r := Rect2(0, i * ALTURA, LARGURA, ALTURA)
		_rects.append(r)
		var t := _tex(a.faixa) if a.faixa != "" else null
		if t:
			_area.draw_texture_rect(t, r, false)  # 512x128 em 2x na horizontal (faixas de rocha)
		else:
			_area.draw_rect(r, a.cor)
		var motivo: String = Niveis.motivo(get_tree(), a.nivel)
		if motivo != "":  # Bloco 68: nível fechado (ou em breve): escurece e diz por quê
			_area.draw_rect(r, Color(0, 0, 0, 0.55))
			_area.draw_string(ThemeDB.fallback_font, r.position + Vector2(LARGURA * 0.5 - 160, ALTURA * 0.55), "FECHADO — " + motivo,
				HORIZONTAL_ALIGNMENT_LEFT, 360, 13, Color(1.0, 0.7, 0.5))
		_area.draw_rect(Rect2(r.position, Vector2(LARGURA, 18)), Color(0, 0, 0, 0.55))
		_area.draw_string(f, r.position + Vector2(8, 13), a.nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiSkin.COLOR_TITLE)
		var n := _gente_no_andar(i)
		_area.draw_string(f, r.position + Vector2(LARGURA - 8, 13), "%d ipezinho%s" % [n, "s" if n != 1 else ""],
			HORIZONTAL_ALIGNMENT_RIGHT, 200, 12, UiSkin.COLOR_TEXT)
	_ligacoes()
	_perigos()
	_jazidas()
	_maquinas()
	_reatores()
	_bichos()
	_bonecos()
	_legenda()


func _gente_no_andar(i: int) -> int:
	var n := 0
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if _onde((w as Node2D).global_position)[0] == i:
			n += 1
	return n


## Túnel (escada da clareira pra pedreira) e os poços do elevador com a gaiola.
func _ligacoes() -> void:
	if _env == null:
		return
	var tx: float = clampf((_env.tunnel_x - _env.map_rect.position.x) / _env.map_rect.size.x, 0.0, 1.0) * LARGURA
	_escada(Vector2(tx, ALTURA * 0.75), Vector2(tx, ALTURA * 1.7))
	var gaiola := _tex("gaiola_lado")
	for g in ["elevador", "elevador_abismo"]:
		for e in get_tree().get_nodes_in_group(g):
			var topo: Vector2 = (e as Node2D).global_position
			var fundo = e.get("bottom_position")
			if fundo == null:
				continue
			var a := _no_corte(topo, 0.6)
			var b := _no_corte(fundo, 0.75)
			b.x = a.x
			_area.draw_line(a + Vector2(-9, 0), b + Vector2(-9, 0), Color(0.18, 0.13, 0.1), 2.0)
			_area.draw_line(a + Vector2(9, 0), b + Vector2(9, 0), Color(0.18, 0.13, 0.1), 2.0)
			_area.draw_line(a, b, Color(0.55, 0.5, 0.45, 0.8), 1.0)  # o cabo
			if gaiola:
				var k := 0.5 + 0.5 * sin(_t * 0.6 + a.x)  # (a lógica não guarda onde a gaiola está: vai e volta)
				var p := a.lerp(b, k) - gaiola.get_size() * 0.5
				_area.draw_texture(gaiola, p.round())


func _escada(a: Vector2, b: Vector2) -> void:
	_area.draw_line(a + Vector2(-6, 0), b + Vector2(-6, 0), Color(0.42, 0.3, 0.18), 2.0)
	_area.draw_line(a + Vector2(6, 0), b + Vector2(6, 0), Color(0.42, 0.3, 0.18), 2.0)
	var y := a.y
	while y < b.y:
		_area.draw_line(Vector2(a.x - 6, y), Vector2(a.x + 6, y), Color(0.5, 0.36, 0.22), 2.0)
		y += 8.0


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
		_area.draw_string(ThemeDB.fallback_font, p + Vector2(-20, 24), String(z.get("kind")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.6, 0.4))


func _maquinas() -> void:
	var esc := _tex("escavadeira_lado")
	var d := get_tree().get_first_node_in_group("escavadeira") as Node2D
	if esc and d:
		var p := _no_corte(d.global_position, 0.95)
		_area.draw_texture(esc, (p - Vector2(esc.get_width() * 0.5, esc.get_height())).round())
	for r in get_tree().get_nodes_in_group("robos"):
		var t := _tex("mini_robo")
		if t:
			var p := _no_corte((r as Node2D).global_position, 0.95)
			_area.draw_texture(t, (p - Vector2(t.get_width() * 0.5, t.get_height())).round())
	for c in get_tree().get_nodes_in_group("criaturas"):
		if not c.has_method("is_alive") or not c.is_alive():
			continue
		var forte: bool = c.get("variant") == "forte"
		var nome: String = {"lumivoro": "criatura_lumivoro", "ferrugento": "criatura_ferrugento"}.get(String(c.get("kind")), "")
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
	var f := ThemeDB.fallback_font
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
		if String(m.get("gallery_name")) != "" and m.is_sealed():
			_area.draw_string(f, p + Vector2(-24, 18), String(m.gallery_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.7, 0.45))


## Reatores da escavadeira: o instalado aceso, os construídos apagados, o em obra piscando.
func _reatores() -> void:
	var d := get_tree().get_first_node_in_group("escavadeira")
	if d == null or d.get("REACTOR_IDS") == null:
		return
	var base := _no_corte((d as Node2D).global_position, 0.3)
	var f := ThemeDB.fallback_font
	var x := base.x - 40.0
	for id in d.REACTOR_IDS:
		var cor := Color(0.25, 0.22, 0.2)
		if id == d.reactor:
			cor = Color(1.0, 0.75, 0.3)
		elif id in d.built_reactors:
			cor = Color(0.6, 0.55, 0.45)
		elif id == d.building_reactor:
			cor = Color(0.9, 0.6, 0.3, 0.5 + 0.5 * sin(_t * 6.0))
		_area.draw_rect(Rect2(Vector2(x, base.y), Vector2(12, 10)), cor)
		_area.draw_rect(Rect2(Vector2(x, base.y), Vector2(12, 10)), Color(0, 0, 0, 0.6), false, 1.0)
		x += 16.0
	_area.draw_string(f, Vector2(base.x - 40.0, base.y - 3), "reator: %s" % d.REACTOR_NAMES.get(d.reactor, "-"), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.85, 0.5))


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
	# Bloco 68: os níveis declarados que ainda não existem
	if not EM_BREVE.is_empty():
		var yb := ANDARES.size() * ALTURA
		var xb := 0.0
		var w := LARGURA / EM_BREVE.size()
		for n in EM_BREVE:
			_area.draw_rect(Rect2(xb, yb, w - 2.0, FAIXA_BREVE - 2.0), n.cor_faixa.darkened(0.3))
			_area.draw_string(f, Vector2(xb + 8.0, yb + 17.0), "%s — em breve" % n.nome, HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, 11, Color(0.75, 0.8, 0.95))
			xb += w
	var y := ANDARES.size() * ALTURA + FAIXA_BREVE + 14.0
	var x := 6.0
	var itens := [["●", Color(0.72, 0.62, 0.55), "jazida aberta (anel = quanto tem)"], ["✕", Color(0.85, 0.7, 0.45), "galeria lacrada (clique: ir até ela)"],
		["▣", Color(0.9, 0.8, 0.4), "trancada (ferramenta/descida)"], ["■", Color(1.0, 0.75, 0.3), "reator instalado"],
		["■", Color(0.55, 0.85, 0.5), "coletor produzindo"], ["●", Color(0.42, 0.3, 0.24), "bicho da clareira"]]
	for it in itens:
		_area.draw_string(f, Vector2(x, y), "%s %s" % [it[0], it[2]], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, it[1])
		x += 170.0


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
	for i in _rects.size():
		if _rects[i].has_point(p) and _env:
			if i >= 4:
				return  # Bloco 68: os "em breve" não têm lugar no mapa ainda
			var alvo: Vector2 = [_env.clearing_rect, _env.map_rect, _env.deep_rect, _env.abyss_rect][i].get_center()
			var cam = _main.get_node_or_null("Camera2D") if _main else null
			if cam and cam.has_method("focus_on"):
				cam.focus_on(alvo)
			fecha()
			return
