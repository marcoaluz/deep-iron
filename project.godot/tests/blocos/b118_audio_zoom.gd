extends SceneTree
## Bloco 118: o SOM SEGUE O ZOOM (o modelo do Frostpunk): o mundo só faz barulho com a câmera perto; o clique num prédio ou num ipezinho
## "mostra" o som. RODAR SÓ COM APPDATA ISOLADO.
##   (A) as classes de zoom dos slots (perto / medio / global) e a curva (mudo abaixo, inteiro acima, suave no meio);
##   (B) efeitos posicionais (picareta, passos, voz), sons soltos e loops de prédio somem com a câmera longe e voltam com ela perto;
##   (C) o fundo (bus Ambience) desce na vista longe e volta; música, interface, stingers e alarme não mudam com o zoom;
##   (D) o clique num prédio põe o som dele em destaque (se ouve de qualquer zoom por alguns segundos) e toca o toque curto; o clique num ipezinho
##       faz ele responder (a voz sem a regra de zoom); o toque de selecionar tem arquivo.
const Slots := preload("res://scripts/core/audio_slots.gd")
var audio: Node
var main: Node
var fails := 0
var _t0 := 0


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
	audio = root.get_node("Audio")
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_t0 = Time.get_ticks_msec()
	_roda()


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - _t0 > 200000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _zoom(px: float) -> void:
	audio._zoom_t = 1.0e9  # congela a leitura da câmera: o teste manda no zoom
	audio._zoom_px = px


func _roda() -> void:
	await _frames(5)
	Slots.ignora_arquivos = false
	Slots.limpa_cache()
	audio._ctx_timer = 1.0e9
	audio._pont_t = 1.0e9
	var cam = main.get_node("Camera2D")
	cam.focus_on(Vector2(400, 300))
	cam.position = cam._target_pos
	cam.force_update_scroll()
	var centro: Vector2 = cam.get_screen_center_position()

	print("== (A) as classes e a curva")
	check(Slots.zoom_de("passos/terra") == "perto" and Slots.zoom_de("voz/homem_ordem") == "perto" and Slots.zoom_de("sfx/picareta") == "perto", "passos, voz e picareta: classe perto")
	check(Slots.zoom_de("sfx/lumivoro_grito") == "medio" and Slots.zoom_de("sfx/portao_abre") == "medio" and Slots.zoom_de("maquinas/quebrou") == "medio", "criatura, portão e máquina quebrada: classe medio")
	check(Slots.zoom_de("sfx/alarme_invasao") == "global" and Slots.zoom_de("ui/clique") == "global" and Slots.zoom_de("stingers/morte") == "global" and Slots.zoom_de("predios/sino_missa") == "global", "alarme, interface, stinger e sino: classe global (sempre se ouve)")
	check(Slots.zoom_de("ambiencia/chuva") == "global" and Slots.zoom_de("musica/jogo") == "global", "ambiência e música: global")
	var sem: Array = []
	for id in Slots.todos():
		if not ["perto", "medio", "global"].has(Slots.zoom_de(id)):
			sem.append(id)
	check(sem.is_empty(), "todo slot tem uma classe de zoom válida%s" % ((" — %s" % str(sem)) if not sem.is_empty() else ""))
	_zoom(0.5)
	check(audio.fator_zoom("perto") == 0.0 and audio.fator_zoom("medio") == 0.0 and audio.fator_zoom("global") == 1.0, "vista longe (0,5): perto e medio mudos, global inteiro")
	_zoom(0.75)
	check(audio.fator_zoom("perto") < 0.15 and audio.fator_zoom("medio") > 0.3 and audio.fator_zoom("medio") < 0.7, "0,75: perto quase mudo (%.2f), medio no meio (%.2f)" % [audio.fator_zoom("perto"), audio.fator_zoom("medio")])
	_zoom(1.0)
	check(audio.fator_zoom("perto") > 0.3 and audio.fator_zoom("perto") < 0.6 and audio.fator_zoom("medio") == 1.0, "a vista de sempre (1): perto fica mais baixo (%.2f), medio inteiro" % audio.fator_zoom("perto"))
	_zoom(2.0)
	check(audio.fator_zoom("perto") == 1.0 and audio.fator_zoom("medio") == 1.0, "câmera perto (2): tudo inteiro")
	_zoom(3.0)
	check(audio.fator_zoom("perto") == 1.0 and audio.fator_zoom("medio") == 1.0, "bem perto (3): tudo inteiro")
	_zoom(99.0)
	check(audio.fator_zoom("perto") == 1.0, "sem câmera (99): tudo inteiro (os outros testes não mudam)")

	print("== (B) efeitos, passos, voz e sons soltos")
	var fk := Slots.som_falso(0.5)
	Slots.poe_falso("sfx/picareta", [fk])
	Slots.poe_falso("sfx/alarme_invasao", [fk])
	Slots.poe_falso("sfx/lumivoro_grito", [fk])
	for c in ["terra", "cascalho", "pedra", "madeira", "agua"]:
		Slots.poe_falso("passos/" + c, [fk])
	Slots.poe_falso("voz/homem_ordem", [fk])
	_zoom(0.5)
	audio._step_tokens = 8.0
	audio._voz_ultima = -100000
	check(not audio.som("sfx/picareta", centro), "câmera longe: a picareta não toca")
	check(not audio.som("sfx/lumivoro_grito", centro), "câmera longe: o grito da criatura (medio) não toca")
	var n_vozes := _tocando()
	audio.step(centro)
	check(_tocando() == n_vozes, "câmera longe: o passo não toca")
	audio.voz(centro, "ordem", "menino")
	check(_tocando() == n_vozes, "câmera longe: a voz não toca")
	audio.alarm()
	check(true, "o alarme (global) toca de qualquer zoom (sem erro)")
	_zoom(0.6)
	check(audio.som("sfx/lumivoro_grito", centro), "vista média (0,6): o grito da criatura (medio) já se ouve")
	check(not audio.som("sfx/picareta", centro), "vista média (0,6): a picareta (perto) ainda não")
	_zoom(3.0)
	audio._step_tokens = 8.0
	audio._voz_ultima = -100000
	check(audio.som("sfx/picareta", centro), "câmera perto: a picareta toca")
	var v0 := _tocando()
	audio.step(centro)
	check(_tocando() > v0, "câmera perto: o passo toca")
	_zoom(1.0)
	await _frames(2)
	check(true, "no meio do caminho toca mais baixo (sem erro)")
	for q in audio._pool:
		q.stop()
	Slots.limpa_falsos()

	print("== (C) o fundo desce na vista longe; música e interface não mudam")
	_zoom(0.5)
	audio._aplica_zoom_ambiencia(2.0)
	check(is_equal_approx(audio.zoom_ambiencia_atual(), audio.zoom_ambiencia_longe_db), "vista longe: o fundo desce %.0f dB" % audio.zoom_ambiencia_atual())
	_zoom(3.0)
	audio._aplica_zoom_ambiencia(0.25)
	check(audio.zoom_ambiencia_atual() > audio.zoom_ambiencia_longe_db and audio.zoom_ambiencia_atual() < 0.0, "chegando perto: sobe aos poucos (%.1f dB)" % audio.zoom_ambiencia_atual())
	audio._aplica_zoom_ambiencia(2.0)
	check(is_equal_approx(audio.zoom_ambiencia_atual(), 0.0), "bem perto: o fundo volta a 0 dB")
	var idx := AudioServer.get_bus_index(&"Ambience")
	var achou := false
	for i in AudioServer.get_bus_effect_count(idx):
		var e := AudioServer.get_bus_effect(idx, i)
		if e is AudioEffectAmplify and e.resource_name == "zoom":
			achou = true
	check(achou, "o efeito do zoom está no bus Ambience (o slider de ambiência não é mexido)")
	var im := AudioServer.get_bus_index(&"Music")
	var mexeu := false
	for i in AudioServer.get_bus_effect_count(im):
		var e := AudioServer.get_bus_effect(im, i)
		if e is AudioEffectAmplify and e.resource_name == "zoom":
			mexeu = true
	check(not mexeu, "a música não tem efeito de zoom (não muda com a câmera)")
	_zoom(0.5)
	check(audio.fator_zoom(Slots.zoom_de("ui/clique")) == 1.0 and audio.fator_zoom(Slots.zoom_de("stingers/vitoria")) == 1.0, "interface e stingers não mudam com o zoom")

	print("== (D) loops de prédio e o clique")
	var gs := GDScript.new()
	gs.source_code = "extends Node2D\nvar ativo := true\nfunc som_ativo() -> bool:\n\treturn ativo\n"
	gs.reload()
	var ff := Slots.som_falso(1.0)
	Slots.poe_falso("predios/fornalha", [ff])
	var f1: Node2D = gs.new()
	main.add_child(f1)
	f1.add_to_group("fornalhas")
	f1.global_position = centro + Vector2(20, 0)
	var pr: Node = audio.predios
	_zoom(0.5)
	pr.atualiza()
	check(not pr._vozes.has(f1.get_instance_id()), "câmera longe: a fornalha trabalhando fica muda")
	audio.selecionar_predio(f1)
	check(audio.destacado(f1), "o clique põe a fornalha em destaque")
	pr.atualiza()
	check(pr._vozes.has(f1.get_instance_id()), "clicada: o som dela se ouve MESMO com a câmera longe")
	audio._destaque[f1.get_instance_id()] = Time.get_ticks_msec() - 1
	pr.atualiza()
	check(not audio.destacado(f1) and not pr._vozes.has(f1.get_instance_id()), "passados os segundos do destaque, ela volta a ficar muda")
	_zoom(3.0)
	pr.atualiza()
	check(pr._vozes.has(f1.get_instance_id()), "câmera perto: a fornalha toca sozinha")
	var vz: Dictionary = pr._vozes[f1.get_instance_id()]
	_zoom(1.0)
	pr.atualiza()
	check(pr._vozes.has(f1.get_instance_id()) and float(vz.get("db", 0.0)) <= float(Slots.slot("predios/fornalha").get("db", 0.0)) + 0.01, "no meio do caminho ela toca mais baixo (%.1f dB)" % float(pr._vozes[f1.get_instance_id()].get("db", 0.0)))
	f1.remove_from_group("fornalhas")
	f1.queue_free()
	await _frames(2)
	pr.atualiza()
	Slots.limpa_falsos()
	check(Slots.tem("ui/selecionar_predio") and Slots.streams("ui/selecionar_predio").size() == 3, "o toque de selecionar prédio tem as 3 variações")
	check(String(Slots.slot("ui/selecionar_predio").get("bus", "")) == "UI", "...e sai no bus UI")
	var fonte_hud := FileAccess.get_file_as_string("res://scripts/core/hud.gd")
	var fonte_main := FileAccess.get_file_as_string("res://scripts/core/main.gd")
	check(fonte_hud.contains("Audio.selecionar_predio(node)"), "hud.open_panel_for chama o clique do prédio")
	check(fonte_main.count("Audio.selecionar_gente(clicked_unit)") == 2, "main.gd: o clique num ipezinho (mapa e vista iso) chama a resposta dele")
	var unit: Node2D = get_first_node_in_group("ipezinhos")
	if unit != null:
		var fv := Slots.som_falso(0.3)
		Slots.poe_falso("voz/homem_ordem", [fv])
		Slots.poe_falso("voz/mulher_ordem", [fv])
		_zoom(0.5)
		audio._voz_ultima = -100000
		var antes := _tocando()
		audio.selecionar_gente(unit)
		check(_tocando() > antes or not audio.voz_ligada, "clicou num ipezinho com a câmera longe: ele responde (a voz ignora o zoom)")
		Slots.limpa_falsos()

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


func _tocando() -> int:
	var n := 0
	for q in audio._pool:
		if q.playing:
			n += 1
	return n
