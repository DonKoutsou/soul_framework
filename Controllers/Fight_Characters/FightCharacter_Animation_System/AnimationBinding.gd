extends RefCounted
class_name AnimationTrackBinding

var track_index : int
var track_type : Animation.TrackType

func Handle(_anim : Animation, _animationProgress : float, _progressionAmmount : float, _animInfo : AnimationInfo, _blendValue : float, _skel : Skeleton3D) -> void:
	return

static func Create(_trackIndex : int, _targetNode : Node, _anim : Animation):
	var binding = AnimationTrackBinding.new()
	return binding
