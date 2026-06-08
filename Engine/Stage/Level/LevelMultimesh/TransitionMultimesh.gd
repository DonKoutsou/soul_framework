@tool
extends LevelMultimesh
class_name TransitionMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.GetCell(pos)
	if (cell.type == CellData.CELLTYPE.EXIT):
		var realPos = Helper.MapToPlayerPosition(pos)
		var Trans = Transform3D(Basis(), Vector3(realPos) + Vector3(0, 0.1, 0))
		AddSpawn(geometry.get_rid(), pos, Trans, 0)


func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.TRANSITIONS
