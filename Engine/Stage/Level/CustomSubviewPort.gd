extends SubViewport

func _ready() -> void:
	if (OS.get_name() == "Web"):
		world_3d.environment = world_3d.fallback_environment
	
	#add_to_group("Enviroments")
	
func ElevationChanged(t : bool) -> void:
	var tw = create_tween()
	var currentH = world_3d.environment.fog_height
	if (t):
		tw.tween_property(world_3d.environment, "fog_height", currentH + Stage.CurrentWorld.CurrentWorldScale.y, 0.5)
	else:
		tw.tween_property(world_3d.environment, "fog_height", currentH - Stage.CurrentWorld.CurrentWorldScale.y, 0.5)

func SetElevation(e : float) -> void:
	world_3d.environment.fog_height = Stage.CurrentWorld.CurrentWorldScale.y + e
