extends ItemEffect

class_name ReflectDamageEffect

@export_range(1, 100, 1) var ReflectPercent : int = 100

func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item
	
	var per = ReflectPercent / 100.0
	
	Data["Instigator"].DamageFlat(Data["FinalDamage"] * per, source.ItemIcon.resource_path)

func GetDescription() -> String:
	return "Reflect {0}% of damage".format([ReflectPercent])
