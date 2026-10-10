extends SceneTree
## Bloco 112 (não é teste): fotos da INTRODUÇÃO e do PRIMEIRO DIA GUIADO — os 3 quadros ilustrados, os 4 quadros no mapa
## (pedreira, coletor em ruína, corte da mina, fogueira com o título) e o cartão do capataz com as setas (fundar, o botão
## do Engenheiro, o cartão da casa no Construir).
## Roda COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco112.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var sm: Node
var Settings: GDScript


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco112")
	DirAccess.make_dir_recursive_absolute(out_dir)
	sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Settings = load("res://scripts/core/settings.gd")
	Settings.set_value("jogo", "intro_vista", false)
	Settings.set_value("jogo", "guia_primeiro_dia", true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)


func g(n: String) -> Node:
	return get_first_node_in_group(n)


func _salva(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("tela: ", nome)


func _spot(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 600, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return c


func _proximo() -> void:
	passo += 1
	t_mark = t


func _cin() -> Node:
	return current_scene.get_node_or_null("IntroCinema") if current_scene else null


## Espera o quadro `nome` do mapa chegar em `seg` segundos (o texto inteiro e o preto já clareado).
func _quadro_mapa(nome: String, seg: float) -> bool:
	var cin := _cin()
	return cin != null and cin.quadro() == nome and float(cin._t) >= seg


func _process(delta: float) -> bool:
	t += delta
	if t > 240.0:
		print("TIMEOUT no passo %d" % passo)
		return true
	match passo:
		0:
			sm.start_new_game()
			_proximo()
		1, 2, 3:  # os quadros ilustrados
			var intro = current_scene
			var k := passo - 1
			if intro == null or not intro.has_method("quadro") or intro.quadro() != k or float(intro._t) < 6.2:
				return false
			_salva(String(intro.QUADROS[k][0]))
			_proximo()
		4:
			if not _quadro_mapa("pedreira", 5.0):
				return false
			_salva("q4_pedreira")
			_proximo()
		5:
			if not _quadro_mapa("coletor", 6.0):
				return false
			_salva("q5_coletor_ruina")
			_proximo()
		6:
			if not _quadro_mapa("corte", 6.0):
				return false
			_salva("q6_corte_mina")
			_proximo()
		7:
			var cin := _cin()
			if not _quadro_mapa("fogueira", float(cin.titulo_depois if cin else 0.0) + 2.2):
				return false
			_salva("q7_fogueira_titulo")
			cin.pula()
			_proximo()
		8:
			if t - t_mark < 2.5:
				return false
			_salva("guia_1_fundar")
			var p = g("house_placer")
			p.move_to(_spot(g("founding")._map_center()))
			p.try_confirm()
			_proximo()
		9:
			if t - t_mark < 2.5:
				return false
			_salva("guia_2_engenheiro")
			var ws := get_nodes_in_group("ipezinhos")
			ws[0].set_job("engenheiro")
			var jobs := ["minerador", "minerador", "lenhador", "caçador", "minerador", "lenhador"]
			for i in jobs.size():
				if i + 1 < ws.size():
					ws[i + 1].set_job(jobs[i])
			_proximo()
		10:
			if t - t_mark < 2.0:
				return false
			_salva("guia_3_construir")
			var hud = g("hud")
			if not hud._build_menu.visible:
				hud.toggle_build_menu()
			hud._build_menu._show_tab(0)
			_proximo()
		11:
			if t - t_mark < 1.5:
				return false
			_salva("guia_4_cartao_casa")
			print("FIM")
			return true
	return false
