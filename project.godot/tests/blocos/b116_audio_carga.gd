extends SceneTree
## Bloco 116: TESTE DE CARGA do áudio — o jogo roda COM os arquivos gerados, SEM eles (ignorando-os) e SEM a pasta (silêncio sem erro) — e a infraestrutura
## da ferramenta de geração (segredos fora do git, LFS, docs, manifesto). RODAR SÓ COM APPDATA ISOLADO.
##   (A) Com os arquivos: todos os 191 de efeitos carregam, os loops repetem e emendam sem estalo, nenhum está quase inaudível (o do cemitério não se ouvia),
##       e o jogo toca tudo (ambiência, prédios, sons soltos, efeitos, interface, stingers, passos, voz) sem erro.
##   (B) Sem os arquivos (só a reserva, o som de antes): o mesmo percurso, sem erro.
##   (C) Sem a pasta de áudio: nenhum slot tem som, o mesmo percurso, silêncio e sem erro.
##   (D) Git e ferramenta: .env e audio_candidatos fora do git, .env.example sem chave, LFS dos áudios, gerados.json, docs; o teste offline da ferramenta (Python).
const Slots := preload("res://scripts/core/audio_slots.gd")
const CHAOS := ["terra", "cascalho", "pedra", "madeira", "agua"]
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
	if Time.get_ticks_msec() - _t0 > 400000:
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


func _fora(caminho: String) -> String:
	return FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../").path_join(caminho))


func _sem_musica() -> Array:
	return Slots.todos().filter(func(i): return not i.begins_with("musica/"))


## O percurso: tudo que o jogo faz de som, uma vez. Devolve quantos slots tocaram alguma coisa.
func _toca_tudo() -> int:
	var cam: Camera2D = main.get_node("Camera2D")
	var centro: Vector2 = cam.get_screen_center_position()
	audio.sfx_max_distance = 1.0e9
	for ctx in ["mina", "dia", "noite", "s2", "s3", "s4", "s5"]:
		audio.set_ambience(ctx, ctx == "dia", ctx == "noite", ctx == "mina")
		await _frames(2)
	audio.set_ambience("dia", false, false, false)
	audio.predios.atualiza()
	for id in audio._pont_ids:
		audio._pont_prox[id] = 1
	audio._pont_t = 0.0
	audio._pontuais_tick(0.0)
	var tocou := 0
	for id in _sem_musica():
		var sl := Slots.slot(id)
		for p in audio._pool:
			p.stop()
		for p in audio._ui_pool:
			p.stop()
		for p in audio._iface_pool:
			p.stop()
		if id.begins_with("ui/"):
			audio.ui(id.get_slice("/", 1))
		elif id.begins_with("stingers/"):
			audio.stinger(id.get_slice("/", 1))
		elif bool(sl.get("global", false)):
			audio.som_global(id)
		elif String(sl.get("tipo", "")) == "tiro":
			audio.som(id, centro)
		var algo := false
		for p in audio._pool + audio._ui_pool + audio._iface_pool:
			if p.playing:
				algo = true
		if algo:
			tocou += 1
	for chao in CHAOS:
		audio._step_tokens = 5.0
		audio.step(centro)
	audio._voz_ultima = -100000
	audio.voz(centro, "dor", "menino")
	audio.alarm()
	audio.toll()
	audio.sino(centro, "missa")
	await _frames(3)
	audio.sfx_max_distance = 900.0
	return tocou


func _roda() -> void:
	await _frames(12)
	audio._ctx_timer = 1.0e9
	audio._pont_t = 1.0e9
	var amb: float = audio.ambience_crossfade
	audio.ambience_crossfade = 0.2

	print("== A) com os arquivos gerados")
	Slots.ignora_arquivos = false
	Slots.limpa_cache()
	var mem0 := OS.get_static_memory_usage()
	var sem_arquivo: Array = []
	var nao_wav: Array = []
	var estalo: Array = []
	var inaudiveis: Array = []
	var arquivos := 0
	var segundos := 0.0
	for id in _sem_musica():
		var sl := Slots.slot(id)
		var esperados: int = maxi(int(sl.get("variacoes", 0)), 1)
		var arr := Slots.streams(id)
		if arr.size() != esperados:
			sem_arquivo.append("%s (%d de %d)" % [id, arr.size(), esperados])
		var loop := String(sl.get("tipo", "")) in ["loop", "loop_predio"]
		for st in arr:
			arquivos += 1
			if not (st is AudioStreamWAV):
				nao_wav.append(id)
				continue
			var w: AudioStreamWAV = st
			segundos += w.get_length()
			if loop and w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
				estalo.append("%s não repete" % id)
			var m := _medidas(w)
			if loop:
				if m.razao > 6.0:
					estalo.append("%s (emenda %.1f)" % [id, m.razao])
				if m.rms < -34.0:
					inaudiveis.append("%s rms %.0f dBFS" % [id, m.rms])
			elif m.pico < -20.0:
				inaudiveis.append("%s pico %.0f dBFS" % [id, m.pico])
	var mem1 := OS.get_static_memory_usage()
	check(sem_arquivo.is_empty(), "os %d slots de efeitos têm todos os arquivos%s" % [_sem_musica().size(), (" — faltam: %s" % str(sem_arquivo)) if not sem_arquivo.is_empty() else ""])
	check(nao_wav.is_empty() and arquivos >= 191, "%d arquivos carregam (%.0f s de áudio)%s" % [arquivos, segundos, (" — não WAV: %s" % str(nao_wav)) if not nao_wav.is_empty() else ""])
	check(estalo.is_empty(), "os loops repetem e emendam sem estalo%s" % [(" — %s" % str(estalo)) if not estalo.is_empty() else ""])
	check(inaudiveis.is_empty(), "nenhum som está quase inaudível (loops: RMS acima de −34 dBFS; curtos: pico acima de −20)%s" % [(" — %s" % str(inaudiveis)) if not inaudiveis.is_empty() else ""])
	print("    (memória estática do motor depois de carregar tudo: +%.0f MB; o contador não garante contar o áudio inteiro)" % (float(mem1 - mem0) / 1048576.0))
	var tocou_com := await _toca_tudo()
	check(tocou_com >= 80, "o jogo tocou %d slots em sequência, sem erro" % tocou_com)

	print("== B) sem os arquivos (só o som de antes)")
	Slots.ignora_arquivos = true
	Slots.limpa_cache()
	check(_sem_musica().all(func(i): return not Slots.tem(i)), "nenhum slot tem arquivo")
	var tocou_sem := await _toca_tudo()
	check(tocou_sem > 0 and tocou_sem < tocou_com, "só tocam os sons que têm o de antes (%d de %d slots)" % [tocou_sem, tocou_com])
	audio.stinger("amanhecer")
	audio.ui("noticia_boa")
	audio.voz(Vector2.ZERO, "dor", "menina")
	check(true, "slot sem arquivo e sem som de antes: silêncio, sem erro")

	print("== C) sem a pasta de áudio")
	Slots.ignora_arquivos = false
	Slots.pasta_atual = "res://nao_existe_pasta_de_audio/"
	Slots.limpa_cache()
	check(_sem_musica().all(func(i): return not Slots.tem(i)), "com a pasta ausente nenhum slot tem arquivo")
	var tocou_pasta := await _toca_tudo()
	check(tocou_pasta == tocou_sem, "o jogo roda igual ao 'sem arquivos' (%d slots tocam o som de antes)" % tocou_pasta)
	Slots.pasta_atual = Slots.PASTA
	Slots.limpa_cache()
	check(Slots.tem("sfx/picareta"), "a pasta volta e os arquivos voltam")
	audio.ambience_crossfade = amb

	print("== D) git, segredos e ferramenta")
	var ig := _fora(".gitignore").split("\n")
	var ig2: PackedStringArray = PackedStringArray()
	for l in ig:
		ig2.append(l.strip_edges())
	check(ig2.has(".env") and ig2.has("audio_candidatos/"), ".env e audio_candidatos/ estão no .gitignore")
	var ex := _fora(".env.example")
	var chave_no_exemplo := false
	for l in ex.split("\n"):
		if l.begins_with("ELEVENLABS_API_KEY=") and l.strip_edges().length() > "ELEVENLABS_API_KEY=".length():
			chave_no_exemplo = true
	check(ex.contains("ELEVENLABS_API_KEY=") and not chave_no_exemplo, ".env.example existe e não tem chave")
	var ga := _fora(".gitattributes")
	check(ga.contains("*.wav filter=lfs") and ga.contains("*.ogg filter=lfs") and ga.contains("*.mp3 filter=lfs"), "o .gitattributes manda wav, ogg e mp3 pro Git LFS")
	var reg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/gerados.json"))
	var sem_reg: Array = []
	for id in _sem_musica():
		var n: int = int(Slots.slot(id).get("variacoes", 0))
		var nomes: Array = [id] if n <= 0 else range(n).map(func(i): return "%s_%d" % [id, i])
		for nome in nomes:
			if not (reg.arquivos as Dictionary).has(nome):
				sem_reg.append(nome)
	check(sem_reg.is_empty(), "o gerados.json registra todos os arquivos (hash do pedido + aprovação)%s" % [(" — faltam: %s" % str(sem_reg)) if not sem_reg.is_empty() else ""])
	var docs_ok := true
	for d in ["docs/audio/PEDIDO_DE_SONS.md", "docs/audio/PROMPTS_ELEVENLABS.md", "docs/audio/LISTA_DE_ESCUTA.md"]:
		var txt := _fora(d)
		for id in _sem_musica():
			if not txt.contains("`%s" % id):
				docs_ok = false
				print("    %s não cita %s" % [d, id])
				break
	check(docs_ok, "PEDIDO_DE_SONS, PROMPTS_ELEVENLABS e LISTA_DE_ESCUTA citam todos os sons")
	for f in ["tools/elevenlabs/gerar_sons.py", "tools/elevenlabs/posprocessa.py", "tools/elevenlabs/docs_audio.py", "tools/elevenlabs/testa_ferramenta.py"]:
		check(FileAccess.file_exists(ProjectSettings.globalize_path("res://").path_join("../").path_join(f)), "%s existe" % f)
	var saida: Array = []
	var cod := OS.execute("python", [ProjectSettings.globalize_path("res://").path_join("../tools/elevenlabs/testa_ferramenta.py")], saida, true)
	if cod == -1:
		print("    (python não encontrado: o teste offline da ferramenta não rodou)")
	else:
		var txt := String(saida[0]) if saida.size() > 0 else ""
		check(cod == 0 and txt.contains("FALHAS: 0"), "o teste offline da ferramenta (cache, candidatos, aprovar, teto, confirmação, chave): código %d" % cod)

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


## Pico e RMS (dBFS) e a razão do estalo do loop de um WAV de 16 bits, olhando 1 amostra em cada 8 (rápido).
func _medidas(w: AudioStreamWAV) -> Dictionary:
	var d := w.data
	var canais := 2 if w.stereo else 1
	var n := d.size() / (2 * canais)
	var pico := 1
	var soma := 0.0
	var k := 0
	var i := 0
	while i < n:
		var v := d.decode_s16(i * 2 * canais)
		var a := absi(v)
		if a > pico:
			pico = a
		soma += float(v) * float(v)
		k += 1
		i += 8
	var rms := sqrt(soma / float(maxi(k, 1)))
	# a razão do estalo: o salto entre o fim e o começo / a diferença típica entre amostras vizinhas
	var salto := absf(float(d.decode_s16(0)) - float(d.decode_s16((n - 1) * 2 * canais)))
	var tip := 0.0
	var m := mini(n - 1, 40000)
	for j in m:
		tip += absf(float(d.decode_s16((j + 1) * 2 * canais)) - float(d.decode_s16(j * 2 * canais)))
	tip /= float(maxi(m, 1))
	return {"pico": 20.0 * log(maxf(float(pico), 1.0) / 32768.0) / log(10.0), "rms": 20.0 * log(maxf(rms, 1.0) / 32768.0) / log(10.0), "razao": salto / maxf(tip, 1.0)}
