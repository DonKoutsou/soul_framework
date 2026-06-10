extends ItemEffect

class_name HealItemEffect

@export var HealAmm : int = 0
@export var Percentile : bool = false
@export var Resurect : bool = false
#@export var AffectTeam : bool = false

func HealChar(Char : Character, ItemSource : Item) -> void:
	var AmmountToHeal = HealAmm
	if (Percentile):
		AmmountToHeal = roundi(Char.GetStat(CharacterStat.STATS.MAX_HP) * (HealAmm / 100.0))
	if (Resurect):
			Char.Heal(AmmountToHeal, ItemSource.ItemIcon.resource_path)
	else: if (Char.IsAlive()):
		Char.Heal(AmmountToHeal, ItemSource.ItemIcon.resource_path)

func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item
	HealChar(Data["User"], source)
	AudioManager.Instance.PlaySound(AudioManager.Sound.LEVELUP, 0, 0.2)

func CanUse(Data : Dictionary) -> bool:
	var user = Data["User"] as Character
	return !user.IsFullHp()

func GetDescription() -> String:
	var Desc : String
	var HealStr : String = var_to_str(HealAmm)
	if (Percentile):
		HealStr += "%"
	#if (AffectTeam):
		#Desc = "Heal team for {0} hp".format([HealStr])
	#else:
	Desc = "Heal current character for {0} hp".format([HealStr])
	return Desc
	
