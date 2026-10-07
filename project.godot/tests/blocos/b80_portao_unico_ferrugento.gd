extends SceneTree
## Bloco 80: o PORTÃO ÚNICO e o FERRUGENTO robô. Confere: o portão do poço saiu (só o da floresta,
## "tunel"); a invasão anda sem ele (antes e depois do nível 2 abrir); com o nível 2 aberto os guardas
## se dividem entre o portão e um POSTO na boca do poço; o Ferrugento (e o que vem do fundo) sai da boca
## do poço, sem barricada (entra direto, sem portão); o visual dele é a folha de quadros configurável
## (textura, quadro, quadros por animação) e troca de animação pelo estado; a BRECHA só abre no portão do
## túnel (guarda caído no posto do poço não abre); e um save antigo com o portão do poço (barricada
## "BarricadaPoco" e guarda caído com downed_gate "poco") carrega sem erro, ignorando esse portão.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var ferr: Node2D = null
var downed_name := ""


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
	return get_first_node_in_group(grupo)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func _limpa_criaturas() -> void:
	for c in get_nodes_in_group("criaturas"):
		if is_instance_valid(c) and c.is_alive():
			c.die(false)


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	for w in ws():
		w.hunger = w.hunger_max
	match step:
		0:
			if t > 4.0:
				_sem_portao_do_poco()
				_invasao_sem_nivel2()
				_postos()
				_ferrugento_no_poco()
				step = 1
				t_mark = t
		1:  # o Ferrugento anda um pouco (a caminhada pela distância)
			if t - t_mark > 1.5:
				_visual_andando()
				_brecha()
				_salva_antigo()
				step = 2
				t_mark = t
		2:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 5.0:
				_carregou()
				print("FALHAS: %d" % fails)
				return true
	return false


func _sem_portao_do_poco() -> void:
	print("== o portão do poço saiu")
	var def = g("defense")
	var ids: Array = get_nodes_in_group("barricadas").map(func(b): return b.gate_id)
	check(ids == ["tunel"], "só o portão da floresta (%s)" % [ids])
	check(def.gate("poco") == null and main.get_node("World").get_node_or_null("BarricadaPoco") == null, "nada de BarricadaPoco na cena")
	check(def.gate_label("tunel") == "portão da floresta" and def.gate_label("") == "posto do poço", "rótulos: portão da floresta / posto do poço")


func _invasao_sem_nivel2() -> void:
	print("== invasão antes do nível 2 (sem Ferrugento)")
	var def = g("defense")
	check(not def.level2_open(), "nível 2 fechado")
	check(def.posto_poco() == Vector2.INF, "sem posto no poço com o nível 2 fechado")
	def.start_invasion()
	check(def.invasion_active and def._spawn_queue.all(func(e): return e.kind == "lumivoro"), "a invasão começa só com Lumívoros (%d)" % def._spawn_queue.size())
	def._spawn_queue = []
	def.end_invasion()
	_limpa_criaturas()


func _postos() -> void:
	print("== nível 2 aberto: guardas no portão e no poço")
	var def = g("defense")
	g("elevador").unlock(false)
	check(def.level2_open(), "nível 2 aberto")
	var boca: Vector2 = def.boca_poco()
	var pp: Vector2 = def.posto_poco()
	check(pp != Vector2.INF and pp.distance_to(boca) < def.poco_post_dist + 1.0, "posto na boca do poço (%s)" % pp.round())
	var lista := ws()
	for i in mini(2, lista.size()):
		lista[i].set_job("guarda")
	var gs: Array = def.guards()
	check(gs.size() >= 2, "2 guardas")
	if gs.size() >= 2:
		var gate: Node2D = def.gate("tunel")
		var p0: Vector2 = def.guard_post(gs[0])
		var p1: Vector2 = def.guard_post(gs[1])
		check(p0.distance_to(gate.global_position) < 80.0, "um no portão da floresta (%s)" % p0.round())
		check(p1.distance_to(pp) < 40.0, "o outro no posto do poço (%s)" % p1.round())


func _ferrugento_no_poco() -> void:
	print("== o Ferrugento sai da boca do poço")
	var def = g("defense")
	def.invasion_active = true
	def._raided_gates = []
	ferr = def._spawn("ferrugento")
	var boca: Vector2 = def.boca_poco()
	check(ferr != null and ferr.kind == "ferrugento", "nasceu um Ferrugento")
	check(ferr.global_position.distance_to(boca) < 40.0, "na boca do poço (%d px)" % ferr.global_position.distance_to(boca))
	check(ferr.inside and ferr._gate == null and ferr.gate_id == "", "sem barricada no caminho: entra direto, sem portão")
	var gos = def._spawn("gosma")
	check(gos.global_position.distance_to(boca) < 40.0 and gos.inside and gos.gate_id == "", "o que vem do fundo também (Gosma)")
	print("== o visual configurável")
	check(ferr.visual_textura != null and ferr._visual.region_enabled, "desenha pela folha de quadros")
	check(ferr._visual.region_rect.size == Vector2(ferr.visual_quadro), "um quadro de %s" % ferr.visual_quadro)
	check(ferr.visual_anims.size() == ferr.visual_quadros.size(), "quadros por animação: %s" % [ferr.visual_quadros])
	check(preload("res://scripts/iso/iso_bonecos.gd").criatura_pose(ferr, 0, true).is_empty(), "sem a arte de máquina antiga")
	ferr._attack_at = ferr._anim
	ferr._atualiza_visual()
	var linha_atq: int = ferr.visual_anims.find("atacar")
	check(ferr.anim_atual()[0] == "atacar" and int(ferr._visual.region_rect.position.y) == linha_atq * ferr.visual_quadro.y,
		"atacando: a linha 'atacar' da folha")
	ferr._attack_at = -100.0
	ferr.set_meta("y_parado", ferr._visual.region_rect.position.y)


func _visual_andando() -> void:
	if ferr == null or not is_instance_valid(ferr):
		check(false, "o Ferrugento sumiu")
		return
	var linha_and: int = ferr.visual_anims.find("caminhada")
	check(ferr._andado > 0.0, "andou %d px" % ferr._andado)
	ferr._andando = true
	ferr._atualiza_visual()
	check(int(ferr._visual.region_rect.position.y) == linha_and * ferr.visual_quadro.y, "andando: a linha 'caminhada'")
	var iso = g("iso_view")
	var bb = iso.billboard_of(ferr) if iso else null
	check(bb != null, "tem espelho na vista iso")


func _brecha() -> void:
	print("== a brecha só no portão da floresta")
	var def = g("defense")
	var gs: Array = def.guards()
	var no_poco: Node = gs[1]
	no_poco.global_position = def.posto_poco()
	no_poco._fall_in_combat("ferrugento")
	check(no_poco.downed and no_poco.downed_gate == "", "caído no posto do poço: sem portão (%s)" % no_poco.downed_gate)
	check(not def.breached("") and not def.breached("poco") and not def.breached("tunel"), "não abre brecha")
	var no_tunel: Node = gs[0]
	no_tunel.global_position = def.gate("tunel").global_position + Vector2(30, 0)
	no_tunel._fall_in_combat("lumivoro")
	check(no_tunel.downed_gate == "tunel" and def.breached("tunel"), "caído no portão da floresta: brecha no túnel")
	check(not def.breached(""), "quem sai do poço não aproveita a brecha do túnel")
	downed_name = no_poco.display_name


func _salva_antigo() -> void:
	print("== save antigo com o portão do poço")
	_limpa_criaturas()
	g("defense").end_invasion()
	root.get_node("SaveManager").save_game("teste")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var bar: Dictionary = d.get("barricadas", {})
	bar["BarricadaPoco"] = {"level": 2, "hp": 200.0}
	d["barricadas"] = bar
	for wd in d.get("workers", []):
		if wd.get("display_name") == downed_name:
			wd["downed"] = true
			wd["injured"] = true
			wd["injury_severity"] = "grave"
			wd["downed_gate"] = "poco"
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	check(bar.has("BarricadaPoco"), "o save tem a BarricadaPoco e um guarda caído no 'poco'")


func _carregou() -> void:
	print("== depois de carregar")
	var def = g("defense")
	check(def != null and get_nodes_in_group("barricadas").size() == 1 and def.gate("poco") == null, "carregou sem o portão do poço")
	var w: Node = null
	for x in ws():
		if x.display_name == downed_name:
			w = x
	check(w != null and w.downed, "o guarda caído voltou caído")
	check(w != null and w.downed_gate == "", "downed_gate 'poco' ignorado (%s)" % (w.downed_gate if w else "?"))
	def.invasion_active = true
	check(not def.breached("poco") and not def.breached(""), "sem brecha fantasma do poço")
	def.invasion_active = false
	check(def.gate("tunel") != null, "o portão da floresta continua lá")
