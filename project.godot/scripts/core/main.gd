extends Node2D

@onready var _ipezinho := $Ipezinho

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_ipezinho.move_to(get_global_mouse_position())
