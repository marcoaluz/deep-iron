extends SceneTree
## Bloco 72 (não é teste): o mapa do jogo pra comparar com a referência (docs/arte/referencia_mapa_mundo.jpg).
## Fotos de cada região + medida de cada vista (ms por quadro, nós, draw calls, luzes e partículas
## visíveis). Com janela, vsync desligado e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco72.gd -- <pasta de saída>
## Grava <pasta>/<vista>.jpg e <pasta>/medidas.txt. Os andares de baixo ficam abertos (estado de fim de
## jogo, como a referência); a vila cheia (40 ipezinhos, noite, chuva, invasão) é a última vista.
const PATH := "user://savegame.json"
const ASSENTA := 2.0
const MEDE := 2.0
var main: Node
var out_dir := ""
var t := 0.0
var t_mark := 0.0
var step := 0
var vista := 0
var _vistas: Array = []  # [nome, Callable que mira]
var _amostras: Array = []
var _linhas: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco72")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_linhas.append("Deep Iron — capturas do Bloco 72 (%s), janela 1920x1080, vsync desligado" % Time.get_datetime_string_from_system())
	_linhas.append("%-22s %7s %6s %6s %6s %6s %6s" % ["vista", "ms méd", "FPS", "nós", "draws", "luzes", "partíc"])


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func iso() -> Node:
	return main.get_node("IsoView")


## Câmera num ponto da TELA iso com um zoom qualquer (fora das paradas também: a vista geral).
func _tela(centro: Vector2, z: float) -> void:
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()
	cam.zoom_min = minf(cam.zoom_min, z)
	cam.iso_zoom_min = minf(cam.iso_zoom_min, z)
	cam.zoom = Vector2(z, z)
	cam._target_zoom = z
	cam.position = centro
	cam._target_pos = centro


## Enquadra um retângulo da tela iso inteiro (com folga).
func _enquadra(r: Rect2, folga := 1.08) -> void:
	var vis: Vector2 = root.get_visible_rect().size  # (a área do mundo é a resolução base esticada, não a janela)
	_tela(r.get_center(), minf(vis.x / (r.size.x * folga), vis.y / (r.size.y * folga)))


## Retângulo na tela iso de um retângulo da lógica (os 4 cantos projetados no chão de cada um).
func _tela_de(r: Rect2) -> Rect2:
	var v = iso()
	var out := Rect2(v.to_screen(r.position), Vector2.ZERO)
	for c in [Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		out = out.expand(v.to_screen(c))
	return out


## O meio da escada em espiral na tela (entre o S3 e o S4).
func _espiral_meio() -> Vector2:
	for c in iso()._terrain_node.get_children():
		if c.name == "Espiral":
			var sp: Sprite2D = c
			return sp.position + Vector2(sp.texture.get_width() * 0.5 - 120.0, sp.texture.get_height() * 0.55)
	return Vector2.ZERO


func _laje(nome: String) -> Rect2:
	for lv in iso()._levels:
		if lv.nome == nome:
			return Rect2(lv.sprite.position, lv.sprite.texture.get_size())
	return Rect2()


func _prepara() -> void:
	var hud = g("hud")
	if hud:
		hud.visible = false
	g("elevador").unlock(false)
	for e in main.get_tree().get_nodes_in_group("elevadores"):
		e.unlocked = true
		e._apply(false)
	g("environment").set_leste_aberto(true, false)
	for pq in ["carrinhos", "trajes", "ventilacao", "bombas"]:
		g("research")._finish(pq)  # (o corte mostra os andares abertos, não "precisa pesquisar")
	var env = g("environment")
	var sup: Rect2 = _tela_de(env.iso_ground_rect())
	var pilha := sup
	for lv in iso()._levels:
		pilha = pilha.merge(Rect2(lv.sprite.position, lv.sprite.texture.get_size()))
	var vila: Vector2 = g("village_hub").global_position
	var elev: Vector2 = g("elevador").global_position
	_vistas = [
		["01_superficie_inteira", func(): _enquadra(sup, 1.02)],
		["02_pilha_inteira", func(): _enquadra(pilha, 1.02)],
		["03_vila_s1", func(): _tela(iso().to_screen(vila + Vector2(0, 60)), 1.0)],
		["04_encosta_boca_mina", func(): _tela(iso().to_screen(elev), 1.0)],
		["05_leste_vila_antiga", func(): _tela(iso().to_screen(Vector2(2500, -40)), 1.0)],
		["06_s2_acido", func(): _enquadra(_laje("nivel2"))],
		["07_s3_lava", func(): _enquadra(_laje("abismo"))],
		["08_s4_cachoeira", func(): _enquadra(_laje("s4"))],
		["09_s5_lago", func(): _enquadra(_laje("s5"))],
		["10_rampa_s4", func(): _tela(iso().to_screen(Vector2(320, 2180)), 3.0)],
		["10b_espiral", func(): _tela(_espiral_meio(), 1.0)],
		["11_corte_f2", func():
			if hud:
				hud.visible = true
			hud._corte.abre()],
		["12_vila_cheia", func():
			hud._corte.fecha()
			hud.visible = false
			_monta_cheia()
			_tela(iso().to_screen(vila + Vector2(0, 60)), 1.0)],
	]


# a vila cheia do bench_cena (cenário C): 40 ipezinhos, casas, noite, chuva e invasão
func _monta_cheia() -> void:
	var eco = g("economy")
	eco.credits = 999999
	eco.max_workers = 60
	var arm = g("armazens")
	for ore in arm.stock.keys():
		arm.stock[ore] = 99999.0
	arm.wood_stored = 99999.0
	var hub = g("village_hub")
	var placer = g("house_placer")
	placer._collect_blockers()
	for k in 5:
		for r in range(1, 18):
			var feito := false
			for a in range(16):
				var p: Vector2 = hub.global_position + Vector2.RIGHT.rotated(a * TAU / 16.0 + r + k) * (70.0 + r * 30.0)
				if placer.check_spot(p) == "":
					hub._confirm_house(p)
					placer._collect_blockers()
					feito = true
					break
			if feito:
				break
	for o in main.get_tree().get_nodes_in_group("obras"):
		if o.has_method("obra_pending") and o.obra_pending():
			o.obra_work(99999.0)
	var n := main.get_tree().get_nodes_in_group("ipezinhos").size()
	for i in maxi(40 - n, 0):
		eco.recruit_free()
	var jobs := ["minerador", "minerador", "lenhador", "cozinheiro", "caçador", "guarda", "guarda", "engenheiro", "pesquisador"]
	var ws := main.get_tree().get_nodes_in_group("ipezinhos")
	for i in ws.size():
		ws[i].set_job(jobs[i % jobs.size()])
	var dn = g("day_night")
	dn.time = dn.day_duration + 5.0
	var w = g("weather")
	if w:
		w.forcar_chuva = true
		w.snap()
	var d = g("defense")
	if d and not d.invasion_active:
		d.start_invasion()


func _conta(n: Node, out: Array) -> void:
	if n is PointLight2D and (n as PointLight2D).enabled and (n as CanvasItem).is_visible_in_tree():
		out[0] += 1
	elif n is CPUParticles2D and (n as CPUParticles2D).emitting and (n as CanvasItem).is_visible_in_tree():
		out[1] += 1
	for c in n.get_children():
		_conta(c, out)


func _process(delta: float) -> bool:
	t += delta
	if t > 400.0:
		_grava()
		return true
	if step == 0:
		if t > 4.0:
			_prepara()
			step = 1
			_proxima()
		return false
	var dt := t - t_mark
	if dt > ASSENTA and dt <= ASSENTA + MEDE:
		_amostras.append([delta, Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	elif dt > ASSENTA + MEDE:
		var nome: String = _vistas[vista][0]
		root.get_texture().get_image().save_jpg(out_dir.path_join(nome + ".jpg"), 0.88)
		var cont := [0, 0]
		_conta(main, cont)
		var soma := 0.0
		var nos := 0.0
		var dr := 0.0
		for a in _amostras:
			soma += a[0]
			nos += a[1]
			dr += a[2]
		var k := maxf(float(_amostras.size()), 1.0)
		var ms := soma / k * 1000.0
		var l := "%-22s %7.2f %6.0f %6.0f %6.0f %6d %6d" % [nome, ms, 1000.0 / maxf(ms, 0.01), nos / k, dr / k, cont[0], cont[1]]
		_linhas.append(l)
		print(l)
		vista += 1
		if vista >= _vistas.size():
			_grava()
			return true
		_proxima()
	return false


func _proxima() -> void:
	(_vistas[vista][1] as Callable).call()
	_amostras.clear()
	t_mark = t


func _grava() -> void:
	var f := FileAccess.open(out_dir.path_join("medidas.txt"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_linhas) + "\n")
	print("fotos e medidas em ", out_dir)
