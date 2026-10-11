extends Node
## Bloco 123: os PEDIDOS DA VILA (nó "Pedidos", grupo "pedidos"; Prompt 11, seção 21.2 do guia): desejos de ipezinhos COM NOME E RETRATO que aparecem na janela
## (F7) e no diário e dão ânimo ou uma recompensa quando cumpridos. Os pedidos moram em res://data/pedidos/pedidos.json (texto, prazo, meta, recompensa);
## aqui ficam a condição de cada um (`_pode`: só pede o que faz sentido naquele momento; `_progresso`: o quanto já está), o sorteio (um novo a cada
## `intervalo_dias_min`..`max` dias, no máximo `max_abertos` abertos, cada um com PRAZO) e as recompensas.
##   banco perto de casa · ninguém passando fome por N dias · casaco para todos antes do inverno · enterrar com dignidade · 3 guardas com 100% de treino ·
##   caminho de pedra até a mina · Festival das Lanternas (5 lampiões na praça)
## Nada é obrigatório: pedido que vence só some (e fica no diário). O nó responde `fatores_animo()` (o moral.gd soma: ânimo de todos) e `fatores_animo_de(w)`
## (o relacoes.gd soma: ânimo de uma pessoa ou de uma função) e guarda o festival de graça / em dobro que o morale.gd usa. Save: chave "pedidos".

signal mudou
signal pedido_novo(p: Dictionary)
signal pedido_cumprido(p: Dictionary)
signal pedido_vencido(p: Dictionary)

const DATA := "res://data/pedidos/pedidos.json"
const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Frequência")
## Os pedidos só começam a partir deste dia e quando a vila já tem esta gente adulta.
@export var primeiro_dia: int = 3
@export var adultos_minimo: int = 5
## Dias entre um pedido novo e o seguinte (sorteado entre os dois).
@export var intervalo_dias_min: int = 2
@export var intervalo_dias_max: int = 4
## No máximo tantos pedidos abertos de uma vez.
@export var max_abertos: int = 3
## Desliga os pedidos (o Criativo, os testes).
@export var ligado: bool = true
@export_group("Condições")
## Banco "perto de casa": a distância máxima (px do mundo).
@export var banco_raio: float = 110.0
## Quem tem menos que esta fração da fome (0 a 1) está com "fome braba" (o pedido "ninguém passando fome").
@export_range(0.0, 1.0) var fome_braba: float = 0.25
## Habilidade de combate que vale "100% de treino" (0 a 1).
@export_range(0.0, 1.0) var treino_cheio: float = 0.99
## Lampiões do Festival das Lanternas: a distância máxima da praça (px do mundo).
@export var lanternas_raio: float = 170.0
## O que o inverno deste ano perde de ânimo quando o pedido do casaco foi cumprido (o -3 vira 0).
@export var inverno_ameno_cancela: bool = true

static var _dados: Array = []

## Os pedidos abertos: {n, tipo, autor, dia, prazo_dia, meta, progresso}.
var abertos: Array = []
## Os encerrados (do mais antigo ao mais novo): {n, tipo, autor, titulo, dia, estado ("cumprido"/"vencido"), recompensa}.
var historico: Array = []
var proximo_dia := -1
var dias_sem_fome := 0
var _fome_hoje := false
## Recompensas guardadas pro morale.gd: o próximo festival de graça / em dobro; o inverno sem frio.
var festival_gratis := false
var festival_dobro := false
var inverno_ameno := false
var _efeitos: Array = []  # [{alvo: "*" | nome | "job:minerador", v, texto, ate_dia}]
var _n := 0
var _t := 0.0


func _ready() -> void:
	add_to_group("pedidos")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_liga.call_deferred()


func _liga() -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn and dn.has_signal("day_started") and not dn.day_started.is_connected(_novo_dia):
		dn.day_started.connect(_novo_dia)


# ------------------------------------------------------------ os dados
static func catalogo() -> Array:
	if _dados.is_empty() and FileAccess.file_exists(DATA):
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if typeof(d) == TYPE_DICTIONARY:
			_dados = d.get("tipos", [])
	return _dados


static func tipo(id: String) -> Dictionary:
	for t in catalogo():
		if String(t.id) == id:
			return t
	return {}


func _dia() -> int:
	var dn := get_tree().get_first_node_in_group("day_night")
	return int(dn.day) if dn else 1


func _adultos() -> Array:
	return get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return not (w.has_method("e_crianca") and w.e_crianca()) and not bool(w.get("visitante")))


func _acha(nome: String) -> Node:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if String(w.display_name) == nome:
			return w
	return null


# ------------------------------------------------------------ o relógio
func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 1.0
	# "fome braba" hoje? (o pedido "ninguém passando fome" conta dias seguidos sem ninguém assim)
	for w in _adultos():
		if float(w.hunger) < float(w.hunger_max) * fome_braba:
			_fome_hoje = true
			break
	var mudou_algo := false
	for p in abertos.duplicate():
		if _cumprido(p):
			_encerra(p, "cumprido")
			mudou_algo = true
	if mudou_algo:
		mudou.emit()


func _novo_dia(dia: int) -> void:
	dias_sem_fome = 0 if _fome_hoje else dias_sem_fome + 1
	_fome_hoje = false
	_efeitos = _efeitos.filter(func(e): return int(e.ate_dia) > dia)
	var sol := get_tree().get_first_node_in_group("sun")
	var estacao: int = sol.season_index() if sol and sol.has_method("season_index") else 0
	if estacao == 0:
		inverno_ameno = false  # a primavera: o inverno passou
	for p in abertos.duplicate():
		var vence: bool = dia > int(p.prazo_dia) or (String(p.tipo) == "casaco_todos" and estacao == 3)
		if vence and not _cumprido(p):
			_encerra(p, "vencido")
	if ligado and dia >= primeiro_dia and abertos.size() < max_abertos:
		if proximo_dia < 0:
			proximo_dia = dia
		if dia >= proximo_dia:
			sorteia()
	mudou.emit()


# ------------------------------------------------------------ as condições de cada pedido
## O pedido faz sentido agora? (`autor` pode ser null quando só se pergunta "dá pra pedir?")
func _pode(id: String, autor: Node = null) -> bool:
	var sol := get_tree().get_first_node_in_group("sun")
	var estacao: int = sol.season_index() if sol and sol.has_method("season_index") else 0
	match id:
		"banco_perto":
			return autor != null and autor.has_home() and not _banco_perto_de(autor)
		"sem_fome":
			return not get_tree().get_nodes_in_group("comedouros").is_empty()
		"casaco_todos":
			var eq := get_tree().get_first_node_in_group("equipment")
			return estacao in [1, 2] and eq != null and not _todos_de_casaco()
		"enterrar":
			var ms := get_tree().get_first_node_in_group("missoes")
			var morreu: bool = ms != null and int(ms.contadores.mortes) > 0
			return morreu and not _enterrar_ok()
		"guardas_100":
			var def := get_tree().get_first_node_in_group("defense")
			return not get_tree().get_nodes_in_group("campos").is_empty() and def != null and _guardas().size() >= 3 and _guardas_treinados() < 3
		"caminho_pedra":
			var cam := get_tree().get_first_node_in_group("caminhos")
			return cam != null and _pedras() < int(tipo(id).get("meta", 25)) and get_tree().get_first_node_in_group("village_hub") != null
		"festival_lanternas":
			return get_tree().get_first_node_in_group("calendario") != null and get_tree().get_first_node_in_group("decoracoes_mgr") != null and _lampioes() < int(tipo(id).get("meta", 5))
	return false


func _banco_perto_de(w: Node) -> bool:
	var casa: Node2D = w.get("_home")
	if casa == null:
		return true
	for d in get_tree().get_nodes_in_group("decoracoes"):
		if String(d.get("id")) == "banco" and (d as Node2D).global_position.distance_to(casa.global_position) <= banco_raio:
			return true
	return false


func _todos_de_casaco() -> bool:
	var ws := _adultos()
	return ws.size() >= adultos_minimo and ws.all(func(w): return (w.get("wearing") as Dictionary).has("casaco"))


func _enterrar_ok() -> bool:
	var res := get_tree().get_first_node_in_group("research")
	return not get_tree().get_nodes_in_group("cemiterios").is_empty() and res != null and res.has("ritos")


func _guardas() -> Array:
	return _adultos().filter(func(w): return String(w.get("job")) == "guarda")


func _guardas_treinados() -> int:
	return _guardas().filter(func(w): return float((w.get("habilidade") as Dictionary).get("guarda", 0.0)) >= treino_cheio).size()


func _pedras() -> int:
	var cam := get_tree().get_first_node_in_group("caminhos")
	if cam == null:
		return 0
	var n := 0
	for c in cam.celulas:
		if String(cam.celulas[c]) == "pedra":
			n += 1
	return n


func _praca() -> Vector2:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return (hub as Node2D).global_position + Vector2(0, 34) if hub else Vector2.ZERO


func _lampioes() -> int:
	var praca := _praca()
	return get_tree().get_nodes_in_group("decoracoes").filter(func(d): return String(d.get("id")) == "lampiao" and (d as Node2D).global_position.distance_to(praca) <= lanternas_raio).size()


## O quanto o pedido está (0..meta) e a meta. Pedidos de "sim ou não" têm meta 1.
func progresso(p: Dictionary) -> Array:
	var meta := int(p.get("meta", 1))
	var v := 0
	match String(p.tipo):
		"banco_perto":
			var w := _acha(String(p.autor))
			v = 1 if w != null and _banco_perto_de(w) else 0
		"sem_fome":
			v = mini(dias_sem_fome, meta)
		"casaco_todos":
			v = 1 if _todos_de_casaco() else 0
		"enterrar":
			v = 1 if _enterrar_ok() else 0
		"guardas_100":
			v = mini(_guardas_treinados(), meta)
		"caminho_pedra":
			v = mini(_pedras(), meta)
		"festival_lanternas":
			v = mini(_lampioes(), meta)
	return [v, meta]


func _cumprido(p: Dictionary) -> bool:
	var pr := progresso(p)
	return int(pr[0]) >= int(pr[1])


# ------------------------------------------------------------ o sorteio
## Sorteia um pedido que faz sentido (e abre). {} = nenhum agora.
func sorteia() -> Dictionary:
	if abertos.size() >= max_abertos:
		return {}
	var adultos := _adultos()
	if adultos.size() < adultos_minimo:
		return {}
	var abertos_tipos := abertos.map(func(p): return String(p.tipo))
	var autores := abertos.map(func(p): return String(p.autor))
	var cand: Array = []
	for t in catalogo():
		var id := String(t.id)
		if id in abertos_tipos:
			continue
		var pessoas := adultos.filter(func(w): return not (String(w.display_name) in autores))
		pessoas.shuffle()
		if id == "banco_perto":
			for w in pessoas:
				if _pode(id, w):
					cand.append([id, w])
					break
		elif _pode(id) and not pessoas.is_empty():
			cand.append([id, pessoas[0]])
	if cand.is_empty():
		proximo_dia = _dia() + 1
		return {}
	var c: Array = cand[randi() % cand.size()]
	return abre(String(c[0]), c[1])


## Abre um pedido de um tipo, feito por `autor` (o F3 e os testes chamam direto).
func abre(id: String, autor: Node) -> Dictionary:
	var t := tipo(id)
	if t.is_empty() or autor == null:
		return {}
	_n += 1
	var dia := _dia()
	var p := {"n": _n, "tipo": id, "autor": String(autor.display_name), "dia": dia, "prazo_dia": dia + int(t.get("dias", 10)), "meta": int(t.get("meta", 1))}
	abertos.append(p)
	proximo_dia = dia + randi_range(intervalo_dias_min, maxi(intervalo_dias_min, intervalo_dias_max))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s pediu: %s  (F7)" % [String(autor.display_name), String(t.titulo)], Color(1.0, 0.9, 0.55), autor)
	pedido_novo.emit(p)
	mudou.emit()
	return p


func texto_de(p: Dictionary) -> String:
	var t := tipo(String(p.tipo))
	return String(t.get("texto", "")).replace("{nome}", String(p.autor)).replace("{meta}", str(int(p.meta))).replace("{raio}", str(roundi(banco_raio)))


func titulo_de(p: Dictionary) -> String:
	return String(tipo(String(p.tipo)).get("titulo", String(p.tipo)))


func recompensa_texto(p: Dictionary) -> String:
	return String(tipo(String(p.tipo)).get("recompensa_texto", "")).replace("{nome}", String(p.autor))


## Dias que faltam pro prazo.
func dias_restantes(p: Dictionary) -> int:
	return int(p.prazo_dia) - _dia()


# ------------------------------------------------------------ encerrar e recompensar
func _encerra(p: Dictionary, estado: String) -> void:
	abertos.erase(p)
	var dia := _dia()
	var h := {"n": int(p.n), "tipo": String(p.tipo), "autor": String(p.autor), "titulo": titulo_de(p), "dia": dia, "estado": estado,
		"recompensa": recompensa_texto(p) if estado == "cumprido" else ""}
	historico.append(h)
	if historico.size() > 40:
		historico.pop_front()
	var hud := get_tree().get_first_node_in_group("hud")
	var autor := _acha(String(p.autor))
	if estado == "cumprido":
		_recompensa(p)
		if hud:
			hud.show_toast("Pedido cumprido: %s. %s." % [titulo_de(p), recompensa_texto(p).capitalize()], Color(0.55, 1.0, 0.5), autor)
		_som("stinger", "missao_cumprida")
		pedido_cumprido.emit(p)
	else:
		if hud:
			hud.show_toast("%s desistiu do pedido: %s." % [String(p.autor), titulo_de(p)], Color(0.85, 0.7, 0.6), autor)
		pedido_vencido.emit(p)
	_diario(h)
	mudou.emit()


func _recompensa(p: Dictionary) -> void:
	var r: Dictionary = tipo(String(p.tipo)).get("recompensa", {})
	var dia := _dia()
	if r.has("animo_pessoa"):
		_efeitos.append({"alvo": String(p.autor), "v": float(r.animo_pessoa), "texto": "pedido cumprido", "ate_dia": dia + int(r.get("dias", 2))})
	if r.has("animo_vila"):
		_efeitos.append({"alvo": "*", "v": float(r.animo_vila), "texto": "pedido da vila cumprido", "ate_dia": dia + int(r.get("dias", 3))})
	if r.has("animo_funcao"):
		_efeitos.append({"alvo": "job:" + String(r.animo_funcao), "v": float(r.get("v", 8)), "texto": "o caminho de pedra ficou pronto", "ate_dia": dia + int(r.get("dias", 3))})
	if bool(r.get("festival_gratis", false)):
		festival_gratis = true
	if bool(r.get("festival_dobro", false)):
		festival_dobro = true
	if bool(r.get("inverno_ameno", false)):
		inverno_ameno = true
	if String(r.get("arma", "")) != "":
		var def := get_tree().get_first_node_in_group("defense")
		if def:
			var arma := String(r.arma)
			def.rack[arma] = def.rack_count(arma) + 1
			if not def.weapons.has(arma):
				def.weapons.append(arma)
			for w in def.guards():
				w.wake_decision()


func _diario(h: Dictionary) -> void:
	var diary := get_tree().get_first_node_in_group("diary")
	if diary == null:
		return
	var pid := "pedido_%d" % int(h.n)
	var txt := ""
	if String(h.estado) == "cumprido":
		txt = "%s tinha pedido: %s. A vila deu um jeito e o pedido foi cumprido no dia %d. %s." % [String(h.autor), String(h.titulo).to_lower(), int(h.dia), String(h.recompensa).capitalize()]
	else:
		txt = "%s tinha pedido: %s. O prazo passou no dia %d sem que a vila desse conta. Ninguém reclamou alto." % [String(h.autor), String(h.titulo).to_lower(), int(h.dia)]
	diary.registra(pid, "Pedido de %s" % String(h.autor), txt)
	diary.unlock(pid, false)


# ------------------------------------------------------------ o ânimo e o festival (o moral.gd e o relacoes.gd perguntam)
## [texto, valor] pra todo mundo: os pedidos de vila inteira e o inverno sem frio.
func fatores_animo() -> Array:
	var out: Array = []
	for e in _efeitos:
		if String(e.alvo) == "*" and float(e.v) != 0.0:
			out.append([String(e.texto), float(e.v)])
	var sol := get_tree().get_first_node_in_group("sun")
	if inverno_ameno and inverno_ameno_cancela and sol and sol.has_method("season_index") and sol.season_index() == 3 and float(sol.winter_joy) < 0.0:
		out.append(["inverno ameno (pedido do casaco)", -float(sol.winter_joy)])
	return out


## O que vale só pra essa pessoa (o pedido dela) ou pra função dela.
func fatores_animo_de(w: Node) -> Array:
	var out: Array = []
	for e in _efeitos:
		var alvo := String(e.alvo)
		if alvo == String(w.display_name) or (alvo.begins_with("job:") and String(w.get("job")) == alvo.trim_prefix("job:")):
			out.append([String(e.texto), float(e.v)])
	return out


## O morale.gd pergunta ao dar o festival: {gratis, mult}; ao gastar, o pedido se consome.
func consome_festival() -> Dictionary:
	var r := {"gratis": festival_gratis, "mult": 2.0 if festival_dobro else 1.0}
	festival_gratis = false
	festival_dobro = false
	mudou.emit()
	return r


# ------------------------------------------------------------ save/load
func get_save_data() -> Dictionary:
	return {"abertos": abertos.duplicate(true), "historico": historico.duplicate(true), "proximo_dia": proximo_dia, "dias_sem_fome": dias_sem_fome, "n": _n,
		"festival_gratis": festival_gratis, "festival_dobro": festival_dobro, "inverno_ameno": inverno_ameno, "efeitos": _efeitos.duplicate(true), "ligado": ligado}


func load_save_data(d: Dictionary) -> void:
	_n = SaveUtil.integer(d, "n", 0)
	proximo_dia = SaveUtil.integer(d, "proximo_dia", -1)
	dias_sem_fome = SaveUtil.integer(d, "dias_sem_fome", 0)
	festival_gratis = SaveUtil.boolean(d, "festival_gratis", false)
	festival_dobro = SaveUtil.boolean(d, "festival_dobro", false)
	inverno_ameno = SaveUtil.boolean(d, "inverno_ameno", false)
	ligado = SaveUtil.boolean(d, "ligado", ligado)
	abertos = []
	for p in SaveUtil.array(d, "abertos"):
		if typeof(p) == TYPE_DICTIONARY and not tipo(String(p.get("tipo", ""))).is_empty() and String(p.get("autor", "")) != "":
			abertos.append({"n": int(p.get("n", 0)), "tipo": String(p.tipo), "autor": String(p.autor), "dia": int(p.get("dia", 1)),
				"prazo_dia": int(p.get("prazo_dia", 99999)), "meta": int(p.get("meta", 1))})
	historico = []
	for h in SaveUtil.array(d, "historico"):
		if typeof(h) == TYPE_DICTIONARY and not tipo(String(h.get("tipo", ""))).is_empty():
			historico.append({"n": int(h.get("n", 0)), "tipo": String(h.tipo), "autor": String(h.get("autor", "")), "titulo": String(h.get("titulo", "")),
				"dia": int(h.get("dia", 1)), "estado": String(h.get("estado", "vencido")), "recompensa": String(h.get("recompensa", ""))})
	_efeitos = []
	for e in SaveUtil.array(d, "efeitos"):
		if typeof(e) == TYPE_DICTIONARY and String(e.get("alvo", "")) != "":
			_efeitos.append({"alvo": String(e.alvo), "v": float(e.get("v", 0.0)), "texto": String(e.get("texto", "")), "ate_dia": int(e.get("ate_dia", 0))})
	_diarios_de_volta.call_deferred()
	mudou.emit()


func _diarios_de_volta() -> void:
	for h in historico:
		_diario(h)


## O autoload Audio por caminho (os testes carregam este script antes dos autoloads).
func _som(metodo: String, arg: String = "") -> void:
	var a := get_node_or_null("/root/Audio")
	if a == null:
		return
	if arg != "":
		a.call(metodo, arg)
	else:
		a.call(metodo)
