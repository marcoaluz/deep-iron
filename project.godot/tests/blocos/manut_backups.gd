extends SceneTree
## Teste dos backups rotativos. RODAR SÓ COM APPDATA ISOLADO.
var sm: Node
var t := 0.0
var step := 0
var template := {}
var chosen := ""
var chosen_credits := -1.0
var fails := 0
var menu: Node


func _initialize() -> void:
	sm = root.get_node("SaveManager")
	var real := ProjectSettings.globalize_path("user://")
	if not ("fake_appdata" in real):
		print("ABORTADO: pasta de save NÃO está isolada: ", real)
		quit()
		return
	print("pasta de save do teste: ", real)
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	_clean()
	root.add_child(load("res://scenes/game/main.tscn").instantiate())


func _clean() -> void:
	for p in ["user://savegame.json", "user://savegame_backup.json"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	var d := DirAccess.open("user://backups")
	if d:
		for f in d.get_files():
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://backups/" + f))


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func write_save(day: int, credits: float) -> void:
	var d: Dictionary = template.duplicate(true)
	d["summary"]["day"] = day
	d["summary"]["credits"] = credits
	d["economy"]["credits"] = credits
	var f := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()


func days() -> Array:
	return sm.list_backups_with_summary().map(func(b): return int(b.summary.get("day", -1)))


func _process(delta: float) -> bool:
	t += delta
	if step == 0 and t > 2.0:
		step = 1
		print("== 0) save normal (F5) continua igual")
		check(sm.save_game("manual") and FileAccess.file_exists("user://savegame.json"), "save_game grava savegame.json")
		check(sm.list_backups().is_empty(), "salvar NÃO cria backup")
		template = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
		check(sm.read_save() != null, "save lido de volta (versão %d)" % int(template.get("save_version", 0)))

		# nome "mais novo" (2099) mas criado ANTES de todos: pela data é o mais antigo
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://backups"))
		var fake := "user://backups/savegame_backup_2099-01-01_00-00-00.json"
		var ff := FileAccess.open(fake, FileAccess.WRITE)
		ff.store_string(JSON.stringify(template))
		ff.close()
		OS.delay_msec(1100)
		print("== 1) 6 backups seguidos (1,1 s entre cada): só os 5 mais novos ficam")
		for i in range(1, 7):
			write_save(i, i * 100.0)
			var p: String = sm.backup_existing_save()
			check(p != "" and not FileAccess.file_exists("user://savegame.json"), "backup %d criado: %s" % [i, p.get_file()])
			OS.delay_msec(1100)
		var ds := days()
		print("  dias nos backups (mais novo primeiro): ", ds)
		check(ds == [6, 5, 4, 3, 2], "ficaram os 5 mais recentes e o do dia 1 saiu")
		check(not FileAccess.file_exists(fake), "ordem por DATA: o de nome '2099' (criado antes de todos) foi podado")
		var b0: Dictionary = sm.list_backups()[0]
		check(absi(int(Time.get_unix_time_from_system()) - int(b0.time)) < 5, "data do backup = momento do backup (%s)" % b0.label)

		print("== 3) F6 duas vezes (main.tscn aberta direto com save existente)")
		write_save(7, 700.0)
		sm._backup_checked = false
		sm.pending_load = false
		sm.register_game(root.get_child(root.get_child_count() - 1))
		write_save(8, 800.0)
		sm._backup_checked = false  # cada F6 é um processo novo
		sm.register_game(root.get_child(root.get_child_count() - 1))
		ds = days()
		print("  dias: ", ds)
		check(ds == [8, 7, 6, 5, 4], "cada F6 virou um backup novo, limite de 5 mantido")

		print("== 4) carregar um backup (o mais antigo) com um save atual na pasta")
		write_save(9, 900.0)
		var list: Array = sm.list_backups_with_summary()
		chosen = list[list.size() - 1].path
		chosen_credits = float(list[list.size() - 1].summary.get("credits", -1))
		check(sm.load_backup(chosen), "load_backup(%s)" % chosen.get_file())
		step = 2
	elif step == 2 and t > 5.0:
		step = 3
		var eco = get_first_node_in_group("economy")
		check(eco != null and is_equal_approx(eco.credits, chosen_credits), "partida carregada com os créditos do backup (%s)" % (str(eco.credits) if eco else "?"))
		var ds := days()
		print("  dias depois de carregar: ", ds)
		check(ds.has(9), "o save atual (dia 9) virou backup antes de carregar")
		check(FileAccess.file_exists(chosen), "o backup escolhido não foi podado")
		check(sm.save_game("manual"), "a partida carregada salva normalmente no savegame.json")

		print("== 5) backup único antigo (savegame_backup.json) é adotado pela pasta nova")
		var f := FileAccess.open("user://savegame_backup.json", FileAccess.WRITE)
		f.store_string(FileAccess.get_file_as_string("user://savegame.json"))
		f.close()
		sm._adopt_legacy_backup()
		check(not FileAccess.file_exists("user://savegame_backup.json"), "savegame_backup.json saiu da raiz")
		var adopted: Array = sm.list_backups().filter(func(b): return b.file.ends_with("_antigo.json"))
		check(adopted.size() == 1 or sm.list_backups().size() == sm.max_backups, "virou backups/…_antigo.json (ou foi podado por ser o mais velho)")

		print("== 6) tela inicial lista os backups")
		menu = load("res://scenes/ui/start_menu.tscn").instantiate()
		root.add_child(menu)
		step = 4
	elif step == 4 and t > 6.0:
		var found := ""
		var loads := 0
		for n in menu.find_children("*", "Button", true, false):
			if n.text.begins_with("Backups ("):
				found = n.text
			if n.text == "Carregar" and not (n.get_parent() is Window or n.find_parent("*") is AcceptDialog or _in_dialog(n)):
				loads += 1
		check(found != "", "botão '%s' na tela inicial" % found)
		check(loads == sm.list_backups().size(), "%d botões 'Carregar' (um por backup)" % loads)
		print("\nFALHAS: %d" % fails)
		return true
	return false


func _in_dialog(n: Node) -> bool:
	var p := n.get_parent()
	while p:
		if p is AcceptDialog:
			return true
		p = p.get_parent()
	return false
