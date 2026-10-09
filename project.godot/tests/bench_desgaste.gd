extends SceneTree
## Bloco 105: MEDIÇÃO do desgaste no ritmo padrão (não é teste: é a telemetria pro Marco aprovar o balanceamento).
## Uma vila em operação contínua, no relógio NORMAL do jogo (dia de 540 s reais; o Engine.time_scale só acelera a
## simulação, as taxas por segundo de jogo são as de sempre), a agenda de verdade (dormir, refeições, hora social):
##   escavadeira ligada (reator a vapor, carvão de sobra), o coletor de madeira restaurado com 1 lenhador designado, o coletor
##   de minério com 1 minerador designado, 2 ventiladores no S2 (o S2 aberto e o elevador restaurado, como o F3 "abrir todos"); o resto da vila trabalhando (mineradores, lenhador).
## O armazém sem limite (limite_desligado) pra medir a máquina, não o armazém cheio.
## A cada hora de jogo imprime "DADO;hora;..." (condição e eficiência de cada máquina, o que cada uma produziu, a
## proteção do ventilador, quebras, preventivas, consertos). No fim, "RESUMO;...".
## Uso: godot --headless --path . -s res://tests/bench_desgaste.gd -- cfg=padrao|sem_desgaste|com_mecanico|vida_meia|vida_dobro dias=3
## RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var cfg := "padrao"
var dias := 3.0
var pronto := false
var iniciou := false
var hora_ant := -1
var maqs: Dictionary = {}  # nome -> máquina
var prod: Dictionary = {}  # nome -> produção acumulada (minério/madeira)
var primeira_quebra: Dictionary = {}  # nome -> hora de jogo
var quebrou_ant: Dictionary = {}
var horas := 0.0
var mec: Node = null
var mec_ocupado := 0.0
var t0_real := 0
var vent_prot: Array = []
var pos_vent := Vector2(-300, 3600)


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("cfg="):
			cfg = a.substr(4)
		elif a.begins_with("dias="):
			dias = float(a.substr(5))
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
	load("res://scripts/core/defense.gd").moradores_desligados = true
	load("res://scripts/props/armazem.gd").limite_desligado = true
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	t0_real = Time.get_ticks_msec()


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 400, 10):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func prepara() -> void:
	var eco = g("economy")
	var arm = g("armazens")
	var hub = g("village_hub")
	var mt = g("manutencao")
	var sun = g("sun")
	var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
	sun.season_wave_chance = nunca
	g("defense").set("invasions_enabled", false)
	match cfg:
		"sem_desgaste":
			for k in mt.vida:
				mt.vida[k] = 1.0e12
		"vida_meia":
			for k in mt.vida:
				mt.vida[k] = float(mt.vida[k]) * 0.5
		"vida_dobro":
			for k in mt.vida:
				mt.vida[k] = float(mt.vida[k]) * 2.0
	while g("ipezinhos") and get_nodes_in_group("ipezinhos").size() < 9:
		eco.novo_ipezinho()
	eco.credits = 99999.0
	arm.stock["carvao"] = 5000.0
	arm.stock["ferro"] = 2000.0
	arm.wood_stored = 2000.0
	arm.raw_stored = 400.0
	arm._recount()
	# a escavadeira montada, reator a vapor ligado
	var esc = g("escavadeira")
	esc.complete = true
	if not esc.built_reactors.has("vapor"):
		esc.built_reactors.append("vapor")
	esc.reactor = "vapor"
	esc.drill_on = true
	maqs["escavadeira"] = esc
	# o coletor de madeira restaurado
	for m in get_nodes_in_group("maquinas"):
		if m.manut_tipo() == "coletor_madeira":
			m.etapa = 4
			maqs["coletor_madeira"] = m
	# o coletor de minério perto de uma jazida do S1
	var jaz: Node = null
	for j in get_nodes_in_group("minerios"):
		if j.has_method("is_unlocked") and j.is_unlocked() and j.ore_remaining > 200.0 and j.global_position.y < 1500.0:
			jaz = j
			break
	if jaz:
		var cm = load("res://scenes/props/coletor_minerio.tscn").instantiate()
		cm.position = spot_near(jaz.global_position + Vector2(50, 30))
		hub.get_parent().add_child(cm)
		maqs["coletor_minerio"] = cm
	# o S2 aberto e o elevador restaurado (como o "Andares: abrir todos" do F3): dá pra descer de cabine
	var ele = g("elevador")
	if ele and ele.has_method("unlock"):
		ele.unlock(false)
	if ele and ele.has_method("restaura_tudo"):
		ele.restaura_tudo()
	if ele:
		maqs["cabine"] = ele
	await process_frame
	await process_frame
	# 2 ventiladores no S2, presos na malha de navegação (o mecânico tem que chegar)
	var fundo = g("fundo")
	var mapa: RID = g("environment").navigation_region.get_navigation_map()
	for i in 2:
		var q: Vector2 = NavigationServer2D.map_get_closest_point(mapa, [Vector2(-300, 3600), Vector2(200, 3700)][i])
		maqs["ventilador%d" % (i + 1)] = fundo.spawn_ventilador(q)
	pos_vent = maqs.ventilador1.global_position
	await process_frame
	var ws: Array = get_nodes_in_group("ipezinhos")
	ws[0].set_job("lenhador")
	ws[1].set_job("lenhador")
	if maqs.has("coletor_madeira"):
		maqs.coletor_madeira.designate(ws[0])
	ws[2].set_job("minerador")
	if maqs.has("coletor_minerio"):
		maqs.coletor_minerio.designate(ws[2])
	ws[3].set_job("minerador")
	ws[4].set_job("minerador")
	ws[5].set_job("cozinheiro")
	ws[6].set_job("lenhador")
	if cfg in ["com_mecanico", "vida_meia"]:
		ws[7].set_job("mecânico")
		mec = ws[7]
	for k in maqs:
		prod[k] = 0.0
		quebrou_ant[k] = false
	# a produção de cada máquina, contada na fonte
	print("CFG;%s;vida=%s;mecanico=%s;armazem_sem_limite=1" % [cfg, str(mt.vida), mec != null])
	pronto = true


func _process(delta: float) -> bool:
	t += delta
	if t < 2.0:
		return false
	if not iniciou:
		iniciou = true
		_comeca()
		return false
	if not pronto:
		return false
	var dn = g("day_night")
	var mt = g("manutencao")
	if mec and is_instance_valid(mec) and mec.get_state() in ["manutencao", "building"]:
		mec_ocupado += delta
	for k in maqs:
		var m = maqs[k]
		if not is_instance_valid(m):
			continue
		var q: bool = m.manut_quebrada()
		if q and not quebrou_ant[k] and not primeira_quebra.has(k):
			primeira_quebra[k] = horas
		quebrou_ant[k] = q
	var sph: float = dn.segundos_por_hora()
	horas += delta / sph
	var h := int(horas)
	if h != hora_ant:
		hora_ant = h
		_linha(h)
	if horas >= dias * 24.0:
		_resumo()
		Engine.time_scale = 1.0
		quit()
		return true
	return false


func _comeca() -> void:
	await prepara()
	# conta a produção na fonte: o minério da escavadeira e do coletor entra no armazém; a madeira do coletor também
	var arm = g("armazens")
	arm.set_meta("bench_ore0", _total_minerio(arm))
	Engine.time_scale = 10.0


func _total_minerio(arm) -> float:
	var n := 0.0
	for k in arm.stock:
		if k != "carvao":
			n += float(arm.stock[k])
	return n


func _ef(m) -> float:
	if m.has_method("eficiencia"):
		return m.eficiencia()
	var d = m.get("_desgaste")
	return d.eficiencia() if d else 1.0


func _linha(h: int) -> void:
	var mt = g("manutencao")
	var fundo = g("fundo")
	var esc = maqs.escavadeira
	var cols: Array = ["DADO", cfg, h, g("day_night").hora_texto() if g("day_night").has_method("hora_texto") else ""]
	for k in ["escavadeira", "coletor_madeira", "coletor_minerio", "ventilador1", "ventilador2", "cabine"]:
		if maqs.has(k) and is_instance_valid(maqs[k]):
			cols.append("%s=%.3f/%.2f%s" % [k, maqs[k].manut_condicao(), _ef(maqs[k]), "Q" if maqs[k].manut_quebrada() else ""])
	cols.append("esc_minerio=%d" % int(esc.total_produced))
	cols.append("col_madeira=%d" % int(maqs.coletor_madeira.total_produced))
	if maqs.has("coletor_minerio"):
		cols.append("col_minerio=%d" % int(maqs.coletor_minerio.total_produced))
	if maqs.has("cabine"):
		cols.append("cabine_viagens=%d" % int(maqs.cabine.cabine.total_viagens))
	cols.append("vent_mult=%.2f" % fundo.ventilacao_mult(pos_vent))
	cols.append("nevoa=%.2f" % fundo.nevoa_mult())
	cols.append("quebras=%s" % JSON.stringify(mt.quebras))
	cols.append("preventivas=%d" % mt.preventivas)
	cols.append("consertos=%d" % mt.consertos_feitos)
	cols.append("mec_ocupado_h=%.1f" % (mec_ocupado / g("day_night").segundos_por_hora()))
	print(";".join(cols.map(func(x): return str(x))))


func _resumo() -> void:
	var mt = g("manutencao")
	var d := dias
	var linhas: Array = []
	for k in maqs:
		var m = maqs[k]
		var p = m.get("total_produced")
		linhas.append("%s:cond=%.3f,quebrada=%s,1a_quebra_h=%s,produziu=%s" % [k, m.manut_condicao(), m.manut_quebrada(), str(snappedf(primeira_quebra[k], 0.1)) if primeira_quebra.has(k) else "-", str(int(p)) if p != null else "-"])
	print("RESUMO;%s;dias=%.1f;%s;quebras=%s;quebras_por_dia=%.2f;preventivas=%d;consertos=%d;mec_ocupado_h=%.1f;tempo_real_s=%d" % [
		cfg, d, " | ".join(linhas), JSON.stringify(mt.quebras), float(mt.total_quebras()) / d, mt.preventivas, mt.consertos_feitos,
		mec_ocupado / g("day_night").segundos_por_hora(), (Time.get_ticks_msec() - t0_real) / 1000])
