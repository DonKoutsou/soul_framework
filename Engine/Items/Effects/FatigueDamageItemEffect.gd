extends ItemEffect

class_name FatigueDamageItemEffect

@export var DamageAmm : int = 0
#@export var AffectTeam : bool = false

func DamageFatigue(Char : Character, ItemSource : Item) -> void:
	Char.DamageFatigue(DamageAmm, ItemSource.ItemIcon.resource_path)

func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item
	
	#if (AffectTeam):
		#for g in Data["Team"] as Array[Character]:
			#DamageFatigue(g, source)
	#else:
	DamageFatigue(Data["User"], source)

func GetDescription() -> String:
	var Desc : String = ""
	#if (AffectTeam):
		#Desc = "{0} damage to team's fatigue".format([DamageAmm])
	#else:
	Desc = "{0} damage to current character's fatigue".format([DamageAmm])
	return Desc
