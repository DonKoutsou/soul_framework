extends Node3D

class_name BasePlayerManequin

@export var Cast : RayCast3D
@export var CamPivot : Node3D
@export var CamRotPivot : Node3D
@export var Cam : PlayerCamera
@export var DuckPivot : Node3D

@export var AimPoint : Node3D
@export var RewardLocation : Node3D
@export var MagicProjectileLocation : Node3D

var CanMove : bool = true
var LookDir : Vector3
var LastPosition : Vector3i
var PlayerPos : Vector3i
var ActualPos : Vector3
signal PositionChanged(OriginalPos : Vector3, Pos : Vector3, Rot : float, Moved : bool)
signal PositionPassed(passedPosition : Vector3)
signal HitWall(Pos, Rot)
signal HitGap(Pos, Rot)
signal OrientationChanged(Pos : Vector3, Rot : float)
signal PositionSeen(Pos : Vector3)

signal LockedDoorMet(Pos : Vector3i)
signal NPC_MET(Char : MapCharacter, Pos : Vector3i)
signal VerticalMovement(t : bool, Up : bool)
signal VerticalMovementStarted
signal VerticalMovementEnded
signal Teleported(Height : float)
signal Fell()
signal Damaged(Source : Map.TrapType, Amm : int)
signal FallStarted()
signal DialogueMet(Pos : Vector3,Dialogue : DialogueContainer)
signal MovableFound(t : bool)
signal MovableLifted(t : bool)

var Walking : bool = false
var Walkback : bool = false
var WalkUp : bool = false
var WalkDown : bool = false
var FallDown : bool = false
var StairsUp : bool = false
var StairsDown : bool = false
var CamOriginalPosition : Transform3D

var PlayerFighter : Player

static var Instance : BasePlayerManequin
var NoClip : bool

static var CanWalkOnWater : bool = false
static var CanWalkOnLava : bool = false
static var CanWalkOverGaps : bool = false

var HoldingPosition : Vector3i

var MoveTween : Tween
var RotTween : Tween
var FlowTween : Tween
var camtw : Tween
var DuckTween : Tween
var JumpTween : Tween

#Used for doing step sounds every 0.5 seconds
var StepCoolDown : float = 0.4

#--------------------------------------------------------------------------------------
func _ready() -> void:
	Instance = self
	CamOriginalPosition = Cam.transform
	InputManager.ChangeMouse(Input.MOUSE_MODE_CAPTURED)
	#$MeshInstance3D.scale = Vector3(1,1,1) * Level.CurrentWorldScale

#--------------------------------------------------------------------------------------
func ProcessInput(event: InputEvent) -> void:
		
	if (CanMove):
		HandleRotation(event)
		HandleWalk(event)

		if (event.is_action_pressed("Hold")):
			var dir = Helper.rotate_vector3i(Vector3i(0,0,-1), LookDir.y, Vector3i(0,1,0))
			var LookPosition = Vector3i(PlayerPos + (dir * Level.CurrentWorldScale))
			var mapLookPosition = Helper.PlayerPositionToMap(LookPosition)
			var cell = Stage.CurrentWorld.GetMapData().cells[mapLookPosition]
			if (cell.Custom_Data.has("Movable")):
				HoldingPosition = mapLookPosition
				PlayerFighter.Grab()
				MovableLifted.emit(true)
			
		if (event.is_action_released("Hold") and !Walking):
			if (HoldingPosition != Vector3i.ZERO):
				MovableLifted.emit(false)
				HoldingPosition = Vector3i.ZERO
				PlayerFighter.ReturnHand()
			CheckForMovable()

#--------------------------------------------------------------------------------------
func FightToggled(t : bool) -> void:
	if (t):
		ReturnCam()
		CanMove = false
	else:
		CanMove = true

#--------------------------------------------------------------------------------------
func Update(delta: float) -> void:
	
	if (CanMove):
		HandleWalk(null)
		HandleDeltaRotation(delta)
	
	if (Walking):
		StepCoolDown -= delta
		if (StepCoolDown <= 0):
			StepCoolDown = 0.4
			
#--------------------------------------------------------------------------------------
func Damage(Origin : Map.TrapType, Amm : int) -> void:
	Damaged.emit(Origin, Amm)

#--------------------------------------------------------------------------------------
func Teleport(Pos : Vector3) -> void:
	LastPosition = position
	var OriginalPos = PlayerPos
	PlayerPos = Pos
	ActualPos = Pos
	if (is_instance_valid(MoveTween)):
		MoveTween.kill()
	
	position = PlayerPos
	PositionChanged.emit(OriginalPos, PlayerPos, LookDir.y, false)
	CamPivot.position = Vector3.ZERO
	Teleported.emit(PlayerPos.y)
	CheckForMovable()
	
#--------------------------------------------------------------------------------------
func ProcessTweens(delta : float) -> void:
	if (is_instance_valid(MoveTween) and MoveTween.is_valid()):
		MoveTween.custom_step(delta)
	if (is_instance_valid(RotTween) and RotTween.is_valid()):
		RotTween.custom_step(delta)
	if (is_instance_valid(FlowTween) and FlowTween.is_valid()):
		FlowTween.custom_step(delta)
	if (is_instance_valid(camtw) and camtw.is_valid()):
		camtw.custom_step(delta)
	if (is_instance_valid(DuckTween) and DuckTween.is_valid()):
		DuckTween.custom_step(delta)
	if (is_instance_valid(JumpTween) and JumpTween.is_valid()):
		JumpTween.custom_step(delta)

#--------------------------------------------------------------------------------------
func OverrideCamPos(NewPos : Transform3D) -> void:
	if (is_instance_valid(camtw)):
		camtw.kill()
	camtw = create_tween()
	camtw.set_ease(Tween.EASE_OUT)
	camtw.set_trans(Tween.TRANS_SINE)
	camtw.tween_property(Cam,"global_transform", NewPos, 1)
	camtw.pause()
	Cam.PositionOverriden = true
	#Cam.global_transform = NewPos

#--------------------------------------------------------------------------------------
func LookAtPoint(Point : Vector3) -> void:
	AimPoint.look_at(Point, Vector3.UP, false)
	var Rot : Vector3 = Vector3(0,AimPoint.global_rotation.y,0)
	var Flow : Vector3 = Vector3(0,0,AimPoint.global_rotation.y / 50)
	#if (Rot == Vector3.ZERO):
		#return
		
	LookDir = Rot
	
	if (is_instance_valid(FlowTween)):
		FlowTween.kill()
	if (is_instance_valid(RotTween)):
		RotTween.kill()
		
	RotTween = create_tween()
	RotTween.set_ease(Tween.EASE_IN_OUT)
	RotTween.set_trans(Tween.TRANS_CIRC)
	RotTween.tween_property(CamRotPivot, "global_rotation", LookDir + Flow, 0.15)
	RotTween.finished.connect(ResetFlow.bind(LookDir))
	RotTween.pause()
	OrientationChanged.emit(PlayerPos, LookDir.y)
	#AudioManager.Instance.PlaySound(AudioManager.Sound.STEP, -10, 0.2, 0.8)
 
#--------------------------------------------------------------------------------------
func ReturnCam(t : float = 1) -> void:
	
	if (is_instance_valid(camtw)):
		camtw.kill()
	#Cam.transform = CamOriginalPosition
	camtw = create_tween()
	camtw.set_ease(Tween.EASE_OUT)
	camtw.set_trans(Tween.TRANS_SINE)

	camtw.tween_property(Cam,"transform", CamOriginalPosition, t)
	camtw.set_parallel(true)
	camtw.tween_property(Cam,"RotationToFocusOn", Vector3(-0.1,0,0), t)
	camtw.pause()
	camtw.finished.connect(Cam.set.bind("PositionOverriden" ,false))


#--------------------------------------------------------------------------------------
var Turning : bool = false
var AccumulatedTime : float = 0.0
const CAM_MAX = Vector2(PI * 0.25, PI * 0.25)
func HandleRotation(event: InputEvent) -> void:
	var Rot : Vector3 = Vector3.ZERO
	var Flow : Vector3 = Vector3.ZERO

	if (event == null):

		var d = GetJoyDir(event.axis, event.axis_value) 
		var CameraOffset : Vector3 = Vector3.ZERO
		CameraOffset.y -= d.x / 200
		CameraOffset.x -= d.y / 200
		Cam.RotationToFocusOn = Vector3(clamp(Cam.RotationToFocusOn.x + CameraOffset.x, -CAM_MAX.x, PI * 0.5), clamp(Cam.RotationToFocusOn.y + CameraOffset.y, -CAM_MAX.y, CAM_MAX.y), Cam.RotationToFocusOn.z + CameraOffset.z)
	
		return
	if (event is InputEventMouseMotion ):
		var d = event.screen_relative
		var CameraOffset : Vector3 = Vector3.ZERO
		CameraOffset.y -= d.x / 200
		CameraOffset.x -= d.y / 200
		Cam.RotationToFocusOn = Vector3(clamp(Cam.RotationToFocusOn.x + CameraOffset.x, -CAM_MAX.x, PI * 0.5), clamp(Cam.RotationToFocusOn.y + CameraOffset.y, -CAM_MAX.y, CAM_MAX.y), Cam.RotationToFocusOn.z + CameraOffset.z)

	if (event.is_action_pressed("look_left")):
		Rot.y += PI / 2
		Flow.z += PI / 100
	if (event.is_action_pressed("look_right")):
		Rot.y -= PI / 2
		Flow.z -= PI / 100

	if (Rot == Vector3.ZERO):
		return
	
	if (HoldingPosition != Vector3i.ZERO):
		MovableLifted.emit(false)
		HoldingPosition = Vector3i.ZERO
		PlayerFighter.ReturnHand()
	
	if (is_instance_valid(FlowTween)):
		FlowTween.kill()
	
	var EaseT = Tween.EASE_OUT
	if (is_instance_valid(RotTween)):
		if (RotTween.is_valid()):
			if (RotTween.get_total_elapsed_time() < AccumulatedTime * 0.8):
				return
			AccumulatedTime -= RotTween.get_total_elapsed_time()
			if AccumulatedTime > 0.2:
				EaseT = Tween.EASE_OUT

		AccumulatedTime = 0.0
		RotTween.kill()
	
	LookDir += Rot
	
	RotTween = create_tween()
	RotTween.set_ease(EaseT)
	RotTween.set_trans(Tween.TRANS_SINE)
	AccumulatedTime += 0.5
	RotTween.tween_property(CamRotPivot, "rotation", LookDir + Flow, AccumulatedTime)

	RotTween.finished.connect(ResetFlow.bind(LookDir))
	RotTween.pause()
	Turning = true

	OrientationChanged.emit(PlayerPos, LookDir.y)
	PlayerFighter.Rotated(-Vector3(Flow.z, 0, randf_range(-0.01, 0.01)))
	
	CheckForMovable()

#--------------------------------------------------------------------------------------
func HandleDeltaRotation(_delta : float) -> void:
	var x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var d = Vector2(x,y) * 2
	if (d != Vector2.ZERO):
		var CameraOffset : Vector3 = Vector3.ZERO
		CameraOffset.y -= d.x / 200
		CameraOffset.x -= d.y / 200
		Cam.RotationToFocusOn = Vector3(clamp(Cam.RotationToFocusOn.x + CameraOffset.x, -CAM_MAX.x, PI), clamp(Cam.RotationToFocusOn.y + CameraOffset.y, -CAM_MAX.y, CAM_MAX.y), Cam.RotationToFocusOn.z + CameraOffset.z)

#--------------------------------------------------------------------------------------
func GetJoyDir(axis : JoyAxis, value : float):
	match(axis):
		JoyAxis.JOY_AXIS_RIGHT_X:
			return Vector2(value, 0)
		JoyAxis.JOY_AXIS_RIGHT_Y:
			return Vector2(0, value)
		JoyAxis.JOY_AXIS_LEFT_X:
			return Vector2(value, 0)
		JoyAxis.JOY_AXIS_LEFT_Y:
			return Vector2(0, value)

#--------------------------------------------------------------------------------------
func ResetFlow(ResetTo : Vector3) -> void:
	if (is_instance_valid(FlowTween)):
		FlowTween.kill()
	Turning = false
	FlowTween = create_tween()
	FlowTween.set_ease(Tween.EASE_OUT)
	FlowTween.set_trans(Tween.TRANS_BACK)
	FlowTween.tween_property(CamRotPivot, "rotation", ResetTo, 0.5)
	FlowTween.pause()

#--------------------------------------------------------------------------------------
func GetLookDir() -> Vector3:
	return CamRotPivot.rotation

#--------------------------------------------------------------------------------------
func GetLookTransform() -> Transform3D:
	return CamRotPivot.global_transform.rotated_local(Vector3(0,1,0), -PI/2)

#--------------------------------------------------------------------------------------
func SetLookDir(rot : float) -> void:
	CamRotPivot.rotation.y = rot
	LookDir.y = rot

#--------------------------------------------------------------------------------------
func ReturnToLastPosition() -> void:
	if (is_instance_valid(MoveTween)):
		MoveTween.kill()
	Walking = true
	MoveTween = create_tween()
	MoveTween.set_ease(Tween.EASE_OUT)
	MoveTween.set_trans(Tween.TRANS_QUAD)
	MoveTween.tween_method(TweenCam.bind(CamPivot.global_position, LastPosition), 0.0, 1.0, 0.3)
	MoveTween.finished.connect(FinishedWalk)
	MoveTween.pause()
	var OriginalPos = PlayerPos
	position = LastPosition
	PlayerPos = LastPosition
	ActualPos = PlayerPos
	PositionChanged.emit(OriginalPos, LastPosition, LookDir.y, true)
	#AudioManager.Instance.PlaySound(Stage.CurrentWorld.StepSound, 0, 0.2)
	Walkback = false

#--------------------------------------------------------------------------------------
func WalkVertical() -> void:
	if (is_instance_valid(MoveTween)):
		MoveTween.kill()
	
	Walking = true
	MoveTween = create_tween()
	var CameraLastPosition = CamPivot.global_position
	var dest : Vector3i = PlayerPos
	if (WalkUp):
		
		dest.y += Level.CurrentWorldScale.y
		MessageBox.RegisterEvent("Went up the stairs")
		AudioManager.Instance.PlaySound(AudioManager.Sound.STEP, 0, 0.2)
		AudioManager.Instance.PlaySound(AudioManager.Sound.LADDER)
		VerticalMovement.emit(true, true)
		VerticalMovementStarted.emit()
		MoveTween.set_ease(Tween.EASE_OUT)
		MoveTween.set_trans(Tween.TRANS_QUAD)
		MoveTween.tween_method(TweenCam.bind(CamPivot.global_position, dest), 0.0, 1.0, 1)
	else: if (WalkDown):
		
		dest.y -= Level.CurrentWorldScale.y
		MessageBox.RegisterEvent("Went down the stairs")
		AudioManager.Instance.PlaySound(AudioManager.Sound.STEP, 0, 0.2)
		AudioManager.Instance.PlaySound(AudioManager.Sound.LADDER)
		VerticalMovement.emit(true, false)
		VerticalMovementStarted.emit()
		MoveTween.set_ease(Tween.EASE_OUT)
		MoveTween.set_trans(Tween.TRANS_QUAD)
		MoveTween.tween_method(TweenCam.bind(CamPivot.global_position, dest), 0.0, 1.0, 1)
	else : if (FallDown):
		FallStarted.emit()
		dest.y -= Level.CurrentWorldScale.y
		MessageBox.RegisterEvent("Fell down a pit")
		MoveTween.set_ease(Tween.EASE_IN)
		MoveTween.set_trans(Tween.TRANS_QUINT)
		MoveTween.tween_method(TweenCam.bind(CamPivot.global_position, dest), 0.0, 1.0, 0.5)
		VerticalMovement.emit(false, false)
	else : if (StairsDown):
		dest.y -= Level.CurrentWorldScale.y
		dest.z += 2
		#MessageBox.RegisterEvent("Fell down a pit")
		MoveTween.set_ease(Tween.EASE_IN)
		MoveTween.set_trans(Tween.TRANS_QUINT)
		MoveTween.tween_method(TweenCam.bind(CamPivot.global_position, dest), 0.0, 1.0, 0.5)
		VerticalMovementStarted.emit()
		#VerticalMovement.emit(false)
	else : if (StairsUp):
		dest.y += Level.CurrentWorldScale.y
		dest.z += 2
		#MessageBox.RegisterEvent("Fell down a pit")
		MoveTween.set_ease(Tween.EASE_IN)
		MoveTween.set_trans(Tween.TRANS_QUINT)
		MoveTween.tween_method(TweenCam.bind(CamPivot.global_position, dest), 0.0, 1.0, 0.5)
		VerticalMovementStarted.emit()
		#VerticalMovement.emit(false)
	MoveTween.finished.connect(VerticalMovementStopped)
	MoveTween.finished.connect(FinishedWalk)
	MoveTween.pause()
	var OriginalPos = PlayerPos
	position = dest
	CamPivot.global_position = CameraLastPosition
	PlayerPos = dest
	
	PositionChanged.emit(OriginalPos, dest, LookDir.y, false)
	
	
	Walkback = false

#--------------------------------------------------------------------------------------
func RegisterPlayerCharacter(plchar : Character) -> void:
	Fell.connect(plchar.DamageFlat.bind(10))
	Damaged.connect(plchar.EV_EnviromentalDamage)

#--------------------------------------------------------------------------------------
func VerticalMovementStopped() -> void:
	if (WalkDown):
		VerticalMovementEnded.emit()
		VerticalMovement.emit(false, false)
	if (WalkUp):
		VerticalMovementEnded.emit()
		VerticalMovement.emit(false, true)
	if (FallDown):
		PlayerCamera.start_shake(0.01, 0.4, true)
		Fell.emit()
		#VerticalMovement.emit(false)
	WalkUp = false
	WalkDown = false
	StairsDown = false
	StairsUp = false
	FallDown = false

#--------------------------------------------------------------------------------------
func GetWalkMagniture(event : InputEvent) -> Vector3i:
	var dir = Vector3i.ZERO

	if (event != null):
		if event.is_action_pressed("move_forward"):
			dir.z -= 1
		if event.is_action_pressed("move_back", false):
			dir.z += 1
		#if event.is_action_pressed("look_left", false):
			#dir.x -= 1
		#if event.is_action_pressed("look_right", false):
			#dir.x += 1
	else:
		if Input.is_action_pressed("move_forward") and !Walking:
			dir.z -= 1
		if Input.is_action_pressed("move_back") and !Walking:
			dir.z += 1
		#if Input.is_action_pressed("look_left") and !Walking:
			#dir.x -= 1
		#if Input.is_action_pressed("look_right") and !Walking:
			#dir.x += 1

	return dir
	

#--------------------------------------------------------------------------------------
func CantMoveFurther(dir : Vector3i) -> bool:
	Cast.target_position = ((-dir * 2) * Level.CurrentWorldScale)
	Cast.force_raycast_update()
	return Cast.is_colliding()

#--------------------------------------------------------------------------------------
func CanCrossGap(dir : Vector3i) -> bool:
	Cast.target_position = ((-dir * 2) * Level.CurrentWorldScale)
	Cast.set_collision_mask_value(7, false)
	Cast.force_raycast_update()
	Cast.set_collision_mask_value(7, true)
	return !Cast.is_colliding()

var AccumulatedWalkTime : float = 0.0

func HandleWalk(event: InputEvent) -> void:
	if (Walkback or WalkUp or WalkDown or FallDown):
		return

	var dir = GetWalkMagniture(event)
 	
	if (dir == Vector3i.ZERO):
		return
	
	var TraversalTime = 1.0
	var Ease = Tween.EASE_OUT
	if (is_instance_valid(MoveTween)):
		if (MoveTween.is_valid()):
			if (MoveTween.get_total_elapsed_time() < TraversalTime * 0.6):
				return
			Ease = Tween.EASE_OUT
	
	var flow = Vector3(randf_range(-0.01, 0.01), dir.y, dir.z * 0.05)
	dir = Helper.rotate_vector3i(dir, LookDir.y, Vector3i(0,1,0))
	
	var mapData : MapData = Stage.CurrentWorld.GetMapData()
	var NewPosition = PlayerPos + ((dir * Level.CurrentWorldScale) as Vector3i)
	var PlMapPos = Helper.PlayerPositionToMap(NewPosition)
	
	Cast.target_position = dir * Level.CurrentWorldScale
	Cast.force_raycast_update()
	if (Cast.is_colliding() and !NoClip):
		
		var Collider = Cast.get_collider() as Area3D
		#Water
		if (Collider.get_collision_mask_value(5)):
			if (!CanWalkOnWater):
				MessageBox.RegisterEvent("Can't go there right now", false)
				NewPosition = PlayerPos
		#Lava
		else: if (Collider.get_collision_mask_value(6)):
			if (!CanWalkOnLava):
				MessageBox.RegisterEvent("Can't go there right now", false)
				NewPosition = PlayerPos
		#Gap
		else: if (Collider.get_collision_mask_value(7)):
			if (!CanWalkOverGaps):
				MessageBox.RegisterEvent("Can't jump this gap right now", false)
				HitGap.emit(PlayerPos, LookDir.y)
				NewPosition = PlayerPos
			else: if (HoldingPosition != Vector3i.ZERO):
				MessageBox.RegisterEvent("Can't jump while holding an obstacle", false)
				NewPosition = PlayerPos
			else:
				if (!CanCrossGap(-dir)):
					NewPosition = PlayerPos
				else:
					NewPosition = NewPosition + ((dir * Level.CurrentWorldScale) as Vector3i)
					Jump()
					
		else : if (Collider.get_collision_layer_value(2)):
			NewPosition = PlayerPos
			var DorLoc = Helper.PlayerPositionToMap(NewPosition)
			LockedDoorMet.emit(DorLoc)
			
		else: if (Collider is Interactable):
			NewPosition = HandleInteractable(Collider, PlayerPos, NewPosition)

		else:
			HitWall.emit(PlayerPos, LookDir.y)
			NewPosition = PlayerPos
	
	var cell = mapData.GetCell(PlMapPos)
	if (!is_instance_valid(cell)):
		return
	
	if (cell.HasData("Breakable")):
		#Manequin.Walkback = true
		NewPosition = PlayerPos
		MessageBox.RegisterEvent("Way is blocked", false)
	if (cell.HasData("Chest")):
		#Manequin.Walkback = true
		NewPosition = PlayerPos
		MessageBox.RegisterEvent("Way is blocked", false)
	if (cell.HasData("SoftBreakable")):
		NewPosition = PlayerPos
		MessageBox.RegisterEvent("Way is blocked", false)
		
	if (cell.type == CellData.CELLTYPE.DOWN_STAIRS):
		NewPosition = HandleStairDownCellTraversal(NewPosition, dir, cell, mapData)

	if (cell.type == CellData.CELLTYPE.UP_STAIRS):
		NewPosition = HandleStairUpCellTraversal(NewPosition, dir, cell, mapData)
	
	PlMapPos = Helper.PlayerPositionToMap(NewPosition)
	cell = mapData.cells[PlMapPos]
	
	var newCell = mapData.cells[Helper.PlayerPositionToMap(NewPosition)]
	
	if (newCell.Custom_Data.has("Movable")):
		var PushDirection : Vector3i = Vector3(NewPosition).direction_to(Vector3(PlayerPos))
		if (CantMoveFurther(PushDirection) or HoldingPosition == Vector3i.ZERO):
			MessageBox.RegisterEvent("Way is blocked", false)
			NewPosition = PlayerPos
	
	
	var OriginalPos = PlayerPos
	if (NewPosition != PlayerPos):
		WalkDown = cell.type == CellData.CELLTYPE.DOWN_LADDER
		WalkUp = cell.type == CellData.CELLTYPE.UP_LADDER
		FallDown = cell.type == CellData.CELLTYPE.FALL
		PlayerFighter.ToggleWalk(true)
	
	if (is_instance_valid(MoveTween)):
		MoveTween.kill()
		
	PlayerPos = NewPosition
	var CameraLastPosition = CamPivot.global_position
	
	MoveTween = create_tween()
	MoveTween.set_ease(Ease)
	MoveTween.set_trans(Tween.TRANS_SINE)
	MoveTween.tween_method(TweenCam.bind(CameraLastPosition, PlayerPos), 0.0, 1.0, TraversalTime)
	MoveTween.finished.connect(FinishedWalk)
	MoveTween.pause()
	
	LastPosition = position
	position = PlayerPos
	CamPivot.global_position = CameraLastPosition
	Walking = true
	
	PositionChanged.emit(OriginalPos, PlayerPos, LookDir.y, true)
	PlayerFighter.Rotated(flow)
	
	CheckForMovable()

#--------------------------------------------------------------------------------------
func HandleInteractable(Collider : Interactable, CurrentPosition : Vector3i, TargetPosition : Vector3i) -> Vector3i:
	var newPosition = TargetPosition
	if (Collider is MapCharacter):
		var mapCharacterPos = Helper.PlayerPositionToMap(TargetPosition)
		NPC_MET.emit(Collider, mapCharacterPos)
		newPosition = CurrentPosition
	return newPosition

#--------------------------------------------------------------------------------------
func HandleStairUpCellTraversal(pos : Vector3i, dir : Vector3i, cell : CellData, mapData : MapData) -> Vector3i:
	var NewPos = pos
	PositionPassed.emit(NewPos)
	var stairCell = cell
	
	while(stairCell.type == CellData.CELLTYPE.UP_STAIRS):
		NewPos += ((dir * Level.CurrentWorldScale) as Vector3i) + ( Vector3i(0,1,0) * Level.CurrentWorldScale)
		PositionPassed.emit(NewPos)
		stairCell = mapData.GetCell(Helper.PlayerPositionToMap(NewPos))
		
	get_tree().call_group("Enviroments", "ElevationChanged", true)
	
	return NewPos

#--------------------------------------------------------------------------------------
func HandleStairDownCellTraversal(pos : Vector3i, dir : Vector3i, cell : CellData, mapData : MapData) -> Vector3i:
	var NewPos = pos
	PositionPassed.emit(NewPos)
	var stairCell = cell
	
	while(stairCell.type == CellData.CELLTYPE.DOWN_STAIRS):
		NewPos += ((dir * Level.CurrentWorldScale) as Vector3i) - ( Vector3i(0,1,0) * Level.CurrentWorldScale)
		PositionPassed.emit(NewPos)
		stairCell = mapData.GetCell(Helper.PlayerPositionToMap(NewPos))
		
	get_tree().call_group("Enviroments", "ElevationChanged", true)
	
	return NewPos

#-----------------------------------------------------
##Checks if movable exists in front of player
func CheckForMovable() -> void:
	var dir = Helper.rotate_vector3i(Vector3i(0,0,-1), LookDir.y, Vector3i(0,1,0))
	var LookPosition = Vector3i(PlayerPos + (dir * Level.CurrentWorldScale))
	var LookMapPosition = Helper.PlayerPositionToMap(LookPosition)
	var cell = Stage.CurrentWorld.GetMapData().GetCell(LookMapPosition)
	if (!is_instance_valid(cell)):
		return
	Cast.target_position = dir
	Cast.force_raycast_update()
	if (Cast.is_colliding()):
		return
	if (cell.Custom_Data.has("Movable")):
		MovableFound.emit(true)
	else:
		MovableFound.emit(false)

#--------------------------------------------------------------------------------------
func FinishedWalk() -> void:
	Walking = false
	PlayerFighter.ToggleWalk(false)
	if (!Input.is_action_pressed("Hold")):
		if (HoldingPosition != Vector3i.ZERO):
			MovableLifted.emit(false)
			HoldingPosition = Vector3i.ZERO
			PlayerFighter.ReturnHand()
	if (Walkback):
		call_deferred("ReturnToLastPosition")
	else: if (WalkDown or WalkUp or FallDown):
		call_deferred("WalkVertical")

#--------------------------------------------------------------------------------------
func TweenCam(Alpha : float, OriginalPosition : Vector3, FinalPos : Vector3) -> void:
	CamPivot.global_position = OriginalPosition.lerp(FinalPos, Alpha)

#--------------------------------------------------------------------------------------
func Jump() -> void:
	JumpTween = create_tween()
	JumpTween.set_ease(Tween.EASE_IN)
	JumpTween.set_trans(Tween.TRANS_BACK)
	JumpTween.tween_property(CamRotPivot, "position", Vector3(0,1.5,0), 0.75)
	AudioManager.Instance.PlaySound(AudioManager.Sound.JUMP, 0, 0.2)
	await JumpTween.finished
	JumpTween = create_tween()
	JumpTween.set_ease(Tween.EASE_OUT)
	JumpTween.set_trans(Tween.TRANS_BOUNCE)
	JumpTween.tween_property(CamRotPivot, "position", Vector3(0,1,0), 1.25)
	
#--------------------------------------------------------------------------------------
func Duck(Direction : FightCharacter.AtackSide) -> void:
	#Assign the correct transform and state based on direction
	var t : Transform3D
	if (Direction == FightCharacter.AtackSide.LEFT):
		t = Transform3D(Basis().rotated(Vector3(0,0,1), PI/15), Vector3(-0.5,0,-0.2))
	else:
		t = Transform3D(Basis().rotated(Vector3(0,0,1), -PI/15), Vector3(0.5,0,-0.2))
	
	if (is_instance_valid(DuckTween)):
		DuckTween.kill()
	#init the tween to move the player
	DuckTween = create_tween()
	DuckTween.set_ease(Tween.EASE_OUT)
	DuckTween.set_trans(Tween.TRANS_QUINT)
	DuckTween.tween_property(DuckPivot, "transform", t, 0.5)
	DuckTween.pause()

#--------------------------------------------------------------------------------------
func UnDuck() -> void:
	if (is_instance_valid(DuckTween)):
		DuckTween.kill()
	DuckTween = create_tween()
	DuckTween.set_ease(Tween.EASE_OUT)
	DuckTween.set_trans(Tween.TRANS_BACK)
	var t = Transform3D(Basis(), Vector3.ZERO)
	DuckTween.tween_property(DuckPivot, "transform", t, 0.25)
	DuckTween.pause()

#--------------------------------------------------------------------------------------
func _on_area_3d_area_entered(area: Area3D) -> void:
	if (area is DialogueTrigger):
		DialogueMet.emit(area.position, area.Dialogues)
