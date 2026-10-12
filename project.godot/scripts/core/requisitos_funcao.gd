extends RefCounted
## Bloco 128: os REQUISITOS DA FUNÇÃO. Cada função diz o que precisa pra ter trabalho (arco, toca estudada, horta,
## Fornalha com ordem...) e o jogo mostra isso com ✓/✗ — no cartão que abre ao dar a função, no cartão do selecionado,
## na dica do botão da função e no balão de "parado" (o motivo específico em vez de "sem trabalho").
##
## - Os requisitos vêm de DADOS: data/funcoes/requisitos.json ({id, teste} por função + os "caminhos": a função tem trabalho
##   se TODOS os ids de PELO MENOS UM caminho passam; requisito fora de todo caminho só informa) e os textos de
##   data/funcoes/textos.txt (resumo, <id>.ok, <id>.falta, <id>.falta.<variante>, sem_trabalho).
## - O TESTE de cada requisito é um nome (match em `_teste`): devolve "" se passa, ou a variante da falta ("falta" é a
##   padrão; "variante:detalhe" traz o {d} do texto). Requisito novo = uma entrada no JSON + o texto + um teste aqui.
## - Tudo é lido na hora (só olha o estado que o jogo já tem), nada é guardado: não entra no save.
## - `w` (o ipezinho) é opcional: com ele, o teste usa o que a IA dele usa (estação usável, andar liberado, área de
##   trabalho); sem ele, olha a vila em geral.

const ARQ := "res://data/funcoes/requisitos.json"
const ARQ_TEXTOS := "res://data/funcoes/textos.txt"
const OK := "✓"
const FALTA := "✗"

static var _dados: Dictionary = {}
static var _textos: Dictionary = {}  # função -> {chave: texto}
static var _lido := false


## Lê os arquivos uma vez (o `forcar` serve ao teste que edita os dados).
static func carrega(forcar := false) -> void:
	if _lido and not forcar:
		return
	_lido = true
	_dados = {}
	_textos = {}
	if FileAccess.file_exists(ARQ):
		var j = JSON.parse_string(FileAccess.get_file_as_string(ARQ))
		if j is Dictionary:
			for k in j:
				if not String(k).begins_with("_") and j[k] is Dictionary:
					_dados[String(k)] = j[k]
	if FileAccess.file_exists(ARQ_TEXTOS):
		var secao := ""
		var chave := ""
		for bruta in FileAccess.get_file_as_string(ARQ_TEXTOS).split("\n"):
			var ln: String = bruta.strip_edges(false, true)
			if ln.strip_edges().begins_with("#"):
				continue
			if ln.begins_with("[") and ln.ends_with("]"):
				secao = ln.substr(1, ln.length() - 2)
				_textos[secao] = {}
				chave = ""
				continue
			if secao == "" or ln.strip_edges() == "":
				continue
			var i := ln.find(" = ")
			if i > 0 and not ln.begins_with(" ") and not ln.begins_with("\t"):
				chave = ln.substr(0, i).strip_edges()
				_textos[secao][chave] = ln.substr(i + 3).strip_edges()
			elif chave != "":
				_textos[secao][chave] = String(_textos[secao][chave]) + " " + ln.strip_edges()


static func funcoes() -> Array:
	carrega()
	return _dados.keys()


static func tem(job: String) -> bool:
	carrega()
	return _dados.has(job)


static func texto(job: String, chave: String, padrao := "") -> String:
	carrega()
	return String((_textos.get(job, {}) as Dictionary).get(chave, padrao))


static func resumo(job: String) -> String:
	return texto(job, "resumo")


## Os ids dos requisitos da função, na ordem do arquivo.
static func ids(job: String) -> Array:
	carrega()
	var out: Array = []
	for r in (_dados.get(job, {}) as Dictionary).get("requisitos", []):
		out.append(String(r.get("id", "")))
	return out


## Avalia a função AGORA. {funcao, resumo, itens: [{id, ok, texto, variante}], pode, primeiro (o texto do primeiro que falta
## no primeiro caminho que não passa; "" se pode), sem_trabalho (o texto de "tudo certo e nada pra fazer")}.
static func avalia(arvore: SceneTree, job: String, w: Node = null) -> Dictionary:
	carrega()
	var d: Dictionary = _dados.get(job, {})
	var out := {"funcao": job, "resumo": resumo(job), "itens": [], "pode": true, "primeiro": "",
		"sem_trabalho": texto(job, "sem_trabalho", "Nada pra fazer agora.")}
	if d.is_empty() or arvore == null:
		return out
	var por_id := {}
	for r in d.get("requisitos", []):
		var rid := String(r.get("id", ""))
		var res := _teste(arvore, String(r.get("teste", "")), w)
		var ok := res == ""
		var variante := "" if ok else res.split(":")[0]
		var detalhe := "" if ok or not ":" in res else res.substr(res.find(":") + 1)
		var t := ""
		if ok:
			t = texto(job, rid + ".ok", rid)
		else:
			t = texto(job, "%s.falta.%s" % [rid, variante], texto(job, rid + ".falta", "Falta: " + rid))
			t = t.replace("{d}", detalhe)
		var item := {"id": rid, "ok": ok, "texto": t, "variante": variante}
		(out.itens as Array).append(item)
		por_id[rid] = item
	var caminhos: Array = d.get("caminhos", [])
	if caminhos.is_empty():
		caminhos = [por_id.keys()]
	# Os caminhos estão por prioridade (o principal da função primeiro): o motivo é o primeiro que falta do PRIMEIRO caminho
	# que não passa (o caçador sem arco ouve "falta o arco", mesmo que a horta também pudesse ocupá-lo).
	var primeiro := ""
	var pode := false
	for c in caminhos:
		var prim := ""
		for rid in c:
			var it: Dictionary = por_id.get(String(rid), {})
			if not it.is_empty() and not bool(it.ok):
				prim = String(it.texto)
				break
		if prim == "":
			pode = true
			break
		if primeiro == "":
			primeiro = prim
	out.pode = pode
	out.primeiro = "" if pode else primeiro
	return out


## As linhas do cartão: "✓ Tem arco" / "✗ Falta o arco: a Oficina faz".
static func linhas(av: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for it in av.get("itens", []):
		out.append("%s %s" % [OK if bool(it.ok) else FALTA, it.texto])
	return out


## O texto de um parado: o que falta (função com requisito que falha) ou "tudo certo, nada pra fazer".
static func motivo(arvore: SceneTree, job: String, w: Node = null) -> String:
	if not tem(job):
		return ""
	var av := avalia(arvore, job, w)
	return String(av.primeiro) if not bool(av.pode) else String(av.sem_trabalho)


# ------------------------------------------------------------ os testes
static func _grupo(arvore: SceneTree, g: String) -> Array:
	return arvore.get_nodes_in_group(g)


## Tem estação usável do grupo? Com o ipezinho, pela escolha dele (área, andar liberado, vaga); sem ele, só `is_usable`.
static func _usavel(arvore: SceneTree, w: Node, g: String) -> bool:
	if w != null and w.has_method("_has_usable_station"):
		return w._has_usable_station(g)
	for n in arvore.get_nodes_in_group(g):
		if not n.has_method("is_usable") or n.is_usable():
			return true
	return false


static func _sem_espaco(arvore: SceneTree, w: Node, cat: String) -> bool:
	if w != null and w.has_method("_sem_espaco"):
		return w._sem_espaco(cat)
	var eco := arvore.get_first_node_in_group("economy")
	return eco != null and eco.has_method("armazens_cheios") and eco.armazens_cheios(cat)


static func _agricultor(arvore: SceneTree, w: Node) -> bool:
	if w != null and w.has_method("_agricultor_na_vila"):
		return w._agricultor_na_vila()
	return arvore.get_nodes_in_group("ipezinhos").any(func(o): return o.has_method("is_farmer") and o.is_farmer())


static func _ordem_de(arvore: SceneTree, grupo: String) -> String:
	var com_ordem := 0
	var falta := ""
	for f in arvore.get_nodes_in_group(grupo):
		if f.get("fila") == null or not f.fila.tem_trabalho():
			continue
		com_ordem += 1
		var fl: String = f.falta() if f.has_method("falta") else ""
		if fl == "":
			return ""
		if falta == "":
			falta = fl
	if com_ordem == 0:
		return "falta"
	return "pausada:" + falta


static func _teste(arvore: SceneTree, teste: String, w: Node) -> String:
	match teste:
		"jazida":
			if _usavel(arvore, w, "minerios"):
				return ""
			for m in _grupo(arvore, "minerios"):
				if m.has_method("is_unlocked") and not m.is_unlocked() and float(m.get("ore_remaining") if m.get("ore_remaining") != null else 0.0) > 0.0:
					return "ferramenta"
			return "falta"
		"espaco_minerios":
			return "falta" if _sem_espaco(arvore, w, "minerios") else ""
		"arvore":
			return "" if _usavel(arvore, w, "arvores") else "falta"
		"espaco_madeira":
			return "falta" if _sem_espaco(arvore, w, "madeira") else ""
		"espaco_alimentos":
			return "falta" if _sem_espaco(arvore, w, "alimentos") else ""
		"arco":
			var of := arvore.get_first_node_in_group("oficina")
			if of == null or (of.has_method("is_built") and not of.is_built()):
				return "sem_oficina"
			return "" if of.has_tool("arco") else "falta"
		"toca_estudada":
			var tocas := _grupo(arvore, "caca")
			if tocas.is_empty():
				return "sem_toca"
			for t in tocas:
				if not t.has_method("conhecida") or t.conhecida():
					return ""
			return "falta"
		"horta_do_cacador":
			if _grupo(arvore, "coleta_comida").is_empty():
				return "falta"
			if _agricultor(arvore, w):
				return "agricultor"
			return "" if _usavel(arvore, w, "coleta_comida") else "descansando"
		"horta":
			if _grupo(arvore, "coleta_comida").is_empty():
				return "falta"
			return "" if _usavel(arvore, w, "coleta_comida") else "descansando"
		"cozinha":
			return "" if not _grupo(arvore, "comedouros").is_empty() else "falta"
		"materia_prima":
			for a in _grupo(arvore, "armazens"):
				if a.get("raw_stored") != null and a.raw_stored >= 0.5:
					return ""
			if w != null and w.has_method("_cozinha_com_estoque") and w._cozinha_com_estoque() != null:
				return ""
			return "falta"
		"fornalha":
			return "" if not _grupo(arvore, "fornalhas").is_empty() else "falta"
		"ordem_fornalha":
			return _ordem_de(arvore, "fornalhas")
		"oficina_ou_arsenal":
			var of2 := arvore.get_first_node_in_group("oficina")
			if of2 != null and (not of2.has_method("is_built") or of2.is_built()):
				return ""
			return "" if not _grupo(arvore, "arsenais").is_empty() else "falta"
		"encomenda_ferreiro":
			if w != null and w.has_method("_pick_obra"):
				return "" if w._pick_obra() != null else "falta"
			for s in _grupo(arvore, "obras"):
				if s.has_method("obra_pending") and s.obra_pending() and str(s.get("oficio")) == "ferreiro":
					return ""
			return "falta"
		"carpintaria":
			return "" if not _grupo(arvore, "carpintarias").is_empty() else "falta"
		"ordem_carpintaria":
			if w != null and w.has_method("_casa_pra_cama") and w._casa_pra_cama() != null:
				return ""
			return _ordem_de(arvore, "carpintarias")
		"obra_pendente":
			if w != null and w.has_method("_pick_obra"):
				return "" if w._pick_obra() != null else "falta"
			for s in _grupo(arvore, "obras"):
				if s.has_method("obra_pending") and s.obra_pending():
					return ""
			return "falta"
		"entrega":
			var lg := arvore.get_first_node_in_group("logistica")
			if lg == null:
				return "falta"
			if w != null and lg.has_method("tem_entrega_para"):
				return "" if lg.tem_entrega_para(w) or not (w.get("_carga") as Dictionary).is_empty() else "falta"
			return "" if not lg.entregas_abertas().is_empty() else "falta"
		"maquina_gasta":
			var mt := arvore.get_first_node_in_group("manutencao")
			if mt == null:
				return "falta"
			for m in mt.maquinas():
				if m.manut_quebrada():
					return ""
			return "" if mt.alvo_preventiva(w) != null else "falta"
		"enfermaria":
			return "" if not _grupo(arvore, "enfermarias").is_empty() else "falta"
		"laboratorio":
			return "" if not _grupo(arvore, "laboratorios").is_empty() else "falta"
		"pesquisa_andando":
			var res := arvore.get_first_node_in_group("research")
			return "" if res != null and str(res.get("current")) not in ["", "<null>"] else "falta"
		"alvo_catalogo":
			var cat := arvore.get_first_node_in_group("catalogo")
			return "" if cat != null and w != null and cat.tem_alvo(w) else "falta"
		"igreja":
			return "" if not _grupo(arvore, "igrejas").is_empty() else "falta"
		"cemiterio":
			return "" if not _grupo(arvore, "cemiterios").is_empty() else "falta"
		"toca_a_rastrear":
			return "" if not _grupo(arvore, "caca").is_empty() else "falta"
		"muro":
			for b in _grupo(arvore, "barricadas"):
				if int(b.get("level") if b.get("level") != null else 0) >= 1:
					return ""
			return "falta"
		"arsenal":
			return "" if not _grupo(arvore, "arsenais").is_empty() else "falta"
		"campo_treino":
			return "" if not _grupo(arvore, "campos").is_empty() else "falta"
	return "falta"
