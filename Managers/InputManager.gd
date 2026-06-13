extends Node

class_name InputManager



static var Instance : InputManager

signal PausePressed

static var prevMouseMode = Input.MOUSE_MODE_VISIBLE
static var MouseIn : bool = false

func _ready() -> void:
	Input.set_custom_mouse_cursor(load("res://Engine/Assets/UI_Icons/M100-2.png"), Input.CURSOR_POINTING_HAND, Vector2(8, 2))
	process_mode = Node.PROCESS_MODE_ALWAYS
	Instance = self

static func ChangeMouse(newMode : Input.MouseMode) -> void:
	if (MouseIn):
		Input.mouse_mode = newMode
	else:
		prevMouseMode = newMode

func _notification(what: int):
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		MouseIn = false
		prevMouseMode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		MouseIn = true
		Input.mouse_mode = prevMouseMode

func _input(event: InputEvent) -> void:
	
	if (event.is_action_pressed("Pause")):
		PausePressed.emit()
