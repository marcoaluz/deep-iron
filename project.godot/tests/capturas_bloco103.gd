extends SceneTree
## Bloco 103 (não é teste): fotos do BESTIÁRIO — o corpo do Lumívoro no chão com a pesquisadora estudando, o cartão da
## descoberta e a janela da Defesa (a previsão e as espécies). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco103.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var pesq: Node = null


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco103")
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
	if t > 150.0:
		print("TIMEOUT")
		return true
	var cat = g("catalogo")
	var hud = g("hud")
	if passo == 0 and t > 4.0:
		passo = 1
		var mig = g("migrantes")
		if mig:
			mig.proximo = 1.0e9
		for id in ["cobre", "carvao", "coelho"]:
			cat.estuda(id, null)
		cat.segundos_estudo = 25.0
		var hub = g("village_hub")
		var lum: Node2D = load("res://scenes/creatures/lumivoro.tscn").instantiate()
		lum.position = hub.global_position + Vector2(80, 80)
		main.get_node("World").add_child(lum)
		lum.call_deferred("die", true)
		pesq = main.get_tree().get_nodes_in_group("ipezinhos")[0]
		pesq.set_job("pesquisador")
		hud.close_panels()
		Engine.time_scale = 3.0
		t_mark = t
	elif passo == 1 and pesq and String(pesq._campo.get("fase", "")) == "anotando":
		passo = 2
		Engine.time_scale = 1.0
		_foca(pesq.global_position, 2.6)
		t_mark = t
	elif passo == 1 and t - t_mark > 80.0:
		passo = 2
		t_mark = t
	elif passo == 2 and t - t_mark > 2.0:
		hud._refresh()
		_salva("01_pesquisadora_no_corpo")
		cat.segundos_estudo = 0.5
		Engine.time_scale = 3.0
		passo = 3
		t_mark = t
	elif passo == 3 and cat.estudado("lumivoro"):
		Engine.time_scale = 1.0
		passo = 4
		t_mark = t
	elif passo == 3 and t - t_mark > 60.0:
		cat.estuda("lumivoro", pesq)
	elif passo == 4 and t - t_mark > 1.2:
		_salva("02_cartao_da_descoberta")
		cat.avista("ferrugento", false)
		passo = 45
		t_mark = t
	elif passo == 45 and t - t_mark > 8.0:  # (o cartão some antes da foto da Defesa)
		hud.open_panel("defesa")
		passo = 5
		t_mark = t
	elif passo == 5 and t - t_mark > 1.5:
		_salva("03_defesa_bestiario")
		return true
	return false
