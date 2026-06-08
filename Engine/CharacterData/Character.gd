extends Actor

class_name Character

@export var CharacterName : String
@export var CharacterStats : Array[CharacterStat]
@export var CanBreakBarrels : bool = false
@export_file("*.tscn") var Visuals : String

@export_group("RecruitData")
@export var CurrentStage : int = 0
@export var Stages : Array[RecruitStage]

enum RecruitState{
	INITIAL,
	TALKED,
	TO_MOVE,
	MOVED,
}

signal StressHealed(Amm : int, Source : String)

signal Picked(t : bool)

var CurrentExp : int = 0


#func ResetExp() -> void:
	#CurrentExp = 0
	#ExpGained.emit()

func TogglePickedChar(t : bool) -> void:
	Picked.emit(t)



func Init() -> void:
	CurrentHP = GetStat(CharacterStat.STATS.MAX_HP)

func EV_EnviromentalDamage(Origin : Map.TrapType, DamageAmm : int) -> void:
	if (Origin == Map.TrapType.FIRE_TRAP):
		MessageBox.RegisterEvent("Got hit by a fireball")
	else: if (Origin == Map.TrapType.SPIKE_TRAP):
		MessageBox.RegisterEvent("Stepped on spikes")
	else: if (Origin == Map.TrapType.SPIKE_TRAP):
		MessageBox.RegisterEvent("Hurt by fire")
	PlayerCamera.start_shake(0.02 ,0.3, true, false)
	DamageFlat(DamageAmm)

func BuffNextAtackDamage(Amm : int, Source : String = "") -> void:
	super(Amm, Source)
	if (Source != ""):
		MessageBox.RegisterEvent("[img={16}x{16}]{2}[/img] {0}'s next atack will do {1} more damage".format([CharacterName, Amm, Source]))
	#else:
		#MessageBox.RegisterEvent("{0}'s next atack will do {1} more damage".format([CharacterName, Amm]))

func BuffNextAtackSpeed(Amm : float, Source : String = "") -> void:
	super(Amm, Source)
	if (Source != ""):
		MessageBox.RegisterEvent("[img={16}x{16}]{2}[/img] {0}'s next atack got sped up by {1}".format([CharacterName, Amm, Source]))
	#else:
		#MessageBox.RegisterEvent("{0}'s next atack got sped up by {1}".format([CharacterName, Amm]))

func HealStress(Amm : int, Source : String = "") -> void:
	StressHealed.emit(Amm, Source)

func GetStatContainer(StatName : CharacterStat.STATS) -> CharacterStat:
	return CharacterStats[StatName]

func UpgradeStat(StatName : CharacterStat.STATS) -> void:
	var Stat : CharacterStat = CharacterStats[StatName]
	Stat.UpgradeLevel += 1
	StatsUpgraded.emit()
	MessageBox.RegisterEvent("{0} has been upgraded".format([Helper.GetNameOfStat(StatName)]))
