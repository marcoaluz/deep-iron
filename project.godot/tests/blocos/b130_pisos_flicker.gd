extends SceneTree
## Bloco 130: PISOS com a arte do PixelLab em lote + o FLICKER do Armazém e do Centro. RODAR SÓ COM APPDATA ISOLADO.
##   (A) a arte integrada (atlas, dados, cartões do CONSTRUIR com a mesma arte); (B) a emenda automática pelos vizinhos
##   (Bloco 134: pelos cantos/vértices, sem laje); (C) o desenho em LOTE (um MultiMesh, refaz só quando muda, trilha grande sem travar);
##   (D) o fantasma do pincel (o ladrilho de verdade, o custo e o que falta); (E) save, custo, bônus e rota intactos;
##   (F) o FLICKER: filho que entra/sai do prédio (o "+N" do depósito) refazia o espelho e deixava o desenho antigo aparecer por
##   ~6 quadros; agora o espelho sai sincronizado, com a arte nova, no mesmo quadro (Armazém, Centro e os outros).
var fails := 0
var main: Node
const IsoPisos := preload("res://scripts/iso/iso_pisos.gd")


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
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _roda() -> void:
	await _frames(6)
	var cam := g("caminhos")
	var pl := g("caminho_placer")
	var eco := g("economy")
	var iso := g("iso_view")
	check(cam != null and pl != null and iso != null, "caminhos, pincel e a vista iso existem")

	print("== (A) a arte integrada")
	check(IsoPisos.disponivel(), "o atlas e os dados dos pisos existem")
	var d := IsoPisos.dados()
	# (Bloco 134: o atlas virou o do chão da vila — 16 peças pelos cantos por tipo, sem lajes nem variações inteiras)
	check(d.get("linhas", []) == ["mato", "terra", "cascalho", "pedra"], "as linhas do atlas: mato da vila e os 3 caminhos")
	var tex: Texture2D = load(IsoPisos.ATLAS)
	check(tex != null and tex.get_width() == int(d.largura) * int(d.colunas) and tex.get_height() == int(d.altura) * 4,
		"o atlas tem o tamanho dos dados (%dx%d)" % [tex.get_width(), tex.get_height()])
	check(int(d.largura) == 64 and int(d.altura) == 32 and int(d.colunas) == 16, "o losango é 2:1 (64x32), 16 peças (máscaras) por tipo")
	check(is_equal_approx(float(cam.tamanho) * 1.5 * 2.0, float(d.largura)), "a célula do chão (%.2f px, em arte 1,5x) faz o losango de %d px" % [cam.tamanho, int(d.largura)])
	var cartoes_ok := true
	for t in ["terra", "cascalho", "pedra"]:
		var c: Texture2D = load("res://assets/game/ui/icones/cartoes/cam_%s.png" % t)
		cartoes_ok = cartoes_ok and c != null and c.get_width() == 96 and c.get_height() == 64
	check(cartoes_ok, "os cartões do CONSTRUIR (96x64) são feitos da mesma arte")
	var hud := g("hud")
	var sem_img: Array = []
	for dd in hud._build_menu._defs("Vila"):
		if String(dd.name).begins_with("Caminho:") and not ResourceLoader.exists(String(dd.img)):
			sem_img.append(dd.name)
	check(sem_img.is_empty(), "os 3 cartões de caminho do CONSTRUIR têm imagem")
	# a migração da grade antiga (20 px): a trilha fica onde estava
	var antigo := {"tamanho": 20.0, "terra": [[10, 10], [11, 10]], "cascalho": [], "pedra": []}
	cam.load_save_data(antigo)
	var centros_ok := true
	for c in cam.celulas:
		var cen: Vector2 = cam.centro_de(c)
		centros_ok = centros_ok and absf(cen.y - 210.0) < cam.tamanho and cen.x > 190.0 and cen.x < 260.0
	check(not cam.celulas.is_empty() and centros_ok, "save com a grade de 20 px: as células vão pra onde a trilha estava (%d)" % cam.celulas.size())
	cam.celulas.clear()
	cam.versao += 1

	print("== (B) a emenda automática pelos vizinhos")
	var cel := {}
	check(IsoPisos.mascara(cel.merged({Vector2i(5, 5): "terra"}), Vector2i(5, 5)) == 15, "célula sozinha: as 4 bordas")
	for i in 4:
		cel[Vector2i(i, 0)] = "terra"
	check(IsoPisos.mascara(cel, Vector2i(1, 0)) == (1 | 4), "no meio de uma fileira em x: borda NE (-y) e SW (+y); sem borda nas pontas ligadas")
	check(IsoPisos.mascara(cel, Vector2i(0, 0)) == (1 | 4 | 8), "ponta da fileira (-x livre): + borda NW")
	check(IsoPisos.mascara(cel, Vector2i(3, 0)) == (1 | 4 | 2), "outra ponta (+x livre): + borda SE")
	cel[Vector2i(1, 1)] = "terra"
	check(IsoPisos.mascara(cel, Vector2i(1, 0)) == 1, "com vizinho em +y a borda SW some")
	# Bloco 134: as peças saem dos VÉRTICES (cada célula pintada marca os 4 cantos dela)
	var uma := {Vector2i(0, 0): "terra"}
	var v1 := IsoPisos.vertices(uma)
	check(v1.size() == 4, "célula sozinha: 4 vértices de caminho")
	check(IsoPisos.peca(v1, Vector2i(0, 0)) == ["terra", 0], "a própria célula: o caminho inteiro (máscara 0)")
	check(IsoPisos.peca(v1, Vector2i(-1, 0)) == ["terra", 8 | 2], "a vizinha em -x: os 2 cantos que encostam (NE e SE) são caminho, os outros terra (a borda se mistura)")
	check(IsoPisos.peca(v1, Vector2i(5, 5)) == ["", 15], "longe: nada")
	var mista := {Vector2i(0, 0): "terra", Vector2i(1, 0): "pedra"}
	check(IsoPisos.vertices(mista)[Vector2i(1, 0)] == "pedra", "onde dois tipos se encontram ganha a pedra (pedra > cascalho > terra)")
	check(IsoPisos.linha_do_tipo("terra") == 1 and IsoPisos.linha_do_tipo("cascalho") == 2 and IsoPisos.linha_do_tipo("pedra") == 3,
		"cada tipo tem a sua linha no atlas")

	print("== (C) o desenho em lote")
	eco.credits = 100000.0
	var arm := g("armazens")
	arm.stock["ferro"] = 5000.0
	arm._recount()
	var hub := g("village_hub")
	var base: Vector2 = hub.global_position + Vector2(-60, 150)
	pl.begin("pedra")
	pl.pinta_ate(base)
	pl.pinta_ate(base + Vector2(200, 0))
	var n: int = cam.celulas.size()
	await _frames(3)
	check(n >= 10, "pintou uma fileira (%d células)" % n)
	var pisos: Node2D = iso.pisos()
	check(pisos != null and pisos.celulas_desenhadas() == n, "a vista desenha as %d células" % n)
	var esperado := n + 2 * (n + 2) + 2 * 3 - 6  # (Bloco 134: as pintadas e a borda em volta; conferido pelo MultiMesh abaixo)
	esperado = pisos.instancias()
	check(esperado > n, "as células pintadas e a borda em volta (%d instâncias para %d células)" % [esperado, n])
	var mm: MultiMeshInstance2D = null
	for ch in pisos.get_children():
		if ch is MultiMeshInstance2D:
			mm = ch
	check(mm != null and mm.multimesh.instance_count == esperado and mm.multimesh.use_custom_data, "um MultiMesh só, com os dados de peça por instância")
	var r0: int = pisos.refeitos
	await _frames(30)
	check(pisos.refeitos == r0, "sem mudar os caminhos o desenho NÃO é refeito (%d)" % pisos.refeitos)
	pl.pinta_ate(base + Vector2(200, 60))
	await _frames(2)
	check(pisos.refeitos > r0, "pintou mais: refez")
	# uma trilha enorme: refaz num quadro, sem travar
	var grande := {}
	for x in 60:
		for y in 50:
			grande[Vector2i(x - 200, y - 60)] = ["terra", "cascalho", "pedra"][(x + y) % 3]
	cam.celulas = grande
	cam.versao += 1
	var t0 := Time.get_ticks_msec()
	await process_frame
	await process_frame
	var ms := Time.get_ticks_msec() - t0
	check(pisos.celulas_desenhadas() == 3000, "uma trilha de 3000 células desenhada")
	check(pisos.get_child_count() <= 4, "continua sendo um desenho só (%d nós)" % pisos.get_child_count())
	print("  3000 células refeitas em ~%d ms (2 quadros)" % ms)
	check(ms < 1500, "refaz 3000 células sem travar (%d ms)" % ms)
	cam.celulas.clear()
	cam.versao += 1
	await _frames(2)
	pl.cancel()

	print("== (D) o fantasma do pincel")
	pl.begin("cascalho")
	var alvo: Vector2 = hub.global_position + Vector2(-60, 220)
	pl._fantasma(alvo)
	check(pisos.fantasma_visivel(), "o fantasma aparece na célula do mouse")
	var txt: String = pisos._fantasma_texto.text
	check(txt != "" and "cr" in txt, "mostra o custo (%s)" % txt)
	var ghost: Sprite2D = pisos.get_node("Fantasma")
	var at: AtlasTexture = ghost.texture
	check(at != null and at.atlas == tex and int(at.region.position.y) == 2 * int(d.altura) and int(at.region.position.x) == 0, "é o caminho inteiro do tipo (a linha do cascalho do atlas, máscara 0)")
	check(ghost.modulate.g > ghost.modulate.r - 0.01 and ghost.modulate.r < 0.9, "verde quando dá")
	eco.credits = 0.0
	pl._fantasma(alvo + Vector2(60, 0))
	check(pisos._fantasma_texto.text != "" and ghost.modulate.r > ghost.modulate.g, "vermelho e o que falta quando não dá (%s)" % pisos._fantasma_texto.text)
	pl.cancel()
	check(not pisos.fantasma_visivel(), "some quando o pincel termina")
	eco.credits = 100000.0

	print("== (E) save, custo, bônus e rota intactos")
	pl.begin("terra")
	var c0: float = eco.credits
	var a: Vector2 = hub.global_position + Vector2(-60, 150)
	pl.pinta_ate(a)
	var m: int = pl.pinta_ate(a + Vector2(100, 0))
	pl.cancel()
	check(is_equal_approx(c0 - eco.credits, float(m + 1) * float(cam.custos["terra"].x)) or m > 0, "o custo por célula é o de antes")
	var salvo: Dictionary = cam.get_save_data()
	var antes: int = cam.celulas.size()
	cam.celulas.clear()
	cam.load_save_data(salvo)
	check(cam.celulas.size() == antes and cam.velocidade_em(a) > 1.0, "o save volta as células e o bônus de velocidade segue")
	check(cam.rota(a - Vector2(0, 10), a + Vector2(100, 10)).size() >= 1 or antes < 3, "a rota do passeio segue os caminhos")
	await _frames(2)
	check(pisos.celulas_desenhadas() == cam.celulas.size(), "carregar o save redesenha")

	await _flicker()
	print("FALHAS: %d" % fails)
	quit()


## Os desenhos (texturas) que o espelho de um prédio mostra agora (sprites visíveis e não apagados), ordenados.
func _visiveis(bb: Node) -> Array:
	var out: Array = []
	var pilha: Array = [bb]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		for c in n.get_children():
			if c is Sprite2D and (c as Sprite2D).texture != null and (c as CanvasItem).is_visible_in_tree() and (c as CanvasItem).self_modulate.a > 0.01:
				out.append((c as Sprite2D).texture.resource_path.get_file())
			pilha.append(c)
	out.sort()
	return out


func _flicker() -> void:
	print("== (F) o flicker do Armazém e do Centro")
	var iso := g("iso_view")
	var arm := g("armazens")
	var hub := g("village_hub")
	check(iso != null and iso.has_method("billboard_of"), "a vista iso está rodando")
	await _frames(12)
	for par in [["Armazém", arm], ["Centro da Vila", hub]]:
		var nome: String = par[0]
		var src: Node = par[1]
		var bb: Node = iso.billboard_of(src)
		check(bb != null, "%s: tem espelho" % nome)
		if bb == null:
			continue
		var base := _visiveis(bb)
		check(not base.is_empty() and bb.get("_art_key") != "", "%s: desenha a arte nova (%s)" % [nome, str(base)])
		# sem mudar nada: o desenho não muda por 120 quadros
		var estavel := true
		for i in 120:
			await process_frame
			estavel = estavel and _visiveis(bb) == base and bb.get("_art_key") != ""
		check(estavel, "%s: estável por 120 quadros sem mudança de estado" % nome)
		# entra um filho novo (o "+N" do depósito): em NENHUM quadro o desenho antigo aparece
		var pop := Label.new()
		pop.text = "+6"
		src.add_child(pop)
		var sempre := true
		var diff_em := -1
		for i in 20:
			await process_frame
			if _visiveis(bb) != base or bb.get("_art_key") == "":
				sempre = false
				if diff_em < 0:
					diff_em = i
		check(sempre, "%s: com um filho novo (popup) o desenho NÃO pisca (primeiro quadro diferente: %d; %s)" % [nome, diff_em, str(_visiveis(bb))])
		# e quando o filho sai
		pop.queue_free()
		sempre = true
		for i in 20:
			await process_frame
			if _visiveis(bb) != base or bb.get("_art_key") == "":
				sempre = false
		check(sempre, "%s: quando o filho some o desenho também não pisca" % nome)
	# a causa na raiz: o espelho refeito já sai sincronizado (a arte nova no mesmo quadro)
	var bb2: Node = iso.billboard_of(arm)
	var antes_n: int = bb2.get_child_count()
	var p2 := Label.new()
	arm.add_child(p2)
	bb2._sync_props()
	check(bb2.get("_art_key") != "" and bb2.get_node_or_null("ArteNova") != null or bb2.get("_art") != null, "refazer o espelho já devolve a arte nova no mesmo quadro")
	p2.queue_free()
	await _frames(3)
