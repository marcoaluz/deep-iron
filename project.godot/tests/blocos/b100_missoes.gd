extends SceneTree
## Bloco 100: o SISTEMA DE MISSÕES e o CAPÍTULO 1 "Cinzas" (seção 21 do guia). (A) Os dados: o recurso missao.gd (um .tres
## por missão em data/missoes/) e os textos num arquivo por capítulo (data/missoes/capitulo_1.txt, fácil de editar: o
## formato lê "chave = valor", continuação de linha e comentário). (B) O nó Missoes na cena (grupo "missoes"), a janela
## "Missões" (tecla vírgula, botão da aba fina) e o rastreador do canto (capítulo + 3 objetivos). (C) O capítulo 1: fundar
## a vila, 3 casas, a cozinha, 100 de minério e sobreviver à 1ª invasão; cada objetivo se marca sozinho, fica marcado
## mesmo se o minério sair, e cumprir tudo dá 150 cr, a página do diário e libera o capítulo 2. (D) Save: a chave
## "missoes" volta igual. (E) Save ANTIGO (sem a chave): começa no capítulo certo, conferindo o que já foi feito.
## RODAR SÓ COM APPDATA ISOLADO.
const Missoes := preload("res://scripts/core/missoes.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
var main: Node
var fails := 0
var _t0 := 0


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
	_t0 = Time.get_ticks_msec()
	_roda()


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - _t0 > 240000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func _espera(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += root.get_process_delta_time()


## Zera o estado da campanha e da vila pra um começo conhecido: nenhuma casa pronta, sem cozinha, armazém vazio.
func _base() -> void:
	var m = g("missoes")
	m.capitulo_liberado = 1
	m.cumpridas.clear()
	m.cumpridas.append(Missoes.PRIMEIRO_DIA)  # Bloco 112: a Cinzas vem depois do primeiro dia guiado
	m.feitos = {}
	m.contadores = {"invasoes": 0, "vendido": 0.0, "mortes": 0, "obras": {}}
	for c in get_nodes_in_group("casas"):
		c.built = false
	for c in get_nodes_in_group("comedouros"):
		c.remove_from_group("comedouros")
	for a in get_nodes_in_group("armazens"):
		for k in a.stock:
			a.stock[k] = 0.0
		a._recount()
	g("village_hub").founded = true
	g("diary").pages.clear()


func _roda() -> void:
	for i in 12:
		await process_frame
	await _espera(2.0)
	var m = g("missoes")
	var eco = g("economy")
	var hud = g("hud")
	var diary = g("diary")
	var hub = g("village_hub")
	var def = g("defense")
	var arm = g("armazens")

	print("== A) os dados e os textos")
	var ms := Missoes.todas()
	check(ms.size() >= 1 and Missoes.por_id("cap1_cinzas") != null, "o .tres da missão do capítulo 1 (%d missão(ões) em data/missoes)" % ms.size())
	var c1 = Missoes.por_id("cap1_cinzas")
	check(c1 != null and c1.capitulo == 1 and c1.objetivos.size() == 5 and int(c1.recompensa.get("creditos", 0)) == 150 and int(c1.recompensa.get("libera_capitulo", 0)) == 2,
		"capítulo 1: 5 objetivos, 150 cr, libera o capítulo 2")
	var tipos: Array = c1.objetivos.map(func(o): return o[0])
	check(tipos == ["fundar_vila", "casas", "construcao", "minerio_armazem", "invasoes"], "os objetivos: fundar, casas, cozinha, minério, invasão (%s)" % [tipos])
	check(m.capitulo_titulo(1) == "Cinzas" and m.capitulo_subtitulo(1) == "Acampamento" and m.titulo_da(c1) == "Cinzas",
		"os textos vêm do arquivo do capítulo (capitulo_1.txt): '%s' / '%s'" % [m.capitulo_titulo(1), m.capitulo_subtitulo(1)])
	check(m.objetivo_texto(c1, 1, false) == "Construir 3 casas" and m.objetivo_texto(c1, 3, false).begins_with("Ter 100 de minério"),
		"o {n} vira a quantidade ('%s' / '%s')" % [m.objetivo_texto(c1, 1, false), m.objetivo_texto(c1, 3, false)])
	var amostra := "# comentário\n[a]\ntitulo = Um título\ntexto = primeira linha\n  segunda linha\n  terceira com = igual\n[b]\nx = 1\n"
	var p := Missoes.interpreta(amostra)
	check(p.a.titulo == "Um título" and p.a.texto == "primeira linha segunda linha terceira com = igual" and p.b.x == "1" and not p.has("# comentário"),
		"o formato do arquivo de texto: chave = valor, continuação de linha e comentário")
	Missoes._textos_cache[1]["cap1_cinzas"]["titulo"] = "Cinzas (editado)"
	check(m.titulo_da(c1) == "Cinzas (editado)", "mudar o texto no arquivo muda o jogo (sem tocar no código nem no .tres)")
	Missoes.recarrega_textos()
	check(m.titulo_da(c1) == "Cinzas", "recarregar o arquivo volta ao texto dele")

	print("== B) o nó, a janela, a tecla e o rastreador")
	check(m != null and m.is_in_group("missoes"), "o nó Missoes na cena (grupo 'missoes')")
	check(hud._panels.has("missoes"), "a janela 'Missões' registrada no HUD")
	check(Teclas.acao(KEY_COMMA) == "painel_missoes" and Teclas.tecla("painel_missoes") == KEY_COMMA, "tecla própria: vírgula")
	check(hud.TECLA_JANELA.get("missoes", "") == "painel_missoes", "aparece no menu Janelas com a tecla")
	check(not hud._tira_missoes.disabled, "o botão da aba fina da esquerda agora funciona")
	_base()
	m.confere()
	await process_frame
	var rast = hud._missoes
	check(rast.visible and rast._titulo.text == "Cap. 1  Cinzas", "o rastreador do canto mostra o capítulo ('%s')" % rast._titulo.text)
	check(rast._lista.get_child_count() == 3, "e até 3 objetivos (%d)" % rast._lista.get_child_count())

	print("== C) o capítulo 1, objetivo por objetivo")
	var cr0: float = eco.credits
	# fundar a vila
	m.feitos = {}  # (o rastreador de cima já tinha marcado: volta ao zero pra ver a vila sem fundar)
	hub.founded = false
	m.confere()
	check(not m.objetivo_feito(c1, 0), "vila ainda não fundada: objetivo 1 aberto")
	hub.founded = true
	m.confere()
	check(m.objetivo_feito(c1, 0), "fundou a vila: objetivo 1 cumprido")
	# 3 casas
	var casas := get_nodes_in_group("casas")
	check(casas.size() >= 3, "a cena tem casas pra construir (%d)" % casas.size())
	for i in mini(2, casas.size()):
		casas[i].built = true
	m.confere()
	check(not m.objetivo_feito(c1, 1) and m.valor_do_objetivo(c1.objetivos[1]) == 2.0, "2 casas prontas: ainda não (2/3)")
	check(m.objetivo_texto(c1, 1).ends_with("(2/3)"), "o texto mostra o andamento ('%s')" % m.objetivo_texto(c1, 1))
	casas[2].built = true
	m.confere()
	check(m.objetivo_feito(c1, 1), "3 casas prontas: objetivo 2 cumprido")
	# a cozinha
	check(not m.objetivo_feito(c1, 2), "sem cozinha: objetivo 3 aberto")
	var coz = get_nodes_in_group("comedouro_teste")
	var comedouros_cena := main.get_node("World").get_children().filter(func(n): return n.has_method("deposit_food") or n.get_script() != null and String(n.get_script().resource_path).ends_with("comedouro.gd"))
	check(not comedouros_cena.is_empty(), "a cena tem a cozinha (comedouro.gd)")
	for c in comedouros_cena:
		c.add_to_group("comedouros")
	m.confere()
	check(m.objetivo_feito(c1, 2), "cozinha pronta: objetivo 3 cumprido")
	# 100 de minério
	arm.stock["ferro"] = 99.0
	arm._recount()
	m.confere()
	check(not m.objetivo_feito(c1, 3), "99 de minério: ainda não")
	arm.stock["ferro"] = 100.0
	arm._recount()
	m.confere()
	check(m.objetivo_feito(c1, 3), "100 de minério no armazém: objetivo 4 cumprido")
	arm.stock["ferro"] = 0.0
	arm._recount()
	m.confere()
	check(m.objetivo_feito(c1, 3), "vendeu o minério depois: o objetivo continua cumprido")
	# o rastreador: os cumpridos vão pro fim, os que faltam primeiro
	await process_frame
	check(rast._lista.get_child_count() == 3, "o rastreador segue com 3 linhas")
	check(not m.cumprida("cap1_cinzas") and m.capitulo_liberado == 1 and not diary.has_page("cap1_cinzas"), "falta a invasão: a missão ainda não foi cumprida")
	# a janela
	hud.open_panel("missoes")
	var jan = hud._panels.missoes
	check(jan.visible and jan._conteudo.get_child_count() > 6 and "Cap. 1" in jan._titulo.text, "a janela abre com o capítulo, o texto e os objetivos ('%s')" % jan._titulo.text)
	check(jan.button_text() == "Missões 4/5", "o menu Janelas diz o andamento ('%s')" % jan.button_text())
	hud.close_panels()
	# a invasão
	var fim := {"cumpriu": false}
	m.missao_cumprida.connect(func(id: String): fim.cumpriu = (id == "cap1_cinzas"))
	def.invasion_ended.emit(4)
	await process_frame
	check(m.contadores.invasoes == 1 and m.objetivo_feito(c1, 4), "invasão sobrevivida (sinal invasion_ended): objetivo 5 cumprido")
	check(m.cumprida("cap1_cinzas") and fim.cumpriu, "todos os objetivos: a missão está cumprida")
	check(is_equal_approx(eco.credits - cr0, 150.0), "recompensa: +150 créditos (%+.0f)" % (eco.credits - cr0))
	check(diary.has_page("cap1_cinzas") and diary.entrada("cap1_cinzas").title == "Cap. 1 — Cinzas", "recompensa: a página do diário, com o texto do arquivo ('%s')" % diary.entrada("cap1_cinzas").get("title", ""))
	check(m.capitulo_liberado == 2 and not m.capitulo_existe(2), "libera o capítulo 2 (ainda não escrito)")
	await process_frame
	check(not rast.visible, "sem missão valendo, o rastreador some")
	m.confere()
	check(is_equal_approx(eco.credits - cr0, 150.0), "a recompensa não é paga duas vezes")
	hud.open_panel("missoes")
	await process_frame
	check("Capítulo 2" in hud._panels.missoes._conteudo.get_children().map(func(c): return c.text if c is Label else "").reduce(func(a, b): return a + "|" + b, ""), "a janela fala do capítulo 2 que vem aí")
	hud.close_panels()
	# os outros sinais que o sistema escuta
	var o0: int = int(m.contadores.mortes)
	var w = get_nodes_in_group("ipezinhos")[0]
	w.died.emit("Teste")
	check(int(m.contadores.mortes) == o0 + 1, "morte (ipezinho.died) conta")
	var v0: float = float(m.contadores.vendido)
	eco.ore_sold.emit(30.0, 90.0)
	check(is_equal_approx(float(m.contadores.vendido) - v0, 30.0), "minério vendido (economy.ore_sold) conta")
	hub.obra_pronta.emit("taverna")
	check(int(m.contadores.obras.get("taverna", 0)) == 1, "obra pronta (centro_vila.obra_pronta, o sinal novo) conta")

	print("== D) save: a chave 'missoes' volta igual")
	var d: Dictionary = m.get_save_data()
	check(d.cumpridas == [Missoes.PRIMEIRO_DIA, "cap1_cinzas"] and d.capitulo_liberado == 2 and (d.feitos.cap1_cinzas as Array).size() == 5, "o que vai pro save (%s)" % [d.cumpridas])
	m.cumpridas.clear()
	m.feitos = {}
	m.capitulo_liberado = 1
	m.load_save_data(d)
	check(m.cumprida("cap1_cinzas") and m.capitulo_liberado == 2 and m.objetivo_feito(c1, 3), "carregou: a missão cumprida, o capítulo 2 e os objetivos voltam")
	m.load_save_data({"capitulo_liberado": 99, "cumpridas": ["nao_existe"], "feitos": {"cap1_cinzas": [0, 99, -1]}})
	check(m.capitulo_liberado == 6 and m.cumpridas == [Missoes.PRIMEIRO_DIA] and (m.feitos.cap1_cinzas as Array) == [0], "chaves ruins: ignora o que não existe (sem erro; sem 'primeiro_dia' = save antigo: o primeiro dia já passou)")
	var sm = root.get_node("SaveManager")
	m.load_save_data(d)
	sm.save_game("manual")
	m.cumpridas.clear()
	m.capitulo_liberado = 1
	sm.load_game()
	await _espera(1.0)
	check(g("missoes").cumprida("cap1_cinzas") and g("missoes").capitulo_liberado == 2, "pelo SaveManager de verdade: salvou e carregou")
	m = g("missoes")  # (o load_game trocou a cena: tudo de antes foi liberado, pega de novo)
	def = g("defense")
	eco = g("economy")
	hud = g("hud")
	hub = g("village_hub")
	diary = g("diary")

	print("== E) save ANTIGO (sem a chave): começa no capítulo certo")
	# 1) a vila já tinha feito tudo: casas, cozinha, minério e 2 invasões passadas
	_base()
	for c in get_nodes_in_group("casas"):
		c.built = true
	for c in g("village_hub").get_parent().get_children():  # (o load_game trocou a cena: o `main` de antes foi liberado)
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("comedouro.gd"):
			c.add_to_group("comedouros")
	arm = g("armazens")
	arm.stock["ferro"] = 250.0
	arm._recount()
	def.wave = 2
	def.invasion_active = false
	eco.credits = 1000.0
	sm.save_game("manual")
	var f := FileAccess.open("user://savegame.json", FileAccess.READ)
	var dados = JSON.parse_string(f.get_as_text())
	f.close()
	dados.erase("missoes")
	var w2 := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	w2.store_string(JSON.stringify(dados))
	w2.close()
	def = g("defense")
	eco = g("economy")
	m = g("missoes")
	m.capitulo_liberado = 5  # (lixo da partida de antes: o save antigo manda)
	m.cumpridas.append("lixo")
	sm.load_game()
	await _espera(1.0)
	m = g("missoes")
	check(m.cumprida("cap1_cinzas") and m.capitulo_liberado == 2 and not m.cumpridas.has("lixo"), "o capítulo 1 já estava cumprido: conferiu e liberou o 2 (lixo descartado)")
	check(is_equal_approx(g("economy").credits, 1150.0), "a recompensa foi entregue uma vez (%.0f)" % g("economy").credits)
	check(g("diary").has_page("cap1_cinzas"), "e a página do diário")
	# 2) a vila tinha feito só uma parte: nenhuma invasão ainda, sem minério
	_base()
	for c in get_nodes_in_group("casas"):
		c.built = true
	arm = g("armazens")
	arm.stock["ferro"] = 10.0
	arm._recount()
	g("defense").wave = 0
	g("economy").credits = 500.0
	sm.save_game("manual")
	f = FileAccess.open("user://savegame.json", FileAccess.READ)
	dados = JSON.parse_string(f.get_as_text())
	f.close()
	dados.erase("missoes")
	w2 = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	w2.store_string(JSON.stringify(dados))
	w2.close()
	sm.load_game()
	await _espera(1.0)
	m = g("missoes")
	var c1b = Missoes.por_id("cap1_cinzas")
	check(not m.cumprida("cap1_cinzas") and m.capitulo_liberado == 1 and m.capitulo_atual() == 1, "só parte feita: continua no capítulo 1")
	check(m.objetivo_feito(c1b, 0) and m.objetivo_feito(c1b, 1) and not m.objetivo_feito(c1b, 3) and not m.objetivo_feito(c1b, 4),
		"o que já estava feito vem marcado (vila, casas); falta o minério e a invasão (%s)" % [m.feitos.get("cap1_cinzas", [])])
	check(is_equal_approx(g("economy").credits, 500.0), "sem recompensa antes da hora")
	check(g("hud")._missoes.visible, "o rastreador volta com a missão valendo")

	print("\nFALHAS: %d" % fails)
	quit()
