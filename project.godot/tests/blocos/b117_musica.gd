extends SceneTree
## Bloco 117: a MÚSICA do jogo (gerada pela API de música do ElevenLabs) — abertura, intro, música do jogo e de perigo — e o conserto da ambiência da mina.
## RODAR SÓ COM APPDATA ISOLADO.
##   (A) Os 4 arquivos existem em assets/audio/musica/, carregam como WAV estéreo de 44,1 kHz, têm a duração pedida, volume no alvo (RMS -18, pico <= -1) e os loops emendam.
##   (B) O jogo usa os arquivos: a música do jogo e a de perigo vêm dos slots (não mais do loop antigo), a mina também (o som antigo entrava no _ready e ficava),
##       a abertura e a intro tocam pelo Audio.tema(), a intro não repete e os loops repetem.
##   (C) Sem os arquivos (ignorando-os) volta o som de antes, sem erro.
##   (D) A ferramenta (tools/elevenlabs/gerar_musica.py) e os slots (prompt e duração) existem; --lista funciona e o pedido seguinte não gasta nada (já gerado).
const Slots := preload("res://scripts/core/audio_slots.gd")
const ARQUIVOS := {"abertura": 72.0, "intro": 60.0, "jogo": 117.0, "perigo": 57.0}
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
	if Time.get_ticks_msec() - _t0 > 300000:
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


func _roda() -> void:
	await _frames(5)
	Slots.ignora_arquivos = false
	Slots.limpa_cache()

	print("== (A) os arquivos")
	for nome in ARQUIVOS:
		var id: String = "musica/" + String(nome)
		check(Slots.tem(id), "%s tem arquivo" % id)
		var st = Slots.streams(id)[0] if Slots.tem(id) else null
		check(st is AudioStreamWAV and (st as AudioStreamWAV).stereo and (st as AudioStreamWAV).mix_rate == 44100, "%s: WAV estéreo de 44,1 kHz" % nome)
		if st is AudioStreamWAV:
			var w := st as AudioStreamWAV
			check(absf(w.get_length() - float(ARQUIVOS[nome])) < 1.5, "%s: duração %.1f s (pedido %.0f s)" % [nome, w.get_length(), ARQUIVOS[nome]])
			var m := _medidas_arq("res://assets/audio/musica/%s.wav" % nome)
			check(absf(float(m["rms"]) + 18.0) < 1.5, "%s: RMS %.1f dBFS (alvo -18)" % [nome, m["rms"]])
			check(float(m["pico"]) <= -1.0, "%s: pico %.1f dBFS (<= -1, sem estourar)" % [nome, m["pico"]])
			if nome != "intro":
				check(float(m["razao"]) < 6.0, "%s: o loop emenda sem estalo (razão %.1f)" % [nome, m["razao"]])
	var cfg := JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/slots.json")) as Dictionary
	var com_prompt := 0
	for s in cfg["slots"]:
		if String(s["id"]).begins_with("musica/") and String(s.get("prompt", "")) != "" and int(s.get("seg", 0)) > 0:
			com_prompt += 1
	check(com_prompt == 4, "os 4 slots de música têm prompt e duração (seg) no slots.json (%d)" % com_prompt)

	print("== (B) o jogo usa os arquivos")
	var jogo = audio._music_player.stream
	var perigo = audio._danger_player.stream
	check(jogo is AudioStreamWAV and absf((jogo as AudioStreamWAV).get_length() - 117.0) < 1.5, "a música do jogo vem do slot musica/jogo (não é o loop antigo de 27 s)")
	check(perigo is AudioStreamWAV and absf((perigo as AudioStreamWAV).get_length() - 57.0) < 1.5, "a música de perigo vem do slot musica/perigo (não é a antiga de 19 s)")
	check(jogo != audio.music and perigo != null, "não toca mais o stream antigo do Audio.music")
	check((jogo as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD and (perigo as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "os dois loops repetem")
	var mina = audio._amb["mina"].stream
	check(mina != null and mina != audio.ambience, "a ambiência da mina vem do arquivo novo (antes ficava o som antigo da caverna)")
	check(audio._music_player.playing, "a música do jogo está tocando")
	audio.tema("abertura")
	check(audio.tema_atual() == "abertura" and audio._tema_player.stream != null and absf((audio._tema_player.stream as AudioStreamWAV).get_length() - 72.0) < 1.5, "tema('abertura') toca a música da abertura")
	check((audio._tema_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "a abertura repete")
	audio.tema("intro")
	check(audio.tema_atual() == "intro" and (audio._tema_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "a intro toca uma vez só (não repete)")
	audio.tema("")
	check(audio.tema_atual() == "", "tema('') volta pra música do jogo")
	audio.set_danger(true)
	check(audio.is_danger(), "o perigo troca a música sem erro")
	audio.set_danger(false)
	await _frames(3)

	print("== (C) sem os arquivos: volta o som de antes")
	Slots.ignora_arquivos = true
	Slots.limpa_cache()
	check(not Slots.tem("musica/jogo"), "ignorando os arquivos, o slot não tem som")
	check(audio._slot_stream("musica/jogo") == audio.music, "a reserva da música do jogo é o loop antigo (Audio.music)")
	check(audio._slot_stream("musica/perigo") != null, "a reserva da música de perigo é a antiga")
	audio.tema("abertura")
	check(audio.tema_atual() == "", "sem arquivo, a abertura não toca (nada muda)")
	Slots.ignora_arquivos = false
	Slots.limpa_cache()

	print("== (D) a ferramenta")
	var raiz := ProjectSettings.globalize_path("res://").path_join("../")
	check(FileAccess.file_exists(raiz.path_join("tools/elevenlabs/gerar_musica.py")), "tools/elevenlabs/gerar_musica.py existe")
	check(FileAccess.file_exists(raiz.path_join("project.godot/data/audio/musicas.json")), "musicas.json (o que foi gerado) existe")
	var reg := JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/musicas.json")) as Dictionary
	check((reg["arquivos"] as Dictionary).size() == 4, "musicas.json registra as 4 músicas")
	var saida: Array = []
	var cod := OS.execute("python", [raiz.path_join("tools/elevenlabs/gerar_musica.py"), "--lista"], saida, true)
	if cod == -1:
		print("    (python não encontrado: a ferramenta não rodou)")
	else:
		var txt := String(saida[0]) if saida.size() > 0 else ""
		check(cod == 0 and txt.count("TEM arquivo") == 4, "gerar_musica.py --lista: as 4 têm arquivo (código %d) %s" % [cod, txt.left(300)])
		saida = []
		cod = OS.execute("python", [raiz.path_join("tools/elevenlabs/gerar_musica.py"), "--tudo", "--dry-run"], saida, true)
		txt = String(saida[0]) if saida.size() > 0 else ""
		check(cod == 0 and txt.contains("0 arquivo(s) no plano"), "pedir de novo não gasta nada: 0 arquivos no plano (já gerados)")

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


## Pico e RMS (dBFS) e a razão do estalo do loop, lidos do ARQUIVO .wav (16 bits) — o stream importado é QOA (comprimido), então os bytes dele não são amostras.
## Olha 1 amostra em cada 8 (rápido).
func _medidas_arq(caminho: String) -> Dictionary:
	var b := FileAccess.get_file_as_bytes(caminho)
	var canais := b.decode_u16(22)
	var pos := 12
	var ini := -1
	var tam := 0
	while pos + 8 <= b.size():
		var tag := b.slice(pos, pos + 4).get_string_from_ascii()
		var t := b.decode_u32(pos + 4)
		if tag == "data":
			ini = pos + 8
			tam = mini(t, b.size() - ini)
			break
		pos += 8 + t + (t & 1)
	if ini < 0:
		return {"pico": -99.0, "rms": -99.0, "razao": 99.0}
	var n := tam / (2 * canais)
	var pico := 1
	var soma := 0.0
	var k := 0
	var i := 0
	while i < n:
		var v := b.decode_s16(ini + i * 2 * canais)
		var a := absi(v)
		if a > pico:
			pico = a
		soma += float(v) * float(v)
		k += 1
		i += 8
	var rms := sqrt(soma / float(maxi(k, 1)))
	var salto := absf(float(b.decode_s16(ini)) - float(b.decode_s16(ini + (n - 1) * 2 * canais)))
	var tip := 0.0
	var m := mini(n - 1, 40000)
	for j in m:
		tip += absf(float(b.decode_s16(ini + (j + 1) * 2 * canais)) - float(b.decode_s16(ini + j * 2 * canais)))
	tip /= float(maxi(m, 1))
	return {"pico": 20.0 * log(maxf(float(pico), 1.0) / 32768.0) / log(10.0), "rms": 20.0 * log(maxf(rms, 1.0) / 32768.0) / log(10.0), "razao": salto / maxf(tip, 1.0)}
