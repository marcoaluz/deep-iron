extends SceneTree
## Desempenho e GIF (não é teste): abre a partida em 1920×1080 com a vista iso e a arte nova,
## mede o tempo de quadro em 3 situações (vila de perto, a parada "longe", e com 20 ipezinhos a
## mais andando) e grava quadros de um trecho de partida pra montar um GIF.
## Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/desempenho_iso.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const MEASURE := 6.0
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var t_mark := 0.0
var frames := []
var shots := 0
var results := []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://desempenho")
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("gif"))
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _aim(ground: Vector2, stop_index: int) -> void:
	var cam = main.get_node("Camera2D")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(stop_index, 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(ground)


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT")
		return true
	frames.append(delta)
	match step:
		0:
			if t > 3.0:
				var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
				var jobs := ["minerador", "engenheiro", "cozinheiro"]
				for i in ws.size():
					ws[i].set_job(jobs[i % jobs.size()])
				_aim(Vector2(-200, -150), 2)
				_next(1)
		1:
			if t - t_mark > MEASURE:
				_report("vila de perto (1 px de arte = %.0f px de tela)" % main.get_node("Camera2D").art_pixel_screen(main.get_node("Camera2D").zoom.x))
				_aim(Vector2(-100, -100), 0)
				_next(2)
		2:
			if t - t_mark > MEASURE:
				_report("parada longe (mapa quase inteiro)")
				var eco = main.get_node("Economy")
				eco.max_workers = 40
				var scene: PackedScene = load("res://scenes/characters/Ipezinho.tscn")
				var jobs := ["minerador", "lenhador", "cozinheiro", "guarda", "engenheiro"]
				for i in 20:
					var w = scene.instantiate()
					w.position = Vector2(-300 + (i % 5) * 40, -200 + (i / 5) * 30)
					main.get_node("World").add_child(w)
					w.set_job(jobs[i % jobs.size()])
				_next(3)
		3:
			if t - t_mark > MEASURE:
				_report("parada longe + 20 ipezinhos a mais trabalhando")
				# mapa cheio: +17 (40 no total), noite (tochas e lanternas acesas) e invasão
				var scene: PackedScene = load("res://scenes/characters/Ipezinho.tscn")
				for i in 17:
					var w = scene.instantiate()
					w.position = Vector2(-200 + (i % 6) * 40, -100 + (i / 6) * 30)
					main.get_node("World").add_child(w)
					w.set_job(["minerador", "lenhador", "guarda"][i % 3])
				var dn = main.get_node("DayNight")
				dn.time = dn.day_duration + 5.0
				var def = main.get_tree().get_first_node_in_group("defense")
				if def:
					def.start_invasion()
				_next(5)
		5:
			if t - t_mark > MEASURE:
				_report("mapa cheio: 40 ipezinhos, noite com luzes, invasão (parada longe)")
				_aim(Vector2(-200, -150), 2)
				_next(6)
		6:
			if t - t_mark > MEASURE:
				_report("mapa cheio, zoom de jogo (vila de perto)")
				var dn = main.get_node("DayNight")
				dn.time = 30.0
				_aim(Vector2(-150, -120), 2)
				_next(4)
		4:
			# trecho de partida pro GIF: um quadro a cada 0,12 s
			if t - t_mark > 0.12 * shots and shots < 40:
				root.get_texture().get_image().save_png(out_dir.path_join("gif/q%02d.png" % shots))
				shots += 1
			elif shots >= 40:
				var f := FileAccess.open(out_dir.path_join("desempenho.txt"), FileAccess.WRITE)
				f.store_string("\n".join(results))
				f.close()
				return true
	return false


func _next(s: int) -> void:
	step = s
	t_mark = t
	frames.clear()


func _report(what: String) -> void:
	var fr: Array = frames.slice(30)  # tira o começo (assentar câmera/zoom)
	if fr.is_empty():
		return
	var tot := 0.0
	var worst := 0.0
	var sorted := fr.duplicate()
	sorted.sort()
	for d in fr:
		tot += d
		worst = maxf(worst, d)
	var avg: float = tot / fr.size()
	var p99: float = sorted[int(sorted.size() * 0.99) - 1]
	var line := "%s: %.0f fps em média (%.1f ms), 99%% dos quadros até %.1f ms, pior %.1f ms" % [what, 1.0 / avg, avg * 1000.0, p99 * 1000.0, worst * 1000.0]
	results.append(line)
	print(line)
