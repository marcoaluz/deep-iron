extends Node
## Bloco 100: o SISTEMA DE MISSÕES (nó "Missoes" na cena, grupo "missoes"; seção 21 do guia). A campanha é em CAPÍTULOS;
## cada missão é um recurso (missao.gd, um .tres em res://data/missoes/) com objetivos, recompensa e pré-requisitos, e os
## TEXTOS ficam num arquivo por capítulo (res://data/missoes/capitulo_N.txt: fácil de editar, ver o cabeçalho dele).
##
## Como mede: escuta os sinais que o jogo já tem — minério vendido (economy.ore_sold), pesquisa pronta
## (research.researched), fim de invasão (defense.invasion_ended), morte (ipezinho.died), estágio novo
## (centro_vila.level_changed) e, novo neste bloco, obra pronta (centro_vila.obra_pronta, só avisa: não muda nada) — e
## CONFERE os contadores a cada segundo. Objetivo cumprido fica cumprido (não desfaz se vender o minério depois).
## Cumpriu todos os objetivos: a recompensa (créditos, página do diário, itens, libera o capítulo seguinte) e o aviso.
## Janela "Missões" (missoes_panel.gd, tecla vírgula) e o rastreador do canto direito (ui/rastreador_missoes.gd).
## Save: chave "missoes". Save antigo (sem a chave) começa no capítulo certo: confere o que a vila já fez
## (contadores refeitos do estado: invasões que já passaram, mortes, estágio...) e entrega o que já estava cumprido.

signal mudou
signal missao_cumprida(id: String)
signal objetivo_cumprido(id: String, indice: int)

## Bloco 112: a missão do primeiro dia guiado (o capataz do guia.gd segue os objetivos dela).
const PRIMEIRO_DIA := "cap1_primeiro_dia"

const SaveUtil := preload("res://scripts/core/save_util.gd")
const Missao := preload("res://scripts/core/missao.gd")
const DIR := "res://data/missoes/"
## O capítulo que existe até aqui (o seguinte "ainda está sendo escrito").
const ULTIMO_CAPITULO := 6

## De quanto em quanto tempo (s) confere os contadores.
@export var confere_a_cada: float = 1.0

static var _lista: Array = []
static var _textos_cache := {}

## O maior capítulo liberado, as missões cumpridas (ids), os objetivos já cumpridos de cada missão
## ({id: [índices]}) e os contadores dos eventos.
var capitulo_liberado := 1
var cumpridas: Array[String] = []
var feitos := {}
var contadores := {"invasoes": 0, "vendido": 0.0, "mortes": 0, "obras": {}}
var _t := 0.0
var _silencio := false


func _ready() -> void:
	add_to_group("missoes")
	_liga.call_deferred()


## Liga nos sinais que o jogo já tem (depois que todos os nós entraram na árvore).
func _liga() -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and eco.has_signal("ore_sold"):
		eco.ore_sold.connect(func(vendido: float, _ganho: float): contadores.vendido = float(contadores.vendido) + vendido)
	var def := get_tree().get_first_node_in_group("defense")
	if def and def.has_signal("invasion_ended"):
		def.invasion_ended.connect(func(_mortos: int):
			contadores.invasoes = int(contadores.invasoes) + 1
			confere())
	var res := get_tree().get_first_node_in_group("research")
	if res and res.has_signal("researched"):
		res.researched.connect(func(_id: String): confere())
	var exped := get_tree().get_first_node_in_group("expedicoes")
	if exped and exped.has_signal("expedicao_voltou"):  # Bloco 104
		exped.expedicao_voltou.connect(func(_r: String, _res: Dictionary): confere())
		exped.regiao_revelada.connect(func(_id: String): confere())
	var cat := get_tree().get_first_node_in_group("catalogo")
	if cat and cat.has_signal("entrada_estudada"):  # Bloco 102: o objetivo "estudar"
		cat.entrada_estudada.connect(func(_id: String, _categoria: String): confere())
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub:
		if hub.has_signal("level_changed"):
			hub.level_changed.connect(func(_n: int): confere())
		if hub.has_signal("obra_pronta"):
			hub.obra_pronta.connect(func(tipo: String):
				var o: Dictionary = contadores.obras
				o[tipo] = int(o.get(tipo, 0)) + 1
				confere())
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		_vigia(w)
	get_tree().node_added.connect(func(n: Node):
		if n.is_in_group("ipezinhos"):
			_vigia(n))
	confere()


func _vigia(w: Node) -> void:
	if w.has_signal("died") and not w.died.is_connected(_morreu):
		w.died.connect(_morreu)


func _morreu(_nome: String) -> void:
	contadores.mortes = int(contadores.mortes) + 1
	confere()


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = confere_a_cada
		confere()


# ------------------------------------------------------------ os dados (.tres) e os textos (.txt)
## Todas as missões, por capítulo e ordem.
static func todas() -> Array:
	if _lista.is_empty():
		for f in DirAccess.get_files_at(DIR):
			var arq := String(f).trim_suffix(".remap")
			if not arq.ends_with(".tres"):
				continue
			var r = load(DIR + arq)
			if r != null and r.get("id") != null and String(r.id) != "":
				_lista.append(r)
		_lista.sort_custom(func(a, b): return a.capitulo < b.capitulo or (a.capitulo == b.capitulo and a.ordem < b.ordem))
	return _lista


static func por_id(id: String) -> Resource:
	for m in todas():
		if m.id == id:
			return m
	return null


static func do_capitulo(n: int) -> Array:
	return todas().filter(func(m): return m.capitulo == n)


## O arquivo de texto de um capítulo: {secao: {chave: valor}}. Linhas "chave = valor"; as seguintes (sem "chave =")
## continuam o texto; "#" é comentário; "[secao]" começa outra. Arquivo ausente = {} (valem os textos do .tres).
static func textos(capitulo: int, recarrega := false) -> Dictionary:
	if not recarrega and _textos_cache.has(capitulo):
		return _textos_cache[capitulo]
	var out := {}
	var path := DIR + "capitulo_%d.txt" % capitulo
	if FileAccess.file_exists(path):
		out = interpreta(FileAccess.get_file_as_string(path))
	_textos_cache[capitulo] = out
	return out


## O formato do arquivo de texto (separado pra poder testar).
static func interpreta(conteudo: String) -> Dictionary:
	var out := {}
	var secao := ""
	var chave := ""
	for linha_crua in conteudo.replace("\r", "").split("\n"):
		var linha := String(linha_crua)
		var t := linha.strip_edges()
		if t.begins_with("#"):
			continue
		if t.begins_with("[") and t.ends_with("]"):
			secao = t.substr(1, t.length() - 2).strip_edges()
			chave = ""
			if not out.has(secao):
				out[secao] = {}
			continue
		if secao == "":
			continue
		var i := linha.find("=")
		var eh_chave := i > 0 and not linha.begins_with(" ") and not linha.begins_with("\t") and linha.substr(0, i).strip_edges().find(" ") < 0
		if eh_chave:
			chave = linha.substr(0, i).strip_edges()
			out[secao][chave] = linha.substr(i + 1).strip_edges()
		elif t != "" and chave != "":
			out[secao][chave] = String(out[secao][chave]) + (" " if String(out[secao][chave]) != "" else "") + t
	return out


static func recarrega_textos() -> void:
	_textos_cache.clear()


## Título e texto de uma missão: o arquivo do capítulo ganha do .tres.
func titulo_da(m: Resource) -> String:
	return String(textos(m.capitulo).get(m.id, {}).get("titulo", m.titulo if m.titulo != "" else m.id))


func texto_da(m: Resource) -> String:
	return String(textos(m.capitulo).get(m.id, {}).get("texto", m.texto))


func recompensa_texto(m: Resource) -> String:
	var t := String(textos(m.capitulo).get(m.id, {}).get("recompensa", ""))
	if t != "":
		return t
	var partes: Array[String] = []
	if int(m.recompensa.get("creditos", 0)) > 0:
		partes.append("%d créditos" % int(m.recompensa.creditos))
	if String(m.recompensa.get("diario", "")) != "":
		partes.append("uma página do diário")
	if int(m.recompensa.get("libera_capitulo", 0)) > 0:
		partes.append("o Capítulo %d" % int(m.recompensa.libera_capitulo))
	return ", ".join(partes)


## "Cinzas", "Acampamento" e a introdução do capítulo.
func capitulo_titulo(n: int) -> String:
	return String(textos(n).get("capitulo", {}).get("titulo", "Capítulo %d" % n))


func capitulo_subtitulo(n: int) -> String:
	return String(textos(n).get("capitulo", {}).get("subtitulo", ""))


func capitulo_intro(n: int) -> String:
	return String(textos(n).get("capitulo", {}).get("intro", ""))


## O texto de um objetivo (do arquivo; "{n}" vira a quantidade) e, quando precisa de mais de 1, o "(tem/precisa)".
func objetivo_texto(m: Resource, i: int, com_progresso := true) -> String:
	var o: Array = m.objetivos[i]
	var q := int(o[2]) if o.size() > 2 else 1
	var t := String(textos(m.capitulo).get(m.id, {}).get("objetivo.%d" % i, m.objetivo_padrao(i)))
	t = t.replace("{n}", str(q))
	if com_progresso and q > 1 and not objetivo_feito(m, i):
		t += " (%d/%d)" % [mini(int(valor_do_objetivo(o)), q), q]
	return t


# ------------------------------------------------------------ o estado
func cumprida(id: String) -> bool:
	return cumpridas.has(id)


func objetivo_feito(m: Resource, i: int) -> bool:
	return cumprida(m.id) or (feitos.get(m.id, []) as Array).has(i)


## A missão está valendo agora? (capítulo liberado, pré-requisitos cumpridos, ainda não cumprida)
func disponivel(m: Resource) -> bool:
	if cumprida(m.id) or m.capitulo > capitulo_liberado:
		return false
	for p in m.prerequisitos:
		if not cumprida(p):
			return false
	return true


func ativas() -> Array:
	return todas().filter(func(m): return disponivel(m))


## O capítulo em andamento (o menor com missão ativa); sem nenhuma ativa = o último liberado.
func capitulo_atual() -> int:
	var a := ativas()
	return int(a[0].capitulo) if not a.is_empty() else capitulo_liberado


## O capítulo atual existe no jogo (tem missão)? Liberado e sem missão = "em breve".
func capitulo_existe(n: int) -> bool:
	return not do_capitulo(n).is_empty()


## O capítulo todo cumprido?
func capitulo_cumprido(n: int) -> bool:
	var ms := do_capitulo(n)
	return not ms.is_empty() and ms.all(func(m): return cumprida(m.id))


# ------------------------------------------------------------ medir
## O valor de agora de um objetivo [tipo, alvo, quantidade].
func valor_do_objetivo(o: Array) -> float:
	var alvo := String(o[1]) if o.size() > 1 else ""
	match String(o[0]):
		"fundar_vila":
			var hub := get_tree().get_first_node_in_group("village_hub")
			return 1.0 if hub != null and hub.get("founded") != false else 0.0
		"casas":
			return float(get_tree().get_nodes_in_group("casas").filter(func(c): return c.get("built") == true).size())
		"funcoes":  # Bloco 112: adultos com função (alvo "" = qualquer uma)
			return float(get_tree().get_nodes_in_group("ipezinhos").filter(func(w):
				var j := String(w.get("job"))
				return j != "ocioso" and j != "" and not (w.has_method("e_crianca") and w.e_crianca()) and (alvo == "" or j == alvo)).size())
		"construcao":
			return float(get_tree().get_nodes_in_group(alvo).size()) if alvo != "" else 0.0
		"minerio_armazem":
			var eco := get_tree().get_first_node_in_group("economy")
			return eco.stored_ore(alvo) if eco else 0.0
		"item":
			var eco2 := get_tree().get_first_node_in_group("economy")
			return eco2.quantidade(alvo) if eco2 else 0.0
		"invasoes":
			return float(contadores.invasoes)
		"estagio":
			var hub2 := get_tree().get_first_node_in_group("village_hub")
			return float(hub2.level) if hub2 and hub2.get("level") != null else 0.0
		"pesquisa":
			var res := get_tree().get_first_node_in_group("research")
			return 1.0 if res and (res.done as Array).has(alvo) else 0.0
		"vendido":
			return float(contadores.vendido)
		"obras":
			return float((contadores.obras as Dictionary).get(alvo, 0))
		"mortes":
			return float(contadores.mortes)
		"estudar":  # Bloco 102: alvo = id da entrada (1 = estudada), uma categoria (quantas) ou "" (quantas no total)
			var cat := get_tree().get_first_node_in_group("catalogo")
			if cat == null:
				return 0.0
			if alvo == "" or alvo in cat.CATEGORIAS:
				return float(cat.quantos_estudados(alvo))
			return 1.0 if cat.estudado(alvo) else 0.0
		"expedicao":  # Bloco 104: quantas expedições voltaram (alvo = a região: voltou de lá ao menos uma vez)
			var ex := get_tree().get_first_node_in_group("expedicoes")
			if ex == null:
				return 0.0
			if alvo != "":
				return 1.0 if ex.relatorios.any(func(r): return String(r.regiao) == alvo) or ex.voltou_de.has(alvo) else 0.0
			return float(ex.total_voltaram)
		"entregas":  # Bloco 105: quantas entregas os carregadores fizeram
			var lg := get_tree().get_first_node_in_group("logistica")
			return float(lg.entregas) if lg else 0.0
		"consertos":  # Bloco 105: alvo "" = consertos de máquina quebrada; "preventiva" = as manutenções preventivas
			var mt := get_tree().get_first_node_in_group("manutencao")
			if mt == null:
				return 0.0
			return float(mt.preventivas) if alvo == "preventiva" else float(mt.consertos_feitos)
		"regiao":  # Bloco 104: uma região revelada
			var ex2 := get_tree().get_first_node_in_group("expedicoes")
			return 1.0 if ex2 and ex2.reveladas.has(alvo) else 0.0
		"criatura", "reconhecer":  # Bloco 103: alvo = a espécie / o andar (1 = estudado), ou "" (quantos)
			var cat2 := get_tree().get_first_node_in_group("catalogo")
			if cat2 == null:
				return 0.0
			if alvo != "":
				return 1.0 if cat2.estudado(alvo) else 0.0
			if String(o[0]) == "criatura":
				return float(cat2.quantos_estudados("criatura"))
			return float(cat2.da_categoria("local").filter(func(e): return String(e.get("nivel", "")) != "" and cat2.estudado(String(e.id))).size())
	return 0.0


## Confere as missões valendo: marca os objetivos que bateram e cumpre a missão quando todos bateram.
func confere() -> void:
	if not is_inside_tree():
		return
	var mexeu := false
	for m in ativas():
		var lista: Array = feitos.get(m.id, [])
		for i in m.objetivos.size():
			if lista.has(i):
				continue
			if m.get("em_ordem") == true and i > 0 and not lista.has(i - 1):
				break  # Bloco 112: em ordem — o próximo só conta depois do anterior
			var o: Array = m.objetivos[i]
			var q := float(o[2]) if o.size() > 2 else 1.0
			if valor_do_objetivo(o) >= q:
				lista.append(i)
				feitos[m.id] = lista
				mexeu = true
				objetivo_cumprido.emit(m.id, i)
				if not _silencio:
					_aviso("Objetivo cumprido: %s" % objetivo_texto(m, i, false), Color(0.55, 1.0, 0.5))
		if lista.size() >= m.objetivos.size() and not m.objetivos.is_empty():
			_cumpre(m)
			mexeu = true
	if mexeu:
		mudou.emit()


func _cumpre(m: Resource) -> void:
	if cumpridas.has(m.id):
		return
	cumpridas.append(m.id)
	var r: Dictionary = m.recompensa
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and int(r.get("creditos", 0)) > 0:
		eco.ganha_creditos(float(r.creditos))
	if eco and r.get("itens") is Dictionary:
		for k in r.itens:
			eco.add_item(String(k), float(r.itens[k]))
	var pag := String(r.get("diario", ""))
	if pag != "":
		_pagina_do_diario(m, pag)
	var lib := int(r.get("libera_capitulo", 0))
	if lib > capitulo_liberado:
		capitulo_liberado = mini(lib, ULTIMO_CAPITULO)
	missao_cumprida.emit(m.id)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and not _silencio:
		var som := get_node_or_null("/root/Audio")  # (o autoload por caminho: o teste carrega este script antes dos autoloads)
		if som:
			som.stinger("missao_cumprida")  # Bloco 114 (sem arquivo: a fanfarra)
		var sub := "Recompensa: %s." % recompensa_texto(m)
		if lib > 0:
			sub += (" O Capítulo %d está liberado." % lib) if capitulo_existe(lib) else " O Capítulo %d ainda está sendo escrito." % lib
		hud.show_banner("MISSÃO CUMPRIDA: %s" % titulo_da(m).to_upper(), sub)


## A página do diário da missão: o texto vem do arquivo do capítulo ("[diario.<id>]").
func _pagina_do_diario(m: Resource, pagina: String) -> void:
	var diary := get_tree().get_first_node_in_group("diary")
	if diary == null:
		return
	var sec: Dictionary = textos(m.capitulo).get("diario." + pagina, {})
	if diary.has_method("registra"):
		diary.registra(pagina, String(sec.get("titulo", titulo_da(m))), String(sec.get("texto", texto_da(m))))
	diary.unlock(pagina)


func _aviso(texto: String, cor: Color) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast(texto, cor)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"capitulo_liberado": capitulo_liberado, "cumpridas": cumpridas.duplicate(), "feitos": feitos.duplicate(true),
		"contadores": contadores.duplicate(true), "primeiro_dia": true}


func load_save_data(d: Dictionary) -> void:
	capitulo_liberado = clampi(SaveUtil.integer(d, "capitulo_liberado", 1), 1, ULTIMO_CAPITULO)
	cumpridas.clear()
	for id in SaveUtil.array(d, "cumpridas"):
		if por_id(String(id)) != null and not cumpridas.has(String(id)):
			cumpridas.append(String(id))
	if not SaveUtil.boolean(d, "primeiro_dia", false):
		_primeiro_dia_ja_passou()  # Bloco 112: save de antes do guia — o primeiro dia já passou
	feitos = {}
	var f := SaveUtil.dict(d, "feitos")
	for id in f:
		var m := por_id(String(id))
		if m == null or typeof(f[id]) != TYPE_ARRAY:
			continue
		var lista := []
		for i in f[id]:
			if int(i) >= 0 and int(i) < m.objetivos.size() and not lista.has(int(i)):
				lista.append(int(i))
		feitos[String(id)] = lista
	var c := SaveUtil.dict(d, "contadores")
	contadores = {"invasoes": SaveUtil.integer(c, "invasoes", 0), "vendido": SaveUtil.num(c, "vendido", 0.0),
		"mortes": SaveUtil.integer(c, "mortes", 0), "obras": {}}
	for k in SaveUtil.dict(c, "obras"):
		contadores.obras[String(k)] = SaveUtil.integer(SaveUtil.dict(c, "obras"), String(k), 0)
	# as páginas do diário das missões cumpridas voltam com o texto do arquivo
	for id in cumpridas:
		var m2 := por_id(id)
		if m2 and String(m2.recompensa.get("diario", "")) != "":
			var diary := get_tree().get_first_node_in_group("diary")
			var sec: Dictionary = textos(m2.capitulo).get("diario." + String(m2.recompensa.diario), {})
			if diary and diary.has_method("registra"):
				diary.registra(String(m2.recompensa.diario), String(sec.get("titulo", titulo_da(m2))), String(sec.get("texto", texto_da(m2))))
	mudou.emit()


## Bloco 112: save de antes do primeiro dia guiado: a missão dele conta como cumprida (sem recompensa nem guia de novo).
func _primeiro_dia_ja_passou() -> void:
	if por_id(PRIMEIRO_DIA) != null and not cumpridas.has(PRIMEIRO_DIA):
		cumpridas.append(PRIMEIRO_DIA)


## O SaveManager chama no fim do carregamento: `tinha` = o save tem a chave "missoes". Sem ela (save de antes do
## Bloco 100) a campanha começa no capítulo certo: refaz os contadores do que a vila já viveu e confere tudo.
func depois_de_carregar(tinha: bool) -> void:
	if tinha:
		confere()
		return
	capitulo_liberado = 1
	cumpridas.clear()
	feitos = {}
	var def := get_tree().get_first_node_in_group("defense")
	var passadas := 0
	if def and def.get("wave") != null:
		passadas = maxi(int(def.wave) - (1 if def.get("invasion_active") == true else 0), 0)
	var mortes := 0
	for e in get_tree().get_nodes_in_group("enfermarias"):
		mortes += (e.get("memorial") as Array).size() if e.get("memorial") != null else 0
	contadores = {"invasoes": passadas, "vendido": 0.0, "mortes": mortes, "obras": {}}
	_silencio = true  # (um aviso só, no fim: não uma chuva de "objetivo cumprido")
	_primeiro_dia_ja_passou()  # Bloco 112: save sem missões é de antes do guia
	var antes := cumpridas.size()
	for volta in ULTIMO_CAPITULO:  # cumprir um capítulo libera o seguinte: confere de novo até assentar
		var n := cumpridas.size()
		confere()
		if cumpridas.size() == n:
			break
	_silencio = false
	if cumpridas.size() > antes:
		_aviso("Missões: %d já estavam cumpridas (recompensas entregues). Capítulo atual: %d." % [cumpridas.size() - antes, capitulo_atual()], Color(0.8, 0.85, 0.7))
	mudou.emit()
