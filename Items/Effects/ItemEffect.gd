extends Resource

class_name ItemEffect

@export var Timing : EffectTiming

func ApplyEffect(_Data : Dictionary) -> void:
	pass

func CanUse(_Data : Dictionary) -> bool:
	return true

func GetDescription() -> String:
	return "Class Missing Description"

func OnUse() -> void:
	pass

enum EffectTiming {
	ON_KILL,
	ON_HIT,
	ON_ATACKED,
	ON_EVADE,
	ON_DEATH,
	ON_REST,
	ON_PARRY,
	ON_BLOCK,
	ON_USE,
}
