extends ItemEffect

class_name SpeedBuffItemEffect

@export var  BuffAmm : float = 0
#@export var AffectTeam : bool = false

func BuffCharacter(Char : Actor, ItemSource : Item) -> void:
	if (ItemSource!= null):
		Char.BuffNextAtackSpeed(BuffAmm, ItemSource.ItemIcon.resource_path)
	else:
		Char.BuffNextAtackSpeed(BuffAmm, "")

func ApplyEffect(Data : Dictionary) -> void:
	var source
	if (Data.has("Source")):
		source = Data["Source"] as Item
		
	#if (AffectTeam):
		#for g in Data["Team"] as Array[Character]:
			#BuffCharacter(g, source)
	#else:
	BuffCharacter(Data["User"], source)

func GetDescription() -> String:
	var Desc : String = ""
	#if (AffectTeam):
		#Desc = "Buff team's speed of next hit by {0}".format([BuffAmm])
	#else:
	Desc = "Buff current character's speed of next hit by {0}".format([BuffAmm])
	return Desc
