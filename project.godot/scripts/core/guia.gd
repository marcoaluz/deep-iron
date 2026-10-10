extends CanvasLayer
## Bloco 112: o PRIMEIRO DIA GUIADO (grupo "guia"; criado pelo main.gd). O capataz — o retrato do minerador, sem arte nova
## — fala um passo de cada vez num cartão no canto de cima, e SETAS pulsando apontam o que clicar na interface (o
## Construir, a aba e o cartão da casa ou da cozinha, os botões de função) ou no mapa (onde fundar).
##
## Os passos SÃO os objetivos da missão "cap1_primeiro_dia" (data/missoes, em ordem): o guia só mostra o objetivo da vez
## (missoes.gd decide quando ele foi cumprido). Assim o primeiro dia é o começo do Capítulo 1, e quem pula ou desliga o
## guia continua com a missão normal no rastreador, só sem o capataz e as setas.
##
## Pular: o botão "Pular o guia" no cartão (vai no save). Desligar: Configurações > "Primeiro dia guiado" (fica no
## settings.cfg, vale pra todas as partidas). Save antigo: a missão do primeiro dia já vem cumprida (missoes.gd), então
## o guia não aparece.

const Tipo := preload("res://scripts/ui/tipografia.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Settings := preload("res://scripts/core/settings.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const Canteiro := preload("res://scripts/props/canteiro.gd")
const RETRATO := "res://assets/game/ui/retratos/minerador/%s__parda.png"
const NOME := "Capataz Bastião"
const COR_SETA := Color(1.0, 0.8, 0.35)
const COR_SETA_BORDA := Color(0.16, 0.09, 0.03)
## O que o capataz diz em cada objetivo da missão (o índice do objetivo) — curto, pra ler de relance.
const FALAS := [
	"Primeiro o Centro da vila. Escolha um lugar plano perto da fogueira e clique.",
	"Sem engenheiro nada fica de pé. Clique num ipezinho e aperte Engenheiro na barra de baixo.",
	"Agora o resto: arraste um retângulo pra pegar vários e dê funções. Minério e comida primeiro.",
	"Todo mundo precisa de cama. Abra o Construir e encomende as casas: o engenheiro ergue.",
	"A noite traz bicho da floresta. Ponha um guarda: ele vigia o portão.",
	"Barriga cheia segura a noite. Construa a cozinha e chame alguém de cozinheiro.",
]
const FALA_OBRA := "O engenheiro está erguendo as casas (%d de %d prontas). Enquanto isso, a vila trabalha."
const FALA_FIM := "Pronto pro primeiro dia. O portão fecha sozinho às 18:30. Na terceira noite eles vêm: até lá, minério no armazém e comida na cozinha."

## Segundos entre as conferências do passo (as setas andam a cada quadro).
@export var confere_cada: float = 0.25
## Pulsar das setas: ciclos por segundo e quantos px ela sobe e desce.
@export var seta_pulso_hz: float = 1.6
@export var seta_pulso_px: float = 6.0

## Pulou o guia nesta partida (vai no save).
var pulado := false
## O "pronto pro primeiro dia" já foi dispensado (vai no save).
var fim_visto := false
var _missoes: Node
var _hud: Node
var _t := 0.0
var _passo := -2  # índice do objetivo da vez; -1 = acabou (a fala do fim); -2 = nada
var _alvos: Array = []  # [Control ou Vector2 do mundo]
var _cartao: PanelContainer
var _retrato: TextureRect
var _fala: Label
var _contagem: Label
var _botao_pular: Button
var _botao_ok: Button
var _setas: Control


func _init() -> void:
	layer = 20  # (por cima do HUD; abaixo da introdução)


func _ready() -> void:
	add_to_group("guia")
	_monta()
	visible = false


## Ligado nas configurações?
static func ligado() -> bool:
	return bool(Settings.get_value("jogo", "guia_primeiro_dia", true))


## A configuração mudou (Configurações chama).
func ligado_mudou() -> void:
	_t = confere_cada


func _monta() -> void:
	_setas = Control.new()  # as setas e os contornos, desenhados por código
	_setas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_setas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setas.draw.connect(_desenha_setas)
	add_child(_setas)
	_cartao = PanelContainer.new()
	_cartao.name = "CartaoCapataz"
	if UiSkin.ok():
		_cartao.add_theme_stylebox_override("panel", UiSkin.painel(8))
	_cartao.position = Vector2(56, 64)
	_cartao.custom_minimum_size = Vector2(380, 0)
	add_child(_cartao)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	_cartao.add_child(linha)
	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(64, 64)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	linha.add_child(_retrato)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	linha.add_child(col)
	var topo := HBoxContainer.new()
	col.add_child(topo)
	var nome := Label.new()
	nome.text = NOME
	nome.add_theme_font_size_override("font_size", Tipo.TITULO)
	nome.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(nome)
	_contagem = Label.new()
	_contagem.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_contagem.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
	topo.add_child(_contagem)
	_fala = Label.new()
	_fala.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fala.custom_minimum_size = Vector2(290, 0)
	_fala.add_theme_font_size_override("font_size", Tipo.CORPO)
	_fala.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	col.add_child(_fala)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(botoes)
	_botao_ok = Button.new()
	_botao_ok.text = "Entendi"
	_botao_ok.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_botao_ok.pressed.connect(func():
		Audio.click()
		fim_visto = true
		_atualiza())
	botoes.add_child(_botao_ok)
	_botao_pular = Button.new()
	_botao_pular.text = "Pular o guia"
	_botao_pular.tooltip_text = "Esconde o capataz e as setas nesta partida. A missão do primeiro dia continua no rastreador.\nPra desligar em todas as partidas: Configurações > Primeiro dia guiado."
	_botao_pular.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_botao_pular.pressed.connect(pula)
	botoes.add_child(_botao_pular)


## Pula o guia nesta partida.
func pula() -> void:
	Audio.click()
	pulado = true
	_atualiza()


func _mis() -> Node:
	if _missoes == null or not is_instance_valid(_missoes):
		_missoes = get_tree().get_first_node_in_group("missoes")
	return _missoes


func _h() -> Node:
	if _hud == null or not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	return _hud


## O objetivo da vez da missão do primeiro dia (-1 = cumprida; -2 = não existe/não vale).
func passo() -> int:
	var m := _mis()
	if m == null:
		return -2
	var mis = m.por_id(m.PRIMEIRO_DIA)
	if mis == null:
		return -2
	if m.cumprida(mis.id):
		return -1
	if not m.disponivel(mis):
		return -2
	for i in mis.objetivos.size():
		if not m.objetivo_feito(mis, i):
			return i
	return -1


## Mostrando agora? (pro teste)
func mostrando() -> bool:
	return visible and _cartao.visible


## Os alvos das setas agora (Controls ou pontos do mundo) — pro teste.
func alvos() -> Array:
	return _alvos.duplicate()


func fala() -> String:
	return _fala.text


func _process(delta: float) -> void:
	_t += delta
	if _t >= confere_cada:
		_t = 0.0
		_atualiza()
	if visible:
		_setas.queue_redraw()


func _atualiza() -> void:
	var cinema := get_tree().current_scene.get_node_or_null("IntroCinema") if get_tree().current_scene else null
	var hub := get_tree().get_first_node_in_group("village_hub")
	_passo = passo()
	var mostra := ligado() and not pulado and _passo != -2 and cinema == null and not (_passo == -1 and fim_visto)
	visible = mostra
	if not mostra:
		_alvos.clear()
		return
	var menu = _h().get("_build_menu") if _h() else null
	_cartao.visible = not (menu is Control and menu.visible)  # (o Construir aberto: o cartão cobriria as abas; ficam as setas)
	_botao_ok.visible = _passo == -1
	_botao_pular.visible = _passo >= 0
	_retrato.texture = _tex_retrato("contente" if _passo == -1 else "neutro")
	_contagem.text = "" if _passo < 0 else "Passo %d de %d" % [_passo + 1, FALAS.size()]
	_alvos = []
	if _passo == -1:
		_fala.text = FALA_FIM
		return
	_fala.text = FALAS[_passo] if _passo < FALAS.size() else ""
	match _passo:
		0:  # fundar: a seta no lugar do acampamento (o fantasma do Centro anda com o mouse)
			var fog := get_tree().current_scene.get_node_or_null("World/FogueiraIntro") if get_tree().current_scene else null
			var f := get_tree().get_first_node_in_group("founding")
			if fog:
				_alvos.append(fog.global_position)
			elif f and f.has_method("_map_center"):
				_alvos.append(f._map_center())
		1:
			_alvo_funcao("engenheiro")
		2:
			_alvo_funcao("minerador")
			_alvo_funcao("lenhador")
			_alvo_funcao("caçador")
		3:
			var casas: int = get_tree().get_nodes_in_group("casas").filter(func(c): return c.get("built") == true).size()
			var pedidas: int = get_tree().get_nodes_in_group("casas").size()  # (a casa encomendada já existe, em obra)
			if pedidas >= 3:
				_fala.text = FALA_OBRA % [casas, 3]  # já encomendou: só esperar o engenheiro
			else:
				_alvo_construir("Moradia", ["Casa inicial", "Casa (Moradias)"])
		4:
			_alvo_funcao("guarda")
		5:
			if get_tree().get_nodes_in_group("comedouros").is_empty() and Canteiro.pending(get_tree(), "comedouro") == null:
				_alvo_construir("Alimentação", ["Cozinha"])
			else:
				_alvo_funcao("cozinheiro")


func _tex_retrato(expr: String) -> Texture2D:
	var p := RETRATO % expr
	return load(p) if ResourceLoader.exists(p) else null


func _alvo_funcao(job: String) -> void:
	var h := _h()
	if h == null:
		return
	var info: Dictionary = h.get("_job_buttons").get(job, {}) if h.get("_job_buttons") != null else {}
	var b: Control = info.get("button") as Control
	if b and b.is_visible_in_tree():
		_alvos.append(b)


## O caminho do Construir: o botão; com o menu aberto, a aba; na aba certa, o cartão.
func _alvo_construir(aba: String, cartoes: Array) -> void:
	var h := _h()
	if h == null:
		return
	var menu: Control = h.get("_build_menu")
	if menu == null or not menu.visible:
		var b: Control = h.get("_build_button")
		if b:
			_alvos.append(b)
		return
	var nomes: Array = menu.TAB_NAMES
	var k := nomes.find(aba)
	if k >= 0 and int(menu.get("_tab")) != k:
		var tabs: Array = menu.get("_tab_buttons")
		if k < tabs.size():
			_alvos.append(tabs[k])
		return
	for c in menu.get("_cards"):
		var d: Dictionary = c.get("def", {})
		if String(d.get("name", "")) in cartoes and c.get("panel") is Control:
			_alvos.append(c.panel)
			return


## Onde a seta aponta, na tela (o meio de cima do controle, ou o ponto do mundo pela câmera).
func _ponta(a) -> Vector2:
	if a is Control:
		var r: Rect2 = (a as Control).get_global_rect()
		return Vector2(r.get_center().x, r.position.y)
	if a is Vector2:
		var cam := get_viewport().get_camera_2d()
		var p: Vector2 = a
		if cam and cam.has_method("_to_cam"):
			p = cam._to_cam(a)
		return get_viewport().get_canvas_transform() * p
	return Vector2.ZERO


func _desenha_setas() -> void:
	var pulso := sin(Time.get_ticks_msec() / 1000.0 * TAU * seta_pulso_hz) * seta_pulso_px
	for a in _alvos:
		if a is Control and not is_instance_valid(a):
			continue
		if a is Control:  # o contorno do botão
			var r: Rect2 = (a as Control).get_global_rect().grow(3.0)
			_setas.draw_rect(r, COR_SETA_BORDA, false, 4.0)
			_setas.draw_rect(r, COR_SETA, false, 2.0)
		var p := _ponta(a) + Vector2(0, -6.0 + pulso)
		var seta := PackedVector2Array([p, p + Vector2(-13, -16), p + Vector2(-5, -16), p + Vector2(-5, -34),
			p + Vector2(5, -34), p + Vector2(5, -16), p + Vector2(13, -16)])
		_setas.draw_colored_polygon(seta, COR_SETA)
		var borda := seta.duplicate()
		borda.append(p)
		_setas.draw_polyline(borda, COR_SETA_BORDA, 2.0)


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	return {"pulado": pulado, "fim_visto": fim_visto}


func load_save_data(d: Dictionary) -> void:
	pulado = SaveUtil.boolean(d, "pulado", false)
	fim_visto = SaveUtil.boolean(d, "fim_visto", true)  # (save sem a chave: não mostra o "pronto" de novo)
	_atualiza()
