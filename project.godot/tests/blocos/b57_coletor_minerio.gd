extends SceneTree
## Bloco 57: coletor de minério. Lugar só perto de jazida, encomenda vira canteiro do engenheiro,
## designar minerador, produz minério do tipo da jazida pro armazém, para sem operador, jazida
## esgotada para sem erro (e volta), trocar de jazida, vários (custo cresce), cartão do menu e
## save/load (posição, operador, total, jazida escolhida). RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var col: Node
var op: Node
var ferro0 := 0.0
var tipo := ""


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
	return current_scene.get_tree().get_first_node_in_group(grupo)


func _jazida_livre() -> Node:
	for j in main.get_tree().get_nodes_in_group("minerios"):
		if j.is_unlocked() and not j.is_sealed() and j.ore_type == "ferro":
			return j
	return null


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 150.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_encomenda()
				step = 1
		1:
			var cs: Array = main.get_tree().get_nodes_in_group("coletores_minerio")
			if not cs.is_empty():
				col = cs[0]
				Engine.time_scale = 1.0
				_designa()
				step = 2
				t_mark = t
		2:
			if t - t_mark > 2.0 and col._producing:
				ferro0 = _estoque()
				step = 3
				t_mark = t
			elif t - t_mark > 40.0:
				check(false, "operador chegou e a broca ligou (%s)" % col.status_text())
				step = 3
				t_mark = t
		3:
			if t - t_mark > 6.0:
				_produziu()
				step = 4
				t_mark = t
		4:
			if t - t_mark > 1.0:
				_esgota()
				step = 5
				t_mark = t
		5:
			if t - t_mark > 1.0:
				_volta_e_salva()
				step = 6
				t_mark = t
		6:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 7
				t_mark = t
		7:
			if t - t_mark > 4.0:
				_carregado()
				Engine.time_scale = 1.0
				print("FALHAS: %d" % fails)
				return true
	return false


func _estoque() -> float:
	var s := 0.0
	for a in main.get_tree().get_nodes_in_group("armazens"):
		s += float(a.stock.get(tipo, 0.0))
	return s


func _encomenda() -> void:
	print("== construir")
	var hub = g("village_hub")
	var eco = g("economy")
	eco.credits = 5000
	var arm = g("armazens")
	arm.stock["ferro"] = 500.0
	arm.wood_stored = 500.0
	arm._recount()
	var j := _jazida_livre()
	check(j != null, "há jazida de ferro liberada")
	check(hub.coletor_minerio_spot_reason(Vector2(-3000, -3000)) != "", "longe de jazida: não pode (%s)" % hub.coletor_minerio_spot_reason(Vector2(-3000, -3000)))
	var placer = g("house_placer")
	var spot := Vector2.INF
	check(hub.build_coletor_minerio(), "abre o posicionador")
	for r in range(3, 9):
		for a in 16:
			var p: Vector2 = j.global_position + Vector2.RIGHT.rotated(a * TAU / 16.0) * (r * 20.0)
			placer.move_to(p)
			if placer._reason == "":
				spot = p
				break
		if spot != Vector2.INF:
			break
	check(spot != Vector2.INF, "achou lugar perto da jazida (%s)" % spot)
	var c0: float = eco.credits
	check(placer.try_confirm(), "encomendou")
	check(eco.credits < c0, "cobrou (%d cr)" % int(c0 - eco.credits))
	var cant: Node = null
	for c in main.get_tree().get_nodes_in_group("canteiros"):
		if c.kind == "coletor_minerio":
			cant = c
	check(cant != null, "virou canteiro (obra do engenheiro)")
	check(hub.coletor_minerio_block_reason().begins_with("em obra"), "outro só depois da obra: %s" % hub.coletor_minerio_block_reason())
	if cant:
		cant.total = 3.0
		cant.left = 3.0
	main.get_tree().get_nodes_in_group("ipezinhos")[0].set_job("engenheiro")
	Engine.time_scale = 3.0


func _designa() -> void:
	print("== operar")
	check(col.is_in_group("clickable") and col.panel_id == "coletor_minerio", "pronto e clicável")
	check(not col.has_operator() and not col._producing, "sem operador: parado (%s)" % col.status_text())
	var hud = g("hud")
	hud.open_panel_for(col)
	var pn = hud._panels["coletor_minerio"]
	check(pn.visible and pn._current() == col, "clique abre a janela dele")
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	op = ws[1]
	op.set_job("minerador")
	main.select(op)
	pn.refresh()
	check("Designar minerador: %s" % op.display_name == pn._designate_button.text, "janela oferece o selecionado (%s)" % pn._designate_button.text)
	pn._designate_button.pressed.emit()
	check(col.operator == op, "designado")
	var lenhador = ws[2]
	lenhador.set_job("lenhador")
	check(not col.designate(lenhador) and col.operator == op, "lenhador não opera a broca")
	hud.close_panels()
	tipo = col.jazida().ore_type if col.jazida() else ""
	check(tipo != "", "broca tira de uma jazida de %s" % tipo)


func _produziu() -> void:
	print("== produzir")
	var agora := _estoque()
	check(agora > ferro0 + 0.5, "%s no armazém subiu (%.1f -> %.1f)" % [tipo, ferro0, agora])
	check(col.total_produced > 0.0, "total produzido %.1f" % col.total_produced)
	check(op.get_state() == "operating_ore", "operador: %s" % op.get_state_label())
	col.release()
	check(not col.has_operator(), "liberou")


func _esgota() -> void:
	check(not col._producing and "sem operador" in col.status_text(), "sem operador para (%s)" % col.status_text())
	col.designate(op)
	var j = col.jazida()
	j.ore_remaining = 0.5
	var got: float = j.extract(5.0)
	check(is_equal_approx(got, 0.5) and j.is_depleted(), "jazida esgotada pela broca entra no descanso")
	check(j.extract(1.0) == 0.0, "esgotada: extract devolve 0 (sem erro)")


func _volta_e_salva() -> void:
	print("== esgotada e save")
	col._process(0.1)
	check(not col._producing and "esgotada" in col.status_text(), "para sem erro: %s" % col.status_text())
	var hub = g("village_hub")
	var custo1: Vector3i = hub.coletor_minerio_cost()
	check(custo1.x > hub.coletor_min_credits, "o segundo custa mais (%s)" % hub.coletor_minerio_cost_text())
	var card: Dictionary = {}
	for d in g("hud")._build_menu._defs("Coleta automática"):
		if d.name == "Coletor de minério":
			card = d
	check(not card.is_empty() and card.get("many", false) and not card.get("soon", false) and card.cost.call() == hub.coletor_minerio_cost_text(), "cartão do menu: pode ter vários, custo atual")
	if col.jazidas_no_alcance().size() > 1:
		col.choose_next()
	else:
		col.chosen_pos = col.jazida().global_position
	root.get_node("SaveManager").save_game("teste")


func _carregado() -> void:
	print("== depois de carregar")
	var cs: Array = main.get_tree().get_nodes_in_group("coletores_minerio")
	check(cs.size() == 1, "o coletor voltou")
	if cs.is_empty():
		return
	var c = cs[0]
	check(c.total_produced > 0.0, "total voltou (%.1f)" % c.total_produced)
	check(c.chosen_pos != Vector2.INF, "jazida escolhida voltou")
	var op2: Node = c.operator
	check(op2 != null and op2.is_miner(), "o operador voltou pro posto (%s)" % (op2.display_name if op2 else "-"))
