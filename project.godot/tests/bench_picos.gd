extends SceneTree
## Bloco 131: benchmark das TRAVADAS (não é teste do GUT). Janela 1280x720 (sem vsync), pasta de usuário isolada.
## Cenários (todos na vila cheia: 40 ipezinhos com função, casas, taverna, laboratório, campo; câmera no zoom de jogo):
##   N  noite: a vila cheia à noite, parado (o custo de todo quadro)
##   S  hora social: a hora social de verdade (todo mundo nos pontos sociais)
##   O  obra pronta: uma casa fica pronta (clear_decor_under_extras + rebuild_navigation) — repetido 5x
##   E  subida de estágio: a vila sobe de estágio (_finish_expansion) — repetido 3x
## Pra cada um: tempo de quadro médio, p99 e MAIOR (ms) numa janela de quadros, e nos de pico a duração da própria chamada
## (µs com Time.get_ticks_usec) + o maior quadro dos 30 seguintes. Saída: arquivo (-- <saída> [rapido]).
##   powershell -File tools\bench_picos.ps1
const PATH := "user://savegame.json"
const ASSENTA := 2.0
const MEDE := 8.0
var main: Node
var out_file := ""
var t := 0.0
var t_mark := 0.0
var step := 0
var deltas: Array[float] = []
var linhas: Array[String] = []
var _pico_n := 0
var _pico_calls: Array[float] = []
var _pico_max: Array[float] = []
var _janela := 0  # quadros restantes da janela de um pico
var _rapido := false
var _frame := 0
var _seq: Array = []
var _frio_feito := false
var _aqueceu := false
var _janela_frio := 0
var _seq_frio: Array = []
var _seq_rend: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_file = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://bench_picos.txt")
	_rapido = "rapido" in args
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1280, 720)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	linhas.append("Deep Iron — bench_picos (%s)" % Time.get_datetime_string_from_system())
	linhas.append("máquina: %s, %d núcleos | GPU: %s | janela %s, vsync desligado" % [
		OS.get_processor_name(), OS.get_processor_count(), RenderingServer.get_video_adapter_name(), str(DisplayServer.window_get_size())])
	linhas.append("")
	linhas.append("%-40s %8s %8s %9s %7s" % ["cenário (quadros)", "ms méd", "ms p99", "ms maior", "FPS"])


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	_frame += 1
	if t > 600.0:
		print("TIMEOUT")
		_grava()
		return true
	if step in [1, 3] and t - t_mark > ASSENTA:
		deltas.append(delta)
	if _janela_frio > 0:
		var vp := root.get_viewport_rid()
		_seq_frio.append(snappedf(delta * 1000.0, 0.1))
		_seq_rend.append("%.0f/%.0f/%.0f" % [delta * 1000.0, RenderingServer.viewport_get_measured_render_time_cpu(vp), RenderingServer.viewport_get_measured_render_time_gpu(vp)])
		_janela_frio -= 1
		if _janela_frio == 0:
			print("  quadros depois dos frios: ", _seq_frio)
			print("  quadros depois dos frios (quadro/render cpu/gpu): ", _seq_rend)
			linhas.append("  quadros depois dos frios (a 1ª vez de cada coisa da subida, chamada antes): maior %.1f ms" % _seq_frio.max())
	if _janela > 0:
		_pico_max[-1] = maxf(_pico_max[-1], delta * 1000.0)
		_seq.append("%.0f/%.0f/%.0f" % [delta * 1000.0, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
		_janela -= 1
		if _janela == 0:
			var iso2 := g("iso_view")
			var o2 = iso2.get("_order") if iso2 else null
			if o2:
				print("  ordem depois: reconstrucoes=%d reparos=%d" % [o2.full_rebuilds, o2.repairs])
			print("  quadros depois do pico: ", _seq)
			_seq = []
	match step:
		0:
			if t > 3.0:
				_monta()
				_next(1)
		1:  # noite
			if t - t_mark > ASSENTA + MEDE:
				_relata("N  vila cheia à noite")
				var dn := g("day_night")
				dn.time = dn.tempo_da_hora(20.0)  # a hora social (depois de anoitecer)
				_next(3)
		3:
			if t - t_mark > ASSENTA + MEDE:
				_relata("S  hora social (20:00)")
				_pico_n = 0
				_next(5)
		5:  # obra pronta x5 (uma por 1,2 s)
			if t - t_mark > 1.0 + 1.5 * _pico_n and _pico_n < 5 and _janela == 0:
				_obra_pronta()
			if _pico_n >= 5 and _janela == 0:
				_relata_pico("O  obra pronta, 5x")
				_pico_n = 0
				_next(7)
		7:  # subida de estágio x3
			if t - t_mark > 2.0 + 2.5 * _pico_n and _pico_n < 3 and _janela == 0 and _janela_frio == 0:
				_sobe_estagio()
			if _pico_n >= 3 and _janela == 0:
				_relata_pico("E  subida de estágio, 3x")
				_pico_n = 0
				_next(9)
		9:  # P: chega um morador novo (o padre, que chega uns segundos depois da subida)
			if _pico_n == 0 and not _aqueceu:
				_aqueceu = true
				var cal_a := g("calendario")
				if cal_a and cal_a.has_method("aquece_padre"):
					cal_a.aquece_padre()  # (como no jogo: começa a carregar quando a vila chega no estágio)
			if t - t_mark > 2.5 and _pico_n == 0 and _janela == 0:
				var cal := g("calendario")
				if cal and not cal.padre_chegou:
					var t0 := Time.get_ticks_usec()
					cal.chega_padre()
					_pico_calls.append((Time.get_ticks_usec() - t0) / 1000.0)
					_pico_max.append(0.0)
					_janela = 30
				_pico_n = 1
			if _pico_n == 1 and _janela == 0 and t - t_mark > 3.5:
				_relata_pico("P  chega um morador (o padre)")
				_partes()
				_next(11)
		11:  # espera a malha do pedido de _partes e grava
			if t - t_mark > 4.0:
				_grava()
				return true
	return false


func _next(s: int) -> void:
	step = s
	t_mark = t
	deltas.clear()


func _relata(nome: String) -> void:
	if deltas.is_empty():
		return
	var ds := deltas.duplicate()
	ds.sort()
	var tot := 0.0
	for d in ds:
		tot += d
	var med: float = tot / ds.size() * 1000.0
	var p99: float = ds[mini(int(ds.size() * 0.99), ds.size() - 1)] * 1000.0
	var mx: float = ds[-1] * 1000.0
	var l := "%-40s %8.2f %8.2f %9.2f %7.0f" % ["%s (%d)" % [nome, ds.size()], med, p99, mx, 1000.0 / med]
	linhas.append(l)
	print(l)


func _relata_pico(nome: String) -> void:
	var mc := 0.0
	var mq := 0.0
	var sc := 0.0
	var sq := 0.0
	for i in _pico_calls.size():
		mc = maxf(mc, _pico_calls[i])
		mq = maxf(mq, _pico_max[i])
		sc += _pico_calls[i]
		sq += _pico_max[i]
	var n := maxf(_pico_calls.size(), 1.0)
	var l := "%-40s chamada méd %7.1f / maior %7.1f ms | maior quadro nos 30 seguintes: méd %7.1f / maior %7.1f ms" % [
		nome, sc / n, mc, sq / n, mq]
	linhas.append(l)
	print(l)
	_pico_calls.clear()
	_pico_max.clear()


func _livre(perto: Vector2) -> Vector2:
	var placer := g("house_placer")
	placer._collect_blockers()
	for r in range(1, 18):
		for a in range(16):
			var p: Vector2 = perto + Vector2.RIGHT.rotated(a * TAU / 16.0 + r) * (70.0 + r * 30.0)
			if placer.check_spot(p) == "":
				return p
	return Vector2.INF


func _termina_obras() -> void:
	for o in main.get_tree().get_nodes_in_group("obras"):
		if o.has_method("obra_pending") and o.obra_pending():
			o.obra_work(99999.0)


func _monta() -> void:
	var eco := g("economy")
	eco.credits = 999999
	eco.max_workers = 60
	var arm := g("armazens")
	for ore in arm.stock.keys():
		arm.stock[ore] = 99999.0
	arm.wood_stored = 99999.0
	var hub := g("village_hub")
	var c: Vector2 = hub.global_position
	for f in [func(p): g("morale")._confirm_taverna(p), func(p): g("research")._confirm_lab(p), func(p): g("defense")._confirm_campo(p),
			func(p): hub._confirm_house(p), func(p): hub._confirm_house(p), func(p): hub._confirm_house(p)]:
		var p := _livre(c)
		if p != Vector2.INF:
			f.call(p)
	_termina_obras()
	var jobs := ["minerador", "minerador", "lenhador", "cozinheiro", "caçador", "guarda", "guarda", "engenheiro", "pesquisador"]
	var n := main.get_tree().get_nodes_in_group("ipezinhos").size()
	for i in maxi(40 - n, 0):
		if eco.recruit_free() == null:
			break
	var ws := main.get_tree().get_nodes_in_group("ipezinhos")
	for i in ws.size():
		ws[i].set_job(jobs[i % jobs.size()])
	var dn := g("day_night")
	dn.time = dn.day_duration + 5.0  # noite
	var cam = main.get_node("Camera2D")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(2, 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(c)


const Canteiro := preload("res://scripts/props/canteiro.gd")
const TIPOS_OBRA := ["campo", "arsenal", "taverna", "laboratorio", "campo"]


## Uma obra que fica pronta: o que o jogo faz quando o engenheiro termina (Canteiro -> prédio -> decoração e navegação). Como
## no jogo, o canteiro existe um tempo antes (1 s aqui) e só então termina.
var _canteiro: Node = null
var _t_canteiro := 0.0


func _obra_pronta() -> void:
	if _canteiro == null:
		var hub := g("village_hub")
		var p := _livre(hub.global_position + Vector2(randf_range(-80, 80), randf_range(-60, 60)))
		if p == Vector2.INF:
			_pico_n += 1
			return
		_canteiro = Canteiro.order(main.get_tree(), TIPOS_OBRA[_pico_n % TIPOS_OBRA.size()], p, 30.0)
		_t_canteiro = t
		if _canteiro == null:
			_pico_n += 1
		return
	if t - _t_canteiro < 1.0:
		return
	var c: Node = _canteiro
	_canteiro = null
	_pico_n += 1
	var iso := g("iso_view")
	var ord = iso.get("_order") if iso else null
	if ord:
		print("  ordem antes da obra: reconstrucoes=%d reparos=%d estaticas=%d" % [ord.full_rebuilds, ord.repairs, ord.order.size()])
	var t0 := Time.get_ticks_usec()
	c.obra_work(99999.0)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("obra %s: chamada %.1f ms" % [c.kind, ms])
	_pico_calls.append(ms)
	_pico_max.append(0.0)
	_janela = 30


## O custo de cada parte: a decoração debaixo das estruturas, os PEDIDOS de malha (3 no mesmo quadro) e quanto tempo até a
## malha nova entrar (assíncrona: o quadro não espera); e, de referência, o bake síncrono sozinho.
func _partes() -> void:
	var env := g("environment")
	var iso_p := g("iso_view")
	if iso_p:
		for k in 3:
			_tempo("vista iso: reordenar TODAS as fixas (_rebuild_order) #%d" % (k + 1), func(): iso_p._rebuild_order())
	if not env.has_method("_fonte_navegacao"):
		var tr := Time.get_ticks_usec()
		env.rebuild_navigation()
		var lr := "  partes (código antigo): rebuild_navigation síncrono %.1f ms" % [(Time.get_ticks_usec() - tr) / 1000.0]
		linhas.append(lr)
		print(lr)
		return
	var t0 := Time.get_ticks_usec()
	env.clear_decor_under_extras()
	var t1 := Time.get_ticks_usec()
	var b0: int = env.nav_bakes
	env.rebuild_navigation()
	env.rebuild_navigation()
	env.rebuild_navigation()
	var t2 := Time.get_ticks_usec()
	var l := "  partes: clear_decor_under_extras (pedido) %.1f ms | 3 pedidos de malha no mesmo quadro %.2f ms" % [
		(t1 - t0) / 1000.0, (t2 - t1) / 1000.0]
	linhas.append(l)
	print(l)
	_espera_malha(t2, b0)
	var t3 := Time.get_ticks_usec()
	var src = env._fonte_navegacao()
	var t4 := Time.get_ticks_usec()
	var np := NavigationPolygon.new()
	np.agent_radius = env.nav_agent_radius
	NavigationServer2D.bake_from_source_geometry_data(np, src)
	var t5 := Time.get_ticks_usec()
	var np2 = env._sem_degenerados(np)
	var t6 := Time.get_ticks_usec()
	env.navigation_region.navigation_polygon = np2
	var t7 := Time.get_ticks_usec()
	var l2 := "  referência (síncrono): geometria %.1f ms | bake %.1f ms | _sem_degenerados %.1f ms (%d polígonos) | trocar a malha da região %.1f ms" % [
		(t4 - t3) / 1000.0, (t5 - t4) / 1000.0, (t6 - t5) / 1000.0, np.get_polygon_count(), (t7 - t6) / 1000.0]
	linhas.append(l2)
	print(l2)


func _espera_malha(t2: int, b0: int) -> void:
	var env := g("environment")
	if env.has_signal("navigation_rebuilt"):
		await env.navigation_rebuilt
		var l := "  malha nova entrou %.0f ms depois do pedido (bakes feitos: %d pros 3 pedidos)" % [
			(Time.get_ticks_usec() - t2) / 1000.0, env.nav_bakes - b0]
		linhas.append(l)
		print(l)


var _novos := {}
var _novos_ate := -1


func _conta_novo(n: Node) -> void:
	if _frame > _novos_ate:
		if node_added.is_connected(_conta_novo):
			node_added.disconnect(_conta_novo)
		var top: Array = _novos.keys()
		top.sort_custom(func(a, b): return _novos[a] > _novos[b])
		var l := "  nós criados nos 3 quadros da 1ª subida: %s" % str(top.slice(0, 12).map(func(k): return "%s x%d" % [k, _novos[k]]))
		linhas.append(l)
		print(l)
		return
	var dono: String = String(n.get_parent().name) if n.get_parent() else "?"
	var k := "%s<%s" % [n.get_class(), dono]
	_novos[k] = int(_novos.get(k, 0)) + 1


func _tempo(nome: String, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	f.call()
	var l := "  frio: %-46s %7.1f ms" % [nome, (Time.get_ticks_usec() - t0) / 1000.0]
	linhas.append(l)
	print(l)


## O custo "frio" (a 1ª vez) dos suspeitos da subida de estágio.
func _frios() -> void:
	var hub := g("village_hub")
	var iso := g("iso_view")
	_tempo("Audio.stinger('estagio_novo')", func(): root.get_node("Audio").stinger("estagio_novo"))
	_tempo("hub._stage_dust(2) (filho novo: poeira)", func(): hub._stage_dust(2))
	var bb = iso.billboard_of(hub) if iso else null
	if bb:
		_tempo("espelho do Centro: _sync_props com filho novo", func(): bb._sync_props())
	_tempo("hub._grow_to_stage(2)", func(): hub._grow_to_stage(2))
	_tempo("hub._update_visual()", func(): hub._update_visual())
	var hud := g("hud")
	if hud:
		_tempo("hud.show_banner", func(): hud.show_banner("TESTE", "x"))
	if iso:
		_tempo("vista iso: reordenar TODAS as fixas (_rebuild_order)", func(): iso._rebuild_order())
	var eco := g("economy")
	var antes := main.get_tree().get_nodes_in_group("ipezinhos").size()
	_tempo("morador novo: eco.novo_ipezinho (a cena)", func(): eco.novo_ipezinho("M"))
	var novo: Node = main.get_tree().get_nodes_in_group("ipezinhos")[-1]
	if iso and main.get_tree().get_nodes_in_group("ipezinhos").size() > antes:
		_tempo("morador novo: o espelho na vista iso (iso._process)", func(): iso._process(0.016))
	if hud:
		_tempo("morador novo: a HUD (hud._refresh)", func(): hud._refresh())
	var cal := g("calendario")
	if cal and not cal.padre_chegou:
		_tempo("o padre chega (cal.chega_padre)", func(): cal.chega_padre())
		if iso:
			_tempo("o padre: o espelho na vista iso (iso._process)", func(): iso._process(0.016))


func _sobe_estagio() -> void:
	var hub := g("village_hub")
	var eco := g("economy")
	var cal0 := g("calendario")
	if cal0:
		cal0.set("padre_atraso", 9999.0)  # (o padre é o cenário P, à parte; no código antigo ele chega junto com a subida)
	eco.credits = 999999
	hub.pending_upgrade = "expandir"
	hub.upgrade_left = 0.001
	var iso := g("iso_view")
	var ord = iso.get("_order") if iso else null
	if ord:
		print("  ordem antes: reconstrucoes=%d reparos=%d estaticas=%d" % [ord.full_rebuilds, ord.repairs, ord.order.size()])
	var o0 = iso.get("_order") if iso else null
	if o0:
		print("  subida: reconstrucoes da ordem antes=%d" % o0.full_rebuilds)
	var env0 := g("environment")
	var ped0: int = int(env0.get("nav_pedidos")) if env0.get("nav_pedidos") != null else 0
	var t0 := Time.get_ticks_usec()
	hub.obra_work(1.0)
	_pico_calls.append((Time.get_ticks_usec() - t0) / 1000.0)
	_pico_max.append(0.0)
	_janela = 30
	_pico_n += 1


func _grava() -> void:
	var f := FileAccess.open(out_file, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(linhas) + "\n")
		f.close()
	print("gravado: ", out_file)
