extends CombatItemEffect

class_name DamageSelfItemEffect

@export var DamageAmm : int
#@export var AffectTeam : bool = false
@export var Percentile : bool = false

func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item
	
	var FinalDamage : int = DamageAmm
	
	#if (AffectTeam):
		#for g in Data["Team"] as Array[Character]:
			#if (Percentile):
				#FinalDamage = roundi(g.GetStat(CharacterStat.STATS.MAX_HP) * (DamageAmm / 100.0))
			#g.DamageFlat(DamageAmm, source.ItemIcon.resource_path)
	#else:
	var Char = Data["User"] as Character
	if (Percentile):
		FinalDamage = roundi(Char.GetStat(CharacterStat.STATS.MAX_HP) * (DamageAmm / 100.0))
	Char.DamageFlat(FinalDamage, source.ItemIcon.resource_path)

func GetDescription() -> String:
	var Desc : String = ""
	var DamageAmmount : String = var_to_str(DamageAmm)
	if (Percentile):
		DamageAmmount += "%"
	Desc = "Damage self by {0}".format([DamageAmmount])
	return Desc
