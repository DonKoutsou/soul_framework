extends FightWeapon

class_name AnimatedFightWeapon

@export var Anim : AnimationPlayer

func AnimateWeapon(AnimName : String = "Anim") -> void:
	Anim.play(AnimName)
	
	
