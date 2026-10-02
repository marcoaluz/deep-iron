extends PanelContainer
## Janela do Robô antigo (clique no robô ou botão no HUD, que só aparece depois
## que ele é achado): mandar buscar, consertar e o status do Guarda Ferrugento.

var _hud: CanvasLayer
var _finds: Node
var _status: Label
var _desc: Label
var _button: Button
var _bar: ProgressBar


func setup(hud: CanvasLayer, finds: Node, _economy: Node) -> void:
	_hud = hud
	_finds = finds
	_build()
	visible = false


func _build() -> void:
	add_theme_stylebox_override("panel", _hud._panel_style())
	custom_minimum_size = Vector2(420, 0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title: Label = _hud._label("ROBÔ ANTIGO", 20, _hud.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = _hud._button("X")
	close.pressed.connect(func():
		Audio.click()
		visible = false)
	header.add_child(close)
	var lore: Label = _hud._label(
		"Um Ferrugento: máquina de antes da explosão solar, parada há décadas no fundo da mina. "
		+ "Consertado, ele fica do nosso lado.", 12, _hud.COLOR_DIM)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lore)
	_status = _hud._label("", 15, _hud.COLOR_TEXT)
	vbox.add_child(_status)
	_desc = _hud._label("", 12, _hud.COLOR_DIM)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_desc)
	_bar = _hud._bar(_hud.COLOR_TITLE)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.max_value = 1.0
	vbox.add_child(_bar)
	_button = _hud._button("")
	_button.pressed.connect(_on_button)
	vbox.add_child(_button)


func _robot() -> Node:
	return _finds.robot() if _finds else null


func _on_button() -> void:
	Audio.click()
	var r := _robot()
	if r == null:
		return
	if r.state == "found":
		var w: Node = r.request_carrier()
		if w == null:
			Audio.error()
			_hud.show_toast("Ninguém disponível pra buscar o robô (greve ou todos machucados).", Color(1.0, 0.6, 0.45))
		else:
			_hud.show_toast("%s vai buscar o robô." % _hud._worker_name(w), Color(0.5, 1.0, 0.95))
	elif r.state == "base":
		r.start_repair()
	refresh()


func refresh() -> void:
	if not visible:
		return
	var r := _robot()
	if r == null:
		visible = false
		return
	_bar.visible = r.state == "repairing"
	_button.visible = r.state in ["found", "base"]
	_button.disabled = false
	match r.state:
		"found":
			_status.text = "Caído onde foi achado"
			if r.carrier != null and is_instance_valid(r.carrier):
				_desc.text = "%s está indo buscar. Carregar deixa o ipezinho bem mais lento." % _hud._worker_name(r.carrier)
				_button.text = "Já tem gente indo buscar"
				_button.disabled = true
			else:
				_desc.text = "Mande um ipezinho carregar o robô até a Oficina (vem até pelo elevador)."
				_button.text = "Mandar buscar"
				var ofi := get_tree().get_first_node_in_group("oficina")
				if ofi and ofi.has_method("is_built") and not ofi.is_built():
					_button.text = "Precisa da Oficina construída (menu de construção)"  # Bloco 58
					_button.disabled = true
		"carried":
			_status.text = "Sendo carregado por %s" % (_hud._worker_name(r.carrier) if r.carrier and is_instance_valid(r.carrier) else "alguém")
			_desc.text = "Destino: ao lado da Oficina."
		"base":
			_status.text = "Na Oficina, esperando conserto"
			var reason: String = r.repair_block_reason()
			_desc.text = "Conserto: %d peças raras + %d cr + %d ferro, %ds de trabalho. Você tem %d peças raras." % [
				r.repair_parts, r.repair_credits, r.repair_ore, roundi(r.repair_time), _finds.rare_parts]
			_button.text = "Consertar" if reason == "" else "Consertar: " + reason
			_button.disabled = reason != ""
		"repairing":
			_status.text = "Consertando... faltam %ds" % ceili(r.repair_left)
			_desc.text = "Quase lá."
			_bar.value = 1.0 - r.repair_left / r.repair_time
		"active":
			_status.text = "GUARDA FERRUGENTO — ativo"
			_desc.text = "De dia vigia o Centro da Vila; à noite patrulha as casas. A vila dorme mais tranquila (+%d de ânimo pra todos)." % roundi(r.guard_bonus)


func is_available() -> bool:
	return _robot() != null


func button_text() -> String:
	var r := _robot()
	if r == null:
		return ""
	match r.state:
		"found":
			return "Robô: buscar"
		"carried":
			return "Robô: a caminho"
		"base":
			return "Robô: consertar"
		"repairing":
			return "Robô %d%%" % roundi((1.0 - r.repair_left / r.repair_time) * 100.0)
	return "Guarda ativo"


func has_available_action() -> bool:
	var r := _robot()
	return r != null and ((r.state == "found" and r.carrier == null) or (r.state == "base" and r.repair_block_reason() == ""))
