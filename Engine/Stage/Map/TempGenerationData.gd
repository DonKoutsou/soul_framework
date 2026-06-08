@tool
extends RefCounted

class_name TempGenerationData

var Locks : Dictionary[Vector3i, LockData]
var MasterLocks : Array[Vector3i]
var Cracks : Dictionary[Vector3i, Vector2]
var Blocks : Array[Vector3i]
var r : RandomNumberGenerator

static func NewData(rand : RandomNumberGenerator) -> TempGenerationData:
	var newData = TempGenerationData.new()
	newData.r = rand
	return newData
