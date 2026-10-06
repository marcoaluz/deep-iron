extends Node
## Bloco 88: o CALENDÁRIO da vila (nó "Calendario" da cena principal, grupo "calendario") — o padre, a igreja e
## os eventos da semana e das estações.
##
## - PADRE: um só, não recrutável. Chega por evento quando a vila atinge padre_estagio (banner + diário). É um
##   ipezinho com a função "padre" (ninguém troca), que fica na igreja aconselhando (sem igreja: na praça).
## - IGREJA (igreja.gd): construída pelo jogador (canteiro "igreja"); é ponto social (os bancos).
## - MISSA de domingo (missa_inicio..missa_fim, 09:00–11:00): com padre e igreja, todos que não estão em
##   emergência vão (a agenda vira "missa"; o médico segue de plantão). Quem foi ganha o fator "foi à missa".
## - FUNERAL: quem morre (ipezinho._die) ganha um funeral na hora social seguinte (funeral_horas na igreja);
##   no fim o luto da vila (morale.grief) cai funeral_alivio. Sem padre ou sem igreja: só o luto de sempre.
## - ACONSELHAMENTO: quem fica na igreja (missa, funeral ou hora social) perde zanga
##   (aconselhamento_por_segundo; com o padre lá, x2).
## - DOMINGO À TARDE (tarde_inicio..fim do expediente): o jogador escolhe — FESTIVAL (a festa do morale.gd:
##   créditos + comida, grande ânimo, todos na PRAÇA), DIA LIVRE (passeiam: hora social) ou TRABALHAR (hora
##   extra: + zanga). Sem escolha até a tarde começar: dia livre. A janela abre sozinha ao meio-dia.
## - CALENDÁRIO: um festival com nome próprio por estação (o último domingo dela; o festival desse dia anima
##   mais). O HUD mostra o próximo evento (coluna da direita e a dica do relógio).

const WORKER_SCENE := preload("res://scenes/characters/Ipezinho.tscn")

@export_group("Padre")
## Estágio da vila em que o padre chega (2 = Vilarejo).
@export_range(1, 5) var padre_estagio: int = 2
## Nome dele.
@export var padre_nome: String = "Padre Bento"

@export_group("Missa (domingo)")
@export_range(0.0, 24.0, 0.25) var missa_inicio: float = 9.0
@export_range(0.0, 24.0, 0.25) var missa_fim: float = 11.0
## Ânimo de quem foi à missa (fator "foi à missa"), que some aos poucos (por segundo).
@export var missa_animo: float = 6.0
@export var missa_decai: float = 0.012
## Zanga a menos por segundo de quem está na igreja (o padre lá dobra).
@export var aconselhamento_por_segundo: float = 0.6

@export_group("Funeral")
## Horas de funeral na igreja, começando na hora social depois da morte.
@export var funeral_horas: float = 1.0
## Quanto o luto da vila cai com cada funeral.
@export var funeral_alivio: float = 12.0

@export_group("Domingo à tarde")
## A tarde do domingo começa (até o fim do expediente).
@export_range(0.0, 24.0, 0.25) var tarde_inicio: float = 13.0
## A janela da escolha abre sozinha a esta hora do domingo.
@export_range(0.0, 24.0, 0.25) var aviso_escolha: float = 12.0
## Trabalhar no domingo: zanga a mais de uma vez pra cada um (hora extra).
@export var domingo_trabalho_zanga: float = 20.0
## Festival do dia de festa da estação: o ânimo da festa x isto.
@export var festival_mult: float = 1.5

@export_group("Calendário")
## Nome do festival de cada estação (primavera, verão, outono, inverno).
@export var festivais: PackedStringArray = PackedStringArray(["Festa das Flores", "Festa do Sol", "Festa da Colheita", "Festa das Lanternas"])

var padre_chegou := false
## A escolha do domingo de hoje ("festival", "livre", "trabalhar"; "" = ainda não escolheu) e o dia dela.
var escolha := ""
var escolha_dia := -1
## Funerais esperando: [{nome, dia}].
var funerais: Array = []
## Último domingo em que a janela da escolha abriu sozinha.
var _avisou_dia := -1
var _forcado: Node = null
var _forcado_quadro := -1


func _ready() -> void:
	add_to_group("calendario")


func _dn() -> Node:
	return get_tree().get_first_node_in_group("day_night")


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func igreja() -> Node:
	return get_tree().get_first_node_in_group("igrejas")


func padre() -> Node:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.has_method("is_priest") and w.is_priest():
			return w
	return null


## Tem missa (padre + igreja)?
func missa_ativa() -> bool:
	return padre() != null and igreja() != null


# ------------------------------------------------------------ o dia
func _process(_delta: float) -> void:
	var dn := _dn()
	if dn == null:
		return
	# o padre chega quando a vila cresce
	var hub := get_tree().get_first_node_in_group("village_hub")
	if not padre_chegou and hub and int(hub.level) >= padre_estagio and not SaveManager.pending_load:
		chega_padre()
	# domingo: a janela da escolha abre sozinha
	if dn.e_domingo() and _avisou_dia != dn.day and dn.entre_horas(aviso_escolha, dn.hora_fim_expediente) and escolha_hoje() == "":
		_avisou_dia = dn.day
		var hud := _hud()
		if hud:
			hud.show_banner("DOMINGO À TARDE", "Escolha: %s, dia livre ou trabalhar (Calendário)." % nome_festival_hoje())
			if hud.has_method("open_panel"):
				hud.open_panel("calendario")
	# funeral que acabou: alivia o luto
	_confere_funerais(dn)
	if Engine.get_process_frames() % 30 == 0:
		_placa_igreja(dn)


## O padre chega (uma vez): um ipezinho com a função "padre", no Centro da Vila.
func chega_padre() -> Node:
	padre_chegou = true
	var hub: Node2D = get_tree().get_first_node_in_group("village_hub")
	var w: Node2D = WORKER_SCENE.instantiate()
	w.name = "Padre"
	w.set("display_name", padre_nome)
	w.set("gender", "menino")
	w.position = (hub.global_position if hub else Vector2.ZERO) + Vector2(randf_range(-30.0, 30.0), 60.0)
	(hub.get_parent() if hub else get_parent()).add_child(w)
	w.set_job("padre")
	var hud := _hud()
	if hud:
		var onde := "Ele fica na igreja." if igreja() != null else "Construa uma IGREJA (menu CONSTRUIR, aba Culto) pra ter missa e funerais."
		hud.show_banner("UM PADRE CHEGOU À VILA", "%s veio morar com a gente. Missa no domingo, funeral pra quem se for e um ouvido pra quem anda zangado. %s" % [padre_nome, onde])
	var diary := get_tree().get_first_node_in_group("diary")
	if diary and diary.has_method("unlock"):
		diary.unlock("padre")
	Audio.recruit()
	return w


## O período da agenda num domingo ("" = dia comum ou hora comum). Chamado pelo Schedule.
func periodo_domingo(h: float) -> String:
	var dn := _dn()
	if dn == null or not dn.e_domingo():
		return ""
	if missa_ativa() and _entre(h, missa_inicio, missa_fim):
		return "missa"
	if _entre(h, tarde_inicio, dn.hora_fim_expediente):
		return "trabalho" if escolha_hoje() == "trabalhar" else "social"
	return ""


## Hoje é domingo e a tarde é de festival? (todos na praça)
func festival_agora() -> bool:
	var dn := _dn()
	return dn != null and escolha_hoje() == "festival" and _entre(dn.hora(), tarde_inicio, dn.hora_fim_expediente)


## Funeral agora (na hora social do dia dele)?
func funeral_agora() -> bool:
	var dn := _dn()
	if dn == null or funerais.is_empty() or not missa_ativa():
		return false
	return int(funerais[0].dia) == dn.day and _entre(dn.hora(), dn.hora_anoitecer, dn.hora_anoitecer + funeral_horas)


## O ponto social pra onde todo mundo vai agora (missa/funeral: igreja; festival: praça). null = livre.
## Guardado por quadro (todo ipezinho na hora social pergunta).
func ponto_forcado() -> Node:
	var f := Engine.get_process_frames()
	if f != _forcado_quadro:
		_forcado_quadro = f
		_forcado = _calcula_ponto_forcado()
	return _forcado if _forcado != null and is_instance_valid(_forcado) else null


func _calcula_ponto_forcado() -> Node:
	var dn := _dn()
	if dn == null:
		return null
	var ig := igreja()
	if ig and (periodo_domingo(dn.hora()) == "missa" or funeral_agora()):
		return ig.ponto()
	if festival_agora():
		for s in get_tree().get_nodes_in_group("social_spots"):
			if s.tipo == "praca":
				return s
	return null


func _entre(h: float, a: float, b: float) -> bool:
	return fposmod(h - a, 24.0) < fposmod(b - a, 24.0)


# ------------------------------------------------------------ domingo à tarde
func escolha_hoje() -> String:
	var dn := _dn()
	return escolha if dn and dn.e_domingo() and escolha_dia == dn.day else ""


## "" se dá pra escolher agora; senão o motivo.
func motivo_escolha(op: String) -> String:
	var dn := _dn()
	if dn == null or not dn.e_domingo():
		return "só no domingo"
	if escolha_hoje() != "":
		return "já escolhido: %s" % NOMES_ESCOLHA.get(escolha_hoje(), escolha_hoje())
	if not _entre(dn.hora(), dn.hora_amanhecer, dn.hora_fim_expediente):
		return "a tarde já acabou"
	if op == "festival":
		var mor := get_tree().get_first_node_in_group("morale")
		return mor.festa_block_reason() if mor else "sem ânimo"
	return ""


const NOMES_ESCOLHA := {"festival": "Festival", "livre": "Dia livre", "trabalhar": "Trabalhar"}


## O jogador escolheu a tarde do domingo.
func escolher(op: String) -> bool:
	if op not in NOMES_ESCOLHA or motivo_escolha(op) != "":
		Audio.error()
		return false
	var dn := _dn()
	var hud := _hud()
	match op:
		"festival":
			var mor := get_tree().get_first_node_in_group("morale")
			var dia_de_festa := e_dia_de_festival(dn.day)
			if not mor.throw_festa(festival_mult if dia_de_festa else 1.0, nome_festival_hoje()):
				return false
		"livre":
			if hud:
				hud.show_toast("Domingo livre: a tarde é pra passear e conversar.", Color(0.7, 0.95, 1.0))
		"trabalhar":
			for w in get_tree().get_nodes_in_group("ipezinhos"):
				if not (w.has_method("is_priest") and w.is_priest()):
					w.anger = minf(w.anger + domingo_trabalho_zanga, 100.0)
			if hud:
				hud.show_toast("Domingo de trabalho: hora extra (todo mundo mais zangado).", Color(1.0, 0.6, 0.4))
	escolha = op
	escolha_dia = dn.day
	Audio.click()
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.wake_decision()
	return true


# ------------------------------------------------------------ festivais da estação
## O festival da estação de hoje (nome) e se hoje é o dia dele (o último domingo da estação).
func e_dia_de_festival(d: int) -> bool:
	var dn := _dn()
	var sun := get_tree().get_first_node_in_group("sun")
	if dn == null or sun == null or not dn.e_domingo(d):
		return false
	var dps: int = sun.days_per_season
	return (d - 1) % dps >= dps - 7


func nome_festival(d: int) -> String:
	var sun := get_tree().get_first_node_in_group("sun")
	var s: int = sun.season_index(d) if sun else 0
	return festivais[s] if s >= 0 and s < festivais.size() else "Festival"


func nome_festival_hoje() -> String:
	var dn := _dn()
	return nome_festival(dn.day) if dn and e_dia_de_festival(dn.day) else "Festival"


## Os próximos eventos a partir de agora: [{nome, dia, hora}], em ordem.
func proximos(n: int = 5) -> Array:
	var dn := _dn()
	if dn == null:
		return []
	var out: Array = []
	for f in funerais:
		out.append({"nome": "Funeral de %s" % f.nome, "dia": int(f.dia), "hora": dn.hora_anoitecer})
	for k in 21:
		var d: int = dn.day + k
		if dn.e_domingo(d):
			if missa_ativa():
				out.append({"nome": "Missa", "dia": d, "hora": missa_inicio})
			out.append({"nome": nome_festival(d) if e_dia_de_festival(d) else "Domingo à tarde", "dia": d, "hora": tarde_inicio})
	var agora: float = dn.day * 24.0 + dn.tempo_da_hora(dn.hora()) / dn.segundos_por_hora()
	out = out.filter(func(e): return e.dia * 24.0 + dn.tempo_da_hora(e.hora) / dn.segundos_por_hora() >= agora - 0.01)
	out.sort_custom(func(a, b): return a.dia * 100.0 + dn.tempo_da_hora(a.hora) < b.dia * 100.0 + dn.tempo_da_hora(b.hora))
	return out.slice(0, n)


## "Missa · dom 09:00" (hoje: "hoje 09:00").
func texto_evento(e: Dictionary) -> String:
	var dn := _dn()
	var quando: String = "hoje" if int(e.dia) == dn.day else dn.nome_dia(true, int(e.dia)).to_lower()
	return "%s · %s %s" % [e.nome, quando, dn.hora_texto(e.hora)]


func proximo_texto() -> String:
	var p := proximos(1)
	return texto_evento(p[0]) if not p.is_empty() else "nada marcado"


# ------------------------------------------------------------ funeral
## Alguém morreu (ipezinho._die): funeral na próxima hora social (com padre e igreja).
func on_morte(nome: String) -> void:
	var dn := _dn()
	if dn == null:
		return
	var h: float = dn.hora()
	var dia: int = dn.day if _entre(h, dn.hora_amanhecer, dn.hora_anoitecer) else dn.day + 1
	funerais.append({"nome": nome, "dia": dia})
	if missa_ativa():
		var hud := _hud()
		if hud:
			hud.show_toast("Funeral de %s hoje à noite na igreja (%s)." % [nome, dn.hora_texto(dn.hora_anoitecer)], Color(0.8, 0.8, 0.9))


## Funeral que passou da hora: alivia o luto (se teve padre e igreja) e sai da lista.
func _confere_funerais(dn: Node) -> void:
	while not funerais.is_empty():
		var f: Dictionary = funerais[0]
		var fim: float = dn.tempo_da_hora(dn.hora_anoitecer + funeral_horas)
		var passou: bool = dn.day > int(f.dia) or (dn.day == int(f.dia) and dn.time >= fim)
		if not passou:
			return
		funerais.pop_front()
		if missa_ativa():
			var mor := get_tree().get_first_node_in_group("morale")
			if mor:
				mor.grief = maxf(mor.grief - funeral_alivio, 0.0)
			var hud := _hud()
			if hud:
				hud.show_toast("A vila se despediu de %s. O luto pesa menos." % f.nome, Color(0.8, 0.85, 1.0))


func _placa_igreja(dn: Node) -> void:
	var ig := igreja()
	if ig == null:
		return
	var txt := ""
	if periodo_domingo(dn.hora()) == "missa":
		txt = "missa agora"
	elif funeral_agora():
		txt = "funeral de %s" % funerais[0].nome
	elif padre() == null:
		txt = "sem padre"
	ig.set_status(txt)


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	var ig := igreja()
	return {"padre_chegou": padre_chegou, "escolha": escolha, "escolha_dia": escolha_dia, "funerais": funerais.duplicate(true),
		"avisou_dia": _avisou_dia, "igreja": [ig.global_position.x, ig.global_position.y] if ig else []}


## Save antigo: sem padre (chega quando a vila tiver o estágio), sem igreja, sem funeral pendente.
func load_save_data(d: Dictionary) -> void:
	padre_chegou = bool(d.get("padre_chegou", false))
	escolha = String(d.get("escolha", ""))
	escolha_dia = int(d.get("escolha_dia", -1))
	_avisou_dia = int(d.get("avisou_dia", -1))
	funerais = []
	for f in d.get("funerais", []):
		if f is Dictionary and f.has("nome"):
			funerais.append({"nome": String(f.nome), "dia": int(f.get("dia", 0))})
	for old in get_tree().get_nodes_in_group("igrejas"):
		old.get_parent().remove_child(old)
		old.queue_free()
	var pos = d.get("igreja", [])
	if pos is Array and pos.size() == 2:
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub and hub.has_method("spawn_igreja"):
			hub.spawn_igreja(Vector2(float(pos[0]), float(pos[1])))
