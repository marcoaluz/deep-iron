extends SceneTree
## Bloco 63: o "Corte da mina" lê o estado real (jazidas abertas/lacradas/trancadas, reatores,
## ipezinhos por andar, bichos, coletores), atualiza com o jogo, clique numa galeria leva a câmera
## até ela, e o desenho se refaz ~20x/s (não todo quadro). RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var corte: Node
var desenhos := 0


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


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	match step:
		0:
			if t > 3.0:
				corte = g("hud")._corte
				corte.abre()
				corte._area.draw.connect(func(): desenhos += 1)
				step = 1
				t_mark = t
				desenhos = 0
		1:
			if t - t_mark > 1.0:
				_le_estado()
				step = 2
				t_mark = t
		2:
			if t - t_mark > 0.3:
				_atualiza_e_clica()
				print("FALHAS: %d" % fails)
				return true
	return false


func _le_estado() -> void:
	print("== estado")
	check(desenhos >= 5 and desenhos <= 30, "redesenha ~20x/s (%d desenhos em 1 s)" % desenhos)
	var ms: Array = main.get_tree().get_nodes_in_group("minerios")
	check(corte._galerias.size() == ms.size(), "todas as jazidas no corte (%d)" % corte._galerias.size())
	var lacradas := ms.filter(func(m): return m.is_sealed()).size()
	check(lacradas > 0, "há galerias lacradas pra mostrar (%d)" % lacradas)
	var n_mina: int = corte._gente_no_andar(1)
	check(n_mina == main.get_tree().get_nodes_in_group("ipezinhos").size(), "ipezinhos por andar (mina: %d)" % n_mina)


func _atualiza_e_clica() -> void:
	print("== tempo real e clique")
	var ms: Array = main.get_tree().get_nodes_in_group("minerios")
	var lacrada: Node = null
	for m in ms:
		if m.is_sealed():
			lacrada = m
	lacrada.blast_open()
	corte._area.queue_redraw()
	await_draw()
	check(not lacrada.is_sealed(), "estado novo (galeria aberta) aparece no próximo desenho")
	var r: Rect2 = Rect2()
	for gl in corte._galerias:
		if gl[1] == lacrada:
			r = gl[0]
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = r.get_center()
	corte._clique(ev)
	var cam = main.get_node("Camera2D")
	var primeira: Node = null  # (galerias juntas no corte: vale a primeira que o clique acerta)
	for gl in corte._galerias:
		if (gl[0] as Rect2).has_point(ev.position):
			primeira = gl[1]
			break
	var alvo: Vector2 = cam._clamp_to_bounds(cam._to_cam(primeira.global_position))
	check(not corte.visible and cam._target_pos.distance_to(alvo) < 2.0, "clique na galeria: fecha e leva a câmera até ela (%s, %.0f px)" % [primeira.name, cam._target_pos.distance_to(alvo)])


## (desenha fora do sinal draw: os draw_* do Control não valem fora dele, mas as listas de clique sim)
func await_draw() -> void:
	corte._area.queue_redraw()
