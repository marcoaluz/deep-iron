extends SceneTree
## Bloco 52: painel de debug (F3, só em build de debug) e telemetria (CSV por dia de jogo).
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var fails := 0
var dia0 := 0


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
	if t > 90.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		_painel()
		t = 3.0
	elif step == 1 and t > 4.0:
		step = 2
		_telemetria()
		Engine.time_scale = 1.0
		print("FALHAS: %d" % fails)
		return true
	return false


func _painel() -> void:
	print("== painel de debug")
	var dbg = main.get_node_or_null("DebugPanel")
	check(OS.is_debug_build() and dbg != null, "em build de debug o painel existe")
	if dbg == null:
		return
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_F3
	dbg._unhandled_input(ev)
	check(dbg._painel.visible, "F3 abre")
	var eco = g("economy")
	var c0: float = eco.credits
	dbg._creditos()
	check(is_equal_approx(eco.credits, c0 + 1000.0), "+1000 créditos")
	var arm = g("armazens")
	var f0: float = arm.stock.ferro
	dbg._minerio()
	check(arm.stock.ferro >= f0 + 199.0, "+200 de cada minério")
	var m0: float = arm.wood_stored
	dbg._madeira()
	check(arm.wood_stored >= m0 + 199.0, "+200 madeira")
	dbg._tempo(4.0)
	check(is_equal_approx(Engine.time_scale, 4.0), "tempo x4")
	dbg._tempo(1.0)
	var dn = g("day_night")
	dia0 = dn.day
	dbg._dia()
	check(dn.day == dia0 + 1, "pular dia (%d -> %d)" % [dia0, dn.day])
	for i in 9:  # partida de 10 dias pra telemetria
		dbg._dia()
	check(dn.day == dia0 + 10, "mais 9 dias (dia %d)" % dn.day)
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w.hurt("mina", "leve")
	dbg._curar()
	check(not w.injured, "curar todos")
	var res = g("research")
	dbg._pesquisas()
	check(res.done.size() >= res.ORDER.size() - 4, "liberar pesquisas (%d de %d; as de escolha ficam com uma)" % [res.done.size(), res.ORDER.size()])
	var d = g("defense")
	dbg._invasao()
	check(d.invasion_active, "invasão agora")


func _telemetria() -> void:
	print("== telemetria")
	var tel = main.get_tree().get_first_node_in_group("telemetria")
	check(tel != null and FileAccess.file_exists(tel.arquivo), "CSV da partida criado")
	if tel == null:
		return
	var linhas := FileAccess.get_file_as_string(tel.arquivo).strip_edges().split("\n")
	check(linhas[0].begins_with("dia,estacao,tempo_real_s,creditos"), "cabeçalho com as colunas")
	check(linhas.size() == 11, "10 dias = 10 linhas (+ cabeçalho: %d)" % linhas.size())
	var ok := true
	for i in range(1, linhas.size()):
		var cols := linhas[i].split(",")
		if cols.size() != tel.COLUNAS.size() or int(cols[0]) != dia0 + i:
			ok = false
			print("    linha %d: %s" % [i, linhas[i]])
	check(ok, "cada linha com o dia certo e as %d colunas" % tel.COLUNAS.size())
	print("    " + linhas[linhas.size() - 1])
