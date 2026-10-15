extends SceneTree
## Bloco 138: PERFORMANCE DE ABERTURA, a trava do "pular" e o jogo que "fechava" ao construir. RODAR SÓ COM APPDATA ISOLADO.
##   (1) a seta do guia apontando um cartão do CONSTRUIR que a troca de aba solta não dá erro de script (no editor o erro
##       PARAVA o jogo no debugger: parecia que tinha fechado); o posicionador aceita textura nula; a criatura de folha com
##       um quadro só não pede o quadro 1;
##   (2) a 1ª malha de navegação vai pelo pedido agrupado (no jogo, fora do quadro) e fica em dia;
##   (3) o blocos.json bate com os PNGs do terreno (lista velha = blocos faltando no mapa) e a vista iso usa ele;
##   (4) o índice das pastas de som acha os mesmos arquivos que o ResourceLoader.exists;
##   (5) a partida carrega em SEGUNDO PLANO: o "pular" volta na hora, a tela de carregamento tem a barra, a cena troca
##       quando tudo chega e a tela some depois que a partida assenta.
var fails := 0
var main: Node


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
	await _frames(2)
	await _blocos_json()
	_sons()
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	await _frames(8)
	await _guia()
	await _posicionador()
	await _criatura()
	_terreno()
	await _navegacao()
	await _carregamento()
	print("FALHAS: %d" % fails)
	quit()


# ------------------------------------------------------------ (1) o guia, o posicionador e a criatura
func _guia() -> void:
	var guia = g("guia")
	var hud = g("hud")
	var menu = hud.get("_build_menu")
	check(guia != null and menu != null, "o guia e o CONSTRUIR existem")
	if guia == null or menu == null:
		return
	if not menu.visible:
		hud.toggle_build_menu()
	menu._show_tab(0)
	await process_frame
	guia.set("confere_cada", 999.0)  # (a conferência não refaz a lista antes do desenho)
	guia.visible = true
	var cartao: Control = menu._cards[0].panel
	guia.set("_alvos", [cartao, Vector2(10, 20)])
	menu._show_tab(1)  # solta o cartão
	await _frames(4)
	var soltos := 0
	for a in guia.alvos():
		if typeof(a) == TYPE_OBJECT and not is_instance_valid(a):
			soltos += 1
	check(not is_instance_valid(cartao), "a troca de aba soltou o cartão que a seta apontava")
	check(soltos == 0, "o desenho das setas tira o cartão solto da lista (sem 'is' em objeto liberado): %d solto(s)" % soltos)
	check(guia.alvos().has(Vector2(10, 20)), "o alvo no mapa (Vector2) continua")
	guia.set("confere_cada", 0.25)
	hud.toggle_build_menu()
	await process_frame


func _posicionador() -> void:
	var placer = g("house_placer")
	placer.begin(func(_p): return false, null, 0, "teste sem textura")
	check(placer.active, "o posicionador com textura nula começa (cai na textura da casa)")
	check(placer.get("_ghost").hframes >= 1, "hframes 0 vira 1")
	placer.cancel()
	placer.begin(Callable(), null, 1, "teste sem ação")
	check(not placer.active, "sem ação de confirmar, o posicionador nem começa")
	await process_frame


func _criatura() -> void:
	var rato: Node2D = load("res://scenes/creatures/rato.tscn").instantiate()
	main.get_node("World").add_child(rato)
	await process_frame
	var vis: Sprite2D = rato.get_node("Visual")
	if rato.get("visual_textura") != null:
		check(true, "o rato tem folha de animação (o caso de um quadro não se aplica)")
	else:
		rato.set("_anim", 0.15)  # (o quadro piscaria pro 1)
		rato._atualiza_visual()
		check(vis.frame < vis.hframes * vis.vframes, "a criatura de folha com %d quadro(s) não pede um quadro fora da folha" % (vis.hframes * vis.vframes))
	rato.queue_free()
	await process_frame


# ------------------------------------------------------------ (2) a navegação
func _navegacao() -> void:
	var env = g("environment")
	check(env.navigation_region != null and env.navigation_region.navigation_polygon.get_polygon_count() > 0,
		"a 1ª malha existe (headless: o pedido agrupado é síncrono)")
	check(env.navegacao_em_dia(), "a navegação está em dia")
	# o caminho do jogo: o pedido do _ready vai pro bake em segundo plano e a malha chega depois
	var Env = load("res://scripts/core/environment.gd")
	Env.bake_assincrono_forcado = true
	var b0: int = env.nav_bakes
	env.rebuild_navigation()
	env.rebuild_navigation()
	var n := 0
	while not env.navegacao_em_dia() and n < 600:
		await process_frame
		n += 1
	Env.bake_assincrono_forcado = false
	check(env.navegacao_em_dia() and env.nav_bakes == b0 + 1, "dois pedidos no mesmo quadro = um bake em segundo plano (%d quadros)" % n)
	check(env.navigation_region.navigation_polygon.get_polygon_count() > 0, "a malha nova chegou")


# ------------------------------------------------------------ (3) o terreno
func _blocos_json() -> void:
	var dir := "res://assets/game/iso/mapa/"
	var d = JSON.parse_string(FileAccess.get_file_as_string(dir + "blocos.json")) if FileAccess.file_exists(dir + "blocos.json") else null
	check(d is Dictionary and int(d.get("bloco", 0)) == 256, "o blocos.json existe (bloco de 256 px)")
	if not (d is Dictionary):
		return
	var imgs: Dictionary = d.get("imagens", {})
	var mapa = JSON.parse_string(FileAccess.get_file_as_string(dir + "mapa.json"))
	var faltam: Array = []
	for r in mapa.get("regioes", {}).values():
		if not imgs.has(String(r.img)):
			faltam.append(r.img)
	check(faltam.is_empty(), "toda região do mapa.json está no blocos.json %s" % str(faltam))
	var errados: Array = []
	for nome in imgs:
		var tex: Texture2D = load(dir + String(nome))
		if tex == null:
			errados.append("%s (sem textura)" % nome)
			continue
		var img := tex.get_image()
		var w := img.get_width()
		var h := img.get_height()
		var e: Array = imgs[nome]
		if int(e[0]) != w or int(e[1]) != h:
			errados.append("%s (tamanho)" % nome)
			continue
		var cols := ceili(w / 256.0)
		var usados: Array = []
		for y in range(0, h, 256):
			for x in range(0, w, 256):
				if img.get_region(Rect2i(x, y, mini(256, w - x), mini(256, h - y))).get_used_rect().size != Vector2i.ZERO:
					usados.append(floori(x / 256.0) + floori(y / 256.0) * cols)
		var lista: Array = []
		for i in e[2]:
			lista.append(int(i))
		if lista != usados:
			errados.append("%s (%d x %d blocos)" % [nome, lista.size(), usados.size()])
		await process_frame
	check(errados.is_empty(), "o blocos.json bate com os PNGs (rode prototipos/camera/arte_iso/mapa/blocos.py): %s" % str(errados))


func _terreno() -> void:
	var Iso = load("res://scripts/iso/iso_view.gd")
	var dir := "res://assets/game/iso/mapa/"
	var tex: Texture2D = load(dir + "terreno_fundo.png")
	var usados: Dictionary = Iso.blocos_guardados(tex.resource_path, tex.get_width(), tex.get_height())
	check(not usados.is_empty(), "a vista iso acha os blocos do terreno_fundo no blocos.json (%d)" % usados.size())
	check(Iso.blocos_guardados(tex.resource_path, tex.get_width() + 1, tex.get_height()).is_empty(), "de outro tamanho: lista vazia (lê a imagem, como antes)")
	var iso = g("iso_view")
	var blocados: Array = iso.get("_blocados") if iso else []
	var total := 0
	for e in blocados:
		total += e[1].size()
	check(total > 0, "o terreno da vista iso está em blocos (%d)" % total)


# ------------------------------------------------------------ (4) o som
func _sons() -> void:
	var Slots = load("res://scripts/core/audio_slots.gd")
	Slots.limpa_cache()
	Slots.carrega()
	var ids: Array = Slots._dados.keys()
	var diferentes: Array = []
	for id in ids:
		var velho: Array[String] = []
		var base: String = Slots.pasta_atual + String(id)
		for ext in Slots.EXTENSOES:
			if ResourceLoader.exists("%s.%s" % [base, ext]):
				velho.append("%s.%s" % [base, ext])
				break
		for i in Slots.MAX_VARIACOES:
			for ext in Slots.EXTENSOES:
				if ResourceLoader.exists("%s_%d.%s" % [base, i, ext]):
					velho.append("%s_%d.%s" % [base, i, ext])
					break
		if Slots.arquivos(String(id)) != velho:
			diferentes.append(id)
	check(ids.size() > 50, "os slots de som carregaram (%d)" % ids.size())
	check(diferentes.is_empty(), "o índice das pastas acha os mesmos arquivos dos %d slots %s" % [ids.size(), str(diferentes.slice(0, 5))])


# ------------------------------------------------------------ (5) o carregamento em segundo plano
func _carregamento() -> void:
	var sm = root.get_node("SaveManager")
	var Car = load("res://scripts/ui/carregando.gd")
	var SM = load("res://scripts/core/save_manager.gd")
	SM.carregamento_assincrono_forcado = true
	# a partida de agora sai; a nova vem pelo caminho do "pular" da intro
	var t := Time.get_ticks_msec()
	sm.intro_terminou(false)
	var bloqueou := Time.get_ticks_msec() - t
	var tela = Car.get("_atual")
	check(bloqueou < 400, "o 'pular' volta na hora (%d ms; antes carregava a partida inteira no mesmo quadro)" % bloqueou)
	check(tela != null and is_instance_valid(tela), "a tela de carregamento está na frente")
	# (no teste a partida anterior já deixou quase tudo no cache: o que está lá não precisa de pedido)
	var dir := "res://assets/game/iso/mapa/"
	var blocos = JSON.parse_string(FileAccess.get_file_as_string(dir + "blocos.json"))
	var sem := 0
	for nome in [] + blocos.imagens.keys():
		if not (dir + String(nome) in Car._pedidos or ResourceLoader.has_cached(dir + String(nome))):
			sem += 1
	var cena_ok: bool = "res://scenes/game/main.tscn" in Car._pedidos or ResourceLoader.has_cached("res://scenes/game/main.tscn")
	check(cena_ok and sem == 0, "a partida e as %d texturas do terreno: pedidas em segundo plano ou já no cache (%d pedidos, %d sem)" % [blocos.imagens.size(), Car._pedidos.size(), sem])
	var barra: ProgressBar = tela.get("_barra") if tela else null
	check(barra != null, "a tela tem a barra do carregamento")
	var n := 0
	var pior := 0
	while (current_scene == null or current_scene == main or not is_instance_valid(current_scene) or current_scene.name != "Main") and n < 3000:
		var tq := Time.get_ticks_msec()
		await process_frame
		if current_scene == null or current_scene == main or not is_instance_valid(current_scene) or current_scene.name != "Main":
			pior = maxi(pior, Time.get_ticks_msec() - tq)
		n += 1
	check(n < 3000 and current_scene != null and current_scene.name == "Main", "a partida nova abriu (%d quadros carregando)" % n)
	check(pior < 1000, "nenhum quadro de carregamento passou de 1 s (pior %d ms: a janela responde)" % pior)
	check(Car._pedidos.is_empty(), "tudo que foi pedido chegou")
	var m := 0
	while is_instance_valid(tela) and m < 2000:
		await process_frame
		m += 1
	check(not is_instance_valid(tela), "a tela some depois que a partida assenta (%d quadros)" % m)
	SM.carregamento_assincrono_forcado = false
	await _frames(4)
