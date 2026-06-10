extends Control

class_name PopMenu

@export var PopLabel : Label
@export var YesButton : Button
@export var NoButton : Button
@export var OkButton : Button

signal Answered(YesNo : bool)
signal Ok

func _ready() -> void:
	UISoundMan.Instance.Refresh()

func Pop(Text : String, YesNO : bool) -> void:
	PopLabel.text = Text
	YesButton.visible = YesNO
	NoButton.visible = YesNO
	OkButton.visible = !YesNO

func _on_yes_tutorial_pressed() -> void:
	Answered.emit(true)
	queue_free()

func _on_no_tutorial_pressed() -> void:
	Answered.emit(false)
	queue_free()

func _on_ok_pressed() -> void:
	Ok.emit()
	queue_free()
