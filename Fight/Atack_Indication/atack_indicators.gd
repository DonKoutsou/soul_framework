extends Control

class_name AtackIndicators

@export var LeftIndicator : TextureRect
@export var RightIndicator : TextureRect
@export var TopIndicator : TextureRect
@export var BotIndicator : TextureRect
@export var MidIndicator : TextureRect
@export var Anim : AnimationPlayer

var AtackMemory : Dictionary[FightCharacter.AtackSide, float] = {
	FightCharacter.AtackSide.LEFT : 0,
	FightCharacter.AtackSide.RIGHT : 0,
	FightCharacter.AtackSide.MIDDLE : 0,
	FightCharacter.AtackSide.LOW : 0,
	FightCharacter.AtackSide.TOP : 0,
}

func _ready() -> void:
	LeftIndicator.visible = false
	RightIndicator.visible = false
	TopIndicator.visible = false
	BotIndicator.visible = false
	MidIndicator.visible = false

func Update(delta : float) -> void:
	Anim.advance(delta)
	for g in AtackMemory:
		if (AtackMemory[g] > 0):
			AtackMemory[g] = max(0, AtackMemory[g] - delta)
			if (AtackMemory[g] == 0):
				AtackPerformed(g)
	
func ToggleHelp(t : bool) -> void:
	if (t):
		Anim.play("Bounce")
		visible = true
	else:
		Anim.stop()
		visible = false

func EnemyAtackStarted(Dir : FightCharacter.AtackSide) -> void:
	AtackMemory[Dir] = 0.4
	match (Dir):
		FightCharacter.AtackSide.RIGHT:
			LeftIndicator.visible = true
		FightCharacter.AtackSide.LEFT:
			RightIndicator.visible = true
		FightCharacter.AtackSide.TOP:
			TopIndicator.visible = true
		FightCharacter.AtackSide.LOW:
			BotIndicator.visible = true
		FightCharacter.AtackSide.MIDDLE:
			MidIndicator.visible = true


func AtackPerformed(Dir : FightCharacter.AtackSide) -> void:
	match (Dir):
		FightCharacter.AtackSide.RIGHT:
			LeftIndicator.visible = false
		FightCharacter.AtackSide.LEFT:
			RightIndicator.visible = false
		FightCharacter.AtackSide.TOP:
			TopIndicator.visible = false
		FightCharacter.AtackSide.LOW:
			BotIndicator.visible = false
		FightCharacter.AtackSide.MIDDLE:
			MidIndicator.visible = false

func AtackCanceled() -> void:
	LeftIndicator.visible = false
	RightIndicator.visible = false
	TopIndicator.visible = false
	BotIndicator.visible = false
	MidIndicator.visible = false
