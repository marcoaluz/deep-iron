extends VBoxContainer
## Tela de configurações. Usada no menu de pausa e na tela inicial. Cada mudança já vale na hora e
## fica salva em settings.cfg (e volta ao abrir o jogo).
## Bloco 54: duas colunas — SOM E VÍDEO (volumes, música, tela cheia, escala da interface) e JOGO
## (velocidade da câmera e do zoom, reduzir efeitos, idioma, dicas, teclas). "Teclas..." abre a
## página de remapear (clique na ação e aperte a tecla nova; Esc cancela; "Restaurar padrão").
## Bloco 135: o conteúdo rola (ScrollContainer com a altura limitada à tela, em qualquer resolução e escala) e o RODAPÉ
## fica sempre visível e fixo: CANCELAR (e Esc) desfaz tudo o que mudou desde que a tela abriu (o settings.cfg volta como
## estava e tudo é reaplicado: volumes, música, tela cheia, escala, idioma, câmera, efeitos, teclas) e CONCLUIR guarda.

signal back_pressed

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const Settings := preload("res://scripts/core/settings.gd")
const Teclas := preload("res://scripts/core/teclas.gd")
const Efeitos := preload("res://scripts/core/efeitos.gd")
const Camera := preload("res://scripts/core/camera_controller.gd")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const COLOR_TITLE := Color(1.0, 0.8, 0.35)
const COLOR_TEXT := Color(0.92, 0.88, 0.8)
const COLOR_DIM := Color(0.7, 0.66, 0.6)

var _fullscreen: CheckBox
var _main_page: VBoxContainer
var _keys_page: VBoxContainer
var _key_buttons := {}  # ação -> Button
var _waiting := ""  # ação esperando a tecla nova
var _scale_note: Label
## Bloco 135: a parte que rola, o rodapé fixo e o retrato das configurações de quando a tela abriu.
var _scroll: ScrollContainer
var _paginas: VBoxContainer
var _rodape: HBoxContainer
var cancelar: Button
var concluir: Button
var _foto := ""
var _foto_estado := {}
## px (da interface) reservados fora da parte que rola: o rodapé, a moldura da janela e uma margem da tela.
const RESERVA_ALTURA := 150.0
## px (da interface) livres entre a janela e a borda da tela.
const MARGEM_TELA := 8.0
## As variáveis do Audio que vão pro settings.cfg (o retrato guarda e o Cancelar devolve).
const CHAVES_AUDIO := ["master_volume", "music_volume", "ambience_volume", "sfx_volume", "ui_volume", "voz_ligada",
	"musica_dinamica", "mix_melodia", "mix_pad", "mix_percussao", "soltos_volume"]


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_scroll = ScrollContainer.new()
	_scroll.name = "Rolagem"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_paginas = VBoxContainer.new()
	_paginas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_paginas)
	_main_page = VBoxContainer.new()
	_main_page.add_theme_constant_override("separation", 10)
	_paginas.add_child(_main_page)
	_keys_page = VBoxContainer.new()
	_keys_page.add_theme_constant_override("separation", 8)
	_keys_page.visible = false
	_paginas.add_child(_keys_page)
	_build_main()
	_build_keys()
	_build_rodape()
	visibility_changed.connect(_ao_mostrar)
	get_viewport().size_changed.connect(func(): _ajusta_altura.call_deferred())
	_ajusta_altura.call_deferred()


func _ao_mudar_escala(_f: float) -> void:
	_update_scale_note()
	_ajusta_altura.call_deferred()


## O rodapé fixo: Cancelar (desfaz) e Concluir (guarda).
func _build_rodape() -> void:
	_rodape = HBoxContainer.new()
	_rodape.name = "Rodape"
	_rodape.add_theme_constant_override("separation", 12)
	add_child(_rodape)
	cancelar = Button.new()
	cancelar.name = "Cancelar"
	cancelar.text = "Cancelar  (Esc)"
	cancelar.custom_minimum_size = Vector2(0, 38)
	cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancelar.pressed.connect(func():
		Audio.click()
		cancela())
	_rodape.add_child(cancelar)
	concluir = Button.new()
	concluir.name = "Concluir"
	concluir.text = "Concluir"
	concluir.custom_minimum_size = Vector2(0, 38)
	concluir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	concluir.pressed.connect(func():
		Audio.click()
		conclui())
	_rodape.add_child(concluir)


## A altura da parte que rola: o conteúdo inteiro, mas nunca mais que a tela (menos o rodapé e a moldura). Depois de
## assentar, confere quanto a janela ainda passa da tela (a moldura de quem a contém varia) e encolhe nessa medida.
func _ajusta_altura(tentativa: int = 0) -> void:
	if not is_inside_tree() or _scroll == null:
		return
	var tela := get_viewport().get_visible_rect()
	var conteudo := _paginas.get_combined_minimum_size()
	var alt := clampf(conteudo.y, 120.0, maxf(tela.size.y - RESERVA_ALTURA, 120.0))
	if tentativa > 0:
		var r := get_global_rect()
		var sobra_baixo := r.end.y - (tela.end.y - MARGEM_TELA)
		var sobra_cima := (tela.position.y + MARGEM_TELA) - r.position.y
		var excesso := maxf(sobra_baixo, sobra_cima)
		if excesso <= 0.5:
			return
		alt = maxf(_scroll.custom_minimum_size.y - ceilf(excesso), 120.0)  # (aos poucos: centrada, a base sobe só metade)
	_scroll.custom_minimum_size = Vector2(conteudo.x, alt)
	if tentativa < 8 and is_visible_in_tree():
		await get_tree().process_frame
		_ajusta_altura(tentativa + 1)


func _ao_mostrar() -> void:
	if not is_visible_in_tree():
		return
	_foto = FileAccess.get_file_as_string(Settings.PATH) if FileAccess.file_exists(Settings.PATH) else ""
	_foto_estado = {"musica": Audio.music_enabled, "tela_cheia": WindowManager.is_fullscreen(), "idioma": WindowManager.language(),
		"audio": {}}
	for k in CHAVES_AUDIO:
		_foto_estado.audio[k] = Audio.get(k)
	_show_keys(false)
	_scroll.scroll_vertical = 0
	_ajusta_altura.call_deferred()


## Concluir: o que mudou já está salvo; só fecha.
func conclui() -> void:
	_waiting = ""
	back_pressed.emit()


## Cancelar (ou Esc): o settings.cfg volta ao que era quando a tela abriu e tudo é reaplicado.
func cancela() -> void:
	_waiting = ""
	if not _foto_estado.is_empty():
		if Audio.music_enabled != bool(_foto_estado.musica):
			Audio.toggle_music()
		if WindowManager.is_fullscreen() != bool(_foto_estado.tela_cheia):
			WindowManager.set_fullscreen(bool(_foto_estado.tela_cheia))
		if WindowManager.language() != String(_foto_estado.idioma):
			WindowManager.set_language(String(_foto_estado.idioma))
		if _foto != "":
			var f := FileAccess.open(Settings.PATH, FileAccess.WRITE)
			if f:
				f.store_string(_foto)
				f.close()
		elif FileAccess.file_exists(Settings.PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.PATH))
		for k in _foto_estado.audio:  # (a chave pode não existir no arquivo: a variável volta direto)
			Audio.set(k, _foto_estado.audio[k])
		_reaplica()
	back_pressed.emit()


## Tudo o que lê o settings.cfg volta a ler (e a tela se refaz com os valores de volta).
func _reaplica() -> void:
	Audio._load_settings()
	Audio.apply_volumes()
	Audio.aplica_musica_dinamica()
	WindowManager._reapply_ui_scale()
	Camera.load_speeds()
	Efeitos.set_reduzidos(Efeitos.reduzidos(), get_tree())
	get_tree().call_group("efeitos", "efeitos_mudaram")
	Teclas._por_tecla.clear()
	Teclas._carrega()
	var Ipe: GDScript = load("res://scripts/workers/ipezinho.gd")
	Ipe.baloes_motivo = bool(Settings.get_value("hud", "baloes_motivo", true))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_hints_visible"):
		hud.set_hints_visible(bool(Settings.get_value("hud", "show_hints", false)))
	for c in _main_page.get_children():  # a página refeita com os valores de volta
		_main_page.remove_child(c)
		c.queue_free()
	_build_main()


## Esc com a tela aberta (e sem esperar tecla): cancela, antes do menu de pausa tratar o Esc.
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _waiting != "":
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _keys_page.visible:
			_show_keys(false)
		else:
			cancela()


func _build_main() -> void:
	var title := _label("CONFIGURAÇÕES", Tipo.TITULO_JANELA, COLOR_TITLE)
	UiSkin.usa_fonte(title, "titulo", Tipo.PIXEL_2)  # Prompt 22
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_page.add_child(title)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	_main_page.add_child(cols)
	var left := _column(cols, "SOM E VÍDEO")
	var right := _column(cols, "JOGO")

	_slider(left, "Volume geral", "master_volume")
	_slider(left, "Música", "music_volume")
	_slider(left, "Ambiência (floresta, mina, chuva)", "ambience_volume")
	_slider(left, "Sons soltos (coruja, sapo, trovão...)", "soltos_volume")  # Bloco 131: separado da ambiência
	_slider(left, "Efeitos", "sfx_volume")
	_slider(left, "Interface (cliques, avisos)", "ui_volume")  # Bloco 114: o bus UI
	var music := CheckBox.new()
	music.text = "Música ligada  (M)"
	music.button_pressed = Audio.music_enabled
	music.toggled.connect(func(on: bool):
		if on != Audio.music_enabled:
			Audio.toggle_music())
	left.add_child(music)
	var voz := CheckBox.new()  # Bloco 114: a voz curta dos ipezinhos
	voz.text = "Voz dos ipezinhos"
	voz.button_pressed = Audio.voz_ligada
	voz.toggled.connect(func(on: bool):
		Audio.voz_ligada = on
		Audio.save_settings())
	left.add_child(voz)
	var camadas := CheckBox.new()  # Bloco 121: a música em camadas (estação, dia, noite e perigo)
	camadas.text = "Música em camadas (estação, dia, noite, perigo)"
	camadas.button_pressed = Audio.musica_dinamica
	camadas.toggled.connect(func(on: bool):
		Audio.musica_dinamica = on
		Audio.aplica_musica_dinamica())
	left.add_child(camadas)
	for linha in [["  Melodia (dia)", "mix_melodia"], ["  Base e pad (noite)", "mix_pad"], ["  Percussão (perigo)", "mix_percussao"]]:
		_percent(left, linha[0], float(Audio.get(linha[1])), 0.0, 1.0, 0.05, func(v: float):
			Audio.set(linha[1], v)
			Audio.aplica_musica_dinamica())
	# Bloco 48: tela cheia (F11 / Alt+Enter também alternam; a escolha fica salva)
	_fullscreen = CheckBox.new()
	_fullscreen.text = "Tela cheia  (F11 / Alt+Enter)"
	_fullscreen.button_pressed = WindowManager.is_fullscreen()
	_fullscreen.toggled.connect(func(on: bool):
		Audio.click()
		WindowManager.set_fullscreen(on))
	left.add_child(_fullscreen)
	if not WindowManager.fullscreen_changed.is_connected(_on_fullscreen_changed):
		WindowManager.fullscreen_changed.connect(_on_fullscreen_changed)
	# Bloco 54: escala da interface (limitada pra caber na janela). Bloco 95: 3 opções (90 / 100 / 125%).
	var esc_row := HBoxContainer.new()
	esc_row.add_theme_constant_override("separation", 6)
	esc_row.name = "Escala"
	left.add_child(esc_row)
	var el := _label("Escala da interface", Tipo.TITULO, COLOR_TEXT)
	el.custom_minimum_size.x = 150
	esc_row.add_child(el)
	var grupo := ButtonGroup.new()
	for op in WindowManager.UI_SCALES:
		var b := Button.new()
		b.text = "%d%%" % roundi(op * 100.0)
		b.toggle_mode = true
		b.button_group = grupo
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(56, 30)
		b.button_pressed = is_equal_approx(op, WindowManager.ui_scale())
		b.pressed.connect(func():
			Audio.click()
			WindowManager.set_ui_scale(op))
		esc_row.add_child(b)
	_scale_note = _label("", Tipo.DETALHE, COLOR_DIM)
	left.add_child(_scale_note)
	if not WindowManager.ui_scale_changed.is_connected(_ao_mudar_escala):
		WindowManager.ui_scale_changed.connect(_ao_mudar_escala)
	_update_scale_note()

	_percent(right, "Velocidade da câmera", Settings.get_value("camera", "pan_mult", 1.0), 0.5, 2.0, 0.1, func(v: float):
		Settings.set_value("camera", "pan_mult", v)
		Camera.load_speeds())
	_percent(right, "Velocidade do zoom", Settings.get_value("camera", "zoom_mult", 1.0), 0.5, 2.0, 0.1, func(v: float):
		Settings.set_value("camera", "zoom_mult", v)
		Camera.load_speeds())
	_percent(right, "Atmosfera dos níveis", Settings.get_value("video", "atmosfera", 1.0), 0.0, 1.0, 0.1, func(v: float):
		Settings.set_value("video", "atmosfera", v)
		get_tree().call_group("efeitos", "efeitos_mudaram"))  # Bloco 69
	var fx := CheckBox.new()
	fx.text = "Reduzir efeitos (clima, tremor, partículas)"
	fx.button_pressed = Efeitos.reduzidos()
	fx.toggled.connect(func(on: bool):
		Audio.click()
		Efeitos.set_reduzidos(on, get_tree()))
	right.add_child(fx)
	var hints := CheckBox.new()
	hints.text = "Mostrar dicas de controle  (H)"
	hints.button_pressed = Settings.get_value("hud", "show_hints", false)
	hints.toggled.connect(func(on: bool):
		Settings.set_value("hud", "show_hints", on)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("set_hints_visible"):
			hud.set_hints_visible(on))
	right.add_child(hints)
	var motivo := CheckBox.new()  # Bloco 95: o ícone sobre quem está parado (sem trabalho, sem ferramenta...)
	motivo.text = "Balões de motivo (por que está parado)"
	motivo.button_pressed = Settings.get_value("hud", "baloes_motivo", true)
	motivo.toggled.connect(func(on: bool):
		Audio.click()
		Settings.set_value("hud", "baloes_motivo", on)
		var Ipe: GDScript = load("res://scripts/workers/ipezinho.gd")
		Ipe.baloes_motivo = on
		Ipe._baloes_lido = true)
	right.add_child(motivo)
	var intro_box := CheckBox.new()  # Bloco 129: a introdução roda em toda partida nova (Esc pula)
	intro_box.text = "Introdução em toda partida nova"
	intro_box.button_pressed = Settings.get_value("jogo", "intro_ligada", true)
	intro_box.toggled.connect(func(on: bool):
		Audio.click()
		Settings.set_value("jogo", "intro_ligada", on))
	right.add_child(intro_box)
	var guia := CheckBox.new()  # Bloco 112: o capataz e as setas do primeiro dia (a missão continua valendo sem eles)
	guia.text = "Primeiro dia guiado (capataz e setas)"
	guia.button_pressed = Settings.get_value("jogo", "guia_primeiro_dia", true)
	guia.toggled.connect(func(on: bool):
		Audio.click()
		Settings.set_value("jogo", "guia_primeiro_dia", on)
		var g := get_tree().get_first_node_in_group("guia")
		if g and g.has_method("ligado_mudou"):
			g.ligado_mudou())
	right.add_child(guia)
	# idioma
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 10)
	right.add_child(lang_row)
	var ll := _label("Idioma", Tipo.TITULO, COLOR_TEXT)
	ll.custom_minimum_size.x = 150
	lang_row.add_child(ll)
	var lang := OptionButton.new()
	lang.name = "Idioma"
	for i in WindowManager.IDIOMAS.size():
		lang.add_item(WindowManager.IDIOMAS[i][1], i)
		lang.set_item_metadata(i, WindowManager.IDIOMAS[i][0])
		if WindowManager.IDIOMAS[i][0] == WindowManager.language():
			lang.select(i)
	lang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang.item_selected.connect(func(i: int):
		Audio.click()
		WindowManager.set_language(String(lang.get_item_metadata(i))))
	lang_row.add_child(lang)
	right.add_child(_label("(inglês parcial: textos com números seguem em português)", Tipo.DETALHE, COLOR_DIM))
	var keys := Button.new()
	keys.text = "Teclas..."
	keys.custom_minimum_size = Vector2(0, 34)
	keys.pressed.connect(func():
		Audio.click()
		_show_keys(true))
	right.add_child(keys)

	# (Bloco 135: sem "Voltar" aqui: o rodapé fixo tem Cancelar e Concluir)


func _column(parent: Container, titulo: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size.x = 340
	parent.add_child(v)
	v.add_child(_label(titulo, Tipo.CORPO, COLOR_TITLE))
	return v


func _update_scale_note() -> void:
	if _scale_note == null:
		return
	var want := WindowManager.ui_scale()
	var got := WindowManager.applied_ui_scale()
	_scale_note.text = "" if is_equal_approx(want, got) else "nesta janela cabe até %d%% (usando %d%%)" % [roundi(WindowManager.max_ui_scale() * 100.0), roundi(got * 100.0)]


## F11 com a janela aberta: a caixinha acompanha.
func _on_fullscreen_changed(on: bool) -> void:
	if _fullscreen:
		_fullscreen.set_pressed_no_signal(on)


## Linha "nome  [====slider====]  75%" ligada a uma variável de volume do Audio.
func _slider(parent: Container, text: String, audio_var: String) -> void:
	_percent(parent, text, float(Audio.get(audio_var)), 0.0, 1.0, 0.05, func(v: float):
		Audio.set(audio_var, v)
		Audio.apply_volumes()
		Audio.save_settings())


## Linha "nome  [====slider====]  100%" de um valor entre lo e hi (mostrado em %).
func _percent(parent: Container, text: String, value: float, lo: float, hi: float, step: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var name_label := _label(text, Tipo.TITULO, COLOR_TEXT)
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.name = text
	slider.min_value = lo * 100.0
	slider.max_value = hi * 100.0
	slider.step = step * 100.0
	slider.value = roundf(value * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := _label("%d%%" % slider.value, Tipo.CORPO, COLOR_TEXT)
	value_label.custom_minimum_size.x = 44
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float):
		value_label.text = "%d%%" % v
		on_change.call(v / 100.0))
	slider.drag_ended.connect(func(_changed: bool): Audio.click())
	return slider


# ------------------------------------------------------------ teclas (Bloco 54)
func _build_keys() -> void:
	var title := _label("TECLAS", Tipo.TITULO_JANELA, COLOR_TITLE)
	UiSkin.usa_fonte(title, "titulo", Tipo.PIXEL_2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keys_page.add_child(title)
	_keys_page.add_child(_label("Clique numa ação e aperte a tecla nova (Esc cancela). Se outra ação usava a tecla, as duas trocam.", Tipo.DETALHE, COLOR_DIM))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_keys_page.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for par in Teclas.NOMES:
		var l := _label(par[1], Tipo.CORPO, COLOR_TEXT)
		l.custom_minimum_size.x = 190
		grid.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(120, 26)
		b.focus_mode = Control.FOCUS_NONE
		var acao: String = par[0]
		b.pressed.connect(func():
			Audio.click()
			_waiting = acao
			_refresh_keys())
		grid.add_child(b)
		_key_buttons[acao] = b
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_keys_page.add_child(row)
	var reset := Button.new()
	reset.text = "Restaurar padrão"
	reset.custom_minimum_size = Vector2(0, 36)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(func():
		Audio.click()
		Teclas.restaura_padrao()
		_waiting = ""
		_refresh_keys())
	row.add_child(reset)
	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(0, 36)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func():
		Audio.click()
		_show_keys(false))
	row.add_child(back)
	_refresh_keys()


func _show_keys(on: bool) -> void:
	_waiting = ""
	_keys_page.visible = on
	_main_page.visible = not on
	_refresh_keys()
	_ajusta_altura.call_deferred()


func _refresh_keys() -> void:
	for acao in _key_buttons:
		_key_buttons[acao].text = "aperte uma tecla..." if acao == _waiting else Teclas.nome(acao)
	var hud := get_tree().get_first_node_in_group("hud") if is_inside_tree() else null
	if hud and hud.has_method("_fill_hints"):
		hud._fill_hints()


## Esperando a tecla nova: pega antes do resto do jogo (Esc cancela).
func _input(event: InputEvent) -> void:
	if _waiting == "" or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var k: int = event.physical_keycode
		if k != KEY_ESCAPE:
			if Teclas.permitida(k):
				Teclas.define(_waiting, k)
			else:
				Audio.error()
				return
		_waiting = ""
		_refresh_keys()


## Fechou a página (Esc no menu de pausa / Voltar): volta pra página principal.
func reset_page() -> void:
	_show_keys(false)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
