extends SceneTree
## Bloco 129: O ARQUIVO DO SAVE É ESCOLHIDO PELO JOGADOR e a INTRODUÇÃO é parte de toda partida nova. RODAR SÓ COM APPDATA ISOLADO.
##   (A) set_caminho_save (extensão .json, pasta que existe, guardado nas configurações); (B) save, autosave e backup usam
##   SEMPRE esse arquivo (nada vai pro savegame.json padrão) e não sobra .tmp; (C) carregar de um arquivo passa a salvar nele
##   (e arquivo ruim não troca nada); (D) as telas: Nova partida (escolher onde salvar), menu inicial (sem "Ver a
##   introdução", com "Carregar de um arquivo") e pausa (Salvar como); (E) a partida nova leva o arquivo e passa pela
##   introdução MESMO com a intro já vista (e some só se desligada nas Configurações).
var fails := 0
var sm: Node
const Settings := preload("res://scripts/core/settings.gd")


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	sm = root.get_node("SaveManager")
	sm.save_on_quit = false
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func _botoes(n: Node, out: Array = []) -> Array:
	if n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_botoes(c, out)
	return out


func _roda() -> void:
	await process_frame
	var base := ProjectSettings.globalize_path("user://") + "meus_saves"
	DirAccess.make_dir_recursive_absolute(base)
	var arq1 := base + "/minha_partida.json"
	var arq2 := base + "/outra.json"
	for f in [arq1, arq2, arq1 + ".tmp", "user://savegame.json"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f) if f.begins_with("user://") else f)

	print("== (A) escolher o arquivo")
	check(sm.caminho_save == sm.SAVE_PATH, "padrão: user://savegame.json")
	check(not sm.set_caminho_save(base + "/pasta_que_nao_existe/x.json") and sm.caminho_save == sm.SAVE_PATH, "pasta inexistente: recusa e não troca")
	check(not sm.set_caminho_save("   "), "vazio: recusa")
	check(sm.set_caminho_save(base + "/minha_partida"), "aceita sem extensão")
	check(sm.caminho_save == arq1, "acrescenta .json (%s)" % sm.caminho_save)
	check(String(Settings.get_value("jogo", "caminho_save", "")) == arq1, "a escolha fica nas configurações")
	check(sm.caminho_legivel() == arq1, "caminho legível")

	print("== (B) salvar, autosave e backup vão pro arquivo escolhido")
	var main: Node = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	check(sm.is_game_running(), "a partida está rodando")
	check(sm.save_game("teste"), "salvou")
	check(FileAccess.file_exists(arq1), "o arquivo escolhido existe")
	check(not FileAccess.file_exists("user://savegame.json"), "o savegame.json padrão NÃO foi criado")
	check(not FileAccess.file_exists(arq1 + ".tmp"), "sem .tmp sobrando")
	check(sm.has_save() and sm.save_status() == "ok" and sm.read_save() != null, "has_save/save_status/read_save leem esse arquivo")
	DirAccess.remove_absolute(arq1)
	var razoes: Array = []
	sm.saved.connect(func(r: String): razoes.append(r))
	sm.autosave_interval = 0.4
	sm._autosave_timer = 0.0
	for i in 240:
		await process_frame
		if FileAccess.file_exists(arq1):
			break
	check(FileAccess.file_exists(arq1) and "autosave" in razoes, "o AUTOSAVE refez o save no MESMO arquivo (%s)" % str(razoes))
	check(not FileAccess.file_exists("user://savegame.json"), "e nada no arquivo padrão")
	sm.autosave_interval = 0.0
	var bk: String = sm.backup_existing_save()
	check(bk != "" and FileAccess.file_exists(bk) and not FileAccess.file_exists(arq1), "o backup sai do arquivo escolhido (%s)" % bk.get_file())
	check(sm.save_game("de novo") and FileAccess.file_exists(arq1), "salva de novo no mesmo arquivo")

	print("== (C) carregar de um arquivo")
	FileAccess.open(base + "/lixo.json", FileAccess.WRITE).store_string("isso nao e json {")
	var antes: String = sm.caminho_save
	check(not sm.load_arquivo(base + "/lixo.json") and sm.caminho_save == antes, "arquivo que não é save: recusa e não troca o arquivo atual")
	check(not sm.load_arquivo(base + "/nao_existe.json") and sm.caminho_save == antes, "arquivo que não existe: recusa")

	print("== (D) as telas")
	var painel = load("res://scripts/ui/nova_partida_panel.gd").new()
	root.add_child(painel)
	await process_frame
	check(painel.escolha().arquivo == sm.caminho_legivel(), "Nova partida: o arquivo de saída começa no atual")
	painel.define_arquivo(arq2.trim_suffix(".json"))
	check(painel.escolha().arquivo == arq2 and painel.escolha().perfil == "normal", "escolher onde salvar: vai na escolha (%s)" % painel.escolha().arquivo)
	check(painel.has_meta("escolhe_arquivo_button"), "o botão 'Escolher onde salvar…' existe")
	painel.queue_free()
	var menu = load("res://scenes/ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var bs := _botoes(menu)
	check("Carregar de um arquivo…" in bs, "menu inicial: 'Carregar de um arquivo…'")
	check(not ("Ver a introdução" in bs), "menu inicial: a introdução não é mais um botão à parte")
	menu.queue_free()
	var pausa := get_first_node_in_group("pause_menu")
	check(pausa != null and "Salvar como… (escolher o arquivo)" in _botoes(pausa), "menu de pausa: 'Salvar como…'")
	check(pausa._arquivo_label != null, "menu de pausa: mostra o arquivo")
	var cfg = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(cfg)
	await process_frame
	var achou := false
	var pilha: Array = [cfg]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n is CheckBox and (n as CheckBox).text.begins_with("Introdução em toda partida nova"):
			achou = true
		pilha.append_array(n.get_children())
	check(achou, "Configurações: 'Introdução em toda partida nova'")
	cfg.queue_free()

	print("== (E) partida nova: arquivo + introdução em TODA partida")
	check(sm.intro_ligada(), "a introdução está ligada por padrão")
	Settings.set_value("jogo", "intro_vista", true)  # (já vista: antes pulava; agora roda de novo)
	sm.start_new_game({"perfil": "normal", "custom": {}, "arquivo": arq2})
	check(sm.cinema == "novo", "intro já vista e mesmo assim a partida nova passa pela introdução")
	check(sm.caminho_save == arq2, "a partida nova salva no arquivo escolhido")
	check(not sm.dificuldade_nova.has("arquivo") and sm.dificuldade_nova.get("perfil", "") == "normal", "a dificuldade chega sem a chave 'arquivo'")
	sm.cinema = ""
	Settings.set_value("jogo", "intro_ligada", false)
	check(not sm.intro_ligada(), "desligada nas Configurações: não roda")
	Settings.set_value("jogo", "intro_ligada", true)
	sm.set_caminho_save("user://savegame.json")  # (devolve o padrão: o próximo teste não herda)

	print("FALHAS: %d" % fails)
	quit()
