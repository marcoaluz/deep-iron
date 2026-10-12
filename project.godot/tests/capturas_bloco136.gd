extends SceneTree
## Bloco 136 (não é teste): capturas das três janelas novas.
## COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco136.gd -- <pasta de saída>
##   1_caixa_venda.png      o armazém com a caixa de venda aberta (gema azul)
##   2_funcao_minerador.png a janela da função (quem tem e quem não tem)
##   2b_trocar_menu.png     o menu "Trocar ▾" com os ✓/✗
##   3_ficha_pesquisador.png a ficha do pesquisador: a pesquisa de agora, a fila e o corpo do Lumívoro pronto pra estudar
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var _espera := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	root.size = Vector2i(1366, 768)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("foto: ", nome)


func _proximo(segundos: float) -> void:
	passo += 1
	_espera = segundos


func _process(delta: float) -> bool:
	t += delta
	_espera -= delta
	if _espera > 0.0:
		return false
	match passo:
		0:
			if t < 3.0:
				return false
			var eco := g("economy")
			eco.credits = 3000.0
			for i in 6:
				eco.novo_ipezinho("menina" if i % 2 == 0 else "menino")
			var arm: Node2D = get_nodes_in_group("armazens")[0]
			arm.stock["gema_azul"] = 200.0
			arm.stock["ferro"] = 300.0
			arm.stock["carvao"] = 120.0
			arm._recount()
			var cat := g("catalogo")
			cat.estuda("gema_azul", null)
			var hud := g("hud")
			hud.open_panel("armazem")
			hud._panels["armazem"].seleciona("gema_azul")
			_proximo(1.0)
		1:
			_foto("1_caixa_venda")
			var hud := g("hud")
			hud._panels["armazem"]._caixa.cancelar()
			hud.close_panels()
			var gente: Array = get_nodes_in_group("ipezinhos")
			for i in gente.size():
				gente[i].set_job("minerador" if i < 3 else ("lenhador" if i < 5 else gente[i].ROLE_IDLE), false)
			main.selection.clear()
			main.toggle_miner()
			_proximo(1.5)
		2:
			_foto("2_funcao_minerador")
			var p = g("hud")._panels["funcoes"]
			var w: Node = p.sem_funcao()[0]
			var mb: MenuButton = p._linhas[w].trocar
			mb.show_popup()
			_proximo(0.8)
		3:
			_foto("2b_trocar_menu")
			var p = g("hud")._panels["funcoes"]
			for w in p._linhas:
				p._linhas[w].trocar.get_popup().hide()
			var hud := g("hud")
			hud.close_panels()
			var res := g("research")
			var cat := g("catalogo")
			var hub: Node2D = g("village_hub")
			if res.labs().is_empty():
				res.spawn_lab(hub.global_position + Vector2(260, 120))
			var w: Node = get_nodes_in_group("ipezinhos")[5]
			w.set_job("pesquisador", false)
			res.pede("carrinhos")
			res.add_points(30.0)
			res.pede("medicina")
			cat.avista("lumivoro", false)
			var corpo: Node2D = load("res://scripts/props/corpo_criatura.gd").new()
			corpo.kind = "lumivoro"
			corpo.especie = "lumivoro"
			var pz: Array = cat.prazo_corpo()
			corpo.prazo_dia = int(pz[0])
			corpo.prazo_t = float(pz[1])
			main.get_node("World").add_child(corpo)
			corpo.global_position = hub.global_position + Vector2(120, 160)
			cat.pede_estudo("cobre")
			hud.open_panel("ficha", w)
			_proximo(1.5)
		4:
			_foto("3_ficha_pesquisador")
			return true
	return false
