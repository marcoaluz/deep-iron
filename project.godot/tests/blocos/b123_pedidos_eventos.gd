extends SceneTree
## Bloco 123: PEDIDOS DA VILA e EVENTOS COM ESCOLHA (Prompt 11, seção 21 do guia). RODAR SÓ COM APPDATA ISOLADO.
##   (A) os dados (6 eventos de 2 ou 3 opções com ilustração que existe; 7 pedidos) e os @export;
##   (B) os pedidos: o sorteio só pede o que faz sentido, limite de abertos, prazo, cada condição e cada recompensa;
##   (C) os eventos: o cartão (pausa, opções, custo), cada um dos 6 com as consequências, o que não dá pra pagar, sem repetir em sequência, frequência;
##   (D) a janela F7 e o F3; (E) o save.
const Pedidos := preload("res://scripts/core/pedidos.gd")
const Eventos := preload("res://scripts/core/eventos.gd")
const Icones := preload("res://scripts/ui/icones.gd")
var main: Node
var ped: Node
var evs: Node
var eco: Node
var fails := 0
var _extras: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _adultos() -> Array:
	return get_nodes_in_group("ipezinhos").filter(func(w): return not (w.has_method("e_crianca") and w.e_crianca()) and not bool(w.get("visitante")))


func _dia() -> int:
	return int(g("day_night").day)


func _roda() -> void:
	await _frames(5)
	ped = g("pedidos")
	evs = g("eventos")
	eco = g("economy")
	evs.ligado = false  # (o sorteio do dia não atrapalha: o teste dispara à mão)
	ped.ligado = false

	print("== (A) os dados")
	var ev: Array = Eventos.catalogo()
	check(ev.size() == 6, "6 eventos: refugiados, tempestade de poeira, desabamento, febre, casamento, mapa antigo (%d)" % ev.size())
	var ev_ok := true
	for e in ev:
		var n: int = (e.opcoes as Array).size()
		if n < 2 or n > 3 or Icones.ilustracao(String(e.ilustracao)) == null or String(e.texto) == "" or String(e.titulo) == "":
			ev_ok = false
		for o in e.opcoes:
			if not (o.has("custo") and String(o.get("resultado", "")) != "" and (o.efeitos as Array).size() > 0):
				ev_ok = false
	check(ev_ok, "cada evento tem 2 ou 3 opções (com custo, efeitos e resultado), texto e uma ilustração que existe")
	var ids := ev.map(func(e): return String(e.id))
	check("refugiados" in ids and "tempestade_poeira" in ids and "desabamento" in ids and "febre" in ids and "casamento" in ids and "mapa_antigo" in ids, "os 6 eventos do pedido estão lá")
	var da_vila: Array = Pedidos.catalogo().filter(func(t): return not bool(t.get("caravana", false)))  # (Bloco 125: a encomenda da caravana é um tipo à parte)
	check(da_vila.size() == 7, "7 pedidos: banco, sem fome, casaco, enterrar, 3 guardas, caminho de pedra e Festival das Lanternas (%d)" % da_vila.size())
	var peds_ok := true
	for t in Pedidos.catalogo():
		if String(t.titulo) == "" or String(t.texto) == "" or not t.has("recompensa") or int(t.dias) <= 0:
			peds_ok = false
	check(peds_ok, "cada pedido tem título, texto, prazo e recompensa")
	check(evs.pesos.size() == 6 and evs.intervalo_dias_min > 0 and evs.intervalo_dias_max >= evs.intervalo_dias_min and evs.cooldown_dias > 0, "frequência e peso nos @export do Eventos")
	check(ped.max_abertos > 0 and ped.intervalo_dias_min > 0 and ped.banco_raio > 0.0, "limite de abertos, intervalo e as metas nos @export dos Pedidos")

	var ws := _adultos()
	check(ws.size() >= 3, "a vila de teste tem gente (%d)" % ws.size())

	print("== (B) os pedidos")
	g("armazens").wood_stored = 800.0
	g("armazens").add_ore(200.0, "ferro")
	ped.adultos_minimo = 2
	check(not ped._pode("caminho_pedra") or g("caminhos") != null, "só pede caminho de pedra com a ferramenta dos caminhos")
	var p1: Dictionary = ped.abre("sem_fome", ws[0])
	check(not p1.is_empty() and ped.abertos.size() == 1 and String(p1.autor) == String(ws[0].display_name), "abrir um pedido: tem nome de quem pediu (%s)" % p1.autor)
	check(int(p1.prazo_dia) == _dia() + 10, "o pedido tem prazo (10 dias)")
	check(ped.texto_de(p1).contains(String(ws[0].display_name)) and ped.titulo_de(p1) == "Ninguém passando fome", "o texto leva o nome e o título vem do arquivo")
	# sem fome: dias seguidos
	ped.dias_sem_fome = 0
	check(ped.progresso(p1) == [0, 3], "sem fome: 0 de 3 dias")
	for i in 3:
		ped._fome_hoje = false
		ped._novo_dia(_dia() + 1 + i)
	check(ped.dias_sem_fome == 3, "3 dias seguidos sem fome braba")
	var antes_gratis: bool = ped.festival_gratis
	ped._process(2.0)
	check(ped.abertos.is_empty() and ped.historico.size() == 1 and String(ped.historico[0].estado) == "cumprido", "o pedido foi cumprido (e foi pro histórico)")
	check(ped.festival_gratis and not antes_gratis, "recompensa: o próximo festival de graça")
	var diary = g("diary")
	check(diary.has_page("pedido_%d" % int(p1.n)), "o pedido cumprido entrou no diário")
	# o festival de graça: sem pagar
	var morale = g("morale")
	var cr0: float = eco.credits
	check(morale.festa_block_reason() == "", "festival de graça: nem falta crédito nem comida")
	eco.credits = 0.0
	var feita: bool = morale.throw_festa(1.0, "")
	check(feita and is_equal_approx(eco.credits, 0.0) and not ped.festival_gratis, "o festival de graça saiu sem gastar nada e o pedido se consumiu")
	eco.credits = cr0
	# vencer
	var p2: Dictionary = ped.abre("sem_fome", ws[1])
	ped.dias_sem_fome = 0
	ped._novo_dia(int(p2.prazo_dia) + 1)
	check(ped.abertos.is_empty() and String(ped.historico.back().estado) == "vencido" and diary.has_page("pedido_%d" % int(p2.n)), "pedido que passa do prazo vence e fica no diário")
	# banco perto de casa
	var casa = ws[0]._home
	if casa != null:
		var pb: Dictionary = ped.abre("banco_perto", ws[0])
		check(ped.progresso(pb)[0] == 0, "banco perto de casa: ainda sem banco")
		var dm = g("decoracoes_mgr")
		eco.credits = 500.0
		var b = dm.colocar("banco", (casa as Node2D).global_position + Vector2(40, 10))
		check(b != null and ped.progresso(pb)[0] == 1, "com um banco a até %d px da casa o pedido está feito" % roundi(ped.banco_raio))
		ped._process(2.0)
		check(ped.abertos.is_empty() and String(ped.historico.back().estado) == "cumprido", "banco perto de casa cumprido")
		var f1: Array = ped.fatores_animo_de(ws[0])
		var f2: Array = ped.fatores_animo_de(ws[1])
		check(f1.size() == 1 and float(f1[0][1]) > 0.0 and f2.is_empty(), "recompensa: ânimo só pra quem pediu (%s)" % str(f1))
		dm.remover(b)
	else:
		print("    (sem casa de ipezinho na partida de teste: o banco fica fora)")
	# casaco
	ped.abertos.clear()
	var sol = g("sun")
	var dia_antes: int = _dia()
	var pc: Dictionary = ped.abre("casaco_todos", ws[0])
	for w in ws:
		(w.wearing as Dictionary)["casaco"] = true
	check(ped.progresso(pc)[0] == 1, "casaco para todos: todos os adultos de casaco")
	ped._process(2.0)
	check(ped.inverno_ameno, "recompensa: inverno sem o -3")
	for w in ws:
		(w.wearing as Dictionary).erase("casaco")
	# guardas
	ped.abertos.clear()
	var pg: Dictionary = ped.abre("guardas_100", ws[0])
	for k in mini(3, ws.size()):
		ws[k].job = "guarda"
		ws[k].habilidade["guarda"] = 1.0
	check(ped.progresso(pg)[0] == 3 or ws.size() < 3, "3 guardas com 100% de treino")
	var def = g("defense")
	var bestas0: int = def.rack_count("besta")
	ped._process(2.0)
	check(def.rack_count("besta") == bestas0 + 1 and def.weapons.has("besta"), "recompensa: uma besta de graça no cavalete")
	for k in mini(3, ws.size()):
		ws[k].job = "ocioso"
	# caminho de pedra
	var cam = g("caminhos")
	ped.abertos.clear()
	var pp: Dictionary = ped.abre("caminho_pedra", ws[0])
	for k in 25:
		cam.celulas[Vector2i(k, 500)] = "pedra"
	check(ped.progresso(pp)[0] == 25, "caminho de pedra: 25 trechos de pedra")
	ped._process(2.0)
	var f_job: Array = ped.fatores_animo_de(_miner(ws))
	check(not f_job.is_empty() and float(f_job[0][1]) > 0.0, "recompensa: ânimo dos mineradores (%s)" % str(f_job))
	for k in 25:
		cam.celulas.erase(Vector2i(k, 500))
	# festival das lanternas
	ped.abertos.clear()
	var pl: Dictionary = ped.abre("festival_lanternas", ws[0])
	var dm2 = g("decoracoes_mgr")
	var praca: Vector2 = ped._praca()
	eco.credits = 1000.0
	var lamps: Array = []
	for k in 5:
		lamps.append(dm2.colocar("lampiao", praca + Vector2(float(k) * 20.0 - 40.0, 30.0)))
	check(ped.progresso(pl)[0] == 5, "5 lampiões na praça")
	ped._process(2.0)
	check(ped.festival_dobro, "recompensa: o próximo festival rende o dobro")
	check(ped.consome_festival().mult == 2.0 and not ped.festival_dobro, "o festival dobrado se consome")
	for l in lamps:
		dm2.remover(l)
	# enterrar
	ped.abertos.clear()
	var pe: Dictionary = ped.abre("enterrar", ws[0])
	check(ped.progresso(pe)[0] == 0, "enterrar com dignidade: sem cemitério e sem os Ritos ainda")
	# sorteio: só o que faz sentido, com limite
	ped.abertos.clear()
	ped.max_abertos = 2
	ped.adultos_minimo = 2
	ped.sorteia()
	ped.sorteia()
	ped.sorteia()
	check(ped.abertos.size() <= 2, "no máximo %d pedidos abertos (%d)" % [ped.max_abertos, ped.abertos.size()])
	var tipos: Array = ped.abertos.map(func(p): return String(p.tipo))
	var autores: Array = ped.abertos.map(func(p): return String(p.autor))
	check(tipos.size() == (tipos.filter(func(t): return tipos.count(t) == 1)).size() and autores.size() == (autores.filter(func(a): return autores.count(a) == 1)).size(), "não repete o tipo nem o autor entre os abertos")
	var todos_fazem_sentido := true
	for p in ped.abertos:
		if not ped._pode(String(p.tipo), ped._acha(String(p.autor))):
			todos_fazem_sentido = false
	check(todos_fazem_sentido, "só abriu pedido que fazia sentido na hora")
	ped.abertos.clear()
	ped.ligado = false

	print("== (C) os eventos")
	eco.credits = 1000.0
	# --- tempestade de poeira
	var dia0 := _dia()
	check(evs.dispara("tempestade_poeira", true), "o evento abre o cartão")
	var cartao = g("evento_cartao")
	check(cartao != null and paused and cartao.botoes.size() == 3 and evs.ativo.id == "tempestade_poeira", "o cartão pausa o jogo e tem 3 opções")
	check(not evs.dispara("febre", true), "com um cartão aberto não abre outro")
	check(evs.motivo_opcao("tempestade_poeira", 1) == "" and cartao.botoes[1].disabled == false, "dá pra pagar a opção 2 (120 cr + 20 madeira): %s" % evs.motivo_opcao("tempestade_poeira", 1))
	var madeira_antes: float = g("armazens").wood_stored
	check(evs.escolhe(1), "escolher a opção 2")
	check(is_equal_approx(eco.credits, 880.0) and is_equal_approx(g("armazens").wood_stored, madeira_antes - 20.0), "pagou 120 créditos e 20 de madeira")
	await _frames(2)
	check(not paused, "o jogo voltou a andar")
	check(is_equal_approx(evs.mult("producao"), 0.8) and is_equal_approx(evs.mult("acidente"), 1.0), "consequência: produção x0,8 por 1 dia (o modificador do grupo)")
	var f_mod: float = preload("res://scripts/core/modificadores.gd").mult(self, "producao", ws[0])
	check(f_mod <= 0.8 + 0.001, "o Modificadores.mult enxerga o efeito (%.2f)" % f_mod)
	evs._novo_dia(dia0 + 2)
	check(is_equal_approx(evs.mult("producao"), 1.0), "um dia depois o efeito acabou")
	# a que não dá pra pagar
	eco.credits = 10.0
	evs.dispara("tempestade_poeira", true)
	check(evs.motivo_opcao("tempestade_poeira", 1) != "" and g("evento_cartao").botoes[1].disabled and not evs.escolhe(1), "sem dinheiro a opção fica desabilitada e não escolhe (%s)" % evs.motivo_opcao("tempestade_poeira", 1))
	check(evs.escolhe(0) and is_equal_approx(evs.mult("producao"), 0.4), "a opção de graça sempre dá: parar tudo (x0,4)")
	evs._novo_dia(dia0 + 5)
	eco.credits = 1000.0
	# --- desabamento
	var mineiros := 0
	for k in mini(3, ws.size()):
		ws[k].job = "minerador"
		mineiros += 1
	if mineiros >= 3:
		check(evs._pode("desabamento"), "o desabamento só vem com mineradores trabalhando")
		evs.dispara("desabamento", true)
		evs.escolhe(1)
		var feridos := ws.filter(func(w): return bool(w.injured)).size()
		check(feridos == 2, "resgate rápido: 2 machucados (%d)" % feridos)
		for w in ws:
			w.injured = false
		evs.dispara("desabamento", true)
		var cr1: float = eco.credits
		evs.escolhe(0)
		check(is_equal_approx(eco.credits, cr1 - 150.0) and ws.filter(func(w): return bool(w.injured)).size() == 1, "resgate com tudo: 150 cr e só 1 machucado")
		for w in ws:
			w.injured = false
		for k in 3:
			ws[k].job = "ocioso"
	else:
		print("    (menos de 3 adultos na partida de teste: o desabamento fica fora)")
	# --- febre
	ped.ligado = false
	if ws.size() >= 8:
		check(evs._pode("febre"), "a febre só vem numa vila de %d" % evs.febre_populacao_min)
	var pop0 := ws.size()
	evs.dispara("febre", true)
	evs.escolhe(1)
	check(ws.filter(func(w): return bool(w.injured)).size() == mini(2, pop0), "isolar os doentes: 2 de cama e produção x0,9")
	check(is_equal_approx(evs.mult("producao"), 0.9), "...e a produção cai 10%% (%.2f)" % evs.mult("producao"))
	for w in ws:
		w.injured = false
	evs._novo_dia(dia0 + 20)
	evs.dispara("febre", true)
	var cr2: float = eco.credits
	evs.escolhe(0)
	check(is_equal_approx(eco.credits, cr2 - 180.0) and ws.filter(func(w): return bool(w.injured)).is_empty(), "tratar todos: 180 cr e ninguém adoece")
	check(evs.fatores_animo().size() >= 1 and float(evs.fatores_animo()[0][1]) > 0.0, "e o ânimo sobe um pouco (fator no moral)")
	var fv: Array = morale.village_factors()
	check(fv.any(func(f): return String(f[0]) == "cuidaram de todos na febre"), "o moral.gd soma o fator do evento (village_factors)")
	evs._novo_dia(dia0 + 30)
	# --- refugiados
	var pop_antes := get_nodes_in_group("ipezinhos").size()
	var camas: int = eco.free_beds()
	print("    (camas livres: %d)" % camas)
	var comida0: float = morale.total_food()
	evs.dispara("refugiados", true)
	evs.escolhe(2)
	check(get_nodes_in_group("ipezinhos").size() == pop_antes and morale.village_factors().any(func(f): return float(f[1]) < 0.0 and String(f[0]).contains("portão")), "fechar o portão: ninguém entra e o ânimo cai")
	evs._novo_dia(dia0 + 40)
	if camas >= 2 and comida0 >= 10.0:
		evs.dispara("refugiados", true)
		evs.escolhe(1)
		check(get_nodes_in_group("ipezinhos").size() == pop_antes + mini(2, camas) and morale.total_food() <= comida0 - 10.0 + 0.5, "abrigar só uma família: entram 2 (os que couberem) e custa 10 de comida")
	else:
		print("    (sem camas ou comida suficiente na partida de teste: a entrada fica fora)")
	# --- casamento
	var a: Node = ws[0]
	var b: Node = ws[1]
	var rel = g("relacoes")
	var chave: String = rel.chave(a, b)
	rel.pares[chave] = {"casal": true, "casado": false, "desde": 1, "pontos": 100.0}
	var igreja := Node2D.new()
	main.add_child(igreja)
	igreja.add_to_group("igrejas")
	_extras.append(igreja)
	var padre_antes: String = String(ws[2].job)
	ws[2].job = "padre"
	check(evs._pode("casamento") and evs._casal().size() == 2, "o casamento só vem com um casal, a igreja e o padre")
	evs.dispara("casamento", true)
	check(g("evento_cartao").botoes.size() == 3 and evs.texto_de(Eventos.evento("casamento")).contains(String(a.display_name)), "o cartão do casamento traz o nome do casal")
	cr2 = eco.credits
	evs.escolhe(1)
	check(bool(rel.pares[chave].casado), "cerimônia simples: o casal se casou")
	ws[2].job = padre_antes
	rel.pares.erase(chave)
	# --- mapa antigo
	var ex = g("expedicoes")
	var hub = g("village_hub")
	hub.level = 2
	var escondida: String = evs._regiao_escondida()
	if escondida != "":
		check(evs._pode("mapa_antigo"), "o mapa antigo só vem com uma região escondida e a vila no estágio 2")
		evs.dispara("mapa_antigo", true)
		cr2 = eco.credits
		evs.escolhe(0)
		check(ex.reveladas.has(escondida) and is_equal_approx(eco.credits, cr2 - 100.0), "marcar o lugar: revela a região (%s) e custa 100 cr" % escondida)
		evs._novo_dia(dia0 + 60)
		evs.dispara("mapa_antigo", true, )
		cr2 = eco.credits
		evs.escolhe(1)
		check(is_equal_approx(eco.credits, cr2 + 120.0), "vender o mapa: +120 cr")
	else:
		print("    (sem região escondida na partida de teste: o mapa antigo fica fora)")
	# --- sem repetir em sequência
	evs.ligado = true
	evs.ultimo_id = "febre"
	evs.ultimo_dia = {"febre": _dia()}
	var viu_febre := false
	var sorteios := 0
	for k in 40:
		if not evs.ativo.is_empty():
			evs.escolhe(0) if evs.motivo_opcao(String(evs.ativo.id), 0) == "" else evs.escolhe(2)
		evs.ultimo_id = "febre"
		var s: String = evs.sorteia()
		if s != "":
			sorteios += 1
			if s == "febre":
				viu_febre = true
			evs.ultimo_dia = {}
	check(sorteios > 0 and not viu_febre, "o mesmo evento não vem duas vezes em sequência (%d sorteios, a febre nunca depois da febre)" % sorteios)
	if not evs.ativo.is_empty():
		evs.escolhe(2) if evs.motivo_opcao(String(evs.ativo.id), 0) != "" else evs.escolhe(0)
	evs.ligado = false
	# frequência: o próximo sai entre min e max dias
	var dia_ref := _dia()
	evs.proximo_dia = -1
	evs.ativo = {}
	evs._novo_dia(dia_ref)
	check(evs.proximo_dia >= maxi(evs.primeiro_dia, dia_ref) + evs.intervalo_dias_min or not evs.ligado, "o próximo evento é marcado de %d a %d dias adiante" % [evs.intervalo_dias_min, evs.intervalo_dias_max])
	var dias_ok := true
	for k in 30:
		evs.proximo_dia = -1
		evs.ligado = true
		evs._novo_dia(dia_ref)
		var d: int = evs.proximo_dia - maxi(evs.primeiro_dia, dia_ref)
		if d < evs.intervalo_dias_min or d > evs.intervalo_dias_max:
			dias_ok = false
	evs.ligado = false
	check(dias_ok, "a frequência respeita o intervalo mínimo e máximo (30 sorteios)")
	evs.ultimo_id = ""
	evs.ultimo_dia = {}
	# ocupado: invasão e greve não recebem cartão
	evs.ligado = true
	def.invasion_active = true
	check(evs.sorteia() == "" and evs.ativo.is_empty(), "com invasão em andamento não abre cartão")
	def.invasion_active = false
	evs.ligado = false

	print("== (D) a janela F7 e o F3")
	var hud = g("hud")
	hud.open_panel("pedidos")
	await _frames(2)
	check(hud._panels.has("pedidos") and hud._panels.pedidos.visible, "a janela Pedidos abre (F7)")
	ped.ligado = true
	var pw: Dictionary = ped.abre("sem_fome", ws[0])
	hud._panels.pedidos.refresh()
	check(hud._panels.pedidos._lista.get_child_count() >= 1, "a janela lista o pedido aberto (com retrato e nome)")
	hud.close_panels()
	ped.abertos.clear()
	ped.ligado = false
	check(preload("res://scripts/core/teclas.gd").tecla("painel_pedidos") == KEY_F7, "tecla F7 = Pedidos da vila")
	var dbg := FileAccess.get_file_as_string("res://scripts/core/debug_panel.gd")
	check(dbg.contains("evento agora") and dbg.contains("pedido novo"), "o F3 tem 'evento agora' e 'pedido novo'")
	var main_tscn := FileAccess.get_file_as_string("res://scenes/game/main.tscn")
	check(main_tscn.contains("pedidos.gd") and main_tscn.contains("eventos.gd"), "os nós Pedidos e Eventos estão na cena principal")

	print("== (E) o save")
	ped.abertos.clear()
	ped.historico.clear()
	var ps: Dictionary = ped.abre("sem_fome", ws[0])
	ped.dias_sem_fome = 2
	ped.festival_dobro = true
	ped.inverno_ameno = true
	ped._efeitos = [{"alvo": "*", "v": 5.0, "texto": "teste", "ate_dia": _dia() + 5}]
	evs.historico = [{"dia": 3, "id": "febre", "opcao": 0, "titulo": "Febre na vila", "resultado": "r", "escolha": "e"}]
	evs.ultimo_id = "febre"
	evs.ultimo_dia = {"febre": 3}
	evs.proximo_dia = 77
	evs._efeitos = [{"t": "mult", "chave": "producao", "v": 0.5, "texto": "", "ate_dia": _dia() + 3}]
	var dp: Dictionary = ped.get_save_data()
	var de: Dictionary = evs.get_save_data()
	ped.abertos.clear()
	ped.festival_dobro = false
	ped.inverno_ameno = false
	ped._efeitos.clear()
	evs.historico.clear()
	evs._efeitos.clear()
	evs.ultimo_id = ""
	ped.load_save_data(dp)
	evs.load_save_data(de)
	check(ped.abertos.size() == 1 and String(ped.abertos[0].autor) == String(ws[0].display_name) and ped.dias_sem_fome == 2 and ped.festival_dobro and ped.inverno_ameno and ped._efeitos.size() == 1, "carregou: os pedidos, os dias sem fome, o festival e o efeito voltam")
	check(evs.historico.size() == 1 and evs.ultimo_id == "febre" and int(evs.ultimo_dia.febre) == 3 and evs.proximo_dia == 77 and is_equal_approx(evs.mult("producao"), 0.5), "carregou: os eventos (histórico, último, próximo e o efeito que dura)")
	ped.load_save_data({})
	evs.load_save_data({})
	check(ped.abertos.is_empty() and evs.proximo_dia == -1 and evs.historico.is_empty(), "save antigo (sem as chaves) carrega com padrão sensato")
	ped.load_save_data({"abertos": [{"tipo": "inexistente", "autor": "x"}, {"tipo": "sem_fome", "autor": ""}, 5], "efeitos": [3, {"alvo": ""}], "historico": ["a"]})
	evs.load_save_data({"historico": [{"id": "nada"}], "efeitos": [{"t": "outro"}], "ultimo_dia": {"zzz": 3}})
	check(ped.abertos.is_empty() and ped._efeitos.is_empty() and evs.historico.is_empty() and evs._efeitos.is_empty() and evs.ultimo_dia.is_empty(), "chaves ruins são ignoradas, sem erro")
	var sv := FileAccess.get_file_as_string("res://scripts/core/save_manager.gd")
	check(sv.contains('"pedidos": "pedidos"') and sv.contains('"eventos": "eventos"'), "o SaveManager guarda as duas chaves")

	for n in _extras:
		if is_instance_valid(n):
			n.queue_free()
	paused = false
	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


func _miner(ws: Array) -> Node:
	for w in ws:
		if String(w.job) == "minerador":
			return w
	var w0: Node = ws[0]
	w0.job = "minerador"
	return w0
