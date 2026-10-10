extends SceneTree
## Bloco 113 (não é teste): fotos da tela de NOVA PARTIDA (Normal, Personalizado, Criativo) e da janela da DEFESA com o tier.
## Roda COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco113.gd -- <pasta de saída>
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var sm: Node
var menu: Node
var main: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco113")
	DirAccess.make_dir_recursive_absolute(out_dir)
	sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	load("res://scripts/core/settings.gd").set_value("jogo", "guia_primeiro_dia", false)  # (o cartão do capataz tamparia a janela)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)


func _salva(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("tela: ", nome)


func _proximo() -> void:
	passo += 1
	t_mark = t


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		print("TIMEOUT no passo %d" % passo)
		return true
	match passo:
		0:
			menu = load("res://scenes/ui/start_menu.tscn").instantiate()
			root.add_child(menu)
			current_scene = menu
			_proximo()
		1:
			if t - t_mark < 1.0:
				return false
			menu._abre_nova()
			_proximo()
		2:
			if t - t_mark < 0.6:
				return false
			_salva("nova_partida_normal")
			menu._nova.seleciona("ferro")
			_proximo()
		3:
			if t - t_mark < 0.6:
				return false
			_salva("nova_partida_ferro")
			menu._nova.seleciona("personalizado")
			menu._nova.slider("fome_mult").value = 1.3
			menu._nova.slider("primeira_invasao_dia").value = 6
			_proximo()
		4:
			if t - t_mark < 0.6:
				return false
			_salva("nova_partida_personalizado")
			menu._nova.seleciona("criativo")
			_proximo()
		5:
			if t - t_mark < 0.6:
				return false
			_salva("nova_partida_criativo")
			menu.queue_free()
			sm.dificuldade_nova = {"perfil": "ferro"}
			main = load("res://scenes/game/main.tscn").instantiate()
			main.founding_on_new_game = false
			root.add_child(main)
			current_scene = main
			_proximo()
		6:
			if t - t_mark < 3.0:
				return false
			get_first_node_in_group("defense").wave = 7
			get_first_node_in_group("hud").open_panel("defesa")
			_proximo()
		7:
			if t - t_mark < 1.0:
				return false
			_salva("defesa_tier_ferro")
			print("FIM")
			return true
	return false
