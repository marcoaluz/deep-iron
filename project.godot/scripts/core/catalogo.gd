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

signal mudou
signal entrada_avistada(id: String)
signal entrada_estudada(id: String, categoria: String)

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
		if quem.has_method("_popup"):
			quem._popup("Estudou: %s!" % nome(id), Color(0.75, 0.9, 1.0))
	_aviso("Estudou: %s%s" % [nome(id), extra], Color(0.6, 1.0, 0.75), quem if quem is Node2D else null)
	var au := get_node_or_null("/root/Audio")
	if au:
		au.find((quem as Node2D).global_position if quem is Node2D and is_instance_valid(quem) else Vector2.ZERO)
	_avisa_mundo()
	entrada_estudada.emit(id, cat)
	mudou.emit()
	return true


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
		_aviso("Amostra de %s guardada: a pesquisadora estuda no laboratório (Catálogo, R)" % nome(id), Color(0.75, 0.85, 1.0))
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
							and c.has_method("is_alive") and c.is_alive():
						avista(id, false)  # (a invasão já avisa)
						break
			"local":
				if _local_aberto(e, env):
					avista(id)
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


## Perigoso pra esta pesquisadora? (zona de gás/radiação/calor ou poça de ácido/lava sem o traje)
func perigoso(pos: Vector2, w: Node) -> bool:
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
				var pos := _chao(Vector2(float(p[0]), float(p[1])))
				if not perigoso(pos, w):
					return {"id": id, "pos": pos, "lab": false}
		"criatura":
			var lab := _lab_perto(de)
			if lab and int(amostras.get(id, 0)) > 0:
				return {"id": id, "pos": lab.global_position + Vector2(0, 40), "lab": true}
	return {}


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
	var lib: Array[String] = []
	for l in e.get("libera", []):
		if String(l).begins_with("pesquisa:"):
			var res := get_tree().get_first_node_in_group("research")
			var pid := String(l).trim_prefix("pesquisa:")
			lib.append("pesquisa %s" % (res.TECHS[pid].name if res and res.TECHS.has(pid) else pid))
	if not lib.is_empty():
		out.append(["Libera", ", ".join(lib)])
	return out


## As receitas da fornalha antes de ter uma (os @export do script).
static func _receitas_padrao(proto: Script) -> Array:
	var v = proto.get_property_default_value("receitas")
	return v if v is Array else []


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"estados": estados.duplicate(), "bruto": bruto.duplicate(), "amostras": amostras.duplicate(),
		"estudo_lab": estudo_lab.duplicate()}


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
