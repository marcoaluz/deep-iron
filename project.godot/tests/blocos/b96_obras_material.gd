extends SceneTree
## Bloco 96: OBRAS COM MATERIAL levado pelo engenheiro. A encomenda cobra os créditos e RESERVA o material no
## armazém (não sai ainda; a encomenda pede estoque livre; vender e produzir não pegam o reservado); o engenheiro
## busca no armazém mais perto que tem (até carga_material por viagem), leva e entrega; a obra só anda até a
## fração entregue (os estágios vêm com o material); dois engenheiros não pegam o mesmo item; cancelar devolve
## créditos e material; save no meio e save antigo (tudo entregue); obra sem material igual a antes; os
## consertos grandes (barricada, plataforma do abismo, robô) viram obra. RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
const ObraEstagio := preload("res://scripts/core/obra_estagio.gd")
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var obra: Node = null
var eng: Array = []
var max_mao := 0.0
var max_excesso := 0.0
var estagios: Array = []
var viagens := {}
var sobra_promessa := 0.0
var segundo_arm: Node = null


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


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func canteiro(kind: String) -> Node:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			return c
	return null


## Acompanha a obra a cada quadro: carga máxima na mão, progresso passando do entregue, estágios, promessas.
func vigia() -> void:
	if obra == null or not is_instance_valid(obra):
		return
	var site = ObraSite.de(obra)
	for w in eng:
		var m: float = w._material_qtd(w.material_mao) + w._material_qtd(w.material_pedido)
		max_mao = maxf(max_mao, m)
		if not w.material_mao.is_empty() and not viagens.has(w):
			viagens[w] = true
	max_excesso = maxf(max_excesso, obra.obra_progress() - site.fracao())
	for k in site.necessario:
		sobra_promessa = maxf(sobra_promessa, site.em_maos(k) + site.pedido(k) - site.falta(k))
	if obra.get("_ghost") != null:
		var e := ObraEstagio.shown(obra._ghost)
		if estagios.is_empty() or estagios[-1] != e:
			estagios.append(e)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 290.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	vigia()
	var eco = g("economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	if step == 0 and t > 3.0:
		step = 1
		print("== A) encomenda: créditos na hora, material RESERVADO (não sai do armazém)")
		eco.credits = 5000.0
		arm.wood_stored = 40.0
		arm.stock["ferro"] = 0.0
		arm._recount()
		var c0: float = eco.credits
		var pos := spot_near(hub.global_position + Vector2(140, 80))
		check(g("morale")._confirm_taverna(pos), "encomendou a taverna (40 madeira)")
		obra = canteiro("taverna")
		var site = ObraSite.de(obra)
		check(site != null and is_equal_approx(float(site.necessario.get("madeira", 0.0)), 40.0), "lista de material: %s" % str(site.necessario if site else {}))
		check(is_equal_approx(eco.credits, c0 - 120.0) and is_equal_approx(site.creditos, 120.0), "créditos cobrados na encomenda (%d)" % int(c0 - eco.credits))
		check(is_equal_approx(arm.wood_stored, 40.0), "a madeira continua no armazém (%d)" % int(arm.wood_stored))
		check(is_equal_approx(eco.reservado("madeira"), 40.0) and is_equal_approx(eco.livre("madeira"), 0.0), "reservada: livre %d" % int(eco.livre("madeira")))
		check(eco.can_afford(0, 0, "", 10) == false and g("defense").campo_block_reason().begins_with("falta"), "outra encomenda não usa o reservado (%s)" % g("defense").campo_block_reason())
		# vender não vende o reservado
		arm.stock["ferro"] = 20.0
		arm.wood_stored = 65.0
		arm._recount()
		var pos2 := spot_near(hub.global_position + Vector2(-160, 90))
		check(hub._confirm_comedouro(pos2), "encomendou a cozinha (20 ferro + 25 madeira)")
		eco.sell_all()
		check(is_equal_approx(arm.stock["ferro"], 20.0), "vender tudo não vendeu o ferro reservado (%d)" % int(arm.stock["ferro"]))
		check(eco.sale_value() == 0, "valor de venda sem o reservado")
		var coz := canteiro("comedouro")
		check(ObraSite.cancelar(coz), "cancelou a cozinha")
		check(is_equal_approx(eco.livre("ferro"), 20.0) and is_equal_approx(eco.livre("madeira"), 25.0), "o reservado da cozinha ficou livre de novo")

		print("== B) obra sem material (Expandir: só créditos): anda como antes")
		var sem := ObraSite.new()
		check(not sem.tem_material() and sem.fracao() == 1.0, "obra sem lista: tudo entregue")
		var antigo := ObraSite.new()
		antigo.load_save_data({"ordered_at": 12.0})
		check(not antigo.tem_material() and antigo.tudo_entregue(), "save antigo (sem 'necessario'): tudo entregue")
		var meio := ObraSite.new()
		meio.load_save_data({"ordered_at": 1.0, "necessario": {"madeira": 40.0}, "entregue": {"madeira": 15.0}, "creditos": 120.0})
		check(is_equal_approx(meio.fracao(), 15.0 / 40.0) and is_equal_approx(meio.creditos, 120.0), "save no meio: entregue/necessário voltam (%.2f)" % meio.fracao())
		var d: Dictionary = obra.get_save_data()
		check((d.obra as Dictionary).has("necessario") and (d.obra as Dictionary).has("entregue"), "o canteiro salva a lista")

		print("== C) viagens com limite, de outro armazém mais perto, progresso limitado, estágios")
		var w = ws()[0]
		w.set_job("engenheiro")
		eng = [w]
		check(w.carga_material == 10.0, "limite de carga: %d por viagem" % int(w.carga_material))
		# um 2º armazém do lado da obra, com a madeira: o engenheiro busca lá (o mais perto que tem)
		segundo_arm = load("res://scenes/props/armazem.tscn").instantiate()
		segundo_arm.position = spot_near(obra.global_position + Vector2(-90, 40))
		arm.get_parent().add_child(segundo_arm)
		segundo_arm.wood_stored = 40.0
		arm.wood_stored = 0.0
		Engine.time_scale = 6.0
		t_mark = t
		return false
	if step == 1:
		if obra == null or not is_instance_valid(obra):
			Engine.time_scale = 1.0
			step = 2
			check(viagens.has(eng[0]), "o engenheiro levou material")
			check(max_mao <= 10.0 + 0.01, "nunca levou mais de 10 por viagem (máx. %.1f)" % max_mao)
			check(max_excesso <= 0.02, "o progresso nunca passou do entregue (máx. +%.3f)" % max_excesso)
			var cres := true
			for i in range(1, estagios.size()):
				if estagios[i] < estagios[i - 1] and estagios[i] != 0:
					cres = false
			check(cres and estagios.size() >= 3, "os estágios vêm conforme o material chega %s" % str(estagios))
			check(is_equal_approx(segundo_arm.wood_stored, 0.0), "pegou do armazém mais perto que tinha (sobrou %d)" % int(segundo_arm.wood_stored))
			check(get_nodes_in_group("tavernas").size() >= 1, "a taverna ficou pronta")
			print("== D) dois engenheiros, sem pegar o mesmo item duas vezes")
			var w2 = ws()[1]
			w2.set_job("engenheiro")
			eng = [ws()[0], w2]
			viagens.clear()
			max_mao = 0.0
			max_excesso = 0.0
			sobra_promessa = 0.0
			estagios.clear()
			arm.wood_stored = 200.0
			arm.stock["ferro"] = 200.0
			arm._recount()
			var pos := spot_near(hub.global_position + Vector2(40, 170))
			print("  parque: '%s'" % g("morale").park_block_reason())
			check(g("morale")._confirm_park(pos), "encomendou o parque (ferro + madeira)")
			obra = canteiro("parque")
			if obra == null:
				step = 9
				return false
			print("  lista: ", ObraSite.de(obra).necessario)
			Engine.time_scale = 6.0
			t_mark = t
		elif t - t_mark > 150.0:
			check(false, "a taverna não ficou pronta a tempo (%s)" % ObraSite.de(obra).status(obra.obra_progress()))
			step = 9
		return false
	if step == 2:
		var site = ObraSite.de(obra) if obra and is_instance_valid(obra) else null
		if site and site.fracao() >= 0.5:
			Engine.time_scale = 1.0
			step = 3
			check(viagens.size() == 2, "os dois engenheiros fizeram viagens (%d)" % viagens.size())
			check(sobra_promessa <= 0.01, "nunca prometeram mais do que faltava (máx. +%.2f)" % sobra_promessa)
			check(max_mao <= 10.0 + 0.01, "cada um no máximo 10 por viagem (%.1f)" % max_mao)
			var txt: String = site.status(obra.obra_progress())
			print("  estado: ", txt, " | ", site.material_texto())
			check(site.material_texto().contains("/"), "entregue/necessário por item: %s" % site.material_texto())
			print("== E) cancelar no meio devolve créditos e material")
			var c0: float = eco.credits
			var antes_m: float = eco.quantidade("madeira") + site.falta("madeira") * 0.0
			var total_m: float = float(site.necessario.get("madeira", 0.0))
			var total_f: float = float(site.necessario.get("ferro", 0.0))
			check(ObraSite.cancelar(obra), "cancelou o parque")
			check(is_equal_approx(eco.credits, c0 + 100.0), "os créditos voltaram (+%d)" % int(eco.credits - c0))
			check(is_equal_approx(eco.quantidade("madeira"), 200.0) and is_equal_approx(eco.quantidade("ferro"), 200.0),
				"o material voltou pro armazém (madeira %d, ferro %d de 200)" % [int(eco.quantidade("madeira")), int(eco.quantidade("ferro"))])
			check(eng.all(func(w): return w.material_mao.is_empty() and w.material_pedido.is_empty()), "ninguém ficou com material na mão")
			check(eco.reservado("madeira") == 0.0 and eco.reservado("ferro") == 0.0, "nada reservado")
			t_mark = t
		elif t - t_mark > 150.0:
			check(false, "o parque não chegou a 50%% do material (%s)" % (site.status(obra.obra_progress()) if site else "?"))
			step = 9
		return false
	if step == 3 and t - t_mark > 0.5:
		step = 4
		check(canteiro("parque") == null, "o canteiro sumiu")
		print("== F) material na mão vai pro save e volta pro armazém ao carregar")
		var w = ws()[0]
		var dados: Dictionary = w.get_save_data()
		dados["material_mao"] = {"madeira": 7.0}
		var m0: float = eco.quantidade("madeira")
		w.load_save_data(dados)
		t_mark = t
		return false
	if step == 4 and t - t_mark > 0.3:
		step = 5
		check(is_equal_approx(eco.quantidade("madeira"), 200.0 + 7.0), "os 7 da mão voltaram pro armazém (%d)" % int(eco.quantidade("madeira")))
		print("== G) consertos grandes viram obra (barricada, plataforma, robô)")
		var bar = g("barricadas")
		var nivel0: int = bar.level
		eco.credits = 9999.0
		arm.stock["ferro"] = 500.0
		arm.wood_stored = 500.0
		arm._recount()
		check(bar.upgrade(), "encomendou o próximo nível da barricada")
		check(bar.level == nivel0 and bar.obra_pending() and bar.is_in_group("obras"), "o nível só sobe com a obra (nível %d, em obra)" % bar.level)
		check(ObraSite.de(bar).tem_material(), "com material: %s" % str(ObraSite.de(bar).necessario))
		ObraSite.de(bar).entregar("madeira", 999.0)
		for k in ObraSite.de(bar).necessario:
			ObraSite.de(bar).entregar(k, 999.0)
		bar.obra_work(999.0)
		check(bar.level == nivel0 + 1 and not bar.obra_pending(), "obra pronta: subiu pro nível %d" % bar.level)
		bar.hp = bar.max_hp() - 8.0  # conserto pequeno (2 madeira): na hora
		check(bar.repair() and is_equal_approx(bar.hp, bar.max_hp()) and not bar.obra_pending(), "conserto pequeno: na hora")
		bar.hp = 1.0  # conserto grande: obra
		check(bar.repair() and bar.obra_pending() and bar.hp < bar.max_hp(), "conserto grande: vira obra (madeira %d)" % int(ObraSite.de(bar).necessario.get("madeira", 0)))
		check(ObraSite.cancelar(bar) and not bar.obra_pending(), "conserto cancelado")
		var robo = g("robos")
		if robo:
			robo.state = "base"
			var finds = g("finds")
			finds.rare_parts = 50
			check(robo.start_repair() and robo.obra_pending() and robo.is_in_group("obras"), "conserto do robô vira obra")
			var r0: float = robo.repair_left
			for i in 30:
				robo._process(0.5)
			check(is_equal_approx(robo.repair_left, r0), "sem engenheiro o conserto do robô não anda")
			check(ObraSite.cancelar(robo) and robo.state == "base" and finds.rare_parts == 50, "cancelar: as peças raras voltam")
		var aby = g("elevador_abismo")
		if aby:
			check(aby.has_method("obra_work") and aby.has_method("obra_cancelar"), "a plataforma do abismo é obra de engenheiro")
		print("== H) telemetria: obras prontas e tempo médio")
		var tel = g("telemetria")
		if tel:
			var od: Array = tel.obras_do_dia()
			print("  telemetria: ", od)
			check(od[0] >= 1 and od[1] > 0.0, "a telemetria contou as obras (%d, média %.0f s)" % [od[0], od[1]])
		else:
			check(preload("res://scripts/core/telemetria.gd").COLUNAS.has("obra_tempo_medio_s"), "coluna nova da telemetria")
		print("\nFALHAS: %d" % fails)
		Engine.time_scale = 1.0
		return true
	if step == 9:
		print("\nFALHAS: %d" % fails)
		Engine.time_scale = 1.0
		return true
	return false
