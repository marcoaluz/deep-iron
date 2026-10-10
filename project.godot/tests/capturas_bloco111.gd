extends SceneTree
## Bloco 111 (não é teste): fotos — as crianças brincando perto da escola pronta, o adulto ao lado (a escala), o bebê no
## cartão do selecionado, a ficha com a família e a janela de Políticas com o cartão de Família.
## Roda COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco111.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var passo := 0
var t_mark := 0.0
var pai: Node
var mae: Node
var c1: Node
var c2: Node
var bebe: Node
var escola: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco111")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(n: String) -> Node:
	return main.get_tree().get_first_node_in_group(n)


func _salva(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(nome + ".png"))
	print("tela: ", nome)


func _foca(pos: Vector2, zoom: float) -> void:
	var cam = main.get_node("Camera2D")
	var alvo: Vector2 = main.get_node("IsoView").to_screen(pos)
	cam.zoom = Vector2(zoom, zoom)
	cam._target_zoom = zoom
	cam.position = alvo
	cam._target_pos = alvo


func _spot(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 600, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return c


func _process(delta: float) -> bool:
	t += delta
	if t > 160.0:
		print("TIMEOUT")
		return true
	var dn = g("day_night")
	if dn:
		dn.time = dn.tempo_da_hora(10.0)
	if t - t_mark < (6.0 if passo == 1 else 1.5):
		return false
	t_mark = t
	var hub = g("village_hub")
	var rel = g("relacoes")
	var fam = g("familias")
	match passo:
		0:
			hub.level = 2
			var eco = g("economy")
			pai = eco.novo_ipezinho("menino")
			mae = eco.novo_ipezinho("menina")
			pai.set_job("minerador")
			mae.set_job("lenhador")
			rel.soma(pai, mae, 300.0)
			escola = hub.spawn_obra107("escola", _spot(hub.global_position + Vector2(150, 40)))
			c1 = eco.novo_ipezinho("menino")
			c2 = eco.novo_ipezinho("menina")
			bebe = eco.novo_ipezinho("menina")
			for k in [c1, c2]:
				k.fase = "crianca"
				k.idade_s = 10.0 * fam._seg_dia()  # (a fase sai da idade: o Familias confere a cada segundo)
				k.pais = [String(mae.name), String(pai.name)]
				k._apply_outfit()
			bebe.fase = "bebe"
			bebe.pais = [String(mae.name), String(pai.name)]
			pai.filhos = [String(c1.name), String(c2.name), String(bebe.name)]
			mae.filhos = pai.filhos.duplicate()
			mae.gravidez_s = 3.0 * fam._seg_dia()
			mae.pai_bebe = String(pai.name)
			for k in [c1, c2]:
				k.auto_mode = false
		1:
			var base: Vector2 = escola.global_position + Vector2(-80, 110)
			c1.global_position = base
			c2.global_position = base + Vector2(26, 6)
			pai.global_position = base + Vector2(-34, 2)
			pai.auto_mode = false
			for k in [c1, c2]:
				k._work_timer = 5.0
			_foca(base + Vector2(30, -50), 2.5)
		2:
			for k in [c1, c2]:
				k._work_timer = 5.0
			_salva("111_criancas_escola")
			main.select(bebe)
		3:
			_salva("111_bebe_cartao")
			main.select(mae)
			g("hud").open_panel("ficha", mae)
		4:
			_salva("111_ficha_familia")
			g("hud").close_panels()
			g("hud").open_panel("politicas")
			g("hud")._panels["politicas"]._seleciona("familia", "incentivar")
		5:
			_salva("111_politica_familia")
			print("FIM")
			return true
	passo += 1
	return false
