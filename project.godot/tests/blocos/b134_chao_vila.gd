extends SceneTree
## Bloco 134: o CHÃO DA VILA com a arte do PixelLab. RODAR SÓ COM APPDATA ISOLADO.
##   (A) a arte (atlas 16 máscaras x 4 linhas, detalhes, cartões); (B) a terra batida na área da vila e o mato fora, pelos
##   vértices, com a transição pelos cantos; (C) a praça de pedra do Centro e a terra pisada em volta dos prédios; (D) os
##   detalhes soltos (só em célula inteira de terra/mato); (E) refeito só quando a vila muda e só as peças (a ordem fica);
##   (F) a terra cresce com o estágio; (G) a grade de construção é só de linhas; (H) os shaders desviram o UV do QuadMesh.
var fails := 0
var main: Node
const Grade := preload("res://scripts/core/grade.gd")


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


## A peça desenhada na célula c: [máscara, linha], pelo buffer do chão.
func _peca(ch: Node, c: Vector2i) -> Array:
	for k in ch._ordem.size():
		if ch._ordem[k][1] == c:
			return [int(ch._buf[k * 12 + 8]), int(ch._buf[k * 12 + 9])]
	return [-1, -1]


func _roda() -> void:
	await _frames(10)
	var iso := g("iso_view")
	var env := g("environment")
	var hub := g("village_hub")
	var ch: Node = iso.chao_vila() if iso and iso.has_method("chao_vila") else null
	check(ch != null, "a vista tem o chão da vila")
	if ch == null:
		print("FALHAS: %d" % fails)
		quit()
		return

	print("== (A) a arte")
	var d: Dictionary = ch.dados()
	var tex: Texture2D = load(ch.ATLAS)
	check(tex != null and tex.get_width() == 64 * 16 and tex.get_height() == 32 * 4, "o atlas: 16 peças (máscaras) x 4 linhas de 64x32")
	check(d.get("linhas", []) == ["mato", "terra", "cascalho", "pedra"], "linhas: mato da vila, terra, cascalho e pedra")
	check((d.detalhes.terra as Array).size() >= 6 and (d.detalhes.mato as Array).size() >= 6, "detalhes soltos de terra e de mato (%d / %d)" % [d.detalhes.terra.size(), d.detalhes.mato.size()])
	var cart_ok := true
	for t in ["terra", "cascalho", "pedra"]:
		var c: Texture2D = load("res://assets/game/ui/icones/cartoes/cam_%s.png" % t)
		cart_ok = cart_ok and c != null and c.get_width() == 96
	check(cart_ok, "os cartões do CONSTRUIR dos caminhos com a mesma arte")

	print("== (B) terra na vila, mato fora, transição pelos cantos")
	var reg: Rect2 = ch.regiao(env)
	check(reg.position.x == float(env.areas["vila"][0]) and reg.end.x == float(env.areas["vila"][1]), "cobre a faixa da vila, da paliçada até a mina (%s)" % str(reg))
	check(ch.celulas == Grade.celulas(reg).get_area(), "uma célula desenhada por célula da faixa (%d)" % ch.celulas)
	var area: Rect2 = env.area_vila()
	var meio: Array = _peca(ch, Grade.celula(area.get_center() + Vector2(0, area.size.y * 0.3)))
	check(meio[0] == 15 or meio[1] == 3, "no meio da área da vila: terra inteira (ou a praça) %s" % str(meio))
	var longe: Array = _peca(ch, Grade.celula(Vector2(reg.position.x + 30, reg.position.y + 30)))
	check(longe[0] == 0 and longe[1] == 0, "longe da vila, no canto da faixa: mato inteiro %s" % str(longe))
	var transicoes := 0
	for k in ch._ordem.size():
		var m := int(ch._buf[k * 12 + 8])
		if int(ch._buf[k * 12 + 9]) == 0 and m != 0 and m != 15:
			transicoes += 1
	check(transicoes > 20, "a fronteira terra/mato usa as peças de transição (%d células)" % transicoes)
	# a borda não é um retângulo: a terra passa do retângulo em algum ponto e falta em outro
	var fora := 0
	var falta := 0
	var cs := Grade.celulas(reg)
	for k in ch._ordem.size():
		var c: Vector2i = ch._ordem[k][1]
		var p := Grade.centro(c)
		var m := int(ch._buf[k * 12 + 8])
		if int(ch._buf[k * 12 + 9]) != 0 or p.x > reg.end.x - ch.faixa_mina * 1.5:
			continue
		if m == 15 and not area.grow(Grade.CELULA * 3).has_point(p):
			fora += 1
		if m == 0 and area.grow(-Grade.CELULA * 2).has_point(p):
			falta += 1
	check(fora > 0 or falta > 0, "a borda da terra é irregular (não segue o retângulo: %d além, %d aquém)" % [fora, falta])

	print("== (C) a praça do Centro e a terra em volta dos prédios")
	var pracas := 0
	for k in ch._ordem.size():
		if int(ch._buf[k * 12 + 9]) == 3:
			pracas += 1
	check(pracas > 20, "um largo de pedra em volta do Centro (%d células)" % pracas)
	var enf := g("enfermarias") as Node2D
	if enf:
		var IsoArt: GDScript = load("res://scripts/iso/iso_art.gd")
		var b: Rect2 = IsoArt.base_rect(enf)
		var cf := Grade.celulas(b)
		var embaixo: Array = _peca(ch, Vector2i(cf.position.x + 1, cf.end.y))
		check(embaixo[0] == 15 or embaixo[1] == 3, "na frente da Enfermaria o chão é terra pisada %s" % str(embaixo))

	print("== (D) os detalhes soltos")
	check(ch.detalhes > 100 and ch.detalhes < ch.celulas / 2, "detalhes sorteados (%d em %d células)" % [ch.detalhes, ch.celulas])

	print("== (E) refeito só quando a vila muda")
	var r0: int = ch.refeitos
	await _frames(70)
	check(ch.refeitos == r0, "parado, não refaz (%d)" % ch.refeitos)
	var ordem0: Array = ch._ordem
	var t0 := Time.get_ticks_usec()
	ch.refaz(env)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	check(ch._ordem == ordem0, "refazer reaproveita a ordem e as posições (só troca as peças)")
	check(ms < 40.0, "refazer custa pouco (%.1f ms)" % ms)

	print("== (F) a terra cresce com o estágio")
	var terra1 := 0
	for k in ch._ordem.size():
		if int(ch._buf[k * 12 + 8]) == 15 and int(ch._buf[k * 12 + 9]) == 0:
			terra1 += 1
	hub.level = 5
	await _frames(35)
	var terra5 := 0
	for k in ch._ordem.size():
		if int(ch._buf[k * 12 + 8]) == 15 and int(ch._buf[k * 12 + 9]) == 0:
			terra5 += 1
	check(ch.refeitos > r0 + 1 and terra5 > terra1, "no estágio 5 a terra ocupa mais células (%d -> %d)" % [terra1, terra5])
	hub.level = 1

	print("== (G) a grade de construção só de linhas")
	var fonte: String = (load("res://scripts/iso/iso_grade.gd") as GDScript).source_code
	var corpo := fonte.substr(fonte.find("func _desenha_base"), fonte.find("func _desenha_fantasma") - fonte.find("func _desenha_base"))
	check(corpo.contains("draw_multiline") and not corpo.contains("_tris(") and not fonte.contains("const COR_PORTA :="), "a camada da grade desenha só linhas (sem mancha de cor)")

	print("== (H) os shaders desviram o UV do QuadMesh")
	var f1: String = (load("res://scripts/iso/iso_chao_vila.gd") as GDScript).source_code
	var f2: String = (load("res://scripts/iso/iso_pisos.gd") as GDScript).source_code
	check(f1.contains("1.0 - UV.y") and f2.contains("1.0 - UV.y"), "chão e caminhos: a textura não sai de cabeça pra baixo (borda reta, sem dente de serra)")

	print("FALHAS: %d" % fails)
	quit()
