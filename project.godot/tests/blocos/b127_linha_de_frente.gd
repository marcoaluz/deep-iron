extends SceneTree
## Bloco 127: LINHA DE FRENTE, PORTÃO COMO SEGUNDA DEFESA E INVASÃO DENTRO DA VILA. RODAR SÓ COM APPDATA ISOLADO.
##   (A) o guarda fica FORA do portão FECHADO (o postigo) e luta; (B) a criatura prefere o guarda ao portão, e o portão só apanha
##   sem defensor; (C) o recuo pelo postigo; (D) o invasor que passou rouba minério e itens (com teto); (E) a Matriarca
##   danifica uma casa até as ruínas (moradores sem cama), o Centro nunca vira ruína, o conserto custa a fração do original;
##   (F) o médico espera se há criatura perto do caído; (G) os banners; (H) save (e save antigo); (I) a igreja de enfeite saiu.
var main: Node
var def: Node
var est: Node
var eco: Node
var gate: Node2D
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
	load("res://scripts/core/defense.gd").moradores_desligados = true  # (Bloco 103: ninguém mora no fundo aqui)
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


## Espera `cond` (Callable -> bool) por até `max_s` segundos REAIS (o jogo anda em câmera rápida).
func _espera(cond: Callable, max_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) / 1000.0 < max_s:
		_noite()
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _noite() -> void:
	var dn := g("day_night")
	dn.time = dn.day_duration + 5.0  # a noite o tempo todo (a cada quadro)


func _limpa_criaturas() -> void:
	for c in get_nodes_in_group("criaturas"):
		if is_instance_valid(c) and c.is_alive():
			c.die(false)
	for c in get_nodes_in_group("corpos_criatura"):
		c.queue_free()


func _chao(p: Vector2) -> Vector2:
	var world: Node2D = g("village_hub").get_parent()
	return NavigationServer2D.map_get_closest_point(world.get_world_2d().navigation_map, p)


func _fora(dist: float) -> Vector2:
	return _chao(gate.global_position - gate.inside_dir() * dist)


func _dentro(dist: float) -> Vector2:
	return _chao(gate.global_position + gate.inside_dir() * dist)


func _guarda(nome_idx: int, hp_cheio := true) -> Node:
	var w: Node = get_nodes_in_group("ipezinhos")[nome_idx]
	w.set_job("guarda")
	w.combat_skill = 1.0
	w.weapon = "porrete"
	w.weapon_durability = 999.0
	if hp_cheio:
		w.combat_hp = w.guard_max_hp()
	return w


func _roda() -> void:
	await _frames(5)
	def = g("defense")
	est = g("estruturas")
	eco = g("economy")
	g("eventos").ligado = false
	g("pedidos").ligado = false
	check(def != null and est != null and eco != null, "o nó Estruturas existe na cena")
	gate = g("barricadas")
	gate.level = 2
	gate.hp = gate.max_hp()
	gate._update_visual()
	gate._snap = true
	var tel := g("telemetria")
	Engine.time_scale = 6.0

	print("== (A) o guarda FORA do portão FECHADO (o postigo)")
	for w in get_nodes_in_group("ipezinhos").slice(1):
		w.set_job("minerador")
	var gd := _guarda(0)
	def.invasion_active = true  # (a invasão "ligada" sem criatura nenhuma)
	_noite()
	await _frames(4)
	var dn := g("day_night")
	var fechou := await _espera(func(): return gate.fechado(), 20.0)
	check(fechou and gate.fechado() and gate.is_standing(), "o portão da floresta está FECHADO de noite")
	var post_fora: Vector2 = def.guard_post_ativo(gd)
	var post_dentro: Vector2 = def.guard_post(gd)
	check(gate.lado_de(post_fora) < 0, "o posto da linha de frente fica FORA da paliçada")
	check(gate.lado_de(post_dentro) > 0, "o posto de dentro (guard_post) continua dentro (o do recuo)")
	check(def.linha_de_frente_ativa(), "a linha de frente vale (tem portão da floresta)")
	check(post_fora.distance_to(gate.global_position) > def.frente_dist * 0.5, "e à frente do portão (%d px)" % roundi(post_fora.distance_to(gate.global_position)))
	check(gd.pode_postigo() and not get_nodes_in_group("ipezinhos")[1].pode_postigo(), "só o guarda passa pelo postigo (o mineiro não)")
	check(gate.separa(gd.global_position, post_fora, gd) == false and gate.separa(_dentro(60.0), _fora(60.0)) == true,
		"separa(): o portão fechado separa a vila da floresta, menos pro guarda")
	gd.global_position = _dentro(70.0)
	await _frames(2)
	var chegou := await _espera(func(): return gd.global_position.distance_to(post_fora) < 28.0, 60.0)
	check(chegou and gate.lado_de(gd.global_position) < 0, "o guarda atravessou pelo postigo e está fora (%s -> %s)" % [gd.global_position.round(), post_fora.round()])
	check(gate.fechado(), "...com o portão FECHADO o tempo todo")
	check(gd.get_state() == "guard", "estado: de guarda")
	var vista := false
	# o entreaberto: um guarda no raio do postigo faz o portão aparecer meio aberto
	gd.global_position = gate.postigo_pos()
	gate._postigo_t = 0.0
	gate._vigia_postigo()
	vista = gate.abertura_visual() >= 0.5 and gate.passagem_livre() == false
	check(vista, "o portão aparece ENTREABERTO quando o guarda cruza (visual %.2f), sem abrir as faixas dos outros" % gate.abertura_visual())
	gd.global_position = post_fora

	print("== (B) a criatura prefere o guarda ao portão")
	var hp0: float = gate.hp
	var c: Node2D = def._spawn("lumivoro")
	c.global_position = _fora(150.0)
	c.speed = 30.0
	c.max_hp = 400.0
	c.hp = 400.0
	await _frames(3)
	var viu := await _espera(func(): return c._target == gd, 10.0)
	check(viu, "o Lumívoro mira o GUARDA (alvo: %s)" % (c._target.name if c._target else "nenhum"))
	check(gate.hp == hp0, "...e o portão não apanhou")
	await _espera(func(): return gd._foe == c or c.hp < 400.0, 20.0)
	check(gd._foe == c or c.hp < 400.0, "o guarda luta com ele (lá fora, portão fechado): vida %d/400" % roundi(c.hp))
	check(gate.hp == hp0, "enquanto o guarda está de pé o portão segue inteiro (%d)" % roundi(gate.hp))
	# sem defensor: o portão passa a apanhar
	gd.set_job("minerador")
	gd._foe = null
	var alvo_portao := await _espera(func(): return c._target == gate, 10.0)
	check(alvo_portao, "sem defensor por perto, o alvo vira o PORTÃO")
	var bateu := await _espera(func(): return gate.hp < hp0, 40.0)
	check(bateu, "...e o portão apanha (%d -> %d)" % [roundi(hp0), roundi(gate.hp)])
	_limpa_criaturas()
	gate.hp = gate.max_hp()

	print("== (C) o recuo pelo postigo")
	gd = _guarda(0)
	gd.global_position = post_fora
	await _frames(3)
	var c2: Node2D = def._spawn("lumivoro")
	c2.global_position = _fora(140.0)
	c2.speed = 20.0
	c2.max_hp = 4000.0
	c2.hp = 4000.0
	await _espera(func(): return gd._foe != null, 20.0)
	gd.combat_hp = gd.guard_max_hp() * 0.2  # ferido (abaixo de guard_recua_pct)
	var recuou := await _espera(func(): return gd.recuando, 10.0)
	check(recuou, "ferido (20%%), o guarda RECUA (recuando=%s)" % str(gd.recuando))
	var entrou := await _espera(func(): return gate.lado_de(gd.global_position) > 0, 60.0)
	check(entrou, "e entra pelo postigo, com o portão fechado (%s)" % gd.global_position.round())
	check(gate.fechado(), "...portão fechado")
	var vida_antes: float = gd.combat_hp
	await _espera(func(): return gd.combat_hp > vida_antes + 3.0 or not gd.recuando, 40.0)
	check(gd.combat_hp > vida_antes or not gd.recuando, "regenera a vida de luta lá dentro (%.1f -> %.1f)" % [vida_antes, gd.combat_hp])
	check(c2._target == gate or c2._target == null or c2._target.is_in_group("barricadas") or c2._target != gd,
		"a criatura não corre atrás de quem está atrás da paliçada (alvo: %s)" % (c2._target.name if c2._target else "nenhum"))
	var voltou := await _espera(func(): return not gd.recuando and gd.combat_hp / gd.guard_max_hp() >= def.guard_volta_pct - 0.02, 120.0)
	check(voltou, "recuperou (%d%%) e volta pra linha de frente" % roundi(100.0 * gd.combat_hp / gd.guard_max_hp()))
	_limpa_criaturas()

	print("== (D) o invasor que passou rouba minério e itens")
	var arm: Node = g("armazens")
	arm.limite_desligado = true
	arm.stock["ferro"] = 300.0
	arm.stock["cobre"] = 100.0
	arm._recount()
	def.start_invasion()  # (começa a noite: zera os contadores e guarda o teto do saque)
	def._spawn_queue = []
	var teto: float = def._saque_teto
	check(teto >= def.saque_teto_piso and teto <= 0.30 * (arm.total_stored + 50.0) + def.saque_teto_piso, "o teto do saque da noite: %d (piso %d)" % [roundi(teto), roundi(def.saque_teto_piso)])
	gate.hp = gate.max_hp()  # (a criatura da etapa C pode ter derrubado ele: volta inteiro)
	gate.damage(gate.hp + 1.0)  # o portão cai
	check(def.portao_cedeu_noite and not gate.is_standing(), "o portão cedeu (contagem da noite + banner)")
	var ferro0: float = float(arm.stock.get("ferro", 0.0))
	var c3: Node2D = def._spawn("lumivoro")
	c3.global_position = arm.global_position + Vector2(0, 30)
	c3.inside = true
	c3._gate = null
	c3.max_hp = 9999.0
	c3.hp = 9999.0
	c3.damage = 0.0
	for w in get_nodes_in_group("ipezinhos"):  # (ninguém acordado perto: ele vai no armazém)
		w.global_position = arm.global_position + Vector2(900, 900)
	var roubou := await _espera(func(): return def.saque_noite > 0.0, 60.0)
	check(roubou, "o Lumívoro que passou o portão ROUBOU o armazém (%.1f levado)" % def.saque_noite)
	check(float(arm.stock.get("ferro", 0.0)) < ferro0, "o minério do armazém diminuiu (%d -> %d)" % [roundi(ferro0), roundi(float(arm.stock.get("ferro", 0.0)))])
	await _espera(func(): return def._saque_noite_cheio(), 90.0)
	check(def.saque_noite <= def._saque_teto + c3.steal_amount, "o roubo para no TETO da noite (%.1f de %.1f)" % [def.saque_noite, def._saque_teto])
	var sq: float = def.saque_noite
	await _frames(60)
	check(is_equal_approx(def.saque_noite, sq), "...e não leva mais depois do teto")
	check(def.invasores_dentro().has(c3), "ele conta como invasor DENTRO da vila")
	# itens: sem minério, o invasor leva barras
	arm.stock = {}
	arm._recount()
	arm.add_item("barra_ferro", 40.0)
	def._saque_teto = 100.0
	def.saque_noite = 0.0
	def._estoque_cache = 40.0
	var b0 := float(eco.quantidade("barra_ferro"))
	var levou: float = def.saque_invasor(arm, 3.0)
	check(levou > 0.0 and float(eco.quantidade("barra_ferro")) < b0, "sem minério, leva ITENS (barra de ferro %d -> %d)" % [roundi(b0), roundi(float(eco.quantidade("barra_ferro")))])
	_limpa_criaturas()

	print("== (E) a Matriarca danifica uma casa")
	var casa: Node2D = get_nodes_in_group("casas")[0]
	var morador: Node = null
	for w in get_nodes_in_group("ipezinhos"):
		if w.has_home() and w._home == casa:
			morador = w
	if morador == null:
		morador = get_nodes_in_group("ipezinhos")[2]
		morador._home = null
		morador._claim_home()
		if morador._home != casa:  # a cama dele é de outra casa: usa a casa dele
			casa = morador._home
	check(morador != null and morador.has_home() and morador._home == casa, "tem um morador com cama na casa (%s)" % (morador.display_name if morador else "?"))
	var camas0: int = casa.beds_total()
	var livres0: int = eco.free_beds()
	check(camas0 > 0, "a casa tem camas (%d)" % camas0)
	def._spawn_boss()
	var boss: Node2D = def._boss
	check(boss != null and boss.is_in_group("chefes"), "a Matriarca nasceu")
	boss.inside = true
	boss._gate = null
	boss.max_hp = 99999.0
	boss.hp = 99999.0
	boss.global_position = casa.global_position + Vector2(0, 40)
	boss._target = casa
	check(est.pode_quebrar(boss), "a Matriarca pode quebrar prédio")
	check(est.dano_do_golpe(boss) > est.dano_do_golpe(def._spawn("lumivoro")) * 3.0, "o golpe dela é muito maior que o do Lumívoro comum")
	var cond0: float = est.condicao_de(casa)
	var inicio_dano := await _espera(func(): return _mira(boss, casa) and est.condicao_de(casa) < 0.99, 40.0)
	check(inicio_dano and cond0 >= 0.999, "a casa foi ATINGIDA (condição %.2f)" % est.condicao_de(casa))
	var ruina := await _espera(func(): return _mira(boss, casa) and est.em_ruina(casa), 90.0)
	check(ruina, "a casa caiu em RUÍNAS")
	check(casa.beds_total() == 0 and not casa.has_free_slot_for(morador), "em ruínas: sem camas (beds_total 0)")
	check(eco.free_beds() <= livres0 - 0 and not morador.has_home() or morador._home != casa, "o morador ficou SEM a cama dela (home: %s)" % str(morador._home))
	check(not morador.injured and morador.hunger >= 0.0, "quem morava lá não morreu nem se machucou (só perdeu a cama)")
	_limpa_criaturas()
	# a estação em ruínas some da escolha da IA
	var lab: Node = null
	for gname in ["oficinas", "laboratorios", "fornalhas", "arsenais", "carpintarias", "campos"]:
		var l := get_nodes_in_group(gname)
		if not l.is_empty():
			lab = l[0]
			break
	if lab != null:
		est._integ(lab, true).gasta(1.0)
		check(est.em_ruina(lab), "uma estação (%s) pode cair em ruínas" % lab.name)
		check(get_nodes_in_group("ipezinhos")[3]._find_best_station(lab.get_groups()[0] if false else _grupo_de(lab)) != lab, "a IA não escolhe a estação em ruínas")
		est._integ(lab, false)._desgaste.restaura()
	# o armazém em ruínas não recebe mais, mas o que tem dentro continua lá
	var cap_antes: float = arm.espaco_cat("minerio")
	est._integ(arm, true).gasta(1.0)
	check(arm.em_ruina() and arm.espaco_cat("minerio") == 0.0, "armazém em ruínas: não recebe mais (espaço %.0f -> 0)" % cap_antes)
	est._integ(arm, false)._desgaste.restaura()
	check(arm.espaco_cat("minerio") > 0.0, "...e volta a receber depois do conserto")
	# o Centro da Vila nunca vira ruína
	var hub: Node2D = g("village_hub")
	def._spawn_boss()
	var big: Node2D = def._boss
	big.inside = true
	for i in 40:
		est.golpe(big, hub)
	check(not est.em_ruina(hub) and est.condicao_de(hub) >= 1.0 - est.centro_dano_max - 0.001,
		"o Centro da Vila só perde até %d%% (condição %.2f)" % [roundi(est.centro_dano_max * 100.0), est.condicao_de(hub)])
	big.die(false)
	_limpa_criaturas()
	# o conserto: custo = fração do original, pelo mecânico ou engenheiro
	var integ: Node = est.integridade_de(casa)
	var custo: Array = integ.manut_custo()
	var base: Array = est.custo_base["casa"]
	check(custo[0] == ceili(float(base[0]) * est.ruina_custo_pct) and custo[1] == ceili(float(base[1]) * est.ruina_custo_pct),
		"a reconstrução custa %d%% do original (%d cr, %d ferro)" % [roundi(est.ruina_custo_pct * 100.0), custo[0], custo[1]])
	var manut := g("manutencao")
	eco.credits = 5000.0
	arm.stock["ferro"] = 500.0
	arm.add_item("barra_ferro", 300.0)
	arm.wood_stored = 500.0
	arm._recount()
	while get_nodes_in_group("ipezinhos").size() < 5:  # (a Matriarca pode ter ferido gente; garante o elenco)
		eco.novo_ipezinho("menina")
	await _frames(2)
	var mec: Node = get_nodes_in_group("ipezinhos")[1]
	mec.injured = false
	mec.set_job(mec.ROLE_MECHANIC)
	var cr0: float = eco.credits
	manut._tenta_consertos()
	var obra: Node = manut.conserto_de(integ)
	check(obra != null, "com mecânico e material, a Manutenção abre a OBRA de reconstrução (falta: '%s')" % manut.conserto_falta(integ))
	check(is_equal_approx(cr0 - eco.credits, float(custo[0])), "...e paga só o custo da fração (%d cr)" % roundi(cr0 - eco.credits))
	if obra != null:
		obra.obra_work(9999.0)
	check(not est.em_ruina(casa) and est.condicao_de(casa) > 0.99, "pronto: a casa voltou (condição %.2f)" % est.condicao_de(casa))
	check(casa.beds_total() == camas0, "...com as camas de volta (%d)" % casa.beds_total())

	print("== (F) o médico espera se há criatura perto do caído")
	var doc: Node = get_nodes_in_group("ipezinhos")[1]
	doc.set_job(doc.ROLE_DOCTOR)
	var caido: Node = get_nodes_in_group("ipezinhos")[3]
	caido.downed = true
	caido.global_position = _fora(90.0)
	var perto: Node2D = def._spawn("lumivoro")
	perto.global_position = caido.global_position + Vector2(-40, 0)
	perto.speed = 0.0
	check(doc._pick_rescue() == null, "com criatura viva perto do caído, o médico NÃO sai pra resgatar")
	perto.die(false)
	await _frames(2)
	check(doc._pick_rescue() == caido, "sem criatura por perto, ele vai buscar")
	check(doc.pode_postigo(), "...e passa pelo postigo (médico em resgate)")
	caido.downed = false
	doc._rescue = null
	caido._rescuer = null
	_limpa_criaturas()

	print("== (G) os banners e os sinais")
	def.start_invasion()
	def._spawn_queue = []
	var gd2 := _guarda(0)
	gd2.global_position = def.guard_post_ativo(gd2)
	gd2._ai_state = "guard"
	def._dentro_t = 0.0
	def._frente_tick(0.1)
	check(def._frente_avisada, "o banner 'Os guardas seguram o portão' foi dado")
	var intruso: Node2D = def._spawn("lumivoro")
	intruso.inside = true
	def._dentro_t = 0.0
	def._frente_tick(0.1)
	check(def._dentro_avisado, "o banner 'Invasores dentro da vila' foi dado")
	var hud := g("hud")
	hud._refresh()
	check(def.invasores_dentro().has(intruso), "o alerta da coluna da direita conta o invasor dentro")
	_limpa_criaturas()
	def.end_invasion()
	check(def.last_result.has("guardas_caidos") and def.last_result.has("portao_cedeu") and def.last_result.has("saque") and def.last_result.has("predios_danificados"),
		"o resultado da noite guarda guardas caídos, portão, saque e prédios feridos (telemetria)")
	check((tel.COLUNAS as Array).has("noite_guardas_caidos") and (tel.COLUNAS as Array).has("predios_ruinas"), "a telemetria tem as colunas novas")

	print("== (H) o save")
	est._integ(casa, true)._desgaste.condicao = 0.55
	var sm = root.get_node("SaveManager")
	check(sm.save_game("teste127"), "salvou com um prédio ferido")
	var d: Dictionary = est.get_save_data()
	check((d.predios as Array).size() >= 1 and d.has("ruinas"), "o save das estruturas tem os feridos e as ruínas")
	est._integ(casa, true)._desgaste.restaura()
	est.load_save_data(d)
	check(is_equal_approx(est.condicao_de(casa), 0.55), "carregou: a casa volta com a condição de antes (%.2f)" % est.condicao_de(casa))
	est.load_save_data({})  # save antigo: nenhuma chave
	check(is_equal_approx(est.condicao_de(casa), 1.0) and est.feridos().is_empty(), "save antigo (sem 'estruturas'): tudo 100%")
	est.load_save_data({"predios": [123, "x", {"path": "/root/nao_existe", "pos": [99999.0, 99999.0], "d": {"c": 0.2, "q": false}}], "ruinas": -4})
	check(est.feridos().is_empty() and est.ruinas_total == 0, "save quebrado/sem o prédio: ignora sem erro")
	var texto := FileAccess.get_file_as_string("res://scripts/core/save_manager.gd")
	check(texto.find("\"estruturas\"") >= 0 and texto.find("Bloco 127") >= 0, "o save_manager documenta e guarda a chave 'estruturas'")

	print("== (I) a igreja de enfeite saiu do mapa; os textos")
	var env := g("environment")
	var deco: Array = env.get_script().get_script_constant_map().get("MAP_DECOR_V3", [])
	check(not deco.is_empty() and not deco.any(func(e): return String(e[0]) == "igreja_0"), "a igreja de enfeite (igreja_0) não está mais na decoração da vila")
	var cat := FileAccess.get_file_as_string("res://data/catalogo/textos.txt")
	check(cat.find("ROUBA minério e itens") >= 0 and cat.find("DESTRÓI prédios") >= 0, "a ficha da criatura diz o que ela faz dentro da vila")

	Engine.time_scale = 1.0
	print("FALHAS: %d" % fails)
	quit()


## Mantém o alvo da criatura no prédio (a IA dela escolhe sozinha; o teste quer o golpe NA casa). Retorna true.
func _mira(c: Node2D, alvo: Node2D) -> bool:
	if is_instance_valid(c) and c.is_alive():
		c._target = alvo
		c._retarget = 5.0
	return true


## O primeiro grupo de estação que esse nó tem (pro _find_best_station).
func _grupo_de(n: Node) -> String:
	for gname in ["oficinas", "laboratorios", "fornalhas", "arsenais", "carpintarias", "campos"]:
		if n.is_in_group(gname):
			return gname
	return ""
