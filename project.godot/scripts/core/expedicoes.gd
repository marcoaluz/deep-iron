extends Node
## Bloco 104: as EXPEDIÇÕES (nó "Expedicoes" na main.tscn, grupo "expedicoes") e a CADEIA DO ROBÔ ANTIGO.
##
## - As REGIÕES vêm de dados (data/expedicoes/regioes.json + textos.txt): perigo, dias, por onde se sai (o portão da
##   floresta ou um andar da mina), o traje exigido, como aparece ("?" até ser revelada) e o que se acha.
## - Uma expedição = uma região, uma EQUIPE de 2 a 4 (o BATEDOR lidera e é obrigatório; guardas, pesquisadora, médico), a
##   RAÇÃO (porções da cozinha por pessoa por dia), o KIT de ferramentas (opcional) e os dias. A equipe anda até a saída e
##   SAI DO MUNDO (ipezinho.sai_do_mundo: escondida, fora do grupo da vila — não trabalha, não come, não defende; a cama
##   fica guardada). No meio do caminho, 1 ou 2 DECISÕES (um cartão com 2 opções; sem resposta, a prudente). Na volta, o
##   RELATÓRIO (achados, feridos, mortes) na janela, no banner e no diário.
## - O RISCO: o perigo da região x escolta x traje x ração x kit x batedor (risco_partes mostra cada um).
## - A CADEIA DO ROBÔ (no lugar da sorte do finds.gd): 1 a origem (o corpo do Ferrugento estudado) -> 2 o sinal (o Rádio, ou
##   a Antena improvisada da Oficina, de noite) -> 3 as 3 escutas (pistas do catálogo: a pesquisadora anota no portão, na
##   pedreira e na boca do poço) -> 4 a região "A fábrica soterrada" (atrás da radiação do S2) -> 5 a expedição acha o robô
##   (ele chega no portão "found" e o fluxo de sempre continua). Save antigo sem robô: a sorte continua como reserva.
## Save: chave "expedicoes" (reveladas, em curso com o save de quem está fora, a cadeia, os relatórios).

signal mudou
signal expedicao_saiu(regiao: String)
signal expedicao_voltou(regiao: String, resultado: Dictionary)
signal regiao_revelada(id: String)
signal robo_localizado

const SaveUtil := preload("res://scripts/core/save_util.gd")
const Missoes := preload("res://scripts/core/missoes.gd")
const Items := preload("res://scripts/core/items.gd")
const ARQ := "res://data/expedicoes/regioes.json"
const ARQ_TEXTOS := "res://data/expedicoes/textos.txt"
const ESCUTAS := ["escuta_portao", "escuta_pedreira", "escuta_poco"]

@export_group("Expedições")
## Quantas expedições ao mesmo tempo (sem e com a melhoria "Posto de expedição" do Centro).
@export var max_expedicoes: int = 1
@export var max_com_posto: int = 2
## Tamanho da equipe.
@export var equipe_min: int = 2
@export var equipe_max: int = 4
## Ração: porções da cozinha (Schedule.porcao) por pessoa por dia de expedição.
@export var racao_porcoes_dia: float = 2.0
## Kit de ferramentas (opcional): ferro e madeira; menos risco e mais minério nos achados.
@export var kit_ferro: int = 20
@export var kit_madeira: int = 15
@export var kit_minerio_mult: float = 1.3
## Depois desta hora a equipe não sai mais (sai de dia) e a hora em que ela volta (no dia da volta).
@export var hora_saida_max: float = 15.0
@export var hora_volta: float = 8.0
## Segundos (de jogo) andando até a saída antes de "sumir" mesmo sem chegar (não trava).
@export var tempo_max_saindo: float = 150.0
## Horas de jogo pra responder uma decisão do caminho (sem resposta: a prudente).
@export var horas_decisao: float = 2.0

@export_group("Risco")
## Cada guarda armado na escolta multiplica o risco por isto, até o mínimo.
@export var mult_guarda: float = 0.8
@export var mult_guarda_min: float = 0.5
@export var mult_batedor: float = 0.7
## Sem o traje que a região pede (pra alguém da equipe), sem ração inteira, com o kit, explorando uma região "?".
@export var mult_sem_traje: float = 3.0
@export var mult_sem_racao: float = 2.0
@export var mult_kit: float = 0.85
@export var mult_explorar: float = 1.2
## Ferido: chance de ser grave; grave: chance de morrer sem e com médico na equipe.
@export var chance_grave: float = 0.3
@export var morte_sem_medico: float = 0.3
@export var morte_com_medico: float = 0.05

@export_group("Achados")
## O batedor: + esta fração na chance de mapas, pistas e entradas do catálogo.
@export var bonus_batedor_pistas: float = 0.5
## Explorar uma região "?" (a 1ª ida): os achados valem esta fração.
@export var achado_explorar: float = 0.5

@export_group("O batedor na vila")
## O batedor (sem expedição) avista bichos e lugares de mais longe: alcance do catálogo x isto.
@export var batedor_alcance_mult: float = 3.0
## Toca rastreada pelo batedor no dia: os bichos nascem mais rápido (x isto).
@export var toca_rastreada_mult: float = 1.5

static var _dados := {}
static var _textos := {}

## Regiões reveladas: {id: true}.
var reveladas := {}
## Em curso: [{n, regiao, fase ("saindo"/"fora"), membros [nós], nomes [], saves [] (do load), racao, kit, explorar,
## dias, partida_dia, volta_dia, volta_t, decisoes [{evento, quando_t, escolha}], mult_risco, mult_achado, extra_t, log []}]
var em_curso: Array = []
## A cadeia do robô (0 nada .. 5 achado).
var cadeia := 0
## Save antigo sem o robô: a sorte do finds.gd continua (só pra eles).
var sorte_robo := false
## Os relatórios das últimas expedições (o mais novo no fim).
var relatorios: Array = []
var _n := 0
var _t := 0.0
## Telemetria (totais da partida).
var total_voltaram := 0
var total_achados := 0
var total_feridos := 0
## As regiões de onde já voltou uma expedição: {id: true} (as missões).
var voltou_de := {}
var _saindo_t := {}


func _ready() -> void:
	add_to_group("expedicoes")
	for r in regioes():
		if String(r.aparece) == "inicio":
			reveladas[String(r.id)] = true
	_liga.call_deferred()


func _liga() -> void:
	var cat := get_tree().get_first_node_in_group("catalogo")
	if cat and cat.has_signal("entrada_estudada"):
		cat.entrada_estudada.connect(_estudou)
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		var tx: Dictionary = textos().get("cadeia", {})
		for k in ["origem", "sinal", "triangulacao", "regiao"]:
			diary.registra("robo_" + k, String(tx.get(k + "_titulo", k)), String(tx.get(k, "")))
		for sec in textos():
			if String(sec).begins_with("pista."):
				var p: Dictionary = textos()[sec]
				diary.registra("exp_" + String(sec), String(p.get("titulo", sec)), String(p.get("texto", "")))


# ------------------------------------------------------------ dados
static func dados() -> Dictionary:
	if _dados.is_empty() and FileAccess.file_exists(ARQ):
		var j = JSON.parse_string(FileAccess.get_file_as_string(ARQ))
		if j is Dictionary:
			_dados = j
	return _dados


static func regioes() -> Array:
	return dados().get("regioes", [])


static func regiao(id: String) -> Dictionary:
	for r in regioes():
		if String(r.id) == id:
			return r
	return {}


static func textos() -> Dictionary:
	if _textos.is_empty() and FileAccess.file_exists(ARQ_TEXTOS):
		_textos = Missoes.interpreta(FileAccess.get_file_as_string(ARQ_TEXTOS))
	return _textos


static func texto(sec: String, chave: String) -> String:
	return String(textos().get(sec, {}).get(chave, ""))


static func nome(id: String) -> String:
	var n := texto(id, "nome")
	return n if n != "" else id


# ------------------------------------------------------------ regiões
## Como a região está pra vila: "revelada", "escondida" ("?": dá pra explorar com batedor) ou "trancada" (+ o motivo).
func situacao(id: String) -> Array:
	var r := regiao(id)
	if r.is_empty():
		return ["trancada", "região desconhecida"]
	if reveladas.has(id):
		return ["revelada", ""]
	var ap := String(r.aparece)
	if ap == "batedor":
		return ["escondida", ""]
	if ap == "leste":
		var env := get_tree().get_first_node_in_group("environment")
		return ["escondida", ""] if env and bool(env.get("leste_aberto")) else ["trancada", "desbrave o leste primeiro"]
	if ap == "cadeia":
		return ["trancada", "o sinal antigo ainda não foi achado"]
	if ap.begins_with("andar:"):
		var cat := get_tree().get_first_node_in_group("catalogo")
		var a := ap.trim_prefix("andar:")
		return ["revelada", ""] if cat and cat.estudado(a) else ["trancada", "reconheça o %s primeiro" % a]
	return ["trancada", ""]


func revela(id: String, avisa := true) -> bool:
	if reveladas.has(id) or regiao(id).is_empty():
		return false
	reveladas[id] = true
	if avisa:
		_aviso("Região revelada: %s (Expedições, ;)" % nome(id), Color(0.75, 0.95, 0.7))
	regiao_revelada.emit(id)
	mudou.emit()
	return true


# ------------------------------------------------------------ a equipe e o risco
func max_agora() -> int:
	var hub := get_tree().get_first_node_in_group("village_hub")
	return max_com_posto if hub and int(hub.upgrades.get("posto", 0)) > 0 else max_expedicoes


func fora_agora() -> Array:
	var out: Array = []
	for e in em_curso:
		out.append_array(e.membros.filter(func(w): return is_instance_valid(w)))
	return out


## Pode ir nessa equipe? (função certa, inteiro, não está noutra expedição)
func membro_ok(w: Node) -> bool:
	if not is_instance_valid(w) or not w.is_in_group("ipezinhos") or w.injured or w.get("downed") or w.get("fora"):
		return false
	return w.job in ["batedor", "guarda", "pesquisador", "médico"]


## As porções da ração dessa equipe (comida da cozinha).
func racao_total(n: int, dias: float) -> float:
	var s := get_tree().get_first_node_in_group("schedule")
	var porcao: float = float(s.porcao) if s else 8.0
	return racao_porcoes_dia * porcao * n * dias


## Bloco 107: as rações PRONTAS (item "racao", feitas na cozinha por ordem) e a comida que elas cobrem: 1 ração = 1 pessoa por
## 1 dia = `racao_porcoes_dia` porções.
func racoes_prontas() -> float:
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.quantidade("racao") if eco else 0.0


func comida_por_racao() -> float:
	var s := get_tree().get_first_node_in_group("schedule")
	return racao_porcoes_dia * (float(s.porcao) if s else 8.0)


## Quantas rações prontas essa equipe gasta (as que existem, até o necessário).
func racoes_a_gastar(n: int, dias: float) -> int:
	return mini(int(floor(racoes_prontas())), ceili(float(n) * dias))


## A comida que ainda faltaria tirar da cozinha depois das rações prontas.
func comida_a_tirar(n: int, dias: float) -> float:
	return maxf(racao_total(n, dias) - float(racoes_a_gastar(n, dias)) * comida_por_racao(), 0.0)


func comida_na_cozinha() -> float:
	var t := 0.0
	for c in get_tree().get_nodes_in_group("comedouros"):
		t += float(c.food_stock)
	return t


func _tem_traje(traje: String) -> bool:
	if traje == "":
		return true
	var eq := get_tree().get_first_node_in_group("equipment")
	return eq != null and eq.has_method("usable") and int(eq.usable(traje)) + int(eq.in_use(traje)) > 0


## O risco por pessoa por dia e as partes: {total, partes: [[texto, multiplicador ou base]]}.
func risco(id: String, equipe: Array, racao: bool, kit: bool) -> Dictionary:
	var r := regiao(id)
	var base := float(r.get("perigo", 0.1))
	var partes: Array = [["perigo da região", base]]
	var m := 1.0
	var guardas := equipe.filter(func(w): return is_instance_valid(w) and w.job == "guarda" and String(w.weapon) != "").size()
	if guardas > 0:
		var g := maxf(pow(mult_guarda, guardas), mult_guarda_min)
		m *= g
		partes.append(["escolta (%d guarda%s)" % [guardas, "s" if guardas > 1 else ""], g])
	if equipe.any(func(w): return is_instance_valid(w) and w.job == "batedor"):
		m *= mult_batedor
		partes.append(["o batedor conhece o caminho", mult_batedor])
	var traje := String(r.get("traje", ""))
	if traje != "" and not _tem_traje(traje):
		m *= mult_sem_traje
		var eq := get_tree().get_first_node_in_group("equipment")
		partes.append(["sem %s" % (String(eq.NAMES.get(traje, traje)).to_lower() if eq else traje), mult_sem_traje])
	if not racao:
		m *= mult_sem_racao
		partes.append(["sem ração", mult_sem_racao])
	if kit:
		m *= mult_kit
		partes.append(["kit de ferramentas", mult_kit])
	if situacao(id)[0] == "escondida":
		m *= mult_explorar
		partes.append(["explorando o desconhecido", mult_explorar])
	return {"total": clampf(base * m, 0.0, 0.95), "partes": partes}


## A chance de alguém da equipe voltar ferido (pra janela).
func chance_alguem_ferido(id: String, equipe: Array, racao: bool, kit: bool, dias: float) -> float:
	var p: float = risco(id, equipe, racao, kit).total
	var ninguem := pow(1.0 - p, float(equipe.size()) * dias)
	return 1.0 - ninguem


## "" = pode sair; senão o motivo.
func motivo(id: String, equipe: Array, racao: bool, kit: bool, dias: int) -> String:
	var sit := situacao(id)
	if sit[0] == "trancada":
		return String(sit[1])
	if em_curso.size() >= max_agora():
		return "já tem %d expedição%s fora (o Posto de expedição libera mais)" % [em_curso.size(), "ões" if em_curso.size() > 1 else ""]
	if em_curso.any(func(e): return String(e.regiao) == id):
		return "já tem uma expedição lá"
	if equipe.size() < equipe_min or equipe.size() > equipe_max:
		return "a equipe é de %d a %d" % [equipe_min, equipe_max]
	if not equipe.any(func(w): return is_instance_valid(w) and w.job == "batedor"):
		return "precisa de um batedor (ele lidera)"
	for w in equipe:
		if not membro_ok(w):
			return "%s não pode ir" % (w.display_name if is_instance_valid(w) else "alguém")
	var r := regiao(id)
	var dmin := int((r.get("dias", [1, 1]) as Array)[0])
	var dmax := int((r.get("dias", [1, 1]) as Array)[1])
	if dias < dmin or dias > dmax:
		return "essa região leva de %d a %d dia%s" % [dmin, dmax, "s" if dmax > 1 else ""]
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn and (dn.is_night() or float(dn.hora()) >= hora_saida_max or float(dn.hora()) < float(dn.hora_amanhecer)):
		return "só sai de dia (até as %02d:00)" % int(hora_saida_max)
	if racao and comida_na_cozinha() < comida_a_tirar(equipe.size(), dias):  # Bloco 107: as rações prontas contam primeiro
		return "falta comida pra ração (%d na cozinha, precisa de %d; %d rações prontas)" % [int(comida_na_cozinha()), int(comida_a_tirar(equipe.size(), dias)), int(racoes_prontas())]
	if kit:
		var eco := get_tree().get_first_node_in_group("economy")
		var falta: String = eco.missing_text(0, kit_ferro, "ferro", kit_madeira) if eco else ""
		if falta != "":
			return "kit: " + falta
	return ""


# ------------------------------------------------------------ partir
func parte(id: String, equipe: Array, racao: bool, kit: bool, dias: int) -> bool:
	if motivo(id, equipe, racao, kit, dias) != "":
		return false
	var dn := get_tree().get_first_node_in_group("day_night")
	if racao:
		var eco_r := get_tree().get_first_node_in_group("economy")
		var n_prontas := racoes_a_gastar(equipe.size(), dias)  # Bloco 107: gasta as rações prontas primeiro
		var falta := comida_a_tirar(equipe.size(), dias)
		if n_prontas > 0 and eco_r:
			eco_r.tira("racao", float(n_prontas))
		for c in get_tree().get_nodes_in_group("comedouros"):
			var tira := minf(float(c.food_stock), falta)
			c.food_stock = float(c.food_stock) - tira
			if c.has_method("_update_visual"):
				c._update_visual()
			falta -= tira
	if kit:
		var eco := get_tree().get_first_node_in_group("economy")
		if eco:
			eco.spend(0, kit_ferro, "ferro", kit_madeira)
	_n += 1
	var r := regiao(id)
	var e := {"n": _n, "regiao": id, "fase": "saindo", "membros": equipe.duplicate(), "nomes": equipe.map(func(w): return String(w.name)),
		"racao": racao, "kit": kit, "explorar": situacao(id)[0] == "escondida", "dias": dias,
		"partida_dia": int(dn.day) if dn else 1, "volta_dia": (int(dn.day) if dn else 1) + dias,
		"volta_t": float(dn.tempo_da_hora(hora_volta)) if dn else 0.0, "decisoes": [], "mult_risco": 1.0, "mult_achado": 1.0,
		"extra_t": 0.0, "log": [texto(id, "chegada")], "risco": risco(id, equipe, racao, kit).total}
	# as decisões do caminho: 1 (1 dia) ou 2 (2+ dias), no meio da viagem
	var evs: Array = (r.get("eventos", []) as Array).duplicate()
	evs.shuffle()
	var n_ev := 1 if dias <= 1 else 2
	var seg_dia: float = float(dn.cycle_length()) if dn else 540.0
	for i in mini(n_ev, evs.size()):
		e.decisoes.append({"evento": String(evs[i]), "quando": seg_dia * dias * (float(i) + 1.0) / float(n_ev + 1),
			"escolha": "", "mostrada": false})
	e["decorrido"] = 0.0
	em_curso.append(e)
	var saida := ponto_saida(id)
	for w in equipe:
		w.vai_pra_expedicao(saida)
	_aviso("A expedição pra %s saiu: %s." % [nome(id), ", ".join(PackedStringArray(equipe.map(func(w): return String(w.display_name))))],
		Color(0.95, 0.85, 0.55))
	expedicao_saiu.emit(id)
	mudou.emit()
	return true


## Onde a equipe sai (e volta): do lado de fora do portão, na floresta; ou o ponto do andar (a região da mina).
func ponto_saida(id: String) -> Vector2:
	var r := regiao(id)
	var s := String(r.get("saida", "portao"))
	if r.has("saida_pos"):
		var p: Array = r.saida_pos
		return Vector2(float(p[0]), float(p[1]))
	if s == "portao":
		var b := get_tree().get_first_node_in_group("barricadas")
		if b and b.has_method("inside_dir"):
			return (b as Node2D).global_position - (b.inside_dir() as Vector2) * 110.0
		return Vector2(-420, -40)
	var Cat := preload("res://scripts/core/catalogo.gd")
	var pos: Array = Cat.entrada(s).get("pos", [])
	return Vector2(float(pos[0]), float(pos[1])) if pos.size() >= 2 else Vector2.ZERO


# ------------------------------------------------------------ o relógio das expedições
func _process(delta: float) -> void:
	if em_curso.is_empty():
		_t -= delta
		if _t <= 0.0:
			_t = 1.0
			_confere_cadeia()
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	for e in em_curso.duplicate():
		match String(e.fase):
			"saindo":
				_saindo(e, delta)
			"fora":
				e.decorrido = float(e.decorrido) + delta
				_decisoes(e)
				if dn and _hora_da_volta(e, dn):
					_volta(e)
	_t -= delta
	if _t <= 0.0:
		_t = 1.0
		_confere_cadeia()


## A equipe andando até a saída: quem chegou (ou passou do tempo) sai do mundo; todos fora = a viagem começa.
func _saindo(e: Dictionary, delta: float) -> void:
	e["saindo_t"] = float(e.get("saindo_t", 0.0)) + delta
	var saida := ponto_saida(String(e.regiao))
	var todos := true
	for w in e.membros:
		if not is_instance_valid(w):
			continue
		if w.get("fora"):
			continue
		if w.global_position.distance_to(saida) < 40.0 or float(e.saindo_t) > tempo_max_saindo:
			w.sai_do_mundo()
		else:
			todos = false
	if todos:
		e.fase = "fora"


func _hora_da_volta(e: Dictionary, dn: Node) -> bool:
	var dia := int(e.volta_dia)
	var t := float(e.volta_t) + float(e.extra_t)
	var seg_dia := float(dn.cycle_length())
	while t >= seg_dia:
		t -= seg_dia
		dia += 1
	if int(dn.day) < dia or (int(dn.day) == dia and float(dn.time) < t):
		return false
	return not dn.is_night()  # (de noite eles esperam o dia pra entrar)


## As decisões do caminho: o cartão aparece na hora; sem resposta em horas_decisao, vale a prudente.
func _decisoes(e: Dictionary) -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	var seg_h: float = float(dn.segundos_por_hora()) if dn else 22.5
	for d in e.decisoes:
		if String(d.escolha) != "" or float(e.decorrido) < float(d.quando):
			continue
		if not d.mostrada:
			d.mostrada = true
			_mostra_decisao(e, d)
		elif float(e.decorrido) >= float(d.quando) + horas_decisao * seg_h:
			var ev: Dictionary = dados().get("eventos", {}).get(String(d.evento), {})
			decide(int(e.n), String(d.evento), String(ev.get("prudente", "b")), true)


func _mostra_decisao(e: Dictionary, d: Dictionary) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("confirma"):
		return
	var sec := "evento." + String(d.evento)
	var n := int(e.n)
	var ev := String(d.evento)
	var sim := func(): decide(n, ev, "a")
	var nao := func(): decide(n, ev, "b")
	hud.confirma("%s — %s" % [nome(String(e.regiao)), texto(sec, "titulo")], texto(sec, "texto"), sim, texto(sec, "a"), texto(sec, "b"), nao)
	var au := get_node_or_null("/root/Audio")
	if au and au.has_method("click"):
		au.click()


## A escolha de uma decisão ("a" ou "b"): muda o risco, os achados e a duração.
func decide(n: int, evento: String, escolha: String, sozinha := false) -> void:
	for e in em_curso:
		if int(e.n) != n:
			continue
		for d in e.decisoes:
			if String(d.evento) != evento or String(d.escolha) != "":
				continue
			d.escolha = escolha
			var ef: Dictionary = dados().get("eventos", {}).get(evento, {}).get(escolha, {})
			e.mult_risco = float(e.mult_risco) * float(ef.get("risco", 1.0))
			e.mult_achado = float(e.mult_achado) * float(ef.get("achado", 1.0))
			var dn := get_tree().get_first_node_in_group("day_night")
			e.extra_t = float(e.extra_t) + float(ef.get("dias", 0.0)) * (float(dn.cycle_length()) if dn else 540.0)
			e.log.append(texto("evento." + evento, escolha + "_depois") + (" (sem notícia da vila: a equipe escolheu sozinha)" if sozinha else ""))
			mudou.emit()
			return


# ------------------------------------------------------------ a volta
func _volta(e: Dictionary) -> void:
	em_curso.erase(e)
	var r := regiao(String(e.regiao))
	var saida := ponto_saida(String(e.regiao))
	var res := {"regiao": String(e.regiao), "achados": [], "feridos": [], "mortos": [], "texto": ""}
	var vivos: Array = e.membros.filter(func(w): return is_instance_valid(w))
	var tem_medico := vivos.any(func(w): return w.job == "médico")
	var tem_batedor := vivos.any(func(w): return w.job == "batedor")
	var pesq: Node = null
	for w in vivos:
		if w.job == "pesquisador":
			pesq = w
	# os ferimentos (por pessoa, pelos dias) e as mortes
	var p := clampf(float(e.risco) * float(e.mult_risco), 0.0, 0.95)
	var dias := float(e.dias) + float(e.extra_t) / maxf(_seg_dia(), 1.0)
	for w in vivos.duplicate():
		if randf() < 1.0 - pow(1.0 - p, dias):
			var grave := randf() < chance_grave
			if grave and randf() < (morte_com_medico if tem_medico else morte_sem_medico):
				res.mortos.append(String(w.display_name))
				vivos.erase(w)
				w.morre_na_expedicao(nome(String(e.regiao)))
				continue
			res.feridos.append([String(w.display_name), "grave" if grave and not tem_medico else "leve"])
			w.set_meta("ferido_expedicao", "grave" if grave and not tem_medico else "leve")
	# quem voltou entra no mundo pela saída (e os ferimentos valem a partir daí)
	for w in vivos:
		w.volta_ao_mundo(saida + Vector2(randf_range(-14, 14), randf_range(-10, 10)))
		if w.has_meta("ferido_expedicao"):
			w.hurt("expedicao", String(w.get_meta("ferido_expedicao")))
			w.remove_meta("ferido_expedicao")
	# os achados
	var achado_mult := float(e.mult_achado) * (achado_explorar if e.explorar else 1.0)
	for a in r.get("achados", []):
		var ch := float(a.get("chance", 0.0))
		if String(a.tipo) in ["mapa", "pista", "catalogo"] and tem_batedor:
			ch *= 1.0 + bonus_batedor_pistas
		if String(a.tipo) == "robo":
			ch = 1.0 if cadeia >= 4 else 0.0
		elif String(a.tipo) != "robo":
			ch *= minf(achado_mult, 2.0) if String(a.tipo) in ["item", "pecas", "minerio"] else 1.0
		if randf() >= ch:
			continue
		var q: Array = a.get("qtd", [1, 1])
		var n := randi_range(int(q[0]), int(q[1]))
		if String(a.tipo) in ["item", "pecas", "minerio"]:
			n = maxi(roundi(float(n) * achado_mult * (kit_minerio_mult if e.kit and String(a.tipo) == "minerio" else 1.0)), 1)
		var txt := _entrega_achado(String(a.tipo), String(a.get("id", "")), n, saida, pesq)
		if txt != "":
			res.achados.append(txt)
	if e.explorar:
		revela(String(e.regiao))
	# o relatório
	var linhas: Array[String] = []
	for l in e.log:
		if String(l) != "":
			linhas.append(String(l))
	linhas.append("Acharam: " + (", ".join(PackedStringArray(res.achados)) if not res.achados.is_empty() else "nada que valesse a viagem") + ".")
	if not res.feridos.is_empty():
		linhas.append("Feridos: " + ", ".join(PackedStringArray(res.feridos.map(func(f): return "%s (%s)" % [f[0], f[1]]))) + ".")
	if not res.mortos.is_empty():
		linhas.append("Não voltaram: " + ", ".join(PackedStringArray(res.mortos)) + ".")
	res.texto = "\n".join(linhas)
	var dn := get_tree().get_first_node_in_group("day_night")
	relatorios.append({"regiao": String(e.regiao), "dia": int(dn.day) if dn else 1, "texto": res.texto})
	while relatorios.size() > 6:
		relatorios.pop_front()
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		var pid := "expedicao_%d" % int(e.n)
		diary.registra(pid, "Expedição: %s (dia %d)" % [nome(String(e.regiao)), int(dn.day) if dn else 1], res.texto)
		diary.unlock(pid, false)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_banner"):
		hud.show_banner("A EXPEDIÇÃO VOLTOU: %s" % nome(String(e.regiao)).to_upper(), res.texto)
	total_voltaram += 1
	voltou_de[String(e.regiao)] = true
	total_achados += res.achados.size()
	total_feridos += res.feridos.size() + res.mortos.size()
	expedicao_voltou.emit(String(e.regiao), res)
	mudou.emit()


func _seg_dia() -> float:
	var dn := get_tree().get_first_node_in_group("day_night")
	return float(dn.cycle_length()) if dn else 540.0


## Entrega um achado e devolve o texto dele ("" = nada).
func _entrega_achado(tipo: String, id: String, n: int, onde: Vector2, pesq: Node) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	match tipo:
		"item":
			if eco:
				eco.devolve(id, float(n), onde)
			return "%d %s" % [n, Items.plural(id) if n > 1 else Items.nome(id).to_lower()]
		"minerio":
			var arm := get_tree().get_first_node_in_group("armazens")
			if arm:
				arm.add_ore(float(n), id)
			return "%d de %s" % [n, preload("res://scripts/core/ores.gd").display_name(id).to_lower()]
		"pecas":
			var finds := get_tree().get_first_node_in_group("finds")
			if finds:
				finds.rare_parts += n
			return "%d peça%s rara%s" % [n, "s" if n > 1 else "", "s" if n > 1 else ""]
		"mapa":
			if revela(id, false):
				return "um mapa (%s)" % nome(id)
		"catalogo":
			var cat := get_tree().get_first_node_in_group("catalogo")
			if cat and not cat.estudado(id):
				cat.avista(id, false)
				if pesq != null and cat.estado(id) == cat.AVISTADO:
					cat.estuda(id, pesq)  # a pesquisadora da equipe estudou lá mesmo
					return "a ficha de %s (estudada)" % cat.nome(id)
				return "rastros de %s (Catálogo)" % (cat.nome(id) if cat.estudado(id) else "um bicho desconhecido")
		"pista":
			var diary := get_tree().get_first_node_in_group("diary")
			if diary and not diary.has_page("exp_pista." + id):
				diary.unlock("exp_pista." + id, false)
				return "uma pista: %s" % texto("pista." + id, "titulo")
		"sobreviventes":
			var mig := get_tree().get_first_node_in_group("migrantes")
			if mig and mig.has_method("chama_grupo"):
				mig.chama_grupo(n, "expedicao")
				return "%d sobrevivente%s (vêm pro portão)" % [n, "s" if n > 1 else ""]
		"robo":
			return _acha_robo(onde)
	return ""


## Bloco 104: a expedição achou o robô na fábrica: ele chega no portão desligado ("found"); o resto é o fluxo de sempre.
func _acha_robo(onde: Vector2) -> String:
	var finds := get_tree().get_first_node_in_group("finds")
	if finds == null or finds.robot_found:
		return ""
	finds.robot_found = true
	var r: Node2D = finds.ROBO_SCENE.instantiate()
	var hub := get_tree().get_first_node_in_group("village_hub")
	r.position = onde + Vector2(20, 6)
	hub.get_parent().add_child(r)
	cadeia = 5
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		diary.unlock("robo")
	return "O ROBÔ ANTIGO (desligado, ficou na saída: mande levar pra Oficina)"


# ------------------------------------------------------------ a cadeia do robô
func _estudou(id: String, _cat: String) -> void:
	if id == "ferrugento" and cadeia < 1:
		cadeia = 1
		_pagina("origem", "Pista: o Ferrugento tem número de série de uma fábrica (diário, J)")
	elif id in ESCUTAS and cadeia >= 2 and cadeia < 4:
		var cat := get_tree().get_first_node_in_group("catalogo")
		if cat and ESCUTAS.all(func(x): return cat.estudado(x)):
			cadeia = 4
			_pagina("triangulacao", "")
			_pagina("regiao", "")
			revela("fabrica", false)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_banner"):
				hud.show_banner("O SINAL FOI LOCALIZADO", texto("cadeia", "regiao"))
			robo_localizado.emit()
		elif cat:
			cadeia = 3
	mudou.emit()


## A cada segundo: o sinal (o rádio ou a antena, de noite) depois da origem.
func _confere_cadeia() -> void:
	if cadeia != 1:
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn == null or not dn.is_night():
		return
	if not tem_receptor():
		return
	cadeia = 2
	_pagina("sinal", "")
	var cat := get_tree().get_first_node_in_group("catalogo")
	if cat:
		for x in ESCUTAS:
			cat.avista(x, false)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_banner"):
		hud.show_banner("UM SINAL NO RÁDIO", texto("cadeia", "sinal"))
	mudou.emit()


## O rádio da vila ou a Antena improvisada da Oficina.
func tem_receptor() -> bool:
	var res := get_tree().get_first_node_in_group("research")
	var of := get_tree().get_first_node_in_group("oficina")
	return (res != null and res.has("radio")) or (of != null and of.has_tool("antena"))


func _pagina(k: String, aviso: String) -> void:
	var diary := get_tree().get_first_node_in_group("diary")
	if diary:
		diary.unlock("robo_" + k, aviso == "")
	if aviso != "":
		_aviso(aviso, Color(0.8, 0.85, 1.0))


## O ponto de cada escuta (o catálogo pergunta pra pesquisadora ir).
func ponto_escuta(alvo: String) -> Vector2:
	match alvo:
		"portao":
			var b := get_tree().get_first_node_in_group("barricadas")
			return (b as Node2D).global_position + (b.inside_dir() as Vector2) * 50.0 if b and b.has_method("inside_dir") else Vector2(-250, -40)
		"pedreira":
			return Vector2(1000, -40)
		"poco":
			var def := get_tree().get_first_node_in_group("defense")
			var p: Vector2 = def.boca_poco() if def and def.has_method("boca_poco") else Vector2.INF
			return p + Vector2(30, 30) if p != Vector2.INF else Vector2(700, 300)
	return Vector2.ZERO


func _aviso(t: String, cor: Color) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast(t, cor)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	var ec: Array = []
	for e in em_curso:
		var x := {}
		for k in e:
			if k != "membros":
				x[k] = e[k]
		x["saves"] = e.membros.filter(func(w): return is_instance_valid(w)).map(func(w): return w.get_save_data())
		ec.append(x)
	return {"reveladas": reveladas.keys(), "em_curso": ec, "cadeia": cadeia, "sorte_robo": sorte_robo,
		"relatorios": relatorios.duplicate(true), "n": _n, "voltou_de": voltou_de.keys(),
		"totais": [total_voltaram, total_achados, total_feridos]}


func load_save_data(d: Dictionary) -> void:
	for e in em_curso:
		for w in e.membros:
			if is_instance_valid(w) and w.get("fora"):
				w.queue_free()
	em_curso.clear()
	reveladas.clear()
	for id in SaveUtil.array(d, "reveladas"):
		if not regiao(String(id)).is_empty():
			reveladas[String(id)] = true
	for r in regioes():
		if String(r.aparece) == "inicio":
			reveladas[String(r.id)] = true
	cadeia = clampi(SaveUtil.integer(d, "cadeia", 0), 0, 5)
	sorte_robo = SaveUtil.boolean(d, "sorte_robo", false)
	relatorios = []
	for r in SaveUtil.array(d, "relatorios"):
		if r is Dictionary:
			relatorios.append(r)
	_n = SaveUtil.integer(d, "n", 0)
	voltou_de.clear()
	for id in SaveUtil.array(d, "voltou_de"):
		voltou_de[String(id)] = true
	var tot: Array = SaveUtil.array(d, "totais")
	total_voltaram = int(tot[0]) if tot.size() > 0 else 0
	total_achados = int(tot[1]) if tot.size() > 1 else 0
	total_feridos = int(tot[2]) if tot.size() > 2 else 0
	var eco := get_tree().get_first_node_in_group("economy")
	var hub := get_tree().get_first_node_in_group("village_hub")
	for x in SaveUtil.array(d, "em_curso"):
		if not (x is Dictionary) or regiao(SaveUtil.text(x, "regiao", "")).is_empty():
			continue
		var e: Dictionary = (x as Dictionary).duplicate(true)
		e.erase("saves")
		e.membros = []
		if eco and eco.worker_scene and hub:
			for wd in SaveUtil.array(x, "saves"):
				if not (wd is Dictionary):
					continue
				var w: Node2D = eco.worker_scene.instantiate()
				w.name = SaveUtil.text(wd, "name", "Ipezinho")
				w.position = ponto_saida(String(e.regiao))
				w.set("pending_save_data", wd)
				w.set("nasce_fora", true)  # (sai do mundo assim que entra na árvore)
				hub.get_parent().add_child(w)
				e.membros.append(w)
		e.fase = "fora"
		em_curso.append(e)
	mudou.emit()


## Depois de carregar tudo: save antigo (sem a chave) — a cadeia no passo certo, a sorte do robô como reserva.
func depois_de_carregar(tinha: bool) -> void:
	if tinha:
		return
	var finds := get_tree().get_first_node_in_group("finds")
	var cat := get_tree().get_first_node_in_group("catalogo")
	if finds and finds.robot_found:
		cadeia = 5
	elif cat and cat.estudado("ferrugento"):
		cadeia = 1
	sorte_robo = finds != null and not finds.robot_found  # (o achado por sorte continua só pra quem já jogava)
	var env := get_tree().get_first_node_in_group("environment")
	if env and bool(env.get("leste_aberto")):
		pass  # (as ruínas além do leste aparecem como "?": o batedor revela)
	mudou.emit()
