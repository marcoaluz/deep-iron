extends SceneTree
## Bloco 75: a coluna da maquete aprovada (docs/arte/bloco72/maquete/coluna_v3.png) — os andares de baixo em
## FAIXAS largas e rasas ao longo da face sul, debaixo da floresta e da vila, empilhadas bem juntas (22
## degraus), com a faixa das galerias de madeira logo abaixo da superfície. Confere: o formato (faixa, área
## menor que o andar antigo), a ordem e o passo entre andares, as galerias entre a superfície e o S2, o
## chão de cada faixa aparecendo inteiro (o de cima não cobre o de baixo na tela), as gaiolas na vertical do
## poço, o conteúdo de cada andar dentro da faixa e da caverna, o caminho da gaiola até cada jazida, e o save
## de antes das faixas (o que estava no retângulo antigo vai pro mesmo lugar relativo na faixa).
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const ANTIGOS := {"nivel2": Rect2(-560, 700, 1120, 620), "abismo": Rect2(-480, 1420, 960, 560),
	"s4": Rect2(-440, 2120, 880, 520), "s5": Rect2(-400, 2760, 800, 480)}
var main: Node
var t := 0.0
var fails := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
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
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if t > 4.0:
		_formato()
		_galerias()
		_tela()
		_gaiolas()
		_conteudo()
		_caminhos()
		_save_antigo()
		print("FALHAS: %d" % fails)
		return true
	return false


func _rect(nome: String) -> Rect2:
	var a: Dictionary = g("environment").andares.andares[nome]
	return Rect2(a.rect[0], a.rect[1], a.rect[2], a.rect[3])


func _formato() -> void:
	print("== os andares em faixas")
	var env = g("environment")
	var nomes: Array = env.andares.andares.keys()
	check(nomes == ["nivel2", "abismo", "s4", "s5"], "os 4 andares de baixo (%s)" % [nomes])
	var zs := []
	for nome in nomes:
		var r := _rect(nome)
		check(r.size.x >= 4.0 * r.size.y, "%s é uma faixa: %d x %d (larga e rasa)" % [nome, r.size.x, r.size.y])
		check(r.get_area() < ANTIGOS[nome].get_area(), "%s menor em área que o andar antigo (%d%%)" % [nome, roundi(100.0 * r.get_area() / ANTIGOS[nome].get_area())])
		check(not r.intersects(ANTIGOS[nome].grow(10.0)) and not r.intersects(env.map_rect), "%s longe dos retângulos antigos e da superfície (na lógica)" % nome)
		zs.append(float(env.andares.andares[nome].z_chao))
	var passo_ok := true
	for i in range(1, zs.size()):
		passo_ok = passo_ok and is_equal_approx(zs[i - 1] - zs[i], 22.0 * 32.0)
	check(passo_ok, "empilhados bem juntos: 22 degraus entre um andar e o outro (%s)" % [zs])
	check(env.deep_rect == _rect("nivel2") and env.abyss_rect == _rect("abismo"), "deep_rect/abyss_rect = as faixas do S2 e do S3")


func _galerias() -> void:
	print("== as galerias de madeira")
	var env = g("environment")
	var iso = main.get_node("IsoView")
	var gal: Dictionary = env.andares.get("galerias", {})
	check(not gal.is_empty(), "a faixa das galerias no andares.json")
	if gal.is_empty():
		return
	var zg := float(gal.z_chao)
	check(zg < 0.0 and zg > float(env.andares.andares.nivel2.z_chao), "entre a superfície e o S2 (chão em %d)" % zg)
	var achou := false
	for c in iso._terrain_node.get_children():
		achou = achou or String(c.name) == "Galerias"
	check(achou, "desenhada na vista (na ordem como terreno)")


func _tela() -> void:
	print("== cada faixa aparece inteira")
	var env = g("environment")
	var iso = main.get_node("IsoView")
	var nomes: Array = env.andares.andares.keys()
	var cobre := []
	for i in range(1, nomes.size()):
		var de_cima := _rect(nomes[i - 1])
		var de_baixo := _rect(nomes[i])
		# o mesmo ponto relativo das duas faixas fica um embaixo do outro, a diferença de altura; numa
		# coluna da tela o chão ocupa a profundidade da faixa (px de arte) e a laje 3 degraus
		var a: Vector2 = iso.to_screen(de_cima.get_center())
		var b: Vector2 = iso.to_screen(de_baixo.get_center())
		var dz := b.y - a.y
		if absf(a.x - b.x) > 1.0 or dz <= de_baixo.size.y * env.iso_scale() + 96.0:
			cobre.append("%s (%.0f px)" % [nomes[i], dz])
	check(cobre.is_empty(), "o chão de cima não cobre o de baixo: as faixas uma embaixo da outra, com a parede de trás aparecendo %s" % [cobre])
	var elev_x: float = iso.to_screen(g("elevador").global_position).x
	var mata_x: float = iso.to_screen(Vector2(env.palisade_x - 200.0, 300)).x
	for nome in nomes:
		var c: float = iso.to_screen(_rect(nome).get_center()).x
		check(c < elev_x and c > mata_x - 900.0, "%s debaixo da floresta e da vila (centro %.0f; elevador %.0f)" % [nome, c, elev_x])


func _gaiolas() -> void:
	print("== as gaiolas no poço")
	var env = g("environment")
	var iso = main.get_node("IsoView")
	var topo: float = iso.to_screen(g("elevador").global_position).x
	var fins := [g("elevador").bottom_position]
	for grupo in ["elevador_abismo", "elevador_s4", "elevador_s5"]:
		var e = g(grupo)
		if e:
			fins.append(e.bottom_position)
	var ok := fins.size() == 4
	for k in fins.size():
		var nome: String = env.andares.andares.keys()[k]
		var gj: Array = env.andares.andares[nome].gaiola
		ok = ok and (fins[k] as Vector2).distance_to(Vector2(gj[0], gj[1])) < 1.0 and absf(iso.to_screen(fins[k]).x - topo) < 6.0
	check(ok, "a chegada de cada elevador é a gaiola da faixa, na vertical da torre da vila")


func _conteudo() -> void:
	print("== o conteúdo de cada andar na faixa")
	var env = g("environment")
	var fora := []
	var total := 0
	for grupo in ["minerios", "zonas_perigo", "pocas_perigo", "nivel_deco"]:
		for n in main.get_tree().get_nodes_in_group(grupo):
			var p: Vector2 = (n as Node2D).global_position
			for nome in ANTIGOS:
				if ANTIGOS[nome].grow(40.0).has_point(p):
					fora.append("%s (no andar antigo)" % n.name)
			if env.level_of(p).is_empty():
				continue
			total += 1
			if not env.dentro_da_caverna(p):
				fora.append(String(n.name))
	check(total > 40 and fora.is_empty(), "%d coisas dos andares, todas no chão da faixa (fora: %s)" % [total, fora])


func _caminhos() -> void:
	print("== caminhos dentro das faixas")
	var env = g("environment")
	var map: RID = main.get_world_2d().navigation_map
	var falta := []
	var n := 0
	for e in [g("elevador"), g("elevador_abismo"), g("elevador_s4"), g("elevador_s5")]:
		if e == null:
			continue
		var de: Vector2 = e.bottom_position
		var lv: Dictionary = env.level_of(de)
		for j in main.get_tree().get_nodes_in_group("minerios"):
			var p: Vector2 = (j as Node2D).global_position
			if env.level_of(p).get("nome", "") != lv.get("nome", "?"):
				continue
			n += 1
			var c := NavigationServer2D.map_get_path(map, de, p, true)
			if c.is_empty() or c[c.size() - 1].distance_to(p) > 45.0:
				falta.append(String(j.name))
	check(n >= 15 and falta.is_empty(), "da gaiola até cada uma das %d jazidas do andar (sem caminho: %s)" % [n, falta])


func _save_antigo() -> void:
	print("== save de antes das faixas")
	var env = g("environment")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	var velho := Vector2(100, 1000)  # o meio do nível 2 antigo
	w.global_position = velho
	env.migrated.clear()
	env.migrate_positions()
	var esperado: Vector2 = env.posicao_nova(velho)
	check(w.global_position.distance_to(esperado) < 1.0 and _rect("nivel2").has_point(w.global_position),
		"quem estava no nível 2 antigo vai pro mesmo lugar relativo na faixa (%s -> %s)" % [velho, w.global_position.round()])
	check(env.migrated.any(func(m): return m.nome == String(w.name)), "fica anotado em migrated")
	check(env.posicao_nova(Vector2(40, -190)) == Vector2(40, -190), "a superfície não muda")
