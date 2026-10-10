extends SceneTree
## Bloco 112: a INTRODUÇÃO e o PRIMEIRO DIA GUIADO. RODAR SÓ COM APPDATA ISOLADO.
##   (A) Partida nova sem "intro vista": o menu leva pra intro (scenes/ui/intro.tscn): 3 quadros com a ilustração e o texto
##       letra a letra, o clique completa o texto e passa; no fim, a partida (main.tscn) com os quadros 4 a 7 NO MAPA:
##       sem HUD, sem nomes, a câmera na pedreira, no coletor em ruína, o corte da mina e a fogueira (efeito do mapa) com o
##       título; Esc pula; a marca "intro vista" fica nas configurações; a Fundação começa.
##   (B) O guia: o capataz e as setas seguem a missão cap1_primeiro_dia, em ordem (fundar, engenheiro, 6 funções, 3 casas,
##       guarda, cozinha); a seta aponta o botão certo (função, Construir -> aba -> cartão); o "pronto" com Entendi; a missão
##       Cinzas só vem depois.
##   (C) Pular o guia e desligar nas configurações; save, save antigo (o primeiro dia não se repete).
##   (D) Partida nova com a intro já vista vai direto; "Ver a introdução" do menu não salva nada e volta pro menu.
const SAVE := "user://savegame.json"
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var Settings: GDScript
var sm: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	Settings = load("res://scripts/core/settings.gd")
	Settings.set_value("jogo", "intro_vista", false)
	Settings.set_value("jogo", "guia_primeiro_dia", true)
	current_scene = null


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func cena() -> Node:
	return current_scene


func spot_near(c: Vector2, r0: float = 0.0, r1: float = 500.0) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	var r := r0
	while r <= r1:
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
		r += 14.0
	return c


func espera(s: float) -> bool:
	return t - t_mark >= s


func proximo() -> void:
	step += 1
	t_mark = t


func _process(delta: float) -> bool:
	t += delta
	if t > 600.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	var guia = g("guia")
	match step:
		0:
			print("== (A) partida nova sem 'intro vista': a introdução")
			sm.start_new_game()
			proximo()
		1:
			if not espera(0.5):
				return false
			var intro = cena()
			check(intro != null and intro.scene_file_path == "res://scenes/ui/intro.tscn" and sm.cinema == "novo", "o menu levou pra introdução (%s)" % (intro.scene_file_path if intro else "?"))
			check(intro.quadro() == 0 and intro._img.texture != null and intro._img.texture.get_width() == 640, "quadro 1: a ilustração do sol (640x360)")
			for q in intro.QUADROS:
				check(ResourceLoader.exists(intro.DIR + String(q[0]) + ".png"), "ilustração %s integrada" % q[0])
			check(intro._texto.visible_characters < intro._texto.text.length(), "o texto aparece letra a letra")
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			intro._unhandled_input(ev)
			intro._process(0.01)
			check(intro._texto.visible_characters >= intro._texto.text.length(), "um clique completa o texto")
			intro._unhandled_input(ev)
			proximo()
		2:
			if not espera(1.5):
				return false
			var intro = cena()
			check(intro.quadro() == 1, "outro clique: quadro 2 (as cidades)")
			intro.segundos_por_quadro = 0.6  # (o resto sozinho, depressa)
			proximo()
		3:
			var c = cena()
			if c == null or c.scene_file_path != "res://scenes/game/main.tscn":
				return false
			if c.get_node_or_null("IntroCinema") == null:
				return false
			print("== quadros 4 a 7 no mapa")
			var cin = c.get_node("IntroCinema")
			check(cin.quadro() == "pedreira", "quadro 4: a pedreira, no mapa (%s)" % cin.quadro())
			check(not g("hud").visible and c.get("_iso").get("cinema") == true, "sem a interface e sem os nomes dos prédios")
			check(Settings.get_value("jogo", "intro_vista", false) == true, "a marca 'intro vista' nas configurações")
			check(g("house_placer") == null or not g("house_placer").active, "a Fundação espera a introdução")
			cin._t = 999.0
			proximo()
		4:
			var cin = cena().get_node_or_null("IntroCinema")
			if cin == null or cin.quadro() != "coletor" or not espera(1.0):
				return false
			var col = g("coletores")
			var cam: Camera2D = cena().get_node("Camera2D")
			var alvo: Vector2 = cam._to_cam(col.global_position)
			check(cam.get_screen_center_position().distance_to(alvo) < 400.0, "quadro 5: a câmera no coletor em ruína (%.0f px)" % cam.get_screen_center_position().distance_to(alvo))
			cin._t = 999.0
			proximo()
		5:
			var cin = cena().get_node_or_null("IntroCinema")
			if cin == null or cin.quadro() != "corte" or not espera(1.0):
				return false
			check(cin._corte.visible and cin._corte.texture != null, "quadro 6: o corte da mina")
			var y0: float = cin._corte.position.y
			cin._process(4.0)
			check(cin._corte.position.y < y0, "o corte desce (%.0f -> %.0f)" % [y0, cin._corte.position.y])
			cin._t = 999.0
			proximo()
		6:
			var cin = cena().get_node_or_null("IntroCinema")
			if cin == null or cin.quadro() != "fogueira" or not espera(0.8):
				return false
			var fog = cena().get_node_or_null("World/FogueiraIntro")
			check(fog != null and fog.get_meta("iso_fx", "") == "fogueira", "quadro 7: a fogueira (o efeito animado do mapa)")
			check(load("res://scripts/iso/iso_fx.gd").fx_layer("fogueira").get("anim", []).size() == 4, "a fogueira anima (4 quadros)")
			var perto: int = get_nodes_in_group("ipezinhos").filter(func(w): return w.global_position.distance_to(fog.global_position) < 60.0).size()
			check(perto >= 2, "a caravana em volta do fogo (%d)" % perto)
			cin._t = cin.titulo_depois + 0.1
			cin._process(0.01)
			set_meta("cin", cin)
			proximo()
		7:
			if not espera(1.6):
				return false
			var cin = get_meta("cin")
			check(cin._logo.modulate.a > 0.5, "o título DEEP IRON aparece")
			var ev := InputEventKey.new()
			ev.keycode = KEY_ESCAPE
			ev.pressed = true
			cin._input(ev)
			proximo()
		8:
			if not espera(1.0):
				return false
			check(cena().get_node_or_null("IntroCinema") == null and sm.cinema == "", "Esc: a introdução acabou")
			check(g("hud").visible and cena().get("_iso").get("cinema") == false, "a interface e os nomes voltaram")
			check(g("house_placer").active and not g("village_hub").founded, "a Fundação começou")
			check(cena().get_node_or_null("World/FogueiraIntro") != null, "a fogueira fica acesa até o Centro")
			print("== (B) o guia do capataz")
			guia.ligado_mudou()
			proximo()
		9:
			if not espera(0.6):
				return false
			check(guia.mostrando() and guia.passo() == 0, "o capataz aparece: passo 1, fundar (%d)" % guia.passo())
			check(guia.alvos().size() == 1 and guia.alvos()[0] is Vector2, "a seta aponta o lugar no mapa")
			check(g("missoes").ativas().map(func(m): return m.id) == ["cap1_primeiro_dia"], "o Capítulo 1 começa pelo Primeiro dia (a Cinzas vem depois)")
			var p = g("house_placer")
			p.move_to(spot_near(g("founding")._map_center(), 0.0, 300.0))
			check(p.try_confirm(), "Centro da vila fundado")
			proximo()
		10:
			if not espera(1.6):
				return false
			check(cena().get_node_or_null("World/FogueiraIntro") == null, "o Centro tomou o lugar da fogueira do acampamento")
			check(guia.passo() == 1, "passo 2: o engenheiro (%d)" % guia.passo())
			var b: Control = g("hud")._job_buttons["engenheiro"].button
			check(guia.alvos().has(b), "a seta no botão Engenheiro")
			var ws := get_nodes_in_group("ipezinhos")
			ws[1].set_job("guarda")  # (fora de ordem: só conta no passo dele)
			proximo()
		11:
			if not espera(1.2):
				return false
			check(guia.passo() == 1, "em ordem: o guarda antes da hora não pula o passo")
			var ws := get_nodes_in_group("ipezinhos")
			ws[0].set_job("engenheiro")
			proximo()
		12:
			if not espera(1.2):
				return false
			check(guia.passo() == 2 and guia.alvos().has(g("hud")._job_buttons["minerador"].button), "passo 3: dar funções (seta no Minerador)")
			var ws := get_nodes_in_group("ipezinhos")
			ws[1].set_job("ocioso")  # (o guarda de antes sai: senão ele já conta quando chegar a vez dele — o certo)
			var jobs := ["minerador", "minerador", "lenhador", "caçador", "minerador", "lenhador"]
			var k := 0
			for w in ws:
				if w.job == "ocioso" and k < jobs.size():
					w.set_job(jobs[k])
					k += 1
			proximo()
		13:
			if not espera(1.2):
				return false
			var hud = g("hud")
			check(guia.passo() == 3, "passo 4: as casas (%d)" % guia.passo())
			check(guia.alvos().has(hud._build_button), "a seta no Construir")
			if hud._build_menu.visible:
				hud.toggle_build_menu()
			hud.toggle_build_menu()
			hud._build_menu._show_tab(1)
			proximo()
		14:
			if not espera(0.6):
				return false
			var menu = g("hud")._build_menu
			check(guia.alvos().has(menu._tab_buttons[0]), "menu aberto em outra aba: a seta na aba Moradia")
			menu._show_tab(0)
			proximo()
		15:
			if not espera(0.6):
				return false
			var menu = g("hud")._build_menu
			var card = menu._cards.filter(func(c): return String(c.def.name) in ["Casa inicial", "Casa (Moradias)"])
			check(not card.is_empty() and guia.alvos().has(card[0].panel), "na aba certa: a seta no cartão da casa")
			g("hud").toggle_build_menu()
			var hub = g("village_hub")
			for i in 3:
				hub.spawn_house(spot_near(hub.global_position + Vector2(-140 + 120 * i, 150)), "CasaGuia%d" % i)
			proximo()
		16:
			if not espera(1.2):
				return false
			check(guia.passo() == 4 and guia.alvos().has(g("hud")._job_buttons["guarda"].button), "passo 5: o guarda (%d)" % guia.passo())
			var livre = get_nodes_in_group("ipezinhos").filter(func(w): return w.job == "ocioso" or w.job == "minerador")
			livre[0].set_job("guarda")
			proximo()
		17:
			if not espera(1.2):
				return false
			check(guia.passo() == 5, "passo 6: a cozinha (%d)" % guia.passo())
			check(guia.alvos().has(g("hud")._build_button), "a seta no Construir de novo")
			var hub = g("village_hub")
			hub.spawn_comedouro(spot_near(hub.global_position + Vector2(160, -40)), "CozinhaGuia")
			proximo()
		18:
			if not espera(1.6):
				return false
			var m = g("missoes")
			check(m.cumprida("cap1_primeiro_dia") and guia.passo() == -1, "o Primeiro dia cumprido")
			check(guia.mostrando() and guia._botao_ok.visible and "terceira noite" in guia.fala(), "o capataz: pronto pro primeiro dia (com Entendi)")
			check(m.ativas().map(func(x): return x.id).has("cap1_cinzas"), "e agora a missão Cinzas")
			guia._botao_ok.pressed.emit()
			check(not guia.mostrando() and guia.fim_visto, "Entendi: o capataz sai")
			print("== (C) pular, desligar, save")
			var d: Dictionary = guia.get_save_data()
			check(d.get("fim_visto") == true and d.get("pulado") == false, "o guia no save (%s)" % str(d))
			check(g("missoes").get_save_data().get("primeiro_dia") == true, "as missões marcam o save novo")
			m.cumpridas.erase("cap1_primeiro_dia")
			m.feitos.erase("cap1_primeiro_dia")
			m.load_save_data({"capitulo_liberado": 1, "cumpridas": [], "feitos": {"cap1_cinzas": [0]}})
			check(m.cumprida("cap1_primeiro_dia") and m.objetivo_feito(m.por_id("cap1_cinzas"), 0), "save antigo: o primeiro dia já passou (e o resto volta)")
			guia.load_save_data({})
			check(guia.fim_visto and not guia.pulado and not guia.mostrando(), "save antigo: o capataz não aparece")
			m.cumpridas.erase("cap1_primeiro_dia")
			guia.fim_visto = false
			guia._atualiza()
			check(guia.mostrando(), "(sem o primeiro dia: o capataz volta — pro teste)")
			Settings.set_value("jogo", "guia_primeiro_dia", false)
			guia._atualiza()
			check(not guia.mostrando(), "desligado nas configurações: sem capataz")
			Settings.set_value("jogo", "guia_primeiro_dia", true)
			guia.pula()
			check(not guia.mostrando() and guia.pulado, "Pular o guia")
			check(g("missoes").ativas().size() >= 1, "pulou: a missão continua no rastreador")
			m.cumpridas.append("cap1_primeiro_dia")
			print("== (D) a intro já vista: partida nova direto; 'Ver a introdução' não salva")
			sm.save_on_quit = false
			sm.save_game("teste")
			set_meta("hash", FileAccess.get_md5(SAVE))
			sm.ver_introducao()
			proximo()
		19:
			if not espera(0.5):
				return false
			check(cena() != null and cena().scene_file_path == "res://scenes/ui/intro.tscn" and sm.cinema == "ver", "Ver a introdução: a intro de novo")
			cena().pula()
			proximo()
		20:
			if not espera(0.6):
				return false
			check(cena() != null and cena().scene_file_path == "res://scenes/ui/start_menu.tscn", "pulou: de volta ao menu (%s)" % (cena().scene_file_path if cena() else "?"))
			check(FileAccess.get_md5(SAVE) == get_meta("hash"), "o save não mudou")
			sm.ver_introducao()
			proximo()
		21:
			if not espera(0.5):
				return false
			cena().segundos_por_quadro = 0.3
			proximo()
		22:
			var c = cena()
			if c == null or c.scene_file_path != "res://scenes/game/main.tscn" or c.get_node_or_null("IntroCinema") == null:
				return false
			check(sm.so_vendo() and not sm.save_game("tentativa"), "revendo no mapa: nada se salva")
			c.get_node("IntroCinema").pula()
			proximo()
		23:
			if not espera(1.0):
				return false
			check(cena() != null and cena().scene_file_path == "res://scenes/ui/start_menu.tscn" and sm.cinema == "", "revendo: no fim, de volta ao menu")
			check(FileAccess.get_md5(SAVE) == get_meta("hash"), "o save continua o mesmo")
			sm.start_new_game()
			proximo()
		24:
			if not espera(1.0):
				return false
			var c = cena()
			check(c != null and c.scene_file_path == "res://scenes/game/main.tscn" and sm.cinema == "", "intro já vista: partida nova direto (%s)" % (c.scene_file_path if c else "?"))
			proximo()
		25:
			if not espera(2.0):
				return false
			check(cena().get_node_or_null("IntroCinema") == null and g("house_placer").active, "sem cinema: a Fundação começa já")
			print("FALHAS: %d" % fails)
			return true
	return false
