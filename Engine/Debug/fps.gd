extends Label


func _physics_process(_delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	text = var_to_str(roundi(fps))
