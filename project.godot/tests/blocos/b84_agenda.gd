extends SceneTree
## Bloco 84: a AGENDA dos ipezinhos (Schedule) por cima do _choose_state — períodos (café, trabalho, almoço,
## voltar, social, dormir), exceções (médico de plantão comendo em turnos, vigília dos guardas em rodízio e
## todos na noite de invasão, cozinheiro mais cedo e até o anoitecer), refeições com porção (uma por
## refeição), refeição perdida rendendo menos, voltar largando a carga, emergência da invasão, HUD
## (porções x refeições de hoje) e save. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var cheios: Array = []  # quem fica com a fome travada no máximo (isola as contas da comida)


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


func w(i: int) -> Node:
	return get_meta("ws")[i]


func comida() -> float:
	var total := 0.0
	for c in get_nodes_in_group("comedouros"):
		total += c.food_stock
	return total


func poe_comida(n: float) -> void:
	var cs := get_nodes_in_group("comedouros")
	for c in cs:
		c.food_stock = 0.0
	if not cs.is_empty():
		cs[0].food_stock = n


func vai(h: float) -> void:
	var dn = g("day_night")
	dn._pula_para(dn.tempo_da_hora(h))
	for x in ws():
		x._agenda_t = 0.0


func dia_sem_invasao() -> void:
	var dn = g("day_night")
	var def = g("defense")
	while def.is_invasion_night(dn.day):
		dn.day += 1


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
	var eco = g("economy")
	var def = g("defense")
	var arm = g("armazens")
	for x in cheios:
		if is_instance_valid(x):
			x.hunger = x.hunger_max
	if arm:
		arm.raw_stored = 0.0  # (o cozinheiro não acrescenta comida: as contas da comida ficam limpas)
	if step == 0 and t > 2.0:
		print("== a agenda")
		check(sched != null and sched.is_in_group("schedule"), "nó Schedule na cena")
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca  # (onda solar é emergência: manda todo mundo pro abrigo — aqui não)
		sun.wave_today = false
		sun.warned = false
		while ws().size() < 7:
			eco.recruit_free()
		var lista: Array = ws().slice(0, 7)
		set_meta("ws", lista)
		var jobs := ["minerador", "lenhador", "médico", "guarda", "guarda", "cozinheiro", "minerador"]
		for i in 7:
			lista[i].set_job(jobs[i])
			lista[i].manual_override_time = 0.0
		dia_sem_invasao()
		var esperado := [[5.5, "cafe"], [9.0, "trabalho"], [12.5, "almoco"], [15.0, "trabalho"], [18.25, "voltar"],
			[19.0, "social"], [22.0, "dormir"], [3.0, "dormir"]]
		var ok := true
		for e in esperado:
			vai(e[0])
			if sched.periodo(w(0)) != e[1]:
				ok = false
				print("  %s: %s (esperado %s)" % [dn.hora_texto(), sched.periodo(w(0)), e[1]])
		check(ok, "minerador: café 05-07, trabalho, almoço 12-13, trabalho, voltar 18:00, social 18:30, dormir 21:30")
		print("== exceções")
		vai(9.0)
		var med_dia: String = sched.periodo(w(2))
		vai(23.0)
		var med_noite: String = sched.periodo(w(2))
		vai(12.1)
		var med_almoco: String = sched.periodo(w(2))
		vai(12.75)
		var med_depois: String = sched.periodo(w(2))
		check(med_dia == "plantao" and med_noite == "plantao" and med_almoco == "almoco" and med_depois == "plantao",
			"médico: plantão dia e noite, almoça no turno dele (%s/%s/%s/%s)" % [med_dia, med_noite, med_almoco, med_depois])
		vai(4.5)
		var coz_cedo: String = sched.periodo(w(5))
		var min_cedo: String = sched.periodo(w(0))
		vai(18.25)
		var coz_tarde: String = sched.periodo(w(5))
		check(coz_cedo == "trabalho" and min_cedo == "dormir" and coz_tarde == "trabalho", "cozinheiro: começa às 04:00 e cozinha o jantar até o anoitecer (%s, %s)" % [coz_cedo, coz_tarde])
		vai(23.0)
		var vig := [sched.de_vigia(w(3)), sched.de_vigia(w(4))]
		dn.day += 1
		dia_sem_invasao()
		var vig2 := [sched.de_vigia(w(3)), sched.de_vigia(w(4))]
		check(vig.count(true) == 1 and vig2.count(true) == 1, "vigília em rodízio: 1 de 2 guardas por noite (%s, depois %s)" % [vig, vig2])
		var d_inv: int = dn.day
		while not def.is_invasion_night(d_inv):
			d_inv += 1
		var antes: int = dn.day
		dn.day = d_inv
		check(sched.de_vigia(w(3)) and sched.de_vigia(w(4)), "noite de invasão: todos os guardas de vigia")
		dn.day = antes
		print("== almoço: uma porção cada, e voltam ao trabalho")
		vai(11.9)
		cheios = [w(1), w(2), w(3), w(4), w(5)]
		w(0).hunger = 50.0
		w(6).hunger = 50.0
		poe_comida(100.0)
		set_meta("c0", comida())
		Engine.time_scale = 8.0
		step = 1
		t_mark = t
	elif step == 1:
		var feito: bool = w(0).refeicoes_hoje.has("almoco") and w(6).refeicoes_hoje.has("almoco") and w(0)._prato <= 0.0 and w(6)._prato <= 0.0
		if feito and w(0).get_state() != "eating" and w(6).get_state() != "eating":
			Engine.time_scale = 1.0
			var gasto: float = get_meta("c0") - comida()
			print("  %s: comida %.0f -> %.0f; fome %.0f e %.0f; estados %s, %s" % [dn.hora_texto(), get_meta("c0"), comida(), w(0).hunger, w(6).hunger, w(0).get_state(), w(6).get_state()])
			check(is_equal_approx(gasto, 2.0 * sched.porcao), "gastou uma porção por refeição (2 x %.0f = %.0f)" % [sched.porcao, gasto])
			check(w(0).hunger >= 50.0 + sched.refeicao_fome - 3.0, "a refeição encheu ~%.0f de fome (%.0f)" % [sched.refeicao_fome, w(0).hunger])
			check(w(0).get_state() in ["mining", "storing"] and w(6).get_state() in ["mining", "storing"], "depois do almoço voltaram a trabalhar")
			check(w(0).refeicoes_perdidas == 0 and is_equal_approx(w(0)._mult_refeicoes(), 1.0), "sem refeição perdida")
			print("== voltar: largar a carga às 18:00")
			vai(17.95)
			cheios = [w(0), w(1), w(2), w(3), w(4), w(5)]
			w(1).wood_carrying = 3.0
			w(0).carrying = 4.0
			w(0).cargo_type = "ferro"
			w(6).hunger = 50.0
			poe_comida(0.0)  # o jantar vai faltar pro w(6)
			Engine.time_scale = 4.0
			step = 2
			t_mark = t
		elif t - t_mark > 400.0:
			Engine.time_scale = 1.0
			check(false, "o almoço não aconteceu (%s: %s/%s, %s)" % [dn.hora_texto(), w(0).get_state(), w(6).get_state(), w(0).refeicoes_hoje])
			step = 99
	elif step == 2:
		if dn.hora() >= 18.1 and not has_meta("v1"):
			set_meta("v1", true)
			print("  18:0x: lenhador %s, minerador %s" % [w(1).get_state(), w(0).get_state()])
			check(w(1).get_state() == "hauling" and w(0).get_state() == "storing", "voltar: lenhador leva a madeira, minerador o minério")
		if dn.hora() >= 19.0 and not has_meta("v2"):
			set_meta("v2", true)
			var fora: Array = [w(0), w(1)].filter(func(x): return x.get_state() != "home")
			check(fora.is_empty() and w(1).wood_carrying <= 0.0 and w(0).carrying <= 0.0, "largaram a carga e foram pra casa (%s)" % [fora.map(func(x): return x.get_state())])
			check(w(2).get_state() == "doctor", "médico de plantão (%s)" % w(2).get_state())
			set_meta("mult0", w(6).work_mult())
		if dn.hora() >= 21.7 and dn.hora() < 23.0 and not has_meta("v3"):
			set_meta("v3", true)
			check(w(6).refeicoes_perdidas == 1 and not w(6).refeicoes_hoje.has("jantar"), "sem comida, perdeu o jantar (perdidas %d)" % w(6).refeicoes_perdidas)
			check(w(6).work_mult() < get_meta("mult0") - 0.05, "refeição perdida rende menos (%.2f -> %.2f)" % [get_meta("mult0"), w(6).work_mult()])
			var nao_casa: Array = [w(0), w(1), w(5), w(6)].filter(func(x): return x.get_state() != "home")
			check(nao_casa.is_empty(), "21:30: hora de dormir, todos em casa (%s)" % [nao_casa.map(func(x): return x.get_state())])
		if dn.hora() >= 22.5 and dn.hora() < 23.5:
			Engine.time_scale = 1.0
			var guardas := [w(3), w(4)].filter(func(x): return x.get_state() in ["guard", "rearming"])
			var dormindo := [w(3), w(4)].filter(func(x): return x.get_state() == "home")
			check(guardas.size() == 1 and dormindo.size() == 1, "noite comum: um guarda de vigia e o outro dormindo (%s, %s)" % [w(3).get_state(), w(4).get_state()])
			check(w(2).get_state() == "doctor", "médico segue de plantão à noite")
			print("== jantar de novo: comendo, a refeição perdida sai")
			poe_comida(100.0)
			vai(18.6)
			w(6).refeicoes_hoje.erase("jantar")
			w(6).hunger = 40.0
			Engine.time_scale = 4.0
			step = 3
			t_mark = t
		elif t - t_mark > 900.0:
			Engine.time_scale = 1.0
			check(false, "a noite não passou (%s)" % dn.hora_texto())
			step = 99
	elif step == 3:
		if w(6).refeicoes_hoje.has("jantar"):
			Engine.time_scale = 1.0
			check(w(6).refeicoes_perdidas == 0 and is_equal_approx(w(6)._mult_refeicoes(), 1.0), "jantou: a refeição perdida saiu (rende normal)")
			print("== invasão: emergência")
			vai(14.0)
			w(0).hunger = w(0).hunger_max
			def.invasion_active = true
			w(0)._decision_timer = 0.0
			w(0)._decide_next_action()
			check(w(0).get_state() == "home", "invasão em andamento: o minerador fica em casa de dia (%s)" % w(0).get_state())
			def.invasion_active = false
			print("== fome devagar e HUD")
			check(is_equal_approx(w(0).hunger_decay * dn.segundos_por_hora(), 4.5), "a fome cai %.1f por hora de jogo" % (w(0).hunger_decay * dn.segundos_por_hora()))
			vai(9.0)
			var hud = g("hud")
			hud._refresh_top_bar(ws())
			var faltam: int = sched.refeicoes_restantes_hoje()
			var txt: String = hud._chips.food.value.text
			print("  HUD comida: '%s' (faltam %d, porções %.1f)" % [txt, faltam, sched.porcoes_em_estoque()])
			check(("hoje %d" % faltam) in txt and str(floori(sched.porcoes_em_estoque())) in txt, "HUD: porções x refeições que faltam hoje")
			print("== save")
			w(0).refeicoes_hoje = {"cafe": true}
			w(0).refeicoes_perdidas = 2
			var d: Dictionary = w(0).get_save_data()
			check(d.refeicoes_hoje == ["cafe"] and d.refeicoes_perdidas == 2, "save: refeições de hoje e perdidas")
			d.erase("refeicoes_hoje")
			d.erase("refeicoes_perdidas")
			w(0).load_save_data(d)
			check(w(0).refeicoes_hoje.is_empty() and w(0).refeicoes_perdidas == 0, "save antigo: nenhuma refeição feita, nenhuma perdida")
			print("== amanhecer zera as refeições")
			w(1).refeicoes_hoje = {"cafe": true, "almoco": true, "jantar": true}
			dn.ir_para_hora(5.0, true)
			check(w(1).refeicoes_hoje.is_empty(), "novo dia: refeições zeradas")
			step = 99
		elif t - t_mark > 300.0:
			Engine.time_scale = 1.0
			check(false, "não jantou (%s, %s)" % [dn.hora_texto(), w(6).get_state()])
			step = 99
	if step == 99:
		Engine.time_scale = 1.0
		print("\nFALHAS: %d" % fails)
		return true
	return false
