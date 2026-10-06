extends SceneTree
## Bloco 88: o PADRE (chega por evento, não recrutável), a IGREJA (canteiro, ponto social), a MISSA de domingo
## (todos vão; aconselhamento tira zanga; "foi à missa"), o FUNERAL (alivia o luto), a ESCOLHA do domingo à
## tarde (festival na praça / dia livre / trabalhar) e o CALENDÁRIO (festivais da estação, próximo evento).
## RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0


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


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos").filter(func(w): return not w.is_priest())


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func finish_canteiro(kind: String) -> bool:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			c.obra_work(c.left + 1.0)
			return true
	return false


func na_igreja() -> Array:
	return ws().filter(func(w): return w.get_state() == "social" and w._spot != null and w._spot.tipo == "igreja" and w._conversando)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 3000.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	var dn = g("day_night")
	var cal = g("calendario")
	var hub = g("village_hub")
	var eco = g("economy")
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 2.0:
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		print("== o padre chega")
		check(cal != null and cal.padre() == null and not cal.padre_chegou, "estágio 1: sem padre")
		var n0: int = eco.worker_count()
		hub.level = cal.padre_estagio
		cal._process(0.0)
		var pd = cal.padre()
		check(pd != null and pd.display_name == cal.padre_nome and pd.is_priest(), "estágio %d: %s chegou" % [cal.padre_estagio, pd.display_name if pd else "?"])
		check(eco.worker_count() == n0, "o padre não conta no limite de recrutas")
		pd.set_job("minerador")
		check(pd.is_priest(), "ninguém troca a função do padre")
		check(g("diary").unlocked.has("padre") if g("diary").get("unlocked") != null else true, "página do padre no diário")
		print("== a igreja")
		eco.credits = 9999.0
		var arm = g("armazens")
		arm.stock["ferro"] = 999.0
		arm.wood_stored = 999.0
		arm._recount()
		check(hub.igreja_block_reason() == "", "estágio 2 com recursos: dá pra construir ('%s')" % hub.igreja_block_reason())
		check(hub.build_igreja(), "escolher lugar")
		var q := spot_near(hub.global_position + Vector2(-150, 140))
		g("house_placer").cancel()
		check(q.is_finite() and hub._confirm_igreja(q) and finish_canteiro("igreja"), "o engenheiro ergueu a igreja")
		var ig = cal.igreja()
		check(ig != null and ig.ponto().tipo == "igreja" and ig.ponto().coberto and ig.ponto().vagas() >= 20, "a igreja é ponto social coberto com bancos (%d)" % (ig.ponto().vagas() if ig else 0))
		check("igreja" in hub.igreja_block_reason() or "uma só" in hub.igreja_block_reason(), "é uma só")
		print("== calendário")
		check(cal.e_dia_de_festival(14) and not cal.e_dia_de_festival(7) and cal.nome_festival(14) == "Festa das Flores" and cal.nome_festival(28) == "Festa do Sol",
			"festival no último domingo da estação, com nome (dia 14: %s; dia 28: %s)" % [cal.nome_festival(14), cal.nome_festival(28)])
		print("  próximos: ", cal.proximos(4).map(func(e): return cal.texto_evento(e)))
		check(cal.proximos(4).any(func(e): return e.nome == "Missa"), "a missa aparece nos próximos eventos")
		check("Calendário:" in g("hud")._panels["calendario"].button_text(), "o HUD mostra o próximo evento ('%s')" % g("hud")._panels["calendario"].button_text())
		print("== missa de domingo")
		var lista: Array = ws()
		for i in lista.size():
			lista[i].set_job(["minerador", "lenhador", "minerador", "engenheiro"][i % 4])
			lista[i].anger = 50.0
		dn.day = 7
		dn._pula_para(dn.tempo_da_hora(8.9))
		def_sem_invasao()
		Engine.time_scale = 6.0
		step = 1
		t_mark = t
	elif step == 1:
		if dn.hora() >= 10.5 and not has_meta("m1"):
			set_meta("m1", true)
			var la := na_igreja()
			print("  %s: %d de %d na missa; zanga %s" % [dn.hora_texto(), la.size(), ws().size(), ws().map(func(w): return roundi(w.anger))])
			check(la.size() >= ws().size() - 1, "missa: todo mundo na igreja (%d de %d)" % [la.size(), ws().size()])
			check(ws().all(func(w): return w.anger < 45.0), "o aconselhamento tirou zanga")
		if dn.hora() >= 11.3 and not has_meta("m2"):
			set_meta("m2", true)
			check(ws().any(func(w): return w.happiness_factors().any(func(f): return f[0] == "foi à missa")), "fator 'foi à missa' no ânimo")
			check(na_igreja().is_empty(), "11:00: a missa acabou e saíram")
			print("== domingo ao meio-dia: a escolha")
		if dn.hora() >= 12.1 and not has_meta("m3"):
			set_meta("m3", true)
			Engine.time_scale = 1.0
			check(g("hud")._panels["calendario"].visible, "a janela abriu sozinha no domingo")
			var mor = g("morale")
			var c0: float = eco.credits
			check(cal.escolher("festival"), "escolheu o Festival")
			check(eco.credits == c0 - mor.festa_credits and mor.festa_left > 0.0, "festival: pagou e a festa começou")
			check(cal.motivo_escolha("livre") != "", "uma escolha por domingo")
			Engine.time_scale = 6.0
		if dn.hora() >= 14.0 and not has_meta("m4"):
			set_meta("m4", true)
			var praca := ws().filter(func(w): return w.get_state() == "social" and w._spot != null and w._spot.tipo == "praca")
			print("  %s: %d na praça" % [dn.hora_texto(), praca.size()])
			check(praca.size() >= ws().size() - 1, "festival: todo mundo na praça (%d)" % praca.size())
			print("== funeral")
			Engine.time_scale = 1.0
			dn.day = 8
			dn._pula_para(dn.tempo_da_hora(15.0))
			g("morale").grief = 0.0
			var morto = ws()[0]
			morto.hunger = 0.0
			morto._die()
			check(cal.funerais.size() == 1 and int(cal.funerais[0].dia) == 8, "funeral marcado pra hora social de hoje")
			set_meta("luto", g("morale").grief)
			Engine.time_scale = 6.0
			step = 2
			t_mark = t
		elif t - t_mark > 1500.0:
			check(false, "o domingo não passou (%s)" % dn.hora_texto())
			step = 99
	elif step == 2:
		if dn.hora() >= 18.9 and dn.hora() < 19.4 and not has_meta("f1"):
			set_meta("f1", true)
			print("  %s: %d no funeral; placa '%s'" % [dn.hora_texto(), na_igreja().size(), cal.igreja()._label.text.replace("\n", " | ")])
			check(na_igreja().size() >= ws().size() - 1, "funeral: todo mundo na igreja (%d)" % na_igreja().size())
		if dn.hora() >= 19.8:
			Engine.time_scale = 1.0
			var luto: float = g("morale").grief
			print("  luto %.1f -> %.1f" % [get_meta("luto"), luto])
			check(cal.funerais.is_empty() and luto < get_meta("luto") - cal.funeral_alivio * 0.8, "depois do funeral o luto caiu")
			print("== trabalhar no domingo")
			dn.day = 14
			dn._pula_para(dn.tempo_da_hora(12.5))
			var z0: float = ws()[0].anger
			check(cal.e_dia_de_festival(14) and cal.nome_festival_hoje() == "Festa das Flores", "hoje é a Festa das Flores")
			check(cal.escolher("trabalhar"), "escolheu trabalhar")
			check(ws()[0].anger >= z0 + cal.domingo_trabalho_zanga - 0.1 and cal.periodo_domingo(15.0) == "trabalho", "trabalhar: + zanga e a tarde é de trabalho")
			print("== save")
			root.get_node("SaveManager").save_game("teste")
			var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
			check(data.has("calendario") and data.calendario.padre_chegou and data.calendario.igreja.size() == 2 and data.calendario.escolha == "trabalhar", "save: padre, igreja e a escolha")
			set_meta("ig", cal.igreja().global_position)
			root.get_node("SaveManager").load_game()
			step = 3
			t_mark = t
		elif t - t_mark > 1500.0:
			Engine.time_scale = 1.0
			check(false, "o funeral não aconteceu (%s)" % dn.hora_texto())
			step = 99
	elif step == 3 and t - t_mark > 2.0:
		check(cal.igreja() != null and cal.igreja().global_position == get_meta("ig") and cal.padre() != null and cal.escolha_hoje() == "trabalhar",
			"load: igreja no lugar, o padre e a escolha de hoje")
		step = 99
	if step == 99:
		Engine.time_scale = 1.0
		print("\nFALHAS: %d" % fails)
		return true
	return false


func def_sem_invasao() -> void:
	var def = g("defense")
	if def:
		def.invasion_active = false
