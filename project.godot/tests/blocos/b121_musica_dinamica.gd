extends SceneTree
## Bloco 121: a MÚSICA DINÂMICA (Prompt 7): camadas por estação (AudioStreamSynchronized: pad, melodia, percussão) + clipes de estação e de tema trocados no compasso
## (AudioStreamInteractive), temas de menu, vitória e derrota, mix nas Configurações, e o FALLBACK (sem as camadas, as 2 músicas de antes). RODAR SÓ COM APPDATA ISOLADO.
##   (A) carga: 4 estações completas e 3 temas, o Interactive com 7 clipes e as transições; (B) volumes por camada (dia, noite, perigo, fundo da mina, mix);
##   (C) tocando de verdade (tem som no bus Music); (D) trocas: de estação só na virada do compasso, tema de vitória e volta, tema do menu;
##   (E) fallback: sem arquivos, desligada ou em headless sem forçar, o jogo toca como antes; (F) Configurações.
const Slots := preload("res://scripts/core/audio_slots.gd")
const Dinamica := preload("res://scripts/core/musica_dinamica.gd")
var audio: Node
var main: Node
var din: Node
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
	if Time.get_ticks_msec() - _t0 > 250000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


## Espera tempo de verdade (o mixer do áudio troca de clipe no ritmo dele, não no dos quadros).
func _espera(seg: float) -> void:
	await create_timer(seg).timeout


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _roda() -> void:
	await _frames(5)
	Slots.ignora_arquivos = false
	Slots.limpa_cache()
	audio._ctx_timer = 1.0e9  # congela o contexto automático: o teste manda no estado
	audio._pont_t = 1.0e9
	din = audio.dinamica
	check(din != null and din.get_script() == Dinamica, "o Audio tem o nó MusicaDinamica")

	print("== (A) a carga: estações, temas e o AudioStreamInteractive")
	var t0 := Time.get_ticks_msec()
	check(din.carrega(), "carrega(): há estação completa")
	print("    (carregou as 15 faixas em %d ms)" % (Time.get_ticks_msec() - t0))
	for i in 4:
		check(din.tem_estacao(i), "estação %s completa (pad, melodia e percussão)" % Dinamica.ESTACOES[i])
	for nome in Dinamica.TEMAS:
		check(din.tem_tema(nome), "tema_%s existe" % nome)
	var it: AudioStreamInteractive = din._interativo
	check(it != null and it.clip_count == 7, "o Interactive tem 7 clipes: 4 estações + menu, vitória e derrota")
	check(it.get_clip_stream(0) is AudioStreamSynchronized and (it.get_clip_stream(0) as AudioStreamSynchronized).stream_count == 3, "cada estação é um AudioStreamSynchronized de 3 camadas")
	var tam := {}
	for l in 3:
		var w := (it.get_clip_stream(0) as AudioStreamSynchronized).get_sync_stream(l) as AudioStreamWAV
		tam[int(snappedf(w.get_length(), 0.01) * 100.0)] = true
		check(w.loop_mode == AudioStreamWAV.LOOP_FORWARD, "camada %d da primavera repete" % l)
	check(tam.size() == 1, "as 3 camadas têm a mesma duração (alinhadas)")
	check(it.has_transition(0, 1) and it.has_transition(3, 0) and it.has_transition(0, 4) and it.has_transition(5, 2), "há transição entre todos os clipes")
	check(it.get_transition_to_time(0, 1) == AudioStreamInteractive.TRANSITION_TO_TIME_SAME_POSITION, "estação -> estação continua do mesmo ponto")
	check(it.get_transition_to_time(0, 5) == AudioStreamInteractive.TRANSITION_TO_TIME_START and it.get_transition_to_time(5, 0) == AudioStreamInteractive.TRANSITION_TO_TIME_START, "tema entra e sai do começo")
	check(it.get_transition_fade_mode(0, 1) == AudioStreamInteractive.FADE_CROSS and is_equal_approx(it.get_transition_fade_beats(0, 1), din.crossfade_s), "a troca é um crossfade de %.0f s" % din.crossfade_s)
	check(is_equal_approx(din.compasso_s(), 3.0) and 117.0 / din.compasso_s() == 39.0, "o compasso dura 3 s e a faixa (117 s) fecha 39 compassos")

	print("== (B) o volume de cada camada")
	audio.musica_dinamica = true
	audio.mix_melodia = 1.0
	audio.mix_pad = 1.0
	audio.mix_percussao = 1.0
	din._clip = 0
	din._estacao = 0
	din._jogando = true
	_estado(false, false, false)
	check(is_equal_approx(din.alvo_db(Dinamica.L_MELODIA), din.melodia_dia_db) and is_equal_approx(din.alvo_db(Dinamica.L_PAD), din.pad_dia_db) and din.alvo_db(Dinamica.L_PERCUSSAO) <= -59.0, "dia: melodia %.0f, pad %.0f, sem percussão" % [din.alvo_db(1), din.alvo_db(0)])
	_estado(true, false, false)
	check(din.alvo_db(Dinamica.L_MELODIA) <= -59.0 and is_equal_approx(din.alvo_db(Dinamica.L_PAD), din.pad_noite_db), "noite: sem melodia, o pad assume (%.0f dB)" % din.alvo_db(0))
	_estado(false, true, false)
	check(is_equal_approx(din.alvo_db(Dinamica.L_PERCUSSAO), din.percussao_perigo_db) and is_equal_approx(din.alvo_db(Dinamica.L_MELODIA), din.melodia_dia_db + din.melodia_perigo_db), "perigo: entra a percussão (%.0f) e a melodia cede (%.0f)" % [din.alvo_db(2), din.alvo_db(1)])
	_estado(false, false, true)
	check(is_equal_approx(din.alvo_db(Dinamica.L_MELODIA), din.melodia_dia_db + din.melodia_fundo_db) and is_equal_approx(din.alvo_db(Dinamica.L_PAD), din.pad_dia_db + din.pad_fundo_db), "fundo da mina: mais drone (%.0f) e menos melodia (%.0f)" % [din.alvo_db(0), din.alvo_db(1)])
	check(din.alvo_db(Dinamica.L_PAD) > din.pad_dia_db and din.alvo_db(Dinamica.L_MELODIA) < din.melodia_dia_db, "...comparado com a superfície de dia")
	_estado(true, true, true)
	check(din.alvo_db(Dinamica.L_PERCUSSAO) > -59.0 and din.alvo_db(Dinamica.L_MELODIA) <= -59.0, "noite + perigo + fundo: percussão e pad, nada de melodia")
	audio.mix_melodia = 0.5
	_estado(false, false, false)
	check(absf(din.alvo_db(Dinamica.L_MELODIA) - (din.melodia_dia_db + linear_to_db(0.5))) < 0.01, "o mix da melodia a 50%% abaixa 6 dB (%.1f)" % din.alvo_db(1))
	audio.mix_melodia = 0.0
	check(din.alvo_db(Dinamica.L_MELODIA) <= -50.0, "o mix da melodia em 0 cala a melodia")
	audio.mix_melodia = 1.0
	audio.mix_percussao = 0.0
	_estado(false, true, false)
	check(din.alvo_db(Dinamica.L_PERCUSSAO) <= -50.0, "o mix da percussão em 0 cala a percussão no perigo")
	audio.mix_percussao = 1.0

	print("== (E) o fallback: sem arquivos, desligada, ou headless sem forçar, o jogo toca as 2 músicas de antes")
	Dinamica.forcar = false
	check(not din.ativa(), "em headless sem forçar a dinâmica está desligada (os outros testes seguem como antes)")
	Dinamica.forcar = true
	check(din.ativa(), "forçada, com os arquivos: ativa")
	audio.musica_dinamica = false
	check(not din.ativa(), "desligada nas Configurações: não toca")
	audio.musica_dinamica = true
	Slots.ignora_arquivos = true
	Slots.limpa_cache()
	din._carregada = false
	din._interativo = null
	check(not din.ativa() and not din.carrega(), "sem os arquivos das camadas: não toca (o jogo usa jogo e perigo)")
	audio.set_danger(false)
	audio.aplica_musica_dinamica()
	check(not audio.dinamica_ligada(), "o Audio não entrega a música pra dinâmica sem camadas")
	check(audio._slot_stream("musica/jogo") == audio.music, "a música do jogo continua a de antes (reserva)")
	Slots.ignora_arquivos = false
	Slots.limpa_cache()
	din._carregada = false
	din.carrega()

	print("== (C) tocando de verdade")
	din.relogio_ms = 100000
	audio.music_enabled = true
	Dinamica.forcar = true
	din.atualiza(0, false, false, false, true)
	audio._reconcilia_musica()
	check(din.estado().tocando and din.clipe_atual() == 0, "a primavera toca (clipe 0)")
	check(audio.dinamica_ligada(), "o Audio entregou a música do jogo pra dinâmica")
	await _frames(40)
	check(not audio._music_player.playing or audio._music_player.volume_db < -20.0, "a música antiga do jogo fica muda enquanto a dinâmica toca")
	var pico := AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index(&"Music"), 0)
	check(pico > -60.0, "o bus Music tem som (pico %.0f dB)" % pico)
	check(din._player.bus == &"Music", "toca no bus Music (o slider de música vale)")
	# as camadas descem e sobem aos poucos, não de uma vez
	din.atualiza(0, true, false, false, true)
	await _frames(2)
	check(din.db_atual(Dinamica.L_MELODIA) > -59.0, "a noite chega: a melodia ainda não sumiu de uma vez (%.1f dB)" % din.db_atual(1))
	for i in 12:
		din._process(0.5)
	check(din.db_atual(Dinamica.L_MELODIA) <= -59.0 and absf(din.db_atual(Dinamica.L_PAD) - din.pad_noite_db) < 0.5, "...e some em segundos (melodia %.0f, pad %.0f)" % [din.db_atual(1), din.db_atual(0)])

	print("== (D) as trocas")
	din.atualiza(0, false, false, false, true)
	din.relogio_ms = 100000
	din._inicio_ms = 100000
	din._clip = 0
	din._troca_clip = -1
	din.relogio_ms = 101000  # 1 s depois do começo: a virada do compasso é em 3 s
	din.atualiza(1, false, false, false, true)
	var est: Dictionary = din.estado()
	check(est.troca == 1 and est.troca_em_ms == 103000, "estação nova (verão): a troca espera a virada do compasso (em %d ms, a 3,0 s)" % est.troca_em_ms)
	check(din.clipe_atual() == 0, "...até lá a primavera segue tocando")
	din.relogio_ms = 103010
	din._process(0.016)
	await _espera(0.4)
	check(din.estado().clipe == 1 and din.clipe_atual() == 1, "na virada do compasso entra o verão (clipe 1) %s atual=%d" % [str(din.estado()), din.clipe_atual()])
	din._inicio_ms = 100000
	din.relogio_ms = 102900  # a 2,9 s: quase em cima da virada, espera a seguinte
	din.atualiza(2, false, false, false, true)
	check(din.estado().troca_em_ms == 106000, "quase em cima da virada: espera o compasso seguinte (em %d ms)" % din.estado().troca_em_ms)
	din.relogio_ms = 106010
	din._process(0.016)
	await _espera(0.4)
	check(din.clipe_atual() == 2, "o outono entra no compasso seguinte")
	# o tema de vitória entra na hora e a música do jogo volta depois
	check(din.toca_tema("vitoria"), "toca_tema('vitoria') toca")
	await _espera(0.4)
	check(din.clipe_atual() == 5 and din.estado().tema == "vitoria", "o tema de vitória entra (clipe 5)")
	din.relogio_ms += 61000
	din._process(0.016)
	await _espera(0.4)
	check(din.estado().tema == "" and din.clipe_atual() == 2, "passados 60 s a música do jogo volta (outono)")
	check(din.toca_tema("derrota") and din.estado().tema == "derrota", "o tema de derrota também toca")
	din.relogio_ms += 61000
	din._process(0.016)
	await _espera(0.4)
	check(not din.toca_tema("menu"), "só vitória e derrota são temas de jogo")
	# o tema do menu (sem partida)
	din.atualiza(0, false, false, false, false)
	await _espera(0.4)
	check(not din.estado().tocando or din.clipe_desejado() == -1, "sem partida e sem menu: a dinâmica para")
	din.menu(true)
	await _espera(0.4)
	check(din.estado().tocando and din.clipe_atual() == 4, "o tema do menu toca na tela inicial (clipe 4) %s atual=%d" % [str(din.estado()), din.clipe_atual()])
	din.menu(false)
	din.atualiza(0, false, false, false, true)
	await _espera(0.4)
	check(din.clipe_atual() == 0, "ao começar a partida o tema sai e entra a primavera (do começo) %s atual=%d" % [str(din.estado()), din.clipe_atual()])

	print("== (F) integração com o Audio e as Configurações")
	audio.set_danger(false)
	audio._reconcilia_musica()
	audio.set_danger(true)
	check(audio.is_danger() and audio.dinamica_ligada(), "a invasão (set_danger) não liga a música de perigo de antes: a dinâmica tem a percussão")
	audio.set_danger(false)
	audio.musica_dinamica = false
	audio.aplica_musica_dinamica()
	check(not audio.dinamica_ligada(), "desligar 'Música em camadas' devolve o jogo às 2 músicas de antes")
	await _frames(40)
	check(audio._music_player.playing, "...e a música do jogo de antes volta a tocar")
	audio.musica_dinamica = true
	audio.aplica_musica_dinamica()
	check(audio.dinamica_ligada(), "ligar de novo volta pras camadas")
	var painel := FileAccess.get_file_as_string("res://scripts/ui/settings_panel.gd")
	check(painel.contains("Música em camadas") and painel.contains("mix_melodia") and painel.contains("mix_pad") and painel.contains("mix_percussao"), "o painel de Configurações tem a caixa e os 3 volumes das camadas")
	var fonte := FileAccess.get_file_as_string("res://scripts/core/audio_manager.gd")
	check(fonte.contains('"musica_dinamica", "mix_melodia", "mix_pad", "mix_percussao"'), "o toggle e o mix são salvos nas Configurações")
	check(audio.has_method("stinger") and FileAccess.get_file_as_string("res://scripts/core/audio_manager.gd").contains("dinamica.toca_tema(nome)"), "o stinger de vitória e de derrota chama o tema")

	# deixa tudo como estava
	Dinamica.forcar = false
	audio.musica_dinamica = true
	din.menu(false)
	din.atualiza(0, false, false, false, false)
	audio._reconcilia_musica()
	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


func _estado(noite: bool, perigo: bool, fundo: bool) -> void:
	din._noite = noite
	din._perigo = perigo
	din._fundo = fundo
