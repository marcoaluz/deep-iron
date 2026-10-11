extends SceneTree
## Bloco 127: SIMULAÇÃO de UMA invasão (balanceamento da linha de frente). RODAR SÓ COM APPDATA ISOLADO.
## Uso: godot --headless --path project.godot -s res://../tools/sim_invasao.gd -- <guardas> <habilidade 0..1> <onda> <nivel_portao> [modelo]
## (o script fica em tools/; copie/aponte com -s <caminho absoluto>). Imprime UMA linha "SIM modelo;guardas;hab;onda;nivel;..." com:
##   derrubadas/total, guardas caídos (distintos), portão (hp restante / máximo), minério e créditos roubados, prédios feridos,
##   segundos de jogo até acabar (todas derrubadas) ou o teto. Só usa API que existe antes e depois do Bloco 127.
var main: Node
var p: PackedStringArray


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	p = OS.get_cmdline_user_args()
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	load("res://scripts/core/defense.gd").moradores_desligados = true
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _minerio(arm: Node) -> float:
	var s := 0.0
	for k in arm.stock:
		s += float(arm.stock[k])
	return s


func _roda() -> void:
	for i in 5:
		await process_frame
	var n_guardas := int(p[0]) if p.size() > 0 else 3
	var hab := float(p[1]) if p.size() > 1 else 0.0
	var onda := int(p[2]) if p.size() > 2 else 1
	var nivel := int(p[3]) if p.size() > 3 else 1
	var modelo := p[4] if p.size() > 4 else "?"
	var arma := p[6] if p.size() > 6 else "porrete"  # (p[5] é o "diag")
	var def := g("defense")
	var dn := g("day_night")
	var eco := g("economy")
	g("eventos").ligado = false
	g("pedidos").ligado = false
	var gate: Node2D = g("barricadas")
	gate.level = nivel
	gate.hp = gate.max_hp()
	gate._update_visual()
	gate._snap = true
	var ws := get_nodes_in_group("ipezinhos")
	for i in ws.size():
		var w: Node = ws[i]
		if i < n_guardas:
			w.set_job("guarda")
			w.combat_skill = hab
			w.weapon = arma
			w.weapon_durability = 45.0
			w.combat_hp = w.guard_max_hp()
		else:
			w.set_job("minerador")
	var arm: Node = g("armazens")
	arm.limite_desligado = true
	arm.stock["ferro"] = 300.0
	arm.stock["cobre"] = 100.0
	arm._recount()
	eco.credits = 500.0
	var ore0 := _minerio(arm)
	var cr0: float = eco.credits
	# os guardas já estão no posto quando a invasão começa (na partida de verdade eles estão lá desde o fim da tarde)
	var world: Node2D = g("village_hub").get_parent()
	var nav: RID = world.get_world_2d().navigation_map
	for w in get_nodes_in_group("ipezinhos"):
		if w.is_guard():
			var post: Vector2 = def.guard_post_ativo(w) if def.has_method("guard_post_ativo") else def.guard_post(w)
			w.global_position = NavigationServer2D.map_get_closest_point(nav, post)
	def.wave = maxi(onda - 1, 0)
	dn.time = def.tempo_invasao() + 1.0
	Engine.time_scale = 10.0
	await process_frame
	def.start_invasion()
	var total: int = int(def.last_result.get("total", 0))
	var t0: float = dn.time
	var caidos := {}
	var fim := ""
	var tmax := 400.0  # segundos de jogo
	var diag := p.size() > 5 and p[5] == "diag"  # imprime o estado a cada 20 s de jogo (achar criatura parada)
	var prox_diag := 20.0
	while true:
		await process_frame
		if diag and dn.time - t0 >= prox_diag:
			prox_diag += 20.0
			print("  t=%d portao=%d" % [roundi(dn.time - t0), roundi(gate.hp)])
			for c in get_nodes_in_group("criaturas"):
				if is_instance_valid(c) and c.is_alive():
					var ag: NavigationAgent2D = c.get_node("Agent")
					print("    criatura %s hp=%d pos=%s alvo=%s inside=%s nav_fim=%s dist_alvo=%d" % [c.kind, roundi(c.hp), c.global_position.round(),
						(c._target.name if c._target != null and is_instance_valid(c._target) else "-"), str(c.inside), str(ag.is_navigation_finished()),
						roundi(c.global_position.distance_to(c._target.global_position)) if c._target != null and is_instance_valid(c._target) else -1])
			for w in get_nodes_in_group("ipezinhos"):
				if w.is_guard():
					var foe = w.get("_foe")
					var dfoe := -1.0
					if foe != null and is_instance_valid(foe):
						dfoe = w.global_position.distance_to(foe.global_position)
					print("    guarda %s pos=%s st=%s hp=%d rec=%s caido=%s moving=%s foe_dist=%d nav_fim=%s" % [w.display_name, w.global_position.round(), w.get_state(),
						roundi(w.combat_hp), str(w.get("recuando")), str(w.downed), str(w.get("_moving")), roundi(dfoe),
						str(w.get_node("Agent").is_navigation_finished())])
		if dn.time < t0:
			fim = "amanheceu"
			break
		for w in get_nodes_in_group("ipezinhos"):
			if w.get("downed") == true:
				caidos[w.get_instance_id()] = true
		var vivas := 0
		for c in get_nodes_in_group("criaturas"):
			if is_instance_valid(c) and c.is_alive():
				vivas += 1
		var fila: int = (def._spawn_queue as Array).size()
		if vivas == 0 and fila == 0 and dn.time - t0 > 5.0:
			fim = "limpou"
			break
		if dn.time - t0 > tmax:
			fim = "teto"
			break
	var estr := g("estruturas")
	var feridos := 0
	if estr and estr.has_method("feridos"):
		feridos = estr.feridos().size()
	var portao := 0
	if gate.is_standing():
		portao = roundi(100.0 * gate.hp / maxf(gate.max_hp(), 1.0))
	print("SIM %s;arma=%s;guardas=%d;hab=%.1f;onda=%d;nivel=%d;derrubadas=%d/%d;guardas_caidos=%d;portao_pct=%d;minerio_perdido=%d;creditos_perdidos=%d;predios_feridos=%d;segundos=%d;fim=%s" % [
		modelo, arma, n_guardas, hab, onda, nivel, int(def.killed_tonight), total, caidos.size(), portao,
		roundi(ore0 - _minerio(arm)), roundi(cr0 - float(eco.credits)), feridos, roundi(dn.time - t0), fim])
	Engine.time_scale = 1.0
	quit()
