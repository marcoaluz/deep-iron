extends SceneTree
## Prompt 30 (item 1): QA visual — percorre o jogo e tira fotos (não é teste: não dá OK/FALHOU).
## Vila cheia (todos os prédios, ipezinhos a mais), as 4 estações, dia e noite, onda solar,
## invasão, obras de cada tipo, nível 2 e abismo, o mapa de longe. Em cada foto conta os pares
## desenhados na ordem errada (a verdade 3D das caixas).
## Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/qa_prompt30.gd -- <pasta de saída>
const Iso := preload("res://scripts/iso/iso_core.gd")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const PATH := "user://savegame.json"
## [nome, preparação, ponto do chão, zoom]
const SHOTS := [
	["01_primavera_vila", "primavera", Vector2(-330, -300), 1.0],
	["02_primavera_floresta", "", Vector2(0, -760), 1.0],
	["03_primavera_pedreira", "", Vector2(-100, 280), 1.0],
	["04_obras", "obras", Vector2(160, 80), 1.0],
	["05_verao_vila", "verao", Vector2(250, -320), 1.0],
	["06_outono_floresta", "outono", Vector2(0, -760), 1.0],
	["07_inverno_vila", "inverno", Vector2(-330, -300), 1.0],
	["08_inverno_bonecos", "", Vector2(-200, -230), 2.0],
	["09_noite_vila", "noite", Vector2(-330, -300), 1.0],
	["10_noite_pedreira", "", Vector2(-100, 280), 1.0],
	["11_onda_solar", "onda", Vector2(-330, -300), 1.0],
	["12_invasao_portao", "invasao", Vector2(0, -470), 1.0],
	["13_invasao_poco", "", Vector2(480, 380), 1.0],
	["14_nivel2", "dia", Vector2(188, 3726), 1.0],
	["15_abismo", "", Vector2(146, 4130), 1.0],
	["16_mapa_longe", "", Vector2(0, -200), 0.0],
]
const EXTRA := [
	["res://scenes/props/taverna.tscn", Vector2(130, -370)],
	["res://scenes/props/parque.tscn", Vector2(470, -360)],
	["res://scenes/props/laboratorio.tscn", Vector2(420, -260)],
	["res://scenes/props/vestiario.tscn", Vector2(220, -260)],
	["res://scenes/props/arsenal.tscn", Vector2(-200, -90)],
	["res://scenes/props/campo_treino.tscn", Vector2(-560, 90)],
	["res://scenes/props/casa.tscn", Vector2(-140, -380)],
	["res://scenes/props/casa.tscn", Vector2(-60, -260)],
	["res://scenes/props/casa.tscn", Vector2(-200, -250)],
]
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var shot := 0
var t_shot := 0.0
var report := []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://qa30")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	root.size = Vector2i(1600, 900)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _process(delta: float) -> bool:
	t += delta
	if t > 240.0:
		print("TIMEOUT")
		return true
	if step == 0 and t > 2.5:
		step = 1
		_setup()
	elif step == 1 and t > 5.0:
		step = 2
		_begin(shot)
	elif step == 2 and t - t_shot > 2.0:
		var s: Array = SHOTS[shot]
		var iso = main.get_node("IsoView")
		iso._process(0.0)
		var e: Array = _order_errors(iso)
		root.get_texture().get_image().save_png(out_dir.path_join(s[0] + ".png"))
		var line := "%s: %d pares sobrepostos, %d na ordem errada" % [s[0], e[1], e[0]]
		print(line)
		report.append(line)
		shot += 1
		if shot >= SHOTS.size():
			var f := FileAccess.open(out_dir.path_join("ordem.txt"), FileAccess.WRITE)
			f.store_string("\n".join(report) + "\n")
			f.close()
			return true
		_begin(shot)
	return false


func _begin(i: int) -> void:
	t_shot = t
	var s: Array = SHOTS[i]
	_prepare(s[1])
	var cam = main.get_node("Camera2D")
	var z: float = s[3]
	if z <= 0.0:
		var stops: Array = cam.zoom_stops()
		z = stops[0]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(s[2])


func _day_night(day: int, night: bool) -> void:
	var dn = main.get_node("DayNight")
	dn.day = day
	dn.time = dn.day_duration + 10.0 if night else 20.0
	dn.snap_lighting()
	var w = main.get_tree().get_first_node_in_group("weather")
	if w and w.has_method("snap"):
		w.snap()


func _prepare(what: String) -> void:
	match what:
		"primavera", "dia":
			_day_night(1, false)
		"verao":
			_day_night(5, false)
		"outono":
			_day_night(9, false)
		"inverno":
			_day_night(13, false)
		"noite":
			_day_night(13, true)
		"onda":
			_day_night(5, false)
			var sun = main.get_tree().get_first_node_in_group("sun")
			if sun:
				sun._start_wave()
		"invasao":
			_day_night(6, true)
			var d = main.get_tree().get_first_node_in_group("defense")
			if d:
				d.start_invasion()
		"obras":
			_obras()


func _setup() -> void:
	var world := main.get_node("World")
	for e in EXTRA:
		var n: Node2D = load(e[0]).instantiate()
		n.position = e[1]
		world.add_child(n)
	var hub := main.get_tree().get_first_node_in_group("village_hub")
	hub.level = 3
	hub._update_visual()
	var esc := main.get_tree().get_first_node_in_group("escavadeira")
	if esc:
		esc.installed["estrutura"] = true
		esc.installed["motor"] = true
		esc._update_visual()
	# ipezinhos a mais, com funções diferentes (vila cheia)
	var eco = main.get_node("Economy")
	eco.credits = 99999
	for i in 9:
		eco.recruit()
	var jobs := ["minerador", "engenheiro", "cozinheiro", "lenhador", "guarda", "cacador", "medico", "pesquisador"]
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	for i in ws.size():
		ws[i].set_job(jobs[i % jobs.size()])
	main.get_node("World/Environment").rebuild_navigation()


## Obras de cada tipo, em estágios diferentes, no fundo da pedreira.
func _obras() -> void:
	var kinds := ["taverna", "laboratorio", "comedouro", "arsenal", "parque", "vestiario", "enfermaria", "campo"]
	var k := 0
	for kind in kinds:
		var p := Vector2(-40 + (k % 4) * 130, 0 + (k / 4) * 130)
		var c: Node2D = Canteiro.order(self, kind, p, 30.0)
		c.left = 30.0 * (1.0 - [0.15, 0.5, 0.85][k % 3])
		k += 1


func _order_errors(iso) -> Array:
	var all := []
	for bb in iso._ents.values():
		if bb.visible_src():
			for b in bb.boxes:
				all.append([b, bb.z_index, bb.dynamic])
	for tr in iso._terrain:
		all.append([tr[0], tr[1].z_index, false])
	var bad := 0
	var pairs := 0
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a = all[i]
			var b = all[j]
			if not Iso.screen_rect(a[0]).intersects(Iso.screen_rect(b[0])):
				continue
			var r = Iso.behind(a[0], b[0])
			if r == null:
				continue
			pairs += 1
			if a[1] == b[1] and a[2] and b[2]:
				continue
			if (r == true and a[1] >= b[1]) or (r == false and b[1] >= a[1]):
				bad += 1
				print("   errado: %s x %s" % [a[0].name, b[0].name])
	return [bad, pairs]
