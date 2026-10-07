extends SceneTree
## Bloco 80 (não é teste): o Ferrugento robô no jogo — saindo da boca do poço, andando, atacando e com o
## minério roubado nas costas, ao lado dos ipezinhos (pra conferir tamanho e animação). Com janela e APPDATA
## isolado:   <Godot>.exe --path . -s res://tests/capturas_bloco80.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var fs: Array = []
var quadros: Array[Image] = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	out_dir = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("user://capturas_b80")
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
	match step:
		0:
			if t > 5.0:
				var hud = g("hud")
				if hud:
					hud.visible = false
				var def = g("defense")
				g("elevador").unlock(false)
				var boca: Vector2 = def.boca_poco()
				for i in 3:
					var f = def._spawn("ferrugento")
					f.set_process(false)
					f.global_position = boca + Vector2(-40 + 40 * i, 50)
					fs.append(f)
				fs[1].looted = true
				var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
				for k in mini(2, ws.size()):
					ws[k].global_position = boca + Vector2(-60 + 120 * k, 95)
					ws[k].set_job("guarda")
					ws[k].manual_override_time = 999.0
				var cam = main.get_node("Camera2D")
				var iso = main.get_node("IsoView")
				cam.bounds = Rect2()
				cam.zoom = Vector2(3, 3)
				cam._target_zoom = 3.0
				cam.position = iso.to_screen(boca + Vector2(0, 70))
				cam._target_pos = cam.position
				step = 1
				t = 0.0
		1:
			# um parado, um andando (com carga), um atacando
			fs[0]._andando = false
			fs[1]._andando = true
			fs[1]._andado += delta * fs[1].speed
			fs[1]._visual.flip_h = false
			if int(t * 10) % 14 == 0:
				fs[2]._attack_at = fs[2]._anim
			for f in fs:
				f._anim += delta
				f._atualiza_visual()
			if t > 0.4 and quadros.size() < 40 and Engine.get_process_frames() % 3 == 0:
				var img := root.get_texture().get_image()
				quadros.append(img)
			if quadros.size() >= 40:
				for k in quadros.size():
					quadros[k].save_png(out_dir.path_join("q_%03d.png" % k))
				print("ok ", quadros.size())
				return true
	return false
