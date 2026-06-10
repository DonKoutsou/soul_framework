@tool
extends Actor

class_name MonsterGroup

@export var Tiles : Array
@export var OriginalPos : Vector3i
@export var Mon : Monster
@export var LastKnownPosition : Vector3i
@export var PickedMat : Material
@export_file var Drop : String

signal Respawned

var PickedDecorations : Dictionary[String, int] = {
	"RA" : 0,
	"LS" : 0,
	"RS" : 0,
	"HE" : 0,
	"CH" : 0,
}

var variant_index : int = 0

func RegisterMonster(monster : Monster, r : RandomNumberGenerator, drop : String = "") -> void:
	Mon = monster
	Drop = drop
	Init(r)

func Respawn(_Amm : int) -> void:
	Respawned.emit()
	MaxHeal()
	
func IsTurnBased() -> bool:
	return Mon.AutoTurns

func BuffNextAtackDamage(Amm : int, Source : String = "") -> void:
	super(Amm, Source)
	if (Source != ""):
		MessageBox.RegisterEvent("[img={16}x{16}]{2}[/img] {0}'s next atack will do {1} more damage".format([Mon.MonsterName, Amm, Source]))
	else:
		MessageBox.RegisterEvent("{0} was enraged!".format([Mon.MonsterName]))

func BuffNextAtackSpeed(Amm : float, Source : String = "") -> void:
	super(Amm, Source)
	if (Source != ""):
		MessageBox.RegisterEvent("[img={16}x{16}]{2}[/img] {0}'s next atack got sped up by {1}".format([Mon.MonsterName, Amm, Source]))
	#else:
		#MessageBox.RegisterEvent("{0}'s next atack got sped up by {1}".format([Mon.MonsterName, Amm]))

func Init(r : RandomNumberGenerator) -> void:
	variant_index = r.randi_range(0, 2)
	CurrentHP = Mon.GetStat(CharacterStat.STATS.MAX_HP)
	CharacterWeapon = load(Mon.MonsterWeapons.pick_random())
	if (Mon.Materials.size() > 0):
		PickedMat = load(Mon.Materials.pick_random())
	for DecoType : String in Mon.DecorationAmm.keys():
		PickedDecorations[DecoType] = randi_range(0, Mon.DecorationAmm.size())

func GetStatContainer(StatName : CharacterStat.STATS) -> CharacterStat:
	return Mon.GetStatContainer(StatName)

func UpgradeStat(StatName : CharacterStat.STATS) -> void:
	Mon.UpgradeStat(StatName)
	StatsUpgraded.emit()
