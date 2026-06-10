extends ItemEffect

class_name HealStressEffect

@export_range(1,100,1.0) var HealAmm : int = 0
@export var Percentile : bool = false

func HealChar(Char : Character, ItemSource : Item) -> void:
	var AmmountToHeal = HealAmm

	Char.HealStress(AmmountToHeal, ItemSource.ItemIcon.resource_path)

func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item

	HealChar(Data["User"], source)

func GetDescription() -> String:
	var Desc : String
	var Amm : String = var_to_str(HealAmm)
	Amm += "%"

	Desc = "Refil Lantern by {0}".format([Amm])
	
	return Desc
	
