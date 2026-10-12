extends SceneTree
## Bloco 135 (não é teste): capturas das correções, uma por item.
## COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco135.gd -- <pasta de saída>
##   1_config_1366_125.png   as Configurações do menu inicial em 1366x768 a 125% (o rodapé fixo à vista)
##   2_janelas.png           o Centro, a ficha e o cartão de requisitos abertos juntos (lado a lado / cascata)
##   4_mineiro_jazida.png    mineiros nos postos de uma jazida (na frente da pedra)
##   5_migrantes_noite.png   migrantes no portão à noite: o ícone com o contador e a janela
##   6_construir_unicos.png  o CONSTRUIR: a Oficina "✔ Construído" e a Igreja "Em obra"
var main: Node
var menu: Node
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
	menu = load("res://scenes/ui/start_menu.tscn").instantiate()
	root.add_child(menu)


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("foto: ", nome)


func _process(delta: float) -> bool:
	t += delta
	_espera -= delta
	if _espera > 0.0:
		return false
	match passo:
		0:
			if t < 1.5:
				return false
			root.get_node("WindowManager").set_ui_scale(1.25)
			for b in menu.find_children("*", "Button", true, false):
				if String((b as Button).text) == "Configurações":
					(b as Button).pressed.emit()  # (como o jogador: o menu abre as Configurações)
			_proximo(1.5)
		1:
			_foto("1_config_1366_125")
			root.get_node("WindowManager").set_ui_scale(1.0)
			menu.queue_free()
			main = load("res://scenes/game/main.tscn").instantiate()
			main.founding_on_new_game = false
			root.add_child(main)
			current_scene = main
			_proximo(3.0)
		2:
			var hud := g("hud")
			var w: Node = get_nodes_in_group("ipezinhos")[0]
			hud.open_panel("hub")
			hud.open_panel("ficha", w)
			hud.mostra_requisitos("cozinheiro", "Cozinheiro", Color(0.95, 0.8, 0.5), w)
			_proximo(1.0)
		3:
			_foto("2_janelas")
			g("hud").close_panels()
			# mineiros nos postos de uma jazida, câmera perto
			var m: Node2D = get_nodes_in_group("minerios")[0]
			var ws: Array = get_nodes_in_group("ipezinhos")
			for i in mini(m.slot_count, ws.size()):
				ws[i].set_job("minerador", false)
				ws[i].global_position = m.get_slot_position(i)
				ws[i].set_physics_process(false)
			_camera(m.global_position, 3.0)
			_proximo(1.2)
		4:
			_foto("4_mineiro_jazida")
			for w in get_nodes_in_group("ipezinhos"):
				w.set_physics_process(true)
			var dn := g("day_night")
			dn.time = dn.tempo_da_hora(22.0)
			var mig := g("migrantes")
			mig.chama_grupo(3)
			_proximo(6.0)
		5:
			var mig := g("migrantes")
			var w: Node2D = mig.esperando[0].w if not mig.esperando.is_empty() else null
			if w:
				_camera(w.global_position, 1.6)
			g("hud").close_panels()
			g("hud")._refresh()
			g("hud").open_panel("migrantes")
			_proximo(1.2)
		6:
			_foto("5_migrantes_noite")
			var hud := g("hud")
			hud.close_panels()
			var dn := g("day_night")
			dn.time = dn.tempo_da_hora(12.0)
			var hub := g("village_hub")
			hub.level = maxi(int(hub.level), int(hub.igreja_estagio))
			load("res://scripts/props/canteiro.gd").order(self, "igreja", hub.global_position + Vector2(200, 200), 60.0)
			hud.toggle_build_menu()
			var bm: Node = hud._build_menu
			var k: int = bm.TAB_NAMES.find("Culto")
			if k < 0:
				k = 0
			bm._show_tab(k)
			_proximo(1.0)
		7:
			_foto("6_construir_unicos_igreja")
			var bm: Node = g("hud")._build_menu
			var k: int = bm.TAB_NAMES.find("Defesa e equipamento")
			if k >= 0:
				bm._show_tab(k)
			_proximo(0.8)
		8:
			var bm: Node = g("hud")._build_menu
			bm._scroll.scroll_vertical = int(bm._scroll.get_v_scroll_bar().max_value)  # (a Oficina fica embaixo)
			_proximo(0.6)
		9:
			_foto("6_construir_unicos_oficina")
			return true
	return false


func _proximo(segundos: float) -> void:
	passo += 1
	_espera = segundos


func _camera(p: Vector2, z: float) -> void:
	var c = main.get_node("Camera2D")
	c.set_target_zoom(z)
	c.zoom = Vector2(z, z)
	c.on_view_changed(p)
