@tool
extends FightCharacter

class_name Enemy

@export var LookAtNode : LookAtModifier3D
@export var HitParticles : GPUParticles3D
@export var Target: FightCharacter

var BodyModels : Array[MeshInstance3D]
var Decorations : Dictionary[String, Array] = {
	"RA" : [],
	"LS" : [],
	"RS" : [],
	"HE" : [],
	"CH" : [],
}

var DecisionCooldown : float = 0.2

var Visuals : Node3D

var MedianDecisionCooldown : float = 0
var Acting : bool

var FlowUp : bool = false
var FlowPos : float

signal DeathAnimFin

var monsterR : RandomNumberGenerator

##Array of arrays containing AtackSides
var ComboCatalogue : Array[Array]
##Current Combe being executed
var CurrentCombo : Array[AtackSide]

#------------------------------------------------------------------------------
func _ready() -> void:
	super()
	monsterR = RandomNumberGenerator.new()
	var pl : Player = Target
	LookAtNode.target_node = LookAtNode.get_path_to(pl.Cam)

#------------------------------------------------------------------------------
func SetControllingChar(Char : Actor) -> void:
	if (Char == null):
		Visuals.queue_free()
		sk.clear_bones()
		if (Engine.is_editor_hint()):
			sk.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
		return
	
	if (Engine.is_editor_hint()):
		sk.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_IDLE
	
	var Group = Char as MonsterGroup

	for DecoType : String in Decorations.keys():
		Decorations[DecoType].clear()
			
	BodyModels.clear()
	
	var skeletonScene : PackedScene = await Helper.Instance.LoadThreaded(Group.Mon.Skeleton).Finished
	var incommingSkel : Skeleton3D = skeletonScene.instantiate()

	CreateSkeleton(incommingSkel)
	incommingSkel.queue_free()
	
	if (Visuals != null):
		ClearVisuals()
	
	var visualScene : PackedScene = await Helper.Instance.LoadThreaded(Group.Mon.Visuals).Finished
	Visuals = visualScene.instantiate()
	ApplyVisuals(Visuals)
	
	for g in BodyModels:
		g.set_surface_override_material(0, Group.PickedMat)
		g.set_instance_shader_parameter("variant_index", Group.variant_index)
	
	MedianDecisionCooldown = Group.Mon.GetDecisionCooldown()
	UpdateState(CharacterState.IDLE)
	Dead = false
	Blocking = false
	Parrying = false
	StartingParry = false
	GenerateCombos()
	
	Char.Exposed.connect(Exposed)
	Char.SpeedBuffed.connect(SpeedChanged)
	
	for DecoType : String in Decorations.keys():
		for g in Decorations[DecoType].size():
			var deco : MeshInstance3D = Decorations[DecoType][g]
			deco.visible = Group.PickedDecorations[DecoType] == g
	
	
	ControllingCharacterSet.emit()

#------------------------------------------------------------------------------
#Apply bones from incomming skeleton to this scenes skeleton
func CreateSkeleton(incommingSkel : Skeleton3D) -> void:
	var hitPartAttachment : BoneAttachment = HitParticles.get_parent()
	sk.clear_bones()
	
	for boneIndex in incommingSkel.get_bone_count():
		sk.add_bone(incommingSkel.get_bone_name(boneIndex))
		
		var parentIndex = incommingSkel.get_bone_parent(boneIndex)
		if (parentIndex != -1):
			sk.set_bone_parent(boneIndex, parentIndex)
		
		sk.set_bone_global_pose(boneIndex, incommingSkel.get_bone_global_pose(boneIndex))
		
		if (sk.get_bone_name(boneIndex) == "Head"):
			hitPartAttachment.boneID = boneIndex

	
#----------------------------------------------------
func ApplyVisuals(viz : Node3D) -> void:
	sk.add_child(viz)
	for g : MeshInstance3D in viz.get_children():
		g.skeleton = g.get_path_to(sk)
		if (g.name.contains("Deco")):
			Decorations[g.name.substr(0, 2)].append(g)
		else: if g.name.contains("B_"):
			BodyModels.append(g)

		
#----------------------------------------------------------------------
func GenerateCombos() -> void:
	var availableAttacks = [AtackSide.TOP, AtackSide.LEFT, AtackSide.RIGHT, AtackSide.MIDDLE]
	#Make sure to keep the combo size within the characer's stamina range.
	var maxHitAmmount = floori(ControllingCharacter.GetMaxFatigue() / GetRequiredStaminaForHit())
	
	ComboCatalogue.clear()
	#create 3 combos of 3 hits
	for g in 3:
		var combo : Array[AtackSide]
		combo.append(availableAttacks.pick_random())
		
		for z in min(randi_range(1, 3), maxHitAmmount - 1):
			#we make sure that each combo is on different side cause animation system can't support same side attacks
			var pickedAttack = availableAttacks.pick_random()
			while combo[z] == pickedAttack:
				pickedAttack = availableAttacks.pick_random()
			combo.append(pickedAttack)
		
		ComboCatalogue.append(combo)
	PickNewCombo()

#----------------------------------------------------------------------
func PickNewCombo() -> void:
	CurrentCombo = ComboCatalogue.pick_random().duplicate()
	
#----------------------------------------------------------------------
#Force to pick new 
func CancelHits() -> void:
	super()
	CurrentCombo.clear()

#----------------------------------------------------------------------
#Decission making function
func GetCharacterActions() -> Callable:
	if (Engine.is_editor_hint()):
		return DoNothing
	
	if (IsRecoiling() or IsRetaliating() or IsAttacking()):
		return DoNothing
	
	var ActionList : Array[Callable] = []
	var ActionWeights : PackedFloat32Array = []
	
	#The Bigger the difficulty of the monster the bigger this weight is
	var goodWeight : float = ControllingCharacter.Mon.GetGoodActionWeight()
	#The lower the difficulty of the monster the bigger this weight is
	var badWeight : float = ControllingCharacter.Mon.GetGoodActionWeight()

	if (Target.IsCharged() or Target.CurrentState in [CharacterState.HITTING_LEFT, CharacterState.HITTING_MIDDLE, CharacterState.HITTING_RIGHT]):
		if (Parrying or StartingParry or Blocking or IsDuckingCorrectly(CurrentState ,Target.CurrentState)):
			ActionList.append(DoNothing)
			ActionWeights.append(goodWeight)
		else:
			ActionList.append(Duck.bind(GetDuckDirectionBasedOnState(Target.CurrentState)))
			ActionWeights.append(goodWeight)
			ActionList.append(Parry)
			ActionWeights.append(goodWeight)
	
	
	if (!IsCharging() and HasStaminaForHit()):
	#if (!IsCharging()):
	#else: if (!IsCharging()):
		#if (IsCharged()):
			#ActionList.append(CancelHits)
			#ActionWeights.append(1.0)
			
		if (IsCharged()):
			ActionList.append(DoNothing)
			ActionWeights.append(1 - ChargePower)
			
			var chargeDir = GetAtackBasedOnState()

			#If target is duccking properly
			if IsDuckingCorrectly(Target.CurrentState ,CurrentState):
				#Potential to cancel hit if player is ducking correctly
				ActionList.append(CancelHits)
				ActionWeights.append(goodWeight)
				#Potential for lower lever enemies to still perform "wrong" hits
				ActionList.append(Hit.bind(chargeDir))
				ActionWeights.append(badWeight)
			else:
				#Allwas a small chance to cancel hit for whifs
				ActionList.append(CancelHits)
				ActionWeights.append(0.1)
				ActionList.append(Hit.bind(chargeDir))
				ActionWeights.append(0.3)
				#Exrta potential to initiate a hit if player is stunned
				if (Target.IsStunned() or Target.IsRecovering()):
					ActionList.append(Hit.bind(chargeDir))
					ActionWeights.append(goodWeight)
		
		else: if (IsDucking()):
			if (!IsDuckingCorrectly(CurrentState ,Target.CurrentState)):
				var duckDir = GetAtackBasedOnState()
				ActionList.append(UnDuck.bind(duckDir))
				ActionWeights.append(goodWeight)
		
		else: if (IsParrying()):
				ActionList.append(StopParry)
				ActionWeights.append(goodWeight)
		
		else: if (IsRecoveringHit()):
			if (CurrentCombo.size() > 0):
				ChargePower = 0.2
				ActionList.append(Hit.bind(CurrentCombo[0]))
				ActionWeights.append(1.0)
		
		else: if (CurrentState == CharacterState.IDLE):
			var direction : AtackSide
			if (CurrentCombo.size() == 0):
				ActionList.append(PickNewCombo)
				ActionWeights.append(0.1)
				direction = PickAtackDirection()
			else:
				direction = CurrentCombo[0]

			ActionList.append(ChargeHit.bind(direction))
			ActionWeights.append(0.1)
			
			if (Target.IsStunned() or Target.IsRecovering()):
				ActionList.append(ChargeHit.bind(direction))
				ActionWeights.append(goodWeight)
					
	else:
		match (CurrentState):
			CharacterState.DUCKING_LEFT:
				if (!IsDuckingCorrectly(CurrentState ,Target.CurrentState)):
					ActionList.append(UnDuck.bind(AtackSide.LEFT))
					ActionWeights.append(goodWeight)
					
			CharacterState.DUCKING_RIGHT:
				if (!IsDuckingCorrectly(CurrentState ,Target.CurrentState)):
					ActionList.append(UnDuck.bind(AtackSide.RIGHT))
					ActionWeights.append(goodWeight)
			CharacterState.PARRY:
				ActionList.append(StopParry)
				ActionWeights.append(goodWeight)
			

	if (ActionList.size() == 0):
		ActionList.append(DoNothing)
		ActionWeights.append(1)
		if (CurrentState == CharacterState.IDLE):
			ActionList.append(Taunt)
			ActionWeights.append(1)
		#return DoNothing
		
	return ActionList[monsterR.rand_weighted(ActionWeights)]


#------------------------------------------------------------------------------
func Hit(Direction : AtackSide) -> void:
	if (CurrentCombo.find(Direction) == 0):
		CurrentCombo.pop_front()
	
	UpdateState(GetStateBasedOnSide(Direction))

	AtackStarted.emit(Direction)

#------------------------------------------------------------------------------
func IsDuckingCorrectly(deffenderState : CharacterState, AttackerState : CharacterState) -> bool:
	var CorrectDuck : Array[CharacterState]
	match (AttackerState):
		CharacterState.HITTING_LEFT:
			CorrectDuck.append(CharacterState.DUCKING_RIGHT)
		CharacterState.HITTING_RIGHT:
			CorrectDuck.append(CharacterState.DUCKING_LEFT)
		CharacterState.HITTING_MIDDLE:
			CorrectDuck.append(CharacterState.DUCKING_LEFT)
			CorrectDuck.append(CharacterState.DUCKING_RIGHT)
		CharacterState.HITTING_TOP:
			CorrectDuck.append(CharacterState.DUCKING_LEFT)
			CorrectDuck.append(CharacterState.DUCKING_RIGHT)
		CharacterState.CHARGED_LEFT:
			CorrectDuck.append(CharacterState.DUCKING_RIGHT)
		CharacterState.CHARGED_TOP:
			CorrectDuck.append(CharacterState.DUCKING_LEFT)
			CorrectDuck.append(CharacterState.DUCKING_RIGHT)
		CharacterState.CHARGED_MIDDLE:
			CorrectDuck.append(CharacterState.DUCKING_LEFT)
			CorrectDuck.append(CharacterState.DUCKING_RIGHT)
		CharacterState.CHARGED_RIGHT:
			CorrectDuck.append(CharacterState.DUCKING_LEFT)
			
	return deffenderState in CorrectDuck

#------------------------------------------------------------------------------
func GetDuckDirectionBasedOnState(State : CharacterState) -> AtackSide:
	match (State):
		CharacterState.HITTING_LEFT:
			return AtackSide.RIGHT
		CharacterState.HITTING_RIGHT:
			return AtackSide.LEFT
		CharacterState.HITTING_MIDDLE:
			return [AtackSide.LEFT, AtackSide.RIGHT].pick_random()
		CharacterState.HITTING_TOP:
			return [AtackSide.LEFT, AtackSide.RIGHT].pick_random()
		CharacterState.CHARGED_LEFT:
			return AtackSide.RIGHT
		CharacterState.CHARGED_MIDDLE:
			return [AtackSide.LEFT, AtackSide.RIGHT].pick_random()
		CharacterState.CHARGED_TOP:
			return [AtackSide.LEFT, AtackSide.RIGHT].pick_random()
		CharacterState.CHARGED_RIGHT:
			return AtackSide.LEFT
		_:
			return AtackSide.MIDDLE

#------------------------------------------------------------------------------
func PickAtackDirection() -> AtackSide:
	var AvailableAtackDirections : Array
	if (ControllingCharacter.Mon.Dificulty <= Monster.MonsterDifficulty.C):
		if (Target.CurrentState == CharacterState.DUCKING_RIGHT):
			#print("Monster atacking from right to counter ducking")
			return AtackSide.RIGHT
		else : if (Target.CurrentState == CharacterState.DUCKING_LEFT):
			#print("Monster atacking from left to counter ducking")
			return AtackSide.LEFT
		else : if (Target.CurrentState == CharacterState.PARRY):
			#print("Monster kicking to counter blocking")
			return AtackSide.LOW
		else:
			AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.LEFT, AtackSide.TOP]
			if (CurrentWeapon.Pierce):
				AvailableAtackDirections.append(AtackSide.MIDDLE)
	else:
		AvailableAtackDirections = [AtackSide.RIGHT, AtackSide.LEFT, AtackSide.TOP]
		if (CurrentWeapon.Pierce):
				AvailableAtackDirections.append(AtackSide.MIDDLE)
		
	return AvailableAtackDirections.pick_random()
	
#------------------------------------------------------------------------------
func AnimTreeFinished(anim_name: StringName) -> void:
	super(anim_name)
	if (anim_name == "Death"):
		DeathFinished()

	if (anim_name == "Taunt" and IsTaunting()):
		UpdateState(CharacterState.IDLE)

#------------------------------------------------------------------------------
func UpdateAnims(delta : float) -> void:
	super(delta)
	if (Dead):
		LookAtNode.influence = max(0, LookAtNode.influence - (delta * 8))
	if (IsRecoiling()):
		LookAtNode.influence = max(0.5, LookAtNode.influence - (delta * 8))
	else:
		LookAtNode.influence = min(1, LookAtNode.influence + (delta))

#------------------------------------------------------------------------------
func Update(delta: float) -> void:
	if (Dead):
		return
	super(delta)

	for WeaponScene in WeaponScenes:
		WeaponScene.ToggleDamageBuff(ControllingCharacter.DamageBuff > 0 )
		WeaponScene.ToggleSeedBuff(ControllingCharacter.SpeedBuff > 0)
	#----------------------------
	#Handling of stun
	
	if (ControllingCharacter.Exposure > 0):
		ControllingCharacter.Exposure = max(0, ControllingCharacter.Exposure- delta / 2)
		if (ControllingCharacter.Exposure == 0):
			ControllingCharacter.HealFatigue(9999999)
			UpdateState(CharacterState.IDLE)
			#SetStun(0.0)
		return
	
	if (CurrentState == CharacterState.REPOSTE):
		return
	#----------------------------
	
	DecisionCooldown -= delta
	if (DecisionCooldown > 0):
		return
	DecisionCooldown = randf_range(MedianDecisionCooldown - 0.1, MedianDecisionCooldown + 0.1)
	
	#Collect actions and choose what to perform
	
	var Action = GetCharacterActions()
	#print("Enemy performs action {0}".format([Action]))
	Action.call()

#-------------------------------------------------------------------
func GetFightName() -> String:
	return "Enemy"

#------------------------------------------------------------------------------
func HasStaminaForHit() -> bool:
	if (CurrentCombo.size() > 0):
		return ControllingCharacter.GetMaxFatigue() - ControllingCharacter.Fatigue > GetRequiredStaminaForHit() * CurrentCombo.size()
	return ControllingCharacter.GetMaxFatigue() - ControllingCharacter.Fatigue > GetRequiredStaminaForHit()

#-------------------------------------------------------------------
#Dummy function called when we want enemy to keep doing what they are doing
func DoNothing() -> void:
	pass

#-------------------------------------------------------------------
func Taunt() -> void:
	UpdateState(CharacterState.TAUNT)
	#AnimTree.set("parameters/TauntShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

#-------------------------------------------------------------------
func CancelTaunt() -> void:
	pass 
	#Taunting = false
	#AnimTree.set("parameters/TauntShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)

#-------------------------------------------------------------------
func Damage(DamageAmm : int, Direction : AtackSide, ShakeAmm : float, AtackWeight : float) -> int:
	var finalDamage = super(DamageAmm, Direction, ShakeAmm, AtackWeight)
	if (finalDamage == DamageAmm):
		var mat = HitParticles.process_material as ParticleProcessMaterial
		if (Direction == AtackSide.LEFT):
			mat.direction = Vector3(1,0,0)
		if (Direction == AtackSide.RIGHT):
			mat.direction = Vector3(-1,0,0)
		if (Direction in [AtackSide.TOP]):
			mat.direction = Vector3(0, -0.5, 0.5)
		if (Direction in [AtackSide.MIDDLE ,AtackSide.LOW]):
			mat.direction = Vector3(0,0.5,-0.5)
		HitParticles.restart()
		HitParticles.emitting = true
	
	return finalDamage

#-------------------------------------------------------------------
#Used to initiate retaliation from enemy, Retaliate is set in the Recoil function
func RecoilFinished() -> void:
	if (IsRecoiling()):
		if (Retaliate):
			ChargePower = 0.2
			Hit(GetAtackBasedOnState())
		else:
			UpdateState(CharacterState.IDLE)

#------------------------------------------------------------------------------
func Defeated() -> void:
	Dead = true
	CancelHits()
	UpdateState(FightCharacter.CharacterState.DEATH)
	UpdateSkeletonState()

#------------------------------------------------------------------------------
func DeathFinished() -> void:
	
	queue_free()
	DeathAnimFin.emit()

#------------------------------------------------------------------------------
func ClearVisuals() -> void:
	ControllingCharacter.Exposed.disconnect(Exposed)
	ControllingCharacter.SpeedBuffed.disconnect(SpeedChanged)
	Visuals.queue_free()
	for WeaponScene in WeaponScenes:
		WeaponScene.queue_free()
	WeaponScenes.clear()
