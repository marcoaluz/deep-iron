extends SceneTree
## Bloco 92: a ARTE DO PIXELLAB dos Blocos 86-90 no jogo e o PADRE COMO FUNÇÃO.
## - Bonecos próprios (oficios92.py, a receita do elenco): fundidor/fundidora, ferreiro/ferreira e o padre (só homem),
##   com parado, caminhada de 8 quadros, comer, ferido, deitar, mancar, o trabalho (fundir / forjar / pregar) e o
##   casaco de inverno (andando; o padre também pregando); retrato com as 5 expressões nos 3 tons; ícone na barra.
## - Prédios com a evolução da obra (obra 1 -> 2 -> 3 -> pronto): a FORNALHA (a Fundição do Prompt 12) e a IGREJA.
## - Decoração pelo desenho do PixelLab (a tocha acende/apaga; lampião, cerca, canteiro e bandeira novos).
## - Padre = função da barra (tecla 8): só homem, um por vila, abre no estágio do padre; o padre pode trocar de
##   função; na missa ele prega.
## RODAR SÓ COM APPDATA ISOLADO.
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Decor := preload("res://scripts/core/decor.gd")
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


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func sel(ws: Array) -> void:
	main.selection.clear()
	for w in ws:
		main.selection.append(w)


func finish_canteiro(kind: String) -> bool:
	for c in get_nodes_in_group("canteiros"):
		if c.kind == kind:
			c.obra_work(c.left + 1.0)
			return true
	return false


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 600.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var hub = g("village_hub")
	var cal = g("calendario")
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step == 0 and t > 2.0:
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		print("== bonecos do PixelLab (bonecos.json)")
		var d: Dictionary = IsoBonecos.data()
		var fn: Dictionary = d.get("funcoes", {})
		check(fn.get("fundidor") == ["fundidor", "fundidora", "fundir"] and fn.get("ferreiro") == ["ferreiro", "ferreira", "forjar"]
			and fn.get("padre") == ["padre", "padre", "pregar"], "as 3 funções com pasta de homem, de mulher (padre: só homem) e o trabalho")
		var precisa := ["parado", "caminhada", "comer", "ferido", "deitar", "mancar_esq"]
		for pz in [["fundidor", "fundir"], ["fundidora", "fundir"], ["ferreiro", "forjar"], ["ferreira", "forjar"], ["padre", "pregar"]]:
			var an: Dictionary = d.pastas.get(pz[0], {}).get("anims", {})
			var falta := (precisa + [pz[1]]).filter(func(a): return not an.has(a) or an[a].size() < 4)
			check(falta.is_empty(), "%s: parado, caminhada, comer, ferido, deitar, mancar e %s nas 4 direções (falta: %s)" % [pz[0], pz[1], falta])
			check(an.get("caminhada", {}).get("SE", {}).get("n", 0) == 8 and an.get(pz[1], {}).get("SE", {}).get("n", 0) == 8,
				"%s: caminhada e trabalho de 8 quadros" % pz[0])
			var cas: Dictionary = d.pastas.get("casaco_" + pz[0], {}).get("anims", {})
			check(cas.has("caminhada") and cas.caminhada.size() == 4, "%s: casaco de inverno andando" % pz[0])
			var tira: String = an.get("caminhada", {}).get("SE", {}).get("img", "")
			check(tira != "" and ResourceLoader.exists("res://assets/game/iso/bonecos/" + tira.replace(".png", "__negra.png")),
				"%s: os 3 tons de pele" % pz[0])
		check(d.pastas.get("casaco_padre", {}).get("anims", {}).has("pregar"), "o padre prega de casaco")
		print("== quem veste o quê")
		var lista: Array = get_nodes_in_group("ipezinhos")
		var h: Node = lista[0]
		var m: Node = lista[1]
		h.gender = "menino"  # (os do começo são sorteados)
		m.gender = "menina"
		for w in lista.slice(2):
			w.gender = "menino"
		set_meta("h", h)
		set_meta("m", m)
		h.set_job("fundidor")
		m.set_job("ferreiro")
		check(IsoBonecos.folders(h).back() == "fundidor" and IsoBonecos.work_anim(h) == "fundir", "fundidor homem: pasta fundidor, trabalho 'fundir'")
		check(IsoBonecos.folders(m).back() == "ferreira" and IsoBonecos.work_anim(m) == "forjar", "ferreiro mulher: pasta ferreira, trabalho 'forjar'")
		m.wearing["casaco"] = 1.0
		check(IsoBonecos.folders(m).slice(-2) == ["casaco_ferreira", "ferreira"], "de casaco: casaco_ferreira por cima")
		m._work_timer = 0.2
		var po: Dictionary = IsoBonecos.pose(m, 0, 0.0)
		check(po.get("anim") == "forjar" and po.get("pasta") == "ferreira", "forjando de casaco: a forja é quente, trabalha sem ele (%s/%s)" % [po.get("pasta"), po.get("anim")])
		m.wearing.erase("casaco")
		m._work_timer = 0.0
		check(h._body.modulate == Color.WHITE or not h.is_cold(), "sem o tom provisório (Blocos 86-88)")
		print("== retratos e ícones")
		check(Retratos.de(h) != null and Retratos.pasta(h) == "fundidor", "retrato do fundidor")
		check(Retratos.de(m) != null and Retratos.pasta(m) == "ferreira", "retrato da ferreira")
		for e in ["contente", "cansado", "bravo", "ferido"]:
			check(ResourceLoader.exists("res://assets/game/ui/retratos/padre/%s__clara.png" % e), "padre: expressão %s" % e)
		check(Icones.tex("fundidor") != null and Icones.tex("ferreiro") != null and Icones.tex("padre") != null, "ícones das 3 funções")
		check(g("hud")._job_buttons.has("padre"), "botão Padre na barra de funções")
		print("== prédios: a evolução da obra")
		for k in ["fornalha", "igreja"]:
			var e: Dictionary = IsoArt.entry(k).get("estados", {})
			check(["obra_1", "obra_2", "obra_3", "pronto"].all(func(s): return e.has(s) and ResourceLoader.exists(IsoArt.DIR + e[s].img)),
				"%s: obra 1, 2, 3 e pronto" % k)
			check(IsoArt.KIND_OF_CANTEIRO.get(k) == k and IsoArt.KIND_OF_SCENE.get(k) == k, "%s: canteiro e prédio desenhados com a arte nova" % k)
		print("== decoração")
		var deco = g("decoracoes")
		for id in Decor.CATALOGO:
			var nome: String = Decor.info(id).get("iso", "")
			var ok: bool = nome == "tocha_chao" or IsoArt.props().has(nome)
			check(ok, "%s: desenho do PixelLab (%s)" % [id, nome])
		var tocha: Node2D = load("res://scripts/props/decoracao.gd").new()
		tocha.monta("tocha")
		hub.get_parent().add_child(tocha)
		tocha.global_position = hub.global_position + Vector2(-200, 160)
		tocha.acende(1.0)
		var lit := IsoArt.prop_layers(tocha)
		check(tocha.iso_prop_nome() == "tocha_chao" and lit.size() == 1 and lit[0].has("anim"), "tocha acesa: a chama animada")
		tocha.take_hit(1.0, null)
		check(tocha.iso_prop_nome() == "tocha_apagada", "um Lumívoro apagou: a tocha apagada")
		tocha.queue_free()
		print("== padre: função da barra (só homem, um só)")
		hub.level = 1
		check(h.motivo_padre() != "" and "estágio" in h.motivo_padre(), "antes do estágio do padre: fechado ('%s'; vila %d, padre %d)" % [h.motivo_padre(), hub.level, cal.padre_estagio])
		hub.level = cal.padre_estagio
		cal.padre_chegou = true  # (sem o Padre Bento: o jogador escolhe)
		sel([m])
		main.toggle_priest()
		check(not m.is_priest() and "homem" in m.motivo_padre(), "mulher não vira padre ('%s')" % m.motivo_padre())
		sel([h])
		main.toggle_priest()
		check(h.is_priest() and cal.padre() == h, "%s virou o padre" % h.display_name)
		var h2: Array = lista.filter(func(w): return w.gender == "menino" and w != h)
		if not h2.is_empty():
			sel([h2[0]])
			main.toggle_priest()
			check(not h2[0].is_priest() and "já tem padre" in h2[0].motivo_padre(), "um padre só ('%s')" % h2[0].motivo_padre())
		sel([h, m])
		main.toggle_priest()
		check(h.is_priest(), "padre: um ipezinho de cada vez (com 2 selecionados não faz nada)")
		print("== na missa ele prega")
		var eco = g("economy")
		eco.credits = 9999.0
		var arm = g("armazens")
		arm.stock["ferro"] = 999.0
		arm.wood_stored = 999.0
		arm._recount()
		hub.build_igreja()
		var q := spot_near(hub.global_position + Vector2(-150, 140))
		g("house_placer").cancel()
		check(q.is_finite() and hub._confirm_igreja(q) and finish_canteiro("igreja"), "a igreja de pé")
		var dn = g("day_night")
		while not dn.e_domingo():
			dn.day += 1
		dn.time = dn.tempo_da_hora(cal.missa_inicio + 0.5)
		h.global_position = cal.igreja().altar_pos()
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 3.0:
		var h: Node = get_meta("h")
		check(cal.pregando_agora(), "domingo, hora da missa")
		check(h.get_state() == "padre" and h._work_timer > 0.0 and IsoBonecos.pose(h, 0, 0.0).get("anim") == "pregar",
			"o padre na porta da igreja pregando (estado %s, anim %s)" % [h.get_state(), IsoBonecos.pose(h, 0, 0.0).get("anim")])
		print("== o padre troca de função e o save guarda")
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		check(JSON.stringify(data).contains("\"padre\""), "save com o padre")
		h.set_job("minerador")
		check(not h.is_priest() and cal.padre() == null, "o padre pode deixar a função (a vaga abre)")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
