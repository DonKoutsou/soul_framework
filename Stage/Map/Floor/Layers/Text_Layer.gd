@tool
extends BaseFloorLayer

class_name TextLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, _tempLayerData : TempLayerGenerationData, _tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index != -1 and map.TextCatalogue.size() > index):
		cellDat.AddData("Text", map.TextCatalogue[index])
