extends SceneTree
## Bloco 73: os bonecos andando no chão (o Marco: "parece que eles flutuam um pouco"). Confere: em toda
## animação de andar o pé mais baixo de cada quadro encosta na linha da âncora depois do ajuste (antes
## subia até 9 px), a cabeça da caminhada fica na mesma vertical, a pose aplica o ajuste (âncora, topo,
## altura), o quadro da caminhada vem da distância andada, "andando" sem sair do lugar fica parado, o
## passo não conta pulo de lugar, e a posição desenhada fica entre dois passos da física.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const B := preload("res://scripts/iso/iso_bonecos.gd")
var main: Node
var t := 0.0
var fails := 0
var step := 0
var w: Node
var bb: Node
var frames_vistos := {}


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


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 4.0:
		_dados()
		_pose()
		_passo()
		_comeca_andar()
		step = 1
		t = 4.0
	elif step == 1:
		var cam = main.get_node("Camera2D")  # a câmera segue (fora da tela o espelho não anima)
		cam.position = main.get_node("IsoView").to_screen(w.global_position)
		cam._target_pos = cam.position
		if bb != null and bb._char != null and bb._c_body.texture != null:
			frames_vistos[bb._c_body.frame] = true
		if t > 5.5:
			_andando()
			print("FALHAS: %d" % fails)
			return true
	return false


## O pé mais baixo de cada quadro (beira de baixo, px do quadro) e o x médio da cabeça.
func _medidas(info: Dictionary) -> Array:
	var img := Image.load_from_file(ProjectSettings.globalize_path(B.DIR + String(info.img)))
	var w_q := int(info.quadro[0])
	var out := []
	for k in int(info.n):
		var baixo := -1
		var topo := -1
		for y in img.get_height():
			var n := 0
			for x in range(k * w_q, (k + 1) * w_q):
				if img.get_pixel(x, y).a > 40.0 / 255.0:
					n += 1
			if n >= 1 and topo < 0:
				topo = y
			if n >= 2:
				baixo = y + 1
		var sx := 0.0
		var cnt := 0
		for y in range(topo, topo + 11):
			for x in range(k * w_q, (k + 1) * w_q):
				if img.get_pixel(x, y).a > 40.0 / 255.0:
					sx += x - k * w_q
					cnt += 1
		out.append([baixo, sx / maxf(cnt, 1.0)])
	return out


func _dados() -> void:
	print("== pé no chão nas animações de andar (bonecos.json: aj)")
	var d: Dictionary = B.data()
	var casos := [["minerador", "caminhada", "SE"], ["mineradora", "caminhada", "SE"], ["civil", "caminhada", "NE"],
		["guarda", "caminhada", "NE"], ["lenhador", "mancar_esq", "SE"], ["minerador", "com_picareta", "NE"], ["robo", "caminhada", "NE"],
		["casaco_minerador", "caminhada", "SO"], ["traje_gas_f", "caminhada", "NO"]]
	for c in casos:
		var info: Dictionary = d.pastas.get(c[0], {}).get("anims", {}).get(c[1], {}).get(c[2], {})
		if info.is_empty():
			check(false, "%s/%s/%s existe" % c)
			continue
		var m := _medidas(info)
		var antes := 0.0
		var depois := 0.0
		var cab := []
		for k in m.size():
			var aj := B._aj(info, k)
			antes = maxf(antes, absf(float(info.ancora[1]) - m[k][0]))
			depois = maxf(depois, absf(float(info.ancora[1]) - (m[k][0] + aj.y)))
			cab.append(m[k][1] + aj.x)
		var cab_var: float = float(cab.max()) - float(cab.min())
		var gente: bool = c[0] != "robo" and c[1] != "mancar_esq"
		check(depois <= 1.0 and (not gente or cab_var <= 2.0),
			"%s %s %s: pé até %.0f px fora do chão antes, %.0f depois%s" % [c[0], c[1], c[2], antes, depois,
			(", cabeça varia %.1f px" % cab_var) if gente else ""])
	var sem := 0
	var com := 0
	for p in d.pastas:
		for an in ["caminhada", "mancar_esq"]:
			for dr in d.pastas[p].get("anims", {}).get(an, {}).values():
				if dr.has("aj"):
					com += 1
				elif int(dr.n) > 1:
					sem += 1
	check(com >= 200, "ajuste em %d tiras de andar (%d já estavam no chão)" % [com, sem])
	var gosma: Dictionary = d.pastas.get("criatura_gosma", {}).get("anims", {}).get("caminhada", {})
	check(not gosma.values().any(func(x): return x.has("aj")), "a gosma pula de propósito: sem ajuste")


func _pose() -> void:
	print("== a pose aplica o ajuste e o passo")
	w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w.gender = "menina"
	w.set_job("minerador")
	w.carrying = 5.0  # carregando: caminhada (sem a picareta desenhada)
	w.velocity = Vector2(60, 0)
	var info: Dictionary = B.data().pastas.mineradora.anims.caminhada.SE
	var p := B.pose(w, 0, 0.0, 0.0)
	check(p.anim == "caminhada" and p.frame == 0, "passo 0: quadro 0 da caminhada")
	var aj := B._aj(info, 0)
	check(aj != Vector2.ZERO and p.ancora == Vector2(info.ancora[0], info.ancora[1]) - aj,
		"âncora do quadro = âncora da tira - ajuste (%s)" % aj)
	check(is_equal_approx(p.altura, -(float(info.topo[0][1]) + aj.y)), "altura do boneco já com o ajuste")
	check(B.pose(w, 0, 0.0, 0.26).frame == 1 and B.pose(w, 0, 0.0, 0.51).frame == 2 and B.pose(w, 0, 0.0, 1.0).frame == 0,
		"o quadro vem da fase do passo (1/4 de ciclo por quadro)")
	check(B.pose(w, 0, 0.0, 0.3, false).anim == "parado", "velocidade sem sair do lugar: parado (não marcha no lugar)")
	check(B.pose(w, 0, 0.0).anim == "caminhada", "sem passo: o relógio de antes (testes antigos)")
	w.carrying = 0.0
	w.velocity = Vector2.ZERO


func _passo() -> void:
	print("== o passo pela distância")
	var iso = main.get_node("IsoView")
	for k in iso._ents:
		if iso._ents[k].src == w:
			bb = iso._ents[k]
	check(bb != null, "o espelho do ipezinho")
	if bb == null:
		return
	var c: float = bb.PASSO_CICLO
	bb._chao_ant = Vector2.INF
	bb._passo = 0.0
	bb._conta_passo(Vector2(100, 100), 1.0 / 60.0)
	bb._conta_passo(Vector2(100 + c * 0.25, 100), 1.0 / 60.0)
	check(is_equal_approx(bb._passo, 0.25), "1/4 do ciclo andado = 1/4 de passo (%.2f)" % bb._passo)
	bb._conta_passo(Vector2(400, 300), 1.0 / 60.0)
	check(is_equal_approx(bb._passo, 0.25), "pulo de lugar (elevador, porta) não conta")
	print("== a posição entre dois passos da física")
	bb._f_quadro = -1
	bb._f_cur = Vector2.INF
	var p0: Vector2 = w.global_position
	bb._pos_suave()
	w.global_position = p0 + Vector2(4, 0)
	bb._f_quadro = Engine.get_physics_frames() - 1  # um passo da física depois
	var s: Vector2 = bb._pos_suave()
	var fr := Engine.get_physics_interpolation_fraction()
	check(s.distance_to(p0.lerp(p0 + Vector2(4, 0), fr)) < 0.01, "desenhada entre o passo anterior e o atual (fração %.2f)" % fr)
	w.global_position = p0 + Vector2(300, 0)
	check(bb._pos_suave() == w.global_position, "mudou fora da física (gaiola, save): vai direto")
	w.global_position = p0


func _comeca_andar() -> void:
	w.manual_override_time = 999.0
	w.move_to(w.global_position + Vector2(-300, 40))


func _andando() -> void:
	print("== andando de verdade")
	check(bb._desloc > bb.MEXENDO, "velocidade de verdade na vista: %.0f px/s" % bb._desloc)
	check(frames_vistos.size() >= 3, "a perna mexe (quadros vistos: %s)" % [frames_vistos.keys()])
	var anim: String = B.pose(w, bb.iso_dir, 0.0, bb._passo, bb._desloc > bb.MEXENDO).get("anim", "")
	check(anim in ["caminhada", "com_picareta"], "andando: %s" % anim)
