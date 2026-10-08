extends SceneTree
## Bloco 68: níveis temáticos por dados (res://data/niveis/*.tres): leitura, ordem, nível de cada
## ponto, liberação com motivo (ligação, pesquisa, em breve), a pesquisa Trajes trava o S3, a
## gaiola do elevador leva tempo e tem lotação, o corte da mina lê os dados. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const Niveis := preload("res://scripts/core/niveis.gd")
var main: Node
var t := 0.0
var step := 0
var fails := 0


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
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		_dados()
		_liberacao()
		_gaiola()
		_corte()
		print("FALHAS: %d" % fails)
		return true
	return false


func _dados() -> void:
	print("== dados")
	var ns: Array = Niveis.todos()
	check(ns.size() == 6, "6 níveis declarados (%d)" % ns.size())
	var ok_ordem := true
	for i in range(1, ns.size()):
		if ns[i].profundidade < ns[i - 1].profundidade:
			ok_ordem = false
	check(ok_ordem, "em ordem de profundidade")
	check(Niveis.por_id("S2").perigo == "gas" and Niveis.por_id("S3").traje == "calor" and Niveis.por_id("S3").pesquisa == "trajes", "perigo, traje e pesquisa vêm do .tres")
	check(not Niveis.por_id("S4").em_breve and not Niveis.por_id("S5").em_breve and Niveis.jogaveis().size() == 6, "S4 e S5 jogáveis (Bloco 71)")
	var env = g("environment")
	check(Niveis.do_ponto(env, g("village_hub").global_position).id == "S1", "a vila fica no S1")
	check(Niveis.do_ponto(env, env.deep_rect.get_center()).id == "S2" and Niveis.do_ponto(env, env.abyss_rect.get_center()).id == "S3", "nível 2 = S2, abismo = S3")
	check(Niveis.do_ponto(env, env.clearing_rect.get_center()).id == "S0", "a clareira = S0")


func _liberacao() -> void:
	print("== liberação")
	var tree := main.get_tree()
	check(Niveis.motivo(tree, Niveis.por_id("S1")) == "", "S1 liberado")
	check("escavadeira" in Niveis.motivo(tree, Niveis.por_id("S2")), "S2 fechado: %s" % Niveis.motivo(tree, Niveis.por_id("S2")))
	check("plataforma" in Niveis.motivo(tree, Niveis.por_id("S4")), "S4: fechado até consertar a plataforma (%s)" % Niveis.motivo(tree, Niveis.por_id("S4")))
	g("elevador").unlock(false)
	check(Niveis.motivo(tree, Niveis.por_id("S2")) == "", "escavadeira pronta: S2 abre")
	var s3: String = Niveis.motivo(tree, Niveis.por_id("S3"))
	check("Trajes" in s3, "S3 pede a pesquisa (%s)" % s3)
	var ab = g("elevador_abismo")
	check("Trajes" in ab.repair_block_reason(), "a plataforma do abismo não conserta sem a pesquisa")
	g("research")._finish("trajes")
	check(not ("Trajes" in ab.repair_block_reason()), "com Trajes: o conserto segue (%s)" % ab.repair_block_reason())
	ab.unlocked = true
	check(Niveis.motivo(tree, Niveis.por_id("S3")) == "", "plataforma aberta: S3 liberado")


func _gaiola() -> void:
	# Bloco 99: a gaiola virou a CABINE de verdade (cabine.gd): o ipezinho entra na fila em cima, espera parado, embarca,
	# a cabine anda e ele desembarca lá embaixo. (O teste da viagem completa e da quebra fica no b99.)
	print("== gaiola do elevador (a cabine do Bloco 99)")
	var sh = g("elevador")
	sh.restaura_tudo()
	sh.unlock(false)
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w._on_link_reached({"owner": sh.get_node("Link"), "link_entry_position": sh.global_position, "link_exit_position": sh.bottom_position})
	check(w.na_cabine() and sh.cabine.tem(w) and w.global_position.distance_to(sh.global_position) < 40.0, "ipezinho na gaiola: entra na fila em cima e espera a cabine")
	var p0: Vector2 = w.global_position
	w._moving = true
	w._target = p0 + Vector2(100, 0)
	w._physics_process(0.1)
	check(w.global_position.distance_to(p0) < 0.5, "na fila da cabine não anda")
	check(sh.capacity == sh.cabine.capacidade and sh.cabine.capacidade >= 1, "cabem %d de cada vez" % sh.capacity)
	w._sai_da_fila()


func _corte() -> void:
	print("== corte da mina")
	var c = g("hud")._corte
	var ids: Array = c.ANDARES.map(func(a): return a.id)
	check(ids == ["S0", "S1", "S2", "S3", "S4", "S5"], "andares do corte vêm dos dados (%s)" % str(ids))
	check(c.EM_BREVE.is_empty(), "nenhum em breve (Bloco 71 abriu S4 e S5)")
