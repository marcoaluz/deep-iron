extends CanvasLayer
## Prompt 26: TELA DE CARREGAMENTO (troca de cena: jogo novo, carregar save): a arte de dentro da
## pedreira ou uma das cenas dos eventos, o logo e uma DICA do jogo. Some sozinha quando a partida
## nova termina de abrir.
##   Carregando.mostra(get_tree())

const DIR := "res://assets/game/ui/titulo/"
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
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


static func mostra(tree: SceneTree) -> void:
	if _atual != null and is_instance_valid(_atual):
		return
	var c = load("res://scripts/ui/carregando.gd").new()
	tree.root.add_child(c)
	_atual = c


func _ready() -> void:
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
	UiSkin.usa_fonte(t, "texto", 16)
	v.add_child(t)
	var d := Label.new()
	d.text = "Dica: " + DICAS[randi() % DICAS.size()]
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.custom_minimum_size.x = 640
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 14)
	d.add_theme_color_override("font_color", UiSkin.COLOR_TEXT)
	v.add_child(d)
	get_tree().scene_changed.connect(_some, CONNECT_ONE_SHOT)


func _some() -> void:
	var tw := create_tween()
	tw.tween_interval(1.0)  # (a partida nova termina de montar: ninguém vê o mapa piscando)
	for c in get_children():
		if c is CanvasItem:
			tw.parallel().tween_property(c, "modulate:a", 0.0, 0.5).set_delay(1.0)
	tw.tween_callback(func():
		_atual = null
		queue_free())
