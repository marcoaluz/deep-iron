extends SceneTree
## Bloco 45: coletor de madeira. RODAR SÓ COM APPDATA ISOLADO.
## Bloco 81: o primeiro é a ruína da floresta (restaurada aqui de uma vez; as etapas estão no b81) —
## o fluxo de construir/operar/salvar é testado com o SEGUNDO coletor (o construído).
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
	load("res://scripts/props/armazem.gd").limite_desligado = true  # Bloco 97: o limite do armazém não é o assunto deste teste


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


## O coletor construído (não a ruína da cena).
func novo(hub) -> Node:
	for c in hub.coletores():
		if c != hub.coletor_fixo():
			return c
	return null


func spot_in(rect: Rect2) -> Vector2:
	var p = g("house_placer")
	var c := rect.get_center()
	for r in range(0, 260, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 800.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0  # sempre de dia (de noite o operador vai pra casa, como todo lenhador)
	for w in ws():
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	var eco = main.get_node("Economy")
	var arm = g("armazens")
	var env = g("environment")
	if step == 0 and t > 2.0:
		print("== construir")
		eco.credits = 5000.0
		arm.stock["ferro"] = 500.0
		arm.wood_stored = 100.0
		arm._recount()
		var hud = main.get_node("HUD")
		var fx = hub.coletor_fixo()
		check(fx != null and not fx.restaurado() and hub.coletor_block_reason() != "", "Bloco 81: o primeiro é a ruína; construir outro fica travado")
		fx.restaura_tudo()
		hud.open_panel("coletor")
		hud._panels["coletor"].refresh()
		print("  botão: ", hud._panels["coletor"]._build_button.text)
		check(hub.coletor_cost_text() in hud._panels["coletor"]._build_button.text, "coletor aparece como construção com custo")
		check(hub.build_coletor(), "escolher lugar")
		var placer = g("house_placer")
		placer.move_to(hub.global_position)
		print("  na mina: '%s'" % placer._reason)
		check(placer._reason == "fora da clareira", "só pode na clareira")
		var q := spot_in(env.clearing_rect.grow(-40.0))
		placer.move_to(q)
		var c0: float = eco.credits
		var f0: float = arm.stock["ferro"]
		var w0: float = arm.wood_stored
		var custo: Vector3i = hub.coletor_cost()
		check(placer.try_confirm(), "coletor encomendado na clareira em %s" % q)
		# Bloco 96: o ferro fica RESERVADO no armazém (o engenheiro leva): o livre cai, o estoque não
		check(eco.credits == c0 - custo.x and is_equal_approx(eco.livre("ferro"), f0 - custo.y) and arm.wood_stored == w0,
			"gastou %d cr + %d ferro (sem madeira)" % [custo.x, custo.y])
		check(novo(hub) == null and g("canteiros") != null, "ainda é canteiro")
		set_meta("pos", q)
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 3.0:
		check(g("canteiros").obra_progress() == 0.0, "sem engenheiro não anda")
		ws()[0].set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 2
		t_mark = t
	elif step == 2:
		if novo(hub) != null:
			Engine.time_scale = 1.0
			var c = novo(hub)
			check(c.global_position == get_meta("pos"), "engenheiro ergueu o coletor no lugar")
			ws()[0].set_job("ocioso")
			print("== operar")
			ws()[1].set_job("lenhador")
			ws()[2].set_job("lenhador")
			var panel = main.get_node("HUD")._panels["coletor"]
			main.get_node("HUD").open_panel("coletor")
			panel.refresh()
			var cand = panel._pick_lumber()
			check(cand != null, "janela acha um lenhador pra designar (%s)" % (cand.display_name if cand else "?"))
			c.designate(ws()[1])
			check(c.operator == ws()[1], "lenhador designado")
			Engine.time_scale = 4.0
			step = 3
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "coletor não ficou pronto")
			step = 99
	elif step == 3:
		var c = novo(hub)
		if c._producing and not has_meta("prod_t"):
			set_meta("prod_t", t)
			set_meta("tot0", c.total_produced)
			print("  %s chegou e está operando: %s" % [c.operator.display_name, c.operator.get_state_label()])
		if has_meta("prod_t") and t - get_meta("prod_t") > 20.0:
			Engine.time_scale = 1.0
			var made: float = c.total_produced - get_meta("tot0")
			print("  produziu %d de madeira em %.0f s (%.1f/s)" % [made, t - get_meta("prod_t"), c.wood_per_sec])
			check(made >= 5.0, "produz madeira sozinho, sem ordem manual")
			check(c.operator.get_state() == "operating", "operador continua no posto")
			var manual = ws()[2]
			print("  lenhador manual: %s" % manual.get_state_label())
			check(manual.get_state() in ["chopping", "hauling"], "lenhador manual trabalha em paralelo")
			print("== remover operador")
			c.operator.set_job("ocioso")
			check(c.operator == null, "tirou a função: a máquina ficou sem operador")
			step = 4
			t_mark = t
		elif t - t_mark > 400.0:
			Engine.time_scale = 1.0
			check(false, "operador não começou (%s)" % ws()[1].get_state_label())
			step = 99
	elif step == 4 and t - t_mark > 1.0:
		var c = novo(hub)
		set_meta("tot1", c.total_produced)
		step = 5
		t_mark = t
	elif step == 5 and t - t_mark > 3.0:
		var c = novo(hub)
		check(c.total_produced == get_meta("tot1") and not c._producing, "sem operador parou de produzir (sem erro)")
		c.designate(ws()[2])
		Engine.time_scale = 4.0
		step = 6
		t_mark = t
	elif step == 6:
		var c = novo(hub)
		if c._producing:
			Engine.time_scale = 1.0
			set_meta("snap", [c.global_position, c.total_produced, c.operator.display_name])
			root.get_node("SaveManager").save_game("teste")
			root.get_node("SaveManager").load_game()
			step = 7
			t_mark = t
		elif t - t_mark > 400.0:
			Engine.time_scale = 1.0
			check(false, "novo operador não começou")
			step = 99
	elif step == 7 and t - t_mark > 1.5:
		var c = novo(hub)
		var snap: Array = get_meta("snap")
		print("  depois do load: ", [c.global_position, c.total_produced, c.operator.display_name if c and c.operator else "-"])
		check(c != null and c.global_position == snap[0] and absf(c.total_produced - snap[1]) < 2.0, "save/load: coletor no lugar, total mantido")
		check(c.operator != null and c.operator.display_name == snap[2], "save/load: o mesmo operador voltou pro posto")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
