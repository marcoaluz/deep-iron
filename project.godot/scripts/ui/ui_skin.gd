extends RefCounted
## Prompt 20: a PELE da interface (madeira velha, ferro enferrujado, rebites, couro), em peças
## 9-slice recortadas do kit gerado (prototipos/camera/arte_iso/ui/fatia.py -> assets/game/ui/).
##
## O HUD e as janelas montam a interface por código (hud.gd: _button, _panel_style, _bar...): elas
## pedem os estilos daqui. theme() = o tema da janela raiz (vale pra quem não tem estilo próprio:
## menus, dicas/tooltips, caixas de marcar, sliders, barras de rolagem).
## Pixel inteiro: a arte entra 1:1 (o "canvas_items" do projeto amplia a tela inteira junto).

const DIR := "res://assets/game/ui/"
const FILE := DIR + "ui.json"
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_DIM := Color(0.65, 0.6, 0.55)
const Tipo := preload("res://scripts/ui/tipografia.gd")

static var _data: Dictionary = {}
static var _tex: Dictionary = {}
static var _theme: Theme = null
static var _fontes: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(FILE):
		var d = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = d.get("pecas", {}) if typeof(d) == TYPE_DICTIONARY else {}
	return _data


static func ok() -> bool:
	return not data().is_empty()


static func tex(nome: String) -> Texture2D:
	if not _tex.has(nome):
		var p := DIR + nome + ".png"
		_tex[nome] = load(p) if ResourceLoader.exists(p) else null
	return _tex[nome]


## Estilo 9-slice de uma peça (margens do ui.json). conteudo = margem de dentro (sobrepõe a do json).
static func caixa(nome: String, conteudo: Array = [], tile := false) -> StyleBox:
	var p: Dictionary = data().get(nome, {})
	var t := tex(nome)
	if p.is_empty() or t == null:
		return StyleBoxEmpty.new()
	var s := StyleBoxTexture.new()
	s.texture = t
	var m: Array = p.get("margens", [0, 0, 0, 0])
	s.texture_margin_left = m[0]
	s.texture_margin_top = m[1]
	s.texture_margin_right = m[2]
	s.texture_margin_bottom = m[3]
	var c: Array = conteudo if not conteudo.is_empty() else p.get("conteudo", m)
	s.content_margin_left = c[0]
	s.content_margin_top = c[1]
	s.content_margin_right = c[2]
	s.content_margin_bottom = c[3]
	if tile:
		s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return s


# ------------------------------------------------------------ peças prontas
static func painel(margem := -1) -> StyleBox:
	return caixa("painel", [] if margem < 0 else [margem + 8, margem + 6, margem + 8, margem + 6])


static func dica() -> StyleBox:
	return caixa("dica")


static func faixa() -> StyleBox:
	return caixa("dica", [20, 14, 20, 14])


static func titulo() -> StyleBox:
	return caixa("titulo")


static func barra_topo() -> StyleBox:
	return caixa("barra_topo", [], true)


static func barra() -> StyleBox:
	return caixa("barra", [], true)


static func cartao(estado: String = "") -> StyleBox:
	return caixa("cartao" if estado == "" else "cartao_" + estado)


## Estilos de botão: {normal, hover, pressed, disabled} (+ "on" no de ícone: aceso).
static func botao(icone := false) -> Dictionary:
	var base := "botao_icone_" if icone else "botao_"
	var out := {}
	for st in ["normal", "hover", "pressed", "disabled"]:
		out[st] = caixa(base + st)
	if icone:
		out["on"] = caixa(base + "on")
	return out


static func aba() -> Dictionary:
	return {"normal": caixa("aba_normal"), "hover": caixa("aba_hover"), "pressed": caixa("aba_pressed"),
		"hover_pressed": caixa("aba_pressed"), "disabled": caixa("aba_normal")}


static func aplica_botao(b: Button, icone := false) -> void:
	var st := botao(icone)
	for k in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(k, st[k])
	b.add_theme_stylebox_override("hover_pressed", st.get("on", st.pressed))
	if icone:
		b.add_theme_stylebox_override("pressed", st.on)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func aplica_aba(b: Button) -> void:
	var st := aba()
	for k in st:
		b.add_theme_stylebox_override(k, st[k])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Fundo da barra de progresso (moldura de ferro) e o recheio colorido por dentro dela.
static func progresso_fundo() -> StyleBox:
	return caixa("progresso", [3, 3, 3, 3])


static func progresso_cheio(cor: Color, fina := false) -> StyleBox:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	var m := 2.0 if fina else 4.0
	s.expand_margin_left = -m
	s.expand_margin_right = -m
	s.expand_margin_top = -m
	s.expand_margin_bottom = -m
	# faixa clara em cima (luz) como os metais da arte
	s.border_width_top = 1
	s.border_color = cor.lightened(0.3)
	return s


# ------------------------------------------------------------ o tema da janela raiz
static func theme() -> Theme:
	if _theme != null or not ok():
		return _theme
	var t := Theme.new()
	t.set_stylebox("panel", "PanelContainer", painel())
	t.set_stylebox("panel", "Panel", painel())
	t.set_stylebox("panel", "TooltipPanel", dica())
	t.set_color("font_color", "TooltipLabel", COLOR_TEXT)
	t.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0.6))
	var b := botao()
	for k in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(k, "Button", b[k])
	t.set_stylebox("hover_pressed", "Button", b.pressed)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", COLOR_TEXT)
	t.set_color("font_hover_color", "Button", Color(1.0, 0.94, 0.8))
	t.set_color("font_pressed_color", "Button", COLOR_TITLE)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.46, 0.42))
	t.set_stylebox("background", "ProgressBar", progresso_fundo())
	t.set_stylebox("fill", "ProgressBar", progresso_cheio(Color(0.85, 0.6, 0.25)))
	for cls in ["CheckBox", "CheckButton"]:
		t.set_icon("checked", cls, tex("caixa_on"))
		t.set_icon("unchecked", cls, tex("caixa_off"))
		t.set_icon("checked_disabled", cls, tex("caixa_on"))
		t.set_icon("unchecked_disabled", cls, tex("caixa_off"))
		for k in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			t.set_stylebox(k, cls, StyleBoxEmpty.new())
	var trilho := caixa("trilho", [0, 0, 0, 0])
	t.set_stylebox("slider", "HSlider", trilho)
	t.set_stylebox("grabber_area", "HSlider", StyleBoxEmpty.new())
	t.set_stylebox("grabber_area_highlight", "HSlider", StyleBoxEmpty.new())
	t.set_icon("grabber", "HSlider", tex("pino"))
	t.set_icon("grabber_highlight", "HSlider", tex("pino"))
	var trilho_v := StyleBoxFlat.new()
	trilho_v.bg_color = Color(0.08, 0.06, 0.05, 0.8)
	var pega := StyleBoxFlat.new()
	pega.bg_color = Color(0.45, 0.3, 0.16)
	pega.border_color = Color(0.7, 0.5, 0.25)
	pega.set_border_width_all(1)
	for cls in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", cls, trilho_v)
		t.set_stylebox("grabber", cls, pega)
		t.set_stylebox("grabber_highlight", cls, pega)
		t.set_stylebox("grabber_pressed", cls, pega)
	var campo := StyleBoxFlat.new()
	campo.bg_color = Color(0.06, 0.05, 0.04, 0.9)
	campo.border_color = Color(0.45, 0.32, 0.18)
	campo.set_border_width_all(1)
	campo.set_content_margin_all(5)
	t.set_stylebox("normal", "LineEdit", campo)
	t.set_stylebox("focus", "LineEdit", campo)
	for cls in ["ItemList", "Tree"]:
		t.set_stylebox("panel", cls, campo)
	t.set_stylebox("panel", "PopupMenu", dica())
	t.set_stylebox("normal", "OptionButton", b.normal)
	t.set_stylebox("hover", "OptionButton", b.hover)
	t.set_stylebox("pressed", "OptionButton", b.pressed)
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	Tipo.aplica_no_tema(t)  # Bloco 95: a escala tipográfica, a fonte do corpo e a sombra fina
	_theme = t
	return t


## Bloco 95: o tema da janela raiz NÃO chega nos Controls de um CanvasLayer (o HUD, o corte, a pausa): cada
## Control de cima da camada recebe o tema, agora e quando entrar depois (janela nova, aviso, faixa).
static func tema_na_camada(camada: CanvasLayer) -> void:
	var t := theme()
	if t == null:
		return
	for c in camada.get_children():
		if c is Control and (c as Control).theme == null:
			(c as Control).theme = t
	if not camada.has_meta("_tema_95"):
		camada.set_meta("_tema_95", true)
		camada.child_entered_tree.connect(func(n: Node): _tema_no_filho(n))


static func _tema_no_filho(n: Node) -> void:
	if n is Control and (n as Control).theme == null and n.get_parent() is CanvasLayer:
		(n as Control).theme = theme()


## Cursor do mouse (assets/game/ui/cursor_<nome>.png, ponta no ui.json).
static func cursor(nome: String) -> void:
	var t := tex("cursor_" + nome)
	if t == null:
		return
	var raw = JSON.parse_string(FileAccess.get_file_as_string(FILE)) if FileAccess.file_exists(FILE) else {}
	var hs: Array = raw.get("cursores", {}).get(nome, [0, 0]) if typeof(raw) == TYPE_DICTIONARY else [0, 0]
	Input.set_custom_mouse_cursor(t, Input.CURSOR_ARROW, Vector2(hs[0], hs[1]))


# ------------------------------------------------------------ fontes (Prompt 22)
## As fontes pixel do jogo (assets/fonts/deep_iron_<nome>.ttf, montadas por fontes/monta_fonte.py):
##   "titulo" — pesada, estêncil de ferro: nítida em 32 e 64 (cabeçalhos, faixas, logo);
##   "texto"  — de leitura, com todos os acentos e números de largura fixa: nítida em 16 e 32.
## O que faltar na fonte (símbolo raro) cai na fonte padrão.
static func fonte(nome: String) -> Font:
	if not _fontes.has(nome):
		var p := "res://assets/fonts/deep_iron_%s.ttf" % nome
		var f: FontFile = load(p) if ResourceLoader.exists(p) else null
		if f:
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			f.generate_mipmaps = false
			f.fallbacks = [ThemeDB.fallback_font]
		_fontes[nome] = f
	return _fontes[nome]


## Rótulo com a fonte pixel no tamanho nítido dela.
static func usa_fonte(l: Control, nome: String, tamanho: int) -> void:
	var f := fonte(nome)
	if f == null:
		return
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", tamanho)
