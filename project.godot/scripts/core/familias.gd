extends Node
## Bloco 111: FAMÍLIAS E CRIANÇAS (nó "Familias" da cena principal, grupo "familias"). Os casais do Bloco 110 têm filhos; a
## vila cresce também por dentro (além dos migrantes do Bloco 101), sem micro: o jogador influencia pelo ambiente e pela
## política de Família (Políticas da Vila).
##   GRAVIDEZ: a cada amanhecer, um casal ESTÁVEL (junto há casal_estavel_dias) tem chance_dia de esperar um filho se a vila
##     tem cama livre pro bebê, comida (porções na cozinha por morador), ânimo médio acima do mínimo, o estágio mínimo, não
##     está em greve, o intervalo desde o último filho do casal e menos que max_filhos. Gestação de gestacao_dias com o
##     sinal sobre a cabeça; nos últimos trabalho_leve_dias ela trabalha leve (rende menos, não desce na mina funda).
##   PARTO: no fim, ela vai pra enfermaria (se tem) ou pra casa; com médico de plantão é mais rápido e ela não precisa de
##     resguardo. COMPLICAÇÃO no parto (morte_parto_chance; menor com médico): a mãe fica com o machucado GRAVE de sempre
##     — morre só se não chegar a um leito da enfermaria a tempo (ligada na validação do Marco).
##   FASES (dias de jogo, todos @export): BEBÊ até bebe_dias (fica em casa, na cama, só o ícone), CRIANÇA até crianca_ate
##     (anda, brinca na praça e no parque, vai à ESCOLA no horário de trabalho, come meia porção, dorme em casa), APRENDIZ
##     até adulto_aos (acompanha um adulto — o pai ou a mãe com função — e aprende a função dele), ADULTO (sem função; traço
##     de um dos pais + 1 sorteado; habilidade inicial herdada dos pais + o que aprendeu; o tom de pele de um dos pais).
##   SEGURANÇA: criança nunca é alvo de criatura (creature.gd), vai pra casa na invasão e pro abrigo na onda solar (as
##     regras do ipezinho), ocupa cama (conta no limite da vila) e entra na conta de comida do HUD (meia porção).
## Save: chave "familias" (contadores, o último filho de cada casal); o ipezinho guarda a fase, a idade, os pais, os filhos,
## a gravidez e o estudo.

signal nasceu(bebe: Node)
signal cresceu(w: Node, fase: String)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const FASES := ["bebe", "crianca", "aprendiz", "adulto"]
const NOME_FASE := {"bebe": "bebê", "crianca": "criança", "aprendiz": "aprendiz", "adulto": "adulto"}

@export_group("Tempos (dias de jogo; 1 dia = 9 min reais em 1x)")
## Dias de gestação.
@export var gestacao_dias: float = 7.0
## Bebê até este dia de idade; criança até crianca_ate; aprendiz até adulto_aos (aí vira adulto). O Marco pediu 1 a 2 anos
## (56 a 112 dias; 1 ano = 4 estações de 14 dias): 28 é o padrão rápido (~4 h reais em 1x).
@export var bebe_dias: float = 7.0
@export var crianca_ate: float = 21.0
@export var adulto_aos: float = 28.0

@export_group("Gravidez")
## Chance (0..1) por amanhecer de um casal que pode ter filho esperar um.
@export var chance_dia: float = 0.15
## Dias de casal até ser "estável" (antes disso, nada de filho).
@export var casal_estavel_dias: int = 3
## Dias mínimos entre dois filhos do mesmo casal e o máximo de filhos por casal.
@export var intervalo_filhos_dias: int = 14
@export var max_filhos: int = 3
## Ânimo médio da vila mínimo, estágio mínimo do Centro e porções de comida pronta por morador.
@export var animo_minimo: float = 55.0
@export var estagio_minimo: int = 2
@export var comida_porcoes_por_morador: float = 1.0
## Nos últimos dias da gestação ela trabalha leve: a produção dela x isto.
@export var trabalho_leve_dias: float = 2.0
@export var trabalho_leve_mult: float = 0.6

@export_group("Parto")
## Segundos de jogo do parto (com médico de plantão, x parto_medico_mult) e os dias de resguardo sem médico (em casa).
@export var parto_segundos: float = 45.0
@export var parto_medico_mult: float = 0.5
@export var resguardo_dias: float = 1.0
## Chance (0..1) de COMPLICAÇÃO no parto: a mãe sai com o machucado grave de sempre (morre se não chegar a um leito da
## enfermaria a tempo). O Marco ligou na validação do Bloco 111 (antes era 0).
@export var morte_parto_chance: float = 0.06
## Com médico no parto, a chance da complicação x isto.
@export var morte_parto_medico_mult: float = 0.25

@export_group("Crianças")
## A criança come esta fração da porção (e a fome dela cai nesta fração da de um adulto: a conta fecha igual).
@export var crianca_porcao: float = 0.5
## ESTUDO ganho por segundo de aula na escola (0..1).
@export var estudo_por_s: float = 0.002
## Ânimo de quem foi à escola (some devagar).
@export var animo_escola: float = 5.0
## Aprendiz: habilidade ganha por segundo acompanhando o mentor (x 1 + estudo x aprendiz_estudo_mult).
@export var aprendiz_ganho: float = 0.0008
@export var aprendiz_estudo_mult: float = 0.5
## Distância (px) em que o aprendiz fica do mentor.
@export var aprendiz_perto: float = 36.0
## Ao virar adulto: a habilidade herdada = esta fração da maior habilidade dos pais (por função) + o estudo x estudo_bonus.
@export var heranca_habilidade: float = 0.2
@export var estudo_bonus: float = 0.15

@export_group("Política de Família")
## Desestimular / Incentivar: multiplicam a chance; Incentivar paga um auxílio por nascimento (sem créditos, a chance volta
## ao neutro). O ânimo do Desestimular (os casais queriam filhos) fica nas Políticas (politicas.familia_desestimular_animo).
@export var desestimular_mult: float = 0.3
@export var incentivar_mult: float = 2.0
@export var incentivar_auxilio: int = 30
## Máximo de filhos por casal: o Incentivar soma isto e o Desestimular tira isto (nunca abaixo de 1). Assim as duas mudam
## o TAMANHO da vila, não só o ritmo (a simulação de 3 anos mostrou que só a chance quase não mudava o total).
@export var incentivar_filhos_extra: int = 1
@export var desestimular_filhos_menos: int = 1
## Ânimo do casal que espera um filho.
@export var animo_esperando: float = 5.0

## Contadores e o último filho de cada casal ("a|b" -> dia).
var nascimentos := 0
var viraram_adultos := 0
var ultimo_filho := {}
var filhos_do_casal := {}
var _t := 0.0


func _ready() -> void:
	add_to_group("familias")
	_liga.call_deferred()


func _liga() -> void:
	var dn := _dn()
	if dn:
		dn.day_started.connect(_amanheceu)


func _dn() -> Node:
	return get_tree().get_first_node_in_group("day_night")


func _seg_dia() -> float:
	var dn := _dn()
	return dn.cycle_length() if dn and dn.has_method("cycle_length") else 540.0


func _rel() -> Node:
	return get_tree().get_first_node_in_group("relacoes")


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


# ------------------------------------------------------------ política
func politica() -> String:
	var pol := get_tree().get_first_node_in_group("politicas")
	return pol.opcao("familia") if pol and pol.has_method("opcao") and "familia" in pol.POLITICAS else "neutro"


func mult_politica() -> float:
	match politica():
		"desestimular":
			return desestimular_mult
		"incentivar":
			var eco := get_tree().get_first_node_in_group("economy")
			return incentivar_mult if eco and int(eco.credits) >= incentivar_auxilio else 1.0
	return 1.0


## O máximo de filhos por casal com a política de agora.
func max_filhos_casal() -> int:
	match politica():
		"incentivar":
			return max_filhos + incentivar_filhos_extra
		"desestimular":
			return maxi(max_filhos - desestimular_filhos_menos, 1)
	return max_filhos


# ------------------------------------------------------------ gravidez
## Por que este casal NÃO pode esperar filho agora ("" = pode).
func motivo_sem_filho(a: Node, b: Node) -> String:
	var rel := _rel()
	var dn := _dn()
	if rel == null or dn == null:
		return "sem relações"
	var mae: Node = a if String(a.gender) == "menina" else b
	if mae.gravida() or mae.e_crianca():
		return "já espera um filho"
	var d: Dictionary = rel.par(a, b)
	if dn.day - int(d.get("desde", 0)) < casal_estavel_dias:
		return "casal novo"
	var k: String = rel.chave(a, b)
	if int(filhos_do_casal.get(k, 0)) >= max_filhos_casal():
		return "já tem %d filhos" % max_filhos_casal()
	if dn.day - int(ultimo_filho.get(k, -999)) < intervalo_filhos_dias:
		return "filho recente"
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and eco.free_beds() - gravidas() < 1:  # (a cama de quem já vai nascer está prometida)
		return "sem cama livre pro bebê"
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub and int(hub.level) < estagio_minimo:
		return "a vila ainda é pequena"
	var mor := get_tree().get_first_node_in_group("morale")
	if mor and (bool(mor.on_strike) or mor.average() < animo_minimo):
		return "a vila está desanimada"
	var sch := get_tree().get_first_node_in_group("schedule")
	var pop := get_tree().get_nodes_in_group("ipezinhos").size()
	if sch and sch.porcoes_em_estoque() < comida_porcoes_por_morador * pop:
		return "pouca comida"
	return ""


func _amanheceu(_d: int) -> void:
	var rel := _rel()
	if rel == null:
		return
	var vistos := {}
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		var p: Node = rel.parceiro_de(w)
		if p == null or vistos.has(w) or vistos.has(p):
			continue
		vistos[w] = true
		vistos[p] = true
		if motivo_sem_filho(w, p) == "" and randf() < chance_dia * mult_politica():
			engravida(w if String(w.gender) == "menina" else p, p if String(w.gender) == "menina" else w)


## Quantas esperam um filho agora (cada bebê a caminho já tem uma cama prometida).
func gravidas() -> int:
	var n := 0
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.gravida():
			n += 1
	return n


## Ela espera um filho dele.
func engravida(mae: Node, pai: Node) -> void:
	mae.gravidez_s = gestacao_dias * _seg_dia()
	mae.pai_bebe = String(pai.name)
	var hud := _hud()
	if hud:
		hud.show_toast("%s e %s esperam um filho." % [_nome(mae), _nome(pai)], Color(1.0, 0.8, 0.85), mae)


## Nos últimos dias: trabalho leve.
func trabalho_leve(w: Node) -> bool:
	return w.gravida() and float(w.gravidez_s) <= trabalho_leve_dias * _seg_dia()


func _nome(w: Node) -> String:
	return String(w.display_name) if w.get("display_name") != null and String(w.display_name) != "" else String(w.name)


# ------------------------------------------------------------ o tempo: gravidez, parto, crescer
func _process(delta: float) -> void:
	_t -= delta
	var dt := 0.0
	if _t <= 0.0:
		dt = 1.0 - _t
		_t = 1.0
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.gravida():
			w.gravidez_s = maxf(float(w.gravidez_s) - delta, 0.0)
		if dt > 0.0 and w.e_crianca():
			w.idade_s = float(w.idade_s) + dt
			_confere_fase(w)


## O parto acabou (o ipezinho chama, no lugar dele): nasce o bebê, em casa.
func parto(mae: Node, com_medico: bool) -> Node:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null:
		return null
	var pai := _acha(String(mae.pai_bebe))
	var bebe: Node = eco.novo_ipezinho("menino" if randf() < 0.5 else "menina")
	if bebe == null:
		return null
	bebe.fase = "bebe"
	bebe.idade_s = 0.0
	Audio.som("vida/bebe_nasce", mae.global_position)  # Bloco 115: o primeiro choro
	bebe.pais = [String(mae.name)] + ([String(pai.name)] if pai else [])
	bebe.set_job("ocioso")
	bebe.tracos = []  # (o traço vem na vida adulta: um dos pais + um sorteado)
	if bebe.has_method("herda_tom"):
		bebe.herda_tom(mae if randf() < 0.5 or pai == null else pai)
	for p in [mae, pai]:
		if p != null:
			p.filhos.append(String(bebe.name))
	if mae.has_home():
		bebe.muda_pra_casa(mae._home, mae._home_slot)  # a cama livre mais perto da mãe (Bloco 110)
	if not bebe.has_home():
		bebe._claim_home()
	bebe.global_position = bebe._rest_position()
	mae.gravidez_s = -1.0
	mae.pai_bebe = ""
	if not com_medico:
		mae.resguardo_s = resguardo_dias * _seg_dia()
	nascimentos += 1
	var rel := _rel()
	if rel and pai:
		var k: String = rel.chave(mae, pai)
		ultimo_filho[k] = _dn().day if _dn() else 1
		filhos_do_casal[k] = int(filhos_do_casal.get(k, 0)) + 1
	if politica() == "incentivar" and eco and int(eco.credits) >= incentivar_auxilio:
		eco.spend(incentivar_auxilio, 0)  # o auxílio da política Incentivar
	var complicacao := morte_parto_chance > 0.0 and randf() < morte_parto_chance * (morte_parto_medico_mult if com_medico else 1.0)
	if complicacao:
		mae.resguardo_s = 0.0  # (vai direto pro leito da enfermaria, não pra casa)
		mae.hurt("parto", "grave")
	var hud := _hud()
	if hud and complicacao and hud.has_method("show_banner"):
		hud.show_banner("COMPLICAÇÃO NO PARTO", "%s teve %s, mas saiu mal do parto. Precisa de leito na enfermaria logo." % [_nome(mae), _nome(bebe)])
	if hud:
		hud.show_toast("Nasceu %s, filh%s de %s%s!" % [_nome(bebe), "o" if bebe.gender == "menino" else "a", _nome(mae),
			(" e " + _nome(pai)) if pai else ""], Color(1.0, 0.85, 0.9), bebe)
	if nascimentos == 1:
		_diario("fam_primeiro_bebe", "O primeiro bebê", "Nasceu %s, de %s. É o primeiro ipezinho nascido na colônia depois da explosão: a vila não é mais só de quem chegou, é de quem começa aqui." % [_nome(bebe), _nome(mae)])
	nasceu.emit(bebe)
	return bebe


func _confere_fase(w: Node) -> void:
	var dias := float(w.idade_s) / _seg_dia()
	var nova := "bebe"
	if dias >= adulto_aos:
		nova = "adulto"
	elif dias >= crianca_ate:
		nova = "aprendiz"
	elif dias >= bebe_dias:
		nova = "crianca"
	if nova == String(w.fase):
		return
	w.muda_fase(nova)
	if nova == "adulto":
		_vira_adulto(w)
	elif nova == "aprendiz":
		w.mentor = _escolhe_mentor(w)
	cresceu.emit(w, nova)


## O mentor do aprendiz: o pai ou a mãe com função; senão um adulto com função qualquer.
func _escolhe_mentor(w: Node) -> String:
	for n in w.pais:
		var p := _acha(String(n))
		if p and not p.has_no_job() and not p.e_crianca():
			return String(p.name)
	for o in get_tree().get_nodes_in_group("ipezinhos"):
		if not o.e_crianca() and not o.has_no_job() and not o.is_guard():
			return String(o.name)
	return ""


func _vira_adulto(w: Node) -> void:
	viraram_adultos += 1
	var rel := _rel()
	var pais: Array = w.pais.map(func(n): return _acha(String(n))).filter(func(p): return p != null)
	# traços: um de um dos pais + um sorteado
	var t: Array = []
	if not pais.is_empty():
		var de: Node = pais[randi() % pais.size()]
		var dele: Array = de.tracos_de()
		if not dele.is_empty():
			t.append(dele[randi() % dele.size()])
	if rel:
		for _i in 8:
			var s: Array = rel.sorteia_tracos()
			var x: String = s[0]
			if t.is_empty() or (x != t[0] and not rel._opostos(x, t[0])):
				t.append(x)
				break
	w.tracos = t
	# habilidade: o que aprendeu + uma parte da dos pais + o estudo na função do mentor
	for p in pais:
		for f in p.habilidade:
			w.habilidade[f] = maxf(float(w.habilidade.get(f, 0.0)), float(p.habilidade[f]) * heranca_habilidade)
	var mentor := _acha(String(w.mentor))
	if mentor:
		var fm: String = String(mentor.job)
		w.habilidade[fm] = minf(float(w.habilidade.get(fm, 0.0)) + float(w.estudo) * estudo_bonus, 1.0)
	w.mentor = ""
	var hud := _hud()
	if hud:
		hud.show_toast("%s cresceu: agora é adulto e espera uma função." % _nome(w), Color(0.8, 0.95, 0.7), w)
	if viraram_adultos == 1:
		_diario("fam_primeiro_adulto", "Nascido aqui, adulto aqui", "%s, que nasceu na colônia, virou adulto. Os pais contam que aprendeu o ofício olhando; a escola, que aprendeu a ler o céu." % _nome(w))


func _acha(nome: String) -> Node:
	if nome == "":
		return null
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if String(w.name) == nome:
			return w
	return null


# ------------------------------------------------------------ escola e aprendiz
## A escola chama: a criança numa vaga estuda.
func estuda(w: Node, delta: float) -> void:
	w.estudo = minf(float(w.estudo) + estudo_por_s * delta, 1.0)
	w.animo_escola = animo_escola


## O aprendiz perto do mentor: aprende a função dele.
func aprende(w: Node, mentor: Node, delta: float) -> void:
	var f: String = String(mentor.funcao_atual()) if mentor.has_method("funcao_atual") else String(mentor.job)
	if f == "" or f == "ocioso":
		return
	var ganho := aprendiz_ganho * (1.0 + float(w.estudo) * aprendiz_estudo_mult) * delta
	w.habilidade[f] = minf(float(w.habilidade.get(f, 0.0)) + ganho, 1.0)


func mentor_de(w: Node) -> Node:
	return _acha(String(w.mentor))


# ------------------------------------------------------------ ânimo
## O que a família dá no ânimo (a política Desestimular pesa pelas Políticas da Vila: o ponto único do ânimo delas).
func fatores_animo(w: Node) -> Array:
	var f: Array = []
	var p: Node = _rel().parceiro_de(w) if _rel() else null
	if w.gravida() or (p != null and p.gravida()):
		f.append(["vai ter um filho", animo_esperando])
	return f


# ------------------------------------------------------------ diário, telemetria
func _diario(id: String, titulo: String, texto: String) -> void:
	var rel := _rel()
	if rel and rel.has_method("_marco"):
		rel._marco(id, titulo, texto)  # (os marcos do diário vão no save das relações)


func contagem() -> Dictionary:
	var c := {"bebes": 0, "criancas": 0, "aprendizes": 0, "gravidas": 0}
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		match String(w.fase):
			"bebe":
				c.bebes += 1
			"crianca":
				c.criancas += 1
			"aprendiz":
				c.aprendizes += 1
		if w.gravida():
			c.gravidas += 1
	c["nascimentos"] = nascimentos
	return c


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	return {"nascimentos": nascimentos, "viraram_adultos": viraram_adultos, "ultimo_filho": ultimo_filho.duplicate(),
		"filhos_do_casal": filhos_do_casal.duplicate()}


## Save antigo: ninguém nasceu ainda.
func load_save_data(d: Dictionary) -> void:
	nascimentos = maxi(SaveUtil.integer(d, "nascimentos", 0), 0)
	viraram_adultos = maxi(SaveUtil.integer(d, "viraram_adultos", 0), 0)
	ultimo_filho = SaveUtil.dict(d, "ultimo_filho").duplicate()
	filhos_do_casal = SaveUtil.dict(d, "filhos_do_casal").duplicate()
