@tool
extends Resource

class_name AnimationInfo

@export var AnimName : String = ""

@export_group("Blend Settings")
@export var AllowOverBlend : bool = false
@export_subgroup("Blend In")
@export var BlendInAnim : String = ""
@export var BlendCurve : Curve
@export var Blend_Duration : float = 1.0
@export_subgroup("Blend Out")
@export var BlendOutAnim : String = ""
##Will start blending out just before the animation finishes
@export var EarlyBlendOut : bool = true
@export var AllowTransitionWithoutBlendOut : bool = false
@export var BlendOutCurve : Curve
@export var Blend_Out_Duration : float = 1.0

##Animation will have its progress synced with animation being blended out
@export var InverseSyncBlend : bool = false
##Max ammount value will be synced with Blend out Anim
@export_range(0, 1.0, 0.1) var MaxSyncNormalised : float = 0

@export_subgroup("")
@export var OnCompleteAnim : String = ""
@export_flags_2d_navigation var BoneFilter : int = 4294967295

@export_group("Speed")
@export var AffectedByWeapon : bool = false
@export var Time_Scale : float = 1.0
#@export var SpeedMulti : float = 1.0

@export_group("State")
@export var AllowRestart : bool = false
@export var Loop : bool = false
#@export var BreakLoop : bool = false
@export var AutoComplete : bool = true
@export var ValidStates : Array[FightCharacter.CharacterState]

#func PassInfo(info : Dictionary) -> void:
	#return

#func GetInfo() -> Dictionary:
	#return {}

func IsAnim(animMatchName : String) -> bool:
	return animMatchName.contains(AnimName)

func GetAnimationName(_type : Fight_Animation_Modifier.WeaponType, _dir : bool) -> String:
	return AnimName

func GetBlendInAnimationName(_type : Fight_Animation_Modifier.WeaponType, _dir : bool) -> String:
	return BlendInAnim

func GetBlendOutAnimationName(_type : Fight_Animation_Modifier.WeaponType, _dir : bool) -> String:
	return BlendOutAnim

func GetOnCompleteAnimationName(_type : Fight_Animation_Modifier.WeaponType, _dir : bool) -> String:
	return OnCompleteAnim

func AnimateBone(bone : int) -> bool:
	return BoneFilter & (1 << bone - 1) != 0
