extends Resource

class_name CharacterStat

@export var StatName : STATS
@export var StatValue : int = 1
@export var UpgradeIntervals : int = 5
@export var UpgradeLevel : int = 0

static func GetIconForStat(St : STATS) -> String:
	var t : String
	
	match (St):
		STATS.MAX_HP:
			t = "res://Assets/StatIcons/Sprite-0003.png"
		STATS.MAX_MANA:
			t = "res://Assets/StatIcons/Sword.png"
		STATS.MAX_FATIGUE:
			t = "res://Assets/StatIcons/Speed.png"
		STATS.MAX_POISE:
			t = "res://Assets/StatIcons/Shield.png"
	return t

enum STATS
{
	MAX_HP,
	MAX_FATIGUE,
	MAX_MANA,
	MAX_POISE,
	#SPD,
}
