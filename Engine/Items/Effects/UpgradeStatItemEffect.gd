extends ItemEffect

class_name UpgradeStatItemEffect

@export var Stat : CharacterStat.STATS

func ApplyEffect(Data : Dictionary) -> void:
	#var source = Data["Source"] as Item
	
	var Char : Character = Data["User"]
	Char.UpgradeStat(Stat)
	AudioManager.Instance.PlaySound(AudioManager.Sound.MAGIC, 0, 0.2)

func GetDescription() -> String:
	var Desc : String
	
	Desc = "Upgrades {0}".format([Helper.GetNameOfStat(Stat)])
	return Desc
