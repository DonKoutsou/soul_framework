@tool
extends Resource

class_name ChestData

@export var ChestMapPosition : Vector3i
@export var ChestTransform : Transform3D
@export_file var ContainedItem : String
@export var LockDat : LockData

func TryUnlock(it : Item) -> bool:
	return LockDat.RequiredItem == it
