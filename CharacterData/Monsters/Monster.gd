@tool
extends Resource

class_name Monster

@export var MonsterName : String

@export_group("Settings")
##Monster stats, its mandatory to condigure
@export var MonsterStats : Array[CharacterStat]

##Possible weapons monster could spawn with
@export_file("*.tres") var MonsterWeapons : Array[String]

##Effects monster will have when being damages, parries etc...
@export var Effects : Array[ItemEffect]

##Highter difficulty means monster takes decisions faster and will react better to player inputs
@export var Dificulty : MonsterDifficulty = MonsterDifficulty.E

##if set to true monster will take an action only after player has instead of working in realtime
@export var AutoTurns : bool = false

##Item monster will reward to player when killed
@export var Drop : Item

@export var GoldReward : int = 1

@export_group("Monster Visuals")
@export_file("*.tscn") var Visuals : String
@export_file("*.tscn") var Skeleton : String

@export_file("*.tres") var Materials : Array[String]
@export var DecorationAmm : Dictionary[String, int] = {
	"RA" : 0,
	"LS" : 0,
	"RS" : 0,
	"HE" : 0,
	"CH" : 0,
}

##Returns the value of a stat
func GetStat(StatName : CharacterStat.STATS) -> int:
	var Stat : CharacterStat = MonsterStats[StatName]
	return Stat.StatValue + (Stat.UpgradeIntervals * Stat.UpgradeLevel)

func GetStatContainer(StatName : CharacterStat.STATS) ->CharacterStat:
	return MonsterStats[StatName]

##Upgrades a stat by 1
func UpgradeStat(StatName : CharacterStat.STATS) -> void:
	var Stat : CharacterStat = MonsterStats[StatName]
	Stat.UpgradeLevel += 1
	

func GetExtraMoves() -> float:
	var Cooldown : float = 0
	match (Dificulty):
		MonsterDifficulty.E:
			Cooldown = 1.0
		MonsterDifficulty.D:
			Cooldown = 0.8
		MonsterDifficulty.C:
			Cooldown = 0.6
		MonsterDifficulty.B:
			Cooldown = 0.4
		MonsterDifficulty.A:
			Cooldown = 0.2
		MonsterDifficulty.S:
			Cooldown = 0.0
	return Cooldown

##Returns the cooldown a mosnter will have when taking decisions against the player
func GetDecisionCooldown() -> float:
	var Cooldown : float = 0
	match (Dificulty):
		MonsterDifficulty.E:
			Cooldown = 0.5
		MonsterDifficulty.D:
			Cooldown = 0.28
		MonsterDifficulty.C:
			Cooldown = 0.24
		MonsterDifficulty.B:
			Cooldown = 0.18
		MonsterDifficulty.A:
			Cooldown = 0.14
		MonsterDifficulty.S:
			Cooldown = 0.10
	return Cooldown

##used for actions that help the monster, the more difficult the monster the bigger the number this function will return, value is normalised
func GetGoodActionWeight() -> float:
	@warning_ignore("integer_division")
	return (MonsterDifficulty.keys().size() - Dificulty) / MonsterDifficulty.keys().size()

##used for actions that go against the monster, the more difficult the monster the smaller the number this function will return, value is normalised
func GetBadActionWeight() -> float:
	@warning_ignore("integer_division")
	return Dificulty / MonsterDifficulty.keys().size()

enum MonsterDifficulty{
	S,
	A,
	B,
	C,
	D,
	E,
}
