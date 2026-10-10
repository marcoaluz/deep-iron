extends SceneTree
## Bloco 109 (não é teste): fotos — o cartão do selecionado com a FUNÇÃO SECUNDÁRIA (o engenheiro sem obra cortando lenha,
## vestido de lenhador) e o botão que troca. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco109.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var eng: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco109")
	DirAccess.make_dir_recursive_absolute(out_dir)
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
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


func _foca(pos: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var alvo: Vector2 = main.get_node("IsoView").to_screen(pos)
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = alvo
	cam._target_pos = alvo


func _process(delta: float) -> bool:
	t += delta
	if t > 150.0:
		print("TIMEOUT")
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(9.5)
	if t - t_mark < (2.0 if passo != 1 else 14.0):
		return false
	t_mark = t
	match passo:
		0:
			var eco = g("economy")
			while main.get_tree().get_nodes_in_group("ipezinhos").size() < 4:
				eco.novo_ipezinho()
			eng = main.get_tree().get_nodes_in_group("ipezinhos")[0]
			eng.set_job("engenheiro")
			eng.wake_decision()
		1:
			main.select(eng)
			_foca(eng.global_position, 3.0)
		2:
			_foca(eng.global_position, 3.0)
			_salva("109_secundaria_engenheiro_lenhador")
			g("hud")._troca_secundaria()
		3:
			_salva("109_secundaria_botao_trocado")
			print("FIM estado=%s secundaria=%s" % [eng.get_state(), eng.funcao_secundaria])
			return true
	passo += 1
	return false
