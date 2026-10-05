extends SceneTree
## Bloco 78 (não é teste): os MARCOS de cada andar (maquete v4, docs/NovoLayout) de perto — a vila de mineração
## nas galerias, a caverna de cristais (S2), o fóssil gigante (S3), a fonte termal (S4) e a cidade subterrânea (S5).
## Com janela e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco78.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const ZOOM := 1.6
## [nome da foto, ponto da lógica no meio da vista] — as galerias são só desenho (sem chão na lógica): ponto
## da TELA (a caixa delas no andares.json, art (-400, 536) na altura -384)
const GALERIAS_TELA := Vector2(-60, 700)
const VISTAS := [["01_galerias_vila_mineracao", Vector2.INF], ["02_s2_cristais", Vector2(-380, 3740)],
	["03_s3_fossil", Vector2(-480, 4110)], ["04_s4_fonte_termal", Vector2(-360, 4540)],
	["05_s5_cidade", Vector2(-480, 4920)]]
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var vista := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco78")
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


func _foca(p: Vector2) -> void:
	var cam = main.get_node("Camera2D")
	var iso = main.get_node("IsoView")
	cam.bounds = Rect2()
	cam.zoom = Vector2(ZOOM, ZOOM)
	cam._target_zoom = ZOOM
	var c: Vector2 = GALERIAS_TELA if p == Vector2.INF else iso.to_screen(p)
	cam.position = c
	cam._target_pos = c


func _process(delta: float) -> bool:
	t += delta
	if step == 0:
		if t > 5.0:
			var hud = main.get_tree().get_first_node_in_group("hud")
			if hud:
				hud.visible = false
			# os andares abertos, como no fim do jogo (pra luz e névoa dos andares)
			for e in main.get_tree().get_nodes_in_group("elevadores"):
				if e.has_method("set") and e.get("unlocked") != null:
					e.set("unlocked", true)
			step = 1
			t = 0.0
			_foca(VISTAS[0][1])
		return false
	if t > 1.6:
		var img := root.get_texture().get_image()
		img.save_jpg(out_dir.path_join(VISTAS[vista][0] + ".jpg"), 0.9)
		print("foto ", VISTAS[vista][0])
		vista += 1
		t = 0.0
		if vista >= VISTAS.size():
			print("ok")
			return true
		_foca(VISTAS[vista][1])
	return false
