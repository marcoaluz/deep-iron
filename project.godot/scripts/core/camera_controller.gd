extends Camera2D
## Câmera RTS: zoom suave na direção do cursor, pan com botão do meio / setas / WASD,
## pan pela borda da tela (opcional), limites no mapa e seguir o ipezinho selecionado (F).
##
## Bloco 48: a roda do mouse anda por PARADAS NÍTIDAS — zooms em que 1 pixel de arte vira um
## número INTEIRO de pixels na tela (nada de colunas de pixel desiguais). A parada depende da
## escala da janela sobre a base 1280×720 (×1,5 em 1080p, ×2 em 1440p, ×3 em 4K): trocar de
## janela pra tela cheia reassenta o zoom na parada mais perto. O movimento continua suave e
## na direção do cursor.

@export_group("Zoom")
## Bloco 48: 0,6 -> 0,5 (em 720p a parada nítida mais afastada é 0,5: 1 px de arte = 1 px de tela).
@export var zoom_min: float = 0.5
@export var zoom_max: float = 3.0
## Zoom ao abrir (assenta na parada nítida mais perto).
@export var start_zoom: float = 1.3
## Multiplicador por "clique" da roda do mouse (só com crisp_zoom desligado).
@export var zoom_step: float = 1.15
@export var zoom_smoothing: float = 12.0
## Bloco 48: a roda anda de parada nítida em parada nítida (pixel de arte inteiro na tela).
## Desligado: zoom livre como antes (zoom_step por clique).
@export var crisp_zoom: bool = true
## Pixels de MUNDO por pixel de ARTE. Hoje a arte é desenhada pequena e mostrada em escala 2;
## se a densidade da arte mudar (ver docs/escala_visual), é só trocar aqui.
@export var art_pixel_world: float = 2.0

@export_group("Pan")
@export var pan_speed: float = 650.0
@export var pan_smoothing: float = 10.0
@export var edge_scroll: bool = false
@export var edge_margin: float = 10.0

@export_group("Limites")
## Área onde o centro da câmera pode ficar (normalmente o mapa). Tamanho zero = sem limite.
@export var bounds: Rect2 = Rect2()
@export var bounds_margin: float = 80.0

var follow_target: Node2D = null
## Prompt 28: vista isométrica ligada (iso_view.gd). A câmera passa a andar na TELA
## isométrica, mas quem a usa continua falando em pontos do CHÃO (focus_on, follow_target,
## bounds, save) — a conversão é aqui.
var iso_view: Node = null

var _target_zoom: float = 1.0
var _target_pos: Vector2
var _zoom_anchor_screen: Vector2
var _panning := false
var _pan_origin := Vector2.ZERO
var _cam_origin := Vector2.ZERO


func _ready() -> void:
	_target_zoom = snap_zoom(start_zoom)
	zoom = Vector2.ONE * _target_zoom
	_target_pos = position
	make_current()
	get_tree().root.size_changed.connect(_on_window_resized)


## Janela mudou de tamanho (tela cheia, redimensionar): a escala mudou, então as paradas
## também — assenta na mais perto do zoom atual (zoom no centro da tela).
func _on_window_resized() -> void:
	if not crisp_zoom:
		return
	_zoom_anchor_screen = get_viewport_rect().size * 0.5
	_target_zoom = snap_zoom(_target_zoom)


# ------------------------------------------------------------ paradas nítidas (Bloco 48)
## Quanto a janela está esticada sobre a resolução base (canvas_items/expand):
## 1 em 1280×720, 1,5 em 1920×1080, 2 em 2560×1440, 3 em 3840×2160.
func screen_scale() -> float:
	var win := get_tree().root
	if win.has_meta("screen_scale"):
		return float(win.get_meta("screen_scale"))  # (testes headless: a janela lá é 64×64)
	var base := Vector2(win.content_scale_size)
	var size := Vector2(win.size)
	if base.x <= 0.0 or base.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return 1.0
	return minf(size.x / base.x, size.y / base.y) * win.content_scale_factor


## Quantos pixels de tela 1 pixel de arte ocupa nesse zoom.
func art_pixel_screen(z: float, win_scale: float = -1.0) -> float:
	return art_pixel_world * z * (screen_scale() if win_scale <= 0.0 else win_scale)


## Os zooms nítidos entre zoom_min e zoom_max (1 px de arte = 1, 2, 3... px de tela).
func zoom_stops(win_scale: float = -1.0) -> Array[float]:
	var out: Array[float] = []
	var unit := art_pixel_screen(1.0, win_scale)  # px de tela por px de arte com zoom 1
	if unit <= 0.0:
		return out
	var n := maxi(ceili(zoom_min * unit - 0.001), 1)
	while n / unit <= zoom_max + 0.001:
		out.append(n / unit)
		n += 1
	return out


## A parada nítida mais perto de z (na proporção: 1,3 fica mais perto de 1,33 que de 1,0).
## Sem parada no intervalo (ou crisp_zoom desligado): z dentro dos limites.
func snap_zoom(z: float) -> float:
	var stops := zoom_stops() if crisp_zoom else ([] as Array[float])
	if stops.is_empty():
		return clampf(z, zoom_min, zoom_max)
	var best := stops[0]
	for st in stops:
		if absf(log(st / z)) < absf(log(best / z)):
			best = st
	return best


## Zoom pedido de fora (ex.: o save): vai pra parada nítida mais perto.
func set_target_zoom(z: float) -> void:
	_target_zoom = snap_zoom(clampf(z, zoom_min, zoom_max))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_by(zoom_step, event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_by(1.0 / zoom_step, event.position)
			MOUSE_BUTTON_MIDDLE:
				_panning = event.pressed
				_pan_origin = event.position
				_cam_origin = position
				follow_target = null
	elif event is InputEventMouseMotion and _panning:
		position = _clamp_to_bounds(_cam_origin - (event.position - _pan_origin) / zoom.x)
		_target_pos = position
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_HOME:
				_target_pos = _to_cam(bounds.get_center()) if bounds.has_area() else Vector2.ZERO
				follow_target = null


func _zoom_by(factor: float, screen_pos: Vector2) -> void:
	_zoom_anchor_screen = screen_pos
	var stops := zoom_stops() if crisp_zoom else ([] as Array[float])
	if stops.is_empty():
		_target_zoom = clampf(_target_zoom * factor, zoom_min, zoom_max)
		return
	# Bloco 48: próxima parada nítida pra dentro (factor > 1) ou pra fora
	if factor > 1.0:
		for st in stops:
			if st > _target_zoom + 0.0001:
				_target_zoom = st
				return
		_target_zoom = stops[-1]
	else:
		for i in range(stops.size() - 1, -1, -1):
			if stops[i] < _target_zoom - 0.0001:
				_target_zoom = stops[i]
				return
		_target_zoom = stops[0]


func _process(delta: float) -> void:
	# --- zoom suave mantendo o ponto sob o cursor parado
	if not is_equal_approx(zoom.x, _target_zoom):
		var screen_offset := _zoom_anchor_screen - get_viewport_rect().size * 0.5
		if follow_target != null:
			screen_offset = Vector2.ZERO  # seguindo alguém: zoom no centro
		var anchor_world := position + screen_offset / zoom.x
		var z := lerpf(zoom.x, _target_zoom, 1.0 - exp(-zoom_smoothing * delta))
		if absf(z - _target_zoom) < 0.001:
			z = _target_zoom
		zoom = Vector2(z, z)
		var new_pos := anchor_world - screen_offset / z
		_target_pos += new_pos - position
		position = new_pos

	# --- pan por teclado / borda
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D): dir.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):  dir.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):  dir.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):    dir.y -= 1.0
	if edge_scroll and not _panning:
		var mouse := get_viewport().get_mouse_position()
		var size := get_viewport_rect().size
		if mouse.x < edge_margin: dir.x -= 1.0
		elif mouse.x > size.x - edge_margin: dir.x += 1.0
		if mouse.y < edge_margin: dir.y -= 1.0
		elif mouse.y > size.y - edge_margin: dir.y += 1.0
	if dir != Vector2.ZERO:
		follow_target = null
		_target_pos += dir.normalized() * pan_speed * delta / zoom.x

	# --- seguir alvo
	if follow_target != null:
		if is_instance_valid(follow_target):
			_target_pos = _to_cam(follow_target.global_position) + Vector2(0, -16)
		else:
			follow_target = null

	_target_pos = _clamp_to_bounds(_target_pos)
	if not _panning:
		position = position.lerp(_target_pos, 1.0 - exp(-pan_smoothing * delta))


func _clamp_to_bounds(p: Vector2) -> Vector2:
	if not bounds.has_area():
		return p
	var r := bounds.grow(bounds_margin)
	if iso_view:  # o losango do mapa na tela: o retângulo que contém os 4 cantos
		var a: Vector2 = iso_view.to_screen(r.position)
		var sr := Rect2(a, Vector2.ZERO)
		for c in [Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			sr = sr.expand(iso_view.to_screen(c))
		r = sr
	return p.clamp(r.position, r.end)


## Ponto do chão -> onde a câmera fica (na vista iso, a tela isométrica).
func _to_cam(world_pos: Vector2) -> Vector2:
	return iso_view.to_screen(world_pos) if iso_view else world_pos


## O ponto do CHÃO no centro da tela (save, troca de vista).
func ground_center() -> Vector2:
	var c := get_screen_center_position()
	return iso_view.ground_under(c) if iso_view else c  # Prompt 29: o raio acha o terraço


## Prompt 28: trocou de vista — continua olhando o mesmo ponto do chão.
func on_view_changed(ground: Vector2) -> void:
	position = _to_cam(ground)
	_target_pos = position
	reset_smoothing()


func focus_on(world_pos: Vector2) -> void:
	_target_pos = _clamp_to_bounds(_to_cam(world_pos))
