extends SceneTree
## Bloco 132 (não é teste): capturas da ÁREA DE CONSTRUÇÃO, antes e depois da grade.
## COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco132.gd -- <pasta de saída> <prefixo>
## Funciona com o código de antes (sem grade) e o de depois: as mesmas ações, o que o posicionador aceitar.
##   vila        — o terreno em volta do Centro (pedras e mato; depois: a área da vila limpa)
##   construindo — o posicionador de casa aberto ao lado de um prédio (depois: a grade, a ocupação e a porta)
##   encostadas  — 4 casas postas da esquerda pra direita na primeira posição que o posicionador aceita
##   rua         — uma rua de terra traçada na frente delas
var main: Node
var out_dir := ""
var prefixo := "depois"
var t := 0.0
var step := 0
var _casas_x := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas")
	prefixo = args[1] if args.size() > 1 else "depois"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if step == 0 and t > 2.5:
		step = 1
		var eco = g("economy")
		eco.credits = 100000.0
		var arm = g("armazens")
		arm.stock["ferro"] = 5000.0
		arm.wood_stored = 5000.0
		arm._recount()
		_camera(g("village_hub").global_position + Vector2(40, -60), 1.0)
	elif step == 1 and t > 4.0:
		step = 2
		_foto("vila")
		_construindo()
	elif step == 2 and t > 5.5:
		step = 3
		_foto("construindo")
		_encostadas()
	elif step == 3 and t > 7.5:
		step = 4
		_foto("encostadas")
		_rua()
	elif step == 4 and t > 9.0:
		_foto("rua")
		return true
	return false


func _camera(p: Vector2, z: float) -> void:
	var c = main.get_node("Camera2D")
	c.set_target_zoom(z)
	c.zoom = Vector2(z, z)
	c.on_view_changed(p)


## A fileira das casas: atrás do Centro (o norte da vila, onde há espaço).
func _base() -> Vector2:
	return g("village_hub").global_position + Vector2(-200, -260)


func _construindo() -> void:
	var hub = g("village_hub")
	var hp = g("house_placer")
	hp.begin(func(_p): return false, preload("res://assets/game/casa.png"), 3, "a casa nova", hub.house_placer_opts())
	var alvo := _base() + Vector2(150, 0)
	hp.move_to(alvo)
	_camera(alvo + Vector2(0, 40), 1.6)


func _encostadas() -> void:
	var hub = g("village_hub")
	var hp = g("house_placer")
	hp._end(false)
	var postas := 0
	var x := 0.0
	var b := _base()
	while postas < 4 and x < 700.0:
		hp.begin(_poe_casa, preload("res://assets/game/casa.png"), 3, "a casa nova", hub.house_placer_opts())
		hp.move_to(b + Vector2(x, 0))
		if hp._reason == "" and hp.try_confirm():
			postas += 1
			print("casa %d em %s" % [postas, hp._pos])
		else:
			hp._end(false)
		x += 4.0
	_casas_x = x
	print("casas postas: %d (andou %d px)" % [postas, int(x)])
	_camera(b + Vector2(_casas_x * 0.4, 20), 1.6)


## (o que o jogo faz quando a casa é aceita, sem o limite de moradias do estágio: a captura é sobre o LUGAR)
func _poe_casa(p: Vector2) -> bool:
	var casa = g("village_hub").spawn_house(p)
	casa.start_construction(30.0)
	return true


func _rua() -> void:
	var pl = g("caminho_placer")
	var b := _base()
	pl.begin("terra")
	pl.pinta_ate(b + Vector2(-40, 64))
	pl.pinta_ate(b + Vector2(_casas_x + 40, 64))
	pl.cancel()


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [prefixo, nome]))
	print("foto: ", nome)
