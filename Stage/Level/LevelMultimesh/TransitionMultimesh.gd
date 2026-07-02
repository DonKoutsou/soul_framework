@tool
extends LevelMultimesh
class_name TransitionMultimesh

const Neighbors : Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.GetCell(pos)
	if (cell.type == CellData.CELLTYPE.EXIT):
		#find door 
		var doorPos : Vector3i = pos
		for g in Neighbors:
			var possibleDoor = pos + g
			if (Data.HasCell(possibleDoor) and Data.GetCell(possibleDoor).type == CellData.CELLTYPE.DOOR):
				doorPos = possibleDoor
				break
		
		var doordir = doorPos - pos
		
		var realPos = Helper.MapToPlayerPosition(pos)
		var Trans = Transform3D(Basis(), Vector3(realPos) + Vector3(0, 0.1, 0) + Vector3(doordir))
		AddSpawn(geometry.get_rid(), pos, Trans, 0)


func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.TRANSITIONS
