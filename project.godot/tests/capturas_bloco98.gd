extends SceneTree
## Bloco 98 (não é teste): fotos do portão da paliçada e das tochas, de dia e de noite. Roda COM JANELA e APPDATA
## isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco98.gd -- <pasta de saída> [prefixo]
## Grava <pasta>/<prefixo>_<vista>.jpg. Com a marcação (`marca` = true) desenha por cima o vão LÓGICO do portão
## (a linha vermelha de gate_y ± gate_half_width) e os blocos de navegação, pra ver onde o sprite cai.
const PATH := "user://savegame.json"
const ASSENTA := 2.2
var main: Node
var out_dir := ""
var prefixo := "antes"
var t := 0.0
var step := 0
var vista := 0
var _vistas: Array = []
var marca := true


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco98")
	prefixo = args[1] if args.size() > 1 else "antes"
	marca = not args.has("semmarca")
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


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func iso() -> Node:
	return main.get_node("IsoView")


func _tela(centro: Vector2, z: float) -> void:
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()
	cam.zoom_min = minf(cam.zoom_min, z)
	cam.iso_zoom_min = minf(cam.iso_zoom_min, z)
	cam.zoom = Vector2(z, z)
	cam._target_zoom = z
	cam.position = centro
	cam._target_pos = centro


func _hora(h: float) -> void:
	var dn = g("day_night")
	if dn:
		dn._pula_para(dn.tempo_da_hora(h))


## A marcação: o vão lógico (vermelho), a linha da paliçada (amarelo) e o centro do portão (ciano).
func _desenha_marca() -> void:
	var env = g("environment")
	var v = iso()
	var raiz := Node2D.new()
	raiz.name = "MarcaPortao"
	raiz.z_index = 4000
	main.add_child(raiz)
	var gy: float = env.gate_y
	var gh: float = env.gate_half_width
	var px: float = env.palisade_x
	var vao := Line2D.new()
	vao.width = 2.0
	vao.default_color = Color(1, 0.1, 0.1)
	vao.points = PackedVector2Array([v.to_screen(Vector2(px, gy - gh)), v.to_screen(Vector2(px, gy + gh))])
	raiz.add_child(vao)
	var linha := Line2D.new()
	linha.width = 1.0
	linha.default_color = Color(1, 0.9, 0.1)
	linha.points = PackedVector2Array([v.to_screen(Vector2(px, gy - 260.0)), v.to_screen(Vector2(px, gy + 260.0))])
	raiz.add_child(linha)
	var c := Line2D.new()
	c.width = 3.0
	c.default_color = Color(0.2, 1, 1)
	c.points = PackedVector2Array([v.to_screen(Vector2(px - 6, gy)), v.to_screen(Vector2(px + 6, gy))])
	raiz.add_child(c)
	for b in env._iso_blockers():
		var cx := Vector2.ZERO
		var pts := PackedVector2Array()
		for q in b:
			var s: Vector2 = v.to_screen(q)
			pts.append(s)
		if pts.size() < 3:
			continue
		var bb := Rect2(b[0], Vector2.ZERO)
		for q in b:
			bb = bb.expand(q)
		if absf(bb.get_center().x - px) > 40.0 or absf(bb.get_center().y - gy) > 400.0:
			continue  # só a paliçada perto do portão
		var pl := Line2D.new()
		pl.width = 1.0
		pl.default_color = Color(0.3, 0.6, 1.0)
		pl.points = pts
		pl.closed = true
		raiz.add_child(pl)


func _prepara() -> void:
	var hud = g("hud")
	if hud:
		hud.visible = false
	var env = g("environment")
	var centro: Vector2 = Vector2(env.palisade_x, env.gate_y)
	var gate = g("barricadas")
	var deco = g("decoracoes_mgr")
	var eco = g("economy")
	eco.credits = 9999.0
	if deco:  # a decoração do jogador: uma tocha e um lampião do lado da cozinha
		deco.colocar("tocha", Vector2(-40, 30))
		deco.colocar("lampiao", Vector2(-10, 40))
	_vistas = [
		["portao_dia_sem_muro", func(): _hora(12.0); _tela(iso().to_screen(centro), 2.4)],
		["portao_dia_longe", func(): _tela(iso().to_screen(centro), 1.2)],
		["portao_n1_dia_aberto", func(): gate.level = 1; gate.hp = gate.max_hp(); gate._update_visual(); _tela(iso().to_screen(centro), 2.4)],
		["portao_n2_dia_aberto", func(): gate.level = 2; gate.hp = gate.max_hp(); gate._update_visual()],
		["portao_n2_noite_fechado", func(): _hora(21.0)],
		["portao_n3_noite_fechado", func(): gate.level = 3; gate.hp = gate.max_hp(); gate._update_visual()],
		["portao_n3_dia_aberto", func(): _hora(9.0)],
		["tochas_dia", func(): _hora(12.0); _tela(iso().to_screen(Vector2(0, 0)), 1.5)],
		["tochas_noite", func(): _hora(21.0); _tela(iso().to_screen(Vector2(0, 0)), 1.5)],
	]
	if marca:
		_desenha_marca()


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		return true
	if step == 0:
		if t > 4.0:
			_prepara()
			step = 1
			t = 0.0
			_vistas[0][1].call()
		return false
	if t > ASSENTA:
		var img := root.get_texture().get_image()
		img.save_jpg(out_dir.path_join("%s_%s.jpg" % [prefixo, _vistas[vista][0]]), 0.9)
		print("foto ", _vistas[vista][0])
		vista += 1
		t = 0.0
		if vista >= _vistas.size():
			return true
		_vistas[vista][1].call()
	return false
