extends SceneTree
## Bloco 108 (não é teste): fotos da janela POLÍTICAS DA VILA — o padrão, uma opção clicada (o detalhe: ganha, custa, ânimo
## previsto, Confirmar), a espera depois de uma troca e a restrição do treinamento sem campo. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco108.gd -- <pasta de saída>
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
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco108")
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
	if t - t_mark < (8.0 if passo == 1 else 1.0):  # (o primeiro espera os banners de evento sumirem)
		return false
	t_mark = t
	var hud = g("hud")
	var pol = g("politicas")
	match passo:
		0:
			var eco = g("economy")
			while main.get_tree().get_nodes_in_group("ipezinhos").size() < 8:
				eco.novo_ipezinho()
			g("village_hub").level = 2
			hud.open_panel("politicas")
		1:
			_salva("108_politicas_padrao")
			hud._panels["politicas"]._seleciona("jornada", "estendida")
		2:
			_salva("108_politicas_detalhe_estendida")
			hud._panels["politicas"]._confirma()
			hud._panels["politicas"]._seleciona("racao", "reduzida")
		3:
			_salva("108_politicas_racao_reduzida")
			hud._panels["politicas"]._seleciona("jornada", "reduzida")
		4:
			_salva("108_politicas_espera")
			hud._panels["politicas"]._seleciona("seguranca", "treinamento")
		5:
			_salva("108_politicas_sem_campo")
			print("FIM")
			return true
	passo += 1
	return false
