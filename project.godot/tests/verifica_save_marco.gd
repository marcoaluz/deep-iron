extends SceneTree
## Verificação (não é teste de bloco): carrega uma CÓPIA de um save do Marco com o código atual e deixa a
## partida rodar acelerada, conferindo que nada quebra: ipezinhos andando (não travados), a vista iso, as
## áreas de trabalho (cria uma de madeira com quem estiver sem função), os lotes e a boca da espiral.
## Uso (APPDATA isolado; o save é COPIADO pra user:// depois que a cena abre):
##   <Godot>.exe --headless --path . -s res://tests/verifica_save_marco.gd -- <caminho do save>
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var t_mark := 0.0
var origem := ""
var fails := 0
var pos0 := {}


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	origem = args[0] if args.size() > 0 else ""
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
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


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		Engine.time_scale = 1.0
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	match step:
		0:
			if t > 3.0:
				var f := FileAccess.open(origem, FileAccess.READ)
				if f == null:
					print("sem o arquivo ", origem)
					return true
				var txt := f.get_as_text()
				var w := FileAccess.open(PATH, FileAccess.WRITE)
				w.store_string(txt)
				w.close()
				var d = JSON.parse_string(txt)
				print("save: ", d.get("saved_at"), "  ", d.get("summary"))
				root.get_node("SaveManager").load_game()
				step = 1
				t_mark = t
		1:
			if t - t_mark > 6.0:
				_carregado()
				Engine.time_scale = 4.0
				step = 2
				t_mark = t
		2:
			if t - t_mark > 60.0:  # 60 s de jogo rodando
				Engine.time_scale = 1.0
				_rodou()
				print("FALHAS: %d" % fails)
				return true
	return false


func _carregado() -> void:
	print("== carregado")
	var ws := get_nodes_in_group("ipezinhos")
	check(ws.size() > 0, "%d ipezinhos" % ws.size())
	for w in ws:
		pos0[w] = w.global_position
		print("   %s: %s / %s  em %s" % [w.display_name, w.job, w.get_state(), w.global_position.round()])
	var iso = g("iso_view")
	check(iso != null and iso.enabled, "vista iso ligada")
	var env = g("environment")
	check(env.lotes().size() == 4, "lotes: %d livres de %d" % [env.lotes_livres().size(), env.lotes().size()])
	var esp := false
	for ch in env.get_children():
		if ch is Node2D and str(ch.get_meta("iso_prop", "")) == "boca_espiral":
			esp = true
	check(esp, "a boca da espiral está no mapa")
	var wa = g("work_areas")
	check(wa != null and wa.areas.is_empty(), "save antigo: sem áreas de trabalho (%d)" % (wa.areas.size() if wa else -1))
	var livres: Array = wa.disponiveis()
	print("   disponíveis (sem função): %d" % livres.size())
	var trees: Array = get_nodes_in_group("arvores").filter(func(x): return x.is_usable())
	if not trees.is_empty() and not livres.is_empty():
		var c: Vector2 = trees[0].global_position
		var a = wa.criar("madeira", Rect2(c - Vector2(210, 210), Vector2(420, 420)))
		check(a != null, "dá pra criar área de madeira no save dele")
		var n: int = wa.definir(a, 5)
		check(n == mini(5, livres.size()), "%d na área (de %d disponíveis)" % [n, livres.size()])


func _rodou() -> void:
	print("== depois de 60 s de jogo")
	var parados := 0
	for w in get_nodes_in_group("ipezinhos"):
		var andou: float = w.global_position.distance_to(pos0.get(w, w.global_position))
		var st: String = w.get_state()
		print("   %s: %s / %s  andou %d px%s" % [w.display_name, w.job, st, andou,
			("  área " + w.work_area.nome()) if w.work_area != null else ""])
		# (trabalho parado no lugar não conta: cozinhar, operar máquina, pesquisar, treinar, plantão...)
		if andou < 4.0 and st not in ["home", "downed", "infirmary", "eating", "leisure", "idle", "doctor", "cooking",
				"operating", "operating_ore", "research", "training", "guard", "strike"]:
			parados += 1
	check(parados == 0, "ninguém travado trabalhando sem sair do lugar (%d)" % parados)
	var wa = g("work_areas")
	for a in wa.areas:
		print("   área %s: %d/%d %s, total %.1f" % [a.nome(), a.quantos(), a.capacidade, wa.estado(a), a.total])
		check(a.total > 0.0 or a.quantos() == 0, "a área produziu (%.1f)" % a.total)
