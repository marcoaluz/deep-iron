extends SceneTree
## Bloco 104 (não é teste): fotos — o batedor e a batedora batendo o mato (a luneta), a janela das Expedições com o mapa
## e o relatório de uma expedição que voltou. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco104.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var bats: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco104")
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
	var hud = g("hud")
	var ex = g("expedicoes")
	if passo == 0 and t > 4.0:
		passo = 1
		var mig = g("migrantes")
		if mig:
			mig.proximo = 1.0e9
		var gente: Array = main.get_tree().get_nodes_in_group("ipezinhos")
		for w in gente:
			if w.gender == "menino" and bats.size() == 0:
				bats.append(w)
		for w in gente:
			if w.gender == "menina" and bats.size() == 1:
				bats.append(w)
		for w in bats:
			w.set_job("batedor")
		hud.close_panels()
		Engine.time_scale = 3.0
		t_mark = t
	elif passo == 1 and bats.all(func(w): return w.get_state() == "batendo" and not w._bate.is_empty() and float(w._bate.t) > 0.5):
		passo = 2
		Engine.time_scale = 1.0
		bats[1].global_position = bats[0].global_position + Vector2(36, 10)
		_foca(bats[0].global_position + Vector2(18, 0), 3.0)
		t_mark = t
	elif passo == 1 and t - t_mark > 60.0:
		passo = 2
		Engine.time_scale = 1.0
		_foca(bats[0].global_position, 3.0)
		t_mark = t
	elif passo == 2 and t - t_mark > 1.5:
		_salva("01_batedores_na_luneta")
		var gente: Array = main.get_tree().get_nodes_in_group("ipezinhos")
		var guarda: Node = gente.filter(func(w): return not bats.has(w))[0]
		guarda.set_job("guarda")
		guarda.equip("lanca")
		hud.open_panel("expedicoes")
		hud._panels.expedicoes.escolhe("floresta")
		hud._panels.expedicoes.define_equipe([bats[0], guarda])
		passo = 3
		t_mark = t
	elif passo == 3 and t - t_mark > 1.5:
		_salva("02_janela_expedicoes")
		passo = 4
		t_mark = t
	elif passo == 4:
		# uma expedição que volta na hora, pro relatório
		var gente: Array = main.get_tree().get_nodes_in_group("ipezinhos")
		var guarda: Node = gente.filter(func(w): return w.job == "guarda")[0]
		if ex.parte("floresta", [bats[0], guarda], true, false, 1):
			var e: Dictionary = ex.em_curso[0]
			for w in [bats[0], guarda]:
				w.sai_do_mundo()
			e.fase = "fora"
			for d in e.decisoes:
				d.escolha = "a"
				d.mostrada = true
				e.log.append(ex.texto("evento." + String(d.evento), "a_depois"))
			e.risco = 0.0
			var dn = g("day_night")
			e.volta_dia = dn.day
			e.volta_t = 0.0
		hud.close_panels()
		passo = 5
		t_mark = t
	elif passo == 5 and not ex.relatorios.is_empty() and t - t_mark > 1.0:
		hud.open_panel("expedicoes")
		passo = 6
		t_mark = t
	elif passo == 6 and t - t_mark > 1.5:
		_salva("03_relatorio")
		return true
	return false
