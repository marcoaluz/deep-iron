extends SceneTree
## Prompt 19 (não é teste): um ciclo dia/noite na vila + mina, pra o GIF e as fotos do relatório.
## Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/ciclo_luz.gd -- <pasta de saída>
const PATH := "user://savegame.json"
## [arquivo, segundos desde o amanhecer, ponto do chão, parada de zoom, dia (estação)]
const SHOTS := [
	["c01_amanhecer", 6.0, Vector2(-200, -150), 1, 1],
	["c02_manha", 40.0, Vector2(-200, -150), 1, 1],
	["c03_meio_dia", 90.0, Vector2(-200, -150), 1, 1],
	["c04_tarde", 150.0, Vector2(-200, -150), 1, 1],
	["c05_entardecer", 172.0, Vector2(-200, -150), 1, 1],
	["c06_anoitecer", 184.0, Vector2(-200, -150), 1, 1],
	["c07_noite", 205.0, Vector2(-200, -150), 1, 1],
	["c08_madrugada", 232.0, Vector2(-200, -150), 1, 1],
	["n1_vila_noite", 215.0, Vector2(-420, -300), 3, 1],
	["n2_oficina_lab_noite", 215.0, Vector2(150, -250), 2, 1],
	["n3_nivel2_cristais", 215.0, Vector2(188, 3705), 1, 1],
	["n4_abismo_lava", 215.0, Vector2(554, 4214), 1, 1],
	["n5_inverno_noite", 215.0, Vector2(-420, -300), 2, 13],
	["n6_verao_noite", 215.0, Vector2(-420, -300), 2, 5],
	["n7_inverno_dia", 90.0, Vector2(-420, -300), 2, 13],
	["n8_verao_dia", 90.0, Vector2(-420, -300), 2, 5],
]
var main: Node
var out_dir := ""
var t := 0.0
var t_mark := 0.0
var cur := -1


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://ciclo")
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


func _process(delta: float) -> bool:
	t += delta
	if t > 240.0:
		print("TIMEOUT")
		return true
	if cur < 0:
		if t > 3.0:
			_setup()
			_next()
		return false
	_hold()
	if t - t_mark > 2.0:
		root.get_texture().get_image().save_png(out_dir.path_join(SHOTS[cur][0] + ".png"))
		print("ciclo: ", SHOTS[cur][0])
		if cur + 1 >= SHOTS.size():
			return true
		_next()
	return false


func _setup() -> void:
	var dn = main.get_node("DayNight")
	dn.time_scale = 0.0  # o relógio fica parado em cada foto
	var world := main.get_node("World")
	for e in [["res://scenes/props/laboratorio.tscn", Vector2(420, -260)], ["res://scenes/props/taverna.tscn", Vector2(130, -370)],
			["res://scenes/props/casa.tscn", Vector2(-140, -380)]]:
		var n: Node2D = load(e[0]).instantiate()
		n.position = e[1]
		world.add_child(n)


## Segura o horário e acende as luzes de "em uso" (casas ocupadas, forja e laboratório trabalhando).
func _hold() -> void:
	var s: Array = SHOTS[cur]
	var dn = main.get_node("DayNight")
	dn.day = s[4]
	dn.time = s[1]
	dn.snap_lighting()
	var night: bool = s[1] >= dn.day_duration - 10.0
	for c in main.get_tree().get_nodes_in_group("casas"):
		var wl = c.get_node_or_null("WindowLight")
		if wl:
			wl.enabled = night
	for g in ["oficina", "laboratorios", "tavernas"]:
		for b in main.get_tree().get_nodes_in_group(g):
			for nm in ["ForgeLight", "Glow", "WindowLight"]:
				var l = b.get_node_or_null(nm)
				if l:
					l.enabled = night


func _next() -> void:
	cur += 1
	var s: Array = SHOTS[cur]
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()  # (só pras fotos: a câmera chega no abismo direto)
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(s[3], 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(s[2])
	_hold()
	t_mark = t
