extends Node
## Bloco 48 (autoload "WindowManager"): janela e tela cheia.
##
## - F11 ou Alt+Enter alternam tela cheia / janela, em qualquer tela (menu inicial, jogo,
##   pausa). A escolha fica em user://settings.cfg ([video] fullscreen) e volta ao abrir.
## - Resolução base 1280×720 (project.godot, stretch canvas_items/expand): a janela escala
##   ×1 em 720p, ×1,5 em 1080p, ×2 em 1440p e ×3 em 4K. As paradas de zoom da câmera
##   (camera_controller.gd) usam essa escala pra manter o pixel de arte inteiro na tela.

signal fullscreen_changed(on: bool)

const Settings := preload("res://scripts/core/settings.gd")

## Estava maximizada antes de ir pra tela cheia? (volta do mesmo jeito)
var _was_maximized := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # vale até com o jogo pausado
	if Settings.get_value("video", "fullscreen", false):
		_apply.call_deferred(true)


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


func _headless() -> bool:
	return DisplayServer.get_name() == "headless"
