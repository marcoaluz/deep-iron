extends SceneTree
## Bloco 110 (não é teste): fotos — o casal com o balão de CORAÇÃO no mapa e a FICHA do ipezinho (traços, habilidades,
## amigos, parceiro). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco110.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var a: Node
var b: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco110")
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


func _foca(pos: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var alvo: Vector2 = main.get_node("IsoView").to_screen(pos)
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = alvo
	cam._target_pos = alvo


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT")
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(10.0)
	if t - t_mark < (6.0 if passo == 1 else 1.5):
		return false
	t_mark = t
	var rel = g("relacoes")
	match passo:
		0:
			var eco = g("economy")
			a = eco.novo_ipezinho("menino")
			b = eco.novo_ipezinho("menina")
			for x in [a, b]:
				x.auto_mode = false
			a.tracos = ["trabalhador", "sociavel"]
			b.tracos = ["devoto"]
			a.habilidade = {"minerador": 0.62, "lenhador": 0.18}
			var c = eco.novo_ipezinho("menina")
			rel.soma(a, c, 40.0)
			rel.soma(a, b, 200.0)
		1:
			b.global_position = a.global_position + Vector2(18, 4)
			_foca(a.global_position, 4.0)
			a._mostra_balao("coracao")
			b._mostra_balao("coracao")
		2:
			_salva("110_casal_coracao")
			main.select(a)
			g("hud").open_panel("ficha", a)
		3:
			_salva("110_ficha")
			print("FIM")
			return true
	passo += 1
	return false
