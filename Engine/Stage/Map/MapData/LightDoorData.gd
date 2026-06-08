@tool
extends DoorData

class_name LightDoorData

@export var StoredLight : float

static func NewData(Transform : Transform3D, OpossiteMapPos : Vector3i, State : bool = true) -> LightDoorData:
	var NewDoorData = LightDoorData.new()
	NewDoorData.DoorTransform = Transform
	NewDoorData.OpossiteDoorMapPosition = OpossiteMapPos
	NewDoorData.DoorState = State
	return NewDoorData
