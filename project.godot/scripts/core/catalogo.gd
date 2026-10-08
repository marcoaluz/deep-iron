extends Node
## Bloco 102: o CATÁLOGO DE DESCOBERTAS (nó "Catalogo" na main.tscn, grupo "catalogo"). O pesquisador como naturalista.
##
## - As ENTRADAS vêm de dados: data/catalogo/entradas.json (id, categoria, alvo, estado inicial, pontos, o que libera,
##   a página do diário, o ícone) e os textos de data/catalogo/textos.txt (o formato dos capítulos das missões).
## - Cada entrada anda Desconhecido -> Avistado -> Estudado (nunca volta). AVISTA quando um morador chega perto do alvo
##   (a jazida, a toca), quando o andar abre (local) ou quando a criatura aparece. ESTUDA pela pesquisadora no campo
##   (ipezinho.gd, estado "catalogando": vai, anota, volta e entrega), pela amostra do abate no laboratório (criatura)
##   ou pelo laboratório sozinho, mais devagar (o PLANO B, sem pesquisador).
## - Minério não estudado é "pedra desconhecida" e o que sai dela é "minério desconhecido" (ores.gd): o catálogo anota
##   de que tipo era (bruto) e, quando o tipo é estudado, troca no armazém esse tanto pelo minério de verdade. A receita
##   da fornalha e a toca do caçador também esperam o estudo. A pesquisa pode exigir uma entrada estudada ("libera").
## - Sinais pras missões e pra janela: entrada_avistada / entrada_estudada (objetivo "estudar" em missoes.gd).
## Save: chave "catalogo". Save antigo (sem a chave): entra como Estudado tudo que o jogo já tinha liberado.
##
## Bloco 103: o BESTIÁRIO e o RECONHECIMENTO DOS ANDARES.
## - A criatura abatida deixa um CORPO (corpo_criatura.gd) até o amanhecer seguinte + horas_corpo: a pesquisadora estuda
##   a espécie NO CORPO (de dia; corpo lá fora só com o portão aberto) e colhe o que ele deixou. A ficha (comportamento,
##   fraqueza, o que deixa, perigo, POR QUE VEIO + a dica, a história) vem do textos.txt; o perigo e o que deixa são lidos
##   da cena da criatura. A descoberta vira um cartão (o banner) e a página do diário; quem descobriu fica realizada
##   (ânimo e experiência: ipezinho.descobriu). Corpo na vila ou perto do portão tira um pouco do ânimo (morale.gd).
## - Andar novo (S2-S5) que abriu e ainda não foi RECONHECIDO: a IA não manda ninguém trabalhar lá (a pesquisadora é a
##   exceção, pra fazer o reconhecimento — com risco de ferimento); a ordem à mão, a área de trabalho e a patrulha dos
##   guardas pedem confirmação (libera_descida) e aí os acidentes lá são x acidente_sem_reconhecimento até o
##   reconhecimento. O reconhecimento revela os perigos, as criaturas e o equipamento do andar (as regras não mudam).

signal mudou
signal entrada_avistada(id: String)
signal entrada_estudada(id: String, categoria: String)
## Bloco 103: pras missões (e a janela da Defesa / o corte da mina).
signal criatura_estudada(id: String)
signal andar_reconhecido(id: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const Ores := preload("res://scripts/core/ores.gd")
const Items := preload("res://scripts/core/items.gd")
const Niveis := preload("res://scripts/core/niveis.gd")
const Missoes := preload("res://scripts/core/missoes.gd")
const ARQ_ENTRADAS := "res://data/catalogo/entradas.json"
const ARQ_TEXTOS := "res://data/catalogo/textos.txt"
const CATEGORIAS := ["minerio", "animal", "criatura", "local"]
const NOMES_CATEGORIA := {"minerio": "Minerais", "animal": "Animais", "criatura": "Criaturas", "local": "Locais"}
## A pesquisadora prefere, nesta ordem (depois pela distância): minério, local, animal, criatura.
const PRIORIDADE := {"minerio": 0, "local": 1, "animal": 2, "criatura": 3}
const DESCONHECIDO := 0
const AVISTADO := 1
const ESTUDADO := 2

## Testes de antes do Bloco 102 (mineram cobre, caçam, pesquisam explosivos...): tudo conta como estudado.
static var tudo_estudado := false

@export_group("Avistar")
## Distância (px da lógica) de um morador até a jazida/toca pra ela virar Avistada.
@export var alcance_avistar: float = 160.0
## Segundos (reais) entre uma conferência e outra (avistar, reservas, o plano B).
@export var intervalo_confere: float = 1.0

@export_group("Estudo de campo")
## Segundos de jogo anotando no alvo (x o ritmo do pesquisador: zanga e tristeza deixam mais lento).
@export var segundos_estudo: float = 40.0
## Distância (px) do alvo em que a pesquisadora já começa a anotar.
@export var alcance_estudo: float = 44.0
## Pontos de pesquisa que cada estudo de campo dá (pra pesquisa em andamento, ou guardados pra próxima).
@export var pontos_por_estudo: float = 8.0

@export_group("Corpos e bestiário (Bloco 103)")
## Horas depois do amanhecer SEGUINTE à morte em que o corpo da criatura some (se ninguém estudou).
@export var horas_corpo: float = 8.0
## Ânimo que cada corpo de criatura dentro da paliçada (ou perto do portão) tira da vila, e o máximo somado.
@export var desconforto_corpo: float = 1.5
@export var desconforto_max: float = 4.5
## Distância (px) do portão em que o corpo do lado de fora ainda incomoda.
@export var desconforto_perto_portao: float = 120.0
## A pesquisadora não escolhe alvo com um morador do fundo vivo a menos disto (px).
@export var distancia_morador: float = 150.0

@export_group("Reconhecimento dos andares (Bloco 103)")
## Chance de ferimento no fim de um reconhecimento (o andar é perigoso); com o traje do andar no vestiário, x 0,25.
@export_range(0.0, 1.0) var risco_reconhecimento: float = 0.15
@export var risco_com_traje: float = 0.25
## Acidentes na mina num andar liberado sem reconhecimento (o jogador confirmou descer) até o reconhecimento.
@export var acidente_sem_reconhecimento: float = 2.0

@export_group("Plano B: o laboratório sozinho")
## Pontos por segundo que o laboratório gera sozinho num estudo do catálogo (o pesquisador gera 1/s numa pesquisa).
@export var lab_pontos_sozinho: float = 0.15

static var _entradas: Array = []
static var _por_id := {}
static var _textos := {}

## id -> AVISTADO/ESTUDADO (o que não está aqui é desconhecido).
var estados := {}
## Minério desconhecido que entrou, por tipo de verdade: {tipo: quantidade} (vira o minério quando estudado).
var bruto := {}
## Amostras de criatura guardadas (do abate): {id: n}.
var amostras := {}
## Plano B em andamento: {id, pontos} ({} = nenhum).
var estudo_lab := {}
## Bloco 103: andares que o jogador mandou descer sem reconhecimento: {id: true}.
var descida_liberada := {}
## Bloco 103: o ânimo que os corpos tiram da vila agora (o morale.gd lê; conferido a cada segundo).
var desconforto := 0.0
var _reservas := {}  # id -> ipezinho (a pesquisadora que vai estudar)
var _t := 0.0


func _ready() -> void:
	add_to_group("catalogo")
	_aplica_inicial()
	_registra_diario.call_deferred()


# ------------------------------------------------------------ dados
static func entradas() -> Array:
	if _entradas.is_empty() and FileAccess.file_exists(ARQ_ENTRADAS):
		var j = JSON.parse_string(FileAccess.get_file_as_string(ARQ_ENTRADAS))
		if j is Dictionary:
			for e in j.get("entradas", []):
				if e is Dictionary and String(e.get("id", "")) != "":
					_entradas.append(e)
					_por_id[String(e.id)] = e
	return _entradas


static func entrada(id: String) -> Dictionary:
	entradas()
	return _por_id.get(id, {})


static func da_categoria(cat: String) -> Array:
	return entradas().filter(func(e): return String(e.categoria) == cat)


static func textos() -> Dictionary:
	if _textos.is_empty() and FileAccess.file_exists(ARQ_TEXTOS):
		_textos = Missoes.interpreta(FileAccess.get_file_as_string(ARQ_TEXTOS))
	return _textos


static func texto(id: String, chave: String) -> String:
	return String(textos().get(id, {}).get(chave, ""))


## O nome da entrada (do arquivo de textos).
static func nome(id: String) -> String:
	var n := texto(id, "nome")
	return n if n != "" else id


## A entrada do catálogo de um tipo de minério / bicho ("" = o catálogo não fala dele: conta como conhecido).
static func id_do_alvo(categoria: String, alvo: String, chefe := false) -> String:
	for e in entradas():
		if String(e.categoria) == categoria and String(e.alvo) == alvo and bool(e.get("chefe", false)) == chefe:
			return String(e.id)
	return ""


## O ícone da entrada: {ui: nome do Icones} ou {png: caminho}.
static func icone(id: String) -> Texture2D:
	var ic: Dictionary = entrada(id).get("icone", {})
	if ic.has("ui"):
		return preload("res://scripts/ui/icones.gd").tex(String(ic.ui))
	if ic.has("png") and ResourceLoader.exists(String(ic.png)):
		return load(String(ic.png))
	return null


# ------------------------------------------------------------ estados
func estado(id: String) -> int:
	if tudo_estudado:
		return ESTUDADO
	return int(estados.get(id, DESCONHECIDO))


func estudado(id: String) -> bool:
	return estado(id) == ESTUDADO


func minerio_conhecido(tipo: String) -> bool:
	var id := id_do_alvo("minerio", tipo)
	return id == "" or estudado(id)


func animal_conhecido(kind: String) -> bool:
	var id := id_do_alvo("animal", kind)
	return id == "" or estudado(id)


## Quantas entradas estudadas (de uma categoria, ou de todas com "").
func quantos_estudados(cat := "") -> int:
	var n := 0
	for e in entradas():
		if (cat == "" or String(e.categoria) == cat) and estudado(String(e.id)):
			n += 1
	return n


## O nome da entrada que a pesquisa ainda espera ser estudada ("" = nenhuma). Vem do "libera" das entradas.
func falta_para_pesquisa(pesquisa: String) -> String:
	for e in entradas():
		if ("pesquisa:" + pesquisa) in e.get("libera", []) and not estudado(String(e.id)):
			return nome(String(e.id))
	return ""


func _aplica_inicial() -> void:
	estados.clear()
	for e in entradas():
		match String(e.get("inicial", "")):
			"estudado":
				estados[String(e.id)] = ESTUDADO
			"avistado":
				estados[String(e.id)] = AVISTADO


## Virou Avistada (só de desconhecida).
func avista(id: String, avisa := true) -> bool:
	if entrada(id).is_empty() or estado(id) != DESCONHECIDO:
		return false
	estados[id] = AVISTADO
	if avisa:
		var cat := String(entrada(id).categoria)
		var txt: String = {"minerio": "Pedra desconhecida avistada: falta estudar (Catálogo, R)",
			"animal": "Uma toca nova avistada: falta estudar (Catálogo, R)",
			"local": "Lugar novo pra reconhecer: %s (Catálogo, R)" % nome(id)}.get(cat, "")
		if txt != "":
			_aviso(txt, Color(0.75, 0.85, 1.0))
	entrada_avistada.emit(id)
	mudou.emit()
	return true


## ESTUDOU (a pesquisadora no campo, a amostra no laboratório ou o plano B). quem = quem estudou (null = o laboratório
## sozinho: não dá pontos). Troca o minério desconhecido, abre a página do diário e avisa.
func estuda(id: String, quem: Node = null) -> bool:
	var e := entrada(id)
	if e.is_empty() or estudado(id):
		return false
	estados[id] = ESTUDADO
	_reservas.erase(id)
	if estudo_lab.get("id", "") == id:
		estudo_lab = {}
	var cat := String(e.categoria)
	var extra := ""
	if cat == "minerio":
		var n := _revela_bruto(String(e.alvo))
		if n >= 1.0:
			extra = " — %d de minério desconhecido no armazém eram %s" % [int(n), nome(id).to_lower()]
	elif cat == "criatura":
		amostras[id] = maxi(int(amostras.get(id, 0)) - 1, 0)
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		diary.unlock(String(e.get("diario", "")) if String(e.get("diario", "")) != "" else "cat_" + id, false)
	if quem != null and is_instance_valid(quem):
		var res := get_tree().get_first_node_in_group("research")
		if res and res.has_method("ganha_pontos"):
			res.ganha_pontos(pontos_por_estudo)
		if quem.has_method("descobriu"):
			quem.descobriu(id)  # Bloco 103: ânimo, experiência e o balão de comemoração
		elif quem.has_method("_popup"):
			quem._popup("Estudou: %s!" % nome(id), Color(0.75, 0.9, 1.0))
	_aviso("Estudou: %s%s" % [nome(id), extra], Color(0.6, 1.0, 0.75), quem if quem is Node2D else null)
	if cat in ["criatura", "local"]:
		_cartao(id, quem)  # Bloco 103: o cartão narrativo curto
	var au := get_node_or_null("/root/Audio")
	if au:
		au.find((quem as Node2D).global_position if quem is Node2D and is_instance_valid(quem) else Vector2.ZERO)
	_avisa_mundo()
	entrada_estudada.emit(id, cat)
	if cat == "criatura":
		criatura_estudada.emit(id)
	elif cat == "local" and String(e.get("nivel", "")) != "":
		andar_reconhecido.emit(id)
	mudou.emit()
	return true


## Bloco 103: o cartão da descoberta (o banner da tela): o nome, duas linhas da história e a dica.
func _cartao(id: String, quem: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("show_banner"):
		return
	var cat := String(entrada(id).categoria)
	var titulo := ("DESCOBERTA: %s" if cat == "criatura" else "RECONHECIMENTO: %s") % nome(id).to_upper()
	var linhas: Array[String] = []
	if quem != null and is_instance_valid(quem) and quem.get("display_name"):
		linhas.append("%s %s." % [quem.display_name, "estudou o corpo" if cat == "criatura" else "voltou do reconhecimento"])
	var hist := texto(id, "historia")
	if hist != "":
		linhas.append(hist)
	if texto(id, "dica") != "":
		linhas.append("Dica: " + texto(id, "dica"))
	elif cat == "local":
		var f := ficha_local(id)
		for k in ["Perigos", "Equipamento"]:
			if f.has(k):
				linhas.append("%s: %s" % [k, f[k]])
	hud.show_banner(titulo, "\n".join(linhas))


## Testes e o F3: tudo estudado de uma vez (sem aviso).
func estuda_tudo() -> void:
	for e in entradas():
		estados[String(e.id)] = ESTUDADO
	_avisa_mundo()
	mudou.emit()


## As jazidas e as tocas guardam se são conhecidas: avisa todas (pedra desconhecida -> minério; toca ??? -> caça).
func _avisa_mundo() -> void:
	for m in get_tree().get_nodes_in_group("minerios"):
		if m.has_method("on_unlock_changed"):
			var era: bool = m.get("conhecido") != false
			m.on_unlock_changed(not era)  # (a jazida que acabou de ser revelada pula)
	for t in get_tree().get_nodes_in_group("caca"):
		if t.has_method("_update_visual"):
			t._update_visual()
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.is_hunter() or w.is_researcher():
			w.wake_decision()


# ------------------------------------------------------------ minério desconhecido
## O minério que saiu de uma jazida não estudada: anota de que tipo era.
func anota_bruto(tipo: String, qtd: float) -> void:
	if qtd > 0.0:
		bruto[tipo] = float(bruto.get(tipo, 0.0)) + qtd


## Troca no armazém o minério desconhecido que era desse tipo (a parte dele no que sobrou: o resto pode ter sido vendido).
func _revela_bruto(tipo: String) -> float:
	var anotado := float(bruto.get(tipo, 0.0))
	bruto.erase(tipo)
	if anotado <= 0.0:
		return 0.0
	var tem := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		tem += float(a.stock.get(Ores.DESCONHECIDO, 0.0))
	var soma := anotado
	for t in bruto:
		soma += float(bruto[t])
	var vira := minf(anotado, tem * anotado / maxf(soma, 0.001)) if soma > tem else minf(anotado, tem)
	var falta := vira
	for a in get_tree().get_nodes_in_group("armazens"):
		if falta <= 0.0:
			break
		var tira: float = a.take(minf(falta, float(a.stock.get(Ores.DESCONHECIDO, 0.0))), Ores.DESCONHECIDO)
		if tira > 0.0:
			a.stock[tipo] = float(a.stock.get(tipo, 0.0)) + tira
			a._recount()
			falta -= tira
	# o que sobrou anotado não pode passar do que ainda está no armazém
	var resto := tem - (vira - falta)
	var soma_resto := 0.0
	for t in bruto:
		soma_resto += float(bruto[t])
	if soma_resto > resto and soma_resto > 0.0:
		for t in bruto.keys():
			bruto[t] = float(bruto[t]) * maxf(resto, 0.0) / soma_resto
	return vira - falta


# ------------------------------------------------------------ amostras (criaturas)
## Uma criatura caiu: guarda a amostra (e ela conta como vista).
func amostra(kind: String, chefe := false) -> void:
	var id := id_do_alvo("criatura", kind, chefe)
	if id == "":
		return
	avista(id, false)
	var n := int(amostras.get(id, 0))
	amostras[id] = n + 1
	if n == 0 and not estudado(id):
		_aviso("Uma criatura desconhecida caiu: o corpo fica no chão até amanhã — a pesquisadora pode estudar (Catálogo, R)", Color(0.75, 0.85, 1.0))  # Bloco 103: o nome só depois do estudo
	mudou.emit()


# ------------------------------------------------------------ a pesquisadora no campo
func _confere() -> void:
	var gente := get_tree().get_nodes_in_group("ipezinhos")
	var env := get_tree().get_first_node_in_group("environment")
	for e in entradas():
		var id := String(e.id)
		if estado(id) != DESCONHECIDO:
			continue
		match String(e.categoria):
			"minerio":
				for m in get_tree().get_nodes_in_group("minerios"):
					if m.ore_type == String(e.alvo) and m.acessivel() and _alguem_perto(m.global_position, gente):
						avista(id)
						break
			"animal":
				for t in get_tree().get_nodes_in_group("caca"):
					if String(t.animal) == String(e.alvo) and t.visible and not _trancado(env, t.global_position) \
							and _alguem_perto(t.global_position, gente):
						avista(id)
						break
			"criatura":
				for c in get_tree().get_nodes_in_group("criaturas"):
					if String(c.kind) == String(e.alvo) and c.is_in_group("chefes") == bool(e.get("chefe", false)) \
							and c.has_method("is_alive") and c.is_alive() \
							and (String(c.get("morador")) == "" or _alguem_perto(c.global_position, gente)):
						avista(id, false)  # (a invasão já avisa; o morador do fundo, só quando alguém chega perto)
						break
			"local":
				if _local_aberto(e, env):
					avista(id)
	_confere_corpos()  # Bloco 103
	# reservas de quem não está mais nessa (trocou de função, morreu, largou o campo sem anotação)
	for id in _reservas.keys():
		var w = _reservas[id]
		if not is_instance_valid(w) or not w.is_researcher() or (w.get_state() != "catalogando" and String(w.nota_campo) != id):
			_reservas.erase(id)


func _alguem_perto(pos: Vector2, gente: Array) -> bool:
	for w in gente:
		if (w as Node2D).global_position.distance_to(pos) <= alcance_avistar:
			return true
	return false


func _trancado(env: Node, pos: Vector2) -> bool:
	return env != null and env.has_method("trancado") and env.trancado(pos)


func _local_aberto(e: Dictionary, env: Node) -> bool:
	if String(e.get("nivel", "")) != "":
		var nv: Resource = Niveis.por_id(String(e.nivel))
		return nv != null and Niveis.liberado(get_tree(), nv)
	var p: Array = e.get("pos", [])
	return env != null and env.has_method("has_leste") and env.has_leste() and p.size() >= 2 \
		and not _trancado(env, Vector2(float(p[0]), float(p[1])))


## Perigoso pra esta pesquisadora? (zona de gás/radiação/calor ou poça de ácido/lava sem o traje; Bloco 103: um morador
## do fundo vivo perto)
func perigoso(pos: Vector2, w: Node) -> bool:
	if morador_perto(pos):
		return true
	var eq := get_tree().get_first_node_in_group("equipment")
	if eq and eq.has_method("hazard_at"):
		var z: String = eq.hazard_at(pos)
		if z != "" and not w.can_enter_hazard(z):
			return true
	for p in get_tree().get_nodes_in_group("pocas_perigo"):
		if p.traje() != "" and (p as Node2D).global_position.distance_to(pos) <= float(p.radius) + 16.0 \
				and not w.can_enter_hazard(p.traje()):
			return true
	return false


## O alvo de campo de uma entrada pra esta pesquisadora: {id, pos, lab (estuda no laboratório)} ({} = não dá agora).
func _alvo_de(id: String, w: Node) -> Dictionary:
	var e := entrada(id)
	var env := get_tree().get_first_node_in_group("environment")
	var de: Vector2 = (w as Node2D).global_position
	match String(e.categoria):
		"minerio":
			var melhor: Node2D = null
			for m in get_tree().get_nodes_in_group("minerios"):
				if m.ore_type != String(e.alvo) or not m.acessivel():
					continue
				if String(m.hazard) != "" and not w.can_enter_hazard(String(m.hazard)):
					continue
				if perigoso(m.global_position, w):
					continue
				if melhor == null or de.distance_to(m.global_position) < de.distance_to(melhor.global_position):
					melhor = m
			if melhor:
				return {"id": id, "pos": melhor.get_wait_position(w), "lab": false}
		"animal":
			var melhor: Node2D = null
			for t in get_tree().get_nodes_in_group("caca"):
				if String(t.animal) != String(e.alvo) or not t.visible or _trancado(env, t.global_position):
					continue
				if melhor == null or de.distance_to(t.global_position) < de.distance_to(melhor.global_position):
					melhor = t
			if melhor:
				return {"id": id, "pos": melhor.global_position + Vector2(0, 34), "lab": false}
		"local":
			var p: Array = e.get("pos", [])
			if p.size() >= 2 and _local_aberto(e, env):
				# Bloco 103: o ponto dos dados; com um morador do fundo perto, outro ponto do mesmo andar
				for dx in [0.0, -300.0, 300.0, -550.0, 550.0]:
					var pos := _chao(Vector2(float(p[0]) + dx, float(p[1])))
					if not perigoso(pos, w) and (env == null or env.level_at(pos) == env.level_at(Vector2(float(p[0]), float(p[1])))):
						return {"id": id, "pos": pos, "lab": false}
		"criatura":  # Bloco 103: estuda NO CORPO (o mais perto), não mais a amostra no laboratório
			var melhor: Node2D = null
			for c in get_tree().get_nodes_in_group("corpos_criatura"):
				if String(c.especie) != id or not is_instance_valid(c) or c.is_queued_for_deletion():
					continue
				if not _chega_no_corpo(c, w) or perigoso(c.global_position, w):
					continue
				if melhor == null or de.distance_to(c.global_position) < de.distance_to(melhor.global_position):
					melhor = c
			if melhor:
				return {"id": id, "pos": melhor.global_position + Vector2(0, 14), "lab": false, "corpo": melhor}
	return {}


## Bloco 103: dá pra ir até o corpo agora? (lá fora da paliçada só com o portão aberto; o andar dele aberto)
func _chega_no_corpo(c: Node2D, w: Node) -> bool:
	var b := get_tree().get_first_node_in_group("barricadas")
	if b and b.has_method("separa") and b.separa((w as Node2D).global_position, c.global_position) \
			and b.has_method("fechado") and b.fechado():
		return false
	var nv: Resource = Niveis.por_id(String(c.andar))
	return nv == null or String(c.andar) in ["S0", "S1"] or Niveis.liberado(get_tree(), nv)


## Bloco 103: um morador do fundo vivo perto desse ponto? (a pesquisadora evita)
func morador_perto(pos: Vector2) -> bool:
	for c in get_tree().get_nodes_in_group("criaturas"):
		if String(c.get("morador")) != "" and c.is_alive() and (c as Node2D).global_position.distance_to(pos) < distancia_morador:
			return true
	return false


## Bloco 103: o alvo ainda vale? (o corpo pode ter sumido no prazo ou ter sido estudado)
func alvo_valido(campo: Dictionary) -> bool:
	if estado(String(campo.get("id", ""))) != AVISTADO:
		return false
	if campo.has("corpo"):
		var c = campo.corpo
		return c != null and is_instance_valid(c) and not c.is_queued_for_deletion()
	return true


## Bloco 103: a anotação acabou no alvo. O corpo: colhe o que ele deixou e some. O andar: o risco do reconhecimento.
func fim_da_anotacao(campo: Dictionary, w: Node) -> void:
	if campo.has("corpo"):
		var c = campo.corpo
		if c != null and is_instance_valid(c):
			var txt: String = c.entrega_drop()
			if txt != "" and w.has_method("_popup"):
				w._popup("Colheu: %s" % txt, Color(1.0, 0.85, 0.45))
				_aviso("%s colheu do corpo: %s (no armazém)" % [w.display_name, txt], Color(1.0, 0.85, 0.45))
			c.queue_free()
	elif String(entrada(String(campo.get("id", ""))).get("nivel", "")) != "":
		var nv: Resource = Niveis.por_id(String(entrada(String(campo.id)).nivel))
		var chance := risco_reconhecimento
		var eq := get_tree().get_first_node_in_group("equipment")
		if nv and String(nv.traje) != "" and eq and eq.has_method("usable") and (eq.usable(String(nv.traje)) + eq.in_use(String(nv.traje))) > 0:
			chance *= risco_com_traje
		if randf() < chance and w.has_method("hurt"):
			w.hurt("mina", "leve")
			_aviso("%s se machucou no reconhecimento do %s." % [w.display_name, String(campo.id)], Color(1.0, 0.5, 0.4))


# ------------------------------------------------------------ andares não reconhecidos (Bloco 103)
## O id do andar novo (S2..S5) num ponto ("" = a superfície, a vila e a mina de cima, ou fora de um andar do catálogo).
func andar_de(pos: Vector2) -> String:
	var env := get_tree().get_first_node_in_group("environment")
	if env == null:
		return ""
	var nv: Resource = Niveis.do_ponto(env, pos)
	if nv == null or String(nv.id) in ["S0", "S1"] or entrada(String(nv.id)).is_empty():
		return ""
	return String(nv.id)


func reconhecido(andar: String) -> bool:
	return andar == "" or estudado(andar)


## A IA não manda ninguém trabalhar num andar que ninguém reconheceu (a pesquisadora pode ir; o jogador pode liberar).
func andar_bloqueado(pos: Vector2, w: Node = null) -> bool:
	var a := andar_de(pos)
	if a == "" or reconhecido(a) or descida_liberada.has(a):
		return false
	return not (w != null and w.has_method("is_researcher") and w.is_researcher())


## O andar que pede confirmação antes de mandar gente pra esse ponto ("" = nenhum).
func precisa_confirmar(pos: Vector2) -> String:
	var a := andar_de(pos)
	return a if a != "" and not reconhecido(a) and not descida_liberada.has(a) else ""


func libera_descida(andar: String) -> void:
	if andar != "":
		descida_liberada[andar] = true
		for w in get_tree().get_nodes_in_group("ipezinhos"):
			w.wake_decision()
		mudou.emit()


## Multiplica o acidente na mina: andar liberado sem reconhecimento = x acidente_sem_reconhecimento.
func mult_acidente(pos: Vector2) -> float:
	var a := andar_de(pos)
	return acidente_sem_reconhecimento if a != "" and not reconhecido(a) and descida_liberada.has(a) else 1.0


## O texto do aviso da confirmação.
func texto_confirmar(andar: String) -> String:
	return "O %s ainda não foi reconhecido: ninguém sabe que perigos tem lá. Descer mesmo assim?\n\nLá dentro os acidentes ficam %s mais comuns até uma pesquisadora fazer o reconhecimento (Catálogo, R)." % [
		nome(andar), ("%.0fx" % acidente_sem_reconhecimento)]


## A ficha de um andar reconhecido: {Perigos, Criaturas, Equipamento} (lidos do jogo: as zonas, as poças, os dados).
func ficha_local(id: String) -> Dictionary:
	var e := entrada(id)
	var nv: Resource = Niveis.por_id(String(e.get("nivel", "")))
	if nv == null:
		return {}
	var env := get_tree().get_first_node_in_group("environment")
	var NOMES_PERIGO := {"gas": "gás", "calor": "calor", "radiacao": "radiação", "acido": "poças de ácido", "lava": "poços de lava",
		"agua": "a água da cachoeira (molha: protege do calor)", "poeira": "poeira"}
	var perigos: Array[String] = []
	if String(nv.perigo) != "" and NOMES_PERIGO.has(String(nv.perigo)):
		perigos.append(NOMES_PERIGO[String(nv.perigo)])
	for z in get_tree().get_nodes_in_group("zonas_perigo"):
		var nz: Resource = Niveis.do_ponto(env, (z as Node2D).global_position) if env else null
		if nz and nz.id == nv.id and NOMES_PERIGO.has(String(z.kind)) and not perigos.has(NOMES_PERIGO[String(z.kind)]):
			perigos.append(NOMES_PERIGO[String(z.kind)])
	for p in nv.perigos:
		if p is Array and p.size() > 0 and NOMES_PERIGO.has(String(p[0])) and not perigos.has(NOMES_PERIGO[String(p[0])]):
			perigos.append(NOMES_PERIGO[String(p[0])])
	var criaturas: Array[String] = []
	var moradores: Array = nv.get("moradores") if nv.get("moradores") != null else []
	var kinds_moradores := moradores.map(func(m): return String(m[0]) if m is Array and m.size() > 0 else "")
	for c in nv.criaturas:
		if not kinds_moradores.has(String(c)):  # (o morador entra embaixo, com o "mora aqui")
			criaturas.append(nome(String(c)) if estudado(String(c)) else "???")
	for m in moradores:
		if m is Array and m.size() > 0:
			var nm: String = (nome(String(m[0])) if estudado(String(m[0])) else "???") + " (mora aqui)"
			if not criaturas.has(nm):
				criaturas.append(nm)
	var equip: Array[String] = []
	var eq := get_tree().get_first_node_in_group("equipment")
	if String(nv.traje) != "" and eq:
		equip.append(String(eq.NAMES.get(String(nv.traje), nv.traje)))
	var of := get_tree().get_first_node_in_group("oficina")
	for mi in nv.minerios:
		var t: String = of.tool_for_ore(String(mi)) if of else ""
		if t != "" and not equip.has(String(of.TOOL_NAMES[t])):
			equip.append(String(of.TOOL_NAMES[t]))
	var out := {}
	out["Perigos"] = ", ".join(perigos) if not perigos.is_empty() else "nenhum à vista"
	if not criaturas.is_empty():
		out["Criaturas"] = ", ".join(criaturas)
	out["Equipamento"] = ", ".join(equip) if not equip.is_empty() else "nenhum"
	return out


# ------------------------------------------------------------ corpos (Bloco 103)
## O prazo de um corpo que cai agora: [dia, segundos desde o amanhecer] — o amanhecer seguinte + horas_corpo.
func prazo_corpo() -> Array:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn == null:
		return [1, 0.0]
	return [int(dn.day) + 1, horas_corpo * float(dn.segundos_por_hora())]


## A cada segundo: os corpos que passaram do prazo somem (o drop vai pro armazém) e o desconforto da vila.
func _confere_corpos() -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	var b := get_tree().get_first_node_in_group("barricadas")
	var soma := 0.0
	for c in get_tree().get_nodes_in_group("corpos_criatura"):
		if c.is_queued_for_deletion():
			continue
		if dn and c.vencido(int(dn.day), float(dn.time)):
			c.entrega_drop()
			c.queue_free()
			continue
		if b and b.has_method("lado_de") and (b.lado_de(c.global_position) == 1
				or c.global_position.distance_to(b.global_position) <= desconforto_perto_portao):
			soma += desconforto_corpo
	desconforto = minf(soma, desconforto_max)


## O ponto andável mais perto (o ponto do reconhecimento pode cair numa pedra).
func _chao(p: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null or vp.world_2d == null:
		return p
	var map := vp.world_2d.navigation_map
	if NavigationServer2D.map_get_iteration_id(map) <= 0:
		return p
	return NavigationServer2D.map_get_closest_point(map, p)


func _lab_perto(de: Vector2) -> Node2D:
	var melhor: Node2D = null
	for l in get_tree().get_nodes_in_group("laboratorios"):
		if melhor == null or de.distance_to(l.global_position) < de.distance_to(melhor.global_position):
			melhor = l
	return melhor


## O melhor alvo pra ela agora (o que ela já reservou primeiro; senão pela prioridade e a distância). {} = nenhum.
func alvo_para(w: Node) -> Dictionary:
	for id in _reservas:
		if _reservas[id] == w:
			var a := _alvo_de(id, w)
			if not a.is_empty() and estado(id) == AVISTADO:
				return a
	var melhor := {}
	var melhor_nota := INF
	var de: Vector2 = (w as Node2D).global_position
	var anotadas := {}  # o que outra já estudou e vai entregar
	for g in get_tree().get_nodes_in_group("ipezinhos"):
		if g != w and String(g.get("nota_campo")) != "":
			anotadas[String(g.nota_campo)] = true
	for e in entradas():
		var id := String(e.id)
		if estado(id) != AVISTADO or String(estudo_lab.get("id", "")) == id or anotadas.has(id):
			continue
		var dono = _reservas.get(id)
		if dono != null and dono != w and is_instance_valid(dono):
			continue
		var a := _alvo_de(id, w)
		if a.is_empty():
			continue
		var nota: float = PRIORIDADE.get(String(e.categoria), 9) * 100000.0 + de.distance_to(a.pos)
		if nota < melhor_nota:
			melhor_nota = nota
			melhor = a
	return melhor


func tem_alvo(w: Node) -> bool:
	return not alvo_para(w).is_empty()


## Reserva o alvo (duas pesquisadoras nunca estudam a mesma entrada).
func reserva(w: Node) -> Dictionary:
	var a := alvo_para(w)
	if a.is_empty():
		return {}
	for id in _reservas.keys():
		if _reservas[id] == w and id != a.id and String(w.nota_campo) != id:
			_reservas.erase(id)
	_reservas[a.id] = w
	return a


## Solta o que ela reservou (menos a entrada que ela já anotou e ainda vai entregar).
func solta(w: Node) -> void:
	for id in _reservas.keys():
		if _reservas[id] == w and String(w.get("nota_campo")) != id:
			_reservas.erase(id)


func reservado_por(id: String) -> Node:
	var w = _reservas.get(id)
	return w if w != null and is_instance_valid(w) else null


## Onde ela entrega a anotação: o laboratório mais perto (sem laboratório, o Centro da Vila).
func entrega_pos(w: Node) -> Vector2:
	var lab := _lab_perto((w as Node2D).global_position)
	if lab:
		return lab.global_position + Vector2(0, 40)
	var hub := get_tree().get_first_node_in_group("village_hub")
	return (hub as Node2D).global_position + Vector2(0, 55) if hub else (w as Node2D).global_position


## A anotação chegou (a pesquisadora entregou).
func entrega(id: String, w: Node) -> void:
	_reservas.erase(id)
	if estado(id) == AVISTADO:
		estuda(id, w)


# ------------------------------------------------------------ plano B (o laboratório sozinho)
## "" = dá pra começar; senão o motivo.
func motivo_lab(id: String) -> String:
	if estado(id) == ESTUDADO:
		return "já estudado"
	if estado(id) == DESCONHECIDO:
		return "ainda não avistado"
	if get_tree().get_nodes_in_group("laboratorios").is_empty():
		return "sem laboratório"
	var res := get_tree().get_first_node_in_group("research")
	if res and res.current != "":
		return "o laboratório está numa pesquisa"
	if not estudo_lab.is_empty():
		return "o laboratório já está estudando: %s" % nome(String(estudo_lab.id))
	if String(entrada(id).categoria) == "criatura" and int(amostras.get(id, 0)) <= 0:
		return "sem amostra (abata uma)"
	if reservado_por(id) != null:
		return "%s já está estudando no campo" % reservado_por(id).display_name
	return ""


func estudar_no_lab(id: String) -> bool:
	if motivo_lab(id) != "":
		return false
	estudo_lab = {"id": id, "pontos": 0.0}
	mudou.emit()
	return true


func cancela_estudo_lab() -> void:
	estudo_lab = {}
	mudou.emit()


func progresso_lab() -> float:
	if estudo_lab.is_empty():
		return 0.0
	return clampf(float(estudo_lab.pontos) / maxf(float(entrada(String(estudo_lab.id)).get("pontos", 40)), 1.0), 0.0, 1.0)


func _process(delta: float) -> void:
	if not estudo_lab.is_empty():
		var res := get_tree().get_first_node_in_group("research")
		var livre: bool = not get_tree().get_nodes_in_group("laboratorios").is_empty() and (res == null or res.current == "")
		if livre:  # (com pesquisa em andamento, o estudo espera)
			estudo_lab.pontos = float(estudo_lab.pontos) + lab_pontos_sozinho * delta
			if float(estudo_lab.pontos) >= float(entrada(String(estudo_lab.id)).get("pontos", 40)):
				var id := String(estudo_lab.id)
				estudo_lab = {}
				estuda(id, null)
	_t -= delta
	if _t <= 0.0:
		_t = intervalo_confere
		_confere()


# ------------------------------------------------------------ diário e avisos
## As entradas sem página própria no diário ganham a do catálogo (o texto do arquivo).
func _registra_diario() -> void:
	var diary := get_tree().get_first_node_in_group("diary")
	if diary == null:
		return
	for e in entradas():
		if String(e.get("diario", "")) == "":
			var id := String(e.id)
			var uso := texto(id, "uso")
			diary.registra("cat_" + id, nome(id), texto(id, "texto") + ("\n\nPara que serve: " + uso if uso != "" else ""))


func _aviso(t: String, cor: Color, alvo: Node2D = null) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if alvo != null:
			hud.show_toast(t, cor, alvo)
		else:
			hud.show_toast(t, cor)


## A ficha de uma entrada estudada, linha por linha (a janela mostra): para que serve, ferramenta, receita, bicho...
func ficha(id: String) -> Array:
	var e := entrada(id)
	var out: Array = []
	var uso := texto(id, "uso")
	if uso != "":
		out.append(["Para que serve", uso])
	match String(e.get("categoria", "")):
		"minerio":
			var tipo := String(e.alvo)
			var of := get_tree().get_first_node_in_group("oficina")
			var tool: String = of.tool_for_ore(tipo) if of else ""
			out.append(["Ferramenta", of.TOOL_NAMES[tool] if tool != "" else "qualquer picareta"])
			var receitas: Array[String] = []
			for f in get_tree().get_nodes_in_group("fornalhas"):
				for r in f.receitas:
					if r.get("insumos", {}).has(tipo):
						receitas.append(String(r.get("nome", r.id)))
				break
			if receitas.is_empty():
				var proto: Script = load("res://scripts/props/fornalha.gd")  # (load: a fornalha usa o autoload Audio e testes carregam este script)
				for r in _receitas_padrao(proto):
					if r.get("insumos", {}).has(tipo):
						receitas.append(String(r.get("nome", r.id)))
			if not receitas.is_empty():
				out.append(["Fornalha", ", ".join(receitas)])
			var eco := get_tree().get_first_node_in_group("economy")
			if eco:
				var pr: float = eco.price_of(tipo)
				out.append(["Venda", ("%d cr cada" % int(pr)) if is_equal_approx(pr, roundf(pr)) else ("%.1f cr cada" % pr)])
		"animal":
			for k in [["rende", "Rende"], ["risco", "Risco"], ["epoca", "Época"]]:
				if texto(id, k[0]) != "":
					out.append([k[1], texto(id, k[0])])
		"criatura":  # Bloco 103: o bestiário
			for k in [["comportamento", "Comportamento"], ["fraqueza", "Fraqueza"]]:
				if texto(id, k[0]) != "":
					out.append([k[1], texto(id, k[0])])
			out.append(["Deixa", deixa(id)])
			out.append(["Perigo", "%s (%d de 5)" % ["●".repeat(perigo(id)) + "○".repeat(5 - perigo(id)), perigo(id)]])
			if texto(id, "porque") != "":
				out.append(["Por que veio", texto(id, "porque")])
			if texto(id, "dica") != "":
				out.append(["Dica", texto(id, "dica")])
		"local":  # Bloco 103: o reconhecimento
			var fl := ficha_local(id)
			for k in fl:
				out.append([k, fl[k]])
	var lib: Array[String] = []
	for l in e.get("libera", []):
		if String(l).begins_with("pesquisa:"):
			var res := get_tree().get_first_node_in_group("research")
			var pid := String(l).trim_prefix("pesquisa:")
			lib.append("pesquisa %s" % (res.TECHS[pid].name if res and res.TECHS.has(pid) else pid))
	if not lib.is_empty():
		out.append(["Libera", ", ".join(lib)])
	return out


## Bloco 103: as cenas das criaturas (o perigo e o que deixam são lidos delas).
const CENAS_CRIATURA := {"lumivoro": "res://scenes/creatures/lumivoro.tscn", "ferrugento": "res://scenes/creatures/ferrugento.tscn",
	"gosma": "res://scenes/creatures/gosma.tscn", "magmante": "res://scenes/creatures/magmante.tscn"}


## Um valor @export da cena da criatura (o que a cena troca; senão o padrão do script).
static func _da_cena(kind: String, prop: String, padrao: Variant) -> Variant:
	if not CENAS_CRIATURA.has(kind) or not ResourceLoader.exists(CENAS_CRIATURA[kind]):
		return padrao
	var st: SceneState = (load(CENAS_CRIATURA[kind]) as PackedScene).get_state()
	for i in st.get_node_property_count(0):
		if st.get_node_property_name(0, i) == prop:
			return st.get_node_property_value(0, i)
	return padrao


## O nível de perigo (1 a 5): a vida x o dano por segundo da criatura (a Matriarca: os multiplicadores do chefe).
func perigo(id: String) -> int:
	var e := entrada(id)
	var kind := String(e.get("alvo", id))
	var hp := float(_da_cena(kind, "max_hp", 18.0))
	var dano := float(_da_cena(kind, "damage", 4.0)) / maxf(float(_da_cena(kind, "attack_interval", 1.0)), 0.1)
	if bool(e.get("chefe", false)):
		var def := get_tree().get_first_node_in_group("defense")
		if def:
			hp *= float(def.boss_hp_mult)
			dano *= float(def.boss_damage_mult)
	var v := hp * dano
	var n := 1
	for limite in [80.0, 150.0, 250.0, 500.0]:
		if v > limite:
			n += 1
	return clampi(n, 1, 5)


## O que a criatura deixa (as chances de verdade da cena e do código).
func deixa(id: String) -> String:
	var e := entrada(id)
	var kind := String(e.get("alvo", id))
	if bool(e.get("chefe", false)):
		var def := get_tree().get_first_node_in_group("defense")
		return "solarita (%d), %d peças raras e pontos de pesquisa" % [int(def.boss_reward_solarita), int(def.boss_reward_parts)] if def else "solarita"
	var partes: Array[String] = []
	if kind == "ferrugento":
		partes.append("peça rara (35%)")
	var ore := String(_da_cena(kind, "drop_ore", ""))
	var ch := float(_da_cena(kind, "drop_chance", 0.0))
	if ore != "" and ch > 0.0:
		partes.append("%d %s (%d%%)" % [int(_da_cena(kind, "drop_amount", 0)), Ores.display_name(ore).to_lower(), roundi(ch * 100.0)])
	return ", ".join(partes) if not partes.is_empty() else "nada"


## As receitas da fornalha antes de ter uma (os @export do script).
static func _receitas_padrao(proto: Script) -> Array:
	var v = proto.get_property_default_value("receitas")
	return v if v is Array else []


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"estados": estados.duplicate(), "bruto": bruto.duplicate(), "amostras": amostras.duplicate(),
		"estudo_lab": estudo_lab.duplicate(), "descida_liberada": descida_liberada.keys()}  # Bloco 103


func load_save_data(d: Dictionary) -> void:
	estados.clear()
	var es := SaveUtil.dict(d, "estados")
	for id in es:
		var v := clampi(int(es[id]), DESCONHECIDO, ESTUDADO)
		if not entrada(String(id)).is_empty() and v > DESCONHECIDO:
			estados[String(id)] = v
	bruto.clear()
	var br := SaveUtil.dict(d, "bruto")
	for t in br:
		if Ores.TYPES.has(String(t)):
			bruto[String(t)] = maxf(float(br[t]), 0.0)
	amostras.clear()
	var am := SaveUtil.dict(d, "amostras")
	for id in am:
		if not entrada(String(id)).is_empty():
			amostras[String(id)] = maxi(int(am[id]), 0)
	var el := SaveUtil.dict(d, "estudo_lab")
	estudo_lab = {}
	if not entrada(SaveUtil.text(el, "id", "")).is_empty():
		estudo_lab = {"id": SaveUtil.text(el, "id", ""), "pontos": maxf(SaveUtil.num(el, "pontos", 0.0), 0.0)}
	descida_liberada.clear()  # Bloco 103 (save antigo: nenhuma)
	for a in SaveUtil.array(d, "descida_liberada"):
		if not entrada(String(a)).is_empty():
			descida_liberada[String(a)] = true
	_reservas.clear()
	mudou.emit()


## Depois de carregar tudo (SaveManager). tinha = o save tinha a chave "catalogo". Save antigo: o estado inicial e
## tudo que o jogo já liberou vira Estudado (ninguém perde a caça, o cobre ou a pesquisa que já tinha).
func depois_de_carregar(tinha: bool) -> void:
	if not tinha:
		_aplica_inicial()
		_migra_save_antigo()
	_avisa_mundo()
	mudou.emit()


func _migra_save_antigo() -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	var env := get_tree().get_first_node_in_group("environment")
	var diary := get_tree().get_first_node_in_group("diary")
	var res := get_tree().get_first_node_in_group("research")
	var defense := get_tree().get_first_node_in_group("defense")
	var feitas: Array = res.done if res else []
	for e in entradas():
		var id := String(e.id)
		var sim := false
		match String(e.categoria):
			"minerio":
				var tipo := String(e.alvo)
				sim = eco != null and eco.quantidade(tipo) > 0.0
				for m in get_tree().get_nodes_in_group("minerios"):
					if m.ore_type == tipo and m.is_unlocked():
						sim = true
			"animal":
				for t in get_tree().get_nodes_in_group("caca"):
					if String(t.animal) == String(e.alvo) and t.visible and not _trancado(env, t.global_position):
						sim = true
			"criatura":
				var pg := String(e.get("diario", ""))
				sim = diary != null and pg != "" and diary.has_page(pg)
				if id == "lumivoro" and defense != null and int(defense.wave) > 0:
					sim = true
			"local":
				sim = _local_aberto(e, env)
		for l in e.get("libera", []):
			if String(l).begins_with("pesquisa:") and feitas.has(String(l).trim_prefix("pesquisa:")):
				sim = true
		if sim:
			estados[id] = ESTUDADO
