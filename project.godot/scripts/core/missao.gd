extends Resource
## Bloco 100: a definição de uma MISSÃO (dados, não código), no padrão dos níveis da mina (nivel_mina.gd): um arquivo
## .tres por missão em res://data/missoes/, lido por scripts/core/missoes.gd. Missão nova = um .tres novo (e as linhas
## dos textos dela no arquivo do capítulo).
##
## OS TEXTOS moram em res://data/missoes/capitulo_N.txt (um arquivo por capítulo, fácil de editar): o título e o texto
## daqui só valem se o arquivo não tiver a seção da missão (ou não existir).

## Identificador único (cap1_cinzas) — é o nome da seção no arquivo de texto e a chave do save.
@export var id: String = ""
## Título e texto (os do arquivo do capítulo ganham destes).
@export var titulo: String = ""
@export_multiline var texto: String = ""
## Capítulo (1..6) e a ordem da missão dentro dele.
@export var capitulo: int = 1
@export var ordem: int = 0
## Objetivos: [tipo, alvo, quantidade]. Tipos (os que a Missoes sabe medir; ver missoes.gd `valor_do_objetivo`):
##   "fundar_vila"      a vila foi fundada (alvo e quantidade ignorados)
##   "casas"            casas construídas (quantidade)
##   "construcao"       prédios de um grupo do jogo (alvo = grupo: "comedouros" = cozinha, "tavernas"...; quantidade)
##   "minerio_armazem"  minério guardado nos armazéns (alvo = "" qualquer, ou o minério; quantidade)
##   "item"             itens processados no armazém (alvo = id do item: barra_ferro...; quantidade)
##   "invasoes"         invasões que acabaram (quantidade)
##   "estagio"          estágio da vila (quantidade = o número do estágio)
##   "pesquisa"         pesquisa pronta (alvo = id da pesquisa)
##   "vendido"          minério vendido, no total (quantidade)
##   "obras"            obras prontas de um tipo (alvo = tipo do canteiro: "taverna"...; quantidade)
##   "mortes"           mortes na vila (quantidade)
@export var objetivos: Array = []
## Recompensa: {"creditos": 150, "diario": "id da página", "libera_capitulo": 2, "itens": {id: qtd}}.
@export var recompensa: Dictionary = {}
## Ids das missões que precisam estar cumpridas antes desta aparecer.
@export var prerequisitos: PackedStringArray = PackedStringArray()


## O texto de um objetivo sem o arquivo de texto (o "Cap. N" do arquivo ganha deste).
func objetivo_padrao(i: int) -> String:
	if i < 0 or i >= objetivos.size():
		return "?"
	var o: Array = objetivos[i]
	var q := int(o[2]) if o.size() > 2 else 1
	var alvo := String(o[1]) if o.size() > 1 else ""
	match String(o[0]):
		"fundar_vila":
			return "Fundar a vila"
		"casas":
			return "%d casas construídas" % q
		"construcao":
			return "Construir: %s" % alvo
		"minerio_armazem":
			return "%d de minério no armazém" % q
		"item":
			return "%d %s no armazém" % [q, alvo]
		"invasoes":
			return "Sobreviver a %d invasão(ões)" % q
		"estagio":
			return "Vila no estágio %d" % q
		"pesquisa":
			return "Pesquisar: %s" % alvo
		"vendido":
			return "Vender %d de minério" % q
		"obras":
			return "Obras prontas (%s): %d" % [alvo, q]
		"mortes":
			return "%d mortes" % q
		"estudar":  # Bloco 102 (o catálogo)
			return "Estudar: %s" % alvo if alvo != "" else "Estudar %d descobertas" % q
		"criatura":  # Bloco 103 (o bestiário)
			return "Estudar a criatura: %s" % alvo if alvo != "" else "Estudar %d criaturas" % q
		"reconhecer":  # Bloco 103 (os andares)
			return "Reconhecer o %s" % alvo if alvo != "" else "Reconhecer %d andares" % q
	return String(o[0])
