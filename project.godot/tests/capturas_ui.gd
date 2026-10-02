extends SceneTree
## Prompt 20 (não é teste): o mockup da interface com a pele nova, no jogo de verdade.
## Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_ui.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const EventWindow := preload("res://scripts/ui/event_window.gd")
const TELAS := ["ui_jogo_hud", "ui_menu_construir", "ui_janela_evento", "ui_painel_predio"]
var main: Node
var out_dir := ""
var t := 0.0
var cur := -1
var t_mark := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_ui")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func node(g: String) -> Node:
	return main.get_tree().get_first_node_in_group(g)


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT")
		return true
	if cur < 0:
		if t > 3.0:
			node("day_night").time_scale = 0.0
			var cam = main.get_node("Camera2D")
			cam.bounds = Rect2()
			cam.on_view_changed(Vector2(-300, -230))
			_next()
		return false
	if t - t_mark > 1.5:
		root.get_texture().get_image().save_png(out_dir.path_join(TELAS[cur] + ".png"))
		print("tela: ", TELAS[cur])
		_limpa()
		if cur + 1 >= TELAS.size():
			return true
		_next()
	return false


func _limpa() -> void:
	var hud := node("hud")
	var bm = hud.find_child("*BuildMenu*", true, false) if hud else null
	for c in hud.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("build_menu.gd"):
			c.visible = false
	var w := EventWindow.aberta()
	if w:
		w._fecha()
	for c in main.get_tree().root.get_children():
		if c is CanvasLayer and c.get_script() != null and String(c.get_script().resource_path).ends_with("pause_menu.gd"):
			if c.has_method("close"):
				c.close()
	main.get_tree().paused = false


func _next() -> void:
	cur += 1
	var hud := node("hud")
	match TELAS[cur]:
		"ui_jogo_hud":
			var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
			main.select(w)
		"ui_menu_construir":
			for c in hud.get_children():
				if c.get_script() != null and String(c.get_script().resource_path).ends_with("build_menu.gd"):
					c.toggle()
		"ui_janela_evento":
			var img: Texture2D = load("res://assets/game/iso/bonecos/robo/parado_achado.png")
			EventWindow.abre(main.get_tree(), "ROBÔ ANTIGO", "Os mineiros acharam, no fundo da galeria, um robô de antes da explosão solar. Está enferrujado, mas o reator ainda dá sinal. Levar pra base e consertar?",
				img, [["Levar pra base", null], ["Deixar lá", null]])
		"ui_painel_predio":
			hud.open_panel_for(node("village_hub"))
		"ui_pausa":
			var pm = load("res://scripts/ui/pause_menu.gd")
			for c in main.get_tree().root.get_children():
				if c is CanvasLayer and c.get_script() == pm and c.has_method("open"):
					c.open()
	t_mark = t
