extends Node
## Bloco 123: os EVENTOS COM ESCOLHA (nó "Eventos", grupos "eventos" e "modificadores"; Prompt 11, seção 21 do guia, estilo Frostpunk).
## De vez em quando a vila recebe um CARTÃO com uma das ilustrações do jogo e 2 ou 3 opções; cada opção tem custo (créditos, comida, madeira) e
## consequência (gente que chega ou se machuca, produção que cai, ânimo que sobe ou desce, dinheiro, uma região no mapa...). Os eventos moram em
## res://data/eventos/eventos.json (texto, ilustração, opções e efeitos); aqui ficam a condição de cada um (`_pode`), o sorteio (peso nos @export,
## sem repetir o mesmo evento em sequência, cooldown por evento) e a aplicação dos efeitos.
##   refugiados · tempestade de poeira · desabamento numa galeria · febre na vila · casamento · mapa antigo
## Efeitos que duram (produção/acidente, ânimo) valem por dias de jogo. O nó responde `mult(chave, quem)` (grupo "modificadores": a produção e o acidente)
## e `fatores_animo()` (o moral.gd soma). Nada acontece sozinho com a vila: o jogador sempre escolhe. Save: chave "eventos".

signal evento_aberto(id: String)
signal evento_resolvido(id: String, opcao: int)

const DATA := "res://data/eventos/eventos.json"
const Cartao := preload("res://scripts/ui/evento_cartao.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")

@export_group("Frequência")
## Os eventos só começam a partir deste dia.
@export var primeiro_dia: int = 4
## Dias entre um cartão e o seguinte (sorteado entre os dois).
@export var intervalo_dias_min: int = 3
@export var intervalo_dias_max: int = 7
## Dias até o MESMO evento poder voltar (e ele nunca vem duas vezes em sequência).
@export var cooldown_dias: int = 8
## Peso de cada evento no sorteio (maior = mais comum).
@export var pesos: Dictionary = {"refugiados": 3.0, "tempestade_poeira": 2.0, "desabamento": 2.0, "febre": 2.0, "casamento": 2.0, "mapa_antigo": 1.5}
## Desliga os eventos (o Criativo, os testes).
@export var ligado: bool = true
## O cartão pausa o jogo enquanto não for decidido.
@export var pausa_no_cartao: bool = true

@export_group("Condições")
## O refugiado só vem se couber ao menos isto de gente nas camas.
@export var refugiados_camas_min: int = 2
## O desabamento pede ao menos tantos mineradores.
@export var desabamento_mineradores_min: int = 3
## A febre pede uma vila deste tamanho.
@export var febre_populacao_min: int = 8
## O mapa antigo pede a vila neste estágio.
@export var mapa_estagio_min: int = 2

static var _dados: Array = []

## [{dia, id, opcao, titulo, resultado}] do mais antigo ao mais novo.
var historico: Array = []
var proximo_dia := -1
var ultimo_id := ""
var ultimo_dia := {}  # evento -> o dia em que veio
## O evento em aberto: {id, a, b (o casal), dia}. {} = nenhum.
var ativo := {}
var _efeitos: Array = []  # [{t: "mult"/"animo", chave, v, texto, ate_dia}]
var _cartao: CanvasLayer


func _ready() -> void:
	add_to_group("eventos")
	add_to_group("modificadores")
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
			_dados = d.get("eventos", [])
	return _dados


static func evento(id: String) -> Dictionary:
	for e in catalogo():
		if String(e.id) == id:
			return e
	return {}


func _dia() -> int:
	var dn := get_tree().get_first_node_in_group("day_night")
	return int(dn.day) if dn else 1


# ------------------------------------------------------------ o sorteio
func _novo_dia(dia: int) -> void:
	_efeitos = _efeitos.filter(func(e): return int(e.ate_dia) > dia)
	if not ligado or not ativo.is_empty():
		return
	if proximo_dia < 0:
		proximo_dia = maxi(primeiro_dia, dia) + randi_range(intervalo_dias_min, maxi(intervalo_dias_min, intervalo_dias_max))
		return
	if dia >= proximo_dia:
		sorteia()


## Sorteia um evento que faz sentido agora (e dispara). "" = nenhum (tenta de novo amanhã).
func sorteia() -> String:
	if _ocupado():
		return ""
	var dia := _dia()
	var cand: Array = []
	var total := 0.0
	for e in catalogo():
		var id := String(e.id)
		if id == ultimo_id or (ultimo_dia.has(id) and dia - int(ultimo_dia[id]) < cooldown_dias) or not _pode(id):
			continue
		var p := float(pesos.get(id, 1.0))
		if p <= 0.0:
			continue
		cand.append([id, p])
		total += p
	if cand.is_empty():
		proximo_dia = dia + 1
		return ""
	var r := randf() * total
	for c in cand:
		r -= float(c[1])
		if r <= 0.0:
			dispara(String(c[0]))
			return String(c[0])
	dispara(String(cand[0][0]))
	return String(cand[0][0])


## Tem coisa acontecendo que pede calma (invasão, onda solar, greve, vitória, outro cartão)?
func _ocupado() -> bool:
	if not ativo.is_empty() or get_tree().get_first_node_in_group("hud") == null:
		return true
	var def := get_tree().get_first_node_in_group("defense")
	if def and bool(def.get("invasion_active")):
		return true
	var sol := get_tree().get_first_node_in_group("sun")
	if sol and ((bool(sol.get("won")) and not bool(sol.get("infinito"))) or (sol.has_method("wave_active") and sol.wave_active())):  # (Bloco 126: no modo infinito eles continuam)
		return true
	var mor := get_tree().get_first_node_in_group("morale")
	return mor != null and bool(mor.get("on_strike"))


# ------------------------------------------------------------ as condições
func _pode(id: String) -> bool:
	var eco := get_tree().get_first_node_in_group("economy")
	var gente := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return not (w.has_method("e_crianca") and w.e_crianca()))
	match id:
		"refugiados":
			return eco != null and eco.free_beds() >= refugiados_camas_min
		"tempestade_poeira":
			return gente.size() >= 3
		"desabamento":
			return gente.filter(func(w): return String(w.get("job")) == "minerador").size() >= desabamento_mineradores_min
		"febre":
			return gente.size() >= febre_populacao_min
		"casamento":
			return not _casal().is_empty()
		"mapa_antigo":
			var hub := get_tree().get_first_node_in_group("village_hub")
			return hub != null and int(hub.level) >= mapa_estagio_min and _regiao_escondida() != ""
	return false


## O casal que pede casamento: [a, b] (os dois vivos, em casal e ainda sem casar, com igreja e padre na vila), ou [].
func _casal() -> Array:
	var rel := get_tree().get_first_node_in_group("relacoes")
	var cal := get_tree().get_first_node_in_group("calendario")
	if rel == null or cal == null or cal.igreja() == null or cal.padre() == null:
		return []
	for k in rel.pares:
		var d: Dictionary = rel.pares[k]
		if not bool(d.get("casal", false)) or bool(d.get("casado", false)):
			continue
		var partes: PackedStringArray = String(k).split("|")
		var a = rel._acha(partes[0])
		var b = rel._acha(partes[1])
		if a != null and b != null:
			return [a, b]
	return []


func _regiao_escondida() -> String:
	var ex := get_tree().get_first_node_in_group("expedicoes")
	if ex == null:
		return ""
	for r in ex.regioes():
		if String(ex.situacao(String(r.id))[0]) == "escondida":
			return String(r.id)
	return ""


# ------------------------------------------------------------ o cartão
## Abre o cartão de um evento (forca = ignora a condição e o "ocupado": o F3 e os testes).
func dispara(id: String, forca := false) -> bool:
	var e := evento(id)
	if e.is_empty() or not ativo.is_empty():
		return false
	if not forca and (not ligado or _ocupado() or not _pode(id)):
		return false
	var c := _casal() if id == "casamento" else []
	if id == "casamento" and c.is_empty():
		return false
	ativo = {"id": id, "dia": _dia(), "a": c[0] if not c.is_empty() else null, "b": c[1] if not c.is_empty() else null}
	_cartao = Cartao.new()
	get_tree().root.add_child(_cartao)
	_cartao.setup(self, e)
	if pausa_no_cartao:
		get_tree().paused = true
	_som("stinger", "estagio_novo")
	evento_aberto.emit(id)
	return true


## O texto do evento com os nomes (o casamento).
func texto_de(e: Dictionary) -> String:
	var t := String(e.texto)
	if ativo.get("a") != null and ativo.get("b") != null:
		t = t.replace("{a}", String(ativo.a.display_name)).replace("{b}", String(ativo.b.display_name))
	return t


## "" = a opção pode ser escolhida; senão por que não.
func motivo_opcao(id: String, i: int) -> String:
	var e := evento(id)
	if e.is_empty() or i < 0 or i >= (e.opcoes as Array).size():
		return "opção inexistente"
	return _falta(e.opcoes[i].get("custo", {}))


func _falta(custo: Dictionary) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	var partes: Array[String] = []
	var cr := float(custo.get("creditos", 0))
	var mad := float(custo.get("madeira", 0))
	if eco and (cr > 0.0 or mad > 0.0):
		var f: String = eco.missing_text(cr, 0.0, "", mad)
		if f != "":
			partes.append(f.trim_prefix("falta "))
	var com := float(custo.get("comida", 0))
	if com > 0.0 and _comida() < com:
		partes.append("%d comida" % ceili(com - _comida()))
	return ("falta " + " + ".join(partes)) if not partes.is_empty() else ""


func _comida() -> float:
	var mor := get_tree().get_first_node_in_group("morale")
	return mor.total_food() if mor else 0.0


func _tira_comida(q: float) -> void:
	var left := q
	for c in get_tree().get_nodes_in_group("comedouros"):
		var take := minf(left, c.food_stock)
		c.food_stock -= take
		c._update_visual()
		left -= take
		if left <= 0.0:
			break


## O jogador escolheu a opção `i`: paga, aplica as consequências, registra e fecha o cartão.
func escolhe(i: int) -> bool:
	if ativo.is_empty():
		return false
	var id := String(ativo.id)
	var e := evento(id)
	if motivo_opcao(id, i) != "":
		_som("error")
		return false
	var op: Dictionary = e.opcoes[i]
	var custo: Dictionary = op.get("custo", {})
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and (float(custo.get("creditos", 0)) > 0.0 or float(custo.get("madeira", 0)) > 0.0):
		if not eco.spend(float(custo.get("creditos", 0)), 0.0, "", float(custo.get("madeira", 0))):
			return false
	if float(custo.get("comida", 0)) > 0.0:
		_tira_comida(float(custo.comida))
	for ef in op.get("efeitos", []):
		_aplica(ef)
	var dia := _dia()
	var resultado := String(op.get("resultado", ""))
	historico.append({"dia": dia, "id": id, "opcao": i, "titulo": String(e.titulo), "resultado": resultado, "escolha": String(op.texto)})
	if historico.size() > 40:
		historico.pop_front()
	ultimo_id = id
	ultimo_dia[id] = dia
	proximo_dia = dia + randi_range(intervalo_dias_min, maxi(intervalo_dias_min, intervalo_dias_max))
	_diario(historico.back())
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner(String(e.titulo).to_upper(), resultado, String(e.ilustracao))
	ativo = {}
	_fecha_cartao()
	evento_resolvido.emit(id, i)
	return true


func _fecha_cartao() -> void:
	if _cartao != null and is_instance_valid(_cartao):
		_cartao.queue_free()
	_cartao = null
	if pausa_no_cartao:
		get_tree().paused = false


func _diario(h: Dictionary) -> void:
	var diary := get_tree().get_first_node_in_group("diary")
	if diary == null:
		return
	var pid := "evento_%d_%s" % [int(h.dia), String(h.id)]
	diary.registra(pid, "Dia %d — %s" % [int(h.dia), String(h.titulo)], "%s Escolha: %s. %s" % [String(h.titulo), String(h.escolha), String(h.resultado)])
	diary.unlock(pid, false)


# ------------------------------------------------------------ os efeitos
func _aplica(ef: Dictionary) -> void:
	var dia := _dia()
	var gente := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return not (w.has_method("e_crianca") and w.e_crianca()) and not bool(w.get("visitante")))
	match String(ef.t):
		"creditos":
			var eco := get_tree().get_first_node_in_group("economy")
			if eco:
				if float(ef.v) >= 0.0:
					eco.ganha_creditos(float(ef.v))
				else:
					eco.spend(-float(ef.v), 0.0)
		"migrantes":
			var mig := get_tree().get_first_node_in_group("migrantes")
			if mig:
				for e in mig.chama_grupo(int(ef.n), "refugiados"):  # a decisão já foi do jogador: entram os que couberem
					mig.aceita(e.w)
		"mult", "animo_dias":
			var t := "mult" if String(ef.t) == "mult" else "animo"
			_efeitos.append({"t": t, "chave": String(ef.get("chave", "")), "v": float(ef.v), "texto": String(ef.get("texto", "")), "ate_dia": dia + int(ef.get("dias", 1))})
		"ferir":
			var mineiros := gente.filter(func(w): return not bool(w.get("injured")) and String(w.get("job")) == "minerador")
			if mineiros.is_empty():
				mineiros = gente.filter(func(w): return not bool(w.get("injured")))
			mineiros.shuffle()
			for k in mini(int(ef.n), mineiros.size()):
				mineiros[k].hurt(String(ef.get("causa", "mina")), String(ef.get("grau", "")))
		"doentes":
			var sadios := gente.filter(func(w): return not bool(w.get("injured")))
			sadios.shuffle()
			for k in mini(int(ef.n), sadios.size()):
				sadios[k].hurt("doenca", "leve")
		"casar":
			var rel := get_tree().get_first_node_in_group("relacoes")
			if rel and ativo.get("a") != null and ativo.get("b") != null and is_instance_valid(ativo.a) and is_instance_valid(ativo.b):
				rel.casa_os_dois(ativo.a, ativo.b)
		"regiao":
			var ex := get_tree().get_first_node_in_group("expedicoes")
			var r := _regiao_escondida()
			if ex and r != "":
				ex.revela(r)
		"pecas_raras":
			var fnd := get_tree().get_first_node_in_group("finds")
			if fnd:
				fnd.rare_parts = int(fnd.rare_parts) + int(ef.v)


## Resumo curto do que a opção faz (o cartão mostra embaixo do texto).
static func descreve_efeitos(op: Dictionary) -> String:
	var partes: Array[String] = []
	for ef in op.get("efeitos", []):
		match String(ef.t):
			"migrantes":
				partes.append("+%d gente (se couber)" % int(ef.n))
			"mult":
				var p := roundi((float(ef.v) - 1.0) * 100.0)
				partes.append("%s %+d%% por %d dia%s" % [{"producao": "produção", "acidente": "acidentes"}.get(String(ef.chave), String(ef.chave)), p, int(ef.get("dias", 1)), "s" if int(ef.get("dias", 1)) > 1 else ""])
			"animo_dias":
				partes.append("ânimo %+d por %d dia%s" % [roundi(float(ef.v)), int(ef.get("dias", 1)), "s" if int(ef.get("dias", 1)) > 1 else ""])
			"ferir":
				partes.append("%d machucado%s%s" % [int(ef.n), "s" if int(ef.n) > 1 else "", " (grave)" if String(ef.get("grau", "")) == "grave" else ""])
			"doentes":
				partes.append("%d de cama" % int(ef.n))
			"casar":
				partes.append("o casal se casa")
			"regiao":
				partes.append("revela uma região")
			"creditos":
				partes.append("%+d cr" % int(ef.v))
	return ", ".join(partes) if not partes.is_empty() else "sem outra consequência"


static func custo_texto(custo: Dictionary) -> String:
	var p: Array[String] = []
	if int(custo.get("creditos", 0)) > 0:
		p.append("%d cr" % int(custo.creditos))
	if int(custo.get("comida", 0)) > 0:
		p.append("%d comida" % int(custo.comida))
	if int(custo.get("madeira", 0)) > 0:
		p.append("%d madeira" % int(custo.madeira))
	return ", ".join(p) if not p.is_empty() else "de graça"


# ------------------------------------------------------------ os modificadores (grupo "modificadores") e o ânimo
func mult(chave: String, _quem: Node = null) -> float:
	var m := 1.0
	for e in _efeitos:
		if String(e.t) == "mult" and String(e.chave) == chave:
			m *= float(e.v)
	return m


## [texto, valor] que o moral.gd soma no ânimo de todo mundo.
func fatores_animo() -> Array:
	var out: Array = []
	for e in _efeitos:
		if String(e.t) == "animo" and float(e.v) != 0.0:
			out.append([String(e.texto) if String(e.texto) != "" else "evento", float(e.v)])
	return out


## Quantos efeitos de prazo estão valendo (o teste).
func efeitos_ativos() -> int:
	return _efeitos.size()


# ------------------------------------------------------------ save/load
func get_save_data() -> Dictionary:
	return {"proximo_dia": proximo_dia, "ultimo_id": ultimo_id, "ultimo_dia": ultimo_dia.duplicate(), "historico": historico.duplicate(true), "efeitos": _efeitos.duplicate(true),
		"ligado": ligado}


func load_save_data(d: Dictionary) -> void:
	proximo_dia = SaveUtil.integer(d, "proximo_dia", -1)
	ultimo_id = SaveUtil.text(d, "ultimo_id", "")
	ligado = SaveUtil.boolean(d, "ligado", ligado)
	ultimo_dia = {}
	var ud := SaveUtil.dict(d, "ultimo_dia")
	for k in ud:
		if not evento(String(k)).is_empty():
			ultimo_dia[String(k)] = SaveUtil.integer(ud, String(k), 0)
	historico = []
	for h in SaveUtil.array(d, "historico"):
		if typeof(h) == TYPE_DICTIONARY and not evento(String(h.get("id", ""))).is_empty():
			historico.append({"dia": int(h.get("dia", 1)), "id": String(h.id), "opcao": int(h.get("opcao", 0)), "titulo": String(h.get("titulo", "")),
				"resultado": String(h.get("resultado", "")), "escolha": String(h.get("escolha", ""))})
	_efeitos = []
	for e in SaveUtil.array(d, "efeitos"):
		if typeof(e) == TYPE_DICTIONARY and String(e.get("t", "")) in ["mult", "animo"]:
			_efeitos.append({"t": String(e.t), "chave": String(e.get("chave", "")), "v": float(e.get("v", 1.0)), "texto": String(e.get("texto", "")), "ate_dia": int(e.get("ate_dia", 0))})
	ativo = {}
	_diarios_de_volta.call_deferred()


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
