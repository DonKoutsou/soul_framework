# Player.gd (character body with camera as child)
@tool
extends FightCharacter

class_name Player

@export_group("Nodes")
@export var Lantern : MeshInstance3D
@export var Cam : PlayerCamera
@export var LeftHandLocator : TwoBoneIK3D
@export var LeftHandTrans : CopyTransformModifier3D
@export var RightHandLocator : TwoBoneIK3D
@export var LookMOdif : LookAtModifier3D
@export var FlowPivot : Node3D
@export var LanternL : LanternLight
@export var LLight : OmniLight3D
@export var LanternLightMesh : MeshInstance3D
@export var CameraAttachment : BoneAttachment3D

@export var RewardLocation : Node3D

var RotTween : Tween
var LookTween : Tween
var LanternTween : Tween
var FightTw : Tween
var WalkTween : Tween
var LanternHandTween : Tween

var RotVelocity : Vector3
var PulledWeapon : bool = false
var InFight : bool = false
var Digging : bool = false

static var HeadBob : bool = true

signal DigComplete
	
func _ready() -> void:
	##WeaponShape.position = Vector3(0,0.306, -1)
	super()
	UpdateState(CharacterState.IDLE)
	call_deferred("PullOutLantern")
	#UpdateState(CharacterState.IDLE_LANTERN)
	ToggleCameraMovement(HeadBob)
	#ToggleWalk(true)

func SetControllingChar(Char : Actor) -> void:
	Char.Exposed.connect(Exposed)
	Char.SpeedBuffed.connect(SpeedChanged)
	
	var c : Character = Char
	
	var Visuals = load(c.Visuals).instantiate()
	sk.add_child(Visuals)
	for g : MeshInstance3D in Visuals.get_children():
		g.skeleton = g.get_path_to(sk)

func SetRightHandLocator(t : float) -> void:
	if (LanternHandTween != null and LanternHandTween.is_valid()):
		LanternHandTween.kill()
	LanternHandTween = create_tween()
	LanternHandTween.set_ease(Tween.EASE_OUT)
	LanternHandTween.set_trans(Tween.TRANS_BACK)
	LanternHandTween.tween_property(RightHandLocator, "influence", t, 1.0)
	LanternHandTween.pause()



func ToggleCameraMovement(t : bool) -> void:
	for g in Anim.get_animation_list():
		var anim = Anim.get_animation(g)
		if (anim.resource_name.contains("Duck") or anim.resource_name.contains("Dig") or anim.resource_name.contains("Stun")):
			continue
		for trackId in anim.get_track_count():
			var bone_name : String = anim.track_get_path(trackId)
			bone_name = bone_name.replace("%{0}:".format([sk.name]), "")
			if (bone_name == "CameraBone"):
				anim.track_set_enabled(trackId, t)
			
	#CameraAttachment.override_pose = !t
	if (!t):
		CameraAttachment.position = Vector3(0, 0.76, 0)

func EquipWeapon(W : Weapon, Notify : bool = true) -> void:
	if (CurrentWeapon != null):
		CurrentWeapon.WeaponEquiped(false)
		
	super(W, Notify)
	
	#UpdateState(CharacterState.IDLE_LANTERN)
	#state_machine.travel("IdleLantern")
	#UpdateState(CharacterState.IDLE_LANTERN)
	W.WeaponEquiped(true)
	
func SeathSound(t : bool) -> void:
	if (t):
		AudioManager.Instance.PlaySound(AudioManager.Sound.SEATH_IN, -2, 0.1, 1, true)
	else:
		AudioManager.Instance.PlaySound(AudioManager.Sound.SEATH_OUT, -2, 0.1, 1, true)
	
var d = 0.2

func AnimateWeapon(AnimName : String) -> void:
	for WeaponScene in WeaponScenes:
		if (WeaponScene is AnimatedFightWeapon):
			WeaponScene.AnimateWeapon(AnimName)

func Update(delta: float) -> void:
	#Cam.Update(delta)
	#Cam.Update(delta)
	LanternL.Update(delta)
	super(delta)
	
	if (DuckCoolDown <= 0 and IsDucking() and !Input.is_action_pressed("DuckLeft") and !Input.is_action_pressed("DuckRight")):
		UnDuck(GetAtackBasedOnState())
	
	if (ParryCooldDown <= 0 and IsBlocking() and !Input.is_action_pressed("AtackRight")):
		StopParry()
	
	if (is_instance_valid(RotTween) and RotTween.is_valid()):
		if (!RotTween.custom_step(delta)):
			RotTween.kill()
	if (is_instance_valid(LanternTween) and LanternTween.is_valid()):
		if (!LanternTween.custom_step(delta)):
			LanternTween.kill()
	if (is_instance_valid(FightTw) and FightTw.is_valid()):
		if (!FightTw.custom_step(delta)):
			FightTw.kill()
	if (is_instance_valid(WalkTween) and WalkTween.is_valid()):
		if (!WalkTween.custom_step(delta)):
			WalkTween.kill()
	if (is_instance_valid(LookTween) and LookTween.is_valid()):
		if (!LookTween.custom_step(delta)):
			LookTween.kill()
	if (is_instance_valid(LanternHandTween) and LanternHandTween.is_valid()):
		if (!LanternHandTween.custom_step(delta)):
			LanternHandTween.kill()
			
	if (ControllingCharacter.Exposure > 0):
		ControllingCharacter.Exposure -= delta / 2
		if (ControllingCharacter.Exposure <= 0):
			ControllingCharacter.HealFatigue(9999999)
			UpdateState(CharacterState.IDLE)
			#SetStun(0.0)
		return

	#PlayerCamera.UpdateBreath(delta)
	for WeaponScene in WeaponScenes:
		WeaponScene.ToggleDamageBuff(ControllingCharacter.DamageBuff > 0)
		WeaponScene.ToggleSeedBuff(ControllingCharacter.SpeedBuff > 0)

	d -= delta
	
	if (d <= 0):
		d = 3
		CheckIfOutOfCombat()

func Recoil(Dir : AtackSide = AtackSide.MIDDLE, HitConnected : bool = false, Magnitude : float = 0) -> void:
	super(Dir, HitConnected, Magnitude)
	AudioManager.Instance.PlaySound(AudioManager.Sound.PAIN_HUMAN, -5, 0.2, 1, true, "Voice")
	
#func OnAtackPerformed(Direction : AtackSide) -> void:
	#AudioManager.Instance.PlaySound(AudioManager.Sound.SHOUT_HUMAN, -5, 0.2, 1, true, "Voice")
	#super(Direction)

func Shout() -> void:
	return
	#AudioManager.Instance.PlaySound(AudioManager.Sound.SHOUT_HUMAN, -5, 0.2, 1, true, "Voice")

func Damage(DamageAmm : int, Direction : AtackSide, ShakeAmm : float, AtackWeight : float) -> int:
	var finalDamage = super(DamageAmm, Direction, ShakeAmm, AtackWeight)
	if (finalDamage == DamageAmm):
		AudioManager.Instance.PlaySound(AudioManager.Sound.PAIN_HUMAN, -5, 0.2, 1, true, "Voice")
	return finalDamage

func UpdateLanternLight(LightAmm : float) -> void:
	LanternLightMesh.scale = Vector3(LightAmm * 1.6, 1, LightAmm * 1.6)
	LanternL.CurrentLightAmm = LightAmm
	#LLight.light_energy = LightAmm * 0.09
	#DirLight.light_energy = LightAmm
	#if (FightTw != null):
	
func GetReadyForFight() -> void:
	d = 3
	SetFightStance(true)
	SetRightHandLocator(0)
	LeftHandLocator.influence = 0.0
	LeftHandTrans.influence = 0.0
	if (CurrentWeapon.WeaponType == Fight_Animation_Modifier.WeaponType.BOW):
		SetLookModif(1)
	else:
		SetLookModif(0)
	#WeaponScene.show()
	Lantern.hide()
	PulledWeapon = true


func LeftFight() -> void:
	InFight = false
	#get_tree().create_timer(1).timeout.connect(CheckIfOutOfCombat)


func PullOutLantern() -> void:
	SetFightStance(false)
	SetRightHandLocator(0.4)
	SetLookModif(0.5)
	Lantern.show()
	#WeaponScene.hide()


func CheckIfOutOfCombat() -> void:
	if (!InFight and CurrentState == CharacterState.IDLE):
		if (PulledWeapon):
			PullOutLantern()
			PulledWeapon = false

func Kill() -> void:
	CancelHits()
	StopParry(true)
	#BreathAudio.playing = false


func Rotated(Dir : Vector3) -> void:
	#RotVelocity += Dir
	if (is_instance_valid(RotTween)):
		RotTween.kill()
	
	RotTween = create_tween()
	RotTween.set_ease(Tween.EASE_OUT)
	RotTween.set_trans(Tween.TRANS_BACK)
	RotTween.tween_property(FlowPivot, "rotation", Vector3(-Dir.z* 5, Dir.y, Dir.x * 4), 0.5)
	RotTween.pause()
	
	if (-Dir.z > 0.01 or Dir.z > 0.01):
		var LanternDir = Vector3(-Dir.x, -Dir.y, -Dir.z * 8)
		if (is_instance_valid(LanternTween)):
			LanternTween.kill()
	
		LanternTween = create_tween()
		LanternTween.set_ease(Tween.EASE_OUT)
		LanternTween.set_trans(Tween.TRANS_SINE)
		LanternTween.tween_property(Lantern, "rotation", LanternDir, 0.55)
		LanternTween.finished.connect(ResetLanternFlow)
		LanternTween.pause()

	RotTween.finished.connect(ResetFlow)


func ResetFlow() -> void:
	if (is_instance_valid(RotTween)):
		RotTween.kill()

	RotTween = create_tween()
	RotTween.set_ease(Tween.EASE_OUT)
	RotTween.set_trans(Tween.TRANS_ELASTIC)
	RotTween.tween_property(FlowPivot, "rotation", Vector3.ZERO, 2)
	RotTween.pause()

func ResetLanternFlow() -> void:
	if (is_instance_valid(LanternTween)):
		LanternTween.kill()
	
	LanternTween = create_tween()
	LanternTween.set_ease(Tween.EASE_OUT)
	LanternTween.set_trans(Tween.TRANS_ELASTIC)
	LanternTween.tween_property(Lantern, "rotation", Vector3.ZERO, 3)
	LanternTween.pause()

func ProcessInput(event: InputEvent) -> void:
	if (ControllingCharacter.Exposure > 0):
		return
	if (IsRecoiling()):
		return
	if (event.is_action_released("AtackRight")):
		if (CurrentState == CharacterState.PARRY):
			StopParry()
			
	
	
	#Different Behavior if in fight or out since we can still use weapon outside of combat
	if (InFight):
		if (event.is_action_pressed("DuckLeft")):
			Duck(AtackSide.LEFT)

		if (event.is_action_pressed("DuckRight")):
			Duck(AtackSide.RIGHT)
		
		if (event.is_action_released("DuckLeft")):
			UnDuck(AtackSide.LEFT)

		if (event.is_action_released("DuckRight")):
			UnDuck(AtackSide.RIGHT)
			
		if (event.is_action_pressed("AtackLeft")):
			if (!HasStaminaForHit()):
				MessageBox.RegisterEvent("Not enough stamina", true, true)
				return
			var AvailableAtackDirections : Array
			if (ComboWindowOpen):
				match (CurrentState):
					CharacterState.RECOVERING_LEFT:
						AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.MIDDLE]
					CharacterState.RECOVERING_RIGHT:
						AvailableAtackDirections = [AtackSide.LEFT, AtackSide.TOP]
					CharacterState.RECOVERING_TOP:
						AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.LEFT]
					_:
						AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.LEFT, AtackSide.TOP]
			else:
				AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.LEFT, AtackSide.TOP]
			if (CurrentWeapon.WeaponType == Fight_Animation_Modifier.WeaponType.BOW):
				ChargeHit(AtackSide.MIDDLE)
			else:
				#var r = randi_range(0, AvailableAtackDirections.size() - 1)
				ChargeHit(AvailableAtackDirections.pick_random())
		
		if (event.is_action_pressed("Kick") ):
			if (!HasStaminaForHit()):
				MessageBox.RegisterEvent("Not enough stamina", true, true)
				return
			ChargeHit(AtackSide.LOW)
		
		if (event.is_action_released("AtackLeft")):
			Hit(GetAtackBasedOnState())
					
		if (event.is_action_released("Kick")):
			Hit(AtackSide.LOW)
			
		if (event.is_action_pressed("AtackRight")):
			Parry()
			
	else:
		if (event.is_action_pressed("Kick")):
			if (!HasStaminaForHit()):
				MessageBox.RegisterEvent("Not enough stamina", true, true)
				return
			if (!PulledWeapon):
				GetReadyForFight()
				return
			
			ChargeHit(AtackSide.LOW)
			
		if (event.is_action_pressed("AtackLeft")):
			if (!HasStaminaForHit()):
				MessageBox.RegisterEvent("Not enough stamina", true, true)
				return
			if (!PulledWeapon):
				GetReadyForFight()
				return
			if (ControllingCharacter.CharacterWeapon.Proj != null):
				if (!ControllingCharacter.CharacterWeapon.Proj.CanShoot()):
					return
					
			var AvailableAtackDirections : Array
			if (ComboWindowOpen):
				match (CurrentState):
					CharacterState.RECOVERING_HIT_LEFT:
						AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.TOP]
					CharacterState.RECOVERING_HIT_RIGHT:
						AvailableAtackDirections = [AtackSide.LEFT, AtackSide.TOP]
					CharacterState.RECOVERING_HIT_TOP:
						AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.LEFT]
			else:
				AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.LEFT, AtackSide.TOP]
			if (CurrentWeapon.WeaponType == Fight_Animation_Modifier.WeaponType.BOW):
				ChargeHit(AtackSide.MIDDLE)
			else:
				var r = randi_range(0, AvailableAtackDirections.size() - 1)
				ChargeHit(AvailableAtackDirections[r])
		
		if (event.is_action_released("Kick")):
			Hit(AtackSide.LOW)
		
		if (event.is_action_released("AtackLeft")):
			Hit(GetAtackBasedOnState())
		
		#if (event.is_action_pressed("AtackRight")):
			#if (!PulledWeapon):
				#GetReadyForFight()
				#return
			#Parry()



func ExtendHand(Return : bool = true) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CIRC)
	tw.tween_property(LeftHandLocator, "influence", 1.0, 0.25)
	tw.set_parallel(true)
	tw.tween_property(LeftHandTrans, "influence", 1.0, 0.25)

	if (!Return):
		return
	await tw.finished
	tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(LeftHandLocator, "influence", 0.0, 0.211)
	tw.set_parallel(true)
	tw.tween_property(LeftHandTrans, "influence", 0.0, 0.211)
	

func Grab() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CIRC)
	tw.tween_property(LeftHandLocator, "influence", 1.0, 0.25)
	tw.set_parallel(true)
	tw.tween_property(LeftHandTrans, "influence", 1.0, 0.25)

func ReturnHand() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(LeftHandLocator, "influence", 0.0, 0.211)
	tw.set_parallel(true)
	tw.tween_property(LeftHandTrans, "influence", 0.0, 0.211)

func ToggleWalk(t : bool) -> void:
	SkeletonModif.Walking = t
	
func SetLookModif(Value : float) -> void:
	if (is_instance_valid(LookTween)):
		LookTween.kill()
		
	LookTween = create_tween() 
	LookTween.set_ease(Tween.EASE_OUT)
	LookTween.set_trans(Tween.TRANS_BACK)
	LookTween.tween_property(LookMOdif, "influence", Value, 0.5)
	LookTween.pause()

func SetFightStance(t : bool) -> void:
	print("Setting fight stance {0}".format([t]))
	if (t == true):
		#state_machine.travel("Idle")
		UpdateState(CharacterState.IDLE)
	else:
		UpdateState(CharacterState.IDLE_LANTERN)
		#state_machine.travel("IdleLantern")

func GetFightName() -> String:
	return "Player"

func OnAttackCharged(dir : AtackSide) -> void:
	if (IsCharging()):
		UpdateState(GetChargeStateBasedOnSide(dir))
		AtackCharged.emit(dir)
		if (!Input.is_action_pressed("AtackLeft")):
			Hit(dir)

func AnimTreeFinished(anim_name: StringName) -> void:
	super(anim_name)
	if (anim_name == "Dig"):
		SetRightHandLocator(0.5)
		UpdateState(FightCharacter.CharacterState.IDLE_LANTERN)
		Digging = false
	
func Dig() -> void:
	Digging = true
	#AnimTree.set("parameters/DigShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	UpdateState(FightCharacter.CharacterState.DIG)
	SetRightHandLocator(0)
	LeftHandLocator.influence = 0.0
	LeftHandTrans.influence = 0.0
	Lantern.visible = false
	WeaponPlecement.visible = false

func WholeDug() -> void:
	AudioManager.Instance.PlaySound(AudioManager.Sound.DIG, 0, 0.2)
	DigComplete.emit()
	Lantern.visible = !PulledWeapon
	WeaponPlecement.visible = PulledWeapon
	
