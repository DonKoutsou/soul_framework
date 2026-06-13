extends Item

class_name KeyItem

@export var ItemDesc : String
@export var Type : KeyItemType

func GetItemDesc() -> String:
	var text : String = ItemDesc
	
	for g in Effects:
		if (text != ""):
			text += "[p]"
		var effect : String = g.GetDescription()
		
		var effectstring : String = ItemEffect.EffectTiming.keys()[g.Timing]
		effectstring = effectstring.replace("_", " ")
		text += "[color=#56da59ff]{0}[/color] > {1}".format([effectstring, effect])
		
	if (ConsumeOnUse):
		text += "[p]Gets consumed on use"
	
	if (UsableBy != null):
		text += "[p]Only usable by [color=#1695bdff]{0}[/color]".format([UsableBy.CharacterName])
	
	if (Value > -1):
		text += "[p]Value : {0}".format([Value])
	else:
		text += "[p][color=#e44d42ff]Can't be sold"
		#var c = Color("e44d42ff")
	return text

enum KeyItemType{
	NONE = -1,
	LOCK_PICK = 0,
	CHEST_KEY = 1,
	ASSIST_RING = 2,
	MASTER_KEY = 3,
	WATER_BOOTS = 4,
	WING_BOOTS = 5,
	LAVA_BOOTS = 6,
	SHOVEL = 7,
	LANTERN = 8,
	KNIGHT_SWORD = 9
}
