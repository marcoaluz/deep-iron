extends SceneTree
## Bloco 102: o CATÁLOGO DE DESCOBERTAS (o pesquisador como naturalista). (A) O conhecimento inicial (ferro estudado;
## carvão, cobre e coelho avistados; o resto desconhecido), a pedra desconhecida no mapa e a toca escondida do caçador.
## (B) Avistar quando alguém passa perto. (C) O minério desconhecido: sai "desconhecido" da jazida, vira o minério de
## verdade quando estudado; a fornalha sem a receita; a Oficina sem o nome. (D) A pesquisadora: sem pesquisa sai pra
## catalogar (vai, anota, volta, entrega: aviso, pontos, diário), duas não repetem o alvo, com pesquisa fica no
## laboratório. (E) A pesquisa travada pelo estudo. (F) O plano B (o laboratório sozinho) e a amostra da criatura.
## (G) As missões (o sinal e o objetivo "estudar"). (H) A janela (tecla R, abas, silhueta, "???"). (I) Save e save
## antigo. RODAR SÓ COM APPDATA ISOLADO.
const Teclas := preload("res://scripts/core/teclas.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
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
	if Time.get_ticks_msec() - _t0 > 400000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		Engine.time_scale = 1.0
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


func _ate(cond: Callable, s: float) -> bool:
	var t := 0.0
	while t < s:
		if cond.call():
			return true
		await process_frame
		t += root.get_process_delta_time()
	return cond.call()


func _jazida(tipo: String, acessivel := true) -> Node:
	for m in get_nodes_in_group("minerios"):
		if m.ore_type == tipo and (not acessivel or m.acessivel()):
			return m
	return null


func _toca(animal: String) -> Node:
	for t in get_nodes_in_group("caca"):
		if t.animal == animal:
			return t
	return null


func _roda() -> void:
	for i in 12:
		await process_frame
	await _espera(2.0)
	var cat = g("catalogo")
	var eco = g("economy")
	var hud = g("hud")
	var res = g("research")
	var of = g("oficina")
	var env = g("environment")
	var dn = g("day_night")
	var mig = g("migrantes")
	if mig:
		mig.proximo = 1.0e9  # (sem migrantes no meio)
	check(cat != null and cat.entradas().size() >= 20, "o catálogo está na cena com as entradas dos dados (%d)" % (cat.entradas().size() if cat else 0))

	print("== A) conhecimento inicial")
	check(cat.estado("ferro") == cat.ESTUDADO, "ferro: estudado")
	check(cat.estado("carvao") == cat.AVISTADO and cat.estado("cobre") == cat.AVISTADO, "carvão e cobre: avistados")
	check(cat.estado("coelho") == cat.AVISTADO, "coelho: avistado")
	check(cat.estado("javali") == cat.DESCONHECIDO and cat.estado("prata") == cat.DESCONHECIDO
		and cat.estado("S2") == cat.DESCONHECIDO and cat.estado("lumivoro") == cat.DESCONHECIDO, "javali, prata, S2 e lumívoro: desconhecidos")
	var cobre: Node = _jazida("cobre")
	var ferro: Node = _jazida("ferro")
	check(cobre != null and not cobre.conhecido and cobre.tipo_extraido() == "desconhecido", "a jazida de cobre é pedra desconhecida (sai 'desconhecido')")
	check(ferro.conhecido and ferro.tipo_extraido() == "ferro", "a de ferro é ferro")
	cobre._update_visual()
	check("Pedra desconhecida" in cobre._label.text, "a placa diz 'Pedra desconhecida' (%s)" % cobre._label.text.replace("\n", " "))
	var camadas: Array = IsoArt._ore_layers(cobre, env)
	check(not camadas.is_empty() and "desconhecida" in (camadas[0].tex as Texture2D).resource_path, "a vista iso desenha a pedra desconhecida (%s)" % ((camadas[0].tex as Texture2D).resource_path.get_file() if not camadas.is_empty() else "?"))
	of.crafted["arco"] = true  # (o caçador já teria arco)
	var coelho: Node = _toca("coelho")
	coelho._update_visual()
	check(not coelho.conhecida() and not coelho.is_usable() and not coelho.accepts_worker(null), "a toca de coelho ainda não estudada não aparece pro caçador")
	check("???" in coelho._label.text, "a placa da toca diz 'Toca ???'")
	check(of.unlock_label("picareta_aco") == "um minério desconhecido", "a Oficina não diz o nome do minério: '%s'" % of.unlock_label("picareta_aco"))

	print("== B) avistar")
	var javali: Node = _toca("javali")
	var gente: Array = get_nodes_in_group("ipezinhos")
	var batedor: Node = gente[gente.size() - 1]
	batedor.auto_mode = false
	batedor.global_position = javali.global_position + Vector2(60, 40)
	var viu := await _ate(func(): return cat.estado("javali") == cat.AVISTADO, 4.0)
	check(viu, "alguém passou perto da toca do javali: avistada")
	batedor.auto_mode = true
	var sinal_av := [0]
	cat.entrada_avistada.connect(func(_id): sinal_av[0] += 1)
	cat.avista("prata")
	check(cat.estado("prata") == cat.AVISTADO and sinal_av[0] == 1, "avista emite o sinal (entrada_avistada)")

	print("== C) minério desconhecido")
	of.crafted["picareta_aco"] = true
	cobre.on_unlock_changed(false)
	check(cobre.is_unlocked() and not cobre.conhecido, "com a picareta, a pedra desconhecida dá pra minerar")
	var tirou: float = cobre.extract(12.0)
	check(tirou > 0.0 and is_equal_approx(float(cat.bruto.get("cobre", 0.0)), tirou), "o que sai dela fica anotado como cobre (%.0f)" % tirou)
	var arm = g("armazens")
	arm.add_ore(30.0, "desconhecido")
	cat.bruto["cobre"] = 30.0
	var cobre0: float = eco.quantidade("cobre")
	check(eco.quantidade("desconhecido") >= 30.0 and eco.price_of("desconhecido") < eco.price_of("ferro"), "minério desconhecido no armazém, vale menos que o ferro")
	check(eco.missing_text(0, 1000, "", 0) != "" and not eco.can_afford(0, eco.stored_ore("") , "", 0), "o desconhecido não paga custo de 'minério qualquer'")
	var fpc = load("res://scenes/props/fornalha.tscn").instantiate()
	fpc.position = Vector2(900, 300)
	main.get_node("World").add_child(fpc)
	await process_frame
	check(fpc.minerio_nao_estudado("barra_cobre") == "cobre" and "estudar" in fpc.motivo_encomenda("barra_cobre", 1), "a fornalha não faz barra de cobre sem o estudo (%s)" % fpc.motivo_encomenda("barra_cobre", 1))
	var antes_est := []
	cat.entrada_estudada.connect(func(id, c): antes_est.append([id, c]))
	cat.estuda("cobre")
	check(cat.estudado("cobre") and antes_est.size() == 1 and antes_est[0] == ["cobre", "minerio"], "estudou o cobre (sinal entrada_estudada)")
	check(is_equal_approx(eco.quantidade("cobre") - cobre0, 30.0) and eco.quantidade("desconhecido") < 1.0, "os 30 de minério desconhecido viraram cobre no armazém")
	check(cobre.conhecido and cobre.tipo_extraido() == "cobre", "a jazida volta a ser cobre")
	check(fpc.minerio_nao_estudado("barra_cobre") == "carvao", "a barra de cobre agora só espera o carvão (o outro insumo)")
	check(g("diary").has_page("cat_cobre"), "o diário ganhou a página do cobre")
	check(of.unlock_label("picareta_aco") == "Cobre", "a Oficina diz o nome agora")
	fpc.queue_free()

	print("== D) a pesquisadora no campo")
	cat.segundos_estudo = 3.0
	var guardados0: float = res.pontos_guardados
	var p1: Node = null
	var p2: Node = null
	for w in get_nodes_in_group("ipezinhos"):
		if w == batedor:
			continue
		if p1 == null:
			p1 = w
		elif p2 == null:
			p2 = w
	p1.set_job("pesquisador")
	p2.set_job("pesquisador")
	p1.carrying = 0.0
	p2.carrying = 0.0
	dn.time = dn.tempo_da_hora(9.0) if dn.has_method("tempo_da_hora") else dn.time
	Engine.time_scale = 4.0
	var sairam := await _ate(func(): return not p1._campo.is_empty() and not p2._campo.is_empty(), 30.0)
	check(sairam and p1.get_state() == "catalogando" and p2.get_state() == "catalogando", "sem pesquisa, as duas saem pra catalogar (%s / %s)" % [p1.get_state(), p2.get_state()])
	check(sairam and String(p1._campo.id) != String(p2._campo.id), "as duas não repetem o alvo (%s / %s)" % [p1._campo.get("id", "?"), p2._campo.get("id", "?")])
	var primeiro := String(p1._campo.get("id", ""))
	check(primeiro == "carvao" or String(p2._campo.get("id", "")) == "carvao", "o minério vem primeiro (carvão)")
	var estudou := await _ate(func(): return cat.estudado("carvao"), 120.0)
	check(estudou, "a pesquisadora foi, anotou, voltou e entregou: carvão estudado")
	check(res.pontos_guardados >= guardados0 + cat.pontos_por_estudo - 0.01, "o estudo deu pontos de pesquisa guardados (%.0f)" % res.pontos_guardados)
	Engine.time_scale = 1.0

	print("== E) a pesquisa travada pelo estudo")
	if not res.done.has("carrinhos"):
		res.done.append("carrinhos")
	if res.lab() == null:
		res.spawn_lab(Vector2(560, 300))
	await process_frame
	check("precisa estudar" in res.block_reason("trajes"), "Trajes espera o reconhecimento do S2 (%s)" % res.block_reason("trajes"))
	check(res.estudo_que_falta("explosivos") == "", "Explosivos liberou (o carvão foi estudado)")
	cat.avista("S2", false)
	cat.estuda("S2")
	check(not ("precisa estudar" in res.block_reason("trajes")), "estudado o S2, a pesquisa dos Trajes anda (%s)" % res.block_reason("trajes"))
	# com pesquisa no laboratório, a pesquisadora fica lá
	res.current = "medicina"
	res.progress = 0.0
	var g0: float = res.pontos_guardados
	res.ganha_pontos(5.0)
	check(is_equal_approx(res.progress, 5.0) and is_equal_approx(res.pontos_guardados, g0), "com pesquisa em andamento, os pontos vão direto pra ela")
	p1.wake_decision()
	p2.wake_decision()
	var no_lab := await _ate(func(): return p1.get_state() == "research" or p2.get_state() == "research", 20.0)
	check(no_lab, "com pesquisa ativa, a pesquisadora fica no laboratório (%s / %s)" % [p1.get_state(), p2.get_state()])
	res.current = ""
	res.progress = 0.0

	print("== F) plano B e amostras")
	p1.set_job("ocioso")
	p2.set_job("ocioso")
	await process_frame
	check(cat.motivo_lab("lumivoro") == "ainda não avistado", "o que não foi avistado não dá pra estudar")
	check(cat.motivo_lab("javali") == "", "javali avistado: o laboratório pode estudar sozinho")
	check(cat.estudar_no_lab("javali"), "começou o estudo no laboratório")
	cat.lab_pontos_sozinho = 40.0
	var lab_ok := await _ate(func(): return cat.estudado("javali"), 5.0)
	check(lab_ok and cat.estudo_lab.is_empty(), "o laboratório sozinho estudou o javali (plano B)")
	javali._update_visual()
	check(javali.conhecida(), "a toca do javali agora aparece pro caçador")
	var lum = load("res://scenes/creatures/lumivoro.tscn").instantiate()
	lum.position = Vector2(-400, 200)
	main.get_node("World").add_child(lum)
	await process_frame
	lum.die(true)
	check(int(cat.amostras.get("lumivoro", 0)) == 1 and cat.estado("lumivoro") == cat.AVISTADO, "o lumívoro abatido deixou uma amostra (e conta como visto)")
	p1.set_job("pesquisador")
	var alvo_l: Dictionary = cat._alvo_de("lumivoro", p1)
	check(not alvo_l.is_empty() and alvo_l.lab, "a amostra se estuda no laboratório")
	p1.set_job("ocioso")
	cat.estuda("lumivoro")
	check(cat.estudado("lumivoro") and int(cat.amostras.get("lumivoro", 0)) == 0 and g("diary").has_page("lumivoros"), "estudada a amostra: a página dos Lumívoros no diário")

	print("== G) missões")
	var ms = g("missoes")
	check(ms.valor_do_objetivo(["estudar", "", 3]) == float(cat.quantos_estudados()), "objetivo 'estudar' (quantas): %d" % cat.quantos_estudados())
	check(ms.valor_do_objetivo(["estudar", "cobre", 1]) == 1.0 and ms.valor_do_objetivo(["estudar", "gema_azul", 1]) == 0.0, "objetivo 'estudar' (uma entrada)")
	check(ms.valor_do_objetivo(["estudar", "animal", 2]) == 2.0, "objetivo 'estudar' (uma categoria)")

	print("== H) a janela")
	check(Teclas.acao(KEY_R) == "painel_catalogo", "a tecla R abre o Catálogo")
	hud.open_panel("catalogo")
	var pn = hud._panels.get("catalogo")
	check(pn != null and pn.visible, "a janela abre")
	pn.mostra_aba("minerio")
	await process_frame
	await process_frame
	var prata_row: Node = pn._lista.get_node_or_null("Entrada_gema_azul")
	var ferro_row: Node = pn._lista.get_node_or_null("Entrada_ferro")
	check(_nome_da_linha(prata_row) == "???", "desconhecida: '???'")
	check(prata_row != null and (prata_row.get_node("Icone") as TextureRect).modulate.r < 0.05, "desconhecida: o ícone em silhueta")
	check(ferro_row != null and _nome_da_linha(ferro_row) == "Ferro", "estudada: o nome")
	check(ferro_row != null and _textos_da_linha(ferro_row).contains("Para que serve"), "estudada: para que serve")
	var prata2: Node = pn._lista.get_node_or_null("Entrada_prata")
	check(prata2 != null and prata2.find_child("PlanoB", true, false) != null, "avistada: o botão do plano B")
	check((pn._abas["minerio"] as Button).text.begins_with("Minerais"), "as abas com o contador (%s)" % (pn._abas["minerio"] as Button).text)
	pn.mostra_aba("criatura")
	await process_frame
	await process_frame
	check(pn._lista.get_node_or_null("Entrada_lumivoro") != null and pn._lista.get_node_or_null("Entrada_ferro") == null, "a aba Criaturas mostra as criaturas")
	hud.close_panels()

	print("== I) save e save antigo")
	cat.bruto["prata"] = 7.0
	cat.amostras["gosma"] = 2
	var d: Dictionary = cat.get_save_data()
	var est0: Dictionary = cat.estados.duplicate()
	cat.load_save_data({})
	cat.load_save_data(d)
	check(cat.estados == est0 and is_equal_approx(float(cat.bruto.get("prata", 0.0)), 7.0) and int(cat.amostras.get("gosma", 0)) == 2, "salvou e carregou os estados, o minério anotado e as amostras")
	var sm = root.get_node("SaveManager")
	sm.save_game()
	var js = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
	check(js is Dictionary and js.has("catalogo") and (js.catalogo.estados as Dictionary).has("cobre"), "o save do jogo tem a chave 'catalogo'")
	# save antigo: sem a chave — o liberado vira estudado
	if not res.done.has("trajes"):
		res.done.append("trajes")
	of.crafted["lampiao"] = true
	for m in get_nodes_in_group("minerios"):
		m.on_unlock_changed(false)
	cat.load_save_data({})
	cat.depois_de_carregar(false)
	check(cat.estudado("ferro") and cat.estudado("coelho") and cat.estudado("javali"), "save antigo: ferro e as tocas visíveis estudados (a caça continua)")
	check(cat.estudado("S2"), "save antigo: o que a pesquisa feita pedia (Trajes -> S2) estudado")
	check(cat.estudado("cobre") and cat.estudado("carvao"), "save antigo: minério com jazida destravada estudado")
	check(cat.estado("gema_azul") == cat.DESCONHECIDO, "save antigo: o que não tinha sido liberado continua desconhecido")
	res.load_save_data({"done": ["carrinhos"]})
	check(is_equal_approx(res.pontos_guardados, 0.0), "pesquisa de save antigo: sem pontos guardados")

	print("\nFALHAS: %d" % fails)
	quit()


func _nome_da_linha(row: Node) -> String:
	if row == null:
		return ""
	var n := row.find_child("Nome", true, false)
	return (n as Label).text if n else ""


func _textos_da_linha(row: Node) -> String:
	var out := ""
	for l in row.find_children("*", "Label", true, false):
		out += (l as Label).text + "\n"
	return out
