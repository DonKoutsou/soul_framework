extends ItemEffect

class_name FatigueHealItemEffect

@export var HealAmm : int = 0
#@export var AffectTeam : bool = false

func HealFatigue(Char : Character, ItemSource : Item) -> void:
	Char.HealFatigue(HealAmm, ItemSource.ItemIcon.resource_path)


func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item
	
	#if (AffectTeam):
		#for g in Data["Team"] as Array[Character]:
			#HealFatigue(g, source)
	#else:
	HealFatigue(Data["User"], source)

func GetDescription() -> String:
	var Desc : String = ""
	#if (AffectTeam):
		#Desc = "Heal {0} fatigue from team".format([HealAmm])
	#else:
	Desc = "Heal {0} fatigue from current character".format([HealAmm])
	return Desc
