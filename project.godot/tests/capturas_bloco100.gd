extends SceneTree
## Bloco 100 (não é teste): fotos do sistema de missões — o rastreador do canto, a janela "Missões" (começo, com o andamento
## e depois de cumprir) e o aviso da missão cumprida. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco100.gd -- <pasta de saída>
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
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco100")
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
	if t > 90.0:
		print("TIMEOUT")
		return true
	var m = g("missoes")
	var hud = g("hud")
	if passo == 0 and t > 4.0:
		passo = 1
		m.cumpridas.clear()
		m.feitos = {}
		m.capitulo_liberado = 1
		m.contadores = {"invasoes": 0, "vendido": 0.0, "mortes": 0, "obras": {}}
		for c in main.get_tree().get_nodes_in_group("casas"):
			c.built = false
		var casas := main.get_tree().get_nodes_in_group("casas")
		for i in mini(1, casas.size()):
			casas[i].built = true
		var arm = g("armazens")
		for k in arm.stock:
			arm.stock[k] = 0.0
		arm.stock["ferro"] = 38.0
		arm._recount()
		m.confere()
		t_mark = t
	elif passo == 1 and t - t_mark > 1.5:
		passo = 2
		_salva("01_rastreador_no_jogo")
		hud.open_panel("missoes")
		t_mark = t
	elif passo == 2 and t - t_mark > 1.5:
		passo = 3
		_salva("02_janela_andamento")
		hud.close_panels()
		var casas := main.get_tree().get_nodes_in_group("casas")
		for c in casas:
			c.built = true
		var arm = g("armazens")
		arm.stock["ferro"] = 100.0
		arm._recount()
		m.confere()
		t_mark = t
	elif passo == 3 and t - t_mark > 1.5:
		passo = 4
		_salva("03_rastreador_quase")
		g("defense").invasion_ended.emit(3)
		t_mark = t
	elif passo == 4 and t - t_mark > 1.2:
		passo = 5
		_salva("04_missao_cumprida")
		hud.open_panel("missoes")
		t_mark = t
	elif passo == 5 and t - t_mark > 1.5:
		_salva("05_janela_capitulo_2")
		return true
	return false
