extends Resource

class_name Item

@export var ItemName : String
@export var Effects : Array[ItemEffect]
@export var ConsumeOnUse : bool = false
@export var Value : int = 1
@export var UsableBy : Character
@export var Model : Mesh
@export var ModelMat : Material
@export var Stack : bool = false


func GetItemDesc() -> String:
	var text : String = ""
	
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
		text += "[p]Value : [img={16}x{16}]res://Assets/ItemIcons/Gold.png[/img]{0}".format([Value])
	else:
		text += "[p][color=#e44d42ff]Can't be sold[/color]"
	return text
