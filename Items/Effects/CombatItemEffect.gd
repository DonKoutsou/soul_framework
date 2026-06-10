extends ItemEffect

class_name CombatItemEffect


func Effect(_Char : Character, _PlayerTeam : Array[Character], _ItemSource : Item) -> void:
	pass

func CombatEffect(_Char : Character, _PlayerTeam : Array[Character], _En : MonsterGroup, _EnTeam : Array[MonsterGroup], _ItemSource : Item) -> void:
	pass

func DamageEffec(_Char : Character, _En : MonsterGroup, _Damage : float, _ItemSource : Item) -> void:
	pass
