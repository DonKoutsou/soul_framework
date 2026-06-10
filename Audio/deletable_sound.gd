extends AudioStreamPlayer

class_name DeletableSound

func _ready() -> void:
	bus = "Sounds"
	connect("finished", _on_finished)

func _on_finished() -> void:
	queue_free()
