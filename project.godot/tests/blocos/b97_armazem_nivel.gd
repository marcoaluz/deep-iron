extends SceneTree
## Bloco 97: o ARMAZÉM COM LIMITE e níveis até 3. Capacidade = tudo junto (400 / 1000 / 2000); cheio: quem vem
## entregar espera com a carga (balão "armazém cheio" e alerta), o armazém recusa quem vem entregar, a máquina para de
## mandar; devolução entra mesmo cheio (nada some); ampliar é obra de engenheiro com material (Bloco 96) e a
## capacidade sobe; o ARMAZÉM NOVO (estágio 2, o jogador escolhe o lugar) é construção por canteiro e volta no
## save; save antigo = nível 1 e fica com o que tem. RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var mineiro: Node = null
var novo_nome := ""


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


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 600, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func termina_obra(o: Node) -> void:
	var site = ObraSite.de(o)
	if site:
		for k in site.necessario:
			site.entregar(k, float(site.necessario[k]))
	o.obra_work(9999.0)


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 200.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	var eco = g("economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	if step == 0 and t > 3.0:
		step = 1
		print("== A) capacidade por nível (tudo junto)")
		# Bloco 106: o limite é por COMPARTIMENTO; o de minério continua 400 / 1000 / 2000
		check(arm.cap_minerios == [400.0, 1000.0, 2000.0] and arm.nivel == 1 and arm.capacidade_cat("minerios") == 400.0, "nível 1: cabem 400 de minério")
		for k in arm.stock:
			arm.stock[k] = 0.0
		arm.itens.clear()
		arm.raw_stored = 0.0
		arm.leather_stored = 0.0
		arm.wood_stored = 100.0
		arm.stock["ferro"] = 200.0
		arm._recount()
		eco.add_item("prego", 20.0)
		check(is_equal_approx(arm.usado(), 320.0) and is_equal_approx(arm.espaco_cat("minerios"), 200.0) and is_equal_approx(arm.usado_cat("manufaturados"), 20.0),
			"usado = madeira + minério + itens (%d; cabe mais %d de minério)" % [int(arm.usado()), int(arm.espaco_cat("minerios"))])
		print("== B) cheio: o minerador espera com a carga (balão e alerta)")
		arm.stock["ferro"] = 395.0  # (Bloco 106: o compartimento de minério com 395: cabem só 5)
		for p in get_nodes_in_group("pontos_carga"):
			p.parar_por_area(true, "teste")
		arm._recount()
		mineiro = get_nodes_in_group("ipezinhos")[0]
		mineiro.set_job("minerador")
		mineiro.cargo_type = "ferro"
		mineiro.carrying = mineiro.capacidade_carga()
		Engine.time_scale = 4.0
		t_mark = t
		return false
	if step == 1 and t - t_mark > 40.0:
		Engine.time_scale = 1.0
		step = 2
		print("  usado %d de %d, mão do minerador %.1f, estado %s, motivo '%s'" % [arm.usado(), arm.capacidade(), mineiro.carrying, mineiro.get_state(), mineiro.motivo_parado()])
		check(arm.usado_cat("minerios") <= arm.capacidade_cat("minerios") + 0.01, "não passou do limite (%d de %d)" % [int(arm.usado_cat("minerios")), int(arm.capacidade_cat("minerios"))])
		check(arm.cheio_cat("minerios"), "encheu (o minério)")
		check(mineiro.carrying > 0.5, "o minerador ficou com o resto da carga (%.1f)" % mineiro.carrying)
		check(mineiro.motivo_parado() == "armazem_cheio", "balão de motivo: armazém cheio ('%s')" % mineiro.motivo_parado())
		check(mineiro._entrega_pendente() == "", "fora do expediente, a carga não prende: vai pro festival/funeral/cama e entrega depois")
		var hud = main.get_node("HUD")
		hud._refresh()
		check(hud._alertas.ativos().has("armazem_cheio"), "alerta 'armazém cheio' na coluna")
		check(mineiro.get_state() == "esperando_espaco", "cheio: ele não fica na porta, espera disponível (Bloco 106: %s)" % mineiro.get_state())
		print("== C) a máquina para; devolução entra mesmo cheio")
		var col = g("coletores")
		if col and col.has_method("_deliver"):
			var w_antes: float = arm.wood_stored
			arm.wood_stored = arm.capacidade_cat("madeira")  # (Bloco 106: o compartimento de madeira cheio)
			if col.has_method("restaurado") and not col.restaurado():
				col.restaura_tudo()  # (a ruína não produz: aqui ele restaurado)
			col._process(0.1)
			check(col._sem_espaco, "o coletor de madeira para com a madeira cheia (antes de produzir)")
			arm.wood_stored = w_antes
		var m0: float = arm.wood_stored
		eco.devolve("madeira", 10.0)
		check(is_equal_approx(arm.wood_stored, m0 + 10.0), "devolução entra mesmo cheio (nada some)")
		var cart = load("res://scripts/props/estacao_vagonete.gd")
		check(cart != null and "_sem_espaco" in cart.new(), "o vagonete sabe esperar com o armazém cheio")
		print("== D) ampliar: obra de engenheiro com material; a capacidade sobe")
		check(arm.ampliar_motivo().begins_with("precisa da vila"), "nível 2 pede a vila no estágio 2 ('%s')" % arm.ampliar_motivo())
		hub.level = 2
		eco.credits = 9999.0
		arm.stock["ferro"] = 300.0
		arm.wood_stored = 200.0
		arm._recount()
		eco.add_item("barra_ferro", 40.0)  # (no estágio da fornalha o ferro vira barra)
		var c0: float = eco.credits
		check(arm.ampliar() and arm.ampliando and arm.nivel == 1 and arm.is_in_group("obras"), "ampliação encomendada: vira obra (nível 1 até acabar)")
		check(is_equal_approx(eco.credits, c0 - 250.0) and ObraSite.de(arm).tem_material(), "créditos na hora; material reservado %s" % str(ObraSite.de(arm).necessario))
		termina_obra(arm)
		check(arm.nivel == 2 and arm.capacidade_cat("minerios") == 1000.0 and not arm.ampliando, "nível 2: cabem 1000 de minério")
		# Bloco 106: com espaço ele não está mais bloqueado (na próxima decisão sai do "esperando espaço" e o balão some)
		check(not mineiro._sem_espaco("minerios") and arm.espaco_cat("minerios") >= 1.0, "com espaço, ele não está mais bloqueado (o balão some na próxima decisão)")
		print("== E) armazém novo: estágio 2, o jogador escolhe o lugar, canteiro, obra")
		hub.level = 1
		check(hub.armazem_block_reason().begins_with("precisa da vila"), "armazém novo só no estágio 2 ('%s')" % hub.armazem_block_reason())
		hub.level = 2
		check(hub.armazem_block_reason() == "", "estágio 2: liberado")
		var pos := spot_near(hub.global_position + Vector2(-200, 120))
		check(hub._confirm_armazem(pos), "encomendado no lugar escolhido")
		var cant: Node = null
		for c in get_nodes_in_group("canteiros"):
			if c.kind == "armazem":
				cant = c
		check(cant != null and ObraSite.de(cant).tem_material(), "canteiro do armazém novo, com material")
		var n0 := get_nodes_in_group("armazens").size()
		termina_obra(cant)
		t_mark = t
		step = 3
		return false
	if step == 3 and t - t_mark > 0.5:
		step = 4
		var arms := get_nodes_in_group("armazens")
		var novo: Node = null
		for a in arms:
			if a.construido:
				novo = a
		check(novo != null and arms.size() == 2, "o armazém novo nasceu (%d armazéns)" % arms.size())
		check(novo != null and novo.nivel == 1 and novo.capacidade_cat("minerios") == 400.0, "começa no nível 1")
		novo.wood_stored = 33.0
		novo._recount()
		novo_nome = String(novo.name)
		var bm = main.get_node("HUD")._build_menu
		var tem := false
		for d in bm._defs("Vila"):
			if d.name == "Armazém novo" or d.name == "Ampliar armazém":
				tem = true
				check(ResourceLoader.exists(d.img), "cartão '%s' com imagem" % d.name)
		check(tem, "cartões no CONSTRUIR (aba Vila)")
		print("== F) save e carregar: o armazém novo, o nível e o estoque voltam")
		root.get_node("SaveManager").save_game("manual")
		root.get_node("SaveManager").load_game()
		t_mark = t
		return false
	if step == 4 and t - t_mark > 4.0:
		step = 5
		var arms := get_nodes_in_group("armazens")
		var novo: Node = null
		var velho: Node = null
		for a in arms:
			if a.construido:
				novo = a
			else:
				velho = a
		check(arms.size() == 2 and novo != null and String(novo.name) == novo_nome, "voltou com os 2 armazéns")
		check(velho != null and velho.nivel == 2, "o armazém da mina continua no nível 2")
		check(novo != null and is_equal_approx(novo.wood_stored, 33.0), "o estoque do novo voltou (%s)" % (str(novo.wood_stored) if novo else "-"))
		print("== G) save antigo: nível 1 e fica com o que tem (mesmo passando)")
		var a2 = velho
		a2.load_save_data({"stock": {"ferro": 900.0}, "wood_stored": 50.0})
		check(a2.nivel == 1 and is_equal_approx(a2.usado(), 950.0) and a2.cheio_cat("minerios"), "save antigo: nível 1, com os 950 (o minério cheio, não recebe mais)")
		print("\nFALHAS: %d" % fails)
		return true
	return false
