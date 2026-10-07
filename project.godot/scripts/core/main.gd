extends Node2D
## Cena principal: entrada do jogador (seleção, ordens, atalhos) e início da partida.
##
## Seleção (estilo RTS):
##   clique esquerdo num ipezinho   -> seleciona só ele
##   clique esquerdo no chão vazio  -> solta a seleção
##   arrastar com o esquerdo        -> seleciona todos dentro do retângulo
##   Shift + clique / arrasto       -> soma/tira da seleção atual sem perder os outros
## Ordens (botão direito, pra todos os selecionados, usando a ordem manual de cada um):
##   numa jazida  -> todos vão minerar lá, espalhados em volta dela
##   no chão      -> todos andam pra lá em formação (sem empilhar no mesmo pixel)

signal selection_changed(unit: Node2D)

const Teclas := preload("res://scripts/core/teclas.gd")
const SELECT_RADIUS := 22.0
const MARKER_TIME := 0.6
## Quanto (px de tela) o mouse precisa andar com o botão apertado pra virar arrasto.
const DRAG_THRESHOLD := 6.0
## Distância entre ipezinhos na formação de uma ordem de grupo.
const FORMATION_SPACING := 18.0
## Raio (px do mundo) em volta de uma jazida que conta como "clicou na jazida".
const ORE_CLICK_RADIUS := 30.0
## Constantes de função (job) do ipezinho — Bloco 25.
const Worker := preload("res://scripts/workers/ipezinho.gd")
## Prompt 28: a vista isométrica.
const IsoView := preload("res://scripts/iso/iso_view.gd")

## Bloco 37: partida nova começa com a FUNDAÇÃO (o jogador escolhe onde ficam o Centro da
## Vila e o Armazém; ver founding.gd). false = começa com o layout da cena (testes).
@export var founding_on_new_game: bool = true

## Ipezinhos selecionados (a ordem importa pro Tab no modo grupo).
var selection: Array[Node2D] = []
## Selecionado "principal" (o único, ou o primeiro do grupo): F segue ele.
var selected: Node2D:
	get:
		_prune_selection()
		return selection[0] if not selection.is_empty() else null

var _marker_pos := Vector2.ZERO
var _marker_timer := 0.0
var _lmb_down := false
var _dragging := false
var _press_screen := Vector2.ZERO
var _press_world := Vector2.ZERO
var _drag_world := Vector2.ZERO  # ponto atual do arrasto (mundo)
var _additive := false  # Shift segurado no clique/arrasto atual
var _box_drawer: Node2D
var _group_focus := 0  # Tab no modo grupo: qual deles a câmera mostra
var _pause: CanvasLayer
var _founding: Node
## Prompt 28: vista isométrica. A lógica continua no chão cartesiano. (Prompt 29: o F3 saiu;
## a vista de cima ficou só pro mapa antigo e pros testes.)
var _iso: Node2D
var _press_canvas := Vector2.ZERO  # ponto do clique no canvas (na vista iso = tela isométrica)
var _drag_canvas := Vector2.ZERO

@onready var _camera: Camera2D = $Camera2D
@onready var _environment: Node2D = $World/Environment
@onready var _economy: Node = $Economy
@onready var _day_night: Node = $DayNight
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	add_to_group("game_main")
	_camera.bounds = _environment.world_rect()
	# retângulo da seleção por arrasto: desenhado por cima de tudo do mundo
	_box_drawer = Node2D.new()
	_box_drawer.name = "SelectionBox"
	_box_drawer.z_index = 50
	_box_drawer.draw.connect(_draw_box)
	add_child(_box_drawer)
	# Prompt 28: a vista isométrica
	_iso = IsoView.new()
	add_child(_iso)
	_iso.setup(self)
	_box_drawer.visibility_layer = IsoView.LAYER_ISO  # o retângulo é da tela, fora da textura do chão
	# Prompt 29: com o mapa novo a vista iso é A vista do jogo (o F3, que voltava pra de cima pra
	# conferir, saiu no fim do Prompt 29). DEEP_IRON_ISO=0 começa na de cima (só testes); =1 força a iso.
	var iso_env := OS.get_environment("DEEP_IRON_ISO")
	if iso_env == "1" or (iso_env != "0" and _environment.has_method("has_iso_map") and _environment.has_iso_map()):
		_iso.set_enabled.call_deferred(true)
	# Bloco 77: as áreas de trabalho (antes do save: os ipezinhos religam nelas)
	var areas := preload("res://scripts/core/work_areas.gd").new()
	areas.name = "WorkAreas"
	add_child(areas)
	# Bloco 89: os caminhos pintados (antes do save)
	var caminhos := preload("res://scripts/core/caminhos.gd").new()
	caminhos.name = "Caminhos"
	add_child(caminhos)
	# modo de posicionar casa (último filho: recebe o input antes do main e o "consome")
	add_child(preload("res://scripts/core/house_placer.gd").new())
	add_child(preload("res://scripts/core/area_placer.gd").new())  # Bloco 77: marcar área (idem)
	add_child(preload("res://scripts/core/caminho_placer.gd").new())  # Bloco 89: pintar caminhos (idem)
	var decor := preload("res://scripts/core/decoracoes.gd").new()  # Bloco 90: decoração (modo remover: idem)
	decor.name = "Decoracoes"
	add_child(decor)
	_pause = preload("res://scripts/ui/pause_menu.gd").new()
	add_child(_pause)
	_founding = preload("res://scripts/core/founding.gd").new()
	_founding.name = "Founding"
	add_child(_founding)
	# Bloco 40: clima visual da clareira (folhas, neve, chuva, pólen)
	var weather := preload("res://scripts/core/weather.gd").new()
	weather.name = "Weather"
	add_child(weather)
	# Bloco 70: o conteúdo do S2/S3 (poças, ventiladores, cristais da broca)
	var fundo := preload("res://scripts/core/fundo.gd").new()
	fundo.name = "Fundo"
	add_child(fundo)
	SaveManager.register_game(self)
	if SaveManager.pending_load:
		# espera o ambiente montar (1 frame + navegação) e as estruturas entrarem nos grupos
		await _environment.navigation_ready
		SaveManager.apply_pending(self)
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub and not hub.founded:
			_founding.start(false)  # salvo no meio da fundação: volta a escolher
	elif founding_on_new_game:
		var ofi := get_tree().get_first_node_in_group("oficina")
		if ofi and ofi.has_method("set_built"):
			ofi.set_built(false)  # Bloco 58: jogo novo — a Oficina é construída pelo engenheiro
		await _environment.navigation_ready
		_founding.start(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_lmb_down = true
				_dragging = false
				_press_screen = event.position
				_press_world = _to_world(event.position)
				_drag_world = _press_world
				_press_canvas = _to_canvas(event.position)
				_drag_canvas = _press_canvas
				_additive = event.shift_pressed
			elif _lmb_down:
				_drag_world = _to_world(event.position)
				_drag_canvas = _to_canvas(event.position)
				_additive = _additive or event.shift_pressed
				_finish_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var hit_ore: Node2D = null
			if _iso.enabled:
				var hit: Dictionary = _iso.pick(_to_canvas(event.position))
				if hit.node and hit.node.is_in_group("minerios"):
					hit_ore = hit.node
			_give_order(_to_world(event.position), hit_ore)
	elif event is InputEventMouseMotion and _lmb_down:
		_drag_world = _to_world(event.position)
		_drag_canvas = _to_canvas(event.position)
		if not _dragging and event.position.distance_to(_press_screen) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			_box_drawer.queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		# Bloco 54: as teclas são remapeáveis (Configurações > Teclas): pergunta a AÇÃO da tecla
		match Teclas.acao(event.physical_keycode):
			"proximo":
				_select_next()
			"pessoas":
				_hud.toggle_pessoas()  # Bloco 95: a lista da força de trabalho (aba fina)
			"seguir":
				if selected:
					_camera.follow_target = null if _camera.follow_target == selected else selected
			"voltar":
				# Esc fecha o que estiver aberto; sem nada pra fechar/soltar, pausa
				if _hud.close_panels():
					pass
				elif not selection.is_empty():
					select(null)
				else:
					_pause.open()
			"pausa":
				_pause.open()
			"dicas":
				_hud.toggle_hints()
			"painel_hub":
				_hud.toggle_panel("hub")
			"painel_escavadeira":
				_hud.toggle_panel("escavadeira")
			"painel_oficina":
				_hud.toggle_panel("oficina")
			"painel_enfermaria":
				_hud.toggle_panel("enfermaria")
			"painel_moral":
				_hud.toggle_panel("moral")
			"painel_defesa":
				_hud.toggle_panel("defesa")
			"painel_diario":
				_hud.toggle_panel("diario")
			"guarda":
				toggle_guard()
			"fundidor":
				toggle_smelter()
			"ferreiro":
				toggle_smith()
			"padre":
				toggle_priest()
			"carpinteiro":
				toggle_carpenter()
			"pesquisador":
				toggle_research()
			"painel_lab":
				_hud.toggle_panel("lab")
			"painel_sol":
				_hud.toggle_panel("sol")
			"painel_trabalho":
				_hud.toggle_panel("trabalho")  # Bloco 77
			"vender":
				_economy.sell_all()
			"recrutar":
				var worker: Node2D = _economy.recruit()
				if worker:
					_camera.focus_on(worker.global_position)
			"construir":
				_hud.toggle_build_menu()  # Bloco 46: menu de construção
			"musica":
				Audio.toggle_music()
			"caixas":
				if _iso.enabled:
					_iso.show_boxes = not _iso.show_boxes  # Prompt 28: mostra as caixas
			"salvar":
				SaveManager.save_game("manual")
			"carregar":
				if SaveManager.has_save():
					SaveManager.load_game()
				else:
					Audio.error()
			"pular_fase":
				_day_night.skip_phase()
			"turno_extra":
				toggle_overtime()
			"cozinheiro":
				toggle_cook()
			"lenhador":
				toggle_lumber()
			"minerador":
				toggle_miner()
			"cacador":
				toggle_hunter()
			"medico":
				toggle_doctor()
			"engenheiro":
				toggle_engineer()
			"sem_funcao":
				clear_job()
			"machucar":
				for unit in selection.duplicate():
					if is_instance_valid(unit):
						unit.hurt("mina", "grave" if event.shift_pressed else "")


# ------------------------------------------------------------ clique / arrasto (botão esquerdo)
func _finish_left_click() -> void:
	_lmb_down = false
	var additive := _additive or Input.is_key_pressed(KEY_SHIFT)
	if _dragging:
		_dragging = false
		_box_drawer.queue_redraw()
		_box_select(_selection_rect(), additive)
		return

	if _iso.enabled:
		_finish_left_click_iso(additive)
		return
	var click_pos := _press_world
	var clicked_unit := _find_ipezinho_at(click_pos)
	if clicked_unit:
		if additive:
			toggle_selected(clicked_unit)
		else:
			select(clicked_unit)
		return
	if not additive:
		for building in get_tree().get_nodes_in_group("clickable"):
			if building.contains_point(click_pos):
				_hud.open_panel_for(building)
				return
		if selection.is_empty() and _open_area_at(click_pos):
			return
		select(null)  # chão vazio: solta todo mundo


## Prompt 28: clique na vista iso = o RAIO DA CÂMERA (a 1ª coisa que ele acerta é a que se
## vê). Ipezinho tem uma folga (SELECT_RADIUS na tela) porque a caixa dele é fina.
func _finish_left_click_iso(additive: bool) -> void:
	var hit: Dictionary = _iso.pick(_press_canvas)
	var node: Node2D = hit.node
	var clicked_unit: Node2D = node if node and node.is_in_group("ipezinhos") else _find_ipezinho_at_canvas(_press_canvas)
	if clicked_unit:
		if additive:
			toggle_selected(clicked_unit)
		else:
			select(clicked_unit)
		return
	if not additive:
		if node and node.is_in_group("clickable"):
			_hud.open_panel_for(node)
			return
		if selection.is_empty() and _open_area_at(_press_world):
			return
		select(null)


## Bloco 77: clique no chão de uma área de trabalho (sem ninguém selecionado) abre a janela nela.
func _open_area_at(pos: Vector2) -> bool:
	var wa := get_tree().get_first_node_in_group("work_areas")
	var a = wa.area_em(pos) if wa else null
	if a == null:
		return false
	_hud.open_panel("trabalho")
	var panel = _hud._panels.get("trabalho")
	if panel:
		panel.focus_area(a)
	return true


func _find_ipezinho_at_canvas(canvas_pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := SELECT_RADIUS
	for ip in get_tree().get_nodes_in_group("ipezinhos"):
		if not ip.visible:
			continue
		var d: float = (_iso.to_screen(ip.global_position) + Vector2(0, -14)).distance_to(canvas_pos)
		if d <= best_dist:
			best_dist = d
			best = ip
	return best


func _selection_rect() -> Rect2:
	if _iso.enabled:
		return Rect2(_press_canvas, _drag_canvas - _press_canvas).abs()  # retângulo na TELA
	return Rect2(_press_world, _drag_world - _press_world).abs()


## Posição de um evento de mouse (tela) -> mundo, levando em conta câmera e zoom.
## Prompt 28: na vista iso, o ponto do CHÃO embaixo do mouse (raio da câmera).
func _to_world(screen_pos: Vector2) -> Vector2:
	var canvas := _to_canvas(screen_pos)
	if _iso and _iso.enabled:
		return _iso.ground_at(canvas)
	return canvas


## Tela -> canvas (com câmera e zoom). Na vista de cima é o próprio chão.
func _to_canvas(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func _box_select(rect: Rect2, additive: bool) -> void:
	var picked: Array[Node2D] = []
	if additive:
		picked.assign(selection)
	for ip in get_tree().get_nodes_in_group("ipezinhos"):
		# conta o meio do corpo (a origem fica no pé), igual ao clique
		var body: Vector2 = (_iso.to_screen(ip.global_position) if _iso.enabled else ip.global_position) + Vector2(0, -14)
		if rect.has_point(body) and not picked.has(ip):
			picked.append(ip)
	set_selection(picked)


func _draw_box() -> void:
	if not _dragging:
		return
	var r := _selection_rect()
	var w := 1.5 / _camera.zoom.x  # linha com a mesma espessura em qualquer zoom
	_box_drawer.draw_rect(r, Color(1.0, 0.84, 0.25, 0.12), true)
	_box_drawer.draw_rect(r, Color(1.0, 0.84, 0.25, 0.9), false, w)


# ------------------------------------------------------------ ordens (botão direito)
func _give_order(pos: Vector2, ore_hint: Node2D = null) -> void:
	_prune_selection()
	if selection.is_empty():
		return
	var ore := ore_hint if ore_hint else _find_ore_at(pos)
	if ore:
		_order_mine(ore)
	else:
		_order_move(pos.clamp(_environment.world_rect().position, _environment.world_rect().end))


## Todos vão pra jazida, cada um num ponto diferente da elipse em volta dela
## (dentro da área de trabalho: quem para ali minera enquanto dura a ordem manual).
func _order_mine(ore: Node2D) -> void:
	var n := selection.size()
	var radius: Vector2 = ore.slot_radius
	# começa pelo lado de onde o grupo vem, pra ninguém dar a volta na pedra à toa
	var center := Vector2.ZERO
	for unit in selection:
		center += unit.global_position
	var start := (center / n - ore.global_position).angle()
	var per_ring := 8
	for i in n:
		var ring := int(float(i) / per_ring)
		var count := mini(per_ring, n - ring * per_ring)
		var a := start + TAU * float(i % per_ring) / float(count) + ring * 0.4
		var r := radius * (1.0 + ring * 0.35)
		selection[i].move_to(ore.global_position + Vector2(cos(a) * r.x, sin(a) * r.y))
	_show_marker(ore.global_position)


## Todos andam pro ponto em formação espiral: o mais perto do destino fica no centro.
func _order_move(target: Vector2) -> void:
	var units := selection.duplicate()
	units.sort_custom(func(a, b): return a.global_position.distance_squared_to(target) < b.global_position.distance_squared_to(target))
	for i in units.size():
		var offset := Vector2.ZERO
		if i > 0:
			# espiral de "girassol": pontos bem distribuídos sem grade
			offset = Vector2.RIGHT.rotated(i * 2.39996) * FORMATION_SPACING * sqrt(float(i))
		var p: Vector2 = (target + offset).clamp(_environment.world_rect().position, _environment.world_rect().end)
		units[i].move_to(p)
	_show_marker(target)


func _find_ore_at(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := ORE_CLICK_RADIUS
	for node in get_tree().get_nodes_in_group("minerios"):
		var d: float = (node.global_position + Vector2(0, -10)).distance_to(pos)
		if d <= best_dist:
			best_dist = d
			best = node
	return best


func _show_marker(pos: Vector2) -> void:
	_marker_pos = pos
	_marker_timer = MARKER_TIME


# ------------------------------------------------------------ seleção
func _find_ipezinho_at(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := SELECT_RADIUS
	for ip in get_tree().get_nodes_in_group("ipezinhos"):
		# o clique conta a partir do meio do corpo (a origem fica no pé)
		var d: float = (ip.global_position + Vector2(0, -14)).distance_to(pos)
		if d <= best_dist:
			best_dist = d
			best = ip
	return best


## Seleciona só este (null = solta todo mundo). Mantém a API antiga.
func select(unit: Node2D) -> void:
	set_selection([unit] if unit else [])


func set_selection(units: Array) -> void:
	for unit in selection:
		if is_instance_valid(unit) and not units.has(unit):
			unit.set_selected(false)
	selection.clear()
	for unit in units:
		if is_instance_valid(unit) and not selection.has(unit):
			selection.append(unit)
			unit.set_selected(true)
	if _camera.follow_target and not selection.has(_camera.follow_target):
		_camera.follow_target = null
	_group_focus = 0
	selection_changed.emit(selected)


## Shift+clique: tira se já estava, põe se não estava.
func toggle_selected(unit: Node2D) -> void:
	var units: Array = selection.duplicate()
	if units.has(unit):
		units.erase(unit)
	else:
		units.append(unit)
	set_selection(units)


## T / botão do HUD: liga o turno extra pros selecionados (se algum ainda não
## estiver); se todos já estiverem, desliga pra todos.
func toggle_overtime() -> void:
	_prune_selection()
	if selection.is_empty():
		Audio.error()
		_hud.show_toast("Selecione ipezinhos pra dar turno extra", Color(1.0, 0.6, 0.45))
		return
	var turn_on := selection.any(func(w): return not w.overtime)
	for unit in selection:
		unit.set_overtime(turn_on)
	Audio.click()
	_hud.show_toast("Turno extra %s: %d ipezinho%s" % [
		"LIGADO" if turn_on else "desligado", selection.size(), "s" if selection.size() > 1 else ""],
		Color(0.6, 0.7, 1.0))


## Bloco 25: designa a função `job` aos selecionados. Se TODOS já têm essa função,
## tira (ficam sem função, ociosos no Centro da Vila). Trocar é seguro: quem estiver
## carregando algo entrega antes (ver _choose_state no ipezinho).
func toggle_job(job: String, label: String, color: Color) -> void:
	_prune_selection()
	if selection.is_empty():
		Audio.error()
		_hud.show_toast("Selecione ipezinhos pra virar %s" % label.to_lower(), Color(1.0, 0.6, 0.45))
		return
	var make := selection.any(func(w): return w.job != job)
	for unit in selection:
		unit.set_job(job if make else Worker.ROLE_IDLE)
	Audio.click()
	_hud.show_toast("%s: %d ipezinho%s" % [
		label if make else "Sem função", selection.size(), "s" if selection.size() > 1 else ""],
		color if make else Color(0.75, 0.75, 0.8))


## 1 / botão do HUD: minerador (ou tira, se todos já forem).
func toggle_miner() -> void:
	toggle_job(Worker.ROLE_MINER, "Minerador", Color(0.95, 0.75, 0.45))


## 2 / botão do HUD: caçador (ou tira, se todos já forem) — Bloco 27.
func toggle_hunter() -> void:
	toggle_job(Worker.ROLE_HUNTER, "Caçador", Color(0.8, 0.9, 0.55))


## 3 / botão do HUD: médico (ou tira, se todos já forem) — Bloco 30.
func toggle_doctor() -> void:
	toggle_job(Worker.ROLE_DOCTOR, "Médico", Color(0.6, 0.9, 0.85))


## 4 / botão do HUD: engenheiro (ou tira, se todos já forem) — Bloco 31.
func toggle_engineer() -> void:
	toggle_job(Worker.ROLE_ENGINEER, "Engenheiro", Color(1.0, 0.6, 0.25))


## C / botão do HUD: cozinheiro (ou tira, se todos já forem).
func toggle_cook() -> void:
	toggle_job(Worker.ROLE_COOK, "Cozinheiro", Color(0.95, 0.9, 0.6))


## L / botão do HUD: lenhador (ou tira, se todos já forem).
func toggle_lumber() -> void:
	toggle_job(Worker.ROLE_LUMBER, "Lenhador", Color(0.85, 0.7, 0.5))


## X / botão do HUD: guarda (ou tira, se todos já forem).
func toggle_guard() -> void:
	toggle_job(Worker.ROLE_GUARD, "Guarda", Color(0.95, 0.55, 0.45))


## Z / botão do HUD: pesquisador (ou tira, se todos já forem).
func toggle_research() -> void:
	toggle_job(Worker.ROLE_RESEARCH, "Pesquisador", Color(0.55, 0.95, 0.65))


## 6 / botão do HUD: fundidor (ou tira, se todos já forem) — Bloco 86.
func toggle_smelter() -> void:
	toggle_job(Worker.ROLE_SMELTER, "Fundidor", Color(1.0, 0.62, 0.32))


## 7 / botão do HUD: ferreiro (ou tira, se todos já forem) — Bloco 87.
func toggle_smith() -> void:
	toggle_job(Worker.ROLE_SMITH, "Ferreiro", Color(0.62, 0.74, 1.0))


## 9 / botão do HUD: carpinteiro (homem ou mulher; ou tira, se todos já forem) — Bloco 94.
func toggle_carpenter() -> void:
	toggle_job(Worker.ROLE_CARPENTER, "Carpinteiro", Color(0.86, 0.7, 0.45))


## 8 / botão do HUD: padre — Bloco 92. Só UM ipezinho homem (o selecionado); a vila tem um padre só. Se o
## selecionado já é o padre, tira a função dele.
func toggle_priest() -> void:
	_prune_selection()
	if selection.size() != 1:
		Audio.error()
		_hud.show_toast("Selecione UM ipezinho homem pra virar padre", Color(1.0, 0.6, 0.45))
		return
	var w: Node = selection[0]
	if w.is_priest():
		w.set_job(Worker.ROLE_IDLE)
		Audio.click()
		_hud.show_toast("%s deixou de ser padre" % String(w.get("display_name")), Color(0.75, 0.75, 0.8))
		return
	var motivo: String = w.motivo_padre()
	if motivo != "":
		Audio.error()
		_hud.show_toast(motivo, Color(1.0, 0.6, 0.45))
		return
	w.set_job(Worker.ROLE_PRIEST)
	Audio.click()
	_hud.show_toast("%s agora é o padre da vila" % String(w.get("display_name")), Color(0.78, 0.7, 0.95))


## 0 / botão do HUD: tira a função dos selecionados (voltam a ficar ociosos).
func clear_job() -> void:
	_prune_selection()
	if selection.is_empty():
		Audio.error()
		_hud.show_toast("Selecione ipezinhos pra tirar a função", Color(1.0, 0.6, 0.45))
		return
	for unit in selection:
		unit.set_job(Worker.ROLE_IDLE)
	Audio.click()
	_hud.show_toast("Sem função: %d ipezinho%s" % [selection.size(), "s" if selection.size() > 1 else ""],
		Color(0.75, 0.75, 0.8))


func is_selected(unit: Node) -> bool:
	return selection.has(unit)


func _prune_selection() -> void:
	for i in range(selection.size() - 1, -1, -1):
		if not is_instance_valid(selection[i]) or not selection[i].is_inside_tree():
			selection.remove_at(i)


## Tab: sem grupo, seleciona o próximo ipezinho (como sempre foi);
## com grupo, só leva a câmera de um selecionado pro outro, sem desfazer o grupo.
func _select_next() -> void:
	_prune_selection()
	if selection.size() > 1:
		_group_focus = (_group_focus + 1) % selection.size()
		_camera.focus_on(selection[_group_focus].global_position)
		return
	var workers := get_tree().get_nodes_in_group("ipezinhos")
	if workers.is_empty():
		return
	var i := workers.find(selected)
	var next: Node2D = workers[(i + 1) % workers.size()]
	select(next)
	_camera.focus_on(next.global_position)


func _process(delta: float) -> void:
	if _marker_timer > 0.0:
		_marker_timer -= delta
		queue_redraw()
	if _dragging:
		_box_drawer.queue_redraw()  # acompanha o mouse mesmo passando por cima do HUD
	# soltou o botão fora do jogo (em cima do HUD, fora da janela): fecha o clique/arrasto
	if _lmb_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_left_click()


func _draw() -> void:
	if _marker_timer <= 0.0 or (_iso and _iso.enabled):
		return  # na vista iso o marcador é desenhado achatado no chão (iso_view.gd)
	var t := _marker_timer / MARKER_TIME
	draw_set_transform(_marker_pos, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, lerpf(18.0, 6.0, t), 0.0, TAU, 24, Color(1.0, 0.84, 0.25, t), 2.0)
