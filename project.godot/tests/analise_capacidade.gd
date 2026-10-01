extends SceneTree
## Análise (não é teste): quantas casas cabem na pedreira com a pegada nova (Prompt 29).
## Ergue os prédios do layout aprovado + os extras de fim de jogo, depois encaixa casas
## (posicionador de verdade: pegada do desenho + porta, chão plano, sem encostar) varrendo o chão
## da pedreira, até não caber mais. Imprime a contagem por terraço.
## RODAR SÓ COM APPDATA ISOLADO:  <Godot>.exe --headless --path . -s res://tests/analise_capacidade.gd
const PATH := "user://savegame.json"
const EXTRA := [
	["res://scenes/props/taverna.tscn", Vector2(130, -370)],
	["res://scenes/props/parque.tscn", Vector2(470, -360)],
	["res://scenes/props/laboratorio.tscn", Vector2(420, -260)],
	["res://scenes/props/vestiario.tscn", Vector2(220, -260)],
	["res://scenes/props/arsenal.tscn", Vector2(-200, -90)],
	["res://scenes/props/campo_treino.tscn", Vector2(-560, 90)],
]
const STEP := 12.0
var main: Node
var t := 0.0
var done := false


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


func _process(delta: float) -> bool:
	t += delta
	if done or t < 3.0:
		return done
	done = true
	_run(EXTRA, "layout + extras de fim de jogo (taverna, parque, lab, vestiário, arsenal, campo)")
	return true


func _run(extra: Array, title: String) -> void:
	var world := main.get_node("World")
	for e in extra:
		var n: Node2D = load(e[0]).instantiate()
		n.position = e[1]
		world.add_child(n)
	var env := main.get_node("World/Environment")
	var placer := main.get_tree().get_first_node_in_group("house_placer")
	var casa_tex := preload("res://assets/game/casa.png")
	var g: Rect2 = env.iso_ground_rect()
	var by_level := {}
	var spots: Array = []
	var houses := 0
	placer.begin(func(_p): return false, casa_tex, 3, "análise", {})
	var y: float = env.palisade_y + 20.0
	while y < g.end.y:
		var x := g.position.x
		while x < g.end.x:
			var p := Vector2(x, y)
			if placer.check_spot(p) == "":
				var c: Node2D = load("res://scenes/props/casa.tscn").instantiate()
				c.position = p
				world.add_child(c)
				houses += 1
				spots.append(p)
				var lv: int = env.tile_level(env.tile_at(p))
				by_level[lv] = by_level.get(lv, 0) + 1
				placer.cancel()
				placer.begin(func(_p): return false, casa_tex, 3, "análise", {})  # bloqueios de agora
			x += STEP
		y += STEP
	placer.cancel()
	var fp: Rect2 = placer.IsoArt.placer_footprint(main.get_tree(), "casa")
	print("== ", title)
	print("  pegada de uma casa no posicionador: %.0f x %.0f px da lógica" % [fp.size.x, fp.size.y])
	print("  casas novas que ainda cabem: %d  (por degrau: %s — 3 = terraço de cima, 2 = meio, 0 = fundo)" % [houses, by_level])
	print("  lugares: ", spots)
	print("  o jogo pede no máximo: 7 casas (3 iniciais + 4 níveis de Moradias)")
