@tool
extends RefCounted

class_name TempLayerGenerationData

var Floor : FloorLayer
var SpawnFloor = true
var SpawnDeco = true
var SpawnCeiling = true

static func NewData(fl : FloorLayer) -> TempLayerGenerationData:
	var newData = TempLayerGenerationData.new()
	newData.Floor = fl
	return newData
