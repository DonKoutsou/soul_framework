@tool
extends BaseFloorLayer

class_name PreassurePlateLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, _tempLayerData : TempLayerGenerationData, _tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index != -1 and map.PlateCatalogue.size() > index):
		var PData = PreassuerPlateData.new()
		PData.Info = map.PlateCatalogue[index].duplicate()
		cellDat.Custom_Data["Plate"] = PData

func GetDebugData(map : Map, floorIndex : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	
	for PlatePosition in get_used_cells():
		
		var Index = get_cell_atlas_coords(PlatePosition).x
		if (map.PlateCatalogue.size() - 1 < Index):
			printerr("Plate of Index {0} hasn't been configured in {1}".format([Index, map.LocationName.keys()[map.LevelName]]))
			continue
			
		var Dat = map.PlateCatalogue[Index]

		var TextDrawPos = map_to_local(PlatePosition)
		var text = "{0}\n{1}".format([Index, PreassuerPlateData.SwitchElement.keys()[Dat.Element]])
		
		var textSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		TextDrawPos.x -= textSize.x / 2.0
		
		var textData : Dictionary[String, Variant] = {
			"text" : text,
			"color" : DebugStringColor
		}
		
		DebugData["Texts"][TextDrawPos] = textData

		if (Dat is DoorPreassurePlateCallInfo):
			var UnlockPosition = Dat.DoorLoc
			if (UnlockPosition == Vector3i.ZERO):
				DebugData["Lines"].append(map_to_local(PlatePosition))
				DebugData["Lines"].append(map_to_local(PlatePosition))
				
				var lineText = var_to_str(Vector3i(PlatePosition.x, floorIndex, PlatePosition.y)).erase(0, 8)
				
				var LineTextDrawPos = map_to_local(PlatePosition)
				var LinetextSize = ThemeDB.fallback_font.get_multiline_string_size(lineText, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
				LineTextDrawPos.x -= LinetextSize.x / 2.0
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : lineText,
					"color" : DebugStringColor
				}
				
				DebugData["Texts"][LineTextDrawPos] = linetextData
				
			else:
				DebugData["Lines"].append(map_to_local(PlatePosition))
				DebugData["Lines"].append(map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z)))
				
				var lineText = var_to_str(UnlockPosition).erase(0, 8)
				
				var LineTextDrawPos = map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z))
				var LinetextSize = ThemeDB.fallback_font.get_multiline_string_size(lineText, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
				LineTextDrawPos.x -= LinetextSize.x / 2.0
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : lineText,
					"color" : DebugStringColor
				}
				
				DebugData["Texts"][LineTextDrawPos] = linetextData
		
	return DebugData
