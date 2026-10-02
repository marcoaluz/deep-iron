extends SceneTree
## Prompts 17 e 18 (não é teste): fotos e quadros de GIF dos invasores e dos efeitos na vista iso.
## Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_fx.gd -- <pasta de saída>
## Cada cena: [nome, ponto do chão, parada de zoom, horário (s), quadros (1 = foto; >1 = GIF)]
const PATH := "user://savegame.json"
const CENAS := [
	["criaturas", Vector2(-300, -140), 2, 90.0, 12],
	["criaturas_noite", Vector2(-300, -140), 2, 215.0, 1],
	["festa_noite", Vector2(-300, -250), 1, 215.0, 16],
	["greve", Vector2(-300, -250), 2, 90.0, 12],
	["onda_solar", Vector2(-300, -250), 1, 90.0, 1],
	["chuva_neblina", Vector2(-300, -250), 1, 8.0, 1],
	["mina_gotas_calor", Vector2(380, 1880), 1, 90.0, 10],
	["oficina_fogo", Vector2(150, -250), 3, 215.0, 10],
	["acidente", Vector2(300, 950), 3, 90.0, 8],
	["cemiterio", Vector2(-120, -170), 3, 90.0, 1],
	["escudo", Vector2(-260, -240), 0, 90.0, 10],
]
var main: Node
var out_dir := ""
var t := 0.0
var cur := -1
var t_mark := 0.0
var frame := 0
var _criaturas: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_fx")
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


func node(g: String) -> Node:
	return main.get_tree().get_first_node_in_group(g)


func _process(delta: float) -> bool:
	t += delta
	if t > 400.0:
		print("TIMEOUT")
		return true
	if cur < 0:
		if t > 3.0:
			_setup()
			_next()
		return false
	_anima_criaturas(delta)
	var c: Array = CENAS[cur]
	var dn := node("day_night")
	dn.time = c[3]
	dn.snap_lighting()
	if t - t_mark > 1.6 + frame * 0.12:
		var nome: String = c[0] if c[4] == 1 else "%s_%02d" % [c[0], frame]
		root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
		frame += 1
		if frame >= c[4]:
			print("cena: ", c[0])
			if cur + 1 >= CENAS.size():
				return true
			_next()
	return false


func _setup() -> void:
	node("day_night").time_scale = 0.0
	var world := main.get_node("World")
	for e in [["res://scenes/props/laboratorio.tscn", Vector2(420, -260)], ["res://scenes/props/oficina.tscn", Vector2(150, -250)]]:
		var n: Node2D = load(e[0]).instantiate()
		n.position = e[1]
		world.add_child(n)


func _limpa() -> void:
	for c in _criaturas:
		if is_instance_valid(c):
			c.queue_free()
	_criaturas.clear()
	var m := node("morale")
	m.festa_left = 0.0
	if m.on_strike:
		m._end_strike()
	node("sun").wave_left = 0.0
	var w := node("weather")
	if w and w.get("_fx") != null:
		for k in w._fx:
			w._fx[k].node.emitting = false
			w._fx[k].node.modulate.a = 0.0


func _next() -> void:
	cur += 1
	frame = 0
	_limpa()
	var c: Array = CENAS[cur]
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(c[2], 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(c[1])
	match c[0]:
		"criaturas", "criaturas_noite":
			var world := main.get_node("World")
			var spots := [Vector2(-360, -150), Vector2(-320, -120), Vector2(-280, -150), Vector2(-240, -125)]
			var kinds := [["lumivoro", false], ["lumivoro", true], ["ferrugento", false], ["ferrugento", true]]
			for i in 4:
				var cr: Node2D = load("res://scenes/creatures/%s.tscn" % kinds[i][0]).instantiate()
				cr.position = spots[i]
				world.add_child(cr)
				cr.setup(null, 1.0)
				if kinds[i][1]:
					cr.make_strong(1.6, 1.3)
				cr.set_process(false)
				_criaturas.append(cr)
			_anda_criaturas.call_deferred()
		"festa_noite":
			node("morale").festa_left = 200.0
		"greve":
			var m := node("morale")
			m.strike_end_at = 101.0
			m.strike_ultimatum = 9999.0
			m._start_strike()
		"onda_solar":
			node("sun").wave_left = 30.0
		"escudo":
			var sun := node("sun")
			if sun.shield() == null:
				sun.spawn_shield(node("village_hub").global_position + Vector2(160, 120))
			sun.won = true
			for l in main.get_tree().root.get_children():
				if l is CanvasLayer and l.get_script() != null and String(l.get_script().resource_path).ends_with("victory.gd"):
					l.queue_free()
			main.get_tree().paused = false
		"chuva_neblina":
			var w := node("weather")
			if w and w.get("_fx") != null and w._fx.has("rain"):
				w._fx.rain.node.emitting = true
				w._fx.rain.node.modulate.a = 1.0
		"oficina_fogo":
			for o in main.get_tree().get_nodes_in_group("oficina"):
				for nm in ["ForgeLight", "Sparks", "Smoke"]:
					var l = o.get_node_or_null(nm)
					if l is PointLight2D:
						l.enabled = true
					elif l is CPUParticles2D:
						l.emitting = true
		"acidente":
			var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
			w.global_position = Vector2(300, 950)
			w.hurt("mina", "leve")
			cam.on_view_changed(w.global_position)
		"cemiterio":
			var enf := node("enfermarias")
			enf._spawn_grave(enf._grave_spot(), "Zé Bigorna")
			enf._spawn_grave(enf._grave_spot(), "Dona Brasa")
			cam.on_view_changed(enf.global_position + Vector2(60, 0))
	t_mark = t


## As criaturas da foto: paradas no lugar (sem IA), andando de um lado pro outro devagar (o
## espelho vê a velocidade e anima a caminhada); a 2ª ataca e a 3ª leva golpe de vez em quando.
func _anda_criaturas() -> void:
	for cr in _criaturas:
		cr.set_meta("base", cr.position)


func _anima_criaturas(delta: float) -> void:
	for i in _criaturas.size():
		var cr = _criaturas[i]
		if not is_instance_valid(cr) or not cr.has_meta("base"):
			continue
		cr._anim += delta
		var b: Vector2 = cr.get_meta("base")
		if i == 1:
			if fmod(cr._anim, 1.2) < delta:
				cr._attack_at = cr._anim
		elif i == 2:
			if fmod(cr._anim, 1.5) < delta:
				cr._hit_at = cr._anim
		else:
			cr.position = b + Vector2(sin(cr._anim * 0.8) * 26.0, 0)
