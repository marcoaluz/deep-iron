extends SceneTree
## Bloco 99: ENTRADA DA MINA, ELEVADOR, ESCADA EM ESPIRAL E VAGONETE. (A) O elevador do S2 começa em ruína e é
## restaurado por 3 etapas (pedidas e feitas pelo engenheiro, em paralelo com a escavadeira); a ligação só anda com ele
## restaurado e o S2 aberto. (B) A viagem de verdade: fila, embarque, a cabine andando e o desembarque no andar certo.
## (C) O cabo gasta e arrebenta: a ligação some, o conserto vira obra com material e a ESCADA EM ESPIRAL leva quem
## estava embaixo (ninguém fica preso); consertado, volta. (D) A espiral abre junto com o andar e o caminho prefere o
## elevador. (E) Com a área de mina, o trilho e o vagonete funcionando, o mineiro ENTRA pela boca e trabalha lá dentro
## ("dentro N/5", lanterna, o minério vai pro ponto e sai da jazida); sai no almoço e volta; trilho quebrado: sai e
## minera na mão. (F) Cargas grandes (100 / 240 / 60 s) e o desgaste por minério. (G) Save: etapa e cabine voltam;
## save antigo com o S2 aberto = elevador restaurado. (H) As escadas de mão do paredão saíram. RODAR SÓ COM APPDATA ISOLADO.
const ObraSite := preload("res://scripts/core/obra_site.gd")
var main: Node
var fails := 0
var _t0 := 0


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
	load("res://scripts/props/armazem.gd").limite_desligado = true  # (o limite do armazém não é o assunto)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_t0 = Time.get_ticks_msec()
	_roda()


## Trava de segurança: emperrou (erro no meio da corrotina) = termina com falha, sem ficar pendurado.
func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - _t0 > 480000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		Engine.time_scale = 1.0
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func _espera(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += root.get_process_delta_time()


## Espera até `cond` ficar verdadeira (no máximo `s` segundos de jogo). Devolve se ficou.
func _ate(cond: Callable, s: float) -> bool:
	var t := 0.0
	while t < s:
		if cond.call():
			return true
		await process_frame
		t += root.get_process_delta_time()
	return cond.call()


func _hora(h: float) -> void:
	var dn = g("day_night")
	dn._pula_para(dn.tempo_da_hora(h))


func termina_obra(o: Node) -> void:
	var site = ObraSite.de(o)
	if site:
		for k in site.necessario:
			site.entregar(k, float(site.necessario[k]))
	o.obra_work(9999.0)


func _caminho(de: Vector2, ate: Vector2) -> PackedVector2Array:
	var map: RID = main.get_world_2d().navigation_map
	return NavigationServer2D.map_get_path(map, de, ate, true)


func _chega(de: Vector2, ate: Vector2) -> bool:
	var p := _caminho(de, ate)
	return not p.is_empty() and p[p.size() - 1].distance_to(ate) < 30.0


func _passa_perto(p: PackedVector2Array, ponto: Vector2, raio: float) -> bool:
	for q in p:
		if q.distance_to(ponto) <= raio:
			return true
	return false


func _roda() -> void:
	for i in 12:
		await process_frame
	await _espera(3.0)
	var eco = g("economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	var el = g("elevador")
	var env = g("environment")
	eco.credits = 99999.0
	arm.stock["ferro"] = 2000.0
	arm.wood_stored = 2000.0
	arm._recount()
	eco.add_item("prego", 100.0)
	eco.add_item("barra_ferro", 400.0)  # (a partir da fornalha o ferro das obras é em barras)
	_hora(8.0)
	var ws := get_nodes_in_group("ipezinhos")
	for w in ws:
		w.auto_mode = false

	print("== A) o elevador: ruína, 3 etapas em paralelo com a escavadeira")
	check(el.etapa == 0 and not el.restaurado() and not el.unlocked and not el.get_node("Link").enabled, "começa em ruína, fechado (sem ligação)")
	check(el.panel_id == "elevador" and g("hud")._panels.has("elevador"), "janela do elevador")
	hub.level = 1
	check(el.etapa_block_reason() == "", "a 1ª etapa (%s) libera no estágio 1, antes da escavadeira ('%s')" % [el.etapa_nome(1), el.etapa_block_reason()])
	check(el.pedir_etapa() and el.pago and el.obra_pending() and ObraSite.de(el).tem_material(), "pediu: vira obra de engenheiro com material")
	termina_obra(el)
	check(el.etapa == 1 and not el.pago, "1ª etapa pronta")
	check(el.etapa_block_reason().begins_with("precisa da vila"), "a 2ª pede a vila no estágio 2 ('%s')" % el.etapa_block_reason())
	hub.level = 2
	check(el.pedir_etapa(), "2ª etapa pedida")
	termina_obra(el)
	check(el.pedir_etapa(), "3ª etapa pedida")
	termina_obra(el)
	check(el.restaurado() and not el.unlocked and not el.get_node("Link").enabled, "restaurado ANTES da escavadeira: ainda fechado (o S2 abre com ela)")
	el.unlock(false)
	await _espera(0.5)
	check(el.unlocked and el.funcionando() and el.get_node("Link").enabled, "a escavadeira abriu o S2: a cabine anda")

	print("== D) a escada em espiral abre com o andar; o caminho prefere o elevador")
	var esp := get_nodes_in_group("espirais")
	check(esp.size() >= 1 and esp.any(func(e): return e.ligacao == el and e.aberta() and e.get_node("Link").enabled), "a espiral do S2 aberta (%d escadas)" % esp.size())
	var vila: Vector2 = hub.global_position + Vector2(0, 80)
	var s2: Vector2 = el.bottom_position + Vector2(-40, 30)
	await _espera(0.5)
	var p := _caminho(vila, s2)
	check(_chega(vila, s2) and _passa_perto(p, el.global_position, 20.0), "da vila ao S2 o caminho passa pelo elevador")

	print("== B) a viagem: fila, embarque, a cabine andando, desembarque no S2")
	Engine.time_scale = 4.0
	var w = ws[0]
	w.global_position = el.global_position + Vector2(-40, 30)
	var t0: int = el.cabine.total_viagens
	w.move_to(s2)
	var na_fila := await _ate(func(): return w.na_cabine(), 20.0)
	check(na_fila and el.cabine.tem(w), "chegou na gaiola: entrou na fila / na cabine")
	var andou := await _ate(func(): return el.cabine.pos > 0.2 and el.cabine.dentro(w), 15.0)
	check(andou, "embarcou e a cabine desce pelo poço (pos %.2f)" % el.cabine.pos)
	var chegou := await _ate(func(): return not w.na_cabine() and env.level_at(w.global_position) == 2, 30.0)
	check(chegou and el.cabine.total_viagens > t0, "desembarcou no S2 (andar %d), viagem contada (%d)" % [env.level_at(w.global_position), el.cabine.total_viagens])
	await _espera(3.0)
	check(w.global_position.distance_to(s2) < 40.0, "e seguiu até o destino lá embaixo (a %.0f px)" % w.global_position.distance_to(s2))

	print("== C) o cabo arrebenta: a espiral leva quem está embaixo; o conserto é obra com material")
	el.cabine.viagens = el.viagens_ate_quebrar - 1
	var w2 = ws[1]
	w2.global_position = el.global_position + Vector2(-40, 30)
	w2.move_to(s2)
	var quebrou := await _ate(func(): return el.cabine.quebrada, 40.0)
	check(quebrou and not el.get_node("Link").enabled, "o cabo arrebentou (depois de %d viagens): a ligação some" % el.viagens_ate_quebrar)
	check(el.cabine.consertando and el.obra_pending() and ObraSite.de(el).tem_material(), "o conserto foi pedido sozinho, com material, pro engenheiro")
	check(not w2.na_cabine() or w2.get("_a_bordo") == false, "ninguém ficou preso dentro (quebra sempre na chegada)")
	await _espera(1.0)
	var sobe: Vector2 = vila
	check(_chega(w.global_position, sobe), "com o elevador quebrado, do S2 dá pra subir (pela espiral)")
	var pe := _caminho(w.global_position, sobe)
	var esp_s2: Node = esp.filter(func(e): return e.ligacao == el)[0]
	check(_passa_perto(pe, esp_s2.fundo, 25.0), "o caminho vai pela escada em espiral")
	w.move_to(sobe)
	var na_escada := await _ate(func(): return w._cage_wait > 0.0, 30.0)
	check(na_escada, "entrou na escada (some e sobe devagar: %.0f s por andar)" % esp_s2.segundos_por_andar)
	var subiu := await _ate(func(): return env.level_at(w.global_position) == 0 and w._cage_wait <= 0.0, 40.0)
	check(subiu, "chegou na superfície pela espiral (ninguém fica preso embaixo)")
	termina_obra(el)
	await _espera(0.5)
	check(not el.cabine.quebrada and el.funcionando() and el.get_node("Link").enabled and el.cabine.viagens == 0, "consertado: a cabine volta a andar (cabo novo)")
	Engine.time_scale = 1.0

	print("== F) o vagonete: cargas grandes e desgaste por minério")
	var est: Node = g("bocas_mina")
	check(est != null and est.tem_interior and est.is_in_group("ponto_carga_fixo"), "a boca principal tem a galeria de dentro")
	check(est.cart_capacity == 100.0 and est.buffer_capacity == 240.0 and est.cart_wait == 60.0, "100 por viagem, guarda 240, espera até 60 s")
	var r0: float = est.rail_left
	est.stock = {"ferro": 100.0}
	est._wait_t = est.cart_wait
	Engine.time_scale = 4.0
	var voltou := await _ate(func(): return est.cart_state == "esperando" and est.total_moved >= 100.0, 60.0)
	Engine.time_scale = 1.0
	check(voltou and is_equal_approx(r0 - est.rail_left, 100.0 / est.desgaste_ref), "uma viagem de 100 gasta %.1f do trilho (= 4 viagens de 25: o mesmo desgaste por minério)" % (r0 - est.rail_left))

	print("== E) os mineiros dentro da mina")
	hub.level = 5
	for j in get_nodes_in_group("minerios"):
		if j.has_method("on_unlock_changed"):
			j.on_unlock_changed(false)
	var wa = g("work_areas")
	var area = wa.criar("mina", Rect2(640, -520, 540, 400))
	check(area != null, "área de mina na montanha (a boca principal dentro)")
	for x in ws:
		x.auto_mode = true
		x.set_job("ocioso")
	wa.ativar(area, true)
	var n_area: int = wa.definir(area, 2)
	var mineiros: Array = area.vivos()
	check(n_area == 2, "2 mineiros na área")
	for m in mineiros:
		m.hunger = m.hunger_max  # (alimentados: o teste é a mina, não a fome)
		m.refeicoes_hoje = {"cafe": true}
	_hora(8.5)
	Engine.time_scale = 4.0
	var entraram := await _ate(func(): return est.dentro.size() == 2, 60.0)
	check(entraram and mineiros.all(func(m): return m.dentro_da_mina() and not m.visible), "entraram pela boca e sumiram do mundo (dentro: %d)" % est.dentro.size())
	await _espera(1.0)
	check("dentro: 2/5" in est.get_node("StatusLabel").text and est._lanterna.enabled, "na boca: 'dentro da mina 2/5' e a lanterna acesa")
	var b0: float = est.buffered() + est.total_moved
	var jaz := get_nodes_in_group("minerios").filter(func(j): return area.contem(j.global_position))
	var ore0: float = 0.0
	for j in jaz:
		ore0 += j.ore_remaining
	await _espera(23.0)  # ~1 h de jogo
	var prod: float = est.buffered() + est.total_moved - b0
	var ore1: float = 0.0
	for j in jaz:
		ore1 += j.ore_remaining
	check(prod > 10.0, "lá dentro sai minério pro ponto (%.1f em ~1 h com 2: a meta é ~%d/h cada)" % [prod, int(est.taxa_dentro)])
	check(ore1 < ore0 + 2.0 * jaz.size() * 22.5, "e ele sai da jazida da área (nada de minério infinito)")
	_hora(12.1)  # o almoço
	var sairam := await _ate(func(): return est.dentro.is_empty() and mineiros.all(func(m): return not m.dentro_da_mina() and m.visible), 30.0)
	check(sairam, "na hora do almoço saíram pela boca")
	_hora(13.2)
	var voltaram := await _ate(func(): return est.dentro.size() == 2, 60.0)
	check(voltaram, "depois do almoço voltaram pra dentro")
	est.rail_left = 0.0  # o trilho quebrou
	var na_mao := await _ate(func(): return est.dentro.is_empty() and mineiros.all(func(m): return not m.dentro_da_mina()), 30.0)
	check(na_mao, "trilho quebrado: saem e mineram na mão como antes (nada trava)")
	var algum_minerando := await _ate(func(): return mineiros.any(func(m): return m.get_state() in ["mining", "storing"]), 30.0)
	check(algum_minerando, "minerando na mão (%s)" % str(mineiros.map(func(m): return m.get_state())))
	Engine.time_scale = 1.0

	print("== G) save: a etapa e a cabine voltam; save antigo com o S2 aberto = restaurado")
	el.cabine.viagens = 7
	var d: Dictionary = el.get_save_data()
	el.load_save_data(d)
	check(el.restaurado() and el.unlocked and el.cabine.viagens == 7, "salvou e carregou (etapa %d, %d viagens no cabo)" % [el.etapa, el.cabine.viagens])
	el.load_save_data({"unlocked": true})
	check(el.restaurado() and el.funcionando() and not el.cabine.quebrada, "save antigo com o S2 aberto: o elevador vem restaurado e inteiro")
	el.load_save_data({"unlocked": false})
	check(el.etapa == 0 and not el.restaurado(), "save antigo fechado: ruína, como na partida nova")
	est.load_save_data({"rail_left": 25, "stock": {}})
	check(is_equal_approx(est.rail_left, 25.0), "o trilho do save antigo (inteiro) carrega")

	print("== H) as escadas de mão do paredão saíram")
	var escadas := 0
	for n in env.get_children():
		if n.has_meta("iso_prop") and String(n.get_meta("iso_prop")) == "escada_mao" and env.level_at((n as Node2D).global_position) == 0:
			escadas += 1
	check(escadas == 0, "nenhuma escada de mão na superfície (%d)" % escadas)

	print("\nFALHAS: %d" % fails)
	quit()
