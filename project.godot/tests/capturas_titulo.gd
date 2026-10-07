extends SceneTree
## Prompt 26 (não é teste): fotos/quadros do menu inicial animado e da tela de carregamento.
## Roda COM JANELA e APPDATA isolado (precisa de um save na pasta isolada pra mostrar "Continuar"):
##   <Godot>.exe --path . -s res://tests/capturas_titulo.gd -- <pasta de saída>
const Carregando := preload("res://scripts/ui/carregando.gd")
var out_dir := ""
var t := 0.0
var n := 0
var fase := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_titulo")
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.size = Vector2i(1280, 720)
	var m = load("res://scenes/ui/start_menu.tscn").instantiate()
	root.add_child(m)
	current_scene = m


func _process(delta: float) -> bool:
	t += delta
	if fase == 0 and t > 2.0 and t > 2.0 + n * 0.15:
		root.get_texture().get_image().save_png(out_dir.path_join("menu_%02d.png" % n))
		n += 1
		if n >= 12:
			fase = 1
			Carregando.mostra(self)
			t = 0.0
	elif fase == 1 and t > 1.0:
		root.get_texture().get_image().save_png(out_dir.path_join("carregando.png"))
		print("ok")
		return true
	return false
