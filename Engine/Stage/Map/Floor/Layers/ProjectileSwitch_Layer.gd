@tool
extends BaseFloorLayer

class_name ProjectileSwitchLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x
	
	if (index != -1 and map.ProjectileSwitchCatalogue.size() > index):
		var SwitchData = ProjectileSwitchData.new()
		SwitchData.Info = map.ProjectileSwitchCatalogue[index].duplicate()
		SwitchData.Pos = Pos
		cellDat.Custom_Data["ProjectileSwitch"] = SwitchData
