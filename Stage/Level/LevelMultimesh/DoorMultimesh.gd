@tool
extends LevelMultimesh
class_name DoorMultimesh

func _ready() -> void:
	collider = Level.CurrentWallCollider.create_trimesh_shape()
	collider.backface_collision = true

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	if (cell.HasData("Door")):
		var DoorDat = cell.Custom_Data["Door"]
		var trans = DoorDat.DoorTransform
		
		var collision = DoorCollisionShape.new()
		collision.Name = InteractionCollisionShape.AreaNames.Door
		collision.shape = collider
		collision.DoorDat = DoorDat
		collision.transform = trans
		collision.disabled = !DoorDat.DoorState
		
		if (DoorDat.DoorState):
			AddSpawn(geometry.get_rid(), pos, DoorDat.DoorTransform, 0, collision)
		else:
			AddSpawn(geometry.get_rid(), pos, DoorDat.OpenDoorTransform, 0, collision)

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.DOORS

func ToggleDoor(Data : MapData, Pos : Vector3i) -> void:
	var CurrentWorldScale = Level.CurrentWorldScale
	
	var cell : CellData = Data.cells[Pos]
	var DoorDat : DoorData = cell.Custom_Data["Door"]
	
	var oppositeCell : CellData = Data.cells[DoorDat.OpossiteDoorMapPosition]
	var OppositeDoorDat :DoorData = oppositeCell.Custom_Data["Door"]
	
	
	RemoveSpot(Data, Pos)
	RemoveSpot(Data, DoorDat.OpossiteDoorMapPosition)
	
	DoorDat.DoorState = !DoorDat.DoorState
	OppositeDoorDat.DoorState = !OppositeDoorDat.DoorState
	
	if (DoorDat.DoorState):
		DoorDat.Blocked = true
		OppositeDoorDat.Blocked = true
	else:
		DoorDat.Blocked = false
		OppositeDoorDat.Blocked = false
	
	var NewDoorPosition : Transform3D = DoorDat.DoorTransform.rotated_local(Vector3(0,1,0), PI/2).translated_local(-Vector3(0.6,0,-0.7))
	DoorDat.OpenDoorTransform = NewDoorPosition
	OppositeDoorDat.OpenDoorTransform = NewDoorPosition.rotated_local(Vector3(0,1,0), PI).translated_local(-Vector3(CurrentWorldScale.x,0,0))
	
	AudioManager.Instance.PlaySoundLocational(AudioManager.Sound.DOOR_OPEN, Pos * CurrentWorldScale, -5, 0.2, 1, true, 5)
