extends RefCounted
## Prompt 21: os ÍCONES do jogo (assets/game/ui/icones/, montados por ui/icones.py).
##   tex("creditos")        -> 32 px (tamanho base: barra de funções, painéis)
##   tex("creditos", true)  -> 24 px (barra de recursos do topo)
##   predio("casa")         -> render reduzido da arte pronta (menu de construção)
## Sem o arquivo: null (quem chama usa o desenho de antes).

const DIR := "res://assets/game/ui/icones/"
## função do jogo (ipezinho.job) -> ícone
const FUNCAO := {"minerador": "minerador", "caçador": "cacador", "médico": "medico", "engenheiro": "engenheiro",
	"cozinheiro": "cozinheiro", "lenhador": "lenhador", "guarda": "guarda", "pesquisador": "pesquisador",
	"fundidor": "fundidor", "ferreiro": "ferreiro", "padre": "padre"}  # Bloco 92 (PixelLab, oficios92.py)
## estação (sun.season_index) -> ícone
const ESTACAO := ["primavera", "verao", "outono", "inverno"]

static var _tex: Dictionary = {}


static func tex(nome: String, pequeno := false) -> Texture2D:
	var p := DIR + ("p24/" if pequeno else "") + nome + ".png"
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]


static func predio(nome: String) -> Texture2D:
	return tex("predios/" + nome)


## Prompt 24: ilustração de evento (assets/game/ui/ilustracoes/<nome>.png, cartão 256x144).
static func ilustracao(nome: String) -> Texture2D:
	var p := "res://assets/game/ui/ilustracoes/" + nome + ".png"
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]
