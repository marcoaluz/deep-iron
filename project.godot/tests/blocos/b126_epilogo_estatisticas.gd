extends SceneTree
## Bloco 126: EPÍLOGO, ESTATÍSTICAS e MODO INFINITO (Prompt 15). RODAR SÓ COM APPDATA ISOLADO.
##   (A) o epílogo em arquivo editável, com ilustração que existe; (B) as estatísticas (quem passou, mortes e causas, invasões, minério, barras, festivais,
##   pedidos, caravana); (C) a tela de vitória: epílogo + estatísticas + as duas saídas; (D) o modo infinito (os eventos e as invasões seguem, sem vitória nova);
##   (E) a janela do Sol reabre a tela; (F) o save (e save antigo/quebrado).
var Victory: GDScript
var Estat: GDScript
var main: Node
var sol: Node
var est: Node
var eco: Node
var ms: Node
var fails := 0


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


func _textos(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	if n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_textos(c, out)


func _botao(n: Node, texto: String) -> Button:
	if n is Button and (n as Button).text == texto:
		return n
	for c in n.get_children():
		var r := _botao(c, texto)
		if r != null:
			return r
	return null


func _roda() -> void:
	await _frames(5)
	Victory = load("res://scripts/ui/victory.gd")  # (load, não preload: usa os autoloads)
	Estat = load("res://scripts/core/estatisticas.gd")
	sol = g("sun")
	est = g("estatisticas")
	eco = g("economy")
	ms = g("missoes")
	g("eventos").ligado = false
	g("pedidos").ligado = false
	check(est != null and sol != null and ms != null, "o nó Estatisticas existe")

	print("== (A) o epílogo")
	var ep: Dictionary = Victory.carrega_epilogo()
	check(not ep.is_empty() and String(ep.titulo) != "" and String(ep.subtitulo) != "", "data/epilogo/epilogo.txt tem título e subtítulo")
	var paragrafos: Array = ep.paragrafos
	check(paragrafos.size() >= 2 and String(paragrafos[0]).begins_with("Anos depois"), "o epílogo tem parágrafos (%d), o primeiro começa 'Anos depois'" % paragrafos.size())
	var total := 0
	for p in paragrafos:
		total += String(p).length()
	check(total > 100 and total < 1200, "é curto (%d letras)" % total)
	var Icones := load("res://scripts/ui/icones.gd")
	check(Icones.ilustracao(String(ep.imagem)) != null, "a ilustração '%s' existe (reaproveitada do jogo)" % String(ep.imagem))
	check(FileAccess.get_file_as_string("res://scripts/ui/victory.gd").find("EPILOGO") >= 0 and ms.epilogo() != "", "o texto de capitulo_6.txt continua como reserva")

	print("== (B) as estatísticas")
	await _frames(3)
	var vivos0: int = est.vivos()
	check(est.passaram >= vivos0 and vivos0 > 0, "quem está na vila já passou por ela (%d passaram, %d vivos)" % [est.passaram, vivos0])
	var p0: int = est.passaram
	var novo: Node = eco.novo_ipezinho("menina")
	await _frames(3)
	est._t = 0.0
	est._process(0.1)
	check(est.passaram == p0 + 1, "um ipezinho novo conta uma vez (%d -> %d)" % [p0, est.passaram])
	est._t = 0.0
	est._process(0.1)
	est._t = 0.0
	est._process(0.1)
	check(est.passaram == p0 + 1, "...e só uma (a varredura não conta duas vezes)")
	var m0: int = est.mortes_total()
	est.registra_morte("Fulano", "lumivoro")
	est.registra_morte("Beltrana", "radiacao")
	est.registra_morte("Cicrano", "expedicao: Floresta")
	est.registra_morte("Dona", "mina")
	est.registra_morte("Ninguém", "")
	check(est.mortes == 5 and est.mortes_total() >= m0 and est.causas.get("criaturas", 0) == 1 and est.causas.get("radiação", 0) == 1 and est.causas.get("expedições", 0) == 1
		and est.causas.get("acidentes na mina", 0) == 1 and est.causas.get("outras causas", 0) == 1, "as mortes contam, cada uma na sua causa")
	check(Estat.rotulo_causa("gosma") == "criaturas" and Estat.rotulo_causa("magmante") == "criaturas" and Estat.rotulo_causa("sombra") == "criaturas", "as criaturas novas entram em 'criaturas'")
	var def := g("defense")
	var inv0: int = est.invasoes
	def.invasion_ended.emit(3)
	check(est.invasoes == inv0 + 1, "uma invasão vencida (sinal da Defesa) conta")
	var ped := g("pedidos")
	var pc0: int = est.pedidos_cumpridos
	ped.pedido_cumprido.emit({"tipo": "sem_fome"})
	check(est.pedidos_cumpridos == pc0 + 1, "um pedido cumprido conta")
	var f0: int = est.festas
	var mor := g("morale")
	eco.credits = 99999.0
	for c in get_nodes_in_group("comedouros"):
		c.food_stock = c.food_capacity
	mor.last_festa_day = -99
	var deu: bool = mor.throw_festa(1.0, "Festival")
	check(deu and est.festas == f0 + 1, "um festival realizado conta (hook no morale.gd: %s)" % ("sim" if deu else "a festa não pôde ser dada neste teste"))
	var arm := g("armazens")
	var mn0: int = est.minerio_produzido()
	arm.add_ore(40.0, "ferro")
	check(est.minerio_produzido() >= mn0 + 40, "o minério que entra nos armazéns soma (%d)" % est.minerio_produzido())
	var forn := Node.new()  # (uma fornalha de mentira: só a `produzido` que o estatisticas.gd lê)
	var gs := GDScript.new()
	gs.source_code = "extends Node
var produzido := {}
"
	gs.reload()
	forn.set_script(gs)
	forn.add_to_group("fornalhas")
	root.add_child(forn)
	var b0: int = est.barras_produzidas()
	forn.produzido["barra_ferro"] = 7
	forn.produzido["aco"] = 2
	forn.produzido["prego"] = 50
	check(est.barras_produzidas() == b0 + 9, "as barras e o aço que as fornalhas fizeram somam, sem contar prego (%d)" % est.barras_produzidas())
	forn.remove_from_group("fornalhas")  # (o resto do jogo não pode ver a de mentira)
	forn.queue_free()
	var lin: Array = est.linhas()
	var txt := "\n".join(lin.map(func(l): return String(l)))
	var quer := ["Dias de vila", "Ipezinhos que passaram", "Mortes na vila", "Mortes por causa", "Invasões vencidas", "Minério", "Barras", "Festivais", "Pedidos"]
	var falta: Array = quer.filter(func(q): return txt.find(q) < 0)
	check(falta.is_empty(), "as linhas cobrem tudo o que o pedido listou (faltou: %s)" % str(falta))
	var vazias: int = lin.filter(func(l): return String(l) == "").size()
	check(vazias == 0 and lin.size() >= 9, "%d linhas, nenhuma vazia" % lin.size())
	var car := g("caravana")
	car.visitas = 2
	car.vendido_cr = 500.0
	check("\n".join(est.linhas().map(func(l): return String(l))).find("Caravana: 2 visitas") >= 0, "a caravana aparece quando já veio")
	car.visitas = 0
	car.vendido_cr = 0.0

	print("== (C) a tela de vitória")
	check(not sol.won and not sol.infinito, "antes da vitória: sem vitória e sem modo infinito")
	sol.win()
	await _frames(3)
	var tela = g("victory_screen")
	check(tela != null and sol.won and paused, "a tela abriu e o jogo pausou")
	var ts: Array = []
	_textos(tela, ts)
	check(ts.any(func(t): return String(t) == String(ep.titulo)), "mostra o título do arquivo")
	check(ts.any(func(t): return String(t).begins_with("Anos depois")), "mostra o epílogo do arquivo")
	check(ts.any(func(t): return String(t) == "Estatísticas da vila"), "mostra a tela de estatísticas")
	var q: Array = ["Dias de vila", "Ipezinhos que passaram", "Mortes na vila", "Invasões vencidas", "Minério", "Barras", "Festivais", "Pedidos"]
	check(q.all(func(k): return ts.any(func(t): return String(t).begins_with(k))), "com as linhas: dias, quem passou, mortes, invasões, minério, barras, festivais e pedidos")
	check(_botao(tela, "Continuar em modo infinito") != null and _botao(tela, "Voltar ao menu inicial") != null, "as duas saídas: 'Continuar em modo infinito' e 'Voltar ao menu inicial'")
	check(_botao(tela, "Continuar jogando") == null, "o 'Continuar jogando' de antes saiu")
	check(tela.get_child_count() > 0 and _tem_rolagem(tela), "a tela rola (muita estatística)")

	print("== (D) o modo infinito")
	var ev := g("eventos")
	var ant_ligado: bool = ev.ligado
	check(ev._ocupado(), "com a vitória (sem modo infinito) os eventos ficam parados")
	_botao(tela, "Continuar em modo infinito").pressed.emit()
	await _frames(3)
	check(sol.infinito and sol.won and not paused, "'Continuar em modo infinito': o jogo segue (escudo aceso, sem pausa)")
	check(g("victory_screen") == null or g("victory_screen").is_queued_for_deletion(), "a tela fecha")
	check(not ev._ocupado(), "os eventos voltam a rodar (a vitória não os trava mais)")
	sol.win()
	await _frames(2)
	check(g("victory_screen") == null, "a vitória não se repete (won continua e win() é ignorada)")
	check(not def.sem_invasao() and def.next_invasion_day() != -1, "as invasões seguem (a Defesa não parou: próxima no dia %d)" % def.next_invasion_day())
	check(not bool(sol.wave_active()), "sem ondas solares (o escudo as segura)")
	ev.ligado = true
	var dn := g("day_night")
	ev.proximo_dia = int(dn.day)
	ev.ativo = {}
	var id: String = ev.sorteia()
	check(id != "", "no modo infinito um evento é sorteado e abre ('%s')" % id)
	ev.ligado = ant_ligado
	if not ev.ativo.is_empty():
		ev.ativo = {}
	paused = false

	print("== (E) a janela do Sol")
	var hud := g("hud")
	var painel = hud._panels.get("sol")
	check(painel != null and painel._epilogo_button != null, "a janela do Sol tem o botão 'Ver o epílogo e as estatísticas'")
	if painel != null:
		hud.open_panel("sol")
		await _frames(2)
		check(painel._epilogo_button.visible, "ele aparece depois da vitória")
		painel._epilogo_button.pressed.emit()
		await _frames(3)
		var t2 = g("victory_screen")
		check(t2 != null, "reabre o epílogo e as estatísticas")
		if t2 != null:
			var ts2: Array = []
			_textos(t2, ts2)
			check(_botao(t2, "Continuar em modo infinito") == null and _botao(t2, "Fechar") != null and ts2.any(func(t): return String(t).find("Modo infinito ligado") >= 0),
				"já no modo infinito: só 'Fechar' e 'Voltar ao menu inicial'")
			_botao(t2, "Fechar").pressed.emit()
			await _frames(2)
		check(not paused, "fechar volta ao jogo")
		painel.visible = false

	print("== (F) o save")
	var ds: Dictionary = est.get_save_data()
	var dj: Dictionary = JSON.parse_string(JSON.stringify(ds))
	check(dj.has("passaram") and dj.has("mortes") and dj.has("causas") and dj.has("invasoes") and dj.has("festas") and dj.has("pedidos_cumpridos"), "as chaves do save das estatísticas")
	var p_ant: int = est.passaram
	est.passaram = 0
	est.mortes = 0
	est.causas = {}
	est.load_save_data(dj)
	await _frames(2)
	est._t = 0.0
	est._process(0.1)
	check(est.passaram == p_ant and est.mortes == 5 and est.causas.get("criaturas", 0) == 1, "carregou: o que estava no save volta")
	check(est.passaram == p_ant, "...e quem já estava na vila não conta de novo depois de carregar (%d)" % est.passaram)
	est.load_save_data({})
	check(est.passaram == 0 and est.mortes == 0 and est.causas.is_empty() and est.festas == 0, "save antigo (sem 'estatisticas'): zera sem erro")
	check(est.invasoes_total() >= 0 and est.mortes_total() >= 0, "...e as mortes e invasões ainda saem dos contadores das missões")
	est.load_save_data({"passaram": "x", "mortes": -4, "causas": {"a": "b", "c": 2, "d": -1}, "festas": [1]})
	check(est.passaram == 0 and est.mortes == 0 and est.causas.get("c", 0) == 2 and not est.causas.has("a") and not est.causas.has("d"), "save quebrado vira o padrão")
	var sd: Dictionary = sol.get_save_data()
	check(sd.has("infinito") and bool(sd.infinito), "o Sol guarda o modo infinito")
	sol.infinito = false
	sol.load_save_data(JSON.parse_string(JSON.stringify(sd)))
	check(sol.infinito and sol.won, "carregou: continua no modo infinito")
	sd.erase("infinito")
	sol.load_save_data(sd)
	check(not sol.infinito, "save antigo (sem 'infinito'): sem modo infinito")
	check(FileAccess.get_file_as_string("res://scripts/core/save_manager.gd").find('"estatisticas": "estatisticas"') >= 0, "o save_manager guarda a chave 'estatisticas'")
	sol.won = false
	sol.infinito = false

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


func _tem_rolagem(n: Node) -> bool:
	if n is ScrollContainer:
		return true
	for c in n.get_children():
		if _tem_rolagem(c):
			return true
	return false
