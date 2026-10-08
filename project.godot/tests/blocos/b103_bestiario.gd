extends SceneTree
## Bloco 103: CRIATURAS (corpos e bestiário) e RECONHECIMENTO DOS ANDARES. (A) O corpo: nasce na morte com a pose de
## morte e o drop, tem prazo, incomoda na vila e some no prazo (o drop vai pro armazém). (B) A pesquisadora estuda o
## corpo: a ficha (perigo, fraqueza, deixa, por que veio, dica), o cartão, o diário, a experiência, o ânimo, o balão, o
## drop colhido; corpo lá fora com o portão fechado: não vai. (C) A Defesa: "???", a previsão, o banner, sem Gosma e
## Magmante na onda. (D) A Gosma corrói a arma. (E) Os moradores do fundo (nascem no andar, não sobem, só miram quem
## está lá) e a patrulha dos guardas. (F) O andar não reconhecido: a IA não desce, a confirmação, o acidente 2x, o
## reconhecimento (risco, ficha). (G) Sinais e missões. (H) Save e save antigo. RODAR SÓ COM APPDATA ISOLADO.
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
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


func _cria(kind: String, pos: Vector2) -> Node2D:
	var c: Node2D = load("res://scenes/creatures/%s.tscn" % kind).instantiate()
	c.position = pos
	main.get_node("World").add_child(c)
	return c


func _corpos(especie: String) -> Array:
	return get_nodes_in_group("corpos_criatura").filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion() and c.especie == especie)


func _roda() -> void:
	for i in 12:
		await process_frame
	await _espera(2.0)
	var cat = g("catalogo")
	var eco = g("economy")
	var hud = g("hud")
	var res = g("research")
	var def = g("defense")
	var dn = g("day_night")
	var b = g("barricadas")
	var mig = g("migrantes")
	if mig:
		mig.proximo = 1.0e9
	var hub = g("village_hub")
	var dentro: Vector2 = hub.global_position + Vector2(60, 70)
	while get_nodes_in_group("ipezinhos").size() < 5:
		eco.novo_ipezinho()  # (gente pra pesquisadora, guarda, quem fica lá em cima e o minerador)
	await process_frame

	print("== A) o corpo")
	var lum := _cria("lumivoro", dentro)
	await process_frame
	lum.die(true)
	await process_frame
	await process_frame
	var cl: Array = _corpos("lumivoro")
	check(cl.size() == 1, "o lumívoro abatido deixou um corpo no chão")
	var corpo: Node2D = cl[0] if not cl.is_empty() else null
	check(corpo != null and corpo.prazo_dia == dn.day + 1 and is_equal_approx(corpo.prazo_t, cat.horas_corpo * dn.segundos_por_hora()), "o prazo: o amanhecer seguinte + %d h" % int(cat.horas_corpo))
	var pose: Dictionary = IsoBonecos.criatura_pose(corpo, 0, false) if corpo else {}
	check(not pose.is_empty() and pose.anim == "morrer" and int(pose.frame) == int(pose.n) - 1, "desenho: o último quadro da morte (%s %s/%s)" % [pose.get("anim", "?"), pose.get("frame", "?"), pose.get("n", "?")])
	check(cat.estado("lumivoro") == cat.AVISTADO, "a criatura conta como vista")
	await _espera(1.5)
	check(cat.desconforto >= cat.desconforto_corpo - 0.01, "corpo na vila incomoda (%.1f)" % cat.desconforto)
	var mor = g("morale")
	check(mor.village_factors().any(func(f): return String(f[0]) == "corpos de criatura na vila"), "o ânimo da vila mostra o motivo")
	var gos := _cria("gosma", dentro + Vector2(40, 0))
	gos.drop_chance = 1.0
	await process_frame
	gos.die(true)
	await process_frame
	await process_frame
	var cg: Array = _corpos("gosma")
	check(cg.size() == 1 and int(cg[0].drop.get("cristal_verde", 0)) == 2, "o drop da Gosma (espécie não estudada) fica no corpo: %s" % [cg[0].drop if not cg.is_empty() else "?"])
	var cv0: float = eco.quantidade("cristal_verde")
	cg[0].prazo_dia = dn.day
	cg[0].prazo_t = 0.0
	var sumiu := await _ate(func(): return _corpos("gosma").is_empty(), 3.0)
	check(sumiu and is_equal_approx(eco.quantidade("cristal_verde") - cv0, 2.0), "passou do prazo: o corpo some e o drop vai pro armazém (o total não muda)")

	print("== B) a pesquisadora estuda o corpo")
	cat.segundos_estudo = 3.0
	var gente: Array = get_nodes_in_group("ipezinhos")
	var pq: Node = gente[0]
	pq.set_job("pesquisador")
	pq.carrying = 0.0
	pq.global_position = dentro + Vector2(-40, 20)
	for id in ["cobre", "carvao", "coelho"]:
		cat.estuda(id, null)  # (o que já começa avistado: ela iria primeiro no minério)
	var xp0: int = pq.xp_pesquisa
	dn.time = dn.tempo_da_hora(9.0)
	Engine.time_scale = 4.0
	var foi := await _ate(func(): return not pq._campo.is_empty() and pq._campo.has("corpo"), 25.0)
	check(foi and String(pq._campo.id) == "lumivoro", "sem pesquisa, a pesquisadora vai até o corpo (%s)" % [pq._campo.get("id", "?")])
	var est := await _ate(func(): return cat.estudado("lumivoro"), 90.0)
	Engine.time_scale = 1.0
	check(est, "estudou o Lumívoro pelo corpo")
	check(_corpos("lumivoro").is_empty(), "o corpo estudado sumiu")
	check(g("diary").has_page("lumivoros"), "a página dos Lumívoros no diário")
	check(pq.xp_pesquisa == xp0 + 1 and pq.ritmo_estudo() > 1.0, "a pesquisadora ganhou experiência (xp %d, ritmo %.1f)" % [pq.xp_pesquisa, pq.ritmo_estudo()])
	check(pq.animo_descoberta > 0.0 and pq.happiness_factors().any(func(f): return String(f[0]) == "fez uma descoberta"), "e ficou realizada (ânimo)")
	check(pq._balao != null, "o balão de comemoração")
	var fic: Array = cat.ficha("lumivoro")
	var chaves := fic.map(func(f): return String(f[0]))
	check(chaves.has("Comportamento") and chaves.has("Fraqueza") and chaves.has("Deixa") and chaves.has("Perigo") and chaves.has("Por que veio") and chaves.has("Dica"), "a ficha completa: %s" % [chaves])
	check(cat.perigo("lumivoro") < cat.perigo("magmante") and cat.perigo("matriarca") == 5, "o perigo vem dos números (lumívoro %d, magmante %d, matriarca %d)" % [cat.perigo("lumivoro"), cat.perigo("magmante"), cat.perigo("matriarca")])
	check(cat.texto("lumivoro", "porque").contains("LUZ") and cat.texto("lumivoro", "historia") != "", "por que veio (a luz) e a história, do arquivo")
	# o drop colhido no estudo (um ferrugento com peça rara)
	var fer := _cria("ferrugento", dentro + Vector2(-20, 40))
	await process_frame
	fer.die(true)
	await process_frame
	await process_frame
	var cf: Array = _corpos("ferrugento")
	check(cf.size() == 1, "o ferrugento deixou corpo (desenho da folha: %s)" % [cf[0]._visual.region_rect if not cf.is_empty() else "?"])
	cf[0].drop = {"pecas": 1}
	var pecas0: int = g("finds").rare_parts
	Engine.time_scale = 4.0
	var est2 := await _ate(func(): return cat.estudado("ferrugento"), 90.0)
	Engine.time_scale = 1.0
	check(est2 and g("finds").rare_parts == pecas0 + 1, "estudou o Ferrugento e colheu a peça rara do corpo")
	# corpo lá fora com o portão fechado
	var fora := Vector2.INF
	for dx in [-160.0, 160.0]:
		for dy in [-160.0, 160.0]:
			var p: Vector2 = b.global_position + Vector2(dx, dy)
			if b.lado_de(p) == -1:
				fora = p
	var gm := _cria("gosma", fora)
	await process_frame
	gm.die(true)
	await process_frame
	await process_frame
	b.set_process(false)
	b._livre = false
	var corpo_fora: Array = _corpos("gosma")
	check(not corpo_fora.is_empty() and not cat._chega_no_corpo(corpo_fora[0], pq), "corpo lá fora com o portão fechado: ela não vai")
	b._livre = true
	check(not corpo_fora.is_empty() and cat._chega_no_corpo(corpo_fora[0], pq), "com o portão aberto, vai")
	b.set_process(true)

	print("== C) a Defesa")
	check(def.fundo_count("gosma", 9) == 0 and def.fundo_count("magmante", 9) == 0, "Gosma e Magmante saíram das invasões da superfície")
	var comp: Dictionary = def.composicao(def.wave + 1)
	check(comp.has("lumivoro") and comp.lumivoro >= 1, "a previsão da próxima onda: %s" % [comp])
	var txt: String = def.texto_onda({"lumivoro": 3, "ferrugento": 2})
	check(txt.contains("3 Lumívoros") and txt.contains("2 Ferrugentos"), "estudadas, aparecem pelo nome: %s" % txt)
	check(def.texto_onda({"lumivoro": 1, "chefe": true}).contains("???"), "a Matriarca não estudada aparece como ???")
	hud.open_panel("defesa")
	var pd = hud._panels.get("defesa")
	pd._cri_sig = ""
	pd.refresh()
	await process_frame
	var bes: Node = pd._cri_box
	check(bes.get_node_or_null("Previsao") != null and (bes.get_node("Previsao") as Label).text.contains("Previsão"), "a janela da Defesa mostra a previsão")
	var row_l: Node = bes.get_node_or_null("Especie_lumivoro")
	check(row_l != null and (row_l.get_node("Texto") as Label).text.contains("Lumívoro"), "a espécie estudada com a ficha curta")
	var row_g: Node = bes.get_node_or_null("Especie_gosma")
	check(row_g != null and (row_g.get_node("Texto") as Label).text.begins_with("???"), "a não estudada aparece como ???")
	hud.close_panels()

	print("== D) a Gosma corrói a arma")
	var guarda: Node = gente[1]
	guarda.set_job("guarda")
	guarda.equip("lanca")
	var d0: float = guarda.weapon_durability
	var g2 := _cria("gosma", guarda.global_position + Vector2(10, 0))
	await process_frame
	g2.set_process(false)
	g2._attack(guarda)
	check(guarda.weapon_durability < d0, "o golpe da Gosma gastou a arma (%.0f -> %.0f)" % [d0, guarda.weapon_durability])
	var d1: float = guarda.weapon_durability
	var l2 := _cria("lumivoro", guarda.global_position + Vector2(10, 0))
	await process_frame
	l2.set_process(false)
	l2._attack(guarda)
	check(is_equal_approx(guarda.weapon_durability, d1), "o do Lumívoro não gasta")
	g2.queue_free()
	l2.queue_free()
	if guarda.injured:
		guarda._heal()  # (o golpe pode ter machucado: a patrulha é só de guarda inteiro)

	print("== E) moradores do fundo e a patrulha")
	g("elevador").unlock(false)
	if g("elevador").has_method("restaura_tudo"):
		g("elevador").restaura_tudo()
	await _espera(0.5)
	def._moradores_t = 0.0
	def._moradores_tick(0.1)
	await process_frame
	var mor_s2: Array = def.moradores("S2")
	check(mor_s2.size() == 2 and mor_s2.all(func(c): return c.kind == "gosma" and c.morador == "S2"), "o S2 abriu: 2 Gosmas moram lá (%d)" % mor_s2.size())
	var env = g("environment")
	check(mor_s2.all(func(c): return env.level_at(c.global_position) == env.level_at(Vector2(220, 3680))), "nasceram no andar delas")
	check(not def.creatures().any(func(c): return mor_s2.has(c)), "não contam como invasão (não fogem no amanhecer)")
	var na_vila: Node = gente[2]
	check(not mor_s2[0]._target_ok(na_vila), "o morador não mira quem está lá em cima")
	def.pede_patrulha("S2", 1)
	check(def.patrulha_para(guarda) == "S2", "o guarda foi mandado caçar no S2")
	guarda.wake_decision()
	var desceu := await _ate(func(): return guarda.get_state() == "patrulha", 10.0)
	check(desceu, "de dia, o guarda da patrulha sai pra caçar (%s)" % guarda.get_state())
	def.pede_patrulha("S2", 0)

	print("== F) o andar não reconhecido")
	var no_s2 := Vector2(220, 3680)
	var minerador: Node = gente[3]
	minerador.set_job("minerador")
	check(cat.estado("S2") == cat.AVISTADO, "o S2 abriu: não reconhecido (avistado)")
	check(cat.andar_bloqueado(no_s2, minerador) and not cat.andar_bloqueado(no_s2, pq), "a IA não manda o minerador sozinho (a pesquisadora pode ir)")
	check(minerador._andar_bloqueado(no_s2), "as jazidas do S2 não chamam o minerador")
	check(cat.precisa_confirmar(no_s2) == "S2", "a ordem pra lá pede confirmação")
	var feito := [false]
	check(hud.pergunta_descida(no_s2, func(): feito[0] = true), "pergunta (o diálogo)")
	check(hud._confirma != null and hud._confirma.visible, "o diálogo apareceu: %s" % (hud._confirma.dialog_text.left(60) if hud._confirma else "?"))
	hud._confirma.confirmed.emit()
	hud._confirma.hide()
	check(feito[0] and cat.descida_liberada.has("S2") and not cat.andar_bloqueado(no_s2, minerador), "confirmou: a descida liberada e a ordem dada")
	check(is_equal_approx(cat.mult_acidente(no_s2), cat.acidente_sem_reconhecimento) and is_equal_approx(cat.mult_acidente(dentro), 1.0), "lá dentro, acidentes x%.0f até o reconhecimento" % cat.acidente_sem_reconhecimento)
	var fl: Dictionary = cat.ficha_local("S2")
	check(fl.has("Perigos") and fl.has("Equipamento") and fl.has("Criaturas"), "a ficha do andar: %s" % [fl])
	cat.risco_reconhecimento = 1.0
	cat.risco_com_traje = 1.0
	var sinais := {"cri": 0, "and": 0}
	cat.criatura_estudada.connect(func(_id): sinais.cri += 1)
	cat.andar_reconhecido.connect(func(_id): sinais.and += 1)
	var campo := {"id": "S2", "pos": no_s2, "fase": "anotando", "t": 0.0, "lab": false}
	pq.injured = false
	cat.fim_da_anotacao(campo, pq)
	check(pq.injured, "o reconhecimento tem risco real (ferimento)")
	cat.estuda("S2", null)
	check(cat.reconhecido("S2") and is_equal_approx(cat.mult_acidente(no_s2), 1.0), "reconhecido: acidentes normais")
	check(sinais.and == 1, "sinal andar_reconhecido")
	cat.avista("magmante", false)
	cat.estuda("magmante", null)
	check(sinais.cri == 1, "sinal criatura_estudada")

	print("== G) missões")
	var ms = g("missoes")
	check(ms.valor_do_objetivo(["criatura", "", 2]) >= 3.0, "objetivo 'criatura' (quantas): %d" % int(ms.valor_do_objetivo(["criatura", "", 2])))
	check(ms.valor_do_objetivo(["reconhecer", "S2", 1]) == 1.0 and ms.valor_do_objetivo(["reconhecer", "S3", 1]) == 0.0, "objetivo 'reconhecer'")

	print("== H) save e save antigo")
	var dc: Dictionary = cat.get_save_data()
	cat.load_save_data({})
	check(cat.descida_liberada.is_empty(), "catálogo de save antigo: nenhuma descida liberada")
	cat.load_save_data(dc)
	check(cat.descida_liberada.has("S2"), "salvou e carregou a descida liberada")
	def.pede_patrulha("S3", 2)
	var dd: Dictionary = def.get_save_data()
	def.load_save_data({})
	check(def.patrulhas.is_empty(), "defesa de save antigo: nenhuma patrulha")
	def.load_save_data(dd)
	check(int(def.patrulhas.get("S3", 0)) == 2, "salvou e carregou a patrulha")
	var dw: Dictionary = pq.get_save_data()
	var xp1: int = pq.xp_pesquisa
	pq.xp_pesquisa = 0
	pq.load_save_data(dw)
	check(pq.xp_pesquisa == xp1, "salvou e carregou a experiência da pesquisadora (%d)" % xp1)
	var velho := dw.duplicate()
	velho.erase("xp_pesquisa")
	velho.erase("animo_descoberta")
	pq.load_save_data(velho)
	check(pq.xp_pesquisa == 0, "ipezinho de save antigo: xp 0")
	var sm = root.get_node("SaveManager")
	sm.save_game()
	var js = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
	check(js is Dictionary and not JSON.stringify(js).contains("corpos_criatura"), "os corpos não vão pro save")

	print("\nFALHAS: %d" % fails)
	quit()
