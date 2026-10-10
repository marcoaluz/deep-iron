extends CanvasLayer
## Bloco 112: os quadros 4 a 7 da INTRODUÇÃO, no próprio mapa da partida (o main.gd cria este nó quando o
## SaveManager.cinema não está vazio, antes da Fundação). Sem a interface do jogo e sem os nomes dos prédios:
##
##   4 pedreira — a câmera atravessa a pedreira, da mina até a vila;
##   5 coletor  — na beira da floresta, o coletor de madeira em ruína;
##   6 corte    — o corte da mina (o mapa do mundo, mapa_mundo.png do Bloco 72) descendo andar por andar;
##   7 fogueira — a primeira fogueira acesa no meio da vila, a caravana em volta, e o título DEEP IRON.
##
## Esc ou Espaço pulam (o resto da intro). O mundo continua rodando (é a partida; o relógio NÃO é mexido: voltar a hora
## dispararia um "novo dia" de mentira). Nada aqui muda o jogo além da fogueira, que fica acesa até a Fundação escolher
## o Centro. Sons: ganchos Audio.intro (tocam quando o arquivo existir).

signal terminou

const Tipo := preload("res://scripts/ui/tipografia.gd")
const Ipezinho := preload("res://scripts/workers/ipezinho.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const MAPA_MUNDO := "res://assets/game/ui/corte/mapa_mundo.png"
const LOGO := "res://assets/game/ui/titulo/logo.png"
const COR_TEXTO := Color(0.95, 0.88, 0.74)
const COR_DICA := Color(0.7, 0.64, 0.55)
## Altura (px) da faixa escura da legenda: cabe duas linhas.
const ALTURA_FAIXA := 112.0
## [quadro, texto, som, segundos]
const QUADROS := [
	["pedreira", "Uma pedreira velha. Pedra boa, ferro no fundo e um poço que desce.", "pedreira", 9.0],
	["coletor", "Na beira da floresta, a máquina de lenha parada há anos. Dá pra consertar.", "vento", 8.0],
	["corte", "Embaixo, a mina desce andar por andar: ácido, lava, água. E o que mora lá.", "mina", 9.0],
	["fogueira", "Aqui a gente acende o fogo. Aqui começa a vila.", "fogo", 10.0],
]
## Onde ficam os ipezinhos em volta da fogueira (px do mundo, em relação a ela).
## Dos lados e atrás do fogo (na vista iso, x + y grande = na frente: ninguém fica entre a câmera e o fogo).
const RODA := [Vector2(-26, 26), Vector2(26, -26), Vector2(-36, -6), Vector2(-6, -36), Vector2(-22, 42), Vector2(42, -22)]

## Letras por segundo das legendas.
@export var letras_por_segundo: float = 30.0
## Segundos do escurecer/clarear entre os quadros.
@export var fade_segundos: float = 0.6
## Zoom da câmera em cada quadro do mapa (pedreira, coletor, fogueira).
@export var zoom_pedreira: float = 1.0
@export var zoom_coletor: float = 1.5
@export var zoom_fogueira: float = 2.0
## Segundos, dentro do quadro da fogueira, até o título aparecer.
@export var titulo_depois: float = 3.0

var _main: Node
var _cam: Camera2D
var _iso: Node
var _i := -1
var _t := 0.0
var _foco := Vector2.ZERO  # o ponto do mundo que a câmera segue (anda por tween)
var _usa_foco := false
var _tw_foco: Tween  # o passeio da câmera do quadro de agora (morre no próximo: pular não deixa dois brigando)
var _acabou := false
var _trocando := false
var _hud_antes := true
var _parados: Array = []  # ipezinhos da roda: [nó, auto_mode antes]
var fogueira: Node2D

var _raiz: Control
var _texto: Label
var _preto: ColorRect
var _corte: TextureRect
var _logo: TextureRect


func _init() -> void:
	layer = 50  # por cima da interface do jogo


func setup(main: Node) -> void:
	_main = main


func _ready() -> void:
	if _main == null:
		_main = get_parent()
	_cam = _main.get_node_or_null("Camera2D") as Camera2D
	_iso = _main.get("_iso")
	var hud := get_tree().get_first_node_in_group("hud") as CanvasLayer
	if hud:
		_hud_antes = hud.visible
		hud.visible = false
	if _iso:
		_iso.set("cinema", true)
	Ipezinho.sem_baloes = true
	_monta_tela()
	_proximo()


func _monta_tela() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP  # (nada de clique no mapa durante a intro)
	add_child(_raiz)
	_corte = TextureRect.new()  # o quadro 6: o corte da mina
	_corte.texture = load(MAPA_MUNDO) if ResourceLoader.exists(MAPA_MUNDO) else null
	_corte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_corte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_corte.stretch_mode = TextureRect.STRETCH_SCALE
	_corte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corte.visible = false
	var fundo_corte := ColorRect.new()
	fundo_corte.name = "FundoCorte"
	fundo_corte.color = Color(0.06, 0.05, 0.05)
	fundo_corte.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo_corte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo_corte.visible = false
	_raiz.add_child(fundo_corte)
	_raiz.add_child(_corte)
	var faixa := ColorRect.new()
	faixa.color = Color(0.0, 0.0, 0.0, 0.62)
	faixa.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	faixa.offset_top = -ALTURA_FAIXA
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(faixa)
	_texto = Label.new()
	_texto.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_texto.offset_top = -ALTURA_FAIXA + 8.0
	_texto.offset_bottom = -10.0
	_texto.offset_left = 48.0
	_texto.offset_right = -48.0
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_color_override("font_color", COR_TEXTO)
	_texto.add_theme_font_size_override("font_size", Tipo.FAIXA)  # (sem a fonte pixel; com ela, o tamanho dela)
	UiSkin.usa_fonte(_texto, "texto", Tipo.PIXEL_2)
	_texto.add_theme_color_override("font_shadow_color", Tipo.SOMBRA)
	_raiz.add_child(_texto)
	_logo = TextureRect.new()
	_logo.texture = load(LOGO) if ResourceLoader.exists(LOGO) else null
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	var lw := float(_logo.texture.get_width()) * 2.0 if _logo.texture else 480.0
	var lh := float(_logo.texture.get_height()) * 2.0 if _logo.texture else 120.0
	_logo.offset_left = -lw * 0.5
	_logo.offset_right = lw * 0.5
	_logo.offset_top = 60.0
	_logo.offset_bottom = 60.0 + lh
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.modulate.a = 0.0
	_raiz.add_child(_logo)
	if _logo.texture == null:  # sem o logo: o nome escrito
		var titulo := Label.new()
		titulo.text = "DEEP IRON"
		titulo.set_anchors_preset(Control.PRESET_FULL_RECT)
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		titulo.add_theme_font_size_override("font_size", Tipo.TELA)
		UiSkin.usa_fonte(titulo, "titulo", Tipo.PIXEL_4)
		titulo.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
		_logo.add_child(titulo)
	var dica := Label.new()
	dica.text = "Esc ou Espaço: pular"
	dica.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dica.offset_left = -220.0
	dica.offset_right = -16.0
	dica.offset_top = 12.0
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dica.add_theme_font_size_override("font_size", Tipo.DETALHE)
	dica.add_theme_color_override("font_color", COR_DICA)
	_preto = ColorRect.new()
	_preto.color = Color.BLACK
	_preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_preto)
	_raiz.add_child(dica)


func _exit_tree() -> void:
	Ipezinho.sem_baloes = false  # (saiu sem passar pelo fim: troca de cena, fechar o jogo)


## O quadro de agora ("" antes e depois) — pro teste e pras fotos.
func quadro() -> String:
	return String(QUADROS[_i][0]) if _i >= 0 and _i < QUADROS.size() else ""


func _proximo() -> void:
	_i += 1
	if _i >= QUADROS.size():
		_fim()
		return
	var q: Array = QUADROS[_i]
	_t = 0.0
	_texto.text = String(q[1])
	_texto.visible_characters = 0
	_corte.visible = q[0] == "corte"
	_raiz.get_node("FundoCorte").visible = _corte.visible
	match String(q[0]):
		"pedreira":
			var boca := _no("bocas_mina")
			var a: Vector2 = boca.global_position + Vector2(120, 20) if boca else Vector2(900, -100)
			var hub := _no("village_hub")
			var b: Vector2 = hub.global_position + Vector2(160, 40) if hub else Vector2(200, -150)
			_anda(a, b, float(q[3]), zoom_pedreira)
		"coletor":
			var col := _no("coletores")
			var c: Vector2 = col.global_position if col else Vector2(-420, 260)
			_anda(c + Vector2(90, -110), c + Vector2(10, -10), float(q[3]), zoom_coletor)
		"corte":
			_usa_foco = false
			_poe_corte(0.0)
		"fogueira":
			var p := _lugar_da_fogueira()
			_acende(p)
			_anda(p + Vector2(20, 40), p + Vector2(-20, -20), float(q[3]), zoom_fogueira)  # (termina com o fogo abaixo do título)
	var clareia := create_tween()
	clareia.tween_property(_preto, "color:a", 0.0, fade_segundos)
	Audio.intro(String(q[2]))
	_trocando = false


func _no(grupo: String) -> Node2D:
	return get_tree().get_first_node_in_group(grupo) as Node2D


## A câmera corta pra `de` (atrás do preto) e anda devagar até `ate`.
func _anda(de: Vector2, ate: Vector2, segundos: float, z: float) -> void:
	_usa_foco = true
	_foco = de
	if _cam:
		if _cam.has_method("set_target_zoom"):
			_cam.set_target_zoom(z)
			_cam.zoom = Vector2.ONE * float(_cam.get("_target_zoom"))
		var p: Vector2 = _cam._to_cam(de) if _cam.has_method("_to_cam") else de
		_cam.position = p
		_cam.set("_target_pos", p)
	if _tw_foco and _tw_foco.is_valid():
		_tw_foco.kill()
	_tw_foco = create_tween()
	_tw_foco.tween_property(self, "_foco", ate, segundos).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## O quadro 6: o mapa do mundo grande, descendo do topo (k = 0) até o fundo (k = 1).
func _poe_corte(k: float) -> void:
	if _corte.texture == null:
		return
	var tela := get_viewport().get_visible_rect().size
	var tw := float(_corte.texture.get_width())
	var th := float(_corte.texture.get_height())
	var escala := maxf(floorf(tela.y * 1.6 / th), 1.0)  # escala inteira (pixel nítido); ~1,6 tela de alto: desce
	var tam := Vector2(tw, th) * escala
	var y0 := 0.0
	var y1 := minf(tela.y - ALTURA_FAIXA - tam.y, 0.0)  # (o fim do corte encostado em cima da legenda)
	_corte.size = tam
	_corte.position = Vector2((tela.x - tam.x) * 0.5, lerpf(y0, y1, k))


## Onde fica a fogueira: no meio da vila, onde a Fundação começa a escolher (no chão livre).
func _lugar_da_fogueira() -> Vector2:
	var f := get_tree().get_first_node_in_group("founding")
	var c: Vector2 = f._map_center() + Vector2(0, 40) if f and f.has_method("_map_center") else Vector2(40, -100)
	return c


## A fogueira (o efeito animado do mapa, com a luz e a fumaça) e a caravana em volta dela.
func _acende(p: Vector2) -> void:
	var world := _main.get_node_or_null("World")
	if world == null:
		return
	fogueira = Node2D.new()
	fogueira.name = "FogueiraIntro"
	fogueira.position = p
	fogueira.set_meta("iso_fx", "fogueira")
	var luz := PointLight2D.new()
	luz.name = "FireLight"
	luz.position = Vector2(0, -20)
	luz.color = Color(1.0, 0.6, 0.3)
	luz.energy = 0.9
	luz.texture = load("res://assets/game/light_radial.tres")
	luz.texture_scale = 0.6
	fogueira.add_child(luz)
	var fumaca := CPUParticles2D.new()
	fumaca.name = "Smoke"
	fumaca.position = Vector2(0, -30)
	fumaca.amount = 10
	fumaca.lifetime = 2.6
	fumaca.direction = Vector2(0.15, -1)
	fumaca.spread = 12.0
	fumaca.gravity = Vector2(3, -6)
	fumaca.initial_velocity_min = 8.0
	fumaca.initial_velocity_max = 14.0
	fumaca.scale_amount_min = 3.0
	fumaca.scale_amount_max = 5.0
	fumaca.color = Color(0.22, 0.2, 0.19, 0.8)
	fogueira.add_child(fumaca)
	world.add_child(fogueira)
	var f := get_tree().get_first_node_in_group("founding")
	if f and f.has_signal("done"):
		# (o Centro toma o lugar do acampamento; ligado na própria fogueira: este nó sai antes da Fundação acabar)
		f.done.connect(fogueira.queue_free, CONNECT_ONE_SHOT)
	var k := 0
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if k >= RODA.size():
			break
		_parados.append([w, w.get("auto_mode")])
		w.set("auto_mode", false)
		w.set("_moving", false)
		w.global_position = p + RODA[k]
		k += 1


func _process(delta: float) -> void:
	if _acabou or _i < 0 or _i >= QUADROS.size():
		return
	_t += delta
	var q: Array = QUADROS[_i]
	_texto.visible_characters = int(_t * letras_por_segundo)
	if _usa_foco and _cam:
		_cam.set("_target_pos", _cam._to_cam(_foco) if _cam.has_method("_to_cam") else _foco)
	if q[0] == "corte":
		_poe_corte(clampf(_t / float(q[3]), 0.0, 1.0))
	if q[0] == "fogueira" and _t >= titulo_depois and _logo.modulate.a <= 0.0 and not _logo.has_meta("subindo"):
		_logo.set_meta("subindo", true)
		var tw := create_tween()
		tw.tween_property(_logo, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
		Audio.intro("titulo")
	if _t >= float(q[3]) and not _trocando:
		_passa()


func _passa() -> void:
	if _trocando or _acabou:
		return
	_trocando = true
	var escurece := create_tween()
	escurece.tween_property(_preto, "color:a", 1.0, fade_segundos)
	escurece.finished.connect(_proximo)


func _input(e: InputEvent) -> void:
	if _acabou:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ESCAPE, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		pula()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if _texto.visible_characters < _texto.text.length():
			_t = maxf(_t, float(_texto.text.length()) / letras_por_segundo)
		else:
			_passa()


## Pula o resto (Esc/Espaço): direto pro fim.
func pula() -> void:
	if _i < QUADROS.size() - 1 or fogueira == null:
		_i = QUADROS.size() - 1
		if fogueira == null:  # (a fogueira fica acesa mesmo pulando: é o acampamento)
			_acende(_lugar_da_fogueira())
	_fim()


func _fim() -> void:
	if _acabou:
		return
	_acabou = true
	Audio.tema("")  # Bloco 114: acabou a introdução: volta a música do jogo
	for par in _parados:
		if is_instance_valid(par[0]):
			par[0].set("auto_mode", par[1] if par[1] != null else true)
	if _iso:
		_iso.set("cinema", false)
	Ipezinho.sem_baloes = false
	var hud := get_tree().get_first_node_in_group("hud") as CanvasLayer
	if hud:
		hud.visible = _hud_antes
	if _cam and fogueira:  # a câmera fica no acampamento: a Fundação começa daqui
		var p := fogueira.global_position
		_cam.set("_target_pos", _cam._to_cam(p) if _cam.has_method("_to_cam") else p)
	terminou.emit()
	queue_free()
