extends SceneTree
## QA visual do Prompt 30 (não é teste): percorre situações do jogo com a arte integrada e salva
## uma foto de cada (noite, inverno, invasão, onda solar, nível 2, abismo, todos os prédios em
## obra, Centro e escudo nas etapas). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/qa_iso.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const Canteiro := preload("res://scripts/props/canteiro.gd")
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var t_mark := 0.0
var shots: Array = []  # [nome, chão, zoom, preparar]
var cur := -1


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://qa")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	shots = [
		["obras_todas", Vector2(60, -120), 1, Callable(self, "_obras")],
		["obras_todas_2", Vector2(-360, 120), 1, Callable()],
		["escudo_etapas", Vector2(560, -40), 1, Callable(self, "_escudo")],
		["noite_vila", Vector2(-300, -300), 1, Callable(self, "_noite")],
		["inverno", Vector2(-200, -200), 1, Callable(self, "_inverno")],
		["invasao", Vector2(0, -470), 1, Callable(self, "_invasao")],
		["onda_solar", Vector2(-200, -200), 1, Callable(self, "_onda")],
		["nivel2", Vector2(250, 3726), 1, Callable(self, "_dia")],
		["abismo", Vector2(146, 4130), 1, Callable()],
		["mapa_longe", Vector2(0, 0), 0, Callable()],
	]


func g(n: String) -> Node:
	return main.get_tree().get_first_node_in_group(n)


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		print("TIMEOUT")
		return true
	if step == 0 and t > 3.0:
		step = 1
		_next()
	elif step == 1 and t - t_mark > 1.5:
		root.get_texture().get_image().save_png(out_dir.path_join(shots[cur][0] + ".png"))
		print("qa: ", shots[cur][0])
		if cur + 1 >= shots.size():
			return true
		_next()
	return false


func _next() -> void:
	cur += 1
	var s: Array = shots[cur]
	if s[3].is_valid():
		s[3].call()
	var cam = main.get_node("Camera2D")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(s[2], 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(s[1])
	t_mark = t


func _obras() -> void:
	# um canteiro de cada prédio construível, em estágios diferentes
	var spots := [Vector2(-20, -130), Vector2(140, -120), Vector2(300, -100), Vector2(460, -40), Vector2(-420, 100),
		Vector2(-300, 140), Vector2(-160, 200), Vector2(160, 160), Vector2(320, 200)]
	var kinds := ["taverna", "laboratorio", "comedouro", "parque", "campo", "arsenal", "vestiario", "coletor", "enfermaria"]
	for i in kinds.size():
		var c: Node2D = Canteiro.order(self, kinds[i], spots[i], 30.0)
		c.left = 30.0 * (1.0 - fmod(0.15 + 0.3 * i, 1.0))


func _escudo() -> void:
	var e: Node2D = load("res://scenes/props/escudo.tscn").instantiate()
	e.position = Vector2(560, -40)
	main.get_node("World").add_child(e)
	e.built = 2


func _noite() -> void:
	var dn = main.get_node("DayNight")
	dn.time = dn.day_duration + 20.0


func _dia() -> void:
	var dn = main.get_node("DayNight")
	dn.time = 30.0


func _inverno() -> void:
	var dn = main.get_node("DayNight")
	dn.time = 30.0
	var sun = g("sun")
	if sun:
		dn.day = 1 + sun.days_per_season * 3  # inverno


func _invasao() -> void:
	var dn = main.get_node("DayNight")
	dn.time = dn.day_duration + 5.0
	var def = g("defense")
	if def:
		def.start_invasion()


func _onda() -> void:
	var dn = main.get_node("DayNight")
	dn.time = 40.0
	var sun = g("sun")
	if sun:
		sun._start_wave()
