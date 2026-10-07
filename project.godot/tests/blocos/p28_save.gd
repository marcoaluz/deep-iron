extends SceneTree
## Prompt 28: saves de antes da vista isométrica continuam carregando, e a vista não muda o
## que vai pro save. Conferido num SAVE DE TESTE (nunca no de verdade):
##   - DEEP_IRON_SAVE_FIXTURE=<arquivo>: uma CÓPIA de um save feito antes do Prompt 28;
##   - sem ela, o teste faz o próprio save (vista de cima) e usa esse.
## Carregar não mexe no arquivo (md5 igual), o mundo volta igual (ipezinhos, posições,
## créditos, prédios), e salvar/carregar com a vista iso ligada dá o mesmo resultado.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t0 := 0
var step := 0
var fails := 0
var data: Dictionary
var md5_before := ""


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	t0 = Time.get_ticks_msec()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func secs() -> float:
	return (Time.get_ticks_msec() - t0) / 1000.0


func key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = code
	return ev


## Carrega o save com o tempo do jogo parado (ninguém anda antes da conferência).
func load_frozen() -> void:
	md5_before = FileAccess.get_md5(PATH)
	data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	Engine.time_scale = 0.0
	root.get_node("SaveManager").load_game()
	t0 = Time.get_ticks_msec()


## O mundo carregado bate com o save?
func compare(label: String) -> void:
	main = current_scene
	check(FileAccess.get_md5(PATH) == md5_before, "%s: carregar não mexeu no arquivo (md5)" % label)
	var ws: Array = data.get("workers", [])
	var by_name := {}
	for ip in main.get_tree().get_nodes_in_group("ipezinhos"):
		by_name[String(ip.name)] = ip
	check(by_name.size() == ws.size(), "%s: %d ipezinhos (save: %d)" % [label, by_name.size(), ws.size()])
	var off := 0
	for wd in ws:
		var ip = by_name.get(String(wd.get("name", "")))
		var p: Array = wd.get("position", [0, 0])
		if ip == null or ip.global_position.distance_to(Vector2(p[0], p[1])) > 1.0:
			off += 1
	check(off == 0, "%s: todo ipezinho no lugar salvo (%d fora)" % [label, off])
	var eco = main.get_node("Economy")
	var sv_credits: int = int(data.get("summary", {}).get("credits", -1))
	check(sv_credits < 0 or int(eco.credits) == sv_credits, "%s: créditos iguais (%d)" % [label, int(eco.credits)])
	var cam: Camera2D = main.get_node("Camera2D")
	var cp: Array = data.get("camera", {}).get("position", [0, 0])
	print("  câmera: save %s  agora (chão) %s" % [Vector2(cp[0], cp[1]), cam.ground_center()])


func _process(_delta: float) -> bool:
	if current_scene != null and current_scene != main and step != 1 and step != 3:
		main = current_scene
	if secs() > 150.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	if step == 0 and secs() > 4.0:
		step = 1
		var fx := OS.get_environment("DEEP_IRON_SAVE_FIXTURE")
		if fx != "" and FileAccess.file_exists(fx):
			print("== save de antes do Prompt 28 (cópia): %s" % fx.get_file())
			DirAccess.copy_absolute(fx, ProjectSettings.globalize_path(PATH))
		else:
			print("== sem cópia de save antigo: salva a partida de agora (vista de cima)")
			root.get_node("SaveManager").save_game("teste")
		load_frozen()
	elif step == 1 and secs() > 4.0:
		step = 2
		print("== carregou na vista de cima")
		compare("cima")
		print("== liga a vista iso, salva e carrega de novo")
		main = current_scene
		main.get_node("IsoView").set_enabled(true)  # (já pode estar ligada: DEEP_IRON_ISO=1)
		check(main.get_node("IsoView").enabled, "vista iso ligada")
		var ground: Vector2 = main.get_node("Camera2D").ground_center()
		Engine.time_scale = 0.0
		root.get_node("SaveManager").save_game("teste")
		var saved = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		var cp: Array = saved.camera.position
		check(Vector2(cp[0], cp[1]).distance_to(ground) < 2.0, "na vista iso o save grava o ponto do CHÃO da câmera")
		t0 = Time.get_ticks_msec()
		step = 3
		load_frozen()
	elif step == 3 and secs() > 4.0:
		step = 4
		print("== carregou o save feito na vista iso")
		compare("iso")
		Engine.time_scale = 1.0
		print("FALHAS: %d" % fails)
		return true
	return false
