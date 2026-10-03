extends Resource
## Bloco 68: a definição de um NÍVEL DA MINA (dados, não código). Um arquivo .tres por nível em
## res://data/niveis/; scripts/core/niveis.gd lê todos. Novo nível = novo .tres (o resto do jogo —
## corte da mina, liberação, atmosfera do Bloco 69 — pergunta aqui).

## Identificador (S1, S2...) e nome na tela.
@export var id: String = "S1"
@export var nome: String = "Mina"
## Profundidade (0 = superfície; 1, 2, 3...). Ordem no corte da mina.
@export var profundidade: int = 1
## Onde fica na lógica: "mapa" (a pedreira/vila), "deep" (deep_rect), "abyss" (abyss_rect), um nome
## próprio com `rect` (Bloco 71: "s4", "s5") ou "" (ainda não existe).
@export var area: String = "mapa"
## Bloco 71: o retângulo na lógica dos níveis novos (os antigos usam deep_rect/abyss_rect do ambiente).
@export var rect: Rect2 = Rect2()
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
## Bloco 72: decoração SORTEADA por dados: [quantas, [props...]] — o ambiente espalha em lugar livre do
## nível (longe de jazida, poça, gaiola e uma da outra), com sorteio fixo por nível (a mesma em todo jogo).
@export var decoracao_sorteada: Array = []
## Bloco 72: decalques deitados no chão da laje (só visual): [imagem em assets/game/iso/chao, x, y]. Os de
## nome "rio_lava*" brilham como lava.
@export var decalques: Array = []
## Bloco 70: poças de perigo do chão (props/poca_perigo.gd): [tipo ("acido"/"lava"), x, y, raio].
@export var perigos: Array = []
## Bloco 70: jazidas do nível: [minério, x, y] ou [minério, x, y, total, ritmo, regeneração].
## Nome fixo no save: Jazida<id>_<n> (JazidaS2_1...).
@export var jazidas: Array = []
## Bloco 71: a ligação que chega aqui, montada pelo ambiente quando não está na cena (grupo = `ligacao`):
## a plataforma arruinada fica no nível de cima (`ligacao_topo`), a gaiola de chegada aqui
## (`ligacao_fundo`); o conserto custa créditos (x), peças raras (y), minério (z, do tipo
## `conserto_minerio`) e segundos (w), com a vila no estágio `conserto_estagio`. `ligacao_acima` = o
## grupo da ligação que tem que estar aberta antes.
@export var ligacao_topo: Vector2 = Vector2.ZERO
@export var ligacao_fundo: Vector2 = Vector2.ZERO
@export var ligacao_acima: String = ""
@export var conserto: Vector4i = Vector4i(2000, 14, 150, 120)
@export var conserto_minerio: String = "solarita"
@export var conserto_estagio: int = 5
## Bloco 71: áreas não andáveis do nível: a ELIPSE dentro de [x, y, w, h] (na lógica: o lago).
@export var obstaculos: Array = []
## Bloco 71: soma no alvo de ânimo de quem está no nível (o lago azul acalma; negativo = pesa), com o
## motivo que aparece na janela do ipezinho.
@export var animo: float = 0.0
@export var animo_motivo: String = ""
## Bloco 71: a faixa que aparece quando a ligação abre (título; o texto é a descrição).
@export var titulo_abertura: String = ""
