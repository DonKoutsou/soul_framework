@tool
extends Node3D

class_name EnemyManequin

#The representation of enemies on the map

#----------------------------------------------------------------

@export var Cast : RayCast3D
@export var PlayerCast : RayCast3D
@export var WeaponPlacementL : Node3D
@export var WeaponPlacementR : Node3D
@export var Area : Area3D
@export var Sound : AudioStreamPlayer3D
@export var Scream : AudioStreamPlayer3D
@export var AnimModifier : Fight_Animation_Modifier
@export var Skel : Skeleton3D
@export var AlarmStateLabel : Label3D
@export var HeadRotationPivot : Node3D
@export var G : MonsterGroup:
	set(value):
		G = value
		RegisterCharacter(G)
		
var BodyModels : Array[MeshInstance3D]
var Decorations : Dictionary[String, Array] = {
	"RA" : [],
	"LS" : [],
	"RS" : [],
	"HE" : [],
	"CH" : [],
}

var CurrentAlarmState : AlarmState = AlarmState.IDLE

enum AlarmState{
	IDLE,
	ALARMED,
	TRIGGERED
}

var visuals : Node3D

func SetAlarmState(NewState : AlarmState) -> void:
	CurrentAlarmState = NewState
	UpdateStateLabel()

func UpdateStateLabel() -> void:
	match(CurrentAlarmState):
		AlarmState.IDLE:
			AlarmStateLabel.text = ""
		AlarmState.ALARMED:
			AlarmStateLabel.text = "?"
		AlarmState.TRIGGERED:
			AlarmStateLabel.text = "!"

#----------------------------------------------------------------

#Monster Data


#Location details
var CurrentPosition : Vector3i
var CurrentPlPosition : Vector3
var LookDir : float
var LastDirection : Vector3i = Vector3i.BACK

#Signals
signal EnemyMet(Group : MonsterGroup)
signal Dissabled
signal Respawned

#Tweens
var MoveTw : Tween
var HeadRotTw : Tween
var RotTw : Tween
var RunTw : Tween

var SeeingPlayer : bool = false
#Bool that stops from Update function from continuing
var GoingAfterPlayer : bool = false
#Varaible rises when enemy looks at player, once at max (1) moster atacks player
var PlayerVis : float = 0
#----------------------------------------------------------------

func _ready() -> void:
	position = CurrentPosition * Level.CurrentWorldScale
	G.LastKnownPosition = position
	Level.EnemyOccupiedSlots.append(CurrentPosition)
	AnimModifier.StateSwitched(FightCharacter.CharacterState.IDLE)

func RegisterCharacter(group : MonsterGroup) -> void:
	if (group == null):
		Skel.clear_bones()
		visuals.queue_free()
		return
		
	G.Respawned.connect(Respawn)
	
	var pickedArchetype = G
	
	var incommingSkel : Skeleton3D = load(pickedArchetype.Mon.Skeleton).instantiate()
	
	for boneIndex in incommingSkel.get_bone_count():
		Skel.add_bone(incommingSkel.get_bone_name(boneIndex))
		
		var parentIndex = incommingSkel.get_bone_parent(boneIndex)
		if (parentIndex != -1):
			Skel.set_bone_parent(boneIndex, parentIndex)
		
		Skel.set_bone_global_pose(boneIndex, incommingSkel.get_bone_global_pose(boneIndex))
	
	incommingSkel.queue_free()
	
	visuals = load(pickedArchetype.Mon.Visuals).instantiate()
	Skel.add_child(visuals)
	for g : MeshInstance3D in visuals.get_children():
		g.skeleton = g.get_path_to(Skel)
		if (g.name.contains("Deco")):
			Decorations[g.name.substr(0, 2)].append(g)
		else: if g.name.contains("B_"):
			BodyModels.append(g)
	
	var leftWeapon : FightWeapon = pickedArchetype.CharacterWeapon.WeaponScene.instantiate()
	WeaponPlacementL.add_child(leftWeapon)
	leftWeapon.ToggleTrail(false)
	
	if (pickedArchetype.CharacterWeapon.WeaponType == Fight_Animation_Modifier.WeaponType.TWO_HANDED):
		AnimModifier.CurrentWeaponType = Fight_Animation_Modifier.WeaponType.TWO_HANDED

	else: if (pickedArchetype.CharacterWeapon.WeaponType == Fight_Animation_Modifier.WeaponType.DUAL):
		AnimModifier.CurrentWeaponType = Fight_Animation_Modifier.WeaponType.DUAL

		var rightWeapon = pickedArchetype.CharacterWeapon.WeaponScene.instantiate()
		WeaponPlacementR.add_child(rightWeapon)
		rightWeapon.ToggleTrail(false)
		
	else:
		AnimModifier.CurrentWeaponType = Fight_Animation_Modifier.WeaponType.ONE_HANDED
		
	for g in BodyModels:
		g.set_surface_override_material(0, pickedArchetype.PickedMat)
		g.set_instance_shader_parameter("variant_index", pickedArchetype.variant_index)
	#if (pickedArchetype.CharacterWeapon.Mat != null):
		#WeaponShape.material_override = pickedArchetype.CharacterWeapon.Mat
	for DecoType : String in Decorations.keys():
		for g in Decorations[DecoType].size():
			var deco : MeshInstance3D = Decorations[DecoType][g]
			deco.visible = pickedArchetype.PickedDecorations[DecoType] == g

func Update(delta: float, PlayerPos : Vector3) -> void:
	Skel.advance(delta)
	
	if (!SeeingPlayer):
		if (is_instance_valid(MoveTw) and MoveTw.is_valid()):
			MoveTw.custom_step(delta)

	if (is_instance_valid(RotTw) and RotTw.is_valid()):
		RotTw.custom_step(delta)
	if (is_instance_valid(HeadRotTw) and HeadRotTw.is_valid()):
		HeadRotTw.custom_step(delta)
	if (is_instance_valid(RunTw) and RunTw.is_valid()):
		RunTw.custom_step(delta)
	
	CurrentPlPosition = PlayerPos
	
	if (GoingAfterPlayer):
		return
	
	#PlayerCast.rotation.y = LookDir
	
	#if (PlayerCast.is_colliding()):
		#var Collider = PlayerCast.get_collider().get_parent().get_parent()
		#if (Collider is PlayerManequin):
			#PlayerVis += delta
			#if (PlayerVis < 1.0):
				##added if statement to stop alarm state showing when collision randomly happens when enemy rotates
				#if (PlayerVis > 0.1):
					#SetAlarmState(AlarmState.ALARMED)
				#SeeingPlayer = true
				#return
			#SeeingPlayer = false
			#JumpToPlayer(Collider)
			#SetAlarmState(AlarmState.TRIGGERED)
		#else:
			#SeeingPlayer = false
			#PlayerVis = 0
			#SetAlarmState(AlarmState.IDLE)
	#else:
		#SeeingPlayer = false	

func Toggle(t : bool) -> void:
	PlayerCast.enabled = t
	Area.get_child(0).disabled = !t
	Cast.enabled = t
	visible = t

func StepSound() -> void:
	if (Stage.CurrentWorld.MData.IsWater(Helper.PlayerPositionToMap(global_position))):
		AudioManager.Instance.PlaySoundLocational(AudioManager.Sound.WATER_STEP, global_position, -2, 0.1, 1, true, 2)
	else:
		AudioManager.Instance.PlaySoundLocational(Stage.CurrentWorld.StepSound, global_position, -2, 0.1, 1, true, 2)
	
		

func TakeAction() -> void:
	Action(1)

var d = 2
func UpdateAction(delta : float) -> void:
	d -= delta
	if d > 0:
		return
	d = 3
	Action(3)

func CanGoToLocation(Loc : Vector3i) -> bool:
	return !Cast.is_colliding() and !Level.EnemyOccupiedSlots.has(Loc)

func Action(CustomStep : float = 0.6) -> void:
	if (CurrentAlarmState == AlarmState.TRIGGERED or SeeingPlayer):
		return
	
	var dirs = GetRandomDirections()
	
	var PickedDirection : Vector3i = Vector3i.ZERO
	
	var DirectionToGo : Vector3i = dirs.pop_front()
	#Cast.global_position = Vector3(CurrentPosition * Level.CurrentWorldScale) + Vector3(0,0.3,0)
	Cast.target_position = DirectionToGo * Level.CurrentWorldScale
	Cast.force_raycast_update()
	
	while (dirs.size() > 0):
		if (CanGoToLocation(CurrentPosition + DirectionToGo)):
			PickedDirection = DirectionToGo
			break
		DirectionToGo = dirs.pop_back()
		Cast.target_position = DirectionToGo * Level.CurrentWorldScale
		Cast.force_raycast_update()
	
	if (DirectionToGo != LastDirection):
		LookAtDirection(DirectionToGo)
		return
	
	if (PickedDirection == Vector3i.ZERO):
		return
	
	var cell = Stage.CurrentWorld.GetMapData().GetCell(CurrentPosition + PickedDirection)
	if (cell.type == CellData.CELLTYPE.DOWN_STAIRS):
		var NewLoc = CurrentPosition - Vector3i(0,1,0) + PickedDirection + PickedDirection
		if (Level.EnemyOccupiedSlots.has(NewLoc)):
			return
		PickedDirection *= 2
		PickedDirection.y -= 1
	else: if (cell.type == CellData.CELLTYPE.UP_STAIRS):
		var NewLoc = CurrentPosition + Vector3i(0,1,0) + PickedDirection + PickedDirection
		if (Level.EnemyOccupiedSlots.has(NewLoc)):
			return
		PickedDirection *= 2
		PickedDirection.y += 1
	
	Level.EnemyOccupiedSlots.erase(CurrentPosition)
	CurrentPosition = (CurrentPosition + PickedDirection)
	Level.EnemyOccupiedSlots.append(CurrentPosition)
	
	print("Moving to position {0}".format([CurrentPosition]))
	G.LastKnownPosition = CurrentPosition * Level.CurrentWorldScale
	
	if (is_instance_valid(MoveTw)):
		MoveTw.kill()
	var lastPos = Skel.global_position
	position = CurrentPosition * Level.CurrentWorldScale
	Skel.global_position = lastPos
	MoveTw = create_tween()
	MoveTw.tween_property(Skel, "position", Vector3(0,0.1,0), CustomStep)
	MoveTw.pause()
	MoveTw.finished.connect(WalkingFinished)
	#print("Mosnter moving from {0} to {1}".format([position, CurrentPosition * Level.CurrentWorldScale]))
	
	AnimModifier.Walking = true

func LookAtDirection(DirectionToGo : Vector3i) -> void:
	
	#var NewLookDir = DirToAngle(DirectionToGo)
	if (is_instance_valid(RotTw)):
		RotTw.kill()
	RotTw = create_tween()
	RotTw.set_ease(Tween.EASE_IN)
	RotTw.set_trans(Tween.TRANS_QUART)

	var angle = Vector3(LastDirection).signed_angle_to(DirectionToGo, Vector3.UP)
	
	LookDir += angle
	
	RotTw.tween_property(Skel, "rotation", Vector3(0,LookDir,0), 0.5)
	RotTw.pause()
	RotTw.finished.connect(RotationFinished)
	
	if (is_instance_valid(HeadRotTw)):
		HeadRotTw.kill()
	HeadRotTw = create_tween()
	HeadRotTw.set_ease(Tween.EASE_OUT)
	HeadRotTw.set_trans(Tween.TRANS_CUBIC)
	HeadRotTw.tween_property(HeadRotationPivot, "rotation", Vector3(0,LookDir,0), 0.25)
	HeadRotTw.pause()
	
	LastDirection = DirectionToGo
	
func RotationFinished() -> void:
	d = 0


func WalkingFinished() -> void:
	AnimModifier.Walking = false
	#AnimTree.set("parameters/WalkBlend/blend_amount", 0.0)
	
func GetRandomDirections() -> Array[Vector3i]:
	var Directions : Array[Vector3i] = [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]
	Directions.shuffle()
	var ran = randf_range(0, 100)
	if ran > 50:
		Directions.erase(LastDirection)
		Directions.insert(0, LastDirection)
	#Make sure to stop enemy from heading to player when on different floor or too far away
	var DistanceToPlayer = global_position.distance_squared_to(CurrentPlPosition)
	if (DistanceToPlayer < 50 and global_position.y == CurrentPlPosition.y):
		var PlDir = global_position.direction_to(CurrentPlPosition)
		for g in Directions:
			if (PlDir.dot(g) > 0):
				Directions.erase(g)
				Directions.insert(0, g)
				break;
	return Directions

func DirToAngle(Dir : Vector3) -> float:
	var Angle : float = 0
	match Dir:
		Vector3.FORWARD: Angle = PI
		Vector3.BACK: Angle = 0
		Vector3.LEFT: Angle = -PI / 2
		Vector3.RIGHT: Angle = PI / 2
	return Angle

func Respawn() -> void:
	Respawned.emit()
	#$Area3D.monitoring = true
	show()
	Sound.play()
	position = G.OriginalPos * Level.CurrentWorldScale
	CurrentPosition = G.OriginalPos
	Level.EnemyOccupiedSlots.append(CurrentPosition)
	G.LastKnownPosition = CurrentPosition * Level.CurrentWorldScale
	#PlayerCast.enabled = true

func JumpToPlayer(_PL : BasePlayerManequin, _ForceLook : bool = true) -> void:
	GoingAfterPlayer = true
	PlayerCast.enabled = false
	PlayerVis = 0
	
	var PlMapPos = Helper.PlayerPositionToMap(CurrentPlPosition)
	PlMapPos.y -= 1
	var Dist = roundi((PlMapPos * LastDirection).distance_to(CurrentPosition * LastDirection))
	var NewPos = CurrentPosition + Vector3i(LastDirection * Dist)
	print("Jumping from position {0} to position {1}, Player position : {2}".format([CurrentPosition, NewPos, PlMapPos]))
	CurrentPosition = NewPos
	G.LastKnownPosition = CurrentPosition * Level.CurrentWorldScale
	Scream.play(0)
	if (is_instance_valid(MoveTw)):
		MoveTw.kill()
	MoveTw = create_tween()
	MoveTw.tween_property(self, "position", Vector3(NewPos * Level.CurrentWorldScale), Dist / 2.0)
	MoveTw.finished.connect(JumpFinished)
	MoveTw.pause()


func JumpFinished() -> void:
	SetAlarmState(AlarmState.IDLE)
	Scream.stop()
	GoingAfterPlayer = false
	PlayerCast.enabled = true
	d = 0
	

func PlayerMet() -> void:
	GoingAfterPlayer = false
	Dead()
	EnemyMet.emit(G)
	Sound.stop()

func Dead() -> void:
	Level.EnemyOccupiedSlots.erase(CurrentPosition)
	Dissabled.emit()

func _on_area_3d_area_entered(area: Area3D) -> void:
	if (area.get_parent().get_parent() is BasePlayerManequin):
		PlayerMet()


	
