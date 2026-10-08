extends SceneTree
## Bloco 98: o PORTÃO DA PALIÇADA e as TOCHAS. (1) O desenho do portão encaixa no vão e na paliçada (a cerca começa onde o
## portão acaba) e a paliçada inteira bloqueia a navegação: a única passagem é o portão, e os caminhos de pontos
## aleatórios dos dois lados sempre cruzam em gate_y ± gate_half_width. (2) O portão ABRE de dia e FECHA ao anoitecer
## (18:30; abre 05:00), com a animação (nivel_N / meio_N / aberto_N), tirando as faixas da malha sem refazê-la; derrubado
## ou sem muro fica aberto (a brecha continua abrindo o caminho). (3) Quem está fora na hora de fechar espera ENCOSTADO no
## portão; um guarda abre (sem guarda, demora mais); criatura por perto = não abre. (4) A tocha tem UM desenho só
## (a chama), de dia e de noite, nas sorteadas do mapa, nas do jogador e no lampião; muda só a luz. RODAR SÓ COM APPDATA
## ISOLADO.
const Iso := preload("res://scripts/iso/iso_core.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
var main: Node
var fails := 0
var _t0 := 0


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
	_t0 = Time.get_ticks_msec()
	_roda()


## Trava de segurança: se o teste emperrar (um erro no meio da corrotina), termina com falha em vez de ficar pendurado.
func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - _t0 > 420000:
		print("TIMEOUT
FALHAS: %d" % (fails + 1))
		Engine.time_scale = 1.0
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func iso() -> Node:
	return main.get_node("IsoView")


## Espera `s` segundos de jogo (já com o time_scale).
func _espera(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += root.get_process_delta_time()  # (já vem com o time_scale)


func _quadros(n: int) -> void:
	for i in n:
		await physics_frame


func _hora(h: float) -> void:
	var dn = g("day_night")
	dn._pula_para(dn.tempo_da_hora(h))


## Caminho na malha de navegação: {chega, y} (y = onde cruza a linha da paliçada; NAN = não cruza).
func _caminho(de: Vector2, ate: Vector2) -> Dictionary:
	var env = g("environment")
	var map: RID = env.navigation_region.get_navigation_map()
	var p := NavigationServer2D.map_get_path(map, de, ate, true)
	var px: float = env.palisade_x
	var cy := NAN
	for i in range(p.size() - 1):
		var a: Vector2 = p[i]
		var b: Vector2 = p[i + 1]
		if (a.x - px) * (b.x - px) <= 0.0 and a.x != b.x:
			cy = a.y + (b.y - a.y) * (px - a.x) / (b.x - a.x)
			break
	return {"chega": p.size() >= 2 and p[p.size() - 1].distance_to(ate) < 12.0, "y": cy}


func _intervalo_y(box) -> Vector2:
	var v = iso()
	var a: Vector2 = v.logic_of(box.rect.position, 0.0)
	var b: Vector2 = v.logic_of(box.rect.end, 0.0)
	return Vector2(minf(a.y, b.y), maxf(a.y, b.y))


func _roda() -> void:
	for i in 12:
		await process_frame
	await _espera(2.0)
	var env = g("environment")
	var gate = g("barricadas")
	var dn = g("day_night")
	var px: float = env.palisade_x
	var gy: float = env.gate_y
	var hw: float = env.gate_half_width
	var map: RID = env.navigation_region.get_navigation_map()
	gate.level = 2
	gate.hp = gate.max_hp()
	gate._update_visual()
	_hora(12.0)
	await _espera(2.5)

	print("== A) o portão encaixa na paliçada")
	check(env.vertical_palisade() and env.portao_por_faixas(), "paliçada de norte a sul e o portão passa por faixas")
	var gbox = iso().billboard_of(gate).box
	var gi := _intervalo_y(gbox)
	check(gate.global_position.distance_to(Vector2(px, gy)) < 2.0, "o portão está no vão (%s)" % gate.global_position)
	check(absf((gi.x + gi.y) * 0.5 - gy) <= 4.0, "a caixa do desenho está centrada no vão (centro %.1f, vão em %.1f)" % [(gi.x + gi.y) * 0.5, gy])
	var norte := -INF  # a ponta de baixo (maior y) da peça de cerca do lado norte; a de cima da do lado sul
	var sul := INF
	for e in iso()._terrain:
		if not String(e[0].name).begins_with("palicada"):
			continue
		var iv := _intervalo_y(e[0])
		if iv.y <= gy:
			norte = maxf(norte, iv.y)
		else:
			sul = minf(sul, iv.x)
	print("  cerca: norte acaba em y=%.1f, sul começa em y=%.1f; borda do portão em %.1f e %.1f" % [norte, sul, gy - hw, gy + hw])
	check(absf(norte - (gy - hw)) <= 4.0 and absf(sul - (gy + hw)) <= 4.0, "a cerca começa onde o portão acaba (sem fresta nem sobra: ±4 px)")
	for nivel in [1, 2, 3]:  # os 3 níveis (e as folhas abertas) correm no mesmo sentido: ponto alto da esquerda, baixo da direita
		for quadro in ["nivel_%d", "meio_%d", "aberto_%d"]:
			var im: Image = IsoArt.state("portao", quadro % nivel).tex.get_image()
			var topo_e := 9999
			var topo_d := 9999
			for yy in im.get_height():
				for xx in range(0, 24):
					if im.get_pixel(xx, yy).a > 0.5:
						topo_e = mini(topo_e, yy)
				for xx in range(im.get_width() - 24, im.get_width()):
					if im.get_pixel(xx, yy).a > 0.5:
						topo_d = mini(topo_d, yy)
			check(topo_e < topo_d, "portão nível %d (%s): corre no mesmo sentido da paliçada (topo esq %d, dir %d)" % [nivel, quadro % nivel, topo_e, topo_d])
	var pecas := 0
	for e in iso()._terrain:
		if String(e[0].name).begins_with("palicada"):
			pecas += 1
	check(pecas > 50, "a paliçada continua ao longo de toda a linha (%d peças)" % pecas)

	print("== B) a paliçada inteira bloqueia: o único caminho é o portão")
	var rng := RandomNumberGenerator.new()
	rng.seed = 98
	var gr: Rect2 = env.iso_ground_rect()
	var ok := 0
	var fora := 0
	var tentou := 0
	while ok + fora < 120 and tentou < 3000:
		tentou += 1
		var a := Vector2(rng.randf_range(gr.position.x + 30, px - 40), rng.randf_range(gr.position.y + 30, gr.end.y - 30))
		var b := Vector2(rng.randf_range(px + 40, env.map_rect.end.x - 30), rng.randf_range(gr.position.y + 30, gr.end.y - 30))
		if NavigationServer2D.map_get_closest_point(map, a).distance_to(a) > 6.0 or NavigationServer2D.map_get_closest_point(map, b).distance_to(b) > 6.0:
			continue
		var r := _caminho(a, b)
		if not r.chega:
			continue
		if not is_nan(r.y) and absf(r.y - gy) <= hw:
			ok += 1
		else:
			fora += 1
			print("  cruzou FORA do portão em y=%.1f (de %s pra %s)" % [r.y, a.round(), b.round()])
	check(ok >= 100 and fora == 0, "%d caminhos aleatórios (floresta → vila) cruzam em gate_y ± gate_half_width; %d fora" % [ok, fora])
	var lados := 0
	for k in 40:  # e o contrário (vila → floresta)
		var b2 := Vector2(rng.randf_range(gr.position.x + 30, px - 40), rng.randf_range(gr.position.y + 30, gr.end.y - 30))
		var a2 := Vector2(rng.randf_range(px + 40, env.map_rect.end.x - 30), rng.randf_range(gr.position.y + 30, gr.end.y - 30))
		if NavigationServer2D.map_get_closest_point(map, a2).distance_to(a2) > 6.0 or NavigationServer2D.map_get_closest_point(map, b2).distance_to(b2) > 6.0:
			continue
		var r2 := _caminho(a2, b2)
		if r2.chega and not is_nan(r2.y) and absf(r2.y - gy) <= hw:
			lados += 1
	check(lados >= 15, "vila → floresta também pelo portão (%d caminhos)" % lados)
	var rente := 0
	for yy in [-700.0, -420.0, -200.0, 180.0, 330.0]:  # colado na cerca, dos dois lados, longe do portão: dá a volta pelo portão
		var r3 := _caminho(Vector2(px - 30.0, yy), Vector2(px + 30.0, yy))
		if r3.chega and absf(r3.y - gy) <= hw:
			rente += 1
	check(rente == 5, "colado na cerca, longe do portão, o caminho vai ao portão e passa por ele (%d de 5)" % rente)
	var r4 := _caminho(Vector2(px - 30.0, gy), Vector2(px + 30.0, gy))
	check(r4.chega and absf(r4.y - gy) <= 14.5, "pela frente do portão a travessia é pelas faixas (y=%.1f)" % r4.y)

	print("== C) abre de dia, fecha ao anoitecer, abre no amanhecer")
	check(gate.hora_fecha == 18.5 and gate.hora_abre == 5.0 and gate.hora_fecha >= dn.hora_fim_expediente + 0.5, "padrão: fecha 18:30 (depois da hora de voltar, 18:00), abre 05:00")
	check(gate.passagem_livre() and gate.abertura == 1.0, "12:00: aberto (abertura %.2f)" % gate.abertura)
	var livre := _caminho(Vector2(px - 120.0, gy + 10.0), Vector2(px + 120.0, gy + 10.0))
	check(livre.chega, "aberto: passa")
	_hora(18.7)
	await _espera(2.5)
	await _quadros(4)
	check(gate.fechado() and gate.abertura == 0.0 and not gate._faixas[0].enabled, "18:42: fechou (abertura %.2f, faixas desligadas)" % gate.abertura)
	var fech := _caminho(Vector2(px - 120.0, gy + 10.0), Vector2(px + 120.0, gy + 10.0))
	check(not fech.chega and is_nan(fech.y), "fechado: ninguém atravessa a paliçada (o caminho não chega nem cruza)")
	check(iso().billboard_of(gate).get("_art_key") != null, "o desenho do portão sai do estado aberto")
	var ab_nome: String = IsoArt._portao_estado(gate, 2, true).get("tex").resource_path.get_file()
	check(ab_nome == "nivel_2.png", "fechado desenha as folhas fechadas (%s)" % ab_nome)
	gate.abertura = 0.5
	check(IsoArt._portao_estado(gate, 2, true).get("tex").resource_path.get_file() == "meio_2.png", "a meio caminho: meio_2.png")
	gate.abertura = 1.0
	check(IsoArt._portao_estado(gate, 2, true).get("tex").resource_path.get_file() == "aberto_2.png", "aberto: aberto_2.png")
	gate.abertura = 0.0
	_hora(4.9)
	await _espera(0.5)
	check(gate.fechado(), "04:54: ainda fechado")
	_hora(5.1)
	await _espera(2.5)
	await _quadros(4)
	check(gate.passagem_livre() and gate._faixas[0].enabled, "05:06: abriu de novo (faixas ligadas)")
	var reabre := _caminho(Vector2(px - 120.0, gy + 10.0), Vector2(px + 120.0, gy + 10.0))
	check(reabre.chega and absf(reabre.y - gy) <= hw, "depois de abrir, passa de novo pelo vão")

	print("== D) brecha, derrubado e sem muro: sempre aberto (a barricada continua com vida)")
	_hora(21.0)
	await _espera(2.5)
	check(gate.fechado(), "21:00: fechado")
	gate.damage(gate.hp)
	await _espera(2.5)
	await _quadros(4)
	check(not gate.is_standing() and gate.passagem_livre(), "derrubado de noite: abre o caminho (as criaturas entram)")
	check(IsoArt._portao_estado(gate, 2, false).get("tex").resource_path.get_file() == "quebrado_aberto.png", "derrubado: a ruína com o vão aberto")
	gate._conserta()
	await _espera(2.5)
	check(gate.is_standing() and gate.fechado(), "consertado: volta a fechar de noite")
	var nivel_antes: int = gate.level
	gate.level = 0
	await _espera(2.5)
	check(gate.passagem_livre(), "sem muro (nível 0): sempre aberto")
	gate.level = nivel_antes
	gate.hp = gate.max_hp()
	await _espera(2.5)
	var hp0: float = gate.hp
	gate.damage(10.0)
	check(gate.hp == hp0 - 10.0 and gate.fechado(), "a vida e o dano da barricada seguem iguais (%.0f)" % gate.hp)

	print("== E) quem está fora na hora de fechar espera encostado no portão")
	var fora_gente = get_nodes_in_group("ipezinhos")[0]
	var guarda = get_nodes_in_group("ipezinhos")[1]
	for w in get_nodes_in_group("ipezinhos"):
		w.auto_mode = false
		if w.is_guard():
			w.set_job("ocioso")
	fora_gente.global_position = Vector2(px - 150.0, gy + 20.0)
	guarda.global_position = Vector2(px + 200.0, gy + 80.0)
	gate.sem_guarda_demora = 8.0
	gate.guarda_demora = 0.5
	gate.janela_segundos = 6.0
	Engine.time_scale = 4.0
	fora_gente.move_to(Vector2(px + 150.0, gy))
	await _espera(5.0)
	var da: float = fora_gente.global_position.distance_to(gate.global_position)
	print("  esperando: x=%.1f (paliçada em %.1f), a %.0f px do portão, _esperando_portao=%s" % [fora_gente.global_position.x, px, da, fora_gente._esperando_portao])
	check(fora_gente._esperando_portao and fora_gente.global_position.x < px - 10.0 and da < 70.0, "fechado, quem vinha da floresta espera junto do portão (não ao longo da cerca)")
	check(gate.fechado() or gate._janela > 0.0, "sem guarda, o portão ainda não abriu antes da demora (%.1f s)" % gate._espera_t)
	await _espera(10.0)  # sem guarda: depois de sem_guarda_demora alguém ouve a batida e abre
	check(fora_gente.global_position.x > px + 20.0, "sem guarda, depois da demora alguém abre e ele passa pra vila (x=%.1f)" % fora_gente.global_position.x)
	await _espera(10.0)
	check(gate.fechado(), "passou: o portão fecha de novo")
	# com guarda (abre rápido, a demora sem guarda fica enorme: só o guarda explica)
	gate.sem_guarda_demora = 600.0
	guarda.set_job("guarda")
	check(guarda.is_guard(), "um guarda na vila")
	fora_gente.global_position = Vector2(px - 150.0, gy - 30.0)
	fora_gente.move_to(Vector2(px + 150.0, gy))
	await _espera(7.0)
	check(fora_gente.global_position.x > px + 20.0, "com guarda, ele abre rápido pra quem espera (x=%.1f)" % fora_gente.global_position.x)
	await _espera(10.0)
	check(gate.fechado(), "fechou de novo depois da janela")
	# criatura por perto: não abre pra ninguém
	var bicho: Node2D = load("res://scenes/creatures/lumivoro.tscn").instantiate()
	main.get_node("World").add_child(bicho)
	bicho.global_position = gate.global_position + Vector2(-60, 0)
	bicho.set_process(false)  # parado ali (não ataca o portão nem a gente)
	fora_gente.global_position = Vector2(px - 150.0, gy)
	fora_gente.move_to(Vector2(px + 150.0, gy))
	await _espera(12.0)
	check(fora_gente.global_position.x < px and gate.fechado(), "com criatura junto do portão, ele não abre (nem pro guarda)")
	bicho.queue_free()
	await _espera(10.0)
	check(fora_gente.global_position.x > px + 20.0, "a criatura foi embora: abre pra quem esperava (x=%.1f)" % fora_gente.global_position.x)
	Engine.time_scale = 1.0

	print("== F) carregou de noite: já nasce fechado, sem animar")
	_hora(21.0)
	await _espera(2.5)
	gate.abertura = 1.0
	gate.load_save_data(gate.get_save_data())
	await process_frame
	await process_frame
	check(gate.fechado() and gate.abertura == 0.0, "o relógio carregado decide: fechado (abertura %.2f)" % gate.abertura)

	print("== G) tochas: UM desenho só, dia e noite (muda só a luz)")
	var tochas := get_nodes_in_group("tochas")
	check(not tochas.is_empty(), "tem tochas sorteadas no mapa (%d)" % tochas.size())
	var iguais := true
	var luz_noite := 0.0
	var luz_dia := 0.0
	var anim_nomes := []
	if not tochas.is_empty():
		var t0: Node = tochas[0]
		_hora(12.0)
		await _espera(1.5)
		var dia: Array = IsoArt.layers(t0)
		luz_dia = dn.torch_level()
		_hora(21.0)
		await _espera(2.5)
		var noite: Array = IsoArt.layers(t0)
		luz_noite = dn.torch_level()
		iguais = dia.size() == 1 and noite.size() == 1 and dia[0].has("anim") and noite[0].has("anim") \
			and dia[0].anim.map(func(t): return t.resource_path) == noite[0].anim.map(func(t): return t.resource_path)
		anim_nomes = dia[0].anim.map(func(t): return t.resource_path.get_file()) if not dia.is_empty() and dia[0].has("anim") else []
	check(iguais and not anim_nomes.is_empty(), "tocha do mapa: os mesmos quadros (a chama) de dia e de noite %s" % [anim_nomes])
	check(not anim_nomes.has("tocha_apagada.png") and luz_dia < 0.05 and luz_noite > 0.9, "sem a tocha apagada; a luz é que muda (dia %.2f, noite %.2f)" % [luz_dia, luz_noite])
	var deco = g("decoracoes_mgr")
	var eco = g("economy")
	eco.credits = 9999.0
	var arm = g("armazens")
	arm.wood_stored = 500.0
	arm.stock["ferro"] = 300.0
	arm._recount()
	var tocha_j: Node = deco.colocar("tocha", Vector2(-40, 30))
	var lamp_j: Node = deco.colocar("lampiao", Vector2(-10, 40))
	check(tocha_j != null and lamp_j != null, "decoração do jogador: tocha e lampião")
	if tocha_j and lamp_j:
		_hora(12.0)
		await _espera(1.5)
		var n_dia: String = tocha_j.iso_prop_nome()
		var l_dia: String = lamp_j.iso_prop_nome()
		var luz_da_tocha_dia: bool = tocha_j.acesa()
		_hora(21.0)
		await _espera(2.5)
		var n_noite: String = tocha_j.iso_prop_nome()
		var l_noite: String = lamp_j.iso_prop_nome()
		check(n_dia == "tocha_chao" and n_noite == "tocha_chao", "tocha do jogador: tocha_chao de dia e de noite (%s / %s)" % [n_dia, n_noite])
		check(l_dia == l_noite and l_dia == "decor_lampiao", "lampião: o mesmo desenho (%s / %s)" % [l_dia, l_noite])
		check(not luz_da_tocha_dia and tocha_j.acesa() and lamp_j.acesa(), "a luz da tocha e do lampião liga à noite e some de dia")
		tocha_j.take_hit(1.0, null)  # um Lumívoro comeu a luz
		check(not tocha_j.acesa() and tocha_j.iso_prop_nome() == "tocha_chao", "sem a luz (comida pelo Lumívoro) o desenho continua o mesmo")
		var cam_dia: Array = IsoArt.layers(tocha_j)
		check(cam_dia.size() == 1 and cam_dia[0].has("anim"), "a vista iso desenha a chama animada da tocha do jogador")

	print("\nFALHAS: %d" % fails)
	quit()
