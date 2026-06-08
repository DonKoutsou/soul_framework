extends AnimationTrackBinding
class_name MethodTrackBinding

var node : Node
var method : StringName

func Handle(anim : Animation, animationProgress : float, progressionAmmount : float, animInfo : AnimationInfo, blendValue : float, skel : Skeleton3D) -> void:
	var key = anim.track_find_key(track_index, animationProgress, Animation.FIND_MODE_NEAREST)

	if key == -1:
		return

	var key_time = anim.track_get_key_time(track_index, key)
		
	# key must already be passed
	if key_time > animationProgress:
		return

	# ensure key crossed this frame
	if abs(key_time - animationProgress) >= progressionAmmount:
		return
	
	var method = anim.method_track_get_name(track_index, key)

	var args = anim.method_track_get_params(track_index, key)
		
	node.callv(method, args)

static func Create(trackIndex : int, targetNode : Node, _anim : Animation):
	var binding = MethodTrackBinding.new()

	binding.track_index = trackIndex
	binding.track_type = Animation.TrackType.TYPE_METHOD

	binding.node = targetNode
	
	return binding
