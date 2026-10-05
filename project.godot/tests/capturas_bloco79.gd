extends SceneTree
## Bloco 79 (não é teste): a FERROVIA DE CARGA no jogo — estações nos 4 andares, o cavalete à direita da espiral
## e os carrinhos subindo. Com janela e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco79.gd -- <pasta de saída>
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
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco79")
	DirAccess.make_dir_recursive_absolute(out_dir)
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


func _cam(c: Vector2, z: float) -> void:
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()
	cam.zoom_min = minf(cam.zoom_min, z)
	cam.iso_zoom_min = minf(cam.iso_zoom_min, z)
	cam.zoom = Vector2(z, z)
	cam._target_zoom = z
	cam.position = c
	cam._target_pos = c


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_jpg(out_dir.path_join(nome + ".jpg"), 0.9)
	print("foto ", nome)


func _process(delta: float) -> bool:
	t += delta
	var iso = main.get_node("IsoView")
	match step:
		0:
			if t > 5.0:
				var hud = main.get_tree().get_first_node_in_group("hud")
				if hud:
					hud.visible = false
				var hub = main.get_tree().get_first_node_in_group("village_hub")
				var env = main.get_tree().get_first_node_in_group("environment")
				var k := 0
				for id in ["S2", "S3", "S4", "S5"]:
					var n = preload("res://scripts/core/niveis.gd").por_id(id)
					var e = hub.spawn_ferrovia(id, env.ponto_ferrovia(n))
					e.stock["ferro"] = 40.0
					e._wait_t = 99.0
					e.cart_wait = 1.0 + k * 2.5
					k += 1
				Engine.time_scale = 3.0
				step = 1
				t = 0.0
		1:
			if t > 5.0:
				Engine.time_scale = 1.0
				var px: Vector2 = iso.ferrovia_postes()
				var topo: Vector2 = iso.ferrovia_topo()
				_cam(Vector2(px.x - 200, (topo.y + 3900) * 0.5), 0.3)
				step = 2
				t = 0.0
		2:
			if t > 1.2:
				_foto("01_coluna_com_ferrovia")
				var px: Vector2 = iso.ferrovia_postes()
				_cam(Vector2(px.x - 120, 2400), 1.0)
				step = 3
				t = 0.0
		3:
			if t > 1.2:
				_foto("02_cavalete_de_perto")
				var f = main.get_tree().get_nodes_in_group("ferrovias")[0]
				_cam(iso.to_screen(f.global_position) + Vector2(150, -40), 1.4)
				step = 4
				t = 0.0
		4:
			if t > 1.2:
				_foto("03_estacao_e_doca_s2")
				var px: Vector2 = iso.ferrovia_postes()
				_cam(iso.ferrovia_topo() + Vector2(-120, 60), 1.2)
				step = 5
				t = 0.0
		5:
			if t > 1.2:
				_foto("04_plataforma_na_superficie")
				print("ok")
				return true
	return false
