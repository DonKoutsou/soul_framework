extends WorldEnvironment

func ElevationChanged(t : bool) -> void:
	var tw = create_tween()
	var currentH = environment.fog_height
	if (t):
		tw.tween_property(environment, "fog_height", currentH +  + Stage.CurrentWorld.CurrentWorldScale.y, 0.5)
	else:
		tw.tween_property(environment, "fog_height", currentH - Stage.CurrentWorld.CurrentWorldScale.y, 0.5)

func SetElevation(e : float) -> void:
	environment.fog_height = Stage.CurrentWorld.CurrentWorldScale.y + e
