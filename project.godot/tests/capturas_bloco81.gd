extends SceneTree
## Bloco 81 (não é teste): o coletor de madeira em ruína em cada etapa da restauração, no jogo (vista iso).
## Com janela e APPDATA isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco81.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var fase := 0
## [etapa, pago, progresso (0..1)] de cada foto
const FASES := [[0, false, 0.0], [1, true, 0.5], [2, false, 0.0], [2, true, 0.5], [3, false, 0.0], [4, false, 0.0]]


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b81")
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


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	var c = g("coletor_fixo")
	match step:
		0:
			if t > 5.0:
				var hud = g("hud")
				if hud:
					hud.visible = false
				var cam = main.get_node("Camera2D")
				var iso = main.get_node("IsoView")
				cam.bounds = Rect2()
				cam.zoom = Vector2(1.7, 1.7)
				cam._target_zoom = 1.7
				cam.position = iso.to_screen(c.global_position) + Vector2(0, -70)
				cam._target_pos = cam.position
				step = 1
				t = 0.0
		1:
			var f: Array = FASES[fase]
			c.etapa = f[0]
			c.pago = f[1]
			c.progresso = f[2] * c.segundos_etapa(maxi(f[0], 1))
			c.refresh()
			if t > 1.2:
				var img := root.get_texture().get_image()
				img.save_png(out_dir.path_join("etapa_%d_%s.png" % [fase, "obra" if f[1] else "parado"]))
				fase += 1
				t = 0.0
				if fase >= FASES.size():
					print("ok ", fase)
					return true
	return false
