extends SceneTree
## Bloco 114: os SISTEMAS DE SOM (nenhum áudio novo: os testes usam sons FALSOS criados na memória). RODAR SÓ COM APPDATA ISOLADO.
##   (A) O catálogo data/audio/slots.json: todos os slots do pedido, bus e reserva válidos, a lista docs/audio/PEDIDO_DE_SONS.md.
##   (B) Sem arquivo o slot fica mudo (sem erro); com som, o loop é forçado.
##   (C) Ambiência por andar (S2 a S5), floresta de dia e de noite, vento no inverno e o eco do S5, com troca suave.
##   (D) Loops de prédios posicionais: só perto da câmera, só em atividade, no máximo N.
##   (E) Stingers (com a reserva do som de antes), amanhecer, sino da missa e do funeral.
##   (F) O bus UI separado e as notícias boa e ruim.
##   (G) Passos por tipo de chão e a voz curta (desligável, com persistência).
##   (H) Ducking: a música abaixa de 6 a 10 dB no alarme, no sino e no aviso, e volta.
##   (I) A música de abertura e da introdução (os temas), as Configurações e os ganchos nos eventos do jogo.
const Slots := preload("res://scripts/core/audio_slots.gd")
const Settings := preload("res://scripts/core/settings.gd")
const BUSES := ["Master", "Music", "Ambience", "SFX", "UI"]
const OBRIGATORIOS := [
	"ambiencia/s2_acido", "ambiencia/s3_lava", "ambiencia/s4_cachoeira", "ambiencia/s5_lago", "ambiencia/floresta_dia",
	"ambiencia/floresta_noite", "ambiencia/vento_inverno",
	"predios/fornalha", "predios/taverna", "predios/cemiterio", "predios/vagonete", "predios/coletor_madeira",
	"predios/coletor_minerio", "predios/carpintaria", "predios/sino_missa", "predios/sino_funeral",
	"stingers/amanhecer", "stingers/onda_solar", "stingers/estagio_novo", "stingers/pesquisa_pronta", "stingers/morte",
	"stingers/vitoria", "stingers/derrota", "stingers/missao_cumprida",
	"ui/abrir_janela", "ui/fechar_janela", "ui/confirmar", "ui/erro", "ui/noticia_boa", "ui/noticia_ruim",
	"passos/terra", "passos/cascalho", "passos/pedra", "passos/madeira", "passos/agua",
	"voz/homem_ordem", "voz/homem_dor", "voz/mulher_ordem", "voz/mulher_dor",
	"musica/abertura", "musica/intro"]
var main: Node
var audio: Node
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


func perto(a: float, b: float, tol: float = 0.05) -> bool:
	return absf(a - b) <= tol


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _espera(s: float) -> void:
	await create_timer(s).timeout


## Cala todas as vozes (um teste não ouve o do outro).
func _calar() -> void:
	for p in audio._pool:
		p.stop()
	for p in audio._ui_pool:
		p.stop()
	for p in audio._iface_pool:
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


func _fonte(caminho: String) -> String:
	return FileAccess.get_file_as_string(caminho)


func _roda() -> void:
	Slots.ignora_arquivos = true  # (os testes não dependem dos arquivos de som que o Marco vai gerando)
	await _frames(12)
	var env = g("environment")
	var dn = g("day_night")
	var sun = g("sun")
	var cam = main.get_node("Camera2D")
	var amb_fade: float = audio.ambience_crossfade
	var mus_fade: float = audio.music_crossfade
	audio.ambience_crossfade = 0.3
	audio.music_crossfade = 0.3

	print("== A) o catálogo")
	var ids := Slots.todos()
	check(ids.size() >= OBRIGATORIOS.size(), "%d slots no data/audio/slots.json" % ids.size())
	var faltam := OBRIGATORIOS.filter(func(i): return not Slots.existe(i))
	check(faltam.is_empty(), "todos os slots do pedido existem%s" % ((" — faltam: %s" % str(faltam)) if not faltam.is_empty() else ""))
	var sem_dup := {}
	for i in ids:
		sem_dup[i] = true
	check(sem_dup.size() == ids.size(), "ids únicos")
	var ruins := []
	for i in ids:
		var s := Slots.slot(i)
		if not (String(s.get("tipo", "")) in ["loop", "loop_predio", "tiro", "tema", "pontual"]):
			ruins.append("%s: tipo" % i)
		if AudioServer.get_bus_index(StringName(String(s.get("bus", "")))) < 0:
			ruins.append("%s: bus %s" % [i, s.get("bus", "")])
		if String(s.get("quando", "")) == "":
			ruins.append("%s: sem 'quando'" % i)
		var r := String(s.get("reserva", ""))
		if r.begins_with("prop:") and not ((audio.get(r.substr(5)) is AudioStream) or ((audio.get(r.substr(5)) is Array) and not (audio.get(r.substr(5)) as Array).is_empty())):
			ruins.append("%s: reserva %s" % [i, r])
		if r.begins_with("novo:") and (audio._streams.get(r.substr(5), []) as Array).is_empty():
			ruins.append("%s: reserva %s" % [i, r])
		if String(s.get("tipo", "")) == "loop_predio" and (String(s.get("grupo", "")) == "" or String(s.get("ativo", "")) == ""):
			ruins.append("%s: sem grupo/ativo" % i)
	check(ruins.is_empty(), "cada slot tem tipo, bus que existe, 'quando' e reserva que resolve%s" % ((" — %s" % str(ruins)) if not ruins.is_empty() else ""))
	for b in BUSES:
		check(AudioServer.get_bus_index(StringName(b)) >= 0, "bus %s" % b)
	var doc := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../docs/audio/PEDIDO_DE_SONS.md"))
	var sem_doc := ids.filter(func(i): return not doc.contains("`%s" % i))
	check(doc != "" and sem_doc.is_empty(), "docs/audio/PEDIDO_DE_SONS.md lista todos os slots (python tools/elevenlabs/docs_audio.py)%s" % ((" — faltam: %s" % str(sem_doc)) if not sem_doc.is_empty() else ""))

	print("== B) sem arquivo é mudo, com som repete")
	var sem_arq := ids.filter(func(i): return Slots.arquivos(i).is_empty()).size()
	print("    %d dos %d slots ainda sem arquivo (esperado: os sons vêm do ElevenLabs depois)" % [sem_arq, ids.size()])
	_calar()
	audio.stinger("amanhecer")  # sem arquivo e sem reserva: nada toca, nada quebra
	audio.sino(cam.get_screen_center_position(), "missa")  # (reserva: o sino de antes)
	audio.voz(cam.get_screen_center_position(), "dor")
	audio.ui("noticia_boa")
	check(audio._ui_pool.filter(func(p): return p.playing).is_empty() and audio._iface_pool.filter(func(p): return p.playing).is_empty(), "slot sem arquivo e sem reserva: mudo, sem erro")
	var f := Slots.som_falso(0.5)
	Slots.forca_loop(f)
	check(f.loop_mode == AudioStreamWAV.LOOP_FORWARD and f.loop_end > 0, "o loop é forçado por código (o import não precisa marcar)")

	print("== C) ambiência por andar")
	audio._ctx_timer = 1.0e9  # (congela a conta automática do contexto: o teste chama _update_context à mão)
	var fa := {}
	for i in ["s2_acido", "s3_lava", "s4_cachoeira", "s5_lago", "floresta_dia", "floresta_noite", "vento_inverno"]:
		fa[i] = Slots.som_falso(1.0)
		Slots.poe_falso("ambiencia/" + i, [fa[i]])
	var pos_nivel := {}
	var candidatos: Array[Vector2] = []
	if env.deep_rect.has_area():
		candidatos.append(env.deep_rect.get_center())
	for nome in env.andares.get("andares", {}):
		var a: Dictionary = env.andares.andares[nome]
		candidatos.append(Vector2(float(a.rect[0]) + float(a.rect[2]) * 0.5, float(a.rect[1]) + float(a.rect[3]) * 0.5))
	for c in candidatos:
		var n: int = env.level_at(c)
		if n >= 2 and not pos_nivel.has(n):
			pos_nivel[n] = c
	check(pos_nivel.has(2), "achei o S2 no mapa (níveis achados: %s)" % str(pos_nivel.keys()))
	var chaves := {2: "s2_acido", 3: "s3_lava", 4: "s4_cachoeira", 5: "s5_lago"}
	for n in pos_nivel:
		_camera_em(pos_nivel[n])
		audio._update_context()
		check(audio.ambience_now == "s%d" % n, "câmera no S%d: ambiência %s" % [n, audio.ambience_now])
		await _espera(audio.ambience_crossfade + 0.3)
		var p: AudioStreamPlayer = audio._amb["s%d" % n]
		check(p.playing and p.stream == fa[chaves[n]] and p.volume_db > -3.0, "S%d: o loop dele toca (%.1f dB)" % [n, p.volume_db])
		var outros := 0
		for k in audio._amb:
			if k != "s%d" % n and audio._amb[k].playing and audio._amb[k].volume_db > -30.0:
				outros += 1
		check(outros == 0, "S%d: a troca foi suave e as outras ambiências desceram" % n)
	audio.set_ambience("s5")
	await _espera(audio.ambience_crossfade + 0.3)
	check(perto(audio.eco_atual(), 0.35, 0.06), "S5 (lago): o eco subiu (reverb %.2f)" % audio.eco_atual())
	audio.set_ambience("s2")
	await _espera(audio.ambience_crossfade + 0.3)
	check(audio.eco_atual() < 0.05, "fora do S5 o eco volta a zero (%.2f)" % audio.eco_atual())
	var clareira: Vector2 = (env.clearing_rect as Rect2).get_center()
	_camera_em(clareira)
	dn.time = 10.0
	dn._process(0.0)
	dn.day = 1
	audio._update_context()
	check(audio.ambience_now == "dia" and not audio._vento, "floresta de dia (primavera, sem vento): %s" % audio.ambience_now)
	await _espera(audio.ambience_crossfade + 0.3)
	check(audio._amb["dia"].stream == fa["floresta_dia"] and audio._amb["dia"].playing, "floresta de dia: o loop de pássaros")
	dn.time = dn.day_duration + 5.0
	dn._process(0.0)
	audio._update_context()
	await _espera(audio.ambience_crossfade + 0.3)
	check(audio.ambience_now == "noite" and audio._amb["noite"].stream == fa["floresta_noite"] and audio._amb["noite"].playing, "floresta de noite: o loop de grilos")
	dn.day = sun.days_per_season * 3 + 1
	audio._update_context()
	await _espera(audio.ambience_crossfade + 0.3)
	check(sun.season_index() == 3 and audio._vento and audio._over["vento"].playing and audio._over["vento"].stream == fa["vento_inverno"], "inverno: o vento por cima da floresta")
	dn.day = 1
	audio._update_context()
	await _espera(audio.ambience_crossfade + 0.3)
	check(not audio._vento and not audio._over["vento"].playing, "o vento some quando o inverno acaba")
	dn.time = 10.0
	dn._process(0.0)
	_camera_em(g("armazens").global_position)
	audio._update_context()
	check(audio.ambience_now == "mina", "câmera na mina: ambiência mina (a de sempre)")
	Slots.limpa_falsos()

	print("== D) loops de prédios, só perto da câmera")
	var gs := GDScript.new()
	gs.source_code = "extends Node2D\nvar ativo := true\nfunc som_ativo() -> bool:\n\treturn ativo\n"
	gs.reload()
	_camera_em(clareira)
	cam.position = cam._target_pos
	var centro: Vector2 = cam.get_screen_center_position()
	var ff := Slots.som_falso(1.0)
	Slots.poe_falso("predios/fornalha", [ff])
	var perto_nos: Array = []
	for i in 10:
		var n: Node2D = gs.new()
		main.add_child(n)
		n.add_to_group("fornalhas")
		n.global_position = centro + Vector2(float(i) * 12.0, 0)
		perto_nos.append(n)
	var longe: Node2D = gs.new()
	main.add_child(longe)
	longe.add_to_group("fornalhas")
	longe.global_position = centro + Vector2(6000, 0)
	var parado: Node2D = gs.new()
	main.add_child(parado)
	parado.add_to_group("fornalhas")
	parado.global_position = centro
	parado.ativo = false
	var sem_som: Node2D = gs.new()
	main.add_child(sem_som)
	sem_som.add_to_group("cemiterios")  # (o slot do cemitério não tem som: nem entra)
	sem_som.global_position = centro
	var pr: Node = audio.predios
	pr.atualiza()
	var ids_voz: Dictionary = pr._vozes
	var dentro := perto_nos.filter(func(n): return ids_voz.has(n.get_instance_id())).size()
	check(dentro == pr.max_loops and pr.quantos() == pr.max_loops, "10 fornalhas perto: no máximo %d loops (tocando %d)" % [pr.max_loops, pr.quantos()])
	check(ids_voz.has(perto_nos[0].get_instance_id()) and not ids_voz.has(perto_nos[9].get_instance_id()), "ficam os mais perto da câmera")
	check(not ids_voz.has(longe.get_instance_id()), "a fornalha longe da câmera não toca")
	check(not ids_voz.has(parado.get_instance_id()), "a fornalha parada (sem atividade) não toca")
	check(not ids_voz.has(sem_som.get_instance_id()), "slot sem arquivo: não cria loop")
	var vz: Dictionary = ids_voz[perto_nos[0].get_instance_id()]
	check(vz.player.stream == ff and vz.player.playing and vz.player.bus == &"SFX" and vz.player is AudioStreamPlayer2D, "o loop é um AudioStreamPlayer2D no lugar do prédio")
	_camera_em(clareira + Vector2(5000, 0))
	pr.atualiza()
	check(perto_nos.filter(func(n): return pr._vozes.has(n.get_instance_id())).is_empty(), "a câmera foi embora: os loops de lá soltam")
	_camera_em(clareira)
	for n in perto_nos:
		n.ativo = false
	pr.atualiza()
	check(perto_nos.filter(func(n): return pr._vozes.has(n.get_instance_id())).is_empty(), "prédio que para de funcionar solta o loop")
	for n in perto_nos + [longe, parado, sem_som]:
		n.queue_free()
	await _frames(2)
	pr.atualiza()
	Slots.limpa_falsos()
	for caminho in ["res://scripts/props/station.gd", "res://scripts/props/fornalha.gd", "res://scripts/props/taverna.gd", "res://scripts/props/cemiterio.gd", "res://scripts/props/vagonete.gd"]:
		var tem: bool = (load(caminho) as GDScript).get_script_method_list().any(func(m): return m.name == "som_ativo")
		check(tem, "%s responde som_ativo()" % caminho.get_file())

	print("== E) stingers, amanhecer e sinos")
	_calar()
	var fs := {}
	for nome in ["amanhecer", "onda_solar", "estagio_novo", "pesquisa_pronta", "morte", "vitoria", "derrota", "missao_cumprida"]:
		fs[nome] = Slots.som_falso(0.5)
		Slots.poe_falso("stingers/" + nome, [fs[nome]])
	for nome in fs:
		_calar()
		audio.stinger(nome)
		check(_tocando(audio._ui_pool, fs[nome]) == 1, "stinger %s toca" % nome)
	Slots.limpa_falsos()
	_calar()
	audio.stinger("estagio_novo")
	check(_tocando(audio._ui_pool, audio.fanfare_sound) == 1, "sem arquivo, o stinger do estágio usa a fanfarra de antes (reserva)")
	_calar()
	audio.stinger("morte")
	check(_tocando(audio._ui_pool, audio.toll_sound) == 1, "sem arquivo, o stinger da morte usa o sino de antes (reserva)")
	Slots.poe_falso("stingers/amanhecer", [fs["amanhecer"]])
	_calar()
	audio._dia_visto = -1
	audio._update_context()
	check(_tocando(audio._ui_pool, fs["amanhecer"]) == 0, "o primeiro dia que o jogo vê não toca o amanhecer")
	dn.day += 1
	audio._update_context()
	check(_tocando(audio._ui_pool, fs["amanhecer"]) == 1, "o dia virou: o stinger do amanhecer")
	audio._update_context()
	check(_tocando(audio._ui_pool, fs["amanhecer"]) == 1, "no mesmo dia não repete")
	Slots.limpa_falsos()
	# o sino da igreja: só na subida (começo da missa / do funeral)
	var cal = g("calendario")
	var fm := Slots.som_falso(1.0)
	var ffu := Slots.som_falso(1.0)
	Slots.poe_falso("predios/sino_missa", [fm])
	Slots.poe_falso("predios/sino_funeral", [ffu])
	var ig := Node2D.new()
	main.add_child(ig)
	ig.global_position = cam.get_screen_center_position()
	_calar()
	audio._duck_alvo = 0.0
	audio._duck_ate = 0
	cal._sino_missa = false
	cal._sino_funeral = false
	cal._toca_sinos(true, ig, null)
	check(_tocando(audio._pool, fm) == 1, "a missa começou: o sino toca na igreja")
	check(audio._duck_alvo <= -6.0, "o sino abaixa a música (%.1f dB)" % audio._duck_alvo)
	cal._toca_sinos(true, ig, null)
	check(_tocando(audio._pool, fm) == 1, "a missa continua: o sino não repete")
	cal._toca_sinos(false, ig, null)
	cal._toca_sinos(true, ig, null)
	check(_tocando(audio._pool, fm) == 2, "outra missa: o sino toca de novo")
	cal._toca_sinos(false, ig, ig)
	check(_tocando(audio._pool, ffu) == 1, "o funeral começou: o sino do funeral")
	ig.global_position = cam.get_screen_center_position() + Vector2(9000, 0)
	_calar()
	audio._duck_alvo = 0.0
	audio._duck_ate = 0
	cal._sino_missa = false
	cal._toca_sinos(true, ig, null)
	check(_tocando(audio._pool, fm) == 0 and audio._duck_alvo == 0.0, "igreja longe da câmera: o sino não toca e a música não abaixa")
	cal._sino_missa = false
	cal._sino_funeral = false
	ig.queue_free()
	Slots.limpa_falsos()

	print("== F) o bus UI separado")
	_calar()
	var fc := Slots.som_falso(0.3)
	Slots.poe_falso("ui/clique", [fc])
	for p in audio._iface_pool:
		check(p.bus == &"UI", "voz de interface no bus UI")
		break
	audio.click()
	check(_tocando(audio._iface_pool, fc) == 1 and _tocando(audio._ui_pool, fc) == 0, "o clique toca no bus UI (e não no SFX)")
	for nome in ["abrir_janela", "fechar_janela", "confirmar", "erro"]:
		_calar()
		var fu := Slots.som_falso(0.3)
		Slots.poe_falso("ui/" + nome, [fu])
		match nome:
			"abrir_janela":
				audio.ui_open()
			"fechar_janela":
				audio.ui_close()
			"confirmar":
				audio.confirmar()
			"erro":
				audio.error()
		check(_tocando(audio._iface_pool, fu) == 1, "ui/%s toca no bus UI" % nome)
	audio.ui_volume = 0.5
	audio.apply_volumes()
	check(perto(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"UI")), linear_to_db(0.5), 0.1), "o slider Interface mexe no bus UI")
	audio.ui_volume = 0.8
	audio.apply_volumes()
	var fb := Slots.som_falso(0.3)
	var fr := Slots.som_falso(0.3)
	Slots.poe_falso("ui/noticia_boa", [fb])
	Slots.poe_falso("ui/noticia_ruim", [fr])
	_calar()
	audio._noticia_ultima = -100000
	audio.noticia_cor(Color(0.55, 1.0, 0.5))
	check(_tocando(audio._iface_pool, fb) == 1, "aviso verde: notícia boa")
	audio.noticia_cor(Color(0.55, 1.0, 0.5))
	check(_tocando(audio._iface_pool, fb) == 1, "duas notícias seguidas: a segunda espera o intervalo")
	_calar()
	audio._noticia_ultima = -100000
	audio.noticia_cor(Color(1.0, 0.4, 0.35))
	check(_tocando(audio._iface_pool, fr) == 1, "aviso vermelho: notícia ruim")
	_calar()
	audio._noticia_ultima = -100000
	audio.noticia_cor(Color(0.9, 0.85, 0.5))
	audio.noticia_cor(Color(0.6, 0.7, 0.9))
	check(audio._iface_pool.filter(func(p): return p.playing).is_empty(), "aviso neutro: silêncio")
	Slots.limpa_falsos()

	print("== G) passos por chão e voz")
	audio.sfx_max_distance = 1.0e9
	var fp := {}
	for chao in ["terra", "cascalho", "pedra", "madeira", "agua"]:
		fp[chao] = Slots.som_falso(0.2)
		Slots.poe_falso("passos/" + chao, [fp[chao]])
	var pos_terra := clareira
	var pos_mina: Vector2 = g("armazens").global_position
	check(audio.chao_de(pos_terra) == "terra", "a clareira é terra (%s)" % audio.chao_de(pos_terra))
	check(audio.chao_de(pos_mina) == "cascalho", "a pedreira (área da mina) é cascalho (%s)" % audio.chao_de(pos_mina))
	if pos_nivel.has(2):
		check(audio.chao_de(pos_nivel[2]) == "pedra", "os andares fundos são pedra (%s)" % audio.chao_de(pos_nivel[2]))
	var camin = g("caminhos")
	var cel: Vector2i = camin.celula_de(pos_terra + Vector2(300, 300))
	for tipo in ["terra", "cascalho", "pedra"]:
		camin.celulas[cel] = tipo
		check(audio.chao_de(camin.centro_de(cel)) == tipo, "caminho pintado de %s: o passo é de %s" % [tipo, tipo])
	camin.celulas.erase(cel)
	var pocas := get_nodes_in_group("pocas_perigo")
	if not pocas.is_empty():
		check(audio.chao_de(pocas[0].global_position) == "agua", "em cima de uma poça: água")
	else:
		print("    (sem poça no mapa deste teste: água só conferida pelo slot)")
	var plataforma: Node2D = null
	for grupo in ["elevadores", "elevador", "espirais"]:
		for n in get_nodes_in_group(grupo):
			if n is Node2D and plataforma == null:
				plataforma = n
	if plataforma:
		check(audio.chao_de(plataforma.global_position) == "madeira", "perto de plataforma, escada ou elevador: madeira")
	for chao in ["terra", "cascalho", "pedra"]:
		_calar()
		var pp: Vector2 = {"terra": pos_terra, "cascalho": pos_mina, "pedra": pos_nivel.get(2, pos_mina)}[chao]
		audio._step_tokens = 5.0
		audio.step(pp)
		check(_tocando(audio._pool, fp[chao]) == 1, "o passo em chão de %s toca o som de %s" % [chao, chao])
	Slots.limpa_falsos()
	_calar()
	audio._step_tokens = 5.0
	audio.step(pos_terra)
	var legado := false
	for p in audio._pool:
		if p.playing and audio.step_sounds.has(p.stream):
			legado = true
	check(legado, "sem arquivo de passo, vale o passo de sempre (reserva)")
	var fvh := Slots.som_falso(0.3)
	var fvm := Slots.som_falso(0.3)
	Slots.poe_falso("voz/homem_dor", [fvh])
	Slots.poe_falso("voz/mulher_dor", [fvm])
	audio.voz_ligada = true
	_calar()
	audio._voz_ultima = -100000
	audio.voz(centro, "dor", "menino")
	check(_tocando(audio._pool, fvh) == 1, "voz curta do homem (dor)")
	audio.voz(centro, "dor", "menino")
	check(_tocando(audio._pool, fvh) == 1, "duas vozes seguidas: a segunda espera o intervalo")
	_calar()
	audio._voz_ultima = -100000
	audio.voz(centro, "dor", "menina")
	check(_tocando(audio._pool, fvm) == 1, "voz curta da mulher (dor)")
	_calar()
	audio.voz_ligada = false
	audio._voz_ultima = -100000
	audio.voz(centro, "dor", "menino")
	check(audio._pool.filter(func(p): return p.playing).is_empty(), "voz desligada: silêncio")
	audio.save_settings()
	check(Settings.get_value("audio", "voz_ligada", true) == false, "a escolha da voz fica nas configurações")
	audio.voz_ligada = true
	audio.ui_volume = 0.6
	audio.save_settings()
	check(perto(float(Settings.get_value("audio", "ui_volume", 0.0)), 0.6, 0.001), "o volume da interface fica nas configurações")
	audio.ui_volume = 0.8
	audio.voz_ligada = true
	audio.save_settings()
	Slots.limpa_falsos()
	audio.sfx_max_distance = 900.0

	print("== H) ducking")
	audio._ctx_timer = 0.0
	check(audio.duck_alarme_db <= -6.0 and audio.duck_alarme_db >= -10.0 and audio.duck_sino_db <= -6.0 and audio.duck_sino_db >= -10.0 and audio.duck_aviso_db <= -6.0 and audio.duck_aviso_db >= -10.0,
		"os 3 ducks ficam entre -6 e -10 dB (alarme %.0f, sino %.0f, aviso %.0f)" % [audio.duck_alarme_db, audio.duck_sino_db, audio.duck_aviso_db])
	var amp: AudioEffectAmplify = audio._duck_fx
	var musica_idx := AudioServer.get_bus_index(&"Music")
	var tem_amp := false
	for i in AudioServer.get_bus_effect_count(musica_idx):
		if AudioServer.get_bus_effect(musica_idx, i) == amp:
			tem_amp = true
	check(amp != null and tem_amp, "o bus Music tem o efeito de ducking")
	var seg: float = audio.duck_segura
	var ata: float = audio.duck_ataque
	var sol: float = audio.duck_solta
	audio.duck_segura = 0.4
	audio.duck_ataque = 0.1
	audio.duck_solta = 0.4
	var vol_musica := AudioServer.get_bus_volume_db(musica_idx)
	audio.duck("alarme")
	await _espera(0.35)
	check(perto(audio.duck_atual(), audio.duck_alarme_db, 0.6) and perto(amp.volume_db, audio.duck_atual(), 0.01), "alarme: a música abaixou (%.1f dB)" % audio.duck_atual())
	check(perto(AudioServer.get_bus_volume_db(musica_idx), vol_musica, 0.01), "o slider de música não é mexido pelo ducking")
	await _espera(1.5)
	check(audio.duck_atual() > -0.3, "e voltou sozinha (%.1f dB)" % audio.duck_atual())
	audio.toll()
	await _espera(0.35)
	check(perto(audio.duck_atual(), audio.duck_sino_db, 0.6), "sino: a música abaixa menos (%.1f dB)" % audio.duck_atual())
	await _espera(1.5)
	g("hud").show_banner("TESTE", "aviso grande")
	await _espera(0.35)
	check(perto(audio.duck_atual(), audio.duck_aviso_db, 0.6), "aviso (banner): a música abaixa só um pouco (%.1f dB)" % audio.duck_atual())
	audio.alarm()
	await _espera(0.35)
	check(perto(audio.duck_atual(), audio.duck_alarme_db, 0.6), "alarme em cima do aviso: vale o mais fundo (%.1f dB)" % audio.duck_atual())
	await _espera(1.6)
	check(audio.duck_atual() > -0.3, "passou tudo: a música voltou ao normal")
	audio.click()
	await _espera(0.3)
	check(audio.duck_atual() > -0.3, "um clique comum não abaixa a música")
	audio.duck_segura = seg
	audio.duck_ataque = ata
	audio.duck_solta = sol

	print("== I) abertura, intro, configurações e ganchos")
	var fab := Slots.som_falso(2.0)
	var fin := Slots.som_falso(2.0)
	Slots.poe_falso("musica/abertura", [fab])
	Slots.poe_falso("musica/intro", [fin])
	check(audio.music_enabled and audio._music_player.stream != null, "a música do jogo está ligada")
	audio.tema("abertura")
	await _espera(audio.music_crossfade + 0.3)
	check(audio.tema_atual() == "abertura" and audio._tema_player.playing and audio._tema_player.stream == fab and audio._tema_player.volume_db > -3.0, "tema da abertura: toca no lugar da música do jogo")
	check(not audio._music_player.playing or audio._music_player.volume_db < -30.0, "a música do jogo desceu")
	audio.set_danger(true)
	check(not audio._danger_player.playing, "com o tema tocando, o perigo espera")
	audio.set_danger(false)
	audio.tema("intro")
	await _espera(audio.music_crossfade + 0.3)
	check(audio.tema_atual() == "intro" and audio._tema_player.stream == fin and audio._tema_player.playing, "tema da intro")
	audio.tema("")
	await _espera(audio.music_crossfade + 0.3)
	check(audio.tema_atual() == "" and not audio._tema_player.playing and audio._music_player.playing and audio._music_player.volume_db > -3.0, "tema vazio: volta a música do jogo")
	Slots.limpa_falsos()
	audio.tema("abertura")
	check(audio.tema_atual() == "", "sem arquivo de tema, a música do jogo segue (nada muda)")
	audio.ambience_crossfade = amb_fade
	audio.music_crossfade = mus_fade
	var painel: VBoxContainer = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(painel)
	await _frames(3)
	var caixa: CheckBox = null
	var achou_slider := false
	var pilha: Array = [painel]
	while not pilha.is_empty():
		var no: Node = pilha.pop_back()
		pilha.append_array(no.get_children())
		if no is CheckBox and (no as CheckBox).text == "Voz dos ipezinhos":
			caixa = no
		if no is Label and (no as Label).text.begins_with("Interface"):
			achou_slider = true
	check(caixa != null and caixa.button_pressed == audio.voz_ligada, "as Configurações têm a caixa 'Voz dos ipezinhos'")
	check(achou_slider, "as Configurações têm o slider 'Interface'")
	if caixa:
		caixa.button_pressed = false
		check(audio.voz_ligada == false and Settings.get_value("audio", "voz_ligada", true) == false, "desmarcar a caixa desliga a voz e salva")
		caixa.button_pressed = true
		check(audio.voz_ligada == true, "marcar liga a voz de novo")
	painel.free()
	var ganchos := [
		["res://scripts/core/sun.gd", 'Audio.stinger("onda_solar")'], ["res://scripts/core/sun.gd", 'Audio.stinger("vitoria")'],
		["res://scripts/props/centro_vila.gd", 'Audio.stinger("estagio_novo")'], ["res://scripts/core/research.gd", 'Audio.stinger("pesquisa_pronta")'],
		["res://scripts/workers/ipezinho.gd", 'Audio.stinger("morte")'], ["res://scripts/core/morale.gd", 'Audio.stinger("derrota")'],
		["res://scripts/core/missoes.gd", 'stinger("missao_cumprida")'], ["res://scripts/core/hud.gd", "Audio.noticia_cor(color)"],
		["res://scripts/core/hud.gd", 'Audio.duck("aviso")'], ["res://scripts/core/calendario.gd", "Audio.sino("],
		["res://scripts/workers/ipezinho.gd", '"dor", gender'], ["res://scripts/workers/ipezinho.gd", '"cansaco", gender'],
		["res://scripts/props/taverna.gd", '"alegria"'], ["res://scripts/core/main.gd", '"ordem"'],
		["res://scripts/core/main.gd", 'Audio.tema("")'], ["res://scripts/ui/start_menu.gd", 'Audio.tema("abertura")'],
		["res://scripts/ui/intro.gd", 'Audio.tema("intro")'], ["res://scripts/ui/intro_cinema.gd", 'Audio.tema("")'],
		["res://scripts/core/defense.gd", "Audio.alarm()"], ["res://scripts/core/morale.gd", "Audio.toll()"]]
	var soltos := ganchos.filter(func(h): return not _fonte(h[0]).contains(h[1]))
	check(soltos.is_empty(), "os %d ganchos estão ligados nos eventos do jogo%s" % [ganchos.size(), (" — faltam: %s" % str(soltos)) if not soltos.is_empty() else ""])

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)
