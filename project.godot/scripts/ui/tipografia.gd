extends RefCounted
## Bloco 95: a ESCALA TIPOGRÁFICA única da interface (parte C do layout v2). Todo tamanho de letra do jogo sai
## daqui — nada de número solto no código (o teste b95 procura e falha). Os tamanhos são px LÓGICOS na tela de
## 1280x720; a escala da interface (90/100/125%, configurações) amplia tudo junto.
##
##   TITULO_JANELA  cabeçalho de janela ("CONSTRUIR", "FORÇA DE TRABALHO")
##   TITULO         título de cartão, nome do ipezinho, título de seção
##   CORPO          texto corrido, botões (o padrão do tema: quem não pede tamanho fica com este)
##   DETALHE        custo, requisito, etiqueta, legenda curta
##   DICA           texto das dicas (tooltip)
##   FAIXA          faixa de aviso grande (invasão, conquista) e títulos de tela (pausa, vitória)
##   TELA           título grande de tela (menu inicial, fim de jogo)
## As fontes PIXEL do jogo (ui_skin.fonte: "titulo" e "texto") só ficam nítidas nos tamanhos nativos:
##   PIXEL_1 / PIXEL_2 / PIXEL_4 (16 / 32 / 64).
## Os rótulos do MAPA (prédios, placas, "+1") ficam no mundo e crescem com o zoom: MAPA, MAPA_MINI, MAPA_POPUP.

const TITULO_JANELA := 20
const TITULO := 15
const CORPO := 13
const DETALHE := 12
const DICA := 12
const FAIXA := 26
const TELA := 34

const PIXEL_1 := 16
const PIXEL_2 := 32
const PIXEL_4 := 64

const MAPA := 10
const MAPA_MINI := 8
const MAPA_POPUP := 14

## Sombra fina dos textos sobre as placas de madeira (contraste sem engrossar a letra).
const SOMBRA := Color(0.0, 0.0, 0.0, 0.85)
const SOMBRA_DESLOC := 1
## Contorno dos rótulos do mapa (em cima da arte, qualquer cor de chão).
const CONTORNO_MAPA := Color(0.04, 0.03, 0.02, 0.95)
const CONTORNO_MAPA_PX := 3

## A fonte do CORPO: Chakra Petch Medium (OFL, assets/fonts/OFL_chakra_petch.txt), a escolhida pelo Marco entre as
## candidatas de docs/layout_v2/fontes_comparativo.png. Vazio = a fonte padrão do Godot (a de antes do Bloco 95).
const FONTE_CORPO := "res://assets/fonts/chakra_petch_medium.ttf"

static var _fonte: Font = null
static var _fonte_lida := false


## A fonte do corpo (null = a padrão do Godot).
static func fonte() -> Font:
	if not _fonte_lida:
		_fonte_lida = true
		if FONTE_CORPO != "" and ResourceLoader.exists(FONTE_CORPO):
			var f: FontFile = load(FONTE_CORPO)
			f.fallbacks = [ThemeDB.fallback_font]
			_fonte = f
	return _fonte


## A fonte pra desenhar à mão (draw_string): a do corpo, ou a padrão.
static func fonte_desenho() -> Font:
	var f := fonte()
	return f if f != null else ThemeDB.fallback_font


## Põe no tema a escala e a fonte: o corpo como padrão, a sombra nos rótulos e o tamanho das dicas.
static func aplica_no_tema(t: Theme) -> void:
	var f := fonte()
	if f != null:
		t.default_font = f
	t.default_font_size = CORPO
	for cls in ["Label", "RichTextLabel"]:
		t.set_color("font_shadow_color", cls, SOMBRA)
		t.set_constant("shadow_offset_x", cls, SOMBRA_DESLOC)
		t.set_constant("shadow_offset_y", cls, SOMBRA_DESLOC)
	t.set_font_size("font_size", "TooltipLabel", DICA)
	t.set_color("font_shadow_color", "TooltipLabel", SOMBRA)
