@tool
extends SkeletonModifier3D

class_name BoneAttachment

@export var Skeleton : Skeleton3D
@export var boneID : int = -1
@export_flags("Copy Location", "Copy Rotation") var settings : int

func _process_modification_with_delta(_delta: float) -> void:
	if (GetSetting(0)):
		position = Skeleton.get_bone_global_pose(boneID).origin
	if (GetSetting(1)):
		rotation = Skeleton.get_bone_pose_rotation(boneID).get_euler()

func GetSetting(settingIndex : int) -> bool:
	return settings & (1 << settingIndex) != 0
