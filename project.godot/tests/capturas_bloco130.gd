extends SceneTree
## Bloco 130 (não é teste: não dá OK/FALHOU): o FLICKER do Armazém e do Centro da Vila. Roda COM JANELA e com APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_bloco130.gd -- <pasta de saída> [segundos]
## Põe a câmera nos dois prédios com gente passando e depositando minério, e a CADA QUADRO guarda a assinatura de tudo que o
## espelho do prédio desenha (cada sprite: textura, quadro, modulate, posição, z_index, visível) mais a camada de arte e a
## luz. Quando a assinatura muda ele salva o PNG do quadro e escreve o que mudou (diff.txt).
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var duracao := 40.0
var alvos := {}  # nome -> Node (o prédio de verdade)
var ultimo := {}  # nome -> assinatura (Dictionary caminho -> texto)
var trocas := {}  # nome -> quantas vezes mudou
var log_diff: Array[String] = []
var quadro := 0
var fotos := 0
var cam_alvo := ""


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas")
	if args.size() > 1:
		duracao = float(args[1])
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func _process(delta: float) -> bool:
	t += delta
	quadro += 1
	if step == 0 and t > 2.5:
		step = 1
		_prepara()
	elif step == 1:
		_amostra()
		if t > 2.5 + 2.0 + duracao:
			_fim()
			return true
	return false


func _prepara() -> void:
	var arm := get_first_node_in_group("armazens")
	var hub := get_first_node_in_group("village_hub")
	alvos = {"armazem": arm, "centro": hub}
	# gente passando e depositando: todos mineradores (levam minério pro armazém) e uns passeando pelo centro
	var ws := get_nodes_in_group("ipezinhos")
	for w in ws:
		w.set_job("minerador")
	var cam = main.get_node("Camera2D")
	cam.set_target_zoom(2.0)
	cam.zoom = Vector2(2.0, 2.0)
	cam_alvo = "armazem"
	cam.on_view_changed(arm.global_position)
	Engine.time_scale = 3.0
	print("preparado: armazém em %s, centro em %s" % [arm.global_position, hub.global_position])


## A assinatura do espelho de um prédio: tudo que ele desenha agora.
func _assinatura(src: Node) -> Dictionary:
	var iso := get_first_node_in_group("iso_view")
	var out := {}
	var bb: Node2D = iso.billboard_of(src) if iso else null
	if bb == null:
		out["sem_espelho"] = "1"
		return out
	var ord = iso.get("_order")
	if ord != null:
		out["ordem.reparos"] = str(ord.repairs)
		out["ordem.reconstrucoes"] = str(ord.full_rebuilds)
		out["ordem.versao"] = str(ord.version)
	out["bb.visible"] = str(bb.visible)
	out["bb.pos"] = str(bb.position)
	out["bb.z"] = str(bb.z_index)
	out["bb.mod"] = str(bb.modulate)
	out["bb.scale"] = str(bb.scale)
	out["art_key"] = String(bb.get("_art_key"))
	var pilha: Array = [[bb, "bb"]]
	while not pilha.is_empty():
		var par: Array = pilha.pop_back()
		var n: Node = par[0]
		var cam_n: String = par[1]
		for c in n.get_children():
			var p: String = cam_n + "/" + String(c.name)
			if c is CanvasItem:
				var ci := c as CanvasItem
				out[p + ".vis"] = str(ci.visible)
				out[p + ".mod"] = str(ci.modulate) + "|" + str(ci.self_modulate)
				out[p + ".z"] = str(ci.z_index)
			if c is Node2D:
				out[p + ".pos"] = str((c as Node2D).position)
			if c is Sprite2D:
				var sp := c as Sprite2D
				out[p + ".tex"] = (sp.texture.resource_path.get_file() if sp.texture else "-") + "#" + str(sp.frame)
			if c is PointLight2D:
				out[p + ".luz"] = "%s|%.2f" % [(c as PointLight2D).enabled, (c as PointLight2D).energy]
			pilha.append([c, p])
	return out


var _deposito_t := 0.0


## Simula os depósitos de minério (o popup "+N", o pulinho e a pilha do armazém crescendo) a cada segundo.
func _deposita(delta: float) -> void:
	_deposito_t += delta
	if _deposito_t < 1.0:
		return
	_deposito_t = 0.0
	var arm: Node = alvos["armazem"]
	arm.stock["ferro"] = float(arm.stock.get("ferro", 0.0)) + 6.0
	arm._recount()
	arm.show_popup("+6", Color(0.9, 0.8, 0.4))


func _amostra() -> void:
	_deposita(1.0 / 60.0 * Engine.time_scale)
	# alterna a câmera entre os dois prédios a cada 12 s (cada um com a janela de tempo dele)
	var fase := int((t - 4.5) / 12.0) % 2
	var quer := "armazem" if fase == 0 else "centro"
	if quer != cam_alvo:
		cam_alvo = quer
		main.get_node("Camera2D").on_view_changed((alvos[quer] as Node2D).global_position)
	for nome in alvos:
		var src: Node = alvos[nome]
		if not is_instance_valid(src):
			continue
		var sig := _assinatura(src)
		var ant: Dictionary = ultimo.get(nome, {})
		if not ant.is_empty() and sig != ant:
			var diffs: Array[String] = []
			for k in sig:
				if str(ant.get(k, "<novo>")) != str(sig[k]):
					diffs.append("%s: %s -> %s" % [k, ant.get(k, "<novo>"), sig[k]])
			for k in ant:
				if not sig.has(k):
					diffs.append("%s: %s -> <sumiu>" % [k, ant[k]])
			trocas[nome] = int(trocas.get(nome, 0)) + 1
			var linha := "q%d t=%.2f %s (%s) | %s" % [quadro, t, nome, cam_alvo, " ; ".join(diffs)]
			log_diff.append(linha)
			if fotos < 40 and nome == cam_alvo:
				fotos += 1
				root.get_texture().get_image().save_png(out_dir.path_join("%s_q%05d.png" % [nome, quadro]))
		ultimo[nome] = sig


func _fim() -> void:
	Engine.time_scale = 1.0
	var f := FileAccess.open(out_dir.path_join("diff.txt"), FileAccess.WRITE)
	f.store_string("quadros=%d tempo=%.1f\n" % [quadro, t])
	for nome in alvos:
		f.store_string("%s: %d mudanças de assinatura\n" % [nome, int(trocas.get(nome, 0))])
	for l in log_diff:
		f.store_string(l + "\n")
	f.close()
	print("FIM: quadros=%d" % quadro)
	for nome in alvos:
		print("%s: %d mudanças" % [nome, int(trocas.get(nome, 0))])
