extends SceneTree
## Bloco 137 (não é teste): capturas.
## COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco137.gd -- <pasta de saída>
##   1_padre_chega.png    o padre entrando ferido pelo portão, com o banner
##   2_hora_social.png    a hora social: os guardas da 1ª turma e o padre nas rodas (a outra turma no posto)
##   3_f3_som.png         F3 > Som: as candidatas da noite com o "Ouvir"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var _espera := 0.0
var _pd: Node2D


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


func _camera(p: Vector2, z: float) -> void:
	var c = main.get_node("Camera2D")
	c.set_target_zoom(z)
	c.zoom = Vector2(z, z)
	c.on_view_changed(p)


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
			eco.credits = 9999.0
			for i in 8:
				eco.novo_ipezinho("menina" if i % 2 == 0 else "menino")
			var dn := g("day_night")
			dn.time = dn.tempo_da_hora(10.0)
			var hub: Node2D = g("village_hub")
			var cal := g("calendario")
			hub.level = maxi(int(hub.level), int(cal.padre_estagio))
			cal.padre_chegou = true  # (a chegada é chamada à mão, sem o atraso)
			_pd = cal.chega_padre()
			_camera(_pd.global_position, 2.4)
			_proximo(2.5)
		1:
			_camera(_pd.global_position + Vector2(0, -20), 2.4)
			_proximo(0.4)
		2:
			_foto("1_padre_chega")
			_pd._heal()
			var hub: Node2D = g("village_hub")
			var cal := g("calendario")
			if cal.igreja() == null:
				hub.spawn_igreja(hub.global_position + Vector2(320, 220))
			var gente: Array = get_nodes_in_group("ipezinhos").filter(func(x): return not x.e_crianca() and not x.is_priest())
			for i in gente.size():
				gente[i].set_job("guarda" if i < 4 else "minerador", false)
			g("schedule").vigilia_fracao = 1.0
			var dn := g("day_night")
			dn.time = dn.tempo_da_hora(fposmod(dn.hora_anoitecer + 0.1, 24.0))
			Engine.time_scale = 3.0
			_proximo(12.0)
		3:
			Engine.time_scale = 1.0
			var spot: Node2D = g("village_hub")
			_camera(spot.global_position + Vector2(0, 60), 1.4)
			_proximo(1.0)
		4:
			_foto("2_hora_social")
			var p = load("res://scripts/ui/sons_ativos_panel.gd").new()
			root.add_child(p)
			p.abre()
			_proximo(1.0)
		5:
			_foto("3_f3_som")
			return true
	return false
