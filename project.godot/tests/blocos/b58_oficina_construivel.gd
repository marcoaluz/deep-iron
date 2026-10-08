extends SceneTree
## Bloco 58: Oficina construível. Jogo novo com fundação: a Oficina começa NÃO construída (sem clique,
## sem obra, sem bloquear caminho, minérios de ferramenta seguem trancados); construir pelo menu vira
## canteiro do engenheiro e ela fica pronta no lugar escolhido, funcionando (forjar ferramenta).
## Save com ela não construída volta igual; save antigo (sem "built") = já construída no lugar da cena.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var ofi: Node
var pos_cena := Vector2.ZERO
var lugar := Vector2.INF


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
	main.founding_on_new_game = false  # o teste monta a vila; a regra "jogo novo" é aplicada à mão abaixo
	root.add_child(main)
	current_scene = main
	load("res://scripts/props/armazem.gd").limite_desligado = true  # Bloco 97: o limite do armazém não é o assunto deste teste


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return current_scene.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 120.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_nao_construida()
				root.get_node("SaveManager").save_game("teste")
				step = 1
				t_mark = t
		1:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 2
				t_mark = t
		2:
			if t - t_mark > 3.0:
				_continua_nao_construida()
				_constroi()
				step = 3
				t_mark = t
		3:
			if ofi.is_built():
				Engine.time_scale = 1.0
				_pronta()
				step = 4
				t_mark = t
		4:
			if t - t_mark > 0.5:
				_save_antigo()
				print("FALHAS: %d" % fails)
				return true
	return false


func _nao_construida() -> void:
	print("== jogo novo: oficina por construir")
	ofi = g("oficina")
	pos_cena = ofi.global_position
	check(ofi.is_built(), "sem fundação (save antigo/teste): já construída")
	ofi.set_built(false)  # o que main.gd faz num jogo novo com fundação
	check(not ofi.visible and not ofi.is_in_group("clickable") and not ofi.is_in_group("obras"), "não construída: invisível, sem clique, fora das obras")
	check(ofi.get_obstacle_outline().is_empty(), "não bloqueia o caminho")
	check(g("oficina") == ofi, "continua no grupo (as ferramentas trancam os minérios)")
	var cobre: Node = null
	for j in main.get_tree().get_nodes_in_group("minerios"):
		if j.ore_type == "cobre":
			cobre = j
	if cobre:
		cobre.on_unlock_changed(false)
		check(not cobre.is_unlocked(), "cobre segue trancado sem a picareta de aço")
	check(g("equipment").order_block_reason("casaco").contains("Oficina") or g("equipment").vestiario() == null, "equipamento: precisa da Oficina")
	var hud = g("hud")
	hud.open_panel("oficina")
	var pn = hud._panels["oficina"]
	pn.refresh()
	check(pn._build_box.visible and pn._build_button.text.begins_with("Construir a Oficina"), "janela (O): só o construir (%s)" % pn._build_button.text)
	check(pn.button_text().begins_with("Oficina: construir"), "botão da coluna: %s" % pn.button_text())
	hud.close_panels()
	var card: Dictionary = {}
	for d in hud._build_menu._defs("Defesa e equipamento"):
		if d.name == "Oficina (forja)":
			card = d
	if card.is_empty():
		for tab in ["Moradia", "Alimentação", "Saúde", "Lazer", "Pesquisa", "Coleta automática", "Vila"]:
			for d in hud._build_menu._defs(tab):
				if d.name == "Oficina (forja)":
					card = d
	check(not card.is_empty() and not card.has("open") and card.cost.call() == g("village_hub").oficina_cost_text(), "cartão do menu: construir (%s)" % (card.cost.call() if not card.is_empty() else "-"))


func _continua_nao_construida() -> void:
	print("== save com ela por construir")
	ofi = g("oficina")
	check(not ofi.is_built() and not ofi.visible, "voltou não construída")


func _constroi() -> void:
	print("== construir")
	var hub = g("village_hub")
	var eco = g("economy")
	eco.credits = 3000
	var arm = g("armazens")
	arm.stock["ferro"] = 300.0
	arm.wood_stored = 300.0
	arm._recount()
	check(hub.oficina_block_reason() == "", "com recursos: liberado")
	check(hub.build_oficina(), "posicionador aberto")
	var placer = g("house_placer")
	placer._collect_blockers()
	for r in range(2, 16):
		for a in 16:
			var p: Vector2 = hub.global_position + Vector2.RIGHT.rotated(a * TAU / 16.0) * (60.0 + r * 26.0)
			placer.move_to(p)
			if placer._reason == "":
				lugar = p
				break
		if lugar != Vector2.INF:
			break
	check(lugar != Vector2.INF and placer.try_confirm(), "encomendada em %s" % lugar)
	var cant: Node = null
	for c in main.get_tree().get_nodes_in_group("canteiros"):
		if c.kind == "oficina":
			cant = c
	check(cant != null, "canteiro da Oficina (obra do engenheiro)")
	check(hub.oficina_block_reason().begins_with("em obra"), "uma só: %s" % hub.oficina_block_reason())
	if cant:
		cant.total = 3.0
		cant.left = 3.0
	main.get_tree().get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
	Engine.time_scale = 3.0


func _pronta() -> void:
	print("== pronta")
	check(ofi.visible and ofi.is_in_group("clickable") and ofi.is_in_group("obras"), "visível, clicável, aceita obra")
	check(ofi.global_position.distance_to(lugar) < 2.0, "no lugar escolhido")
	check(not ofi.get_obstacle_outline().is_empty(), "bloqueia o caminho de novo")
	check(g("village_hub").oficina_block_reason().begins_with("já construída"), "não dá outra")
	var eco = g("economy")
	eco.credits = 3000
	check(ofi.start_tool("picareta_aco") or ofi.tool_block_reason("picareta_aco") != "", "forja funciona (%s)" % ofi.tool_block_reason("picareta_aco"))


func _save_antigo() -> void:
	print("== save antigo")
	var d: Dictionary = ofi.get_save_data()
	d.erase("built")
	d.erase("position")
	ofi.set_built(false)
	ofi.global_position = pos_cena
	ofi.load_save_data(d)
	check(ofi.is_built() and ofi.visible and ofi.global_position == pos_cena, "sem \"built\": já construída no lugar da cena")
