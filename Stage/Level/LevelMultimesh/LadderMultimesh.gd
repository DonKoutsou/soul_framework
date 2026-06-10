@tool
extends LevelMultimesh
class_name LadderMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)
	if (cell.type == CellData.CELLTYPE.UP_LADDER):
		var Origin = realPos
		Origin.y += Level.CurrentWorldScale.y
		var Trans = Transform3D(Basis().rotated(Vector3(0,0,1), PI), Origin)
		Trans = Trans.rotated_local(Vector3(0,1,0), PI/2)
		AddSpawn(geometry.get_rid(), pos, Trans, 0)
	if (cell.type == CellData.CELLTYPE.DOWN_LADDER):
		var Trans = Transform3D(Basis(), realPos)
		AddSpawn(geometry.get_rid(), pos, Trans, 0)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.LADDERS
