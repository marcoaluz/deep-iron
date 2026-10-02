extends SceneTree
## Prompts 20 a 25: a INTERFACE nova. Pele (painel/botão 9-slice, tema da raiz), ícones (barra de
## cima, funções, laboratório, prédios do menu), fontes pixel (cabeçalho, números), velocidade,
## cursor, retrato do selecionado (expressão pelo estado, tom de pele), janela de evento, faixa
## com ilustração, vitória com a cena e o corte da mina. RODAR SÓ COM APPDATA ISOLADO.
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const EventWindow := preload("res://scripts/ui/event_window.gd")
const PATH := "user://savegame.json"
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
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func hud() -> Node:
	return main.get_tree().get_first_node_in_group("hud")


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		_pele()
		_icones()
		_fontes()
		_velocidade()
		_retrato()
		_eventos()
		t = 3.0
	elif step == 1 and t > 3.6:
		step = 2
		_corte()
		print("FALHAS: %d" % fails)
		Engine.time_scale = 1.0
		return true
	return false


func _pele() -> void:
	print("== pele (Prompt 20)")
	check(UiSkin.ok() and root.theme != null, "tema da janela raiz com a pele nova")
	var b: Button = hud()._button("teste")
	check(b.get_theme_stylebox("normal") is StyleBoxTexture and b.get_theme_stylebox("disabled") is StyleBoxTexture, "botão com tábua 9-slice (estados)")
	check(hud()._panel_style() is StyleBoxTexture, "painel 9-slice")
	var bm: Node = hud()._build_menu
	bm.toggle()
	var card = bm._cards[0] if not bm._cards.is_empty() else null
	check(card != null and card.panel.get_theme_stylebox("panel") is StyleBoxTexture, "cartão do menu de construção com moldura")
	var trancado: bool = card != null and card.button.disabled
	check(card == null or not trancado or card.lock.visible, "cartão trancado mostra o cadeado")
	check(bm._tab_buttons[0].get_theme_stylebox("pressed") is StyleBoxTexture, "abas de couro")
	check(UiSkin.tex("cursor_normal") != null and UiSkin.tex("cursor_proibido") != null, "cursores (5)")
	bm.toggle()


func _icones() -> void:
	print("== ícones (Prompt 21)")
	var falta := []
	for n in ["creditos", "minerio", "madeira", "comida", "camas", "animo", "saude", "minerador", "cacador", "guarda", "pq_escudo",
			"al_invasao", "al_onda_solar", "al_falta_comida", "al_obra_parada", "al_reator", "vel_pausa", "p_ferido", "p_alerta"]:
		if Icones.tex(n) == null:
			falta.append(n)
	check(falta.is_empty(), "ícones base %s" % [falta])
	var chip: Dictionary = hud()._chips.get("credits", {})
	check(chip.get("icon") != null and chip.icon.texture == Icones.tex("creditos", true), "barra de cima: créditos com o ícone novo (24 px)")
	var job: Dictionary = hud()._job_buttons.get("minerador", {})
	var tem := false
	if not job.is_empty():
		for c in job.button.find_children("*", "TextureRect", true, false):
			if c.texture == Icones.tex("minerador"):
				tem = true
	check(tem, "barra de funções: ícone novo do minerador")
	check(Icones.predio("casa") != null and hud()._build_menu._icon("casa", 3) == Icones.predio("casa"), "menu de construção: render reduzido do prédio")


func _fontes() -> void:
	print("== fontes (Prompt 22)")
	var f := UiSkin.fonte("texto")
	check(f != null and UiSkin.fonte("titulo") != null, "as duas fontes pixel carregam")
	var ok := true
	for c in "áàâãéêíóôõúçÁÃÉÍÓÕÚÇ0123456789%$":
		if not (f as FontFile).has_char(c.unicode_at(0)):
			ok = false
	check(ok, "fonte de texto tem os acentos e os números")
	var l: Label = hud()._label("TESTE", 20, hud().COLOR_TITLE)
	check(l.get_theme_font("font") == UiSkin.fonte("titulo"), "cabeçalho na fonte de título")


func _velocidade() -> void:
	print("== velocidade")
	hud().set_speed(2.0)
	check(is_equal_approx(Engine.time_scale, 2.0) and hud()._speed_buttons[2].button_pressed, "2x liga e marca o botão")
	hud().set_speed(1.0)


func _retrato() -> void:
	print("== retrato (Prompt 23)")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	w.injured = false
	w.downed = false
	w.happiness = 80.0
	check(Retratos.expressao(w) == "contente", "ânimo alto: contente")
	w.happiness = 20.0
	check(Retratos.expressao(w) == "cansado", "ânimo baixo: cansado")
	w._ai_state = "strike"
	check(Retratos.expressao(w) == "bravo", "greve: bravo")
	w._ai_state = "idle"
	w.injured = true
	check(Retratos.expressao(w) == "ferido", "machucado: ferido")
	w.injured = false
	w.happiness = 60.0
	var tex := Retratos.de(w)
	check(tex != null, "retrato da pasta/tom/expressão (%s)" % (tex.resource_path.get_file() if tex else "-"))
	main.select(w)
	hud()._update_portrait([w])
	check(hud()._portrait_card != null and hud()._portrait_card.visible and hud()._portrait_img.texture == tex, "cartão do selecionado com o retrato")
	check(Retratos.de_nome("lumivoro") != null, "retrato do Lumívoro (eventos)")


func _eventos() -> void:
	print("== eventos (Prompt 24)")
	check(Icones.ilustracao("invasao") != null and Icones.ilustracao("escudo_vitoria") != null, "ilustrações carregam")
	var antes := hud().get_children().filter(func(c): return c.has_meta("banner")).size()
	hud().show_banner("INVASÃO! (onda 2)", "teste")
	var faixas := hud().get_children().filter(func(c): return c.has_meta("banner"))
	var com_img := false
	for c in faixas:
		for k in c.find_children("*", "TextureRect", true, false):
			if k.texture == Icones.ilustracao("invasao"):
				com_img = true
	check(faixas.size() == antes + 1 and com_img, "faixa de invasão com a ilustração")
	EventWindow.abre(main.get_tree(), "TESTE", "texto", Icones.ilustracao("festa"), [["Ok", null]])
	var w := EventWindow.aberta()
	check(w != null, "janela de evento abre")
	if w:
		w._escolhe(null)
	check(EventWindow.aberta() == null, "e fecha ao escolher")


func _corte() -> void:
	print("== corte da mina (Prompt 25)")
	var c = hud()._corte
	check(c != null, "a tela existe (F2)")
	if c == null:
		return
	c.abre()
	c._desenha()
	check(c.visible and c._rects.size() == 4, "4 andares empilhados")
	var n := main.get_tree().get_nodes_in_group("ipezinhos").size()
	check(c._pontos.size() == n, "um mini-boneco por ipezinho (%d de %d)" % [c._pontos.size(), n])
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = (c._pontos[0][0] as Rect2).get_center()
	c._clique(ev)
	check(not c.visible and main.selection.has(c._pontos[0][1] if c._pontos.size() > 0 else w), "clicar no boneco seleciona e fecha")
