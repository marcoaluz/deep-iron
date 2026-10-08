extends SceneTree
## Bloco 101 (não é teste): fotos dos MIGRANTES — o grupo esperando do lado de fora do portão (com o alerta) e a janela com
## os cartões. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco101.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco101")
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


func g(n: String) -> Node:
	return main.get_tree().get_first_node_in_group(n)


func _salva(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("tela: ", nome)


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT")
		return true
	var mig = g("migrantes")
	var hud = g("hud")
	if passo == 0 and t > 4.0:
		passo = 1
		g("founding").completa_populacao()
		mig.proximo = 1.0e9
		var grupo: Array = mig.chama_grupo(3)
		grupo[0].condicao = "ferido"
		grupo[1].condicao = "com_fome"
		hud.close_panels()
		var cam = main.get_node("Camera2D")
		var iso = main.get_node("IsoView")
		var alvo: Vector2 = iso.to_screen(g("barricadas").global_position + Vector2(-40, 0))
		cam.zoom = Vector2(2.2, 2.2)
		cam._target_zoom = 2.2
		cam.position = alvo
		cam._target_pos = alvo
		Engine.time_scale = 3.0
		t_mark = t
	elif passo == 1 and t - t_mark > 18.0:
		passo = 2
		Engine.time_scale = 1.0
		hud._refresh()
		_salva("01_migrantes_no_portao")
		hud.open_panel("migrantes")
		t_mark = t
	elif passo == 2 and t - t_mark > 1.5:
		_salva("02_cartoes")
		return true
	return false
