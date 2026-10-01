extends SceneTree
## Prompt 28: a vista isométrica no jogo (F3). Liga, confere ordem/clique/câmera/save,
## constrói e demole, desliga — e a lógica (posições, grupos) não pode mudar com a vista.
## RODAR SÓ COM APPDATA ISOLADO.
const Iso := preload("res://scripts/iso/iso_core.gd")
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var snap := {}
var ground_before := Vector2.ZERO
var extra: Node2D
var n_static_before := 0


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


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = code
	return ev


## Posição e grupos de tudo que está no World (a "lógica" que a vista não pode mexer).
func snapshot() -> Dictionary:
	var out := {}
	var world: Node = main.get_node("World")
	for n in world.get_children() + world.get_node("Environment").get_children():
		if n is Node2D:
			out[n.get_instance_id()] = [n.global_position, n.get_groups().size(), n.visible]
	return out


func same_as_snapshot(s: Dictionary) -> int:
	var diff := 0
	for id in s:
		var n = instance_from_id(id)
		if n == null:
			continue
		var now = [n.global_position, n.get_groups().size(), n.visible]
		if now[0].distance_to(s[id][0]) > 0.01 or now[1] != s[id][1] or now[2] != s[id][2]:
			diff += 1
	return diff


## Pares (que se sobrepõem na tela) desenhados na ordem errada: z de quem está atrás >= z de
## quem está na frente. Empate de z entre quem anda (mais de K-1 no mesmo vão) não conta.
func order_errors(iso) -> Array:
	var bbs: Array = iso._ents.values().filter(func(b): return b.visible_src())
	var bad := 0
	var pairs := 0
	for i in bbs.size():
		for j in range(i + 1, bbs.size()):
			var a = bbs[i]
			var b = bbs[j]
			if not Iso.screen_rect(a.box).intersects(Iso.screen_rect(b.box)):
				continue
			var r = Iso.behind(a.box, b.box)
			if r == null:
				continue
			pairs += 1
			if a.z_index == b.z_index and a.dynamic and b.dynamic:
				continue
			if (r == true and a.z_index >= b.z_index) or (r == false and b.z_index >= a.z_index):
				bad += 1
	return [bad, pairs]


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 120.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var iso = main.get_node_or_null("IsoView")
	var cam: Camera2D = main.get_node("Camera2D")
	if step == 0 and t > 3.0:
		step = 1
		print("== liga a vista iso")
		if iso and iso.enabled:
			iso.set_enabled(false)  # Prompt 29: a iso já abre ligada com o mapa novo; volta pra de cima primeiro
		check(iso != null and not iso.enabled, "vista iso existe e começa desligada")
		snap = snapshot()
		ground_before = cam.ground_center()
		# (Prompt 29) o F3 saiu do jogo: o teste liga/desliga direto (a vista de cima ficou só pra conferir)
		main._unhandled_input(key(KEY_F3))
		check(not iso.enabled, "F3 não troca mais de vista (Prompt 29)")
		iso.set_enabled(true)
		check(iso.enabled, "liga")
		check(same_as_snapshot(snap) == 0, "ligar não mexe em nada do World (posição, grupos, visível)")
		var mask: int = main.get_viewport().canvas_cull_mask
		check(mask & iso.LAYER_WORLD == 0, "a tela deixa de mostrar o World cartesiano")
		check(cam.ground_center().distance_to(ground_before) < 2.0, "a câmera continua olhando o mesmo ponto do chão (%s -> %s)" % [ground_before, cam.ground_center()])
		t_mark = t
	elif step == 1 and t > t_mark + 1.5:
		step = 2
		print("== espelhos e caixas")
		var n_ents: int = iso._ents.size()
		var n_ip := 0
		for ip in main.get_tree().get_nodes_in_group("ipezinhos"):
			if iso.billboard_of(ip) != null:
				n_ip += 1
		check(n_ents > 50, "%d coisas em pé espelhadas" % n_ents)
		check(n_ip == main.get_tree().get_nodes_in_group("ipezinhos").size(), "todo ipezinho tem espelho (%d)" % n_ip)
		var clickables := 0
		for b in main.get_tree().get_nodes_in_group("clickable"):
			if iso.billboard_of(b) != null:
				clickables += 1
		check(clickables == main.get_tree().get_nodes_in_group("clickable").size(), "todo prédio clicável tem caixa (%d)" % clickables)
		print("== ordem por caixas")
		var e: Array = order_errors(iso)
		check(e[0] == 0, "%d pares que se sobrepõem na tela, %d na ordem errada" % [e[1], e[0]])
		print("  fixas: %s" % [iso.order_stats()])
		print("== clique pelo raio da câmera")
		var hub = main.get_tree().get_first_node_in_group("village_hub")
		var bb = iso.billboard_of(hub)
		var top: Vector2 = Iso.iso(bb.box.rect.get_center(), bb.box.zt)
		var hit: Dictionary = iso.pick(top)
		check(hit.node == hub and hit.what == "topo", "mirando no alto do Centro da Vila: acerta ele (%s, %s)" % [hit.node, hit.what])
		# a face: só contra a caixa do Centro (um ipezinho parado na frente dela é acertado
		# antes, e isso está certo — o raio pega a 1ª coisa que se vê)
		var face: Vector2 = Iso.iso(Vector2(bb.box.rect.get_center().x, bb.box.rect.end.y), (bb.box.zb + bb.box.zt) * 0.5)
		var planes := [{"rect": main.get_node("World/Environment").world_rect(), "z": 0.0}]
		var fh: Dictionary = Iso.pick(face, bb.boxes, planes)
		check(fh.what == "face", "mirando na parede da frente: FACE do Centro")
		check(absf(fh.ground.y - bb.box.rect.end.y) < 1.0, "a ordem de andar vai pro pé da parede")
		hit = iso.pick(face)
		check(hit.node == hub or (hit.node != null and hit.node.is_in_group("ipezinhos")), "na vista: a parede, ou um ipezinho na frente dela")
		var empty := Vector2(550, -950)  # canto vazio da floresta (terraço de cima)
		hit = iso.pick(iso.to_screen(empty))
		check(hit.node == null or hit.ground.distance_to(empty) < 40.0, "chão livre: ponto certo (%s)" % hit.ground)
		# o ipezinho mais afastado dos outros (dois colados: o clique pega o da frente, certo)
		var ips: Array = main.get_tree().get_nodes_in_group("ipezinhos")
		var ip: Node2D = ips[0]
		var best := -1.0
		for a in ips:
			var near := INF
			for b in ips:
				if a != b:
					near = minf(near, iso.to_screen(a.global_position).distance_to(iso.to_screen(b.global_position)))
			if near > best:
				best = near
				ip = a
		main._press_canvas = iso.to_screen(ip.global_position) + Vector2(0, -14)
		var seen: Dictionary = iso.pick(main._press_canvas)
		var expected: Node2D = seen.node if seen.node and seen.node.is_in_group("ipezinhos") else ip
		main._finish_left_click_iso(false)
		check(main.selected == expected, "clique no boneco seleciona o que se vê ali (%s)" % expected.name)
		print("== construir e demolir (encaixe incremental)")
		n_static_before = iso._order.order.size()
		extra = load("res://scenes/props/arvore.tscn").instantiate()
		extra.position = Vector2(150, 250)
		main.get_node("World").add_child(extra)
		t_mark = t
	elif step == 2 and t > t_mark + 0.5:
		step = 3
		var st: Dictionary = iso.order_stats()
		check(iso.billboard_of(extra) != null, "a árvore nova ganhou espelho")
		check(iso._order.order.size() == n_static_before + 1, "entrou 1 caixa fixa (%d -> %d)" % [n_static_before, iso._order.order.size()])
		check(st.full_rebuilds == 0, "encaixe sem reordenar tudo (reordenações completas: %d)" % st.full_rebuilds)
		extra.queue_free()
		t_mark = t
	elif step == 3 and t > t_mark + 0.5:
		step = 4
		check(iso._order.order.size() == n_static_before, "demolir tira a caixa")
		var e: Array = order_errors(iso)
		check(e[0] == 0, "depois de construir/demolir: %d pares, %d na ordem errada" % [e[1], e[0]])
		print("== prédio em L = 2 caixas")
		extra = make_L()
		main.get_node("World").add_child(extra)
		t_mark = t
	elif step == 4 and t > t_mark + 0.5:
		step = 5
		var bb = iso.billboard_of(extra)
		check(bb != null and bb.boxes.size() == 2, "o L tem 2 caixas")
		var both: bool = bb.boxes.all(func(b): return iso._order.ranks.has(b))
		check(both, "as 2 caixas estão na ordem")
		var zs_ok: bool = bb._part_clips.size() == 2
		for k in bb._part_clips.size():
			zs_ok = zs_ok and bb._part_clips[k].z_index == iso._order.z_of_static(bb.boxes[k])
		check(zs_ok, "cada pedaço da arte desenha com o z da sua caixa")
		var hits := 0
		for b in bb.boxes:
			var h: Dictionary = iso.pick(Iso.iso(b.rect.get_center(), b.zt))
			if h.node == extra:
				hits += 1
		check(hits == 2, "clique em qualquer parte acerta o prédio (%d de 2)" % hits)
		extra.queue_free()
		t_mark = t
	elif step == 5 and t > t_mark + 0.5:
		step = 6
		print("== fantasma do posicionador em pé")
		var placer = main.get_tree().get_first_node_in_group("house_placer")
		placer.begin(func(_p): return false)
		var spot := Vector2(-300, 220)
		placer.move_to(spot)
		iso._process(0.016)
		var gb: Sprite2D = iso._ghost_bb
		check(gb != null and gb.visible, "o fantasma aparece em pé na vista iso")
		check(gb != null and gb.position.distance_to(iso.to_screen(spot)) < 1.0, "no ponto isométrico do mouse")
		check(placer._ghost.visibility_layer == iso.LAYER_STANDING, "fora da textura do chão (não fica deitado)")
		check(gb != null and gb.modulate == placer._ghost.modulate, "mesma cor de pode/não pode")
		# mirando na PAREDE do Centro da Vila: o chão embaixo do mouse é o pé da parede -> recusa
		var hub = main.get_tree().get_first_node_in_group("village_hub")
		var hb = iso.billboard_of(hub).box
		var wall: Vector2 = Iso.iso(Vector2(hb.rect.get_center().x, hb.rect.end.y), (hb.zb + hb.zt) * 0.5)
		placer.move_to(iso.ground_at(wall))
		check(placer._reason != "", "construir mirando na parede de um prédio: recusado (%s)" % placer._reason)
		placer._cancelable = true
		placer.cancel()
		iso._process(0.016)
		check(gb != null and not gb.visible, "cancelou: o fantasma some")
		print("== custo por quadro")
		var t0 := Time.get_ticks_usec()
		for i in 30:
			iso._process(0.016)
		var ms := (Time.get_ticks_usec() - t0) / 30000.0
		print("  %.2f ms por quadro com %d espelhos" % [ms, iso._ents.size()])
		check(ms < 8.0, "vista iso < 8 ms por quadro (%.2f)" % ms)
		print("== save com a vista iso: câmera gravada no CHÃO")
		var sm = root.get_node("SaveManager")
		sm.save_game("manual")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		var p: Array = data.camera.position
		check(Vector2(p[0], p[1]).distance_to(cam.ground_center()) < 2.0, "posição da câmera no save = ponto do chão (%s)" % [p])
		print("== desliga")
		snap = snapshot()
		ground_before = cam.ground_center()
		iso.set_enabled(false)
		check(not iso.enabled and iso._ents.is_empty(), "desliga e solta os espelhos")
		check(main.get_viewport().canvas_cull_mask & iso.LAYER_WORLD != 0, "a tela volta a mostrar o World")
		check(same_as_snapshot(snap) == 0, "desligar não mexe em nada do World")
		check(cam.ground_center().distance_to(ground_before) < 2.0, "a câmera continua no mesmo ponto do chão")
		var std := 0
		for n in main.get_node("World").get_children():
			if n is CanvasItem and n.visibility_layer != 1:
				std += 1
		check(std == 0, "camadas de visibilidade de volta ao normal")
		print("FALHAS: %d" % fails)
		return true
	return false


## Um prédio em "L" de teste: 2 partes (a comprida ao fundo e a perna da frente-esquerda).
func make_L() -> Node2D:
	var sc := GDScript.new()
	sc.source_code = "extends Node2D
func iso_parts() -> Array:
	return [{\"rect\": Rect2(-40, -40, 80, 30), \"h\": 50.0}, {\"rect\": Rect2(-40, -10, 30, 40), \"h\": 50.0}]
"
	sc.reload()
	var n := Node2D.new()
	n.set_script(sc)
	n.name = "PredioL"
	n.position = Vector2(-100, 250)
	var spr := Sprite2D.new()
	spr.texture = load("res://icon.svg")
	spr.offset = Vector2(0, -50)
	n.add_child(spr)
	return n
