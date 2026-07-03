@tool
extends RefCounted

class_name collapseCellData

var collapsed : bool = false
var possibleTiles : Array[collapseTileData]

func GetEntropy(atlasData : Dictionary[int, TileData]) -> float:
	if possibleTiles.is_empty():
		return 0.0  # Contradiction

	var total_weight := 0.0
	var weight_log_weight := 0.0

	for tile in possibleTiles:
		if (atlasData[tile.tileIndex].probability == 0):
			continue
		var w: float = atlasData[tile.tileIndex].probability
		total_weight += w
		weight_log_weight += w * log(w)

	if total_weight == 0.0:
		return 0.0

	return log(total_weight) - (weight_log_weight / total_weight)
