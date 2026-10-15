extends CanvasLayer
## Prompt 26: TELA DE CARREGAMENTO (troca de cena: jogo novo, carregar save): a arte de dentro da
## pedreira ou uma das cenas dos eventos, o logo e uma DICA do jogo. Some sozinha quando a partida
## nova termina de abrir.
##   Carregando.mostra(get_tree())
## Bloco 138: a partida carrega em SEGUNDO PLANO (ResourceLoader.load_threaded_request): a tela aparece na hora, com a
## barra do carregamento, e a janela segue respondendo; a cena troca quando main.tscn e as texturas grandes do terreno
## estão prontas (troca_quando_pronto). Some só quando a partida ASSENTA (quadros curtos seguidos), não por tempo fixo.

const DIR := "res://assets/game/ui/titulo/"
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const DICAS := [
	"Mineiros sem lampião não entram na galeria de carvão: a Oficina (O) faz um.",
	"A noite de invasão começa no dia 3. Guardas (X) e muro no portão seguram os Lumívoros.",
	"Ânimo baixo por muito tempo vira greve. Taverna, parque e festa levantam a vila.",
	"Engenheiro (4) é quem constrói. Sem ele, obra nenhuma sai do lugar.",
	"Onda solar: quem estiver na rua se queima. O Estudo da explosão solar avisa antes.",
	"Machucado grave sem leito na enfermaria pode morrer. Médico de plantão cura mais rápido.",
	"F2 abre o corte da mina: todos os andares de lado, e quem está em cada um.",
	"Os Ferrugentos — robôs enferrujados — saem do poço do elevador quando o nível 2 abre. O poço não tem muro: ponha guardas lá!",
	"O escudo solar é o fim do jogo: pesquise o Projeto do escudo e erga as 4 etapas.",
	"Turno extra (T) rende mais minério, mas deixa os ipezinhos zangados.",
]

static var _atual: CanvasLayer = null
## Bloco 138: os caminhos pedidos em segundo plano (pede) e o que já chegou (seguro até a partida abrir: a cena nova
## acha tudo no cache do ResourceLoader).
static var _pedidos: Array[String] = []
static var _prontos: Dictionary = {}

## Quantos quadros curtos seguidos contam como "a partida assentou" (e o que é curto, em ms).
@export var quadros_estaveis: int = 8
@export var quadro_curto_ms: float = 60.0
## O máximo de segundos esperando a partida assentar (depois disso a tela some de qualquer jeito).
@export var espera_max_s: float = 12.0

var _cena_alvo := ""
var _barra: ProgressBar
var _assentando := false
var _estaveis := 0
var _t_assenta := 0
var _t_quadro := 0


static func mostra(tree: SceneTree) -> void:
	if _atual != null and is_instance_valid(_atual):
		return
	var c = load("res://scripts/ui/carregando.gd").new()
	tree.root.add_child(c)
	_atual = c


## Bloco 138: pede `caminho` em segundo plano (se ainda não está pedido nem no cache).
static func pede(caminho: String, tipo: String = "") -> void:
	if caminho in _pedidos or ResourceLoader.has_cached(caminho):
		return
	if ResourceLoader.load_threaded_get_status(caminho) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		if ResourceLoader.load_threaded_request(caminho, tipo) != OK:
			push_warning("Carregando: não deu pra pedir %s em segundo plano" % caminho)
			return
	_pedidos.append(caminho)


## Bloco 138: mostra a tela e troca pra `cena` quando ela (e o resto pedido) terminar de carregar.
static func troca_quando_pronto(tree: SceneTree, cena: String) -> void:
	mostra(tree)
	pede(cena, "PackedScene")
	_atual.set("_cena_alvo", cena)


## Bloco 138: de 0 a 1, o quanto do que foi pedido já carregou.
static func progresso() -> float:
	if _pedidos.is_empty():
		return 1.0
	var soma := 0.0
	for p in _pedidos:
		var pr := []
		var st := ResourceLoader.load_threaded_get_status(p, pr)
		soma += 1.0 if st != ResourceLoader.THREAD_LOAD_IN_PROGRESS else (float(pr[0]) if not pr.is_empty() else 0.0)
	return soma / _pedidos.size()


## Bloco 138: recolhe o que terminou (o que falhou só sai da lista: a cena carrega do jeito normal). true = tudo pronto.
static func _recolhe() -> bool:
	for p in _pedidos.duplicate():
		var st := ResourceLoader.load_threaded_get_status(p)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			_prontos[p] = ResourceLoader.load_threaded_get(p)
		else:
			push_warning("Carregando: %s falhou em segundo plano (status %d)" % [p, st])
		_pedidos.erase(p)
	return _pedidos.is_empty()


func _process(_delta: float) -> void:
	if _barra:
		_barra.value = progresso() * 100.0 if _cena_alvo != "" else _barra.value
	if _cena_alvo != "":
		if not _recolhe():
			return
		var cena: String = _cena_alvo
		_cena_alvo = ""
		var ps = _prontos.get(cena)
		if ps is PackedScene:
			get_tree().change_scene_to_packed(ps)
		else:
			get_tree().change_scene_to_file(cena)  # (falhou em segundo plano: do jeito de antes, síncrono)
		return
	if _assentando:
		var agora := Time.get_ticks_msec()
		_estaveis = _estaveis + 1 if agora - _t_quadro <= quadro_curto_ms else 0
		_t_quadro = agora
		if _estaveis >= quadros_estaveis or agora - _t_assenta > espera_max_s * 1000.0:
			_assentando = false
			_esconde()


func _ready() -> void:
	UiSkin.tema_na_camada(self)  # Bloco 95: o tema (escala e fonte) chega nos Controls da camada
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0.04, 0.03, 0.03)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var opcoes: Array = ["keyart_b", "../ilustracoes/robo_achado", "../ilustracoes/festa", "../ilustracoes/onda_solar", "../ilustracoes/greve"]
	var p := DIR + String(opcoes[randi() % opcoes.size()]) + ".png"
	if ResourceLoader.exists(p):
		var arte := TextureRect.new()
		arte.texture = load(p)
		arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		arte.set_anchors_preset(Control.PRESET_FULL_RECT)
		arte.modulate = Color(0.75, 0.72, 0.7)
		add_child(arte)
	if ResourceLoader.exists(DIR + "logo.png"):
		var logo := TextureRect.new()
		logo.texture = load(DIR + "logo.png")
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
		logo.position = Vector2(-logo.texture.get_width() * 0.5, 40)
		add_child(logo)
	var caixa := PanelContainer.new()
	caixa.add_theme_stylebox_override("panel", UiSkin.faixa())
	caixa.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caixa.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caixa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caixa.offset_bottom = -40.0
	add_child(caixa)
	var v := VBoxContainer.new()
	caixa.add_child(v)
	var t := Label.new()
	t.text = "Carregando..."
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", UiSkin.COLOR_TITLE)
	UiSkin.usa_fonte(t, "texto", Tipo.PIXEL_1)
	v.add_child(t)
	var d := Label.new()
	d.text = "Dica: " + DICAS[randi() % DICAS.size()]
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.custom_minimum_size.x = 640
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", Tipo.TITULO)
	d.add_theme_color_override("font_color", UiSkin.COLOR_TEXT)
	v.add_child(d)
	_barra = ProgressBar.new()  # Bloco 138: o carregamento em segundo plano
	_barra.custom_minimum_size = Vector2(640, 10)
	_barra.show_percentage = false
	_barra.value = 0.0
	v.add_child(_barra)
	get_tree().scene_changed.connect(_some, CONNECT_ONE_SHOT)


func _some() -> void:
	# Bloco 138: os primeiros quadros da partida montam o mundo (vista iso, HUD): a tela fica até eles assentarem
	if _barra:
		_barra.value = 100.0
	_assentando = true
	_estaveis = 0
	_t_assenta = Time.get_ticks_msec()
	_t_quadro = _t_assenta


func _esconde() -> void:
	var tw := create_tween()
	tw.tween_interval(0.2)  # (ninguém vê o mapa piscando)
	for c in get_children():
		if c is CanvasItem:
			tw.parallel().tween_property(c, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tw.tween_callback(func():
		_atual = null
		_prontos.clear()  # (a partida já segura o que usa)
		queue_free())
