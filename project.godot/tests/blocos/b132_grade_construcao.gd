extends SceneTree
## Bloco 132: a GRADE DE CONSTRUÇÃO. RODAR SÓ COM APPDATA ISOLADO.
##   (A) a grade única (grade.gd = a célula dos caminhos; pegada arredondada pra cima, centrada nas células);
##   (B) casas/prédios ENCOSTADOS são aceitos (folga zero) e o fantasma encaixa na grade;
##   (C) a PORTA: cobrir a porta de outro prédio é recusado; o prédio cuja porta cairia num vizinho também; o acesso ao Centro;
##   (D) RUAS na grade: em cima da faixa da porta, reta (Shift) e retângulo (Ctrl); rua não é obstáculo pra construir;
##   (E) o TERRENO da vila: a decoração removível de dentro da área some; a borda, as entradas e as peças do mapa ficam;
##   (F) LIMPAR uma peça no modo de construção (custo, sem reembolso) e o save (`decor_limpa`; save antigo sem a chave);
##   (G) a VISÃO DE CONSTRUÇÃO na vista iso (aparece no modo, não refaz todo quadro, G liga/desliga) e o F8 reservado;
##   (H) a navegação continua: caminho da porta do prédio novo até o Centro.
var fails := 0
var main: Node
const Grade := preload("res://scripts/core/grade.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
var HousePlacer: GDScript  # (load no _roda: o script usa o autoload Audio)
const Canteiro := preload("res://scripts/props/canteiro.gd")
const TAVERNA_TEX := preload("res://assets/game/taverna.png")


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


## Um lugar perto de `c` em que o fantasma atual cabe (e a condição extra), ou INF.
func _acha(hp: Node, c: Vector2, extra := Callable()) -> Vector2:
	for r in range(0, 520, 21):
		for a in range(24):
			hp.move_to(c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r)
			if hp._reason == "" and (not extra.is_valid() or extra.call(hp._pos)):
				return hp._pos
	return Vector2.INF


func _roda() -> void:
	await _frames(8)
	HousePlacer = load("res://scripts/core/house_placer.gd")
	var env := g("environment")
	var hp := g("house_placer")
	var hub := g("village_hub")
	var eco := g("economy")
	var cam := g("caminhos")
	var iso := g("iso_view")
	eco.credits = 99999.0
	check(env != null and hp != null and hub != null and cam != null, "ambiente, posicionador, Centro e caminhos existem")

	print("== (A) a grade única")
	check(is_equal_approx(Grade.CELULA, 64.0 / 3.0) and is_equal_approx(cam.tamanho, Grade.CELULA), "a célula da grade é a dos caminhos (64/3 px)")
	check(Grade.quantas(88.67) == 4 and Grade.quantas(85.0) == 4 and Grade.quantas(92.0) == 5 and Grade.quantas(10.0) == 1,
		"a pegada arredonda pra cima (a casa de 88,7 px = 4 células; 2 px de contorno não contam)")
	var fp := Rect2(-43.3, -33.3, 88.7, 76.0)
	var p := Grade.encaixa(Vector2(17.3, -201.9), fp)
	var cs := Grade.celulas(Rect2(p + fp.position, fp.size))
	check(cs.size == Vector2i(4, 4), "a casa encaixada ocupa 4x4 células inteiras (%s)" % str(cs.size))
	var bloco := Grade.rect_de(cs)
	check(absf((p + fp.position).x - bloco.position.x - (bloco.size.x - fp.size.x) * 0.5) < 0.01, "e fica centrada no bloco de células")

	print("== (B) prédios encostados")
	hp.begin(func(_q): return true, TAVERNA_TEX, 2, "a taverna (teste)")
	var tcs := Rect2i()
	var dx := 0.0
	var s := _acha(hp, hub.global_position + Vector2(40, 260), func(q):
		var c0: Rect2i = hp.fantasma_celulas
		hp.move_to(q + Vector2(c0.size.x * Grade.CELULA, 0))
		var ok: bool = hp._reason == ""
		hp.move_to(q)
		return ok)
	check(s != Vector2.INF, "achou lugar pra uma taverna com espaço pra outra do lado (%s)" % str(s))
	if s == Vector2.INF:
		print("FALHAS: %d" % (fails + 1))
		quit()
		return
	hp.move_to(s)
	tcs = hp.fantasma_celulas
	dx = tcs.size.x * Grade.CELULA
	check(is_equal_approx(fmod(Grade.rect_de(tcs).position.x, Grade.CELULA), 0.0) or is_equal_approx(absf(fmod(Grade.rect_de(tcs).position.x, Grade.CELULA)), Grade.CELULA),
		"o fantasma encaixou na grade (bloco %s)" % str(tcs))
	var obra := Canteiro.order(self, "taverna", s, 30.0)
	await _frames(2)
	hp._collect_blockers()
	check(hp.ocupadas.has(tcs.position) and hp.portas.has(Vector2i(tcs.position.x, tcs.end.y)), "a obra ocupa as células dela e reserva a fileira da PORTA na frente")
	hp.move_to(s + Vector2(dx, 0))
	var vizinho: Rect2i = hp.fantasma_celulas
	check(hp._reason == "" and vizinho.position.x == tcs.end.x, "a taverna ENCOSTADA (célula vizinha, folga zero) é aceita: '%s'" % hp._reason)
	hp._end(false)
	hp.begin(func(_q): return true, HousePlacer.CASA_TEXTURE, 3, "a casa (teste)")
	var casa_l := _acha(hp, s + Vector2(-dx, 0), func(q): return hp.fantasma_celulas.end.x == tcs.position.x)
	check(casa_l != Vector2.INF, "uma CASA encostada do outro lado da taverna também cabe")

	print("== (B2) o posto de trabalho de uma estação com vizinho encostado")
	var com := g("comedouros") as Node2D
	var IsoArtS: GDScript = load("res://scripts/iso/iso_art.gd")
	var rc: Rect2 = IsoArtS.base_rect(com)
	var tfp: Rect2 = IsoArtS.footprint_of(self, "taverna")
	var lado := Canteiro.order(self, "taverna", Vector2(rc.position.x - tfp.end.x, rc.get_center().y - tfp.get_center().y), 30.0)
	await _frames(2)
	env.rebuild_navigation(true)
	var rl: Rect2 = IsoArtS.base_rect(lado)
	var dentro := 0
	for i in com.slot_count:
		if rl.grow(env.nav_agent_radius).has_point(com.get_slot_position(i)):
			dentro += 1
	check(absf(rl.end.x - rc.position.x) < 1.0 and dentro == 0, "com uma obra colada do lado, nenhum posto da Cozinha fica dentro dela (%d; foram pra frente)" % dentro)
	lado.queue_free()
	await _frames(1)
	env.rebuild_navigation(true)

	print("== (C) a porta")
	hp.move_to(s + Vector2(0, tcs.size.y * Grade.CELULA))
	check(hp._reason.contains("porta"), "uma casa em cima da porta da taverna é recusada: '%s'" % hp._reason)
	check(not hp.celulas_ruins.is_empty(), "as células em conflito ficam marcadas (vermelhas na grade)")
	# um lugar livre X com espaço logo atrás; X vira prédio (simulado) e a casa atrás dele teria a porta em cima de X
	var h: float = hp.fantasma_celulas.size.y * Grade.CELULA
	var x := _acha(hp, hub.global_position + Vector2(-120, -260), func(q):
		hp.move_to(q - Vector2(0, h))
		var ok: bool = hp._reason == ""
		hp.move_to(q)
		return ok)
	check(x != Vector2.INF, "achou um lugar com espaço atrás (%s)" % str(x))
	if x != Vector2.INF:
		hp.ocupa_simulado(x)
		hp.move_to(x - Vector2(0, h))
		check(hp._reason.contains("entrada ficaria bloqueada"), "a casa logo ATRÁS de outro prédio (a porta dela cairia nele) é recusada: '%s'" % hp._reason)
		hp._collect_blockers()
	check(not hp._fonte.is_empty() and not hp._portas_ok0.is_empty(), "o acesso: a porta do Centro e as portas que chegam nela entram na conta")
	var tampa := {}
	for c in hp._fonte:
		tampa[c] = true
	check(hp._alcance(tampa).is_empty(), "com a porta do Centro tapada nada mais chega (a busca é pela grade)")

	print("== (D) ruas na grade")
	hp._end(false)
	var cp := g("caminho_placer")
	cp.begin("terra")
	var porta_c := Vector2i(tcs.position.x, tcs.end.y)
	var n_porta: int = cp.pinta_celulas([porta_c, porta_c + Vector2i(1, 0)])
	check(n_porta == 2 and cam.celulas.has(porta_c), "a rua é pintada na faixa da porta, colada na taverna")
	var a := Grade.centro(porta_c + Vector2i(0, 2))
	var reta: Array = cp.celulas_reta(a, a + Vector2(140, 30))
	check(reta.size() == 1 + int((Grade.celula(a + Vector2(140, 30)).x - Grade.celula(a).x)) and reta.all(func(c): return c.y == Grade.celula(a).y),
		"Shift: a reta segue o eixo em que o mouse andou mais (%d células na mesma fileira)" % reta.size())
	var ret: Array = cp.celulas_retangulo(a, a + Vector2(3 * Grade.CELULA, 2 * Grade.CELULA))
	check(ret.size() == 12, "Ctrl: o retângulo cheio (4x3 = %d células)" % ret.size())
	var n_ret: int = cp.pinta_celulas(ret)
	check(n_ret > 0, "e pinta de uma vez (%d)" % n_ret)
	check(cp.celulas_retangulo(a, a + Vector2(80, 80) * Grade.CELULA).is_empty(), "retângulo grande demais não pinta (até max_retangulo)")
	cp.cancel()
	hp.begin(func(_q): return true, HousePlacer.CASA_TEXTURE, 3, "a casa (teste)")
	var sobre_rua := _acha(hp, Grade.centro(ret[0]), func(q):
		for c in Grade.lista(hp.fantasma_celulas):
			if cam.celulas.has(c):
				return true
		return false)
	check(sobre_rua != Vector2.INF, "rua não conta como obstáculo: dá pra construir em cima (o trecho sai quando o prédio entra)")
	hp._end(false)

	print("== (E) o terreno livre da vila")
	var area: Rect2 = env.area_vila()
	check(area.has_area() and area.has_point(hub.global_position), "a área da vila fica em volta do Centro (%s)" % str(area))
	check(env.area_vila(5).encloses(env.area_vila(1)) and env.area_vila(5).get_area() > env.area_vila(1).get_area(), "e cresce com o estágio")
	var sobrou := 0
	var fora := 0
	for c in env.get_children():
		if c is Node2D and (c as Node2D).visible and env.decor_removivel(c):
			if area.has_point((c as Node2D).global_position) and not env._perto_de_entrada((c as Node2D).global_position):
				sobrou += 1
			else:
				fora += 1
	check(sobrou == 0, "nenhuma decoração removível ficou dentro da área da vila (%d)" % sobrou)
	check(fora > 0, "fora dela a decoração removível continua (%d peças: mato da floresta, pedras)" % fora)
	var poco_ok := false
	var mina_ok := 0
	var leste_ok := 0
	for c in env.get_children():
		if c.has_meta("iso_prop") and (c as Node2D).visible:
			if String(c.get_meta("iso_prop")) == "poco":
				poco_ok = true
			if c.is_in_group("nivel_deco"):
				mina_ok += 1
			if env.has_leste() and (c as Node2D).global_position.x >= env.leste_x():
				leste_ok += 1
	check(poco_ok, "o poço (peça da vila) fica")
	check(mina_ok > 0, "a decoração dos andares/boca da mina fica (%d)" % mina_ok)
	check(not env.has_leste() or env.area_vila(5).end.x <= env.leste_x(), "a área da vila nunca passa da divisa do leste (a vila antiga fica como está)")
	var tochas := get_nodes_in_group("tochas").filter(func(t): return t.visible and area.has_point(t.global_position))
	check(not tochas.is_empty(), "as tochas da vila ficam (dão luz: só saem se o jogador limpar) — %d" % tochas.size())
	var removeu_sozinha: int = env.limpa_area_vila()
	check(removeu_sozinha == 0, "conferir de novo a mesma área não refaz nada")

	print("== (F) limpar uma peça e o save")
	var tocha: Node2D = null
	for t in tochas:
		if hub.global_position.distance_to(t.global_position) > 140.0:
			tocha = t
			break
	if tocha == null and not tochas.is_empty():
		tocha = tochas[0]
	if tocha:
		hp.begin(func(_q): return true, HousePlacer.CASA_TEXTURE, 3, "a casa (teste)")
		var em_cima := Vector2.INF
		for dy in range(-60, 61, 10):
			for dxx in range(-60, 61, 10):
				hp.move_to(tocha.global_position + Vector2(dxx, dy))
				if hp._reason.contains("LIMPAR"):
					em_cima = hp._pos
					break
			if em_cima != Vector2.INF:
				break
		check(em_cima != Vector2.INF, "o fantasma em cima da tocha oferece LIMPAR: '%s'" % hp._reason)
		if em_cima != Vector2.INF:
			var cr0: float = eco.credits
			var pos_tocha := tocha.global_position.round()
			hp.try_confirm()
			check(not tocha.visible, "o clique limpou a peça (sumiu)")
			check(is_equal_approx(eco.credits, cr0 - float(env.custo_limpar)), "custou %d cr (sem reembolso)" % env.custo_limpar)
			check(env.decor_limpa.has(pos_tocha), "a posição fica pro save")
			check(not hp._reason.contains("LIMPAR") or hp._limpar_pendentes.all(func(n): return n != tocha), "o fantasma não pede de novo pra limpar a mesma peça")
			var sm = root.get_node("SaveManager")
			var d: Dictionary = sm._collect()
			check(d.has("decor_limpa") and (d.decor_limpa as Array).size() >= 1, "o save tem 'decor_limpa'")
			tocha.visible = true  # (como se a decoração fosse montada de novo pela semente)
			env.load_decor_limpa(d.decor_limpa)
			check(not tocha.visible, "carregando, a peça limpa à mão some de novo")
			env.load_decor_limpa(SaveUtilVazio())
			check(env.decor_limpa.is_empty(), "save antigo (sem a chave): nenhuma limpa à mão, sem erro")
			var texto := FileAccess.get_file_as_string("res://scripts/core/save_manager.gd")
			check(texto.find("\"decor_limpa\"") >= 0 and texto.find("Bloco 132") >= 0, "o save_manager documenta a chave")
		hp._end(false)
	else:
		check(false, "não achou tocha na vila pra testar o Limpar")

	print("== (G) a visão de construção")
	HousePlacer.grade_ligada = true
	hp.begin(func(_q): return true, HousePlacer.CASA_TEXTURE, 3, "a casa (teste)")
	hp.move_to(s + Vector2(0, 200))
	await _frames(3)
	var gr: Node2D = iso.grade() if iso and iso.has_method("grade") else null
	check(gr != null and gr.visible, "no modo de construção a grade aparece")
	if gr:
		check(gr.celulas_visiveis().get_area() > 0, "com as células da área visível (%s)" % str(gr.celulas_visiveis()))
		var r0: int = gr.refeitos
		await _frames(10)
		check(gr.refeitos == r0, "parado, a grade não é refeita a cada quadro (%d -> %d)" % [r0, gr.refeitos])
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.physical_keycode = Teclas.tecla("painel_defesa")
		ev.keycode = ev.physical_keycode
		hp._unhandled_input(ev)
		await _frames(2)
		check(not HousePlacer.grade_ligada and not gr.visible, "a tecla da Defesa (G) desliga a grade enquanto posiciona")
		hp._unhandled_input(ev)
		await _frames(2)
		check(HousePlacer.grade_ligada and gr.visible, "e liga de novo")
	hp._end(false)
	await _frames(2)
	check(gr == null or not gr.visible, "fora do modo de construção a grade some")
	check(not Teclas.permitida(KEY_F8), "o F8 não pode virar atalho (no editor ele fecha o jogo)")

	print("== (H) a navegação")
	env.rebuild_navigation(true)
	for i in 4:
		await physics_frame
	var map: RID = root.get_world_2d().navigation_map
	var de := Grade.centro(Vector2i(tcs.position.x + 1, tcs.end.y))
	var caminho := NavigationServer2D.map_get_path(map, de, hub.global_position + Vector2(0, 60), true)
	check(caminho.size() >= 2 and caminho[-1].distance_to(hub.global_position + Vector2(0, 60)) < 40.0,
		"da porta da obra nova até a frente do Centro há caminho (%d pontos)" % caminho.size())
	if is_instance_valid(obra):
		obra.queue_free()

	print("FALHAS: %d" % fails)
	quit()


func SaveUtilVazio() -> Array:
	return []
