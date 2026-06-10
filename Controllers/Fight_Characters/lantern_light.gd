extends MeshInstance3D

class_name LanternLight

var CurrentLightAmm : float = 1

var d : float = 0.1
func Update(delta : float) -> void:
	d -= delta
	if d > 0:
		return
	d = 0.05
	var R = randf_range(CurrentLightAmm - 0.05, CurrentLightAmm + 0.05)
	scale = Vector3(R, R, R)
