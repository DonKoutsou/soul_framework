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


func GetDebugData(map : Map, floor : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	
	for LeverPosition in get_used_cells():
			
		var Index = get_cell_atlas_coords(LeverPosition).x
		
		var TextDrawPos = map_to_local(LeverPosition)
		
		var textSize = ThemeDB.fallback_font.get_multiline_string_size(var_to_str(Index), HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		TextDrawPos.x -= textSize.x / 2.0
		
		var textData : Dictionary[String, Variant] = {
			"text" : var_to_str(Index),
			"color" : DebugStringColor
		}
		
		DebugData["Texts"][TextDrawPos] = textData
		
		if (map.LeverCatalogue.size() - 1 < Index):
			printerr("Lever of Index {0} hasn't been configured in {1}".format([Index, map.LocationName.keys()[map.LevelName]]))
			continue
		var Dat = map.LeverCatalogue[Index]
		if (Dat is DoorLeverCallInfo):
			var UnlockPosition = Dat.DoorLoc
			if (UnlockPosition == Vector3i.ZERO):
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : var_to_str(Vector3i(LeverPosition.x, floor, LeverPosition.y)),
					"color" : DebugStringColor
				}
		
				DebugData["Texts"][LeverPosition] = linetextData
				
			else:
				if (map.CurrentlyVisibleFloor != floor and map.CurrentlyVisibleFloor != UnlockPosition.y):
					continue
				
				DebugData["Lines"].append(map_to_local(LeverPosition))
				DebugData["Lines"].append(map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z)))
				
				var text = var_to_str(UnlockPosition).erase(0, 8)
				
				var LineTextDrawPos = map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z))
				var LinetextSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
				LineTextDrawPos.x -= LinetextSize.x / 2.0
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : text,
					"color" : DebugStringColor
				}
				
				DebugData["Texts"][LineTextDrawPos] = linetextData

		if (Dat is BridgeLeverCallInfo):
			var UnlockPositions = Dat.FloorPos
			for Pos in UnlockPositions:
				DebugData["Lines"].append(map_to_local(LeverPosition))
				DebugData["Lines"].append(map_to_local(Vector2i(Pos.x, Pos.z)))
				
				var text = var_to_str(Vector3i(LeverPosition.x, floor, LeverPosition.y)).erase(0, 8)
				
				var LineTextDrawPos = map_to_local(Vector2i(Pos.x, Pos.z))
				var LinetextSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
				LineTextDrawPos.x -= LinetextSize.x / 2.0
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : text,
					"color" : DebugStringColor
				}
				
				DebugData["Texts"][LineTextDrawPos] = linetextData
	return DebugData
