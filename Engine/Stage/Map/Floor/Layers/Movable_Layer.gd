@tool
extends BaseFloorLayer

class_name MovableLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index != -1 and map.MovableCatalogue.size() > index):
		var MoveData = MovableData.new()
		MoveData.Info = map.MovableCatalogue[index].duplicate()
		cellDat.Custom_Data["Movable"] = MoveData
