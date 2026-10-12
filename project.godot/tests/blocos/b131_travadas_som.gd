extends SceneTree
## Bloco 131: TRAVADAS e o SOM CHATO À NOITE. RODAR SÓ COM APPDATA ISOLADO.
##   (A) a malha de navegação em segundo plano: 3 pedidos no mesmo quadro = 1 bake, a chamada não espera o bake, a malha
##       antiga vale até a nova entrar (sinal navigation_rebuilt); o pedido "imediato" (carregar save) continua síncrono;
##   (B) a limpeza da decoração debaixo das estruturas agrupada (uma por quadro) e a área já limpa não é varrida de novo;
##   (C) o padre chega uns segundos DEPOIS da subida de estágio (antes vinha no mesmo quadro do tranco);
##   (D) a ordem de desenho (topo_order com a grade da tela) é IGUAL à de antes (todos os pares), em caixas sorteadas;
##   (E) o desenho do prédio pronto aquecido em segundo plano é o mesmo que o load direto;
##   (F) o diagnóstico de som: a lista dos sons ativos (slot, bus, dB, loop), silenciar/voltar por slot, o bus "Soltos" com o
##       slider próprio nas Configurações.
var fails := 0
var main: Node
const IsoCore := preload("res://scripts/iso/iso_core.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _roda() -> void:
	await _frames(6)
	var env := g("environment")
	check(env != null and env.navigation_region != null, "o ambiente e a malha existem")

	print("== (A) a malha em segundo plano, com os pedidos agrupados")
	var Env: GDScript = load("res://scripts/core/environment.gd")
	check(not env._nav_assincrona(), "em headless o padrão continua síncrono (os testes antigos não mudam)")
	Env.bake_assincrono_forcado = true
	await _frames(2)
	var antiga: NavigationPolygon = env.navigation_region.navigation_polygon
	var ped0: int = env.nav_pedidos
	var bakes0: int = env.nav_bakes
	var t0 := Time.get_ticks_usec()
	env.rebuild_navigation()
	env.rebuild_navigation()
	env.rebuild_navigation()
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	check(env.nav_pedidos == ped0 + 3, "3 pedidos contados")
	check(ms < 50.0, "os pedidos não esperam o bake (%.2f ms)" % ms)
	check(not env.navegacao_em_dia(), "a navegação sabe que há um bake pendente")
	check(env.navigation_region.navigation_polygon == antiga, "a malha antiga continua valendo enquanto isso")
	var entrou := [false]
	env.navigation_rebuilt.connect(func(): entrou[0] = true, CONNECT_ONE_SHOT)
	var espera := 0
	while not entrou[0] and espera < 600:
		await process_frame
		espera += 1
	check(entrou[0], "a malha nova entrou (sinal navigation_rebuilt, %d quadros)" % espera)
	check(env.nav_bakes == bakes0 + 1, "os 3 pedidos viraram 1 bake (%d)" % (env.nav_bakes - bakes0))
	check(env.navigation_region.navigation_polygon != antiga and env.navigation_region.navigation_polygon.get_polygon_count() > 0,
		"a malha nova trocou a antiga e tem polígonos (%d)" % env.navigation_region.navigation_polygon.get_polygon_count())
	check(env.navegacao_em_dia(), "e a navegação ficou em dia")
	# pedido durante o bake: entra mais UM bake depois (com a geometria de agora), não se perde
	env.rebuild_navigation()
	await process_frame  # (o bake começou)
	env.rebuild_navigation()
	env.rebuild_navigation()
	var b1: int = env.nav_bakes
	espera = 0
	while not env.navegacao_em_dia() and espera < 900:
		await process_frame
		espera += 1
	check(env.navegacao_em_dia() and env.nav_bakes == b1 + 1, "o pedido feito durante o bake vira mais um bake só (%d)" % (env.nav_bakes - b1))
	var b2: int = env.nav_bakes
	var antes_imediato: NavigationPolygon = env.navigation_region.navigation_polygon
	env.rebuild_navigation(true)
	check(env.nav_bakes == b2 + 1 and env.navigation_region.navigation_polygon != antes_imediato and env.navegacao_em_dia(),
		"o pedido imediato (carregar save, fundar a vila) é síncrono: a malha já trocou no ato")

	print("== (B) a decoração debaixo das estruturas, agrupada")
	Env.bake_assincrono_forcado = true  # (o caminho do jogo; em headless é na hora)
	env.clear_decor_under_extras()
	env.clear_decor_under_extras()
	check(env._decor_agendado, "o pedido fica agendado pro fim do quadro (não varre no ato)")
	await _frames(2)
	check(not env._decor_agendado, "e foi feito uma vez")
	Env.bake_assincrono_forcado = false
	var area := Rect2(Vector2(123, 456), Vector2(40, 30))
	env._limpa_decor_uma_vez(area)
	check(env._areas_limpas.has(area), "a área limpa fica marcada (não é varrida de novo a cada pedido)")

	print("== (C) o padre chega depois da subida")
	var cal := g("calendario")
	var hub := g("village_hub")
	check(cal.padre_atraso > 0.0, "padre_atraso = %.1f s (@export)" % cal.padre_atraso)
	if cal.padre() == null and not cal.padre_chegou:
		hub.level = cal.padre_estagio
		cal._process(0.0)
		check(cal.padre() == null, "no quadro da subida o padre ainda não chegou (o tranco não se soma)")
		cal._process(cal.padre_atraso + 0.1)
		check(cal.padre() != null, "e chega depois do atraso")
	else:
		check(true, "(o padre já estava na vila)")

	print("== (D) a ordem de desenho é a mesma de antes")
	seed(131)
	var iguais := true
	var maior := 0
	for rodada in 6:
		var caixas := []
		var n := 40 + rodada * 30
		for i in n:
			var p := Vector2(randf_range(0, 900), randf_range(0, 900))
			var s := Vector2(randf_range(8, 90), randf_range(8, 90))
			var zb := 0.0 if randf() < 0.8 else randf_range(0, 40)
			caixas.append(IsoCore.Box.new(Rect2(p, s), zb, zb + randf_range(4, 80), "predio", "c%d" % i))
		var novo := IsoCore.topo_order(caixas)
		var velho := _topo_antigo(caixas)
		maior = n
		for i in n:
			if novo[i] != velho[i]:
				iguais = false
				break
	check(iguais, "topo_order com a grade = todos os pares (6 conjuntos sorteados, até %d caixas)" % maior)

	print("== (E) o desenho pronto aquecido em segundo plano")
	var kind := ""
	for k in IsoArt.data().keys():
		var e: Dictionary = IsoArt.entry(k)
		if e.has("pronto") and e["pronto"] is Dictionary and String(e["pronto"].get("img", "")) != "" and not IsoArt._tex.has(String(e["pronto"].img)):
			kind = k
			break
	if kind == "":
		check(true, "(todos os desenhos prontos já estavam carregados)")
	else:
		var img := String(IsoArt.entry(kind)["pronto"].img)
		IsoArt.aquece(kind)
		check(ResourceLoader.load_threaded_get_status(IsoArt.DIR + img) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE,
			"o desenho pronto de '%s' começou a carregar em segundo plano" % kind)
		var tex := IsoArt.texture(img)
		check(tex != null and tex == load(IsoArt.DIR + img), "e é o mesmo recurso do load direto")

	print("== (F) o diagnóstico de som")
	var au := root.get_node("Audio")
	check(AudioServer.get_bus_index(&"Soltos") >= 0, "o bus Soltos existe")
	var soltos_ok := true
	for q in au._pont_pool:
		soltos_ok = soltos_ok and q.bus == &"Soltos"
	check(soltos_ok and au._pont_pool.size() > 0, "os sons soltos (coruja, sapo...) saem no bus Soltos")
	au.soltos_volume = 0.25
	au.apply_volumes()
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Soltos")), linear_to_db(0.25)), "o volume dos soltos vai pro bus")
	au.save_settings()
	check(is_equal_approx(float(au.Settings.get_value("audio", "soltos_volume", -1.0)), 0.25), "e fica nas configurações")
	au.soltos_volume = 0.8
	au.apply_volumes()
	# um efeito posicional pelo slot: a lista mostra slot, bus, volume e loop
	var id := ""
	for s in au.Slots.todos():
		var sl: Dictionary = au.Slots.slot(s)
		if String(s).begins_with("sfx/") and String(sl.get("tipo", "")) == "tiro" and not au._slot_streams(s).is_empty():
			id = s
			break
	check(id != "", "um slot de efeito com som pra testar (%s)" % id)
	var cam := root.get_viewport().get_camera_2d()
	var pos: Vector2 = cam.get_screen_center_position() if cam else Vector2.ZERO
	check(au.som(id, pos), "o efeito tocou")
	var achou := {}
	for s in au.sons_ativos():
		if s.id == id:
			achou = s
	check(not achou.is_empty(), "a lista ao vivo mostra o slot pelo nome (%s)" % id)
	if not achou.is_empty():
		check(String(achou.bus) != "" and float(achou.db) < 40.0 and achou.has("loop") and float(achou.dist) >= 0.0,
			"com o bus (%s), o volume em dB (%.1f), a distância (%d px) e se é loop (%s)" % [achou.bus, achou.db, int(achou.dist), achou.loop])
	await _frames(3)  # (como no jogo: o som já está tocando quando o Marco clica)
	au.silenciar(id, true)
	check(au.silenciado(id), "silenciado")
	var pausado := true
	var vistos := []
	for s in au.sons_ativos():
		if s.id == id:
			pausado = pausado and (s.player as Node).get("stream_paused")
			vistos.append("%s playing=%s paused=%s" % [(s.player as Node).name, (s.player as Node).get("playing"), (s.player as Node).get("stream_paused")])
	check(pausado, "o que já tocava pausou %s" % str(vistos))
	check(not au.som(id, pos), "e o slot silenciado não toca de novo")
	au.silenciar(id, false)
	check(not au.silenciado(id) and au.som(id, pos), "Voltar: toca de novo")
	# a janela do F3
	var dbg := g("debug_panel") if g("debug_panel") else main.find_child("DebugPanel", true, false)
	if dbg and dbg.has_method("_sons_ativos"):
		dbg._sons_ativos()
		await process_frame
		var pn := g("sons_ativos")
		check(pn != null and pn.visible, "F3 > Som: a janela 'o que está tocando agora' abre")
		if pn:
			pn.atualiza()
			var linhas: Array = pn.find_child("Lista", true, false).get_children()
			var tem := false
			for l in linhas:
				tem = tem or String(l.name) == "Som_" + id.replace("/", "_")
			check(tem, "com uma linha por slot tocando (%d linhas) e o botão Silenciar" % linhas.size())
	else:
		check(OS.is_debug_build() == false, "o painel de debug existe (build de editor)")
	# Configurações: os 3 controles separados
	var SP: GDScript = load("res://scripts/ui/settings_panel.gd")
	var fonte := SP.source_code
	check(fonte.contains("\"ambience_volume\"") and fonte.contains("\"soltos_volume\"") and fonte.contains("\"music_volume\""),
		"Configurações: ambiência, sons soltos e música em sliders separados")

	print("FALHAS: %d" % fails)
	quit()


## O topo_order de antes do Bloco 131 (todos os pares, na ordem i < j), pra comparar.
func _topo_antigo(boxes: Array) -> Array:
	var n := boxes.size()
	var rects := []
	for b in boxes:
		rects.append(IsoCore.screen_rect(b))
	var after := []
	var indeg := []
	for i in n:
		after.append([])
		indeg.append(0)
	for i in n:
		for j in range(i + 1, n):
			if not rects[i].intersects(rects[j]):
				continue
			var r = IsoCore.behind(boxes[i], boxes[j])
			if r == true:
				after[i].append(j)
				indeg[j] += 1
			elif r == false:
				after[j].append(i)
				indeg[i] += 1
	var ready := []
	for i in n:
		if indeg[i] == 0:
			ready.append(i)
	var out := []
	var done := []
	done.resize(n)
	done.fill(false)
	while out.size() < n:
		if ready.is_empty():
			var best := -1
			for i in n:
				if not done[i] and (best < 0 or IsoCore.key(boxes[i]) < IsoCore.key(boxes[best])):
					best = i
			ready.append(best)
		var k := 0
		for q in range(1, ready.size()):
			if IsoCore.key(boxes[ready[q]]) < IsoCore.key(boxes[ready[k]]):
				k = q
		var i: int = ready[k]
		ready.remove_at(k)
		if done[i]:
			continue
		done[i] = true
		out.append(boxes[i])
		for j in after[i]:
			indeg[j] -= 1
			if indeg[j] == 0 and not done[j]:
				ready.append(j)
	return out
