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
var Taunting : bool
#var DualHanded : bool
#var SecondHandCurrentState : CharacterState = CharacterState.IDLE

var FlowUp : bool = false
var FlowPos : float

signal DeathAnimFin

var monsterR : RandomNumberGenerator


var ParryReleased : bool = false

func _ready() -> void:
	super()
	monsterR = RandomNumberGenerator.new()
	var pl : Player = Target
	LookAtNode.target_node = LookAtNode.get_path_to(pl.Cam)
	

func SetControllingChar(Char : Actor) -> void:
	ControllingCharacter = Char
	CancelHits()
	var Group = Char as MonsterGroup
	#DualHanded = Group.Mon.DualHand
	MedianDecisionCooldown = Group.Mon.GetDecisionCooldown()
	Char.Exposed.connect(Exposed)
	Char.SpeedBuffed.connect(SpeedChanged)

	for DecoType : String in Decorations.keys():
		Decorations[DecoType].clear()
			
	BodyModels.clear()
	
	Visuals = load(Group.Mon.Visuals).instantiate()
	sk.add_child(Visuals)
	for g : MeshInstance3D in Visuals.get_children():
		g.skeleton = g.get_path_to(sk)
		
		if (g.name.contains("Deco")):
			Decorations[g.name.substr(0, 2)].append(g)
		else: if g.name.contains("B_"):
			BodyModels.append(g)
	
	for g in BodyModels:
		g.set_surface_override_material(0, Group.PickedMat)
		g.set_instance_shader_parameter("variant_index", Group.variant_index)
	
	#Visuals.BindMesh(sk)
	
	UpdateState(CharacterState.IDLE)
	Dead = false
	Blocking = false
	Parrying = false
	StartingParry = false
	
	for DecoType : String in Decorations.keys():
		for g in Decorations[DecoType].size():
			var deco : MeshInstance3D = Decorations[DecoType][g]
			deco.visible = Group.PickedDecorations[DecoType] == g

func GetCharacterActions() -> Callable:
	var ActionList : Array[Callable] = []
	var ActionWeights : PackedFloat32Array = []
	
	var goodWeight : float = ControllingCharacter.Mon.GetGoodActionWeight()
	var badWeight : float = ControllingCharacter.Mon.GetGoodActionWeight()
	
	if (IsRecoiling() or IsRetaliating()):
		return DoNothing
	
	
	if (IsAttacking()):
		return DoNothing
		#ActionList.append(DoNothing)
		#ActionWeights.append(badWeight)
		
	if (Target.IsCharged() or Target.CurrentState in [CharacterState.HITTING_LEFT, CharacterState.HITTING_MIDDLE, CharacterState.HITTING_RIGHT]):
		if (Parrying or StartingParry or Blocking or IsDuckingCorrectly()):
			ActionList.append(DoNothing)
			ActionWeights.append(goodWeight)
		else:
			ActionList.append(Duck.bind(GetDuckDirectionBasedOnState(Target.CurrentState)))
			ActionWeights.append(goodWeight)
			ActionList.append(Parry)
			ActionWeights.append(goodWeight)
	
	
	#else: if (!IsCharging() and HasStaminaForHit()):
	else: if (!IsCharging()):
	#else: if (!IsCharging()):
		#if (IsCharged()):
			#ActionList.append(CancelHits)
			#ActionWeights.append(1.0)
		match (CurrentState):
			CharacterState.CHARGED_LEFT:
				if (Target.CurrentState == CharacterState.DUCKING_RIGHT):
					ActionList.append(CancelHits)
					ActionWeights.append(0.3)
					ActionList.append(Hit.bind(AtackSide.LEFT))
					ActionWeights.append(0.1)
				else:
					ActionList.append(CancelHits)
					ActionWeights.append(0.1)
					ActionList.append(Hit.bind(AtackSide.LEFT))
					ActionWeights.append(0.3)
					if (Target.IsStunned() or Target.IsRecovering()):
						ActionList.append(Hit.bind(AtackSide.LEFT))
						ActionWeights.append(goodWeight)
			
			CharacterState.CHARGED_TOP:
				if (Target.IsDucking()):
					ActionList.append(CancelHits)
					ActionWeights.append(0.3)
					ActionList.append(Hit.bind(AtackSide.TOP))
					ActionWeights.append(0.1)
				else:
					ActionList.append(CancelHits)
					ActionWeights.append(0.1)
					ActionList.append(Hit.bind(AtackSide.TOP))
					ActionWeights.append(0.3)
					if (Target.IsStunned() or Target.IsRecovering()):
						ActionList.append(Hit.bind(AtackSide.TOP))
						ActionWeights.append(goodWeight)
			
			CharacterState.CHARGED_RIGHT:
				if (Target.CurrentState == CharacterState.DUCKING_LEFT):
					ActionList.append(CancelHits)
					ActionWeights.append(0.3)
					ActionList.append(Hit.bind(AtackSide.RIGHT))
					ActionWeights.append(0.1)
				else:
					ActionList.append(CancelHits)
					ActionWeights.append(0.1)
					ActionList.append(Hit.bind(AtackSide.RIGHT))
					ActionWeights.append(0.3)
					if (Target.IsStunned() or Target.IsRecovering()):
						ActionList.append(Hit.bind(AtackSide.RIGHT))
						ActionWeights.append(goodWeight)
						
			CharacterState.CHARGED_MIDDLE:
				if (Target.IsDucking()):
					ActionList.append(CancelHits)
					ActionWeights.append(0.3)
					ActionList.append(Hit.bind(AtackSide.MIDDLE))
					ActionWeights.append(0.1)
				else:
					ActionList.append(CancelHits)
					ActionWeights.append(0.1)
					ActionList.append(Hit.bind(AtackSide.MIDDLE))
					ActionWeights.append(0.3)
					if (Target.IsStunned() or Target.IsRecovering()):
						ActionList.append(Hit.bind(AtackSide.MIDDLE))
						ActionWeights.append(goodWeight)
						
			CharacterState.CHARGED_LOW:
				if (Target.IsDucking()):
					ActionList.append(CancelHits)
					ActionWeights.append(0.3)
					ActionList.append(Hit.bind(AtackSide.LOW))
					ActionWeights.append(0.1)
				else:
					ActionList.append(CancelHits)
					ActionWeights.append(0.1)
					ActionList.append(Hit.bind(AtackSide.LOW))
					ActionWeights.append(0.3)
					if (Target.IsStunned() or Target.Blocking or Target.IsRecovering()):
						ActionList.append(Hit.bind(AtackSide.LOW))
						ActionWeights.append(goodWeight)
			CharacterState.DUCKING_LEFT:
				if (!IsDuckingCorrectly()):
					ActionList.append(UnDuck.bind(AtackSide.LEFT))
					ActionWeights.append(goodWeight)
					
			CharacterState.DUCKING_RIGHT:
				if (!IsDuckingCorrectly()):
					ActionList.append(UnDuck.bind(AtackSide.RIGHT))
					ActionWeights.append(goodWeight)
			CharacterState.PARRY:
				ActionList.append(StopParry)
				ActionWeights.append(goodWeight)
			_:
				var direction = PickAtackDirection()
				ActionList.append(ChargeHit.bind(direction))
				ActionWeights.append(0.1)
				if (Target.IsStunned() or Target.IsRecovering()):
					ActionList.append(ChargeHit.bind(direction))
					ActionWeights.append(goodWeight)
					
	else:
		match (CurrentState):
			CharacterState.DUCKING_LEFT:
				if (!IsDuckingCorrectly()):
					ActionList.append(UnDuck.bind(AtackSide.LEFT))
					ActionWeights.append(goodWeight)
					
			CharacterState.DUCKING_RIGHT:
				if (!IsDuckingCorrectly()):
					ActionList.append(UnDuck.bind(AtackSide.RIGHT))
					ActionWeights.append(goodWeight)
			CharacterState.PARRY:
				ActionList.append(StopParry)
				ActionWeights.append(goodWeight)
			

	if (ActionList.size() == 0):
		
		ActionList.append(DoNothing)
		ActionWeights.append(1)
		#if (CurrentState == CharacterState.IDLE):
			#ActionList.append(Taunt)
			#ActionWeights.append(1)
		#return DoNothing
	
	return ActionList[monsterR.rand_weighted(ActionWeights)]
	
func IsDuckingCorrectly() -> bool:
	var CorrectDuck : Array[CharacterState]
	match (Target.CurrentState):
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
			
	return CurrentState in CorrectDuck


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

func PickAtackDirection() -> AtackSide:
	var AvailableAtackDirections : Array
	if (ControllingCharacter.Mon.Dificulty <= Monster.MonsterDifficulty.C):
		if (Target.CurrentState == CharacterState.DUCKING_RIGHT):
			print("Monster atacking from right to counter ducking")
			return AtackSide.RIGHT
		else : if (Target.CurrentState == CharacterState.DUCKING_LEFT):
			print("Monster atacking from left to counter ducking")
			return AtackSide.LEFT
		else : if (Target.CurrentState == CharacterState.PARRY):
			print("Monster kicking to counter blocking")
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
	

func AnimTreeFinished(anim_name: StringName) -> void:
	super(anim_name)
	if (anim_name == "Death"):
		DeathFinished()

	if (anim_name == "Taunt"):
		Taunting = false

func UpdateAnims(delta : float) -> void:
	super(delta)
	if (Dead):
		LookAtNode.influence = max(0, LookAtNode.influence - (delta * 8))
	if (IsRecoiling()):
		LookAtNode.influence = max(0.5, LookAtNode.influence - (delta * 8))
	else:
		LookAtNode.influence = min(1, LookAtNode.influence + (delta))

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
	print("Enemy performs action {0}".format([Action]))
	Action.call()

func GetFightName() -> String:
	return "Enemy"

func DoNothing() -> void:
	pass

func Taunt() -> void:
	pass
	#Taunting = true
	#AnimTree.set("parameters/TauntShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func CancelTaunt() -> void:
	pass 
	#Taunting = false
	#AnimTree.set("parameters/TauntShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)

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

func Defeated() -> void:
	Dead = true
	CancelHits()
	UpdateState(FightCharacter.CharacterState.DEATH)
	UpdateSkeletonState()
	
func DeathFinished() -> void:
	
	queue_free()
	DeathAnimFin.emit()

func ClearVisuals() -> void:
	ControllingCharacter.Exposed.disconnect(Exposed)
	ControllingCharacter.SpeedBuffed.disconnect(SpeedChanged)
	Visuals.queue_free()
	for WeaponScene in WeaponScenes:
		WeaponScene.queue_free()
	WeaponScenes.clear()
