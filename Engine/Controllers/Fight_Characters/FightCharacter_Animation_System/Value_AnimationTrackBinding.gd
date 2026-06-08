extends AnimationTrackBinding

class_name ValueTrackBinding

var node : Node
var property : StringName


func Handle(anim : Animation, animationProgress : float, progressionAmmount : float, animInfo : AnimationInfo, blendValue : float, skel : Skeleton3D) -> void:
	var value = anim.value_track_interpolate(track_index, animationProgress)

	node.set(property,value)

static func Create(trackIndex : int, targetNode : Node, anim : Animation):
	var binding = ValueTrackBinding.new()

	binding.track_index = trackIndex
	binding.track_type = Animation.TrackType.TYPE_VALUE
	var path : NodePath = anim.track_get_path(trackIndex)
	binding.property = StringName(path.get_concatenated_subnames())
	binding.node = targetNode
	
	return binding
