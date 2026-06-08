extends RichTextLabel

class_name Notification

var tw : Tween

signal Finished

func _ready() -> void:
	fit_content = true
	#tw = create_tween()
	#modulate = Color(1,1,1,0)
	#tw.tween_property(self, "modulate", Color(1,1,1,1), 1)
	#tw.finished.connect(StartFadeOut)
	#tw.pause()
	StartFadeOut()

func Update(delta : float) -> void:
	if (is_instance_valid(tw)):
		tw.custom_step(delta)

func StartFadeOut() -> void:
	tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 3)
	tw.finished.connect(OnFinished)
	tw.pause()
	
func OnFinished() -> void:
	Finished.emit()
	queue_free()
