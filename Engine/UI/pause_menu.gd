extends Control

class_name PauseMenu

signal Exit
signal SaveRequested
signal SettingsPressed
signal Resume

@export var ControlsPanel : Control

var PreviousInput : Input.MouseMode

func _ready() -> void:
	get_tree().paused = true
	PreviousInput = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	UISoundMan.GetInstance().Refresh()

func _on_resume_pressed() -> void:
	Resume.emit()
	get_tree().paused = false
	queue_free()
	Input.mouse_mode = PreviousInput

	
func _on_exit_pressed() -> void:
	Exit.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_resume_2_pressed() -> void:
	SaveRequested.emit()


func _on_controls_pressed() -> void:
	ControlsPanel.visible = true

func _on_button_pressed() -> void:
	ControlsPanel.visible = false


func _on_settings_pressed() -> void:
	SettingsPressed.emit()
