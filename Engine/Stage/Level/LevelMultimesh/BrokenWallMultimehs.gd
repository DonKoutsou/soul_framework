@tool
extends LevelMultimesh
class_name BrokenWallMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	
	if (!cell.HasData("BrokenWalls")):
		return
	
	var spawnAmm : int = 0
	for wall in cell.Custom_Data["BrokenWalls"]:
		AddSpawn(geometry.get_rid(), pos, wall, spawnAmm)
		spawnAmm += 1

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.BROKEN_WALLS
