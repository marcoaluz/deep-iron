extends Resource
## Bloco 113: um PERFIL de dificuldade (dados, não código), no padrão das missões (missao.gd): um arquivo .tres por perfil
## em res://data/dificuldade/ (tranquilo, normal, ferro, criativo), lido por scripts/core/dificuldade.gd. O Personalizado
## não tem arquivo: nasce do Normal com os sliders do jogador (dificuldade.gd `custom`).
##
## O NORMAL é o jogo de antes do Bloco 113, número por número (o teste b113 confere com os @export de Defesa, Sol, Moral
## e Comedouro): ele nunca sobrescreve nada. Mudou o balanceamento do jogo? Mude o @export de lá E o normal.tres daqui.

## Identificador (o nome do arquivo e a chave do save) e o que a tela de Nova partida mostra.
@export var id: String = ""
@export var nome: String = ""
@export_multiline var descricao: String = ""
## Dia (da partida) da PRIMEIRA invasão das criaturas: defense.first_invasion_day.
@export var primeira_invasao_dia: int = 3
## Dias entre uma invasão e a próxima: defense.invasion_every.
@export var invasao_a_cada: int = 2
## Quanto a vida das criaturas cresce por onda (0,15 = +15% por onda): defense.hp_growth.
@export var vida_por_onda: float = 0.15
## Multiplica a fome de todo mundo (1,2 = passa fome 20% mais depressa): chave "fome" do Modificadores.
@export var fome_mult: float = 1.0
## Chance (0 a 1) de ter onda solar num dia de VERÃO: sun.season_wave_chance[1]. As outras estações não mudam.
@export var onda_verao: float = 0.5
## Segundos de ultimato da greve antes de os ipezinhos expulsarem o jogador: morale.strike_ultimatum.
@export var ultimato_greve: float = 300.0
## Comida que o comedouro novo traz (unidades; o armazém de comida guarda até 300): comedouro.start_food.
@export var comida_inicial: float = 240.0
## Multiplica o preço de venda de tudo (minério e itens): chave "preco_venda" do Modificadores.
@export var preco_venda_mult: float = 1.0
## Criativo: nenhuma invasão (nem os moradores hostis do fundo).
@export var sem_invasao: bool = false
## Criativo: o pacote da Fundação (créditos, pedra e madeira) vem multiplicado por isto...
@export var recursos_pacote_mult: float = 1.0
## ...e entram estes créditos a mais.
@export var creditos_extras: int = 0

## Os 8 números que o Personalizado deixa ajustar (chave -> [mínimo, máximo, passo]) — os limites dos sliders.
const AJUSTAVEIS := {
	"primeira_invasao_dia": [1, 10, 1],
	"invasao_a_cada": [1, 6, 1],
	"vida_por_onda": [0.0, 0.5, 0.01],
	"fome_mult": [0.5, 1.6, 0.05],
	"onda_verao": [0.0, 1.0, 0.05],
	"ultimato_greve": [60.0, 600.0, 10.0],
	"comida_inicial": [0.0, 300.0, 10.0],
	"preco_venda_mult": [0.5, 1.5, 0.05],
}


## {chave: valor} dos 8 números ajustáveis deste perfil.
func numeros() -> Dictionary:
	var d := {}
	for k in AJUSTAVEIS:
		d[k] = get(k)
	return d


## Põe os números ajustáveis de `d` neste perfil (chave que falta ou fora da faixa é ajustada: nunca quebra).
func poe_numeros(d: Dictionary) -> void:
	for k in AJUSTAVEIS:
		if not d.has(k):
			continue
		var lim: Array = AJUSTAVEIS[k]
		var v: float = clampf(float(d[k]), float(lim[0]), float(lim[1]))
		set(k, int(roundf(v)) if typeof(get(k)) == TYPE_INT else v)
