@tool
extends LevelMultimesh
class_name DugDuggableMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)
	if (cell.type == CellData.CELLTYPE.DUG_DUGGABLE):
		AddSpawn(geometry.get_rid(), pos, Transform3D(Basis(), realPos), 0)

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.DUG_DUGGABLES
