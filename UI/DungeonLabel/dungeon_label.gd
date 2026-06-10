extends Label

class_name DungeonLabel

var tw : Tween

func _ready() -> void:
	visible = false
	modulate = Color(1,1,1,0)

func ShowLocation(LocationName : Map.LocationName) -> void:
	visible = true
	var Name : String = Map.LocationName.keys()[LocationName]
	Name = Name.replace("_", " ")
	Name = Name.remove_chars("1234567890")
	text = Name
	if (is_instance_valid(tw)):
		tw.kill()
		
	tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,3),2)
	tw.finished.connect(CloseUp)

func CloseUp() -> void:
	if (is_instance_valid(tw)):
		tw.kill()
		
	tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0),1)
	tw.finished.connect(hide)
