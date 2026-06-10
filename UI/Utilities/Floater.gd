extends Label

class_name Floater


var GoodColor : Color = Color(0.383, 0.605, 0.28, 1.0)
var BadColor : Color = Color(0.893, 0.41, 0.328, 1.0)

var Reverse : bool = false
var PositionToSpawn : Vector2
signal Ended
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	
	call_deferred("DoThing")

func DoThing() -> void:
	
	set_anchors_preset(Control.PRESET_CENTER)
	#global_position = PositionToSpawn - size / 2
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	if (Reverse):
		tw.tween_property(self, "position", Vector2(position.x, position.y + 20), 0.75)
	else:
		tw.tween_property(self, "position", Vector2(position.x, position.y - 20), 0.75)
	await tw.finished
	Ended.emit()
	queue_free()

func SetColor(Good : bool) -> void:
	if (Good):
		modulate = GoodColor
	else:
		modulate = BadColor
