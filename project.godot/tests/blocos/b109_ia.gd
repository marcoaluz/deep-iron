extends SceneTree
## Bloco 109: IA — ESCOLHA POR PONTUAÇÃO, FUNÇÃO SECUNDÁRIA, PERIGO e CARONA. (A) O custo da estação: quanto ela tem, o que
## falta no armazém e o perigo (criatura perto) mudam a escolha. (B) A secundária: o engenheiro sem obra corta lenha (veste o
## lenhador), "nenhuma" desliga, a escolha à mão vale, fora do expediente / sem IA / com área não entra; quem vigiou a noite
## descansa. (C) Perigo: no AVISO da invasão quem não é guarda já recolhe; criatura perto = foge pra casa (e continua
## fugindo); na onda solar quem não tem cama vai pro ABRIGO mais perto, entra e sai quando a onda passa. (D) A carona: sem
## carregador, quem descarregou leva o material de uma obra perto; com carregador, não. (E) Save, save antigo, telemetria e o
## cartão do selecionado. RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
var main: Node
var t := 0.0
var fails := 0
var rodando := false
var hora := 9.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
	load("res://scripts/core/defense.gd").moradores_desligados = true
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func anda(s: float) -> void:
	var t0 := t
	while t - t0 < s:
		await process_frame


func espera(cond: Callable, max_s: float) -> bool:
	var t0 := t
	while not cond.call():
		if t - t0 > max_s:
			return false
		await process_frame
	return true


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func _process(delta: float) -> bool:
	t += delta
	if t > 400.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	var dn = g("day_night")
	if dn and hora >= 0.0:
		dn.time = dn.tempo_da_hora(hora)
	for w in ws():
		w.hunger = w.hunger_max
	var sun = g("sun")
	if sun:
		sun.wave_today = false
	if not rodando and t > 2.0:
		rodando = true
		roda()
	return false


func roda() -> void:
	var eco = g("economy")
	var hub = g("village_hub")
	var hud = g("hud")
	var def = g("defense")
	var arm = g("armazens")
	var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
	g("sun").season_wave_chance = nunca
	def.first_invasion_day = 999
	load("res://scripts/props/armazem.gd").limite_desligado = true
	while ws().size() < 10:
		eco.novo_ipezinho()
	await process_frame
	var w: Array = ws()
	for x in w:
		x.set_job("ocioso")
	var eng: Node = w[0]
	var min1: Node = w[1]
	eco.credits = 9999.0

	print("-- (A) escolha da estação por pontuação")
	var jaz: Node = null
	for j in get_nodes_in_group("minerios"):
		if j.has_method("fracao_restante") and j.is_usable() and String(j.tipo_extraido()) == "ferro":
			jaz = j
			break
	check(jaz != null, "achou uma jazida de ferro usável")
	if jaz:
		var cheia := float(jaz.ore_remaining)
		jaz.ore_remaining = jaz.ore_total
		var c_cheia: float = min1._custo_estacao(jaz, "minerios")
		jaz.ore_remaining = jaz.ore_total * 0.2
		var c_vazia: float = min1._custo_estacao(jaz, "minerios")
		check(c_cheia < c_vazia - 40.0, "a mais cheia custa menos (%.0f x %.0f)" % [c_cheia, c_vazia])
		jaz.ore_remaining = cheia
		arm.stock["ferro"] = 0.0
		arm._recount()
		var c_falta: float = min1._custo_estacao(jaz, "minerios")
		arm.stock["ferro"] = 500.0
		arm._recount()
		var c_sobra: float = min1._custo_estacao(jaz, "minerios")
		check(c_falta < c_sobra - 100.0, "o que FALTA no armazém pesa (sem ferro %.0f x com 500 %.0f)" % [c_falta, c_sobra])
		var bicho: Node2D = def._spawn("lumivoro")
		bicho.set_process(false)
		bicho.set_physics_process(false)
		bicho.global_position = (jaz as Node2D).global_position + Vector2(30, 0)
		var c_perigo: float = min1._custo_estacao(jaz, "minerios")
		check(c_perigo > c_sobra + 200.0, "criatura perto da estação = perigo (%.0f x %.0f)" % [c_perigo, c_sobra])
		var p0: Vector2 = min1.global_position
		bicho.queue_free()
		await process_frame
		min1.global_position = p0  # (ele está sem função e passeia: a distância mudaria entre os quadros)
		check(perto(min1._custo_estacao(jaz, "minerios"), c_sobra, 1.0), "sem a criatura, volta ao custo de antes")

	print("-- (B) função secundária")
	eng.set_job("engenheiro")
	await anda(0.3)
	check(eng.secundaria() == "lenhador" and eng.funcao_secundaria == "", "o engenheiro vem com a secundária automática: lenhador")
	eng.wake_decision()
	var cortou := await espera(func(): return eng.get_state() == "chopping", 8.0)
	check(cortou and eng.na_secundaria(), "sem obra, no expediente: vai cortar lenha (%s)" % eng.get_state())
	check(eng.outfit() == eng.JOB_OUTFIT.get("lenhador", "") , "veste a roupa do lenhador enquanto isso (%s)" % eng.outfit())
	var tem_madeira := await espera(func(): return float(eng.wood_carrying) > 0.0, 15.0)
	check(tem_madeira, "corta de verdade (madeira %.1f)" % float(eng.wood_carrying))
	eng.set_secundaria("nenhuma")
	eng.wake_decision()
	await anda(0.5)
	check(not eng.na_secundaria() and eng.outfit() == eng.JOB_OUTFIT.get("engenheiro", ""), "'nenhuma': volta ao engenheiro (%s)" % eng.get_state())
	eng.set_secundaria("minerador")
	eng.wake_decision()
	var minerou := await espera(func(): return eng.get_state() in ["mining", "storing"], 25.0)  # (antes leva a lenha da mão pro armazém)
	check(minerou and eng.secundaria() == "minerador", "escolhida à mão: minerador (%s)" % eng.get_state())
	eng.set_secundaria("")
	hora = 12.5  # almoço
	await anda(0.3)
	check(not eng._pode_secundaria(), "fora do expediente (almoço) a secundária não entra")
	hora = 9.0
	eng.auto_mode = false
	check(not eng._pode_secundaria(), "sem a IA (controle manual) não entra")
	eng.auto_mode = true
	w[2].set_job("ocioso")
	check(w[2].secundaria() == "" and not w[2]._pode_secundaria(), "sem função: nada de secundária (o jogador escolhe)")
	var g1: Node = w[3]
	g1.set_job("guarda")
	var pol = g("politicas")
	pol.forca("seguranca", "vigilancia")
	var dn = g("day_night")
	var dia0: int = dn.day
	dn.day = maxi(dia0, 3)
	check(g("schedule").vigiou_ontem(g1) and not g1._pode_secundaria(), "o guarda que vigiou a noite descansa (sem secundária)")
	pol.forca("seguranca", "padrao")
	dn.day = dia0
	g1.set_job("ocioso")

	print("-- (C) perigo")
	min1.set_job("minerador")
	def.first_invasion_day = dn.day
	def.start_day = 0
	var noite: bool = def.is_invasion_night(dn.day)
	def._warned_day = dn.day
	hora = 21.2
	await anda(0.3)
	check(noite and def.aviso_dado(), "noite de invasão com o aviso dado")
	check(min1._choose_state() == "home", "no AVISO quem não é guarda já recolhe (%s)" % min1._choose_state())
	def._warned_day = -1
	def.first_invasion_day = 999
	hora = 9.0
	await anda(0.3)
	var bicho2: Node2D = def._spawn("lumivoro")
	bicho2.set_process(false)
	bicho2.set_physics_process(false)
	bicho2.global_position = min1.global_position + Vector2(40, 0)
	check(min1._choose_state() == "home", "criatura perto: larga tudo e corre pra casa")
	bicho2.queue_free()
	await process_frame
	check(min1._choose_state() == "home" and min1._fuga_t > 0.0, "a criatura sumiu, mas ele ainda foge um tempo (sem ir e voltar)")
	min1._fuga_t = 0.0
	check(min1._choose_state() != "home", "passou o tempo: volta ao trabalho (%s)" % min1._choose_state())
	# onda solar: quem não tem cama vai pro abrigo mais perto
	var sem_cama: Node = w[6]
	if sem_cama.has_home():  # (simula quem chegou sem cama: dorme do lado de fora)
		sem_cama._home.release_slot(sem_cama)
		sem_cama._home = null
	if sem_cama and sem_cama._abrigo_mais_perto() == null:
		var casa: Node2D = hub.spawn_house(spot_near(sem_cama.global_position + Vector2(90, 40)), "CasaAbrigoTeste")
		if casa.get("built") != null:
			casa.built = true
		await process_frame
	var abrigo: Node2D = sem_cama._abrigo_mais_perto() if sem_cama else null
	check(sem_cama != null and abrigo != null, "tem alguém sem cama e um abrigo (casa/taverna) na vila")
	if sem_cama and abrigo:
		sem_cama.set_job("lenhador")
		var sun = g("sun")
		sun.wave_left = 60.0
		sem_cama.wake_decision()
		await process_frame
		check(sem_cama._destino_onda() == "abrigo", "na onda solar, sem cama: o ABRIGO mais perto (antes: dormia do lado de fora)")
		var entrou := await espera(func(): return sem_cama._abrigado_em != null and sem_cama._inside, 25.0)
		check(entrou and sem_cama.get_state() == "abrigo", "chegou e entrou no abrigo (%s)" % sem_cama.get_state())
		var exposto: bool = not sem_cama._inside
		check(not exposto, "dentro: a onda não pega ele")
		sun.wave_left = 0.0
		sun._end_wave()
		var saiu := await espera(func(): return sem_cama._abrigado_em == null and not sem_cama._inside, 8.0)
		check(saiu, "a onda passou: sai do abrigo e volta ao trabalho (%s)" % sem_cama.get_state())

	# o prato preso (defeito do Bloco 84 achado na medição): servido, perdeu o lugar no comedouro, parado longe dele
	var faminto: Node = w[7]
	faminto.set_job("caçador")
	faminto._release_station()
	faminto._set_state("eating")
	faminto._servido = true
	faminto._prato = 5.0
	faminto._moving = false
	var est: String = faminto._choose_state()
	check(est != "eating" and faminto._prato == 0.0, "prato pela metade sem lugar no comedouro: larga e volta ao trabalho (antes: preso pra sempre) — %s" % est)

	print("-- (D) a carona (sem carregador)")
	arm.wood_stored = 200.0
	arm._recount()
	var pos := spot_near(arm.global_position + Vector2(120, 60))
	var obra: Node = null
	if pos != Vector2.INF and g("morale")._confirm_taverna(pos):
		for c in get_nodes_in_group("canteiros"):
			if c.kind == "taverna":
				obra = c
	check(obra != null, "encomendou uma taverna (precisa de madeira)")
	var lg = g("logistica")
	check(not lg.tem_carregador(), "não há carregador")
	var lenh: Node = w[4]
	lenh.set_job("lenhador")
	lenh.wood_carrying = 0.0
	lenh.global_position = arm.global_position + Vector2(0, 30)
	lenh._ai_state = "hauling"
	lenh._carona_cd = 0.0
	check(obra != null and lenh._quer_carona() and lenh._carona and not lenh._carga.is_empty(), "descarregou perto do armazém: pegou a carona pra obra")
	if lenh._carona:
		lenh._desfaz_carga(true)
		lenh._carona = false
	var carr: Node = w[5]
	carr.set_job("carregador")
	await process_frame
	lenh._ai_state = "hauling"
	lenh._carona_cd = 0.0
	check(lg.tem_carregador() and not lenh._quer_carona(), "com carregador na vila: sem carona (é trabalho dele)")
	carr.set_job("ocioso")

	print("-- (E) save, telemetria e cartão")
	eng.set_secundaria("caçador")
	var d: Dictionary = JSON.parse_string(JSON.stringify(eng.get_save_data()))
	eng.set_secundaria("")
	eng.load_save_data(d)
	check(eng.funcao_secundaria == "caçador", "a secundária vai no save")
	d.erase("funcao_secundaria")
	eng.load_save_data(d)
	check(eng.funcao_secundaria == "", "save antigo: automática pela função")
	d["funcao_secundaria"] = "padeiro"
	eng.load_save_data(d)
	check(eng.funcao_secundaria == "", "valor estranho: automática")
	var tel := load("res://scripts/core/telemetria.gd")
	for col in ["ociosos_expediente", "na_secundaria", "mortes_bobas", "caronas"]:
		check((tel.COLUNAS as Array).has(col), "telemetria: coluna %s" % col)
	var telem = g("telemetria")
	if telem:
		telem.registra()
		var f := FileAccess.open(telem.arquivo, FileAccess.READ)
		var ultima := ""
		while f and not f.eof_reached():
			var l := f.get_line()
			if l != "":
				ultima = l
		check(ultima.split(",").size() == (tel.COLUNAS as Array).size(), "a linha tem uma coluna por nome (%d x %d)" % [ultima.split(",").size(), (tel.COLUNAS as Array).size()])
	hud._update_portrait([eng])
	check(hud._portrait_sec.visible and hud._portrait_sec.text.begins_with("Secundária:"), "o cartão mostra a secundária (%s)" % hud._portrait_sec.text)
	var antes: String = eng.funcao_secundaria
	hud._troca_secundaria()
	check(eng.funcao_secundaria != antes, "o botão troca (%s -> %s)" % [antes, eng.funcao_secundaria])

	Engine.time_scale = 1.0
	print("\nFALHAS: %d" % fails)
	quit()


func perto(a: float, b: float, eps: float = 0.001) -> bool:
	return absf(a - b) <= eps
