extends Node2D
## Bloco 103: o CORPO de uma criatura abatida (grupo "corpos_criatura"), caído onde ela morreu.
##
## - O desenho é o ÚLTIMO QUADRO da animação "morrer" da própria criatura (a mesma arte, nada novo): na vista iso pela
##   pose da criatura (iso_bonecos.criatura_pose, com _dying e o relógio lá na frente); a de folha de quadros (o
##   Ferrugento do Bloco 80) recorta o quadro da folha.
## - Fica até o amanhecer seguinte + catalogo.horas_corpo, ou até ser estudado (a pesquisadora colhe o que ele deixou).
##   Passou do prazo: o que ele deixou vai pro armazém (o total não muda) e ele some.
## - O DROP sorteado na morte (as mesmas chances de sempre) fica aqui: {item: quantidade}.
## Não vai pro save (o pedido permite): carregar o jogo não traz corpos.

var kind := "lumivoro"
var variant := ""
## A espécie no catálogo (lumivoro, ferrugento, gosma, magmante, matriarca).
var especie := "lumivoro"
var drop := {}
## O prazo: o dia e o momento (segundos desde o amanhecer, como o DayNight.time) em que ele some.
var prazo_dia := 1
var prazo_t := 0.0
## O andar onde caiu (id do nivel: S1, S2...).
var andar := "S1"
## Imitam a criatura pra pose da vista iso (morrer, parado no último quadro).
var visual_textura: Texture2D = null
var _anim := 1000.0
var _dying := true
var _died_at := 0.0
var _leaving := false
var _hit_at := -100.0
var _attack_at := -100.0
var _visual: Sprite2D


func _init() -> void:
	add_to_group("corpos_criatura")  # (no _init: a vista iso decide o espelho quando ele entra na árvore)


## Copia da criatura que caiu: o tipo, a variante, o desenho (o último quadro da morte) e o lugar.
func monta(c: Node2D) -> void:
	kind = String(c.kind)
	variant = String(c.variant)
	especie = "matriarca" if c.is_in_group("chefes") else kind
	name = "Corpo_%s_%d" % [kind, get_instance_id()]
	position = c.global_position
	_visual = Sprite2D.new()
	_visual.name = "Visual"
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var vs: Sprite2D = c.get_node_or_null("Visual")
	if c.get("visual_textura") != null:
		visual_textura = c.visual_textura
		var linha: int = maxi(c.visual_anims.find("morrer"), 0)
		var n: int = maxi(c.visual_quadros[linha] if linha < c.visual_quadros.size() else 1, 1)
		_visual.texture = visual_textura
		_visual.region_enabled = true
		_visual.region_rect = Rect2(Vector2((n - 1) * c.visual_quadro.x, linha * c.visual_quadro.y), Vector2(c.visual_quadro))
		_visual.offset = Vector2(0.0, -float(c.visual_quadro.y) * 0.5 + float(c.visual_pe))
		_visual.scale = Vector2.ONE * float(c.visual_escala)
		_visual.flip_h = vs.flip_h if vs else false
	elif vs:
		_visual.texture = vs.texture
		_visual.hframes = vs.hframes
		_visual.vframes = vs.vframes
		_visual.frame = vs.frame
		_visual.scale = vs.scale
		_visual.offset = vs.offset
		_visual.rotation = PI * 0.5  # (o mapa antigo: deitado)
	_visual.modulate = Color(0.8, 0.78, 0.76)
	add_child(_visual)
	var env := c.get_tree().get_first_node_in_group("environment")
	var nv: Resource = preload("res://scripts/core/niveis.gd").do_ponto(env, c.global_position) if env else null
	andar = String(nv.id) if nv else "S1"


func is_alive() -> bool:
	return false


func vencido(dia: int, t: float) -> bool:
	return dia > prazo_dia or (dia == prazo_dia and t >= prazo_t)


## O que ele deixou vai pro armazém (estudo ou prazo). Retorna o texto ("2 cristais verdes") ou "".
func entrega_drop() -> String:
	var partes: Array[String] = []
	var eco := get_tree().get_first_node_in_group("economy")
	var Items := preload("res://scripts/core/items.gd")
	for it in drop:
		var q := float(drop[it])
		if q <= 0.0:
			continue
		if it == "pecas":
			var finds := get_tree().get_first_node_in_group("finds")
			if finds:
				finds.rare_parts += int(q)
			partes.append("%d peça%s rara%s" % [int(q), "s" if q > 1 else "", "s" if q > 1 else ""])
		elif eco:
			eco.devolve(it, q, global_position)  # (minério entra mesmo com o armazém cheio, como devolução)
			partes.append("%d %s" % [int(q), Items.plural(it) if q > 1 else Items.nome(it).to_lower()])
	drop = {}
	return ", ".join(partes)
