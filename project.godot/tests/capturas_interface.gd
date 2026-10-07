extends SceneTree
## Prompts 23 a 26 (não é teste): fotos do retrato do selecionado, faixa com ilustração, corte da
## mina, vitória e derrota. Se houver user://save_copia.json (cópia de um save), carrega ele (os
## dados de verdade no corte). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_interface.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const COPIA := "user://save_copia.json"
const TELAS := ["retrato_e_faixa", "corte_mina", "vitoria", "derrota"]
var main: Node
var out_dir := ""
var t := 0.0
var cur := -1
var t_mark := 0.0
var carregou := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_interface")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	root.size = Vector2i(1280, 720)
	var dados = sm.read_save_file(COPIA) if FileAccess.file_exists(COPIA) else null
	if dados != null:
		sm._start_loaded.call_deferred(dados)  # a partida do save (troca de cena)
		carregou = true
		return
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func node(g: String) -> Node:
	return main.get_tree().get_first_node_in_group(g)


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT")
		return true
	if cur < 0:
		if main == null or not is_instance_valid(main):
			if current_scene != null and current_scene.has_node("World"):
				main = current_scene
				print("save carregado" if carregou else "partida nova")
			return false
		if t > 6.0:
			node("day_night").time_scale = 0.0
			_next()
		return false
	if t - t_mark > 1.8:
		root.get_texture().get_image().save_png(out_dir.path_join(TELAS[cur] + ".png"))
		print("tela: ", TELAS[cur])
		if cur + 1 >= TELAS.size():
			return true
		_next()
	return false


func _next() -> void:
	cur += 1
	var hud := node("hud")
	match TELAS[cur]:
		"retrato_e_faixa":
			var ws := main.get_tree().get_nodes_in_group("ipezinhos")
			var w = ws[ws.size() - 1]
			main.select(w)
			var cam = main.get_node("Camera2D")
			cam.focus_on(w.global_position)
			hud.show_banner("INVASÃO! (onda 3)", "4 Lumívoros e 1 Ferrugento. Aguentem até o amanhecer.")
		"corte_mina":
			for c in hud.get_children():
				if c.has_meta("banner"):
					c.queue_free()
			hud._corte.abre()
		"vitoria":
			hud._corte.fecha()
			node("sun").win()
		"derrota":
			for l in main.get_tree().root.get_children():
				if l.is_in_group("victory_screen"):
					l.queue_free()
			main.get_tree().paused = false
			node("morale")._expel()
	t_mark = t
