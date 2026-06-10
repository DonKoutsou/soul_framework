@tool
extends LevelMultimesh
class_name MovablesMultimesh

@export var DragParticles : PackedScene

var MovableTween : Tween

func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	#var CurrentWorldScale = Level.CurrentWorldScale
	collider.size = geometry.get_aabb().size

func Proc(delta : float) -> void:
	if (is_instance_valid(MovableTween) and MovableTween.is_valid()):
		MovableTween.custom_step(delta)

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)

	if (cell.Custom_Data.has("Movable")):
		var MoveData : MovableData = cell.Custom_Data["Movable"]
		var Trans = Transform3D(Basis(), realPos).translated(Vector3(0,0.1,0))
		
		MoveData.trans = Trans
		
		var state : float = 0.0
		var variantIndex : int = 0
		if (MoveData.State):
			state = 1.0
		
		variantIndex = MoveData.Info.Element
		
		
		var collision = InteractionCollisionShape.new()
		collision.Name = InteractionCollisionShape.AreaNames.Movable
		collision.shape = collider
		var ColliderPos = Trans.translated(Vector3(0, 0.5, 0))
		collision.transform = ColliderPos
		AddSpawn(geometry.get_rid(), pos, Trans, 0, collision)
		var instance = spawnList[pos][0]["Instance"]
		
		RenderingServer.instance_geometry_set_shader_parameter(instance, "variant_index", variantIndex)
		RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_emission_energy_multiplier", state)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.MOVABLES

func LiftMovable(Data : MapData, Pos : Vector3i, t : bool) -> void:
	var cell = Data.cells[Pos]
	var moveData : MovableData = cell.Custom_Data["Movable"]
	
	var data = spawnList[Pos][0]
	var Instance : RID = data["Instance"]
	var InstanceTransform = moveData.trans
	
	if (is_instance_valid(MovableTween)):
		MovableTween.finished.emit()
		MovableTween.kill()
	MovableTween = create_tween()
	
	if (t):
		MovableTween.set_ease(Tween.EASE_IN_OUT)
		MovableTween.set_trans(Tween.TRANS_SINE)
		var NewT = Transform3D(Basis(), Vector3(InstanceTransform.origin.x, Pos.y * Level.CurrentWorldScale.y, InstanceTransform.origin.z)).translated(Vector3(0,0.1,0))
		AudioManager.Instance.PlaySoundLocational(AudioManager.Sound.LEVITATE, NewT.origin, -10, 0, 1, true, 2)
		MovableTween.tween_method(UpdateMovablePosition.bind(Instance, moveData), InstanceTransform, NewT.translated(Vector3(0,0.3,0)), 0.4)
	else:
		MovableTween.set_ease(Tween.EASE_OUT)
		MovableTween.set_trans(Tween.TRANS_BOUNCE)
		var Destination = Pos * Level.CurrentWorldScale
		var NewT = Transform3D(Basis(), Destination).translated(Vector3(0,0.1,0))
		MovableTween.tween_method(UpdateMovablePosition.bind(Instance, moveData), InstanceTransform, NewT, 0.4)
		AudioManager.Instance.PlaySoundLocational(AudioManager.Sound.DROP, NewT.origin, 20, 0, 1, true, 10)
		var Movedust = DragParticles.instantiate() as GPUParticles3D
		add_child(Movedust)
		Movedust.transform = NewT
		Movedust.emitting = true
		MovableTween.finished.connect(MovableFinish.bind(Movedust))
	MovableTween.pause()

func UpdateMovable(Data : MapData, Pos : Vector3i) -> void:
	var cell = Data.cells[Pos]
	var moveData : MovableData = cell.Custom_Data["Movable"]
	
	var data = spawnList[Pos][0]
	var Instance : RID = data["Instance"]
	
	var state : float = 0.0
	var variantIndex : int = 0
	if (moveData.State):
		state = 1
		
	variantIndex = moveData.Info.Element
	
	RenderingServer.instance_geometry_set_shader_parameter(Instance, "variant_index", variantIndex)
	RenderingServer.instance_geometry_set_shader_parameter(Instance, "instance_emission_energy_multiplier", state)

func MoveMovable(Data : MapData, Pos : Vector3i, MovablePosition : Vector3i, Push : bool = true) -> Vector3i:
	var cell = Data.cells[MovablePosition]
	var moveData : MovableData = cell.Custom_Data["Movable"]
	
	var data = spawnList[MovablePosition][0]
	var Instance = data["Instance"]
	var InstanceTransform = moveData.trans
	
	var Trans = moveData.trans
	var NewPos : Vector3i
	var NewT : Transform3D
	#Depending on the push direction position the movable accordingly
	if (Push):
		var PushDirection : Vector3i = Vector3(Pos).direction_to(Vector3(MovablePosition))
		NewT = Trans.translated(PushDirection * Level.CurrentWorldScale)
		NewPos = MovablePosition + PushDirection
	else:
		var PullDirection : Vector3i = Vector3(MovablePosition).direction_to(Vector3(Pos))
		NewT = Trans.translated(PullDirection * Level.CurrentWorldScale)
		NewPos = MovablePosition + PullDirection
	
	print("Trying to pull movable from {0} to {1}".format([MovablePosition, NewPos]))
	#Tween position of mesh
	if (is_instance_valid(MovableTween)):
		MovableTween.finished.emit()
		MovableTween.kill()
	MovableTween= create_tween()
	MovableTween.set_ease(Tween.EASE_IN_OUT)
	MovableTween.set_trans(Tween.TRANS_SINE)
	MovableTween.tween_method(UpdateMovablePosition.bind(Instance, moveData), InstanceTransform, NewT, 1)
	MovableTween.pause()
	
	var destinationCell = Data.cells[NewPos]

	cell.Custom_Data.erase("Movable")
	destinationCell.Custom_Data["Movable"] = moveData
	
	var collision = data["Collision"]
	#Update position of collision	
	collision.transform = NewT.translated(Vector3(0,0.3,0))

	spawnList.erase(MovablePosition)
	
	spawnList[NewPos] = []
	spawnList[NewPos].append(data)
	
	print("Movable position changed from {0} to {1}".format([MovablePosition, NewPos]))
	return NewPos
	#break

func MovableFinish(Part : GPUParticles3D) -> void:
	Part.emitting = false
	#Part.finished.connect(Part.queue_free)

func UpdateMovablePosition(Trans : Transform3D, Instacne : RID, data : MovableData) -> void:
	data.trans = Trans
	RenderingServer.instance_set_transform(Instacne, Trans)
