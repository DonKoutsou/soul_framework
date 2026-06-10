extends ItemEffect

class_name EXPItemEffect

@export var EXPAmm : int = 0
@export var AffectTeam : bool = false
@export var Percentile : bool = 0

func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item
	
	var ExpToGive = EXPAmm
	if (Percentile):
		if (Timing == EffectTiming.ON_KILL):
			ExpToGive = Data["Monster"].ExpReward * (EXPAmm / 100.0)
		else:
			ExpToGive = Data["User"].ExpToNextLevel()  * (EXPAmm / 100.0)
		
	#if (AffectTeam):
		#for g in Data["Team"] as Array[Character]:
			#g.GiveExp(ExpToGive, source.ItemIcon.resource_path)
	#else:
	Data["User"].GiveExp(ExpToGive, source.ItemIcon.resource_path)

func GetDescription() -> String:
	var Desc : String = ""
	var ExpAmm : String = var_to_str(EXPAmm)
	if (Percentile):
		ExpAmm += "%"
		if (Timing == ItemEffect.EffectTiming.ON_KILL):
			ExpAmm += " extra"
		else:
			ExpAmm += " of current level"
	
	if (AffectTeam):
		Desc = "Give {0} experience points to team".format([ExpAmm])
	else:
		Desc = "Give {0} experience points to current character".format([ExpAmm])
	return Desc
