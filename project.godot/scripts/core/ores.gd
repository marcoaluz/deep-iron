extends RefCounted
## Catálogo dos tipos de minério (use com preload: const Ores := preload("res://scripts/core/ores.gd")).
##
##   ferro  — minério inicial, qualquer picareta minera.
##   cobre  — precisa da "Picareta de aço temperado" (Oficina).
##   carvão — precisa do "Lampião de segurança" (Oficina).
##   prata  — só no NÍVEL 2 (descida pela escavadeira pronta) + "Broca manual" (Oficina).
##   solarita — só no NÍVEL 3, o abismo (plataforma consertada) + "Traje de chumbo" (Oficina).
##              Rocha que guardou a energia da explosão solar: vale muito.
##   cristal_verde — Bloco 70: cristal das galerias de ácido do S2 (nível 2) + "Broca manual".
##   cristal_rubro — Bloco 70: cristal dos poços de lava do S3 (abismo) + "Traje de chumbo".
##
## Preços de venda ficam na Economia (Inspector); as ferramentas, na Oficina.

## Ordem de exibição (e de gasto: o mais barato primeiro, ver Economy.spend).
const TYPES := ["ferro", "carvao", "cobre", "prata", "cristal_verde", "solarita", "cristal_rubro"]
const NAMES := {"ferro": "Ferro", "cobre": "Cobre", "carvao": "Carvão", "prata": "Prata", "solarita": "Solarita",
	"cristal_verde": "Cristal verde", "cristal_rubro": "Cristal rubro"}
## Cor das lascas que voam ao minerar.
const CHIP_COLORS := {
	"ferro": Color(0.62, 0.34, 0.22),
	"cobre": Color(0.8, 0.5, 0.3),
	"carvao": Color(0.16, 0.16, 0.2),
	"prata": Color(0.85, 0.88, 0.95),
	"solarita": Color(1.0, 0.55, 0.2),
	"cristal_verde": Color(0.55, 1.0, 0.35),
	"cristal_rubro": Color(1.0, 0.25, 0.2),
}
## Cor da barra de carga no HUD e do texto do tipo.
const UI_COLORS := {
	"ferro": Color(0.78, 0.45, 0.25),
	"cobre": Color(0.4, 0.78, 0.66),
	"carvao": Color(0.6, 0.62, 0.75),
	"prata": Color(0.86, 0.9, 1.0),
	"solarita": Color(1.0, 0.62, 0.3),
	"cristal_verde": Color(0.6, 1.0, 0.4),
	"cristal_rubro": Color(1.0, 0.4, 0.35),
}
## Ícone do pedaço de minério (carga em cima da cabeça).
const CHUNK_TEXTURES := {
	"ferro": preload("res://assets/game/ore_chunk.png"),
	"cobre": preload("res://assets/game/chunk_cobre.png"),
	"carvao": preload("res://assets/game/chunk_carvao.png"),
	"prata": preload("res://assets/game/chunk_prata.png"),
	"solarita": preload("res://assets/game/chunk_solarita.png"),
	"cristal_verde": preload("res://assets/game/chunk_cristal_verde.png"),
	"cristal_rubro": preload("res://assets/game/chunk_cristal_rubro.png"),
}


static func display_name(type: String) -> String:
	return NAMES.get(type, type)
