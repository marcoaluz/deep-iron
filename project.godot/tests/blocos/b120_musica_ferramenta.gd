extends SceneTree
## Bloco 120: a MÚSICA EM CAMADAS gerada pela Eleven Music (Prompt 7, parte da ferramenta): o manifesto data/audio/musica.json (tema do menu, vitória, derrota e,
## por estação, dia/noite/perigo, todas no MESMO BPM e no MESMO tom), as 15 faixas em assets/audio/musica/, a ferramenta tools/elevenlabs/gerar_musica.py (--confere, --lista,
## --dry-run, limites de crédito) e o veredito de sincronia (docs/audio/SINCRONIA_MUSICA.md). RODAR SÓ COM APPDATA ISOLADO.
const ESTACOES := ["primavera", "verao", "outono", "inverno"]
const PERIODOS := ["dia", "noite", "perigo"]
var fails := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func _roda() -> void:
	var m := JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/musica.json")) as Dictionary
	var faixas: Array = m["faixas"]
	print("== (A) o manifesto")
	check(faixas.size() == 15, "15 faixas: 12 de estação (4 x dia/noite/perigo) + menu, vitória e derrota (%d)" % faixas.size())
	var por_id := {}
	for f in faixas:
		por_id[f["id"]] = f
	var sem := []
	for e in ESTACOES:
		for p in PERIODOS:
			if not por_id.has("musica/%s_%s" % [e, p]):
				sem.append("%s_%s" % [e, p])
	check(sem.is_empty() and por_id.has("musica/tema_menu") and por_id.has("musica/tema_vitoria") and por_id.has("musica/tema_derrota"), "todas as faixas pedidas estão no manifesto")
	var bpms := {}
	var tons := {}
	var segs := {}
	var instrumental := true
	var tudo_prompt := true
	for f in faixas:
		if String(f.get("tipo", "")) == "camada":
			bpms[f["bpm"]] = true
			tons[f["tom"]] = true
			segs[f["seg"]] = true
		if not String(f["prompt"]).to_lower().contains("no vocals"):
			instrumental = false
		if not (String(f["prompt"]).contains("%d BPM" % int(f["bpm"])) and String(f["prompt"]).contains(String(f["tom"]))):
			tudo_prompt = false
	check(bpms.size() == 1 and tons.size() == 1 and segs.size() == 1, "as 12 camadas têm o MESMO BPM, o MESMO tom e a mesma duração (%s BPM, %s, %s s)" % [str(bpms.keys()), str(tons.keys()), str(segs.keys())])
	check(instrumental, "todo prompt pede instrumental (sem vocais)")
	check(tudo_prompt, "todo prompt traz o BPM e o tom do manifesto")
	var compassos_ok := true
	for f in faixas:
		if absf(float(f["bpm"]) * float(f["seg"]) / 60.0 / 4.0 - float(f["compassos"])) > 0.01:
			compassos_ok = false
	check(compassos_ok, "os compassos fecham com a duração (a faixa repete na batida)")
	var papeis := {}
	for e in ESTACOES:
		papeis[String(por_id["musica/%s_dia" % e]["papel"])] = true
		papeis[String(por_id["musica/%s_noite" % e]["papel"])] = true
		papeis[String(por_id["musica/%s_perigo" % e]["papel"])] = true
	check(papeis.has("melodia") and papeis.has("pad") and papeis.has("percussao") and papeis.size() == 3, "dia = melodia, noite = pad, perigo = percussão")
	var noite := String(por_id["musica/inverno_noite"]["prompt"]).to_lower()
	check(noite.contains("no melody") and noite.contains("no drums"), "o pad da noite pede drones sem melodia e sem bateria (mais drone, menos melodia)")

	print("== (B) os arquivos (lidos do .wav: o stream importado é QOA)")
	for f in faixas:
		var id := String(f["id"])
		var caminho := "res://assets/audio/%s.wav" % id
		if not FileAccess.file_exists(caminho):
			check(false, "%s existe" % id)
			continue
		var med := _medidas_arq(caminho)
		var seg_esperado := float(f["seg"]) - (3.0 if bool(f["loop"]) else 0.0)
		var ok_seg := absf(float(med["seg"]) - seg_esperado) < 0.5 or not bool(f["loop"])
		var ok_nivel := absf(float(med["rms"]) + 18.0) < 1.6 and float(med["pico"]) <= -1.0
		check(med["canais"] == 2 and med["taxa"] == 44100 and ok_seg and ok_nivel, "%s: estéreo 44,1 kHz, %.1f s, RMS %.1f, pico %.1f" % [id, med["seg"], med["rms"], med["pico"]])
		if bool(f["loop"]):
			check(float(med["razao"]) < 6.0, "%s: o loop emenda sem estalo (razão %.1f)" % [id, med["razao"]])
	for e in ESTACOES:  # as camadas de uma estação têm o MESMO tamanho (se alinham no AudioStreamSynchronized)
		var tam := {}
		for p in PERIODOS:
			tam[FileAccess.get_file_as_bytes("res://assets/audio/musica/%s_%s.wav" % [e, p]).size()] = true
		check(tam.size() == 1, "%s: as 3 camadas têm exatamente o mesmo tamanho de arquivo" % e)

	print("== (C) a ferramenta, o veredito e os documentos")
	var raiz := ProjectSettings.globalize_path("res://").path_join("../")
	check(FileAccess.file_exists(raiz.path_join("tools/elevenlabs/gerar_musica.py")), "tools/elevenlabs/gerar_musica.py existe")
	var fonte := FileAccess.get_file_as_string(raiz.path_join("tools/elevenlabs/gerar_musica.py"))
	for termo in ["/v1/music", "music_length_ms", "force_instrumental", "--dry-run", "--candidatos", "--max-creditos", "--confirma-acima", "--sincronia", "--confere"]:
		check(fonte.contains(termo), "a ferramenta usa/tem '%s'" % termo)
	check(not fonte.contains("composition_plan\":") and not fonte.contains("\"seed\""), "só parâmetros que existem na documentação (sem seed nem composition_plan no corpo)")
	var saida: Array = []
	var cod := OS.execute("python", [raiz.path_join("tools/elevenlabs/gerar_musica.py"), "--confere"], saida, true)
	if cod == -1:
		print("    (python não encontrado: --confere não rodou)")
	else:
		var txt := String(saida[0]) if saida.size() > 0 else ""
		check(cod == 0 and txt.contains("tudo certo"), "gerar_musica.py --confere: tudo certo (código %d)" % cod)
		saida = []
		cod = OS.execute("python", [raiz.path_join("tools/elevenlabs/gerar_musica.py"), "--tudo", "--dry-run"], saida, true)
		txt = String(saida[0]) if saida.size() > 0 else ""
		check(cod == 0 and txt.contains("0 arquivo(s) no plano") and txt.contains("0 chamada(s)"), "pedir tudo de novo não gasta nada (cache e arquivos)")
	var sinc := FileAccess.get_file_as_string(raiz.path_join("docs/audio/SINCRONIA_MUSICA.md"))
	var veredictos := 0
	for e in ESTACOES:
		if sinc.contains("### " + e):
			veredictos += 1
	check(veredictos == 4 and sinc.contains("Veredito"), "SINCRONIA_MUSICA.md tem a medição das 4 estações")
	var pedido := FileAccess.get_file_as_string(raiz.path_join("docs/audio/PEDIDO_DE_SONS.md"))
	check(pedido.contains("Música em camadas") and pedido.contains("eleven-music-model-specific-terms") and pedido.contains("Indie Game"), "PEDIDO_DE_SONS.md: as camadas, como gerar e a licença")
	check(pedido.contains("folk sombrio") and pedido.contains("mais drone, menos melodia"), "PEDIDO_DE_SONS.md: o estilo e o fundo da mina")
	var ctx := FileAccess.get_file_as_string(raiz.path_join("CONTEXTO.md"))
	check(ctx.contains("eleven-music-model-specific-terms"), "CONTEXTO.md registra o termo de licença que o Marco precisa conferir")

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


## Pico e RMS (dBFS), razão do estalo do loop, canais, taxa e duração, lidos do ARQUIVO .wav (16 bits), olhando 1 amostra em cada 16.
func _medidas_arq(caminho: String) -> Dictionary:
	var b := FileAccess.get_file_as_bytes(caminho)
	var canais := b.decode_u16(22)
	var taxa := b.decode_u32(24)
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
		return {"pico": -99.0, "rms": -99.0, "razao": 99.0, "canais": canais, "taxa": taxa, "seg": 0.0}
	var n := tam / (2 * canais)
	var pico := 1
	var soma := 0.0
	var k := 0
	var i := 0
	while i < n:
		for c in canais:  # (os dois canais: o RMS da ferramenta é dos dois juntos)
			var v := b.decode_s16(ini + (i * canais + c) * 2)
			var a := absi(v)
			if a > pico:
				pico = a
			soma += float(v) * float(v)
			k += 1
		i += 16
	var rms := sqrt(soma / float(maxi(k, 1)))
	var salto := absf(float(b.decode_s16(ini)) - float(b.decode_s16(ini + (n - 1) * 2 * canais)))
	var tip := 0.0
	var m := mini(n - 1, 40000)
	for j in m:
		tip += absf(float(b.decode_s16(ini + (j + 1) * 2 * canais)) - float(b.decode_s16(ini + j * 2 * canais)))
	tip /= float(maxi(m, 1))
	return {"pico": 20.0 * log(maxf(float(pico), 1.0) / 32768.0) / log(10.0), "rms": 20.0 * log(maxf(rms, 1.0) / 32768.0) / log(10.0),
		"razao": salto / maxf(tip, 1.0), "canais": canais, "taxa": taxa, "seg": float(n) / float(taxa)}
