extends Node2D
## PROTÓTIPO ROTA A (endurecida) — cena de ESTRESSE (isolada do jogo; F6 nesta cena).
##
## Todos os tipos de prédio do jogo + relevo difícil + 14 ipezinhos passeando. Três jeitos
## de ordenar o desenho, trocados na hora (teclas 1/2/3):
##   1 INGÊNUA  — y_sort com 1 ponto por prédio (o que quebrou no 1º protótipo)
##   2 FATIADA  — y_sort com o fatiamento automático (Iso.slice_rect, pedaços de até N px)
##   3 CAIXAS   — ordem topológica das caixas (Iso.topo_order), sem fatiar nada
## O painel conta, a cada quadro, os pares (ipezinho × coisa) que se sobrepõem na tela e em
## quantos a ordem desenhada está ERRADA comparada com a verdade 3D (Iso.behind).
## Mouse: mostra o que o "raio da câmera" (Iso.pick) acha embaixo do cursor.
##
## Linha de comando (sem janela):  -- bench   imprime os números das 3 ordenações e do clique.
## Teclas: 1/2/3 ordenação • +/- tamanho do pedaço (fatiada) • Tab pegadas • roda/WASD câmera

const Iso := preload("res://prototipos/camera/iso_core.gd")
const World := preload("res://prototipos/camera/estresse_mundo.gd")
const BoxView := preload("res://prototipos/camera/box_view.gd")
const Incremental := preload("res://prototipos/camera/iso_incremental.gd")
const FLOOR := preload("res://assets/game/floor_cave.png")
const SHEETS := [preload("res://assets/game/ipezinho_m0.png"), preload("res://assets/game/ipezinho_engenheiro_f2.png"),
	preload("res://assets/game/ipezinho_guarda_m1.png"), preload("res://assets/game/ipezinho_medico_f3.png")]
const MODE_NAMES := ["INGÊNUA (1 ponto por prédio)", "FATIADA automática", "CAIXAS (ordem topológica completa)", "CAIXAS incremental (produção)"]
const N_WORKERS := 14
var WORKER_SIZE := 12.0
var WORKER_H := 30.0
## Arte nova (linha de comando `arte=minerador`): minerador isométrico de verdade, 4 direções
## de losango (SE/NE desenhadas, SO/NO espelho), âncora fixa por direção, caixa declarada.
const ARTE_DIR := "res://prototipos/camera/arte_iso/minerador/com_picareta/"
const ARTE_ANCORA := {"SE": Vector2(57.7, 100), "NE": Vector2(58.3, 97), "SO": Vector2(53.3, 100), "NO": Vector2(52.7, 97)}
const ARTE_ANG := {"SE": 26.57, "SO": 153.43, "NO": 206.57, "NE": 333.43}
var _arte := false
var _arte_tex := {}  # "SE" -> [Texture2D x4]
var _arte_dir := {}  # Worker -> direção atual
## Casas de verdade (linha de comando `arte=casa`): cada desenho com a SUA caixa declarada
## (arte_iso/casa/contrato_casa.json), âncora no quadro (120, 222) = ponto do chão.
const CASA_DIR := "res://prototipos/camera/arte_iso/casa/"
var _casa := false
var _casa_tex := {}  # nome do desenho -> Texture2D
var _casa_rel := {}  # nome do prédio -> [desenho, pegada relativa à âncora]

var world := World.new()
var mode := 2
var slice_side := 40.0
var _container: Node2D
var _statics: Array = []
var _units: Array = []  # desenhados: [{box, view, name}]
var _wbox := {}  # Worker -> Iso.Box
var _wview := {}  # Worker -> Node2D
var _stats := {}  # categoria -> [pares, erros]
var _frames := 0
var _frames_with_error := 0
var _hud: Label
var _hover := {}
var _angles: Array[float] = []
var _rng := RandomNumberGenerator.new()
var _wander: Array = []
var _inc := Incremental.new()
var _face_miss := {}


func _ready() -> void:
	_rng.seed = 47
	if "arte=minerador" in OS.get_cmdline_user_args():
		_arte = true
		WORKER_SIZE = 28.0  # caixa declarada do minerador (verifica_arte.py): 28 x 28 x 70
		WORKER_H = 70.0
		world.agent_radius = 15.0
		for d in ARTE_ANCORA:
			var fs := []
			for i in 4:
				var img := Image.load_from_file(ProjectSettings.globalize_path(ARTE_DIR + "%s/%d.png" % [d, i]))
				fs.append(ImageTexture.create_from_image(img))
			_arte_tex[d] = fs
	if "arte=casa" in OS.get_cmdline_user_args():
		_casa = true
		var contrato: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CASA_DIR + "contrato_casa.json"))
		var names := ["casa_v0", "casa_v1", "casa_v2", "casa_v3", "obra_1", "obra_2", "obra_3"]
		var over := []
		for i in names.size():
			var n: String = names[i]
			var cx: Dictionary = contrato.caixas[n]
			var rel: Array = cx.pegada_rel_ancora
			var anchor := Vector2(-520 + (i % 4) * 330, -250 + (i / 4) * 360)
			var r := Rect2(anchor + Vector2(rel[0], rel[1]), Vector2(float(rel[2]) - float(rel[0]), float(rel[3]) - float(rel[1])))
			over.append([n, r, float(cx.altura), 0.0])
			_casa_rel[n] = anchor
			_casa_tex[n] = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(CASA_DIR + n + ".png")))
		world.catalog_override = over
	world.build()
	_statics = world.static_boxes()
	_wander = world.wander_points()
	var floor := Node2D.new()
	floor.transform = Transform2D(Vector2(1, 0.5), Vector2(-1, 0.5), Vector2.ZERO)
	floor.z_index = -3000
	add_child(floor)
	var fs := Sprite2D.new()
	fs.texture = FLOOR
	fs.centered = false
	fs.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fs.region_enabled = true
	fs.region_rect = Rect2(Vector2.ZERO, world.bounds.size / 2.0)
	fs.scale = Vector2(2, 2)
	fs.position = world.bounds.position
	floor.add_child(fs)
	var pit_floor := Node2D.new()  # fundo dos buracos (embaixo de tudo, em cima do chão)
	pit_floor.z_index = -2900
	pit_floor.draw.connect(func():
		for p in world.pits:
			var poly := PackedVector2Array()
			for c in Iso.corners(p[1]):
				poly.append(Iso.iso(c, p[2]))
			pit_floor.draw_colored_polygon(poly, Color(0.16, 0.13, 0.14) if p[2] < -60 else Color(0.3, 0.26, 0.24)))
	add_child(pit_floor)
	_container = Node2D.new()
	add_child(_container)
	for i in N_WORKERS:
		var w := World.Worker.new("ipê %d" % i, _wander[_rng.randi() % _wander.size()])
		w.speed = _rng.randf_range(50.0, 80.0)
		world.workers.append(w)
		_wbox[w] = Iso.Box.new(Rect2(), 0, 0, "ipezinho", w.name, w)
		var v := Node2D.new()
		var s := Sprite2D.new()
		s.name = "S"
		if _arte:
			s.texture = _arte_tex.SE[0]
			s.centered = false
			s.offset = -ARTE_ANCORA.SE  # âncora (pés) no ponto do nó
			_arte_dir[w] = "SE"
		else:
			s.texture = SHEETS[i % SHEETS.size()]
			s.hframes = 4
			s.scale = Vector2(2, 2)
			s.offset = Vector2(0, -8.5)
		v.add_child(s)
		_container.add_child(v)
		_wview[w] = v
	_build_views()
	add_child(preload("res://prototipos/camera/proto_camera.gd").new())
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	_hud.add_theme_font_size_override("font_size", 13)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 5)
	layer.add_child(_hud)
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("mode="):
			set_mode(int(a.trim_prefix("mode=")))
	if "bench" in args:
		_run_bench.call_deferred()
	elif "bench_clique" in args:
		_benching = true
		_bench_click.call_deferred()
		get_tree().quit.call_deferred()


func _exit_tree() -> void:
	world.free_nav()


# ------------------------------------------------------------ montar o desenho de cada modo
func set_mode(m: int) -> void:
	mode = m
	_build_views()
	_reset_stats()


func _colors(b) -> Array:
	match b.kind:
		"terreno":
			return [Color(0.4, 0.35, 0.3), Color(0.44, 0.5, 0.33) if b.zt > 0.0 else Color(0.33, 0.29, 0.27)]
		"rampa":
			return [Color(0.4, 0.35, 0.3), Color(0.55, 0.47, 0.36)]
	var h := float(hash(b.name) % 1000) / 1000.0
	return [Color.from_hsv(0.07 + h * 0.08, 0.35, 0.6), Color.from_hsv(0.02 + h * 0.06, 0.55, 0.62)]


func _build_views() -> void:
	for u in _units:
		u.view.queue_free()
	_units.clear()
	var use_key := mode < 2
	_container.y_sort_enabled = use_key
	if mode == 3:
		_inc.build(_statics)
	for b in _statics:
		var parts := [b]
		if mode == 1 and b.kind != "rampa":
			parts = []
			for r in Iso.slice_rect(b.rect, slice_side):
				var piece := Iso.Box.new(r, b.zb, b.zt, b.kind, b.name, b.owner)
				piece.hide = b.hide
				parts.append(piece)
		for p in parts:
			var v: Node2D
			if _casa and _casa_rel.has(b.name):
				# desenho de verdade no lugar das faces (a caixa declarada continua valendo pra ordenar)
				v = Node2D.new()
				v.position = Vector2(Iso.iso(p.rect.get_center()).x, Iso.key(p)) if use_key else Vector2.ZERO
				var spr := Sprite2D.new()
				spr.texture = _casa_tex[b.name]
				spr.centered = false
				spr.offset = -Vector2(120, 222)
				spr.position = Iso.iso(_casa_rel[b.name]) - v.position
				v.add_child(spr)
			else:
				v = BoxView.new()
				var c := _colors(b)
				v.setup(p, c[0], c[1], use_key)
			_container.add_child(v)
			if mode == 3:
				v.z_index = _inc.ranks[p] * Incremental.K - 2000
			_units.append({"box": p, "view": v, "name": b.name})
	for w in _wview:
		_wview[w].z_index = 0


# ------------------------------------------------------------ por quadro
var _benching := false


func _process(delta: float) -> void:
	if _benching:
		return
	_step(delta)
	_update_hud()


func _step(delta: float) -> void:
	for w in world.workers:
		if w.path.is_empty():
			world.send(w, _wander[_rng.randi() % _wander.size()])
	world.tick(delta)
	for w in world.workers:
		var z := world.height_at(w.pos)
		var b: Iso.Box = _wbox[w]
		b.rect = Rect2(w.pos - Vector2.ONE * WORKER_SIZE * 0.5, Vector2.ONE * WORKER_SIZE)
		b.zb = z
		b.zt = z + WORKER_H
		var v: Node2D = _wview[w]
		var s: Sprite2D = v.get_node("S")
		var feet := Iso.iso(w.pos, z)
		if mode >= 2:
			v.position = feet
			s.position = Vector2.ZERO
		else:
			v.position = Vector2(feet.x, Iso.key(b))
			s.position = Vector2(0, feet.y - v.position.y)
		var sv := Iso.iso(w.velocity) - Iso.iso(Vector2.ZERO)
		if _arte:
			if sv.length() > 0.01:
				_arte_dir[w] = _snap4(rad_to_deg(sv.angle()), _arte_dir[w])
			var dn: String = _arte_dir[w]
			s.texture = _arte_tex[dn][int(w.anim) % 4 if w.moving else 0]
			s.offset = -ARTE_ANCORA[dn]
		else:
			s.frame = int(w.anim) % 4 if w.moving else 0
		if sv.length() > 0.01:
			if not _arte:
				s.flip_h = sv.x < 0.0
			_angles.append(rad_to_deg(sv.angle()))
	if mode == 2:
		var all := []
		for u in _units:
			all.append(u.box)
		all.append_array(_wbox.values())
		var order := Iso.topo_order(all)
		var view_of := {}
		for u in _units:
			view_of[u.box] = u.view
		for w in _wbox:
			view_of[_wbox[w]] = _wview[w]
		for i in order.size():
			view_of[order[i]].z_index = i - 2000
	if mode == 3:
		var slots := _inc.place(_wbox.values())
		var by_slot := {}
		for w in _wbox:
			var sl: int = slots[_wbox[w]]
			if not by_slot.has(sl):
				by_slot[sl] = []
			by_slot[sl].append(w)
		var owner_of := {}
		for w in _wbox:
			owner_of[_wbox[w]] = w
		for sl in by_slot:
			var boxes := []
			for w in by_slot[sl]:
				boxes.append(_wbox[w])
			var ordered := _inc.order_within(boxes)
			# todos da mesma vaga no mesmo z; a ordem entre eles é a da árvore (sem limite de
			# quantos cabem numa vaga — antes eram K-2 = 6 e o 7º empatava)
			for i in ordered.size():
				var wv: Node2D = _wview[owner_of[ordered[i]]]
				wv.z_index = sl * Incremental.K + 1 - 2000
				_container.move_child(wv, -1)
	_measure()
	var m := get_global_mouse_position()
	_hover = Iso.pick(m, _statics, world.planes())


## 4 direções de losango com histerese de 15° (não fica trocando andando reto na tela).
func _snap4(ang: float, current: String) -> String:
	var best := current
	var best_e := absf(wrapf(ang - ARTE_ANG[current], -180.0, 180.0)) - 15.0
	for k in ARTE_ANG:
		var e := absf(wrapf(ang - ARTE_ANG[k], -180.0, 180.0))
		if e < best_e:
			best_e = e
			best = k
	return best


## Conta pares ipezinho × coisa que se sobrepõem na tela e se a ordem desenhada bate com a 3D.
func _measure() -> void:
	_frames += 1
	var any_error := false
	var units := []
	for u in _units:
		units.append({"box": u.box, "order": _order_of(u.view), "name": _category(u)})
	for w in _wbox:
		units.append({"box": _wbox[w], "order": _order_of(_wview[w]), "name": "ipezinho × ipezinho", "w": true})
	for a in units:
		if not a.has("w"):
			continue
		var ra := Iso.screen_rect(a.box)
		var sa := Iso.silhouette(a.box)
		for b in units:
			if b == a or (b.has("w") and b.box.name < a.box.name):
				continue
			if not ra.intersects(Iso.screen_rect(b.box)):
				continue
			if Geometry2D.intersect_polygons(sa, Iso.silhouette(b.box)).is_empty():
				continue
			var truth = Iso.behind(a.box, b.box)
			if truth == null:
				continue
			var drawn_first: bool = _before(a.order, b.order)
			var st: Array = _stats.get(b.name, [0, 0])
			st[0] += 1
			if drawn_first != truth:
				st[1] += 1
				any_error = true
			_stats[b.name] = st
	if any_error:
		_frames_with_error += 1


func _order_of(v: Node2D) -> Array:
	if mode >= 2:
		return [float(v.z_index), float(v.get_index()) if mode == 3 else 0.0]
	return [v.position.y, float(v.get_index())]  # y_sort: chave, empate pela ordem na árvore


func _before(a: Array, b: Array) -> bool:
	return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])


func _category(u: Dictionary) -> String:
	var n: String = u.name
	if n.begins_with("beira") or n.begins_with("parede"):
		return "beiras de buraco (galeria/abismo)"
	if u.box.kind == "rampa":
		return "rampas/escadas"
	if n.begins_with("Platô"):
		return "platôs"
	if n.begins_with("Centro"):
		return n
	return n


func _reset_stats() -> void:
	_stats.clear()
	_frames = 0
	_frames_with_error = 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: set_mode(0)
			KEY_2: set_mode(1)
			KEY_3: set_mode(2)
			KEY_4: set_mode(3)
			KEY_EQUAL, KEY_KP_ADD:
				slice_side = minf(slice_side + 8.0, 96.0)
				set_mode(mode)
			KEY_MINUS, KEY_KP_SUBTRACT:
				slice_side = maxf(slice_side - 8.0, 8.0)
				set_mode(mode)


func _update_hud() -> void:
	var pairs := 0
	var errs := 0
	for k in _stats:
		pairs += _stats[k][0]
		errs += _stats[k][1]
	var worst := []
	for k in _stats:
		if _stats[k][1] > 0:
			worst.append([k, _stats[k][1], _stats[k][0]])
	worst.sort_custom(func(x, y): return x[1] > y[1])
	var lines := ["ROTA A — ESTRESSE  (protótipo, caixas provisórias)",
		"ordenação: %s%s   (1/2/3 troca%s)" % [MODE_NAMES[mode], (" — pedaços de até %d px" % slice_side) if mode == 1 else "", ", +/- pedaço" if mode == 1 else ""],
		"pares ipezinho×coisa sobrepostos: %d   ordem ERRADA: %d (%.1f%%)   quadros com erro visível: %d de %d" % [
			pairs, errs, 100.0 * errs / maxf(pairs, 1.0), _frames_with_error, _frames]]
	for x in worst.slice(0, 5):
		lines.append("   erra em: %s  %d/%d" % x)
	var h := "mouse: "
	match _hover.get("what", "nada"):
		"topo": h += "topo de %s (z %d)" % [_hover.box.name, _hover.z]
		"face": h += "FACE de %s (z %d) — clique = pé da parede" % [_hover.box.name, _hover.z]
		"plano": h += "%s (z %d)" % [_hover.plane.name, _hover.z]
		_: h += "nada"
	lines.append(h)
	_hud.text = "\n".join(lines)


# ------------------------------------------------------------ bench (linha de comando)
func _run_bench() -> void:
	_benching = true
	var dt := 1.0 / 20.0
	print("=== ORDENAÇÃO: %d ipezinhos, %d caixas fixas, 60 s simulados por modo ===" % [N_WORKERS, _statics.size()])
	for cfg in [[0, 40.0], [1, 64.0], [1, 40.0], [1, 24.0], [1, 12.0], [2, 40.0], [3, 40.0]]:
		slice_side = cfg[1]
		set_mode(cfg[0])
		_rng.seed = 47
		var busy := 0.0
		for i in 1200:
			var t1 := Time.get_ticks_usec()
			_step(dt)
			busy += Time.get_ticks_usec() - t1
			await get_tree().process_frame  # a navegação do Godot sincroniza entre quadros
		var ms := busy / 1000.0 / 1200.0
		var pairs := 0
		var errs := 0
		for k in _stats:
			pairs += _stats[k][0]
			errs += _stats[k][1]
		print("\n%s%s: pares %d, ERRADOS %d (%.2f%%), quadros com erro %d/%d, %d nós desenhados, %.2f ms/quadro" % [
			MODE_NAMES[mode], (" até %d px" % slice_side) if mode == 1 else "", pairs, errs, 100.0 * errs / maxf(pairs, 1.0),
			_frames_with_error, _frames, _units.size() + N_WORKERS, ms])
		var keys := _stats.keys()
		keys.sort()
		for k in keys:
			if _stats[k][1] > 0:
				print("   %-40s %4d errados de %5d" % [k, _stats[k][1], _stats[k][0]])
	_bench_directions()
	_bench_click()
	_bench_scale()
	get_tree().quit()


## Custo com o tamanho do jogo de verdade: + N enfeites fixos (árvore/pedra/jazida/tocha) e
## M ipezinhos/criaturas andando. Ordem completa (todos × todos) × incremental.
func _bench_scale() -> void:
	print("
=== CUSTO DA ORDEM POR CAIXAS (GDScript, por quadro) ===")
	for cfg in [[150, 20], [400, 40], [800, 60]]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var statics := _statics.duplicate()
		while statics.size() < _statics.size() + cfg[0]:
			var p := Vector2(rng.randf_range(world.bounds.position.x, world.bounds.end.x), rng.randf_range(world.bounds.position.y, world.bounds.end.y))
			var r := Rect2(p, Vector2(16, 16))
			if _statics.any(func(b): return b.rect.intersects(r)):
				continue
			statics.append(Iso.Box.new(r, world.height_at(p), world.height_at(p) + rng.randf_range(10, 48), "enfeite", "enfeite"))
		var dyn := []
		for i in cfg[1]:
			var p := Vector2(rng.randf_range(world.bounds.position.x, world.bounds.end.x), rng.randf_range(world.bounds.position.y, world.bounds.end.y))
			dyn.append(Iso.Box.new(Rect2(p, Vector2(12, 12)), 0.0, 30.0, "ipezinho", "d"))
		var all := statics + dyn
		var t0 := Time.get_ticks_usec()
		for i in 3:
			Iso.topo_order(all)
		var full := (Time.get_ticks_usec() - t0) / 3000.0
		var inc := Incremental.new()
		t0 = Time.get_ticks_usec()
		inc.build(statics)
		var build_ms := (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		for i in 20:
			inc.place(dyn)
		var place_ms := (Time.get_ticks_usec() - t0) / 20000.0
		print("   %4d fixas + %2d andando: ordem completa %7.1f ms/quadro | incremental %5.2f ms/quadro (+ %6.1f ms uma vez, ao construir/demolir)" % [
			statics.size(), dyn.size(), full, place_ms, build_ms])


## Pra onde os ipezinhos andam NA TELA (decide 4 × 8 direções).
func _bench_directions() -> void:
	var dirs8 := [0.0, 26.57, 90.0, 153.43, 180.0, 206.57, 270.0, 333.43]  # 8 = eixos + diagonais do chão
	var diag4 := [26.57, 153.43, 206.57, 333.43]  # 4 "de losango" (eixos do chão)
	var card4 := [0.0, 90.0, 180.0, 270.0]  # 4 "de tela" (diagonais do chão)
	var err := func(a: float, set: Array) -> float:
		var best := 999.0
		for d in set:
			best = minf(best, absf(wrapf(a - d, -180.0, 180.0)))
		return best
	var sums := [0.0, 0.0, 0.0]
	var bad := [0, 0, 0]
	for a in _angles:
		var e := [err.call(a, dirs8), err.call(a, diag4), err.call(a, card4)]
		for i in 3:
			sums[i] += e[i]
			if e[i] > 30.0:
				bad[i] += 1
	var n := maxf(_angles.size(), 1.0)
	print("\n=== DIREÇÕES (%d amostras de movimento na tela) ===" % _angles.size())
	print("   8 direções:                erro médio %.1f°, >30° em %.1f%%" % [sums[0] / n, 100.0 * bad[0] / n])
	print("   4 de losango (eixos chão): erro médio %.1f°, >30° em %.1f%%" % [sums[1] / n, 100.0 * bad[1] / n])
	print("   4 de tela (cima/baixo/lados): erro médio %.1f°, >30° em %.1f%%" % [sums[2] / n, 100.0 * bad[2] / n])


## Clique: amostra a tela inteira; a VERDADE é a última face desenhada embaixo do ponto (na
## ordem topológica, sem ipezinhos). Compara "prioridade ao topo" (1º protótipo) e o raio.
func _bench_click() -> void:
	var order := Iso.topo_order(_statics)
	var faces := []
	for b in order:
		var f := BoxView.faces(b)
		for k in ["top", "left", "right"]:
			if f[k].size() >= 3:
				faces.append({"poly": f[k], "box": b, "face": k, "rect": _poly_rect(f[k])})
	var planes := world.planes()
	var levels := [72.0, 54.0, 36.0, 0.0, -36.0, -110.0]
	var area := Rect2()
	for b in _statics:
		area = area.merge(Iso.screen_rect(b)) if area.has_area() else Iso.screen_rect(b)
	var per := {}  # categoria -> [n, v1 certos, raio certos]
	var y := area.position.y
	while y < area.end.y:
		var x := area.position.x
		while x < area.end.x:
			var m := Vector2(x, y)
			var truth := _truth_at(m, faces, planes)
			if truth.is_empty():
				x += 10.0
				continue
			var cat := _click_category(truth)
			var v1 := _pick_v1(m, levels)
			var v2 := Iso.pick(m, _statics, planes)
			if cat == "face de penhasco / beira" and not _same(truth, v2):
				var desc := "%s -> %s" % [truth.box.name, (v2.box.name + " " + v2.what) if v2.has("box") else v2.get("plane", {}).get("name", v2.what)]
				_face_miss[desc] = _face_miss.get(desc, 0) + 1
			var st: Array = per.get(cat, [0, 0, 0])
			st[0] += 1
			if _same(truth, v1):
				st[1] += 1
			if _same(truth, v2):
				st[2] += 1
			per[cat] = st
			x += 10.0
		y += 10.0
	print("\n=== CLIQUE (tela amostrada a cada 10 px; verdade = o que está desenhado por cima) ===")
	print("   %-34s %6s  %-18s %-18s" % ["onde o mouse está", "pontos", "prioridade ao topo", "raio da câmera"])
	var keys := per.keys()
	keys.sort()
	for k in keys:
		var st: Array = per[k]
		print("   %-34s %6d  %6.1f%%            %6.1f%%" % [k, st[0], 100.0 * st[1] / st[0], 100.0 * st[2] / st[0]])
	var miss := _face_miss.keys()
	miss.sort_custom(func(a, b): return _face_miss[a] > _face_miss[b])
	print("   faces que o raio erra (verdade -> raio):")
	for k in miss.slice(0, 8):
		print("      %4d  %s" % [_face_miss[k], k])


func _poly_rect(p: PackedVector2Array) -> Rect2:
	var r := Rect2(p[0], Vector2.ZERO)
	for q in p:
		r = r.expand(q)
	return r


func _truth_at(m: Vector2, faces: Array, planes: Array) -> Dictionary:
	var hit := {}
	for f in faces:
		if f.rect.has_point(m) and Geometry2D.is_point_in_polygon(m, f.poly):
			hit = {"what": "topo" if f.face == "top" else "face", "box": f.box}
	if not hit.is_empty():
		return hit
	# nenhuma caixa: o plano desenhado por cima (fundo de buraco vem depois do chão)
	for i in range(planes.size() - 1, -1, -1):
		var p: Dictionary = planes[i]
		var g := Iso.iso_inv(m, p.z)
		if p.rect.has_point(g) and not p.holes.any(func(h): return h.has_point(g)):
			return {"what": "plano", "plane": p}
	return {}


func _click_category(t: Dictionary) -> String:
	if t.what == "plano":
		return "chão" if t.plane.name == "chão" else t.plane.name
	var b = t.box
	if b.kind == "predio":
		return "prédio (qualquer face)"
	if b.kind == "rampa":
		return "rampa/escada"
	if t.what == "face":
		return "face de penhasco / beira"
	return "topo de " + ("platô" if b.name.begins_with("Platô") else "beira de buraco (chão)")


## Regra do 1º protótipo: prédio pela silhueta (o da frente); senão a altura mais alta que bate.
func _pick_v1(m: Vector2, levels: Array) -> Dictionary:
	var best = null
	for b in _statics:
		if b.kind == "predio" and Geometry2D.is_point_in_polygon(m, Iso.silhouette(b)):
			if best == null or Iso.key(b) > Iso.key(best):
				best = b
	if best != null:
		return {"what": "topo", "box": best}
	for z in levels:
		var g := Iso.iso_inv(m, z)
		if not world.bounds.has_point(g) or absf(world.height_at(g) - z) > 0.5:
			continue
		for b in _statics:
			if b.kind != "predio" and absf(b.zt - z) < 0.5 and b.rect.has_point(g):
				return {"what": "topo", "box": b}
		for p in world.planes():
			if absf(p.z - z) < 0.5 and p.rect.has_point(g):
				return {"what": "plano", "plane": p}
	return {"what": "nada"}


func _same(t: Dictionary, r: Dictionary) -> bool:
	if r.get("what", "nada") == "nada":
		return false
	if t.what == "plano":
		return r.what == "plano" and r.plane.name == t.plane.name
	if not r.has("box"):
		return false
	if t.box.kind == "predio":
		return r.box == t.box
	return r.box == t.box and (r.what == "face") == (t.what == "face")
