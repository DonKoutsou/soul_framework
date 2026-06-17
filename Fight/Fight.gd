extends Control

class_name FightScene

@export var FightWorld : FightWorld3D
@export var AtackIndicatorUI : AtackIndicators
@export var TutorialMan : TutorialManager

var InFight : bool = false

signal FightStared
signal FightEnded
signal EnviromentalAttack

signal EnemyKilled(Mon : MonsterGroup)
signal EnemyAtackStarted

signal Effect(Effect : ItemEffect.EffectTiming, Data : Dictionary)

signal TutorialToggled(t : bool)

#static var MapData : Map
var CurrentMosters : Array[MonsterGroup]

func _ready() -> void:
	
	AtackIndicatorUI.ToggleHelp(true)
	
	FightWorld.EnemyIntroFinished.connect(IntroFinished)
	
	GetPlayer().AtackPerformed.connect(EV_PlayerAtacked)
	GetPlayer().AtackParried.connect(EV_IncommingParried)
	GetPlayer().GuardBroken.connect(EV_PlayerGuardBroken)
	GetPlayer().AtackAvoided.connect(EV_IncommingAvoided)
	GetPlayer().AtackBlocked.connect(EV_IncommingBlocked)

func EnemtAttackStarted() -> void:
	EnemyAtackStarted.emit()

func GetCurrentEnemyCombatant() -> MonsterGroup:
	if (CurrentMosters.size() == 0):
		return null
	return CurrentMosters[0]

func GetAllEnemyCombatants() -> Array[MonsterGroup]:
	return CurrentMosters

func GetPlayer() -> Player:
	return FightWorld.Pl

func GetEnemy() -> Enemy:
	return FightWorld.En

func Update(delta: float) -> void:
	FightWorld.Update(delta)
	FightWorld.Pl.Update(delta)
	FightWorld.Pl.UpdateAnims(delta)
	ProcessFatigue(GetPlayer(), delta)
	AtackIndicatorUI.Update(delta)
	
	if (InFight):
		ProcessFatigue(GetEnemy(), delta)
		
func ProcessFatigue(character : FightCharacter,delta : float) -> void:
	if (!character.ControllingCharacter.IsAlive() or character.IsStunned()):
		return
		
	if (character.IsCharged() or character.IsCharging() or character.IsAttacking()):
		character.ControllingCharacter.HealFatigue(delta * 12)
	else :
		character.ControllingCharacter.HealFatigue(delta * 16)

func ProcessInput(event: InputEvent) -> void:
	TutorialMan.ProcessInput(event)
	FightWorld.Pl.ProcessInput(event)
	

func IsInFight() -> bool:
	return InFight

func ToggleHeadBob(t : bool) -> void:
	GetPlayer().ToggleCameraMovement(t)

func EnemyDeathComplete() -> void:
	if (CurrentMosters.size() > 0):
		var PickedGroup = CurrentMosters[0]
		await SpawnEnemy(PickedGroup)
		FightWorld.EnemyIntroAnim()

func SpawnEnemy(monsterActor : MonsterGroup) -> void:
	await FightWorld.SpawnEnemy(monsterActor)
	GetEnemy().AtackPerformed.connect(EV_EnemyAtacked)
	GetEnemy().AtackAvoided.connect(EV_OutgoingAvoided)
	GetEnemy().AtackBlocked.connect(EV_OutgoingBlocked)
	GetEnemy().AtackParried.connect(EV_OutgoingParried)
	GetEnemy().GuardBroken.connect(EV_EnemyGuardBroken)
	GetEnemy().AtackStarted.connect(AtackIndicatorUI.EnemyAtackStarted)
	if (TutorialMan.ShowTutorial):
		GetEnemy().AtackStarted.connect(TutorialMan.InitialAtack)
	GetEnemy().DeathAnimFin.connect(EnemyDeathComplete)
	

func EnemyMet(monsterActor : MonsterGroup) -> void:
	CurrentMosters.append(monsterActor)
	if (CurrentMosters.size() > 1):
		return
	StartFight()

func StartFight() -> void:
	var enemyCombatant = CurrentMosters[0]
	
	#enemyCombatant.Atack.connect(EV_EnemyAtacked)
	enemyCombatant.Killed.connect(EV_MonsterKilled.bind(enemyCombatant))
	enemyCombatant.Damaged.connect(EV_MonsterDamaged.bind(enemyCombatant))

	MessageBox.RegisterEvent("{0} is ambushed by a {1}".format([GetPlayer().ControllingCharacter.CharacterName, enemyCombatant.Mon.MonsterName]))

	await SpawnEnemy(enemyCombatant)
	var tw2 = create_tween()
	tw2.tween_method(UpdateAlpha, 0.0, 1.0, 1)
	
	InFight = true
	GetPlayer().GetReadyForFight()
	GetPlayer().SetLookModif(0)
	GetPlayer().InFight = true
	FightWorld.EnemyIntroAnim()
	
	InteractionCast.Instance.ToggleVisibility(false)
	FightStared.emit()

func EnemyDefeated() -> void:

	var DefeatedMonster = CurrentMosters.pop_front()
	#DefeatedMonster.Atack.disconnect(EV_EnemyAtacked)
	DefeatedMonster.Killed.disconnect(EV_MonsterKilled)
	DefeatedMonster.Damaged.disconnect(EV_MonsterDamaged)
	
	GetEnemy().Defeated()
	
	if (CurrentMosters.size() == 0):
		EndFight()

func EndFight() -> void:
	InteractionCast.Instance.ToggleVisibility(true)
	InFight = false
	
	var tw2 = create_tween()
	tw2.tween_method(UpdateAlpha, 1.0, 0.0, 1)
	
	FightWorld.Pl.LeftFight()
	#FightWorld.Pl.SetLookModif(1)
	MusicManager.Instance.PlayerMusic(MusicManager.Music.MAIN)
	Stage.CurrentWorld.ToggleAmbientSound(true)
	FightEnded.emit()

func PlayerKilled() -> void:
	if (!InFight):
		return

	var DefeatedMonster = CurrentMosters.pop_front()
	#DefeatedMonster.Atack.disconnect(EV_EnemyAtacked)
	DefeatedMonster.Killed.disconnect(EV_MonsterKilled)
	DefeatedMonster.Damaged.disconnect(EV_MonsterDamaged)
	
	CurrentMosters.clear()
	
	EndFight()
	GetEnemy().queue_free()

func IntroFinished() -> void:
	TutorialManager.Instance.PlayTextInstruction(TutorialManager.TutorialTypes.FIGHT)
	TutorialMan.IndicateGrab(false)
	MusicManager.Instance.PlayerMusic(MusicManager.Music.FIGHT)
	Stage.CurrentWorld.ToggleAmbientSound(false)

func _on_tutorial_manager_tutorial_finished() -> void:
	TutorialToggled.emit(false, true)

func _on_tutorial_manager_tutorial_presented() -> void:
	TutorialToggled.emit(true, true)

func UpdateAlpha(A : float) -> void:
	FightWorld.UpdateAlpha(A)
	$SubViewportContainer/SubViewport.transparent_bg = A < 1

func RegisterPlayerCharacter(character : Character) -> void:
	character.Damaged.connect(EV_CharacterDamaged.bind(character))
	GetPlayer().ControllingCharacter = character
	GetPlayer().EquipWeapon(character.CharacterWeapon, false)

func EV_EnemyAtacked(Direction : FightCharacter.AtackSide, power : float) -> void:
	if (!IsInFight()):
		return
	if (!GetPlayer().ControllingCharacter.IsAlive()):
		return
	var FightingMonster = CurrentMosters[0]
	FightingMonster.DamageFatigue(FightingMonster.CharacterWeapon.Stamina_Cost * power, "", false)

	var Dmg = FightingMonster.CharacterWeapon.Damage + FightingMonster.DamageBuff * power
	#var finalDamage = Dmg
	
	var finalDamage = GetPlayer().Damage(Dmg, Direction, GetEnemy().CurrentWeapon.Stamina_Cost * 0.001, power)
	if (finalDamage == 0):
		#AtackAvoided()
		return
	if (finalDamage == -1):
		#MessageBox.RegisterEvent("{0} parried the {1}'s atack".format([SelectedCharacter.CharacterName, FightingMonster.Mon.MonsterName]))
		return
	if (finalDamage == -2):
		#MessageBox.RegisterEvent("{0} avoided the {1}'s atack".format([SelectedCharacter.CharacterName, FightingMonster.Mon.MonsterName]))
		return
	#CurrentStress += 0.5
	GetPlayer().ControllingCharacter.Damage(finalDamage, FightingMonster)

func EV_PlayerAtacked(Direction : FightCharacter.AtackSide, power : float) -> void:
	GetPlayer().ControllingCharacter.DamageFatigue(GetPlayer().ControllingCharacter.CharacterWeapon.Stamina_Cost * power, "", false)

	if (IsInFight()):
		var FightingMonster = CurrentMosters[0]
		if (!FightingMonster.IsAlive()):
			return
		
		var Dmg = GetPlayer().ControllingCharacter.CharacterWeapon.Damage + GetPlayer().ControllingCharacter.DamageBuff * power
		
		var finalDamage = GetEnemy().Damage(Dmg, Direction, GetPlayer().ControllingCharacter.CharacterWeapon.Stamina_Cost * 0.001, power)
		if (finalDamage == 0):
			return
		if (finalDamage == -1):
			#MessageBox.RegisterEvent("The {1} parried {0}'s atack".format([SelectedCharacter.CharacterName, FightingMonster.Mon.MonsterName]))
			return
		if (finalDamage == -2):
			#MessageBox.RegisterEvent("The {1} avoided {0}'s atack".format([SelectedCharacter.CharacterName, FightingMonster.Mon.MonsterName]))
			return
			
		FightingMonster.Damage(finalDamage, GetPlayer().ControllingCharacter)
	else:
		EnviromentalAttack.emit()

func EV_IncommingParried() -> void:
	#Manequin.Spark()
	var FightingMonster = CurrentMosters[0]
	
	var Data : Dictionary = {
		"User" : GetPlayer().ControllingCharacter,
		#"Team" : AliveCharacters,
		"Monster" : FightingMonster,
		#"EnemyTeam" : CurrentMosterHouse[0].Spawns,
	}
	Effect.emit(ItemEffect.EffectTiming.ON_PARRY, Data)
	
	FightingMonster.DamageFatigue(GetPlayer().ControllingCharacter.CharacterWeapon.Stamina_Cost / 2)
	GetEnemy().Recoil(FightCharacter.AtackSide.MIDDLE, false, 100)
	PlayerCamera.start_shake(0.02,0.3, false, true)
	
	WorldTimeManager.Instance.FreezeTime(0)
	#WorldTimeManager.Instance.StartTime(0.35)
	#WorldTimeManager.Instance.StopTime(0.15)
	GetPlayer().Sparks()

func EV_PlayerGuardBroken() -> void:
	PlayerCamera.start_shake(0.02,0.3, false, true)
	GetPlayer().ControllingCharacter.DamageFatigue(30)

func EV_EnemyGuardBroken() -> void:
	var FightingMonster = CurrentMosters[0]
	FightingMonster.DamageFatigue(30)
	PlayerCamera.start_shake(0.02,0.3, false, true)

func EV_IncommingAvoided() -> void:
	var FightingMonster = CurrentMosters[0]
	
	var Data : Dictionary = {
		"User" : GetPlayer().ControllingCharacter,
		#"Team" : AliveCharacters,
		"Monster" : FightingMonster,
		#"EnemyTeam" : CurrentMosterHouse[0].Spawns,
	}
	Effect.emit(ItemEffect.EffectTiming.ON_EVADE, Data)

func EV_OutgoingParried() -> void:
	#FightingMonster.DamageFatigue(10)
	#Fight.GetPlayer().PunishRecovery(1)
	#SelectedCharacter.RecoveryPunished.emit()
	
	var FightingMonster = CurrentMosters[0]
	GetPlayer().ControllingCharacter.DamageFatigue(FightingMonster.CharacterWeapon.Stamina_Cost / 2)
	GetPlayer().Recoil()
	PlayerCamera.start_shake(0.02,0.3, false, false)
	#Manequin.Spark()
	#Fight.FreezeFrame()
	WorldTimeManager.Instance.FreezeTime(0)
	GetEnemy().Sparks()

func EV_IncommingBlocked(BlockedDamage : int) -> void:
	var FightingMonster = CurrentMosters[0]
	GetPlayer().ControllingCharacter.DamageFatigue(BlockedDamage * 2)
	#PlayerCamera.start_shake(0.02,0.3, false, false)
	#WorldTimeManager.Instance.FreezeTime()
	var Data : Dictionary = {
		"User" : GetPlayer().ControllingCharacter,
		#"Team" : AliveCharacters,
		"Monster" : FightingMonster,
		#"EnemyTeam" : CurrentMosterHouse[0].Spawns,
	}
	Effect.emit(ItemEffect.EffectTiming.ON_BLOCK, Data)
	
func EV_OutgoingBlocked(BlockedDamage : int) -> void:
	#Fight.GetEnemy().Recoil()
	#WorldTimeManager.Instance.FreezeTime()
	CurrentMosters[0].DamageFatigue(BlockedDamage * 2)
	#PlayerCamera.start_shake(0.02,0.3, false, false)

func EV_OutgoingAvoided() -> void:
	pass
	#CurrentMosterHouse[0].GetCurrentGroup().HealFatigue(10)
	#FreezeTime()
	#Fight.FreezeFrame()
	#Fight.GetPlayer().PunishRecovery()
	#SelectedCharacter.RecoveryPunished.emit()

func EV_MonsterDamaged(OriginalDamage : int, FinalDamage : int, Instigator : Actor, Mon : MonsterGroup) -> void:
	var Data : Dictionary = {
		"User" : GetPlayer().ControllingCharacter,
		#"Team" : AliveCharacters,
		"Monster" : Mon,
		#"EnemyTeam" : CurrentMosterHouse[0].Spawns,
		"OriginalDamage" : OriginalDamage,
		"FinalDamage" : FinalDamage,
		"Instigator" : Instigator
		
	}
	AudioManager.Instance.PlaySound(AudioManager.Sound.DAMAGE, -5, 0.2)
	Effect.emit(ItemEffect.EffectTiming.ON_HIT, Data)
	PlayerCamera.start_shake(0.02,0.3, false, true)
	#Fight.FreezeFrame()
	WorldTimeManager.Instance.FreezeTime(0.1, 0.1)

func EV_CharacterDamaged(OriginalDamage : int, FinalDamage : int, Instigator : Actor, Char : Character) -> void:
	#Fight.FreezeFrame()
	WorldTimeManager.Instance.FreezeTime(0.1, 0.1)
	PlayerCamera.start_shake(0.02,0.3, true, true)
	AudioManager.Instance.PlaySound(AudioManager.Sound.DAMAGE, -5, 0.2)
	if (Instigator == null):
		return
		
	var FightingMonster = GetCurrentEnemyCombatant()
	
	var Data : Dictionary = {
	"User" : Char,
	#"Team" : AliveCharacters,
	"Monster" : FightingMonster,
	#"EnemyTeam" : FightingMonster.Spawns,
	"OriginalDamage" : OriginalDamage,
	"FinalDamage" : FinalDamage,
	"Instigator" : Instigator
	}
	
	Effect.emit(ItemEffect.EffectTiming.ON_ATACKED, Data)


func EV_MonsterKilled(MonGroup : MonsterGroup) -> void:
	var Data : Dictionary = {
		"User" : GetPlayer().ControllingCharacter,
		#"Team" : AliveCharacters,
		"Monster" : MonGroup,
		#"EnemyTeam" : CurrentMosterHouse[0].Spawns,
	}
	
	Effect.emit(ItemEffect.EffectTiming.ON_KILL, Data)
	
	var GoldReward : int = roundi(randf_range(MonGroup.Mon.GoldReward * 0.8, MonGroup.Mon.GoldReward * 1.2))
	
	var Mon = MonGroup.Mon
	MessageBox.RegisterEvent("{0} killed, gained {1} light fragments".format([Mon.MonsterName, GoldReward]))

	EnemyKilled.emit(MonGroup, GoldReward)

	EnemyDefeated()
