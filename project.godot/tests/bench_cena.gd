extends SceneTree
## Bloco 53: BENCHMARK reproduzível (não é teste do GUT). Abre a partida numa janela 1920×1080, sem
## vsync, e mede 3 cenários com a câmera no zoom de jogo:
##   A  início (3 ipezinhos, dia)
##   B  vila média (15 ipezinhos com função, taverna/laboratório/campo/casas prontos)
##   C  vila cheia (40 ipezinhos) + invasão + chuva + noite
## Por cenário: tempo de quadro médio e p99, FPS, tempo de _process/_physics, nós, draw calls.
## No C ainda mede o CUSTO DE CADA SCRIPT (desliga o _process dos nós daquele script por um tempo e
## vê quanto o quadro cai) e das luzes/partículas (esconde e mede): é o "Profiler" reproduzível.
## Rodar (APPDATA isolado): powershell -File tools\bench_cena.ps1   -> bench_<data>.txt
const PATH := "user://savegame.json"
const ASSENTA := 2.5
const MEDE := 6.0
const ABLA := 2.0
var main: Node
var out_file := ""
var t := 0.0
var t_mark := 0.0
var step := 0
var amostras := []  # [delta, process, physics, draw_calls, objetos]
var linhas: Array[String] = []
var _abla_lista := []
var _abla_i := 0
var _abla_base := 0.0
var _abla_cost := []
var _rapido := false  # "-- <saída> rapido": sem a medição por script (só cenários + detalhe)


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_file = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://bench.txt")
	_rapido = "rapido" in args
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
	linhas.append("Deep Iron — bench_cena (%s)" % Time.get_datetime_string_from_system())
	linhas.append("máquina: %s, %d núcleos | GPU: %s | %s | janela %s, vsync desligado" % [
		OS.get_processor_name(), OS.get_processor_count(), RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_api_version(), str(DisplayServer.window_get_size())])
	linhas.append("")
	linhas.append("%-44s %8s %8s %6s %6s %6s" % ["cenário", "ms méd", "ms p99", "FPS", "nós", "draws"])


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	_ultimo_delta = delta
	if t > 900.0:
		print("TIMEOUT")
		_grava()
		return true
	if step in [1, 3, 5] and t - t_mark > ASSENTA:
		amostras.append([delta, Performance.get_monitor(Performance.TIME_PROCESS), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	match step:
		0:
			if t > 3.0:
				_mira()
				_next(1)
		1:
			if t - t_mark > ASSENTA + MEDE:
				_relata("A  início (3 ipezinhos, dia)")
				_monta_media()
				_next(3)
		3:
			if t - t_mark > ASSENTA + MEDE:
				_relata("B  vila média (15 ipezinhos, prédios)")
				_monta_cheia()
				_next(5)
		5:
			if t - t_mark > ASSENTA + MEDE:
				_relata("C  vila cheia (40) + invasão + chuva + noite")
				_detalhe()
				if _rapido:
					_grava()
					return true
				_abla_prepara()
				_next(7)
		7:
			_abla_tick()
			if step == 8:
				_grava()
				return true
	return false


func _next(s: int) -> void:
	step = s
	t_mark = t
	amostras.clear()


func _mira() -> void:
	var cam = main.get_node("Camera2D")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(2, 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	var hub := g("village_hub")
	cam.on_view_changed(hub.global_position if hub else Vector2(-200, -150))


func _relata(nome: String) -> void:
	if amostras.is_empty():
		return
	var ds := []
	var proc := 0.0
	var phys := 0.0
	var draws := 0.0
	var nos := 0.0
	for a in amostras:
		ds.append(a[0])
		proc += a[1]
		phys += a[2]
		draws += a[3]
		nos += a[4]
	var n := float(amostras.size())
	var tot := 0.0
	for d in ds:
		tot += d
	ds.sort()
	var med: float = tot / n * 1000.0
	var p99: float = ds[mini(int(ds.size() * 0.99), ds.size() - 1)] * 1000.0
	var l := "%-44s %8.2f %8.2f %6.0f %6.0f %6.0f" % [nome, med, p99, 1000.0 / med, nos / n, draws / n]
	linhas.append(l)
	print(l)


func _livre(perto: Vector2) -> Vector2:
	var placer := g("house_placer")
	placer._collect_blockers()
	for r in range(1, 18):
		for a in range(16):
			var p: Vector2 = perto + Vector2.RIGHT.rotated(a * TAU / 16.0 + r) * (70.0 + r * 30.0)
			if placer.check_spot(p) == "":
				return p
	return Vector2.INF


func _dinheiro() -> void:
	var eco := g("economy")
	eco.credits = 999999
	eco.max_workers = 60
	var arm := g("armazens")
	for ore in arm.stock.keys():
		arm.stock[ore] = 99999.0
	arm.wood_stored = 99999.0


func _termina_obras() -> void:
	for o in main.get_tree().get_nodes_in_group("obras"):
		if o.has_method("obra_pending") and o.obra_pending():
			o.obra_work(99999.0)


func _ipezinhos(total: int, jobs: Array) -> void:
	var eco := g("economy")
	var n := main.get_tree().get_nodes_in_group("ipezinhos").size()
	for i in maxi(total - n, 0):
		var w = eco.recruit_free()
		if w == null:
			break
	var ws := main.get_tree().get_nodes_in_group("ipezinhos")
	for i in ws.size():
		ws[i].set_job(jobs[i % jobs.size()])


func _monta_media() -> void:
	_dinheiro()
	var hub := g("village_hub")
	var c: Vector2 = hub.global_position
	for f in [func(p): g("morale")._confirm_taverna(p), func(p): g("research")._confirm_lab(p), func(p): g("defense")._confirm_campo(p),
			func(p): hub._confirm_house(p), func(p): hub._confirm_house(p)]:
		var p := _livre(c)
		if p != Vector2.INF:
			f.call(p)
	_termina_obras()
	_ipezinhos(15, ["minerador", "minerador", "lenhador", "cozinheiro", "cacador", "engenheiro", "pesquisador", "guarda"])
	_mira()


func _monta_cheia() -> void:
	_dinheiro()
	var hub := g("village_hub")
	for i in 3:
		var p := _livre(hub.global_position)
		if p != Vector2.INF:
			hub._confirm_house(p)
	_termina_obras()
	_ipezinhos(40, ["minerador", "minerador", "lenhador", "cozinheiro", "cacador", "guarda", "guarda", "engenheiro", "pesquisador"])
	var dn := g("day_night")
	dn.time = dn.day_duration + 5.0  # noite
	var w := g("weather")
	if w:
		w.forcar_chuva = true
		w.snap()
	var d := g("defense")
	if d and not d.invasion_active:
		d.start_invasion()
	_mira()


# ------------------------------------------------------------ detalhe: as partes da HUD e da vista iso
func _cronometra(nome: String, f: Callable, n: int = 30) -> void:
	var t0 := Time.get_ticks_usec()
	for i in n:
		f.call()
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / n
	linhas.append("  %-48s %7.3f ms por chamada" % [nome, ms])


func _detalhe() -> void:
	linhas.append("")
	linhas.append("Detalhe no cenário C (cada parte chamada 30x, média):")
	var hud := g("hud")
	var ws := main.get_tree().get_nodes_in_group("ipezinhos")
	if hud:
		_cronometra("hud._refresh (inteiro; roda %d x/s)" % int(hud.refresh_rate), func(): hud._refresh())
		_cronometra("  hud._refresh_phase", func(): hud._refresh_phase())
		_cronometra("  hud._refresh_top_bar", func(): hud._refresh_top_bar(ws))
		_cronometra("  hud._refresh_panels", func(): hud._refresh_panels())
		for id in hud._panels:
			var pn = hud._panels[id]
			_cronometra("    painel %s.refresh" % id, func(): pn.refresh(), 10)
		if hud._build_menu:
			_cronometra("    build_menu.refresh", func(): hud._build_menu.refresh(), 10)
		_cronometra("  hud._refresh_workforce", func(): hud._refresh_workforce(ws))
		_cronometra("  hud._refresh_order_bar", func(): hud._refresh_order_bar(ws))
		_cronometra("  hud._refresh_worker_rows", func(): hud._refresh_worker_rows(ws))
		_cronometra("hud._update_cursor (a cada 0,1 s)", func():
			hud._cursor_cd = 0.0
			hud._update_cursor(0.0))
	# _process de cada script chamado direto (o custo de CPU dele, sem o desenho)
	for grupo_script in [["coleta_comida", "food_source"], ["criaturas", "creature"], ["day_night", "day_night"], ["sun", "sun"],
			["ipezinhos", "ipezinho"], ["iso_fx", "iso_fx"]]:
		var nos := main.get_tree().get_nodes_in_group(grupo_script[0])
		if nos.is_empty():
			continue
		_cronometra("%s._process x%d (direto)" % [grupo_script[1], nos.size()], func():
			for n in nos:
				if is_instance_valid(n) and n.has_method("_process"):
					n._process(0.016), 10)
		if nos[0].has_method("_physics_process"):
			_cronometra("%s._physics_process x%d (direto)" % [grupo_script[1], nos.size()], func():
				for n in nos:
					if is_instance_valid(n):
						n._physics_process(0.016), 10)
	var iso := g("iso_view")
	if iso and iso.enabled:
		_cronometra("iso_view._process (inteiro, todo quadro)", func(): iso._process(0.016))
		_cronometra("  iso._sync_blocos", func(): iso._sync_blocos())
		_cronometra("  camera.zoom_stops", func(): iso._camera.zoom_stops())
		var view: Rect2 = iso._screen_view().grow(256.0)
		var dyn := []
		var stat := []
		for src in iso._ents:
			if is_instance_valid(src):
				(dyn if iso._ents[src].dynamic else stat).append(iso._ents[src])
		_cronometra("  sync_dynamic de %d que andam" % dyn.size(), func():
			for bb in dyn:
				bb.sync_dynamic(view))
		_cronometra("    _update_box (que andam)", func():
			for bb in dyn:
				bb._update_box())
		_cronometra("    _sync_props (que andam; 1 quadro sim 1 não)", func():
			for bb in dyn:
				bb._sync_props())
		_cronometra("    _tool_rule (que andam)", func():
			for bb in dyn:
				bb._tool_rule(true))
		_cronometra("    _sync_char (que andam)", func():
			for bb in dyn:
				bb._sync_char())
		var IB = load("res://scripts/iso/iso_bonecos.gd")
		var wsx := ws.filter(func(w): return is_instance_valid(w))
		_cronometra("      IsoBonecos.pose (40 ipezinhos)", func():
			for w in wsx:
				IB.pose(w, 1, 0.5))
		_cronometra("        folders", func():
			for w in wsx:
				IB.folders(w))
		_cronometra("        _tone", func():
			for w in wsx:
				IB._tone(w))
		_cronometra("        _item_name", func():
			for w in wsx:
				IB._item_name(w))
		_cronometra("        work_anim", func():
			for w in wsx:
				IB.work_anim(w))
		_cronometra("        enabled_for", func():
			for w in wsx:
				IB.enabled_for(w))
		_cronometra("    src.set_meta + diamond_dir (que andam)", func():
			for bb in dyn:
				bb.src.set_meta("iso_dir", iso.diamond_dir(Vector2(1, 0.3), bb.iso_dir)))
		_cronometra("  sync_static de %d fixas (1/%d por quadro)" % [stat.size(), iso.STATIC_SYNC_EVERY], func():
			for bb in stat:
				bb.sync_static(view), 5)
		_cronometra("    _sync_props das fixas (inclui _sync_art)", func():
			for bb in stat:
				bb._sync_props(), 5)
		_cronometra("    _sync_art das fixas", func():
			for bb in stat:
				bb._sync_art(), 5)
		_cronometra("    _update_box das fixas", func():
			for bb in stat:
				bb._update_box(), 5)
		_cronometra("  _apply_static_z", func(): iso._apply_static_z(), 10)
		var boxes := dyn.map(func(bb): return bb.box)
		_cronometra("  _order.dynamic_z de %d" % boxes.size(), func(): iso._order.dynamic_z(boxes))
		_cronometra("  _sync_ghost", func(): iso._sync_ghost())


# ------------------------------------------------------------ custo por script / luzes / partículas
func _abla_prepara() -> void:
	var por_script := {}
	for n in _todos(main):
		var s: Script = n.get_script()
		if s == null or not (n.is_processing() or n.is_physics_processing()):
			continue
		var k := s.resource_path.get_file()
		if not por_script.has(k):
			por_script[k] = []
		por_script[k].append(n)
	_abla_lista.clear()
	for k in por_script:
		_abla_lista.append(["script " + k, por_script[k]])
	_abla_lista.append(["luzes 2D (PointLight2D)", _todos(main).filter(func(n): return n is PointLight2D)])
	_abla_lista.append(["partículas (CPU/GPU)", _todos(main).filter(func(n): return n is CPUParticles2D or n is GPUParticles2D)])
	_abla_i = -1
	_abla_cost.clear()
	linhas.append("")
	linhas.append("Custo no cenário C (quadro médio sem aquilo; base medida antes de cada um):")


var _abla_fase := 0  # 0 = base, 1 = sem
var _abla_amostras := []


func _abla_tick() -> void:
	if _abla_i < 0 or (t - t_mark > ABLA and _abla_fase == 1):
		if _abla_i >= 0:
			var sem := _media(_abla_amostras)
			_abla_restaura(_abla_lista[_abla_i])
			_abla_cost.append([_abla_lista[_abla_i][0], _abla_base - sem, _abla_lista[_abla_i][1].size()])
		_abla_i += 1
		if _abla_i >= _abla_lista.size():
			_abla_cost.sort_custom(func(a, b): return a[1] > b[1])
			for c in _abla_cost:
				if c[1] > 0.05:
					linhas.append("  %-48s %6.2f ms  (%d nós)" % [c[0], c[1], c[2]])
			step = 8
			return
		_abla_fase = 0
		_abla_amostras.clear()
		t_mark = t
		return
	if t - t_mark > 0.4:
		_abla_amostras.append(_ultimo_delta)
	if _abla_fase == 0 and t - t_mark > ABLA:
		_abla_base = _media(_abla_amostras)
		_abla_amostras.clear()
		_abla_desliga(_abla_lista[_abla_i])
		_abla_fase = 1
		t_mark = t


var _ultimo_delta := 0.0


func _media(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for x in a:
		s += x
	return s / a.size() * 1000.0


func _abla_desliga(item: Array) -> void:
	for n in item[1]:
		if not is_instance_valid(n):
			continue
		if n is PointLight2D:
			n.set_meta("_bench", n.enabled)
			n.enabled = false
		elif n is CPUParticles2D or n is GPUParticles2D:
			n.set_meta("_bench", n.visible)
			n.visible = false
		else:
			n.set_meta("_bench", [n.is_processing(), n.is_physics_processing()])
			n.set_process(false)
			n.set_physics_process(false)


func _abla_restaura(item: Array) -> void:
	for n in item[1]:
		if not is_instance_valid(n) or not n.has_meta("_bench"):
			continue
		var m = n.get_meta("_bench")
		if n is PointLight2D:
			n.enabled = m
		elif n is CPUParticles2D or n is GPUParticles2D:
			n.visible = m
		else:
			n.set_process(m[0])
			n.set_physics_process(m[1])
		n.remove_meta("_bench")


func _todos(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_todos(c))
	return out


func _grava() -> void:
	var f := FileAccess.open(out_file, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(linhas) + "\n")
		f.close()
	print("\n".join(linhas))
