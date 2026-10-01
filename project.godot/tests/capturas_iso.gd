extends SceneTree
## Capturas da vista iso pros relatórios do Prompt 29 (não é teste: não dá OK/FALHOU).
## Abre a partida, ergue os prédios no layout aprovado (Prompt 27), põe obras em estágios
## diferentes e salva PNGs. Roda COM JANELA (precisa renderizar) e com APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_iso.gd -- <pasta de saída>
const PATH := "user://savegame.json"
const Canteiro := preload("res://scripts/props/canteiro.gd")
## [nome do arquivo, ponto do chão no centro da tela, zoom]
const SHOTS := [
	["vila_oeste", Vector2(-440, -300), 1.0],
	["vila_leste", Vector2(380, -320), 1.0],
	["terraco_meio", Vector2(-330, -40), 1.0],
	["pedreira", Vector2(-300, 300), 1.0],
	["portao_palicada", Vector2(0, -470), 1.0],
	["obras", Vector2(120, -120), 1.0],
	["escavadeira", Vector2(-520, 300), 1.0],
	["centro", Vector2(-300, -320), 2.0],
]
## prédios a mais (cena, posição): o layout do Prompt 27 (mapa/monta.py)
const EXTRA := [
	["res://scenes/props/taverna.tscn", Vector2(130, -370)],
	["res://scenes/props/parque.tscn", Vector2(470, -360)],
	["res://scenes/props/laboratorio.tscn", Vector2(420, -260)],
	["res://scenes/props/vestiario.tscn", Vector2(220, -260)],
	["res://scenes/props/arsenal.tscn", Vector2(-200, -90)],
	["res://scenes/props/campo_treino.tscn", Vector2(-560, 90)],
	["res://scenes/props/casa.tscn", Vector2(-140, -380)],
	["res://scenes/props/casa.tscn", Vector2(-60, -260)],
	["res://scenes/props/casa.tscn", Vector2(-200, -250)],
]
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var shot := 0
var t_shot := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	root.size = Vector2i(1600, 900)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT")
		return true
	if step == 0 and t > 2.5:
		step = 1
		_setup()
	elif step == 1 and t > 4.5:
		step = 2
		t_shot = t
		_aim(shot)
	elif step == 2 and t - t_shot > 1.2:
		var s: Array = SHOTS[shot]
		var img := root.get_texture().get_image()
		img.save_png(out_dir.path_join(s[0] + ".png"))
		print("captura: ", s[0])
		shot += 1
		if shot >= SHOTS.size():
			return true
		t_shot = t
		_aim(shot)
	return false


func _aim(i: int) -> void:
	var cam = main.get_node("Camera2D")
	var s: Array = SHOTS[i]
	cam.zoom = Vector2(s[2], s[2])
	cam.set_target_zoom(s[2])
	cam.on_view_changed(s[1])


func _setup() -> void:
	var world := main.get_node("World")
	for e in EXTRA:
		var n: Node2D = load(e[0]).instantiate()
		n.position = e[1]
		world.add_child(n)
	# obras em estágios diferentes (0–33 / 33–66 / 66–100%)
	var k := 0
	for kind in ["taverna", "laboratorio", "comedouro"]:
		var c: Node2D = Canteiro.order(self, kind, Vector2(-20 + 150 * k, -130 + 10 * k), 30.0)
		c.left = 30.0 * (1.0 - (0.15 + 0.33 * k))
		k += 1
	# uma casa em obra
	var casa: Node2D = load("res://scenes/props/casa.tscn").instantiate()
	casa.position = Vector2(-380, -380)
	world.add_child(casa)
	casa.start_construction(30.0)
	casa.build_left = 12.0
	# Centro no estágio 3; escavadeira com estrutura + motor e a cabine em montagem
	var hub := main.get_tree().get_first_node_in_group("village_hub")
	hub.level = 3
	hub._update_visual()
	var esc := main.get_tree().get_first_node_in_group("escavadeira")
	if esc:
		esc.installed["estrutura"] = true
		esc.installed["motor"] = true
		esc.fabricating = "cabine"
		esc.fab_left = float(esc.part_cost("cabine").z) * 0.5
		esc._update_visual()
	var env := main.get_node("World/Environment")
	env.rebuild_navigation()
