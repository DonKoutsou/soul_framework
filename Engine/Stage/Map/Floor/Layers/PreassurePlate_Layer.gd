@tool
extends BaseFloorLayer

class_name PreassurePlateLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index != -1 and map.PlateCatalogue.size() > index):
		var PData = PreassuerPlateData.new()
		PData.Info = map.PlateCatalogue[index].duplicate()
		cellDat.Custom_Data["Plate"] = PData
