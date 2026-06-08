@tool
extends LevelMultimesh
class_name CornerMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	var spawnamm : int = 0
	
	if (!cell.HasData("Corners")):
		return
	
	for doorFrame in cell.Custom_Data["Corners"]:
		AddSpawn(geometry.get_rid(), pos, doorFrame, spawnamm)
		spawnamm += 1

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.CORNERS
