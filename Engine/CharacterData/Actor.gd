extends Resource

class_name Actor


var SpeedBuff : float
var DamageBuff : int

signal Healed(Amm : int)
signal Damaged(OriginalDamage : int, FinalDamage : int, Instigator : Actor)
signal Killed
signal OnDeath

signal FatigueHealed(Amm : int)
signal FatigueDamaged(Amm : int)
signal SpeedBuffed
signal DamageBuffed
signal StatsUpgraded

@export var CurrentHP : int = 0
@export var CurrentMana : int = 0
var Fatigue : float = 0
var Poise : float = 0

@export var CharacterWeapon : Weapon

signal Exposed
var Exposure : float = 0

func IsStunned() -> bool:
	return Exposure > 0

func IsAlive() -> bool:
	return CurrentHP > 0

func IsFullHp() -> bool:
	return CurrentHP == GetStat(CharacterStat.STATS.MAX_HP)

func IsFullMP() -> bool:
	return CurrentMana == GetStat(CharacterStat.STATS.MAX_MANA)

func UpgradeStat(_StatName : CharacterStat.STATS) -> void:
	StatsUpgraded.emit()

func GetStat(StatName : CharacterStat.STATS) -> int:
	var Stat : CharacterStat = GetStatContainer(StatName)
	return Stat.StatValue + (Stat.UpgradeIntervals * Stat.UpgradeLevel)

func GetStatContainer(_StatName : CharacterStat.STATS) -> CharacterStat:
	return null

func Damage(finalDamage : int, Instigator : Actor, _Source : String = "") -> void:
	var DamageToDo = finalDamage
	if (Exposure > 0):
		DamageToDo *= 2.0
	CurrentHP = max(0, CurrentHP - DamageToDo)
	Damaged.emit(DamageToDo, DamageToDo, Instigator)
	if (CurrentHP <= 0):
		OnDeath.emit()
		Fatigue = 0
		DamageBuff = 0
		ResetSpeedBuff()
		if (CurrentHP <= 0):
			Killed.emit()
	

func DamageFlat(Dmg : int, Source : String = "") -> void:
	CurrentHP = max(0, CurrentHP - Dmg)
	
	AudioManager.Instance.PlaySound(AudioManager.Sound.DAMAGE, -5, 0.2)
	Damaged.emit(Dmg, Dmg, null)
	
	if (CurrentHP <= 0):
		OnDeath.emit()
		Fatigue = 0
		DamageBuff = 0
		ResetSpeedBuff()
		if (CurrentHP <= 0):
			Killed.emit()

func Heal(Amm : int, _Source : String = "") -> void:
	if (CurrentHP == GetStat(CharacterStat.STATS.MAX_HP)):
		return
	var AmmToHeal = min(GetStat(CharacterStat.STATS.MAX_HP) - CurrentHP, Amm)
	CurrentHP += AmmToHeal
	Healed.emit(AmmToHeal)

func MaxHeal() -> void:
	CurrentHP = GetStat(CharacterStat.STATS.MAX_HP)

func GetHPPercent() -> float:
	@warning_ignore("integer_division")
	return (CurrentHP as float / GetStat(CharacterStat.STATS.MAX_HP) as float) * 100.0

func DamageMana(Amm : float, _Source : String = "") -> void:
	if (CurrentMana == 0):
		return
		
	CurrentMana = max(0, CurrentMana - Amm)

	StatsUpgraded.emit()
	
func HealMana(Amm : float, _Source : String = "") -> void:
	if (CurrentMana == GetStat(CharacterStat.STATS.MAX_MANA)):
		return
		
	var AmmToHeal = min(GetStat(CharacterStat.STATS.MAX_MANA) - CurrentMana, Amm)
	CurrentMana += AmmToHeal

	StatsUpgraded.emit()

func HealFatigue(Amm : float, _Source : String = "") -> void:
	if (Fatigue == 0):
		return
	var AmmToHeal = min(Fatigue, Amm)
	Fatigue -= AmmToHeal
	FatigueHealed.emit(AmmToHeal)

func DamageFatigue(Amm : float, _Source : String = "", CanCauseStunn : bool = true) -> void:
	if (Fatigue == GetMaxFatigue()):
		return
	var AmmToHeal = min(GetMaxFatigue() - Fatigue, Amm)
	Fatigue += AmmToHeal
	
	
	if (Fatigue == GetMaxFatigue() and CanCauseStunn):
		Exposure = 1
		Exposed.emit()
	
	FatigueDamaged.emit(Amm)

func BuffNextAtackDamage(Amm : int, _Source : String = "") -> void:
	DamageBuff += Amm
	DamageBuffed.emit()

func BuffNextAtackSpeed(Amm : float, _Source : String = "") -> void:
	SpeedBuff += Amm
	if (Amm == 0):
		return
	SpeedBuffed.emit()

func ResetSpeedBuff() -> void:
	if (SpeedBuff == 0):
		return
	SpeedBuff = 0
	SpeedBuffed.emit()

func GetMaxFatigue() -> float:
	return GetStat(CharacterStat.STATS.MAX_FATIGUE)
