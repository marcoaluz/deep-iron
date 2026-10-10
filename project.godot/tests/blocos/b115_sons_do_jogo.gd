extends SceneTree
## Bloco 115: TODOS os sons do jogo pelo catálogo (menos a música) — nenhum áudio novo: sons FALSOS na memória. RODAR SÓ COM APPDATA ISOLADO.
##   (A) Os sons antigos (picareta, passos, forja, alarme...) viraram slots: com arquivo o arquivo manda; sem arquivo vale o som de antes.
##   (B) Os loops de TODOS os prédios e lugares do catálogo (grupo + atividade) tocam só perto da câmera.
##   (C) Os sons soltos e aleatórios por contexto (pássaro, coruja, trovão, gota...) e a camada da onda solar.
##   (D) Eventos novos: criatura por espécie, portão, Geiger da radiação, animais, máquinas, vida na vila, o "oi" ao selecionar.
##   (E) Cada slot (menos a música) tem prompt e duração, e docs/AUDIO_PROMPTS_ELEVENLABS.md lista todos.
const Slots := preload("res://scripts/core/audio_slots.gd")
var main: Node
var audio: Node
var fails := 0
var _t0 := 0
## (função do Audio, slot, sem posição?)
const LEGADO := [
	["pick", "sfx/picareta", false], ["deposit", "sfx/deposito", false], ["eat", "sfx/comer", false], ["hurt", "sfx/ferido", false],
	["heal", "sfx/curar", false], ["forge", "sfx/forja", false], ["chop", "sfx/machadada", false], ["elevator", "sfx/elevador", false],
	["branch", "sfx/galho", false], ["cheers", "sfx/brinde", false], ["find", "sfx/achado", false], ["robot", "sfx/robo", false],
	["boom", "sfx/explosao", false], ["screech", "sfx/lumivoro_grito", false], ["clank", "sfx/ferrugento_golpe", false],
	["hit", "sfx/golpe", false], ["gate_break", "sfx/portao_quebra", false], ["protest", "sfx/greve", false],
	["build_hit", "sfx/martelo", false], ["build_done", "sfx/obra_pronta", false], ["harvest", "sfx/colher", false],
	["equip", "sfx/equipar", false], ["creature_down", "sfx/criatura_cai", false], ["drill", "sfx/broca", false],
	["migrantes", "sfx/migrantes_chegando", false],
	["fanfare", "sfx/fanfarra", true], ["toll", "sfx/sino_funebre", true], ["alarm", "sfx/alarme_invasao", true],
	["solar", "sfx/solar", true], ["party", "sfx/festa", true], ["sell", "sfx/vender", true], ["recruit", "sfx/boas_vindas", true]]


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
	if Time.get_ticks_msec() - _t0 > 240000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _espera(s: float) -> void:
	await create_timer(s).timeout


func _calar() -> void:
	for p in audio._pool:
		p.stop()
	for p in audio._ui_pool:
		p.stop()
	for p in audio._iface_pool:
		p.stop()
	for p in audio._pont_pool:
		p.stop()


func _tocando(pool: Array, st: AudioStream) -> int:
	var n := 0
	for p in pool:
		if p.playing and p.stream == st:
			n += 1
	return n


func _camera_em(pos: Vector2) -> void:
	var cam = main.get_node("Camera2D")
	cam.focus_on(pos)
	cam.position = cam._target_pos
	cam.force_update_scroll()


func _roda() -> void:
	await _frames(12)
	var cam = main.get_node("Camera2D")
	var env = g("environment")
	var clareira: Vector2 = (env.clearing_rect as Rect2).get_center()
	_camera_em(clareira)
	audio._ctx_timer = 1.0e9  # (a conta automática do contexto e dos sons soltos fica parada: o teste chama à mão)
	audio._pont_t = 1.0e9
	var centro: Vector2 = cam.get_screen_center_position()

	print("== A) os sons antigos pelo catálogo")
	var faltam := LEGADO.filter(func(l): return not Slots.existe(l[1]))
	check(faltam.is_empty(), "todos os %d sons antigos são slots%s" % [LEGADO.size(), (" — faltam: %s" % str(faltam)) if not faltam.is_empty() else ""])
	var rev: Array = []
	for l in LEGADO:
		var id: String = l[1]
		_calar()
		var f := Slots.som_falso(0.3)
		Slots.poe_falso(id, [f])
		if l[2]:
			audio.call(l[0])
		else:
			audio.call(l[0], centro)
		var pool: Array = audio._ui_pool if l[2] else audio._pool
		if _tocando(pool, f) != 1:
			rev.append("%s -> %s" % [l[0], id])
		Slots.limpa_falsos()
	check(rev.is_empty(), "com arquivo no slot, cada função toca o arquivo (%d sons)%s" % [LEGADO.size(), (" — falhou: %s" % str(rev)) if not rev.is_empty() else ""])
	var mudos: Array = []
	for l in LEGADO:
		_calar()
		if l[2]:
			audio.call(l[0])
		else:
			audio.call(l[0], centro)
		var pool: Array = audio._ui_pool if l[2] else audio._pool
		var tocou := false
		for p in pool:
			if p.playing:
				tocou = true
		var tem_reserva := String(Slots.slot(l[1]).get("reserva", "")) != ""
		if tocou != tem_reserva:
			mudos.append("%s (reserva %s, tocou %s)" % [l[0], tem_reserva, tocou])
	check(mudos.is_empty(), "sem arquivo, vale o som sintetizado de antes (e o que nunca teve som fica mudo)%s" % [(" — %s" % str(mudos)) if not mudos.is_empty() else ""])
	# o duck do alarme e do sino agora vêm do slot
	_calar()
	audio._duck_alvo = 0.0
	audio._duck_ate = 0
	audio.alarm()
	check(audio._duck_alvo <= -6.0, "o alarme continua abaixando a música (%.1f dB)" % audio._duck_alvo)
	var pitch_ok: bool = float(Slots.slot("sfx/curar").get("pitch", -1.0)) == 0.0 and float(Slots.slot("sfx/forja").get("pitch", -1.0)) == 0.12
	check(pitch_ok, "a variação de tom de cada som vem do slot (curar 0, forja 0,12)")

	print("== B) os loops de todos os prédios e lugares")
	var gs := GDScript.new()
	gs.source_code = "extends Node2D\nfunc som_ativo() -> bool:\n\treturn true\n"
	gs.reload()
	var pr: Node = audio.predios
	var loops := Slots.todos().filter(func(i): return String(Slots.slot(i).get("tipo", "")) == "loop_predio")
	check(loops.size() >= 17, "%d slots de loop de prédio no catálogo" % loops.size())
	var sem_loop: Array = []
	for id in loops:
		var grupo := String(Slots.slot(id).get("grupo", ""))
		var f := Slots.som_falso(1.0)
		Slots.poe_falso(id, [f])
		var n: Node2D = gs.new()
		main.add_child(n)
		n.add_to_group(grupo)
		n.global_position = centro + Vector2(20, 0)
		pr.atualiza()
		var tocou: bool = pr._vozes.has(n.get_instance_id()) and pr._vozes[n.get_instance_id()].slot == id
		n.remove_from_group(grupo)
		n.queue_free()
		pr.atualiza()
		if not tocou:
			sem_loop.append("%s (grupo %s)" % [id, grupo])
		Slots.limpa_falsos()
	check(sem_loop.is_empty(), "cada loop toca no grupo certo, perto da câmera%s" % [(" — não tocou: %s" % str(sem_loop)) if not sem_loop.is_empty() else ""])
	for caminho in ["res://scripts/props/social_spot.gd", "res://scripts/props/fornalha.gd", "res://scripts/props/taverna.gd", "res://scripts/props/cemiterio.gd", "res://scripts/props/vagonete.gd", "res://scripts/props/station.gd"]:
		var tem: bool = (load(caminho) as GDScript).get_script_method_list().any(func(m): return m.name == "som_ativo")
		check(tem, "%s responde som_ativo()" % caminho.get_file())

	print("== C) sons soltos pelo contexto e a onda solar")
	var pont := Slots.todos().filter(func(i): return String(Slots.slot(i).get("tipo", "")) == "pontual")
	check(pont.size() >= 12, "%d sons soltos no catálogo" % pont.size())
	var ctx_ruim: Array = []
	var nao_tocou: Array = []
	var fora_do_ctx: Array = []
	for id in pont:
		var sl := Slots.slot(id)
		for c in sl.get("ctx", []):
			if not (String(c) in ["dia", "noite", "mina", "s2", "s3", "s4", "s5", "chuva", "vento"]):
				ctx_ruim.append("%s: %s" % [id, c])
		var f := Slots.som_falso(0.5)
		Slots.poe_falso(id, [f])
		for c in sl.get("ctx", []):
			_calar()
			audio.ambience_now = "xx"
			audio._raining = false
			audio._vento = false
			match String(c):
				"chuva":
					audio._raining = true
				"vento":
					audio._vento = true
				_:
					audio.ambience_now = String(c)
			audio._pont_prox.erase(id)
			audio._pont_t = 0.0
			audio._pontuais_tick(0.0)  # a primeira vez só agenda
			if _tocando(audio._pont_pool, f) != 0 or not audio._pont_prox.has(id):
				nao_tocou.append("%s: tocou já na primeira conta" % id)
			audio._pont_prox[id] = 1  # (venceu)
			audio._pont_t = 0.0
			audio._pontuais_tick(0.0)
			if _tocando(audio._pont_pool, f) != 1:
				nao_tocou.append("%s em %s" % [id, c])
			elif int(audio._pont_prox[id]) < Time.get_ticks_msec() + int(float(sl.intervalo[0]) * 1000.0) - 1000:
				nao_tocou.append("%s: o intervalo não foi agendado" % id)
		# fora do contexto: não toca
		_calar()
		audio.ambience_now = "xx"
		audio._raining = false
		audio._vento = false
		audio._pont_prox[id] = 1
		audio._pont_t = 0.0
		audio._pontuais_tick(0.0)
		if _tocando(audio._pont_pool, f) != 0:
			fora_do_ctx.append(id)
		Slots.limpa_falsos()
	check(ctx_ruim.is_empty(), "os contextos dos sons soltos são válidos%s" % [(" — %s" % str(ctx_ruim)) if not ctx_ruim.is_empty() else ""])
	check(nao_tocou.is_empty(), "cada som solto toca no contexto dele, agenda o próximo no intervalo e na 1ª vez só agenda%s" % [(" — %s" % str(nao_tocou)) if not nao_tocou.is_empty() else ""])
	check(fora_do_ctx.is_empty(), "fora do contexto, nenhum som solto toca%s" % [(" — %s" % str(fora_do_ctx)) if not fora_do_ctx.is_empty() else ""])
	var fp := Slots.som_falso(0.5)
	Slots.poe_falso("pontuais/passaro_canto", [fp])
	audio.ambience_now = "dia"
	audio._pont_prox["pontuais/passaro_canto"] = 1
	audio._pont_t = 0.0
	audio._pontuais_tick(0.0)
	var q: AudioStreamPlayer2D = null
	for p in audio._pont_pool:
		if p.playing and p.stream == fp:
			q = p
	check(q != null and q.bus == &"Ambience" and q.global_position.distance_to(cam.get_screen_center_position()) <= 401.0 and q.global_position.distance_to(cam.get_screen_center_position()) >= 119.0,
		"o som solto sai perto da câmera (120 a 400 px) no bus Ambience")
	Slots.limpa_falsos()
	audio.ambience_now = "dia"
	# a camada da onda solar
	var sun = g("sun")
	var fo := Slots.som_falso(1.0)
	Slots.poe_falso("ambiencia/onda_solar", [fo])
	var amb_fade: float = audio.ambience_crossfade
	audio.ambience_crossfade = 0.3
	sun.wave_left = 30.0
	audio._update_context()
	await _espera(0.6)
	check(audio._onda and audio._over["onda_solar"].playing and audio._over["onda_solar"].stream == fo, "onda solar na superfície: a camada de calor e estática liga")
	var dpos = null
	for c in [env.deep_rect.get_center()]:
		dpos = c
	_camera_em(dpos)
	audio._update_context()
	await _espera(0.6)
	check(not audio._onda and not audio._over["onda_solar"].playing, "nos andares fundos a rocha protege: a camada não soa")
	_camera_em(clareira)
	sun.wave_left = 0.0
	audio._update_context()
	await _espera(0.6)
	check(not audio._onda and not audio._over["onda_solar"].playing, "acabou a onda: a camada desce")
	audio.ambience_crossfade = amb_fade
	Slots.limpa_falsos()

	print("== D) os eventos novos")
	audio.sfx_max_distance = 900.0
	var fk := {}
	for id in ["sfx/lumivoro_grito", "sfx/ferrugento_golpe", "criaturas/gosma_ataque", "criaturas/magmante_ataque", "criaturas/matriarca_ataque"]:
		fk[id] = Slots.som_falso(0.3)
	_calar()
	Slots.poe_falso("sfx/lumivoro_grito", [fk["sfx/lumivoro_grito"]])
	Slots.poe_falso("sfx/ferrugento_golpe", [fk["sfx/ferrugento_golpe"]])
	Slots.poe_falso("criaturas/gosma_ataque", [fk["criaturas/gosma_ataque"]])
	Slots.poe_falso("criaturas/magmante_ataque", [fk["criaturas/magmante_ataque"]])
	for par in [["lumivoro", "sfx/lumivoro_grito"], ["ferrugento", "sfx/ferrugento_golpe"], ["gosma", "criaturas/gosma_ataque"], ["magmante", "criaturas/magmante_ataque"]]:
		_calar()
		audio.criatura_golpe(par[0], "", centro)
		check(_tocando(audio._pool, fk[par[1]]) == 1, "%s ataca com o som dele" % par[0])
	_calar()
	audio.criatura_golpe("lumivoro", "chefe", centro)
	check(_tocando(audio._pool, fk["sfx/lumivoro_grito"]) == 1, "a Matriarca sem arquivo próprio usa o som da espécie dela")
	Slots.poe_falso("criaturas/matriarca_ataque", [fk["criaturas/matriarca_ataque"]])
	_calar()
	audio.criatura_golpe("lumivoro", "chefe", centro)
	check(_tocando(audio._pool, fk["criaturas/matriarca_ataque"]) == 1, "com o arquivo dela, a Matriarca ruge")
	Slots.limpa_falsos()
	var fa := Slots.som_falso(0.3)
	var fc := Slots.som_falso(0.3)
	Slots.poe_falso("sfx/portao_abre", [fa])
	Slots.poe_falso("sfx/portao_fecha", [fc])
	_calar()
	audio.portao(true, centro)
	audio.portao(false, centro)
	check(_tocando(audio._pool, fa) == 1 and _tocando(audio._pool, fc) == 1, "o portão abre e fecha com sons diferentes")
	Slots.limpa_falsos()
	_calar()
	audio.portao(true, centro)
	var antigo := false
	for p in audio._pool:
		if p.playing and p.stream == audio.clank_sound:
			antigo = true
	check(antigo, "sem arquivo, o portão faz o clangue de sempre")
	var fg := Slots.som_falso(0.3)
	Slots.poe_falso("perigo/geiger", [fg])
	_calar()
	audio._geiger_ultimo = -100000
	audio.radiacao(centro)
	audio.radiacao(centro)
	audio.radiacao(centro)
	check(_tocando(audio._pool, fg) == 1, "o Geiger toca uma rajada e espera (3 chamadas seguidas = 1 som)")
	var w: Node = get_nodes_in_group("ipezinhos")[0]
	w.global_position = centro
	w.injured = false
	_calar()
	audio._geiger_ultimo = -100000
	w.radiate(0.1)
	check(_tocando(audio._pool, fg) == 1, "quem é irradiado (ipezinho.radiate) faz o Geiger tocar")
	Slots.limpa_falsos()
	# o "oi" ao selecionar (voz desligável)
	var fh := Slots.som_falso(0.3)
	var fm := Slots.som_falso(0.3)
	Slots.poe_falso("voz/homem_ola", [fh])
	Slots.poe_falso("voz/mulher_ola", [fm])
	audio.voz_ligada = true
	w.gender = "menino"
	w.global_position = centro
	_calar()
	audio._voz_ultima = -100000
	main.set_selection([w])
	check(_tocando(audio._pool, fh) == 1, "selecionar um ipezinho: o 'oi' dele")
	main.set_selection([])
	w.gender = "menina"
	_calar()
	audio._voz_ultima = -100000
	main.set_selection([w])
	check(_tocando(audio._pool, fm) == 1, "selecionar uma ipezinha: o 'oi' dela")
	_calar()
	audio.voz_ligada = false
	audio._voz_ultima = -100000
	main.set_selection([])
	main.set_selection([w])
	check(audio._pool.filter(func(p): return p.playing).is_empty(), "com a voz desligada, selecionar não fala")
	audio.voz_ligada = true
	main.set_selection([])
	Slots.limpa_falsos()
	var ganchos := [
		["res://scripts/creatures/animal.gd", 'Audio.som("animais/coelho_foge"'], ["res://scripts/creatures/animal.gd", 'Audio.som("animais/%s_morre" % kind'],
		["res://scripts/props/barricada.gd", "Audio.portao(novo > 0.5"], ["res://scripts/creatures/creature.gd", "Audio.criatura_golpe(kind, variant"],
		["res://scripts/core/manutencao.gd", 'au.som("maquinas/quebrou"'], ["res://scripts/props/conserto_maquina.gd", 'au.som("maquinas/consertada"'],
		["res://scripts/core/familias.gd", 'Audio.som("vida/bebe_nasce"'], ["res://scripts/core/relacoes.gd", 'Audio.som("vida/casamento"'],
		["res://scripts/props/cemiterio.gd", 'Audio.som("vida/enterro"'], ["res://scripts/props/mineral_node.gd", 'Audio.som("sfx/minerio_esgotado"'],
		["res://scripts/workers/ipezinho.gd", "Audio.radiacao(global_position)"], ["res://scripts/core/main.gd", '"ola"']]
	var soltos := ganchos.filter(func(h): return not FileAccess.get_file_as_string(h[0]).contains(h[1]))
	check(soltos.is_empty(), "os %d ganchos dos eventos novos estão ligados%s" % [ganchos.size(), (" — faltam: %s" % str(soltos)) if not soltos.is_empty() else ""])

	print("== E) prompts do ElevenLabs")
	var doc := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../docs/AUDIO_PROMPTS_ELEVENLABS.md"))
	var sem_prompt: Array = []
	var sem_doc: Array = []
	var musica := 0
	for id in Slots.todos():
		var sl := Slots.slot(id)
		if id.begins_with("musica/"):
			musica += 1
			continue
		if String(sl.get("prompt", "")).length() < 30 or String(sl.get("duracao", "")) == "":
			sem_prompt.append(id)
		if not doc.contains("`%s`" % id):
			sem_doc.append(id)
	check(sem_prompt.is_empty(), "todo som (menos a música) tem prompt e duração%s" % [(" — faltam: %s" % str(sem_prompt)) if not sem_prompt.is_empty() else ""])
	check(doc != "" and sem_doc.is_empty(), "docs/AUDIO_PROMPTS_ELEVENLABS.md lista todos%s" % [(" — faltam: %s" % str(sem_doc)) if not sem_doc.is_empty() else ""])
	check(musica == 2 and doc.contains("Fora desta lista: música"), "a música fica de fora da lista de efeitos (2 slots, citados à parte)")
	var longos := Slots.todos().filter(func(i): return String(Slots.slot(i).get("prompt", "")).length() > 450)
	check(longos.is_empty(), "nenhum prompt passa de 450 caracteres%s" % [(" — %s" % str(longos)) if not longos.is_empty() else ""])

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)
