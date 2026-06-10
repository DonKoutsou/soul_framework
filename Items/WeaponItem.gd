extends Item

class_name WeaponItem

@export var WeaponsRes : Weapon



func GetItemDesc() -> String:
	var text = super()
	var DamageText = "["
	var DamageAmm : int = roundi(WeaponsRes.Damage / 10)
	for g in 10:
		if (DamageAmm > 0):
			DamageText += "|"
		else:
			DamageText += "-"
		DamageAmm -= 1
	DamageText += "]"
	
	var WeightText = "["
	var WeightAmm : int = roundi(WeaponsRes.Stamina_Cost / 10)
	for g in 10:
		if (WeightAmm > 0):
			WeightText += "|"
		else:
			WeightText += "-"
		WeightAmm -= 1
	WeightText += "]"
	
	text += "\n[color=#e44d42ff]Damage:[/color] {0}\n[color=#56da59ff]Weight:[/color] {1}".format([DamageText, WeightText])
	
	return text
