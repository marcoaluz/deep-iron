extends Node2D
## Bloco 93: o CEMITÉRIO (grupo "cemiterios") — um terreno que o JOGADOR marca arrastando no mapa (o tamanho é
## dele: centro_vila.build_cemiterio + area_placer.begin_custom), erguido pelo engenheiro e que COMEÇA VAZIO.
##
## - Obra: o próprio cemitério é o local da obra (interface de obra do obra_site.gd, como o coletor em ruína do
##   Bloco 81: o desenho depende do tamanho, então não há um canteiro de desenho fixo). A evolução aparece montada
##   com as peças do PixelLab (predios93.py): 1) estacas nos cantos, 2) os postes todos, 3) a cerca do fundo e
##   dos lados, 4) pronto (a cerca inteira e o portão na frente).
## - A cerca é MODULAR: trecho (cem_cerca "\" ao longo do x, cem_cerca_y "/" ao longo do y), poste em cada
##   emenda e o portão no meio da frente; cada peça é um nó do mundo desenhado pelo nome (iso_prop).
## - Cada ENTERRO (o padre traz o corpo: ipezinho._padre_enterro) põe uma cruz ou uma lápide numa vaga da
##   grade, do fundo pra frente, com o NOME e QUANDO morreu. Cheio: o padre procura outro cemitério.
## - É ponto social ao ar livre (tipo "cemiterio"): o funeral (pesquisa "Ritos fúnebres") junta a vila no portão.

const SocialSpot := preload("res://scripts/props/social_spot.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const ObraEstagio := preload("res://scripts/core/obra_estagio.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")

## Trecho da cerca (px da lógica): o desenho do PixelLab (36 px de arte) / a escala da vista (1,5).
const TRECHO := 24.0
## A vaga de cada túmulo (px da lógica) e a folga até a cerca. Larga o bastante pro nome e o dia de cada lápide
## não encostarem nos vizinhos na vista iso.
const VAGA := Vector2(36, 28)
const MARGEM := 8.0

var rect := Rect2()  # o terreno (lógica, coordenadas do mundo)
var total := 30.0  # segundos de engenheiro
var feito := 0.0
var pronto := false
## Os enterrados: {nome, dia, estacao, causa, tipo ("cruz"/"lapide"), variante, vaga}.
var covas: Array = []
var oficio := "engenheiro"
var panel_id := "calendario"
var _obra := ObraSite.new()
var _pecas: Array = []
var _tumulos: Array = []
var _estagio_desenhado := -1
var _spot: Node2D
var _label: Label


## Antes de entrar na árvore: o terreno (já alinhado aos trechos da cerca) e o tempo da obra.
func configura(r: Rect2, segundos: float) -> void:
	rect = alinha(r)
	total = maxf(segundos, 1.0)
	position = rect.get_center()
	_obra.start()


## O retângulo encaixado nos trechos da cerca (mínimo 3 x 2), pelo canto de cima.
static func alinha(r: Rect2) -> Rect2:
	var w := maxf(roundf(r.size.x / TRECHO), 3.0) * TRECHO
	var h := maxf(roundf(r.size.y / TRECHO), 2.0) * TRECHO
	return Rect2(r.position.round(), Vector2(w, h))


func _ready() -> void:
	add_to_group("cemiterios")
	add_to_group("clickable")
	if not pronto:
		add_to_group("obras")
	_label = Label.new()
	_label.name = "NameLabel"
	_label.size = Vector2(220, 40)
	_label.position = Vector2(-110, -rect.size.y * 0.5 - 70.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.add_theme_font_size_override("font_size", Tipo.MAPA)
	_label.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.03))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	# o funeral junta a vila na frente do portão (ao ar livre)
	_spot = SocialSpot.criar("cemiterio", "Cemitério", false, 3, 5, Vector2(0, rect.size.y * 0.5 + 34.0), 1.0)
	_spot.espaco_rodas = 46.0
	add_child(_spot)
	_monta.call_deferred()
	_atualiza_placa()


func _exit_tree() -> void:
	for n in _pecas + _tumulos:
		if is_instance_valid(n):
			n.queue_free()


func ponto() -> Node2D:
	return _spot


## Onde o padre fica no funeral (no portão, do lado de dentro).
func portao_pos() -> Vector2:
	return Vector2(rect.get_center().x, rect.end.y - 8.0)


func contains_point(p: Vector2) -> bool:
	return rect.grow(6.0).has_point(p)


func decor_clear_rect() -> Rect2:
	return rect.grow(8.0)


# ------------------------------------------------------------ vagas e enterro
func vagas_total() -> int:
	return _grade().size()


func cheio() -> bool:
	return covas.size() >= vagas_total()


## As vagas da grade, do FUNDO pra frente (na vista iso, o fundo é o canto de cima).
func _grade() -> Array:
	var out: Array = []
	var x0 := rect.position.x + MARGEM + VAGA.x * 0.5
	var y0 := rect.position.y + MARGEM + VAGA.y * 0.5
	var nx := maxi(int((rect.size.x - MARGEM * 2.0) / VAGA.x), 1)
	var ny := maxi(int((rect.size.y - MARGEM * 2.0 - 8.0) / VAGA.y), 1)  # (a frente fica livre pro portão)
	for j in ny:
		for i in nx:
			out.append(Vector2(x0 + i * VAGA.x, y0 + j * VAGA.y))
	out.sort_custom(func(a: Vector2, b: Vector2): return a.x + a.y < b.x + b.y)
	return out


## Onde vai o próximo túmulo (Vector2.INF = cheio).
func vaga_pos() -> Vector2:
	var g := _grade()
	return g[covas.size()] if covas.size() < g.size() else Vector2.INF


## O padre enterrou: a cruz ou a lápide aparece com o nome e quando morreu. Devolve a posição.
func enterra(info: Dictionary) -> Vector2:
	var pos := vaga_pos()
	if not pos.is_finite():
		return Vector2.INF
	var c := {"nome": String(info.get("nome", "?")), "dia": int(info.get("dia", 1)), "estacao": String(info.get("estacao", "")),
		"causa": String(info.get("causa", "")), "vaga": covas.size()}
	var h := absi(hash(c.nome + str(c.dia)))
	c["tipo"] = "lapide" if h % 2 == 0 else "cruz"
	c["variante"] = (h / 7) % 3
	covas.append(c)
	_tumulos.append(_cria_tumulo(c, pos))
	_atualiza_placa()
	return pos


## O texto da lápide: o nome e quando morreu.
## (o dia do jogo; a estação fica de fora: o texto mais curto não encosta nas lápides vizinhas)
static func epitafio(c: Dictionary) -> String:
	return "%s · † dia %d" % [String(c.get("nome", "?")), int(c.get("dia", 1))]


func _cria_tumulo(c: Dictionary, pos: Vector2) -> Node2D:
	var t := Node2D.new()
	t.name = "Tumulo_%s" % String(c.nome).validate_node_name()
	t.position = pos
	t.set_meta("iso_prop", "cem_%s_%d" % [c.tipo, int(c.variante)])
	t.add_to_group("tumulos")
	# uma linha só, "Nome · † dia N" (duas etiquetas, ou uma de duas linhas, saíam desencontradas no espelho iso)
	var l := Label.new()
	l.name = "Lapide"
	l.text = epitafio(c)
	l.size = Vector2(110, 12)
	l.position = Vector2(-55, -24)  # (logo acima da lápide: a vista iso estica a altura)
	l.z_as_relative = false
	l.z_index = 4000  # na frente da cerca e das outras lápides (a vista iso ordena por z; o overlay dela é 4090)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", Tipo.MAPA_MINI)
	l.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 0.95))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 3)
	t.add_child(l)
	get_parent().add_child(t)
	return t


# ------------------------------------------------------------ a cerca (montada pelo estágio da obra)
## 1 estacas nos cantos, 2 os postes, 3 a cerca do fundo e dos lados, 4 pronto (cerca inteira + portão).
func estagio() -> int:
	return 4 if pronto else ObraEstagio.stage(obra_progress())


func _monta() -> void:
	if not is_inside_tree():
		return
	var e := estagio()
	if e == _estagio_desenhado:
		return
	_estagio_desenhado = e
	for n in _pecas:
		if is_instance_valid(n):
			n.queue_free()
	_pecas.clear()
	var a := rect.position
	var b := Vector2(rect.end.x, rect.position.y)
	var c := rect.end
	var d := Vector2(rect.position.x, rect.end.y)
	var nx := int(roundf(rect.size.x / TRECHO))
	var ny := int(roundf(rect.size.y / TRECHO))
	var portao := nx / 2  # o trecho do meio da frente (D -> C) vira o portão
	# postes: só os cantos no 1; nas emendas a partir do 2
	for p in [a, b, c, d]:
		_peca("cem_poste", p)
	if e >= 2:
		for i in range(1, nx):
			_peca("cem_poste", a.lerp(b, float(i) / nx))
			if not (e >= 4 and (i == portao or i == portao + 1)):
				_peca("cem_poste", d.lerp(c, float(i) / nx))
		for j in range(1, ny):
			_peca("cem_poste", a.lerp(d, float(j) / ny))
			_peca("cem_poste", b.lerp(c, float(j) / ny))
	if e >= 3:
		for i in nx:  # fundo (A -> B) e os lados
			_peca("cem_cerca", a.lerp(b, (i + 0.5) / nx))
		for j in ny:
			_peca("cem_cerca_y", a.lerp(d, (j + 0.5) / ny))
			_peca("cem_cerca_y", b.lerp(c, (j + 0.5) / ny))
		for i in nx:  # a frente: no 3 só a metade; pronto, inteira com o portão no meio
			if e < 4 and i >= nx / 2:
				continue
			if e >= 4 and i == portao:
				_peca("cem_portao", d.lerp(c, (i + 0.5) / nx))
			else:
				_peca("cem_cerca", d.lerp(c, (i + 0.5) / nx))


func _peca(nome: String, p: Vector2) -> void:
	var n := Node2D.new()
	n.name = "Cemiterio_" + nome
	n.position = p
	n.set_meta("iso_prop", nome)
	n.add_to_group("cemiterio_pecas")
	get_parent().add_child(n)
	_pecas.append(n)


func pecas() -> Array:
	return _pecas.filter(func(n): return is_instance_valid(n))


func _atualiza_placa() -> void:
	if _label == null:
		return
	if not pronto:
		_label.text = "Cemitério (obra)\n%s" % _obra.status(obra_progress())
	else:
		_label.text = "Cemitério  %d/%d" % [covas.size(), vagas_total()]


# ------------------------------------------------------------ interface de obra (obra_site.gd)
func obra_pending() -> bool:
	return not pronto


func obra_title() -> String:
	return "Cemitério"


func obra_progress() -> float:
	return 1.0 if pronto else clampf(feito / total, 0.0, 1.0)


func obra_position(worker: Node) -> Vector2:
	return Vector2(rect.get_center().x, rect.end.y + 14.0) + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	if pronto:
		return
	feito += seconds
	if feito >= total:
		pronto = true
		remove_from_group("obras")
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("Cemitério pronto! O padre traz quem se for e enterra aqui.", Color(0.55, 1.0, 0.5))
		var au := get_node_or_null("/root/Audio")  # (pelo nó: o script também é carregado fora do jogo)
		if au:
			au.recruit()
	_monta()
	_atualiza_placa()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


# ------------------------------------------------------------ save (calendario.gd guarda a lista)
func get_save_data() -> Dictionary:
	return {"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "total": total, "feito": feito,
		"pronto": pronto, "covas": covas.duplicate(true), "obra": _obra.get_save_data()}


## Antes de entrar na árvore (calendario.load_save_data).
func load_save_data(d: Dictionary) -> void:
	var r: Array = SaveUtil.array(d, "rect")
	if r.size() == 4:
		rect = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	position = rect.get_center()
	total = SaveUtil.num(d, "total", 30.0)
	feito = SaveUtil.num(d, "feito", 0.0)
	pronto = SaveUtil.boolean(d, "pronto", false)
	covas = []
	for c in SaveUtil.array(d, "covas"):
		if c is Dictionary and c.has("nome"):
			covas.append(c)
	if d.get("obra") is Dictionary:
		_obra.load_save_data(d.obra)


## Depois de entrar na árvore: os túmulos de volta.
func restaura_tumulos() -> void:
	var g := _grade()
	for i in covas.size():
		if i < g.size():
			_tumulos.append(_cria_tumulo(covas[i], g[i]))
	_atualiza_placa()
