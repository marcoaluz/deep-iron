extends SceneTree
## Bloco 56: casas nível 2 e 3. Bloqueio com motivo (estágio da vila, pesquisa), ampliação cobra e é
## obra do engenheiro (a casa segue habitada), camas e conforto do nível, arte do nível, janela da
## casa pelo clique, cartão do menu, save/load do nível e save antigo = nível 1.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var casa: Node
var viu_engenheiro := false


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
				_bloqueios()
				step = 1
				t_mark = t
		1:
			for w in main.get_tree().get_nodes_in_group("ipezinhos"):
				if w.get_state() == "building" and w.get("_obra") == casa:
					viu_engenheiro = true
			if casa.level >= 2:
				Engine.time_scale = 1.0
				_nivel2()
				root.get_node("SaveManager").save_game("teste")
				step = 2
				t_mark = t
		2:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 3.0:
				_depois_de_carregar()
				print("FALHAS: %d" % fails)
				return true
	return false


func _dar_recursos() -> void:
	var eco = g("economy")
	eco.credits = 5000
	var arm = g("armazens")
	arm.stock["ferro"] = 500.0
	arm.wood_stored = 500.0
	arm._recount()


func _bloqueios() -> void:
	print("== bloqueios e ampliação")
	for c in main.get_tree().get_nodes_in_group("casas"):
		if c.built:
			casa = c
			break
	check(casa != null and casa.level == 1 and casa.slot_count == casa.beds_for(1), "casa pronta começa no nível 1 (%d camas)" % (casa.slot_count if casa else 0))
	check(casa.is_in_group("clickable") and casa.get("panel_id") == "casa", "casa clicável (janela da casa)")
	var hub = g("village_hub")
	hub.level = 1
	check("estágio 2" in casa.upgrade_block_reason(), "vila no estágio 1: bloqueado (%s)" % casa.upgrade_block_reason())
	hub.level = 2
	g("economy").credits = 0
	check(casa.upgrade_block_reason().begins_with("falta"), "sem recursos: %s" % casa.upgrade_block_reason())
	var hud = g("hud")
	hud.open_panel_for(casa)
	var painel = hud._panels["casa"]
	check(painel.visible and painel._casa == casa, "clique abre a janela DESSA casa")
	painel.refresh()
	check(painel._botao.disabled and painel._motivo.text != "", "janela mostra o motivo (%s)" % painel._motivo.text)
	_dar_recursos()
	painel.refresh()
	check(not painel._botao.disabled and "Nível 2" in painel._custo.text, "com recursos: botão liberado (%s)" % painel._custo.text)
	var c0: float = g("economy").credits
	var f0: float = g("armazens").stock["ferro"]
	var m0: float = g("armazens").wood_stored
	painel._ampliar()
	check(casa.upgrade_pending() and casa.obra_pending(), "ampliação encomendada: vira obra")
	check(is_equal_approx(g("economy").credits, c0 - casa.upgrade_credits[1]), "cobrou %d créditos" % casa.upgrade_credits[1])
	check(g("armazens").stock["ferro"] <= f0 - casa.upgrade_ore[1] + 0.01 and g("armazens").wood_stored <= m0 - casa.upgrade_wood[1] + 0.01, "cobrou ferro e madeira")
	check(casa.level == 1 and casa.built, "durante a obra continua nível 1 e habitada")
	hud.close_panels()
	casa.upgrade_total = 6.0
	casa.upgrade_left = 6.0
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	ws[0].set_job("engenheiro")
	Engine.time_scale = 3.0


func _nivel2() -> void:
	print("== nível 2")
	check(viu_engenheiro, "o engenheiro foi construir a ampliação")
	check(casa.level == 2 and not casa.upgrade_pending(), "nível 2")
	check(casa.slot_count == casa.beds_for(2) and casa.beds_total() == casa.beds_for(2), "camas do nível 2: %d" % casa.beds_total())
	check(is_equal_approx(casa.comfort_bonus(), casa.comfort_for(2)) and casa.comfort_bonus() > 0.0, "conforto +%d" % roundi(casa.comfort_bonus()))
	var morador: Node = null
	for w in main.get_tree().get_nodes_in_group("ipezinhos"):
		if w.get("_home") == casa:
			morador = w
	if morador == null:
		var w0 = main.get_tree().get_nodes_in_group("ipezinhos")[1]
		casa.claim_bed(w0)
		w0._home = casa
		morador = w0
	var f: Array = morador.happiness_factors()
	check(f.any(func(x): return String(x[0]).begins_with("casa nível 2") and x[1] > 0.0), "ânimo de quem mora: fator \"casa nível 2\"")
	var IsoArt = load("res://scripts/iso/iso_art.gd")
	var ls: Array = IsoArt.layers(casa)
	check(ls.any(func(l): return l.has("tex") and l.tex != null and "nivel_2" in l.tex.resource_path), "desenho do nível 2")
	g("village_hub").level = 3
	check("pesquisa" in casa.upgrade_block_reason(), "nível 3 sem a pesquisa: %s" % casa.upgrade_block_reason())
	g("research")._finish("medicina")
	_dar_recursos()
	check(casa.upgrade_block_reason() == "", "com Medicina de campo: liberado")
	# cartão do menu: ativo, com custo do próximo
	var bm = g("hud")._build_menu
	var card: Dictionary = {}
	for d in bm._defs("Moradia"):
		if d.name == "Casa nível 2 e 3":
			card = d
	check(not card.is_empty() and not card.get("soon", false) and "próxima: nível" in card.cost.call(), "cartão do menu ativo: %s" % (card.cost.call() if not card.is_empty() else "-"))
	casa.start_upgrade()
	check(casa.upgrade_pending(), "ampliação pro 3 encomendada (vai no save em andamento)")
	var IsoArt2 = load("res://scripts/iso/iso_art.gd")
	check(IsoArt2.layers(casa).any(func(l): return l.has("tex") and l.tex != null and "obra_3" in l.tex.resource_path), "ampliando: andaime (obra_3) por cima")


func _depois_de_carregar() -> void:
	print("== depois de carregar")
	var c2: Node = null
	for c in main.get_tree().get_nodes_in_group("casas"):
		if c.global_position.distance_to(casa.global_position if is_instance_valid(casa) else Vector2.ZERO) < 2.0 or c.level >= 2:
			c2 = c
	check(c2 != null and c2.level == 2, "nível 2 voltou do save")
	check(c2 != null and c2.slot_count == c2.beds_for(2), "com as camas do nível 2")
	check(c2 != null and c2.upgrade_pending() and c2.upgrade_left > 0.0, "a ampliação pro 3 em andamento voltou")
	# save antigo (sem nível): nível 1
	var d: Dictionary = c2.get_save_data()
	d.erase("level")
	d.erase("upgrade_left")
	d.erase("upgrade_total")
	c2.load_save_data(d)
	check(c2.level == 1 and not c2.upgrade_pending() and c2.slot_count >= c2.beds_for(1), "save antigo: nível 1, sem obra")
