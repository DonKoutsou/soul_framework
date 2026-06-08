extends RefCounted
class_name AnimationTrackBinding

var track_index : int
var track_type : Animation.TrackType

func Handle(anim : Animation, animationProgress : float, progressionAmmount : float, animInfo : AnimationInfo, blendValue : float, skel : Skeleton3D) -> void:
	return

static func Create(trackIndex : int, targetNode : Node, _anim : Animation):
	var binding = AnimationTrackBinding.new()
	return binding
