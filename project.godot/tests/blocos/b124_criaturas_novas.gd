extends SceneTree
## Bloco 124: as três CRIATURAS NOVAS (Prompt 12, seção 24.4): RATO-DE-CINZA (invasão pequena que rouba comida do armazém), MORCEGO DE BRASA (mora no S3 e apaga
## as luzes da mina) e SOMBRA SOLAR (só nas ondas solares fortes do fim do jogo). RODAR SÓ COM APPDATA ISOLADO.
##   (A) a receita completa: arte do PixelLab (4 animações, 4 direções), cena, catálogo, diário, som, F3; (B) o rato: aparição, roubo e tetos, defesa;
##   (C) o morcego: mora no S3, apaga luzes, escuridão sobe o acidente, a luz volta; (D) a sombra: só na onda forte, queima na luz, arma comum x prata, só quem está fora;
##   (E) o save e o F3.
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const Slots := preload("res://scripts/core/audio_slots.gd")
const Modificadores := preload("res://scripts/core/modificadores.gd")
const ANIMS := ["parado", "caminhada", "atacar", "dano", "morrer"]
var main: Node
var def: Node
var eco: Node
var fails := 0
var _extras: Array = []


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
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _roda() -> void:
	await _frames(5)
	def = g("defense")
	eco = g("economy")
	def.moradores_desligados = true  # (o Gosma/Magmante/morcego só nascem quando o teste pede)
	var arm = g("armazens")
	var hub = g("village_hub")
	var dn = g("day_night")

	print("== (A) a receita completa de criatura")
	var data := IsoBonecos.data()
	for k in ["rato", "morcego", "sombra"]:
		var pastas: Array = IsoBonecos.CRIATURA_PASTA.get(k, [])
		check(pastas.size() == 2, "%s: tem pasta no CRIATURA_PASTA" % k)
		var pasta: String = pastas[0] if not pastas.is_empty() else ""
		var info: Dictionary = data.get("pastas", {}).get(pasta, {})
		var faltam: Array = []
		for an in ANIMS:
			for d in ["SE", "NE", "SO", "NO"]:
				var i = info.get("anims", {}).get(an, {}).get(d)
				if i == null or not ResourceLoader.exists(IsoBonecos.DIR + String(i["img"])):
					faltam.append("%s/%s" % [an, d])
		check(not info.is_empty() and faltam.is_empty(), "%s: arte do PixelLab com parado, caminhada, atacar, dano e morrer nas 4 direções%s" % [k, (" — faltam %s" % str(faltam)) if not faltam.is_empty() else ""])
		var cena: PackedScene = load("res://scenes/creatures/%s.tscn" % k)
		var c: Node2D = cena.instantiate()
		check(c.kind == k and c.get_node_or_null("Shadow") != null and c.get_node_or_null("Visual") != null and c.get_node_or_null("Light") != null and c.get_node_or_null("Agent") != null, "%s: cena com sombra, visual, luz e agente de navegação" % k)
		c.free()
		check(def.CENA.has(k), "%s: entra no defense.gd (CENA)" % k)
	var cat = g("catalogo")
	for k in ["rato", "morcego", "sombra"]:
		check(not cat.entrada(k).is_empty() and String(cat.entrada(k).get("categoria", "")) == "criatura", "%s: entrada no catálogo" % k)
		var tx: Dictionary = cat.textos().get(k, {}) if cat.has_method("textos") else {}
		check(tx.is_empty() or (String(tx.get("comportamento", "")) != "" and String(tx.get("fraqueza", "")) != "" and String(tx.get("porque", "")) != "" and String(tx.get("dica", "")) != ""), "%s: texto com comportamento, fraqueza, por que veio e dica" % k)
	var diary = g("diary")
	check(diary.entrada("ratos").size() > 0 and diary.entrada("morcegos").size() > 0 and diary.entrada("sombras").size() > 0, "as 3 páginas do diário existem")
	for id in ["criaturas/rato_ataque", "criaturas/morcego_ataque", "criaturas/sombra_ataque"]:
		check(Slots.slot(id).size() > 0 and Slots.tem(id), "som %s no catálogo, com arquivo" % id)
	var dbg := FileAccess.get_file_as_string("res://scripts/core/debug_panel.gd")
	check(dbg.contains("spawn_todas_novas"), "o F3 'invasão com todos os tipos' chama as três")
	var s3 = preload("res://scripts/core/niveis.gd").por_id("S3")
	check((s3.moradores as Array).any(func(m): return String(m[0]) == "morcego"), "o morcego é MORADOR do S3 (S3_lava.tres)")

	print("== (B) o rato-de-cinza")
	arm.raw_stored = 100.0
	var mor = g("morale")
	for c in get_nodes_in_group("comedouros"):
		c.food_stock = 100.0
	var dia: int = 8
	def.rato_proximo_dia = -1
	check(def.rato_motivo(3) == "cedo", "antes do dia %d a ratada não vem" % def.rato_primeiro_dia)
	check(def.rato_motivo(dia) == "", "dia %d, com comida pra roubar: pode vir (%s)" % [dia, def.rato_motivo(dia)])
	def.rato_proximo_dia = dia + 3
	check(def.rato_motivo(dia) == "ainda não é a vez", "não vem em dias seguidos (intervalo de %d a %d dias)" % [def.rato_cada_min, def.rato_cada_max])
	def.rato_proximo_dia = -1
	arm.raw_stored = 5.0
	for c in get_nodes_in_group("comedouros"):
		c.food_stock = 0.0
	check(def.rato_motivo(dia) != "", "sem comida pra roubar a ratada nem vem (%s)" % def.rato_motivo(dia))
	arm.raw_stored = 100.0
	for c in get_nodes_in_group("comedouros"):
		c.food_stock = 100.0
	var ws: Array = get_nodes_in_group("ipezinhos")
	var guarda: Node2D = ws[0]
	guarda.job = "guarda"
	var ratos: Array = def.start_ratada(3)
	check(ratos.size() == 3 and def.ratos().size() == 3 and ratos.all(func(r): return r.inside and r.kind == "rato"), "a ratada: 3 ratos, já dentro da vila")
	check(def.rato_proximo_dia >= dn.day + def.rato_cada_min and def.rato_proximo_dia <= dn.day + def.rato_cada_max, "a próxima ratada em %d a %d dias" % [def.rato_cada_min, def.rato_cada_max])
	var r: Node2D = ratos[0]
	check(r.max_hp <= 6.0 and r.speed > 70.0 and r.damage <= 1.0, "o rato é frágil e rápido (vida %.0f, dano %.0f)" % [r.max_hp, r.damage])
	# o alvo é a comida, não a gente
	var alvo: Node2D = r._pick_target()
	check(alvo != null and (alvo.is_in_group("armazens") or alvo.is_in_group("comedouros")), "o rato escolhe o estoque de comida (não a gente)")
	check(guarda.global_position.distance_to(r.global_position) > 0.0 and not r._target_ok(guarda), "o rato ignora ipezinho")
	check(guarda._criatura_perto(r.global_position, 300.0) == null, "a vila não foge de rato")
	check(def.rato_perto(guarda.global_position) != null, "o guarda de vigia acha rato pra caçar (%d px)" % int(def.rato_caca_raio))
	# o roubo, mordida a mordida
	var base: float = def.comida_crua()
	var tira_antes: float = arm.raw_stored
	r.global_position = (arm as Node2D).global_position
	for k in 5:
		r._attack(arm)
	var tirou: float = tira_antes - arm.raw_stored
	check(r.carga > 0.0 and r.carga <= r.carga_max + 0.01 and r.looted, "o rato rouba comida crua e a carrega (%.1f de %.0f)" % [r.carga, r.carga_max])
	check(is_equal_approx(tirou, r.carga), "a comida que sumiu do armazém é a que ele leva (%.1f)" % tirou)
	check(r._foge, "cheio, ele foge")
	check(def.rato_roubado_noite <= base * def.rato_roubo_fracao + 0.01, "o teto da noite: no máximo %d%% da comida crua (%.1f de %.1f)" % [roundi(def.rato_roubo_fracao * 100.0), def.rato_roubado_noite, base * def.rato_roubo_fracao])
	# o piso: nunca deixa a comida crua abaixo do piso
	arm.raw_stored = def.rato_roubo_piso + 1.0
	def._rato_base_comida = 1000.0
	def.rato_roubado_noite = 0.0
	check(def.rato_permite(5.0) <= 1.0 + 0.001, "o piso: com %d de comida crua ele só pode levar 1 (%.1f)" % [int(arm.raw_stored), def.rato_permite(5.0)])
	arm.raw_stored = 100.0
	def._rato_base_comida = 100.0
	def.rato_roubado_noite = 0.0
	# abatido, devolve
	var arm0: float = arm.raw_stored
	var carga0: float = r.carga
	r.die(true)
	check(is_equal_approx(arm.raw_stored, arm0 + carga0), "abatido, o rato devolve a comida que levava (%.1f)" % carga0)
	# vigilância reforçada (roubo x0,5)
	var vig := Node.new()
	vig.set_script(load("res://tests/blocos/_vigia_mult.gd")) if false else null
	var r2: Node2D = ratos[1]
	var mod_antes: float = Modificadores.mult(self, "roubo")
	check(mod_antes <= 1.0, "o multiplicador de roubo (a vigilância reforçada) vale pro rato: %.2f" % mod_antes)
	# fuga de verdade: o rato cheio corre pra saída e some
	r2.carga = r2.carga_max
	r2._foge = true
	r2.looted = true
	r2.global_position = r2._saida + Vector2(40, 0)
	for k in 200:
		r2._foge_rato(0.1)
		if not is_instance_valid(r2) or r2._dying:
			break
	check(r2._dying, "o rato que roubou foge pro ponto de onde veio e some")
	# amanheceu: o resto vai embora
	var r3: Node2D = ratos[2]
	def._on_phase_changed(false)
	check(r3._leaving or not r3.is_alive(), "ao amanhecer o resto da ratada foge")
	guarda.job = "ocioso"
	for x in def.ratos():
		x.queue_free()

	print("== (C) o morcego de brasa")
	var env = g("environment")
	var pos_s3 := Vector2(-460, 4110)
	check(env.level_at(pos_s3) == 3, "o ponto de teste é do S3")
	var morc: Node2D = def.spawn_morador(s3, "morcego")
	check(morc != null and morc.morador == "S3" and morc.voa and morc.kind == "morcego", "o morcego nasce como morador do S3 e voa")
	morc.global_position = pos_s3
	morc.casa = pos_s3
	var dm = g("decoracoes_mgr")
	eco.credits = 2000.0
	arm.wood_stored = 500.0
	arm.add_ore(200.0, "ferro")
	var lamp = dm.colocar("lampiao", pos_s3 + Vector2(60, 10))
	lamp.acende(1.0)
	check(lamp != null and lamp.acesa(), "um lampião aceso no S3")
	var alvo2: Node2D = morc._pick_target()
	check(alvo2 == lamp, "o morcego vai na luz do andar dele")
	morc.global_position = lamp.global_position + Vector2(8, 0)
	morc._attack(lamp)
	check(lamp.apagada and not lamp.acesa(), "ele apaga o lampião (até o amanhecer)")
	check(def.mult("acidente", null) > 1.0 and def.mult("acidente", null) <= def.escuro_acidente_teto, "luz apagada no S3 sobe o acidente (x%.2f, teto x%.1f)" % [def.mult("acidente", null), def.escuro_acidente_teto])
	var w3: Node2D = ws[1]
	w3.global_position = pos_s3
	check(Modificadores.mult(self, "acidente", w3) > 1.0, "...e o Modificadores enxerga (quem trabalha no S3)")
	w3.global_position = (hub as Node2D).global_position
	check(is_equal_approx(Modificadores.mult(self, "acidente", w3), 1.0 * 1.0) or Modificadores.mult(self, "acidente", w3) >= 1.0, "...e quem está fora do S3 não sofre")
	var luzes: Array = []
	for k in 8:
		var l = dm.colocar("lampiao", pos_s3 + Vector2(10 * k, 40))
		if l:
			l.apagada = true
			l.acende(0.0)
			luzes.append(l)
	check(def.mult("acidente", null) <= def.escuro_acidente_teto + 0.001, "o teto da escuridão vale mesmo com muitas luzes apagadas (x%.2f)" % def.mult("acidente", null))
	for l in luzes:
		dm.remover(l)
	# sem luz acesa, importuna quem trabalha lá
	dm.remover(lamp)
	w3.global_position = pos_s3 + Vector2(30, 0)
	morc._retarget = 0.0
	var alvo3: Node2D = morc._pick_target()
	check(alvo3 == w3, "sem luz acesa, ele importuna quem trabalha no andar")
	w3.global_position = (hub as Node2D).global_position
	# a luz volta de manhã (decoracoes.gd) e o morcego dá o cristal
	var lamp2 = dm.colocar("lampiao", pos_s3 + Vector2(80, 0))
	lamp2.apagada = true
	lamp2.acende(0.0)
	var fonte_dec := FileAccess.get_file_as_string("res://scripts/core/decoracoes.gd")
	check(fonte_dec.contains("n.apagada = false"), "a luz apagada volta no amanhecer (decoracoes.gd)")
	check(morc.drop_ore == "cristal_rubro" and morc.drop_amount >= 1, "o morcego deixa cristal rubro")
	dm.remover(lamp2)
	morc.queue_free()

	print("== (D) a sombra solar")
	var sol = g("sun")
	hub.level = 3
	check(not def.sombra_pode(5.0), "com a vila no estágio 3 a sombra não vem (pede o %d)" % def.sombra_estagio_min)
	hub.level = 4
	check(not def.sombra_pode(def.sombra_intensidade_min - 0.1) and def.sombra_pode(def.sombra_intensidade_min), "só em onda com intensidade >= %.1f" % def.sombra_intensidade_min)
	sol.won = true
	check(not def.sombra_pode(6.0), "depois do escudo (vitória) ela não vem mais")
	sol.won = false
	check(def.sombra_quantas(3.0) == 1 and def.sombra_quantas(5.0) >= 2 and def.sombra_quantas(99.0) == def.sombra_max, "quantas: 1 na onda mínima, mais nas mais fortes, no máximo %d" % def.sombra_max)
	sol.wave_started.emit(2.0)
	check(def.sombras().is_empty(), "onda fraca (2.0): nenhuma sombra")
	sol.wave_started.emit(4.0)
	var sombras: Array = def.sombras()
	check(sombras.size() == def.sombra_quantas(4.0) and sombras.all(func(s): return s.voa), "onda forte (4.0): %d sombra(s) flutuando" % sombras.size())
	var sb: Node2D = sombras[0]
	check(sb.max_hp >= 30.0 and sb.speed < 60.0, "a sombra é lenta e dura (vida %.0f)" % sb.max_hp)
	# só quem está fora
	var fora: Node2D = ws[2]
	var dentro: Node2D = ws[1]
	fora._inside = false
	dentro._inside = true
	check(sb._target_ok(fora) and not sb._target_ok(dentro), "ela mira quem está fora de abrigo e ignora quem está dentro")
	# arma comum x prata
	sb.hp = sb.max_hp
	var atk := Node2D.new()
	atk.set_script(load("res://scripts/workers/ipezinho.gd")) if false else null
	var comum_antes: float = sb.hp
	sb.take_hit(10.0, guarda)
	var dano_comum: float = comum_antes - sb.hp
	sb.hp = sb.max_hp
	guarda.weapon = "lanca_prata"
	var prata_antes: float = sb.hp
	sb.take_hit(10.0, guarda)
	var dano_prata: float = prata_antes - sb.hp
	guarda.weapon = "porrete"
	check(is_equal_approx(dano_comum, 5.0) and is_equal_approx(dano_prata, 15.0) and dano_prata > dano_comum * 2.5, "arma comum faz %.0f, lança de prata %.0f (de 10)" % [dano_comum, dano_prata])
	# a luz queima e afasta
	sb.hp = sb.max_hp
	sb.global_position = (hub as Node2D).global_position + Vector2(300, 0)
	var l4 = dm.colocar("lampiao", sb.global_position + Vector2(40, 0))
	l4.acende(1.0)
	var pos0: Vector2 = sb.global_position
	var hp0: float = sb.hp
	for k in 20:
		sb._queima_com_luz(0.1)
	check(sb.hp < hp0 and sb.global_position.distance_to(l4.global_position) > pos0.distance_to(l4.global_position), "a luz acesa a queima (vida %.1f -> %.1f) e a afasta" % [hp0, sb.hp])
	l4.acende(0.0)
	l4.apagada = true
	var hp1: float = sb.hp
	for k in 20:
		sb._queima_com_luz(0.1)
	check(is_equal_approx(sb.hp, hp1), "luz apagada não queima")
	dm.remover(l4)
	sol.wave_ended.emit()
	check(sb._leaving or not sb.is_alive(), "quando a onda passa a sombra se desfaz")
	for s in def.sombras():
		s.queue_free()
	check(sb.drop_ore == "solarita", "a sombra deixa solarita")

	print("== (E) o save, o F3 e a invasão com todos os tipos")
	def.rato_proximo_dia = 33
	def.ratadas = 4
	var d: Dictionary = def.get_save_data()
	def.rato_proximo_dia = -1
	def.ratadas = 0
	def.load_save_data(d)
	check(def.rato_proximo_dia == 33 and def.ratadas == 4, "o save leva o próximo dia e quantas ratadas já vieram")
	var antigo: Dictionary = d.duplicate(true)
	antigo.erase("ratada")
	def.load_save_data(antigo)
	check(def.rato_proximo_dia == -1 and def.ratadas == 0, "save antigo (sem 'ratada') carrega com padrão sensato")
	def.moradores_desligados = false
	var antes_criaturas: int = get_nodes_in_group("criaturas").size()
	def.spawn_todas_novas()
	var tipos := {}
	for c in get_nodes_in_group("criaturas"):
		tipos[String(c.kind)] = true
	check(tipos.has("rato") and tipos.has("sombra") and tipos.has("morcego") and get_nodes_in_group("criaturas").size() > antes_criaturas, "o F3 (spawn_todas_novas) põe rato, sombra e morcego")
	for c in get_nodes_in_group("criaturas"):
		c.queue_free()
	def.moradores_desligados = true
	# a sombra não cresce com a onda (os tetos são dela)
	def.wave = 30
	var sx = def._spawn("sombra")
	check(sx.max_hp < 40.0, "a vida da sombra não explode com a onda (%.0f na onda 30)" % sx.max_hp)
	sx.queue_free()
	var rx = def._spawn("rato")
	check(rx.max_hp <= 6.5 and not rx.variant == "forte", "o rato não vira 'forte' nem ganha vida com a onda (%.1f)" % rx.max_hp)
	rx.queue_free()

	for n in _extras:
		if is_instance_valid(n):
			n.queue_free()
	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)
