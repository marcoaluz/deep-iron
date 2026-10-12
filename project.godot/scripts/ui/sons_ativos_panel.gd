extends CanvasLayer
## Bloco 131: "Som: o que está tocando agora" (F3). Lista AO VIVO os sons ativos — id do slot, bus, volume em dB (o do player
## somado ao do bus), distância até o centro da câmera, se é loop — com um botão pra silenciar cada um (e voltar). É pra achar
## o som chato da noite ouvindo: silencia um por um até o incômodo sumir. Nada aqui vai pro save.

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")

## Segundos entre as atualizações da lista.
@export var intervalo: float = 0.25

var _painel: PanelContainer
var _lista: VBoxContainer
var _resumo: Label
var _t := 0.0


func _ready() -> void:
	name = "SonsAtivos"
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiSkin.tema_na_camada(self)
	add_to_group("sons_ativos")
	_painel = PanelContainer.new()
	_painel.add_theme_stylebox_override("panel", UiSkin.painel(6) if UiSkin.ok() else StyleBoxFlat.new())
	_painel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_painel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_painel.offset_right = -20.0
	_painel.custom_minimum_size = Vector2(560, 0)
	add_child(_painel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_painel.add_child(v)
	var topo := HBoxContainer.new()
	v.add_child(topo)
	var t := Label.new()
	t.text = "SOM: O QUE ESTÁ TOCANDO AGORA"
	t.add_theme_font_size_override("font_size", Tipo.TITULO)
	t.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(t)
	var fecha := Button.new()
	fecha.text = "X"
	fecha.pressed.connect(func(): visible = false)
	topo.add_child(fecha)
	_resumo = Label.new()
	_resumo.add_theme_font_size_override("font_size", Tipo.DETALHE)
	_resumo.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6))
	v.add_child(_resumo)
	var rol := ScrollContainer.new()
	rol.custom_minimum_size = Vector2(540, 380)
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(rol)
	_lista = VBoxContainer.new()
	_lista.name = "Lista"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 2)
	rol.add_child(_lista)
	visible = false


func abre() -> void:
	visible = true
	atualiza()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t >= intervalo:
		_t = 0.0
		atualiza()


func _audio() -> Node:
	return get_node_or_null("/root/Audio")


## Refaz a lista com o que toca agora (o mesmo slot com vários players aparece uma vez, com a contagem).
func atualiza() -> void:
	var au := _audio()
	if au == null or not au.has_method("sons_ativos"):
		return
	var por_id := {}
	var ordem: Array = []
	for s in au.sons_ativos():
		var id: String = s.id if String(s.id) != "" else "(sem nome)"
		if not por_id.has(id):
			por_id[id] = {"id": id, "bus": s.bus, "db": s.db, "dist": s.dist, "loop": s.loop, "n": 0}
			ordem.append(id)
		var r: Dictionary = por_id[id]
		r.n += 1
		r.db = maxf(float(r.db), float(s.db))
		if float(s.dist) >= 0.0 and (float(r.dist) < 0.0 or float(s.dist) < float(r.dist)):
			r.dist = s.dist
	# os silenciados continuam na lista (pra voltar), mesmo sem tocar agora
	for id in au.silenciados:
		if not por_id.has(id):
			por_id[id] = {"id": id, "bus": "-", "db": -80.0, "dist": -1.0, "loop": false, "n": 0}
			ordem.append(id)
	for c in _lista.get_children():
		_lista.remove_child(c)
		c.queue_free()
	for id in ordem:
		_lista.add_child(_linha(por_id[id], au))
	_resumo.text = "%d sons tocando  •  %d silenciados  •  o volume é o do player + o do bus (antes do Master)" % [
		ordem.size() - au.silenciados.size(), au.silenciados.size()]


func _linha(r: Dictionary, au: Node) -> Control:
	var h := HBoxContainer.new()
	h.name = "Som_" + String(r.id).replace("/", "_")
	h.add_theme_constant_override("separation", 6)
	var mudo: bool = au.silenciado(String(r.id))
	var l := Label.new()
	l.text = "%s%s  •  %s  •  %s dB  •  %s%s" % [r.id, (" x%d" % r.n) if int(r.n) > 1 else "", r.bus,
		("%.1f" % float(r.db)) if float(r.db) > -79.0 else "-", ("%d px" % int(r.dist)) if float(r.dist) >= 0.0 else "sem posição",
		"  •  LOOP" if r.loop else ""]
	l.add_theme_font_size_override("font_size", Tipo.DETALHE)
	l.add_theme_color_override("font_color", Color(0.55, 0.52, 0.5) if mudo else Color(0.92, 0.88, 0.8))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	h.add_child(l)
	var b := Button.new()
	b.text = "Voltar" if mudo else "Silenciar"
	b.add_theme_font_size_override("font_size", Tipo.DETALHE)
	b.custom_minimum_size.x = 86
	var id: String = r.id
	b.pressed.connect(func():
		au.silenciar(id, not au.silenciado(id))
		atualiza())
	h.add_child(b)
	return h
