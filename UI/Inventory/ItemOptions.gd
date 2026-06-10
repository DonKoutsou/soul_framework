extends HBoxContainer

class_name ItemOptions

@export var use_button: Button
@export var equip_button: Button
@export var combine_button: Button

signal Used(It : Item)
signal Next
signal Prev
signal Combined(It : Item)

var It : Item

func _input(event: InputEvent) -> void:
	if (!is_visible_in_tree()):
		return
	if (event.is_action_pressed("DuckLeft")):
		Prev.emit()
	if (event.is_action_pressed("DuckRight")):
		Next.emit()
	if (event.is_action_pressed("Use")):
		Used.emit(It)
	if (event.is_action_pressed("Combine")):
		Combined.emit(It)

func _on_use_button_pressed() -> void:
	Used.emit(It)

func _on_combine_button_pressed() -> void:
	Combined.emit(It)

func _on_next_button_pressed() -> void:
	Next.emit()


func _on_next_button_2_pressed() -> void:
	Prev.emit()
