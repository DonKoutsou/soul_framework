@tool
extends SkeletonModifier3D

class_name Fight_Animation_Modifier

@export var CurrentState : FightCharacter.CharacterState:
	set(value):
		CurrentState = value
		if (!is_inside_tree()):
			return
		StateSwitched(value)
@export var Walking : bool = false:
	set(value):
		Walking = value
		ToggleWalking(Walking)
@export var WeaponCurve : Curve
@export var Custom_Time_Scale : float = 1.0
@export_group("Weapon")
@export var CurrentWeaponType : WeaponType = WeaponType.ONE_HANDED

@export var currentWeaponSpeed: float = 1.0:
	set(value):
		currentWeaponSpeed = value
		UpdateWeaponSpeed(value)


@export_group("Recoil")
@export var Recoil : Vector3 = Vector3.ZERO
@export var RecoilCurve : Curve

@export_group("Nodes")
@export var animator : AnimationPlayer

@export_group("Animation configuration")
@export var anims : Array[AnimationInfo] = []
@export_tool_button("Check For Broken Bone Maps") var boneMapFix : Callable = FixBoneMaps


var animProgress : PackedFloat32Array
var cachedPrevanimProgress : PackedFloat32Array
var animBlend : PackedFloat32Array
#bit flags
var animActive : int = 0
var animBlendDirection : int = 0
var animDir : int = 0

var recoilBone : int
var recoilBone2 : int
var cambone : int
var headbone : int
var animation_cache : Dictionary[String, CachedAnimation] = {}

signal AnimationFinished(animName : String)

func _ready() -> void:
	animProgress.resize(anims.size())
	cachedPrevanimProgress.resize(anims.size())
	animBlend.resize(anims.size())
	
	recoilBone = get_skeleton().find_bone("Body.003")
	recoilBone2 = get_skeleton().find_bone("Body.001")
	cambone = get_skeleton().find_bone("CameraBone")
	headbone = get_skeleton().find_bone("Head")
	
	for g in anims:
		BuildAnimationCache(g.AnimName)
		if (g is CombatAnimationInfo):
			BuildAnimationCache("2H_" + g.AnimName)
			BuildAnimationCache("R_" + g.AnimName)
			BuildAnimationCache("BOW_" + g.AnimName)
	#print(animBlend.size())

func BuildAnimationCache(anim_name : String) -> void:
	var cache = CachedAnimation.new()
	if (!animator.has_animation(anim_name)):
		return

	var anim = animator.get_animation(anim_name)
	if (anim == null):
		#push_error("Animation {0} is missing".format([anim_name]))
		return
	
	cache.animation = anim
	
	for track in range(anim.get_track_count()):

		var type = anim.track_get_type(track)
		
		var path : NodePath = anim.track_get_path(track)
		var targetNode = animator.get_parent().get_node(path)
		
		match type:
			Animation.TYPE_VALUE:
				cache.track_bindings.append(ValueTrackBinding.Create(track, targetNode, anim))
			Animation.TYPE_METHOD:
				cache.track_bindings.append(MethodTrackBinding.Create(track, targetNode, anim))
			Animation.TYPE_ROTATION_3D:
				cache.track_bindings.append(BoneTrackBinding.CreateBoneRotationBinding(track, GetTackBone(anim, track), anim))
			Animation.TYPE_POSITION_3D:
				cache.track_bindings.append(BoneTrackBinding.CreateBonePositionBinding(track, GetTackBone(anim, track), anim))
	
	animation_cache[anim_name] = cache

func ToggleWalking(t : bool) -> void:
	var walkIndex = GetAnimationInfo("Walk")
	if (t):
		SetAnimationActive(walkIndex, t)
	else:
		SetAnimationBlendDirection(walkIndex, t)

func StateSwitched(NewState : FightCharacter.CharacterState) -> void:
	for animIndex in anims.size():
		var animInfo = anims[animIndex]
		if (animInfo.ValidStates.size() == 0):
			continue
		if (animInfo.ValidStates.has(NewState)):
			if (GetAnimationActive(animIndex)):
				continue
			
			var dualDir = GetAnimationDualDirection(animIndex)
				
			if (animInfo.BlendInAnim != ""):
				var blendInAnimName = animInfo.GetBlendInAnimationName(CurrentWeaponType, dualDir)
				var blendInAnimIndex = GetAnimationInfo(blendInAnimName)
				var anim = anims[blendInAnimIndex]
				
				if (anim is CombatAnimationInfo and !anim.AlwaysR):
					SetAnimationDualDirection(blendInAnimIndex, dualDir)
					
				SetAnimationActive(blendInAnimIndex, true)
				#anim.PassInfo(animInfo.GetInfo())
				SetAnimationBlendDirection(blendInAnimIndex, true)
				continue
			if (animInfo.OnCompleteAnim != ""):
				var onCompleteAnimIndex = GetAnimationInfo(animInfo.OnCompleteAnim)
				
				#var anim = animConfig.anims[onCompleteAnimIndex]
				if (GetAnimationActive(onCompleteAnimIndex)):
					continue
			#Animation to blend out when firing this anim
			if (animInfo.BlendOutAnim != ""):
				var blendOutAnimIndex = GetAnimationInfo(animInfo.GetBlendOutAnimationName(CurrentWeaponType, dualDir))
				
				if (!GetAnimationActive(blendOutAnimIndex)):
					continue
					
				var animToStop = anims[blendOutAnimIndex]
				var blendOutDir = GetAnimationDualDirection(blendOutAnimIndex)
				if (animToStop is CombatAnimationInfo and !animToStop.AlwaysR):
					SetAnimationDualDirection(animIndex, blendOutDir)
				
				SetAnimationActive(animIndex, true)
				SetAnimationBlendDirection(animIndex, true)
				#animInfo.PassInfo(animToStop.GetInfo())
				SetAnimationBlendDirection(blendOutAnimIndex, false)
				
				if (animInfo.InverseSyncBlend):
					var time = animator.get_animation(animToStop.GetAnimationName(CurrentWeaponType, dualDir)).length
					var newTime = time - animProgress[blendOutAnimIndex]
					cachedPrevanimProgress[animIndex] = animProgress[animIndex]
					animProgress[animIndex] = newTime
				continue
			
			SetAnimationActive(animIndex, true)
			SetAnimationBlendDirection(animIndex, true)
			if (animInfo is CombatAnimationInfo and !animInfo.AlwaysR):
				SetAnimationDualDirection(animIndex, randi_range(0, 1) == 0)
		else:
			if (!GetAnimationActive(animIndex)):
				continue
			SetAnimationBlendDirection(animIndex, false)



func PlayAnim(animName : String) -> void:
	#print("playing {0}".format([animName]))
	var animToPlayIndex = GetAnimationInfo(animName)
	
	if (GetAnimationActive(animToPlayIndex)):
		return
		
	var animToPlay = anims[animToPlayIndex]
	if (!animToPlay.ValidStates.has(CurrentState)):
		return
	
	SetAnimationActive(animToPlayIndex, true)
	SetAnimationBlendDirection(animToPlayIndex, true)
	animBlend[animToPlayIndex] = 0
	if (animToPlay.BlendOutAnim != ""):
		var dualDir = GetAnimationDualDirection(animToPlayIndex)
		var animToStopIndex = GetAnimationInfo(animToPlay.GetBlendOutAnimationName(CurrentWeaponType, dualDir))
		SetAnimationBlendDirection(animToStopIndex, false)

func UpdateWeaponSpeed(newSpeed : float) -> void:
	var normalisedSpeed = GetWeaponSpeedNormalised(newSpeed)
	var first = clampf(lerpf(0.0, 1.0, normalisedSpeed), 0.0, 1.0)
	var second = clampf(lerpf(3.5, 1.0, normalisedSpeed), 1.0, 3.5)
	WeaponCurve.set_point_right_tangent(0, first)
	WeaponCurve.set_point_left_tangent(1, second)
	WeaponCurve.bake()

func UpdateWeaponType(type : WeaponType) -> void:
	CurrentWeaponType = type

#------------------------- FRAME PROCESSING ----------------------------#
func _process_modification_with_delta(delta: float) -> void:
	var d = delta * Custom_Time_Scale
	#Progress animations
	for animIndex in anims.size():
		if (GetAnimationActive(animIndex)):
			ProgressAnimation(animIndex, d)
	#Apply animations
	for animIndex in anims.size():
		if (!GetAnimationActive(animIndex)):
			continue
		
		var animInfo = anims[animIndex]
		
		var dualDir = GetAnimationDualDirection(animIndex)
		
		var animName = animInfo.GetAnimationName(CurrentWeaponType, dualDir)

		var cached_anim : CachedAnimation = animation_cache[animName]
		
		var anim = cached_anim.animation
		
		var prevProgress = GetPreviousAnimationProgres(animIndex)
		var animation_progress = GetAnimationProgres(animIndex)
		
		#If animation is affected by weapon we need to apply the weapon curve to it.
		#Weapon curve shifts animations a bit based on weapon size, making heavier weapons have bigger windup and faster strike
		if (animInfo.AffectedByWeapon):
			var normalisedProgress = animation_progress / cached_anim.animation.length
			var sampledProgress = WeaponCurve.sample(normalisedProgress)
			
			var normalisedPreviousProgress = prevProgress / cached_anim.animation.length
			var sampledPrevProgress = WeaponCurve.sample(normalisedPreviousProgress)
			
			prevProgress = cached_anim.animation.length * sampledPrevProgress
			animation_progress = cached_anim.animation.length * sampledProgress

		var blendValue = GetBlendValue(animIndex)
		
		var t = animation_progress - prevProgress
		
		for binding in cached_anim.track_bindings:
			if (!anim.track_is_enabled(binding.track_index)):
				return
			
			binding.Handle(anim, animation_progress, t, animInfo, blendValue, get_skeleton())
	
	HandleRecoil(delta)
	
func HandleRecoil(delta : float) -> void:
	if (Recoil == Vector3.ZERO):
		return

	var FinalRecoil = Vector3(SampleRecoil(Recoil.x), SampleRecoil(Recoil.y), SampleRecoil(Recoil.z))
	
	if (recoilBone != -1):
		var pose = get_skeleton().get_bone_pose_rotation(recoilBone)
		var MixedPoseRotation = pose * Quaternion.from_euler(FinalRecoil / 2.0)
		get_skeleton().set_bone_pose_rotation(recoilBone, MixedPoseRotation.normalized())
	
	if (recoilBone2 != -1):
		var pose = get_skeleton().get_bone_pose_rotation(recoilBone2)
		var MixedPoseRotation = pose * Quaternion.from_euler(FinalRecoil / 4.0)
		get_skeleton().set_bone_pose_rotation(recoilBone2, MixedPoseRotation.normalized())
		
	if (cambone != -1):
		var camRest = get_skeleton().get_bone_pose_rotation(cambone)
		var quart = Quaternion.from_euler(FinalRecoil)
		var newCamRotation = camRest * Quaternion(-quart.x, quart.y, -quart.z, quart.w)
		get_skeleton().set_bone_pose_rotation(cambone, newCamRotation.normalized())
	
	if (headbone != -1):
		var headRest = get_skeleton().get_bone_pose_rotation(headbone)
		var newheadRotation = headRest * Quaternion.from_euler(FinalRecoil)
		get_skeleton().set_bone_pose_rotation(headbone, newheadRotation.normalized())

	Recoil = Recoil.move_toward(Vector3.ZERO, delta * 3 * Custom_Time_Scale)
	
#-----------------------------------------------------------------------------#
func ProgressAnimation(animIndex : int, delta : float) -> void:
	var anim = anims[animIndex]
	var dualDir = GetAnimationDualDirection(animIndex)
	var currentAnim = animator.get_animation(anim.GetAnimationName(CurrentWeaponType, dualDir))
	var blendDirection = GetAnimationBlendDirection(animIndex)
	
	if (blendDirection):
		if anim.Blend_Duration <= 0.0:
			animBlend[animIndex] = 1.0
		else:
			var blend_speed = (1.0 / anim.Blend_Duration)
			if (anim.AffectedByWeapon):
				blend_speed *= currentWeaponSpeed
			var newBlend = move_toward(animBlend[animIndex], 1.0, blend_speed * delta)
			animBlend[animIndex] = newBlend
	else:
		if anim.Blend_Out_Duration <= 0.0:
			animBlend[animIndex] = 0.0
		else:
			var blend_speed = (1.0 / anim.Blend_Out_Duration)
			if (anim.AffectedByWeapon):
				blend_speed *= currentWeaponSpeed
			var newBlend = move_toward(animBlend[animIndex], 0.0, blend_speed * delta)
			animBlend[animIndex] = newBlend
			
		if (animBlend[animIndex] == 0):
			SetAnimationActive(animIndex, false)
			
	
	if (anim.Loop):
		var blend_speed = (delta * anim.Time_Scale)
		if (anim.AffectedByWeapon):
			blend_speed *= currentWeaponSpeed
		cachedPrevanimProgress[animIndex] = animProgress[animIndex]
		animProgress[animIndex] += blend_speed
		#anim.animProgress = wrapf(anim.animProgress + (delta / anim.Time_Scale), 0, animator.get_animation(anim.AnimName).length) 
		#var remainingTime = currentAnim.length - animProgress
		if (animProgress[animIndex] > currentAnim.length):
			animProgress[animIndex] -= currentAnim.length
			OnAnimationFinished(anim.AnimName)
		
		#TODO see if we need this
		#if (anim.BreakLoop and anim.Blend_Duration > remainingTime):
			#BreakLoop = false
			#blendingDirection = false
			#AnimationFinished.emit()
			#print("Animation Finished {0}".format([animInfo.GetAnimationName()]))
	else:
		if (animProgress[animIndex] > currentAnim.length):
			return
		var blend_speed = (delta / anim.Time_Scale)
		if (anim.AffectedByWeapon):
			blend_speed *= currentWeaponSpeed
		
		cachedPrevanimProgress[animIndex] = animProgress[animIndex] #cache previous progress, used to calculate ammount the animation progress by
		
		#try to coclulate how far the ending of the animation is and start blending it out eralier
		var remainingBlendTime = animBlend[animIndex]
		var blendOutDuration = anim.Blend_Out_Duration
		if (anim.AffectedByWeapon):
			blendOutDuration /= currentWeaponSpeed
		var timeUntilBlendOut = (remainingBlendTime * blendOutDuration) - delta
		
		
		if (animProgress[animIndex] + timeUntilBlendOut > currentAnim.length):
			if (anim.AutoComplete):
				SetAnimationBlendDirection(animIndex, false)
			if (anim.OnCompleteAnim != ""):
				PlayAnim(anim.GetOnCompleteAnimationName(CurrentWeaponType, dualDir))
		
		animProgress[animIndex] += blend_speed

		if (animProgress[animIndex] > currentAnim.length):
			OnAnimationFinished(anim.AnimName)
			


func OnAnimationFinished(animName : String) -> void:
	print("Finished : {0}".format([animName]))
	AnimationFinished.emit(animName)

func SampleRecoil(Value : float) -> float:
	var s = sign(Value)
	var sampledValue = RecoilCurve.sample(abs(Value))
	return sampledValue * s

#------------GETTERS---------------
func GetAnimationInfo(animatioName : String) -> int:
	for animIndex in anims.size():
		var anim = anims[animIndex]
		if (anim.IsAnim(animatioName)):
			return animIndex
	return -1

func GetWeaponSpeedNormalised(speed : float) -> float:
	return normalize_value(speed, Weapon.WEAPON_MIN_SPEED, Weapon.WEAPON_MAX_SPEED)

func GetSkeletonName() -> String:
	return get_skeleton().name

func GetTackBone(anim : Animation, trackID : int) -> int:
	var bone_name : String = anim.track_get_path(trackID)
	bone_name = bone_name.replace("%{0}:".format([GetSkeletonName()]), "")
	var bone = get_skeleton().find_bone(bone_name)
	return bone

func GetBlendValue(animIndex : int) -> float:
	var animInfo = anims[animIndex]
	var blendValue = animBlend[animIndex]
	if (animInfo.BlendCurve != null and GetAnimationBlendDirection(animIndex)):
		blendValue = animInfo.BlendCurve.sample(blendValue)
	if (animInfo.BlendOutCurve != null and !GetAnimationBlendDirection(animIndex)):
		blendValue = animInfo.BlendOutCurve.sample(blendValue)
	return blendValue

#-------------- ANIMATION PROGRESS ----------------#

func GetAnimationProgres(animIndex : int) -> float:
	return animProgress[animIndex]

func GetPreviousAnimationProgres(animIndex : int) -> float:
	return cachedPrevanimProgress[animIndex]

#------------------------- ANIMATION TOGGLING -------------------------------#
#Once animation has blended out we dissable it so that its no longer proccessed
func GetAnimationActive(animationIndex : int) -> bool:
	return animActive & (1 << animationIndex) != 0

func SetAnimationActive(animationIndex : int, t : bool):
	if (GetAnimationActive(animationIndex) == t):
		return
		
	if (t):
		var anim = anims[animationIndex]
		print("{0} set to active".format([anim.AnimName]))
		animActive |= (1 << animationIndex)
	else:
		var anim = anims[animationIndex]
		print("{0} set to inactive".format([anim.AnimName]))
		if (anim.AnimName in ["Charge_Right_Reversed", "Charge_Top_Reversed", "Charge_Left_Reversed", "Charge_Middle_Reversed"]):
			print("thing")
		animActive &= ~(1 << animationIndex)
	
	#print("toggled {0}".format([anims[animationIndex].AnimName]))
	animBlend[animationIndex] = 0
	animProgress[animationIndex] = 0
	SetAnimationBlendDirection(animationIndex, true)

#-------------------- BLEND DIRECTION ------------------#

func GetAnimationBlendDirection(animationIndex : int) -> bool:
	return animBlendDirection & (1 << animationIndex) != 0

func SetAnimationBlendDirection(animationIndex : int, t : bool):
	if (t):
		animBlendDirection |= (1 << animationIndex)
	else:
		var anim = anims[animationIndex]
		if (anim.AnimName in ["Charge_Right_Reversed", "Charge_Top_Reversed", "Charge_Left_Reversed", "Charge_Middle_Reversed"]):
			print("thing")
		animBlendDirection &= ~(1 << animationIndex)

func GetAnimationDualDirection(animationIndex : int) -> bool:
	return animDir & (1 << animationIndex) != 0

func SetAnimationDualDirection(animationIndex : int, t : bool):
	if (t):
		animDir |= (1 << animationIndex)
	else:
		animDir &= ~(1 << animationIndex)

#----------------------- HELPER FUNCTIONS ----------------------#

func normalize_value(value: float, minimum: float, maximum: float) -> float:
	if minimum == maximum:
		return 0.0
	return (value - minimum) / (maximum - minimum)

func FixBoneMaps() -> void:
	for g in get_skeleton().get_bone_count():
		ProjectSettings.set_setting("layer_names/2d_navigation/layer_{0}".format([g]), get_skeleton().get_bone_name(g))

#----------------------- ENIMS ----------------------#

enum WeaponType{
	ONE_HANDED,
	TWO_HANDED,
	DUAL,
	BOW,
}
