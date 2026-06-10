@tool
extends Resource

class_name DoorData

@export var DoorMapPosition : Vector3i
@export var DoorTransform : Transform3D
@export var OpenDoorTransform : Transform3D
@export var OpossiteDoorMapPosition : Vector3i
@export var DoorState : bool = true
@export var Locked : bool = false
@export var Blocked : bool = false
@export var LockDat : LockData

static func NewData(Transform : Transform3D, OpossiteMapPos : Vector3i, State : bool = true) -> DoorData:
	var NewDoorData = DoorData.new()
	NewDoorData.DoorTransform = Transform
	NewDoorData.OpossiteDoorMapPosition = OpossiteMapPos
	NewDoorData.DoorState = State
	return NewDoorData
