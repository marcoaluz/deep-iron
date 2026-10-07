extends RefCounted
## Bloco 68: os NÍVEIS DA MINA por dados (res://data/niveis/*.tres, recurso nivel_mina.gd).
##   const Niveis := preload("res://scripts/core/niveis.gd")
##   Niveis.todos() -> [NivelMina...] por profundidade     Niveis.por_id("S2")
##   Niveis.do_ponto(env, pos) -> o nível onde fica o ponto  Niveis.motivo(tree, nivel) -> "" = liberado

const DIR := "res://data/niveis/"

static var _lista: Array = []


static func todos() -> Array:
	if _lista.is_empty():
		var nomes := DirAccess.get_files_at(DIR)
		for f in nomes:
			var arq := String(f).trim_suffix(".remap")
			if not arq.ends_with(".tres"):
				continue
			var r = load(DIR + arq)
			if r != null and r.get("id") != null:
				_lista.append(r)
		_lista.sort_custom(func(a, b): return a.profundidade < b.profundidade)
	return _lista


static func por_id(id: String) -> Resource:
	for n in todos():
		if n.id == id:
			return n
	return null


## Os níveis jogáveis (sem os "em breve").
static func jogaveis() -> Array:
	return todos().filter(func(n): return not n.em_breve)


## O nível de um ponto do chão (S1 = a pedreira/vila e a clareira; S2 = nível 2; S3 = abismo).
static func do_ponto(env: Node, pos: Vector2) -> Resource:
	var area := "mapa"
	if env and env.has_method("area_at"):
		area = env.area_at(pos)  # Bloco 71: inclui os níveis novos (S4, S5)
	elif env and env.has_method("is_abyss") and env.is_abyss(pos):
		area = "abyss"
	elif env and env.has_method("is_deep") and env.is_deep(pos):
		area = "deep"
	elif env and env.get("map_rect") != null and pos.y < (env.map_rect as Rect2).position.y:
		area = "clareira"
	for n in todos():
		if n.area == area and not n.em_breve:
			return n
	return null


## Por que esse nível ainda não abriu ("" = liberado).
static func motivo(tree: SceneTree, n: Resource) -> String:
	if n == null:
		return "nível desconhecido"
	if n.em_breve:
		return "em breve"
	if n.ligacao != "":
		var lig := tree.get_first_node_in_group(n.ligacao)
		if lig == null:
			return "sem ligação"
		if not bool(lig.get("unlocked")):
			return String(lig.call("reason_locked")) if lig.has_method("reason_locked") else "a descida está fechada"
	if n.pesquisa != "":
		var res := tree.get_first_node_in_group("research")
		if res and not res.has(n.pesquisa):
			var nm: String = res.TECHS[n.pesquisa].name if res.TECHS.has(n.pesquisa) else n.pesquisa
			return "precisa pesquisar: %s" % nm
	return ""


static func liberado(tree: SceneTree, n: Resource) -> bool:
	return motivo(tree, n) == ""


## O que falta pra descer: pesquisa (antes da ligação abrir) — usado pela ligação pra travar.
static func pesquisa_falta(tree: SceneTree, id: String) -> String:
	var n := por_id(id)
	if n == null or n.pesquisa == "":
		return ""
	var res := tree.get_first_node_in_group("research")
	if res and not res.has(n.pesquisa):
		var nm: String = res.TECHS[n.pesquisa].name if res.TECHS.has(n.pesquisa) else n.pesquisa
		return "precisa pesquisar: %s" % nm
	return ""
