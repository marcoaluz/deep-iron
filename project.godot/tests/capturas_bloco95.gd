extends SceneTree
## Bloco 95 (não é teste): fotos do layout da interface — a tela do jogo, um ipezinho selecionado e a
## janela CONSTRUIR em cada aba (o ANTES e o DEPOIS do layout v2). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco95.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var cur := -1
var t_mark := 0.0
var telas: Array[String] = ["hud_jogo", "hud_selecionado"]
## Telas que só existem no DEPOIS (o layout v2): ficam depois das do ANTES.
const EXTRAS := ["v2_pessoas", "v2_obras", "v2_avisos", "v2_construir_90", "v2_construir_125", "v2_mapa_rotulo", "v2_baloes"]
var depois := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco95")
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
	var bm_script: GDScript = load("res://scripts/core/build_menu.gd")
	for i in bm_script.TAB_NAMES.size():
		telas.append("construir_%02d" % i)
	depois = bm_script.get_script_constant_map().has("TAB_CURTO")  # (o menu do Bloco 95)
	if depois:
		telas.append_array(EXTRAS)


func node(g: String) -> Node:
	return main.get_tree().get_first_node_in_group(g)


func _build_menu() -> Node:
	for c in node("hud").get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("build_menu.gd"):
			return c
	return null


func _process(delta: float) -> bool:
	t += delta
	if t > 180.0:
		print("TIMEOUT")
		return true
	if cur < 0:
		if t > 4.0:
			node("day_night").time_scale = 0.0
			node("economy").credits = 600.0  # uns cartões liberados, outros não
			_next()
		return false
	if t - t_mark > 2.6:
		root.get_texture().get_image().save_png(out_dir.path_join(telas[cur] + ".png"))
		print("tela: ", telas[cur])
		if cur + 1 >= telas.size():
			return true
		_next()
	return false


func _next() -> void:
	cur += 1
	var nome := telas[cur]
	var hud := node("hud")
	if nome.begins_with("v2_"):
		main.get_node("Camera2D").follow_target = null
		_build_menu().visible = false
		if hud.has_method("_fecha_gavetas"):
			hud._fecha_gavetas()
	match nome:
		"v2_pessoas":
			main.select(null)
			hud.toggle_pessoas()
		"v2_obras":
			var eco := node("economy")
			eco.credits = 5000.0
			var arm := node("armazens")
			for k in ["ferro", "cobre", "carvao"]:
				arm.stock[k] = 400.0
			arm.wood_stored = 400.0
			arm.total_stored = arm.stock.values().reduce(func(x, y): return x + y, 0.0)  # (só recalcula quando chega carga)
			var hub := node("village_hub")
			if hub and hub.has_method("buy_upgrade"):
				hub.buy_upgrade("trilhas")  # uma obra encomendada, sem engenheiro (martelo cinza)
			hud.toggle_obras()
		"v2_avisos":
			hud.show_toast("Jogo salvo (manual)")
			hud.show_toast("Sem comida na cozinha!", hud.COLOR_HUNGER_BAD, node("comedouros") if node("comedouros") else null)
			hud.show_toast("INVASÃO hoje às 22:00", Color(1.0, 0.6, 0.45))
		"v2_construir_90", "v2_construir_125":
			root.get_node("WindowManager").set_ui_scale(0.9 if nome.ends_with("90") else 1.25)
			var bm := _build_menu()
			bm.visible = false
			bm.toggle.call_deferred()
		"v2_mapa_rotulo":
			root.get_node("WindowManager").set_ui_scale(1.0)
			var iso := node("iso_view")
			var coz := node("comedouros")
			if iso and coz:
				iso.foco = coz  # o rótulo inteiro, como com o mouse em cima
		"v2_baloes":
			node("iso_view").foco = null
			var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
			main.get_node("Camera2D").follow_target = w  # o balão de motivo de quem está parado
	if nome == "hud_selecionado":
		var ws := main.get_tree().get_nodes_in_group("ipezinhos")
		main.select(ws[0])
	elif nome.begins_with("construir_"):
		main.select(null)
		var bm := _build_menu()
		if not bm.visible:
			bm.toggle()
		bm._show_tab(int(nome.substr(10)))
	t_mark = t
