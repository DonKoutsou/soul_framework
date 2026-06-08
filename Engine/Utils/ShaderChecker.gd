extends ShaderMaterial

class_name ShaderChecker

@export var ValueToCheck : String
@export var ValueOnWeb : float
@export var ValueOnMobile : float

func _init() -> void:
	call_deferred("SetThing")
	
func SetThing() -> void:
	if (OS.get_name() == "Web"):
		set_shader_parameter(ValueToCheck, ValueOnWeb)
	else:
		set_shader_parameter(ValueToCheck, ValueOnMobile)
	
