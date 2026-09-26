extends RefCounted
## Catálogo dos tipos de minério (use com preload: const Ores := preload("res://scripts/core/ores.gd")).
##
##   ferro  — minério inicial, qualquer picareta minera.
##   cobre  — precisa da "Picareta de aço temperado" (Oficina).
##   carvão — precisa do "Lampião de segurança" (Oficina).
##
## Preços de venda ficam na Economia (Inspector); as ferramentas, na Oficina.

## Ordem de exibição (e de gasto: o mais barato primeiro, ver Economy.spend).
const TYPES := ["ferro", "carvao", "cobre"]
const NAMES := {"ferro": "Ferro", "cobre": "Cobre", "carvao": "Carvão"}
## Cor das lascas que voam ao minerar.
const CHIP_COLORS := {
	"ferro": Color(0.62, 0.34, 0.22),
	"cobre": Color(0.8, 0.5, 0.3),
	"carvao": Color(0.16, 0.16, 0.2),
}
## Cor da barra de carga no HUD e do texto do tipo.
const UI_COLORS := {
	"ferro": Color(0.78, 0.45, 0.25),
	"cobre": Color(0.4, 0.78, 0.66),
	"carvao": Color(0.6, 0.62, 0.75),
}
## Ícone do pedaço de minério (carga em cima da cabeça).
const CHUNK_TEXTURES := {
	"ferro": preload("res://assets/game/ore_chunk.png"),
	"cobre": preload("res://assets/game/chunk_cobre.png"),
	"carvao": preload("res://assets/game/chunk_carvao.png"),
}


static func display_name(type: String) -> String:
	return NAMES.get(type, type)
