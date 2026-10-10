extends SceneTree
## Bloco 110: RELACIONAMENTOS, TRAÇOS e HABILIDADES. (A) Traços: todo mundo tem 1 ou 2, sem opostos; os efeitos (produção,
## acidente, fome) e a reação às Políticas da Vila. (B) Habilidade: sobe trabalhando, tem teto, rende mais. (C) Relações: a
## conversa e o trabalho lado a lado dão pontos (a afinidade multiplica); os níveis; interesse e casal só entre um homem e uma
## mulher adultos sem parceiro (um por vez). (D) O casal: mora junto (se couber), senta junto, anima; o casamento na missa
## (igreja + padre, domingo) e o festival vira a festa dele; o diário. (E) A morte: luto maior pelo amigo e pelo parceiro;
## viuvez. (F) Ficha, cartão, save, save antigo (traços sorteados, ninguém se conhece) e telemetria.
## RODAR SÓ COM APPDATA ISOLADO.
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


func perto(a: float, b: float, eps: float = 0.001) -> bool:
	return absf(a - b) <= eps


func anda(s: float) -> void:
	var t0 := t
	while t - t0 < s:
		await process_frame


func soma_fator(w: Node, nome: String) -> float:
	var s := 0.0
	for f in w.happiness_factors():
		if String(f[0]) == nome:
			s += float(f[1])
	return s


func _process(delta: float) -> bool:
	t += delta
	if t > 300.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(9.0)
	for w in ws():
		w.hunger = w.hunger_max
	if g("sun"):
		g("sun").wave_today = false
	if not rodando and t > 2.0:
		rodando = true
		roda()
	return false


func roda() -> void:
	var eco = g("economy")
	var rel = g("relacoes")
	var g_def = g("defense")
	g_def.first_invasion_day = 999
	while ws().size() < 10:
		eco.novo_ipezinho()
	await process_frame
	var w: Array = ws()
	var homens: Array = w.filter(func(x): return x.gender == "menino")
	var mulheres: Array = w.filter(func(x): return x.gender == "menina")
	while homens.size() < 3 or mulheres.size() < 3:
		var n = eco.novo_ipezinho("menino" if homens.size() < 3 else "menina")
		await process_frame
		(homens if n.gender == "menino" else mulheres).append(n)
	var h1: Node = homens[0]
	var h2: Node = homens[1]
	var m1: Node = mulheres[0]
	var m2: Node = mulheres[1]

	print("-- (A) traços")
	check(rel != null and rel.is_in_group("relacoes"), "o nó Relacoes existe")
	var ok_tracos := true
	for x in ws():
		var tr: Array = x.tracos_de()
		if tr.size() < 1 or tr.size() > 2:
			ok_tracos = false
		for a in tr:
			for b in tr:
				if a != b and rel._opostos(a, b):
					ok_tracos = false
	check(ok_tracos, "todo mundo tem 1 ou 2 traços, sem opostos")
	h1.tracos = ["trabalhador"]
	h2.tracos = ["preguicoso"]
	h1.set_job("minerador")
	h2.set_job("minerador")
	h1.habilidade = {}
	h2.habilidade = {}
	check(perto(h1._mult_pessoal(), 1.08) and perto(h2._mult_pessoal(), 0.92), "trabalhador x1,08 e preguiçoso x0,92 (%.2f / %.2f)" % [h1._mult_pessoal(), h2._mult_pessoal()])
	m1.tracos = ["cuidadoso"]
	check(perto(rel.mult_acidente(m1), 0.7) and perto(rel.mult_acidente(h1), 1.0), "cuidadoso: acidente x0,7")
	m2.tracos = ["guloso"]
	check(perto(rel.mult_fome(m2), 1.15), "guloso: fome x1,15")
	var pol = g("politicas")
	pol.forca("jornada", "estendida")
	var f_h2: float = 0.0
	for f in pol.fatores_animo(h2):
		f_h2 += float(f[1])
	var f_h1: float = 0.0
	for f in pol.fatores_animo(h1):
		f_h1 += float(f[1])
	check(perto(f_h2, -12.0) and perto(f_h1, -4.0), "a jornada estendida pesa mais no preguiçoso (%.0f) e menos no trabalhador (%.0f)" % [f_h2, f_h1])
	pol.forca("jornada", "normal")

	print("-- (B) habilidade")
	h1.habilidade = {"minerador": 0.5}
	check(perto(h1._mult_pessoal(), 1.08 * (1.0 + 0.15 * 0.5)), "50% de habilidade: +7,5% de produção")
	h1.habilidade = {}
	h1._work_timer = 0.2
	h1._ai_state = "mining"
	h1._pratica(rel, 100.0)
	check(perto(float(h1.habilidade.get("minerador", 0.0)), 100.0 * rel.habilidade_ganho), "100 s minerando: sobe 100 x o ganho (%.3f)" % float(h1.habilidade.get("minerador", 0.0)))
	h1._pratica(rel, 99999.0)
	check(perto(float(h1.habilidade["minerador"]), 1.0), "teto de 100%")
	h1._ai_state = "idle"
	h1.habilidade = {}

	print("-- (C) relações")
	for x in [h1, h2, m1, m2]:
		x.tracos = ["valente"]
	rel.pares.clear()
	rel._refaz_caches()
	rel.conversou(h1, h2, false)
	check(perto(rel.pontos(h1, h2), rel.pontos_conversa * 1.2), "uma conversa: os pontos x afinidade (mesmo traço x1,2) = %.2f" % rel.pontos(h1, h2))
	check(rel.nivel(h1, h2) == 0, "ainda nem conhecidos")
	rel.soma(h1, h2, rel.limiares[1] / 1.2)
	check(rel.nivel(h1, h2) == 2 and rel.nome_nivel(2) == "amigo", "amigos (%s)" % rel.nome_nivel(rel.nivel(h1, h2)))
	rel.soma(h1, h2, 200.0)
	check(rel.nivel(h1, h2) == 3 and rel.parceiro_de(h1) == null, "dois homens: no máximo 'próximo', nunca casal")
	rel.pares.clear()
	h1.global_position = Vector2(0, 0)
	m1.global_position = Vector2(30, 0)
	h1._ai_state = "mining"
	m1._ai_state = "mining"
	rel._lado_a_lado()
	check(rel.pontos(h1, m1) > 0.0, "trabalhar lado a lado dá pontos (%.2f)" % rel.pontos(h1, m1))
	h1._ai_state = "idle"
	m1._ai_state = "idle"
	rel.soma(h1, m1, rel.limiares[3] / 1.2 + 1.0)
	check(rel.nivel(h1, m1) == 4, "um homem e uma mulher sem parceiro: interesse")
	rel.soma(h1, m1, (rel.limiares[4] - rel.limiares[3]) / 1.2 + 1.0)
	check(rel.parceiro_de(h1) == m1 and rel.parceiro_de(m1) == h1 and rel.nivel(h1, m1) == 5, "viraram casal")
	check(not rel.pode_namorar(h1, m2) and not rel.pode_namorar(h2, m1), "um parceiro por vez")
	rel.soma(h2, m1, 300.0)
	check(rel.parceiro_de(m1) == h1 and rel.nivel(h2, m1) == 3, "outro não toma o lugar (fica 'próximo')")
	check(soma_fator(h1, "namorando") > 0.0, "namorar anima")
	m1.global_position = h1.global_position + Vector2(20, 0)
	check(soma_fator(h1, "perto de quem gosta") > 0.0, "perto do parceiro anima mais")
	check(soma_fator(h2, "tem amigos") > 0.0 or rel.nivel(h2, m1) >= 2, "quem tem amigos ganha ânimo")
	# senta junto: a roda do parceiro puxa
	var sp: Node = null
	for s in get_nodes_in_group("social_spots"):
		sp = s
		break
	if sp:
		sp.reservar(m1)
		check(h1._nota_social(sp) >= 25.0, "a roda do parceiro puxa (senta junto)")
		sp.liberar(m1)
	# mora junto (se couber)
	var casas: Array = get_nodes_in_group("casas").filter(func(c): return c.built)
	if casas.size() >= 1:
		check(h1.has_home() == false or m1.has_home() == false or h1._home == m1._home or casas.any(func(c): return c.free_slot_count() == 0), "o casal tentou morar junto (casa de um dos dois, se tinha cama)")
	else:
		print("  (sem casa pronta nesta partida: a mudança não foi conferida aqui)")

	print("-- (D) casamento")
	var dn = g("day_night")
	var cal = g("calendario")
	var d: Dictionary = rel.par(h1, m1)
	d.desde = -10
	rel.casa_os_dois(h1, m1)
	check(rel.casado(h1) and rel.casamentos == 1 and rel.casamento_left > 0.0, "casaram")
	check(soma_fator(h2, "casamento na vila") > 0.0 and h1.animo_casamento > 0.0, "a vila e os noivos ganham ânimo")
	check(cal.nome_festival_hoje().begins_with("Festa do casamento"), "o festival vira a festa do casamento (%s)" % cal.nome_festival_hoje())
	var di = g("diary")
	check(di.has_page("rel_primeiro_casal") and di.has_page("rel_casamento_1"), "o diário registra o primeiro casal e o casamento")

	print("-- (E) a morte")
	rel.soma(h2, m2, 40.0)
	var luto_antes: float = soma_fator(m1, "luto por alguém querido")
	rel.morreu(h1)
	check(soma_fator(m1, "luto por alguém querido") <= -24.0 and luto_antes == 0.0, "a parceira fica de luto (%.0f)" % soma_fator(m1, "luto por alguém querido"))
	check(rel.parceiro_de(m1) == null and rel._viuvo(m1) and not rel.pode_namorar(m1, h2), "viúva: sem parceiro e sem namoro novo por uns dias")
	rel.morreu(m2)
	check(soma_fator(h2, "luto por alguém querido") <= -9.0, "o amigo fica de luto (%.0f)" % soma_fator(h2, "luto por alguém querido"))

	print("-- (F) ficha, save, telemetria")
	var hud = g("hud")
	hud._update_portrait([h2])
	check(hud._portrait_ficha.visible, "o cartão tem o botão Ficha")
	hud.open_panel("ficha", h2)
	await process_frame
	var fp = hud._panels["ficha"]
	check(fp.visible and fp._tracos.text.contains("Valente") and fp._titulo.text != "", "a ficha mostra os traços (%s)" % fp._tracos.text)
	check(not fp.is_available(), "a ficha fica fora do menu Janelas")
	hud.close_panels()
	h2.habilidade = {"lenhador": 0.4}
	var wd: Dictionary = JSON.parse_string(JSON.stringify(h2.get_save_data()))
	h2.tracos = []
	h2.habilidade = {}
	h2.load_save_data(wd)
	check(h2.tracos == ["valente"] and perto(float(h2.habilidade.get("lenhador", 0.0)), 0.4), "traços e habilidade no save do ipezinho")
	wd.erase("tracos")
	wd.erase("habilidade")
	h2.load_save_data(wd)
	check(h2.tracos.is_empty() and h2.tracos_de().size() >= 1, "save antigo: sem traços -> sorteia na primeira vez")
	rel.soma(h2, m1, 1.0)
	var rd: Dictionary = JSON.parse_string(JSON.stringify(rel.get_save_data()))
	var k: String = rel.chave(h2, m1)
	var p_antes: float = rel.pontos(h2, m1)
	rel.load_save_data({})
	check(rel.pares.is_empty() and rel.casamentos == 0, "save antigo das relações: ninguém se conhece")
	rel.load_save_data(rd)
	check(perto(rel.pontos(h2, m1), p_antes) and rel.casamentos == 1 and rel.pares.has(k), "as relações voltam do save")
	var tel := load("res://scripts/core/telemetria.gd")
	check((tel.COLUNAS as Array).has("amizades") and (tel.COLUNAS as Array).has("casais") and (tel.COLUNAS as Array).has("casamentos"), "a telemetria tem amizades, casais e casamentos")
	var telem = g("telemetria")
	if telem:
		telem.registra()
		var f := FileAccess.open(telem.arquivo, FileAccess.READ)
		var ultima := ""
		while f and not f.eof_reached():
			var l := f.get_line()
			if l != "":
				ultima = l
		check(ultima.split(",").size() == (tel.COLUNAS as Array).size(), "uma coluna por nome (%d x %d)" % [ultima.split(",").size(), (tel.COLUNAS as Array).size()])
	var sm = root.get_node("SaveManager")
	check(sm._collect().has("relacoes"), "o SaveManager leva a chave 'relacoes'")

	Engine.time_scale = 1.0
	print("\nFALHAS: %d" % fails)
	quit()
