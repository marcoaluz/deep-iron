extends SceneTree
## Bloco 46: menu de construção estilo Frostpunk. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0


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


func card(menu, name: String) -> Dictionary:
	for c in menu._cards:
		if c.def.name == name:
			return c
	return {}


func press_space() -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = KEY_SPACE
	main._unhandled_input(ev)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 120.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var hud = main.get_node("HUD")
	var menu = hud._build_menu
	if step == 0 and t > 2.0:
		print("== abrir")
		check(hud._build_button != null and hud._build_button.get_parent() != null, "botão CONSTRUIR na barra de baixo")
		press_space()
		check(menu.visible, "espaço abre o menu")
		print("== abas")
		var counts: Array[String] = []
		for i in menu.TAB_NAMES.size():
			menu._show_tab(i)
			menu.refresh()
			counts.append("%s %d" % [menu.TAB_NAMES[i], menu._cards.size()])
			for c in menu._cards:
				if c.def.get("soon", false):
					check(c.button.disabled and c.button.text == "Em breve", "'%s' aparece como em breve" % c.def.name)
		print("  ", ", ".join(counts))
		check(menu._cards_box.get_child_count() >= 0 and not counts.any(func(s): return s.ends_with(" 0")), "todas as abas têm cartões")
		print("== sem dinheiro: motivo e bloqueado")
		main.get_node("Economy").credits = 0.0
		menu._show_tab(menu.TAB_NAMES.find("Defesa e equipamento"))
		menu.refresh()
		var ars := card(menu, "Arsenal")
		print("  Arsenal: custo '%s' motivo '%s'" % [ars.cost.text, ars.status.text])
		check(ars.button.disabled and ars.status.text.begins_with("falta"), "Arsenal mostra o que falta e fica bloqueado")
		check(ars.cost.text.contains("cr"), "custo aparece no cartão")
		print("== construir pelo menu = mesmo fluxo de sempre")
		var eco = main.get_node("Economy")
		eco.credits = 9999.0
		var arm = g("armazens")
		arm.stock["ferro"] = 900.0
		arm.wood_stored = 900.0
		arm._recount()
		menu._show_tab(menu.TAB_NAMES.find("Alimentação"))
		menu.refresh()
		var com := card(menu, "Cozinha")  # (Prompt 29: o Comedouro virou Cozinha no jogo)
		check(not com.button.disabled, "comedouro liberado com recursos")
		com.button.emit_signal("pressed")
		var placer = g("house_placer")
		check(not menu.visible and placer.active and "cozinha" in placer._what, "construir fecha o menu e abre o posicionador da cozinha")
		placer.cancel()
		press_space()
		g("village_hub").coletor_fixo().restaura_tudo()  # Bloco 81: o cartão só aparece com a ruína da floresta restaurada
		menu._show_tab(menu.TAB_NAMES.find("Coleta automática"))
		menu.refresh()
		card(menu, "Coletor de madeira").button.emit_signal("pressed")
		check(placer.active and placer._area.has_area(), "coletor: posicionador só na clareira")
		placer.cancel()
		press_space()
		menu._show_tab(menu.TAB_NAMES.find("Defesa e equipamento"))
		menu.refresh()
		card(menu, "Oficina (forja)").button.emit_signal("pressed")
		check(hud._panels["oficina"].visible and not menu.visible, "Oficina: abre a janela dela")
		press_space()
		check(menu.visible and not hud._panels["oficina"].visible, "menu fecha as outras janelas")
		check(hud.close_panels() and not menu.visible, "Esc fecha o menu")
		press_space()
		press_space()
		check(not menu.visible, "espaço de novo fecha")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
