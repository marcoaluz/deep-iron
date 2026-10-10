extends PanelContainer
## Bloco 110: a FICHA do ipezinho (botão "Ficha" no cartão do selecionado): os TRAÇOS (com o que fazem), as HABILIDADES por
## função (a prática), os AMIGOS (com o nível) e o PARCEIRO (namorando / casado). Só leitura: o jogador não escolhe amigos
## nem casais — influencia pelo ambiente. Fora do menu Janelas (é de uma pessoa). Padrão visual das janelas do layout v2.
const Tipo := preload("res://scripts/ui/tipografia.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")

var _hud: CanvasLayer
var _rel: Node
var _w: Node = null
var _titulo: Label
var _retrato: TextureRect
var _funcao: Label
var _tracos: Label
var _habil: Label
var _amigos: Label
var _parceiro: Label
var _familia: Label  # Bloco 111


func setup(hud: CanvasLayer, rel: Node, _economy: Node) -> void:
	_hud = hud
	_rel = rel
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(440, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	_retrato = TextureRect.new()
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.custom_minimum_size = Vector2(72, 72)
	header.add_child(_retrato)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(tv)
	_titulo = _hud._label("", Tipo.TITULO_JANELA, _hud.COLOR_TITLE)
	tv.add_child(_titulo)
	_funcao = _hud._label("", Tipo.DETALHE, _hud.COLOR_TEXT)
	tv.add_child(_funcao)
	var close: Button = _hud._button("X")
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	_tracos = _secao(vbox, "TRAÇOS")
	_habil = _secao(vbox, "HABILIDADES (sobem com a prática)")
	_amigos = _secao(vbox, "AMIGOS")
	_parceiro = _secao(vbox, "PARCEIRO")
	_familia = _secao(vbox, "FAMÍLIA")


func _secao(vbox: VBoxContainer, titulo: String) -> Label:
	vbox.add_child(_hud._label(titulo, Tipo.TITULO, _hud.COLOR_TITLE))
	var l: Label = _hud._label("", Tipo.CORPO, _hud.COLOR_TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(l)
	return l


func focus(node: Node) -> void:
	if node != null and node.is_in_group("ipezinhos"):
		_w = node


func refresh() -> void:
	if not visible or _rel == null:
		return
	if _w == null or not is_instance_valid(_w):
		_titulo.text = "Ninguém selecionado"
		return
	_titulo.text = _hud._worker_name(_w)
	_retrato.texture = Retratos.de(_w)
	var sec: String = (" • secundária: %s" % _w.nome_funcao(_w.secundaria())) if _w.has_method("secundaria") and _w.secundaria() != "" else ""
	_funcao.text = "%s%s • ânimo %d" % ["sem função" if _w.has_no_job() else String(_w.job), sec, roundi(_w.happiness)]
	var tl: Array = []
	for t in _w.tracos_de():
		var info: Dictionary = _rel.TRACOS.get(t, {})
		tl.append("%s — %s" % [info.get("nome", t), info.get("texto", "")])
	_tracos.text = "\n".join(tl) if not tl.is_empty() else "—"
	var hl: Array = []
	var hab: Dictionary = _w.habilidade
	var chaves: Array = hab.keys()
	chaves.sort_custom(func(a, b): return float(hab[a]) > float(hab[b]))
	for f in chaves:
		if float(hab[f]) >= 0.01:
			hl.append("%s %s %d%% (+%d%% de produção)" % [String(f), _estrelas(float(hab[f])), roundi(float(hab[f]) * 100.0),
				roundi(float(hab[f]) * _rel.habilidade_bonus * 100.0)])
	if _w.is_guard():
		hl.append("combate %s %d%%" % [_estrelas(minf(float(_w.combat_skill), 1.0)), roundi(float(_w.combat_skill) * 100.0)])
	_habil.text = "\n".join(hl) if not hl.is_empty() else "Ainda aprendendo (trabalhar na função faz subir)."
	var al: Array = []
	for par in _rel.amigos_de(_w):
		if int(par[1]) < 5:
			al.append("%s — %s" % [_hud._worker_name(par[0]), _rel.nome_nivel(int(par[1]))])
	_amigos.text = "\n".join(al.slice(0, 6)) if not al.is_empty() else "Ainda não fez amigos (a hora social, o trabalho lado a lado e as festas aproximam)."
	var p: Node = _rel.parceiro_de(_w)
	_parceiro.text = ("%s — %s" % [_hud._worker_name(p), "casados" if _rel.casado(_w) else "namorando"]) if p != null else "Ninguém (o jogador não escolhe: a convivência decide)."
	_familia.text = _texto_familia()


## Bloco 111: a fase, os pais, os filhos, a gravidez e o estudo.
func _texto_familia() -> String:
	var fam := get_tree().get_first_node_in_group("familias")
	var l: Array = []
	if _w.e_crianca() and fam:
		var dias: float = float(_w.idade_s) / maxf(fam._seg_dia(), 1.0)
		l.append("%s, %d dias%s" % [fam.NOME_FASE.get(_w.fase, _w.fase), int(dias), ("; estudo %d%%" % roundi(float(_w.estudo) * 100.0)) if float(_w.estudo) > 0.0 else ""])
	var nomes := func(lista: Array) -> String:
		var out: Array = []
		for n in lista:
			for o in get_tree().get_nodes_in_group("ipezinhos"):
				if String(o.name) == String(n):
					out.append(_hud._worker_name(o) + (" (%s)" % fam.NOME_FASE.get(o.fase, "") if fam and o.e_crianca() else ""))
		return ", ".join(out)
	var ps: String = nomes.call(_w.pais)
	if ps != "":
		l.append("Pais: " + ps)
	var fs: String = nomes.call(_w.filhos)
	if fs != "":
		l.append("Filhos: " + fs)
	if _w.gravida() and fam:
		l.append("Esperando um filho (faltam %d dias)" % ceili(float(_w.gravidez_s) / maxf(fam._seg_dia(), 1.0)))
	return "\n".join(l) if not l.is_empty() else "—"


## O grau em palavra (a fonte do jogo não tem estrela).
static func _estrelas(x: float) -> String:
	return "(aprendiz)" if x < 0.34 else ("(bom)" if x < 0.67 else "(mestre)")


func button_text() -> String:
	return "Ficha"


func is_available() -> bool:
	return false  # (abre pelo cartão do selecionado)


func has_available_action() -> bool:
	return false
