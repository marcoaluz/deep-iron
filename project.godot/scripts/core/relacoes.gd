extends Node
## Bloco 110: RELACIONAMENTOS, TRAÇOS e HABILIDADES (nó "Relacoes" da cena principal, grupo "relacoes"). Vida social e
## personalidade sem micro: o jogador NÃO escolhe casais nem amigos — ele influencia pelo ambiente (bancos, praças, festas,
## igreja, ânimo, caminhos).
##   TRAÇOS: cada ipezinho nasce com 1 ou 2 (TRACOS; sem os pares que se contradizem). Efeitos pequenos, todos em @export.
##     Eles também modulam a reação às Políticas da Vila (politicas._reacao chama reacao_politica).
##   HABILIDADE por função: sobe com a prática (segundos trabalhando nela) até 100%; rende até +habilidade_bonus.
##   RELAÇÕES (um par = uma entrada): os PONTOS vêm da convivência — conversa na hora social (x festa/festival, x missa),
##     trabalhar lado a lado — e a AFINIDADE dos traços multiplica. Níveis: conhecido -> amigo -> próximo -> interesse ->
##     casal. Interesse e casal só entre um homem e uma mulher adultos, os dois sem parceiro (um parceiro por vez).
##   Efeitos: amigos e o parceiro animam (na roda e perto); o casal passa a morar na mesma casa (se couber) e senta junto; a
##     morte de um amigo ou do parceiro pesa mais em quem ficou (luto pessoal).
##   CASAMENTO (opcional): num domingo, na missa, com igreja e padre, o casal que está junto há casamento_dias casa; a vila
##     ganha um pouco de ânimo e, se o jogador escolher o Festival nesse domingo, ele vira a festa do casamento.
## Save: chave "relacoes" (pares, marcos do diário, contadores); o ipezinho guarda os traços e as habilidades.

signal casal_formado(a: Node, b: Node)
signal casou(a: Node, b: Node)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const NIVEIS := ["", "conhecido", "amigo", "próximo", "interesse", "casal"]
const TRACOS := {
	"valente": {"nome": "Valente", "texto": "Não foge de criatura e o medo delas pesa menos."},
	"guloso": {"nome": "Guloso", "texto": "Sente fome mais depressa; ração reduzida o chateia mais."},
	"devoto": {"nome": "Devoto", "texto": "A missa anima mais; faz amigos na igreja."},
	"preguicoso": {"nome": "Preguiçoso", "texto": "Rende um pouco menos; odeia jornada estendida, adora a reduzida."},
	"trabalhador": {"nome": "Trabalhador", "texto": "Rende um pouco mais; a jornada estendida pesa menos nele."},
	"cuidadoso": {"nome": "Cuidadoso", "texto": "Se machuca menos no trabalho."},
	"sociavel": {"nome": "Sociável", "texto": "Faz amigos mais depressa e a conversa anima mais."},
	"reservado": {"nome": "Reservado", "texto": "Faz amigos devagar, mas gosta do sossego."},
}
## Pares que não vêm juntos na mesma pessoa.
const OPOSTOS := [["preguicoso", "trabalhador"], ["sociavel", "reservado"]]

@export_group("Traços (Bloco 110)")
## Chance (0..1) de nascer com um 2º traço.
@export var chance_segundo_traco: float = 0.5
## Valente: multiplica o "medo das criaturas na vila" (0,5 = metade).
@export var valente_medo: float = 0.5
## Guloso: multiplica a queda da fome.
@export var guloso_fome: float = 1.15
## Devoto: multiplica o ânimo da missa e os pontos de relação na igreja.
@export var devoto_missa: float = 1.5
## Preguiçoso / trabalhador / cuidadoso: multiplicam a produção / a produção / a chance de acidente de trabalho.
@export var preguicoso_producao: float = 0.92
@export var trabalhador_producao: float = 1.08
@export var cuidadoso_acidente: float = 0.7
## Sociável / reservado: multiplicam os pontos de relação e o ânimo da conversa.
@export var sociavel_pontos: float = 1.3
@export var reservado_pontos: float = 0.7
## Reservado: ânimo a mais por gostar do sossego.
@export var reservado_animo: float = 2.0
## Reação às Políticas da Vila (multiplica o efeito no ânimo): preguiçoso na jornada (estendida pesa mais, reduzida
## alegra mais), trabalhador na estendida, guloso na ração reduzida.
@export var reacao_forte: float = 1.5
@export var reacao_fraca: float = 0.5

@export_group("Habilidade por função (Bloco 110)")
## Habilidade (0..1) ganha por segundo trabalhando na função. Medido (bench_relacoes): com 0,0015 o melhor chegava a 100%
## no 3º dia; 0,0006 = 100% em ~7 dias de trabalho na mesma função.
@export var habilidade_ganho: float = 0.0006
## Na habilidade máxima, a produção daquela função rende isto a mais (0,15 = +15%).
@export var habilidade_bonus: float = 0.15

@export_group("Relações: pontos (Bloco 110)")
## Pontos por conversa na roda da hora social (a cada balão olhando pro outro). (Medido no Bloco 110: com 1,0 e os
## limiares 70/110/150, em 12 dias nenhum par passou de "amigo".)
@export var pontos_conversa: float = 1.5
## Multiplicam a conversa: com festa/festival rolando, e na igreja (missa, aconselhamento).
@export var mult_festa: float = 2.0
@export var mult_missa: float = 1.5
## Pontos por TRABALHAR LADO A LADO (a cada conferência, quem trabalha a até lado_a_lado px do outro).
@export var pontos_trabalho: float = 0.3
@export var lado_a_lado: float = 70.0
## Segundos entre as conferências do trabalho lado a lado.
@export var confere_trabalho: float = 5.0
## Afinidade: o mesmo traço nos dois multiplica por isto; traços opostos (OPOSTOS), por afinidade_oposta.
@export var afinidade_igual: float = 1.2
@export var afinidade_oposta: float = 0.7

@export_group("Relações: níveis (Bloco 110)")
## Pontos de cada nível: conhecido, amigo, próximo, interesse, casal.
@export var limiares: Array[float] = [5.0, 30.0, 60.0, 80.0, 100.0]
## A roda da hora social puxa quem tem gente querida nela (somado na nota do ponto social): o parceiro, quem está em
## "próximo"/"interesse" e os amigos. Assim quem gosta se junta e o par forte acelera sozinho (o jogador não escolhe).
@export var puxa_parceiro: float = 25.0
@export var puxa_proximo: float = 8.0
@export var puxa_amigo: float = 4.0

@export_group("Relações: efeitos (Bloco 110)")
## Ânimo por amigo (nível amigo ou mais), até amigos_max amigos.
@export var animo_por_amigo: float = 1.0
@export var amigos_max: int = 4
## A conversa com um amigo anima x isto.
@export var conversa_amigo_mult: float = 1.5
## Ânimo de ter um parceiro, e a mais quando estão perto (até perto_parceiro px).
@export var animo_casal: float = 3.0
@export var animo_juntos: float = 3.0
@export var perto_parceiro: float = 100.0
## Luto pessoal pela morte de um amigo / do parceiro (pontos no alvo) e segundos pra sumir.
@export var luto_amigo: float = 10.0
@export var luto_parceiro: float = 25.0
@export var luto_tempo: float = 900.0
## Quem perdeu o parceiro não começa outro namoro por estes dias.
@export var viuvez_dias: int = 7

@export_group("Casamento (Bloco 110)")
## Dias de casal até poderem casar (num domingo, na missa, com igreja e padre).
@export var casamento_dias: int = 3
## Ânimo da vila toda depois de um casamento e por quantos segundos.
@export var casamento_animo: float = 3.0
@export var casamento_tempo: float = 540.0
## Ânimo dos noivos (some devagar, como a festa).
@export var casamento_noivos: float = 8.0

## Os pares: "a|b" (nomes dos nós, em ordem) -> {p: pontos, casal: bool, casado: bool, desde: dia}.
var pares := {}
## Luto pessoal e viuvez: nome -> {luto: pontos, viuvo_ate: dia}.
var pessoal := {}
## Marcos do diário (as páginas que o código monta): [{id, title, text}].
var marcos: Array = []
var casamentos := 0
var casamento_left := 0.0
var _t_trab := 0.0
var _por_nome := {}
## Caches (o ânimo pergunta a cada quadro): nome -> nome do parceiro; nome -> quantos amigos (refeito a cada conferência).
var _parceiro := {}
var _amigos_n := {}


func _ready() -> void:
	add_to_group("relacoes")
	_liga.call_deferred()


func _liga() -> void:
	_registra_marcos()
	_refaz_caches()


func _process(delta: float) -> void:
	casamento_left = maxf(casamento_left - delta, 0.0)
	for k in pessoal:
		var e: Dictionary = pessoal[k]
		if float(e.get("luto", 0.0)) > 0.0:
			e.luto = maxf(float(e.luto) - maxf(luto_parceiro, luto_amigo) / maxf(luto_tempo, 1.0) * delta, 0.0)
	_t_trab -= delta
	if _t_trab <= 0.0:
		_t_trab = confere_trabalho
		_lado_a_lado()
		_confere_casamento()
		_refaz_caches()
		_casais_separados()


# ------------------------------------------------------------ traços
## Sorteia 1 ou 2 traços (sem opostos).
func sorteia_tracos() -> Array:
	var ids: Array = TRACOS.keys()
	var t: Array = [ids[randi() % ids.size()]]
	if randf() < chance_segundo_traco:
		for _i in 8:
			var o: String = ids[randi() % ids.size()]
			if o != t[0] and not _opostos(t[0], o):
				t.append(o)
				break
	return t


func _opostos(a: String, b: String) -> bool:
	for par in OPOSTOS:
		if (par[0] == a and par[1] == b) or (par[0] == b and par[1] == a):
			return true
	return false


func tem(w: Node, traco: String) -> bool:
	return w != null and w.has_method("tracos_de") and traco in w.tracos_de()


## Multiplicador de produção pelos traços.
func mult_producao(w: Node) -> float:
	var m := 1.0
	if tem(w, "preguicoso"):
		m *= preguicoso_producao
	if tem(w, "trabalhador"):
		m *= trabalhador_producao
	return m


func mult_acidente(w: Node) -> float:
	return cuidadoso_acidente if tem(w, "cuidadoso") else 1.0


func mult_fome(w: Node) -> float:
	return guloso_fome if tem(w, "guloso") else 1.0


## Bloco 108 + 110: a reação de uma pessoa ao efeito de uma política no ânimo (politicas._reacao chama).
func reacao_politica(w: Node, politica: String, opcao: String, valor: float) -> float:
	match politica:
		"jornada":
			if tem(w, "preguicoso"):
				return valor * reacao_forte  # (a estendida pesa mais; a reduzida alegra mais)
			if tem(w, "trabalhador") and opcao == "estendida":
				return valor * reacao_fraca
		"racao":
			if tem(w, "guloso"):
				return valor * reacao_forte
	return valor


# ------------------------------------------------------------ pares
static func chave(a: Node, b: Node) -> String:
	var x := String(a.name)
	var y := String(b.name)
	return (x + "|" + y) if x < y else (y + "|" + x)


func par(a: Node, b: Node) -> Dictionary:
	return pares.get(chave(a, b), {})


func pontos(a: Node, b: Node) -> float:
	return float(par(a, b).get("p", 0.0))


## O nível (0 nenhum .. 5 casal) do par.
func nivel(a: Node, b: Node) -> int:
	var d := par(a, b)
	if d.is_empty():
		return 0
	if bool(d.get("casal", false)):
		return 5
	var p := float(d.get("p", 0.0))
	var n := 0
	for i in 4:
		if p >= limiares[i]:
			n = i + 1
	if n == 4 and not pode_namorar(a, b):
		n = 3  # (interesse só entre quem pode namorar)
	return n


static func nome_nivel(n: int) -> String:
	return NIVEIS[clampi(n, 0, NIVEIS.size() - 1)]


## Adulto? (o Prompt F traz as crianças; hoje todo mundo é adulto)
func adulto(w: Node) -> bool:
	return not (w.has_method("e_crianca") and w.e_crianca())


## Podem namorar: um homem e uma mulher adultos, os dois sem parceiro e fora da viuvez.
func pode_namorar(a: Node, b: Node) -> bool:
	if a == b or not adulto(a) or not adulto(b):
		return false
	if String(a.get("gender")) == String(b.get("gender")):
		return false
	if parentes(a, b):
		return false
	var pa := parceiro_de(a)
	var pb := parceiro_de(b)
	if (pa != null and pa != b) or (pb != null and pb != a):
		return false
	return not _viuvo(a) and not _viuvo(b)


## Bloco 111: família não namora — pai/mãe e filho, ou irmãos (um pai ou mãe em comum).
static func parentes(a: Node, b: Node) -> bool:
	var pa: Array = a.get("pais") if a.get("pais") != null else []
	var pb: Array = b.get("pais") if b.get("pais") != null else []
	if String(a.name) in pb or String(b.name) in pa:
		return true
	for x in pa:
		if x in pb:
			return true
	return false


func _viuvo(w: Node) -> bool:
	var dn := get_tree().get_first_node_in_group("day_night")
	var dia: int = dn.day if dn else 1
	return int(pessoal.get(String(w.name), {}).get("viuvo_ate", -1)) > dia


## A afinidade dos traços (multiplica os pontos do par).
func afinidade(a: Node, b: Node) -> float:
	var m := 1.0
	var ta: Array = a.tracos_de() if a.has_method("tracos_de") else []
	var tb: Array = b.tracos_de() if b.has_method("tracos_de") else []
	for x in ta:
		if x in tb:
			m *= afinidade_igual
		for y in tb:
			if _opostos(x, y):
				m *= afinidade_oposta
	for w in [a, b]:
		if tem(w, "sociavel"):
			m *= sociavel_pontos
		if tem(w, "reservado"):
			m *= reservado_pontos
	return m


## Soma pontos ao par (a afinidade multiplica) e confere o nível (amizade nova, casal novo).
func soma(a: Node, b: Node, p: float) -> void:
	if a == null or b == null or a == b or not is_instance_valid(a) or not is_instance_valid(b):
		return
	var k := chave(a, b)
	var d: Dictionary = pares.get(k, {"p": 0.0, "casal": false, "casado": false, "desde": 0})
	var antes := nivel(a, b)
	d.p = float(d.p) + p * afinidade(a, b)
	pares[k] = d
	var depois := nivel(a, b)
	if depois > antes:
		_subiu(a, b, depois)
	if not bool(d.casal) and float(d.p) >= limiares[4] and pode_namorar(a, b):
		_forma_casal(a, b)


func _subiu(a: Node, b: Node, n: int) -> void:
	if n == 4:  # interesse: o coração aparece
		for w in [a, b]:
			if w.has_method("_mostra_balao"):
				w._mostra_balao("coracao")


## Conversa na roda (a hora social chama a cada balão olhando pro outro).
func conversou(a: Node, b: Node, na_igreja: bool) -> void:
	var m := pontos_conversa
	var mor := get_tree().get_first_node_in_group("morale")
	var cal := get_tree().get_first_node_in_group("calendario")
	if (mor and float(mor.festa_left) > 0.0) or (cal and cal.has_method("festival_agora") and cal.festival_agora()):
		m *= mult_festa
	if na_igreja:
		m *= mult_missa
		if tem(a, "devoto") or tem(b, "devoto"):
			m *= devoto_missa
	soma(a, b, m)
	if nivel(a, b) >= 4 and randf() < 0.35:
		a._mostra_balao("coracao")  # (o casal / o interesse: coração no lugar do assunto, às vezes)


const ESTADOS_TRABALHO := ["mining", "chopping", "foraging", "hunting", "building", "cooking", "fundindo", "serrando",
	"carvoejando", "curtindo", "manutencao", "operating", "operating_ore", "research", "training"]


## Quem trabalha a até lado_a_lado px do outro (em estado de trabalho) ganha pontos.
func _lado_a_lado() -> void:
	var ws: Array = get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return w.get_state() in ESTADOS_TRABALHO)
	for i in ws.size():
		for j in range(i + 1, ws.size()):
			if (ws[i] as Node2D).global_position.distance_to((ws[j] as Node2D).global_position) <= lado_a_lado:
				soma(ws[i], ws[j], pontos_trabalho)


# ------------------------------------------------------------ casal
## Refaz os caches do parceiro e dos amigos (a cada conferência e quando um casal se forma, alguém morre, carrega).
func _refaz_caches() -> void:
	_parceiro.clear()
	_amigos_n.clear()
	for k in pares:
		var d: Dictionary = pares[k]
		var partes: PackedStringArray = String(k).split("|")
		if bool(d.get("casal", false)):
			_parceiro[partes[0]] = partes[1]
			_parceiro[partes[1]] = partes[0]
		elif float(d.get("p", 0.0)) >= limiares[1]:
			for n in partes:
				_amigos_n[n] = int(_amigos_n.get(n, 0)) + 1


func parceiro_de(w: Node) -> Node:
	var outro := String(_parceiro.get(String(w.name), ""))
	return _acha(outro) if outro != "" else null


func casado(w: Node) -> bool:
	var p := parceiro_de(w)
	return p != null and bool(par(w, p).get("casado", false))


func _acha(nome: String) -> Node:
	var n = _por_nome.get(nome)
	if n != null and is_instance_valid(n) and String(n.name) == nome and n.is_in_group("ipezinhos"):
		return n
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if String(w.name) == nome:
			_por_nome[nome] = w
			return w
	return null


func _forma_casal(a: Node, b: Node) -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	var d: Dictionary = pares[chave(a, b)]
	d.casal = true
	d.desde = dn.day if dn else 1
	_refaz_caches()
	for w in [a, b]:
		w._mostra_balao("coracao")
	_mora_junto(a, b)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s e %s estão namorando." % [_nome(a), _nome(b)], Color(1.0, 0.7, 0.8), a)
	var n_casais := pares.values().filter(func(x): return bool(x.get("casal", false))).size()
	if n_casais == 1:
		_marco("rel_primeiro_casal", "O primeiro casal",
			"%s e %s começaram a namorar. Depois da explosão, ninguém achava que ia ter isso de novo por aqui: alguém pra dividir a cama, o prato e o medo." % [_nome(a), _nome(b)])
	casal_formado.emit(a, b)


func _nome(w: Node) -> String:
	return String(w.display_name) if w.get("display_name") != null and String(w.display_name) != "" else String(w.name)


## O casal passa a morar junto: um muda pra casa do outro, se tiver cama livre lá (a cama mais perto da do parceiro).
func _mora_junto(a: Node, b: Node) -> void:
	if not a.has_method("has_home") or not b.has_method("has_home"):
		return
	if a.has_home() and b.has_home() and a._home == b._home:
		return
	for par_ in [[a, b], [b, a]]:
		var quem: Node = par_[0]
		var dono: Node = par_[1]
		if dono.has_home() and dono._home.has_method("free_slot_count") and dono._home.free_slot_count() > 0:
			if quem.has_method("muda_pra_casa") and quem.muda_pra_casa(dono._home, dono._home_slot):
				return


## O casal que ainda mora separado (não tinha cama quando começou) tenta de novo (abriu cama, casa nova).
func _casais_separados() -> void:
	for nome in _parceiro:
		var a := _acha(String(nome))
		var b := _acha(String(_parceiro[nome]))
		if a and b and String(a.name) < String(b.name) and a.has_method("has_home") and not (a.has_home() and b.has_home() and a._home == b._home):
			_mora_junto(a, b)


## Domingo, missa, igreja e padre: o casal que está junto há casamento_dias casa.
func _confere_casamento() -> void:
	var cal := get_tree().get_first_node_in_group("calendario")
	var dn := get_tree().get_first_node_in_group("day_night")
	if cal == null or dn == null or not cal.has_method("periodo_domingo") or cal.periodo_domingo(dn.hora()) != "missa":
		return
	if cal.igreja() == null or cal.padre() == null:
		return
	for k in pares:
		var d: Dictionary = pares[k]
		if not bool(d.get("casal", false)) or bool(d.get("casado", false)) or dn.day - int(d.get("desde", 0)) < casamento_dias:
			continue
		var partes: PackedStringArray = String(k).split("|")
		var a := _acha(partes[0])
		var b := _acha(partes[1])
		if a == null or b == null:
			continue
		casa_os_dois(a, b)
		return  # (um casamento por missa)


func casa_os_dois(a: Node, b: Node) -> void:
	var d: Dictionary = pares.get(chave(a, b), {})
	if d.is_empty() or not bool(d.get("casal", false)) or bool(d.get("casado", false)):
		return
	d.casado = true
	casamentos += 1
	casamento_left = casamento_tempo
	Audio.som("vida/casamento", a.global_position)  # Bloco 115: sino e vivas
	for w in [a, b]:
		w._mostra_balao("coracao")
		if w.get("animo_casamento") != null:
			w.animo_casamento = casamento_noivos
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner("CASAMENTO", "%s e %s casaram na igreja. Se a tarde for de Festival, a festa é deles." % [_nome(a), _nome(b)])
	var dn := get_tree().get_first_node_in_group("day_night")
	_marco("rel_casamento_%d" % casamentos, "Casamento de %s e %s" % [_nome(a), _nome(b)],
		"No domingo do dia %d o padre casou %s e %s na igreja da vila. A colônia, que só contava mortos, contou um começo." % [
			dn.day if dn else 1, _nome(a), _nome(b)])
	casou.emit(a, b)


## O nome do festival de hoje, se tem casamento recente (o calendário pergunta).
func nome_festa_casamento() -> String:
	if casamento_left <= 0.0 or marcos.is_empty():
		return ""
	for i in range(marcos.size() - 1, -1, -1):
		if String(marcos[i].id).begins_with("rel_casamento_"):
			return "Festa do " + String(marcos[i].title).to_lower()
	return ""


# ------------------------------------------------------------ morte
## Alguém morreu: os amigos e o parceiro ficam de luto (pessoal) e o parceiro fica viúvo.
func morreu(w: Node) -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	for o in get_tree().get_nodes_in_group("ipezinhos"):
		if o == w:
			continue
		var n := nivel(w, o)
		var luto := luto_parceiro if n == 5 else (luto_amigo if n >= 2 else 0.0)
		if String(o.name) in (w.get("pais") if w.get("pais") != null else []) or String(w.name) in (o.get("pais") if o.get("pais") != null else []):
			luto = maxf(luto, luto_parceiro)  # Bloco 111: pai, mãe, filho
		if luto > 0.0:
			var e: Dictionary = pessoal.get(String(o.name), {})
			e["luto"] = float(e.get("luto", 0.0)) + luto
			if n == 5:
				e["viuvo_ate"] = (dn.day if dn else 1) + viuvez_dias
				if o.has_method("_mostra_balao"):
					o._mostra_balao("coracao_partido")
			pessoal[String(o.name)] = e
	for k in pares.keys():
		if String(w.name) in String(k).split("|"):
			pares.erase(k)
	_refaz_caches()


# ------------------------------------------------------------ ânimo (o que vai no alvo de cada um)
func fatores_animo(w: Node) -> Array:
	var f: Array = []
	var amigos := int(_amigos_n.get(String(w.name), 0))
	if amigos > 0:
		f.append(["tem amigos", animo_por_amigo * mini(amigos, amigos_max)])
	var p := parceiro_de(w)
	if p != null:
		f.append(["casado" if casado(w) else "namorando", animo_casal])
		if (p as Node2D).global_position.distance_to((w as Node2D).global_position) <= perto_parceiro:
			f.append(["perto de quem gosta", animo_juntos])
	var e: Dictionary = pessoal.get(String(w.name), {})
	if float(e.get("luto", 0.0)) >= 0.5:
		f.append(["luto por alguém querido", -float(e.luto)])
	if tem(w, "reservado"):
		f.append(["gosta do sossego", reservado_animo])
	if tem(w, "valente"):
		var def := get_tree().get_first_node_in_group("defense")
		if def and def.has_method("creatures_inside") and def.creatures_inside() > 0:
			f.append(["valente: o medo pesa menos", 10.0 * (1.0 - valente_medo)])  # (compensa parte do "medo das criaturas" da vila)
	if casamento_left > 0.0:
		f.append(["casamento na vila", casamento_animo])
	return f


## Quem é quem pra ele: [[ipezinho, nível], ...] do mais próximo pro menos (só de amigo pra cima).
func amigos_de(w: Node) -> Array:
	var out: Array = []
	for o in get_tree().get_nodes_in_group("ipezinhos"):
		if o != w and nivel(w, o) >= 2:
			out.append([o, nivel(w, o)])
	out.sort_custom(func(x, y): return int(x[1]) > int(y[1]))
	return out


# ------------------------------------------------------------ diário
func _marco(id: String, titulo: String, texto: String) -> void:
	marcos.append({"id": id, "title": titulo, "text": texto})
	var di := get_tree().get_first_node_in_group("diary")
	if di:
		di.registra(id, titulo, texto)
		di.unlock(id)


func _registra_marcos() -> void:
	var di := get_tree().get_first_node_in_group("diary")
	if di == null:
		return
	for m in marcos:
		di.registra(String(m.id), String(m.title), String(m.text))


# ------------------------------------------------------------ telemetria
func contagem() -> Dictionary:
	var amizades := 0
	var casais := 0
	for k in pares:
		var d: Dictionary = pares[k]
		if bool(d.get("casal", false)):
			casais += 1
		elif float(d.get("p", 0.0)) >= limiares[1]:
			amizades += 1
	return {"amizades": amizades, "casais": casais, "casamentos": casamentos}


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	return {"pares": pares.duplicate(true), "pessoal": pessoal.duplicate(true), "marcos": marcos.duplicate(true),
		"casamentos": casamentos, "casamento_left": casamento_left}


## Save antigo (sem a chave): ninguém se conhece ainda.
func load_save_data(d: Dictionary) -> void:
	pares = {}
	var ps := SaveUtil.dict(d, "pares")
	for k in ps:
		var v = ps[k]
		if typeof(v) == TYPE_DICTIONARY and String(k).contains("|"):
			pares[String(k)] = {"p": maxf(SaveUtil.num(v, "p", 0.0), 0.0), "casal": SaveUtil.boolean(v, "casal", false),
				"casado": SaveUtil.boolean(v, "casado", false), "desde": SaveUtil.integer(v, "desde", 0)}
	pessoal = SaveUtil.dict(d, "pessoal").duplicate(true)
	marcos = []
	for m in SaveUtil.array(d, "marcos"):
		if typeof(m) == TYPE_DICTIONARY and m.has("id"):
			marcos.append({"id": String(m.id), "title": String(m.get("title", "")), "text": String(m.get("text", ""))})
	casamentos = maxi(SaveUtil.integer(d, "casamentos", 0), 0)
	casamento_left = maxf(SaveUtil.num(d, "casamento_left", 0.0), 0.0)
	_por_nome.clear()
	_registra_marcos()
	_refaz_caches()
