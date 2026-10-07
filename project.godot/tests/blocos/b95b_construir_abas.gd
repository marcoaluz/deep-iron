extends SceneTree
## Bloco 95 (partes B e D): a janela CONSTRUIR padronizada. Abre TODAS as abas, nas três escalas da interface
## (90 / 100 / 125%), e confere: o retângulo da janela é o MESMO em todas as abas; nenhum cartão sai da área
## visível na largura (sem rolagem horizontal); todos os cartões têm o mesmo tamanho e o botão no mesmo lugar;
## as abas têm a mesma largura, o nome cabe e há folga pro X; ←/→ trocam de aba, Esc fecha e a última aba fica
## lembrada; e todo cartão tem IMAGEM (a auditoria lista o que faltar). RODAR SÓ COM APPDATA ISOLADO.
const Settings := preload("res://scripts/core/settings.gd")
const ESCALAS := [1.0, 0.9, 1.25]
var main: Node
var t := 0.0
var fails := 0
var t_mark := 0.0
var fase := "inicio"
var esc_i := 0
var aba := 0
var rect_ref := Rect2()
var sem_imagem := {}


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
	preload("res://scripts/core/settings.gd").set_value("video", "ui_scale", 1.0)  # (o autoload ainda não está na árvore)
	root.size = Vector2i(1280, 720)  # a tela lógica do jogo
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP  # (headless: a janela é quadrada; assim a área é 1280x720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func menu() -> Node:
	return main.get_node("HUD")._build_menu


func _process(delta: float) -> bool:
	t += delta
	if t > 240.0:
		print("TIMEOUT na fase %s\nFALHAS: %d" % [fase, fails + 1])
		return true
	if fase == "inicio":
		if t < 3.0:
			return false
		get_first_node_in_group("economy").credits = 600.0
		fase = "escala"
		t_mark = t
		return false
	if fase == "escala":
		var e: float = ESCALAS[esc_i]
		root.get_node("WindowManager").set_ui_scale(e)
		print("== escala %d%% (área lógica %s)" % [roundi(e * 100.0), str(root.get_visible_rect().size)])
		var m := menu()
		if not m.visible:
			main.get_node("HUD").toggle_build_menu()
		aba = 0
		m._show_tab(aba)
		rect_ref = Rect2()
		fase = "aba"
		t_mark = t
		return false
	if fase == "aba" and t - t_mark > 0.15:
		var m := menu()
		var d: Dictionary = m.diagnostico()
		var nome: String = m.TAB_NAMES[aba]
		var r: Rect2 = d.rect
		if aba == 0:
			rect_ref = r
			var vis: Rect2 = root.get_visible_rect()
			var hud = main.get_node("HUD")
			check(vis.encloses(r), "janela inteira dentro da tela %s" % str(r))
			check(r.position.y >= hud.TOP_BAR_H - 0.5 and r.end.y <= hud._order_bar.get_global_rect().position.y + 0.5,
				"entre a barra de cima e a de baixo")
			# abas: largura igual, nome cabe, folga pro X
			var larg: Array = []
			var cabe := true
			for b in m._tab_buttons:
				larg.append(roundi(b.size.x))
				var f: Font = b.get_theme_font("font")
				if f.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x > b.size.x - 4.0:
					cabe = false
			check(larg.all(func(x): return x == larg[0]), "abas com a mesma largura (%s)" % str(larg.slice(0, 3)))
			check(cabe, "o nome de toda aba cabe nela")
			var fechar: Button = null
			for b in m.find_children("*", "Button", true, false):
				if b.text == "X":
					fechar = b
			var bate := false
			for b in m._tab_buttons:
				if fechar and b.get_global_rect().intersects(fechar.get_global_rect()):
					bate = true
			check(fechar != null and not bate, "o X de fechar tem folga das abas")
		check(r.is_equal_approx(rect_ref), "%-20s mesmo retângulo %s" % [nome, str(r)])
		check(d.fora.is_empty(), "%-20s nenhum cartão cortado na largura %s" % [nome, str(d.fora)])
		check(not d.rolagem_h and d.conteudo.x <= d.area.size.x + 0.5, "%-20s sem rolagem horizontal (%d <= %d)" % [nome, d.conteudo.x, d.area.size.x])
		# cartões do mesmo tamanho, botão no mesmo lugar
		var tam: Array = []
		var bot: Array = []
		for c in m._cards:
			var pr: Rect2 = c.panel.get_global_rect()
			tam.append(Vector2i(pr.size.round()))
			bot.append(roundi(c.button.get_global_rect().position.y - pr.position.y))
		check(tam.all(func(x): return x == tam[0]) and bot.all(func(x): return x == bot[0]),
			"%-20s %d cartões do mesmo tamanho %s, botão no mesmo lugar (%s)" % [nome, tam.size(), str(tam[0]) if not tam.is_empty() else "-", str(bot[0]) if not bot.is_empty() else "-"])
		for n in d.sem_imagem:
			sem_imagem[n] = nome
		aba += 1
		if aba < m.TAB_NAMES.size():
			m._show_tab(aba)
			t_mark = t
			return false
		esc_i += 1
		if esc_i < ESCALAS.size():
			fase = "escala"
			return false
		root.get_node("WindowManager").set_ui_scale(1.0)
		fase = "teclas"
		t_mark = t
		return false
	if fase == "teclas" and t - t_mark > 0.3:
		print("== teclas e a última aba")
		var m := menu()
		m._show_tab(2)
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.physical_keycode = KEY_RIGHT
		m._unhandled_key_input(ev)
		check(m._tab == 3, "→ vai pra próxima aba (%d)" % m._tab)
		ev.physical_keycode = KEY_LEFT
		m._unhandled_key_input(ev)
		m._unhandled_key_input(ev)
		check(m._tab == 1, "← volta (%d)" % m._tab)
		check(int(Settings.get_value("hud", "construir_aba", -1)) == 1, "a última aba fica lembrada")
		var cam = main.get_node("Camera2D")
		check(cam._menu_usa_setas(), "com o menu aberto as setas são do menu (a câmera não anda)")
		var esc := InputEventKey.new()
		esc.pressed = true
		esc.physical_keycode = KEY_ESCAPE
		main._unhandled_input(esc)
		check(not m.visible, "Esc fecha")
		main.get_node("HUD").toggle_build_menu()
		check(m.visible and m._tab == 1, "abre de novo na última aba")
		main.get_node("HUD").toggle_build_menu()

		print("== D) auditoria das imagens dos cartões (todas as abas)")
		var faltam: Array[String] = []
		for tab in m.TAB_NAMES:
			for d in m._defs(tab):
				var p: String = d.get("img", "")
				if p == "" or not ResourceLoader.exists(p):
					faltam.append("%s / %s" % [tab, d.name])
		for n in sem_imagem:
			var s := "%s / %s" % [sem_imagem[n], n]
			if not faltam.has(s):
				faltam.append(s)
		for f in faltam:
			print("    SEM IMAGEM: ", f)
		check(faltam.is_empty(), "todo cartão tem imagem (faltam %d)" % faltam.size())
		# estados: bloqueado = imagem escura + cadeado; sem recurso = custo em destaque, imagem normal
		m.visible = true
		m._show_tab(m.TAB_NAMES.find("Defesa e equipamento"))
		m.refresh()
		var bloq := 0
		var falta := 0
		for c in m._cards:
			if c.estado == "bloq":
				bloq += 1
				check(c.lock.visible and c.img.modulate.v < 0.6 and c.button.disabled and c.status.text != "", "bloqueado: cadeado, imagem escura e o motivo (%s: %s)" % [c.def.name, c.status.text])
			elif c.estado == "falta":
				falta += 1
				check(not c.lock.visible and c.img.modulate == Color.WHITE and c.req.icone.visible and c.status.text.begins_with("falta"), "sem recurso: o que falta com ícone (%s: %s)" % [c.def.name, c.status.text])
		check(bloq + falta > 0, "a aba Defesa tem cartões trancados ou sem recurso (%d / %d)" % [bloq, falta])
		check(m._cards.size() == m._cards_box.get_child_count(), "cartões bloqueados continuam visíveis")
		m.visible = false
		print("\nFALHAS: %d" % fails)
		return true
	return false
