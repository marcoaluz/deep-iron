extends SceneTree
## Bloco 70: conteúdo do S2 (ácido) e do S3 (lava). Poças e jazidas vêm dos dados do nível; poça sem
## traje atrasa e queima (ácido leve, lava pode ser grave), com traje não; cristal verde/rubro
## vendável e no HUD/armazém, liberado pela ferramenta; ventilador (pesquisa + nível 2 aberto) poupa a
## máscara, alivia o ácido e afina a névoa; Gosma e Magmante nas ondas certas, com os efeitos deles;
## escavadeira acha cristal e rende mais com o S3; telemetria; save/load. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const Niveis := preload("res://scripts/core/niveis.gd")
const Ores := preload("res://scripts/core/ores.gd")
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var _antes := {}


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


func world() -> Node:
	return g("village_hub").get_parent()


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 120.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 4.0:
				_dados()
				_minerios()
				_pocas()
				_ventilador()
				_criaturas()
				_escavadeira()
				_telemetria()
				_prepara_save()
				root.get_node("SaveManager").save_game("teste")
				step = 1
				t_mark = t
		1:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 2
				t_mark = t
		2:
			if t - t_mark > 4.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _dados() -> void:
	print("== dados dos níveis")
	var env = g("environment")
	var s2 := Niveis.por_id("S2")
	var s3 := Niveis.por_id("S3")
	check(s2.perigos.size() == 4 and s3.perigos.size() == 4, "S2 e S3 declaram 4 poças cada")
	var pocas: Array = main.get_tree().get_nodes_in_group("pocas_perigo")
	check(pocas.size() == s2.perigos.size() + s3.perigos.size(), "todas as poças no lugar (%d)" % pocas.size())
	var ok_area := true
	for p in pocas:
		var ok_kind: bool = (p.kind == "acido" and env.is_deep(p.global_position) and not env.is_abyss(p.global_position)) \
			or (p.kind == "lava" and env.is_abyss(p.global_position))
		ok_area = ok_area and ok_kind
	check(ok_area, "ácido no S2, lava no S3")
	var w := world()
	var j2: Array = []
	var j3: Array = []
	for i in 3:
		j2.append(w.get_node_or_null("JazidaS2_%d" % (i + 1)))
		j3.append(w.get_node_or_null("JazidaS3_%d" % (i + 1)))
	check(not j2.has(null) and j2.all(func(j): return j.ore_type == "cristal_verde"), "3 jazidas de cristal verde (nome fixo)")
	check(not j3.has(null) and j3.all(func(j): return j.ore_type == "cristal_rubro"), "3 jazidas de cristal rubro (nome fixo)")
	check(is_equal_approx(j3[0].ore_total, 80.0) and is_equal_approx(j3[0].MINE_RATE, 1.4), "total e ritmo vêm do .tres")
	check(not j2[0].is_unlocked() and not j3[0].is_unlocked(), "trancadas com o fundo fechado")
	var ofi = g("oficina")
	check(ofi.tool_for_ore("cristal_verde") == "broca" and ofi.tool_for_ore("cristal_rubro") == "traje", "ferramentas: broca (verde) e traje de chumbo (rubro)")


func _minerios() -> void:
	print("== minérios novos")
	var eco = g("economy")
	check(Ores.TYPES.has("cristal_verde") and Ores.TYPES.has("cristal_rubro"), "no catálogo")
	check(eco.price_of("cristal_verde") > eco.price_of("prata") and eco.price_of("cristal_rubro") > eco.price_of("solarita"), "valem mais que prata/solarita (%.0f, %.0f)" % [eco.price_of("cristal_verde"), eco.price_of("cristal_rubro")])
	var arm = g("armazens")
	arm.add_ore(10.0, "cristal_verde")
	arm.add_ore(5.0, "cristal_rubro")
	check(is_equal_approx(eco.stored_ore("cristal_verde"), 10.0), "armazém guarda cristal verde")
	var hud = g("hud")
	hud._refresh_top_bar(main.get_tree().get_nodes_in_group("ipezinhos"))
	var tip: String = hud._chips.ore.box.tooltip_text
	check("cristal verde 10" in tip and "cristal rubro 5" in tip, "aparecem no HUD")
	var c0: float = eco.credits
	var ganho: float = eco.sell("cristal_rubro")
	check(ganho >= 5.0 * eco.price_of("cristal_rubro") - 0.01 and eco.credits > c0, "vende (+%d cr)" % int(ganho))
	arm.add_ore(5.0, "cristal_rubro")


func _pocas() -> void:
	print("== poças sem e com traje")
	var fundo = g("fundo")
	var eq = g("equipment")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	var acido: Node2D = world().get_node("PocaS2_1")
	w.global_position = acido.global_position
	w._moving = false
	var v0: float = w._get_effective_speed()
	w._equip_tick(0.1)
	check(fundo.poca_at(w.global_position) == acido, "poca_at acha a poça")
	check(w._na_poca == acido and w._get_effective_speed() < v0 * 0.7, "sem máscara: devagar (%.0f -> %.0f)" % [v0, w._get_effective_speed()])
	for i in 60:
		w._equip_tick(0.1)
	check(w.injured and w.injury_cause == "acido" and w.injury_severity == "leve", "ficou 6 s: queimadura de ácido leve (%s %s)" % [w.injury_cause, w.injury_severity])
	check(int(fundo.queimaduras.acido) == 1, "contou a queimadura")
	# lava: queima mais rápido
	var w2 = main.get_tree().get_nodes_in_group("ipezinhos")[1]
	var lava: Node2D = world().get_node("PocaS3_1")
	w2.global_position = lava.global_position
	for i in 26:
		w2._equip_tick(0.1)
	check(w2.injured and w2.injury_cause == "lava", "lava: queimou em 2,5 s")
	# com o traje: pega no vestiário ao pisar e nada acontece
	var w3 = main.get_tree().get_nodes_in_group("ipezinhos")[2]
	eq.spawn_vestiario(g("village_hub").global_position + Vector2(160, 40))
	eq.pool["gas"].append(eq.max_durability("gas"))
	w3.global_position = acido.global_position
	w3._equip_tick(0.1)
	check(w3.wearing.has("gas"), "pisou com máscara no vestiário: vestiu")
	var v3: float = w3._get_effective_speed()
	for i in 80:
		w3._equip_tick(0.1)
	check(not w3.injured and w3._na_poca == null and is_equal_approx(w3._get_effective_speed(), v3), "com máscara: nem queima nem atrasa")
	var gasto: float = eq.max_durability("gas") - float(w3.wearing.gas)
	check(gasto > 0.0, "a máscara gastou (%.1f)" % gasto)
	_antes["gasto_mascara"] = gasto
	_antes["w3"] = w3


func _ventilador() -> void:
	print("== ventilador (S2)")
	var fundo = g("fundo")
	var res = g("research")
	check("Ventilação" in fundo.ventilador_block_reason(), "sem a pesquisa: %s" % fundo.ventilador_block_reason())
	res._finish("ventilacao")
	check("nível 2" in fundo.ventilador_block_reason(), "com a pesquisa e o S2 fechado: %s" % fundo.ventilador_block_reason())
	g("elevador").unlock(false)
	g("economy").credits = 5000.0
	g("armazens").add_ore(200.0, "prata")
	g("armazens").wood_stored = 200.0
	check(fundo.ventilador_block_reason() == "", "liberado (%s)" % fundo.ventilador_block_reason())
	# onde pode: dentro do nível 2, fora da superfície
	var placer = g("house_placer")
	check(fundo.build_ventilador() and placer.active, "abre o posicionador")
	var env = g("environment")
	var livre := Vector2(250, 1100)
	check(placer.check_spot(livre) == "", "chão do nível 2 serve (%s)" % placer.check_spot(livre))
	check(placer.check_spot(g("village_hub").global_position + Vector2(200, 0)) != "", "na superfície não (%s)" % placer.check_spot(g("village_hub").global_position + Vector2(200, 0)))
	check(placer.has_method("cancel"), "dá pra cancelar")
	placer.cancel()
	# monta direto (a obra é a de sempre do engenheiro: Canteiro)
	var acido: Node2D = world().get_node("PocaS2_2")
	var v = fundo.spawn_ventilador(acido.global_position + Vector2(0, -90))
	check(v.is_in_group("ventiladores") and fundo.ventiladores().size() == 1, "ventilador no nível 2")
	check(is_equal_approx(fundo.ventilacao_mult(acido.global_position), 0.5) and is_equal_approx(fundo.ventilacao_mult(Vector2(-450, 1250)), 1.0), "alcance: 50% perto, nada longe")
	check(is_equal_approx(fundo.nevoa_mult(), 1.0 - fundo.ventilador_nevoa), "névoa do S2 afina (%.2f)" % fundo.nevoa_mult())
	var iso = main.get_node("IsoView")
	var a2: Dictionary = {}
	for a in iso._atmos:
		if a.nivel.id == "S2":
			a2 = a
	check(not a2.is_empty() and is_equal_approx(a2.nevoa.color.a, a2.alfa * fundo.nevoa_mult()), "a vista iso usa a névoa afinada (%.3f)" % (a2.nevoa.color.a if not a2.is_empty() else -1.0))
	# o ácido perto do ventilador arde na metade do ritmo
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w.injured = false  # (o mesmo da queimadura de antes, curado)
	w.injury_cause = ""
	w.injury_severity = ""
	w._poca_expo = 0.0
	w.global_position = acido.global_position
	for i in 60:
		w._equip_tick(0.1)
	check(not w.injured and w._poca_expo > 2.5 and w._poca_expo < 3.5, "perto do ventilador: 6 s valem 3 (%.1f)" % w._poca_expo)
	# a máscara gasta a metade perto dele
	var eq = g("equipment")
	var w3 = _antes.w3
	var antes: float = w3.wearing.gas
	w3.global_position = acido.global_position
	for i in 80:
		w3._equip_tick(0.1)
	var gasto: float = antes - float(w3.wearing.gas)
	check(absf(gasto - _antes.gasto_mascara * 0.5) < 0.2, "máscara gasta metade perto do ventilador (%.1f x %.1f)" % [gasto, _antes.gasto_mascara])


func _criaturas() -> void:
	print("== criaturas do fundo")
	var def = g("defense")
	check(def.fundo_count("gosma", 1) == 0 and def.fundo_count("gosma", 2) == 1 and def.fundo_count("gosma", 20) == def.gosma_max, "gosma: a partir da onda 2 com o S2 aberto (até %d)" % def.gosma_max)
	check(def.fundo_count("magmante", 5) == 0, "magmante: só com o S3 aberto")
	g("elevador_abismo").unlocked = true
	check(def.fundo_count("magmante", 3) == 1, "S3 aberto: magmante a partir da onda 3")
	var gos = def._spawn("gosma")
	check(gos.kind == "gosma" and gos.gate_id == "poco" and gos.weapon_corrode > 1.0 and gos.barricade_mult > 1.0, "Gosma: sobe pelo poço, corrói arma, derrete barricada")
	var arm = g("armazens")
	arm.add_ore(20.0, "ferro")
	var fe0: float = arm.stock.ferro
	var cv0: float = arm.stock.cristal_verde
	gos._attack(arm)
	check(arm.stock.ferro < fe0 and is_equal_approx(arm.stock.cristal_verde, cv0) and not gos.looted, "no armazém a Gosma dissolve o metal (%.0f -> %.0f)" % [fe0, arm.stock.ferro])
	var Bon := preload("res://scripts/iso/iso_bonecos.gd")
	check(String(Bon.criatura_pose(gos, 0, true).get("pasta", "")) == "criatura_gosma", "Gosma com a arte iso")
	var mag = def._spawn("magmante")
	check(String(Bon.criatura_pose(mag, 1, false).get("pasta", "")) == "criatura_magmante", "Magmante com a arte iso")
	check(mag.kind == "magmante" and mag.max_hp > gos.max_hp * 2.0 and mag.speed < gos.speed, "Magmante: duro e lento (%.0f hp)" % mag.max_hp)
	mag.drop_chance = 1.0
	var cr0: float = arm.stock.cristal_rubro
	mag.take_hit(9999.0, null)
	check(arm.stock.cristal_rubro >= cr0 + float(mag.drop_amount) - 0.01, "derrubado: deixa cristal rubro (+%d)" % mag.drop_amount)
	gos.die(false)
	check(g("diary").has_page("gosmas") and g("diary").has_page("magmantes"), "páginas no diário")


func _escavadeira() -> void:
	print("== escavadeira no fundo")
	var fundo = g("fundo")
	check(is_equal_approx(fundo.broca_mult(), fundo.broca_s3_mult), "S3 aberto: broca rende x%.2f" % fundo.broca_mult())
	var r0: float = fundo.broca_cristal_rubro
	fundo.broca_cristal_rubro = 1.0
	check(fundo.cristal_da_broca() == "cristal_rubro", "a broca acha cristal rubro")
	fundo.broca_cristal_rubro = 0.0
	var v0: float = fundo.broca_cristal_verde
	fundo.broca_cristal_verde = 1.0
	check(fundo.cristal_da_broca() == "cristal_verde", "e cristal verde")
	fundo.broca_cristal_verde = v0
	fundo.broca_cristal_rubro = r0
	var esc = g("escavadeira")
	check(esc.has_method("_fundo_mult") and is_equal_approx(esc._fundo_mult(), fundo.broca_s3_mult), "a escavadeira usa o bônus")


func _telemetria() -> void:
	print("== telemetria")
	var tel = g("telemetria")
	if tel == null:
		tel = load("res://scripts/core/telemetria.gd")
		check(tel.COLUNAS.has("queimaduras_acido") and tel.COLUNAS.has("cristal_rubro"), "colunas novas")
		return
	check(tel.COLUNAS.has("queimaduras_acido") and tel.COLUNAS.has("cristal_rubro") and tel.COLUNAS.has("ventiladores"), "colunas novas")
	tel.registra()
	var f := FileAccess.open(tel.arquivo, FileAccess.READ)
	var linhas := f.get_as_text().strip_edges().split("\n") if f else PackedStringArray()
	check(linhas.size() >= 2 and linhas[linhas.size() - 1].split(",").size() == tel.COLUNAS.size(), "linha com todas as colunas")


func _prepara_save() -> void:
	var j = world().get_node("JazidaS2_2")
	j.ore_remaining = 37.0
	_antes["ore"] = 37.0
	_antes["cristal_verde"] = g("armazens").stock.cristal_verde
	_antes["queimaduras"] = g("fundo").queimaduras.duplicate()
	_antes["ventiladores"] = g("fundo").ventiladores().size()


func _carregado() -> void:
	print("== depois de carregar")
	var fundo = g("fundo")
	check(fundo.ventiladores().size() == _antes.ventiladores, "ventiladores voltaram (%d)" % fundo.ventiladores().size())
	check(fundo.queimaduras == _antes.queimaduras, "contadores voltaram (%s)" % str(fundo.queimaduras))
	check(is_equal_approx(g("armazens").stock.cristal_verde, _antes.cristal_verde), "estoque de cristal verde (%.0f)" % g("armazens").stock.cristal_verde)
	var j = world().get_node_or_null("JazidaS2_2")
	check(j != null and absf(j.ore_remaining - _antes.ore) < 2.5, "jazida do .tres volta pelo nome (%.0f; regenera devagar)" % (j.ore_remaining if j else -1.0))
	check(main.get_tree().get_nodes_in_group("pocas_perigo").size() == 8, "poças sem duplicar")
	var nomes := {}
	for m in main.get_tree().get_nodes_in_group("minerios"):
		nomes[m.name] = nomes.get(m.name, 0) + 1
	check(nomes.values().all(func(n): return n == 1), "jazidas sem duplicar")
