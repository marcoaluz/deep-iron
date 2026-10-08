extends SceneTree
## Prompt 29, parte 4: natureza, objetos e o robô com a arte nova (iso_art.gd prop_layers,
## iso_bonecos.gd robo_pose). O desenho novo sai do desenho antigo de cada coisa (textura + quadro)
## e do estado (quantidade da jazida, tocha acesa, estado do robô); a navegação não muda.
## RODAR SÓ COM APPDATA ISOLADO.
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const B := preload("res://scripts/iso/iso_bonecos.gd")
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var fails := 0
var robo: Node2D


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


func names(n: Node) -> Array:
	return IsoArt.layers(n).map(func(l): return l.tex.resource_path.get_file().get_basename())


func iso() -> Node:
	return main.get_node("IsoView")


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		_natureza()
		robo = load("res://scenes/props/robo.tscn").instantiate()
		robo.position = Vector2(-60, -720)
		main.get_node("World").add_child(robo)
		t = 3.0
	elif step == 1 and t > 3.5:
		_elevadores()
		_robo()
		print("FALHAS: %d" % fails)
		return true
	return false


func _natureza() -> void:
	print("== árvores, tocas, horta")
	var trees := main.get_tree().get_nodes_in_group("arvores")
	var species := {}
	var ok := 0
	for tr in trees:
		var n := names(tr)
		if n.size() == 1 and n[0].begins_with("arvore_"):
			ok += 1
			species[n[0].split("_")[1]] = true
	check(ok == trees.size() and trees.size() > 0, "%d/%d árvores com o desenho novo" % [ok, trees.size()])
	check(species.size() >= 2, "espécies variadas pelo lugar (%s)" % [species.keys()])
	var tr0 = trees[0]
	tr0.get_node("Visual").frame = 2
	check(names(tr0)[0].begins_with("toco_"), "árvore cortada: o toco (%s)" % [names(tr0)])
	tr0.get_node("Visual").frame = 0
	var toca = main.get_tree().get_first_node_in_group("caca")
	var tv: Sprite2D = toca.get_node("Visual")
	var seen := []
	for f in 3:
		tv.frame = f
		seen.append(names(toca)[0])
	check(seen == ["toca_coelho_fora", "toca_coelho_orelhas", "toca_coelho_vazia"], "toca: coelho fora / orelhas / vazia %s" % [seen])
	var horta = main.get_tree().get_first_node_in_group("coleta_comida")
	if horta:
		var hv: Sprite2D = horta.get_node("Visual")
		var hs := []
		for f in 3:
			hv.frame = f
			hs.append(names(horta)[0])
		check(hs == ["horta_pronto", "horta_crescendo", "horta_colhido"], "horta: pronta / crescendo / colhida %s" % [hs])
	print("== jazidas")
	var ores := main.get_tree().get_nodes_in_group("minerios")
	var full := 0
	for o in ores:
		var n := names(o)
		if n.size() >= 1 and (n[0].begins_with("jazida_%s_" % o.ore_type) or n[0] == "jazida_esgotada"):
			full += 1
	check(full == ores.size(), "%d/%d jazidas com o desenho do minério delas" % [full, ores.size()])
	var j = null
	for o in ores:
		if o.is_unlocked() and not o.get("_rubble"):
			j = o
			break
	var tot: float = j.ore_total
	var st := []
	for r in [1.0, 0.5, 0.1]:
		j.ore_remaining = tot * r
		st.append(names(j)[0].trim_prefix("jazida_%s_" % j.ore_type))
	j._cooldown = 5.0
	st.append(names(j)[0])
	j._cooldown = 0.0
	j.ore_remaining = tot
	check(st == ["cheia", "meia", "quase", "jazida_esgotada"], "jazida pela quantidade: %s" % [st])
	var locked = null
	for o in ores:
		if o.get("_rubble") != null and o._rubble.visible:
			locked = o
			break
	if locked:
		var ls: Array = IsoArt.layers(locked)
		check(ls.size() == 2 and ls[1].tex.resource_path.ends_with("entulho_medio.png") and ls[0].mod.r < 0.6, "galeria lacrada: jazida cinza + entulho na frente")
	print("== decoração do ambiente")
	var env := main.get_node("World/Environment")
	var kinds := {}
	var unk := 0
	for c in env.get_children():
		if c is Sprite2D and c.z_index > -5 and c.texture:
			var n := names(c)
			if n.is_empty():
				unk += 1
			else:
				kinds[n[0].rstrip("_0123456789f")] = true
	check(kinds.has("rocha_musgo") or kinds.has("rocha_mina"), "pedras viram rochas novas (%s)" % [kinds.keys()])
	check(kinds.has("cristal_violeta") or kinds.has("cristal_ciano") or kinds.has("cristal_lima") or kinds.has("cristal_brasa"), "cristais novos")
	var torch: Sprite2D = null
	for c in env.get_children():
		if c is Sprite2D and c.is_in_group("tochas"):
			torch = c
			break
	if torch:
		var flame: Sprite2D = torch.get_child(0) if torch.get_child_count() > 0 and torch.get_child(0) is Sprite2D else null
		if flame:
			flame.modulate.a = 1.0
			var lit: Array = IsoArt.layers(torch)
			flame.modulate.a = 0.0
			var off: Array = IsoArt.layers(torch)
			# Bloco 98: UM desenho só — com a chama "apagada" (de dia) o desenho continua a chama animada; só a luz muda
			check(lit[0].has("anim") and lit[0].anim.size() == 4 and off.size() == 1 and off[0].has("anim") and off[0].anim.size() == 4, "tocha: a chama animada (4 quadros) com a chama acesa ou apagada (Bloco 98: o mesmo desenho)")
	check(unk == 0, "nenhuma decoração em pé sem desenho novo (%d)" % unk)
	# no jogo: o espelho de uma árvore desenha a peça nova com a caixa dela
	var bb = iso().billboard_of(tr0)
	bb.never_synced = true
	bb.sync_static(Rect2(-1e6, -1e6, 2e6, 2e6))
	check(bb._art != null and bb._art.get_child_count() == 1 and absf((bb.box.zt - bb.box.zb) - IsoArt.layers(tr0)[0].h) < 0.5, "no jogo: a árvore com o desenho novo e a caixa dele")


func _elevadores() -> void:
	print("== elevadores (andares de baixo)")
	var el = main.get_tree().get_first_node_in_group("elevador")
	check(names(el) == ["ruina", "gaiola"], "elevador fechado: ruína em cima + gaiola embaixo (%s)" % [names(el)])
	el.unlocked = true
	check(names(el) == ["pronto", "gaiola"], "elevador aberto: pronto (%s)" % [names(el)])
	el.unlocked = false
	var bb = iso().billboard_of(el)
	bb.never_synced = true
	bb.sync_static(Rect2(-1e6, -1e6, 2e6, 2e6))
	var g: Sprite2D = bb._art.get_child(1) if bb._art and bb._art.get_child_count() > 1 else null
	var want: Vector2 = iso().to_screen(el.bottom_position) - iso().to_screen(el.global_position)
	check(g != null and g.position.distance_to(want) < 1.0 and want.y > 300.0, "a gaiola fica no chão do nível 2, embaixo (%.0f px abaixo na tela)" % want.y)
	var ab = main.get_tree().get_first_node_in_group("elevador_abismo")
	check(names(ab) == ["ruina", "gaiola"], "plataforma do abismo arruinada + gaiola (%s)" % [names(ab)])
	ab.repairing = true
	ab.repair_left = ab.repair_time * 0.5
	var ls: Array = IsoArt.layers(ab)
	check(names(ab)[0] == "pronto" and ls[0].obra > 0.4 and ls[0].obra < 0.6, "em conserto: o pronto subindo pelo corte (%.2f)" % ls[0].obra)
	ab.repairing = false


func _robo() -> void:
	print("== robô")
	var seen := []
	for s in ["found", "carried", "base"]:
		robo.state = s
		seen.append(B.robo_pose(robo, 0, 0.0, false).anim)
	robo.state = "repairing"
	for left in [80.0, 45.0, 5.0]:
		robo.repair_left = left
		seen.append(B.robo_pose(robo, 0, 0.0, false).anim)
	check(seen == ["achado", "arrastado", "conserto_1", "conserto_1", "conserto_2", "conserto_3"], "no chão: achado, arrastado, conserto 1→2→3 pelo progresso %s" % [seen])
	robo.state = "active"
	var p := B.robo_pose(robo, 3, 0.0, true)
	check(p.anim == "caminhada" and p.dir == "NE", "ativo andando: caminhada na direção (NE)")
	robo.stunned = true
	p = B.robo_pose(robo, 0, 0.0, false)
	check(p.anim == "desligar" and p.frame == p.n - 1, "atordoado: desligado (último quadro)")
	robo.stunned = false
	robo.state = "found"
	var bb = iso().billboard_of(robo)
	check(bb != null and bb.dynamic, "o robô anda na vista (espelho de quem anda)")
	if bb:
		bb.sync_dynamic()
		var vis_hidden := true
		for pr in bb._pairs:
			if pr[0].name == "Visual" and pr[1].visible:
				vis_hidden = false
		check(bb._char != null and bb._char.visible and vis_hidden and bb.box.rect.size.x > 150.0, "achado no jogo: desenho novo deitado, a caixa do tamanho dele (%.0f)" % bb.box.rect.size.x)
