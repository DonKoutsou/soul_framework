@tool
extends AnimationInfo

class_name CombatAnimationInfo

@export var AlwaysR : bool = false

func GetAnimationName(type : Fight_Animation_Modifier.WeaponType, dir : bool) -> String:
	match (type):
		Fight_Animation_Modifier.WeaponType.ONE_HANDED:
			return AnimName
		Fight_Animation_Modifier.WeaponType.TWO_HANDED:
			return "2H_" + AnimName
		Fight_Animation_Modifier.WeaponType.DUAL:
			if (dir or AlwaysR):
				return "R_" + AnimName
			else:
				return AnimName
		Fight_Animation_Modifier.WeaponType.BOW:
			return "BOW_" + AnimName
	return AnimName

func GetBlendInAnimationName(type : Fight_Animation_Modifier.WeaponType, dir : bool) -> String:
	match (type):
		Fight_Animation_Modifier.WeaponType.ONE_HANDED:
			return BlendInAnim
		Fight_Animation_Modifier.WeaponType.TWO_HANDED:
			return "2H_" + BlendInAnim
		Fight_Animation_Modifier.WeaponType.DUAL:
			if (dir or AlwaysR):
				return "R_" + BlendInAnim
			else:
				return BlendInAnim
		Fight_Animation_Modifier.WeaponType.BOW:
			return "BOW_" + BlendInAnim
	return BlendInAnim

func GetBlendOutAnimationName(type : Fight_Animation_Modifier.WeaponType, dir : bool) -> String:
	match (type):
		Fight_Animation_Modifier.WeaponType.ONE_HANDED:
			return BlendOutAnim
		Fight_Animation_Modifier.WeaponType.TWO_HANDED:
			return "2H_" + BlendOutAnim
		Fight_Animation_Modifier.WeaponType.DUAL:
			if (dir or AlwaysR):
				return "R_" + BlendOutAnim
			else:
				return BlendOutAnim
		Fight_Animation_Modifier.WeaponType.BOW:
			return "BOW_" + BlendOutAnim
	return BlendOutAnim

func GetOnCompleteAnimationName(type : Fight_Animation_Modifier.WeaponType, dir : bool) -> String:
	match (type):
		Fight_Animation_Modifier.WeaponType.ONE_HANDED:
			return OnCompleteAnim
		Fight_Animation_Modifier.WeaponType.TWO_HANDED:
			return "2H_" + OnCompleteAnim
		Fight_Animation_Modifier.WeaponType.DUAL:
			if (dir or AlwaysR):
				return "R_" + OnCompleteAnim
			else:
				return OnCompleteAnim
		Fight_Animation_Modifier.WeaponType.BOW:
			return "BOW_" + OnCompleteAnim
	return OnCompleteAnim
