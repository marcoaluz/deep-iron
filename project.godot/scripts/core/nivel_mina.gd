extends Resource
## Bloco 68: a definição de um NÍVEL DA MINA (dados, não código). Um arquivo .tres por nível em
## res://data/niveis/; scripts/core/niveis.gd lê todos. Novo nível = novo .tres (o resto do jogo —
## corte da mina, liberação, atmosfera do Bloco 69 — pergunta aqui).

## Identificador (S1, S2...) e nome na tela.
@export var id: String = "S1"
@export var nome: String = "Mina"
## Profundidade (0 = superfície; 1, 2, 3...). Ordem no corte da mina.
@export var profundidade: int = 1
## Onde fica na lógica: "mapa" (a pedreira/vila), "deep" (deep_rect), "abyss" (abyss_rect) ou "" (ainda não existe).
@export var area: String = "mapa"
## Perigo principal: "" (nenhum), "poeira", "gas", "calor", "radiacao", "acido", "agua".
@export var perigo: String = ""
## Traje que o perigo pede (equipment.gd: "gas", "calor", "radiacao"; "" = nenhum).
@export var traje: String = ""
## Pesquisa que libera a descida ("" = nenhuma) e o grupo da ligação (elevador) que chega aqui.
@export var pesquisa: String = ""
@export var ligacao: String = ""
## Declarado mas ainda não jogável (aparece como "em breve").
@export var em_breve: bool = false
## Minérios e criaturas típicos (informativo + conteúdo do Bloco 70).
@export var minerios: PackedStringArray = PackedStringArray()
@export var criaturas: PackedStringArray = PackedStringArray()
## Atmosfera (Bloco 69): luz ambiente, cor da névoa, partículas ("", "poeira", "acido", "calor", "bolhas", "gotas").
@export var cor_ambiente: Color = Color(1, 1, 1)
@export var cor_nevoa: Color = Color(0, 0, 0, 0)
@export var particulas: String = ""
## Faixa do corte da mina (assets/game/ui/corte/<faixa>.png; "" = cor lisa) e a cor da faixa sem arte.
@export var faixa: String = ""
@export var cor_faixa: Color = Color(0.2, 0.18, 0.16)
@export_multiline var descricao: String = ""
## Decoração por dados (Bloco 69): [prop, x, y] na lógica, colocada pelo ambiente quando o nível existe.
@export var decoracao: Array = []
## Bloco 70: poças de perigo do chão (props/poca_perigo.gd): [tipo ("acido"/"lava"), x, y, raio].
@export var perigos: Array = []
## Bloco 70: jazidas do nível: [minério, x, y] ou [minério, x, y, total, ritmo, regeneração].
## Nome fixo no save: Jazida<id>_<n> (JazidaS2_1...).
@export var jazidas: Array = []
