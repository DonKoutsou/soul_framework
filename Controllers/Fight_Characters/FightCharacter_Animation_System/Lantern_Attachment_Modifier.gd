@tool
extends SkeletonModifier3D

class_name Lantern_Attachment_Modifier

@export var BoneID : int

var LastRot : float

func _process_modification_with_delta(delta: float) -> void:
	var sk = get_skeleton()

	var pose = sk.get_bone_global_pose(BoneID)
	transform = pose
	
	LastRot = move_toward(LastRot, rotation.z, delta)
	
	LastRot = move_toward(LastRot, PI / 2.0, delta / 3)
	
	rotation.z = LastRot

	
	
