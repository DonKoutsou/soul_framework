extends Control

class_name EndScreen

signal EndPressed



func _on_button_pressed() -> void:
	EndPressed.emit()
