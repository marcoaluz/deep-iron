extends RefCounted
## Prompt 29, parte 2: a ARTE NOVA dos prédios no jogo.
##
## Os desenhos aprovados (prototipos/camera/arte_iso/) foram levados pra assets/game/iso/predios/
## por `python integra.py predios`, com o predios.json: por prédio e por ESTADO (pronto, obra_1..3,
## variação, nível, estágio do Centro, etapa de máquina) a imagem, a ÂNCORA no quadro (centro da
## pegada no chão) e a CAIXA (pegada relativa à âncora + altura, px de arte).
##
## Aqui se decide, só olhando a coisa do jogo (duck typing, nada muda nela):
##   layers(node)  -> o que desenhar: [{tex, ancora, peg, h, obra}] (obra >= 0 = progresso da
##                    peça que está sendo montada: sobe por estágios, obra_estagio.gdshader)
##   base_rect(node) -> a pegada de NAVEGAÇÃO no chão da lógica (a do pronto / escala da vista):
##                    o prédio novo tem fundo de verdade (a casa antiga era uma faixa de 48×14)
##   front(node, off) -> ponto de trabalho na frente do prédio, fora da pegada
## Só vale com o mapa novo (Environment.has_iso_map); sem ele, tudo como antes.

const FILE := "res://assets/game/iso/predios/predios.json"
const DIR := "res://assets/game/iso/predios/"
const ObraEstagio := preload("res://scripts/core/obra_estagio.gd")
## cena do jogo (nome do .tscn) -> prédio no predios.json
const KIND_OF_SCENE := {
	"casa": "casa", "armazem": "armazem", "oficina": "oficina", "arsenal": "arsenal",
	"taverna": "taverna", "enfermaria": "enfermaria", "laboratorio": "laboratorio",
	"comedouro": "comedouro", "parque": "parque", "campo_treino": "campo_treino",
	"vestiario": "vestiario", "coletor_madeira": "coletor_madeira", "escudo": "escudo",
	"escavadeira": "escavadeira", "centro_vila": "centro", "barricada": "portao",
}
## canteiro (canteiro.gd KINDS) -> prédio que vai nascer
const KIND_OF_CANTEIRO := {
	"taverna": "taverna", "laboratorio": "laboratorio", "campo": "campo_treino", "arsenal": "arsenal",
	"comedouro": "comedouro", "parque": "parque", "vestiario": "vestiario", "coletor": "coletor_madeira",
	"enfermaria": "enfermaria",
}
const ESCAVADEIRA_PECAS := ["motor", "hidraulica", "cabine", "broca"]
## Folga entre a pegada e o ponto de trabalho/slot (px da lógica): o boneco fica fora da parede.
const FRONT_GAP := 12.0

static var _data: Dictionary = {}
static var _tex: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(FILE):
		var d = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = d.get("predios", {}) if typeof(d) == TYPE_DICTIONARY else {}
	return _data


static func entry(name: String) -> Dictionary:
	return data().get(name, {})


static func texture(img: String) -> Texture2D:
	if not _tex.has(img):
		_tex[img] = load(DIR + img)
	return _tex[img]


## O ambiente do mapa novo (null = mapa antigo: sem arte nova).
static func _env(node: Node) -> Node:
	if not node.is_inside_tree():
		return null
	var env := node.get_tree().get_first_node_in_group("environment")
	if env and env.has_method("has_iso_map") and env.has_iso_map():
		return env
	return null


static func _is_canteiro(node: Node) -> bool:
	return node.get_script() != null and String(node.get_script().resource_path).ends_with("canteiro.gd")


## O prédio da arte nova desta coisa ("" = não tem).
static func kind_of(node: Node) -> String:
	if _is_canteiro(node):
		return KIND_OF_CANTEIRO.get(node.get("kind"), "")
	var scene := String(node.scene_file_path).get_file().get_basename()
	return KIND_OF_SCENE.get(scene, "")


## Um estado do predios.json pronto pra desenhar: {tex, ancora, peg, h, obra} ({} = não tem).
static func state(entry_name: String, st: String, obra: float = -1.0) -> Dictionary:
	var e: Dictionary = entry(entry_name).get("estados", {})
	if not e.has(st):
		return {}
	var s: Dictionary = e[st]
	return {"tex": texture(s.img), "ancora": Vector2(s.ancora[0], s.ancora[1]),
		"peg": s.get("peg", []), "h": float(s.get("h", 0.0)), "obra": obra}


## Obra por estágios com os desenhos obra_1/2/3 do prédio; sem eles, o pronto subindo pelo corte.
static func _obra_layer(kind: String, progress: float) -> Dictionary:
	var st := ObraEstagio.stage(progress)
	var l := state(kind, "obra_%d" % st)
	if l.is_empty():
		l = state(kind, "pronto", progress)
	return l


## O que desenhar agora. [] = nada da arte nova (a coisa fica com o espelho de sempre).
static func layers(node: Node) -> Array:
	if _env(node) == null:
		return []
	var kind := kind_of(node)
	if kind == "" or (entry(kind).is_empty() and kind != "centro"):
		return []
	var out: Array = []
	if _is_canteiro(node):  # o prédio que vai nascer, subindo pelos desenhos de obra
		if node.obra_pending():
			out.append(_obra_layer(kind, node.obra_progress()))
		return out.filter(func(l): return not l.is_empty())
	match kind:
		"casa":
			if node.has_method("obra_pending") and node.obra_pending():
				out.append(_obra_layer("casa", node.obra_progress()))
			elif not node.get("built"):
				out.append(state("casa", "obra_1"))  # lote (formato antigo)
			else:
				out.append(state("casa", "pronto_%d" % _variant(node, 4)))
		"centro":
			var lv := clampi(int(node.get("level")), 1, 5)
			if node.get("pending_upgrade") == "expandir" and lv < 5:
				# a próxima etapa em obra: andaime por cima do prédio de agora (Prompt 10)
				out.append(state("centro_%d" % (lv + 1), "obra"))
			else:
				out.append(state("centro_%d" % lv, "pronto"))
		"taverna":
			out.append(state("taverna", "nivel_2" if int(node.get("level")) >= 2 else "pronto"))
		"enfermaria":
			var n: int = node.level() if node.has_method("level") else 0
			out.append(state("enfermaria", "nivel_2" if n >= 2 else "pronto"))
		"comedouro":
			out.append(state("comedouro", "com_comida" if float(node.get("food_stock")) > 0.0 else "pronto"))
		"escudo":
			var built := int(node.get("built"))
			if built >= 1:
				out.append(state("escudo", "etapa_%d" % mini(built, 4)))
			if node.has_method("obra_pending") and node.obra_pending() and built < 4:
				var l := state("escudo", "etapa_%d" % (built + 1), node.obra_progress())
				out.append(l)
		"escavadeira":
			out = _escavadeira(node)
		"portao":
			var lvp := int(node.get("level"))
			var standing: bool = node.is_standing() if node.has_method("is_standing") else lvp > 0
			out.append(state("portao", "nivel_%d" % clampi(lvp, 1, 3) if standing and lvp > 0 else "quebrado"))
		_:
			out.append(state(kind, "pronto"))
	return out.filter(func(l): return not l.is_empty())


## Escavadeira (Bloco 32): estrutura + cada peça instalada (recorte do pronto), a peça em
## montagem subindo por estágios, o reator embaixo do convés e o reator novo em obra.
static func _escavadeira(node: Node) -> Array:
	var out: Array = []
	var inst: Dictionary = node.get("installed")
	var fab: String = node.get("fabricating")
	var fp: float = node.fab_progress() if node.has_method("fab_progress") else 0.0
	if node.get("complete"):
		out.append(state("escavadeira", "pronto"))
	elif inst.get("estrutura", false) or fab == "estrutura":
		out.append(state("escavadeira", "estrutura", fp if fab == "estrutura" else -1.0))
		var cam: Dictionary = entry("escavadeira").get("camadas", {})
		for p in ESCAVADEIRA_PECAS:
			if (inst.get(p, false) or fab == p) and cam.has(p):
				var l := {"tex": texture(cam[p].img), "ancora": Vector2(cam[p].ancora[0], cam[p].ancora[1]),
					"peg": [], "h": 0.0, "obra": fp if fab == p else -1.0}
				out.append(l)
	var cam2: Dictionary = entry("escavadeira").get("camadas", {})
	var r: String = node.get("reactor")
	if node.get("complete") and cam2.has("reator_" + r):
		var c: Dictionary = cam2["reator_" + r]
		out.append({"tex": texture(c.img), "ancora": Vector2(c.ancora[0], c.ancora[1]), "peg": [], "h": 0.0, "obra": -1.0})
	var br: String = node.get("building_reactor")
	if br != "" and cam2.has("reator_" + br):
		var c2: Dictionary = cam2["reator_" + br]
		var prog: float = node.obra_progress() if node.has_method("obra_progress") else 0.0
		# o reator novo é montado no chão ao lado da plataforma (à direita)
		out.append({"tex": texture(c2.img), "ancora": Vector2(c2.ancora[0] - 210.0, c2.ancora[1] - 40.0), "peg": [], "h": 0.0, "obra": prog})
	return out


## Variação estável por coisa (a casa 2 é sempre a mesma variação).
static func _variant(node: Node, n: int) -> int:
	var p: Vector2 = (node as Node2D).global_position
	return absi(int(p.x) * 7 + int(p.y) * 13) % n


## A caixa (no chão da vista, px de arte, relativa ao pé) que cobre as camadas: Rect2 + altura.
## {} = nenhuma camada declarou caixa.
static func box_of(layers_list: Array) -> Dictionary:
	var r := Rect2()
	var h := 0.0
	var first := true
	for l in layers_list:
		var p: Array = l.peg
		if p.size() < 4:
			continue
		var q := Rect2(p[0], p[1], p[2] - p[0], p[3] - p[1])
		r = q if first else r.merge(q)
		h = maxf(h, l.h)
		first = false
	return {} if first else {"rect": r, "h": h}


## Pegada de navegação no chão da LÓGICA (global). Rect2() = sem arte nova (usa a de sempre).
static func base_rect(node: Node) -> Rect2:
	var env := _env(node)
	if env == null:
		return Rect2()
	var kind := kind_of(node)
	if kind == "":
		return Rect2()
	var name := kind
	if kind == "centro":
		name = "centro_%d" % clampi(int(node.get("level")), 1, 5)
	var b: Array = entry(name).get("base", [])
	if b.size() < 4:
		return Rect2()
	var k: float = env.iso_scale()
	var p: Vector2 = (node as Node2D).global_position
	return Rect2(p + Vector2(b[0], b[1]) / k, Vector2(b[2] - b[0], b[3] - b[1]) / k)


## Pegada que um prédio desse tipo vai ocupar (pro posicionador), relativa ao ponto clicado.
## Rect2() = sem arte nova. `name` = o nome no predios.json (centro: o maior estágio).
static func footprint_of(tree: SceneTree, name: String) -> Rect2:
	var env := tree.get_first_node_in_group("environment")
	if env == null or not env.has_method("has_iso_map") or not env.has_iso_map():
		return Rect2()
	var b: Array = entry(name).get("base", [])
	if b.size() < 4:
		return Rect2()
	var k: float = env.iso_scale()
	return Rect2(Vector2(b[0], b[1]) / k, Vector2(b[2] - b[0], b[3] - b[1]) / k)


## Ponto de trabalho na FRENTE do prédio (lado SO da arte = +y no chão), fora da pegada.
static func front(node: Node2D, off: Vector2) -> Vector2:
	var p := node.global_position + off
	var r := base_rect(node)
	if r.has_area():
		p.y = maxf(p.y, r.end.y + FRONT_GAP)
		p.x = clampf(p.x, r.position.x + 6.0, r.end.x - 6.0)
	return p


# ------------------------------------------------------------ posicionador
## O prédio da arte nova que o posicionador está pondo, pela textura antiga que ele recebe
## ("" = sem arte nova). O Centro reserva o espaço do maior estágio (ele cresce no lugar).
static func name_for_texture(tex: Texture2D) -> String:
	if tex == null:
		return ""
	var k: String = KIND_OF_SCENE.get(tex.resource_path.get_file().get_basename(), "")
	return "centro_5" if k == "centro" else k


## Pegada pra posicionar (relativa ao ponto clicado): a do desenho + o degrau da porta na frente.
static func placer_footprint(tree: SceneTree, name: String) -> Rect2:
	var f := footprint_of(tree, name)
	if not f.has_area():
		return f
	f = f.grow(4.0)
	f.size.y += FRONT_GAP + 8.0
	return f


## Área que um prédio que já existe tira do posicionador (o Centro: a do maior estágio).
static func blocker_rect(node: Node) -> Rect2:
	var r := base_rect(node)
	if r.has_area() and kind_of(node) == "centro":
		var f := footprint_of(node.get_tree(), "centro_5")
		r = r.merge(Rect2((node as Node2D).global_position + f.position, f.size))
	return r


## O desenho do fantasma do posicionador: o prédio pronto (o Centro: o 1º estágio).
static func preview(name: String) -> Dictionary:
	if name.begins_with("centro"):
		return state("centro_1", "pronto")
	for s in ["pronto", "pronto_0", "etapa_4", "nivel_1"]:
		var l := state(name, s)
		if not l.is_empty():
			return l
	return {}


## Contorno (4 cantos) de um retângulo do chão: pra get_obstacle_outline.
static func outline(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
