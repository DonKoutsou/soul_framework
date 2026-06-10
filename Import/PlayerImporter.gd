@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	
	var animPlayer : AnimationPlayer = scene.get_node("AnimationPlayer")
	var animLib = animPlayer.get_animation_library("")
	
	var animsToReverse : PackedStringArray = ["Charge_Right", "Charge_Left", "Charge_Middle", "Charge_Low", "Charge_Top", "2H_Charge_Right", "2H_Charge_Left", "2H_Charge_Middle", "2H_Charge_Low", "2H_Charge_Top", "BOW_Charge_Middle", "R_Charge_Right", "R_Charge_Left", "R_Charge_Middle", "R_Charge_Low", "R_Charge_Top"]
	
	for anim in animsToReverse:
		if (!animLib.has_animation(anim)):
			continue
		var chargeAnime = animLib.get_animation(anim)
		var reversed = reverse_animation(chargeAnime)
		animLib.add_animation("{0}_Reversed".format([anim]), reversed)
	
	var animsToCopy : PackedStringArray = ["SwordSeath", "SwordUnseath", "Idle", "Duck_Left", "Duck_Left_Recover", "Duck_Right", "Duck_Right_Recorver", "Hit_Mid", "Parry"]
	
	for anim in animsToCopy:
		if (!animLib.has_animation(anim)):
			continue
		var swordAnim = animLib.get_animation(anim)
		animLib.add_animation("BOW_{0}".format([anim]), swordAnim)
	
	return scene # Remember to return the imported scene

func reverse_animation(anim: Animation, skip_method_tracks: bool = true) -> Animation:
	var reversed: Animation = anim.duplicate()
	var length: float = anim.length

	for track_idx in range(anim.get_track_count()):
		var track_type = anim.track_get_type(track_idx)
		
		var key_count := anim.track_get_key_count(track_idx)
		
		# Skip method tracks if requested
		if skip_method_tracks and track_type == Animation.TYPE_METHOD:
			reversed.track_set_enabled(track_idx, false)
			continue
		if skip_method_tracks and track_type == Animation.TYPE_VALUE:
			continue
		

		# Store keys (including transition if you want smoother accuracy)
		var keys := []
		for key_idx in range(key_count):
			keys.append({
				"time": anim.track_get_key_time(track_idx, key_idx),
				"value": anim.track_get_key_value(track_idx, key_idx),
				"transition": anim.track_get_key_transition(track_idx, key_idx)
			})

		# Remove keys (backwards)
		for i in range(key_count - 1, -1, -1):
			reversed.track_remove_key(track_idx, i)

		# Reinsert reversed
		for key in keys:
			var new_time = length - key["time"]
			reversed.track_insert_key(track_idx, new_time, key["value"], key["transition"])

	return reversed
