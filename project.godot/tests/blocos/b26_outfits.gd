extends SceneTree
## Bloco 26: outfit por função. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var fails := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func tex_name(w) -> String:
	return w._body.texture.resource_path.get_file()


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t < 2.0:
		return false
	var W = load("res://scripts/workers/ipezinho.gd")
	print("== todos os 48 corpos existem e carregam")
	var missing := 0
	for o in W.OUTFIT_FILES:
		for g in W.GENDERS:
			for i in W.LOOKS_PER_GENDER:
				if W._body_texture(o, g, i) == null:
					missing += 1
	check(missing == 0, "%d texturas faltando" % missing)

	var w = get_nodes_in_group("ipezinhos")[0]
	w._update_animation(0.016)
	print("== partida nova (sem função): %s" % tex_name(w))
	check(tex_name(w).begins_with("ipezinho_civil_"), "ocioso veste civil")
	check(not w._lamp.enabled, "civil sem lanterna acesa")
	check(not w._tool.visible, "civil sem ferramenta")

	var expect := {
		"minerador": ["ipezinho_%s%d.png", true, true],
		"lenhador": ["ipezinho_lenhador_%s%d.png", false, true],
		# (Bloco 43) atualizado pelas regras novas: Bloco 28 = roupa própria do guarda e do
		# pesquisador (sem lanterna); Bloco 29 = cozinheiro com a cesta, guarda com a arma,
		# pesquisador só pega a picareta quando minera.
		"cozinheiro": ["ipezinho_cozinheiro_%s%d.png", false, true],
		"guarda": ["ipezinho_guarda_%s%d.png", false, true],
		"pesquisador": ["ipezinho_pesquisador_%s%d.png", false, false],
		"ocioso": ["ipezinho_civil_%s%d.png", false, false],
	}
	var g: String = W.GENDERS[w.gender]
	for job in expect:
		w.set_job(job)  # troca na hora, sem recarregar
		w._update_animation(0.016)
		var want: String = expect[job][0] % [g, w.look]
		check(tex_name(w) == want and w._lamp.enabled == expect[job][1] and w._tool.visible == expect[job][2],
			"%-11s -> %s  lanterna=%s ferramenta=%s" % [job, tex_name(w), w._lamp.enabled, w._tool.visible])
		check(not w._cook_icon.visible, "  sem chapéu extra por cima")
	# acessórios continuam acompanhando o quadro em outro outfit
	w.set_job("lenhador")
	w._body.frame = 3
	w._sync_accessories()
	var ok := true
	for k in 3:
		if w._accessory_variant[k] >= 0 and w._accessories[k].frame % 4 != 3:
			ok = false
	check(ok, "acessórios sincronizados no outfit de lenhador (variantes %s)" % [w._accessory_variant])
	print("\nFALHAS: %d" % fails)
	return true
