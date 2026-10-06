extends SceneTree
## Bloco 47: mais de um prédio dos que eram "um por vila". RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0


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


func n(group: String) -> int:
	return get_nodes_in_group(group).size()


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


## Bloco 74: o norte da vila (vazio) — longe do Centro, que cresce quando sobe de nível.
const LIVRE := Vector2(100, -600)


func free_spot(near: Vector2) -> Vector2:
	var placer = g("house_placer")
	placer._collect_blockers()
	placer._footprint = Rect2(-64, -104, 128, 124)  # (Bloco 74: a pegada de um prédio grande — um não encosta no outro)
	for r in range(1, 20):
		for a in range(16):
			var p: Vector2 = (near + Vector2.RIGHT.rotated(a * TAU / 16.0) * (60.0 + r * 28.0)).round()
			if placer.check_spot(p) == "":
				return p
	return Vector2.INF


func spot_in(rect: Rect2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	var c := rect.get_center()
	for r in range(0, 700, 12):  # (Bloco 74: a floresta é uma faixa comprida de norte a sul)
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if rect.has_point(q) and p.check_spot(q) == "":
				return q
	return Vector2.INF


## Lugar válido pro coletor: abre o posicionador DELE (pegada e área da clareira), acha e cancela.
func coletor_spot(hub, area: Rect2) -> Vector2:
	var placer = g("house_placer")
	if not hub.build_coletor():
		return Vector2.INF
	var q := spot_in(area)
	placer.cancel()
	return q


## A obra (canteiro) do tipo termina na hora — como se o engenheiro tivesse trabalhado.
func finish_canteiro(kind: String) -> bool:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			c.obra_work(c.left + 1.0)
			return true
	return false


func fill(eco, arm) -> void:
	eco.credits = 99999.0
	arm.stock["ferro"] = 5000.0
	arm.wood_stored = 5000.0
	arm.itens["barra_ferro"] = 5000.0  # Bloco 87: a partir do estágio da fornalha os custos migrados pedem barra
	arm._recount()


func menu_card(menu, tab: String, name: String) -> Dictionary:
	menu.visible = true  # (abrir uma janela fecha o menu)
	menu._show_tab(menu.TAB_NAMES.find(tab))
	menu.refresh()
	for c in menu._cards:
		if c.def.name == name:
			return c
	return {}


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 200.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in ws():
		w.hunger = w.hunger_max
	var hub = g("village_hub")
	var eco = main.get_node("Economy")
	var arm = g("armazens")
	var res = g("research")
	var def = g("defense")
	var mor = g("morale")
	var eq = g("equipment")
	var env = g("environment")
	if step == 0 and t > 2.0:
		step = 98  # (se der erro no meio, não repete tudo a cada quadro)
		fill(eco, arm)
		hub.level = 2  # laboratório pede vila nível 2
		var gr: float = eco.extra_building_cost_growth
		print("== Laboratório: o engenheiro ainda ergue; o 2º custa mais")
		var c1: Vector3i = res.lab_cost()
		check(c1 == Vector3i(res.lab_credits, res.lab_iron, res.lab_wood), "1º laboratório: custo base %s" % c1)
		var cr0: float = eco.credits
		check(res._confirm_lab(free_spot(LIVRE)), "1º laboratório encomendado")
		check(absf(cr0 - eco.credits - c1.x) < 0.5, "cobrou o custo do 1º")
		check(n("laboratorios") == 0 and res.lab_block_reason().begins_with("em obra"), "ainda é canteiro: precisa de engenheiro (%s)" % res.lab_block_reason())
		check(finish_canteiro("laboratorio") and n("laboratorios") == 1, "obra pronta: 1 laboratório")
		check(res.lab_block_reason() == "", "com 1 pronto, NÃO trava mais ('%s')" % res.lab_block_reason())
		var c2: Vector3i = res.lab_cost()
		check(c2 == Vector3i(roundi(c1.x * gr), roundi(c1.y * gr), roundi(c1.z * gr)), "2º custa x%.2f: %s" % [gr, c2])
		cr0 = eco.credits
		check(res._confirm_lab(free_spot(LIVRE)) and finish_canteiro("laboratorio"), "2º laboratório erguido")
		check(absf(cr0 - eco.credits - c2.x) < 0.5, "cobrou o custo maior do 2º")
		var labs: Array = res.labs()
		check(labs.size() == 2 and labs[0].name != labs[1].name, "2 laboratórios com nomes diferentes (%s, %s)" % [labs[0].name, labs[1].name])

		print("== menu: 'pode ter vários • tem N' e custo do PRÓXIMO antes de confirmar")
		var hud = main.get_node("HUD")
		hud.toggle_build_menu()
		var menu = hud._build_menu
		var lc := menu_card(menu, "Pesquisa", "Laboratório")
		print("  cartão: '%s' | '%s'" % [lc.tag.text, lc.cost.text])
		check("pode ter vários" in lc.tag.text and "tem 2" in lc.tag.text, "etiqueta mostra que pode ter vários e quantos tem")
		check(lc.cost.text == res.lab_cost_text() and ("%d cr" % res.lab_cost().x) in lc.cost.text, "custo do cartão = custo do 3º")
		check(not lc.button.disabled, "botão liberado")

		print("== Arsenal x2: forja só no principal (uma obra), cavalete compartilhado")
		check(def._confirm_arsenal(free_spot(LIVRE)) and finish_canteiro("arsenal"), "1º Arsenal")
		check(def.arsenal_block_reason() == "", "2º Arsenal liberado")
		check(def._confirm_arsenal(free_spot(LIVRE)) and finish_canteiro("arsenal"), "2º Arsenal")
		var ars: Array = def.arsenais()
		check(ars.size() == 2 and ars[0].is_forge() and not ars[1].is_forge(), "o 1º forja, o 2º é posto de armas")
		def.queue.append({"what": "forjar", "id": "lanca", "total": 20.0, "left": 20.0, "ordered_at": 1.0})
		check(ars[0].obra_pending() and not ars[1].obra_pending(), "a encomenda na fila vira UMA obra só")
		def.queue.clear()
		var ac := menu_card(menu, "Defesa e equipamento", "Arsenal")
		check("tem 2" in ac.tag.text and ac.cost.text == def.arsenal_cost_text(), "cartão do Arsenal: tem 2, custo do próximo (%s)" % ac.cost.text)

		print("== Campo de treino x2")
		check(def._confirm_campo(free_spot(LIVRE)) and finish_canteiro("campo"), "1º campo")
		check(def._confirm_campo(free_spot(LIVRE)) and finish_canteiro("campo"), "2º campo")
		check(def.campos().size() == 2, "2 campos")

		print("== Taverna x2: construir outra ≠ ampliar; ânimo não soma")
		check(mor._confirm_taverna(free_spot(LIVRE)) and finish_canteiro("taverna"), "1ª taverna")
		check(mor.taverna_build_reason() == "" and mor.taverna_upgrade_reason() == "", "dá pra construir outra E ampliar")
		check(mor._confirm_taverna(free_spot(LIVRE)) and finish_canteiro("taverna"), "2ª taverna")
		var tavs: Array = mor.tavernas()
		check(tavs.size() == 2, "2 tavernas")
		check(mor.upgrade_taverna() and finish_canteiro("taverna_up"), "ampliação encomendada e pronta")
		check(tavs[0].level == 2 and tavs[1].level == 1, "ampliou a 1ª (níveis %d/%d)" % [tavs[0].level, tavs[1].level])
		check(mor.taverna_to_upgrade() == tavs[1], "a próxima ampliação vai pra 2ª")
		var bonus := 0.0
		for f in mor.village_factors():
			if f[0] == "tem taverna":
				bonus += f[1]
		check(is_equal_approx(bonus, mor.taverna_bonus[1]), "ânimo 'tem taverna' = o da melhor (%.0f), não soma" % bonus)
		var tc := menu_card(menu, "Lazer", "Taverna")
		var tu := menu_card(menu, "Lazer", "Ampliar taverna")
		check("tem 2" in tc.tag.text and tc.cost.text == mor.taverna_cost_text() and tu.tag.text == "melhoria", "cartões separados: Taverna (vários) e Ampliar (melhoria)")

		print("== Coletor de madeira x2: cada um com o seu operador")
		var area: Rect2 = env.clearing_rect.grow(-30.0)
		# Bloco 81: o 1º é a ruína da floresta (restaurada); os extras só depois dela
		var fx = hub.coletor_fixo()
		check(fx != null and hub.coletor_block_reason() != "", "1º coletor é a ruína: outro só depois de restaurar ('%s')" % hub.coletor_block_reason())
		fx.restaura_tudo()
		check(hub.coletor_block_reason() == "", "2º coletor liberado ('%s')" % hub.coletor_block_reason())
		var s2 := coletor_spot(hub, area)
		check(s2.is_finite() and hub._confirm_coletor(s2) and finish_canteiro("coletor"), "2º coletor em %s" % s2)
		var cols: Array = hub.coletores()
		check(cols.size() == 2 and cols[0].global_position.distance_to(cols[1].global_position) > 50.0, "2 coletores em lugares diferentes")
		var a = ws()[1]
		var b = ws()[2]
		a.set_job("lenhador")
		b.set_job("lenhador")
		cols[0].designate(a)
		cols[1].designate(b)
		check(cols[0].operator == a and cols[1].operator == b, "cada máquina com o seu lenhador")
		cols[1].designate(a)
		check(cols[0].operator == null and cols[1].operator == a, "o mesmo lenhador numa 2ª máquina sai da 1ª")
		cols[0].designate(b)
		var panel = hud._panels["coletor"]
		hud.open_panel_for(cols[1])
		check(panel._current() == cols[1] and "2 de 2" in panel._title.text, "clicar na 2ª máquina abre a janela DELA (%s)" % panel._title.text)
		hud.open_panel("coletor")
		check(panel._current() == cols[0], "pela tecla/botão: a primeira")

		print("== Enfermaria extra")
		var main_inf = g("enfermarias")
		check(hub.enfermaria_block_reason() == "", "nova enfermaria liberada ('%s')" % hub.enfermaria_block_reason())
		var es := free_spot(LIVRE)
		check(es.is_finite() and hub._confirm_enfermaria(es) and n("enfermarias") == 1, "encomendada: ainda canteiro (em %s)" % es)
		check(finish_canteiro("enfermaria") and n("enfermarias") == 2, "pronta: 2 enfermarias")
		var extra = hub.extra_enfermarias()[0]
		check(extra.extra and not main_inf.extra and extra.primary() == main_inf and g("enfermarias") == main_inf, "a principal continua a primeira (memorial)")
		check(extra.beds_total() == main_inf.beds_total(), "mesmos leitos (a melhoria vale pra todas): %d" % extra.beds_total())
		var ic := menu_card(menu, "Saúde", "Nova enfermaria")
		check(not ic.button.disabled and "tem 2" in ic.tag.text and ic.cost.text == hub.enfermaria_cost_text(), "cartão 'Nova enfermaria' deixou de ser 'em breve'")
		hud.open_panel_for(extra)
		check(hud._panels["enfermaria"]._inf == extra, "clicar na extra abre a janela dela")

		print("== continuam únicos")
		check(eq.vestiario_block_reason() != "construído", "(antes) vestiário não existe")
		eq.finish_build("vestiario", free_spot(LIVRE))
		check(eq.vestiario() != null and eq.vestiario_block_reason() == "construído", "Vestiário: um por vila")
		var vc := menu_card(menu, "Defesa e equipamento", "Vestiário")
		check(vc.tag.text == "um por vila" and vc.button.disabled, "cartão do Vestiário: 'um por vila'")
		var ex := menu_card(menu, "Vila", "Expandir a vila")
		check(ex.tag.text.contains("um só"), "Centro da Vila: um só ('%s')" % ex.tag.text)
		menu.visible = false

		print("== save: tudo em listas")
		set_meta("snap", {"labs": res.labs().map(func(x): return x.global_position),
			"ars": def.arsenais().map(func(x): return x.global_position),
			"lv": mor.tavernas().map(func(x): return x.level),
			"col_b": cols[0].global_position, "col_a": cols[1].global_position,
			"a": a.display_name, "b": b.display_name, "extra": extra.global_position})
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		check(data.research.labs.size() == 2 and data.defense.arsenais.size() == 2 and data.defense.campos.size() == 2, "save: labs/arsenais/campos em lista")
		check(data.morale.tavernas.size() == 2 and data.village.coletores.size() == 2 and data.village.enfermarias_extra.size() == 1, "save: tavernas/coletores/enfermarias extras em lista")
		set_meta("data", data)
		root.get_node("SaveManager").load_game()
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 2.0:
		var snap: Dictionary = get_meta("snap")
		print("== depois do load")
		check(res.labs().map(func(x): return x.global_position) == snap.labs, "load: 2 laboratórios nos mesmos lugares")
		check(def.arsenais().map(func(x): return x.global_position) == snap.ars and def.campos().size() == 2, "load: 2 Arsenais e 2 campos")
		check(mor.tavernas().map(func(x): return x.level) == snap.lv, "load: 2 tavernas com os níveis (%s)" % str(snap.lv))
		check(n("enfermarias") == 2 and hub.extra_enfermarias()[0].global_position == snap.extra and g("enfermarias").extra == false, "load: enfermaria extra de volta, principal primeiro")
		var ops := {}
		for c in hub.coletores():
			ops[c.global_position] = c.operator.display_name if c.operator else "-"
		print("  operadores: ", ops)
		check(ops.get(snap.col_a, "") == snap.a and ops.get(snap.col_b, "") == snap.b, "load: cada lenhador voltou pra SUA máquina")
		print("== save antigo (chaves de um só)")
		var data: Dictionary = get_meta("data")
		data.research.erase("labs")
		data.research["lab"] = [snap.labs[0].x, snap.labs[0].y]
		data.defense.erase("arsenais")
		data.defense.erase("campos")
		data.defense["arsenal"] = [snap.ars[0].x, snap.ars[0].y]
		data.morale["taverna"] = data.morale.tavernas[0]
		data.morale.erase("tavernas")
		data.village["coletor"] = data.village.coletores[0]
		data.village.erase("coletores")
		data.village.erase("enfermarias_extra")
		for wd in data.workers:
			wd.erase("coletor_pos")
		var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(data))
		fw.close()
		root.get_node("SaveManager").load_game()
		step = 2
		t_mark = t
	elif step == 2 and t - t_mark > 2.0:
		check(res.labs().size() == 1 and def.arsenais().size() == 1 and def.campos().size() == 0, "save antigo: 1 laboratório, 1 Arsenal, sem campo")
		check(mor.tavernas().size() == 1 and hub.coletores().size() == 1 and n("enfermarias") == 1, "save antigo: 1 taverna, 1 coletor, só a enfermaria da vila")
		var c = hub.coletor()
		check(c.operator != null, "save antigo: um operador voltou pro coletor (%s)" % (c.operator.display_name if c.operator else "-"))
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
