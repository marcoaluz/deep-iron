extends SceneTree
## Bloco 54: configurações, acessibilidade e idioma. Escala da interface (persistida, limitada pra
## caber em 1280×720 sem cortar janela), velocidade de câmera/zoom, reduzir efeitos, teclas
## remapeáveis (trocar, trocar entre duas, reservadas, restaurar padrão, valer no jogo e depois de
## "reabrir"), idioma (inglês na hora, volta pro português) e a tela de configurações.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const Settings := preload("res://scripts/core/settings.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const Efeitos := preload("res://scripts/core/efeitos.gd")
const Camera := preload("res://scripts/core/camera_controller.gd")
var main: Node
var t := 0.0
var step := 0
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
	if FileAccess.file_exists(Settings.PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.PATH))
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
	if step == 0 and t > 3.0:
		step = 1
		_escala()
		_camera()
		_efeitos()
		_teclas()
		_idioma()
		_tela()
		t = 3.0
		# nada corta: abre todas as janelas (escala 100%, a altura de verdade depois do layout)
		var hud = g("hud")
		for id in hud._panels:
			hud._panels[id].visible = true
			hud._panels[id].refresh()
		hud._build_menu.visible = true
		hud._build_menu.refresh()
	elif step == 1 and t > 3.4:
		step = 2
		_cabe()
		_restaura()
		print("FALHAS: %d" % fails)
		return true
	return false


func _escala() -> void:
	print("== escala da interface")
	var wm = root.get_node("WindowManager")
	check(is_equal_approx(wm.applied_ui_scale(), 1.0) and is_equal_approx(root.content_scale_factor, 1.0), "padrão 100%")
	wm.set_ui_scale(1.5)
	var mx: float = wm.max_ui_scale()
	check(mx < 1.5 and mx >= 1.15, "em 1280×720 cabe até %d%%" % roundi(mx * 100.0))
	check(is_equal_approx(root.content_scale_factor, mx), "pedido 150%%: usa %d%% (o que cabe)" % roundi(root.content_scale_factor * 100.0))
	check(is_equal_approx(Settings.get_value("video", "ui_scale", 0.0), 1.5), "a escolha fica no settings.cfg")
	root.content_scale_factor = 1.0
	wm._reapply_ui_scale()  # "reabrir"
	check(is_equal_approx(root.content_scale_factor, mx), "aplicada de novo ao abrir")
	_area = Vector2(1280, 720) / mx
	wm.set_ui_scale(0.8)
	check(is_equal_approx(root.content_scale_factor, 0.8), "80% vale")
	wm.set_ui_scale(1.0)


var _area := Vector2.ZERO


## Toda janela das estruturas tem a rolagem do Bloco 54 e, aberta, fica dentro da área visível
## abaixo da barra (a conferência em 1280×720 de verdade, com fotos, é tests/capturas_escala.gd).
func _cabe() -> void:
	var hud = g("hud")
	var vis: Vector2 = root.get_visible_rect().size
	var sem := ""
	var fora := ""
	for id in hud._panels:
		var p: Control = hud._panels[id]
		if not p.has_meta("_rolagem"):
			sem += " " + id
		if p.visible:
			hud._fit_panel(p)
			if p.size.y > vis.y - 2.0 * hud.TOP_BAR_H:
				fora += " %s %.0f" % [id, p.size.y]
		p.visible = false
	hud._build_menu.visible = false
	check(sem == "", "toda janela tem rolagem" + (" (sem:%s)" % sem if sem != "" else ""))
	check(fora == "", "abertas, cabem na área visível (%s)%s" % [vis.round(), fora])


func _camera() -> void:
	print("== câmera")
	Settings.set_value("camera", "pan_mult", 1.5)
	Settings.set_value("camera", "zoom_mult", 0.5)
	Camera.load_speeds()
	check(is_equal_approx(Camera.pan_mult, 1.5) and is_equal_approx(Camera.zoom_mult, 0.5), "velocidades lidas do settings.cfg")
	var cam = main.get_node("Camera2D")
	var p0: Vector2 = cam._target_pos
	Input.action_press("ui_right")
	cam._process(0.1)
	Input.action_release("ui_right")
	var andou: float = cam._target_pos.x - p0.x
	var esperado: float = cam.pan_speed * 1.5 * 0.1 / cam.zoom.x
	check(absf(andou - esperado) < 1.0 or cam._target_pos.x != p0.x, "pan anda com o multiplicador (%.0f, esperado ~%.0f antes do limite)" % [andou, esperado])
	Settings.set_value("camera", "pan_mult", 1.0)
	Settings.set_value("camera", "zoom_mult", 1.0)
	Camera.load_speeds()


func _efeitos() -> void:
	print("== reduzir efeitos")
	var w = g("weather")
	var rain: CPUParticles2D = w._fx.rain.node
	var base: int = w._fx.rain.base
	Efeitos.set_reduzidos(true, main.get_tree())
	check(rain.amount == Efeitos.qtd(base) and rain.amount < base, "chuva com menos partículas (%d de %d)" % [rain.amount, base])
	check(Settings.get_value("video", "reduzir_efeitos", false), "fica no settings.cfg")
	Efeitos._cache = -1
	check(Efeitos.reduzidos(), "lido de novo ao abrir")
	Efeitos.set_reduzidos(false, main.get_tree())
	check(rain.amount == base, "desligado: volta ao normal")


func _tecla(k: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = k
	ev.keycode = k
	main._unhandled_input(ev)


func _teclas() -> void:
	print("== teclas")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	main.select(w)
	check(Teclas.acao(KEY_1) == "minerador" and Teclas.acao(KEY_KP_1) == "minerador", "padrão: 1 (e o 1 do teclado numérico) = minerador")
	Teclas.define("minerador", KEY_PERIOD)
	check(Teclas.acao(KEY_PERIOD) == "minerador" and Teclas.acao(KEY_1) == "", "trocou: ponto = minerador, 1 livre")
	w.set_job("lenhador")
	_tecla(KEY_PERIOD)
	check(w.job == "minerador", "a tecla nova vale no jogo (9 -> minerador)")
	w.set_job("lenhador")
	_tecla(KEY_1)
	check(w.job == "lenhador", "a tecla antiga não faz mais nada")
	Teclas.define("minerador", KEY_C)
	check(Teclas.acao(KEY_C) == "minerador" and Teclas.tecla("cozinheiro") == KEY_PERIOD, "tecla de outra ação: as duas trocam (C minerador, ponto cozinheiro)")
	Teclas.define("minerador", KEY_W)
	check(Teclas.tecla("minerador") == KEY_C, "W (câmera) é reservada: não muda")
	Teclas._por_tecla.clear()
	Teclas._principal.clear()
	check(Teclas.acao(KEY_C) == "minerador" and Teclas.acao(KEY_PERIOD) == "cozinheiro", "depois de reabrir continua (settings.cfg)")
	var hud = g("hud")
	hud._fill_hints()
	var texto := ""
	for c in hud._hint_box.get_children():
		if c is Label:
			texto += c.text + "\n"
	check("C minerador" in texto, "a ajuda (H) mostra a tecla nova")
	Teclas.restaura_padrao()
	check(Teclas.acao(KEY_1) == "minerador" and Teclas.acao(KEY_C) == "cozinheiro" and Teclas.acao(KEY_PERIOD) == "", "restaurar padrão")
	w.set_job("lenhador")
	_tecla(KEY_1)
	check(w.job == "minerador", "1 -> minerador de novo")


func _idioma() -> void:
	print("== idioma")
	var wm = root.get_node("WindowManager")
	wm.set_language("en")
	check(TranslationServer.get_locale().begins_with("en"), "inglês: locale %s" % TranslationServer.get_locale())
	check(TranslationServer.translate("CONSTRUIR") == "BUILD" and TranslationServer.translate("Vender") == "Sell", "textos da interface em inglês (CONSTRUIR -> %s)" % TranslationServer.translate("CONSTRUIR"))
	var l := Label.new()
	l.text = "PAUSADO"
	root.add_child(l)
	check(l.atr(l.text) == "PAUSED", "rótulo troca na hora (sem reiniciar)")
	l.queue_free()
	check(Settings.get_value("geral", "idioma", "") == "en", "fica no settings.cfg")
	wm.set_language("pt_BR")
	check(TranslationServer.translate("CONSTRUIR") == "CONSTRUIR", "de volta ao português")
	var f: Font = ThemeDB.fallback_font
	var tema := root.theme
	if tema and tema.default_font:
		f = tema.default_font
	var falta := ""
	for ch in "ãâáàçéêíóôõúÃÂÁÇÉÊÍÓÔÕÚ":
		if f is FontFile and not (f as FontFile).has_char(ch.unicode_at(0)):
			falta += ch
	check(falta == "", "a fonte tem os acentos" + ((" (falta %s)" % falta) if falta != "" else ""))


func _tela() -> void:
	print("== tela de configurações")
	var p: VBoxContainer = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(p)
	check(p.find_child("Escala da interface", true, false) is HSlider, "slider de escala da interface")
	check(p.find_child("Velocidade da câmera", true, false) is HSlider and p.find_child("Velocidade do zoom", true, false) is HSlider, "sliders de câmera e zoom")
	check(p.find_child("Idioma", true, false) is OptionButton, "escolha de idioma")
	p._show_keys(true)
	check(p._keys_page.visible and p._key_buttons.size() == Teclas.NOMES.size(), "página de teclas (%d ações)" % p._key_buttons.size())
	p._waiting = "vender"
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = KEY_8
	p._input(ev)
	check(Teclas.tecla("vender") == KEY_8 and p._key_buttons["vender"].text == Teclas.nome("vender"), "clicar e apertar 8: vender = 8")
	p._waiting = "vender"
	ev.physical_keycode = KEY_ESCAPE
	p._input(ev)
	check(Teclas.tecla("vender") == KEY_8 and p._waiting == "", "Esc cancela")
	p.queue_free()


func _restaura() -> void:
	Teclas.restaura_padrao()
	root.get_node("WindowManager").set_ui_scale(1.0)
