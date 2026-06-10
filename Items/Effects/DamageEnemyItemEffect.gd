extends CombatItemEffect

class_name DamageEnemyItemEffect

@export var DamageAmm : int
@export var AffectTeam : bool = false

func ApplyEffect(Data : Dictionary) -> void:
	var source = Data["Source"] as Item
	
	#if (AffectTeam):
		#for g in Data["EnemyTeam"] as Array[MonsterGroup]:
			#g.DamageFlat(DamageAmm, source.ItemIcon.resource_path)
	#else:
	Data["Monster"].DamageFlat(DamageAmm, source.ItemIcon.resource_path)
