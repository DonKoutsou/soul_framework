extends Node

class_name InputManager

var prevMouseMode

static var Instance : InputManager

signal PausePressed

func _ready() -> void:
	Input.set_custom_mouse_cursor(load("res://Engine/Assets/UI_Icons/M100-2.png"), Input.CURSOR_POINTING_HAND, Vector2(8, 2))
	process_mode = Node.PROCESS_MODE_ALWAYS
	Instance = self

func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		prevMouseMode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Input.mouse_mode = prevMouseMode

func _input(event: InputEvent) -> void:
	
	if (event.is_action_pressed("Pause")):
		PausePressed.emit()
