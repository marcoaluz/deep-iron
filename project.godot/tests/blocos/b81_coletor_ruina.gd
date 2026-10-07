extends SceneTree
## Bloco 81: o coletor de madeira já está na floresta, em RUÍNA, e é restaurado por etapas (limpar folhas e
## entulho -> desenferrujar -> consertar caldeira e serra -> funcionando), cada uma paga pelo jogador e feita
## pelo engenheiro. Extras só depois dele. Save da etapa e do progresso; saves antigos (com coletor = restaurado;
## sem coletor = ruína). RODAR SÓ COM APPDATA ISOLADO.
const IsoArt := preload("res://scripts/iso/iso_art.gd")
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
	return get_nodes_in_group("ipezinhos")


func menu_card(menu, tab: String, name: String) -> Dictionary:
	menu.visible = true
	menu._show_tab(menu.TAB_NAMES.find(tab))
	menu.refresh()
	for c in menu._cards:
		if c.def.name == name:
			return c
	return {}


## As imagens que a vista iso desenha agora pro coletor.
func arte(c) -> Array:
	return IsoArt.layers(c).map(func(l): return String(l.tex.resource_path).get_file())


func estoque(arm, eco) -> Vector3:
	return Vector3(eco.credits, arm.stock["ferro"], arm.wood_stored)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 900.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0  # sempre de dia
	for w in ws():
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	var eco = main.get_node("Economy") if main else null
	var arm = g("armazens")
	var env = g("environment")
	var hud = g("hud")
	var c = hub.coletor_fixo() if hub else null
	if step == 0 and t > 3.0 and c == null:
		check(false, "jogo novo: a ruína do coletor na cena")
		step = 99
	elif step == 0 and t > 3.0:
		print("== a ruína na floresta")
		check(c != null and c.is_in_group("coletores") and hub.coletores().size() == 1, "jogo novo: um coletor na cena (a ruína)")
		check(c.etapa == 0 and not c.restaurado() and c.etapas_feitas() == 0, "começa na etapa 0 (ruína)")
		check(env.clearing_rect.has_point(c.global_position) and c.global_position.x < env.palisade_x, "fica na clareira, a oeste da paliçada (%s)" % c.global_position)
		var perto := INF
		for a in get_nodes_in_group("arvores"):
			perto = minf(perto, a.global_position.distance_to(c.global_position))
		check(perto > 150.0, "longe das árvores (%.0f px)" % perto)
		var mapa: RID = env.navigation_region.get_navigation_map()
		var gate: Vector2 = g("barricadas").global_position
		var alvo: Vector2 = c.obra_position(ws()[0])
		var path := NavigationServer2D.map_get_path(mapa, gate + Vector2(40, 0), alvo, true)
		check(not path.is_empty() and path[path.size() - 1].distance_to(alvo) < 10.0, "dá pra chegar andando do portão até a obra")
		var lenhador = ws()[1]
		lenhador.set_job("lenhador")
		check(not c.designate(lenhador) and c.operator == null and not c.is_usable(), "ruína não aceita operador")
		check(hub.coletor_block_reason() != "" and not hub.build_coletor(), "construir outro coletor fica travado ('%s')" % hub.coletor_block_reason())
		var menu = hud._build_menu
		check(menu != null and menu_card(menu, "Coleta automática", "Coletor de madeira").is_empty(), "o menu de construção não mostra o coletor")
		if menu:
			menu.visible = false
		var arts := arte(c)
		print("  arte: ", arts)
		check(arts.has("quebrado.png") and arts.has("ruina_folhas.png") and arts.has("ruina_entulho.png"), "visual: quebrado + folhas + entulho por cima")
		print("== etapa 1: limpar (só madeira e tempo)")
		hud.open_panel("coletor")
		var panel = hud._panels["coletor"]
		panel.focus(c)
		panel.refresh()
		print("  janela: ", panel._status.text.replace("\n", " | "))
		print("  botão: ", panel._etapa_button.text)
		check(panel._etapa_button.visible and not panel._designate_button.visible and not panel._build_button.visible,
			"janela: botão de pedir etapa, sem designar nem construir")
		check("Limpar folhas e entulho" in panel._status.text and "Desenferrujar" in panel._status.text and "30 madeira" in panel._status.text,
			"janela lista as etapas com o custo")
		eco.credits = 5000.0
		arm.stock["ferro"] = 0.0
		arm.wood_stored = 5.0
		arm._recount()
		check(c.etapa_block_reason() != "" and not c.pedir_etapa(), "sem madeira não dá ('%s')" % c.etapa_block_reason())
		panel.refresh()
		check(panel._etapa_button.disabled and "madeira" in panel._etapa_button.text, "o botão mostra o que falta ('%s')" % panel._etapa_button.text)
		arm.wood_stored = 100.0
		arm._recount()
		var antes := estoque(arm, eco)
		check(c.pedir_etapa(), "pediu a etapa 1")
		var depois := estoque(arm, eco)
		check(depois == antes - Vector3(0, 0, 30), "gastou só 30 madeira (%s -> %s)" % [antes, depois])
		check(c.obra_pending() and c.is_in_group("obras") and c.obra_title().contains("Limpar"), "virou obra de engenheiro")
		set_meta("t1", t)
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 3.0:
		check(c.obra_progress() == 0.0, "sem engenheiro não anda")
		ws()[0].set_job("engenheiro")
		Engine.time_scale = 8.0
		step = 2
		t_mark = t
	elif step == 2:
		if c.obra_progress() > 0.3 and not has_meta("meio"):
			set_meta("meio", true)
			var l: Array = IsoArt.layers(c)
			var f: Array = l.filter(func(x): return String(x.tex.resource_path).ends_with("ruina_folhas.png"))
			check(not f.is_empty() and f[0].mod.a < 0.75, "folhas somem aos poucos com o progresso (alpha %.2f)" % (f[0].mod.a if not f.is_empty() else -1.0))
			Engine.time_scale = 1.0
			print("== save no meio da etapa")
			set_meta("prog", c.progresso)
			root.get_node("SaveManager").save_game("teste")
			var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
			var lista: Array = data.village.coletores
			check(lista.size() == 1 and lista[0].fixo == true and int(lista[0].etapa) == 1 and lista[0].pago == true, "save: etapa e 'pago' na lista dos coletores")
			c.volta_pra_ruina()
			root.get_node("SaveManager").load_game()
			step = 3
			t_mark = t
		elif t - t_mark > 300.0:
			check(false, "engenheiro não começou a limpar")
			step = 99
	elif step == 3 and t - t_mark > 2.0:
		# (o engenheiro volta pra obra e continua: o progresso só pode ter andado pra frente um pouco)
		var dp: float = c.progresso - get_meta("prog")
		check(c.etapa == 1 and c.pago and dp > -0.5 and dp < 4.0, "load: etapa 1 em obra com o progresso (%.1f s, salvo %.1f s)" % [c.progresso, get_meta("prog")])
		Engine.time_scale = 8.0
		step = 4
		t_mark = t
	elif step == 4:
		if c.etapa == 2:
			Engine.time_scale = 1.0
			check(not c.pago and c.etapas_feitas() == 1 and not c.restaurado(), "limpou: etapa 2 espera ser pedida")
			var arts := arte(c)
			check(arts.has("quebrado.png") and not arts.has("ruina_folhas.png") and not arts.has("ruina_entulho.png"), "visual: sem folhas e sem entulho (%s)" % [arts])
			print("== etapa 2: desenferrujar (ferro)")
			var antes := estoque(arm, eco)
			check(not c.pedir_etapa(), "sem ferro não dá ('%s')" % c.etapa_block_reason())
			arm.stock["ferro"] = 200.0
			arm._recount()
			antes = estoque(arm, eco)
			check(c.pedir_etapa(), "pediu desenferrujar")
			check(estoque(arm, eco) == antes - Vector3(0, c.custo_etapa(2).y, 0), "gastou só ferro (%d)" % c.custo_etapa(2).y)
			Engine.time_scale = 8.0
			step = 5
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "a limpeza não terminou")
			step = 99
	elif step == 5:
		if c.etapa == 3:
			Engine.time_scale = 1.0
			var arts := arte(c)
			check(arts == ["pronto.png"] and IsoArt.layers(c)[0].mod != Color.WHITE, "desenferrujado: a máquina limpa, ainda apagada (%s)" % [arts])
			print("== etapa 3: estágio mínimo da vila e o conserto (créditos e ferro)")
			c.etapa_estagio[3] = 3
			var r: String = c.etapa_block_reason()
			check("estágio" in r and not c.pedir_etapa(), "com estágio mínimo, mostra o que falta ('%s')" % r)
			c.etapa_estagio[3] = 0
			var antes := estoque(arm, eco)
			check(c.pedir_etapa(), "pediu o conserto")
			var cu: Vector3i = c.custo_etapa(3)
			check(estoque(arm, eco) == antes - Vector3(cu.x, cu.y, 0), "gastou %d cr + %d ferro" % [cu.x, cu.y])
			Engine.time_scale = 8.0
			step = 6
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "a desferrugem não terminou")
			step = 99
	elif step == 6:
		if c.restaurado():
			Engine.time_scale = 1.0
			ws()[0].set_job("ocioso")
			print("== funcionando")
			check(arte(c) == ["pronto.png"] and IsoArt.layers(c)[0].get("mod", Color.WHITE) == Color.WHITE, "visual: a máquina pronta")
			var lenhador = ws()[1]
			check(c.designate(lenhador) and c.operator == lenhador, "agora aceita operador")
			check(hub.coletor_block_reason() == "", "construir outro coletor liberado")
			var menu = hud._build_menu
			check(menu != null and not menu_card(menu, "Coleta automática", "Coletor de madeira").is_empty(), "o menu mostra o coletor (extras)")
			if menu:
				menu.visible = false
			Engine.time_scale = 4.0
			step = 7
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "o conserto não terminou")
			step = 99
	elif step == 7:
		if c._producing:
			Engine.time_scale = 1.0
			check(true, "o operador chegou e a máquina produz")
			print("== saves antigos")
			root.get_node("SaveManager").save_game("teste")
			var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
			set_meta("data", data)
			# (a) save antigo COM coletor construído (formato do Bloco 47: {position, total}, sem "fixo")
			var velho := Vector2(-560, 60)
			data.village.coletores = [{"position": [velho.x, velho.y], "total": 77.0}]
			for wd in data.workers:
				wd.erase("coletor_pos")
			var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
			fw.store_string(JSON.stringify(data))
			fw.close()
			set_meta("velho", velho)
			root.get_node("SaveManager").load_game()
			step = 8
			t_mark = t
		elif t - t_mark > 400.0:
			check(false, "o operador não começou")
			step = 99
	elif step == 8 and t - t_mark > 2.0:
		check(hub.coletores().size() == 1 and c.restaurado() and c.global_position == get_meta("velho") and int(c.total_produced) == 77,
			"save antigo com coletor: conta como restaurado, no lugar dele (%s, total %d)" % [c.global_position, int(c.total_produced)])
		check(hub.coletor_block_reason() == "", "save antigo com coletor: extras liberados")
		# (b) save antigo SEM coletor
		var data: Dictionary = get_meta("data")
		data.village.erase("coletores")
		data.village.erase("coletor")
		var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(data))
		fw.close()
		root.get_node("SaveManager").load_game()
		step = 9
		t_mark = t
	elif step == 9 and t - t_mark > 2.0:
		check(hub.coletores().size() == 1 and c.etapa == 0 and not c.restaurado() and c.global_position == Vector2(-420, 260) and c.operator == null,
			"save antigo sem coletor: recebe a ruína no lugar da cena (%s, etapa %d)" % [c.global_position, c.etapa])
		check(hub.coletor_block_reason() != "", "save antigo sem coletor: extras travados até restaurar")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
