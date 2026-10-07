extends SceneTree
## Bloco 74 (não é teste): a superfície da maquete v3 no jogo — floresta | vila | mina. Fotos de cada
## área pra comparar com docs/arte/bloco72/maquete/superficie_v3_legenda.jpg. Com janela e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco74.gd -- <pasta de saída>
## Grava <pasta>/<vista>.jpg. O leste continua trancado (como numa partida nova).
const PATH := "user://savegame.json"
const ASSENTA := 1.6
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var vista := 0
var _vistas: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco74")
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


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func iso() -> Node:
	return main.get_node("IsoView")


func _tela(centro: Vector2, z: float) -> void:
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()
	cam.zoom_min = minf(cam.zoom_min, z)
	cam.iso_zoom_min = minf(cam.iso_zoom_min, z)
	cam.zoom = Vector2(z, z)
	cam._target_zoom = z
	cam.position = centro
	cam._target_pos = centro


func _enquadra(r: Rect2, folga := 1.08) -> void:
	var vis: Vector2 = root.get_visible_rect().size
	_tela(r.get_center(), minf(vis.x / (r.size.x * folga), vis.y / (r.size.y * folga)))


## Retângulo na tela iso de um retângulo da lógica (cantos no chão, e no alto da montanha).
func _tela_de(r: Rect2, z_alto := 0.0) -> Rect2:
	var v = iso()
	var out := Rect2(v.to_screen(r.position), Vector2.ZERO)
	for c in [Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		out = out.expand(v.to_screen(c))
		if z_alto > 0.0:
			out = out.expand(v.to_screen(c, z_alto))
	return out


func _prepara() -> void:
	var hud = g("hud")
	if hud:
		hud.visible = false
	var env = g("environment")
	var gr: Rect2 = env.iso_ground_rect()
	var sup := Rect2(gr.position.x, gr.position.y, env.leste_x() - gr.position.x, gr.size.y)
	var mina := Rect2(560, -1040, 680, 1470)
	_vistas = [
		["01_superficie_tres_areas", func(): _enquadra(_tela_de(sup, 380.0), 1.02)],
		["02_mina_montanha", func(): _enquadra(_tela_de(mina, 380.0), 1.0)],
		["03_boca_vagonete_armazem", func(): _tela(iso().to_screen(Vector2(860, -60)), 1.0)],
		["04_degraus_galerias", func(): _tela(iso().to_screen(Vector2(980, -330), 200.0), 1.0)],
		["05_portao_palicada", func(): _tela(iso().to_screen(Vector2(-300, -40)), 1.0)],
		["06_floresta", func(): _enquadra(_tela_de(Rect2(gr.position.x, gr.position.y, env.palisade_x - gr.position.x, gr.size.y)), 1.02)],
		["07_vila", func(): _enquadra(_tela_de(Rect2(env.palisade_x, -760, 560 - env.palisade_x, 1190)), 1.02)],
	]


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		return true
	if step == 0:
		if t > 4.0:
			_prepara()
			step = 1
			t = 0.0
			_vistas[0][1].call()
		return false
	if t > ASSENTA:
		var img := root.get_texture().get_image()
		img.save_jpg(out_dir.path_join(_vistas[vista][0] + ".jpg"), 0.88)
		print("foto ", _vistas[vista][0])
		vista += 1
		t = 0.0
		if vista >= _vistas.size():
			return true
		_vistas[vista][1].call()
	return false
