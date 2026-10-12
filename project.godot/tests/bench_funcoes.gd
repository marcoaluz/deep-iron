extends SceneTree
## Bloco 135 (não é teste): o custo de DAR FUNÇÃO com 12 pessoas — uma por uma (selecionar + função, 24 vezes) e as 12 de uma
## vez (4 vezes) —, o pior quadro, a mediana e quantos quadros passam de 50 ms (a meta do bloco: nenhum).
## Com janela e APPDATA isolado (com janela as cargas em segundo plano valem; sem janela elas esperam, como nos testes):
##   <Godot>.exe --path . -s res://tests/bench_funcoes.gd -- <arquivo de saída>
var main: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func _roda() -> void:
	for i in 10:
		await process_frame
	var eco = get_first_node_in_group("economy")
	while get_nodes_in_group("ipezinhos").size() < 12:
		eco.novo_ipezinho("M")
	for f in 120:
		await process_frame  # (as cargas de segundo plano do começo assentam)
	var ws: Array = get_nodes_in_group("ipezinhos").slice(0, 12)
	var jobs := ["minerador", "lenhador", "cozinheiro", "guarda", "pesquisador", "engenheiro", "fundidor", "carregador"]
	var piores: Array = []
	var acima := 0
	var quadros := 0
	for rodada in 2:
		for k in ws.size():
			main.select(ws[k])
			await process_frame
			await process_frame
			var t0 := Time.get_ticks_usec()
			main.toggle_job(jobs[(k + rodada) % jobs.size()], "x", Color.WHITE)
			var maior := (Time.get_ticks_usec() - t0) / 1000.0
			for f in 8:
				var tf := Time.get_ticks_usec()
				await process_frame
				var q := (Time.get_ticks_usec() - tf) / 1000.0
				maior = maxf(maior, q)
				quadros += 1
				if q > 50.0:
					acima += 1
			piores.append(maior)
	piores.sort()
	var vezes12: Array = []
	for rodada in 4:
		main.selection.clear()
		for w in ws:
			main.selection.append(w)
		var t0 := Time.get_ticks_usec()
		main.toggle_job(jobs[(rodada + 4) % jobs.size()], "x", Color.WHITE)
		var maior := (Time.get_ticks_usec() - t0) / 1000.0
		for f in 8:
			var tf := Time.get_ticks_usec()
			await process_frame
			maior = maxf(maior, (Time.get_ticks_usec() - tf) / 1000.0)
		vezes12.append(maior)
	vezes12.sort()
	var linha := "%s | uma por uma (24): pior %.1f ms, mediana %.1f ms, quadros > 50 ms: %d de %d | as 12 de uma vez (4x): pior %.1f ms" % [
		DisplayServer.get_name(), piores[-1], piores[piores.size() / 2], acima, quadros, vezes12[-1]]
	print(linha)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var fa := FileAccess.open(args[0], FileAccess.WRITE)
		fa.store_string(linha + "\n")
		fa.close()
	quit()
