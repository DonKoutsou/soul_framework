extends Node3D

class_name FightCharacter

@export_group("Nodes")
@export var Anim : AnimationPlayer
@export var WeaponPlecement : Node3D
@export var WeaponPlecement2 : Node3D
@export var SwipeShape : MeshInstance3D
@export var SwipeShape2 : MeshInstance3D

@export var sk : Skeleton3D
@export var SkeletonModif : Fight_Animation_Modifier

@export_group("Settings")
@export var Can_Retaliate : bool = false

var CurrentState : CharacterState = CharacterState.IDLE

var LookDir : Vector3
#var RecoveryPenalty : float
var ControllingCharacter : Actor

enum CharacterState{
	IDLE,
	IDLE_LANTERN,
	CHARGING,
	CHARGING_LEFT,
	CHARGINE_RIGHT,
	CHARGING_TOP,
	CHARGING_LOW,
	CHARGING_MIDDLE,
	CHARGED_LEFT,
	CHARGED_RIGHT,
	CHARGED_TOP,
	CHARGED_LOW,
	CHARGED_MIDDLE,
	HITTING_LEFT,
	HITTING_RIGHT,
	HITTING_TOP,
	HITTING_LOW,
	HITTING_MIDDLE,
	DUCKING_LEFT,
	DUCKING_RIGHT,
	PARRY,
	REPOSTE,
	RECOVERING_LEFT,
	RECOVERING_RIGHT,
	RECOVERING_TOP,
	RECOVERING_LOW,
	RECOVERING_MIDDLE,
	RECOIL_LEFT,
	RECOIL_RIGHT,
	RECOIL_MID,
	RECOIL_LEFT_RETALIATION,
	RECOIL_RIGHT_RETALIATION,
	RECOIL_MID_RETALIATION,
	STUN,
	DEATH,
	RECOVERING_HIT_LEFT,
	RECOVERING_HIT_RIGHT,
	RECOVERING_HIT_TOP,
	RECOVERING_HIT_LOW,
	RECOVERING_HIT_MIDDLE,
	EXTEND_HAND,
	DIG
}

enum AtackSide{
	LEFT,
	RIGHT,
	MIDDLE,
	LOW,
	TOP
}

signal AtackCanceled
signal AtackParried
signal GuardBroken
signal AtackAvoided
signal AtackBlocked(BlockedDamage : int)

signal AtackStarted(Direction : AtackSide)
signal AtackPerformed(Direction : AtackSide)

signal AtackCharged(Direction : AtackSide)
signal CharacterDucked(Dir : AtackSide)
signal CharacterUnducked()

signal StepPerformed

var CanMove : bool = true
var ComboWindowOpen : bool = false

var WeaponScenes : Array[FightWeapon]
var CurrentWeapon : Weapon

var Parrying : bool = false
var Blocking : bool = false
var StartingParry : bool = false

var RecoilTween : Tween

var Dead : bool = true
var DuckCoolDown : float = 0
var ParryCooldDown : float = 0

func _ready() -> void:
	sk.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	
func Update(delta: float) -> void:
	if (is_instance_valid(RecoilTween) and RecoilTween.is_valid()): 
		if (!RecoilTween.custom_step(delta)):
			RecoilTween.kill()
	DuckCoolDown = max(0, DuckCoolDown - delta)
	ParryCooldDown = max(0, ParryCooldDown - delta)
	UpdateSkeletonState()

func UpdateSkeletonState() -> void:
	SkeletonModif.CurrentState = CurrentState

func UpdateAnims(delta : float) -> void:
	sk.advance(delta)


func Exposed() -> void:
	#SetStun(1.0)
	CancelHits()
	UpdateState(CharacterState.STUN)
	Parrying = false
	Blocking = false
	StartingParry = false

#func PunishRecovery(Amm : float = 2) -> void:
	#RecoveryPenalty = Amm

func OnAttackCharged(dir : AtackSide) -> void:
	if (IsCharging()):
		UpdateState(GetChargeStateBasedOnSide(dir))
		AtackCharged.emit(dir)

func RecoilFinished() -> void:
	if (IsRecoiling()):
		UpdateState(CharacterState.IDLE)

func Parry() -> void:
	if (CurrentState == CharacterState.DUCKING_LEFT):
		if (!UnDuck(AtackSide.LEFT)):
			return
		
	if (CurrentState == CharacterState.DUCKING_RIGHT):
		if (!UnDuck(AtackSide.RIGHT)):
			return

	CancelHits()
	StartingParry = true
	#SetParry(true)
	UpdateState(CharacterState.PARRY)
	ParryCooldDown = 0.3

func GetFightName() -> String:
	return ""

func SetComboWindow(t : bool) -> void:
	print("{0} - Combo window open = {1}".format([GetFightName(), t]))
	ComboWindowOpen = t
#----------------------------------------------------
func StopParry(force : bool = false) -> void:
	if (force):
		ParryCooldDown = 0
	if (ParryCooldDown != 0):
		return
	if (CurrentState == CharacterState.PARRY):
		UpdateState(CharacterState.IDLE)
	Parrying = false
	Blocking = false
	StartingParry = false

#----------------------------------------------------
func ParryWindowStart() -> void:
	if (CurrentState != CharacterState.PARRY):
		return
	Parrying = true
	Blocking = false
	StartingParry = false
#----------------------------------------------------
func ParryWindowOver() -> void:
	if (CurrentState != CharacterState.PARRY):
		return
	if (!Parrying):
		return
	Parrying = false
	Blocking = true
	StartingParry = false
#----------------------------------------------------
func GetReadyForFight() -> void:
	pass
#----------------------------------------------------
func SetControllingChar(Char : Actor) -> void:
	ControllingCharacter = Char
	Char.Exposed.connect(Exposed)
	Char.SpeedBuffed.connect(SpeedChanged)
	
	

func SpeedChanged() -> void:
	var animSpeed = GetAnimSpeed()
	SkeletonModif.currentWeaponSpeed = animSpeed
#----------------------------------------------------
func EquipWeapon(W : Weapon, Notify : bool = true) -> void:
	ComboWindowOpen = false
	#UpdateState(FightCharacter.CharacterState.IDLE)
		
	if (WeaponScenes.size() > 0):
		for g in WeaponScenes:
			g.queue_free()
		WeaponScenes.clear()
	#Store new weapon
	CurrentWeapon = W
	
	#Set up the visuals
	var WeaponScene = W.WeaponScene.instantiate() as FightWeapon
	WeaponPlecement.add_child(WeaponScene)
	WeaponScene.wepSound = W.WeaponClashSound
	WeaponScenes.append(WeaponScene)
	
	var weaponAABB: AABB = Helper.get_node_aabb(WeaponScene)
	var WeaponAbbSize = weaponAABB.size
	
	#Set position and size of the Swipe mesh
	SwipeShape.position.y = WeaponAbbSize.y + weaponAABB.position.y
	SwipeShape.scale.y = WeaponAbbSize.y * 100
	
	
	if (W.WeaponType == Fight_Animation_Modifier.WeaponType.DUAL):
		var WeaponScene2 = W.WeaponScene.instantiate() as FightWeapon
		WeaponPlecement2.add_child(WeaponScene2)
		WeaponScenes.append(WeaponScene2)
		WeaponScene2.wepSound = W.WeaponClashSound
		
		var weaponAABB2: AABB = Helper.get_node_aabb(WeaponScene2)
		var WeaponAbbSize2 = weaponAABB2.size
	
		#Set position and size of the Swipe mesh
		SwipeShape2.position.y = WeaponAbbSize2.y + weaponAABB2.position.y 
		SwipeShape2.scale.y = WeaponAbbSize2.y * 100
		
	var animSpeed = GetAnimSpeed()
	SkeletonModif.currentWeaponSpeed = animSpeed
	SkeletonModif.UpdateWeaponType(W.WeaponType)
	
	if (Notify):
		AudioManager.Instance.PlaySound(AudioManager.Sound.SEATH_IN, 0, 0.2)
		MessageBox.RegisterEvent("Held weapon changed")
		
#----------------------------------------------------
func Bang() -> void:
	Anim.play("Bang")
	
#----------------------------------------------------
func GetAnimSpeed() -> float:
	return max(0.6, CurrentWeapon.Speed + ControllingCharacter.SpeedBuff)
	
#----------------------------------------------------
#Function called to cancel any charged hits
func CancelHits() -> void:
	#print("{0} - Canceling hits".format([GetFightName()]))

	SetComboWindow(false)
	
	if (IsAttacking()):
		UpdateState(GetRecoveryBasedOnSide(GetAtackBasedOnState()))
		SetComboWindow(false)
		
	else: if (IsCharging() or IsCharged()):
		UpdateState(GetChargeRecoveryBasedOnSide(GetAtackBasedOnState()))
		
	else: if (IsRecovering()):

		SetComboWindow(false)
	else:

		UpdateState(CharacterState.IDLE)
		SetComboWindow(false)

	AtackCanceled.emit()
#----------------------------------------------------
func Hit(Direction : AtackSide) -> void:
	if (CurrentState == CharacterState.CHARGED_LEFT):
		UpdateState(CharacterState.HITTING_LEFT)

	else: if (CurrentState == CharacterState.CHARGED_RIGHT):
		UpdateState(CharacterState.HITTING_RIGHT)

	else: if (CurrentState == CharacterState.CHARGED_MIDDLE):
		UpdateState(CharacterState.HITTING_MIDDLE)

	else: if (CurrentState == CharacterState.CHARGED_TOP):
		UpdateState(CharacterState.HITTING_TOP)

	else: if (CurrentState == CharacterState.CHARGED_LOW):
		UpdateState(CharacterState.HITTING_LOW)
		
	else:
		#print("{0} - Couldn't process hit".format([GetFightName()]))
		return

	AtackStarted.emit(Direction)

#----------------------------------------------------
#Called from animation
func OnAtackPerformed(Direction : AtackSide) -> void:
	if (IsAttacking()):
		SetComboWindow(true)
		#UpdateState(CharacterState.IDLE)
		UpdateState(GetRecoveryBasedOnSide(Direction))
		var SpeedBuffBefore = ControllingCharacter.SpeedBuff
		var DamageBuffBefore = ControllingCharacter.DamageBuff
		
		ControllingCharacter.BuffNextAtackSpeed(-SpeedBuffBefore)
		ControllingCharacter.DamageBuff -= DamageBuffBefore
		AtackPerformed.emit(Direction)
	else: if (IsRetaliating()):
		var SpeedBuffBefore = ControllingCharacter.SpeedBuff
		var DamageBuffBefore = ControllingCharacter.DamageBuff
		
		ControllingCharacter.BuffNextAtackSpeed(-SpeedBuffBefore)
		ControllingCharacter.DamageBuff -= DamageBuffBefore
		AtackPerformed.emit(Direction)
	else:
		print("{0} - Could not perform atack, current state = {1}".format([GetFightName(),CharacterState.keys()[CurrentState]]))
		return

#----------------------------------------------------
func UpdateState(NewState : CharacterState) -> void:
	CurrentState = NewState
	print("{0} - Updated State to {1}".format([GetFightName(),CharacterState.keys()[NewState]]))
	
	
#----------------------------------------------------
func ChargeHit(Direction : AtackSide) -> void:
	if (CurrentState == CharacterState.PARRY):
		StopParry(true)
		
	if (CurrentState == CharacterState.DUCKING_LEFT):
		if (!UnDuck(AtackSide.LEFT)):
			return
		
	if (CurrentState == CharacterState.DUCKING_RIGHT):
		if (!UnDuck(AtackSide.RIGHT)):
			return
	#Cant start a hit unless we are on idle
	if (CurrentState != CharacterState.IDLE and !ComboWindowOpen):
		print("{0} - Cant start a hit unless we are on idle".format([GetFightName()]))
		return

	if (Direction == AtackSide.LEFT):
		UpdateState(CharacterState.CHARGING_LEFT)
	else: if (Direction == AtackSide.RIGHT):
		UpdateState(CharacterState.CHARGINE_RIGHT)
	else: if (Direction == AtackSide.MIDDLE):
		UpdateState(CharacterState.CHARGING_MIDDLE)
	else: if (Direction == AtackSide.LOW):
		UpdateState(CharacterState.CHARGING_LOW)
	else: if (Direction == AtackSide.TOP):
		UpdateState(CharacterState.CHARGING_TOP)
		
	print("{0} - Charging : {1}".format([GetFightName() ,AtackSide.keys()[Direction]]))
	
	SetComboWindow(false)
#----------------------------------------------------
func Duck(Direction : AtackSide) -> void:
	StopParry(true)
	CancelHits()
	
	if (Direction == AtackSide.LEFT):
		if (CurrentState == CharacterState.DUCKING_LEFT):
			return
		UpdateState(CharacterState.DUCKING_LEFT)
	else:
		if (CurrentState == CharacterState.DUCKING_RIGHT):
			return
		UpdateState(CharacterState.DUCKING_RIGHT)
	
	DuckCoolDown = 0.3
	AudioManager.Instance.PlaySound(AudioManager.Sound.EVADE, -15, 0.1, 1)
	CharacterDucked.emit(Direction)
#----------------------------------------------------
func UnDuck(Direction : AtackSide) -> bool:
	if (DuckCoolDown != 0):
		return false
		
	if (!IsDucking()):
		return true
		
	if (Direction == AtackSide.LEFT and CurrentState == CharacterState.DUCKING_LEFT):
		#duckSateMachine.travel("End")
		UpdateState(CharacterState.IDLE)
		CharacterUnducked.emit()
	if (Direction == AtackSide.RIGHT and CurrentState == CharacterState.DUCKING_RIGHT):
		#duckSateMachine.travel("End")
		UpdateState(CharacterState.IDLE)
		CharacterUnducked.emit()
	
	return true
#----------------------------------------------------
func Recoil(Dir : AtackSide = AtackSide.MIDDLE, HitConnected : bool = false, Magnitude : float = 0) -> void:
	if (HitConnected):
		if (is_instance_valid(RecoilTween) and RecoilTween.is_valid()):
			RecoilTween.kill()
		RecoilTween = create_tween()
		RecoilTween.set_ease(Tween.EASE_OUT)
		RecoilTween.set_trans(Tween.TRANS_BACK)
		RecoilTween.tween_property(SkeletonModif, "Recoil", GetRecoil(Dir), 0.1)
		RecoilTween.pause()
		
	if (IsAttacking()):
		if (ControllingCharacter.CharacterWeapon.Stamina_Cost > Magnitude):
			return

	CancelHits()
	StopParry(true)
	
	var retaliating : bool = false
	if (Can_Retaliate):
		var r = randi_range(1,10)
		if (r <= 2 and !IsStunned()):
			retaliating = true

	match Dir:
		AtackSide.LEFT:
			if (retaliating):
				UpdateState(CharacterState.RECOIL_LEFT_RETALIATION)
			else:
				UpdateState(CharacterState.RECOIL_LEFT)
		AtackSide.RIGHT:
			if (retaliating):
				UpdateState(CharacterState.RECOIL_RIGHT_RETALIATION)
			else:
				UpdateState(CharacterState.RECOIL_RIGHT)
		AtackSide.MIDDLE:
			if (retaliating):
				UpdateState(CharacterState.RECOIL_MID_RETALIATION)
			else:
				UpdateState(CharacterState.RECOIL_MID)
	
#----------------------------------------------------
func Damage(DamageAmm : int, Direction : AtackSide, _ShakeAmm : float, AtackWeight : float) -> int:
	if (IsDuckingDirCorrect(Direction)):
		AtackAvoided.emit()
		return 0
	
	if (Direction == AtackSide.LOW):
		if (Parrying or Blocking or StartingParry):
			StopParry(true)
			
		Recoil(Direction, true, AtackWeight)
		GuardBroken.emit()
		return 1
		
	if (Parrying):
		AtackParried.emit()
		return -1
		
	if (Blocking):
		AudioManager.Instance.PlaySound(CurrentWeapon.WeaponClashSound, -5, 0.1, 0.6)
		AtackBlocked.emit(DamageAmm)
		Recoil(Direction, true, AtackWeight)
		return 0
	
	print("{0} - Damaged".format([GetFightName()]))
	
	Recoil(Direction, true, AtackWeight)
	return DamageAmm
#----------------------------------------------------
#Called from animation
func StepSound() -> void:
	StepPerformed.emit()
	
#----------------------------------------------------
#Called from animation
func Whosh() -> void:
	AudioManager.Instance.PlaySound(AudioManager.Sound.WHOSH, -5, 0.05, CurrentWeapon.Speed - 0.4)
#----------------------------------------------------
func Sparks() -> void:
	for WeaponScene in WeaponScenes:
		WeaponScene.Sparks()
#----------------------------------------------------
func Kill() -> void:
	pass
func GetRequiredStaminaForHit() -> float:
	return ControllingCharacter.CharacterWeapon.Stamina_Cost
func HasStaminaForHit() -> bool:
	return ControllingCharacter.GetMaxFatigue() - ControllingCharacter.Fatigue > GetRequiredStaminaForHit()
 #----------------------------------------------------
var fadingout : bool = false
func AnimTreeFinished(anim_name: StringName) -> void:
	print("{0} - Anim finished {1}".format([GetFightName(),anim_name]))
	#if (anim_name in ["Hit_Left", "Hit_Right", "Hit_Mid"] and IsRecoiling()):
		#UpdateState(CharacterState.IDLE)
	
	if (anim_name in ["Atack_Top", "Atack_Left", "Atack_Right", "Atack_Middle", "Atack_Low", "2H_Atack_Left", "2H_Atack_Right","2H_Atack_Middle", "Atack_Bow", "Hit_Left_Retaliation", "Hit_Right_Retaliation", "Hit_Mid_Retaliation"]):
		SetComboWindow(false)
		if (CurrentState == GetStateBasedOnAnim(anim_name)):
			#state_machine.travel("Idle")
			#RecoveryPenalty = 0
			UpdateState(FightCharacter.CharacterState.IDLE)
			
	if (anim_name in ["Charge_Right_Reversed", "Charge_Left_Reversed", "Charge_Middle_Reversed", "Charge_Low_Reversed", "Charge_Top_Reversed"] and IsRecovering()):
		SetComboWindow(false)
		#state_machine.travel("Idle")
		UpdateState(FightCharacter.CharacterState.IDLE)
		#RecoveryPenalty
#----------------------------------------------------
func GetAtackBasedOnState() -> AtackSide:
	match (CurrentState):
		CharacterState.DUCKING_LEFT:
			return AtackSide.LEFT
		CharacterState.DUCKING_RIGHT:
			return AtackSide.RIGHT
		CharacterState.CHARGINE_RIGHT:
			return AtackSide.RIGHT
		CharacterState.CHARGING_LEFT:
			return AtackSide.LEFT
		CharacterState.CHARGING_MIDDLE:
			return AtackSide.MIDDLE
		CharacterState.CHARGING_TOP:
			return AtackSide.TOP
		CharacterState.CHARGING_LOW:
			return AtackSide.LOW
		CharacterState.CHARGED_RIGHT:
			return AtackSide.RIGHT
		CharacterState.CHARGED_LEFT:
			return AtackSide.LEFT
		CharacterState.CHARGED_MIDDLE:
			return AtackSide.MIDDLE
		CharacterState.CHARGED_TOP:
			return AtackSide.TOP
		CharacterState.CHARGED_LOW:
			return AtackSide.LOW
		CharacterState.HITTING_RIGHT:
			return AtackSide.RIGHT
		CharacterState.HITTING_TOP:
			return AtackSide.TOP
		CharacterState.HITTING_LEFT:
			return AtackSide.LEFT
		CharacterState.HITTING_MIDDLE:
			return AtackSide.MIDDLE
		CharacterState.HITTING_LOW:
			return AtackSide.LOW
		CharacterState.RECOIL_LEFT_RETALIATION:
			return AtackSide.LEFT
		CharacterState.RECOIL_RIGHT_RETALIATION:
			return AtackSide.RIGHT
		CharacterState.RECOIL_MID_RETALIATION:
			return AtackSide.MIDDLE
		_:
			return AtackSide.MIDDLE
#----------------------------------------------------
func GetStateBasedOnSide(side : AtackSide) -> CharacterState:
	match(side):
		AtackSide.LEFT:
			return CharacterState.HITTING_LEFT
		AtackSide.RIGHT:
			return CharacterState.HITTING_RIGHT
		AtackSide.TOP:
			return CharacterState.HITTING_TOP
		AtackSide.MIDDLE:
			return CharacterState.HITTING_MIDDLE
		AtackSide.LOW:
			return CharacterState.HITTING_LOW
		_:
			return -1
#----------------------------------------------------
func GetChargeStateBasedOnSide(side : AtackSide) -> CharacterState:
	match(side):
		AtackSide.LEFT:
			return CharacterState.CHARGED_LEFT
		AtackSide.RIGHT:
			return CharacterState.CHARGED_RIGHT
		AtackSide.MIDDLE:
			return CharacterState.CHARGED_MIDDLE
		AtackSide.TOP:
			return CharacterState.CHARGED_TOP
		AtackSide.LOW:
			return CharacterState.CHARGED_LOW
		_:
			return -1
#----------------------------------------------------
func GetReversedCharge() -> String:
	match (CurrentState):
		CharacterState.CHARGED_RIGHT:
			return "Charge_Right_Reversed"
		CharacterState.CHARGED_LEFT:
			return "Charge_Left_Reversed"
		CharacterState.CHARGED_MIDDLE:
			return "Charge_Middle_Reversed"
		CharacterState.CHARGED_TOP:
			return "Charge_Top_Reversed"
		CharacterState.CHARGED_LOW:
			return "Charge_Low_Reversed"
		_:
			return ""
#----------------------------------------------------
func GetRecoveryBasedOnSide(side : AtackSide) -> CharacterState:
	match(side):
		AtackSide.LEFT:
			return CharacterState.RECOVERING_HIT_LEFT
		AtackSide.RIGHT:
			return CharacterState.RECOVERING_HIT_RIGHT
		AtackSide.MIDDLE:
			return CharacterState.RECOVERING_HIT_MIDDLE
		AtackSide.TOP:
			return CharacterState.RECOVERING_HIT_TOP
		AtackSide.LOW:
			return CharacterState.RECOVERING_HIT_LOW
		_:
			return CharacterState.RECOVERING_HIT_LEFT
#----------------------------------------------------
func GetChargeRecoveryBasedOnSide(side : AtackSide) -> CharacterState:
	match(side):
		AtackSide.LEFT:
			return CharacterState.RECOVERING_LEFT
		AtackSide.RIGHT:
			return CharacterState.RECOVERING_RIGHT
		AtackSide.MIDDLE:
			return CharacterState.RECOVERING_MIDDLE
		AtackSide.TOP:
			return CharacterState.RECOVERING_TOP
		AtackSide.LOW:
			return CharacterState.RECOVERING_LOW
		_:
			return CharacterState.RECOVERING_LEFT
#----------------------------------------------------
func GetStateBasedOnAnim(AnimationName : String) -> CharacterState:
	match (AnimationName):
		"Atack_Left":
			return CharacterState.RECOVERING_HIT_LEFT
		"Atack_Right":
			return CharacterState.RECOVERING_HIT_RIGHT
		"Atack_Middle":
			return CharacterState.RECOVERING_HIT_MIDDLE
		"Atack_Top":
			return CharacterState.RECOVERING_HIT_TOP
		"Atack_Low":
			return CharacterState.RECOVERING_HIT_LOW
		"Atack_Bow":
			return CharacterState.RECOVERING_MIDDLE
		"2H_Atack_Left":
			return CharacterState.RECOVERING_LEFT
		"2H_Atack_Right":
			return CharacterState.RECOVERING_RIGHT
		"2H_Atack_Middle":
			return CharacterState.RECOVERING_MIDDLE
		"2H_Atack_Top":
			return CharacterState.RECOVERING_TOP
		"2H_Atack_Low":
			return CharacterState.RECOVERING_LOW
		"Hit_Left_Retaliation":
			return CharacterState.RECOIL_LEFT_RETALIATION
		"Hit_Right_Retaliation":
			return CharacterState.RECOIL_RIGHT_RETALIATION
		"Hit_Mid_Retaliation":
			return CharacterState.RECOIL_MID_RETALIATION
	return CharacterState.IDLE
#----------------------------------------------------
func IsStunned() -> bool:
	return ControllingCharacter.IsStunned()
#----------------------------------------------------
func IsRecovering() -> bool:
	return CurrentState in [CharacterState.RECOVERING_LEFT, CharacterState.RECOVERING_RIGHT, CharacterState.RECOVERING_LOW, CharacterState.RECOVERING_MIDDLE, CharacterState.RECOVERING_TOP]
#----------------------------------------------------
func IsAttacking() -> bool:
	return CurrentState in [CharacterState.HITTING_LEFT, CharacterState.HITTING_RIGHT, CharacterState.HITTING_MIDDLE, CharacterState.HITTING_LOW, CharacterState.HITTING_TOP]

func IsRetaliating() -> bool:
	return CurrentState in [CharacterState.RECOIL_LEFT_RETALIATION, CharacterState.RECOIL_RIGHT_RETALIATION, CharacterState.RECOIL_MID_RETALIATION]
#----------------------------------------------------
func IsCharging() -> bool:
	return CurrentState in [CharacterState.CHARGING, CharacterState.CHARGING_LEFT, CharacterState.CHARGING_TOP, CharacterState.CHARGING_LOW, CharacterState.CHARGING_MIDDLE, CharacterState.CHARGINE_RIGHT]
#----------------------------------------------------
func IsCharged() -> bool:
	return CurrentState  in [CharacterState.CHARGED_RIGHT, CharacterState.CHARGED_LEFT, CharacterState.CHARGED_LOW, CharacterState.CHARGED_MIDDLE, CharacterState.CHARGED_TOP]
#----------------------------------------------------
func IsDucking() -> bool:
	return CurrentState in [CharacterState.DUCKING_LEFT, CharacterState.DUCKING_RIGHT]

func IsDuckingDirCorrect(atack : AtackSide) -> bool:
	match atack:
		AtackSide.LEFT:
			return CurrentState == CharacterState.DUCKING_RIGHT
		AtackSide.RIGHT:
			return CurrentState == CharacterState.DUCKING_LEFT
	#All other attacks just require player to be ducked so we just return that
	return IsDucking()

func GetRecoil(Dir : AtackSide) -> Vector3:
	match Dir:
		AtackSide.LEFT:
			return Vector3(0,1,-1)

		AtackSide.RIGHT:
			return Vector3(0,-1,1)
			
		AtackSide.TOP:
			return Vector3(1,0,0)
			
		AtackSide.MIDDLE:
			return Vector3(-1,0,0)
			
		AtackSide.LOW:
			return Vector3(-1,0,0)
			
	return Vector3.ZERO


func IsBlocking() -> bool:
	return CurrentState in [CharacterState.PARRY]
#----------------------------------------------------
func IsRecoiling() -> bool:
	return CurrentState in [CharacterState.RECOIL_LEFT, CharacterState.RECOIL_RIGHT, CharacterState.RECOIL_MID]
#----------------------------------------------------
func Shout() -> void:
	pass
	#AudioManager.Instance.PlaySound(AudioManager.Sound.SHOUT_HUMAN, -5, 0.2)
