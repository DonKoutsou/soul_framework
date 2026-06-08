@tool
extends LevelMultimesh
class_name StairsMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var cell = Data.cells[pos]
	if (cell.type == CellData.CELLTYPE.UP_STAIRS):
		var trans = cell.Custom_Data["UP_STAIRS"]
		AddSpawn(geometry.get_rid(), pos, trans, 0)
	if (cell.type == CellData.CELLTYPE.DOWN_STAIRS):
		var trans = cell.Custom_Data["DOWN_STAIRS"]
		AddSpawn(geometry.get_rid(), pos, trans, 0)

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.STAIRS

func AddSpot(_Data : MapData, _pos : Vector3i) -> void:
	return
