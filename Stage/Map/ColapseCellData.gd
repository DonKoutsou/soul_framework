@tool
extends RefCounted

class_name collapseCellData

var collapsed : bool = false
var possibleTiles : Array[collapseTileData]

func GetEntropy() -> int:
	return possibleTiles.size()
