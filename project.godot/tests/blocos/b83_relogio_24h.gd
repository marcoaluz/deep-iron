extends SceneTree
## Bloco 83: relógio de 24 horas (hh:mm, dia da semana, semanas, marcos), estações em semanas, onda solar por
## horário, invasão com aviso às 21:00 e começo às 22:00 (todos em casa, guardas nos postos), controle de
## velocidade (pausa/1x/2x/4x), "Pular dia" (para sozinho), helper de teste e save antigo convertido.
## RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var marcos_vistos: Array = []
var fases: Array = []
var pulo_motivo := ""


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


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 2500.0:  # (t é tempo de JOGO: anda 12x no pulo)
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	var dn = g("day_night")
	var def = g("defense")
	var sun = g("sun")
	var hud = g("hud")
	for w in ws():
		w.hunger = w.hunger_max
	if step == 0 and t > 2.0:
		print("== o relógio")
		dn.time_scale = 0.0  # (o teste mexe no relógio na mão até a parte que roda de verdade)
		dn.day = 1
		dn._pula_para(0.0)
		check(dn.hora_texto() == "05:00" and not dn.is_night(), "o dia começa às 05:00 (amanhecer)")
		check(is_equal_approx(dn.segundos_por_hora(), 22.5) and is_equal_approx(dn.cycle_length(), 540.0), "1 hora de jogo = 22,5 s; o dia inteiro = 9 min")
		check(is_equal_approx(dn.day_duration, 13.5 * 22.5) and is_equal_approx(dn.night_duration, 10.5 * 22.5), "day_duration/night_duration pelos marcos (05:00..18:30)")
		dn.ir_para_hora(14.5)
		check(dn.hora_texto() == "14:30" and is_equal_approx(dn.hora(), 14.5), "ir_para_hora(14.5) -> 14:30")
		dn.ir_para_hora(18.5)
		check(dn.is_night() and dn.hora_texto() == "18:30", "18:30 é noite (anoitecer)")
		dn.ir_para_hora(2.0)
		check(dn.day == 1 and dn.is_night() and dn.hora_texto() == "02:00", "02:00 ainda é a noite do dia 1 (o dia vira no amanhecer)")
		print("== semana")
		check(dn.nome_dia() == "Segunda" and dn.dia_semana() == 1 and dn.semana() == 1, "dia 1: segunda, semana 1")
		check(dn.e_domingo(7) and dn.nome_dia(false, 7) == "Domingo" and dn.nome_dia(true, 6) == "SÁB", "o 7º dia é domingo")
		check(dn.dia_semana(8) == 1 and dn.semana(8) == 2 and dn.semana(14) == 2 and dn.semana(15) == 3, "dia 8: segunda da semana 2")
		print("== marcos e fases")
		dn.marco.connect(func(n): marcos_vistos.append(n))
		dn.phase_changed.connect(func(night): fases.append(night))
		dn.ir_para_hora(5.0, true)
		marcos_vistos.clear()
		fases.clear()
		var d0: int = dn.day
		dn.avancar(dn.cycle_length())
		print("  marcos: ", marcos_vistos, " fases: ", fases)
		check(marcos_vistos == ["fim_expediente", "anoitecer", "dormir", "amanhecer"], "um dia inteiro passa pelos 4 marcos, na ordem")
		check(fases == [true, false] and dn.day == d0 + 1 and dn.hora_texto() == "05:00", "anoitece e amanhece uma vez; o dia virou")
		print("== HUD")
		dn.ir_para_hora(14.0)
		hud._refresh_phase()
		print("  HUD: '%s' / '%s'" % [hud._phase_label.text, hud._phase_time_label.text])
		check(hud._phase_label.text == "14:00 " + dn.nome_dia(true), "HUD mostra hh:mm e o dia da semana")
		check(("dia %d" % dn.day) in hud._phase_time_label.text and "sem. 1" in hud._phase_time_label.text and "fim do turno às 18:00" in hud._phase_label.tooltip_text,
			"HUD mostra o dia e a semana; o próximo marco na dica")
		print("== estações em semanas")
		check(sun.semanas_por_estacao == 2 and sun.days_per_season == 14, "estação de 2 semanas (14 dias)")
		check(sun.season_index(14) == 0 and sun.season_index(15) == 1 and sun.season_index(57) == 0, "dia 15 é verão; dia 57 volta à primavera")
		var cap_antes: float = dn.day_duration
		sun._on_day_started(29)
		check(is_equal_approx(dn.day_duration, cap_antes), "a estação não muda mais o tamanho do dia")
		sun.semanas_por_estacao = 1
		check(sun.days_per_season == 7, "semanas_por_estacao = 1 -> 7 dias")
		sun.semanas_por_estacao = 2
		print("== onda solar por horário")
		var chance: Array[float] = sun.season_wave_chance.duplicate()
		var sempre: Array[float] = [1.0, 1.0, 1.0, 1.0]
		sun.season_wave_chance = sempre
		var ok_hora := true
		for i in 20:
			sun._plan_wave(5)
			var h: float = fposmod(dn.hora_amanhecer + sun.wave_at / dn.segundos_por_hora(), 24.0)
			if not sun.wave_today or h < sun.onda_hora_min - 0.01 or h > sun.onda_hora_max + 0.01:
				ok_hora = false
		check(ok_hora, "a onda é sorteada entre %s e %s" % [dn.hora_texto(sun.onda_hora_min), dn.hora_texto(sun.onda_hora_max)])
		sun.season_wave_chance = chance
		sun.wave_today = false
		print("== invasão: aviso às 21:00, começa às 22:00")
		var dia: int = dn.day
		while not def.is_invasion_night(dia):
			dia += 1
		dn.day = dia
		dn._pula_para(dn.tempo_da_hora(18.0))
		def._t_antes = INF
		def._warned_day = -1
		def._process(0.0)
		dn.ir_para_hora(20.9)
		def._process(0.0)
		check(def._warned_day != dia and not def.invasion_active, "20:54: nada ainda")
		dn.ir_para_hora(21.0)
		def._process(0.0)
		check(def._warned_day == dia and not def.invasion_active, "21:00: o aviso tocou")
		dn.ir_para_hora(21.95)
		def._process(0.0)
		check(not def.invasion_active, "21:57: ainda não começou")
		dn.ir_para_hora(22.0)
		def._process(0.0)
		check(def.invasion_active, "22:00: a invasão começou")
		check(def.next_invasion_day() > dia, "a próxima invasão é depois de hoje")
		dn.ir_para_hora(5.0, true)
		check(not def.invasion_active, "amanheceu: a invasão acabou")
		for c in get_nodes_in_group("criaturas"):
			c.queue_free()
		print("== na noite de invasão de verdade: todos em casa às 22:00, guardas nos postos")
		dia = dn.day
		while not def.is_invasion_night(dia):
			dia += 1
		dn.day = dia
		dn._pula_para(dn.tempo_da_hora(17.8))
		def._t_antes = INF
		ws()[0].set_job("guarda")
		ws()[1].set_job("minerador")
		ws()[2].set_job("lenhador")
		dn.time_scale = 1.0
		Engine.time_scale = 8.0
		step = 1
		t_mark = t
	elif step == 1:
		if def.invasion_active:
			Engine.time_scale = 1.0
			var estados: Array = ws().map(func(w): return [w.display_name, w.job, w.get_state()])
			print("  às %s: %s" % [dn.hora_texto(), estados])
			check(dn.hora() >= 22.0 and dn.hora() < 22.3, "começou às 22:00 (%s)" % dn.hora_texto())
			var fora: Array = ws().filter(func(w): return not w.is_guard() and w.get_state() != "home")
			check(fora.is_empty(), "todo mundo (menos os guardas) em casa (%s)" % [fora.map(func(w): return w.get_state())])
			var guardas: Array = ws().filter(func(w): return w.is_guard())
			check(not guardas.is_empty() and guardas.all(func(w): return w.get_state() in ["guard", "rearming"]), "guardas no posto")
			def.end_invasion()
			for c in get_nodes_in_group("criaturas"):
				c.queue_free()
			step = 2
		elif t - t_mark > 120.0:
			Engine.time_scale = 1.0
			check(false, "a invasão não começou sozinha (%s)" % dn.hora_texto())
			step = 99
	elif step == 2:
		print("== velocidade")
		check(hud.SPEEDS == [0.0, 1.0, 2.0, 4.0], "botões: pausa, 1x, 2x, 4x")
		hud.set_speed(4.0)
		check(Engine.time_scale == 4.0 and hud._speed_buttons[3].button_pressed, "4x liga e marca o botão")
		hud.set_speed(1.0)
		print("== pular dia: para sozinho")
		dn.pulo_terminou.connect(func(m): pulo_motivo = m)
		var w = ws()[1]
		var mor = g("morale")
		var casos := [
			["feriu grave", func(): w.hurt("mina", "grave"), func(): w.injured = false],
			["greve", func(): mor.on_strike = true, func(): mor.on_strike = false],
			["morreu", func(): w.remove_from_group("ipezinhos"), func(): w.add_to_group("ipezinhos")],
		]
		for c in casos:
			pulo_motivo = ""
			hud.pular_dia()
			var vel: float = Engine.time_scale
			c[1].call()
			dn._process(0.0)
			check(not dn.pulando and c[0] in pulo_motivo and Engine.time_scale == 1.0 and vel == dn.pular_velocidade,
				"pulando a %.0fx, parou em '%s' e voltou pra 1x" % [vel, pulo_motivo])
			c[2].call()
		hud.pular_dia()
		hud.set_speed(2.0)
		check(not dn.pulando and Engine.time_scale == 2.0, "mexer na velocidade cancela o pulo")
		hud.set_speed(1.0)
		print("== pular dia: até o amanhecer (simulação rodando)")
		var dia: int = dn.day
		while def.is_invasion_night(dia):
			dia += 1
		dn.day = dia
		dn._pula_para(dn.tempo_da_hora(16.0))
		def._t_antes = INF
		set_meta("dia", dia)
		# (sem onda sorteada no caminho: aqui o pulo tem que ir até o amanhecer; parar na onda é o certo)
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		sun.warned = false
		pulo_motivo = ""
		dn.pular_velocidade = 12.0
		hud.pular_dia()
		check(dn.pulando and Engine.time_scale == 12.0 and hud._pular_button.button_pressed, "Pular dia: acelera e marca o botão")
		step = 3
		t_mark = t
	elif step == 3:
		if not dn.pulando:
			check(pulo_motivo == "amanheceu" and dn.day == get_meta("dia") + 1 and dn.hora() >= 5.0 and dn.hora() < 5.5,
				"parou sozinho no amanhecer do dia seguinte (%s, dia %d, '%s')" % [dn.hora_texto(), dn.day, pulo_motivo])
			check(Engine.time_scale == 1.0, "voltou pra 1x")
			print("== pular dia: para na invasão")
			var dia: int = dn.day
			while not def.is_invasion_night(dia):
				dia += 1
			dn.day = dia
			dn._pula_para(dn.tempo_da_hora(21.5))
			def._t_antes = INF
			def._warned_day = dia
			pulo_motivo = ""
			hud.pular_dia()
			step = 4
			t_mark = t
		elif t - t_mark > 700.0:
			Engine.time_scale = 1.0
			check(false, "o pulo não acabou")
			step = 99
	elif step == 4:
		if not dn.pulando:
			check("invasão" in pulo_motivo and def.invasion_active, "parou quando a invasão começou ('%s', %s)" % [pulo_motivo, dn.hora_texto()])
			def.end_invasion()
			for c in get_nodes_in_group("criaturas"):
				c.queue_free()
			Engine.time_scale = 1.0
			print("== save")
			check(dn.get_save_data().get("relogio") == 24, "save marca o relógio novo")
			dn.load_save_data({"day": 3, "time": 90.0})
			check(dn.day == 3 and is_equal_approx(dn.time, 0.5 * dn.day_duration) and not dn.is_night(), "save antigo de dia (90 de 180 s) -> metade do dia (%s)" % dn.hora_texto())
			dn.load_save_data({"day": 3, "time": 200.0})
			check(dn.is_night() and is_equal_approx(dn.time, dn.day_duration + dn.night_duration / 3.0), "save antigo de noite (20 de 60 s) -> 1/3 da noite (%s)" % dn.hora_texto())
			dn.load_save_data({"day": 4, "time": 120.0, "relogio": 24})
			check(dn.day == 4 and dn.time == 120.0, "save novo: time direto")
			step = 99
		elif t - t_mark > 120.0:
			Engine.time_scale = 1.0
			check(false, "o pulo não parou na invasão")
			step = 99
	if step == 99:
		Engine.time_scale = 1.0
		print("\nFALHAS: %d" % fails)
		return true
	return false
