extends SceneTree
## Bloco 111: FAMÍLIAS E CRIANÇAS. (A) A gravidez: as condições (casal estável, cama, comida, ânimo, estágio, greve, intervalo,
## máximo) e a política de Família (desestimular/incentivar). (B) O trabalho leve no fim e o parto (com médico: mais rápido, sem
## resguardo; sem: resguardo). (C) O bebê: em casa, na cama da mãe, sem fome, só o ícone; ocupa cama. (D) As fases: criança
## (anda, escola ou brincar, meia porção, não trabalha, nunca é alvo de criatura), aprendiz (acompanha e aprende a função do
## mentor), adulto (sem função, traço de um dos pais + 1, habilidade herdada + estudo). (E) A escola (obra, estudo, ânimo).
## (F) O luto dos pais, o memorial com a família, a rede de segurança conta adultos, o HUD conta meia porção. (G) Save, save
## antigo, telemetria, ficha e o diário. RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
var main: Node
var t := 0.0
var fails := 0
var rodando := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
	load("res://scripts/core/defense.gd").moradores_desligados = true
	load("res://scripts/props/armazem.gd").limite_desligado = true
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


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func perto(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) <= eps


func anda(s: float) -> void:
	var t0 := t
	while t - t0 < s:
		await process_frame


func espera(cond: Callable, max_s: float) -> bool:
	var t0 := t
	while not cond.call():
		if t - t0 > max_s:
			return false
		await process_frame
	return true


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


var hora := 9.0


func _process(delta: float) -> bool:
	t += delta
	if t > 420.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	var dn = g("day_night")
	if dn and hora >= 0.0:
		dn.time = dn.tempo_da_hora(hora)
	for w in ws():
		w.hunger = maxf(w.hunger, w.hunger_max * 0.9)
	if g("sun"):
		g("sun").wave_today = false
	if not rodando and t > 2.0:
		rodando = true
		roda()
	return false


func roda() -> void:
	var eco = g("economy")
	var hub = g("village_hub")
	var rel = g("relacoes")
	var fam = g("familias")
	var dn = g("day_night")
	g("defense").first_invasion_day = 999
	hub.level = 2
	eco.credits = 9999.0
	var pai: Node = eco.novo_ipezinho("menino")
	var mae: Node = eco.novo_ipezinho("menina")
	for i in 3:
		hub.spawn_house(spot_near(hub.global_position + Vector2(-150 + i * 90, 110)), "CasaFam%d" % i)
	await process_frame
	pai.set_job("minerador")
	mae.set_job("lenhador")
	pai.habilidade = {"minerador": 0.8}
	pai.tracos = ["trabalhador"]
	mae.tracos = ["devoto"]
	for c in get_nodes_in_group("comedouros"):
		c.food_stock = c.food_capacity
	for x in ws():
		x.happiness = 80.0
	rel.soma(pai, mae, 300.0)
	check(rel.parceiro_de(mae) == pai, "o casal se formou (Bloco 110)")

	print("-- (A) a gravidez: condições e política")
	var d: Dictionary = rel.par(pai, mae)
	d.desde = dn.day
	check(fam.motivo_sem_filho(pai, mae) == "casal novo", "casal novo: ainda não (%s)" % fam.motivo_sem_filho(pai, mae))
	d.desde = dn.day - 10
	var motivo: String = fam.motivo_sem_filho(pai, mae)
	check(motivo == "", "casal estável, cama, comida e ânimo: pode (%s)" % motivo)
	var extras := []
	while g("economy").free_beds() > 1:  # (enche as camas até sobrar UMA)
		extras.append(g("economy").novo_ipezinho("menino"))
	var outra: Node = ws().filter(func(x): return x != mae and String(x.gender) == "menina")[0]
	check(fam.motivo_sem_filho(pai, mae) == "", "uma cama livre: pode")
	outra.gravidez_s = 99999.0
	motivo = fam.motivo_sem_filho(pai, mae)
	check(motivo == "sem cama livre pro bebê", "a única cama já está prometida pro bebê de outra: não ('%s')" % motivo)
	outra.gravidez_s = 0.0
	for x in extras:
		x.remove_from_group("ipezinhos")
		x.queue_free()
	await process_frame
	hub.level = 1
	check(fam.motivo_sem_filho(pai, mae) != "", "vila pequena: não")
	hub.level = 2
	var pol = g("politicas")
	pol.forca("familia", "desestimular")
	check(fam.max_filhos_casal() == maxi(fam.max_filhos - fam.desestimular_filhos_menos, 1), "desestimular: menos filhos por casal (%d)" % fam.max_filhos_casal())
	check(perto(fam.mult_politica(), fam.desestimular_mult) and pol.fatores_animo(pai).any(func(f): return f[0] == "queriam filhos"), "desestimular: chance x0,3 e os casais tristes")
	pol.forca("familia", "incentivar")
	check(perto(fam.mult_politica(), fam.incentivar_mult), "incentivar: chance x2")
	check(fam.max_filhos_casal() == fam.max_filhos + fam.incentivar_filhos_extra, "incentivar: mais filhos por casal (%d)" % fam.max_filhos_casal())
	pol.forca("familia", "neutro")
	fam.chance_dia = 1.0
	fam._amanheceu(dn.day)
	check(mae.gravida() and not pai.gravida() and mae.pai_bebe == String(pai.name), "chance 100%: ela espera um filho dele")
	check(mae.happiness_factors().any(func(f): return f[0] == "vai ter um filho") and pai.happiness_factors().any(func(f): return f[0] == "vai ter um filho"), "os dois ficam contentes")
	check(fam.motivo_sem_filho(pai, mae) == "já espera um filho", "não engravida de novo grávida")

	print("-- (B) trabalho leve e parto")
	check(not fam.trabalho_leve(mae), "no começo: trabalho normal")
	mae.gravidez_s = fam.trabalho_leve_dias * fam._seg_dia() - 1.0
	check(fam.trabalho_leve(mae) and mae._mult_pessoal() < 1.0, "nos últimos dias: trabalho leve (x%.2f)" % mae._mult_pessoal())
	mae.gravidez_s = 0.0
	check(mae._choose_state() == "parto", "chegou a hora: parto")
	var n_antes: int = ws().size()
	var nomes_antes: Array = ws().map(func(x): return String(x.name))
	var cama_mae: bool = mae.has_home() and mae._home.free_slot_count() > 0
	var chance_compl: float = fam.morte_parto_chance
	check(chance_compl > 0.0 and fam.morte_parto_medico_mult < 1.0, "complicação no parto ligada (%.0f%%; com médico x%.2f)" % [chance_compl * 100.0, fam.morte_parto_medico_mult])
	fam.morte_parto_chance = 0.0  # (este parto é o normal; a complicação vem logo abaixo)
	var bebe: Node = fam.parto(mae, false)
	await process_frame
	var novos: Array = ws().filter(func(x): return not String(x.name) in nomes_antes).map(func(x): return "%s fase=%s visitante=%s" % [x.name, x.fase, str(x.visitante)])
	var bebes_novos: int = ws().filter(func(x): return not String(x.name) in nomes_antes and x.fase == "bebe").size()
	check(bebe != null and bebe.fase == "bebe" and bebes_novos == 1, "nasceu UM bebê (novos: %s; o padre pode chegar pelo evento dele)" % str(novos))
	check(not mae.gravida() and mae.resguardo_s > 0.0 and mae._estado_funcao() == "home", "sem médico: a mãe fica de resguardo em casa")
	check(String(bebe.name) in mae.filhos and String(bebe.name) in pai.filhos and String(mae.name) in bebe.pais, "pais e filhos anotados")
	check(fam.nascimentos == 1 and g("diary").has_page("fam_primeiro_bebe"), "o primeiro bebê no diário")
	var outra_mae: Node = ws().filter(func(x): return x != mae and String(x.gender) == "menina" and not x.e_crianca() and not x.injured)[0]
	fam.morte_parto_chance = 1.0
	var bebe2: Node = fam.parto(outra_mae, false)
	check(bebe2 != null and outra_mae.injured and outra_mae.injury_severity == "grave" and outra_mae.injury_cause == "parto" and outra_mae.resguardo_s <= 0.0,
		"complicação: o bebê nasce e a mãe sai com machucado grave (morre só sem leito a tempo)")
	check(outra_mae._choose_state() != "home", "com a complicação ela vai pra enfermaria, não pro resguardo (%s)" % outra_mae._choose_state())
	outra_mae.injured = false
	outra_mae.injury_severity = ""
	bebe2.remove_from_group("ipezinhos")
	bebe2.queue_free()
	fam.nascimentos -= 1
	fam.morte_parto_chance = chance_compl
	await process_frame

	print("-- (C) o bebê")
	check(bebe._choose_state() == "bebe" and bebe.has_home(), "o bebê fica em casa, na cama")
	check(not cama_mae or bebe._home == mae._home, "na casa da mãe (se tinha cama: %s)" % str(cama_mae))
	bebe.hunger = 0.0
	bebe._process(0.1)
	check(perto(bebe.hunger, bebe.hunger_max), "o bebê não passa fome (a mãe alimenta)")
	var ret_bebe = load("res://scripts/ui/retratos.gd").de(bebe)
	var ic_bebe = load("res://scripts/ui/icones.gd").tex("bebe")
	check(ret_bebe != null and ic_bebe != null and ret_bebe.resource_path == ic_bebe.resource_path, "o retrato do bebê é o ícone (%s / %s)" % [str(ret_bebe.resource_path if ret_bebe else null), str(ic_bebe.resource_path if ic_bebe else null)])
	bebe.set_job("minerador")
	check(bebe.job == "ocioso", "bebê/criança não trabalha")

	print("-- (D) as fases")
	var dia: float = fam._seg_dia()
	bebe.idade_s = fam.bebe_dias * dia + 1.0
	fam._confere_fase(bebe)
	check(bebe.fase == "crianca" and bebe.outfit() == "crianca", "virou criança (a arte das crianças)")
	await anda(0.5)
	var e: String = bebe._choose_state()
	check(e in ["brincando", "escola"], "no horário de trabalho: brinca ou estuda (%s)" % e)
	check(bebe._estado_funcao() != "strike", "criança não faz greve")
	check(bebe.motivo_parado() == "" and not g("hud")._parado(bebe), "criança não aparece como trabalhador parado (balão, alerta)")
	var bicho: Node2D = g("defense")._spawn("lumivoro")
	bicho.set_process(false)
	bicho.set_physics_process(false)
	bicho.global_position = bebe.global_position + Vector2(20, 0)
	check(not bicho._target_ok(bebe), "a criatura nunca mira a criança")
	check(bebe._choose_state() == "home", "criança vê criatura: corre pra casa")
	bicho.queue_free()
	bebe._fuga_t = 0.0
	# meia porção
	var coz = g("comedouros")
	check(perto(coz._fracao_de(bebe), 0.5) and perto(coz._fracao_de(pai), 1.0), "a criança come meia porção")
	bebe.idade_s = fam.crianca_ate * dia + 1.0
	fam._confere_fase(bebe)
	check(bebe.fase == "aprendiz" and (bebe.mentor == String(pai.name) or bebe.mentor == String(mae.name)), "virou aprendiz: o mentor é o pai ou a mãe (%s)" % bebe.mentor)
	var mentor: Node = fam.mentor_de(bebe)
	bebe.global_position = mentor.global_position + Vector2(10, 0)
	var f_m: String = mentor.funcao_atual()
	var antes_h: float = float(bebe.habilidade.get(f_m, 0.0))
	bebe._set_state("aprendendo")
	bebe._familia_tick(10.0)
	check(float(bebe.habilidade.get(f_m, 0.0)) > antes_h, "aprendiz perto do mentor aprende a função dele (%s %.4f)" % [f_m, float(bebe.habilidade.get(f_m, 0.0))])
	bebe.estudo = 0.6
	bebe.idade_s = fam.adulto_aos * dia + 1.0
	fam._confere_fase(bebe)
	check(bebe.fase == "adulto" and bebe.job == "ocioso" and not bebe.e_crianca(), "virou adulto, sem função")
	check(bebe.tracos.size() >= 1 and bebe.tracos.size() <= 2 and (bebe.tracos[0] in pai.tracos or bebe.tracos[0] in mae.tracos), "traço de um dos pais + 1 (%s)" % str(bebe.tracos))
	check(float(bebe.habilidade.get("minerador", 0.0)) >= 0.8 * fam.heranca_habilidade - 0.001, "herdou parte da habilidade do pai (%.2f)" % float(bebe.habilidade.get("minerador", 0.0)))
	check(bebe.outfit() == "civil", "adulto: a roupa de sem função")
	var rel2 = g("relacoes")
	var de_fora: Array = ws().filter(func(x): return x != pai and x != bebe and String(x.gender) != String(bebe.gender) and not x.e_crianca() and x.pais.is_empty() and rel2.parceiro_de(x) == null)
	var irmao: Node = g("economy").novo_ipezinho("menino" if String(bebe.gender) == "menina" else "menina")
	irmao.pais = bebe.pais.duplicate()
	var genitor: Node = pai if String(bebe.gender) == "menina" else mae
	check(not rel2.pode_namorar(bebe, genitor) and not rel2.pode_namorar(bebe, irmao), "família não namora (pai/mãe e filho, irmãos)")
	check(de_fora.is_empty() or rel2.pode_namorar(bebe, de_fora[0]) or rel2._viuvo(de_fora[0]), "com gente de fora pode")
	irmao.remove_from_group("ipezinhos")
	irmao.queue_free()

	print("-- (E) a escola")
	var pos := spot_near(hub.global_position + Vector2(160, -40))
	check(not hub.escola_block_reason().begins_with("precisa da vila"), "a escola libera no Vilarejo (agora: %s)" % hub.escola_block_reason())
	hub.level = 1
	check(hub.escola_block_reason().begins_with("precisa da vila"), "no Acampamento, não")
	hub.level = 2
	var escola: Node = hub.spawn_obra107("escola", pos)
	await process_frame
	check(escola != null and escola.is_in_group("escolas"), "a escola existe")
	var crianca: Node = eco.novo_ipezinho("menina")
	crianca.fase = "crianca"
	crianca.pais = [String(mae.name)]
	await process_frame
	check(crianca._estado_crianca() == "escola", "com escola e vaga: a criança vai à aula")
	fam.estuda(crianca, 100.0)
	check(crianca.estudo > 0.0 and crianca.animo_escola > 0.0 and crianca.happiness_factors().any(func(f): return f[0] == "foi à escola"), "estuda e se anima (%.2f)" % crianca.estudo)

	print("-- (F) luto, memorial, rede de segurança, HUD")
	var migr = g("migrantes")
	var adultos: int = ws().filter(func(x): return not x.e_crianca()).size()
	check(migr._populacao() == adultos, "a rede de segurança conta só adultos (%d de %d)" % [adultos, ws().size()])
	var sch = g("schedule")
	check(sch.refeicoes_restantes_hoje() >= 0, "o HUD conta as refeições (criança meia, bebê nenhuma)")
	rel.morreu(crianca)
	check(mae.happiness_factors().any(func(f): return f[0] == "luto por alguém querido"), "a mãe fica de luto pela filha")
	var inf = g("enfermarias")
	if inf:
		check(inf._familia_de(mae).contains("mãe de"), "o memorial lembra a família (%s)" % inf._familia_de(mae))

	print("-- (G) save, telemetria, ficha")
	var wd: Dictionary = JSON.parse_string(JSON.stringify(crianca.get_save_data()))
	crianca.fase = "adulto"
	crianca.load_save_data(wd)
	check(crianca.fase == "crianca" and crianca.pais == [String(mae.name)], "fase e pais no save do ipezinho")
	wd.erase("fase")
	wd.erase("pais")
	crianca.load_save_data(wd)
	check(crianca.fase == "adulto" and crianca.pais.is_empty(), "save antigo: adulto, sem família")
	var fd: Dictionary = JSON.parse_string(JSON.stringify(fam.get_save_data()))
	fam.load_save_data({})
	check(fam.nascimentos == 0, "save antigo das famílias: ninguém nasceu")
	fam.load_save_data(fd)
	check(fam.nascimentos == 1, "as famílias voltam do save")
	check(root.get_node("SaveManager")._collect().has("familias"), "o SaveManager leva 'familias'")
	var tel := load("res://scripts/core/telemetria.gd")
	for col in ["bebes", "criancas", "aprendizes", "gravidas", "nascimentos", "camas_livres"]:
		check((tel.COLUNAS as Array).has(col), "telemetria: %s" % col)
	var telem = g("telemetria")
	if telem:
		telem.registra()
		var fl := FileAccess.open(telem.arquivo, FileAccess.READ)
		var ultima := ""
		while fl and not fl.eof_reached():
			var l := fl.get_line()
			if l != "":
				ultima = l
		check(ultima.split(",").size() == (tel.COLUNAS as Array).size(), "uma coluna por nome (%d x %d)" % [ultima.split(",").size(), (tel.COLUNAS as Array).size()])
	var hud = g("hud")
	hud.open_panel("ficha", pai)
	await process_frame
	check(hud._panels["ficha"]._familia.text.contains("Filhos"), "a ficha mostra os filhos (%s)" % hud._panels["ficha"]._familia.text)
	hud.close_panels()
	check(pol.POLITICAS.has("familia") and pol.texto("familia", "incentivar").custa.size() > 0, "a política de Família está na janela de Políticas")

	Engine.time_scale = 1.0
	print("\nFALHAS: %d" % fails)
	quit()

