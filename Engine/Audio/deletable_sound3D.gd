extends AudioStreamPlayer3D

class_name DeletableSound3D

func _ready() -> void:
	#bus = "Sounds"
	connect("finished", _on_finished)

func _on_finished() -> void:
	queue_free()
