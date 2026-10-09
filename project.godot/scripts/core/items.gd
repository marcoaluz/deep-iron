extends RefCounted
## Bloco 82: CATÁLOGO DE ITENS (use com preload: const Items := preload("res://scripts/core/items.gd")), no
## estilo do ores.gd. Cada item tem id, nome, categoria, ícone, preço de venda base e ONDE fica guardado:
##
##   "stock"         minério bruto — Armazém.stock (o dicionário de sempre; tipos do ores.gd)
##   "madeira"       Armazém.wood_stored
##   "materia_prima" Armazém.raw_stored (fruta e caça cruas: o cozinheiro prepara)
##   "couro"         Armazém.leather_stored (casacos e trajes)
##   "pecas_raras"   Finds.rare_parts (achados da mina; um número só da vila)
##   "itens"         Armazém.itens — os PROCESSADOS (barras, aço, lingote, prego...). Fica fora do `stock`
##                   pra não virar "minério" nas somas (pilha, marcos, custo em minério qualquer).
##
## Quem soma, guarda, tira e vende é a Economia (quantidade / add_item / take_item / sell), olhando todos os
## armazéns (Bloco 47: cada armazém tem o seu estoque; a vila usa a soma). Preço 0 = não se vende. O preço
## dos minérios continua nos @export da Economia; o dos outros pode ser trocado lá (precos_itens).
## Ícone: nome em assets/game/ui/icones/ (Icones.tex); os provisórios são de ui/icones_itens.py.

const Ores := preload("res://scripts/core/ores.gd")

## Ordem das categorias na janela do armazém.
const CATEGORIAS := ["minerio", "metal", "madeira", "comida", "pecas", "equipamento"]
const NOMES_CATEGORIA := {"minerio": "Minério", "metal": "Metal", "madeira": "Madeira", "comida": "Comida",
	"pecas": "Peças e materiais", "equipamento": "Equipamento"}

## id -> {nome, cat, icone, preco, onde}. A ordem aqui é a ordem na grade.
const ITENS := {
	# minério bruto (preço: Economia; ícone: o do minério)
	"ferro": {"nome": "Ferro", "cat": "minerio", "icone": "ferro", "preco": 2.0, "onde": "stock"},
	"carvao": {"nome": "Carvão", "cat": "minerio", "icone": "carvao", "preco": 3.0, "onde": "stock"},
	"cobre": {"nome": "Cobre", "cat": "minerio", "icone": "cobre", "preco": 4.0, "onde": "stock"},
	"prata": {"nome": "Prata", "cat": "minerio", "icone": "prata", "preco": 8.0, "onde": "stock"},
	"cristal_verde": {"nome": "Cristal verde", "cat": "minerio", "icone": "it_cristal_verde", "preco": 10.0, "onde": "stock"},
	"solarita": {"nome": "Solarita", "cat": "minerio", "icone": "solarita", "preco": 14.0, "onde": "stock"},
	"cristal_rubro": {"nome": "Cristal rubro", "cat": "minerio", "icone": "it_cristal_rubro", "preco": 18.0, "onde": "stock"},
	"gema_azul": {"nome": "Gema azul", "cat": "minerio", "icone": "it_gema_azul", "preco": 30.0, "onde": "stock"},
	# Bloco 102: o minério de jazida ainda não estudada (catalogo.gd): vale pouco, não entra em receita
	"desconhecido": {"nome": "Minério desconhecido", "cat": "minerio", "icone": "desconhecido", "preco": 1.0, "onde": "stock"},
	# metal (Bloco 86: a Fornalha faz; o aço é da Fundição, estágio 3)
	"barra_ferro": {"nome": "Barra de ferro", "cat": "metal", "icone": "it_barra_ferro", "preco": 8.0, "onde": "itens"},
	"barra_cobre": {"nome": "Barra de cobre", "cat": "metal", "icone": "it_barra_cobre", "preco": 13.0, "onde": "itens"},
	"aco": {"nome": "Aço", "cat": "metal", "icone": "it_aco", "preco": 18.0, "onde": "itens"},
	"barra_prata": {"nome": "Barra de prata", "cat": "metal", "icone": "it_barra_prata", "preco": 20.0, "onde": "itens"},
	"lingote_solar": {"nome": "Lingote solar", "cat": "metal", "icone": "it_lingote_solar", "preco": 36.0, "onde": "itens"},
	# madeira e comida (não se vendem: obras e cozinha)
	"madeira": {"nome": "Madeira", "cat": "madeira", "icone": "madeira", "preco": 0.0, "onde": "madeira"},
	"comida_crua": {"nome": "Comida crua", "cat": "comida", "icone": "materia_prima", "preco": 0.0, "onde": "materia_prima"},
	# peças e materiais
	"prego": {"nome": "Prego", "cat": "pecas", "icone": "it_prego", "preco": 1.0, "onde": "itens"},
	"ferragem": {"nome": "Ferragem", "cat": "pecas", "icone": "it_ferragem", "preco": 12.0, "onde": "itens"},  # Bloco 87
	"tabua": {"nome": "Tábua", "cat": "madeira", "icone": "it_tabua", "preco": 2.0, "onde": "itens"},  # Bloco 94: carpintaria
	"couro": {"nome": "Couro", "cat": "pecas", "icone": "it_couro", "preco": 0.0, "onde": "couro"},
	"pecas_raras": {"nome": "Peças raras", "cat": "pecas", "icone": "it_pecas_raras", "preco": 0.0, "onde": "pecas_raras"},
	# Bloco 94: o que se fabrica pra USAR (carpintaria e ferreiro)
	"cama_boa": {"nome": "Cama de tábua", "cat": "equipamento", "icone": "it_cama_boa", "preco": 30.0, "onde": "itens"},
	"mochila": {"nome": "Mochila de couro", "cat": "equipamento", "icone": "it_mochila", "preco": 15.0, "onde": "itens"},
	# Bloco 107: o que a Carvoaria, o Curtume e a cozinha fabricam por ordem (não vendem: são insumo); ícones do PixelLab
	"carvao_vegetal": {"nome": "Carvão vegetal", "cat": "madeira", "icone": "carvao_vegetal", "preco": 0.0, "onde": "itens"},
	"couro_curtido": {"nome": "Couro curtido", "cat": "pecas", "icone": "couro_curtido", "preco": 0.0, "onde": "itens"},
	"racao": {"nome": "Ração de expedição", "cat": "comida", "icone": "racao", "preco": 0.0, "onde": "itens"},
}


static func existe(id: String) -> bool:
	return ITENS.has(id)


static func nome(id: String) -> String:
	return ITENS[id].nome if ITENS.has(id) else Ores.display_name(id)


static func categoria(id: String) -> String:
	return ITENS[id].cat if ITENS.has(id) else ""


## Bloco 106: os COMPARTIMENTOS do armazém (lógicos, no mesmo prédio) e o nome deles na tela. Ficam aqui (dados puros)
## pra a Economia, o HUD e a janela usarem sem carregar o armazem.gd.
const COMPARTIMENTOS := ["alimentos", "madeira", "minerios", "manufaturados"]
const NOME_COMPARTIMENTO := {"alimentos": "alimentos", "madeira": "madeira", "minerios": "minérios e barras",
	"manufaturados": "manufaturados"}


## O compartimento de um item/minério: comida -> alimentos; madeira/tábua -> madeira; minério/metal -> minérios e
## barras; o resto (couro, pregos, ferragens, equipamento) -> manufaturados.
static func compartimento(id: String) -> String:
	if id in Ores.TYPES:
		return "minerios"
	match categoria(id):
		"comida":
			return "alimentos"
		"madeira":
			return "madeira"
		"minerio", "metal":
			return "minerios"
	return "manufaturados"


static func onde(id: String) -> String:
	return ITENS[id].onde if ITENS.has(id) else ""


static func icone(id: String) -> String:
	return ITENS[id].icone if ITENS.has(id) else ""


## Preço de venda base (créditos por unidade). A Economia pode trocar (precos_itens) e os minérios usam os
## @export dela.
static func preco_base(id: String) -> float:
	return float(ITENS[id].preco) if ITENS.has(id) else 0.0


## Itens de uma categoria, na ordem do catálogo.
static func da_categoria(cat: String) -> Array:
	return ITENS.keys().filter(func(k): return ITENS[k].cat == cat)


## Ids guardados no dicionário `itens` dos armazéns (os processados).
static func processados() -> Array:
	return ITENS.keys().filter(func(k): return ITENS[k].onde == "itens")


## Bloco 107: o que vale no lugar do insumo da receita, na ORDEM de uso: "carvão" aceita o vegetal (o que o jogador mandou
## fazer) primeiro e o mineral depois. Quem paga insumo (production_queue.gd) usa isto.
const EQUIVALENTES := {"carvao": ["carvao_vegetal", "carvao"]}


## Bloco 87: nome no plural pros custos ("20 barras de ferro").
const PLURAL := {"barra_ferro": "barras de ferro", "barra_cobre": "barras de cobre", "barra_prata": "barras de prata",
	"lingote_solar": "lingotes solares", "aco": "aço", "prego": "pregos", "ferragem": "ferragens",
	"tabua": "tábuas", "cama_boa": "camas de tábua", "mochila": "mochilas",  # Bloco 94
	"carvao_vegetal": "carvões vegetais", "couro_curtido": "couros curtidos", "racao": "rações"}  # Bloco 107


static func plural(id: String) -> String:
	return PLURAL.get(id, nome(id).to_lower())


## Nome da categoria pra mostrar.
static func nome_categoria(cat: String) -> String:
	return NOMES_CATEGORIA.get(cat, cat)
