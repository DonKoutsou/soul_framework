extends ItemEffect

class_name DamageBuffItemEffect

@export var  BuffAmm : int = 0
#@export var AffectTeam : bool = false
@export var Percentile : bool = false

func ApplyEffect(Data : Dictionary) -> void:
	var source
	if (Data.has(["Srouce"])):
		source = Data["Source"]
	#if (AffectTeam):
		#for g in Data["Team"] as Array[Actor]:
			#BuffCharacter(g, source)
	#else:
	BuffCharacter(Data["User"], source)

func BuffCharacter(Char : Actor, ItemSource : Item) -> void:
	var AmmountToBuff = BuffAmm
	if (Percentile):
		AmmountToBuff = roundi(Char.CharacterWeapon.Damage * (BuffAmm / 100.0))
	if (ItemSource != null):
		Char.BuffNextAtackDamage(AmmountToBuff, ItemSource.ItemIcon.resource_path)
	else:
		Char.BuffNextAtackDamage(AmmountToBuff)

func GetDescription() -> String:
	var Desc : String = ""
	var BuffAmmount :String = var_to_str(BuffAmm)
	if (Percentile):
		BuffAmmount += "%"
	#if (AffectTeam):
		#Desc = "Buff team's next hit by {0}".format([BuffAmmount])
	#else:
	Desc = "Buff current character's next hit by {0}".format([BuffAmmount])
	return Desc
