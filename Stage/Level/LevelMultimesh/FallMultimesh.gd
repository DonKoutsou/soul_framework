@tool
extends LevelMultimesh
class_name FallMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)
	if (cell.type == CellData.CELLTYPE.FALL):
		var T1 = Transform3D(Basis(), realPos)
		var T2 = Transform3D(Basis().rotated(Vector3(0,0,1), PI), realPos)
		AddSpawn(geometry.get_rid(), pos, T1, 0)
		AddSpawn(geometry.get_rid(), pos, T2, 1)


func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.FALL
