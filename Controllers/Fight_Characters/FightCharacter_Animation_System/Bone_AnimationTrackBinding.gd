extends AnimationTrackBinding
class_name BoneTrackBinding

var bone_index : int

func Handle(anim : Animation, animationProgress : float, _progressionAmmount : float, animInfo : AnimationInfo, blendValue : float, skel : Skeleton3D) -> void:
	
	if !animInfo.AnimateBone(bone_index):
		return
	
	if (track_type == Animation.TrackType.TYPE_ROTATION_3D):
		var current_pose = skel.get_bone_pose_rotation(bone_index)
		
		var target_pose = anim.rotation_track_interpolate(track_index, animationProgress)
		
		var blend = blendValue
		
		var boneName = skel.get_bone_name(bone_index)
		
		if (boneName in ["LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "WeaponPlacement.L", "WeaponPlacement.R"]):
			blend = min(1, blend)

		var final_rotation = current_pose.slerp(target_pose, blend)
		#print(blendValue)
		
			
		#if (boneName.containsn("camera")):
		skel.set_bone_pose_rotation(bone_index, final_rotation)
		#else:
			#skel.set_bone_pose_rotation(bone_index, quantize_quat(final_rotation, 64))
	
	else: if (track_type == Animation.TrackType.TYPE_POSITION_3D):
		var current_pose = skel.get_bone_pose_position(bone_index)
		
		var target_pose = anim.position_track_interpolate(track_index, animationProgress)
		
		var final_position = lerp(current_pose, target_pose, min(1, blendValue))
		
			
		skel.set_bone_pose_position(bone_index, final_position)

func snap_quat_angle(q: Quaternion, angle_step_deg: float) -> Quaternion:
	var angle = q.get_angle()
	var axis = q.get_axis()

	var step = deg_to_rad(angle_step_deg)
	angle = round(angle / step) * step

	return Quaternion(axis, angle)

func quantize_quat(q: Quaternion, steps: int) -> Quaternion:
	var s = float(steps)

	q.x = round(q.x * s) / s
	q.y = round(q.y * s) / s
	q.z = round(q.z * s) / s
	q.w = round(q.w * s) / s

	return q.normalized()

static func CreateBoneRotationBinding(trackIndex : int, boneIndex : int, _anim : Animation):
	var binding = BoneTrackBinding.new()

	binding.track_index = trackIndex
	
	binding.track_type = Animation.TrackType.TYPE_ROTATION_3D

	binding.bone_index = boneIndex
	
	return binding
	
static func CreateBonePositionBinding(trackIndex : int, boneIndex : int, _anim : Animation):
	var binding = BoneTrackBinding.new()

	binding.track_index = trackIndex
	
	binding.track_type = Animation.TrackType.TYPE_POSITION_3D

	binding.bone_index = boneIndex
	
	return binding
