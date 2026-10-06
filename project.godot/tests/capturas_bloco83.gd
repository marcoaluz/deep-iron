extends SceneTree
## Bloco 83 (não é teste): a barra de cima com o relógio de 24 h, a velocidade e o "Pular dia".
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco83.gd -- <pasta de saída>
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
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b83")
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
		var dn = get_first_node_in_group("day_night")
		dn.day = 3
		dn._pula_para(dn.tempo_da_hora(17.6))
		step = 1
		t = 0.0
	elif step == 1 and t > 1.0:
		var img := root.get_texture().get_image()
		img.get_region(Rect2i(0, 0, 1280, 60)).save_png(out_dir.path_join("barra_relogio.png"))
		img.save_png(out_dir.path_join("tela_17h.png"))
		print("ok")
		return true
	return false
