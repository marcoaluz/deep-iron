extends SceneTree
## Prompt 29, parte 2: a ARTE NOVA dos prédios no jogo (iso_art.gd + predios.json).
## Cada prédio desenha o desenho novo do estado certo (pronto, variação, nível, obra por
## estágios, estágio do Centro, peças da escavadeira, nível do portão); a caixa na ordem é a do
## desenho; a pegada de navegação é a do pronto / 1,5 e os slots/pontos de trabalho ficam fora
## dela (e alcançáveis); o posicionador usa a pegada nova e o fantasma novo; save antigo com
## prédio em cima de outro migra; a paliçada aparece; nada na ordem errada.
## RODAR SÓ COM APPDATA ISOLADO.
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var _cants: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func iso() -> Node:
	return main.get_node("IsoView")


func env() -> Node:
	return main.get_node("World/Environment")


## As texturas que o espelho está desenhando com a arte nova ([] = nenhuma).
func art_files(n: Node) -> Array:
	var bb = iso().billboard_of(n)
	if bb == null or bb._art == null:
		return []
	var out := []
	for c in bb._art.get_children():
		if c is Sprite2D and not c.is_queued_for_deletion() and c.name != "Janelas":  # (Prompt 19: a máscara de janelas acesas é à parte)
			out.append(c.texture.resource_path.trim_prefix(IsoArt.DIR))
	return out


## Força o espelho a sincronizar já (sem esperar a vez dele).
func sync(n: Node) -> void:
	var bb = iso().billboard_of(n)
	if bb:
		bb.never_synced = true
		bb.sync_static(Rect2(-1e6, -1e6, 2e6, 2e6))


func path(a: Vector2, b: Vector2) -> PackedVector2Array:
	return NavigationServer2D.map_get_path(main.get_world_2d().navigation_map, a, b, true)


func group(g: String) -> Node:
	return main.get_tree().get_first_node_in_group(g)


func _process(delta: float) -> bool:
	t += delta
	if t > 150.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	if step == 0 and t > 3.0:
		step = 1
		_step_layout()
		t_mark = t
	elif step == 1 and t - t_mark > 0.6:
		step = 2
		_step_obras()
		t_mark = t
	elif step == 2 and t - t_mark > 0.6:
		step = 3
		_step_maquinas()
		t_mark = t
	elif step == 3 and t - t_mark > 0.6:
		step = 4
		_step_placer_migracao()
		t_mark = t
	elif step == 4 and t - t_mark > 1.0:
		_step_ordem()
		print("FALHAS: %d" % fails)
		return true
	return false


# ------------------------------------------------------------ prédios do layout
func _step_layout() -> void:
	print("== prédios do layout com a arte nova")
	check(not IsoArt.data().is_empty(), "predios.json carregado")
	var casas := main.get_tree().get_nodes_in_group("casas")
	var variacoes := {}
	for c in casas:
		sync(c)
		var f := art_files(c)
		check(f.size() == 1 and f[0].begins_with("casa/pronto_"), "%s desenha a casa nova (%s)" % [c.name, f])
		if f.size() == 1:
			variacoes[f[0]] = true
	check(variacoes.size() >= 2, "as casas não são todas iguais (%d variações)" % variacoes.size())
	for g in ["armazens", "oficina", "enfermarias", "comedouros"]:
		var n := group(g)
		sync(n)
		var f := art_files(n)
		check(f.size() == 1 and f[0].ends_with(".png"), "%s desenha a arte nova (%s)" % [n.name, f])
	# o Centro (estágio 1) e a pegada
	var hub := group("village_hub")
	sync(hub)
	check(art_files(hub) == ["centro_1/pronto.png"], "Centro no estágio 1: centro_1/pronto (%s)" % [art_files(hub)])
	# caixa na ordem = a declarada do desenho
	var casa: Node2D = casas[0]
	var bb = iso().billboard_of(casa)
	var st: Dictionary = IsoArt.entry("casa").estados[art_files(casa)[0].get_file().get_basename()]
	check(absf((bb.box.zt - bb.box.zb) - st.h) < 0.5, "caixa da casa com a altura do desenho (%.0f = %.0f)" % [bb.box.zt - bb.box.zb, st.h])
	var p: Array = st.peg
	check(absf(bb.box.rect.size.x - (p[2] - p[0])) < 0.5 and absf(bb.box.rect.size.y - (p[3] - p[1])) < 0.5,
		"caixa da casa com a pegada do desenho (%s)" % bb.box.rect.size)
	# a velha arte some do espelho; o rótulo continua
	var old_visible := false
	for pr in bb._pairs:
		if pr[1] is Sprite2D and pr[1].visible:
			old_visible = true
	check(not old_visible, "o desenho antigo some do espelho")
	# pegada de navegação = base / 1,5; slots fora dela e alcançáveis
	var base: Array = IsoArt.entry("casa").base
	var r := IsoArt.base_rect(casa)
	check(r.size.is_equal_approx(Vector2(base[2] - base[0], base[3] - base[1]) / 1.5), "pegada da casa = a do desenho / 1,5 (%s)" % r.size)
	var o: PackedVector2Array = casa.get_obstacle_outline()
	check(o.size() == 4 and Rect2(o[0], o[2] - o[0]).is_equal_approx(r), "a navegação contorna a pegada nova")
	var bad := 0
	var unreachable := 0
	for c in casas:
		var rc := IsoArt.base_rect(c)
		for i in c.slot_count:
			var sp: Vector2 = c.get_slot_position(i)
			if rc.grow(2.0).has_point(sp):
				bad += 1
			var pa := path(Vector2(-300, -200), sp)
			if pa.is_empty() or pa[pa.size() - 1].distance_to(sp) > 10.0:
				unreachable += 1
	check(bad == 0, "nenhuma cama (slot) dentro da parede da casa nova (%d dentro)" % bad)
	check(unreachable == 0, "todas as camas são alcançáveis andando (%d sem caminho)" % unreachable)
	var arm := group("armazens")
	var ra := IsoArt.base_rect(arm)
	var inside := 0
	for i in arm.slot_count:
		if ra.has_point(arm.get_slot_position(i)):
			inside += 1
	check(inside == 0, "slots do armazém fora da pegada nova")
	# a área de interação (quem chega no slot é percebido pela estação) cobre todos os slots,
	# também nas estações de raio fixo (laboratório, arsenal, campo, coletor: só trabalha quem está dentro)
	var extra := []
	for e in [["laboratorio", Vector2(420, -260)], ["arsenal", Vector2(-200, -90)], ["campo_treino", Vector2(-560, 90)],
			["coletor_madeira", Vector2(-600, -760)], ["taverna", Vector2(130, -370)]]:
		var n: Node2D = load("res://scenes/props/%s.tscn" % e[0]).instantiate()
		n.position = e[1]
		main.get_node("World").add_child(n)
		extra.append(n)
	var out_area := 0
	for stn in main.get_tree().get_nodes_in_group("casas") + [arm, group("comedouros"), group("enfermarias")] + extra:
		var sh = stn.get_node_or_null("Shape")
		if sh == null or not (sh.shape is CircleShape2D):
			continue
		for i in stn.slot_count:
			if stn.get_slot_position(i).distance_to(sh.global_position) > sh.shape.radius - 2.0:
				out_area += 1
				print("    fora: %s slot %d a %.0f (raio %.0f, auto_fit %s)" % [stn.name, i, stn.get_slot_position(i).distance_to(sh.global_position), sh.shape.radius, stn.auto_fit_area])
	check(out_area == 0, "todos os slots dentro da área de interação da estação (%d fora)" % out_area)
	check(not IsoArt.base_rect(hub).has_point(hub.obra_position(null)), "o engenheiro trabalha na frente do Centro, fora da pegada")
	# os prédios da cena não se sobrepõem com as pegadas novas (o layout aprovado já previa)
	var rects := []
	var over := 0
	for g in env().STATION_GROUPS + env().NAV_EXTRA_GROUPS:
		for n in main.get_tree().get_nodes_in_group(g):
			var rr := IsoArt.base_rect(n)
			if rr.has_area():
				for q in rects:
					if rr.grow(-2.0).intersects(q):
						over += 1
				rects.append(rr)
	check(over == 0, "prédios do layout sem sobreposição com as pegadas novas (%d prédios, %d pares)" % [rects.size(), over])
	# paliçada
	var pal := 0
	for c in iso()._terrain_node.get_children():
		if String(c.name).begins_with("Palicada"):
			pal += 1
	check(pal > 50, "paliçada desenhada ao longo da linha (%d trechos)" % pal)


# ------------------------------------------------------------ obras por estágios
func _step_obras() -> void:
	print("== obra por estágios com os desenhos obra_1/2/3")
	var k := 0
	for frac in [0.1, 0.5, 0.9]:
		var c: Node2D = Canteiro.order(self, "taverna", Vector2(-20 + 160 * k, -130), 30.0)
		c.left = 30.0 * (1.0 - frac)
		_cants.append(c)
		k += 1
	await process_frame
	await process_frame
	for i in _cants.size():
		var c: Node2D = _cants[i]
		sync(c)
		check(art_files(c) == ["taverna/obra_%d.png" % (i + 1)], "canteiro da taverna a %d%%: obra_%d (%s)" % [[10, 50, 90][i], i + 1, art_files(c)])
	check(not IsoArt.base_rect(_cants[0]).has_point(_cants[0].obra_position(null)), "engenheiro na frente do canteiro, fora da pegada")
	# casa encomendada: obra; pronta: variação
	var casa: Node2D = load("res://scenes/props/casa.tscn").instantiate()
	casa.position = Vector2(-380, -380)
	main.get_node("World").add_child(casa)
	casa.start_construction(30.0)
	casa.build_left = 5.0
	await process_frame
	await process_frame
	sync(casa)
	check(art_files(casa) == ["casa/obra_3.png"], "casa nova a 83%%: obra_3 (%s)" % [art_files(casa)])
	casa.queue_free()
	# coletor (sem desenhos de obra): o pronto subindo pelo corte
	var col: Node2D = Canteiro.order(self, "coletor", Vector2(-600, -760), 30.0)
	col.left = 20.0
	await process_frame
	await process_frame
	sync(col)
	var bb = iso().billboard_of(col)
	var shown := 0
	if bb and bb._art and bb._art.get_child_count() > 0:
		shown = preload("res://scripts/core/obra_estagio.gd").shown(bb._art.get_child(0))
	check(art_files(col) == ["coletor_madeira/pronto.png"] and shown == 2, "coletor a 33%%: o pronto no estágio 2 do corte (%s, %d)" % [art_files(col), shown])
	col.queue_free()


# ------------------------------------------------------------ Centro, escavadeira, portão
func _step_maquinas() -> void:
	print("== Centro por estágio, escavadeira por peças, portão por nível")
	var hub := group("village_hub")
	for lv in [2, 3, 4, 5]:
		hub.level = lv
		sync(hub)
		check(art_files(hub) == ["centro_%d/pronto.png" % lv], "Centro estágio %d" % lv)
	hub.level = 3
	hub.pending_upgrade = "expandir"
	sync(hub)
	check(art_files(hub) == ["centro_4/obra.png"], "Centro expandindo: andaime do estágio 4 (%s)" % [art_files(hub)])
	hub.pending_upgrade = ""
	hub.level = 1
	sync(hub)
	var esc := group("escavadeira")
	sync(esc)
	check(art_files(esc).is_empty(), "escavadeira sem peças: plataforma vazia (nada desenhado)")
	esc.installed["estrutura"] = true
	esc.installed["motor"] = true
	esc.fabricating = "cabine"
	esc.fab_left = float(esc.part_cost("cabine").z) * 0.5
	sync(esc)
	check(art_files(esc) == ["escavadeira/estrutura.png", "escavadeira/peca_motor.png", "escavadeira/peca_cabine.png"],
		"escavadeira: estrutura + motor + cabine em montagem (%s)" % [art_files(esc)])
	var bb = iso().billboard_of(esc)
	var cab_stage: int = preload("res://scripts/core/obra_estagio.gd").shown(bb._art.get_child(2))
	check(cab_stage == 2, "a cabine em montagem a 50%% sobe pelo corte (estágio %d)" % cab_stage)
	for id in esc.installed:
		esc.installed[id] = false
	esc.fabricating = ""
	for g in main.get_tree().get_nodes_in_group("barricadas"):
		sync(g)
		var want := "portao/quebrado.png" if not g.is_standing() or g.level == 0 else "portao/nivel_%d.png" % g.level
		check(art_files(g) == [want], "%s: %s (%s)" % [g.name, want, art_files(g)])
	var gate = main.get_tree().get_nodes_in_group("barricadas")[0]
	gate.level = 2
	gate.hp = 200.0
	sync(gate)
	check(art_files(gate) == ["portao/nivel_2.png"], "portão no nível 2: portao/nivel_2 (%s)" % [art_files(gate)])


# ------------------------------------------------------------ posicionador e migração
func _step_placer_migracao() -> void:
	print("== posicionador e migração de save")
	var placer := group("house_placer")
	var hub := group("village_hub")
	placer.begin(func(_p): return false, preload("res://assets/game/casa.png"), 3, "teste", hub.house_placer_opts())
	var want := IsoArt.placer_footprint(main.get_tree(), "casa")
	check(placer.art_name == "casa" and placer._footprint.is_equal_approx(want), "posicionador da casa com a pegada nova (%s)" % placer._footprint)
	# colado numa casa da cena: recusado por causa da casa (sem o raio do Centro no caminho)
	placer.cancel()
	placer.begin(func(_p): return false, preload("res://assets/game/casa.png"), 3, "teste", {})
	var casa: Node2D = main.get_tree().get_nodes_in_group("casas")[0]
	placer.move_to(casa.global_position + Vector2(70, 0))
	check("casa" in placer._reason, "a 70 px de uma casa (cabia na pegada antiga): não pode (%s)" % placer._reason)
	await process_frame
	await process_frame
	var gt = iso()._ghost_bb.texture
	check(iso()._ghost_bb.visible and gt == IsoArt.preview("casa").tex, "o fantasma é a casa nova (%s)" % [gt.resource_path if gt else "nada"])
	placer.cancel()
	# save antigo: duas casas que o jogador pôs perto (a regra antiga deixava) ficam sobrepostas
	var a: Node2D = load("res://scenes/props/casa.tscn").instantiate()
	var b: Node2D = load("res://scenes/props/casa.tscn").instantiate()
	a.position = Vector2(260, -120)
	b.position = Vector2(320, -110)
	a.placed_by_player = true
	b.placed_by_player = true
	main.get_node("World").add_child(a)
	main.get_node("World").add_child(b)
	await process_frame
	check(IsoArt.base_rect(a).intersects(IsoArt.base_rect(b)), "as duas casas do save antigo se sobrepõem com a pegada nova")
	env().migrated.clear()
	env().migrate_positions()
	check(not IsoArt.base_rect(a).grow(-2.0).intersects(IsoArt.base_rect(b)), "migração: não se sobrepõem mais")
	check(env().migrated.size() >= 1, "migração anotada (%s)" % [env().migrated])
	check(env().footprint_reason(IsoArt.base_rect(b)) == "", "a casa mudada ficou em chão plano")
	a.queue_free()
	b.queue_free()


# ------------------------------------------------------------ ordem
func _step_ordem() -> void:
	print("== ordem por caixas com a arte nova")
	var Iso := preload("res://scripts/iso/iso_core.gd")
	var v = iso()
	v._process(0.0)  # caixas e z do mesmo instante
	var all: Array = []
	for bb in v._ents.values():
		if bb.visible_src():
			all.append([bb.box, bb.z_index])
	for tr in v._terrain:
		all.append([tr[0], tr[1].z_index])
	var pairs := 0
	var bad := 0
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a3 = all[i]
			var b3 = all[j]
			if not Iso.screen_rect(a3[0]).intersects(Iso.screen_rect(b3[0])):
				continue
			var r = Iso.behind(a3[0], b3[0])
			if r == null:
				continue
			pairs += 1
			if a3[1] == b3[1] and a3[0].kind == "ipezinho" and b3[0].kind == "ipezinho":
				continue
			if (r == true and a3[1] >= b3[1]) or (r == false and b3[1] >= a3[1]):
				bad += 1
	check(pairs > 0 and bad == 0, "%d pares que se sobrepõem, %d na ordem errada" % [pairs, bad])
