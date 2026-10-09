extends VBoxContainer
## Bloco 95 (layout v2): a COLUNA DE ALERTAS da direita (no lugar da coluna de construções). Cada alerta é um
## ícone com um número — só aparece quando acontece — e a dica conta o detalhe. Clicar leva a câmera ao lugar
## (clicando de novo, ao próximo lugar do mesmo alerta).
##
##   sem_comida   a cozinha acabou ou não dá pra todas as refeições de hoje      -> a cozinha
##   obra_parada  obra encomendada sem ninguém trabalhando nela                  -> a obra
##   ferido       machucados e caídos em combate                                -> quem está ferido
##   invasao      aviso da invasão (21:00) e a invasão em andamento              -> o portão / a criatura
##   onda_solar   onda solar chegando ou em andamento                           -> o Centro da Vila
##   ociosos      sem função ou parados                                         -> quem está parado
##   greve        greve ou ânimo baixo contando pra greve                       -> o Centro da Vila
##   sem_teto     ipezinho sem cama                                             -> uma casa
##   frio         sem casaco no inverno                                         -> quem está sem
##   migrantes     migrantes esperando no portão (Bloco 101)                  -> o portão
##   armazem_cheio armazém cheio (Bloco 97)                                    -> o armazém
##   desarmados   guarda com a arma quebrada                                    -> o guarda

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Icones := preload("res://scripts/ui/icones.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")

## [id, ícone, nome] na ordem da coluna (o mais urgente em cima).
const TIPOS := [
	["invasao", "al_invasao", "Invasão"],
	["ferido", "ferido_grave", "Feridos"],
	["sem_comida", "al_falta_comida", "Sem comida"],
	["onda_solar", "al_onda_solar", "Onda solar"],
	["greve", "greve", "Greve"],
	["obra_parada", "al_obra_parada", "Obra parada"],
	["ociosos", "sem_funcao", "Parados"],
	["migrantes", "pessoas", "Migrantes no portão"],  # Bloco 101
	["armazem_cheio", "armazem_cheio", "Armazém cheio (compartimento)"],  # Bloco 97/106
	["maquina", "al_reator", "Máquina quebrada ou falhando"],  # Bloco 105 (ícone provisório até a arte ser aprovada)
	["desarmados", "it_arma_quebrada", "Desarmados"],
	["frio", "frio", "Sem casaco"],
	["sem_teto", "camas", "Sem cama"],
]
## Tamanho de cada botão de alerta (px lógicos).
@export var botao_tamanho := Vector2(50, 44)

var _hud: CanvasLayer
var _botoes: Dictionary = {}  # id -> {button, count}
var _alvos: Dictionary = {}  # id -> [nós]
var _giro: Dictionary = {}  # id -> índice do próximo alvo


func setup(hud: CanvasLayer) -> void:
	_hud = hud
	add_theme_constant_override("separation", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t in TIPOS:
		_cria(t[0], t[1], t[2])


func _cria(id: String, icone: String, nome: String) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = botao_tamanho
	b.tooltip_text = nome
	if UiSkin.ok():
		UiSkin.aplica_botao(b, true)
	b.visible = false
	add_child(b)
	var ic := TextureRect.new()
	ic.texture = Icones.tex(icone)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_right = -10.0
	b.add_child(ic)
	var n: Label = _hud._label("", Tipo.CORPO, Color(1.0, 0.95, 0.85))
	UiSkin.usa_fonte(n, "texto", Tipo.PIXEL_1)
	n.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	n.add_theme_constant_override("outline_size", 4)
	n.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	n.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	n.grow_vertical = Control.GROW_DIRECTION_BEGIN
	n.offset_right = -4.0
	n.offset_bottom = -1.0
	b.add_child(n)
	b.pressed.connect(func():
		Audio.click()
		vai(id))
	_botoes[id] = {"button": b, "count": n, "nome": nome}


## Põe um alerta: n = 0 esconde; texto = o número (ou "22h"); dica = o detalhe; alvos = onde a câmera vai.
func poe(id: String, n: int, dica: String, alvos: Array = [], texto := "") -> void:
	var a: Dictionary = _botoes.get(id, {})
	if a.is_empty():
		return
	var ver := n > 0
	if a.button.visible != ver:
		a.button.visible = ver
	if not ver:
		return
	var t := texto if texto != "" else str(n)
	if a.count.text != t:
		a.count.text = t
	var tip := "%s\n%s%s" % [a.nome, dica, "\n(clique: vai até lá)" if not alvos.is_empty() else ""]
	if a.button.tooltip_text != tip:
		a.button.tooltip_text = tip
	_alvos[id] = alvos


## Quantos alertas estão na tela (teste).
func ativos() -> Array[String]:
	var out: Array[String] = []
	for id in _botoes:
		if _botoes[id].button.visible:
			out.append(id)
	return out


## Leva a câmera ao próximo lugar do alerta.
func vai(id: String) -> Node:
	var lista: Array = (_alvos.get(id, []) as Array).filter(func(n): return n != null and is_instance_valid(n))
	if lista.is_empty():
		return null
	var i: int = _giro.get(id, 0) % lista.size()
	_giro[id] = i + 1
	var alvo: Node = lista[i]
	var cam: Node = _hud._main.get_node_or_null("Camera2D") if _hud._main else null
	if cam and alvo is Node2D:
		cam.focus_on((alvo as Node2D).global_position)
	if alvo.is_in_group("ipezinhos") and _hud._main.has_method("select"):
		_hud._main.select(alvo)
	return alvo
