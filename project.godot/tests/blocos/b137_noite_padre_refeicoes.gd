extends SceneTree
## Bloco 137: O SOM DA NOITE, A CHEGADA DO PADRE E AS REFEIÇÕES DO PADRE E DOS GUARDAS. RODAR SÓ COM APPDATA ISOLADO.
##   (1) a noite: o loop da floresta à noite é quase silêncio grave (sem agudos: medido no ARQUIVO), a atmosfera vem dos
##       sons pontuais novos (vento distante, galho, grilo isolado) e o amanhecer não toca mais; F3 > Som ouve as candidatas;
##   (2) o padre chega ferido pelo portão (de fora), com o banner, o balão e o diário contando a história, vai pra
##       enfermaria e só assume a função depois do tratamento; um padre só;
##   (3) o padre fica DENTRO da igreja e sai pra janta e a hora social; os guardas de vigia se revezam (metade janta,
##       metade no posto, e trocam); na invasão, todos no posto.
var fails := 0
var main: Node


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


func _roda() -> void:
	await _frames(2)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	await _frames(8)
	var eco := g("economy")
	eco.credits = 9999.0
	for i in 6:
		eco.novo_ipezinho("menina" if i % 2 == 0 else "menino")
	await _frames(4)
	_som()
	await _padre()
	await _refeicoes()
	print("FALHAS: %d" % fails)
	quit()


# ------------------------------------------------------------ (1) o som da noite
## RMS e a razão "diferença entre amostras / RMS" dos primeiros segundos de um WAV de 16 bits (a razão sobe com os agudos:
## o chiado de antes passava de 0,5; um tom grave fica perto de 0,05).
func _medida(caminho: String) -> Vector2:
	var b := FileAccess.get_file_as_bytes(caminho)
	if b.size() < 44:
		return Vector2(-1, -1)
	var ch := b.decode_u16(22)
	var i := 12
	var ini := -1
	var tam := 0
	while i + 8 <= b.size():
		var id := b.slice(i, i + 4).get_string_from_ascii()
		var n := b.decode_u32(i + 4)
		if id == "data":
			ini = i + 8
			tam = n
			break
		i += 8 + n + (n % 2)
	if ini < 0:
		return Vector2(-1, -1)
	var amostras := mini(tam / 2, 24000 * 4 * ch)
	var soma := 0.0
	var dif := 0.0
	var ant := 0.0
	var k := 0
	var j := 0
	while j < amostras:
		var v := float(b.decode_s16(ini + j * 2)) / 32768.0  # (só o 1º canal)
		soma += v * v
		if k > 0:
			dif += (v - ant) * (v - ant)
		ant = v
		k += 1
		j += ch
	var rms := sqrt(soma / maxf(k, 1))
	return Vector2(20.0 * log(maxf(rms, 1e-9)) / log(10.0), sqrt(dif / maxf(k - 1, 1)) / maxf(rms, 1e-9))


func _som() -> void:
	print("== (1) o som da noite")
	var Slots = load("res://scripts/core/audio_slots.gd")
	var s: Dictionary = Slots.slot("ambiencia/floresta_noite")
	check(float(s.get("db", 0.0)) <= -12.0 and "almost complete silence" in String(s.get("prompt", "")) and "no hiss" in String(s.get("prompt", "")),
		"o slot da noite virou quase silêncio (db %s, prompt novo: sem chiado, sem insetos contínuos)" % s.get("db"))
	var m := _medida(ProjectSettings.globalize_path("res://assets/audio/ambiencia/floresta_noite.wav"))
	check(m.x > -60.0 and m.y < 0.2, "o arquivo é um tom grave, sem agudos (rms %.1f dBFS, razão de agudos %.3f; o chiado de antes passava de 0,5)" % [m.x, m.y])
	for id in ["pontuais/vento_distante", "pontuais/galho_estala", "pontuais/grilo_isolado"]:
		var p: Dictionary = Slots.slot(id)
		var tem := FileAccess.file_exists("res://assets/audio/%s_0.wav" % id) and FileAccess.file_exists("res://assets/audio/%s_1.wav" % id)
		check(String(p.get("tipo", "")) == "pontual" and (p.get("ctx", []) as Array).has("noite") and tem,
			"%s: som solto da noite, espaçado %s s, com os 2 arquivos" % [id, p.get("intervalo")])
	var grilo: Dictionary = Slots.slot("pontuais/grilo_isolado")
	check(int((grilo.intervalo as Array)[0]) >= 30, "o grilo é isolado (de %s em %s s, nunca contínuo)" % grilo.intervalo)
	var au := root.get_node("Audio")
	check(au.get("stinger_amanhecer") == false, "o som do amanhecer saiu (stinger_amanhecer = false)")
	var sun := g("sun")
	check(sun != null and sun.has_signal("season_changed"), "o aviso da troca de estação continua (sun.season_changed + o aviso no canto)")
	# F3 > Som: as candidatas
	var Painel = load("res://scripts/ui/sons_ativos_panel.gd")
	var cands: Array = Painel.candidatas("ambiencia/floresta_noite")
	if cands.is_empty():
		print("  (sem audio_candidatos/ nesta máquina: o painel diz como gerar)")
	else:
		check(cands.size() >= 3, "F3 > Som acha as %d candidatas da noite" % cands.size())
		check(au.prova_ambiencia("noite", String(cands[1])) and au.em_prova("noite") == String(cands[1]), "\"Ouvir\" troca o loop da noite pela candidata #1")
		var pn = Painel.new()
		root.add_child(pn)
		pn.abre()
		check(pn.find_children("Ouvir_*", "Button", true, false).size() == cands.size() and pn.find_child("VoltarAoJogo", true, false) != null,
			"o painel tem um \"Ouvir\" por candidata e o \"Voltar ao do jogo\"")
		pn.queue_free()
		check(au.prova_ambiencia("noite", "") and au.em_prova("noite") == "", "\"Voltar ao do jogo\" põe o arquivo do jogo de volta")


# ------------------------------------------------------------ (2) a chegada do padre
func _padre() -> void:
	print("== (2) o padre chega ferido pelo portão")
	var cal := g("calendario")
	var hub: Node2D = g("village_hub")
	var portao: Node2D = g("barricadas")
	hub.level = maxi(int(hub.level), int(cal.padre_estagio))
	var w: Node2D = cal.chega_padre()
	await _frames(2)
	check(w != null and w.is_priest() and String(w.display_name) == String(cal.padre_nome), "o Padre Bento chegou com a função de padre")
	if portao:
		check(portao.lado_de(w.global_position) != portao.lado_de(hub.global_position), "ele aparece do lado de FORA do portão (entra pela paliçada)")
	check(w.injured and String(w.injury_cause) == "fuga" and String(w.injury_severity) == "leve", "ferido de leve: fugiu de uma criatura")
	check(float(w._care_left) > 1.0e6 and is_equal_approx(float(w._recovery_left), cal.padre_tratamento_s), "não piora no caminho; o leito segura %d s" % int(cal.padre_tratamento_s))
	var achou := false
	for l in g("hud").find_children("*", "Label", true, false):
		if "cambaleando" in String((l as Label).text):
			achou = true
	check(achou, "o banner conta a história (\"entrou cambaleando pelo portão… fugiu de uma criatura\")")
	var diary := g("diary")
	check(diary.has_page("padre") and "criatura" in String(diary.entrada("padre").text), "a linha do diário conta a fuga")
	check(w._choose_state() == "infirmary" if not get_nodes_in_group("enfermarias").is_empty() else true, "vai direto pra enfermaria (estado: %s)" % w._choose_state())
	w._heal()
	await _frames(2)
	check(not w.injured and w.is_priest(), "tratado: assume a função")
	# um padre só
	cal.padre_chegou = false
	var w2: Node2D = cal.chega_padre()
	await _frames(1)
	check(w2 != null and not w2.is_priest() and cal.padre() == w, "a vila já tinha padre: o segundo chega sem a função (um padre só)")
	w2._heal()


# ------------------------------------------------------------ (3) refeições do padre e dos guardas
func _refeicoes() -> void:
	print("== (3) o padre na igreja e na janta; os guardas em revezamento")
	var cal := g("calendario")
	var hub: Node2D = g("village_hub")
	var dn := g("day_night")
	var sched := g("schedule")
	var def := g("defense")
	if cal.igreja() == null:
		hub.spawn_igreja(hub.global_position + Vector2(320, 220))
	await _frames(2)
	var ig: Node2D = cal.igreja()
	var pd: Node2D = cal.padre()
	check(ig != null and pd != null, "igreja pronta e o padre na vila")
	if dn.e_domingo():
		dn.day += 1
	dn.time = dn.tempo_da_hora(10.0)
	pd.global_position = ig.altar_pos()
	var dentro := false
	for i in 400:
		await process_frame
		if pd._na_igreja and pd._inside:
			dentro = true
			break
	check(dentro, "no expediente, o padre fica DENTRO da igreja (some do mapa)")
	check(pd._agenda_estado(true) == "padre", "no expediente, a agenda dele é a igreja")
	dn.time = dn.tempo_da_hora(fposmod(dn.hora_anoitecer + 0.5, 24.0))
	var est: String = pd._agenda_estado(true)
	check(est != "padre", "na hora social ele sai pra jantar e pras rodas (agenda: %s)" % est)
	var saiu := false
	for i in 400:
		await process_frame
		if not pd._inside:
			saiu = true
			break
	check(saiu, "saiu da igreja pra janta/convívio")
	# os guardas
	var gente: Array = get_nodes_in_group("ipezinhos").filter(func(x): return not x.e_crianca() and not x.is_priest())
	var guardas: Array = gente.slice(0, 4)
	for x in guardas:
		x.set_job("guarda", false)
	sched.vigilia_fracao = 1.0  # (os 4 de vigia: duas turmas de 2)
	def.invasion_active = false
	var h1: float = fposmod(dn.hora_anoitecer + 0.25, 24.0)
	var h2: float = fposmod(dn.hora_dormir - 0.25, 24.0)
	dn.time = dn.tempo_da_hora(h1)
	await _frames(1)
	var p1: Array = guardas.map(func(x): return sched.periodo(x))
	dn.time = dn.tempo_da_hora(h2)
	await _frames(1)
	var p2: Array = guardas.map(func(x): return sched.periodo(x))
	var soc1 := p1.count("social")
	var soc2 := p2.count("social")
	check(soc1 == 2 and p1.count("vigilia") == 2, "1ª parte da hora social: metade janta/conversa, metade no posto (%s)" % [p1])
	check(soc2 == 2 and p2.count("vigilia") == 2, "2ª parte: a outra metade (%s)" % [p2])
	var trocaram := true
	for i in guardas.size():
		if p1[i] == p2[i]:
			trocaram = false
	check(trocaram, "as turmas trocam: quem jantou primeiro volta pro posto")
	var t0 := guardas.filter(func(x): return sched.turma_guarda(x) == 0).size()
	check(t0 == 2, "duas turmas de 2 (turma_guarda)")
	def.invasion_active = true
	dn.time = dn.tempo_da_hora(h1)
	await _frames(1)
	var p3: Array = guardas.map(func(x): return sched.periodo(x))
	check(p3.count("vigilia") == 4, "invasão: todos no posto, ninguém sai pra jantar (%s)" % [p3])
	def.invasion_active = false
	sched.vigilia_fracao = 0.5
	dn.time = dn.tempo_da_hora(h1)
	await _frames(1)
	var folga: Array = guardas.filter(func(x): return not sched.de_vigia(x))
	check(not folga.is_empty() and folga.all(func(x): return sched.periodo(x) == "social"), "o guarda de folga faz a noite normal (janta e hora social)")
