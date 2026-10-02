extends SceneTree
## Prompt 19: luz e noite na vista iso (iso_luz.gd, luzes/janelas no predios.json).
## Texturas por tipo de luz; cada luz no ponto anotado no desenho e com o tipo dela; janelas
## acesas só à noite e com a luz do prédio acesa; luzes alcançam todo o z da ordem de desenho;
## lava nas fendas de calor; tom do ambiente por estação. RODAR SÓ COM APPDATA ISOLADO.
const IsoLuz := preload("res://scripts/iso/iso_luz.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var fails := 0


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


func dn() -> Node:
	return main.get_node("DayNight")


func sync(n: Node) -> void:
	var bb = iso().billboard_of(n)
	bb.never_synced = true
	bb.sync_static(Rect2(-1e6, -1e6, 2e6, 2e6))


func luz_de(n: Node, nome: String) -> PointLight2D:
	var bb = iso().billboard_of(n)
	for pr in bb._pairs:
		if pr[1] is PointLight2D and String(pr[0].name) == nome:
			return pr[1]
	return null


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		dn().time_scale = 0.0
		_dados()
		_noite()
		t = 3.0
	elif step == 1 and t > 3.5:
		step = 2
		_janelas_e_pontos()
		_estacoes()
		print("FALHAS: %d" % fails)
		return true
	return false


func _noite() -> void:
	dn().time = 215.0
	dn().snap_lighting()


func _dados() -> void:
	print("== texturas e anotações")
	var falta := []
	for tipo in IsoLuz.TIPOS:
		if IsoLuz.texture(tipo) == null:
			falta.append(tipo)
	check(falta.is_empty(), "uma textura por tipo de luz (%d tipos) %s" % [IsoLuz.TIPOS.size(), falta])
	var casa: Dictionary = IsoArt.state("casa", "pronto_0")
	check(casa.has("janelas") and casa.has("luzes") and casa.luzes[0].tipo == "janela", "casa: janelas acesas e ponto de luz no desenho")
	check(IsoArt.state("escavadeira", "pronto").get("luzes", []).size() == 3, "escavadeira: cabine, reator e giroflex anotados")
	check(not IsoArt.state("casa", "obra_2").has("luzes"), "obra não acende (sem luz anotada)")


func _janelas_e_pontos() -> void:
	print("== janelas acesas")
	var casa: Node2D = main.get_tree().get_nodes_in_group("casas")[0]
	var wl: PointLight2D = casa.get_node("WindowLight")
	var bb = iso().billboard_of(casa)
	wl.enabled = true
	sync(casa)
	check(bb._janelas != null and bb._janelas.visible and bb._janelas.modulate.a > 0.9, "noite + casa ocupada: janelas acesas (alfa %.2f)" % (bb._janelas.modulate.a if bb._janelas else 0.0))
	var amb: Color = main.get_node("Ambient").color
	check(bb._janelas.modulate.b * amb.b > 0.95, "a cor da janela compensa o ambiente escuro (fica clara)")
	wl.enabled = false
	sync(casa)
	check(not bb._janelas.visible, "casa vazia: janelas apagadas")
	wl.enabled = true
	dn().time = 60.0
	dn().snap_lighting()
	sync(casa)
	check(not bb._janelas.visible, "de dia: janelas apagadas mesmo ocupada")
	_noite()
	print("== pontos de luz e tipos")
	var arm := main.get_tree().get_first_node_in_group("armazens")
	sync(arm)
	var l := luz_de(arm, "WindowLight")
	var st: Dictionary = IsoArt.state("armazem", "pronto")
	var want: Vector2 = iso().billboard_of(arm).global_position + st.luzes[0].pos
	check(l != null and l.global_position.distance_to(want) < 1.5, "armazém: a luz no ponto anotado (lampião da porta) (%s ~ %s)" % [l.global_position.round() if l else Vector2.INF, want.round()])
	check(l != null and l.texture == IsoLuz.texture("lampiao"), "armazém: textura de lampião")
	check(l != null and l.range_z_min <= -4096 and l.range_z_max >= 4096, "a luz alcança todo o z da ordem de desenho (terreno incluído)")
	check(l != null and is_equal_approx(l.energy, arm.get_node("WindowLight").energy * IsoLuz.TIPOS.lampiao.forca), "força = a do jogo × o ganho do tipo")
	var w = main.get_tree().get_first_node_in_group("ipezinhos")
	w.set_job("minerador")
	await process_frame
	var wbb = iso().billboard_of(w)
	wbb.never_synced = true
	wbb.sync_dynamic()
	var hl := luz_de(w, "HeadLamp")
	check(hl != null and hl.texture == IsoLuz.texture("lanterna"), "lanterna do capacete com a textura de lanterna")
	var env := main.get_node("World/Environment")
	var torch_ok := false
	var crystal_ok := false
	for c in env.get_children():
		var bbc = iso().billboard_of(c)
		if bbc == null:
			continue
		bbc.never_synced = true
		bbc.sync_static(Rect2(-1e6, -1e6, 2e6, 2e6))
		for pr in bbc._pairs:
			if pr[1] is PointLight2D:
				if c.is_in_group("tochas") and pr[1].texture == IsoLuz.texture("tocha") and pr[1].is_visible_in_tree():
					torch_ok = true
				if c is Sprite2D and c.texture.resource_path.get_file().begins_with("crystal") and pr[1].texture == IsoLuz.texture("cristal"):
					crystal_ok = pr[1].color == pr[0].color  # (fora da tela a luz fica apagada pelo Environment)
	check(torch_ok, "tocha: a luz continua visível com o desenho novo (textura de tocha)")
	check(crystal_ok, "cristal: luz de cristal com a cor do cristal")
	var lava := 0
	for c in iso()._terrain_node.get_children():
		if c is PointLight2D and String(c.name).begins_with("Lava_"):
			lava += 1
	var calor := main.get_tree().get_nodes_in_group("zonas_perigo").filter(func(z): return z.kind == "calor").size()
	check(lava == calor and lava > 0, "luz de lava em cada fenda de calor (%d)" % lava)


func _estacoes() -> void:
	print("== ambiente por estação")
	var sun := main.get_tree().get_first_node_in_group("sun")
	var cores := []
	for s in 4:
		dn().day = 1 + sun.days_per_season * s
		dn().time = 90.0
		dn().snap_lighting()
		cores.append(main.get_node("Ambient").color)
	print("  primavera %s  verão %s  outono %s  inverno %s" % cores)
	check(cores[3].b / maxf(cores[3].r, 0.01) > cores[0].b / maxf(cores[0].r, 0.01), "inverno mais frio (azulado) que a primavera")
	check(cores[1].r >= cores[1].b and cores[1] != cores[0], "verão mais quente")
	dn().day = 1 + sun.days_per_season * 3
	dn().time = 215.0
	dn().snap_lighting()
	var inv: Color = main.get_node("Ambient").color
	dn().day = 1
	dn().snap_lighting()
	var pri: Color = main.get_node("Ambient").color
	check(inv.v < pri.v, "noite de inverno mais escura que a de primavera")
