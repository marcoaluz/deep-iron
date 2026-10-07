extends SceneTree
## Bloco 70 (não é teste): fotos do conteúdo do S2/S3 — poças de ácido e de lava, jazidas de cristal,
## ventilador, Gosma e Magmante; Bloco 71: S4 (cachoeira, água, lava) e S5 (lago, gemas, casinhas); itens
## de arte: a vila antiga do leste, a rocha com ácido, o píer. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_fundo.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var _prox := 4.0
var _fotos := []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_fundo")
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


func _mira(alvo: Vector2, parada: int) -> void:
	var cam = main.get_node("Camera2D")
	var iso = g("iso_view")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(parada, 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.bounds = Rect2()
	cam.position = iso.to_screen(alvo)
	cam._target_pos = cam.position


func _prepara() -> void:
	var hud = g("hud")
	if hud:
		hud.visible = false
	g("elevador").unlock(false)
	g("elevador_abismo").unlocked = true
	for e in main.get_tree().get_nodes_in_group("elevadores"):
		e.unlocked = true
		e._apply(false)
	for m in main.get_tree().get_nodes_in_group("minerios"):
		m.on_unlock_changed(false)
	g("environment").set_leste_aberto(true, false)  # (itens de arte: a vila antiga do leste)
	var world: Node = g("village_hub").get_parent()
	var p2: Vector2 = world.get_node("PocaS2_2").global_position
	g("fundo").spawn_ventilador(p2 + Vector2(-40, -80))
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	ws[0].global_position = p2  # um ipezinho dentro do ácido
	var p3: Vector2 = world.get_node("PocaS3_3").global_position
	ws[1].global_position = p3 + Vector2(20, 0)
	var def = g("defense")
	var gos = def._spawn("gosma")
	var mag = def._spawn("magmante")
	var perto: Vector2 = g("village_hub").global_position + Vector2(120, 80)
	gos.global_position = perto
	mag.global_position = perto + Vector2(60, 20)
	gos.set_process(false)
	mag.set_process(false)
	_fotos = [
		["s2_pocas", p2 + Vector2(-60, 0), 2],
		["s2_jazida", world.get_node("JazidaS2_1").global_position, 3],
		["s3_lava", p3, 2],
		["s3_jazida", world.get_node("JazidaS3_2").global_position, 3],
		["criaturas", perto + Vector2(30, 10), 3],
		["s4_cachoeira", Vector2(-40, 2250), 2],
		["s4_lava", Vector2(-150, 2480), 2],
		["s5_lago", Vector2(0, 2990), 1],
		["s5_casas", Vector2(-250, 3080), 2],
		["s5_pier", Vector2(-150, 3000), 2],
		["s2_acido", world.get_node("PocaS2_1").global_position, 1],
		["leste_vila", g("environment").get_node("VilaAntiga1").global_position if g("environment").has_node("VilaAntiga1") else Vector2(2440, -40), 1],
	]


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		return true
	if t < _prox:
		return false
	if step == 0:
		_prepara()
	var i := step / 2
	if i >= _fotos.size():
		print("fotos em ", out_dir)
		return true
	var f: Array = _fotos[i]
	if step % 2 == 0:
		_mira(f[1], f[2])
		_prox = t + 2.5
	else:
		root.get_texture().get_image().save_png(out_dir.path_join(f[0] + ".png"))
		_prox = t + 0.2
	step += 1
	return false
