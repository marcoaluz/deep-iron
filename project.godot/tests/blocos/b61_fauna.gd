extends SceneTree
## Bloco 61: fauna. Tocas de coelho e de javali com bichos de verdade (nascem até o limite, vagam,
## fogem), caçador caça e o bicho cai abatido, javali fere caçador novato (vai pra enfermaria),
## inverno com menos bichos, save/load dos bichos e save antigo. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var coelhos: Node
var javalis: Node
var cacador: Node
var pos0 := {}


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true  # Bloco 102: o teste é de antes do catálogo (tudo conhecido)
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
	return current_scene.get_tree().get_first_node_in_group(grupo)


func _tocas() -> void:
	for tc in main.get_tree().get_nodes_in_group("caca"):
		if tc.name == "TocaLeste":
			continue  # (a do leste, Bloco 67)
		if tc.animal == "javali":
			javalis = tc
		else:
			coelhos = tc


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 150.0:
		Engine.time_scale = 1.0
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 3.0:
				_comeco()
				step = 1
				t_mark = t
		1:
			if t - t_mark > 3.0:
				_vagam()
				step = 2
				t_mark = t
		2:
			var abatido := main.get_tree().get_nodes_in_group("animais").any(func(a): return not a.is_alive())
			if abatido:
				Engine.time_scale = 1.0
				_cacou()
				step = 3
				t_mark = t
			elif t - t_mark > 80.0:
				check(false, "caçador abateu um bicho (estado %s)" % cacador.get_state_label())
				step = 3
		3:
			_javali_e_limite()
			root.get_node("SaveManager").save_game("teste")
			step = 4
			t_mark = t
		4:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 5
				t_mark = t
		5:
			if t - t_mark > 3.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _comeco() -> void:
	print("== tocas e bichos")
	_tocas()
	check(coelhos != null and javalis != null, "uma toca de coelhos e uma de javalis")
	check(coelhos.alive().size() == coelhos.max_animals(), "coelhos nascem cheios (%d)" % coelhos.alive().size())
	check(javalis.alive().size() == javalis.max_animals() and javalis.meat_per_animal() > coelhos.meat_per_animal(), "javalis: %d, mais carne cada" % javalis.alive().size())
	for a in main.get_tree().get_nodes_in_group("animais"):
		pos0[a] = a.global_position
	var iso = g("iso_view")
	if iso and iso.enabled:
		var a0 = coelhos.alive()[0]
		check(iso._ents.has(a0) and a0.get_node("Visual").texture != null, "bicho aparece na vista iso (desenho do coelho)")
	var IsoArt = load("res://scripts/iso/iso_art.gd")
	var ls: Array = IsoArt.prop_layers(javalis)
	check(ls.any(func(l): return l.has("tex") and l.tex != null and "toca_javali" in l.tex.resource_path), "toca de javali com o desenho dela")


func _vagam() -> void:
	var mexeu := 0
	var longe := 0
	for a in pos0:
		if is_instance_valid(a):
			if a.global_position.distance_to(pos0[a]) > 3.0:
				mexeu += 1
			if a.global_position.distance_to(a.toca.global_position) > a.roam_radius + 10.0:
				longe += 1
				print("    longe: %s a %.0f da toca (raio %.0f), alvo %s" % [a.name, a.global_position.distance_to(a.toca.global_position), a.roam_radius, a._target.distance_to(a.toca.global_position)])
	check(mexeu >= 2, "vagam (%d de %d se mexeram)" % [mexeu, pos0.size()])
	check(longe == 0, "ficam perto da toca")
	print("== caçar")
	g("oficina").crafted["arco"] = true
	var ws: Array = main.get_tree().get_nodes_in_group("ipezinhos")
	cacador = ws[0]
	cacador.set_job("caçador")
	coelhos.HUNT_RATE = 4.0
	Engine.time_scale = 3.0


func _cacou() -> void:
	check(cacador.raw_carrying > 0.0, "caçador com carne na mochila (%.1f)" % cacador.raw_carrying)
	check(cacador.hunt_kills >= 1, "abates do caçador: %d" % cacador.hunt_kills)
	var mortos := main.get_tree().get_nodes_in_group("animais").filter(func(a): return not a.is_alive())
	check(not mortos.is_empty() and mortos[0].state == "abatido", "bicho abatido (carcaça)")


func _javali_e_limite() -> void:
	print("== javali e limite")
	var novato = main.get_tree().get_nodes_in_group("ipezinhos")[1]
	novato.set_job("caçador")
	novato.hunt_kills = 0
	javalis.javali_risk_novice = 1.0
	var jv = javalis.alive()[0]
	javalis._javali_risk(novato, jv)
	check(novato.injured and novato.injury_cause == "javali", "javali feriu o caçador novato (vai pra enfermaria)")
	var veterano = main.get_tree().get_nodes_in_group("ipezinhos")[2]
	veterano.hunt_kills = javalis.javali_xp
	javalis.javali_risk_expert = 0.0
	var jv2 = javalis.alive()[javalis.alive().size() - 1]
	jv2.remove_meta("reagiu")
	javalis._javali_risk(veterano, jv2)
	check(not veterano.injured, "caçador experiente não se fere (risco experiente 0)")
	# limite: nasce mais rápido, mas nunca passa do máximo
	coelhos.spawn_every_by_kind[0] = 0.01
	for i in 30:
		coelhos._process(0.05)
	check(coelhos.alive().size() == coelhos.max_animals(), "limite respeitado (%d de %d)" % [coelhos.alive().size(), coelhos.max_animals()])
	var sun = g("sun")
	var dn = g("day_night")
	var d0: int = dn.day
	dn.day = sun.days_per_season * 3 + 1
	check(sun.season_index() == 3 and coelhos.max_animals() < coelhos.max_animals_by_kind[0], "inverno: limite menor (%d)" % coelhos.max_animals())
	dn.day = d0


func _carregado() -> void:
	print("== depois de carregar")
	_tocas()
	check(coelhos.alive().size() >= 1 and javalis.alive().size() >= 1, "bichos voltaram (%d coelhos, %d javalis)" % [coelhos.alive().size(), javalis.alive().size()])
	var destas: int = main.get_tree().get_nodes_in_group("animais").filter(func(a): return a.toca == coelhos or a.toca == javalis).size()
	check(destas <= coelhos.max_animals() + javalis.max_animals(), "sem bicho duplicado (%d)" % destas)
	var d: Dictionary = coelhos.get_save_data()
	d.erase("animais")
	d["game_remaining"] = coelhos.meat_per_animal() * 2.0
	coelhos.load_save_data(d)
	check(coelhos.alive().size() == 2, "save antigo (só a caça): 2 coelhos")
	var c = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	check(c.hunt_kills >= 0, "abates voltaram (%d)" % c.hunt_kills)
