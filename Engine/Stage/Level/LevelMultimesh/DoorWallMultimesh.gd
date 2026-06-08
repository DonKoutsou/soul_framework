@tool
extends LevelMultimesh
class_name DoorWallMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	var spawnAmm : int = 0
	
	if (!cell.HasData("DoorWalls")):
		return
	
	for doorFrame in cell.Custom_Data["DoorWalls"]:
		AddSpawn(geometry.get_rid(), pos, doorFrame, spawnAmm)
		spawnAmm += 1

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.DOOR_WALLS
