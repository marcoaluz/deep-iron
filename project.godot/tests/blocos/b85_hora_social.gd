extends SceneTree
## Bloco 85: a HORA SOCIAL (18:30–21:30) — pontos sociais (refeitório com mesas, praça, taverna, parque) com
## vagas reservadas (ninguém no mesmo pixel), rodas de conversa com balão, troca de ponto passando por
## outro no caminho (waypoint), chuva só nos cobertos, ânimo de conversar e, às 21:30, casa.
## RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var trocas := {}  # ipezinho -> pontos por onde passou
var passeio_com_via := false
var viu_balao := false


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
	return get_nodes_in_group("ipezinhos")


func spots() -> Array:
	return get_nodes_in_group("social_spots")


## Lugar livre perto de `perto` pra um prédio (o posicionador diz se cabe).
func lugar_livre(perto: Vector2) -> Vector2:
	var p = g("house_placer")
	for r in range(0, 400, 16):
		for a in range(16):
			var q: Vector2 = (perto + Vector2.RIGHT.rotated(a * TAU / 16.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return perto


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 1500.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	var dn = g("day_night")
	var sched = g("schedule")
	for w in ws():
		w.hunger = w.hunger_max
		w.refeicoes_hoje["jantar"] = true  # (já jantaram: a hora social de verdade)
	if step == 0 and t > 2.0:
		print("== os pontos sociais")
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		var hub = g("village_hub")
		var mor = g("morale")
		var tav = mor.spawn_taverna(lugar_livre(hub.global_position + Vector2(-220, 140)), 1)
		var par = mor.spawn_park(lugar_livre(hub.global_position + Vector2(240, 160)))
		set_meta("tav", tav)
		set_meta("par", par)
		var tipos := {}
		for s in spots():
			tipos[s.tipo] = s.coberto
		print("  pontos: ", tipos)
		check(tipos.has("refeitorio") and tipos.has("praca") and tipos.has("taverna") and tipos.has("parque"), "refeitório, praça, taverna e parque são pontos sociais")
		check(tipos.refeitorio and tipos.taverna and not tipos.praca and not tipos.parque, "cobertos: refeitório e taverna; ao ar livre: praça e parque")
		var ref = spots().filter(func(s): return s.tipo == "refeitorio")[0]
		check(ref.por_roda == 4, "refeitório: mesas de 4 lugares")
		while ws().size() < 8:
			g("economy").recruit_free()
		var lista: Array = ws()
		for w in lista:
			w.set_job("minerador")
		print("== vagas reservadas")
		var praca = spots().filter(func(s): return s.tipo == "praca")[0]
		var lugares: Array = []
		for w in lista:
			var i: int = praca.reservar(w)
			if i >= 0:
				lugares.append(praca.lugar(i))
		var colados := 0
		for a in lugares.size():
			for b in range(a + 1, lugares.size()):
				if lugares[a].distance_to(lugares[b]) < 6.0:
					colados += 1
		var mapa: RID = g("environment").navigation_region.get_navigation_map()
		var fora := lugares.filter(func(p): return NavigationServer2D.map_get_closest_point(mapa, p).distance_to(p) > 2.0).size()
		check(lugares.size() == mini(lista.size(), praca.vagas()) and colados == 0, "cada um com o seu lugar (%d lugares, %d colados)" % [lugares.size(), colados])
		check(fora == 0, "os lugares ficam no chão navegável")
		var r0: int = praca.roda_de(praca.reservar(lista[0]))
		var r1: int = praca.roda_de(praca.reservar(lista[1]))
		check(r0 == r1, "quem chega prefere a roda que já tem gente (forma o par)")
		for w in lista:
			praca.liberar(w)
		check(praca.livres() == praca.vagas(), "liberar devolve as vagas")
		print("== 18:40: depois do jantar, a hora social")
		sched.conversa_min = 4.0
		sched.conversa_max = 7.0
		dn.ir_para_hora(18.65)
		for w in lista:
			w._agenda_t = 0.0
			w.wake_decision()
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1:
		# (Bloco 111: o máximo de gente conversando em roda durante a hora social — a foto de um instante só às vezes
		# pegava todo mundo trocando de roda ao mesmo tempo)
		var em_roda := ws().filter(func(w): return w.esta_conversando() and w._spot != null and not w._spot.companheiros(w).is_empty()).size()
		set_meta("max_roda", maxi(int(get_meta("max_roda", 0)), em_roda))
		for w in ws():
			if w.get_state() == "social" and w._spot != null:
				if not trocas.has(w):
					trocas[w] = []
				if trocas[w].is_empty() or trocas[w][-1] != w._spot:
					trocas[w].append(w._spot)
				if w._passeio.size() >= 2:
					passeio_com_via = true
				if w._balao != null and w._balao.visible:
					viu_balao = true
		if dn.hora() >= 20.2 and not has_meta("s1"):
			set_meta("s1", true)
			Engine.time_scale = 1.0
			var sociais := ws().filter(func(w): return w.get_state() == "social")
			var rodando := ws().filter(func(w): return w.esta_conversando() and not w._spot.companheiros(w).is_empty())
			print("  %s: %d na hora social, %d conversando em roda; balão: %s; passeio com via: %s" % [dn.hora_texto(), sociais.size(), rodando.size(), viu_balao, passeio_com_via])
			check(sociais.size() >= ws().size() - 1, "todo mundo foi pra hora social (%d de %d)" % [sociais.size(), ws().size()])
			check(int(get_meta("max_roda", 0)) >= 2, "pares/grupos conversando na mesma roda (agora %d; no máximo da hora social %d)" % [rodando.size(), int(get_meta("max_roda", 0))])
			check(viu_balao, "balão de fala com ícone em cima de quem conversa")
			var trocou := trocas.values().filter(func(l): return l.size() >= 2).size()
			check(trocou >= 2, "eles trocam de ponto depois de um tempo (%d trocaram)" % trocou)
			check(passeio_com_via, "o passeio passa por outro ponto no caminho (waypoint)")
			var animados := ws().filter(func(w): return w.animo_social >= 0.5 and w.happiness_factors().any(func(f): return f[0] == "conversou com os amigos"))
			check(animados.size() >= 2, "conversar dá ânimo (%d com o fator)" % animados.size())
			print("== chuva: só nos cobertos")
			g("weather").forcar_chuva = true
			for w in ws():
				w._social_t = 0.0
			Engine.time_scale = 4.0
		if dn.hora() >= 20.9 and not has_meta("s2"):
			set_meta("s2", true)
			Engine.time_scale = 1.0
			var descobertos := ws().filter(func(w): return w.get_state() == "social" and w._spot != null and not w._spot.coberto)
			check(descobertos.is_empty(), "com chuva, ninguém fica em ponto descoberto (%d)" % descobertos.size())
			g("weather").forcar_chuva = false
			Engine.time_scale = 4.0
		if dn.hora() >= 21.75 and dn.hora() < 23.0:
			Engine.time_scale = 1.0
			var fora := ws().filter(func(w): return w.get_state() != "home")
			check(fora.is_empty(), "21:30: acabou a hora social, todos em casa (%s)" % [fora.map(func(w): return w.get_state())])
			var presos := 0
			for s in spots():
				presos += s.ocupantes().size()
			check(presos == 0, "os lugares ficaram livres (%d presos)" % presos)
			print("== save")
			var w0 = ws()[0]
			w0.animo_social = 5.0
			var d: Dictionary = w0.get_save_data()
			d.erase("animo_social")
			w0.load_save_data(d)
			check(w0.animo_social == 0.0, "save antigo: sem ânimo de conversa")
			step = 99
		elif t - t_mark > 1200.0:
			Engine.time_scale = 1.0
			check(false, "a noite não passou (%s)" % dn.hora_texto())
			step = 99
	if step == 99:
		Engine.time_scale = 1.0
		print("\nFALHAS: %d" % fails)
		return true
	return false
