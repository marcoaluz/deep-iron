extends SceneTree
## Bloco 33: rendimento da cozinha + expansão da vila. RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0
var raw0 := 0.0
var food0 := 0.0


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
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false  # (Bloco 37) layout da cena, sem fundação
	root.add_child(main)
	current_scene = main  # load_game troca a cena de verdade (sem deixar o mundo velho)


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func gal(n: String) -> Node:
	return main.get_node("World/" + n)


func gal_state() -> String:
	var parts: Array[String] = []
	for n in ["GaleriaOeste", "GaleriaSudeste", "GaleriaNorte", "GaleriaNordeste"]:
		var m = gal(n)
		parts.append("%s=%s" % [n.trim_prefix("Galeria"), "lacrada" if m.is_sealed() else ("aberta" if m.is_unlocked() else "sem ferramenta")])
	return " ".join(parts)


func _process(delta: float) -> bool:
	if current_scene != null and current_scene != main:
		main = current_scene
	t += delta
	if t > 600.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var dn = g("day_night")
	if dn:
		dn.time = 20.0
	for w in get_nodes_in_group("ipezinhos"):
		w.hunger = w.hunger_max  # ninguém come: a comida do comedouro só muda pelo cozinheiro
	var arm = g("armazens")
	var com = g("comedouros")
	if step == 0 and t > 2.0:
		print("== cozinha")
		var cook = get_nodes_in_group("ipezinhos")[0]
		print("  food_per_raw = ", cook.food_per_raw)
		check(cook.food_per_raw > 1.0, "rendimento > 1 (%.2f)" % cook.food_per_raw)
		arm.raw_stored = 24.0
		com.food_stock = 0.0
		raw0 = arm.raw_stored
		cook.set_job("cozinheiro")
		Engine.time_scale = 4.0
		step = 1
		t_mark = t
	elif step == 1:
		# duas levas (12 + 12) prontas
		if com.food_stock > 0.0 and arm.raw_stored <= 0.01 and get_nodes_in_group("ipezinhos")[0].raw_carrying <= 0.001:
			Engine.time_scale = 1.0
			var used: float = raw0 - arm.raw_stored
			print("  matéria-prima gasta: %.1f  ->  comida pronta: %.1f" % [used, com.food_stock])
			check(absf(com.food_stock - used * 1.25) < 0.5, "comida = 1.25 x matéria-prima (%.1f x 1.25 = %.1f)" % [used, used * 1.25])
			check(com.food_stock > used, "sai MAIS comida do que entrou matéria-prima")
			get_nodes_in_group("ipezinhos")[0].set_job("ocioso")
			step = 2
			t_mark = t
		elif t - t_mark > 200.0:
			check(false, "cozinheiro não terminou (armazém %.1f, comedouro %.1f)" % [arm.raw_stored, com.food_stock])
			step = 2
	elif step == 2:
		print("== expandir a vila")
		var env = g("environment")
		var hub = g("village_hub")
		var cam = main.get_node("Camera2D")
		set_meta("world", env.world_rect())
		set_meta("walk", env.walkable_rect())
		set_meta("cam", cam.bounds)
		print("  nível 1: ", gal_state())
		check(gal("GaleriaOeste").is_sealed() and gal("GaleriaSudeste").is_sealed() and gal("GaleriaNorte").is_sealed() and gal("GaleriaNordeste").is_sealed(), "as 4 galerias começam lacradas")
		check(gal("GaleriaOeste").get_node("Entulho").visible and not gal("GaleriaOeste").get_node("Padlock").visible, "lacrada mostra entulho (sem cadeado)")
		print("  placa: ", gal("GaleriaOeste").get_node("AmountLabel").text.replace("\n", " | "))
		check(not gal("GaleriaOeste").is_usable(), "ninguém minera galeria lacrada")
		check(not main.get_node("World/MineralNode").is_sealed(), "jazidas de sempre não mudaram")
		print("  painel: libera ", hub.stage_unlocks_text(2))
		var eco = main.get_node("Economy")
		eco.credits = 999999
		arm.lifetime_stored = 999999.0
		check(hub.level_up(), "expansão encomendada")
		hub.obra_work(9999.0)
		check(hub.level == 2, "vila subiu pro nível 2")
		step = 3
		t_mark = t
	elif step == 3 and t - t_mark > 1.5:
		var env = g("environment")
		var cam = main.get_node("Camera2D")
		print("  nível 2: ", gal_state())
		check(env.world_rect() == get_meta("world") and env.walkable_rect() == get_meta("walk") and cam.bounds == get_meta("cam"), "mapa do MESMO tamanho (%s)" % str(env.world_rect()))
		check(gal("GaleriaOeste").is_unlocked() and gal("GaleriaOeste").is_usable(), "galeria oeste (ferro) aberta e minerável")
		check(not gal("GaleriaOeste").get_node("Entulho").visible, "entulho sumiu")
		check(gal("GaleriaSudeste").is_sealed() and gal("GaleriaNorte").is_sealed() and gal("GaleriaNordeste").is_sealed(), "as outras continuam lacradas")
		var sm = root.get_node("SaveManager")
		check(sm.save_game("teste"), "salvou no nível 2")
		# carregar com o jogo em outro estado: fecha a oeste "à força" antes do load
		g("village_hub").level = 1
		g("village_hub")._refresh_galleries(false)
		check(gal("GaleriaOeste").is_sealed(), "(antes do load: forçado pro nível 1)")
		sm.load_game()
		step = 4
		t_mark = t
	elif step == 4 and t - t_mark > 2.0:
		print("  depois do load: ", gal_state())
		check(g("village_hub").level == 2 and gal("GaleriaOeste").is_unlocked() and not gal("GaleriaOeste").get_node("Entulho").visible, "save/load: nível 2 com a oeste aberta")
		check(gal("GaleriaSudeste").is_sealed(), "save/load: sudeste ainda lacrada")
		# pula pro 5: todas abertas (cobre/carvão ainda pedem ferramenta)
		var hub = g("village_hub")
		for i in 3:
			hub.level_up()
			hub.obra_work(9999.0)
		print("  nível %d: %s" % [hub.level, gal_state()])
		check(hub.level == 5 and not gal("GaleriaNordeste").is_sealed() and not gal("GaleriaSudeste").is_sealed() and not gal("GaleriaNorte").is_sealed(), "nível 5: nenhuma lacrada")
		check(g("environment").world_rect() == get_meta("world"), "mapa continua do mesmo tamanho no nível 5")
		step = 9
	if step == 9:
		print("\nFALHAS: %d" % fails)
		return true
	return false
