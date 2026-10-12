extends SceneTree
## Bloco 130 (não é teste): capturas dos PISOS (caminhos) — uma vila com trilhas dos 3 tipos, o fantasma do pincel e o zoom.
## COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco130b.gd -- <pasta de saída> <prefixo>
var main: Node
var out_dir := ""
var prefixo := "depois"
var t := 0.0
var step := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas")
	prefixo = args[1] if args.size() > 1 else "depois"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _process(delta: float) -> bool:
	t += delta
	if step == 0 and t > 2.5:
		step = 1
		_monta()
	elif step == 1 and t > 4.5:
		step = 2
		_foto("trilhas")
		var cam = main.get_node("Camera2D")
		cam.set_target_zoom(3.0)
		cam.zoom = Vector2(3.0, 3.0)
	elif step == 2 and t > 6.0:
		step = 3
		_foto("zoom")
		_fantasma()
	elif step == 3 and t > 7.5:
		_foto("fantasma")
		return true
	return false


func _monta() -> void:
	var cam = get_first_node_in_group("caminhos")
	var eco = get_first_node_in_group("economy")
	var pl = get_first_node_in_group("caminho_placer")
	var hub = get_first_node_in_group("village_hub")
	eco.credits = 100000.0
	var arm = get_first_node_in_group("armazens")
	arm.stock["ferro"] = 5000.0
	arm._recount()
	var base: Vector2 = hub.global_position + Vector2(-120, 130)
	var tipos := ["terra", "cascalho", "pedra"]
	for k in 3:
		pl.begin(tipos[k])
		var a: Vector2 = base + Vector2(0, k * 70)
		pl.pinta_ate(a)
		pl.pinta_ate(a + Vector2(260, 0))
		pl.pinta_ate(a + Vector2(260, 40))
		pl.cancel()
	# um quadrado largo de pedra e uma curva
	pl.begin("pedra")
	for i in 5:
		var p: Vector2 = base + Vector2(330, -20 + i * 22)
		pl.pinta_ate(p)
		pl.pinta_ate(p + Vector2(110, 0))
	pl.cancel()
	var c = main.get_node("Camera2D")
	c.set_target_zoom(1.5)
	c.zoom = Vector2(1.5, 1.5)
	c.on_view_changed(base + Vector2(170, 80))


func _fantasma() -> void:
	var pl = get_first_node_in_group("caminho_placer")
	var hub = get_first_node_in_group("village_hub")
	pl.begin("cascalho")
	if pl.has_method("_fantasma"):
		pl._fantasma(hub.global_position + Vector2(-60, 340))
	main.get_node("Camera2D").on_view_changed(hub.global_position + Vector2(-60, 340))


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [prefixo, nome]))
	print("foto: ", nome)
