extends SceneTree
## Bloco 82 (não é teste): a janela do armazém em grade por categoria, com alguns itens guardados.
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco82.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b82")
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
	if step == 0 and t > 4.0:
		var eco = get_first_node_in_group("economy")
		var a = get_first_node_in_group("armazens")
		a.stock["ferro"] = 120.0
		a.stock["carvao"] = 34.0
		a.stock["cobre"] = 18.0
		a.wood_stored = 64.0
		a.raw_stored = 9.0
		a.leather_stored = 5.0
		a._recount()
		eco.add_item("barra_ferro", 12.0)
		eco.add_item("prego", 40.0)
		get_first_node_in_group("finds").rare_parts = 2
		var hud = get_first_node_in_group("hud")
		hud.open_panel("armazem")
		hud._panels["armazem"].refresh()
		step = 1
		t = 0.0
	elif step == 1 and t > 1.0:
		root.get_texture().get_image().save_png(out_dir.path_join("janela_armazem.png"))
		print("ok")
		return true
	return false
