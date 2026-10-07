extends SceneTree
## Bloco 96 (não é teste): fotos das obras com material — o engenheiro buscando, levando (a carga no corpo) e a
## pilha do material entregue ao lado da obra, mais a gaveta Obras do HUD (entregue/necessário e o Cancelar).
## Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco96.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const TELAS := ["obra_levando", "obra_pilha", "obra_gaveta"]
var main: Node
var out_dir := ""
var t := 0.0
var cur := -1
var t_mark := 0.0
var obra: Node = null
var eng: Node = null


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco96")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(n: String) -> Node:
	return main.get_tree().get_first_node_in_group(n)


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func _salva(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("tela: ", nome)


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		print("TIMEOUT")
		return true
	if cur < 0 and t > 4.0:
		cur = 0
		var eco = g("economy")
		eco.credits = 5000.0
		var arm = g("armazens")
		arm.wood_stored = 200.0
		arm.stock["ferro"] = 200.0
		arm._recount()
		eng = main.get_tree().get_nodes_in_group("ipezinhos")[0]
		eng.set_job("engenheiro")
		var pos := spot_near(g("village_hub").global_position + Vector2(220, 140))
		g("morale")._confirm_park(pos)
		for c in main.get_tree().get_nodes_in_group("canteiros"):
			obra = c
		main.get_node("Camera2D").follow_target = eng
		t_mark = t
		return false
	if cur == 0 and not eng.material_mao.is_empty() and t - t_mark > 1.0:
		_salva("obra_levando")
		cur = 1
		main.get_node("Camera2D").follow_target = null
		main.get_node("Camera2D").focus_on(obra.global_position)
		t_mark = t
	elif cur == 1 and obra and is_instance_valid(obra) and not obra._obra.pilha(obra.obra_progress()).is_empty() and t - t_mark > 2.0:
		_salva("obra_pilha")
		cur = 2
		main.get_node("HUD").toggle_obras()
		t_mark = t
	elif cur == 2 and t - t_mark > 1.5:
		_salva("obra_gaveta")
		return true
	return false
