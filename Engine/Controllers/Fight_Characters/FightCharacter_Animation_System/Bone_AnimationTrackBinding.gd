extends AnimationTrackBinding
class_name BoneTrackBinding

var bone_index : int

func Handle(anim : Animation, animationProgress : float, progressionAmmount : float, animInfo : AnimationInfo, blendValue : float, skel : Skeleton3D) -> void:
	
	if !animInfo.AnimateBone(bone_index):
		return
	
	if (track_type == Animation.TrackType.TYPE_ROTATION_3D):
		var current_pose = skel.get_bone_pose_rotation(bone_index)
		
		var target_pose = anim.rotation_track_interpolate(track_index, animationProgress)

		var final_rotation = current_pose.slerp(target_pose, blendValue)

		skel.set_bone_pose_rotation(bone_index, final_rotation)
	
	else: if (track_type == Animation.TrackType.TYPE_POSITION_3D):
		var current_pose = skel.get_bone_pose_position(bone_index)
		
		var target_pose = anim.position_track_interpolate(track_index, animationProgress)

		var final_position = lerp(current_pose, target_pose, blendValue)

		skel.set_bone_pose_position(bone_index, final_position)

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
