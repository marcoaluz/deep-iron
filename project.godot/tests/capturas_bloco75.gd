extends SceneTree
## Bloco 75 (não é teste): a coluna da maquete no jogo — os andares em FAIXAS debaixo da vila, as galerias
## de madeira, o poço e a espiral. Fotos pra comparar com docs/arte/bloco72/maquete/coluna_v3.png.
## Com janela e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco75.gd -- <pasta de saída>
## Os andares ficam abertos (como no fim do jogo) e com alguns ipezinhos andando em cada um.
const PATH := "user://savegame.json"
const ASSENTA := 1.8
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var vista := 0
var _vistas: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco75")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
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


func _enquadra(r: Rect2, folga := 1.06) -> void:
	var vis: Vector2 = root.get_visible_rect().size
	_tela(r.get_center(), minf(vis.x / (r.size.x * folga), vis.y / (r.size.y * folga)))


func _laje(nome: String) -> Rect2:
	for lv in iso()._levels:
		if lv.nome == nome:
			return Rect2(lv.sprite.position, lv.sprite.texture.get_size())
	return Rect2()


func _prepara() -> void:
	var hud = g("hud")
	if hud:
		hud.visible = false
	for e in main.get_tree().get_nodes_in_group("elevadores"):
		e.unlocked = true
		e._apply(false)
	g("elevador").unlock(false)
	for pq in ["carrinhos", "trajes", "ventilacao", "bombas"]:
		g("research")._finish(pq)
	# uns ipezinhos em cada andar, andando (pra ver a escala da faixa)
	var env = g("environment")
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	var eco = g("economy")
	for i in maxi(9 - ws.size(), 0):
		eco.recruit_free()
	ws = main.get_tree().get_nodes_in_group("ipezinhos")
	var rects: Array = [env.deep_rect, env.abyss_rect]
	for n in env.niveis_extra():
		rects.append(n.rect)
	for i in ws.size():
		var r: Rect2 = rects[i % rects.size()]
		var w = ws[i]
		w.set_job("minerador")
		w.manual_override_time = 999.0
		w.global_position = r.get_center() + Vector2(-300 + 140 * (i / rects.size()), 0)
		w.move_to(w.global_position + Vector2(260, 30))
	var pilha := Rect2()
	for lv in iso()._levels:
		var lr := Rect2(lv.sprite.position, lv.sprite.texture.get_size())
		pilha = lr if not pilha.has_area() else pilha.merge(lr)
	var sup: Vector2 = iso().to_screen(Vector2(-200, 300))
	pilha = pilha.expand(sup - Vector2(0, 500))
	_vistas = [
		["01_coluna_inteira", func(): _enquadra(pilha, 1.02)],
		["02_galerias_s2", func(): _tela(iso().to_screen(Vector2(-100, 430)) + Vector2(0, 380), 0.75)],
		["03_s2_acido", func(): _tela(iso().to_screen(env.deep_rect.get_center()), 0.9)],
		["04_s3_lava", func(): _tela(iso().to_screen(env.abyss_rect.get_center()), 0.9)],
		["05_s4_cachoeira", func(): _tela(iso().to_screen((env.niveis_extra()[0].rect as Rect2).get_center()), 0.9)],
		["06_s5_lago", func(): _tela(iso().to_screen((env.niveis_extra()[1].rect as Rect2).get_center()), 0.9)],
		["07_poco_espiral", func(): _tela(iso().to_screen(env.deep_rect.end - Vector2(80, 130)) + Vector2(80, 300), 0.6)],
		["08_superficie_e_coluna", func(): _enquadra(pilha.merge(Rect2(iso().to_screen(Vector2(-760, -1040)), Vector2(10, 10))), 1.02)],
	]


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
		img.save_jpg(out_dir.path_join(_vistas[vista][0] + ".jpg"), 0.88)
		print("foto ", _vistas[vista][0])
		vista += 1
		t = 0.0
		if vista >= _vistas.size():
			return true
		_vistas[vista][1].call()
	return false
