extends SceneTree
## Bloco 134 (não é teste): o CHÃO DA VILA nos estágios 1, 3 e 5, de dia e de noite — pro diagnóstico e pro antes/depois.
## COM JANELA e APPDATA isolado:  <Godot>.exe --path . -s res://tests/capturas_bloco134.gd -- <pasta de saída> <prefixo>
## Fotos: <prefixo>_e<estágio>_<dia|noite>.png (vista geral, zoom 1) e <prefixo>_e1_dia_perto.png (zoom 2, o chão de perto).
var main: Node
var out_dir := ""
var prefixo := "agora"
var t := 0.0
var fila: Array = []  # [[estágio, hora, nome, zoom]]
var _espera := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas")
	prefixo = args[1] if args.size() > 1 else "agora"
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
	var so_perto := OS.get_cmdline_user_args().has("perto")
	if not so_perto:
		for e in [1, 3, 5]:
			fila.append([e, 12.0, "e%d_dia" % e, 1.0])
			fila.append([e, 22.5, "e%d_noite" % e, 1.0])
	fila.append([1, 12.0, "e1_dia_perto", 2.0])
	fila.append([3, 12.0, "e3_dia_longe", 0.5])


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


var _pendente: Array = []
var _caminhos_feitos := false


## Os mesmos caminhos no antes e no depois: uma rua de terra, uma de cascalho com curva e um largo de pedra.
func _pinta_caminhos() -> void:
	var eco = g("economy")
	eco.credits = 100000.0
	var arm = g("armazens")
	arm.stock["ferro"] = 5000.0
	arm.wood_stored = 5000.0
	arm._recount()
	var pl = g("caminho_placer")
	var h: Vector2 = g("village_hub").global_position
	pl.begin("terra")
	pl.pinta_ate(h + Vector2(-230, 110))
	pl.pinta_ate(h + Vector2(150, 110))
	pl.pinta_ate(h + Vector2(150, 230))
	pl.cancel()
	pl.begin("cascalho")
	pl.pinta_ate(h + Vector2(-230, -150))
	pl.pinta_ate(h + Vector2(-230, 90))
	pl.cancel()
	pl.begin("pedra")
	for k in 3:
		pl.pinta_ate(h + Vector2(80, -40 + k * 21))
		pl.pinta_ate(h + Vector2(150, -40 + k * 21))
	pl.cancel()


func _process(delta: float) -> bool:
	t += delta
	if t < 3.0:
		return false
	if not _caminhos_feitos:
		_caminhos_feitos = true
		_pinta_caminhos()
	if not _pendente.is_empty():
		_espera -= delta
		if _espera <= 0.0:
			_foto(_pendente[2])
			_pendente = []
		return false
	if fila.is_empty():
		return true
	_pendente = fila.pop_front()
	_prepara(_pendente)
	_espera = 1.2
	return false


func _prepara(p: Array) -> void:
	var hub = g("village_hub")
	var dn = g("day_night")
	var env = g("environment")
	if int(hub.level) != int(p[0]):
		hub.level = int(p[0])
		if hub.has_method("_grow_to_stage"):
			hub._grow_to_stage(hub._stage_index())
		hub._update_visual()
		if env.has_method("limpa_area_vila"):
			env.limpa_area_vila()
	if dn and dn.has_method("tempo_da_hora"):
		dn.time = dn.tempo_da_hora(float(p[1]))
	var c = main.get_node("Camera2D")
	var z: float = p[3]
	c.set_target_zoom(z)
	c.zoom = Vector2(z, z)
	c.on_view_changed(hub.global_position + (Vector2(0, -60) if z < 1.5 else Vector2(60, 40)))


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [prefixo, nome]))
	print("foto: ", nome)
