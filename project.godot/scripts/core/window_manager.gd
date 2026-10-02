extends Node
## Bloco 48 (autoload "WindowManager"): janela e tela cheia.
##
## - F11 ou Alt+Enter alternam tela cheia / janela, em qualquer tela (menu inicial, jogo,
##   pausa). A escolha fica em user://settings.cfg ([video] fullscreen) e volta ao abrir.
## - Resolução base 1280×720 (project.godot, stretch canvas_items/expand): a janela escala
##   ×1 em 720p, ×1,5 em 1080p, ×2 em 1440p e ×3 em 4K. As paradas de zoom da câmera
##   (camera_controller.gd) usam essa escala pra manter o pixel de arte inteiro na tela.
## - Bloco 54: ESCALA DA INTERFACE (80–150%, [video] ui_scale) e IDIOMA ([geral] idioma), aplicados ao
##   abrir. A escala é o content_scale_factor da janela: a interface cresce e a câmera compensa (as
##   paradas de zoom contam com ela), então o mundo fica do mesmo tamanho. Ela é limitada pra área
##   lógica nunca ficar menor que UI_MIN_LOGICAL (as janelas foram feitas pra 1280×720): em
##   1280×720, até ~120%.

signal fullscreen_changed(on: bool)
signal ui_scale_changed(applied: float)

const UI_SCALE_MIN := 0.8
const UI_SCALE_MAX := 1.5
## A menor área lógica (px da interface) em que as janelas cabem sem cortar.
const UI_MIN_LOGICAL := Vector2(1060, 600)
const IDIOMAS := [["pt_BR", "Português (Brasil)"], ["en", "English"]]

const Settings := preload("res://scripts/core/settings.gd")

## Estava maximizada antes de ir pra tela cheia? (volta do mesmo jeito)
var _was_maximized := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # vale até com o jogo pausado
	if Settings.get_value("video", "fullscreen", false):
		_apply.call_deferred(true)
	set_language(Settings.get_value("geral", "idioma", _idioma_padrao()), false)
	get_tree().root.size_changed.connect(_reapply_ui_scale)
	_reapply_ui_scale.call_deferred()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = event.physical_keycode
	if k == KEY_F11 or (event.alt_pressed and (k == KEY_ENTER or k == KEY_KP_ENTER)):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()  # o Enter não "aperta" o botão em foco


func is_fullscreen() -> bool:
	if _headless():
		return Settings.get_value("video", "fullscreen", false)
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())


## Liga/desliga a tela cheia e lembra a escolha.
func set_fullscreen(on: bool) -> void:
	var was := is_fullscreen()
	Settings.set_value("video", "fullscreen", on)
	_apply(on)
	if on != was:
		fullscreen_changed.emit(on)


func _apply(on: bool) -> void:
	if _headless():
		return  # testes sem janela: só a escolha é guardada
	var m := DisplayServer.window_get_mode()
	var full := m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if on == full:
		return
	if on:
		_was_maximized = m == DisplayServer.WINDOW_MODE_MAXIMIZED
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED if _was_maximized else DisplayServer.WINDOW_MODE_WINDOWED)


# ------------------------------------------------------------ escala da interface (Bloco 54)
## A escala pedida (o que o jogador escolheu).
func ui_scale() -> float:
	return clampf(Settings.get_value("video", "ui_scale", 1.0), UI_SCALE_MIN, UI_SCALE_MAX)


## A maior escala que cabe nesta janela (a área lógica não fica menor que UI_MIN_LOGICAL).
func max_ui_scale() -> float:
	var win := get_tree().root
	var base := Vector2(win.content_scale_size)
	var size := Vector2(win.size)
	if _headless() or base.x <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		size = base  # (testes sem janela: conta como 1280×720)
	var k := minf(size.x / base.x, size.y / base.y)  # esticada da janela (canvas_items)
	var logical := size / k  # área lógica com escala 1 (aspect expand: um lado pode ser maior)
	return clampf(minf(logical.x / UI_MIN_LOGICAL.x, logical.y / UI_MIN_LOGICAL.y), UI_SCALE_MIN, UI_SCALE_MAX)


## A escala que está valendo (a pedida, limitada pela janela).
func applied_ui_scale() -> float:
	return minf(ui_scale(), max_ui_scale())


func set_ui_scale(v: float) -> void:
	Settings.set_value("video", "ui_scale", clampf(v, UI_SCALE_MIN, UI_SCALE_MAX))
	_reapply_ui_scale()


func _reapply_ui_scale() -> void:
	var f := applied_ui_scale()
	var win := get_tree().root
	if not is_equal_approx(win.content_scale_factor, f):
		win.content_scale_factor = f
	ui_scale_changed.emit(f)


# ------------------------------------------------------------ idioma (Bloco 54)
func _idioma_padrao() -> String:
	return "en" if OS.get_locale_language() == "en" else "pt_BR"


func language() -> String:
	return Settings.get_value("geral", "idioma", _idioma_padrao())


## Troca o idioma na hora (os textos fixos da interface que estão em translations/ui.csv mudam
## sozinhos; os montados com números seguem em português por enquanto — ver docs/IDIOMAS.md).
func set_language(code: String, remember: bool = true) -> void:
	TranslationServer.set_locale(code)
	if remember:
		Settings.set_value("geral", "idioma", code)


func _headless() -> bool:
	return DisplayServer.get_name() == "headless"
