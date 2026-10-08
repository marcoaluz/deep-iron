extends SceneTree
## HUD estilo Frostpunk. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var fails := 0
var step := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	# (o toggle_hints do fim grava show_hints=true nas configurações: sem isto a rodada seguinte
	# começava com os atalhos abertos e o teste alternava entre passar e falhar)
	preload("res://scripts/core/settings.gd").set_value("hud", "show_hints", false)
	root.size = Vector2i(1152, 648)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if step == 0 and t > 2.0:
		step = 1
		var hud = main.get_node("HUD")
		# muitos ipezinhos, pra lista ficar grande (pior caso)
		var eco = main.get_node("Economy")
		eco.credits = 99999
		eco.max_workers = 12
		for i in 9:
			eco.novo_ipezinho()  # (Bloco 101: acabou o "Recrutar")
		return false
	if step == 1 and t > 3.5:
		var hud = main.get_node("HUD")
		hud._refresh()
		var vp: Vector2 = root.get_visible_rect().size
		print("viewport: ", vp)
		var top: Rect2 = hud._chips.credits.box.get_parent().get_parent().get_global_rect()
		var order: Rect2 = hud._order_bar.get_global_rect()
		var left: Rect2 = hud._left_panel.get_global_rect()
		var right: Rect2 = hud._alertas.get_global_rect()  # Bloco 95: a coluna de alertas no lugar da de construções
		print("topo ", top, "\nordens ", order, "\nesquerda ", left, "\ndireita ", right)
		var row: Control = hud._chips.credits.box.get_parent()
		check(row.get_combined_minimum_size().x <= vp.x - 24.0, "barra do topo cabe na largura (%d de %d)" % [row.get_combined_minimum_size().x, vp.x])
		check(order.position.x >= 0 and order.end.x <= vp.x and order.end.y <= vp.y, "barra de ordens inteira dentro da tela")
		check(left.end.y <= order.position.y, "painel esquerdo termina acima da barra de ordens (%d <= %d)" % [left.end.y, order.position.y])
		check(right.end.y <= order.position.y or right.position.x >= order.end.x, "alertas não cobrem a barra de ordens")
		check(not hud._hint_panel.visible, "atalhos escondidos por padrão")
		# clicar no botão da função aplica a função
		var ws := get_nodes_in_group("ipezinhos")
		main.select(ws[0])
		var b: Button = hud._job_buttons["caçador"].button
		b.pressed.emit()
		check(ws[0].job == "caçador", "botão 'Caçador' na barra de baixo aplicou a função")
		hud._refresh()
		check(b.button_pressed, "botão fica aceso pra seleção com essa função")
		check(hud._job_buttons["caçador"].count.text == "1", "contador no botão: '%s'" % hud._job_buttons["caçador"].count.text)
		main.toggle_selected(ws[1])
		hud._refresh()
		check(not b.button_pressed, "grupo misto: botão não fica aceso")
		print("legenda: ", hud._selection_caption.text)
		hud._job_buttons["médico"].button.pressed.emit()
		check(ws[0].job == "médico" and ws[1].job == "médico", "botão aplicou pros 2 selecionados")
		hud.toggle_hints()
		check(hud._hint_panel.visible, "H/? abre os atalhos")
		check(hud.close_panels() and not hud._hint_panel.visible, "Esc fecha os atalhos")
		preload("res://scripts/core/settings.gd").set_value("hud", "show_hints", false)  # devolve o padrão
		print("\nFALHAS: %d" % fails)
		return true
	return false
