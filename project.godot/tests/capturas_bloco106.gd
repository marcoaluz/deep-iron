extends SceneTree
## Bloco 106 (não é teste): fotos do "coletor parado". Com o armazém cheio de minério: ANTES (o código do Bloco 105) os
## mineradores ficavam no estado "storing" encostados no armazém, de carga nas costas, esperando (o "parado olhando"); DEPOIS
## (Bloco 106) eles vão pro estado "esperando espaço" e esperam no Centro da Vila, com o balão. Também a janela do armazém
## com uma barra por compartimento e a janela do vagonete em ruína. O mesmo script roda nas duas versões (ele vê o que existe).
## Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco106.gd -- <pasta de saída> <antes|depois>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var prefixo := "depois"
var t := 0.0
var passo := 0
var t_mark := 0.0
var mineiros: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco106")
	prefixo = args[1] if args.size() > 1 else "depois"
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
	root.get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [prefixo, nome]))
	print("tela: ", prefixo, "_", nome)


func _foca(pos: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var alvo: Vector2 = main.get_node("IsoView").to_screen(pos)
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = alvo
	cam._target_pos = alvo


func _enche(arm) -> void:
	for k in arm.stock:
		arm.stock[k] = 0.0
	arm._recount()
	if arm.has_method("espaco_cat"):
		arm.stock["ferro"] = arm.espaco_cat("minerios")
	else:
		arm.stock["ferro"] = arm.espaco()
	arm._recount()


func _estados() -> String:
	return ", ".join(mineiros.map(func(w): return "%s (carga %d, balão '%s')" % [w.get_state(), int(w.carrying), w.motivo_parado()]))


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		print("TIMEOUT")
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(10.0)
	var arm = g("armazens")
	var hud = g("hud")
	if passo == 0 and t > 4.0:
		passo = 1
		var mig = g("migrantes")
		if mig:
			mig.proximo = 1.0e9
		for p in main.get_tree().get_nodes_in_group("pontos_carga"):
			p.parar_por_area(true, "foto")
		var gente: Array = main.get_tree().get_nodes_in_group("ipezinhos")
		for i in mini(3, gente.size()):
			gente[i].set_job("minerador")
			mineiros.append(gente[i])
		hud.close_panels()
		Engine.time_scale = 3.0
		t_mark = t
	elif passo == 1 and t - t_mark > 25.0:
		passo = 2
		_enche(arm)  # o compartimento de minério (ou o armazém todo, no código antigo) cheio
		t_mark = t
	elif passo == 2:
		for p in main.get_tree().get_nodes_in_group("pontos_carga"):
			p.parar_por_area(true, "foto")
		if t - t_mark > 40.0:
			passo = 3
			Engine.time_scale = 1.0
			print("ESTADOS (%s): %s" % [prefixo, _estados()])
			_foca(arm.global_position + Vector2(0, 20), 2.5)
			t_mark = t
	elif passo == 3 and t - t_mark > 1.5:
		_salva("armazem_cheio_porta")
		var hub = g("village_hub")
		_foca(hub.global_position + Vector2(0, 50), 2.5)
		passo = 4
		t_mark = t
	elif passo == 4 and t - t_mark > 1.5:
		_salva("centro_da_vila")
		hud.open_panel("armazem")
		passo = 5
		t_mark = t
	elif passo == 5 and t - t_mark > 1.0:
		_salva("janela_armazem")
		hud.close_panels()
		var boca = g("bocas_mina")
		if boca:
			_foca(boca.global_position, 2.5)
		passo = 6
		t_mark = t
	elif passo == 6 and t - t_mark > 1.5:
		_salva("boca_da_mina")
		hud.open_panel("vagonete")
		passo = 7
		t_mark = t
	elif passo == 7 and t - t_mark > 1.0:
		if hud._panels.has("vagonete"):
			_salva("janela_vagonete")
		print("FIM")
		return true
	return false
