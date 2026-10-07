extends RefCounted
## Prompt 19: LUZ E NOITE na vista iso.
##
## - Uma textura por tipo de luz (assets/game/iso/luz/, `python integra.py luz`): branca em faixas;
##   a cor, a força e o alcance de cada tipo ficam aqui (TIPOS).
## - Cada luz que o jogo já tem (a janela da casa, a forja, a lanterna do capacete, a tocha, o
##   cristal...) ganha o tipo dela pelo nome do nó e por quem é o dono (tipo_de); nos prédios com
##   arte nova, vai pro PONTO DE LUZ anotado no desenho (predios.json -> "luzes").
## - Janelas acesas: a máscara do desenho (predios.json -> "janelas") aparece à noite quando a luz
##   do prédio está acesa, com a cor compensada pelo ambiente (fica clara mesmo no escuro).
## - A cor do ambiente por período já vem do DayNight; por estação, day_night.gd (season_tints).

const DIR := "res://assets/game/iso/luz/"
## tipo -> cor, ganho (multiplica a força que o jogo põe: acender/apagar e piscar continuam do
## jogo), alcance (texture_scale da textura de 128 px). A lava não tem dono: o ganho é a força dela.
const TIPOS := {
	"tocha": {"cor": Color(1.0, 0.62, 0.28), "forca": 1.4, "alcance": 1.1},
	"lampiao": {"cor": Color(1.0, 0.78, 0.42), "forca": 1.6, "alcance": 0.9},
	"fogueira": {"cor": Color(1.0, 0.55, 0.22), "forca": 1.7, "alcance": 1.7},
	"forja": {"cor": Color(1.0, 0.42, 0.16), "forca": 1.7, "alcance": 1.4},
	"lanterna": {"cor": Color(1.0, 0.92, 0.7), "forca": 1.2, "alcance": 0.7},
	"reator": {"cor": Color(0.45, 1.0, 0.75), "forca": 1.3, "alcance": 1.3},
	"cristal": {"cor": Color(0.6, 0.85, 1.0), "forca": 1.3, "alcance": 1.0},
	"lava": {"cor": Color(1.0, 0.35, 0.1), "forca": 1.2, "alcance": 3.0},
	"janela": {"cor": Color(1.0, 0.7, 0.38), "forca": 1.7, "alcance": 1.2},
	"cabine": {"cor": Color(0.85, 0.95, 1.0), "forca": 1.2, "alcance": 0.9},
	"giroflex": {"cor": Color(1.0, 0.3, 0.2), "forca": 1.3, "alcance": 0.8},
}
## nome do nó de luz -> tipos preferidos (o primeiro que o desenho anotar)
const POR_NOME := {
	"ForgeLight": ["forja"], "CabLight": ["cabine"], "Beacon": ["giroflex"], "FireLight": ["fogueira"], "WorkLight": ["reator", "cabine"],
	"HeadLamp": ["lanterna"], "EyeLight": ["reator"], "Lamp": ["lampiao"],
	"WindowLight": ["janela", "fogueira", "lampiao"], "Glow": ["reator", "janela"], "Light": ["lampiao", "janela"],
}
## Cor de compensação máxima das janelas (contra o ambiente escuro): limite pra não estourar.
const COMP_MAX := 4.0

static var _tex: Dictionary = {}


static func texture(tipo: String) -> Texture2D:
	if not _tex.has(tipo):
		_tex[tipo] = load(DIR + tipo + ".png") if ResourceLoader.exists(DIR + tipo + ".png") else null
	return _tex[tipo]


## Tipo de uma luz do jogo pelo nome e pelo dono ("" = deixa como está).
static func tipo_de(light: Node) -> String:
	var dono := light.get_parent()
	if dono is Sprite2D and (dono as Sprite2D).texture:
		var t := (dono as Sprite2D).texture.resource_path.get_file()
		if t.begins_with("torch"):
			return "tocha"
		if t.begins_with("crystal"):
			return "cristal"
	var pref: Array = POR_NOME.get(String(light.name), [])
	return pref[0] if not pref.is_empty() else ""


## O ponto de luz anotado no desenho pra essa luz: {tipo, pos (px de arte, relativo ao pé)} ou {}.
static func ponto_para(light: Node, luzes: Array, usados: Dictionary) -> Dictionary:
	var pref: Array = POR_NOME.get(String(light.name), [])
	for tipo in pref:
		for i in luzes.size():
			if luzes[i].tipo == tipo and not usados.has(i):
				usados[i] = true
				return luzes[i]
	for i in luzes.size():  # sem tipo combinando: o primeiro ponto livre
		if not usados.has(i):
			usados[i] = true
			return luzes[i]
	return {}


## Aplica o tipo na cópia da luz (textura, cor, alcance). `fonte` = a luz do jogo: a força dela
## (acende/apaga, pisca) vezes o ganho do tipo.
static func aplica(d: PointLight2D, tipo: String, manter_cor: bool = false, fonte: PointLight2D = null) -> void:
	var cfg: Dictionary = TIPOS.get(tipo, {})
	if cfg.is_empty():
		return
	var tx := texture(tipo)
	if tx and d.texture != tx:
		d.texture = tx
	if not manter_cor:
		d.color = cfg.cor
	d.texture_scale = cfg.alcance
	if fonte:
		d.energy = fonte.energy * cfg.forca


## Cor das janelas acesas agora: compensa o ambiente (CanvasModulate) pra o vidro ficar claro no
## escuro; o alfa sobe com a escuridão.
static func cor_janela(tree: SceneTree) -> Color:
	var dn := tree.get_first_node_in_group("day_night")
	var dark: float = dn.darkness() if dn and dn.has_method("darkness") else 0.0
	var amb := Color.WHITE
	var cm := tree.current_scene.get_node_or_null("Ambient") if tree.current_scene else null
	if cm is CanvasModulate:
		amb = (cm as CanvasModulate).color
	var c := Color(minf(1.0 / maxf(amb.r, 0.05), COMP_MAX), minf(1.0 / maxf(amb.g, 0.05), COMP_MAX), minf(1.0 / maxf(amb.b, 0.05), COMP_MAX))
	c.a = smoothstep(0.25, 0.7, dark)
	return c
