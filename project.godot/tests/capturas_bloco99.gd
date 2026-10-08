extends SceneTree
## Bloco 99 (não é teste): fotos da AUDITORIA de como os ipezinhos descem hoje — a boca da mina com o vagonete e o
## trilho até o armazém, o elevador ao lado da escavadeira, a coluna dos andares (poço + espiral + cavalete), os degraus
## da montanha, a chegada no S2 e a plataforma do abismo. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco99.gd -- <pasta de saída> [prefixo]
const PATH := "user://savegame.json"
const ASSENTA := 2.0
var main: Node
var out_dir := ""
var prefixo := "antes"
var t := 0.0
var step := 0
var vista := 0
var _vistas: Array = []


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_bloco99")
	prefixo = args[1] if args.size() > 1 else "antes"
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


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func iso() -> Node:
	return main.get_node("IsoView")


func _tela(centro: Vector2, z: float) -> void:
	var cam = main.get_node("Camera2D")
	cam.bounds = Rect2()
	cam.zoom_min = minf(cam.zoom_min, z)
	cam.iso_zoom_min = minf(cam.iso_zoom_min, z)
	cam.zoom = Vector2(z, z)
	cam._target_zoom = z
	cam.position = centro
	cam._target_pos = centro


func _prepara() -> void:
	var hud = g("hud")
	if hud:
		hud.visible = false
	var dn = g("day_night")
	dn._pula_para(dn.tempo_da_hora(11.0))
	var env = g("environment")
	var boca: Vector2 = env.bocas_da_mina()[0]
	var elev = main.get_node("World/Elevador")
	var abismo = main.get_node("World/ElevadorAbismo")
	if prefixo != "antes":
		_vistas = _depois(env, boca, elev, abismo)
		return
	_vistas = [
		["01_boca_vagonete_armazem", func(): _tela(iso().to_screen(boca + Vector2(-60, 120)), 1.3)],
		["02_boca_perto", func(): _tela(iso().to_screen(boca + Vector2(0, 30)), 2.6)],
		["03_elevador_escavadeira", func(): _tela(iso().to_screen((elev.global_position + Vector2(-140, 320)) * 0.5), 1.4)],
		["04_elevador_perto", func(): _tela(iso().to_screen(elev.global_position), 2.6)],
		["05_degraus_montanha", func(): _tela(iso().to_screen(Vector2(980, -330), 200.0), 1.0)],
		["06_coluna_andares", func(): _tela(iso().to_screen(elev.bottom_position), 0.45)],
		["07_chegada_S2", func(): _tela(iso().to_screen(elev.bottom_position), 1.6)],
		["08_plataforma_abismo", func(): _tela(iso().to_screen(abismo.global_position), 1.6)],
	]


## Bloco 99 (depois): o elevador por etapa, a cabine no poço, a fila, a espiral e a boca com gente dentro.
func _depois(env: Node, boca: Vector2, elev: Node, abismo: Node) -> Array:
	var eco = g("economy")
	eco.credits = 99999.0
	var arm = g("armazens")
	arm.stock["ferro"] = 2000.0
	arm.wood_stored = 2000.0
	arm._recount()
	eco.add_item("prego", 100.0)
	eco.add_item("barra_ferro", 400.0)
	g("village_hub").level = 5
	var meio: Vector2 = (iso().to_screen(elev.global_position) + iso().to_screen(elev.bottom_position)) * 0.5
	return [
		["10_elevador_ruina", func(): _tela(iso().to_screen(elev.global_position), 2.2)],
		["11_elevador_obra_1", func(): elev.etapa = 1; elev._apply(false)],
		["12_elevador_obra_2", func(): elev.etapa = 2; elev._apply(false)],
		["13_elevador_pronto", func(): elev.restaura_tudo(); elev.unlock(false)],
		["14_cabine_no_poco", func(): elev.cabine.pos = 0.35; elev.cabine.alvo = 1.0; _tela(meio, 0.6)],
		["15_cabine_chegando_S2", func(): elev.cabine.pos = 0.85; elev.cabine.alvo = 0.85; _tela(iso().to_screen(elev.bottom_position) + Vector2(0, -60), 1.6)],
		["16_boca_com_mineiros", func(): _mineiros_dentro(); _tela(iso().to_screen(boca + Vector2(0, 30)), 2.4)],
		["17_boca_noite", func(): g("day_night")._pula_para(g("day_night").tempo_da_hora(19.0))],
	]


func _mineiros_dentro() -> void:
	var est = g("bocas_mina")
	var ws := main.get_tree().get_nodes_in_group("ipezinhos")
	for i in mini(3, ws.size()):
		ws[i]._entra_mina(est)


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		return true
	if step == 0:
		if t > 4.0:
			_prepara()
			step = 1
			t = 0.0
			_vistas[0][1].call()
		return false
	if t > ASSENTA:
		var img := root.get_texture().get_image()
		img.save_jpg(out_dir.path_join("%s_%s.jpg" % [prefixo, _vistas[vista][0]]), 0.88)
		print("foto ", _vistas[vista][0])
		vista += 1
		t = 0.0
		if vista >= _vistas.size():
			return true
		_vistas[vista][1].call()
	return false
