extends SceneTree
## Bloco 93: o CEMITÉRIO — o jogador marca o terreno arrastando (o tamanho é dele; custo por vaga e por trecho de
## cerca), o engenheiro ergue (a cerca aparece por etapas: estacas, postes, cerca, pronto com portão), começa
## VAZIO; quem morre deixa o corpo, o PADRE busca, leva nos ombros e enterra: a cruz ou a lápide aparece com o
## NOME e o DIA. Com a pesquisa "Ritos fúnebres" o padre faz o funeral no cemitério (a vila vai; no fim o luto
## cai e o ânimo sobe: "funeral digno"); sem ela, não tem funeral. Save (cemitério, túmulos, corpos) e save antigo.
## RODAR SÓ COM APPDATA ISOLADO.
var Cemiterio: GDScript  # (carregado com o jogo aberto: o script usa os autoloads)
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var cem: Node2D
var padre: Node
var mortos: Array = []


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


func pecas(nome: String) -> int:
	return cem.pecas().filter(func(n): return n.get_meta("iso_prop", "") == nome).size()


## Um terreno livre perto do Centro (o hub diz se vale).
func terreno(hub: Node, tam: Vector2) -> Rect2:
	for r in range(60, 600, 24):
		for a in range(16):
			var c: Vector2 = hub.global_position + Vector2.RIGHT.rotated(a * TAU / 16.0) * r
			var q := Rect2(c - tam * 0.5, tam)
			if hub.motivo_cemiterio(q) == "":
				return q
	return Rect2()


func mata(w: Node, perto: Vector2) -> String:
	w.global_position = perto
	var nome: String = w.display_name
	w.injury_cause = "desabamento"
	w._die()
	return nome


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 900.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		Engine.time_scale = 1.0
		return true
	var hub = g("village_hub")
	var cal = g("calendario")
	var dn = g("day_night")
	var mor = g("morale")
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max
	if step >= 1 and step < 20 and dn:
		if dn.is_night() or dn.hora() > 16.5:
			dn.time = dn.tempo_da_hora(9.5)  # (o padre só busca de dia: o teste fica de dia)
		while dn.e_domingo():
			dn.day += 1
	if step == 0 and t > 2.0:
		Cemiterio = load("res://scripts/props/cemiterio.gd")
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca
		sun.wave_today = false
		g("defense").set("invasions_enabled", false)
		var eco = g("economy")
		eco.credits = 99999.0
		var arm = g("armazens")
		arm.stock["ferro"] = 999.0
		arm.wood_stored = 999.0
		arm._recount()
		while get_nodes_in_group("ipezinhos").size() < 6:
			eco.credits = 99999.0
			eco.recruit()
		print("== estágio e tamanho")
		hub.level = 1
		check(hub.cemiterio_block_reason() != "", "estágio 1: ainda não ('%s')" % hub.cemiterio_block_reason())
		hub.level = 2
		cal.padre_chegou = true
		var peq: Vector4 = hub.cemiterio_custo(Rect2(0, 0, 72, 48))
		var gde: Vector4 = hub.cemiterio_custo(Rect2(0, 0, 168, 120))
		check(gde.x > peq.x and gde.y > peq.y and gde.z > peq.z and gde.w > peq.w,
			"custo e obra crescem com o tamanho (3x2: %d cr %.0f s; 7x5: %d cr %.0f s)" % [peq.x, peq.w, gde.x, gde.w])
		check(Cemiterio.alinha(Rect2(0, 0, 40, 10)).size == Vector2(72, 48), "mínimo 3 x 2 trechos de cerca")
		check(hub.motivo_cemiterio(Rect2(hub.global_position - Vector2(40, 40), Vector2(96, 72))) != "", "não pode por cima do Centro da Vila")
		print("== marcar arrastando")
		var q := terreno(hub, Vector2(144, 96))
		check(q.has_area(), "achou terreno livre de 6 x 4 trechos")
		check(hub.build_cemiterio(), "CONSTRUIR > Culto > Cemitério: o arrastar abre")
		var ap = g("area_placer")
		check(ap.active, "a ferramenta de marcar está ligada")
		ap.drag(q.position, q.end)
		check(ap.try_confirm() == true and not ap.active, "soltou: cemitério encomendado")
		cem = hub.cemiterios()[0] if not hub.cemiterios().is_empty() else null
		check(cem != null and cem.obra_pending() and cem.is_in_group("obras"), "é obra do engenheiro")
		check(cem.rect.size == Vector2(144, 96) and cem.vagas_total() >= 6, "o tamanho marcado (%s, %d vagas)" % [cem.rect.size, cem.vagas_total()])
		step = 1
		t_mark = t
	elif step == 1 and t - t_mark > 0.5:
		print("== a evolução da obra")
		check(cem.estagio() == 1 and pecas("cem_poste") == 4 and pecas("cem_cerca") == 0, "etapa 1: estacas nos 4 cantos")
		cem.obra_work(cem.total * 0.45)
		check(cem.estagio() == 2 and pecas("cem_poste") > 4 and pecas("cem_cerca") == 0, "etapa 2: os postes (%d)" % pecas("cem_poste"))
		cem.obra_work(cem.total * 0.3)
		check(cem.estagio() == 3 and pecas("cem_cerca") > 0 and pecas("cem_cerca_y") > 0 and pecas("cem_portao") == 0, "etapa 3: a cerca, ainda sem portão")
		cem.obra_work(cem.total)
		var nx := 6
		var ny := 4
		check(cem.pronto and not cem.is_in_group("obras") and pecas("cem_portao") == 1 and pecas("cem_cerca") == nx * 2 - 1 and pecas("cem_cerca_y") == ny * 2,
			"pronto: a cerca inteira com o portão (%d trechos + portão)" % (pecas("cem_cerca") + pecas("cem_cerca_y")))
		check(cem.covas.is_empty() and get_nodes_in_group("tumulos").is_empty(), "começa VAZIO")
		check(IsoArt.props().has("cem_cerca") and IsoArt.props().has("cem_portao") and IsoArt.props().has("corpo"), "as peças têm desenho (PixelLab)")
		print("== alguém morre: o padre busca e enterra")
		var ws: Array = get_nodes_in_group("ipezinhos")
		padre = ws[0]
		padre.gender = "menino"
		padre.set_job("padre")
		check(padre.is_priest(), "%s é o padre" % padre.display_name)
		padre.global_position = cem.portao_pos() + Vector2(0, 40)
		var covas_enf := get_nodes_in_group("graves").size()
		mortos.append(mata(ws[1], cem.portao_pos() + Vector2(60, 70)))
		var corpos := get_nodes_in_group("corpos")
		check(corpos.size() == 1 and corpos[0].nome == mortos[0], "o corpo de %s ficou onde caiu" % mortos[0])
		check(get_nodes_in_group("graves").size() == covas_enf, "com cemitério, nada de cruz do lado da enfermaria")
		check(cal.funerais.is_empty(), "sem a pesquisa dos ritos: não marca funeral")
		Engine.time_scale = 3.0
		step = 2
		t_mark = t
	elif step == 2:
		if not padre.carregando_corpo.is_empty() and not has_meta("viu_ombro"):
			set_meta("viu_ombro", true)
			var po: Dictionary = IsoBonecos.pose(padre, 0, 0.0)
			check(po.has("saco") and String(po.saco.tex.resource_path).ends_with("corpo_costas.png"), "o padre leva o corpo nos ombros (estado %s)" % padre.get_state())
			check(get_nodes_in_group("corpos").is_empty(), "o corpo saiu do chão")
		if cem.covas.size() >= 1:
			Engine.time_scale = 1.0
			check(has_meta("viu_ombro"), "carregou antes de enterrar")
			var tum: Array = get_nodes_in_group("tumulos")
			check(tum.size() == 1 and String(tum[0].get_meta("iso_prop")).begins_with("cem_"), "apareceu a %s" % (tum[0].get_meta("iso_prop") if not tum.is_empty() else "?"))
			var txt := " / ".join(tum[0].get_children().filter(func(c): return c is Label).map(func(c): return c.text)) if not tum.is_empty() else ""
			check(mortos[0] in txt and ("dia %d" % dn.day) in txt, "a lápide diz o nome e o dia: '%s'" % txt)
			check(cal.funerais.is_empty(), "sem os ritos, só o enterro")
			print("== pesquisa: Ritos fúnebres")
			var res = g("research")
			check(res.TECHS.has("ritos") and res.ORDER.has("ritos"), "a pesquisa existe na árvore (ramo %s)" % res.TECHS.ritos.branch)
			res.done.append("ritos")
			check(cal.funeral_liberado(), "pesquisada: o padre faz funeral")
			var ws: Array = get_nodes_in_group("ipezinhos").filter(func(w): return w != padre)
			mortos.append(mata(ws[0], cem.portao_pos() + Vector2(-60, 60)))
			Engine.time_scale = 3.0
			step = 3
		elif t - t_mark > 240.0:
			check(false, "o padre enterrou em 240 s (estado %s, corpos %d)" % [padre.get_state(), get_nodes_in_group("corpos").size()])
			step = 99
	elif step == 3:
		if cem.covas.size() >= 2:
			Engine.time_scale = 1.0
			check(cal.funerais.size() == 1 and cal.funerais[0].onde == "cemiterio" and cal.funerais[0].nome == mortos[1], "funeral de %s marcado no cemitério" % mortos[1])
			step = 20
			dn.time = dn.tempo_da_hora(dn.hora_anoitecer + 0.25)
			if cal.funerais[0].dia != dn.day:
				dn.day = int(cal.funerais[0].dia)
			t_mark = t
	elif step == 20 and t - t_mark > 1.0:
		check(cal.funeral_agora() and cal.funeral_lugar_agora() == cem, "hora do funeral: no cemitério")
		check(cal.ponto_forcado() == cem.ponto(), "a vila vai pro cemitério (ponto social do funeral)")
		check(cal.pregando_agora(), "o padre prega")
		mor.grief = 30.0
		var g0: float = mor.grief
		dn.time = dn.tempo_da_hora(dn.hora_anoitecer + cal.funeral_horas + 0.2)
		cal._process(0.0)
		check(mor.grief < g0 and mor.funeral_left > 0.0, "fim do funeral: o luto caiu (%.0f -> %.0f) e o ânimo sobe" % [g0, mor.grief])
		check(mor.village_factors().any(func(f): return f[0] == "funeral digno" and f[1] > 0.0), "fator 'funeral digno' pra vila toda")
		print("== largar o corpo e o save")
		padre.carregando_corpo = {"nome": "Teste", "dia": 3, "estacao": "Primavera", "causa": ""}
		padre.set_job("minerador")
		check(padre.carregando_corpo.is_empty() and get_nodes_in_group("corpos").any(func(c): return c.nome == "Teste"), "deixou de ser padre: o corpo volta pro chão")
		root.get_node("SaveManager").save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		var cd: Dictionary = data.calendario
		check(cd.get("cemiterios", []).size() == 1 and cd.cemiterios[0].covas.size() == 2 and cd.cemiterios[0].pronto, "save: o cemitério com 2 covas")
		check(cd.get("corpos", []).size() == 1, "save: o corpo esperando")
		set_meta("data", data)
		root.get_node("SaveManager").load_game()
		step = 21
		t_mark = t
	elif step == 21 and t - t_mark > 2.0:
		var cs: Array = get_nodes_in_group("cemiterios")
		check(cs.size() == 1 and cs[0].covas.size() == 2 and get_nodes_in_group("tumulos").size() == 2 and cs[0].pecas().size() > 10,
			"load: o cemitério volta com a cerca e os 2 túmulos")
		check(get_nodes_in_group("corpos").size() == 1, "load: o corpo esperando voltou")
		print("== save antigo (sem cemitério)")
		var data: Dictionary = get_meta("data")
		data.calendario.erase("cemiterios")
		data.calendario.erase("corpos")
		data.morale.erase("funeral_left")
		var fw := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(data))
		fw.close()
		root.get_node("SaveManager").load_game()
		step = 22
		t_mark = t
	elif step == 22 and t - t_mark > 2.0:
		check(get_nodes_in_group("cemiterios").is_empty() and get_nodes_in_group("tumulos").is_empty() and get_nodes_in_group("corpos").is_empty(),
			"save antigo: sem cemitério, sem erro")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		Engine.time_scale = 1.0
		return true
	return false
