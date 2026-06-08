@tool
extends BaseFloorLayer

class_name LeverLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index != -1 and map.LeverCatalogue.size() > index):
		var LData = LeverData.new()
		LData.Info = map.LeverCatalogue[index].duplicate()
		cellDat.Custom_Data["Lever"] = LData
		
		var LevelPos = Pos * map.WorldScale
		var RoundedPos = Vector3i(LevelPos)
		var rot = deg_to_rad(GetTileRotationDegrees(Vector2i(Pos.x, Pos.z)))
		var T = Transform3D(Basis().rotated(Vector3(0,1,0), rot), RoundedPos + Vector3i(0,1,0))
		LData.Trans = T
