extends SceneTree
## Bloco 107 (não é teste): a RUÍNA do vagonete da boca da mina (o carrinho velho parado) e depois de restaurado.
## COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco107b.gd -- <pasta>
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
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco107")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(n: String) -> Node:
	return main.get_tree().get_first_node_in_group(n)


func _foca(pos: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var alvo: Vector2 = main.get_node("IsoView").to_screen(pos)
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = alvo
	cam._target_pos = alvo


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT")
		return true
	var boca = g("bocas_mina")
	if passo == 0 and t > 4.0:
		g("hud").close_panels()
		_foca(boca._cart.global_position, 4.0)
		passo = 1
		t_mark = t
	elif passo == 1 and t - t_mark > 1.5:
		print("cart: ", boca._cart, " ruina=", boca._cart.ruina if boca._cart else "-", " vis=", boca._cart.visible if boca._cart else "-", " pos=", boca._cart.global_position if boca._cart else "-", " rail=", boca.rail, " boca=", boca.global_position, " restaurado=", boca.restaurado())
		root.get_texture().get_image().save_png(out_dir.path_join("vagonete_ruina.png"))
		boca.restaura_tudo()
		passo = 2
		t_mark = t
	elif passo == 2 and t - t_mark > 1.5:
		root.get_texture().get_image().save_png(out_dir.path_join("vagonete_restaurado.png"))
		print("FIM")
		return true
	return false
