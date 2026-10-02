extends SceneTree
## Bloco 54 (não é teste do GUT): ESCALA DA INTERFACE numa janela 1280×720 de verdade. Pra cada escala
## (80%, 100% e a maior que cabe), abre cada janela das estruturas e o menu de construção, confere que
## o retângulo fica dentro da tela (abaixo da barra de cima) e tira uma foto. Roda COM JANELA e
## APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_escala.gd -- <pasta de saída>
## Imprime "CORTA <janela> <escala>" pra cada uma que sai da tela e "FALHAS: n" no fim.
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var t_mark := 0.0
var fila := []  # [escala, id] ("" = menu de construção)
var i := -1
var fails := 0
var linhas: Array[String] = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_escala")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _process(delta: float) -> bool:
	t += delta
	if t > 240.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if i == -1:
		if t < 3.0:
			return false
		var wm = root.get_node("WindowManager")
		var hud = main.get_tree().get_first_node_in_group("hud")
		for esc in [0.8, 1.0, wm.max_ui_scale()]:
			for id in hud._panels:
				fila.append([esc, id])
			fila.append([esc, ""])
			fila.append([esc, "@config"])
			fila.append([esc, "@teclas"])
		print("janela %s, maior escala que cabe: %d%%" % [str(root.size), roundi(wm.max_ui_scale() * 100.0)])
		_abre(0)
		return false
	if t - t_mark > 0.6:
		_confere()
		if i + 1 >= fila.size():
			root.get_node("WindowManager").set_ui_scale(1.0)
			main.get_tree().get_first_node_in_group("pause_menu").close()
			var f := FileAccess.open(out_dir.path_join("escala.txt"), FileAccess.WRITE)
			f.store_string("\n".join(linhas) + "\n")
			f.close()
			print("FALHAS: %d" % fails)
			return true
		_abre(i + 1)
	return false


func _abre(k: int) -> void:
	i = k
	t_mark = t
	var esc: float = fila[i][0]
	var id: String = fila[i][1]
	var wm = root.get_node("WindowManager")
	if not is_equal_approx(wm.applied_ui_scale(), esc):
		wm.set_ui_scale(esc)
	var hud = main.get_tree().get_first_node_in_group("hud")
	hud.close_panels()
	hud._build_menu.visible = false
	var pm = main.get_tree().get_first_node_in_group("pause_menu")
	if pm.visible:
		pm.close()
	if id == "":
		hud.toggle_build_menu()
	elif id.begins_with("@"):
		pm.open()
		pm._show_settings()
		pm._settings_page._show_keys(id == "@teclas")
	else:
		hud.open_panel(id)


func _confere() -> void:
	var esc: float = fila[i][0]
	var id: String = fila[i][1]
	var hud = main.get_tree().get_first_node_in_group("hud")
	var c: Control = hud._build_menu if id == "" else (main.get_tree().get_first_node_in_group("pause_menu")._panel if id.begins_with("@") else hud._panels[id])
	if not c.visible:
		linhas.append("%-4s %-12s (não abre agora)" % [str(roundi(esc * 100.0)) + "%", id])
		return  # ex.: robô antes de ser achado
	var vis := root.get_visible_rect()
	var area := Rect2(vis.position + Vector2(0, hud.TOP_BAR_H), vis.size - Vector2(0, hud.TOP_BAR_H)).grow(1.0)
	if id.begins_with("@"):
		area = vis.grow(1.0)  # a pausa cobre a tela toda
	var r := c.get_global_rect()
	var nome := "menu" if id == "" else id
	var ok := area.encloses(r)
	var l := "%-4s %-12s %s janela %s em %s" % [str(roundi(esc * 100.0)) + "%", nome, "cabe " if ok else "CORTA", r, vis.size.round()]
	if not ok and c.has_meta("_rolagem"):
		var sc: ScrollContainer = c.get_meta("_rolagem")
		l += "  [rolagem min %s, conteúdo min %s, janela min %s]" % [sc.custom_minimum_size, sc.get_child(0).get_combined_minimum_size().round(), c.get_combined_minimum_size().round()]
	elif not ok:
		l += "  [sem rolagem: %d filhos]" % c.get_child_count()
	linhas.append(l)
	print(l)
	if not ok:
		fails += 1
	root.get_texture().get_image().save_png(out_dir.path_join("%d_%s.png" % [roundi(esc * 100.0), nome]))
